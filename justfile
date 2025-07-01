prereqs:
    brew install vegeta k3d kubectl k9s trivy cosign
    which ddev || curl -fsSL https://ddev.com/install.sh | bash

build: prereqs
    # Ensure ddev is configured for hardened images and rebuilds the web service
    ddev config global --use-hardened-images --omit-containers=ddev-ssh-agent,ddev-router
    ddev debug rebuild --service web
    ddev poweroff

ddev_repo := `docker images ddev/ddev-webserver-prod:*-drupal-built --format '{{.Repository}}'`
export ddev_tag := `docker images ddev/ddev-webserver-prod:*-drupal-built --format '{{.Tag}}'`
local_repo := "ghcr.io/wagov-dtt/apache-fpm-webserver"

local_image:
    @echo {{local_repo}}:${ddev_tag%%-*}

tag-local-image:
    echo `just local_image` | grep "apache-fpm-webserver" # Check image has been built or exit
    docker image tag {{ddev_repo}}:{{ddev_tag}} `just local_image`
    if [ -n "$CI" ]; then cosign sign --yes `just local_image`; fi
    

k3d: tag-local-image
    mkdir -p volumes
    k3d cluster start || k3d cluster create --volume {{absolute_path("volumes")}}:/var/lib/rancher/k3s/storage@all
    k3d image import `just local_image`
    kubectl apply -k kustomize

trivy-scan: tag-local-image
    #!/bin/bash
    if [ -n "$CI" ]; then
        trivy image --format sarif --output trivy-results.sarif --severity HIGH,CRITICAL `just local_image`
        echo "Trivy scan results saved to trivy-results.sarif for GitHub Security tab upload."
    else
        trivy image --severity HIGH,CRITICAL `just local_image`
        echo "Trivy scan complete (console output)."
    fi

push: trivy-scan
    docker push `just local_image`
    echo "Image `just local_image` pushed successfully!"    

# Vegeta command for load testing
vegeta-ddev HOST:
    echo "GET $(ddev describe -j | jq -r .raw.primary_url)/" | vegeta attack -header "Host: {{HOST}}" -duration=10s -rate=500 | vegeta report -type=text
