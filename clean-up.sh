#!/bin/bash

## remove multiple blank lines
find stan -name *.hpp -exec perl -0777 -pi -e 's/\n\n\n/\n\n/igs' {} \;

## remove space between namespace stan and next namespace
find stan -name *.hpp -exec perl -0777 -pi -e 's/namespace stan {\n\n  namespace/namespace stan {\n  namespace/igs' {} \;

## remove "using stan::math::*;" statements
find stan -name *.hpp -exec perl -0777 -pi -e '/using stan::math::/d' {} \;
find stan -name *.hpp -exec sed -i '' '/using stan::math::/d' {} \;


## removing "stan::math::" from statements
find stan -name *.hpp -exec sed -i '' 's/stan::math:://' {} \;

## search through these files to remove end-of-namespace comments
grep -r '}   //' stan

## search through these files to remove 'const double&' arguments
grep -rl 'const double&' stan

## search through these files to remove 'const int&' arguments
grep -rl 'const int&' stan

## search through these files to change leading underscores to trailing
grep -rl ' _' stan
