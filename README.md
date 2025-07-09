# apache-fpm-webserver
Hardened Apache + PHP-FPM builds based on ddev/ddev-webserver-prod.

## Quick Start

```bash
# Install dependencies and build image
just build

# Deploy to local k3d cluster
just k3d

# Security scan (optional)
just trivy-scan

# Push to registry (CI only)
just push
```

## Build Process

The build process creates a hardened DDEV container with:
- **Build User**: Configurable uid/gid (currently 1000) for build compatibility
- **Security**: Trivy vulnerability scanning and Cosign image signing
- **Deployment**: Kubernetes manifests for local k3d development
- **Error Handling**: Automatic log output on build failures for CI debugging

## Architecture

- **Base**: ddev/ddev-webserver-prod:v1.24.6 (hardened)
- **Runtime**: Apache 2.4 + PHP-FPM 8.3 + Drupal 11 support
- **Storage**: Persistent volumes for `/var/www/html` content
- **Security**: Non-root execution, signed images, vulnerability scanning

## Commands

See `just --list` for all available commands or check the [justfile](justfile) for details.