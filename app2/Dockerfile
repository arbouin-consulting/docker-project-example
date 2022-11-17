FROM node:19.1.0-alpine3.16

# Set the Node environment to development to ensure all packages are installed
ENV NODE_ENV development

# Change our current working directory
WORKDIR /app

# Copy over `package.json` and lock files to optimize the build process
COPY ["package.json", "package-lock.json*", "yarn.lock", "./"]
# Install Node modules
RUN yarn install

# Copy over rest of the project files
COPY . .

# Expose port 3000 for the SvelteKit app and 24678 for Vite's HMR
EXPOSE 5173

# Run `yarn dev` and set the host to 0.0.0.0 so we can access the web app from outside
CMD ["yarn", "dev", "--host", "0.0.0.0"]