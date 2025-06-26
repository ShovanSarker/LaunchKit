FROM node:20-alpine AS builder

WORKDIR /app

# Install dependencies
COPY package*.json ./
RUN npm install

# Copy source code and config files
COPY tsconfig.json ./
COPY next.config.js ./

# Create necessary directories
RUN mkdir -p public src

# Copy source files
COPY src ./src/

# Copy public directory if it exists (using a shell script)
RUN mkdir -p public && \
    if [ -d "./public" ]; then \
      cp -r ./public/* ./public/ || true; \
    fi

# Copy environment file if it exists
COPY .env* ./ || true

# Build the application
RUN npm run build

# Production image
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
COPY --from=builder /app/.env* ./ || true

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV PROJECT_SLUG=${PROJECT_SLUG:-launchkit}

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"] 