#!/usr/bin/env bash
set -Eeu

readonly MY_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
readonly REGEX="image_name\": \"(.*)\""
readonly JSON=`cat ${MY_DIR}/docker/image_name.json`
[[ ${JSON} =~ ${REGEX} ]]
readonly IMAGE_NAME="${BASH_REMATCH[1]}"

# Written down here so the gate fails when alpine moves to a different
# alcotest. Reading it from the image instead would compare the image against
# itself and pass whatever the move brought in. The exact version the image
# holds is recorded in its /versions.json.
readonly EXPECTED=1.5

# Asks findlib the same question the compiler asks during a kata, so the gate
# fails both when the alcotest a kata links against is not the one named above
# and when the package has become unresolvable. Matching on the leading
# major.minor lets a patch release through and stops only a minor or major
# move. The trailing dots stop 1.5 matching 1.50.
readonly ACTUAL=$(docker run --rm ${IMAGE_NAME} sh -c "ocamlfind query -format '%v' alcotest")

if [[ "${ACTUAL}." == "${EXPECTED}."* ]]; then
  echo "VERSION CONFIRMED as ${EXPECTED}"
else
  echo "VERSION EXPECTED: ${EXPECTED}"
  echo "VERSION   ACTUAL: ${ACTUAL}"
  exit 42
fi
