# Use Node.js 16 as base image
FROM node:16

# Set working directory
WORKDIR /app

# Copy package.json and install dependencies
COPY package*.json ./
RUN npm install --production

# Copy app source code
COPY . .

# Expose port
EXPOSE 8080

# Start the app
CMD ["npm", "start"]
