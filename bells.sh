#!/bin/bash

# Configuration
DEFAULT_FOLDER="./default"
SPECIAL_DATES_DIR="./special"
START_SOUND="./bell.wav"
LOG_FILE="./bell_log.txt"

# Manual override
OVERRIDE=""

for arg in "$@"; do
    case "$arg" in
        --christmas) OVERRIDE="christmas" ;;
        --easter) OVERRIDE="easter" ;;
        --julyfour) OVERRIDE="july4" ;;
    esac
done

# Define fixed-date holidays
declare -A SPECIAL_DATES=(
    ["12-25"]="christmas"
    ["07-04"]="july4"
)

# Easter calculator (valid 1900–2099)
function get_easter_mmdd() {
    local year=$(date +%Y)
    local a=$((year % 19))
    local b=$((year / 100))
    local c=$((year % 100))
    local d=$((b / 4))
    local e=$((b % 4))
    local f=$(((b + 8) / 25))
    local g=$(((b - f + 1) / 3))
    local h=$(((19 * a + b - d - g + 15) % 30))
    local i=$((c / 4))
    local k=$((c % 4))
    local l=$(((32 + 2 * e + 2 * i - h - k) % 7))
    local m=$(((a + 11 * h + 22 * l) / 451))
    local month=$(((h + l - 7 * m + 114) / 31))
    local day=$((((h + l - 7 * m + 114) % 31) + 1))
    printf "%02d-%02d\n" "$month" "$day"
}

function is_easter() {
    today=$(date +%m-%d)
    easter_date=$(get_easter_mmdd)
    [[ "$today" == "$easter_date" ]]
}

function get_today_folder_name() {
    if [[ -n "$OVERRIDE" ]]; then
        echo "$OVERRIDE"
        return
    fi

    today=$(date +%m-%d)

    if is_easter; then
        echo "easter"
    elif [[ -n "${SPECIAL_DATES[$today]}" ]]; then
        echo "${SPECIAL_DATES[$today]}"
    else
        echo "default"
    fi
}

function play_bells() {
    folder_name=$(get_today_folder_name)
    folder_path="./default"

    if [[ "$folder_name" != "default" ]]; then
        folder_path="$SPECIAL_DATES_DIR/$folder_name"
    fi

    echo "Using folder: $folder_path"

    if [[ ! -d "$folder_path" ]]; then
        echo "Error: Folder not found: $folder_path"
        exit 1
    fi

    # Build per-folder state file path
    STATE_FILE="./.state_$folder_name"

    # Read files to play
    mapfile -t files < <(find "$folder_path" -maxdepth 1 -type f -name "*.wav" | sort)

    if [[ ${#files[@]} -lt 2 ]]; then
        echo "Error: Not enough .wav files in $folder_path (need at least 2)"
        exit 1
    fi

    index=0
    if [[ -f "$STATE_FILE" ]]; then
        index=$(<"$STATE_FILE")
    fi

    file1="${files[$index % ${#files[@]}]}"
    file2="${files[($index + 1) % ${#files[@]}]}"

    timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    log_entry="$timestamp | Folder: $folder_name"

    # Play start sound if available
    if [[ -f "$START_SOUND" ]]; then
        echo "Playing start sound: $START_SOUND"
        hour=$(date +%I)
        for ((i=0; i<10#$hour; i++)); do
            aplay "$START_SOUND"
        done
        log_entry+=" | Start: $START_SOUND"
    fi

    echo "Playing: $file1"
    aplay "$file1"
    echo "Playing: $file2"
    aplay "$file2"

    echo $(( (index + 2) % ${#files[@]} )) > "$STATE_FILE"

    # Append to log
    log_entry+=" | Song1: $(basename "$file1") | Song2: $(basename "$file2")"
    echo "$log_entry" >> "$LOG_FILE"
}

# Trim log to last 7 days
function trim_log() {
    temp_log=$(mktemp)
    cutoff_date=$(date -d "7 days ago" +%Y-%m-%d)
    while IFS= read -r line; do
        log_date=$(echo "$line" | cut -d' ' -f1)
        if [[ "$log_date" > "$cutoff_date" || "$log_date" == "$cutoff_date" ]]; then
            echo "$line" >> "$temp_log"
        fi
    done < "$LOG_FILE"
    mv "$temp_log" "$LOG_FILE"
}

# Run everything
play_bells
trim_log
