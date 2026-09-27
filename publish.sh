#!/bin/bash

# Add a built package to the [umbra] pacman repository and publish it.
#   ./publish.sh path/to/umbra-wiki-X.Y.Z-1-any.pkg.tar.zst
# Signs the package and the repository database with the Umbra packages key,
# keeps only the newest version, and pushes to GitHub Pages.

set -euo pipefail

key=E50B101F98529A32564FDD3B37A6D2DA9E6A0F0B
repo=$(cd "$(dirname "$(readlink -f "$0")")" && pwd)
dir="$repo/x86_64"
pkg=${1:?usage: publish.sh <package file>}
name=$(basename "$pkg")

cp "$pkg" "$dir/$name"
gpg --batch --yes --local-user "$key" --detach-sign --no-armor "$dir/$name"

cd "$dir"
repo-add --sign --key "$key" --remove umbra.db.tar.gz "$name"
# GitHub Pages doesn't serve symlinks: pacman's names become real copies.
for f in umbra.db umbra.files; do
  rm -f "$f" "$f.sig"
  cp "$f.tar.gz" "$f"
  cp "$f.tar.gz.sig" "$f.sig"
done
# Drop older package files that the database no longer lists.
for old in umbra-wiki-*.pkg.tar.zst; do
  [[ $old == "$name" ]] || rm -f "$old" "$old.sig"
done

cd "$repo"
git add -A
git -c user.name=umbraxc -c user.email=334050264+umbraxc@users.noreply.github.com \
  commit -q -m "Publish ${name%.pkg.tar.zst}"
git -c credential.helper= -c credential.helper='!gh auth git-credential' push origin main
echo "Published $name."
