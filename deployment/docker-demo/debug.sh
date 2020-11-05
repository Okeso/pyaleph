#!/bin/bash

# Use this script to run the Docker image of PyAleph

set -euo pipefail

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

cd "$SCRIPT_DIR/../.."

# Use Podman if installed, else use Docker
if hash podman 2> /dev/null
then
  DOCKER_COMMAND=podman
else
  DOCKER_COMMAND=docker
fi

if [ ! -f "$(pwd)/node-secret.key" ]; then
    touch "$(pwd)/node-secret.key"
fi

# Set container user podman as owner of the key
$DOCKER_COMMAND run --name pyaleph --rm --user root \
  -v "$(pwd)/node-secret.key:/opt/pyaleph/node-secret.key" \
  aleph.im/pyaleph-demo chown aleph:aleph /opt/pyaleph/node-secret.key

$DOCKER_COMMAND run --name pyaleph --rm --user ipfs \
  -v "$(pwd)/node-secret.key:/opt/pyaleph/node-secret.key" \
  aleph.im/pyaleph-demo ipfs init

# Run with source mounted in the container
$DOCKER_COMMAND run --name pyaleph \
  --rm -ti \
  -p 8081:8081 \
  -p 0.0.0.0:4024:4024 \
  -p 0.0.0.0:4025:4025 \
  -p 4001:4001 \
  -p 5001:5001 \
  -p 8080:8080 \
  --mount type=tmpfs,destination=/var/log \
  -v pyaleph-mongodb:/var/lib/mongodb \
  -v pyaleph-ipfs:/var/lib/ipfs \
  -v "$(pwd)/config.yml:/opt/pyaleph/config.yml" \
  -v "$(pwd)/node-secret.key:/opt/pyaleph/node-secret.key" \
  -v "$(pwd)/src:/opt/pyaleph/src" \
  aleph.im/pyaleph-demo "$@"
