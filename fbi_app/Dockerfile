# Multi-stage build for Flutter web app
# Stage 1: Build the Flutter web app
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec files
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy the rest of the app
COPY . .

# Build the web app
RUN flutter build web --release

# Stage 2: Serve with nginx
FROM nginx:alpine

# Install envsubst for environment variable substitution
RUN apk add --no-cache gettext

# Copy built files from Flutter build stage
COPY --from=build /app/build/web /usr/share/nginx/html

# Create nginx template configuration
RUN echo 'server { \
    listen ${PORT}; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/templates/default.conf.template

# Create startup script that reads PORT env var
RUN echo '#!/bin/sh' > /start.sh && \
    echo 'set -e' >> /start.sh && \
    echo 'PORT=${PORT:-8080}' >> /start.sh && \
    echo 'envsubst '"'"'${PORT}'"'"' < /etc/nginx/templates/default.conf.template > /etc/nginx/conf.d/default.conf' >> /start.sh && \
    echo 'exec nginx -g "daemon off;"' >> /start.sh && \
    chmod +x /start.sh

# Expose port (Railway will set PORT env var)
EXPOSE 8080

# Start nginx with dynamic port
CMD ["/start.sh"]
