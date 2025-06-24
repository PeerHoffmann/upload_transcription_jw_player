#!/bin/bash
set -euo pipefail

VERSION="1.0.4"
SCRIPT_NAME="upload_transcriptions.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_CONFIG="${SCRIPT_DIR}/config.json"

show_help() {
    cat << EOF
$SCRIPT_NAME v$VERSION - Upload VTT transcription files to JW Player

USAGE:
    $SCRIPT_NAME [OPTIONS] [FILE]

DESCRIPTION:
    Uploads VTT transcription files to JW Player via the Management API v2.
    Supports both single file and batch processing modes.

ARGUMENTS:
    FILE                    Single VTT file to upload (optional)

OPTIONS:
    -d, --directory PATH    Directory containing VTT files (overrides config)
    -c, --config FILE       Config file path (default: ./config.json)
    -l, --log FILE          Log file path (overrides config)
    -k, --kind TYPE         Track kind: captions, subtitles, chapters, descriptions, metadata (default: captions)
    -g, --language CODE     Language code (ISO 639-1 format, e.g., en, es, fr, de) (default: en)
    -b, --label TEXT        Human-readable label for the track (default: auto-generated)
    --default               Set track as default track
    -n, --dry-run           Preview mode - no actual uploads
    -f, --force             Overwrite existing transcriptions
    -v, --verbose           Verbose output
    -h, --help              Show this help message
    --version               Show version information

EXAMPLES:
    $SCRIPT_NAME                           # Process default directory from config
    $SCRIPT_NAME media123.vtt              # Upload single file
    $SCRIPT_NAME -d /path/to/vtt/files     # Process specific directory
    $SCRIPT_NAME --dry-run media123.vtt    # Preview single file upload
    $SCRIPT_NAME -g es -k subtitles media123.vtt  # Spanish subtitles
    $SCRIPT_NAME --language fr --default *.vtt    # French captions as default

EXIT CODES:
    0    All uploads successful
    1    Some uploads failed
    2    Configuration error
    3    No VTT files found

For more information, see the README.md file.
EOF
}

show_version() {
    echo "$SCRIPT_NAME version $VERSION"
    echo "JW Player VTT Transcription Upload Tool"
}

log_message() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local log_entry="[$timestamp] [$level] $message"
    
    if [[ "$VERBOSE" == "true" ]] || [[ "$level" != "DEBUG" ]]; then
        echo "$log_entry" >&2
    fi
    
    if [[ -n "$LOG_FILE" ]]; then
        local log_dir=$(dirname "$LOG_FILE")
        if [[ ! -d "$log_dir" ]]; then
            mkdir -p "$log_dir" 2>/dev/null || true
        fi
        if [[ -w "$log_dir" ]] || [[ -w "$LOG_FILE" ]]; then
            echo "$log_entry" >> "$LOG_FILE" 2>/dev/null || true
        fi
    fi
}

log_info() {
    log_message "INFO" "$1"
}

log_error() {
    log_message "ERROR" "$1"
}

log_debug() {
    log_message "DEBUG" "$1"
}

log_warn() {
    log_message "WARN" "$1"
}

check_dependencies() {
    local missing_deps=()
    
    for cmd in curl jq; do
        if ! command -v "$cmd" &> /dev/null; then
            missing_deps+=("$cmd")
        fi
    done
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        log_error "Missing required dependencies: ${missing_deps[*]}"
        log_error "Please install: apt-get install curl jq"
        exit 2
    fi
}

validate_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file not found: $config_file"
        log_error "Please create a config file based on config.json.example"
        exit 2
    fi
    
    if [[ ! -r "$config_file" ]]; then
        log_error "Configuration file not readable: $config_file"
        log_error "Please check file permissions"
        exit 2
    fi
    
    local json_error
    if ! json_error=$(jq empty "$config_file" 2>&1); then
        log_error "Invalid JSON in configuration file: $config_file"
        log_error "JSON error: $json_error"
        exit 2
    fi
    
    local required_fields=(
        ".api.key"
        ".api.site_id"
        ".api.base_url"
        ".paths.vtt_directory"
        ".paths.log_file"
    )
    
    local missing_fields=()
    for field in "${required_fields[@]}"; do
        if ! jq -e "$field" "$config_file" >/dev/null 2>&1; then
            missing_fields+=("$field")
        fi
    done
    
    if [[ ${#missing_fields[@]} -gt 0 ]]; then
        log_error "Missing required configuration fields: ${missing_fields[*]}"
        log_error "Please update your config file based on config.json.example"
        exit 2
    fi
    
    local api_key=$(jq -r '.api.key' "$config_file")
    if [[ "$api_key" == "enter_your_api_key_here" ]] || [[ -z "$api_key" ]] || [[ "$api_key" == "null" ]]; then
        log_error "Please configure your JW Player API key in $config_file"
        exit 2
    fi
    
    if [[ ${#api_key} -lt 32 ]] || [[ ! "$api_key" =~ ^[a-zA-Z0-9+/=_-]+$ ]]; then
        log_error "Invalid API key format in $config_file"
        exit 2
    fi
    
    local site_id=$(jq -r '.api.site_id' "$config_file")
    if [[ "$site_id" == "enter_your_site_id_here" ]] || [[ -z "$site_id" ]] || [[ "$site_id" == "null" ]]; then
        log_error "Please configure your JW Player site ID in $config_file"
        exit 2
    fi
    
    if [[ ! "$site_id" =~ ^[a-zA-Z0-9]{8}$ ]]; then
        log_error "Invalid site ID format in $config_file (should be 8 alphanumeric characters)"
        exit 2
    fi
    
    local vtt_dir=$(jq -r '.paths.vtt_directory' "$config_file")
    if [[ "$vtt_dir" != "null" ]] && [[ ! -d "$vtt_dir" ]]; then
        log_warn "VTT directory does not exist: $vtt_dir"
    fi
}

load_config() {
    local config_file="$1"
    
    validate_config "$config_file"
    
    API_KEY=$(jq -r '.api.key' "$config_file")
    SITE_ID=$(jq -r '.api.site_id' "$config_file")
    BASE_URL=$(jq -r '.api.base_url' "$config_file")
    RATE_LIMIT=$(jq -r '.api.rate_limit.requests_per_minute // 60' "$config_file")
    RETRY_DELAY=$(jq -r '.api.rate_limit.retry_delay // 5' "$config_file")
    MAX_RETRIES=$(jq -r '.upload.max_retries // 3' "$config_file")
    TIMEOUT=$(jq -r '.upload.timeout // 30' "$config_file")
    DEFAULT_LANGUAGE=$(jq -r '.text_tracks.default_language // "en"' "$config_file")
    DEFAULT_KIND=$(jq -r '.text_tracks.default_kind // "captions"' "$config_file")
    DEFAULT_LABEL=$(jq -r '.text_tracks.default_label // "Auto-generated captions"' "$config_file")
    
    if [[ -z "$VTT_DIRECTORY" ]]; then
        VTT_DIRECTORY=$(jq -r '.paths.vtt_directory' "$config_file")
    fi
    
    if [[ -z "$LOG_FILE" ]]; then
        LOG_FILE=$(jq -r '.paths.log_file' "$config_file")
    fi
}

validate_language() {
    local lang="$1"
    
    if [[ ${#lang} -ne 2 ]] || [[ ! "$lang" =~ ^[a-z]{2}$ ]]; then
        log_error "Invalid language code format: $lang (must be 2-letter ISO 639-1 code)"
        return 1
    fi
    
    local supported_languages=(
        "en" "es" "fr" "de" "it" "pt" "ja" "ko" "zh"
        "ar" "ru" "hi" "th" "tr" "pl" "nl" "sv" "da"
        "no" "fi" "el" "he" "cs" "sk" "hu" "ro" "bg"
        "hr" "sr" "sl" "lv" "lt" "et" "mt" "ga" "cy"
    )
    
    for supported in "${supported_languages[@]}"; do
        if [[ "$lang" == "$supported" ]]; then
            return 0
        fi
    done
    
    log_warn "Language code '$lang' may not be supported by JW Player"
    return 0
}

validate_kind() {
    local kind="$1"
    local supported_kinds=("captions" "subtitles" "chapters" "descriptions" "metadata")
    
    for supported in "${supported_kinds[@]}"; do
        if [[ "$kind" == "$supported" ]]; then
            return 0
        fi
    done
    
    log_error "Invalid track kind: $kind"
    log_error "Supported kinds: ${supported_kinds[*]}"
    return 1
}

extract_media_id() {
    local filename="$1"
    
    if [[ -z "$filename" ]]; then
        return 1
    fi
    
    local basename=$(basename "$filename" .vtt 2>/dev/null)
    
    if [[ -z "$basename" ]] || [[ "$basename" == "$filename" ]]; then
        return 1
    fi
    
    if [[ "$basename" =~ ^[a-zA-Z0-9_-]+$ ]]; then
        echo "$basename"
        return 0
    else
        return 1
    fi
}

check_rate_limit() {
    local current_time=$(date +%s)
    local time_diff=$((current_time - LAST_REQUEST_TIME))
    local min_interval=$((60 / RATE_LIMIT + 1))
    
    if [[ $time_diff -lt $min_interval ]]; then
        local sleep_time=$((min_interval - time_diff))
        log_debug "Rate limiting: sleeping for $sleep_time seconds (requests: $((REQUEST_COUNT + 1))/$RATE_LIMIT per minute)"
        sleep $sleep_time
    fi
    
    LAST_REQUEST_TIME=$(date +%s)
    REQUEST_COUNT=$((REQUEST_COUNT + 1))
    
    if [[ $((current_time / 60)) -gt $((RATE_WINDOW_START / 60)) ]]; then
        REQUEST_COUNT=1
        RATE_WINDOW_START=$current_time
    fi
}

verify_media_exists() {
    local media_id="$1"
    local url="${BASE_URL}/v2/sites/${SITE_ID}/media/${media_id}/"
    
    if [[ -z "$media_id" ]] || [[ "$media_id" =~ [^a-zA-Z0-9_-] ]]; then
        log_error "Invalid media ID format: $media_id"
        return 1
    fi
    
    check_rate_limit
    
    local temp_file=$(mktemp)
    trap "rm -f '$temp_file'" RETURN
    
    local http_code=$(curl -s -w "%{http_code}" \
        -H "Authorization: Bearer $API_KEY" \
        -H "Accept: application/json" \
        --connect-timeout "$TIMEOUT" \
        --max-time $((TIMEOUT * 2)) \
        --retry 2 \
        --retry-delay 1 \
        -o "$temp_file" \
        "$url")
    
    local body=$(cat "$temp_file" 2>/dev/null || echo "")
    
    case "$http_code" in
        200)
            log_debug "Media ID $media_id exists"
            return 0
            ;;
        404)
            log_error "Media ID $media_id not found in JW Player"
            return 1
            ;;
        401|403)
            log_error "Authentication failed for media ID $media_id - check API key and permissions"
            return 1
            ;;
        429)
            log_error "Rate limit exceeded while verifying media ID $media_id"
            return 1
            ;;
        000)
            log_error "Connection failed while verifying media ID $media_id - check network connectivity"
            return 1
            ;;
        *)
            log_error "Failed to verify media ID $media_id (HTTP $http_code): ${body:0:200}"
            return 1
            ;;
    esac
}

upload_vtt_file() {
    local vtt_file="$1"
    local media_id="$2"
    local language="$3"
    local kind="$4"
    local label="$5"
    local is_default="$6"
    
    if [[ ! -f "$vtt_file" ]]; then
        log_error "VTT file not found: $vtt_file"
        return 1
    fi
    
    if [[ ! -r "$vtt_file" ]]; then
        log_error "VTT file not readable: $vtt_file"
        return 1
    fi
    
    local file_size=$(stat -f%z "$vtt_file" 2>/dev/null || stat -c%s "$vtt_file" 2>/dev/null || echo "0")
    if [[ "$file_size" -eq 0 ]]; then
        log_error "VTT file is empty: $vtt_file"
        return 1
    fi
    
    if [[ "$file_size" -gt 10485760 ]]; then
        log_warn "VTT file is large ($(( file_size / 1024 / 1024 ))MB): $vtt_file"
    fi
    
    if [[ "$DRY_RUN" == "true" ]]; then
        log_info "DRY RUN: Would upload $vtt_file to media ID $media_id ($language $kind)"
        return 0
    fi
    
    if ! verify_media_exists "$media_id"; then
        return 1
    fi
    
    local url="${BASE_URL}/v2/sites/${SITE_ID}/media/${media_id}/text_tracks/"
    local attempt=1
    local backoff_delay="$RETRY_DELAY"
    
    while [[ $attempt -le $MAX_RETRIES ]]; do
        log_debug "Upload attempt $attempt/$MAX_RETRIES for $vtt_file ($(basename "$vtt_file"))"
        log_debug "Request fields: kind=$kind, srclang=$language, label=$label, default=$is_default"
        log_debug "Metadata: {\"language\":\"$language\",\"type\":\"$kind\",\"title\":\"$label\"}"
        log_debug "URL: $url"
        
        # Debug: Show exact curl command being executed
        if [[ "$VERBOSE" == "true" ]]; then
            log_debug "Executing curl command:"
            log_debug "curl -s -w '%{http_code}' -X POST -H 'Authorization: Bearer [HIDDEN]' -H 'User-Agent: $SCRIPT_NAME/$VERSION' -F 'metadata={\"language\":\"$language\",\"type\":\"$kind\",\"title\":\"$label\"}' -F 'kind=$kind' -F 'srclang=$language' -F 'label=$label' -F 'default=$is_default' -F 'file=@$vtt_file' '$url'"
        fi
        
        check_rate_limit
        
        local temp_file=$(mktemp)
        trap "rm -f '$temp_file'" RETURN
        
        local start_time=$(date +%s)
        local http_code=$(curl -s -w "%{http_code}" \
            -X POST \
            -H "Authorization: Bearer $API_KEY" \
            -H "User-Agent: $SCRIPT_NAME/$VERSION" \
            -F 'metadata={"language":"'$language'","type":"'$kind'","title":"'$label'"}' \
            -F "kind=$kind" \
            -F "srclang=$language" \
            -F "label=$label" \
            -F "default=$is_default" \
            -F "file=@$vtt_file" \
            --connect-timeout "$TIMEOUT" \
            --max-time $((TIMEOUT * 3)) \
            --retry 0 \
            -o "$temp_file" \
            "$url")
        
        local end_time=$(date +%s)
        local duration=$((end_time - start_time))
        local body=$(cat "$temp_file" 2>/dev/null || echo "")
        
        case "$http_code" in
            201)
                log_info "Successfully uploaded $(basename "$vtt_file") to media ID $media_id (${duration}s)"
                return 0
                ;;
            409)
                if [[ "$FORCE" != "true" ]]; then
                    log_warn "Transcription already exists for media ID $media_id (use --force to overwrite)"
                    return 0
                else
                    log_info "Overwriting existing transcription for media ID $media_id"
                fi
                ;;
            429)
                log_warn "Rate limit exceeded (attempt $attempt), waiting ${backoff_delay}s before retry"
                sleep "$backoff_delay"
                backoff_delay=$((backoff_delay * 2))
                ;;
            401|403)
                log_error "Authentication failed for media ID $media_id - check API key and permissions"
                return 1
                ;;
            413)
                log_error "File too large: $vtt_file ($(( file_size / 1024 ))KB)"
                return 1
                ;;
            422)
                log_error "Invalid VTT file format: $vtt_file - ${body:0:200}"
                return 1
                ;;
            000)
                log_error "Connection timeout for $vtt_file (attempt $attempt) - check network connectivity"
                if [[ $attempt -lt $MAX_RETRIES ]]; then
                    sleep "$backoff_delay"
                    backoff_delay=$((backoff_delay * 2))
                else
                    return 1
                fi
                ;;
            400)
                if [[ "$body" == *"metadata is required"* ]]; then
                    log_warn "Metadata field rejected, trying without metadata (attempt $attempt)"
                    # Retry without metadata field
                    local http_code_retry=$(curl -s -w "%{http_code}" \
                        -X POST \
                        -H "Authorization: Bearer $API_KEY" \
                        -H "User-Agent: $SCRIPT_NAME/$VERSION" \
                        -F "kind=$kind" \
                        -F "srclang=$language" \
                        -F "label=$label" \
                        -F "default=$is_default" \
                        -F "file=@$vtt_file" \
                        --connect-timeout "$TIMEOUT" \
                        --max-time $((TIMEOUT * 3)) \
                        --retry 0 \
                        -o "$temp_file" \
                        "$url")
                    
                    if [[ "$http_code_retry" == "201" ]]; then
                        log_info "Successfully uploaded $(basename "$vtt_file") without metadata to media ID $media_id (${duration}s)"
                        return 0
                    else
                        local body_retry=$(cat "$temp_file" 2>/dev/null || echo "")
                        log_error "Upload failed even without metadata (HTTP $http_code_retry): ${body_retry:0:200}"
                    fi
                fi
                
                if [[ $attempt -lt $MAX_RETRIES ]]; then
                    sleep "$backoff_delay"
                    backoff_delay=$((backoff_delay * 2))
                else
                    return 1
                fi
                ;;
            *)
                log_error "Upload failed for $vtt_file (HTTP $http_code): ${body:0:200}"
                if [[ $attempt -lt $MAX_RETRIES ]]; then
                    sleep "$backoff_delay"
                    backoff_delay=$((backoff_delay * 2))
                else
                    return 1
                fi
                ;;
        esac
        
        ((attempt++))
    done
    
    return 1
}

process_single_file() {
    local vtt_file="$1"
    local media_id=$(extract_media_id "$vtt_file")
    local label="$LABEL"
    
    if [[ "$label" == "auto" ]]; then
        label="$LANGUAGE $KIND for $media_id"
    fi
    
    log_info "Processing single file: $vtt_file (Media ID: $media_id)"
    
    if upload_vtt_file "$vtt_file" "$media_id" "$LANGUAGE" "$KIND" "$label" "$SET_DEFAULT"; then
        return 0
    else
        return 1
    fi
}

process_directory() {
    local directory="$1"
    local success_count=0
    local failure_count=0
    local skipped_count=0
    local vtt_files=()
    
    if [[ ! -d "$directory" ]]; then
        log_error "Directory not found: $directory"
        return 3
    fi
    
    if [[ ! -r "$directory" ]]; then
        log_error "Directory not readable: $directory"
        return 3
    fi
    
    readarray -t vtt_files < <(find "$directory" -maxdepth 1 -name "*.vtt" -type f -readable | sort)
    
    if [[ ${#vtt_files[@]} -eq 0 ]]; then
        log_error "No readable VTT files found in directory: $directory"
        return 3
    fi
    
    log_info "Found ${#vtt_files[@]} VTT files in $directory"
    local start_time=$(date +%s)
    
    for i in "${!vtt_files[@]}"; do
        local vtt_file="${vtt_files[$i]}"
        local media_id=$(extract_media_id "$vtt_file")
        local label="$LABEL"
        
        if [[ "$label" == "auto" ]]; then
            label="$LANGUAGE $KIND for $media_id"
        fi
        
        log_info "Processing ($((i+1))/${#vtt_files[@]}): $(basename "$vtt_file") -> Media ID: $media_id"
        
        if [[ -z "$media_id" ]] || [[ "$media_id" == "*" ]]; then
            log_warn "Skipping file with invalid media ID: $(basename "$vtt_file")"
            ((skipped_count++))
            continue
        fi
        
        if upload_vtt_file "$vtt_file" "$media_id" "$LANGUAGE" "$KIND" "$label" "$SET_DEFAULT"; then
            ((success_count++))
        else
            ((failure_count++))
        fi
        
        if [[ $((i % 10)) -eq 9 ]] && [[ $i -lt $((${#vtt_files[@]} - 1)) ]]; then
            log_info "Progress: $((i+1))/${#vtt_files[@]} processed (${success_count} success, ${failure_count} failed, ${skipped_count} skipped)"
        fi
    done
    
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    local total_processed=$((success_count + failure_count + skipped_count))
    
    log_info "Batch processing complete in ${duration}s: $success_count successful, $failure_count failed, $skipped_count skipped (${total_processed}/${#vtt_files[@]} total)"
    
    if [[ $failure_count -gt 0 ]]; then
        return 1
    else
        return 0
    fi
}

main() {
    CONFIG_FILE="$DEFAULT_CONFIG"
    VTT_DIRECTORY=""
    LOG_FILE=""
    LANGUAGE=""
    KIND=""
    LABEL="auto"
    SET_DEFAULT="false"
    DRY_RUN="false"
    FORCE="false"
    VERBOSE="false"
    INPUT_FILE=""
    
    LAST_REQUEST_TIME=0
    REQUEST_COUNT=0
    RATE_WINDOW_START=$(date +%s)
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            --version)
                show_version
                exit 0
                ;;
            -d|--directory)
                VTT_DIRECTORY="$2"
                shift 2
                ;;
            -c|--config)
                CONFIG_FILE="$2"
                shift 2
                ;;
            -l|--log)
                LOG_FILE="$2"
                shift 2
                ;;
            -k|--kind)
                KIND="$2"
                shift 2
                ;;
            -g|--language)
                LANGUAGE="$2"
                shift 2
                ;;
            -b|--label)
                LABEL="$2"
                shift 2
                ;;
            --default)
                SET_DEFAULT="true"
                shift
                ;;
            -n|--dry-run)
                DRY_RUN="true"
                shift
                ;;
            -f|--force)
                FORCE="true"
                shift
                ;;
            -v|--verbose)
                VERBOSE="true"
                shift
                ;;
            -*)
                log_error "Unknown option: $1"
                echo "Use --help for usage information."
                exit 2
                ;;
            *)
                if [[ -z "$INPUT_FILE" ]]; then
                    INPUT_FILE="$1"
                else
                    log_error "Multiple input files specified. Use directory mode for batch processing."
                    exit 2
                fi
                shift
                ;;
        esac
    done
    
    check_dependencies
    load_config "$CONFIG_FILE"
    
    if [[ -z "$LANGUAGE" ]]; then
        LANGUAGE="$DEFAULT_LANGUAGE"
    fi
    
    if [[ -z "$KIND" ]]; then
        KIND="$DEFAULT_KIND"
    fi
    
    validate_language "$LANGUAGE"
    if ! validate_kind "$KIND"; then
        exit 2
    fi
    
    log_info "Starting $SCRIPT_NAME v$VERSION"
    log_debug "Configuration: Language=$LANGUAGE, Kind=$KIND, Label=$LABEL, Default=$SET_DEFAULT"
    log_debug "Options: DryRun=$DRY_RUN, Force=$FORCE, Verbose=$VERBOSE"
    
    local exit_code=0
    
    if [[ -n "$INPUT_FILE" ]]; then
        if [[ ! -f "$INPUT_FILE" ]]; then
            log_error "Input file not found: $INPUT_FILE"
            exit 3
        fi
        
        if ! process_single_file "$INPUT_FILE"; then
            exit_code=1
        fi
    else
        if [[ -z "$VTT_DIRECTORY" ]]; then
            log_error "No input file or directory specified"
            echo "Use --help for usage information."
            exit 2
        fi
        
        if ! process_directory "$VTT_DIRECTORY"; then
            exit_code=$?
        fi
    fi
    
    log_info "$SCRIPT_NAME completed with exit code $exit_code"
    exit $exit_code
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi