# Use a small Debian image as the Linux base.
FROM debian:bookworm-slim

# Install only the commands used by the diagnostic scripts.
# Remove apt's package lists afterward to reduce the image size.
RUN apt-get update \
    && apt-get install --no-install-recommends -y \
        mawk \
        bash \
        coreutils \
        hostname \
        iputils-ping \
        libc-bin \
        procps \
    && rm -rf /var/lib/apt/lists/*

# Keep the application files together in the image.
WORKDIR /app

# Copy the CLI and its health check into the image.
COPY app/diagnostic.sh app/health-check.sh ./

# Make both scripts executable in the image.
RUN chmod +x diagnostic.sh health-check.sh

# Let Docker report whether the required utilities are available.
HEALTHCHECK --interval=30s --timeout=5s --start-period=5s --retries=3 \
    CMD ["/app/health-check.sh"]

# Treat container arguments as CLI arguments, e.g. `docker run IMAGE system`.
ENTRYPOINT ["/app/diagnostic.sh"]

# Show help if the user starts the container without a command.
CMD ["help"]
