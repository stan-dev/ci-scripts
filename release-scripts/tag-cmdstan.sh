#!/bin/bash

. functions.sh

trap 'abort' 0

set -e -u

## define variables
cmdstan_directory=
old_version=
version=
stan_version=


# ## internal variables
tag_github_url=git@github.com:stan-dev/cmdstan.git
_msg=""
_steps[0]="Set up variables."
_steps[1]="Verify CmdStan is clean and up to date"
_steps[2]="Create release branch using git."
_steps[3]="Update Stan to tagged version."
_steps[4]="Update version number."
_steps[5]="Build documentation."
_steps[6]="Test build. Git push."
_steps[8]="Merge into develop."
_steps[9]="Git tag version."
_steps[10]="Update master branch to new version"
_steps[11]="Create a zip file to upload"


########################################
## 0: Set up variables
########################################
print_step 0
_msg="Input CmdStan directory"
if [[ -z $cmdstan_directory ]]; then
  read -p "  Input CmdStan directory: " cmdstan_directory
  eval cmdstan_directory=$cmdstan_directory
fi

## validate cmdstan_directory
_msg="Validating CmdStan directory: $cmdstan_directory"
[ -z "$cmdstan_directory" ] && cmdstan_directory=$(realpath cmdstan)
if [[ ! -d $cmdstan_directory ]]; then
  _msg="Cloning CmdStan into $cmdstan_directory"
  echo ""
  eval "git clone $tag_github_url $cmdstan_directory"
  echo ""
fi

pushd $cmdstan_directory > /dev/null
_msg="Verifying CmdStan in $cmdstan_directory is correct"

if [[ $(git ls-remote --get-url origin) != $tag_github_url ]]; then
  _msg="Wrong repository!
    $cmdstan_directory is cloned from $(git ls-remote --get-url origin)
    Expecting a clone of $tag_github_url"
  exit 1
fi
popd > /dev/null

## reading current CmdStan version
_msg="Reading current CmdStan version"
if [[ -z $old_version ]]; then
  tmp=$(read_cmdstan_version)
  read -p "  Current CmdStan version (leave blank for: $tmp): " old_version
  if [[ -z $old_version ]]; then
    old_version=$tmp
  fi
fi

_msg="Verifying old version matches the repository version"
if ! check_version $old_version; then
  _msg="Invalid old version: \"$old_version\""
  exit 1
fi
if [[ $(read_cmdstan_version) != $old_version ]]; then
  _msg="Invalid old CmdStan version: \"$old_version\"
    Expecting version: \"$(read_cmdstan_version)\""
  exit 1
fi

## reading new CmdStan version
_msg="Reading new CmdStan version"
if [[ -z $version ]]; then
  read -p "  New CmdStan version (old version: $old_version): " version
fi

_msg="Verifying new CmdStan version"
if ! check_version $version; then
  _msg="Invalid new version: \"$version\""
  exit 1
fi
if [[ $old_version == $version ]]; then
  _msg="Invalid new version!
    Trying to tag the same version: \"$version\""
  exit 1
fi


## reading Stan version
_msg="Reading Stan version"
if [[ -z $stan_version ]]; then
  read -p "  Stan version (default: $version): " stan_version
  if [[ -z $stan_version ]]; then
    stan_version=$version
  fi
fi

########################################
## 1. Verify $cmdstan_directory is clean and
##    up to date
########################################
print_step 1
_msg="Checking $cmdstan_directory"
pushd $cmdstan_directory > /dev/null

if [[ -n $(git status --porcelain) ]]; then
  _msg="$cmdstan_directory is not clean!
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
pushd $cmdstan_directory > /dev/null

git checkout -b release/v$version

popd > /dev/null

########################################
## 3. Update Stan to tagged version
########################################
print_step 3
_msg="Updating Stan to tag v$stan_version."
pushd $cmdstan_directory > /dev/null

git submodule init
git submodule update

pushd stan > /dev/null

git checkout v$stan_version

git submodule init
git submodule update

popd > /dev/null

math_version=$(grep stan_math stan | sed 's|\(.*\)stan_math\(.*\)/|\2|g')

git add stan
git commit -m "Updating Stan to tagged v$version"  || echo "Stan already at v$stan_version"

popd > /dev/null


########################################
## 4. Update version numbers
########################################
print_step 4
_msg="Updating version numbers"
pushd $cmdstan_directory > /dev/null

# See: https://github.com/stan-dev/cmdstan/pull/799#issuecomment-576703881
# We should stick to nightly
# sed -i '' 's/nightly/'$version'/g' make/stanc
replace_version $(grep -rlF "$old_version" src make makefile)
replace_version .github/ISSUE_TEMPLATE.md
git commit -m "release/v$version: updating version numbers" -a

popd > /dev/null


########################################
## 5. Build documentation
########################################0
print_step 5
_msg="Building documentation"
pushd $cmdstan_directory > /dev/null

make manual > /dev/null

popd > /dev/null


########################################
## 6. Test. Git push
########################################
print_step 6
_msg="Pushing changes to github"
pushd $cmdstan_directory > /dev/null

wait_for_input "Ready to push branch "

### FIXME: Add testing code here
git push origin release/v$version

popd > /dev/null

########################################
## 8. Merge into develop
########################################
print_step 8
_msg="Merging into develop"
pushd $cmdstan_directory > /dev/null

wait_for_input "Ready to merge into develop"

git checkout develop
git pull origin develop
git merge release/v$version
git push origin develop
git branch -d release/v$version

popd > /dev/null



########################################
## 9. Git tag version
########################################
print_step 9
_msg="tagging version v$version"
pushd $cmdstan_directory > /dev/null

git checkout develop
git pull origin develop --ff
git tag -a "v$version" -m "Tagging v$version"
git push origin "v$version"

popd > /dev/null

########################################
## 10. Update master branch to new version
########################################
print_step 10
_msg="Updating master to tag v$version"
pushd $cmdstan_directory > /dev/null

wait_for_input "Updating master to v$version"

git checkout master
git reset --hard v$version
git push origin master

popd > /dev/null

########################################
## 11. Package version to upload
########################################
print_step 11
_msg="Creating a zip file for uploading"
pushd $cmdstan_directory > /dev/null

git pull --ff
git checkout v$version
echo "Creating archive: cmdstan-$version.tar.gz"
git-archive-all cmdstan-$version.tar.gz
#echo "Creating archive: cmdstan-$version.zip"
#git-archive-all cmdstan-$version.zip

echo "Manual steps:"
echo "0. Upload zip files and manual to github release manually."
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
echo "Success tagging CmdStan v$version!"


exit 0
