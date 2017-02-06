#!/bin/bash

. functions.sh

trap 'abort' 0

set -e

## define variables
cmdstan_directory=
old_version=
version=
stan_version=
github_user=
github_password=



# ## internal variables
tag_github_url=https://github.com/stan-dev/cmdstan.git
tag_github_api_url=https://api.github.com/repos/stan-dev/cmdstan
_msg=""
_steps[0]="Set up variables."
_steps[1]="Verify CmdStan is clean and up to date"
_steps[2]="Create release branch using git."
_steps[3]="Update Stan to tagged version."
_steps[4]="Update version number."
_steps[5]="Build and commit documentation."
_steps[6]="Test build. Git push."
_steps[7]="Create GitHub pull request."
_steps[8]="Merge GitHub pull request."
_steps[9]="Git tag version."
_steps[10]="Update master branch to new version"
_steps[11]="Create a zip file to upload"
_steps[12]="Create GitHub issue to remove documentation."
_steps[13]="Create git branch to remove documentation"
_steps[14]="Create GitHub pull request to remove documentation."
_steps[15]="Merge GitHub pull request to remove documentation."


echo ""
echo "---------- Script to Tag CmdStan ----------"
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
_msg="Input CmdStan directory"
if [[ -z $cmdstan_directory ]]; then
  read -p "  Input CmdStan directory: " cmdstan_directory
  eval cmdstan_directory=$cmdstan_directory
fi

## validate cmdstan_directory
_msg="Validating CmdStan directory: $cmdstan_directory"
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
## 1. Verify $cmdstan_home is clean and
##    up to date
########################################
print_step 1
_msg="Checking $cmdstan_home"
pushd $cmdstan_directory > /dev/null

if [[ -n $(git status --porcelain) ]]; then
  _msg="$cmdstan_home is not clean!
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

old_stan_dir=stan
if [[ $old_stan_dir != stan_$stan_version ]]; then
  git mv $old_stan_dir stan_$stan_version
  sed -i '' 's|STAN ?=\(.*\)'$old_stan_dir'|STAN ?=\1stan_'$stan_version'|g' makefile  
  sed -i '' 's|\(.*\) stan/|\1 stan_'$stan_version'/|g' test-all.sh
  git add makefile test-all.sh
  git commit -m "moving stan to stan_$stan_version"
fi

git submodule init
git submodule update

pushd stan_$stan_version > /dev/null

git checkout v$stan_version

git submodule init
git submodule update

popd > /dev/null

math_version=$(grep stan_math stan_$stan_version/makefile | sed 's|\(.*\)stan_math\(.*\)/|\2|g')
sed -i '' 's|MATH ?=\(.*\)stan_math/|MATH ?=\1stan_math'$math_version'/|g' makefile
sed -i '' 's|\(.*\)/lib/stan_math/|\1/lib/stan_math'$math_version'/|g' test-all.sh
git add makefile test-all.sh
git commit -m "Updating stan math location"

## update references for src/docs
sed -i '' 's|\(.*\)../'$old_stan_dir'/\(.*\)|\1../stan_'$stan_version'/\2|g' $(grep -rl "../stan/" src/docs --include \*.tex)
sed -i '' 's|\(.*\)../stan_math_'$old_version'/\(.*\)|\1../stan_math'$math_version'/\2|g' $(grep -rl "../stan_math_$old_version/" src/docs --include \*.tex)
git add src/docs

git add stan_$stan_version
git commit -m "Updating Stan to tagged v$version"  || echo "Stan already at v$stan_version"

popd > /dev/null


########################################
## 4. Update version numbers
########################################
print_step 3
_msg="Updating version numbers"
pushd $cmdstan_directory > /dev/null

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
rm doc/*.txt
git add -f doc
git commit -m "release/v$version: adding built documentation"

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
## 7. Create github pull request
########################################
print_step 7
_msg="Create github pull request for $version"
pushd $cmdstan_directory > /dev/null


wait_for_input "Creating the pull request "

create_pull_request "release/v$version" "release/v$version" "develop" "#### Summary:\n\nUpdates version numbers to v$version.\n\n#### Intended Effect:\n\nThe \`develop\` branch should be tagged as \`v$version\` after this is merged.\n\n#### How to Verify:\n\nInspect the code.\n\n#### Side Effects:\n\nNone.\n\n#### Documentation:\n\nDocumentation is included.\n\n#### Reviewer Suggestions: \n\nNone."

echo "Created pull request: $github_number"

popd > /dev/null


########################################
## 8. Merge github pull request
########################################
print_step 8
_msg="Merging pull request $github_number"
pushd $cmdstan_directory > /dev/null

wait_for_input "Merging pull request #$github_number "

merge_pull_request $github_number "release/v$version"
git checkout develop
git pull --ff
git branch -d release/v$version

popd > /dev/null


########################################
## 9. Git tag version
########################################
print_step 9
_msg="tagging version v$version"
pushd $cmdstan_directory > /dev/null

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
echo "Creating archive: cmdstan-$version.zip"
git-archive-all cmdstan-$version.zip

popd > /dev/null

########################################
## 12. Create GitHub issue to remove documentation
##     and move stan version
########################################
print_step 12
_msg="Create github issue for removing v$version documentation and move stan version"
pushd $cmdstan_directory > /dev/null

create_issue "Remove v$version documentation and move stan library" "Remove build documentation from repository and move stan library back to ./stan/."

popd > /dev/null

########################################
## 13. Create git branch to remove documentation
##     remove and commit.
########################################
print_step 13
_msg="Creating branch to remove documentation and move stan math"
pushd $cmdstan_directory > /dev/null

git checkout develop
git pull --ff
git checkout -b feature/issue-$github_number-remove-documentation-move-stan
git rm -rf doc
git commit -m "Removing built documentation"

## move back stan version and change makefile
rm -rf stan_$stan_version
git checkout -- stan_$stan_version
git mv stan_$stan_version $old_stan_dir 
sed -i '' 's|STAN ?=\(.*\)stan_'$stan_version'\(.*\)|STAN ?=\1'$old_stan_dir'\2|g' makefile
sed -i '' 's|MATH ?=\(.*\)stan_math'$math_version'/|MATH ?=\1stan_math/|g' makefile
sed -i '' 's|\(.*\) stan_'$stan_version'/|\1 stan/|g' test-all.sh
sed -i '' 's|\(.*\)/lib/stan_math/|\1/lib/stan_math'$math_version'/|g' test-all.sh
git add makefile test-all.sh

## change src/docs
sed -i '' 's|\(.*\)../stan_'$stan_version'/\(.*\)|\1../'$old_stan_dir'/\2|g' $(grep -rl "../stan_$stan_version/" src/docs --include \*.tex)
git add src/docs
git commit -m "moving stan_$stan_version to stan"


git submodule init
git submodule update --recursive

pushd stan > /dev/null
git checkout develop
git pull --ff
popd > /dev/null

git add stan
git commit -m "fixes #$github_number. moving stan library back to ./stan/"

git push origin feature/issue-$github_number-remove-documentation-move-stan

popd > /dev/null

########################################
## 14. Create GitHub pull request to remove documentation
########################################
print_step 14
_msg="Pull request to remove documentation"
pushd $cmdstan_directory > /dev/null

create_pull_request "Remove v$version documentation" "feature/issue-$github_number-remove-documentation-move-stan" "develop" "#### Summary:\n\nRemoves built documentation and moves stan library.\n\n#### Intended Effect:\n\nRemoves built documentation included as part of the \`v$version\` tag; also moves the stan library.\n\n#### How to Verify:\n\nInspect.\n\n#### Side Effects:\n\nNone.\n\n#### Documentation:\n\nNone.\n\n#### Reviewer Suggestions: \n\nNone.\n\n"

popd > /dev/null



########################################
## 15. Merge GitHub pull request to remove documentation
########################################
print_step 15
_msg="Pull request to remove documentation"
pushd $cmdstan_directory > /dev/null

merge_pull_request $github_number "feature/issue-$github_number-remove-documentation"

popd > /dev/null



########################################
## Done
########################################

trap : 0 


echo "------------------------------------------------------------"
echo ""
echo "Success tagging CmdStan v$version!"


exit 0


