prereqs:
  brew install vegeta

ddev:
    which ddev || curl -fsSL https://ddev.com/install.sh | bash
    ddev config global --use-hardened-images --omit-containers=ddev-ssh-agent,ddev-router
    ddev debug rebuild --service web
    ddev status

vegeta-ddev HOST:
    echo "GET $(ddev describe -j | jq -r .raw.primary_url)/" | vegeta attack -header "Host: {{HOST}}" -duration=10s -rate=500 | vegeta report -type=text

