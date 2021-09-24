#!/bin/bash
set -euo pipefail

package="$1"

if [[ ! -d "$package" || ! -f "$package/PKGBUILD" ]]; then
  echo "This command will commit package's submodule and also create a commit with an updated ref in the umbrella repo."
  echo "usage: $0 packages/<package-name>"
  exit
fi


pushd "$package"
git add .
git commit -m "$2"
git push origin master
popd

git add "$package"
pkgname=$(basename $package)
git commit -m "[automated] $pkgname - $2"
git push
