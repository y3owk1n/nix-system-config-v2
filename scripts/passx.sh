#!/usr/bin/env bash
set -euo pipefail

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

secret_exists() {
  local path="$1"
  pass show "$path" >/dev/null 2>&1
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

  if [ -n "$value" ]; then
    printf "%s\n" "$value" | pass insert -m "$path" --force
  else
    pass insert -m "$path" --force
  fi
}

cmd_get() {
  local env="$1" key="$2"
  local project
  project=$(require_git_root)
  pass show "$project/$env/$key"
}

cmd_run() {
  local env="$1"
  shift || true
  local project
  project=$(require_git_root)

  mapfile -t keys < <(
    find "$PASSWORD_STORE_DIR/$project/$env" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/##; s#\.gpg\$##"
  )

  local k v name
  for k in "${keys[@]}"; do
    name="${k##*/}"
    v=$(pass show "$k")
    export "$name"="$v"
  done

  if [ "$#" -gt 0 ]; then
    exec "$@"
  else
    exec "$SHELL"
  fi
}

cmd_export() {
  local env="$1" output_file="${2:-.env}"
  local project
  project=$(require_git_root)

  mapfile -t keys < <(
    find "$PASSWORD_STORE_DIR/$project/$env" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/##; s#\.gpg\$##"
  )

  {
    for k in "${keys[@]}"; do
      name="${k##*/}"
      v=$(pass show "$k")
      printf "%s=%s\n" "$name" "$v"
    done
  } >"$output_file"

  echo "Exported secrets to $output_file"
}

cmd_import() {
  local env="$1"
  local file="$2"
  local mode="${3:-strict}" # strict | merge | overwrite
  local project
  project=$(require_git_root)

  while IFS='=' read -r key value; do
    [ -z "$key" ] && continue

    local path="$project/$env/$key"
    if secret_exists "$path"; then
      case "$mode" in
      strict)
        echo "Skipping existing $key (use merge/overwrite to change)"
        continue
        ;;
      merge)
        echo "Skipping existing $key (merge mode)"
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
  done <"$file"

  echo "Imported secrets from $file (mode: $mode)"
}

cmd_ls() {
  local env="$1"
  shift || true
  local show_values=false

  # Check for flags
  while [ $# -gt 0 ]; do
    case "$1" in
    --show) show_values=true ;;
    esac
    shift
  done

  local project
  project=$(require_git_root)

  mapfile -t keys < <(
    find "$PASSWORD_STORE_DIR/$project/$env" -type f -name '*.gpg' |
      sed -E "s#^$PASSWORD_STORE_DIR/$project/$env/##; s#\.gpg\$##"
  )

  if $show_values; then
    for key in "${keys[@]}"; do
      local v
      v=$(pass show "$project/$env/$key")
      printf "%s=%s\n" "$key" "$v"
    done
  else
    for key in "${keys[@]}"; do
      echo "$key"
    done
  fi
}

cmd_del() {
  local env="$1" key="$2"
  local project
  project=$(require_git_root)
  pass rm -f "$project/$env/$key"
}

# -------------------------------------------------------
# Dispatcher
# -------------------------------------------------------

usage() {
  echo "Usage: $0 <env> <command> [args...]"
  echo
  echo "Commands:"
  echo "  add <KEY> [VAL]      Add a new secret (fails if exists)"
  echo "  update <KEY> [VAL]   Update an existing secret"
  echo "  get <KEY>            Retrieve a secret"
  echo "  del <KEY>            Delete a secret"
  echo "  ls [--show]          List all secrets (with values if --show)"
  echo "  run [CMD...]         Run with secrets loaded into environment"
  echo "  export [FILE]        Export secrets to .env (default: .env)"
  echo "  import FILE [MODE]   Import from .env (MODE: strict|merge|overwrite)"
  exit 1
}

main() {
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
