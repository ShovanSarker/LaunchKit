FROM node:20-alpine AS base

# Create app directory
WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy configuration files
COPY tsconfig.json ./
COPY next.config.js ./

# Create necessary directories
RUN mkdir -p public src

# Copy source files
COPY src ./src/

# Create a stage for handling optional files
FROM base AS optional-files

# Create a script to handle optional files
RUN echo '#!/bin/sh' > /copy-optional.sh && \
    echo 'mkdir -p /app/public' >> /copy-optional.sh && \
    echo 'if [ -d "/optional/public" ]; then cp -r /optional/public/* /app/public/ 2>/dev/null || true; fi' >> /copy-optional.sh && \
    echo 'if [ -f "/optional/.env" ]; then cp /optional/.env /app/.env; fi' >> /copy-optional.sh && \
    echo 'if [ -f "/optional/.env.local" ]; then cp /optional/.env.local /app/.env.local; fi' >> /copy-optional.sh && \
    chmod +x /copy-optional.sh

# Copy optional files to a temporary location
COPY public /optional/public/ 2>/dev/null || true
COPY .env* /optional/ 2>/dev/null || true

# Run the copy script
RUN /copy-optional.sh

# Builder stage
FROM base AS builder

# Copy files from optional-files stage
COPY --from=optional-files /app/public ./public/
COPY --from=optional-files /app/.env* ./ 2>/dev/null || true

# Build the application
RUN npm run build

# Production stage
FROM node:20-alpine AS runner

WORKDIR /app

# Create necessary directories
RUN mkdir -p public

# Copy necessary files from builder
COPY --from=builder /app/next.config.js ./
COPY --from=builder /app/public ./public/
COPY --from=builder /app/.next ./.next
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/.env* ./ 2>/dev/null || true

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV PROJECT_SLUG=${PROJECT_SLUG:-launchkit}

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"] 