#!/bin/bash
# Описание: Конвертация PNG/JPG ↔ WebP с рекурсивной обработкой каталогов и dry-run режимом
# Использование: image-converter [опции] <путь>
# Примеры:
#   image-converter -t webp ./images
#   image-converter -t jpg --dry-run ./images
# Зависимости: imagemagick (convert) или cwebp/dwebp
# Категория: media

set -euo pipefail

# Script metadata
SCRIPT_NAME=$(basename "$0")
VERSION="1.0.0"
DESCRIPTION="Convert images between PNG/JPG and WebP formats"

# Default settings
DEFAULT_QUALITY=80
VERBOSE=false
DRY_RUN=false
CONVERSION_TYPE="to-webp"
QUALITY=$DEFAULT_QUALITY

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Statistics
TOTAL_FILES=0
CONVERTED_FILES=0
SKIPPED_FILES=0
ERROR_FILES=0

# Function to validate dependencies
validate_dependencies() {
  if ! command -v convert &>/dev/null; then
    echo -e "${RED}Error: ImageMagick 'convert' command not found.${NC}" >&2
    echo -e "${RED}Please install ImageMagick to use this script.${NC}" >&2
    echo -e "${YELLOW}On Ubuntu/Debian: sudo apt-get install imagemagick${NC}" >&2
    echo -e "${YELLOW}On CentOS/RHEL: sudo yum install ImageMagick${NC}" >&2
    echo -e "${YELLOW}On macOS: brew install imagemagick${NC}" >&2
    exit 1
  fi
}

# Function to show help
show_help() {
  cat <<EOF
$SCRIPT_NAME v$VERSION - $DESCRIPTION

Usage: $SCRIPT_NAME [OPTIONS] DIRECTORY [CONVERSION_TYPE]

OPTIONS:
    -h, --help          Show this help message
    -q, --quality N     WebP quality (1-100, default: $DEFAULT_QUALITY)
    -v, --verbose       Verbose output
    -d, --dry-run       Show what would be converted without actually converting

CONVERSION_TYPE:
    to-webp    Convert PNG/JPG to WebP (default)
    to-png     Convert WebP to PNG
    to-jpg     Convert WebP to JPG

DIRECTORY:
    Path to directory containing images to process

EXAMPLES:
    $SCRIPT_NAME ./images                    # Convert PNG/JPG to WebP in ./images
    $SCRIPT_NAME -q 90 ./photos to-webp      # Convert with quality 90
    $SCRIPT_NAME -v ./images to-png          # Convert WebP to PNG with verbose output
    $SCRIPT_NAME -d ./images to-jpg          # Dry run: show what would be converted

EOF
}

# Function to log messages
log_message() {
  local level=$1
  local message=$2
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  case $level in
    "INFO")
      if [[ "$VERBOSE" == true ]]; then
        echo -e "${BLUE}[INFO]${NC} $timestamp - $message"
      fi
      ;;
    "SUCCESS")
      echo -e "${GREEN}[SUCCESS]${NC} $timestamp - $message"
      ;;
    "WARNING")
      echo -e "${YELLOW}[WARNING]${NC} $timestamp - $message"
      ;;
    "ERROR")
      echo -e "${RED}[ERROR]${NC} $timestamp - $message" >&2
      ;;
  esac
}

# Function to parse command line arguments
parse_arguments() {
  while [[ $# -gt 0 ]]; do
    case $1 in
      -h | --help)
        show_help
        exit 0
        ;;
      -q | --quality)
        if [[ -n "${2:-}" && "$2" =~ ^[0-9]+$ && "$2" -ge 1 && "$2" -le 100 ]]; then
          QUALITY="$2"
          shift 2
        else
          echo -e "${RED}Error: Quality must be a number between 1 and 100${NC}" >&2
          exit 1
        fi
        ;;
      -v | --verbose)
        VERBOSE=true
        shift
        ;;
      -d | --dry-run)
        DRY_RUN=true
        shift
        ;;
      -*)
        echo -e "${RED}Error: Unknown option $1${NC}" >&2
        show_help
        exit 1
        ;;
      *)
        if [[ -z "${DIRECTORY:-}" ]]; then
          DIRECTORY="$1"
        elif [[ -z "${CONVERSION_TYPE_OVERRIDE:-}" ]]; then
          case "$1" in
            to-webp | to-png | to-jpg)
              CONVERSION_TYPE_OVERRIDE="$1"
              ;;
            *)
              echo -e "${RED}Error: Invalid conversion type '$1'${NC}" >&2
              echo -e "${RED}Valid types: to-webp, to-png, to-jpg${NC}" >&2
              exit 1
              ;;
          esac
        else
          echo -e "${RED}Error: Too many arguments${NC}" >&2
          show_help
          exit 1
        fi
        shift
        ;;
    esac
  done

  # Override conversion type if specified
  if [[ -n "${CONVERSION_TYPE_OVERRIDE:-}" ]]; then
    CONVERSION_TYPE="$CONVERSION_TYPE_OVERRIDE"
  fi

  # Validate required directory argument
  if [[ -z "${DIRECTORY:-}" ]]; then
    echo -e "${RED}Error: Directory argument is required${NC}" >&2
    show_help
    exit 1
  fi

  # Validate directory exists
  if [[ ! -d "$DIRECTORY" ]]; then
    echo -e "${RED}Error: Directory '$DIRECTORY' does not exist${NC}" >&2
    exit 1
  fi
}

# Function to find image files recursively
find_image_files() {
  local dir="$1"
  local files=()

  case "$CONVERSION_TYPE" in
    "to-webp")
      # Find PNG and JPG files
      while IFS= read -r -d '' file; do
        files+=("$file")
      done < <(find "$dir" -type f \( -iname "*.png" -o -iname "*.jpg" -o -iname "*.jpeg" \) -print0)
      ;;
    "to-png" | "to-jpg")
      # Find WebP files
      while IFS= read -r -d '' file; do
        files+=("$file")
      done < <(find "$dir" -type f -iname "*.webp" -print0)
      ;;
  esac

  echo "${files[@]}"
}

# Function to convert PNG/JPG to WebP
convert_to_webp() {
  local input_file="$1"
  local output_file="${input_file%.*}.webp"

  # Skip if output already exists
  if [[ -f "$output_file" ]]; then
    log_message "WARNING" "Output file already exists, skipping: $output_file"
    ((SKIPPED_FILES++))
    return 0
  fi

  log_message "INFO" "Converting: $input_file -> $output_file"

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}[DRY RUN]${NC} Would convert: $input_file -> $output_file (quality: $QUALITY)"
    ((CONVERTED_FILES++))
    return 0
  fi

  # Perform conversion
  if convert "$input_file" -quality "$QUALITY" "$output_file" 2>/dev/null; then
    log_message "SUCCESS" "Successfully converted: $input_file -> $output_file"
    ((CONVERTED_FILES++))
    return 0
  else
    log_message "ERROR" "Failed to convert: $input_file"
    ((ERROR_FILES++))
    return 1
  fi
}

# Function to convert WebP to PNG
convert_to_png() {
  local input_file="$1"
  local output_file="${input_file%.*}.png"

  # Skip if output already exists
  if [[ -f "$output_file" ]]; then
    log_message "WARNING" "Output file already exists, skipping: $output_file"
    ((SKIPPED_FILES++))
    return 0
  fi

  log_message "INFO" "Converting: $input_file -> $output_file"

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}[DRY RUN]${NC} Would convert: $input_file -> $output_file"
    ((CONVERTED_FILES++))
    return 0
  fi

  # Perform conversion
  if convert "$input_file" "$output_file" 2>/dev/null; then
    log_message "SUCCESS" "Successfully converted: $input_file -> $output_file"
    ((CONVERTED_FILES++))
    return 0
  else
    log_message "ERROR" "Failed to convert: $input_file"
    ((ERROR_FILES++))
    return 1
  fi
}

# Function to convert WebP to JPG
convert_to_jpg() {
  local input_file="$1"
  local output_file="${input_file%.*}.jpg"

  # Skip if output already exists
  if [[ -f "$output_file" ]]; then
    log_message "WARNING" "Output file already exists, skipping: $output_file"
    ((SKIPPED_FILES++))
    return 0
  fi

  log_message "INFO" "Converting: $input_file -> $output_file"

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${BLUE}[DRY RUN]${NC} Would convert: $input_file -> $output_file (quality: $QUALITY)"
    ((CONVERTED_FILES++))
    return 0
  fi

  # Perform conversion
  if convert "$input_file" -quality "$QUALITY" "$output_file" 2>/dev/null; then
    log_message "SUCCESS" "Successfully converted: $input_file -> $output_file"
    ((CONVERTED_FILES++))
    return 0
  else
    log_message "ERROR" "Failed to convert: $input_file"
    ((ERROR_FILES++))
    return 1
  fi
}

# Function to process files
process_files() {
  local files=("$@")
  local total=${#files[@]}

  if [[ $total -eq 0 ]]; then
    echo -e "${YELLOW}No files found to convert in '$DIRECTORY'${NC}"
    return 0
  fi

  echo -e "${BLUE}Found $total file(s) to process...${NC}"

  for ((i = 0; i < total; i++)); do
    local file="${files[i]}"
    ((TOTAL_FILES++))

    # Show progress
    local progress=$((i + 1))
    if [[ "$VERBOSE" == true || "$DRY_RUN" == true ]]; then
      echo -e "${BLUE}[$progress/$total]${NC} Processing: $file"
    fi

    # Convert based on type
    case "$CONVERSION_TYPE" in
      "to-webp")
        convert_to_webp "$file"
        ;;
      "to-png")
        convert_to_png "$file"
        ;;
      "to-jpg")
        convert_to_jpg "$file"
        ;;
    esac
  done
}

# Function to show summary
show_summary() {
  echo
  echo -e "${BLUE}=== Conversion Summary ===${NC}"
  echo -e "Directory processed: ${GREEN}$DIRECTORY${NC}"
  echo -e "Conversion type: ${GREEN}$CONVERSION_TYPE${NC}"
  if [[ "$CONVERSION_TYPE" == "to-webp" ]]; then
    echo -e "WebP quality: ${GREEN}$QUALITY${NC}"
  fi
  echo -e "Total files found: ${GREEN}$TOTAL_FILES${NC}"
  echo -e "Files converted: ${GREEN}$CONVERTED_FILES${NC}"
  echo -e "Files skipped: ${YELLOW}$SKIPPED_FILES${NC}"
  echo -e "Files with errors: ${RED}$ERROR_FILES${NC}"

  if [[ "$DRY_RUN" == true ]]; then
    echo -e "${YELLOW}Note: This was a dry run - no files were actually converted${NC}"
  fi
}

# Main function
main() {
  echo -e "${BLUE}$SCRIPT_NAME v$VERSION${NC}"
  echo -e "${BLUE}$DESCRIPTION${NC}"
  echo

  # Validate dependencies first
  validate_dependencies

  # Parse command line arguments
  parse_arguments "$@"

  # Find image files
  log_message "INFO" "Searching for images in '$DIRECTORY'..."
  local files
  read -ra files <<<"$(find_image_files "$DIRECTORY")"

  # Process files
  process_files "${files[@]}"

  # Show summary
  show_summary

  # Exit with appropriate code
  if [[ $ERROR_FILES -gt 0 ]]; then
    exit 1
  else
    exit 0
  fi
}

# Run main function with all arguments
main "$@"
