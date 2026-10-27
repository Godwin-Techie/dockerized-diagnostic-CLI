#!/usr/bin/env bash

# Print the supported commands and their arguments.
show_help() {
    cat <<'HELP'
Usage:
  diagnostic system
  diagnostic network <host>
  diagnostic disk
  diagnostic help
HELP
}

# Invalid commands and arguments use the assignment's exit code 2.
invalid_input() {
    printf 'Error: %s\n\n' "$1" >&2
    show_help >&2
    exit 2
}

# Check the command before accessing any arguments.
if (( $# == 0 )); then
    invalid_input "a command is required"
fi

command_name=$1
shift

case "$command_name" in
    help)
        if (( $# != 0 )); then
            invalid_input "'help' does not accept additional arguments"
        fi
        show_help
        ;;

    system)
        if (( $# != 0 )); then
            invalid_input "'system' does not accept additional arguments"
        fi

        # Read live system values rather than using machine-specific settings.
        printf 'Hostname: %s\n' "$(hostname)"
        printf 'Operating system: %s\n' "$(uname -s)"
        printf 'Kernel version: %s\n' "$(uname -r)"
        printf 'Architecture: %s\n' "$(uname -m)"
        printf 'Uptime: %s\n' "$(uptime -p 2>/dev/null || uptime)"
        printf 'Memory:\n'
        free -h
        ;;

    disk)
        if (( $# != 0 )); then
            invalid_input "'disk' does not accept additional arguments"
        fi

        # Show filesystem usage in human-readable units.
        df -h
        ;;

    network)
        if (( $# != 1 )); then
            invalid_input "'network' requires exactly one hostname or IP address"
        fi

        host=$1

        # Accept ordinary hostnames and common IPv4/IPv6 address characters.
        if (( ${#host} > 253 )) ||
            [[ ! $host =~ ^[A-Za-z0-9][A-Za-z0-9.-]*$ &&
               ! $host =~ ^[A-Fa-f0-9:.]+$ ]]
        then
            invalid_input "host contains invalid characters or is too long"
        fi

        # Resolve the host before attempting connectivity.
        if ! addresses=$(getent ahosts "$host" 2>/dev/null); then
            printf 'Error: could not resolve host: %s\n' "$host" >&2
            exit 1
        fi

        address=$(awk 'NR == 1 { print $1; exit }' <<< "$addresses")
        if [[ -z $address ]]; then
            printf 'Error: no address found for host: %s\n' "$host" >&2
            exit 1
        fi

        printf 'Host: %s\n' "$host"
        printf 'Resolved address: %s\n' "$address"

        # DNS resolution alone does not confirm that the host responds.
        if ! command -v ping >/dev/null 2>&1; then
            printf 'Error: ping is not installed.\n' >&2
            exit 1
        fi

        if ping -c 1 -W 2 "$host" >/dev/null 2>&1; then
            printf 'Connectivity: reachable\n'
        else
            printf 'Error: host did not respond to ping: %s\n' "$host" >&2
            exit 1
        fi
        ;;

    *)
        invalid_input "unknown command: $command_name"
        ;;
esac
