#!/bin/sh

set -e

# Check if we need to generate a self-signed certificate (for development or initial setup)
if [ ! -f "/etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem" ]; then
    echo "SSL certificate not found, generating self-signed certificate..."
    
    # Create directory if it doesn't exist
    mkdir -p /etc/letsencrypt/live/${DOMAIN_NAME}
    
    # Generate self-signed certificate
    openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
        -keyout /etc/letsencrypt/live/${DOMAIN_NAME}/privkey.pem \
        -out /etc/letsencrypt/live/${DOMAIN_NAME}/fullchain.pem \
        -subj "/CN=${DOMAIN_NAME}"
    
    echo "Self-signed certificate generated successfully"
fi

# For production, we would set up a cron job to renew Let's Encrypt certificates
# This can be expanded later when moving to production 