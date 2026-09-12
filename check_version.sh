#!/usr/bin/env bash
set -Eeu

readonly MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly REGEX="image_name\": \"(.*)\""
readonly JSON=`cat ${MY_DIR}/docker/image_name.json`
[[ ${JSON} =~ ${REGEX} ]]
readonly IMAGE_NAME="${BASH_REMATCH[1]}"

# The image installs whatever alcotest the alpine package index holds when it
# is built and records it in /versions.json, so the expected version is read
# from the image rather than written down here. Writing it down here would pin
# the image to a release chosen when someone last edited this file.
readonly VERSIONS=$(docker run --rm ${IMAGE_NAME} sh -c 'cat /versions.json')
readonly VERSION_REGEX='"alcotest":"([0-9.]+)"'
if [[ ! ${VERSIONS} =~ ${VERSION_REGEX} ]]; then
  echo "VERSION ERROR: /versions.json has no alcotest property"
  echo "VERSION   FILE: ${VERSIONS}"
  exit 42
fi
readonly EXPECTED="${BASH_REMATCH[1]}"

# Asks findlib the same question the compiler asks during a kata, so the gate
# fails both when the number recorded at build time is wrong and when the
# package has become unresolvable.
readonly ACTUAL=$(docker run --rm ${IMAGE_NAME} sh -c "ocamlfind query -format '%v' alcotest")

if [ "${ACTUAL}" == "${EXPECTED}" ]; then
  echo "VERSION CONFIRMED as ${EXPECTED}"
else
  echo "VERSION EXPECTED: ${EXPECTED}"
  echo "VERSION   ACTUAL: ${ACTUAL}"
  exit 42
fi
