#!/bin/bash
# Wrapper script to source environment variables and run a command
# This ensures supervisor-managed processes receive all environment variables

set -e

ENV_FILE="/etc/mise.env"

# Source environment file if it exists
if [ -f "$ENV_FILE" ]; then
    set -a  # Automatically export all variables
    source "$ENV_FILE"
    set +a
fi

# Execute the command passed as arguments
exec "$@"
