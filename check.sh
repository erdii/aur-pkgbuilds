#!/bin/bash
set -uo pipefail

aur-out-of-date \
  -config aur-out-of-date.json \
  -update \
  -local packages/*/.SRCINFO

changed="0"

for package in packages/*; do
  echo "> checking $package"

  set +e
  git diff --quiet HEAD -- $package
  diff_code=$?
  set -e
  if [[ $diff_code == 0 ]]; then
    continue
  fi

  echo "> updating $package"
  changed="1"

  pushd $package
  updpkgsums
  sed -r 's/(.*)(pkgrel=)([0-9]+)(.*)/echo "\1\2$((\3+1))\4"/ge' PKGBUILD | sponge PKGBUILD
  makepkg --printsrcinfo > .SRCINFO
  makepkg
  git add .SRCINFO PKGBUILD

  new_version="$(grep 'pkgver' .SRCINFO | sed 's/pkgver =//' | sed -e 's/^[[:space:]]*//')"
  git commit -m "[automated] $new_version"
  popd

  git add $package
  pkgname=$(basename $package)
  git commit -m "[automated] $pkgname $new_version"

  pushd $package
  git push origin master
  popd
done

if [[ $changed == "1" ]]; then
  git push
fi
