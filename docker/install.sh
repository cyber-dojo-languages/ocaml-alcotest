#!/bin/sh -eu

# Appends one test framework to the test_frameworks list the base image
# wrote in /versions.json, keeping any entry an earlier image added. Stops
# the build if the list is not found, rather than record nothing. Short grep
# flags because busybox grep has no long ones.
add_test_framework()
{
  name="${1}"
  version="${2}"
  entry="{\"name\": \"${name}\", \"version\": \"${version}\"}"
  if grep -q '"test_frameworks": \[\]' /versions.json; then
    sed -i "s|\"test_frameworks\": \[\]|\"test_frameworks\": [${entry}]|" /versions.json
  else
    sed -i "/\"test_frameworks\": \[/s|}\]|}, ${entry}]|" /versions.json
  fi
  if ! grep -q -F "${entry}" /versions.json; then
    echo "Could not add ${name} to /versions.json" >&2
    cat /versions.json >&2
    exit 1
  fi
}

# The -dev half is the one a kata needs: it carries the .cmi and .cma that the
# compiler reads and links against, where the plain package carries only what
# an already-built program needs at run time. apk pulls that half in as a
# dependency, so naming -dev asks for both.
#
# No version is named, so a rebuild installs whatever alcotest alpine is
# shipping by then. If alpine's alcotest ever stops matching the ocaml the base
# image holds, this fails with apk's own message and the build goes red, which
# is the honest outcome.
apk update
apk add ocaml-alcotest-dev

# findlib is asked what it actually resolves the name alcotest to, which is the
# same question the compiler asks during a kata, so a version recorded here is
# one a kata can really link against.
readonly ALCOTEST_VERSION=$(ocamlfind query -format '%v' alcotest)

if [ -z "${ALCOTEST_VERSION}" ]; then
  echo 'findlib cannot resolve the alcotest package' >&2
  exit 1
fi

add_test_framework Alcotest "${ALCOTEST_VERSION}"
cat /versions.json

rm -rf /var/cache/apk/*
