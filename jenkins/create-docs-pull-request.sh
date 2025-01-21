#!/bin/bash

trap 'abort' 0

set -e

git checkout develop
git pull origin
git submodule update --init --recursive
pushd src/quarto-config > /dev/null
git checkout develop
git pull origin
popd > /dev/null
git submodule update --init --recursive

original_commit_hash=$(cd src/quarto-config && git rev-parse --short HEAD)
quarto_commit_hash=$(cd src/quarto-config && git rev-parse --short origin/develop)


if [ "$original_commit_hash" == "$quarto_commit_hash" ]; then
  echo "------------------------------------------------------------"
  echo ""
  echo "  No need to update. "
  echo "  Submodule at: ${original_commit_hash}."
  echo "  Update to:    ${quarto_commit_hash}."
  echo ""
  echo "------------------------------------------------------------"
  echo ""
  trap : 0
  exit 0
fi

pushd src/quarto-config > /dev/null
git checkout ${quarto_commit_hash}
popd > /dev/null
git add src/quarto-config
git commit -m "Updates the src/quarto-config submodule to ${quarto_commit_hash}." stan
git push origin develop

trap : 0

echo "------------------------------------------------------------"
echo ""
echo "  Success updating quarto submodule to ${quarto_commit_hash}"
echo ""
echo "------------------------------------------------------------"
echo ""

exit 0