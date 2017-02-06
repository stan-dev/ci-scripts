#!/bin/bash

## pretty printing for when the shell aborts
## script uses: $_msg, $_steps, and $_step
abort() {
  echo "
********************
An error occurred.

Step $_step: ${_steps[$_step]}

  $_msg

Exiting without tagging." >&2

  exit 1
}

## pretty printing of the current step
print_step() {
  _step=$1
  echo "------------------------------------"
  echo "Step "$_step: ${_steps[$_step]}
  echo 
}

## read major version from the Stan directory
read_stan_major_version() {
  sed -e 's/^.*#define STAN_MAJOR[[:space:]]*\([[:alnum:]]*\).*/\1/p' -n $stan_directory/src/stan/version.hpp
}

## read minor version from the Stan directory
read_stan_minor_version() {
  sed -e 's/^.*#define STAN_MINOR[[:space:]]*\([[:alnum:]]*\).*/\1/p' -n $stan_directory/src/stan/version.hpp
}

## read patch version from the Stan directory
read_stan_patch_version() {
  sed -e 's/^.*#define STAN_PATCH[[:space:]]*\([[:alnum:]]*\).*/\1/p' -n $stan_directory/src/stan/version.hpp
}

## read major version from the Stan directory
read_math_major_version() {
  sed -e 's/^.*#define STAN_MATH_MAJOR[[:space:]]*\([[:alnum:]]*\).*/\1/p' -n $math_directory/stan/math/version.hpp
}

## read minor version from the Stan directory
read_math_minor_version() {
  sed -e 's/^.*#define STAN_MATH_MINOR[[:space:]]*\([[:alnum:]]*\).*/\1/p' -n $math_directory/stan/math/version.hpp
}

## read patch version from the Stan directory
read_math_patch_version() {
  sed -e 's/^.*#define STAN_MATH_PATCH[[:space:]]*\([[:alnum:]]*\).*/\1/p' -n $math_directory/stan/math/version.hpp
}


read_cmdstan_version() {
  sed -e 's/^.*{\\cmdstanversion}{\(.*\)}/\1/p' -n $cmdstan_directory/src/docs/cmdstan-guide/cmdstan-guide.tex
}

## check the version number: currently verifies there are two periods
check_version() {
  [[ $(grep -o "\." <<<$1 | wc -l) -eq 2 ]]
}

## reads the major version from a x.y.z version
major_version() {
  sed 's/\(.*\)\.\(.*\)\.\(.*\)/\1/' <<<$1
}

## reads the minor version from a x.y.z version
minor_version() {
  sed 's/\(.*\)\.\(.*\)\.\(.*\)/\2/' <<<$1
}

## reads the patch version from a x.y.z version
patch_version() {
  sed 's/\(.*\)\.\(.*\)\.\(.*\)/\3/' <<<$1
}

## replaces the major version in the Stan directory
replace_stan_major_version() {
  sed -i '' "s/\(^.*#define STAN_MAJOR[[:space:]]*\)\([[:alnum:]]*\).*/\1$(major_version $1)/g" $stan_directory/src/stan/version.hpp 
}

## replaces the minor version in the Stan directory
replace_stan_minor_version() {
  sed -i '' "s/\(^.*#define STAN_MINOR[[:space:]]*\)\([[:alnum:]]*\).*/\1$(minor_version $1)/g" $stan_directory/src/stan/version.hpp 
}

## replaces the patch version in the Stan directory
replace_stan_patch_version() {
  sed -i '' "s/\(^.*#define STAN_PATCH[[:space:]]*\)\([[:alnum:]]*\)/\1$(patch_version $1)/g" $stan_directory/src/stan/version.hpp 
}

## replaces the major version in the Stan directory
replace_math_major_version() {
  sed -i '' "s/\(^.*#define STAN_MATH_MAJOR[[:space:]]*\)\([[:alnum:]]*\).*/\1$(major_version $1)/g" $math_directory/stan/math/version.hpp 
}

## replaces the minor version in the Stan directory
replace_math_minor_version() {
  sed -i '' "s/\(^.*#define STAN_MATH_MINOR[[:space:]]*\)\([[:alnum:]]*\).*/\1$(minor_version $1)/g" $math_directory/stan/math/version.hpp 
}

## replaces the patch version in the Stan directory
replace_math_patch_version() {
  sed -i '' "s/\(^.*#define STAN_MATH_PATCH[[:space:]]*\)\([[:alnum:]]*\)/\1$(patch_version $1)/g" $math_directory/stan/math/version.hpp 
}

## replaces the version in all source files in the Stan directory
replace_version() {
  for file in "$@"
  do
    sed -i '' "s/$(major_version $old_version)\.$(minor_version $old_version)\.$(patch_version $old_version)/$(major_version $version)\.$(minor_version $version)\.$(patch_version $version)/g" $file
  done
}

replace_version_test() {
  sed -i '' "s/\(^.*EXPECT_EQ(\)\(.*\)\(, STAN_MAJOR);.*\)/\1$(major_version $version)\3/g" src/test/unit/version_test.cpp
  sed -i '' "s/\(^.*EXPECT_EQ(\)\(.*\)\(, STAN_MINOR);.*\)/\1$(minor_version $version)\3/g" src/test/unit/version_test.cpp
  sed -i '' "s/\(^.*EXPECT_EQ(\)\(.*\)\(, STAN_PATCH);.*\)/\1$(patch_version $version)\3/g" src/test/unit/version_test.cpp
  sed -i '' "s/\(^.*EXPECT_EQ(\"\)\(.*\)\(\", stan::MAJOR_VERSION);.*\)/\1$(major_version $version)\3/g" src/test/unit/version_test.cpp
  sed -i '' "s/\(^.*EXPECT_EQ(\"\)\(.*\)\(\", stan::MINOR_VERSION);.*\)/\1$(minor_version $version)\3/g" src/test/unit/version_test.cpp
  sed -i '' "s/\(^.*EXPECT_EQ(\"\)\(.*\)\(\", stan::PATCH_VERSION);.*\)/\1$(patch_version $version)\3/g" src/test/unit/version_test.cpp  
}


## checks the header code for a 201.
curl_success() {
  code=$(sed -n "s,.*HTTP/1.1 \([0-9]\{3\}\).*,\1,p" <<< "$1")
  [[ "$code" -eq "201" ]] || [ "$code" -eq "200" ]
}


## parses the pull request number
parse_github_number() {
  github_number=$(sed -n "s,.*\"number\":[[:space:]]*\([0-9]*\).*,\1,p" <<< "$1")
}


## creates a pull request
##   uses
##     $github_user
##     $github_password
##     $tag_github_api_url
##   arguments
##     $1: title
##     $2: head
##     $3: base
##     $4: body
create_pull_request() {
  data="{
  \"title\": \"$1\",
  \"head\": \"$2\",
  \"base\": \"$3\",
  \"body\": \"$4\" }"

  response=$(eval curl --include --user \"$github_user:$github_password\" --request POST --data \'$data\' $tag_github_api_url/pulls)

  if ! curl_success "${response}"; then
    _msg="
Error creating pull request:
----------------------------
$data


Response:
---------
$response
"
    exit 1
  fi

  parse_github_number "${response}"
}

## merges a pull request
## uses
##  $github_user
##  $github_password
##  $tag_github_api_url
##
## arguments
##  $1: pull request number
##  $2: commit message for the merge
merge_pull_request() {
  echo $tag_github_api_url/pulls/$1/merge
  data="{ \"commit_message\": \"$2\" }"
  echo $data

  response=$(eval curl -i --user \"$github_user:$github_password\" --request PUT --data \'$data\' $tag_github_api_url/pulls/$1/merge)

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


## creates a pull request
##   uses
##     $github_user
##     $github_password
##     $tag_github_api_url
##   arguments
##     $1: title
##     $2: body
create_issue() {
  data="{
  \"title\": \"$1\",
  \"body\": \"$2\" }"

  response=$(eval curl --include --user \"$github_user:$github_password\" --request POST --data \'$data\' $tag_github_api_url/issues)

  if ! curl_success "${response}"; then
    _msg="
Error creating issue
----------------------------
$data


Response:
---------
$response
"
    exit 1
  fi

  parse_github_number "${response}"
}


wait_for_input() {
  input=
  until [ "$input" = "y" ]; do 
    read -p "$1 (Press 'y' to continue): " input
  done
}
