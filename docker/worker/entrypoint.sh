#!/bin/bash

set -e

# Wait for RabbitMQ to be ready
until nc -z $RABBITMQ_HOST 5672; do
  >&2 echo "RabbitMQ is unavailable - sleeping"
  sleep 1
done

>&2 echo "RabbitMQ is up - executing command"

exec "$@" 