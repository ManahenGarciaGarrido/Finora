# Finora Backend Dockerfile
FROM node:18-alpine

# Create app directory
WORKDIR /app

# Install dependencies first (for better caching)
COPY package*.json ./

RUN npm install --omit=dev

# Copy application source
COPY . .

# Create non-root user for security
RUN addgroup -g 1001 -S nodejs && \
    adduser -S finora -u 1001 -G nodejs

# Change ownership of app directory
RUN chown -R finora:nodejs /app

# Switch to non-root user
USER finora

# Expose port
EXPOSE 3000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3000/health || exit 1

# Start the application
CMD ["node", "server.js"]
