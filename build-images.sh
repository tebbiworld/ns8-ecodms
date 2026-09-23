#!/bin/bash

#
# Copyright (C) 2026 tebbi
# SPDX-License-Identifier: GPL-3.0-or-later
#

set -e

images=()
repobase="${REPOBASE:-ghcr.io/tebbiworld}"
reponame="ecodms"

# Pin the ecoDMS all-in-one server image (ecoDMS 26.01 "burns"). Declared in the
# org.nethserver.images label so the node pre-pulls it and exposes it to the
# systemd unit as ${ECODMS_IMAGE}.
ecodms_image="docker.io/ecodms/ecodms:26.01-02"

container=$(buildah from scratch)

if ! buildah containers --format "{{.ContainerName}}" | grep -q nodebuilder-ecodms; then
    echo "Pulling NodeJS runtime..."
    buildah from --name nodebuilder-ecodms -v "${PWD}:/usr/src:Z" docker.io/library/node:24.16.0-slim
fi

echo "Build static UI files with node..."
buildah run \
    --workingdir=/usr/src/ui \
    --env="NODE_OPTIONS=--openssl-legacy-provider" \
    nodebuilder-ecodms \
    sh -c "yarn install && yarn build"

buildah add "${container}" imageroot /imageroot
buildah add "${container}" ui/dist /ui
# Reserve one TCP port for the web interface (container 8080), fronted by
# Traefik. The ecoDMS server ports 17001-17004 (Connection Manager / DB) are
# fixed and published directly on the node, as they use ecoDMS' own non-HTTP
# transport that Traefik can not route.
# One instance per node: the ecoDMS client ports 17001-17004 are published on the node.
# The bulk-data volumes can be placed on an additional disk at install time.
buildah config --entrypoint=/ \
    --label="org.nethserver.authorizations=traefik@node:routeadm" \
    --label="org.nethserver.tcp-ports-demand=1" \
    --label="org.nethserver.rootfull=0" \
    --label="org.nethserver.images=${ecodms_image}" \
    --label="org.nethserver.max-per-node=1" \
    --label="org.nethserver.volumes=ecodms-data ecodms-backup" \
    "${container}"
buildah commit "${container}" "${repobase}/${reponame}"

images+=("${repobase}/${reponame}")

if [[ -n "${CI}" ]]; then
    printf "images=%s\n" "${images[*],,}" >> "${GITHUB_OUTPUT}"
else
    printf "Publish the images with:\n\n"
    for image in "${images[@],,}"; do printf "  buildah push %s docker://%s:%s\n" "${image}" "${image}" "${IMAGETAG:-latest}" ; done
    printf "\n"
fi
