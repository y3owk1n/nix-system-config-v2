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
  if [[ ${LOG_LEVEL:-} == "DEBUG" ]]; then
    echo "[DEBUG] $*" >&2
  fi
}

log_info() {
  if [[ ${LOG_LEVEL:-} =~ ^(DEBUG|INFO)$ ]]; then
    echo "[INFO] $*" >&2
  fi
}

log_warn() {
  if [[ ${LOG_LEVEL:-} =~ ^(DEBUG|INFO|WARN)$ ]]; then
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
  if [[ -z ${PASSWORD_STORE_DIR:-} ]]; then
    export PASSWORD_STORE_DIR="$HOME/.password-store"
  fi

  if [[ ! -d $PASSWORD_STORE_DIR ]]; then
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
  if [[ ! $key =~ ^[A-Z_][A-Z0-9_]*$ ]]; then
    log_error "Invalid key '$1'. Keys must start with letter/underscore and contain only letters, numbers, and underscores."
    exit 1
  fi
  # Return the uppercase version
  echo "$key"
}

validate_env() {
  local env="$1"
  if [[ ! $env =~ ^[A-Za-z0-9_/-]+$ ]]; then
    log_error "Invalid environment name '$env'. Use only letters, numbers, underscores, hyphens, and forward slashes."
    exit 1
  fi

  # Prevent path traversal attacks
  if [[ $env == *".."* ]] || [[ $env == "/"* ]] || [[ $env == *"/"* ]]; then
    # Allow forward slashes but not at the beginning, and no double dots
    if [[ $env == "/"* ]] || [[ $env == *".."* ]]; then
      log_error "Invalid environment path '$env'. No leading slashes or '..' sequences allowed."
      exit 1
    fi
  fi
}

confirm_action() {
  local message="$1"
  local default="${2:-N}" # Y or N

  if [[ ${PASSX_AUTO_CONFIRM:-} == "true" ]]; then
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
  "") [[ $default =~ ^[Yy]$ ]] && return 0 || return 1 ;;
  *) return 1 ;;
  esac
}

# Safe file operations
backup_file() {
  local file="$1"
  if [[ -f $file ]]; then
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
  [[ $force == "true" ]] && pass_args+=("--force")

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

  if [[ -n $value ]]; then
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

  if [[ -n $value ]]; then
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
  local envs=()
  local commands=()
  local merge_strategy="error" # error, first-wins, last-wins

  # Parse arguments to separate environments from command and flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --merge-strategy)
      shift
      if [[ -z ${1:-} ]]; then
        log_error "--merge-strategy requires a value: error, first-wins, or last-wins"
        exit 1
      fi
      case "$1" in
      error | first-wins | last-wins)
        merge_strategy="$1"
        ;;
      *)
        log_error "Invalid merge strategy: $1. Use error, first-wins, or last-wins"
        exit 1
        ;;
      esac
      ;;
    --help | -h)
      echo "Usage: passx <env> [env2 ...] run [--merge-strategy STRATEGY] [CMD...]"
      echo ""
      echo "Merge Strategies (when same key exists in multiple environments):"
      echo "  error       Fail if duplicate keys found (default)"
      echo "  first-wins  Use value from first environment that has the key"
      echo "  last-wins   Use value from last environment that has the key"
      echo ""
      echo "Examples:"
      echo "  passx dev run npm start"
      echo "  passx dev staging run --merge-strategy last-wins ./app"
      echo "  passx base dev run python script.py"
      exit 0
      ;;
    --*)
      log_error "Unknown flag: $1"
      exit 1
      ;;
    *)
      # Check if this looks like a command (executable file or common commands)
      if command -v "$1" >/dev/null 2>&1 || [[ $1 =~ ^(\./) ]] || [[ -x $1 ]]; then
        # This and everything after is the command
        commands=("$@")
        break
      else
        # This is an environment name
        envs+=("$1")
      fi
      ;;
    esac
    shift
  done

  # If no environments specified, error out
  if [[ ${#envs[@]} -eq 0 ]]; then
    log_error "No environment specified"
    exit 1
  fi

  local project
  project=$(require_git_root)

  declare -A all_secrets=()
  declare -A secret_sources=() # Track which env each secret came from
  declare -A duplicates=()     # Track duplicate keys
  local total_envs_processed=0

  log_debug "Processing ${#envs[@]} environments with merge strategy: $merge_strategy"

  # Process each environment
  for env in "${envs[@]}"; do
    validate_env "$env"

    local env_dir="$PASSWORD_STORE_DIR/$project/$env"
    if [[ ! -d $env_dir ]]; then
      log_warn "No secrets found for environment '$env'"
      continue
    fi

    mapfile -t keys < <(
      find "$env_dir" -maxdepth 1 -type f -name '*.gpg' |
        sed -E "s#^$PASSWORD_STORE_DIR/##; s#\.gpg\$##"
    )

    if [[ ${#keys[@]} -eq 0 ]]; then
      log_debug "No secrets found in environment '$env'"
      continue
    fi

    total_envs_processed=$((total_envs_processed + 1))
    log_debug "Processing $env with ${#keys[@]} secrets"

    local env_secrets_loaded=0

    for k in "${keys[@]}"; do
      local name="${k##*/}" # Get the secret name (last part of path)

      if v=$(pass show "$k" 2>/dev/null); then
        # Check for duplicates (only between different environments)
        if [[ -n ${all_secrets[$name]:-} ]] && [[ ${secret_sources[$name]:-} != "$env" ]]; then
          duplicates["$name"]="${secret_sources[$name]:-unknown} -> $env"

          case "$merge_strategy" in
          error)
            log_error "Duplicate key '$name' found in environments: ${secret_sources[$name]:-unknown} and $env"
            log_error "Use --merge-strategy to handle duplicates: first-wins, last-wins"
            exit 1
            ;;
          first-wins)
            log_debug "Duplicate key '$name': keeping value from ${secret_sources[$name]:-unknown} (first-wins)"
            continue # Skip this value, keep the existing one
            ;;
          last-wins)
            log_debug "Duplicate key '$name': using value from $env (last-wins)"
            # Fall through to set the new value
            ;;
          esac
        fi

        # Set/update the secret
        export "$name"="$v"
        all_secrets["$name"]="$v"
        secret_sources["$name"]="$env"
        env_secrets_loaded=$((env_secrets_loaded + 1))

        log_debug "Loaded $name from $env"
      else
        log_warn "Failed to load secret: ${k##*/} from $env"
      fi
    done

    log_debug "Loaded $env_secrets_loaded secrets from $env"
  done

  if [[ ${#all_secrets[@]} -eq 0 ]]; then
    log_error "No secrets loaded from any environment"
    exit 1
  fi

  # Report on duplicates if any were found
  if [[ ${#duplicates[@]} -gt 0 ]] && [[ $merge_strategy != "error" ]]; then
    log_info "Resolved ${#duplicates[@]} duplicate keys using strategy: $merge_strategy"
    if [[ ${LOG_LEVEL:-} == "DEBUG" ]]; then
      for dup_key in "${!duplicates[@]}"; do
        log_debug "Duplicate '$dup_key': ${duplicates[$dup_key]} -> final: ${secret_sources[$dup_key]}"
      done
    fi
  fi

  local env_text="environment"
  if [[ $total_envs_processed -gt 1 ]]; then
    env_text="environments"
  fi

  log_info "Loaded ${#all_secrets[@]} secrets from $total_envs_processed $env_text"

  # Execute command
  if [[ ${#commands[@]} -gt 0 ]]; then
    unset name
    log_debug "Executing: ${commands[*]}"
    exec "${commands[@]}"
  else
    log_debug "Starting shell: ${SHELL:-/bin/bash}"
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
  if [[ -f $output_file ]]; then
    backup_file "$output_file"
    if ! confirm_action "File '$output_file' exists. Overwrite?"; then
      log_info "Export cancelled"
      exit 0
    fi
  fi

  local env_dir="$PASSWORD_STORE_DIR/$project/$env"
  if [[ ! -d $env_dir ]]; then
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

  if [[ ! -f $file ]]; then
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
    [[ -z $line || $line =~ ^# ]] && continue

    # Remove inline comments
    line="${line%%#*}"

    # Only process lines that look like KEY=VALUE after removing comments
    if [[ $line =~ ^([A-Za-z_][A-Za-z0-9_]*)=(.*)$ ]]; then
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
  local show_values=false
  local format="simple"
  local recursive=false
  local envs=()

  # Parse arguments to separate environments from flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
    --show | -s) show_values=true ;;
    --table | -t) format="table" ;;
    --recursive | -r) recursive=true ;;
    --help | -h)
      echo "Usage: passx <env> [env2 ...] ls [--show] [--table] [--recursive]"
      echo "  --show/-s       Show secret values"
      echo "  --table/-t      Use table format"
      echo "  --recursive/-r  Include secrets in subdirectories"
      echo ""
      echo "Examples:"
      echo "  passx dev ls                    # List only direct secrets in dev"
      echo "  passx dev/folder ls             # List only secrets in dev/folder"
      echo "  passx dev dev/folder ls         # List secrets from both dev and dev/folder"
      echo "  passx dev ls --recursive        # List all secrets in dev and subdirectories"
      exit 0
      ;;
    --*)
      log_error "Unknown flag: $1"
      exit 1
      ;;
    *)
      # This is an environment name
      envs+=("$1")
      ;;
    esac
    shift
  done

  # If no environments specified, error out
  if [[ ${#envs[@]} -eq 0 ]]; then
    log_error "No environment specified"
    exit 1
  fi

  local project
  project=$(require_git_root)

  declare -A all_secrets=() # key -> "env:value"
  local total_envs_processed=0

  log_debug "Processing ${#envs[@]} environments: ${envs[*]}"

  # Process each environment
  for env in "${envs[@]}"; do
    validate_env "$env"

    local env_dir="$PASSWORD_STORE_DIR/$project/$env"
    if [[ ! -d $env_dir ]]; then
      log_warn "No secrets found for environment '$env'"
      continue
    fi

    local find_args=("$env_dir")

    if $recursive; then
      # Recursive: find all .gpg files in subdirectories
      find_args+=("-type" "f" "-name" "*.gpg")
    else
      # Non-recursive: only direct children
      find_args+=("-maxdepth" "1" "-type" "f" "-name" "*.gpg")
    fi

    mapfile -t keys < <(
      find "${find_args[@]}" |
        sed -E "s#^$PASSWORD_STORE_DIR/$project/$env/?##; s#\.gpg\$##" |
        grep -v '^$' | # Remove empty lines
        sort
    )

    if [[ ${#keys[@]} -eq 0 ]]; then
      log_debug "No secrets found in environment '$env'"
      continue
    fi

    total_envs_processed=$((total_envs_processed + 1))

    # Collect secrets from this environment
    for key in "${keys[@]}"; do
      local full_path="$project/$env/$key"

      # Create a display key that shows the source environment if multiple envs
      local display_key="$key"
      if [[ ${#envs[@]} -gt 1 ]]; then
        display_key="[$env] $key"
      fi

      log_debug "Processing key: '$key' -> display_key: '$display_key'"

      if $show_values; then
        local v=""
        if v=$(pass show "$full_path" 2>/dev/null); then
          all_secrets["$display_key"]="$v"
          log_debug "Successfully loaded value for: $display_key"
        else
          log_warn "Failed to read secret: $key from $env"
          all_secrets["$display_key"]="[ERROR]"
        fi
      else
        all_secrets["$display_key"]="[hidden]"
        log_debug "Set hidden value for: $display_key"
      fi
    done
  done

  if [[ ${#all_secrets[@]} -eq 0 ]]; then
    log_info "No secrets found in specified environments"
    exit 0
  fi

  # Display results
  if [[ $format == "table" ]]; then
    local key_header="KEY"
    if [[ ${#envs[@]} -gt 1 ]]; then
      key_header="ENVIRONMENT/KEY"
    fi

    printf "%-30s %s\n" "$key_header" "VALUE"
    printf "%-30s %s\n" "$(printf '%*s' 30 '' | tr ' ' '-')" "$(printf '%*s' 40 '' | tr ' ' '-')"

    # Sort keys for consistent output - use array instead of command substitution
    local sorted_keys=()
    while IFS= read -r -d '' key; do
      sorted_keys+=("$key")
    done < <(printf '%s\0' "${!all_secrets[@]}" | sort -z)

    for key in "${sorted_keys[@]}"; do
      local value="${all_secrets[$key]}"

      # Truncate long values in table format
      if [[ ${#value} -gt 50 ]]; then
        value="${value:0:47}..."
      fi

      printf "%-30s %s\n" "$key" "$value"
    done
  else
    # Simple format - use array instead of command substitution
    local sorted_keys=()
    while IFS= read -r -d '' key; do
      sorted_keys+=("$key")
    done < <(printf '%s\0' "${!all_secrets[@]}" | sort -z)

    for key in "${sorted_keys[@]}"; do
      local value="${all_secrets[$key]}"

      if $show_values; then
        printf "%s=%s\n" "$key" "$value"
      else
        echo "$key"
      fi
    done
  fi

  local env_text="environment"
  if [[ ${#envs[@]} -gt 1 ]] || [[ $total_envs_processed -gt 1 ]]; then
    env_text="environments"
  fi

  log_info "Found ${#all_secrets[@]} secrets across $total_envs_processed $env_text"
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

  if [[ -n $key ]]; then
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
    if [[ ! -d $from_dir ]]; then
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

  if [[ ! -d $project_dir ]]; then
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

    if [[ $count -gt 0 ]]; then
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

  if [[ -n $env ]]; then
    validate_env "$env"
    echo "Validating environment: $env"
    local env_dir="$PASSWORD_STORE_DIR/$project/$env"

    if [[ ! -d $env_dir ]]; then
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
  [ENV] add <KEY> [VAL]                               Add a new secret (fails if exists)
  [ENV] update <KEY> [VAL]                            Update an existing secret
  [ENV] get <KEY>                                     Retrieve a secret
  [ENV] del <KEY> [--force]                           Delete a secret
  [ENV...] ls [--show] [--table] [--recursive]        List secrets from one or more environments
  [ENV...] run [--merge-strategy STRATEGY] [CMD...]   Run command with secrets from one or more environments
  [ENV] export [FILE]                                 Export secrets to .env file (default: .env)
  [ENV] import FILE [MODE]                            Import from .env (MODE: strict|merge|overwrite, default: strict)
  copy <FROM_ENV> <TO_ENV> [KEY]                      Copy secrets between environments
  [ENV] validate                                      Validate environment integrity
  envs                                                List all environments

List Command Examples:
  $0 dev ls                          # List only direct secrets in dev (non-recursive)
  $0 dev/folder ls                   # List only secrets in dev/folder
  $0 dev dev/folder ls               # List secrets from both dev and dev/folder
  $0 dev ls --recursive              # List all secrets in dev and subdirectories
  $0 dev prod ls --show --table      # Show values from dev and prod in table format

Run Command Examples:
  $0 dev run npm start               # Run with dev environment
  $0 base dev run python app.py      # Merge base + dev (error on conflicts)
  $0 base dev run --merge-strategy last-wins ./start.sh  # dev overrides base
  $0 shared dev staging run          # Merge 3 environments (error on conflicts)

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

  if [[ $# -eq 0 ]]; then
    usage
  fi

  # Handle global commands
  case "$1" in
  envs)
    cmd_envs
    exit 0
    ;;
  copy)
    if [[ $# -lt 3 ]]; then
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

  # For ls and run commands, we need special handling to support multiple environments
  # Find the position of 'ls' or 'run' command in arguments
  local cmd_pos=-1
  local cmd_found=""
  local i=0
  for arg in "$@"; do
    i=$((i + 1))
    if [[ $arg == "ls" ]] || [[ $arg == "run" ]]; then
      cmd_pos=$i
      cmd_found="$arg"
      break
    fi
  done

  if [[ $cmd_pos -gt 0 ]]; then
    # Extract environments (everything before the command)
    local envs=("${@:1:$((cmd_pos - 1))}")
    # Extract arguments (everything after the command)
    local cmd_args=("${@:$((cmd_pos + 1))}")

    if [[ ${#envs[@]} -eq 0 ]]; then
      log_error "No environment specified for $cmd_found command"
      usage
    fi

    # Call the appropriate command with environments and arguments
    case "$cmd_found" in
    ls)
      cmd_ls "${envs[@]}" "${cmd_args[@]}"
      ;;
    run)
      cmd_run "${envs[@]}" "${cmd_args[@]}"
      ;;
    esac
    exit 0
  fi

  # For all other commands, use the original single-environment logic
  if [[ $# -lt 2 ]]; then
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
