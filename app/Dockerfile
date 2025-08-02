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

# Copy optional files if they exist
COPY public ./public/ 2>/dev/null || mkdir -p public
COPY .env* ./ 2>/dev/null || echo "No .env files found"

# Builder stage
FROM base AS builder

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

# Copy environment files if they exist
COPY --from=builder /app/.env* ./ 2>/dev/null || echo "No .env files to copy"

# Set environment variables
ENV NODE_ENV=production
ENV PORT=3000
ENV PROJECT_SLUG=${PROJECT_SLUG:-launchkit}

# Expose port
EXPOSE 3000

# Start the application
CMD ["npm", "start"] 