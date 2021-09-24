#!/bin/bash
set -euo pipefail

if [[ ! -d "$1" || ! -f "$1/PKGBUILD" ]]; then
  echo "This command will run updpkgsums, bump pkgrel by 1 and regenerate .SRCINFO"
  echo "usage: $0 packages/<package-name>"
  exit
fi

cd "$1"
updpkgsums
sed -r 's/(.*)(pkgrel=)([0-9]+)(.*)/echo "\1\2$((\3+1))\4"/ge' PKGBUILD | sponge PKGBUILD
makepkg --printsrcinfo > .SRCINFO
makepkg

