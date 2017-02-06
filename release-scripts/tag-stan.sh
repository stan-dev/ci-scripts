#!/bin/bash

. functions.sh

trap 'abort' 0

set -e

## define variables
stan_directory=
old_version=
version=
math_version=
github_user=
github_password=


## internal variables
tag_github_url=https://github.com/stan-dev/stan.git
tag_github_api_url=https://api.github.com/repos/stan-dev/stan
_msg=""
_steps[0]="Set up variables."
_steps[1]="Verify Stan is clean and up to date"
_steps[2]="Create release branch using git."
_steps[3]="Update Stan Math Library to tagged version."
_steps[4]="Replace uses of old version number with new version number."
_steps[5]="Git add and commit changed files."
_steps[6]="Build documentation."
_steps[7]="Git add and commit build documentation."
_steps[8]="Test build. Git push."
_steps[9]="Create GitHub pull request."
_steps[10]="Merge GitHub pull request."
_steps[11]="Git tag version."
_steps[12]="Update master branch to new version"
_steps[13]="Create a zip file to upload"
_steps[14]="Create GitHub issue to remove documentation."
_steps[15]="Create git branch to remove documentation"
_steps[16]="Create GitHub pull request to remove documentation."
_steps[17]="Merge GitHub pull request to remove documentation."

echo ""
echo "---------- Script to Tag Stan ----------"
echo ""
echo "  Steps in this script:"
for ((n = 0; n < ${#_steps[@]}; n++))
do
  if [[ $n -lt 10 ]]; then
    echo "     "$n: ${_steps[$n]}
  else
    echo "    "$n: ${_steps[$n]}
  fi
done
echo ""

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

## read GitHub user name
_msg="Reading GitHub user name"
if [[ -z $github_user ]]; then
  read -p "  Github user name: " github_user
fi

## read GitHub user name
_msg="Reading Github password"
if [[ -z $github_password ]]; then
  read -s -p "  Github password (user: $github_user): " github_password
fi
echo

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

old_math_dir=$(find lib -name stan_math*)
if [[ $old_math_dir != lib/stan_math_$math_version ]]; then
  git mv $old_math_dir lib/stan_math_$math_version
  sed -i '' 's|\(.*\)'$old_math_dir'\(.*\)$|\1lib/stan_math_'$math_version'\2|g' makefile
  git add makefile
fi

pushd lib/stan_math_$math_version > /dev/null

git checkout v$math_version

popd > /dev/null

git add lib/stan_math_$math_version
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
## 6. Build documentation
########################################
print_step 6
_msg="Building documentation"
pushd $stan_directory > /dev/null

make manual doxygen > /dev/null

popd > /dev/null


########################################
## 7. Git add and commit built documentation
########################################
print_step 7
_msg="Committing built documentation"
pushd $stan_directory > /dev/null

git add -f doc
git commit -m "release/v$version: adding built documentation."

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
## 9. Create github pull request
########################################
print_step 9
_msg="Create github pull request for $version"
pushd $stan_directory > /dev/null


wait_for_input "Creating the pull request "

create_pull_request "release/v$version" "release/v$version" "develop" "#### Summary:\n\nUpdates version numbers to v$version.\n\n#### Intended Effect:\n\nThe \`develop\` branch should be tagged as \`v$version\` after this is merged.\n\n#### How to Verify:\n\nInspect the code.\n\n#### Side Effects:\n\nNone.\n\n#### Documentation:\n\nDocumentation is included.\n\n#### Reviewer Suggestions: \n\nNone."

popd > /dev/null


########################################
## 10. Merge github pull request
########################################
print_step 10
_msg="Merging pull request $github_number"
pushd $stan_directory > /dev/null

wait_for_input "Merging the pull request "

merge_pull_request $github_number "release/v$version"
git checkout develop
git pull --ff
git branch -d release/v$version

popd > /dev/null


########################################
## 11. Git tag version
########################################
print_step 11
_msg="tagging version v$version"
pushd $stan_directory > /dev/null

git checkout develop
git pull --ff
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
## 13. Package version to upload
########################################
print_step 13
_msg="Creating a zip file for uploading"
pushd $stan_directory > /dev/null

git pull --ff
git checkout v$version

popd > /dev/null


########################################
## 14. Create GitHub issue to remove documentation
##     and move math version
########################################
print_step 14
_msg="Create github issue for removing v$version documentation and moving math version"
pushd $stan_directory > /dev/null

create_issue "Remove v$version documentation and move math library" "Remove build documentation from repository and move math library back to lib/stan_math."

popd > /dev/null

########################################
## 15. Create git branch to remove documentation
##     remove and commit.
########################################
print_step 15
_msg="Creating branch to remove documentation and move math version"
pushd $stan_directory > /dev/null

git checkout develop
git pull --ff
git checkout -b feature/issue-$github_number-remove-documentation-move-math
git rm -rf doc
git commit -m "Removing built documentation."

git mv lib/stan_math_$math_version lib/stan_math
sed -i '' 's|\(.*\)lib/stan_math_'$math_version'\(.*\)|\1'$old_math_dir'\2|g' makefile
git add makefile

pushd lib/stan_math > /dev/null
git checkout develop
git pull --ff
popd > /dev/null

git commit -m "fixes #$github_number. moving math library back to lib/stan_math"

git push origin feature/issue-$github_number-remove-documentation-move-math

popd > /dev/null

########################################
## 16. Create GitHub pull request to remove documentation
########################################
print_step 16
_msg="Pull request to remove documentation"
pushd $stan_directory > /dev/null

create_pull_request "Remove v$version documentation and move math library" "feature/issue-$github_number-remove-documentation-move-math" "develop" "#### Summary:\n\nRemoves built documentation and moves math library.\n\n#### Intended Effect:\n\nRemoves built documentation included as part of the \`v$version\` tag; also moves the math library\n\n#### How to Verify:\n\nInspect.\n\n#### Side Effects:\n\nNone.\n\n#### Documentation:\n\nNone.\n\n#### Reviewer Suggestions: \n\nNone."

popd > /dev/null



########################################
## 17. Merge GitHub pull request to remove documentation
########################################
print_step 17
_msg="Pull request to remove documentation"
pushd $stan_directory > /dev/null

merge_pull_request $github_number "feature/issue-$github_number-remove-documentation"

popd > /dev/null


########################################
## Done
########################################

trap : 0 


echo "------------------------------------------------------------"
echo ""
echo "Success tagging Stan v$version!"


exit 0


