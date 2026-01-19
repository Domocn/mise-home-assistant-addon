#!/bin/bash
# Log wrapper that outputs to both file and stdout/stderr for Home Assistant add-on logs
# Usage: log-wrapper.sh <service-name> <command> [args...]

set -e

SERVICE_NAME=$1
shift

LOG_DIR="/var/log/mise"
STDOUT_LOG="${LOG_DIR}/${SERVICE_NAME}.log"
STDERR_LOG="${LOG_DIR}/${SERVICE_NAME}-error.log"

# Ensure log directory exists
mkdir -p "$LOG_DIR"

# Run command and tee output to both file and stdout/stderr
# Use process substitution to send stdout and stderr to separate files while also displaying them
exec > >(tee -a "$STDOUT_LOG")
exec 2> >(tee -a "$STDERR_LOG" >&2)

# Add timestamp prefix for logs
echo "[$(date '+%Y-%m-%d %H:%M:%S')] Starting $SERVICE_NAME: $*"

# Execute the actual command
exec "$@"
