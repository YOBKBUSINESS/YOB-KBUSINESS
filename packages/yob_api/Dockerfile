# ──────────────────────────────────────────────────────────────
# YOB K Business API — Multi-stage Docker build
# ──────────────────────────────────────────────────────────────

# Stage 1: Install dependencies and build
FROM dart:3.6 AS build

WORKDIR /app

# Copy workspace files
COPY pubspec.yaml pubspec.yaml
COPY melos.yaml melos.yaml
COPY packages/yob_core/pubspec.yaml packages/yob_core/pubspec.yaml
COPY packages/yob_api/pubspec.yaml packages/yob_api/pubspec.yaml

# Install dependencies (cached layer)
RUN dart pub global activate melos && \
    cd packages/yob_core && dart pub get && \
    cd /app/packages/yob_api && dart pub get

# Copy source code
COPY packages/yob_core/ packages/yob_core/
COPY packages/yob_api/ packages/yob_api/

# Build dart_frog production server
WORKDIR /app/packages/yob_api
RUN dart pub global activate dart_frog_cli && \
    dart pub global run dart_frog build

# Stage 2: Production image
FROM dart:3.6-runtime AS production

WORKDIR /app

# Copy built server from build stage
COPY --from=build /app/packages/yob_api/build/ ./build/
COPY --from=build /app/packages/yob_api/db/ ./db/

# Expose port
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD curl -f http://localhost:8080/ || exit 1

# Run production server
ENTRYPOINT ["dart", "build/bin/server.dart"]
