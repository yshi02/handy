#!/bin/bash

set -euo pipefail

SETTING="/ebook"
INPLACE=false

usage() {
    echo "Usage: $0 [-s <screen|ebook|printer|prepress|default>] [--inplace] input.pdf"
    echo
    echo "Options:"
    echo "  -s <setting>   Ghostscript PDFSETTINGS (default: ebook)"
    echo "  --inplace      Replace the input file with the compressed version"
    exit 1
}

# Cross-platform file size function
filesize() {
    if stat --version >/dev/null 2>&1; then
        # GNU stat (Linux)
        stat -c%s "$1"
    else
        # BSD stat (macOS)
        stat -f%z "$1"
    fi
}

# Convert the number of bytes to human-friendly units
humansize() {
    local bytes=$1
    local kib=$((1024))
    local mib=$((1024*1024))
    local gib=$((1024*1024*1024))
    local result

    if   (( bytes >= gib )); then
        result=$(printf "%.2f GB" "$(echo "$bytes/$gib" | bc -l)")
    elif (( bytes >= mib )); then
        result=$(printf "%.2f MB" "$(echo "$bytes/$mib" | bc -l)")
    elif (( bytes >= kib )); then
        result=$(printf "%.2f KB" "$(echo "$bytes/$kib" | bc -l)")
    else
        result=$(printf "%d B" "$bytes")
    fi

    echo "$result"
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        -s)
            shift
            case "$1" in
                screen|ebook|printer|prepress|default)
                    SETTING="/$1"
                    ;;
                *)
                    echo "Invalid setting: $1"
                    usage
                    ;;
            esac
            ;;
        --inplace)
            INPLACE=true
            ;;
        -h|--help)
            usage
            ;;
        -*)
            echo "Unknown option: $1"
            usage
            ;;
        *)
            INPUT="$1"
            ;;
    esac
    shift || true
done

if [[ -z "${INPUT:-}" ]]; then
    echo "Error: No input file provided."
    usage
fi

if [[ ! -f "$INPUT" ]]; then
    echo "Error: File not found: $INPUT"
    exit 1
fi

EXT="${INPUT##*.}"
if [[ "$(echo "$EXT" | tr '[:upper:]' '[:lower:]')" != "pdf" ]]; then
    echo "Error: Input file must have a .pdf extension"
    exit 1
fi

# Sizes before
SIZE_BEFORE=$(humansize $(filesize "$INPUT"))

if $INPLACE; then
    TMP_OUTPUT=$(mktemp "/tmp/compress_tmp_XXXXXX.pdf")
    FINAL_OUTPUT="$INPUT"
else
    BASENAME="${INPUT%.*}"
    EXT="${INPUT##*.}"
    FINAL_OUTPUT="${BASENAME}_compressed.pdf"
    TMP_OUTPUT="$FINAL_OUTPUT"
fi

# Run Ghostscript
gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=$SETTING \
   -dNOPAUSE -dQUIET -dBATCH -sOutputFile="$TMP_OUTPUT" "$INPUT"

# Replace if inplace
if $INPLACE; then
    mv "$TMP_OUTPUT" "$INPUT"
fi

SIZE_AFTER=$(humansize $(filesize "$FINAL_OUTPUT"))

echo "PDF compressed:"
echo -e "\tInput:  $INPUT ($SIZE_BEFORE)"
echo -e "\tOutput: $FINAL_OUTPUT ($SIZE_AFTER)"
