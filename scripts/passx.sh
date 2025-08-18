#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

SCRIPT_VERSION="1.0.0"
DEFAULT_ENV_FILE=".env"

# -------------------------------------------------------
# Utility functions
# -------------------------------------------------------

require_git_root() {
  if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
    echo "Error: not inside a git repository" >&2
    exit 1
  fi
  basename "$root"
}

# secret_exists() {
#   local path="$1"
#   pass show "$path" >/dev/null 2>&1
# }

secret_exists() {
  pass show "$1" &>/dev/null # swallow all output and any passphrase prompt
}

validate_key() {
  local key="$1"
  if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
    echo "Error: Invalid key '$key'. Keys must start with letter/underscore and contain only letters, numbers, and underscores." >&2
    exit 1
  fi
}

confirm_action() {
  local message="$1"
  echo -n "$message (y/N): "
  read -r response
  case "$response" in
  [yY] | [yY][eE][sS]) return 0 ;;
  *) return 1 ;;
  esac
}

# -------------------------------------------------------
# Commands
# -------------------------------------------------------

cmd_add() {
  local env="$1"
  local key="$2"
  local value="${3:-}"
  local project
  project=$(require_git_root)
  local path="$project/$env/$key"

  validate_key "$key"

  if secret_exists "$path"; then
    echo "Error: Secret $path already exists. Use update instead." >&2
    exit 1
  fi

  if [ -n "$value" ]; then
    printf "%s\n" "$value" | pass insert -m "$path"
  else
    pass insert -m "$path"
  fi
  echo "Stored $key"
}

cmd_update() {
  local env="$1"
  local key="$2"
  local value="${3:-}"
  local project
  project=$(require_git_root)
  local path="$project/$env/$key"

  validate_key "$key"

  if ! secret_exists "$path"; then
    echo "Error: Secret $path does not exist. Use add instead." >&2
    exit 1
  fi

  if [ -n "$value" ]; then
    printf "%s\n" "$value" | pass insert -m "$path" --force
  else
    pass insert -m "$path" --force
  fi
  echo "Updated $key"
}

cmd_get() {
  local env="$1"
  local key="$2"
  local project
  project=$(require_git_root)
  local path="$project/$env/$key"

  if ! secret_exists "$path"; then
    echo "Error: Secret $key not found in environment $env" >&2
    exit 1
  fi

  pass show "$path"
}

cmd_run() {
  local env="$1"
  shift || true
  local project
  project=$(require_git_root)

  # Check if environment has any secrets
  local env_dir="$PASSWORD_STORE_DIR/$project/$env"
  if [ ! -d "$env_dir" ]; then
    echo "Error: No secrets found for environment '$env'" >&2
    exit 1
  fi

  mapfile -t keys < <(
    find "$env_dir" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/##; s#\.gpg\$##"
  )

  if [ ${#keys[@]} -eq 0 ]; then
    echo "Error: No secrets found for environment '$env'" >&2
    exit 1
  fi

  local k v name
  for k in "${keys[@]}"; do
    name="${k##*/}"
    v=$(pass show "$k")
    export "$name"="$v"
  done

  echo "Loaded ${#keys[@]} secrets for environment '$env'" >&2

  if [ "$#" -gt 0 ]; then
    exec "$@"
  else
    exec "$SHELL"
  fi
}

cmd_export() {
  local env="$1"
  local output_file="${2:-$DEFAULT_ENV_FILE}"
  local project
  project=$(require_git_root)

  # Check if output file exists and ask for confirmation
  if [ -f "$output_file" ] && ! confirm_action "File '$output_file' exists. Overwrite?"; then
    echo "Export cancelled"
    exit 0
  fi

  mapfile -t keys < <(
    find "$PASSWORD_STORE_DIR/$project/$env" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/##; s#\.gpg\$##"
  )

  if [ ${#keys[@]} -eq 0 ]; then
    echo "Error: No secrets found for environment '$env'" >&2
    exit 1
  fi

  {
    echo "# Exported secrets for environment: $env"
    echo "# Generated on: $(date)"
    echo ""
    for k in "${keys[@]}"; do
      name="${k##*/}"
      v=$(pass show "$k")
      # Quote values that contain spaces or special characters
      if [[ "$v" =~ [[:space:]] ]] || [[ "$v" =~ [\"\'\`\$\\] ]]; then
        printf "%s=\"%s\"\n" "$name" "${v//\"/\\\"}"
      else
        printf "%s=%s\n" "$name" "$v"
      fi
    done
  } >"$output_file"

  echo "Exported ${#keys[@]} secrets to $output_file"
}

cmd_import() {
  local env="$1"
  local file="$2"
  local mode="${3:-strict}" # strict | merge | overwrite
  local project
  project=$(require_git_root)

  declare -A env_map

  # Read valid KEY=VALUE lines, ignore comments/empty lines
  while IFS= read -r line; do
    # Skip empty lines and full-line comments
    [[ -z "$line" || "$line" =~ ^# ]] && continue

    # Remove inline comments
    line="${line%%#*}"

    # Only process lines that look like KEY=VALUE after removing comments
    if [[ "$line" =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
      key="${BASH_REMATCH[1]}"
      value="${BASH_REMATCH[2]}"

      # Trim spaces
      key="${key%% }"
      value="${value## }"

      # Remove surrounding quotes
      value="${value%\"}"
      value="${value#\"}"
      value="${value%\'}"
      value="${value#\'}"

      # Store in associative array (deduplicate)
      env_map["$key"]="$value"
    fi
  done <"$file"

  # Import secrets
  for key in "${!env_map[@]}"; do
    local value="${env_map[$key]}"
    local path="$project/$env/$key"

    if secret_exists "$path"; then
      case "$mode" in
      strict | merge)
        echo "Skipping existing $key (mode: $mode)"
        continue
        ;;
      overwrite)
        printf "%s\n" "$value" | pass insert -m "$path" --force
        echo "Overwritten $key"
        ;;
      esac
    else
      printf "%s\n" "$value" | pass insert -m "$path"
      echo "Stored $key"
    fi
  done

  echo "Imported secrets from $file (mode: $mode)"
}

cmd_ls() {
  local env="$1"
  shift || true
  local show_values=false
  local format="simple"

  # Check for flags
  while [ $# -gt 0 ]; do
    case "$1" in
    --show) show_values=true ;;
    --table) format="table" ;;
    esac
    shift
  done

  local project
  project=$(require_git_root)

  local env_dir="$PASSWORD_STORE_DIR/$project/$env"
  if [ ! -d "$env_dir" ]; then
    echo "No secrets found for environment '$env'"
    exit 0
  fi

  mapfile -t keys < <(
    find "$env_dir" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/$project/$env/##; s#\.gpg\$##" |
      sort
  )

  if [ ${#keys[@]} -eq 0 ]; then
    echo "No secrets found for environment '$env'"
    exit 0
  fi

  if [ "$format" = "table" ]; then
    printf "%-20s %s\n" "KEY" "VALUE"
    printf "%-20s %s\n" "---" "-----"
  fi

  for key in "${keys[@]}"; do
    if $show_values; then
      local v
      v=$(pass show "$project/$env/$key")
      if [ "$format" = "table" ]; then
        printf "%-20s %s\n" "$key" "$v"
      else
        printf "%s=%s\n" "$key" "$v"
      fi
    else
      if [ "$format" = "table" ]; then
        printf "%-20s %s\n" "$key" "[hidden]"
      else
        echo "$key"
      fi
    fi
  done

  echo "" >&2
  echo "Found ${#keys[@]} secrets in environment '$env'" >&2
}

cmd_del() {
  local env="$1"
  local key="$2"
  local force=false

  # Check for --force flag
  if [ "${3:-}" = "--force" ] || [ "${3:-}" = "-f" ]; then
    force=true
  fi

  local project
  project=$(require_git_root)
  local path="$project/$env/$key"

  if ! secret_exists "$path"; then
    echo "Error: Secret $key not found in environment $env" >&2
    exit 1
  fi

  if ! $force && ! confirm_action "Delete secret '$key' from environment '$env'?"; then
    echo "Deletion cancelled"
    exit 0
  fi

  pass rm -f "$path"
  echo "Deleted $key"
}

cmd_copy() {
  local from_env="$1"
  local to_env="$2"
  local key="${3:-}"
  local project
  project=$(require_git_root)

  if [ -n "$key" ]; then
    # Copy single key
    local from_path="$project/$from_env/$key"
    local to_path="$project/$to_env/$key"

    if ! secret_exists "$from_path"; then
      echo "Error: Secret $key not found in environment $from_env" >&2
      exit 1
    fi

    if secret_exists "$to_path" && ! confirm_action "Secret $key already exists in $to_env. Overwrite?"; then
      echo "Copy cancelled"
      exit 0
    fi

    local value
    value=$(pass show "$from_path")
    printf "%s\n" "$value" | pass insert -m "$to_path" --force
    echo "Copied $key from $from_env to $to_env"
  else
    # Copy all keys from one environment to another
    local from_dir="$PASSWORD_STORE_DIR/$project/$from_env"
    if [ ! -d "$from_dir" ]; then
      echo "Error: No secrets found for environment '$from_env'" >&2
      exit 1
    fi

    mapfile -t keys < <(
      find "$from_dir" -type f -name '*.gpg' |
        sed -E "s#^$PASSWORD_STORE_DIR/$project/$from_env/##; s#\.gpg\$##"
    )

    if [ ${#keys[@]} -eq 0 ]; then
      echo "Error: No secrets found for environment '$from_env'" >&2
      exit 1
    fi

    if ! confirm_action "Copy ${#keys[@]} secrets from '$from_env' to '$to_env'?"; then
      echo "Copy cancelled"
      exit 0
    fi

    local copied=0
    for key in "${keys[@]}"; do
      local from_path="$project/$from_env/$key"
      local to_path="$project/$to_env/$key"
      local value
      value=$(pass show "$from_path")
      printf "%s\n" "$value" | pass insert -m "$to_path" --force
      ((copied++))
    done

    echo "Copied $copied secrets from $from_env to $to_env"
  fi
}

cmd_envs() {
  local project
  project=$(require_git_root)
  local project_dir="$PASSWORD_STORE_DIR/$project"

  if [ ! -d "$project_dir" ]; then
    echo "No environments found for project '$project'"
    exit 0
  fi

  echo "Environments in project '$project':"
  find "$project_dir" -mindepth 1 -maxdepth 1 -type d -exec basename {} \; | sort | while read -r env; do
    local count
    count=$(find "$project_dir/$env" -name '*.gpg' | wc -l)
    printf "  %-15s (%d secrets)\n" "$env" "$count"
  done
}

# -------------------------------------------------------
# Dispatcher
# -------------------------------------------------------

usage() {
  echo "passx v$SCRIPT_VERSION - Password store environment manager"
  echo "Usage: $0 <env> <command> [args...]"
  echo
  echo "Commands:"
  echo "  add <KEY> [VAL]        Add a new secret (fails if exists)"
  echo "  update <KEY> [VAL]     Update an existing secret"
  echo "  get <KEY>              Retrieve a secret"
  echo "  del <KEY> [--force]    Delete a secret"
  echo "  ls [--show] [--table]  List secrets (with values/table format)"
  echo "  run [CMD...]           Run with secrets loaded into environment"
  echo "  export [FILE]          Export secrets to .env file"
  echo "  import FILE [MODE]     Import from .env (MODE: strict|merge|overwrite)"
  echo "  copy <FROM_ENV> <TO_ENV> [KEY]  Copy secrets between environments"
  echo
  echo "Global commands:"
  echo "  envs                   List all environments"
  echo
  echo "Examples:"
  echo "  $0 dev add API_KEY secret123"
  echo "  $0 prod import .env.prod overwrite"
  echo "  $0 dev run npm start"
  echo "  $0 copy dev staging"
  exit 1
}

main() {
  if [ "$#" -eq 0 ]; then
    usage
  fi

  # Handle global commands
  if [ "$1" = "envs" ]; then
    cmd_envs
    exit 0
  fi

  # Handle copy command (different syntax)
  if [ "$1" = "copy" ]; then
    if [ "$#" -lt 3 ]; then
      echo "Error: copy requires at least FROM_ENV and TO_ENV" >&2
      usage
    fi
    cmd_copy "$2" "$3" "${4:-}"
    exit 0
  fi

  if [ "$#" -lt 2 ]; then
    usage
  fi

  local env="$1"
  shift
  local cmd="$1"
  shift

  case "$cmd" in
  add) cmd_add "$env" "$@" ;;
  update) cmd_update "$env" "$@" ;;
  get) cmd_get "$env" "$@" ;;
  del) cmd_del "$env" "$@" ;;
  ls) cmd_ls "$env" "$@" ;;
  run) cmd_run "$env" "$@" ;;
  export) cmd_export "$env" "$@" ;;
  import) cmd_import "$env" "$@" ;;
  *) usage ;;
  esac
}

main "$@"
