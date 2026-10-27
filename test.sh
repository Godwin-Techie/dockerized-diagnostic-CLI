#!/usr/bin/env bash

# Stop on unset variables and errors in pipelines.
set -uo pipefail

IMAGE_NAME=${IMAGE_NAME:-diagnostic-tool}

# Fail early with a clear message if the image has not been built.
if ! docker image inspect "$IMAGE_NAME" >/dev/null 2>&1; then
    printf 'Error: Docker image "%s" is not available. Build it first.\n' \
        "$IMAGE_NAME" >&2
    exit 1
fi

failures=0

# Run one container command and check both its exit code and expected output.
check_command() {
    local description=$1
    local expected_status=$2
    local expected_text=$3
    shift 3

    local output
    local actual_status

    if output=$(docker run --rm "$IMAGE_NAME" "$@" 2>&1); then
        actual_status=0
    else
        actual_status=$?
    fi

    if (( actual_status == expected_status )) &&
        [[ $output == *"$expected_text"* ]]
    then
        printf 'PASS: %s\n' "$description"
    else
        printf 'FAIL: %s\n' "$description" >&2
        printf '  Expected exit code: %s; got: %s\n' \
            "$expected_status" "$actual_status" >&2
        printf '  Expected output to include: %s\n' "$expected_text" >&2
        printf '  Actual output:\n%s\n' "$output" >&2
        failures=$((failures + 1))
    fi
}

check_command "help command" 0 "Usage:" help
check_command "system command" 0 "Hostname:" system
check_command "disk command" 0 "Filesystem" disk
check_command "invalid command returns exit code 2" 2 "Error:" not-a-command

if (( failures > 0 )); then
    printf '\nTests failed: %d\n' "$failures" >&2
    exit 1
fi

printf '\nAll Docker CLI tests passed.\n'
