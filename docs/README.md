For a tutorial on interacting with the current Jenkins jobs, please see this discourse post:
http://discourse.mc-stan.org/t/new-jenkins-jobs-tutorial/2383

# GitHub repos

These are the repositories tested/automated using Jenkins:

- [Math](github.com/stan-dev/math)
- [Stan](github.com/stan-dev/stan)
- [CmdStan](github.com/stan-dev/cmdstan)
- [Stanc3](github.com/stan-dev/stanc3)
- [Docs](https://github.com/stan-dev/docs) (WIP)

There is also a dependency between the repos managed by git submodules:
```
math  <-  stan  <- cmdstan
```

Math is standalone.  
Math is a Stan submodule. It's located at `./lib/stan_math`.  
Stan is a CmdStan submodule. It's located at `./stan`.  
  
[Jenkins shared libraries](https://github.com/stan-dev/jenkins-shared-libraries) - This is code used across Jenkins projects, as a package so we don't repeat ourselves.

# Current build machines

- `gelman-group-linux`
    - Operating System: `Ubuntu 18.04.2 LTS`
    - Java version: `1.8.0_232-8u232-b09-0ubuntu1~18.04.1-b09`
    - RAM: `32 GB`
    - CPU: `Intel Xeon CPU E5-2630 v3 @ 2.40GHz`
    - GPU: `NVIDIA Corporation GM107GL [Quadro K620]`
    - Environment variables:
        - `CXX=clang++-6.0`
        - `GCC=g++`
        - `MPICXX=mpicxx.openmpi`
        - `N_TESTS=150`
        - `OPENCL_DEVICE_ID=0`
        - `PARALLEL=16`
    - Labels: `linux` `mpi` `docker` `gpu` `distribution-tests`
    - Disks:
        - `HDD 1 TB`
        
- `gelman-group-mac`
    - Operating System: `OS X 10.11.6 (15G22010)` `(Darwin 15.6.0)`
    - Java version: `9.0.4`
    - RAM: `64 GB`
    - CPU:`Intel Xeon CPU E5-1680 v2 @ 3.00GHz`
    - GPU: 2x`AMD FirePro D700`
    - Environment variables:
        - `CXX=/usr/local/opt/llvm@6/bin/clang++`
        - `GCC=g++`
        - `MPICXX=mpicxx`
        - `N_TESTS=350`
        - `OPENCL_DEVICE_ID=1`
        - `PARALLEL=16`
        - `PATH=$PATH:/usr/local/bin:/Library/TeX/texbin`
    - Labels: `osx` `gpu` `ocaml`
    - Disks:
        - `NvME SSD 512 GB`
        
- `gelman-group-win-new`
    - Operating System: `Windows 10 Pro (Version 1809) (OS Build 17763.914)`
    - Java version: `1.8.0_161`
    - RAM: `32 GB`
    - CPU:`Intel i5-6600K CPU @ 3.50GHz`
    - GPU: `Nvidia Titan Xp`
    - Environment variables:
        - `CC=gcc`
        - `CXX=g++`
        - `N_TESTS=100`
        - `OPENCL_DEVICE_ID=0`
        - `PARALLEL=16`
    - Labels: `windows` `wsl` [windows-low-space](https://jenkins.mc-stan.org/job/Clean-windows-workdir/)
    - Disks:
        - `NvME SSD 256 GB`
        
- `gelman-group-win2`
    - Operating System: `Windows 10 Pro (Version 1809) (OS Build 17763.914)`
    - Java version: `1.8.0_161`
    - RAM: `32 GB`
    - CPU:`Intel Xeon CPU E5-2630 v3 @ 2.40 GHz`
    - GPU: `Nvidia Quadro K620`
    - Environment variables:
        - `CXX=g++`
        - `GCC=g++`
        - `N_TESTS=100`
        - `PARALLEL=16`
    - Labels: `windows` `wsl`
    - Disks:
        - `HDD 1 TB`
- `old-imac`
    - Operating System: `macOS 10.13.4 (17E199) (Darwin 17.5.0)`
    - Java version: `1.8.0_161`
    - RAM: `16 GB`
    - CPU:`Intel Core i7 CPU 870  @ 2.93GHz`
    - GPU: `ATI Radeon HD 5750`
    - Environment variables:
        - `CXX=/usr/local/opt/llvm@6/bin/clang++`
        - `GCC=g++`
        - `MPICXX=mpicxx`
        - `N_TESTS=500`
        - `OPENCL_DEVICE_ID=1`
        - `PARALLEL=6`
        - `PATH=/Library/TeX/texbin`
    - Labels: `master` `oldimac`
    - Disks:
        - `SSD 256 TB`
        - `SSD 256 TB`
- `master` - Doesn't run much builds on the machine but does some docker builds because of the label `docker-registry`
        
# Current jobs

We test each pull request for the repositories, soon we will ignore PRs that do not modify the source code to speedup build times and save resources.
We also test every time a merge happens into the `develop` branch.   
Why do we do both? Honestly -- weird stuff happens sometimes and even a merge that seems safe ends up breaking the `develop` branch. (It hasn't happened in a while, but it has happened.) I'd just rather know when that happens.  

## Math

### History

- Master history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/job/master/)
- Develop history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/job/develop/)
- PRs history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/view/change-requests/)

### Jenkinsfile

Link to Jenkins job: [Math](https://jenkins.mc-stan.org/job/Math%20Pipeline)

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
   - Checks for differences with `git diff` if there are, commit format changes and fail the build.
3. [Linting & Doc checks](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L118)
   - Creates a stash of the clean, cloned repository to be later used in the jobs without git cloning to save resources and time.
   - Echoes `echo CXX=${env.CXX} -Werror` and `echo BOOST_PARALLEL_JOBS=${env.PARALLEL}` into `make/local`
   - Runs in parallel
        - CppLint: `make cpplint`
        - Dependencies: `make test-math-dependencies`
        - Documentation: `make doxygen`
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
9. Post action 
    - On Success
        - Execute [utils.updateUpstream(env, 'stan')](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L27) which will use the [scripts](https://github.com/stan-dev/ci-scripts/tree/master/jenkins) to update upstream module.
    - On Failure
        - Execute [utils.mailBuildResults](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L51) ("FAILURE", [alsoNotify()](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L30)) to send a notification email.
    - On Unstable
        - Execute [utils.mailBuildResults](https://github.com/stan-dev/jenkins-shared-libraries/blob/master/src/org/stan/Utils.groovy#L51) ("UNSTABLE", [alsoNotify()](https://github.com/stan-dev/math/blob/develop/Jenkinsfile#L30)) to send a notification email.