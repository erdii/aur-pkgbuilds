#!/bin/bash
set -euo pipefail

if [[ ! -d "$1" ]]; then
  echo "This command will open the package's aur page."
  echo "usage: $0 packages/<package-name>"
  exit
fi

package=$(basename $1)

echo "opening AUR website for package $package"
gio open "https://aur.archlinux.org/packages/$package"
