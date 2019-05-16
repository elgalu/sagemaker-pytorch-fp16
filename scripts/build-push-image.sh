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
[ -z "${TRAVIS_BUILD_NUMBER}" ] && die "Need env var TRAVIS_BUILD_NUMBER"
[ -z "${CUDA_BASE_VER}" ] && die "Need env var CUDA_BASE_VER"
[ -z "${CUDA_BASE_VER_NO_DOTS}" ] && die "Need env var CUDA_BASE_VER_NO_DOTS"
[ -z "${1}" ] && die "Need script first argument as build level ('0' / '1' / '2')"
BUILD_LEVEL="${1}"

if [ "${BUILD_LEVEL}" == "2" ]; then
  _target_repo="elgalu/pytorch-1.1.0-gpu-py3:${TRAVIS_BUILD_NUMBER}"
else
  _target_repo="elgalu/pytorch-base${BUILD_LEVEL}-1.1.0-gpu-py3:${TRAVIS_BUILD_NUMBER}"
fi

touch local_build.log

( while true; do tail -n 20 local_build.log; sleep 120; done ) &

# We need to send the output to a log file because Travis has a 10k log limit
docker build -t "${_target_repo}" \
  -f "docker/Dockerfile.${BUILD_LEVEL}.gpu" \
  --build-arg CUDA_BASE_VER=${CUDA_BASE_VER} \
  --build-arg CUDA_BASE_VER_NO_DOTS=${CUDA_BASE_VER_NO_DOTS} \
  --build-arg TRAVIS_BUILD_NUMBER=${TRAVIS_BUILD_NUMBER} \
  . > local_build.log

# Let's push this image to re-use it in TravisCI stages
# in order to speed up the build
[ "${DOCKER_USERNAME}" == "" ] && die "Need env var DOCKER_USERNAME to push to docker"
[ "${DOCKER_PASSWORD}" == "" ] && die "Need env var DOCKER_PASSWORD to push to docker"

docker login -u="${DOCKER_USERNAME}" -p="${DOCKER_PASSWORD}"
echo "Logged in to docker with user '${DOCKER_USERNAME}'"

tail -n 20 local_build.log

# https://cloud.docker.com/repository/docker/elgalu/pytorch-base-1.1.0-gpu-py3/general
docker push "${_target_repo}"
