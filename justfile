# Variables for image management
ddev_repo := `docker images ddev/ddev-webserver-prod:*-drupal-built --format '{{.Repository}}'`
export ddev_tag := `docker images ddev/ddev-webserver-prod:*-drupal-built --format '{{.Tag}}'`
local_repo := "ghcr.io/wagov-dtt/apache-fpm-webserver"

# Install required tools
prereqs:
    brew install vegeta k3d kubectl k9s trivy cosign
    which ddev || curl -fsSL https://ddev.com/install.sh | bash

# Build hardened DDEV image with custom configuration
build: prereqs
    ddev config global --use-hardened-images --omit-containers=ddev-ssh-agent,ddev-router
    ddev debug rebuild --service web
    ddev poweroff

# Get the local image name
local_image:
    @echo {{local_repo}}:${ddev_tag%%-*}

# Tag built image for registry and sign if in CI
tag-local-image:
    @echo "Tagging image: `just local_image`"
    docker image tag {{ddev_repo}}:{{ddev_tag}} `just local_image`
    @if [ -n "${CI:-}" ]; then cosign sign --yes `just local_image`; fi

# Deploy to local k3d cluster
k3d: tag-local-image
    mkdir -p volumes
    k3d cluster start || k3d cluster create --volume {{absolute_path("volumes")}}:/var/lib/rancher/k3s/storage@all
    k3d image import `just local_image`
    kubectl apply -k kustomize

# Run security scan (SARIF format in CI, console locally)
trivy-scan: tag-local-image
    #!/bin/bash
    if [ -n "${CI:-}" ]; then
        trivy image --format sarif --output trivy-results.sarif --severity HIGH,CRITICAL `just local_image`
        echo "Trivy scan results saved to trivy-results.sarif"
    else
        trivy image --severity HIGH,CRITICAL `just local_image`
        echo "Trivy scan complete"
    fi

# Push signed image to registry (CI only)
push: trivy-scan
    docker push `just local_image`
    @echo "Image pushed: `just local_image`"

# Load test DDEV environment
vegeta-ddev HOST:
    echo "GET $(ddev describe -j | jq -r .raw.primary_url)/" | vegeta attack -header "Host: {{HOST}}" -duration=10s -rate=500 | vegeta report -type=text
