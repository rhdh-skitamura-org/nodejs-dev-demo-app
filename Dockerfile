# Stage 1 - Install dependencies
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS deps

COPY package.json package-lock.json ./
RUN npm ci
RUN npm audit fix --force

# Stage 2 - Build the source code
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS builder

COPY . .
COPY --from=deps /opt/app-root/src/node_modules ./node_modules

USER root
RUN npm run build

# Stage 3 - Production image, copy all the files and start NodeJS
FROM registry.access.redhat.com/ubi9/nodejs-20-minimal:latest AS runner

COPY --from=deps --chown=1001:1001 /opt/app-root/src .
COPY --from=builder --chown=1001:1001 /opt/app-root/src/dist ./dist

ENV NODE_ENV production

# Update vulnerable package versions
USER root
RUN rm -rf /usr/lib/node_modules/nodemon 

# Switch to nodejs user
USER 1001

# Install production dependencies
RUN npm ci

ENV PORT 3000 
EXPOSE 3000 

CMD ["npm", "run", "start"]
