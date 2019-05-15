#!/usr/bin/env bash

# set -e: exit asap if a command exits with a non-zero status
# set -x: print each command right before it is executed
set -xe

echoerr() { printf "%s\n" "$*" >&2; }

# print error and exit
die () {
  echoerr "ERROR: $1"
  # if $2 is defined AND NOT EMPTY, use $2; otherwise, set to "150"
  errnum=${2-188}
  exit $errnum
}

docker --version

if [[ ${TRAVIS_PULL_REQUEST_SLUG} != "" && \
      ${TRAVIS_PULL_REQUEST_SLUG} != ${TRAVIS_REPO_SLUG} && \
      ${TRAVIS_PULL_REQUEST} != "false" ]]; then
  echo "WARN: External PRs are untrusted by default therefore we need can't reuse and push the image"
  exit 0
fi

# Required env vars
[ -z "${CUDA_BASE_VER}" ] && die "Need env var CUDA_BASE_VER"

touch local_build.log

( while true; do tail -n 20 local_build.log; sleep 120; done ) &

# We need to send the output to a log file because Travis has a 10k log limit
docker build -t local-build-image-name \
  -f docker/1.1.0/base/Dockerfile.gpu \
  --build-arg CUDA_BASE_VER=${CUDA_BASE_VER} . \
  > local_build.log

if [ "${TRAVIS_BUILD_NUMBER}" != "" ]; then
  _target_repo="elgalu/pytorch-base-1.1.0-gpu-py3:${TRAVIS_BUILD_NUMBER}"

  # Let's push this image to re-use it in TravisCI stages
  # in order to speed up the build
  docker tag local-build-image-name "${_target_repo}"

  [ "${DOCKER_USERNAME}" == "" ] && die "Need env var DOCKER_USERNAME to push to docker"
  [ "${DOCKER_PASSWORD}" == "" ] && die "Need env var DOCKER_PASSWORD to push to docker"

  docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"
  echo "Logged in to docker with user '${DOCKER_USERNAME}'"

  # https://cloud.docker.com/repository/docker/elgalu/pytorch-base-1.1.0-gpu-py3/general
  docker push "${_target_repo}"
fi
