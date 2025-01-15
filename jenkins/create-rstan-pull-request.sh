#!/bin/bash

trap 'abort' 0

set -e

git checkout develop
git pull origin
git submodule update --init --recursive
pushd StanHeaders/inst/include/upstream > /dev/null
git checkout develop
git pull origin
popd > /dev/null
git submodule update --init --recursive

original_commit_hash=$(cd StanHeaders/inst/include/upstream && git rev-parse --short HEAD)
stan_commit_hash=$(cd StanHeaders/inst/include/upstream && git rev-parse --short origin/develop)


if [ "$original_commit_hash" == "$stan_commit_hash" ]; then
  echo "------------------------------------------------------------"
  echo ""
  echo "  No need to update. "
  echo "  Submodule at: ${original_commit_hash}."
  echo "  Update to:    ${stan_commit_hash}."
  echo ""
  echo "------------------------------------------------------------"
  echo ""
  trap : 0
  exit 0
fi

pushd StanHeaders/inst/include/upstream > /dev/null
git checkout ${stan_commit_hash}
popd > /dev/null
git add StanHeaders/inst/include/upstream
git commit -m "Updates the Stan submodule to ${stan_commit_hash}." stan
git push origin develop

trap : 0

echo "------------------------------------------------------------"
echo ""
echo "  Success updating stan submodule to ${stan_commit_hash}"
echo ""
echo "------------------------------------------------------------"
echo ""

exit 0
