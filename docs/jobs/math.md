## Math

### History

- Master history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/job/master/)
- Develop history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/job/develop/)
- PRs history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/view/change-requests/)

### Jenkinsfile

Link to Jenkins project: [Math](https://jenkins.mc-stan.org/job/Math%20Pipeline)

Parameters:  

- `cmdstan_pr` - CmdStan PR (Example: PR-123)
- `stan_pr` - Stan PR (Example: PR-123)
- `withRowVector` - Run additional distribution tests on RowVectors (takes 5x as long) (Boolean)

Environment variables:
- `STAN_NUM_THREADS = '4'`

Stages:  

1. [Kill previous builds](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L60)
   - If not on `develop` or `master` branch, clean all build history. This frees up some space with builds that we don't really need :)
2. [Clang-format](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L71)
   - Clones the source code
   - Runs `find stan test -name '*.hpp' -o -name '*.cpp' | xargs -n20 -P${env.PARALLEL} clang-format -i`
   - Checks for differences with `git diff` if there are, commit format changes and fail the build also send an email to the PR owner.
3. [Linting & Doc checks](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L118)
   - Creates a stash of the clean, cloned repository to be later used in the jobs without git cloning to save resources and time.
   - Echoes `echo CXX=${env.CXX} -Werror` and `echo BOOST_PARALLEL_JOBS=${env.PARALLEL}` into `make/local`
   - Runs in parallel
        - CppLint: `make cpplint`
        - Dependencies: `make test-math-dependencies`
        - Documentation: `make doxygen`
   - [Records issues](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L139) through the [Jenkins plugin](https://wiki.jenkins.io/display/JENKINS/Warnings+Next+Generation+Plugin) for later visualisation.
4. [Headers checks](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L146)
   - Will run in Parallel Header Checks
        - MacOs
            - `echo CXX=${env.CXX} -Werror > make/local`
            - `make -j${env.PARALLEL} test-headers`
        - Linux
            - `echo CXX=${env.CXX} -Werror > make/local`
            - `echo STAN_OPENCL=true>> make/local`
            - `echo OPENCL_PLATFORM_ID=0>> make/local`
            - `echo OPENCL_DEVICE_ID=${OPENCL_DEVICE_ID}>> make/local`
            - `make -j${env.PARALLEL} test-headers`
        - Windows (WIP)
            - `echo CXX=${env.CXX} -Werror > make/local`
            - `echo STAN_OPENCL=true>> make/local`
            - `echo OPENCL_PLATFORM_ID=0>> make/local`
            - `echo OPENCL_DEVICE_ID=${OPENCL_DEVICE_ID}>> make/local`
            - `make -j${env.PARALLEL} test-headers`
5. [Always-run tests part 1](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L173)
    - Will run in Parallel
        - Linux Unit with MPI
            - `echo CXX=${MPICXX} >> make/local`
            - `echo CXX_TYPE=gcc >> make/local`
            - `echo STAN_MPI=true >> make/local`
            - `./runTests.py -j${env.PARALLEL} test/unit --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit`
        - Full unit with GPU on Linux
            - `echo CXX=${env.CXX} -Werror > make/local`
            - `echo STAN_OPENCL=true>> make/local`
            - `echo OPENCL_PLATFORM_ID=0>> make/local`
            - `echo OPENCL_DEVICE_ID=${OPENCL_DEVICE_ID}>> make/local`
            - `./runTests.py -j${env.PARALLEL} test/unit --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit`
        - Full unit with GPU on Windows (WIP)
            - `echo CXX=${env.CXX} -Werror > make/local`
            - `echo STAN_OPENCL=true>> make/local`
            - `echo OPENCL_PLATFORM_ID=0>> make/local`
            - `echo OPENCL_DEVICE_ID=${OPENCL_DEVICE_ID}>> make/local`
            - `echo LDFLAGS_OPENCL= -L "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v10.1\lib\x64" -lOpenCL >> make/local`
            - `mingw32-make.exe -f make/standalone math-libs`
            - `./runTests.py -j${env.PARALLEL} test/unit --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit`
6. [Always-run tests part 2](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L202)
    - Will run in Parallel
        - Distribution tests
            - `echo CXX=${env.CXX} > make/local`
            - `echo O=0 >> make/local`
            - `echo N_TESTS=${env.N_TESTS} >> make/local`
            - `if (params.withRowVector || isBranch('develop') || isBranch('master'))`
                - `echo CXXFLAGS+=-DSTAN_TEST_ROW_VECTORS >> make/local`
            - `./runTests.py -j${env.PARALLEL} test/prob`
        - Threading tests
            - `echo CXX=${env.CXX} -Werror > make/local`
            - `echo CPPFLAGS+=-DSTAN_THREADS >> make/local`
            - `./runTests.py -j${env.PARALLEL} test/unit -f thread --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit -f thread`
            - `find . -name *_test.xml | xargs rm`
            - `./runTests.py -j${env.PARALLEL} test/unit -f map_rect --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit -f map_rect`
        - Windows Headers & Unit
            - `mingw32-make -j${env.PARALLEL} test-headers`
            - `mingw32-make.exe -f make/standalone math-libs`
            - `./runTests.py -j${env.PARALLEL} test/unit --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit`
        - Windows Threading
            - `echo CXX=${env.CXX} -Werror > make/local`
            - `echo CXXFLAGS+=-DSTAN_THREADS >> make/local`
            - `mingw32-make.exe -f make/standalone math-libs`
            - `./runTests.py -j${env.PARALLEL} test/unit -f thread --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit -f thread`
            - `mingw32-make.exe -f make/standalone math-libs`
            - `./runTests.py -j${env.PARALLEL} test/unit -f map_rect --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit -f map_rect`
7. [Additional merge tests](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L266) (Only on `develop` and `master` branches)
    - Will run in Parallel
        - Linux Unit with Threading
            - `echo CXX=${GCC} >> make/local`
            - `echo CXXFLAGS=-DSTAN_THREADS >> make/local`
            - `./runTests.py -j${env.PARALLEL} test/unit --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit`
        - Mac Unit with Threading
            - `echo CC=${env.CXX} -Werror > make/local`
            - `echo CXXFLAGS+=-DSTAN_THREADS >> make/local`
            - `./runTests.py -j${env.PARALLEL} test/unit --make-only`
            - `./runTests.py -j${env.PARALLEL} test/unit`
8. [Upstream tests](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L293) (Only on PRs)
    - Start a [Stan PR job](https://github.com/stan-dev/stan/blob/develop/Jenkinsfile#L51) with the parameters:
        - `math_pr` set to the current PR
        - `cmdstan_pr` set to `env.CHANGE_TARGET == "master" ? "downstream_hotfix" : "downstream_tests"`  
  Where `env.CHANGE_TARGET`: For a multibranch project corresponding to some kind of change request, this will be set to the target or base branch to which the change could be merged, if supported; else unset.
8. [Upload doxygen](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L301) (Only on develop)
    - Execute `make doxygen`
    - Push to github
9. [Post action](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L327)
    - Always
        - When the node is either `osx` or `linux`
        - [Records issues](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L330) through the [Jenkins plugin](https://wiki.jenkins.io/display/JENKINS/Warnings+Next+Generation+Plugin) for later visualisation.   
    - On Success
        - Execute [utils.updateUpstream(env, 'stan')](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L27) which will use the [scripts](https://github.com/stan-dev/ci-scripts/tree/master/jenkins) to update upstream module.
        - Execute [utils.mailBuildResults](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L51) ("SUCCESSFUL") to send a notification email.
    - On Failure
        - Execute [utils.mailBuildResults](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L51) ("FAILURE", [alsoNotify()](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L30)) to send a notification email.
    - On Unstable
        - Execute [utils.mailBuildResults](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L51) ("UNSTABLE", [alsoNotify()](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L30)) to send a notification email.