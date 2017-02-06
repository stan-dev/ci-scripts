# Stan Release Script

## Overview

Goals:
- tag new version of Stan quickly, easily, without error
- stop if Stan is broken, indicate error to user
- should be both interactive and non-interactive


Interactive will walk user through all steps.

Non-interactive will require the user to specify these variables.

### Variables
- `stan_home`: location of Stan. If empty dir, git clone.
- old version: match against version in src/stan/version.hpp
- version: replacement version


## Checklist

1. stan_home should have a clean git clone of stan. 
2. git branch to release/v2.6.0
3. replace uses of old version number (v2.5.0) and replace with new version number (v2.6.0)
  - src/stan/version.hpp
  - src/docs/stan-reference/programming.tex
  - src/docs/stan-reference/stan-reference.tex
  - src/doxygen/doxygen.cfg
4. git add and commit changed files
5. build documentation
  - doc/stan*.pdf
6. git add and commit built documentation
7. test! If passes, git push
10. github: merge pull request
11. git pull; git tag as v2.6.0
12. git update master to v2.6.0
13. create github issue to remove documentation; record number
14. git branch to feature/issue-#-remove-documentation
15. git remove built documentation; git commit
16. git push
17. create pull request


## To do after this is done

1. Make sure all closed issues that have no tag, tagged future, etc. are tagged as v2.6.0
2. Close milestone.
3. Create a GitHub release.
