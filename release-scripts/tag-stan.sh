#!/bin/bash

. functions.sh

trap 'abort' 0

set -e -u

## define variables
stan_directory=
old_version=
version=
math_version=


## internal variables
tag_github_url=git@github.com:stan-dev/stan.git
_msg=""
_steps[0]="Set up variables."
_steps[1]="Verify Stan is clean and up to date"
_steps[2]="Create release branch using git."
_steps[3]="Update Stan Math Library to tagged version."
_steps[4]="Replace uses of old version number with new version number."
_steps[5]="Git add and commit changed files."
_steps[8]="Test build. Git push."
_steps[11]="Git tag version."
_steps[12]="Update master branch to new version"
_steps[13]="Build manual. Manual upload of manual."

########################################
## 0: Set up variables
########################################
print_step 0
_msg="Input Stan directory"
if [[ -z $stan_directory ]]; then
  read -p "  Input Stan directory: " stan_directory
  eval stan_directory=$stan_directory
fi

## validate stan_directory
_msg="Validating Stan directory: $stan_directory"
if [[ ! -d $stan_directory ]]; then
  _msg="Cloning Stan into $stan_directory"
  echo ""
  eval "git clone $tag_github_url $stan_directory"
  echo ""
fi

pushd $stan_directory > /dev/null
_msg="Verifying Stan in $stan_directory is correct"

if [[ $(git ls-remote --get-url origin) != $tag_github_url ]]; then
  _msg="Wrong repository!
    $stan_directory is cloned from $(git ls-remote --get-url origin)
    Expecting a clone of $tag_github_url"
  exit 1
fi
popd > /dev/null

## reading old Stan version
_msg="Reading old Stan version"
if [[ -z $old_version ]]; then
  tmp=$(read_stan_major_version).$(read_stan_minor_version).$(read_stan_patch_version)
  read -p "  Current Stan version (leave blank for: $tmp): " old_version
  if [[ -z $old_version ]]; then
    old_version=$tmp
  fi
fi

_msg="Verifying old version matches the repository version"
if ! check_version $old_version; then
  _msg="Invalid old version: \"$old_version\""
  exit 1
fi
if [[ $(read_stan_major_version) -ne $(major_version $old_version) ]]; then
  _msg="Invalid old version: \"$old_version\"
    Expecting major version: $(read_stan_major_version)"
  exit 1
fi
if [[ $(read_stan_minor_version) -ne $(minor_version $old_version) ]]; then
  _msg="Invalid old version: \"$old_version\"
    Expecting minor version: $(read_stan_minor_version)"
  exit 1
fi
if [[ $(read_stan_patch_version) -ne $(patch_version $old_version) ]]; then
  _msg="Invalid old version: \"$old_version\"
    Expecting patch version: $(read_stan_patch_version)"
  exit 1
fi

## reading new Stan version
_msg="Reading new Stan version"
if [[ -z $version ]]; then
  read -p "  New Stan version (old version: $old_version): " version
fi

_msg="Verifying new Stan version"
if ! check_version $version; then
  _msg="Invalid new version: \"$version\""
  exit 1
fi
if [[ $old_version == $version ]]; then
  _msg="Invalid new version!
    Trying to tag the same version: \"$version\""
  exit 1
fi

## reading Stan Math Library version
_msg="Reading Stan Math Library version"
if [[ -z $math_version ]]; then
  read -p "  Stan Math Library version (default: $version): " math_version
  if [[ -z $math_version ]]; then
    math_version=$version
  fi
fi

########################################
## 1. Verify $stan_directroy is clean and
##    up to date
########################################
print_step 1
_msg="Checking $stan_directory"
pushd $stan_directory > /dev/null

if [[ -n $(git status --porcelain) ]]; then
  _msg="$stan_directory is not clean!
    Verify the directory passes \"git status --porcelain\""
  exit 1
fi

git checkout develop
git pull --ff

popd > /dev/null


########################################
## 2. Create release branch using git.
##    release/v$version
########################################
print_step 2
_msg="Creating release/v$version branch"
pushd $stan_directory > /dev/null

git checkout -b release/v$version

popd > /dev/null

########################################
## 3. Update Stan Math Library to tagged
##    version
########################################
print_step 3
_msg="Updating Stan Math Library to v$math_version"
pushd $stan_directory > /dev/null

git submodule init
git submodule update --recursive

pushd lib/stan_math > /dev/null
git checkout v$math_version
popd > /dev/null

git add lib/stan_math
git commit -m "Updating Math Library to tagged v$math_version" || echo "Math Library already at v$math_version"

popd > /dev/null


########################################
## 4. Update version numbers
########################################
print_step 4
_msg="Updating version numbers"
pushd $stan_directory > /dev/null

## src/stan/version.hpp
_msg="Updating version numbers: $stan_directory/src/stan/version.hpp"
replace_stan_major_version $version
replace_stan_minor_version $version
replace_stan_patch_version $version
if [[ $(read_stan_major_version) != $(major_version $version) \
    || $(read_stan_minor_version) != $(minor_version $version) \
    || $(read_stan_patch_version) != $(patch_version $version) ]]; then
  _msg="Updating version numbers failed!
    Check $stan_directory/src/stan/version.hpp"
  exit 1
fi

replace_version $(grep -rlF --exclude={*.hpp,*.cpp} "$old_version" $stan_directory/src)
replace_version .github/ISSUE_TEMPLATE.md
replace_version_test

wait_for_input "Go ahead and edit RELEASE_NOTES.txt now."

popd > /dev/null


########################################
## 5. Git add and commit changed files
########################################
print_step 5
_msg="Committing changed files to local git repository"
pushd $stan_directory > /dev/null


git commit -m "release/v$version: updating version numbers." -a

popd > /dev/null

########################################
## 8. Final test. Git push
########################################
print_step 8
_msg="Pushing changes to github"
pushd $stan_directory > /dev/null

wait_for_input "Ready to push branch "

### FIXME: Add testing code here
git push origin release/v$version

popd > /dev/null

########################################
## 8. Merge into develop
########################################
print_step 8
_msg="Merging into develop"
pushd $stan_directory > /dev/null

wait_for_input "Ready to merge into develop"

git checkout develop
git pull origin develop
git merge release/v$version
git push origin develop
git branch -d release/v$version

popd > /dev/null


########################################
## 11. Git tag version
########################################
print_step 11
_msg="tagging version v$version"
pushd $stan_directory > /dev/null

git checkout develop
git pull origin develop --ff
git tag -a "v$version" -m "Tagging v$version"
git push origin "v$version"

popd > /dev/null

########################################
## 12. Update master branch to new version
########################################
print_step 12
_msg="Updating master to tag v$version"
pushd $stan_directory > /dev/null

wait_for_input "Updating master to v$version"

git checkout master
git reset --hard v$version
git push origin master

popd > /dev/null

########################################
## 13. Build documentation
########################################
print_step 13
_msg="Building documentation"
pushd $stan_directory > /dev/null

make manual > /dev/null

echo "Manual steps:"
echo "0. Upload the manual to github"
echo "1. Rename ${old_version}++ to $version"
echo "2. Create new ${version}++ milestone."
echo "3. Close $version and bump open issues to ${version}++"

popd > /dev/null


########################################
## Done
########################################

trap : 0


echo "------------------------------------------------------------"
echo ""
echo "Success tagging Stan v$version!"


exit 0
