#!/usr/bin/env bash

# Confirm that the diagnostic CLI's required commands are installed.
required_commands=(
    awk
    df
    free
    getent
    hostname
    ping
    uname
    uptime
)

for command_name in "${required_commands[@]}"; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf 'Health check failed: required command is missing: %s\n' \
            "$command_name" >&2
        exit 1
    fi
done

printf 'Health check passed: required diagnostic commands are available.\n'
