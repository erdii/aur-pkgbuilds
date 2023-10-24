#!/bin/bash
set -euxo pipefail

OUTPATH="./.cache/packages"
export REPO_ROOT="$PWD"

mkdir -p "$OUTPATH"

packages="$(cat ./packages.txt | grep -vE '^#')"

pushd go
go build -o ../.cache/forked-aur-out-of-date ./cmd/forked-aur-out-of-date
popd

for package in $packages; do
  pkgpath="${OUTPATH:?}/$package"
  rm -rf "$pkgpath"
  git clone "aur@aur.archlinux.org:$package" "$pkgpath"

  pushd "$pkgpath"

  "$REPO_ROOT/.cache/forked-aur-out-of-date" \
    -config "$REPO_ROOT/aur-out-of-date.json" \
    -update \
    -local ".SRCINFO"

  # test if package repo is dirty (and thus was updated)
  set +e
  git diff --quiet HEAD
  diff_code="$?"
  set -e
  if [[ "$diff_code" == 0 ]]; then
    popd
    continue
  fi

  read -p "Press Enter to continue" </dev/tty

  updpkgsums
  # TODO: reset pkgrel to 0 on bump and only increase otherwise
  sed -r 's/(.*)(pkgrel=)([0-9]+)(.*)/echo "\1\2$((\3+1))\4"/ge' PKGBUILD | sponge PKGBUILD
  makepkg --printsrcinfo > .SRCINFO
  makepkg

  # commit and push new pkg version to AUR
  git add .SRCINFO PKGBUILD
  new_version="$(grep 'pkgver' .SRCINFO | sed 's/pkgver =//' | sed -e 's/^[[:space:]]*//')"
  git commit -m "[automated] $new_version"
  echo "pushing $pkgpath"
  git push origin master
  popd
done
