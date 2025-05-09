FROM nginx:1.25-alpine

# Copy nginx configuration template
COPY docker/nginx/default.conf.template /etc/nginx/templates/default.conf.template

# Copy SSL certificate generation script
COPY docker/nginx/entrypoint.sh /docker-entrypoint.d/30-ssl-cert.sh
RUN chmod +x /docker-entrypoint.d/30-ssl-cert.sh

# Create directories for Let's Encrypt
RUN mkdir -p /etc/letsencrypt/live

# Install certbot for SSL certificate generation
RUN apk add --no-cache certbot openssl

EXPOSE 80 443 