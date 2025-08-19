#!/usr/bin/env bash
set -euo pipefail

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

SCRIPT_VERSION="1.1.0"
DEFAULT_ENV_FILE=".env"
LOG_LEVEL="${LOG_LEVEL:-INFO}" # DEBUG, INFO, WARN, ERROR

# -------------------------------------------------------
# Logging functions
# -------------------------------------------------------

log_debug() {
  if [[ "${LOG_LEVEL:-}" == "DEBUG" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

log_info() {
  if [[ "${LOG_LEVEL:-}" =~ ^(DEBUG|INFO)$ ]]; then
    echo "[INFO] $*" >&2
  fi
}

log_warn() {
  if [[ "${LOG_LEVEL:-}" =~ ^(DEBUG|INFO|WARN)$ ]]; then
    echo "[WARN] $*" >&2
  fi
}

log_error() {
  echo "[ERROR] $*" >&2
}

# -------------------------------------------------------
# Utility functions
# -------------------------------------------------------

require_git_root() {
  local root
  if ! root=$(git rev-parse --show-toplevel 2>/dev/null); then
    log_error "not inside a git repository"
    exit 1
  fi
  basename "$root"
}

# Check if required tools are available
check_dependencies() {
  local missing_tools=()

  command -v pass >/dev/null 2>&1 || missing_tools+=("pass")
  command -v git >/dev/null 2>&1 || missing_tools+=("git")

  if [[ ${#missing_tools[@]} -gt 0 ]]; then
    log_error "Missing required tools: ${missing_tools[*]}"
    log_error "Please install: sudo apt-get install pass git"
    exit 1
  fi
}

# Validate password store is initialized
check_pass_store() {
  if [[ -z "${PASSWORD_STORE_DIR:-}" ]]; then
    export PASSWORD_STORE_DIR="$HOME/.password-store"
  fi

  if [[ ! -d "$PASSWORD_STORE_DIR" ]]; then
    log_error "Password store not found at $PASSWORD_STORE_DIR"
    log_error "Initialize with: pass init <gpg-key-id>"
    exit 1
  fi
}

secret_exists() {
  pass show "$1" &>/dev/null
}

validate_key() {
  local key="$1"
  # Convert to uppercase for validation and storage
  key="${key^^}"
  if [[ ! "$key" =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
    log_error "Invalid key '$1'. Keys must start with letter/underscore and contain only letters, numbers, and underscores."
    exit 1
  fi
  # Return the uppercase version
  echo "$key"
}

validate_env() {
  local env="$1"
  if [[ ! "$env" =~ ^[A-Za-z0-9_/-]+$ ]]; then
    log_error "Invalid environment name '$env'. Use only letters, numbers, underscores, hyphens, and forward slashes."
    exit 1
  fi

  # Prevent path traversal attacks
  if [[ "$env" == *".."* ]] || [[ "$env" == "/"* ]] || [[ "$env" == *"/"* ]]; then
    # Allow forward slashes but not at the beginning, and no double dots
    if [[ "$env" == "/"* ]] || [[ "$env" == *".."* ]]; then
      log_error "Invalid environment path '$env'. No leading slashes or '..' sequences allowed."
      exit 1
    fi
  fi
}

confirm_action() {
  local message="$1"
  local default="${2:-N}" # Y or N

  if [[ "${PASSX_AUTO_CONFIRM:-}" == "true" ]]; then
    log_debug "Auto-confirming: $message"
    return 0
  fi

  local prompt
  case "$default" in
  Y | y) prompt=" (Y/n): " ;;
  *) prompt=" (y/N): " ;;
  esac

  echo -n "$message$prompt" >&2
  read -r response

  case "$response" in
  [yY] | [yY][eE][sS]) return 0 ;;
  [nN] | [nN][oO]) return 1 ;;
  "") [[ "$default" =~ ^[Yy]$ ]] && return 0 || return 1 ;;
  *) return 1 ;;
  esac
}

# Safe file operations
backup_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    cp "$file" "$file.backup.$(date +%Y%m%d_%H%M%S)"
    log_info "Created backup: $file.backup.$(date +%Y%m%d_%H%M%S)"
  fi
}

# Improved error handling for pass operations
safe_pass_insert() {
  local path="$1"
  local force="${2:-false}"
  local temp_file
  temp_file=$(mktemp)

  # Ensure cleanup
  trap '[[ -n "${temp_file:-}" ]] && rm -f "$temp_file"' EXIT

  # Read from stdin to temp file
  cat >"$temp_file"

  # Insert using temp file
  local pass_args=("-m")
  [[ "$force" == "true" ]] && pass_args+=("--force")

  if pass insert "${pass_args[@]}" "$path" <"$temp_file"; then
    log_debug "Successfully inserted/updated secret: $path"
    return 0
  else
    log_error "Failed to insert/update secret: $path"
    return 1
  fi
}

# -------------------------------------------------------
# Commands
# -------------------------------------------------------

cmd_add() {
  local env="$1"
  local key="$2"
  local value="${3:-}"
  local project

  validate_env "$env"
  key=$(validate_key "$key") # Get the uppercase version
  project=$(require_git_root)
  local path="$project/$env/$key"

  if secret_exists "$path"; then
    log_error "Secret $path already exists. Use update instead."
    exit 1
  fi

  if [[ -n "$value" ]]; then
    printf "%s" "$value" | safe_pass_insert "$path"
  else
    safe_pass_insert "$path" </dev/tty
  fi
  log_info "Stored $key in $env"
}

cmd_update() {
  local env="$1"
  local key="$2"
  local value="${3:-}"
  local project

  validate_env "$env"
  key=$(validate_key "$key") # Get the uppercase version
  project=$(require_git_root)
  local path="$project/$env/$key"

  if ! secret_exists "$path"; then
    log_error "Secret $path does not exist. Use add instead."
    exit 1
  fi

  if [[ -n "$value" ]]; then
    printf "%s" "$value" | safe_pass_insert "$path" true
  else
    safe_pass_insert "$path" true </dev/tty
  fi
  log_info "Updated $key in $env"
}

cmd_get() {
  local env="$1"
  local key="$2"
  local project

  validate_env "$env"
  key=$(validate_key "$key") # Get the uppercase version
  project=$(require_git_root)
  local path="$project/$env/$key"

  if ! secret_exists "$path"; then
    log_error "Secret $key not found in environment $env"
    exit 1
  fi

  pass show "$path"
}

cmd_run() {
  local env="$1"
  shift || true
  local project

  validate_env "$env"
  project=$(require_git_root)

  # Check if environment has any secrets
  local env_dir="$PASSWORD_STORE_DIR/$project/$env"
  if [[ ! -d "$env_dir" ]]; then
    log_error "No secrets found for environment '$env'"
    exit 1
  fi

  mapfile -t keys < <(
    find "$env_dir" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/##; s#\.gpg\$##"
  )

  if [[ ${#keys[@]} -eq 0 ]]; then
    log_error "No secrets found for environment '$env'"
    exit 1
  fi

  local k v name

  declare -A loaded_map=()

  for k in "${keys[@]}"; do
    name="${k##*/}"
    if v=$(pass show "$k" 2>/dev/null); then
      export "$name"="$v"
      loaded_map["$name"]="$v"
    else
      log_warn "Failed to load secret: $name"
    fi
  done

  log_info "Loaded ${#loaded_map[@]} secrets for environment '$env'"

  if [[ "$#" -gt 0 ]]; then
    exec "$@"
  else
    exec "${SHELL:-/bin/bash}"
  fi
}

cmd_export() {
  local env="$1"
  local output_file="${2:-$DEFAULT_ENV_FILE}"
  local project

  validate_env "$env"
  project=$(require_git_root)

  # Check if output file exists and ask for confirmation
  if [[ -f "$output_file" ]]; then
    backup_file "$output_file"
    if ! confirm_action "File '$output_file' exists. Overwrite?"; then
      log_info "Export cancelled"
      exit 0
    fi
  fi

  local env_dir="$PASSWORD_STORE_DIR/$project/$env"
  if [[ ! -d "$env_dir" ]]; then
    log_error "No secrets found for environment '$env'"
    exit 1
  fi

  mapfile -t keys < <(
    find "$env_dir" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/##; s#\.gpg\$##" |
      sort
  )

  if [[ ${#keys[@]} -eq 0 ]]; then
    log_error "No secrets found for environment '$env'"
    exit 1
  fi

  local temp_file
  temp_file=$(mktemp)
  trap '[[ -n "${temp_file:-}" ]] && rm -f "$temp_file"' EXIT

  {
    echo "# Exported secrets for environment: $env"
    echo "# Generated on: $(date)"
    echo "# Project: $project"
    echo ""

    declare -A exported_map=()

    for k in "${keys[@]}"; do
      name="${k##*/}"
      if v=$(pass show "$k" 2>/dev/null); then
        # Escape special characters properly
        local escaped_value
        escaped_value=$(printf '%s' "$v" | sed 's/\\/\\\\/g; s/"/\\"/g; s/$/\\n/' | tr -d '\n' | sed 's/\\n$//')

        # Always quote values to handle spaces and special characters safely
        printf "%s=\"%s\"\n" "$name" "$escaped_value"
        exported_map["$name"]="$escaped_value"
      else
        log_warn "Failed to export secret: $name"
      fi
    done
  } >"$temp_file"

  # Atomic move
  mv "$temp_file" "$output_file"
  log_info "Exported ${#exported_map[@]} secrets to $output_file"
}

cmd_import() {
  local env="$1"
  local file="$2"
  local mode="${3:-strict}" # strict | merge | overwrite
  local project

  validate_env "$env"
  project=$(require_git_root)

  if [[ ! -f "$file" ]]; then
    log_error "Import file not found: $file"
    exit 1
  fi

  case "$mode" in
  strict | merge | overwrite) ;;
  *)
    log_error "Invalid mode: $mode. Use strict, merge, or overwrite"
    exit 1
    ;;
  esac

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
      value="${value%"${value##*[![:space:]]}"}" # trim trailing spaces

      # Store in associative array (deduplicate)
      env_map["$key"]="$value"
    fi
  done <"$file"

  log_info "Found ${#env_map[@]} secrets to import in mode: $mode"

  declare -A skipped_map=()
  declare -A imported_map=()

  for key in "${!env_map[@]}"; do
    local value="${env_map[$key]}"
    local path="$project/$env/$key"

    if secret_exists "$path"; then
      case "$mode" in
      strict | merge)
        log_info "Skipping existing $key (mode: $mode)"
        skipped_map["$key"]="$value"
        continue
        ;;
      overwrite)
        printf "%s" "$value" | safe_pass_insert "$path" true "$value"
        log_info "Overwritten $key"
        imported_map["$key"]="$value"
        ;;
      esac
    else
      printf "%s" "$value" | safe_pass_insert "$path"
      log_info "Stored $key"
      imported_map["$key"]="$value"
    fi
  done

  log_info "Import complete: ${#imported_map[@]} imported, ${#skipped_map[@]} skipped"
}

cmd_ls() {
  local env="$1"
  shift || true
  local show_values=false
  local format="simple"

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --show | -s) show_values=true ;;
    --table | -t) format="table" ;;
    --help | -h)
      echo "Usage: passx <env> ls [--show] [--table]"
      echo "  --show/-s     Show secret values"
      echo "  --table/-t    Use table format"
      exit 0
      ;;
    *)
      log_error "Unknown flag: $1"
      exit 1
      ;;
    esac
    shift
  done

  local project
  validate_env "$env"
  project=$(require_git_root)

  local env_dir="$PASSWORD_STORE_DIR/$project/$env"
  if [[ ! -d "$env_dir" ]]; then
    log_info "No secrets found for environment '$env'"
    exit 0
  fi

  mapfile -t keys < <(
    find "$env_dir" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/$project/$env/##; s#\.gpg\$##" |
      sort
  )

  if [[ ${#keys[@]} -eq 0 ]]; then
    log_info "No secrets found for environment '$env'"
    exit 0
  fi

  if [[ "$format" == "table" ]]; then
    printf "%-20s %s\n" "KEY" "VALUE"
    printf "%-20s %s\n" "$(printf '%*s' 20 '' | tr ' ' '-')" "$(printf '%*s' 40 '' | tr ' ' '-')"
  fi

  declare -A displayed_map=()

  for key in "${keys[@]}"; do
    if $show_values; then
      if v=$(pass show "$project/$env/$key" 2>/dev/null); then
        if [[ "$format" == "table" ]]; then
          # Truncate long values in table format
          local display_value="$v"
          if [[ ${#display_value} -gt 50 ]]; then
            display_value="${display_value:0:47}..."
          fi
          printf "%-20s %s\n" "$key" "$display_value"
          displayed_map["$key"]="$display_value"
        else
          printf "%s=%s\n" "$key" "$v"
          displayed_map["$key"]="$v"
        fi
      else
        log_warn "Failed to read secret: $key"
      fi
    else
      if [[ "$format" == "table" ]]; then
        printf "%-20s %s\n" "$key" "[hidden]"
      else
        echo "$key"
      fi
      displayed_map["$key"]="[hidden]"
    fi
  done

  log_info "Found ${#displayed_map[@]} secrets in environment '$env'"
}

cmd_del() {
  local env="$1"
  local key="$2"
  local force=false

  # Check for --force flag
  while [[ $# -gt 2 ]]; do
    case "$3" in
    --force | -f) force=true ;;
    *)
      log_error "Unknown flag: $3"
      exit 1
      ;;
    esac
    shift
  done

  local project
  validate_env "$env"
  key=$(validate_key "$key") # Get the uppercase version
  project=$(require_git_root)
  local path="$project/$env/$key"

  if ! secret_exists "$path"; then
    log_error "Secret $key not found in environment $env"
    exit 1
  fi

  if ! $force && ! confirm_action "Delete secret '$key' from environment '$env'?"; then
    log_info "Deletion cancelled"
    exit 0
  fi

  if pass rm -f "$path" >/dev/null 2>&1; then
    log_info "Deleted $key from $env"
  else
    log_error "Failed to delete $key"
    exit 1
  fi
}

# Fixed copy command with better error handling
cmd_copy() {
  local from_env="$1"
  local to_env="$2"
  local key="${3:-}"
  local project

  validate_env "$from_env"
  validate_env "$to_env"
  project=$(require_git_root)

  if [[ -n "$key" ]]; then
    # Copy single key
    key=$(validate_key "$key") # Get the uppercase version
    local from_path="$project/$from_env/$key"
    local to_path="$project/$to_env/$key"

    if ! secret_exists "$from_path"; then
      log_error "Secret $key not found in environment $from_env"
      exit 1
    fi

    if secret_exists "$to_path" && ! confirm_action "Secret $key already exists in $to_env. Overwrite?"; then
      log_info "Copy cancelled"
      exit 0
    fi

    # Use pass cp command if available (newer versions), otherwise manual copy
    if pass cp --help >/dev/null 2>&1; then
      if pass cp "$from_path" "$to_path" >/dev/null 2>&1; then
        log_info "Copied $key from $from_env to $to_env"
      else
        log_error "Failed to copy $key"
        exit 1
      fi
    else
      # Manual copy using temporary file for safety
      local temp_file
      temp_file=$(mktemp)
      trap 'rm -f "$temp_file"' EXIT

      if pass show "$from_path" >"$temp_file" 2>/dev/null; then
        if safe_pass_insert "$to_path" true <"$temp_file"; then
          log_info "Copied $key from $from_env to $to_env"
        else
          log_error "Failed to copy $key"
          exit 1
        fi
      else
        log_error "Failed to read source secret: $key"
        exit 1
      fi
    fi
  else
    # Copy all keys from one environment to another
    local from_dir="$PASSWORD_STORE_DIR/$project/$from_env"
    if [[ ! -d "$from_dir" ]]; then
      log_error "No secrets found for environment '$from_env'"
      exit 1
    fi

    mapfile -t keys < <(
      find "$from_dir" -type f -name '*.gpg' |
        sed -E "s#^$PASSWORD_STORE_DIR/$project/$from_env/##; s#\.gpg\$##"
    )

    if [[ ${#keys[@]} -eq 0 ]]; then
      log_error "No secrets found for environment '$from_env'"
      exit 1
    fi

    if ! confirm_action "Copy ${#keys[@]} secrets from '$from_env' to '$to_env'?"; then
      log_info "Copy cancelled"
      exit 0
    fi

    declare -A copied_map=()
    declare -A failed_map=()

    for key in "${keys[@]}"; do
      local from_path="$project/$from_env/$key"
      local to_path="$project/$to_env/$key"

      local temp_file
      temp_file=$(mktemp)
      trap 'rm -f "$temp_file"' EXIT

      if pass show "$from_path" >"$temp_file" 2>/dev/null; then
        if safe_pass_insert "$to_path" true <"$temp_file"; then
          copied_map["$key"]="$key"
          log_debug "Copied $key"
        else
          failed_map["$key"]="$key"
          log_warn "Failed to copy $key"
        fi
      else
        failed_map["$key"]="$key"
        log_warn "Failed to read $key"
      fi

      rm -f "$temp_file"
    done

    if [[ ${#failed_map[@]} -eq 0 ]]; then
      log_info "Successfully copied all ${#copied_map[@]} secrets from $from_env to $to_env"
    else
      log_warn "Copied ${#copied_map[@]} secrets, ${#failed_map[@]} failed from $from_env to $to_env"
    fi
  fi
}

cmd_envs() {
  local project
  project=$(require_git_root)
  local project_dir="$PASSWORD_STORE_DIR/$project"

  if [[ ! -d "$project_dir" ]]; then
    log_info "No environments found for project '$project'"
    exit 0
  fi

  echo "Environments in project '$project':"

  # Find all directories that contain .gpg files (actual environments)
  local env_found=false
  while IFS= read -r -d '' env_path; do
    # Check if this directory contains any .gpg files
    local count
    count=$(find "$env_path" -maxdepth 1 -name '*.gpg' 2>/dev/null | wc -l)

    if [[ "$count" -gt 0 ]]; then
      env_found=true
      # Get the relative path from project_dir
      local env_name
      env_name=$(realpath --relative-to="$project_dir" "$env_path")
      printf "  %-20s (%d secrets)\n" "$env_name" "$count"
    fi
  done < <(find "$project_dir" -mindepth 1 -maxdepth 2 -type d -print0 | sort -z)

  if ! $env_found; then
    log_info "No environments with secrets found"
  fi
}

# New command: validate environment integrity
cmd_validate() {
  local env="${1:-}"
  local project
  project=$(require_git_root)

  if [[ -n "$env" ]]; then
    validate_env "$env"
    echo "Validating environment: $env"
    local env_dir="$PASSWORD_STORE_DIR/$project/$env"

    if [[ ! -d "$env_dir" ]]; then
      log_error "Environment '$env' not found"
      exit 1
    fi

    declare -A total_map=()
    declare -A valid_map=()
    declare -A invalid_map=()

    while IFS= read -r -d '' secret_file; do
      local secret_name
      secret_name=$(basename "$secret_file" .gpg)
      local path="$project/$env/$secret_name"

      total_map["$secret_name"]="$secret_name"

      if secret_exists "$path" && pass show "$path" >/dev/null 2>&1; then
        valid_map["$secret_name"]="$secret_name"
        echo "  ✓ $secret_name"
      else
        invalid_map["$secret_name"]="$secret_name"
        echo "  ✗ $secret_name (corrupted or inaccessible)"
      fi
    done < <(find "$env_dir" -name '*.gpg' -print0)

    echo ""
    echo "Validation complete: ${#valid_map[@]} valid, ${#invalid_map[@]} invalid out of ${#total_map[@]} total"
    [[ ${#invalid_map[@]} -eq 0 ]] && exit 0 || exit 1
  else
    echo "Validating all environments..."
    cmd_envs
  fi
}

# -------------------------------------------------------
# Dispatcher
# -------------------------------------------------------

usage() {
  cat <<EOF
passx v$SCRIPT_VERSION - Password store environment manager

Usage: $0 <command> [args...]

Commands:
  [ENV] add <KEY> [VAL]           Add a new secret (fails if exists)
  [ENV] update <KEY> [VAL]        Update an existing secret
  [ENV] get <KEY>                 Retrieve a secret
  [ENV] del <KEY> [--force]       Delete a secret
  [ENV] ls [--show] [--table]     List secrets (--show: with values, --table: table format)
  [ENV] run [CMD...]              Run command with secrets loaded into environment
  [ENV] export [FILE]             Export secrets to .env file (default: .env)
  [ENV] import FILE [MODE]        Import from .env (MODE: strict|merge|overwrite, default: strict)
  copy <FROM_ENV> <TO_ENV> [KEY]  Copy secrets between environments
  [ENV] validate                  Validate environment integrity
  envs                            List all environments

Environment Variables:
  PASSX_AUTO_CONFIRM=true   Skip confirmation prompts
  LOG_LEVEL=DEBUG|INFO|WARN|ERROR  Set logging level (default: INFO)

Examples:
  $0 dev add API_KEY secret123
  $0 prod import .env.prod overwrite
  $0 dev run npm start
  $0 copy dev staging DATABASE_URL
  $0 dev validate

EOF
  exit 1
}

main() {
  # Check dependencies first
  check_dependencies
  check_pass_store

  if [[ "$#" -eq 0 ]]; then
    usage
  fi

  # Handle global commands
  case "$1" in
  envs)
    cmd_envs
    exit 0
    ;;
  copy)
    if [[ "$#" -lt 3 ]]; then
      log_error "copy requires at least FROM_ENV and TO_ENV"
      usage
    fi
    cmd_copy "$2" "$3" "${4:-}"
    exit 0
    ;;
  validate)
    cmd_validate "${2:-}"
    exit 0
    ;;
  --version | -v)
    echo "passx v$SCRIPT_VERSION"
    exit 0
    ;;
  --help | -h)
    usage
    ;;
  esac

  if [[ "$#" -lt 2 ]]; then
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
  validate) cmd_validate "$env" ;;
  *)
    log_error "Unknown command: $cmd"
    usage
    ;;
  esac
}

main "$@"
