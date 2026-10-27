#!/usr/bin/env bash

# Resolve the project root so the grader can be run from any directory.
set -uo pipefail
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
IMAGE_NAME=${IMAGE_NAME:-diagnostic-tool}
failures=0

pass() {
    printf 'PASS: %s\n' "$1"
}

fail() {
    printf 'FAIL: %s\n' "$1" >&2
    failures=$((failures + 1))
}

# Check the files required by Assignment 2.
required_files=(
    README.md
    app/diagnostic.sh
    app/health-check.sh
    Dockerfile
    compose.yaml
    .dockerignore
    test.sh
    grade.sh
)

for file in "${required_files[@]}"; do
    if [[ -f $PROJECT_DIR/$file ]]; then
        pass "required file exists: $file"
    else
        fail "missing required file: $file"
    fi
done

# Check the Bash files for syntax and executable permissions.
scripts=(
    app/diagnostic.sh
    app/health-check.sh
    test.sh
    grade.sh
)

for script in "${scripts[@]}"; do
    if bash -n "$PROJECT_DIR/$script"; then
        pass "Bash syntax: $script"
    else
        fail "Bash syntax: $script"
    fi

    if [[ -x $PROJECT_DIR/$script ]]; then
        pass "executable permission: $script"
    else
        fail "not executable: $script"
    fi
done

# Ensure Compose can parse its configuration.
if docker compose -f "$PROJECT_DIR/compose.yaml" config -q; then
    pass "Docker Compose configuration"
else
    fail "Docker Compose configuration is invalid"
fi

# Build the image that the command and student tests will use.
if docker build -t "$IMAGE_NAME" "$PROJECT_DIR"; then
    pass "Docker image build"
else
    fail "Docker image build"
fi

# Test basic image commands and the invalid-command exit status.
check_container_command() {
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
        pass "$description"
    else
        fail "$description (expected exit $expected_status and output containing '$expected_text'; got exit $actual_status)"
        printf '%s\n' "$output" >&2
    fi
}

check_container_command "container help command" 0 "Usage:" help
check_container_command "container system command" 0 "Hostname:" system
check_container_command "container disk command" 0 "Filesystem" disk
check_container_command "invalid command returns exit code 2" 2 "Error:" not-a-command

# Run the project's test suite against the image.
if IMAGE_NAME="$IMAGE_NAME" "$PROJECT_DIR/test.sh"; then
    pass "student Docker test suite"
else
    fail "student Docker test suite"
fi

if (( failures > 0 )); then
    printf '\nGrading checks found %d issue(s).\n' "$failures" >&2
    exit 1
fi

printf '\nAll grading checks passed.\n'
