#!/bin/bash
set -e

# Remove um possível PID antigo
rm -f /app/tmp/pids/server.pid

exec "$@"
