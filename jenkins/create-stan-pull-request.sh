#!/bin/bash

trap 'abort' 0

set -e

########################################
## Functions
########################################

github_issue_exists() {
  grep -q 'stan-buildbot' <<<$1
}

curl_success() {
  code=$(sed -n "s,.*HTTP/1.1 \([0-9]\{3\}\).*,\1,p" <<< "$1")
  [[ "$code" -eq "201" ]] || [[ "$code" -eq "200" ]]
}

github_issue_number=None
parse_github_issue_number() {
  github_issue_number=$(sed -n "s,.*/issues/\([0-9]*\)\".*,\1,p" <<< "$1" | head -n1)
}

github_pr_number=None
parse_existing_github_issue_and_pr_numbers() {
  numbers=($(echo "$1" | python github_pr_and_issue_number.py))
  github_pr_number=${numbers[0]}
  github_issue_number=${numbers[1]}
}

tag_github_api_url='https://api.github.com/repos/stan-dev/stan'

# XXX stolen from ../release-scripts/functions.sh
## merges a pull request
## uses
##  $github_user
##  $github_token
##  $tag_github_api_url
##
## arguments
##  $1: pull request number
##  $2: commit message for the merge
merge_pull_request() {
  echo $tag_github_api_url/pulls/$1/merge
  data="{ \"commit_message\": \"$2\" }"
  echo $data

  response=$(eval curl -i --user \"$github_user:$github_token\" --request PUT --data \'$data\' $tag_github_api_url/pulls/$1/merge)

  if ! curl_success "${response}"; then
    _msg="
Error merging pull request:
----------------------------
$data

Response:
---------
$response
"
    exit 1
  fi
}

########################################
## Echo
########################################


echo ""
echo "------------------------------------------------------------"
echo "  Math Library's develop branch updated"
echo "  Creating a pull request on Stan to update its submodule"
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
  echo "  No need to create issue. "
  echo "  Submodule at: ${original_commit_hash}."
  echo "  Update to:    ${math_commit_hash}."
  echo ""
  echo "------------------------------------------------------------"
  echo ""
  trap : 0 
  exit 0
fi

response=$(eval curl -G 'https://api.github.com/repos/stan-dev/stan/issues?creator=stan-buildbot')

if github_issue_exists "${response}"; then
  ########################################
  ## Update existing GitHub issue
  ########################################

  parse_existing_github_issue_and_pr_numbers "${response}"
else
  ########################################
  ## Create GitHub issue
  ########################################

  issue="{ 
  \"title\": \"Update submodule for the Stan Math Library\",
  \"body\":  \"The Stan Math Library develop branch has been updated.\nUpdate the submodule to ${math_commit_hash}.\" }"

  response=$(eval curl --include --user \"$github_user:$github_token\" --request POST --data \'$issue\' https://api.github.com/repos/stan-dev/stan/issues)


  if ! curl_success "${response}"; then
    _msg="
Error creating pull request:
----------------------------
$data


Response:
---------
$response
"
    trap : 0 
    exit 1
  fi
  parse_github_issue_number "${response}"
fi


echo "Issue        #"${github_issue_number}
echo "Pull request #"${github_pr_number}

if [ "${github_issue_number}" == "None" ]; then
  echo "Can't find an issue number"
  trap : 0
  exit 1
fi

########################################
## Fix issue on a branch:
## - Create a git branch
## - Update the Math Library to develop
## - Commit and push
########################################
if [ "$github_pr_number" == "None" ]; then
  git checkout -b feature/issue-${github_issue_number}-update-math
else
  git checkout feature/issue-${github_issue_number}-update-math
  git pull --ff
fi
pushd lib/stan_math > /dev/null
git checkout ${math_commit_hash}
popd > /dev/null
git add lib/stan_math
git commit -m "Fixes #${github_issue_number}. Updates the Math submodule to ${math_commit_hash}." lib/stan_math
git push --set-upstream origin feature/issue-${github_issue_number}-update-math


if [ "$github_pr_number" == "None" ]; then
  ########################################
  ## Create pull request
  ########################################

  pull_request="{
  \"title\": \"Update submodule for the Stan Math Library\",
  \"head\": \"feature/issue-${github_issue_number}-update-math\",
  \"base\": \"develop\",
  \"body\": \"#### Summary:\n\nUpdates the Math submodule to the current develop version, ${math_commit_hash}.\n\n#### Intended Effect:\n\nThe Stan Math Library \`develop\` branch has been updated.\nThis pull request updates the submodule for the Stan Math Library submodule to ${math_commit_hash}.\n\n#### Side Effects:\n\nNone.\n\n#### Documentation:\n\nNone.\n\n#### Reviewer Suggestions: \n\nNone.\" }"

  response=$(eval curl --include --user \"$github_user:$github_token\" --request POST --data \'$pull_request\' https://api.github.com/repos/stan-dev/stan/pulls)

  if ! curl_success "${response}"; then
    _msg="
Error creating pull request
----------------------------
$data


Response:
---------
$response
"
    trap : 0 
    exit 1
  fi

fi

########################################
## Merge the pull request
########################################

merge_pull_request $github_pr_number "Automatically bumping math library."

########################################
## Done
########################################

trap : 0 

echo "------------------------------------------------------------"
echo ""
echo "  Success creating a pull request updating submodule"
echo ""
echo "------------------------------------------------------------"
echo ""

exit 0


