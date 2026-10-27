# Dockerized Diagnostic CLI

A Bash diagnostic command-line application packaged in Docker. It displays Linux system and disk information, and resolves and checks a network host. Everything runs locally; no cloud deployment is required.

## Requirements

- Docker with Docker Compose
- Bash for running the local test and grading scripts

The Dockerfile uses Debian Bookworm Slim and installs the packages required by the application.

## Build the image

From the repository root:

```bash
docker build -t diagnostic-tool .
```

## Usage

Run the CLI in a temporary container:

```bash
docker run --rm diagnostic-tool help
docker run --rm diagnostic-tool system
docker run --rm diagnostic-tool disk
docker run --rm diagnostic-tool network localhost
```

The available commands are:

- `system` — display hostname, operating system, kernel, architecture, uptime, and memory.
- `network <host>` — resolve a hostname or IP address and try a ping.
- `disk` — display filesystem usage.
- `help` — display the command list.

The network check requires DNS resolution and a successful ping. A host may resolve but not respond to ping, depending on its network or firewall settings.

## Docker Compose

Compose builds the image from the project directory and lets you run the same commands:

```bash
docker compose run --rm diagnostic help
docker compose run --rm diagnostic system
docker compose run --rm diagnostic disk
docker compose run --rm diagnostic network localhost
```

Check that the Compose file is valid with:

```bash
docker compose config
```

## Exit codes

- `0` — command completed successfully.
- `1` — an operational check failed, such as host resolution or connectivity.
- `2` — the command or its arguments are invalid.

## Health check

The image's Docker health check verifies that commands required by the diagnostic scripts are available inside the container. Docker runs this check periodically while the container is running.

To run the check manually:

```bash
docker run --rm --entrypoint /app/health-check.sh diagnostic-tool
```

## Testing and grading

Build the image before running the standalone test suite:

```bash
./test.sh
```

The tests cover help, system information, disk information, and invalid-command handling.

Run the local grader to check the required files, Bash syntax, executable permissions, Docker Compose configuration, image build, container commands, and student test suite:

```bash
./grade.sh
```

The grader builds the image as part of its checks.

## Assumptions and limitations

- The image must be built locally before running `test.sh`.
- The network command depends on DNS and ICMP ping being available from the host's network environment.
- Disk information inside the container describes the container's visible filesystem and mounts; it may differ from the host's full disk view.
- The project does not deploy to a cloud service.

## Git and submission

Use clear commits as you build the project. Before submitting, clone the repository into a clean directory and run `./grade.sh`.

Do not commit passwords, tokens, private keys, or other secrets.
