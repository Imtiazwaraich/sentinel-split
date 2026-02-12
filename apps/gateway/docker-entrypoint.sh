#!/bin/sh
set -e

# Substitute environment variables in nginx config
envsubst '${BACKEND_SERVICE_HOST} ${BACKEND_SERVICE_PORT}' < /etc/nginx/nginx.conf.template > /etc/nginx/nginx.conf

# Execute the command passed to the script
exec "$@"
