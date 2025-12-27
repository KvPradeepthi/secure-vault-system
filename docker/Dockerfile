FROM node:18-alpine

WORKDIR /app

# Copy package files
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy all project files
COPY . .

# Make entrypoint script executable
RUN chmod +x ./docker/entrypoint.sh

# Expose RPC port
EXPOSE 8545

# Run entrypoint script
CMD ["sh", "./docker/entrypoint.sh"]
