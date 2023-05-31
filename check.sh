#!/bin/bash
set -uo pipefail

aur-out-of-date \
  -config aur-out-of-date.json \
  -update \
  -local packages/*/.SRCINFO

for package in packages/*; do
  echo "> checking $package"

  pushd "$package"
  set +e
  git diff --quiet HEAD
  diff_code=$?
  set -e

  if [[ $diff_code == 0 ]]; then
    popd
    continue
  fi

  echo "> updating $package"

  updpkgsums
  sed -r 's/(.*)(pkgrel=)([0-9]+)(.*)/echo "\1\2$((\3+1))\4"/ge' PKGBUILD | sponge PKGBUILD
  makepkg --printsrcinfo > .SRCINFO
  makepkg
  git add .SRCINFO PKGBUILD

  new_version="$(grep 'pkgver' .SRCINFO | sed 's/pkgver =//' | sed -e 's/^[[:space:]]*//')"
  git commit -m "[automated] $new_version"
  git push origin master
  popd
done
