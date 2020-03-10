## CmdStan

### History

- Master history can be found [here](https://jenkins.mc-stan.org/job/CmdStan/job/master/)
- Develop history can be found [here](https://jenkins.mc-stan.org/job/CmdStan/job/develop/)
- PRs history can be found [here](https://jenkins.mc-stan.org/job/CmdStan/view/change-requests/)

### Jenkinsfile

Link to Jenkins project: [CmdStan](https://jenkins.mc-stan.org/job/CmdStan/)

Parameters:  

- `stan_pr` - Stan PR (Example: PR-123)
- `math_pr` - Math PR (Example: PR-123)

Stages:  

1. [Kill previous builds](https://github.com/stan-dev/cmdstan/blob/develop/Jenkinsfile#L58)
   - If not on `develop` or `master` branch, clean all build history. This frees up some space with builds that we don't really need :)
2. [Clean & Setup](https://github.com/stan-dev/cmdstan/blob/develop/Jenkinsfile#L66)
   - Clean checkout with submodules.
3. [Verify changes](https://github.com/stan-dev/cmdstan/blob/develop/Jenkinsfile#L81)
   - Check if there are changes to the source code
   - If there are changes, pipeline will continue
   - If there are no changes, pipeline will end with success
4. [Parallel tests](https://github.com/stan-dev/cmdstan/blob/develop/Jenkinsfile#L139)
   - Windows interface tests
      - `writeFile(file: "make/local", text: "CXX = ${CXX}\n")` where `CXX = env.CXX`
      - Run tests
      - `withEnv(["PATH+TBB=${WORKSPACE}\\stan\\lib\\stan_math\\lib\\tbb"])`
      - `bat "mingw32-make -j${env.PARALLEL} build"`
      - `"runCmdStanTests.py -j${env.PARALLEL} src/test/interface"`
      - Collect compiler warnings or issues using  [recordIssues](https://plugins.jenkins.io/warnings-ng/) plugin.
   - Linux interface tests with MPI
      - `writeFile(file: "make/local", text: "CXX = ${MPICXX}\n")`
      - `sh "echo STAN_MPI=true >> make/local"`
      - `sh "echo CXX_TYPE=gcc >> make/local"`
      - `sh "make build-mpi > build-mpi.log 2>&1"`
      - Run tests
      - `make -j${env.PARALLEL} build`
      - `./runCmdStanTests.py -j${env.PARALLEL} src/test/interface`
      - Collect compiler warnings or issues using  [recordIssues](https://plugins.jenkins.io/warnings-ng/) plugin.
   - Mac interface tests
      - `writeFile(file: "make/local", text: "CXX = ${CXX}\n")` where `CXX = env.CXX`
      - Run tests
      - `make -j${env.PARALLEL} build`
      - `./runCmdStanTests.py -j${env.PARALLEL} src/test/interface`
      - Collect compiler warnings or issues using  [recordIssues](https://plugins.jenkins.io/warnings-ng/) plugin.
   - Upstream CmdStan Performance tests ( Only when it's a PR or downstream_test/hotfix)
     - Start a build of `CmdStan Performance Tests/downstream_tests` with the following parameters
        - string(name: 'cmdstan_pr', value: env.BRANCH_NAME)
        - string(name: 'stan_pr', value: params.stan_pr)
        - string(name: 'math_pr', value: params.math_pr)
5. [Post action](https://github.com/stan-dev/cmdstan/blob/develop/Jenkinsfile#L256)
   - On Success
     - If the build was started on the master branch, start CmdStan Performance Tests/master
   - On Failure
     - Notify through email
   - On Unstable
     - Notify through email