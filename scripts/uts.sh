#!/usr/bin/env bash

# ============================================================================
# uts - All-in-one utility toolkit
# ============================================================================
# A modular CLI tool with category-based subcommands.
#
# Usage:
#   uts <category> <action> <input...> [options]
#
# Categories & Actions:
#   video    compress   Compress video files (mp4, mov, mkv, avi, webm)
#   image    compress   Compress images (png, jpg, webp, gif, bmp, tiff, heic, avif)
#   pdf      compress   Compress PDF documents
#   audio    compress   Compress audio files (wav, flac, aac, mp3, m4a, opus)
#   archive  compress   Compress directories/files into archives
#   convert  image      Convert between image formats
#   convert  video      Convert between video formats
#   convert  audio      Convert between audio formats
#   convert  pdf        Convert PDF to/from images
#   info                Show file info and suggestions
#
# Examples:
#   uts video compress input.mp4 -q high
#   uts image compress *.png --in-place
#   uts convert image photo.heic --to jpg
#   uts archive compress ./project/ --algorithm zstd
#   uts info video.mp4

set -euo pipefail

# Clean up spinner on exit
trap '_spinner stop 2>/dev/null' EXIT INT TERM

# -------------------------------------------------------
# Configuration
# -------------------------------------------------------

UTS_VERSION="1.0.0"
DEFAULT_QUALITY="medium"

# -------------------------------------------------------
# Colors & formatting
# -------------------------------------------------------

if [[ -t 1 ]]; then
  RED=$'\033[0;31m'
  GREEN=$'\033[0;32m'
  YELLOW=$'\033[1;33m'
  BLUE=$'\033[0;34m'
  CYAN=$'\033[0;36m'
  DIM=$'\033[2m'
  BOLD=$'\033[1m'
  NC=$'\033[0m'
else
  RED='' GREEN='' YELLOW='' BLUE='' CYAN='' DIM='' BOLD='' NC=''
fi

# -------------------------------------------------------
# Logging
# -------------------------------------------------------

log_info() { echo -e "${BLUE}▸${NC} $*"; }
log_success() { echo -e "${GREEN}✔${NC} $*"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $*" >&2; }
log_error() { echo -e "${RED}✖${NC} $*" >&2; }
log_verbose() { [[ ${VERBOSE:-false} == true ]] && echo -e "${DIM}  $*${NC}" >&2 || true; }
log_dry() { echo -e "${CYAN}[dry-run]${NC} $*"; }

# -------------------------------------------------------
# Utility functions
# -------------------------------------------------------

require_tool() {
  local tool="$1"
  local brew_pkg="${2:-$1}"
  if ! command -v "$tool" &>/dev/null; then
    if [[ ${DRY_RUN:-false} == true ]]; then
      log_warn "Tool '${tool}' not found (dry-run continues)"
      echo -e "  Install with: ${BOLD}brew install ${brew_pkg}${NC}" >&2
      return 0
    fi
    log_error "Required tool '${tool}' is not installed."
    echo -e "  Install with: ${BOLD}brew install ${brew_pkg}${NC}" >&2
    return 1
  fi
}

file_size() {
  local file="$1"
  local size
  if [[ $OSTYPE == "darwin"* ]]; then
    size=$(stat -f%z "$file" 2>/dev/null)
  else
    size=$(stat -c%s "$file" 2>/dev/null)
  fi
  # Fallback to wc -c if stat returns 0 or fails
  if [[ -z $size || $size == "0" ]]; then
    size=$(wc -c <"$file" 2>/dev/null)
  fi
  echo "${size:-0}"
}

human_size() {
  local bytes="$1"
  if ((bytes < 1024)); then
    echo "${bytes} B"
  elif ((bytes < 1048576)); then
    local kb=$((bytes / 1024))
    local frac=$(((bytes % 1024) * 10 / 1024))
    echo "${kb}.${frac} KB"
  elif ((bytes < 1073741824)); then
    local mb=$((bytes / 1048576))
    local frac=$(((bytes % 1048576) * 10 / 1048576))
    echo "${mb}.${frac} MB"
  else
    local gb=$((bytes / 1073741824))
    local rem=$(((bytes % 1073741824) * 100 / 1073741824))
    echo "${gb}.${rem} GB"
  fi
}

compression_ratio() {
  local original="$1"
  local compressed="$2"
  if ((original == 0)); then
    echo "0%"
    return
  fi
  local pct=$(((original - compressed) * 1000 / original))
  local whole=$((pct / 10))
  local frac=$((pct % 10))
  # Show (+X.X%) when file gets larger, (-X.X%) when smaller
  if ((pct < 0)); then
    whole=$((-whole))
    frac=$((-frac))
    echo "(+${whole}.${frac}%)"
  else
    echo "(-${whole}.${frac}%)"
  fi
}

output_path() {
  local input="$1"
  local suffix="$2"
  local dir base ext

  if [[ -n ${OUTPUT_DIR:-} ]]; then
    dir="$OUTPUT_DIR"
  else
    dir="$(dirname "$input")"
  fi

  base="$(basename "$input")"
  ext="${base##*.}"
  base="${base%.*}"

  # Handle hidden files (.gitignore, .env) where base becomes empty
  if [[ -z $base ]]; then
    base=".${ext}"
    ext=""
    echo "${dir}/${base}-${suffix}"
  else
    echo "${dir}/${base}-${suffix}.${ext}"
  fi
}

# --- Shared helpers ---

# Spinner for long-running operations. Only shown on TTY.
# Usage: _spinner start "Compressing..." && <command> && _spinner stop "Done"
_spinner_pid=""
_spinner() {
  local cmd="${1:-start}"
  local msg="${2:-}"

  case "$cmd" in
  start)
    # Only spin on TTY
    [[ ! -t 1 ]] && return 0
    local frames=('⠋' '⠙' '⠹' '⠸' '⠼' '⠴' '⠦' '⠧' '⠇' '⠏')
    (
      while true; do
        for frame in "${frames[@]}"; do
          printf "\r${CYAN}%s${NC} %s" "$frame" "$msg"
          sleep 0.1
        done
      done
    ) &
    _spinner_pid=$!
    ;;
  stop)
    [[ -z $_spinner_pid ]] && return 0
    kill "$_spinner_pid" 2>/dev/null || true
    wait "$_spinner_pid" 2>/dev/null || true
    _spinner_pid=""
    # Clear the spinner line
    printf "\r\033[K" 2>/dev/null || true
    ;;
  esac
}

# Detect ImageMagick command (magick or convert). Returns command name.
_get_magick_cmd() {
  if command -v magick &>/dev/null; then
    echo "magick"
  elif command -v convert &>/dev/null; then
    echo "convert"
  else
    return 1
  fi
}

# Map a quality level to a numeric value.
# Accepts presets (low/medium/high) or raw numeric values.
# Usage: val=$(_get_preset_val "$level" $low $med $high) || return 1
_get_preset_val() {
  local map_from="${1:-medium}" # low/medium/high or a number
  local low_val="${2:-60}" low_med="${3:-80}" high_val="${4:-90}"
  # If it's a number, use it directly
  if [[ $map_from =~ ^[0-9]+$ ]]; then
    echo "$map_from"
    return
  fi
  case "$map_from" in
  low) echo "$low_val" ;;
  medium) echo "$low_med" ;;
  high) echo "$high_val" ;;
  *)
    log_error "Invalid quality: $map_from (use low, medium, high, or a number)"
    return 1
    ;;
  esac
}

# Validate quality and return CRF + preset for video.
# Accepts presets (low/medium/high) or raw CRF values (0-51).
# Usage: read -r crf preset < <(_get_video_quality)
_get_video_quality() {
  local q="${QUALITY:-medium}"
  # If it's a number, use it as raw CRF with a sensible preset
  if [[ $q =~ ^[0-9]+$ ]]; then
    if ((q < 18)); then
      echo "$q slow"
    elif ((q < 28)); then
      echo "$q medium"
    else
      echo "$q fast"
    fi
    return
  fi
  case "$q" in
  low) echo "32 fast" ;;
  medium) echo "28 medium" ;;
  high) echo "23 slow" ;;
  *)
    log_error "Invalid quality: $q (use low, medium, high, or CRF 0-51)"
    return 1
    ;;
  esac
}

# Replace original with compressed file if --in-place is set.
_maybe_inplace() {
  local compressed="$1" original="$2"
  if [[ ${IN_PLACE:-false} == true && -f $compressed ]]; then
    mv "$compressed" "$original"
    log_verbose "Replaced original file"
  fi
}

# Expand glob patterns in arguments, even when quoted.
resolve_files() {
  # Runs in a subshell via < <(resolve_files ...), so no need to restore options
  shopt -s nullglob
  [[ ${RECURSIVE:-false} == true ]] && shopt -s globstar

  for arg in "$@"; do
    # Check if argument contains glob characters
    if [[ $arg == *"*"* || $arg == *"?"* || $arg == *"["* ]]; then
      # Expand the glob — unquoted $arg intentionally lets bash expand it
      local -a expanded=($arg)
      if [[ ${#expanded[@]} -eq 0 ]]; then
        log_warn "No files matched pattern: $arg"
      else
        printf '%s\n' "${expanded[@]}"
      fi
    else
      # Not a glob, pass through as-is
      echo "$arg"
    fi
  done
}

# -------------------------------------------------------
# Actions: compress
# -------------------------------------------------------

action_compress_video() {
  require_tool ffmpeg

  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No video files provided."
    return 1
  fi

  if [[ ${IN_PLACE:-false} == true && -n ${OUTPUT_DIR:-} ]]; then
    log_warn "--in-place ignored when used with --output"
    IN_PLACE=false
  fi

  # CRF and preset based on quality
  local crf preset
  read -r crf preset < <(_get_video_quality)

  log_info "Video compression: quality=${BOLD}${QUALITY:-medium}${NC} (crf=${crf}, preset=${preset})"

  local i=0
  local total=${#files[@]}
  for file in "${files[@]}"; do
    ((i++)) || true
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    local out
    out="$(output_path "$file" "small")"

    if [[ $file == "$out" ]]; then
      log_warn "Skipping: input and output path are the same for $file"
      continue
    fi

    local orig_size
    orig_size="$(file_size "$file")"

    log_info "Compressing: ${BOLD}[$i/$total] $(basename "$file")${NC} ($(human_size "$orig_size"))"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would compress $file -> $out (crf=$crf, preset=$preset)"
      continue
    fi

    mkdir -p "$(dirname "$out")"
    _spinner start "[$i/$total] $(basename "$file")..."
    local convert_ok=true
    ffmpeg -i "$file" \
      -vcodec libx265 \
      -crf "$crf" \
      -preset "$preset" \
      -acodec aac \
      -b:a 128k \
      -movflags +faststart \
      -y "$out" \
      2>/dev/null || convert_ok=false
    _spinner stop

    if [[ $convert_ok == true && -f $out ]]; then
      local new_size
      new_size="$(file_size "$out")"
      local ratio
      ratio="$(compression_ratio "$orig_size" "$new_size")"
      log_success "$(basename "$file"): $(human_size "$orig_size") -> $(human_size "$new_size") ${GREEN}${ratio}${NC}"
      _maybe_inplace "$out" "$file"
    else
      log_error "Compression failed: $(basename "$file")"
    fi
  done

  if [[ $total -gt 1 ]]; then
    log_success "Compressed ${BOLD}$total${NC} video files"
  fi
}

action_compress_image() {
  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No image files provided."
    return 1
  fi

  if [[ ${IN_PLACE:-false} == true && -n ${OUTPUT_DIR:-} ]]; then
    log_warn "--in-place ignored when used with --output"
    IN_PLACE=false
  fi

  # Quality mapping: 1-100 scale used by most tools
  local quality_val
  if [[ ${QUALITY:-medium} =~ ^[0-9]+$ ]]; then
    if ((QUALITY < 1 || QUALITY > 100)); then
      log_error "Invalid image quality: $QUALITY (use 1-100, or low/medium/high)"
      return 1
    fi
  fi
  quality_val=$(_get_preset_val "${QUALITY:-medium}" 60 80 90) || return 1

  log_info "Image compression: quality=${BOLD}${QUALITY:-medium}${NC} (value=${quality_val})"

  local i=0
  local total=${#files[@]}
  for file in "${files[@]}"; do
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    ((i++)) || true
    local ext="${file##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    local out
    out="$(output_path "$file" "small")"

    if [[ $file == "$out" ]]; then
      log_warn "Skipping: input and output path are the same for $file"
      continue
    fi

    local orig_size
    orig_size="$(file_size "$file")"

    log_info "Compressing: ${BOLD}[$i/$total] $(basename "$file")${NC} ($(human_size "$orig_size"))"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would compress $file -> $out (format=$ext, quality=$quality_val)"
      continue
    fi

    mkdir -p "$(dirname "$out")"
    local compressed_out="$out"
    _spinner start "[$i/$total] $(basename "$file")..."
    local convert_ok=true
    case "$ext" in
    png)
      _compress_png "$file" "$out" "$quality_val" || convert_ok=false
      ;;
    jpg | jpeg)
      _compress_jpeg "$file" "$out" "$quality_val" || convert_ok=false
      ;;
    webp)
      _compress_webp "$file" "$out" "$quality_val" || convert_ok=false
      ;;
    gif)
      _compress_gif "$file" "$out" || convert_ok=false
      ;;
    bmp | tiff | tif)
      _compress_generic "$file" "$out" "$quality_val" || convert_ok=false
      ;;
    heic | heif)
      compressed_out=$(_compress_heic "$file" "$out" "$quality_val") || convert_ok=false
      ;;
    avif | avifs)
      compressed_out=$(_compress_avif "$file" "$out" "$quality_val") || convert_ok=false
      ;;
    *)
      log_warn "Unsupported image format: $ext — skipping $file"
      continue
      ;;
    esac
    _spinner stop

    if [[ $convert_ok == true && -f $compressed_out ]]; then
      local new_size
      new_size="$(file_size "$compressed_out")"
      local ratio
      ratio="$(compression_ratio "$orig_size" "$new_size")"

      log_success "$(basename "$file"): $(human_size "$orig_size") -> $(human_size "$new_size") ${GREEN}${ratio}${NC}"

      _maybe_inplace "$compressed_out" "$file"
    else
      log_error "Compression failed: $(basename "$file")"
    fi
  done

  if [[ $total -gt 1 ]]; then
    log_success "Compressed ${BOLD}$total${NC} image files"
  fi
}

_compress_png() {
  local file="$1" out="$2" quality="$3"

  # Try pngquant first (lossy, very effective)
  if command -v pngquant &>/dev/null; then
    log_verbose "Using pngquant (lossy)"
    pngquant --quality="$((quality - 10))-$quality" --speed 1 --strip --output "$out" -- "$file"
    # Follow up with optipng for additional lossless optimization
    if command -v optipng &>/dev/null && [[ -f $out ]]; then
      log_verbose "Following up with optipng (lossless)"
      optipng -quiet -o2 "$out" 2>/dev/null
    fi
  elif command -v optipng &>/dev/null; then
    log_verbose "Using optipng (lossless only)"
    cp "$file" "$out"
    optipng -quiet -o2 "$out" 2>/dev/null
  else
    local magick_cmd
    if magick_cmd=$(_get_magick_cmd); then
      log_verbose "Using ImageMagick"
      "$magick_cmd" "$file" -quality "$quality" -strip "$out"
    else
      log_error "No PNG compression tool found. Install pngquant: brew install pngquant"
      return 1
    fi
  fi
}

_compress_jpeg() {
  local file="$1" out="$2" quality="$3"

  if command -v jpegoptim &>/dev/null; then
    log_verbose "Using jpegoptim"
    cp "$file" "$out"
    jpegoptim --max="$quality" --strip-all --quiet "$out"
  else
    local magick_cmd
    if magick_cmd=$(_get_magick_cmd); then
      log_verbose "Using ImageMagick"
      "$magick_cmd" "$file" -quality "$quality" -strip "$out"
    else
      log_error "No JPEG compression tool found. Install jpegoptim: brew install jpegoptim"
      return 1
    fi
  fi
}

_compress_webp() {
  local file="$1" out="$2" quality="$3"

  if command -v cwebp &>/dev/null; then
    log_verbose "Using cwebp"
    cwebp -q "$quality" -m 6 "$file" -o "$out" 2>/dev/null
  else
    local magick_cmd
    if magick_cmd=$(_get_magick_cmd); then
      log_verbose "Using ImageMagick"
      "$magick_cmd" "$file" -quality "$quality" "$out"
    else
      log_error "No WebP compression tool found. Install webp: brew install webp"
      return 1
    fi
  fi
}

_compress_gif() {
  local file="$1" out="$2"

  if command -v gifsicle &>/dev/null; then
    log_verbose "Using gifsicle"
    gifsicle -O3 --lossy=80 "$file" -o "$out"
  else
    local magick_cmd
    if magick_cmd=$(_get_magick_cmd); then
      log_verbose "Using ImageMagick"
      "$magick_cmd" "$file" -layers Optimize "$out"
    else
      log_error "No GIF compression tool found. Install gifsicle: brew install gifsicle"
      return 1
    fi
  fi
}

_compress_generic() {
  local file="$1" out="$2" quality="$3"

  local magick_cmd
  if magick_cmd=$(_get_magick_cmd); then
    log_verbose "Using ImageMagick"
    "$magick_cmd" "$file" -quality "$quality" -strip "$out"
  else
    log_error "No image compression tool found. Install imagemagick: brew install imagemagick"
    return 1
  fi
}

_compress_heic() {
  local file="$1" out="$2" quality="$3"

  # HEIC is already a lossy format — convert to JPEG for best results
  out="${out%.*}.jpg"

  if command -v heif-convert &>/dev/null; then
    log_verbose "Using heif-convert (HEIC -> JPEG)"
    heif-convert -q "$quality" "$file" "$out"
  else
    local magick_cmd
    if magick_cmd=$(_get_magick_cmd); then
      log_verbose "Using ImageMagick (HEIC -> JPEG)"
      _compress_generic "$file" "$out" "$quality"
    else
      log_error "No HEIC tool found. Install: brew install libheif imagemagick"
      return 1
    fi
  fi

  # Return actual output path (extension may have changed)
  echo "$out"
}

_compress_avif() {
  local file="$1" out="$2" quality="$3"

  # AVIF output as AVIF — convert to .avif extension
  out="${out%.*}.avif"

  if command -v cavif &>/dev/null; then
    log_verbose "Using cavif"
    cavif -q "$quality" -s 6 -o "$out" "$file"
  elif command -v avifenc &>/dev/null; then
    log_verbose "Using avifenc (libavif)"
    # Map 1-100 quality to avifenc 0-63 quantizer range
    local quantizer
    quantizer=$(((100 - quality) * 63 / 100))
    avifenc --min 0 --max "$quantizer" -s 6 "$file" "$out"
  else
    local magick_cmd
    if magick_cmd=$(_get_magick_cmd); then
      log_verbose "Using ImageMagick"
      "$magick_cmd" "$file" -quality "$quality" -strip "$out"
    else
      log_error "No AVIF tool found. Install: brew install cavif libavif imagemagick"
      return 1
    fi
  fi

  # Return actual output path (extension may have changed)
  echo "$out"
}

action_compress_pdf() {
  require_tool gs ghostscript

  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No PDF files provided."
    return 1
  fi

  if [[ ${IN_PLACE:-false} == true && -n ${OUTPUT_DIR:-} ]]; then
    log_warn "--in-place ignored when used with --output"
    IN_PLACE=false
  fi

  # Ghostscript settings based on quality
  local pdf_settings=""
  local custom_dpi=""
  if [[ ${QUALITY:-medium} =~ ^[0-9]+$ ]]; then
    # Numeric DPI value — skip preset, only use resolution overrides
    custom_dpi="${QUALITY:-medium}"
    log_info "PDF compression: quality=${BOLD}${custom_dpi} DPI${NC} (custom)"
  else
    case "${QUALITY:-medium}" in
    low) pdf_settings="/screen" ;;
    medium) pdf_settings="/ebook" ;;
    high) pdf_settings="/printer" ;;
    *)
      log_error "Invalid quality: ${QUALITY} (use low, medium, high, or a DPI value)"
      return 1
      ;;
    esac
    log_info "PDF compression: quality=${BOLD}${QUALITY:-medium}${NC} (preset=${pdf_settings})"
  fi

  local i=0
  local total=${#files[@]}
  for file in "${files[@]}"; do
    ((i++)) || true
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    local out
    out="$(output_path "$file" "small")"

    if [[ $file == "$out" ]]; then
      log_warn "Skipping: input and output path are the same for $file"
      continue
    fi

    local orig_size
    orig_size="$(file_size "$file")"

    log_info "Compressing: ${BOLD}[$i/$total] $(basename "$file")${NC} ($(human_size "$orig_size"))"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would compress $file -> $out (settings=$pdf_settings)"
      continue
    fi

    mkdir -p "$(dirname "$out")"
    local gs_args=(
      -sDEVICE=pdfwrite
      -dCompatibilityLevel=1.4
      -dNOPAUSE
      -dQUIET
      -dBATCH
    )
    if [[ -n $custom_dpi ]]; then
      # Custom DPI: only set resolution overrides, skip preset
      gs_args+=(-dColorImageResolution="$custom_dpi")
      gs_args+=(-dGrayImageResolution="$custom_dpi")
      gs_args+=(-dMonoImageResolution="$custom_dpi")
    else
      gs_args+=(-dPDFSETTINGS="$pdf_settings")
      gs_args+=(-dColorImageResolution=150)
      gs_args+=(-dGrayImageResolution=150)
      gs_args+=(-dMonoImageResolution=150)
    fi
    _spinner start "[$i/$total] $(basename "$file")..."
    local convert_ok=true
    gs "${gs_args[@]}" -sOutputFile="$out" "$file" || convert_ok=false
    _spinner stop

    if [[ $convert_ok == true && -f $out ]]; then
      local new_size
      new_size="$(file_size "$out")"
      local ratio
      ratio="$(compression_ratio "$orig_size" "$new_size")"

      log_success "$(basename "$file"): $(human_size "$orig_size") -> $(human_size "$new_size") ${GREEN}${ratio}${NC}"

      _maybe_inplace "$out" "$file"
    else
      log_error "Compression failed: $(basename "$file")"
    fi
  done

  if [[ $total -gt 1 ]]; then
    log_success "Compressed ${BOLD}$total${NC} PDF files"
  fi
}

action_compress_audio() {
  require_tool ffmpeg

  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No audio files provided."
    return 1
  fi

  if [[ ${IN_PLACE:-false} == true && -n ${OUTPUT_DIR:-} ]]; then
    log_warn "--in-place ignored when used with --output"
    IN_PLACE=false
  fi

  # Bitrate based on quality
  local bitrate codec="aac" ext_hint="m4a"
  if [[ ${QUALITY:-medium} =~ ^[0-9]+$ ]]; then
    bitrate="${QUALITY}k"
  else
    bitrate=$(_get_preset_val "${QUALITY:-medium}" 96 128 192) || return 1
    bitrate="${bitrate}k"
  fi

  log_info "Audio compression: quality=${BOLD}${QUALITY:-medium}${NC} (bitrate=${bitrate}, codec=${codec})"

  local i=0
  local total=${#files[@]}
  for file in "${files[@]}"; do
    ((i++)) || true
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    local out
    out="$(output_path "$file" "small")"
    # Override extension for codec-appropriate container
    out="${out%.*}.${ext_hint}"

    if [[ $file == "$out" ]]; then
      log_warn "Skipping: input and output path are the same for $file"
      continue
    fi

    local orig_size
    orig_size="$(file_size "$file")"

    log_info "Compressing: ${BOLD}[$i/$total] $(basename "$file")${NC} ($(human_size "$orig_size"))"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would compress $file -> $out (bitrate=$bitrate, codec=$codec)"
      continue
    fi

    mkdir -p "$(dirname "$out")"
    _spinner start "[$i/$total] $(basename "$file")..."
    local convert_ok=true
    ffmpeg -i "$file" \
      -c:a "$codec" \
      -b:a "$bitrate" \
      -y "$out" \
      2>/dev/null || convert_ok=false
    _spinner stop

    if [[ $convert_ok == true && -f $out ]]; then
      local new_size
      new_size="$(file_size "$out")"
      local ratio
      ratio="$(compression_ratio "$orig_size" "$new_size")"
      log_success "$(basename "$file"): $(human_size "$orig_size") -> $(human_size "$new_size") ${GREEN}${ratio}${NC}"
      _maybe_inplace "$out" "$file"
    else
      log_error "Compression failed: $(basename "$file")"
    fi
  done

  if [[ $total -gt 1 ]]; then
    log_success "Compressed ${BOLD}$total${NC} audio files"
  fi
}

action_compress_archive() {
  local algorithm="${ALGORITHM:-auto}"

  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No files or directories provided."
    return 1
  fi

  log_info "Archive compression: algorithm=${BOLD}${algorithm}${NC}"

  # Determine the archive name
  local archive_name
  if [[ ${#files[@]} -eq 1 ]]; then
    # Single input: use its name
    local first_input="${files[0]}"
    if [[ -d $first_input ]]; then
      archive_name="$(basename "$first_input")"
    else
      archive_name="$(basename "${first_input%.*}")"
    fi
  else
    # Multiple inputs: use the first file's parent directory name
    local parent_dir
    parent_dir="$(dirname "${files[0]}")"
    if [[ $parent_dir == "." ]]; then
      archive_name="archive"
    else
      archive_name="$(basename "$parent_dir")"
    fi
  fi

  local out_dir="${OUTPUT_DIR:-.}"
  mkdir -p "$out_dir"

  if [[ ${DRY_RUN:-false} == true ]]; then
    log_dry "Would create archive from: ${files[*]}"
    log_dry "Output directory: $out_dir"
    return 0
  fi

  if [[ $algorithm == "auto" ]]; then
    _archive_auto "$out_dir" "$archive_name" "${files[@]}"
  else
    _archive_with "$algorithm" "$out_dir" "$archive_name" "${files[@]}"
  fi
}

_archive_auto() {
  local out_dir="$1" name="$2"
  shift 2

  local best_algo="" best_size=999999999999 best_file=""

  # Try available algorithms and pick the smallest
  local algorithms=("zstd" "xz" "brotli" "gzip")

  for algo in "${algorithms[@]}"; do
    local candidate="${out_dir}/${name}.tar.${algo}"
    _archive_with "$algo" "$out_dir" "$name" --quiet "$@"
    if [[ -f $candidate ]]; then
      local size
      size="$(file_size "$candidate")"
      if ((size < best_size)); then
        # Remove previous best if it exists
        [[ -n $best_file && -f $best_file ]] && rm -f "$best_file"
        best_size="$size"
        best_algo="$algo"
        best_file="$candidate"
      else
        rm -f "$candidate"
      fi
    fi
  done

  if [[ -n $best_file ]]; then
    log_success "Best algorithm: ${BOLD}${best_algo}${NC} -> $(basename "$best_file") ($(human_size "$best_size"))"
  else
    log_error "No compression algorithms available. Install one of: zstd, xz, brotli, gzip"
    return 1
  fi
}

_archive_with() {
  local algo="$1" out_dir="$2" name="$3"
  shift 3
  local quiet=false
  [[ ${1:-} == "--quiet" ]] && quiet=true && shift

  local output
  case "$algo" in
  gzip | gz) output="${out_dir}/${name}.tar.gz" ;;
  zstd | zst) output="${out_dir}/${name}.tar.zst" ;;
  xz) output="${out_dir}/${name}.tar.xz" ;;
  brotli | br) output="${out_dir}/${name}.tar.br" ;;
  pigz) output="${out_dir}/${name}.tar.pigz" ;;
  zip) output="${out_dir}/${name}.zip" ;;
  *)
    log_error "Unknown algorithm: $algo (use gzip, zstd, xz, brotli, pigz, zip)"
    return 1
    ;;
  esac

  case "$algo" in
  gzip | gz)
    tar -czf "$output" "$@"
    ;;
  zstd | zst)
    if command -v zstd &>/dev/null; then
      tar --zstd -cf "$output" "$@"
    else
      [[ $quiet == false ]] && log_warn "zstd not found, skipping. Install: brew install zstd"
      return 1
    fi
    ;;
  xz)
    tar -cJf "$output" "$@"
    ;;
  brotli | br)
    if command -v brotli &>/dev/null; then
      tar -cf - "$@" | brotli -c >"$output"
    else
      [[ $quiet == false ]] && log_warn "brotli not found, skipping. Install: brew install brotli"
      return 1
    fi
    ;;
  pigz)
    if command -v pigz &>/dev/null; then
      tar -cf - "$@" | pigz -c >"$output"
    else
      [[ $quiet == false ]] && log_warn "pigz not found, skipping. Install: brew install pigz"
      return 1
    fi
    ;;
  zip)
    if command -v zip &>/dev/null; then
      zip -r "$output" "$@" -q
    else
      [[ $quiet == false ]] && log_warn "zip not found. Install: brew install zip"
      return 1
    fi
    ;;
  *)
    log_error "Unknown algorithm: $algo (use gzip, zstd, xz, brotli, pigz, zip)"
    return 1
    ;;
  esac

  [[ $quiet == false ]] && log_success "Created: $(basename "$output") ($(human_size "$(file_size "$output")"))"
}

# -------------------------------------------------------
# Actions: convert
# -------------------------------------------------------

convert_output_path() {
  local input="$1" target_ext="$2"
  local dir base

  if [[ -n ${OUTPUT_DIR:-} ]]; then
    dir="$OUTPUT_DIR"
  else
    dir="$(dirname "$input")"
  fi

  base="$(basename "$input")"
  base="${base%.*}"

  echo "${dir}/${base}.${target_ext}"
}

action_convert_image() {
  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No image files provided."
    return 1
  fi

  if [[ ${IN_PLACE:-false} == true && -n ${OUTPUT_DIR:-} ]]; then
    log_warn "--in-place ignored when used with --output"
    IN_PLACE=false
  fi

  local target="${TARGET_FORMAT:-}"
  if [[ -z $target ]]; then
    log_error "Missing --to <format>. Examples: --to jpg, --to webp, --to png, --to avif"
    return 1
  fi

  # Normalize target format
  target="$(echo "$target" | tr '[:upper:]' '[:lower:]')"
  # Handle common aliases
  case "$target" in
  jpeg) target="jpg" ;;
  esac

  # Validate target format
  case "$target" in
  jpg | png | webp | gif | bmp | tiff | tif | avif)
    ;;
  *)
    log_error "Unsupported target format: .$target (use jpg, png, webp, gif, bmp, tiff, avif)"
    return 1
    ;;
  esac

  # Quality mapping: 1-100 scale used by most tools
  local quality_val
  if [[ ${QUALITY:-medium} =~ ^[0-9]+$ ]]; then
    if ((QUALITY < 1 || QUALITY > 100)); then
      log_error "Invalid image quality: $QUALITY (use 1-100, or low/medium/high)"
      return 1
    fi
  fi
  quality_val=$(_get_preset_val "${QUALITY:-medium}" 60 80 90) || return 1

  log_info "Image conversion: target=${BOLD}${target}${NC}, quality=${QUALITY:-medium} (value=${quality_val})"

  local i=0
  local total=${#files[@]}
  for file in "${files[@]}"; do
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    ((i++)) || true
    local ext="${file##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    # Skip if already in target format
    if [[ $ext == "$target" ]]; then
      log_warn "Already .$target, skipping: $(basename "$file")"
      continue
    fi

    local out
    out="$(convert_output_path "$file" "$target")"

    if [[ $file == "$out" ]]; then
      log_warn "Skipping: input and output path are the same for $file"
      continue
    fi

    local orig_size
    orig_size="$(file_size "$file")"

    log_info "Converting: ${BOLD}[$i/$total] $(basename "$file")${NC} (.${ext} -> .${target}, $(human_size "$orig_size"))"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would convert $file -> $out"
      continue
    fi

    mkdir -p "$(dirname "$out")"
    _spinner start "[$i/$total] $(basename "$file")..."
    local convert_ok=true
    local magick_cmd
    if magick_cmd=$(_get_magick_cmd); then
      log_verbose "Using ImageMagick"
      "$magick_cmd" "$file" -quality "$quality_val" -strip "$out" || convert_ok=false
    elif [[ $OSTYPE == "darwin"* ]] && command -v sips &>/dev/null; then
      log_verbose "Using sips"
      local sips_format
      case "$target" in
      jpg) sips_format="jpeg" ;;
      *) sips_format="$target" ;;
      esac
      sips -s format "$sips_format" "$file" --out "$out" 2>/dev/null || convert_ok=false
    else
      _spinner stop
      log_error "No image conversion tool found. Install: brew install imagemagick"
      return 1
    fi
    _spinner stop

    if [[ $convert_ok == true && -f $out ]]; then
      local new_size
      new_size="$(file_size "$out")"
      log_success "$(basename "$file"): $(human_size "$orig_size") -> $(human_size "$new_size")"
      _maybe_inplace "$out" "$file"
    else
      log_error "Conversion failed: $(basename "$file")"
    fi
  done

  if [[ $total -gt 1 ]]; then
    log_success "Converted ${BOLD}$total${NC} image files"
  fi
}

action_convert_video() {
  require_tool ffmpeg

  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No video files provided."
    return 1
  fi

  if [[ ${IN_PLACE:-false} == true && -n ${OUTPUT_DIR:-} ]]; then
    log_warn "--in-place ignored when used with --output"
    IN_PLACE=false
  fi

  local target="${TARGET_FORMAT:-}"
  if [[ -z $target ]]; then
    log_error "Missing --to <format>. Examples: --to mp4, --to mkv, --to webm"
    return 1
  fi

  target="$(echo "$target" | tr '[:upper:]' '[:lower:]')"

  # Validate target format
  case "$target" in
  mp4 | mkv | webm | mov | avi | flv)
    ;;
  *)
    log_error "Unsupported target format: .$target (use mp4, mkv, webm, mov, avi, flv)"
    return 1
    ;;
  esac

  # Codec mapping based on target format
  local vcodec acodec
  case "$target" in
  mp4 | mov)
    vcodec="libx264"
    acodec="aac"
    ;;
  mkv)
    vcodec="libx265"
    acodec="aac"
    ;;
  webm)
    vcodec="libvpx-vp9"
    acodec="libopus"
    ;;
  avi)
    vcodec="libx264"
    acodec="mp3"
    ;;
  flv)
    vcodec="libx264"
    acodec="aac"
    ;;
  esac

  log_info "Video conversion: target=${BOLD}${target}${NC} (${vcodec}/${acodec})"

  local i=0
  local total=${#files[@]}
  for file in "${files[@]}"; do
    ((i++)) || true
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    local ext="${file##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    # Skip if already in target format
    if [[ $ext == "$target" ]]; then
      log_warn "Already .$target, skipping: $(basename "$file")"
      continue
    fi

    local out
    out="$(convert_output_path "$file" "$target")"

    if [[ $file == "$out" ]]; then
      log_warn "Skipping: input and output path are the same for $file"
      continue
    fi

    local orig_size
    orig_size="$(file_size "$file")"

    log_info "Converting: ${BOLD}[$i/$total] $(basename "$file")${NC} (.${ext} -> .${target}, $(human_size "$orig_size"))"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would convert $file -> $out (${vcodec}/${acodec})"
      continue
    fi

    mkdir -p "$(dirname "$out")"
    _spinner start "[$i/$total] $(basename "$file")..."
    local convert_ok=true
    ffmpeg -i "$file" \
      -vcodec "$vcodec" \
      -acodec "$acodec" \
      -y "$out" \
      2>/dev/null || convert_ok=false
    _spinner stop

    if [[ $convert_ok == true && -f $out ]]; then
      local new_size
      new_size="$(file_size "$out")"
      log_success "$(basename "$file"): $(human_size "$orig_size") -> $(human_size "$new_size")"
      _maybe_inplace "$out" "$file"
    else
      log_error "Conversion failed: $(basename "$file")"
    fi
  done

  if [[ $total -gt 1 ]]; then
    log_success "Converted ${BOLD}$total${NC} video files"
  fi
}

action_convert_audio() {
  require_tool ffmpeg

  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No audio files provided."
    return 1
  fi

  if [[ ${IN_PLACE:-false} == true && -n ${OUTPUT_DIR:-} ]]; then
    log_warn "--in-place ignored when used with --output"
    IN_PLACE=false
  fi

  local target="${TARGET_FORMAT:-}"
  if [[ -z $target ]]; then
    log_error "Missing --to <format>. Examples: --to mp3, --to aac, --to wav, --to flac"
    return 1
  fi

  target="$(echo "$target" | tr '[:upper:]' '[:lower:]')"

  # Validate target format
  case "$target" in
  mp3 | aac | m4a | wav | flac | opus | ogg)
    ;;
  *)
    log_error "Unsupported target format: .$target (use mp3, aac, m4a, wav, flac, opus, ogg)"
    return 1
    ;;
  esac

  # Codec and extension mapping
  local codec ext_hint
  case "$target" in
  mp3)
    codec="libmp3lame"
    ext_hint="mp3"
    ;;
  aac)
    codec="aac"
    ext_hint="m4a"
    ;;
  m4a)
    codec="aac"
    ext_hint="m4a"
    ;;
  wav)
    codec="pcm_s16le"
    ext_hint="wav"
    ;;
  flac)
    codec="flac"
    ext_hint="flac"
    ;;
  opus)
    codec="libopus"
    ext_hint="opus"
    ;;
  ogg)
    codec="libvorbis"
    ext_hint="ogg"
    ;;
  esac

  # Bitrate based on quality
  local bitrate
  bitrate=$(_get_preset_val "${QUALITY:-medium}" 96 128 192) || return 1
  bitrate="${bitrate}k"

  log_info "Audio conversion: target=${BOLD}${target}${NC} (${codec}, ${bitrate})"

  local i=0
  local total=${#files[@]}
  for file in "${files[@]}"; do
    ((i++)) || true
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    local ext="${file##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    # Skip if already in target format
    if [[ $ext == "$ext_hint" ]]; then
      log_warn "Already .$ext_hint, skipping: $(basename "$file")"
      continue
    fi

    local out
    out="$(convert_output_path "$file" "$ext_hint")"

    if [[ $file == "$out" ]]; then
      log_warn "Skipping: input and output path are the same for $file"
      continue
    fi

    local orig_size
    orig_size="$(file_size "$file")"

    log_info "Converting: ${BOLD}[$i/$total] $(basename "$file")${NC} (.${ext} -> .${ext_hint}, $(human_size "$orig_size"))"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would convert $file -> $out (${codec}, ${bitrate})"
      continue
    fi

    mkdir -p "$(dirname "$out")"
    _spinner start "[$i/$total] $(basename "$file")..."
    local convert_ok=true
    ffmpeg -i "$file" \
      -c:a "$codec" \
      -b:a "$bitrate" \
      -y "$out" \
      2>/dev/null || convert_ok=false
    _spinner stop

    if [[ $convert_ok == true && -f $out ]]; then
      local new_size
      new_size="$(file_size "$out")"
      log_success "$(basename "$file"): $(human_size "$orig_size") -> $(human_size "$new_size")"
      _maybe_inplace "$out" "$file"
    else
      log_error "Conversion failed: $(basename "$file")"
    fi
  done

  if [[ $total -gt 1 ]]; then
    log_success "Converted ${BOLD}$total${NC} audio files"
  fi
}

action_convert_pdf() {
  local target="${TARGET_FORMAT:-}"
  if [[ -z $target ]]; then
    log_error "Missing --to <format>. Examples: --to jpg, --to png, --to pdf"
    return 1
  fi

  target="$(echo "$target" | tr '[:upper:]' '[:lower:]')"

  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No files provided."
    return 1
  fi

  # Detect direction: images->PDF or PDF->images
  local first_ext="${files[0]##*.}"
  first_ext="$(echo "$first_ext" | tr '[:upper:]' '[:lower:]')"

  case "$first_ext" in
  pdf)
    # PDF -> images
    _convert_pdf_to_images "$target" "${files[@]}"
    ;;
  jpg | jpeg | png | webp | gif | bmp | tiff | tif)
    # Images -> PDF
    _convert_images_to_pdf "$target" "${files[@]}"
    ;;
  *)
    log_error "Unsupported input format: .$first_ext (provide PDF or images)"
    return 1
    ;;
  esac
}

_convert_pdf_to_images() {
  local target="$1"
  shift
  local -a files=("$@")

  case "$target" in
  jpg | jpeg | png)
    ;;
  *)
    log_error "Unsupported target format for PDF: .$target (use jpg or png)"
    return 1
    ;;
  esac

  # Quality/DPI based on quality preset
  local dpi
  dpi=$(_get_preset_val "${QUALITY:-medium}" 150 300 400) || return 1

  log_info "PDF -> images: target=${BOLD}${target}${NC}, dpi=${dpi}"

  local i=0
  local total=${#files[@]}
  for file in "${files[@]}"; do
    ((i++)) || true
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    local orig_size
    orig_size="$(file_size "$file")"

    log_info "Converting: ${BOLD}[$i/$total] $(basename "$file")${NC} (pdf -> .${target}, $(human_size "$orig_size"))"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would convert $file -> ${target} images (dpi=${dpi})"
      continue
    fi

    # Output directory for multi-page PDFs
    local out_dir
    if [[ -n ${OUTPUT_DIR:-} ]]; then
      out_dir="$OUTPUT_DIR"
    else
      local base="$(basename "$file")"
      base="${base%.*}"
      out_dir="$(dirname "$file")/${base}"
    fi
    mkdir -p "$out_dir"

    if command -v pdftoppm &>/dev/null; then
      log_verbose "Using pdftoppm"
      local img_ext="$target"
      [[ $target == "jpg" ]] && img_ext="jpg"
      pdftoppm -"$img_ext" -r "$dpi" "$file" "$out_dir/page"
    else
      local magick_cmd
      if magick_cmd=$(_get_magick_cmd); then
        log_verbose "Using ImageMagick"
        "$magick_cmd" -density "$dpi" "$file" "$out_dir/page.%03d.$target"
      else
        log_error "No PDF conversion tool found. Install: brew install poppler imagemagick"
        return 1
      fi
    fi

    local count
    count=$(find "$out_dir" -maxdepth 1 -name "page*.${target}" 2>/dev/null | wc -l | tr -d ' ')
    log_success "$(basename "$file"): $count pages converted to $out_dir/"
  done
}

_convert_images_to_pdf() {
  local target="$1"
  shift
  local -a files=("$@")

  # Validate target is PDF
  case "$target" in
  pdf)
    ;;
  *)
    log_error "Cannot combine images into .$target. Use --to pdf"
    return 1
    ;;
  esac

  log_info "Images -> PDF: ${BOLD}${#files[@]}${NC} images"

  # Validate all inputs are images
  local -a valid_files=()
  for file in "${files[@]}"; do
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi
    local ext="${file##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    case "$ext" in
    jpg | jpeg | png | webp | gif | bmp | tiff | tif)
      valid_files+=("$file")
      ;;
    *)
      log_warn "Skipping non-image file: $file"
      ;;
    esac
  done

  if [[ ${#valid_files[@]} -eq 0 ]]; then
    log_error "No valid image files provided."
    return 1
  fi

  # Sort files for predictable page order
  mapfile -t valid_files < <(printf '%s\n' "${valid_files[@]}" | sort)

  # Determine output path (use first image's base name)
  local out
  local base_name
  base_name="$(basename "${valid_files[0]}")"
  base_name="${base_name%.*}"
  if [[ -n ${OUTPUT_DIR:-} ]]; then
    mkdir -p "$OUTPUT_DIR"
    out="${OUTPUT_DIR}/${base_name}.pdf"
  else
    local dir="$(dirname "${valid_files[0]}")"
    out="${dir}/${base_name}.pdf"
  fi

  if [[ ${DRY_RUN:-false} == true ]]; then
    log_dry "Would combine ${#valid_files[@]} images -> $out"
    for f in "${valid_files[@]}"; do
      log_dry "  $f"
    done
    return 0
  fi

  # Combine images into PDF
  local magick_cmd
  if magick_cmd=$(_get_magick_cmd); then
    log_verbose "Using ImageMagick"
    "$magick_cmd" "${valid_files[@]}" "$out"
  else
    log_error "No image-to-PDF tool found. Install: brew install imagemagick"
    return 1
  fi

  if [[ -f $out ]]; then
    local new_size
    new_size="$(file_size "$out")"
    log_success "${#valid_files[@]} images -> $(basename "$out") ($(human_size "$new_size"))"
  fi
}

# -------------------------------------------------------
# Actions: list
# -------------------------------------------------------

action_list_archive() {
  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No archive files provided."
    return 1
  fi

  for file in "${files[@]}"; do
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    local ext="${file##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    echo ""
    echo -e "${BOLD}$(basename "$file")${NC}"

    _spinner start "Listing $(basename "$file")..."
    case "$ext" in
    zip)
      if command -v unzip &>/dev/null; then
        unzip -l "$file"
      else
        _spinner stop
        log_error "unzip not found. Install: brew install unzip"
        return 1
      fi
      ;;
    tar)
      tar tf "$file"
      ;;
    gz | tgz)
      tar tzf "$file"
      ;;
    zst | zstd)
      if command -v zstd &>/dev/null; then
        zstd -dc "$file" | tar tf -
      else
        _spinner stop
        log_error "zstd not found. Install: brew install zstd"
        return 1
      fi
      ;;
    xz | txz)
      xz -dc "$file" | tar tf -
      ;;
    bz2 | tbz2)
      bzip2 -dc "$file" | tar tf -
      ;;
    *)
      _spinner stop
      log_error "Unsupported archive format: .$ext (use zip, tar, gz, zst, xz, bz2)"
      return 1
      ;;
    esac
    _spinner stop
  done
}

# -------------------------------------------------------
# Actions: extract
# -------------------------------------------------------

action_extract_archive() {
  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No archive files provided."
    return 1
  fi

  for file in "${files[@]}"; do
    if [[ ! -f $file ]]; then
      log_warn "File not found: $file"
      continue
    fi

    local ext="${file##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"

    local out_dir="${OUTPUT_DIR:-.}"

    if [[ ${DRY_RUN:-false} == true ]]; then
      log_dry "Would extract $file -> $out_dir/"
      continue
    fi

    mkdir -p "$out_dir"

    _spinner start "Extracting $(basename "$file")..."
    case "$ext" in
    zip)
      if command -v unzip &>/dev/null; then
        unzip -qo "$file" -d "$out_dir"
      else
        _spinner stop
        log_error "unzip not found. Install: brew install unzip"
        return 1
      fi
      ;;
    tar)
      tar xf "$file" -C "$out_dir"
      ;;
    gz | tgz)
      tar xzf "$file" -C "$out_dir"
      ;;
    zst | zstd)
      if command -v zstd &>/dev/null; then
        zstd -d "$file" --force -o "${file%.*}"
        tar xf "${file%.*}" -C "$out_dir"
        rm -f "${file%.*}"
      else
        _spinner stop
        log_error "zstd not found. Install: brew install zstd"
        return 1
      fi
      ;;
    xz | txz)
      xz -dk "$file"
      tar xf "${file%.xz}" -C "$out_dir"
      rm -f "${file%.xz}"
      ;;
    bz2 | tbz2)
      bunzip2 -k "$file"
      tar xf "${file%.bz2}" -C "$out_dir"
      rm -f "${file%.bz2}"
      ;;
    *)
      _spinner stop
      log_error "Unsupported archive format: .$ext (use zip, tar, gz, zst, xz, bz2)"
      return 1
      ;;
    esac
    _spinner stop

    log_success "Extracted: $(basename "$file") -> $out_dir/"
  done
}

# -------------------------------------------------------
# Info command (top-level, no category needed)
# -------------------------------------------------------

cmd_info() {
  local -a files=()
  mapfile -t files < <(resolve_files "$@")

  if [[ ${#files[@]} -eq 0 ]]; then
    log_error "No files provided."
    return 1
  fi

  for file in "${files[@]}"; do
    if [[ ! -f $file ]]; then
      log_warn "Not a file: $file"
      continue
    fi

    local ext="${file##*.}"
    ext="$(echo "$ext" | tr '[:upper:]' '[:lower:]')"
    local size
    size="$(file_size "$file")"
    local size_human
    size_human="$(human_size "$size")"

    echo ""
    echo -e "${BOLD}$(basename "$file")${NC}"
    echo -e "  Size:     $size_human"
    echo -e "  Type:     .$ext"

    # Suggest actions based on file type
    case "$ext" in
    # ---- Video ----
    mp4 | mov | mkv | avi | webm | m4v | flv | wmv)
      echo -e "  Category: ${CYAN}video${NC}"
      echo -e "  Tool:     ffmpeg (libx265)"
      echo -e "  Compress: ${DIM}uts video compress \"$file\" [-q low|medium|high|<0-51>]${NC}"
      echo -e "  Convert:  ${DIM}uts video convert \"$file\" --to mkv${NC}"
      ;;
    # ---- Images ----
    png)
      echo -e "  Category: ${CYAN}image${NC}"
      echo -e "  Tool:     pngquant + optipng"
      echo -e "  Compress: ${DIM}uts image compress \"$file\" [-q low|medium|high|<1-100>]${NC}"
      echo -e "  Convert:  ${DIM}uts image convert \"$file\" --to webp${NC}"
      ;;
    jpg | jpeg)
      echo -e "  Category: ${CYAN}image${NC}"
      echo -e "  Tool:     jpegoptim"
      echo -e "  Compress: ${DIM}uts image compress \"$file\" [-q low|medium|high|<1-100>]${NC}"
      echo -e "  Convert:  ${DIM}uts image convert \"$file\" --to webp${NC}"
      ;;
    webp)
      echo -e "  Category: ${CYAN}image${NC}"
      echo -e "  Tool:     cwebp"
      echo -e "  Compress: ${DIM}uts image compress \"$file\" [-q low|medium|high|<1-100>]${NC}"
      echo -e "  Convert:  ${DIM}uts image convert \"$file\" --to jpg${NC}"
      ;;
    gif)
      echo -e "  Category: ${CYAN}image${NC}"
      echo -e "  Tool:     gifsicle"
      echo -e "  Compress: ${DIM}uts image compress \"$file\"${NC}"
      ;;
    bmp | tiff | tif)
      echo -e "  Category: ${CYAN}image${NC}"
      echo -e "  Tool:     ImageMagick"
      echo -e "  Compress: ${DIM}uts image compress \"$file\" [-q low|medium|high|<1-100>]${NC}"
      echo -e "  Convert:  ${DIM}uts image convert \"$file\" --to jpg${NC}"
      ;;
    heic | heif)
      echo -e "  Category: ${CYAN}image${NC}"
      echo -e "  Tool:     ImageMagick (HEIC -> JPEG)"
      echo -e "  Compress: ${DIM}uts image compress \"$file\" [-q low|medium|high|<1-100>]${NC}"
      echo -e "  Convert:  ${DIM}uts image convert \"$file\" --to jpg${NC}"
      ;;
    avif | avifs)
      echo -e "  Category: ${CYAN}image${NC}"
      echo -e "  Tool:     cavif / libavif / ImageMagick"
      echo -e "  Compress: ${DIM}uts image compress \"$file\" [-q low|medium|high|<1-100>]${NC}"
      echo -e "  Convert:  ${DIM}uts image convert \"$file\" --to jpg${NC}"
      ;;
    # ---- PDF ----
    pdf)
      echo -e "  Category: ${CYAN}pdf${NC}"
      echo -e "  Tool:     ghostscript"
      echo -e "  Compress: ${DIM}uts pdf compress \"$file\" [-q low|medium|high|<dpi>]${NC}"
      echo -e "  Convert:  ${DIM}uts pdf convert \"$file\" --to jpg${NC}"
      ;;
    # ---- Audio ----
    wav | flac | aac | mp3 | m4a | opus | ogg | wma)
      echo -e "  Category: ${CYAN}audio${NC}"
      echo -e "  Tool:     ffmpeg (aac)"
      echo -e "  Compress: ${DIM}uts audio compress \"$file\" [-q low|medium|high|<kbps>]${NC}"
      echo -e "  Convert:  ${DIM}uts audio convert \"$file\" --to mp3${NC}"
      ;;
    # ---- Archives ----
    zip)
      echo -e "  Category: ${CYAN}archive${NC}"
      echo -e "  Tool:     unzip"
      echo -e "  Extract:  ${DIM}uts archive extract \"$file\"${NC}"
      echo -e "  List:     ${DIM}uts archive list \"$file\"${NC}"
      echo -e "  Re-pack:  ${DIM}uts archive compress <extracted-dir> --algorithm zstd${NC}"
      ;;
    tar)
      echo -e "  Category: ${CYAN}archive${NC}"
      echo -e "  Tool:     tar"
      echo -e "  Extract:  ${DIM}uts archive extract \"$file\"${NC}"
      echo -e "  List:     ${DIM}uts archive list \"$file\"${NC}"
      ;;
    gz | tgz)
      echo -e "  Category: ${CYAN}archive${NC}"
      echo -e "  Tool:     tar (gzip)"
      echo -e "  Extract:  ${DIM}uts archive extract \"$file\"${NC}"
      echo -e "  List:     ${DIM}uts archive list \"$file\"${NC}"
      echo -e "  Re-pack:  ${DIM}uts archive compress <extracted-dir> --algorithm zstd${NC}"
      ;;
    zst | zstd)
      echo -e "  Category: ${CYAN}archive${NC}"
      echo -e "  Tool:     tar (zstd)"
      echo -e "  Extract:  ${DIM}uts archive extract \"$file\"${NC}"
      echo -e "  List:     ${DIM}uts archive list \"$file\"${NC}"
      ;;
    xz | txz)
      echo -e "  Category: ${CYAN}archive${NC}"
      echo -e "  Tool:     tar (xz)"
      echo -e "  Extract:  ${DIM}uts archive extract \"$file\"${NC}"
      echo -e "  List:     ${DIM}uts archive list \"$file\"${NC}"
      ;;
    bz2 | tbz2)
      echo -e "  Category: ${CYAN}archive${NC}"
      echo -e "  Tool:     tar (bzip2)"
      echo -e "  Extract:  ${DIM}uts archive extract \"$file\"${NC}"
      echo -e "  List:     ${DIM}uts archive list \"$file\"${NC}"
      ;;
    7z)
      echo -e "  Category: ${CYAN}archive${NC}"
      echo -e "  Tool:     7z"
      echo -e "  Extract:  ${DIM}7z x \"$file\"${NC}"
      ;;
    # ---- Unknown ----
    *)
      echo -e "  Category: ${YELLOW}unknown${NC}"
      echo -e "  No uts strategy for .$ext"
      echo -e "  Hint:     ${DIM}uts <category> compress \"$file\"${NC}"
      ;;
    esac
  done
  echo ""
}

# -------------------------------------------------------
# Help & version
# -------------------------------------------------------

# Shared option block reused across all help outputs
_help_options() {
  cat <<EOF
${BOLD}OPTIONS${NC}
  -q, --quality <level>   Quality preset: low, medium, high (default: medium)
  -o, --output <dir>      Output directory (default: same as input)
  -i, --in-place          Replace original file with compressed version
  -n, --dry-run           Show what would be done without doing it
  -v, --verbose           Verbose output
  -r, --recursive         Enable recursive glob patterns (**/*.ext)
  -h, --help              Show this help
EOF
}

# Root help
usage() {
  cat <<EOF
${BOLD}uts${NC} v${UTS_VERSION} — All-in-one utility toolkit

${BOLD}USAGE${NC}
  uts <category> <action> <input...> [options]

${BOLD}CATEGORIES${NC}
  ${CYAN}video${NC}     Video files (mp4, mov, mkv, avi, webm)
  ${CYAN}image${NC}     Images (png, jpg, webp, gif, bmp, tiff, heic, avif)
  ${CYAN}pdf${NC}       PDF documents
  ${CYAN}audio${NC}     Audio files (wav, flac, aac, mp3, m4a, opus)
  ${CYAN}archive${NC}   Directories/files into archives

${BOLD}ACTIONS${NC}
  ${GREEN}compress${NC}  Compress files (available for all categories)
  ${GREEN}convert${NC}   Convert between formats (image, video, audio, pdf)

${BOLD}TOP-LEVEL COMMANDS${NC}
  ${CYAN}info${NC}      Show file info and suggestions
  ${CYAN}convert${NC}   Convert between formats directly (e.g. uts convert image ...)$(_help_options)

${BOLD}QUALITY${NC}
  ${GREEN}high${NC}    Best quality, larger files      (crf=23, 192k audio, 300dpi PDF)
  ${YELLOW}medium${NC}  Balanced quality and size       (crf=28, 128k audio, 150dpi PDF)
  ${RED}low${NC}     Smallest files, lower quality   (crf=32, 96k audio, 72dpi PDF)
  ${CYAN}<number>${NC}  Numeric value (CRF, quality %, kbps, or DPI)

${BOLD}QUICK EXAMPLES${NC}
  uts image compress screenshot.png -q low
  uts video compress recording.mp4 -i
  uts convert image photo.heic --to jpg
  uts convert image screenshot.png --to webp -q 85
  uts info video.mp4

Run ${BOLD}uts <category> --help${NC} for category-specific help with examples.

${BOLD}OUTPUT${NC}
  Files are saved as <name>-small.<ext> in the same directory by default.
  Use -o to specify a different output directory.
  Use -i to replace the original file in-place.

EOF
}

# ---- Category-level help ----

help_video() {
  cat <<EOF
${BOLD}uts video${NC} — Compress and convert video files

${BOLD}ACTIONS${NC}
  ${GREEN}compress${NC}  Compress videos using ffmpeg (libx265)
  ${GREEN}convert${NC}   Convert between video formats (mp4, mkv, webm, ...)

${BOLD}SUPPORTED FORMATS${NC}
  Input:   mp4, mov, mkv, avi, webm, m4v, flv, wmv
  Output:  mp4, mov, mkv, webm, avi, flv

$(_help_options)
  --to <format>           Target format for convert (mp4, mkv, webm, ...)

${BOLD}COMPRESSION EXAMPLES${NC}
  uts video compress screen-recording.mp4 -q low
  uts video compress vacation.mov -q high -i
  uts video compress lecture.mkv --dry-run
  uts video compress '*.mp4' -r -q medium

${BOLD}CONVERSION EXAMPLES${NC}
  uts video convert clip.mov --to mp4
  uts video convert recording.mkv --to webm -q medium
  uts video convert presentation.avi --to mp4 -q 18
  uts video convert '*.mov' --to mp4 -i

EOF
}

help_image() {
  cat <<EOF
${BOLD}uts image${NC} — Compress and convert images

${BOLD}ACTIONS${NC}
  ${GREEN}compress${NC}  Compress images (pngquant, jpegoptim, cwebp, ...)
  ${GREEN}convert${NC}   Convert between image formats (jpg, png, webp, avif, ...)

${BOLD}SUPPORTED FORMATS${NC}
  Input:   png, jpg, jpeg, webp, gif, bmp, tiff, heic, heif, avif
  Output:  jpg, png, webp, gif, bmp, tiff, avif

$(_help_options)
  --to <format>           Target format for convert (jpg, png, webp, avif, ...)

${BOLD}COMPRESSION EXAMPLES${NC}
  uts image compress screenshot.png -q medium
  uts image compress logo.jpg -q high -i
  uts image compress '*.png'
  uts image compress '**/*.jpg' -r
  uts image compress photo.heic -q low
  uts image compress animation.gif

${BOLD}CONVERSION EXAMPLES${NC}
  uts image convert photo.heic --to jpg
  uts image convert screenshot.png --to webp -q high
  uts image convert photo.jpg --to avif -q 70
  uts image convert '*.heic' --to jpg
  uts image convert photo.heic --to jpg -i

EOF
}

help_pdf() {
  cat <<EOF
${BOLD}uts pdf${NC} — Compress and convert PDF documents

${BOLD}ACTIONS${NC}
  ${GREEN}compress${NC}  Compress PDFs using Ghostscript
  ${GREEN}convert${NC}   Convert between PDF and images (pdftoppm, ImageMagick)

${BOLD}SUPPORTED FORMATS${NC}
  PDF -> images:  jpg, png
  images -> PDF:  jpg, png, webp, gif, bmp, tiff

$(_help_options)
  --to <format>           Target format: jpg, png (PDF->images) or pdf (images->PDF)

${BOLD}QUALITY PRESETS${NC}
  ${GREEN}high${NC}    400 DPI (print quality)
  ${YELLOW}medium${NC}  300 DPI (standard, default)
  ${RED}low${NC}     150 DPI (web preview)

${BOLD}COMPRESSION EXAMPLES${NC}
  uts pdf compress thesis.pdf -q low
  uts pdf compress report.pdf -q medium -o ./web/
  uts pdf compress '*.pdf' -r
  uts pdf compress slides.pdf --dry-run

${BOLD}PDF -> IMAGES${NC}
  uts pdf convert report.pdf --to jpg
  uts pdf convert slides.pdf --to png -q high
  uts pdf convert document.pdf --to jpg -q 200

${BOLD}IMAGES -> PDF${NC}
  uts pdf convert '*.jpg' --to pdf
  uts pdf convert '*.jpg' '*.png' --to pdf
  uts pdf convert images/*.png --to pdf

EOF
}

help_audio() {
  cat <<EOF
${BOLD}uts audio${NC} — Compress and convert audio files

${BOLD}ACTIONS${NC}
  ${GREEN}compress${NC}  Compress audio using ffmpeg (aac)
  ${GREEN}convert${NC}   Convert between audio formats (mp3, wav, flac, ...)

${BOLD}SUPPORTED FORMATS${NC}
  Input:   wav, flac, aac, mp3, m4a, opus, ogg, wma
  Output:  mp3, aac, m4a, wav, flac, opus, ogg

$(_help_options)
  --to <format>           Target format for convert (mp3, aac, wav, flac, ...)

${BOLD}COMPRESSION EXAMPLES${NC}
  uts audio compress podcast.wav -q low
  uts audio compress voice-memo.m4a -q high
  uts audio compress '*.wav' -r
  uts audio compress track.flac --dry-run

${BOLD}CONVERSION EXAMPLES${NC}
  uts audio convert track.wav --to mp3
  uts audio convert song.flac --to m4a -q high
  uts audio convert '*.wav' --to mp3 -q 96
  uts audio convert podcast.opus --to mp3 -q 256

EOF
}

help_archive() {
  cat <<EOF
${BOLD}uts archive${NC} — Compress, extract, and list archives

${BOLD}ACTIONS${NC}
  ${GREEN}compress${NC}  Create compressed archive (auto-selects best algorithm)
  ${GREEN}extract${NC}   Extract archive contents (zip, tar, gz, zst, xz, bz2)
  ${GREEN}list${NC}      List archive contents without extracting

${BOLD}ALGORITHMS${NC}
  auto    Auto-select best algorithm (default)
  gzip    gzip compression
  zstd    Zstandard compression (fast + good ratio)
  xz      LZMA2 compression (best ratio)
  brotli  Brotli compression
  pigz    Parallel gzip
  zip     ZIP archive (widely compatible)

${BOLD}OPTIONS${NC}
  --algorithm <name>      Archive algorithm (default: auto)
  -o, --output <dir>      Output directory (default: current)
  -n, --dry-run           Show what would be done
  -v, --verbose           Verbose output
  -r, --recursive         Enable recursive glob patterns
  -h, --help              Show this help

${BOLD}COMPRESSION EXAMPLES${NC}
  uts archive compress ./project/ --algorithm zstd
  uts archive compress ./data/ --algorithm gzip
  uts archive compress ./src/ --dry-run
  uts archive compress ./docs/ --algorithm brotli
  uts archive compress ./photos/ --algorithm zip

${BOLD}EXTRACTION EXAMPLES${NC}
  uts archive extract backup.zip
  uts archive extract project.tar.gz
  uts archive extract '*.tar.zst'
  uts archive extract backup.zip -o ./output/

${BOLD}LIST CONTENTS${NC}
  uts archive list backup.zip
  uts archive list project.tar.gz
  uts archive list '*.tar.zst'

EOF
}

# ---- Top-level command help ----

help_info() {
  cat <<EOF
${BOLD}uts info${NC} — Show file info and suggestions

${BOLD}USAGE${NC}
  uts info <input...> [options]

${BOLD}DESCRIPTION${NC}
  Displays file size, type, and suggests the best compress/convert
  command for the detected format.

${BOLD}OPTIONS${NC}
  -r, --recursive         Enable recursive glob patterns
  -h, --help              Show this help

${BOLD}EXAMPLES${NC}
  uts info video.mp4
  uts info '*.png'
  uts info photo.heic

EOF
}

help_convert() {
  cat <<EOF
${BOLD}uts convert${NC} — Convert between formats

${BOLD}USAGE${NC}
  uts convert <subcategory> <input...> --to <format> [options]

${BOLD}SUBCATEGORIES${NC}
  ${CYAN}image${NC}   Image format conversion (ImageMagick / sips)
  ${CYAN}video${NC}   Video format conversion (ffmpeg)
  ${CYAN}audio${NC}   Audio format conversion (ffmpeg)
  ${CYAN}pdf${NC}     PDF <-> image conversion (pdftoppm / ImageMagick)

$(_help_options)
  --to <format>           Target format (required)

${BOLD}IMAGE EXAMPLES${NC}
  uts convert image photo.heic --to jpg
  uts convert image screenshot.png --to webp -q 85
  uts convert image '*.heic' --to jpg

${BOLD}VIDEO EXAMPLES${NC}
  uts convert video clip.mov --to mp4
  uts convert video recording.mkv --to webm -q 20

${BOLD}AUDIO EXAMPLES${NC}
  uts convert audio track.wav --to mp3 -q 96
  uts convert audio song.flac --to m4a

${BOLD}PDF EXAMPLES${NC}
  uts convert pdf report.pdf --to jpg
  uts convert pdf '*.jpg' '*.png' --to pdf

EOF
}

# ---- Action-level help ----

help_compress_video() {
  cat <<EOF
${BOLD}uts video compress${NC} — Compress video files using ffmpeg (libx265)

${BOLD}USAGE${NC}
  uts video compress <input...> [options]

${BOLD}SUPPORTED FORMATS${NC}
  mp4, mov, mkv, avi, webm, m4v, flv, wmv

$(_help_options)
  -r, --recursive         Enable recursive glob patterns

${BOLD}QUALITY${NC}
  ${GREEN}high${NC}       crf=23, preset=slow
  ${YELLOW}medium${NC}     crf=28, preset=medium
  ${RED}low${NC}        crf=32, preset=fast
  ${CYAN}<0-51>${NC}      Raw CRF value (lower = better quality)

${BOLD}OUTPUT${NC}
  Files saved as <name>-small.<ext> in the same directory.

${BOLD}EXAMPLES${NC}
  uts video compress screen-recording.mp4 -q low
  uts video compress vacation.mov -q high -i
  uts video compress clip1.mp4 clip2.mp4 clip3.mp4 -q medium
  uts video compress lecture.mkv -q 25 --dry-run -v
  uts video compress '*.mp4' -r

EOF
}

help_convert_video() {
  cat <<EOF
${BOLD}uts video convert${NC} — Convert between video formats

${BOLD}USAGE${NC}
  uts video convert <input...> --to <format> [options]

${BOLD}TARGET FORMATS${NC}
  mp4   libx264 / aac
  mov   libx264 / aac
  mkv   libx265 / aac
  webm  libvpx-vp9 / libopus
  avi   libx264 / mp3
  flv   libx264 / aac

$(_help_options)
  --to <format>           Target format (required): mp4, mkv, webm, mov, avi, flv
  -r, --recursive         Enable recursive glob patterns

${BOLD}EXAMPLES${NC}
  uts video convert clip.mov --to mp4
  uts video convert recording.mkv --to webm -q medium
  uts video convert presentation.avi --to mkv -q 18
  uts video convert clip1.mov clip2.mov --to mp4 -i
  uts video convert '*.mov' --to mp4

EOF
}

help_compress_image() {
  cat <<EOF
${BOLD}uts image compress${NC} — Compress images using format-specific tools

${BOLD}USAGE${NC}
  uts image compress <input...> [options]

${BOLD}SUPPORTED FORMATS${NC}
  png       pngquant + optipng
  jpg/jpeg  jpegoptim
  webp      cwebp
  gif       gifsicle
  bmp/tiff  ImageMagick
  heic      heif-convert -> JPEG
  avif      cavif / avifenc

$(_help_options)
  -r, --recursive         Enable recursive glob patterns

${BOLD}OUTPUT${NC}
  Files saved as <name>-small.<ext> in the same directory.
  HEIC files are converted to JPEG.

${BOLD}EXAMPLES${NC}
  uts image compress screenshot.png -q medium
  uts image compress logo.jpg -q high -i
  uts image compress photo1.png photo2.png photo3.png -q low
  uts image compress '*.png' -r
  uts image compress '**/*.jpg' -r
  uts image compress photo.webp -q 75 --dry-run -v

EOF
}

help_convert_image() {
  cat <<EOF
${BOLD}uts image convert${NC} — Convert between image formats

${BOLD}USAGE${NC}
  uts image convert <input...> --to <format> [options]

${BOLD}TARGET FORMATS${NC}
  jpg, png, webp, gif, bmp, tiff, avif

${BOLD}TOOLS${NC}
  ImageMagick (primary) or macOS sips (fallback)

$(_help_options)
  --to <format>           Target format (required): jpg, png, webp, gif, bmp, tiff, avif
  -r, --recursive         Enable recursive glob patterns

${BOLD}EXAMPLES${NC}
  uts image convert photo.heic --to jpg
  uts image convert screenshot.png --to webp -q high
  uts image convert photo.jpg --to avif -q 70
  uts image convert photo1.heic photo2.heic --to jpg
  uts image convert '*.heic' --to jpg

EOF
}

help_compress_pdf() {
  cat <<EOF
${BOLD}uts pdf compress${NC} — Compress PDF documents using Ghostscript

${BOLD}USAGE${NC}
  uts pdf compress <input...> [options]

$(_help_options)
  -r, --recursive         Enable recursive glob patterns

${BOLD}QUALITY${NC}
  ${GREEN}high${NC}       /printer  (300 DPI)
  ${YELLOW}medium${NC}     /ebook    (150 DPI)
  ${RED}low${NC}        /screen   (72 DPI)
  ${CYAN}<dpi>${NC}         Numeric DPI (e.g. 150, 300, 400)

${BOLD}OUTPUT${NC}
  Files saved as <name>-small.pdf in the same directory.

${BOLD}EXAMPLES${NC}
  uts pdf compress thesis.pdf -q low
  uts pdf compress report.pdf -q medium -o ./web/
  uts pdf compress doc1.pdf doc2.pdf doc3.pdf -q low
  uts pdf compress slides.pdf -q 300 --dry-run
  uts pdf compress '*.pdf' -r

EOF
}

help_convert_pdf() {
  cat <<EOF
${BOLD}uts pdf convert${NC} — Convert between PDF and images

${BOLD}USAGE${NC}
  uts pdf convert <input...> --to <format> [options]

${BOLD}DIRECTIONS${NC}
  PDF -> images:   pdftoppm or ImageMagick (outputs page-1.jpg, page-2.jpg, ...)
  images -> PDF:   ImageMagick (combines into single PDF)

${BOLD}QUALITY (PDF->images only)${NC}
  ${GREEN}high${NC}       400 DPI
  ${YELLOW}medium${NC}     300 DPI
  ${RED}low${NC}        150 DPI
  ${CYAN}<dpi>${NC}         Numeric DPI (e.g. 150, 300, 400)

$(_help_options)
  --to <format>           jpg, png (PDF->images) or pdf (images->PDF)
  -r, --recursive         Enable recursive glob patterns

${BOLD}OUTPUT${NC}
  PDF -> images:  Creates <basename>/ directory with page-*.ext files
  images -> PDF:  Creates <first-image-name>.pdf

${BOLD}EXAMPLES${NC}
  uts pdf convert report.pdf --to jpg
  uts pdf convert slides.pdf --to png -q high
  uts pdf convert document.pdf --to jpg -q 200
  uts pdf convert '*.jpg' '*.png' --to pdf
  uts pdf convert images/*.png --to pdf

EOF
}

help_compress_audio() {
  cat <<EOF
${BOLD}uts audio compress${NC} — Compress audio files using ffmpeg (aac)

${BOLD}USAGE${NC}
  uts audio compress <input...> [options]

${BOLD}SUPPORTED FORMATS${NC}
  wav, flac, aac, mp3, m4a, opus, ogg, wma

$(_help_options)
  -r, --recursive         Enable recursive glob patterns

${BOLD}QUALITY${NC}
  ${GREEN}high${NC}       192k aac
  ${YELLOW}medium${NC}     128k aac
  ${RED}low${NC}        96k aac
  ${CYAN}<kbps>${NC}      Numeric bitrate (e.g. 256, 320)

${BOLD}OUTPUT${NC}
  Files saved as <name>-small.m4a in the same directory.

${BOLD}EXAMPLES${NC}
  uts audio compress podcast.wav -q low
  uts audio compress voice-memo.m4a -q high
  uts audio compress track1.wav track2.flac track3.m4a -q medium
  uts audio compress voice.wav -q 256 --dry-run
  uts audio compress '*.wav' -r

EOF
}

help_convert_audio() {
  cat <<EOF
${BOLD}uts audio convert${NC} — Convert between audio formats

${BOLD}USAGE${NC}
  uts audio convert <input...> --to <format> [options]

${BOLD}TARGET FORMATS${NC}
  mp3   libmp3lame
  aac   aac
  m4a   aac
  wav   pcm_s16le
  flac  flac
  opus  libopus
  ogg   libvorbis

$(_help_options)
  --to <format>           Target format (required): mp3, aac, m4a, wav, flac, opus, ogg
  -r, --recursive         Enable recursive glob patterns

${BOLD}QUALITY (bitrate)${NC}
  ${GREEN}high${NC}       192k
  ${YELLOW}medium${NC}     128k
  ${RED}low${NC}        96k
  ${CYAN}<kbps>${NC}         Numeric bitrate (e.g. 256, 320)

${BOLD}EXAMPLES${NC}
  uts audio convert track.wav --to mp3
  uts audio convert song.flac --to m4a -q high
  uts audio convert track1.wav track2.flac --to mp3
  uts audio convert '*.wav' --to mp3 -q 96
  uts audio convert lecture.wav --to mp3 -q 256

EOF
}

help_compress_archive() {
  cat <<EOF
${BOLD}uts archive compress${NC} — Create compressed archives

${BOLD}USAGE${NC}
  uts archive compress <input...> [options]

${BOLD}ALGORITHMS${NC}
  auto    Auto-select best algorithm (default)
  gzip    gzip compression
  zstd    Zstandard (fast + good ratio)
  xz      LZMA2 (best ratio)
  brotli  Brotli compression
  pigz    Parallel gzip
  zip     ZIP archive (widely compatible)

${BOLD}OPTIONS${NC}
  --algorithm <name>      Archive algorithm (default: auto)
  -o, --output <dir>      Output directory (default: current)
  -n, --dry-run           Show what would be done
  -v, --verbose           Verbose output
  -h, --help              Show this help

${BOLD}OUTPUT${NC}
  Creates <name>.tar.<algorithm> or <name>.zip in the output directory.

${BOLD}EXAMPLES${NC}
  uts archive compress ./project/ --algorithm zstd
  uts archive compress ./data/ --algorithm zip
  uts archive compress ./src/ --dry-run

EOF
}

help_extract_archive() {
  cat <<EOF
${BOLD}uts archive extract${NC} — Extract archive contents

${BOLD}USAGE${NC}
  uts archive extract <archive...> [options]

${BOLD}SUPPORTED FORMATS${NC}
  zip     ZIP archives
  tar     Plain tar archives
  gz/tgz  gzip-compressed tar
  zst     Zstandard-compressed tar
  xz/txz  XZ-compressed tar
  bz2     bzip2-compressed tar

${BOLD}OPTIONS${NC}
  -o, --output <dir>      Output directory (default: current)
  -n, --dry-run           Show what would be done
  -v, --verbose           Verbose output
  -r, --recursive         Enable recursive glob patterns
  -h, --help              Show this help

${BOLD}OUTPUT${NC}
  Extracts archive contents into the output directory.

${BOLD}EXAMPLES${NC}
  uts archive extract backup.zip
  uts archive extract project.tar.gz
  uts archive extract '*.tar.zst' -o ./output/
  uts archive extract backup.zip --dry-run

EOF
}

help_list_archive() {
  cat <<EOF
${BOLD}uts archive list${NC} — List archive contents

${BOLD}USAGE${NC}
  uts archive list <archive...> [options]

${BOLD}SUPPORTED FORMATS${NC}
  zip     ZIP archives
  tar     Plain tar archives
  gz/tgz  gzip-compressed tar
  zst     Zstandard-compressed tar
  xz/txz  XZ-compressed tar
  bz2     bzip2-compressed tar

${BOLD}OPTIONS${NC}
  -r, --recursive         Enable recursive glob patterns
  -h, --help              Show this help

${BOLD}EXAMPLES${NC}
  uts archive list backup.zip
  uts archive list project.tar.gz
  uts archive list '*.tar.zst'

EOF
}

# -------------------------------------------------------
# Argument parsing & dispatcher
# -------------------------------------------------------

# Check if an argument is -h or --help
_is_help() { [[ ${1:-} == "-h" || ${1:-} == "--help" ]]; }

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 0
  fi

  # Global options
  QUALITY="$DEFAULT_QUALITY"
  OUTPUT_DIR=""
  IN_PLACE=false
  DRY_RUN=false
  VERBOSE=false
  ALGORITHM="auto"
  RECURSIVE=false
  TARGET_FORMAT=""

  # Collect remaining args (non-flag) and parse flags from anywhere
  local -a remaining_args=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
    -q | --quality)
      shift
      QUALITY="${1:-}"
      [[ -z $QUALITY ]] && {
        log_error "--quality requires a value (low, medium, high, or a number)"
        exit 1
      }
      ;;
    -o | --output)
      shift
      OUTPUT_DIR="${1:-}"
      [[ -z $OUTPUT_DIR ]] && {
        log_error "--output requires a value"
        exit 1
      }
      ;;
    -i | --in-place)
      IN_PLACE=true
      ;;
    -n | --dry-run)
      DRY_RUN=true
      ;;
    -v | --verbose)
      VERBOSE=true
      ;;
    --algorithm)
      shift
      ALGORITHM="${1:-auto}"
      ;;
    -r | --recursive)
      RECURSIVE=true
      ;;
    --to)
      shift
      TARGET_FORMAT="${1:-}"
      [[ -z $TARGET_FORMAT ]] && {
        log_error "--to requires a format"
        exit 1
      }
      ;;
    -h | --help)
      # Forward to dispatcher for context-aware help
      remaining_args+=("$1")
      ;;
    -V | --version)
      echo "uts v${UTS_VERSION}"
      exit 0
      ;;
    -*)
      log_error "Unknown option: $1"
      echo "Run 'uts --help' for usage." >&2
      exit 1
      ;;
    *)
      remaining_args+=("$1")
      ;;
    esac
    shift
  done

  # First remaining arg is the category or top-level command
  local category="${remaining_args[0]:-}"
  local rest=("${remaining_args[@]:1}")

  case "$category" in
  video | v)
    local action="${rest[0]:-}"
    local action_args=("${rest[@]:1}")
    if _is_help "$action"; then
      help_video
      exit 0
    fi
    case "$action" in
    compress | c)
      if _is_help "${action_args[0]:-}"; then
        help_compress_video
        exit 0
      fi
      action_compress_video "${action_args[@]}"
      ;;
    convert | x)
      if _is_help "${action_args[0]:-}"; then
        help_convert_video
        exit 0
      fi
      action_convert_video "${action_args[@]}"
      ;;
    "")
      help_video
      ;;
    *)
      log_error "Unknown action: $action (for video)"
      echo "Actions: compress, convert" >&2
      echo "Run 'uts video --help' for usage." >&2
      exit 1
      ;;
    esac
    ;;
  image | img | i)
    local action="${rest[0]:-}"
    local action_args=("${rest[@]:1}")
    if _is_help "$action"; then
      help_image
      exit 0
    fi
    case "$action" in
    compress | c)
      if _is_help "${action_args[0]:-}"; then
        help_compress_image
        exit 0
      fi
      action_compress_image "${action_args[@]}"
      ;;
    convert | x)
      if _is_help "${action_args[0]:-}"; then
        help_convert_image
        exit 0
      fi
      action_convert_image "${action_args[@]}"
      ;;
    "")
      help_image
      ;;
    *)
      log_error "Unknown action: $action (for image)"
      echo "Actions: compress, convert" >&2
      echo "Run 'uts image --help' for usage." >&2
      exit 1
      ;;
    esac
    ;;
  pdf | p)
    local action="${rest[0]:-}"
    local action_args=("${rest[@]:1}")
    if _is_help "$action"; then
      help_pdf
      exit 0
    fi
    case "$action" in
    compress | c)
      if _is_help "${action_args[0]:-}"; then
        help_compress_pdf
        exit 0
      fi
      action_compress_pdf "${action_args[@]}"
      ;;
    convert | x)
      if _is_help "${action_args[0]:-}"; then
        help_convert_pdf
        exit 0
      fi
      action_convert_pdf "${action_args[@]}"
      ;;
    "")
      help_pdf
      ;;
    *)
      log_error "Unknown action: $action (for pdf)"
      echo "Actions: compress, convert" >&2
      echo "Run 'uts pdf --help' for usage." >&2
      exit 1
      ;;
    esac
    ;;
  audio | a)
    local action="${rest[0]:-}"
    local action_args=("${rest[@]:1}")
    if _is_help "$action"; then
      help_audio
      exit 0
    fi
    case "$action" in
    compress | c)
      if _is_help "${action_args[0]:-}"; then
        help_compress_audio
        exit 0
      fi
      action_compress_audio "${action_args[@]}"
      ;;
    convert | x)
      if _is_help "${action_args[0]:-}"; then
        help_convert_audio
        exit 0
      fi
      action_convert_audio "${action_args[@]}"
      ;;
    "")
      help_audio
      ;;
    *)
      log_error "Unknown action: $action (for audio)"
      echo "Actions: compress, convert" >&2
      echo "Run 'uts audio --help' for usage." >&2
      exit 1
      ;;
    esac
    ;;
  archive | arc | ar)
    local action="${rest[0]:-}"
    local action_args=("${rest[@]:1}")
    if _is_help "$action"; then
      help_archive
      exit 0
    fi
    case "$action" in
    compress | c)
      if _is_help "${action_args[0]:-}"; then
        help_compress_archive
        exit 0
      fi
      action_compress_archive "${action_args[@]}"
      ;;
    extract | x)
      if _is_help "${action_args[0]:-}"; then
        help_extract_archive
        exit 0
      fi
      action_extract_archive "${action_args[@]}"
      ;;
    list | ls)
      if _is_help "${action_args[0]:-}"; then
        help_list_archive
        exit 0
      fi
      action_list_archive "${action_args[@]}"
      ;;
    "")
      help_archive
      ;;
    *)
      log_error "Unknown action: $action (for archive)"
      echo "Actions: compress, extract, list" >&2
      echo "Run 'uts archive --help' for usage." >&2
      exit 1
      ;;
    esac
    ;;

  convert | x)
    if _is_help "${rest[0]:-}"; then
      help_convert
      exit 0
    fi
    local subcat="${rest[0]:-}"
    local subcat_args=("${rest[@]:1}")
    case "$subcat" in
    image | img | i)
      if _is_help "${subcat_args[0]:-}"; then
        help_convert_image
        exit 0
      fi
      action_convert_image "${subcat_args[@]}"
      ;;
    video | v)
      if _is_help "${subcat_args[0]:-}"; then
        help_convert_video
        exit 0
      fi
      action_convert_video "${subcat_args[@]}"
      ;;
    audio | a)
      if _is_help "${subcat_args[0]:-}"; then
        help_convert_audio
        exit 0
      fi
      action_convert_audio "${subcat_args[@]}"
      ;;
    pdf | p)
      if _is_help "${subcat_args[0]:-}"; then
        help_convert_pdf
        exit 0
      fi
      action_convert_pdf "${subcat_args[@]}"
      ;;
    "")
      help_convert
      ;;
    *)
      log_error "Unknown subcategory: $subcat"
      echo "Subcategories: image, video, audio, pdf" >&2
      echo "Run 'uts convert --help' for usage." >&2
      exit 1
      ;;
    esac
    ;;
  info)
    if _is_help "${rest[0]:-}"; then
      help_info
      exit 0
    fi
    cmd_info "${rest[@]}"
    ;;
  -h | --help)
    usage
    ;;
  -V | --version)
    echo "uts v${UTS_VERSION}"
    ;;
  "")
    usage
    exit 0
    ;;
  *)
    log_error "Unknown category: $category"
    echo "Run 'uts --help' for usage." >&2
    exit 1
    ;;
  esac
}

main "$@"
