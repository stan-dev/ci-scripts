#!/bin/bash

. functions.sh

trap 'abort' 0

set -e -u

## define variables
math_directory=
old_version=
version=
branch_to_release=develop


## internal variables
tag_github_url=git@github.com:stan-dev/math.git
tag_github_api_url=https://api.github.com/repos/stan-dev/math
_msg=""
_steps[0]="Set up variables."
_steps[1]="Verify Stan Math Library is clean and up to date"
_steps[2]="Create release branch using git."
_steps[3]="Replace uses of old version number with new version number."
_steps[4]="Git add and commit changed files."
_steps[7]="Test build. Git push."
_steps[8]="Merging into develop."
_steps[10]="Git tag version."
_steps[11]="Update master branch to new version"


########################################
## 0: Set up variables
########################################
print_step 0
_msg="Input Stan Math Library directory"
if [[ -z $math_directory ]]; then
  read -p "  Input Stan Math Library directory: " math_directory
  eval math_directory=$math_directory
fi

## validate math_directory
[ -z "$math_directory" ] && math_directory=$(realpath math)
_msg="Validating Stan Math Library directory: $math_directory"
if [[ ! -d $math_directory ]]; then
  _msg="Cloning Stan Math Library into $math_directory"
  echo ""
  eval "git clone $tag_github_url $math_directory"
  echo ""
fi

pushd $math_directory > /dev/null
_msg="Verifying Stan Math Library in $math_directory is correct"

if [[ $(git ls-remote --get-url origin) != $tag_github_url ]]; then
  _msg="Wrong repository!
    $math_directory is cloned from $(git ls-remote --get-url origin)
    Expecting a clone of $tag_github_url"
  exit 1
fi
popd > /dev/null

## reading old Stan Math Library version
_msg="Reading old Stan Math Library version"
if [[ -z $old_version ]]; then
  tmp=$(read_math_major_version).$(read_math_minor_version).$(read_math_patch_version)
  read -p "  Current Stan Math Library version (leave blank for: $tmp): " old_version
  if [[ -z $old_version ]]; then
    old_version=$tmp
  fi
fi

_msg="Verifying old version matches the repository version"
if ! check_version $old_version; then
  _msg="Invalid old version: \"$old_version\""
  exit 1
fi
if [[ $(read_math_major_version) -ne $(major_version $old_version) ]]; then
  _msg="Invalid old version: \"$old_version\"
    Expecting major version: $(read_math_major_version)"
  exit 1
fi
if [[ $(read_math_minor_version) -ne $(minor_version $old_version) ]]; then
  _msg="Invalid old version: \"$old_version\"
    Expecting minor version: $(read_math_minor_version)"
  exit 1
fi
if [[ $(read_math_patch_version) -ne $(patch_version $old_version) ]]; then
  _msg="Invalid old version: \"$old_version\"
    Expecting patch version: $(read_math_patch_version)"
  exit 1
fi

## reading new Stan Math Library version
_msg="Reading new Stan Math Library version"
if [[ -z $version ]]; then
  read -p "  New Stan Math Library version (old version: $old_version): " version
fi

_msg="Verifying new Stan Math Library version"
if ! check_version $version; then
  _msg="Invalid new version: \"$version\""
  exit 1
fi
if [[ $old_version == $version ]]; then
  _msg="Invalid new version!
    Trying to tag the same version: \"$version\""
  exit 1
fi

########################################
## 1. Verify $math_directory is clean and
##    up to date
########################################
print_step 1
_msg="Checking $math_directory"
pushd $math_directory > /dev/null

if [[ -n $(git status --porcelain) ]]; then
  _msg="$math_directory is not clean!
    Verify the directory passes \"git status --porcelain\""
  exit 1
fi

git checkout $branch_to_release
git pull origin $branch_to_release --ff

popd > /dev/null


########################################
## 2. Create release branch using git.
##    release/v$version
########################################
print_step 2
_msg="Creating release/v$version branch"
pushd $math_directory > /dev/null

git checkout -b release/v$version

popd > /dev/null


########################################
## 3. Update version numbers
########################################
print_step 3
_msg="Updating version numbers"

## stan/math/version.hpp
_msg="Updating version numbers: ${math_directory}/stan/math/version.hpp"
replace_math_major_version $version
replace_math_minor_version $version
replace_math_patch_version $version
if [[ $(read_math_major_version) != $(major_version $version) \
    || $(read_math_minor_version) != $(minor_version $version) \
    || $(read_math_patch_version) != $(patch_version $version) ]]; then
  _msg="Updating version numbers failed!
    Check ${math_directory}/stan/math/version.hpp"
  exit 1
fi

replace_version $(grep -rlF --exclude={*.hpp,*.cpp} "$old_version" ${math_directory}/stan)
replace_version $(grep -rlF --exclude={*.hpp,*.cpp} "$old_version" ${math_directory}/doxygen)
replace_version ${math_directory}/.github/ISSUE_TEMPLATE.md

wait_for_input "Go ahead and edit RELEASE_NOTES.txt now."


########################################
## 4. Git add and commit changed files
########################################
print_step 4
_msg="Committing changed files to local git repository"
pushd $math_directory > /dev/null


git commit -m "release/v$version: updating version numbers" -a

popd > /dev/null

########################################
## 7. Final test. Git push
########################################
print_step 7
_msg="Pushing changes to github"
pushd $math_directory > /dev/null

wait_for_input "Ready to push branch "

### FIXME: Add testing code here
git push origin release/v$version

popd > /dev/null

########################################
## 8. Merge into develop
########################################
print_step 8
_msg="Merging into develop"
pushd $math_directory > /dev/null

wait_for_input "Ready to merge into develop"

### FIXME: Add testing code here
git checkout develop
git pull origin develop
git merge release/v$version
git push origin develop
git branch -d release/v$version

popd > /dev/null


########################################
## 10. Git tag version
########################################
print_step 10
_msg="tagging version v$version"
pushd $math_directory > /dev/null

git tag -a "v$version" -m "Tagging v$version"
git push origin "v$version"

popd > /dev/null

########################################
## 11. Update master branch to new version
########################################
print_step 11
_msg="Updating master to tag v$version"
pushd $math_directory > /dev/null

wait_for_input "Updating master to v$version"

# XXX ? change to git branch -f master v$version
git checkout master
git reset --hard v$version
git push origin master

popd > /dev/null

echo "Manual steps:"
echo "1. Rename ${old_version}++ to $version"
echo "2. Create new ${version}++ milestone."
echo "3. Close $version and bump open issues to ${version}++"
echo "4. Create new release https://github.com/stan-dev/math/releases"


########################################
## Done
########################################

trap : 0


echo "------------------------------------------------------------"
echo ""
echo "Success tagging Stan Math Library v$version!"


exit 0
