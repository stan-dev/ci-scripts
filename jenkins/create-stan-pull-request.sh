#!/bin/bash

trap 'abort' 0

set -e

########################################
## Echo
########################################


echo ""
echo "------------------------------------------------------------"
echo "  Math Library's develop branch updated"
echo ""

########################################
## Check to see if it's been updated
########################################

git checkout develop
git pull origin
make math-revert
pushd lib/stan_math > /dev/null
git checkout develop
git pull origin
popd > /dev/null
make math-revert

original_commit_hash=$(cd lib/stan_math && git rev-parse --short HEAD)
math_commit_hash=$(cd lib/stan_math && git rev-parse --short origin/develop)

if [ "$original_commit_hash" == "$math_commit_hash" ]; then
  echo "------------------------------------------------------------"
  echo ""
  echo "  No need to update. "
  echo "  Submodule at: ${original_commit_hash}."
  echo "  Update to:    ${math_commit_hash}."
  echo ""
  echo "------------------------------------------------------------"
  echo ""
  trap : 0 
  exit 0
fi

pushd lib/stan_math > /dev/null
git checkout ${math_commit_hash}
popd > /dev/null
git add lib/stan_math
git commit -m "Updates the Math submodule to ${math_commit_hash}." lib/stan_math
git push origin develop

########################################
## Done
########################################

trap : 0 

echo "------------------------------------------------------------"
echo ""
echo "  Success updating math submodule to ${math_commit_hash}"
echo ""
echo "------------------------------------------------------------"
echo ""

exit 0


