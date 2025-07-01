prereqs:
    brew install vegeta k3d kubectl k9s trivy
    which ddev || curl -fsSL https://ddev.com/install.sh | bash

ddev-image := `docker images ddev/ddev-webserver-prod:*-drupal-built --format json | jq`
ddev-repo := shell("echo $1 | jq -r .Repository", ddev-image)
ddev-tag := shell("echo $1 | jq -r .Tag", ddev-image)
# Define the local-image variable with the correct GHCR path and tag
local-image := shell("echo ghcr.io/wagov-dtt/apache-fpm-webserver:$(echo " + ddev-tag + " | cut -d- -f1)")

k3d:
    mkdir -p volumes
    k3d cluster start || k3d cluster create --volume {{absolute_path("volumes")}}:/var/lib/rancher/k3s/storage@all
    k3d image import {{local-image}}
    kubectl apply -k kustomize

build: prereqs
    # Ensure ddev is configured for hardened images and rebuilds the web service
    ddev config global --use-hardened-images --omit-containers=ddev-ssh-agent,ddev-router
    ddev debug rebuild --service web
    ddev poweroff

tag-local-image:
    echo {{local-image}} | grep "apache-fpm-webserver" # Check image has been built or exit
    docker image tag {{ddev-repo}}:{{ddev-tag}} {{local-image}}

trivy-scan: tag-local-image
    #!/bin/bash
    if [ "${CI}" = "true" ]; then
        trivy image --format sarif --output trivy-results.sarif --severity HIGH,CRITICAL {{local-image}}
        echo "Trivy scan results saved to trivy-results.sarif for GitHub Security tab upload."
    else
        trivy image --severity HIGH,CRITICAL {{local-image}}
        echo "Trivy scan complete (console output)."
    fi

push: trivy-scan
    docker push {{local-image}}
    echo "Image {{local-image}} pushed successfully!"    

# Vegeta command for load testing
vegeta-ddev HOST:
    echo "GET $(ddev describe -j | jq -r .raw.primary_url)/" | vegeta attack -header "Host: {{HOST}}" -duration=10s -rate=500 | vegeta report -type=text
