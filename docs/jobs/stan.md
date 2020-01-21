## Stan

### History

- Master history can be found [here](https://jenkins.mc-stan.org/job/Stan/job/master/)
- Develop history can be found [here](https://jenkins.mc-stan.org/job/Stan/job/develop/)
- PRs history can be found [here](https://jenkins.mc-stan.org/job/Stan/view/change-requests/)

### Jenkinsfile

Link to Jenkins project: [Stan](https://jenkins.mc-stan.org/job/Stan)

Parameters:  

- `math_pr` - Math PR (Example: PR-123)
- `downstream_tests` - PR to test CmdStan upstream against (Example: PR-123)

Stages:  

1. [Kill previous builds](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L63)
   - If not on `develop` or `master` branch, clean all build history. This frees up some space with builds that we don't really need :)
2. [Linting & Doc checks](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L75)
   - Clones the source code
   - Runs
     - `make math-revert`
     - `make clean-all`
     - `git clean -xffd`
   - Checks out math PR using [utils.checkout_pr](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L73)("math", "lib/stan_math", params.math_pr)
   - Stashes a copy of the current repository state for later use in the pipeline
   - Runs [setupCXX](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L6) to write into `make/local` - `CXX=${env.CXX} -Werror`
   - Runs in parallel
     - `make cpplint`
     - `make doxygen`
   - [Records issues](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L98) through the [Jenkins plugin](https://wiki.jenkins.io/display/JENKINS/Warnings+Next+Generation+Plugin) for later visualisation.
3. [Clang-format](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L114)
   - Clones the source code
   - Runs `find src -name '*.hpp' -o -name '*.cpp' | xargs -n20 -P${env.PARALLEL} clang-format -i`
   - Checks for differences with `git diff` if there are, commit format changes and fail the build also send an email to the PR owner.
4. [Unit tests](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L162)
   - Will run in parallel Unit tests
     - `Windows Headers & Unit`
       - Runs [setupCXX](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L6) to write into `make/local` - `CXX=${env.CXX} -Werror`
       - `mingw32-make -f lib/stan_math/make/standalone math-libs`
       - `mingw32-make -j${env.PARALLEL} test-headers`
       - Runs [setupCXX(false)](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L6) to write into `make/local` - `CXX=${env.CXX} ${errorStr}`
       - Runs tests with `withEnv(['PATH+TBB=./lib/stan_math/lib/tbb'])`
         - `runTests.py -j${env.PARALLEL} src/test/unit --make-only`
         - `runTests.py -j${env.PARALLEL} src/test/unit`
         - Stores `test/**/*.xml` with [JUnit Plugin](https://wiki.jenkins.io/display/JENKINS/JUnit+Plugin) for visualisations.
     - `Unit`
       - Runs [setupCXX(false)](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L6) to write into `make/local` - `CXX=${env.CXX} ${errorStr}` 
       - `./runTests.py -j${env.PARALLEL} src/test/unit --make-only`
       - `./runTests.py -j${env.PARALLEL} src/test/unit`
5. [Integration](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L188)
   - Runs [setupCXX](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L6) to write into `make/local` - `CXX=${env.CXX} -Werror`
   - `./runTests.py -j${env.PARALLEL} src/test/integration`
6. [Upstream CmdStan tests](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L197)
   - When it's a `PR`, `downstream_tests` or `downstream_hotfix`
   - Start a job build for [CmdStan](cmdstan.md)/[cmdstan_pr](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L33) with `params.math_pr` and [stan_pr](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L34) as parameters.
7. [Performance](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L207)
   - Runs [setupCXX](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L6) to write into `make/local` - `CXX=${env.CXX} -Werror`
   - `./runTests.py -j${env.PARALLEL} src/test/performance`
   - `cd test/performance`
   - `RScript ../../src/test/performance/plot_performance.R`
   - Stores `test/**/*.xml` with [JUnit Plugin](https://wiki.jenkins.io/display/JENKINS/JUnit+Plugin) for visualisations.
   - Archives artifacts `test/performance/performance.csv,test/performance/performance.png` to be shown in the job results.
   - Stores `test/performance/**.xml` using [perfReport](https://jenkins.io/doc/pipeline/steps/performance/) for performance comparasion.
8. [Post Action](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L230)
   - Always
       - When the node is either `osx` or `linux`
       - [Records issues](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L98) through the [Jenkins plugin](https://wiki.jenkins.io/display/JENKINS/Warnings+Next+Generation+Plugin) for later visualisation.   
   - On Success
        - Execute [utils.updateUpstream(env, 'cmdstan')](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L27) which will use the [scripts](https://github.com/stan-dev/ci-scripts/tree/master/jenkins) to update upstream module.
        - Execute [utils.mailBuildResults](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L51) ("SUCCESSFUL") to send a notification email.
   - On Failure
        - Execute [utils.mailBuildResults](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L51) ("FAILURE", [alsoNotify()](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L30)) to send a notification email.
   - On Unstable
        - Execute [utils.mailBuildResults](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L51) ("UNSTABLE", [alsoNotify()](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L30)) to send a notification email.