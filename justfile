prereqs:
    brew install vegeta k3d kubectl k9s
    which ddev || curl -fsSL https://ddev.com/install.sh | bash

ddev-image := `docker images ddev/ddev-webserver-prod:*-drupal-built --format json | jq`
ddev-repo := shell("echo $1 | jq -r .Repository", ddev-image)
ddev-tag := shell("echo $1 | jq -r .Tag", ddev-image)
local-image := shell("echo ghcr.io/wagov-dtt/apache-fpm-webserver:$(echo " + ddev-tag + " | cut -d- -f1)")

k3d:
    mkdir -p volumes
    k3d cluster start || k3d cluster create --volume {{absolute_path("volumes")}}:/var/lib/rancher/k3s/storage@all
    k3d image import {{local-image}}
    kubectl apply -k kustomize

ddev-build:
    ddev config global --use-hardened-images --omit-containers=ddev-ssh-agent,ddev-router
    ddev debug rebuild --service web
    ddev poweroff
    docker image tag {{ddev-repo}}:{{ddev-tag}} {{local-image}}

vegeta-ddev HOST:
    echo "GET $(ddev describe -j | jq -r .raw.primary_url)/" | vegeta attack -header "Host: {{HOST}}" -duration=10s -rate=500 | vegeta report -type=text
