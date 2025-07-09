# AGENT.md - Apache FPM Webserver Project

## Build/Test Commands
- `just build` - Build DDEV hardened image with custom configuration
- `just k3d` - Deploy to local k3d cluster with persistent storage
- `just trivy-scan` - Run Trivy security scan (SARIF in CI, console locally)
- `just push` - Security scan and push signed image to GHCR (CI only)
- `just vegeta-ddev HOST` - Load test DDEV environment with Vegeta
- `ddev describe` - Show DDEV project details and URLs

## Architecture & Structure
- **Container Platform**: DDEV-based Apache + PHP-FPM webserver for Drupal 11
- **Base Image**: Hardened ddev/ddev-webserver-prod:v1.24.6
- **User Management**: Build user configurable, runtime always uid 1000 for K8s
- **Deployment**: Kubernetes manifests in `/kustomize/` for k3d local clusters
- **Storage**: Persistent volumes for web content in `/var/www/html`
- **Security**: Cosign image signing, Trivy vulnerability scanning, hardened containers

## Code Style & Conventions
- **Configuration**: YAML files use standard 2-space indentation
- **Justfile**: Use kebab-case for recipe names, group variables at top
- **Docker**: Apache runs on port 80, PHP-FPM backend, non-root user (1000:1000)
- **Kubernetes**: Use app and environment labels, local-path storage class
- **Security**: Always scan images before push, sign with Cosign in CI
