#!/bin/sh -eu

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

readonly OCAML_VERSION=$(sed --quiet 's/.*"ocaml":"\([0-9.]*\)".*/\1/p' /versions.json)

# findlib is asked what it actually resolves the name alcotest to, which is the
# same question the compiler asks during a kata, so a version recorded here is
# one a kata can really link against.
readonly ALCOTEST_VERSION=$(ocamlfind query -format '%v' alcotest)

if [ -z "${ALCOTEST_VERSION}" ]; then
  echo 'findlib cannot resolve the alcotest package' >&2
  exit 1
fi

echo "{\"ocaml\":\"${OCAML_VERSION}\",\"alcotest\":\"${ALCOTEST_VERSION}\"}" > /versions.json

rm -rf /var/cache/apk/*
