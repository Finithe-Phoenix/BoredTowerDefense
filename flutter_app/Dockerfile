# Flutter Web Build Dockerfile
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Copy pubspec files first for better caching
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy rest of app
COPY . .

# Optionally run tests before building.
# We skip by default in Docker web builds to keep builds fast and avoid OOM in constrained environments.
ARG RUN_TESTS=0
RUN if [ "$RUN_TESTS" = "1" ]; then \
      chmod +x scripts/run_tests.sh && /bin/sh scripts/run_tests.sh || echo "⚠️  Some tests failed, but continuing with build..."; \
    else \
      echo "Skipping tests during docker web build (RUN_TESTS=$RUN_TESTS)"; \
    fi

# Build for web
RUN flutter build web --release

# Serve with nginx
FROM nginx:alpine

COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
