#!/bin/bash
set -euxo pipefail

git submodule init
git submodule update

for package in packages/*; do
  pushd $package
  git switch master
  popd
done
