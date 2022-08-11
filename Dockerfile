FROM node:16-alpine as development

# Create app directory
WORKDIR /app

# Copy application dependency manifests to the container image.
# Copying this first prevents re-running npm install on every code change.
COPY package*.json ./
RUN npm install

FROM development as build

WORKDIR /app
COPY . .

RUN npm run build

FROM node:16-alpine as production

ENV NODE_ENV=production

# Copy the bundled code from the build stage to the production image
COPY --from=build /app/package*.json ./

# Running `npm ci` removes the existing node_modules directory and passing in --only=production
# ensures that only the production dependencies are installed.
# This ensures that the node_modules directory is as optimized as possible
RUN npm ci --only=production && npm cache clean --force
COPY --from=build /app/dist ./dist

USER node
ENV PORT=4000
EXPOSE 4000
# Start the server using the production build
CMD ["node", "dist/main.js"]
