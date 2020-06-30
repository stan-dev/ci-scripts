## CmdStan Performance Tests

### History

- History can be found [here](https://jenkins.mc-stan.org/job/CmdStan%20Performance%20Tests/job/Custom/)

### Jenkinsfile

Link to Jenkins project: [CmdStan Performance Tests](https://github.com/stan-dev/performance-tests-cmdstan/blob/custom/Jenkinsfile)

Parameters:  

- `cmdstan_origin_pr` - CmdStan hash/branch to base hash/branch. Example: PR-123 or e6c3010fd0168ef961a531d56b2330fd64728523 or develop
- `cmdstan_pr` - CmdStan hash/branch to compare against.
- `stan_pr` - Stan PR to test against.
- `math_pr` - Math PR to test against.

- `make_local_windows` - Make/file contents for the windows machine
- `make_local_linux` - Make/file contents for the linux machine
- `make_local_macosx` - Make/file contents for the macos machine
  
- `run_windows` - True/False to run tests on windows
- `golds_runs_windows` - Number of runs for golds
- `shotguns_runs_windows` - Number of runs for shotguns

- `run_linux` - True/False to run tests on linux
- `golds_runs_linux` - Number of runs for golds
- `shotguns_runs_linux` - Number of runs for shotguns

- `run_macosx` - True/False to run tests on macos
- `golds_runs_macosx` - Number of runs for golds
- `shotguns_runs_macosx` - Number of runs for shotguns

Stages:  

1. [Parallel tests](https://github.com/stan-dev/performance-tests-cmdstan/blob/custom/Jenkinsfile#L66)
    - Test cmdstan base against cmdstan pointer in this branch on windows
      - If `run_windows` is set to True
      - Clean checkout
      - Compare git hashes `bash -cl "compare-git-hashes.sh stat_comp_benchmarks ${cmdstan_origin_pr} \$cmdstan_hash ${params.stan_pr} {params.math_pr} windows"`
      - Push to `cmdstan/make/local` the jenkins parameter `bat "bash -c \"echo ${make_local_windows} > cmdstan/make/local\""`
      - Run performance golds `bat "bash -c \"python runPerformanceTests.py -j${env.PARALLEL} --runs=${golds_runs_windows} --check-golds --name=windows_known_good_perf --tests-file=known_good_perf_all.tests\""`
      - Make clean
      - Push to `cmdstan/make/local` the jenkins parameter `bat "bash -c \"echo ${make_local_windows} > cmdstan/make/local\""`
      - Run performance shotguns `bat "bash -c \"python runPerformanceTests.py -j${env.PARALLEL} --runs=${shotguns_runs_windows} --name=windows_shotgun_perf --tests-file=shotgun_perf_all.tests\""`
      - archiveArtifacts `'*.xml'`
    - Test cmdstan base against cmdstan pointer in this branch on linux
      - If `run_linux` is set to True
      - Clean checkout
      - Compare git hashes `./compare-git-hashes.sh stat_comp_benchmarks ${cmdstan_origin_pr} \$cmdstan_hash ${branchOrPR(params.stan_pr)} ${branchOrPR(params.math_pr)} linux`
      - Push to `cmdstan/make/local` the jenkins parameter `writeFile(file: "cmdstan/make/local", text: make_local_linux)`
      - Run performance golds `sh "./runPerformanceTests.py -j${env.PARALLEL} --runs=${golds_runs_linux} --check-golds --name=linux_known_good_perf --tests-file=known_good_perf_all.tests"`
      - Make clean
      - Push to `cmdstan/make/local` the jenkins parameter `writeFile(file: "cmdstan/make/local", text: make_local_linux)`
      - Run performance shotguns `sh "./runPerformanceTests.py -j${env.PARALLEL} --runs=${shotguns_runs_linux} --name=linux_shotgun_perf --tests-file=shotgun_perf_all.tests"`
      - archiveArtifacts `'*.xml'`
    - Test cmdstan base against cmdstan pointer in this branch on macosx
      - If `run_macosx` is set to True
      - Clean checkout
      - Compare git hashes `./compare-git-hashes.sh stat_comp_benchmarks ${cmdstan_origin_pr} \$cmdstan_hash ${branchOrPR(params.stan_pr)} ${branchOrPR(params.math_pr)} macos`
      - Push to `cmdstan/make/local` the jenkins parameter `writeFile(file: "cmdstan/make/local", text: make_local_macosx)`
      - Run performance golds `sh "./runPerformanceTests.py -j${env.PARALLEL} --runs=${golds_runs_macosx} --check-golds --name=macos_known_good_perf --tests-file=known_good_perf_all.tests"`
      - Make clean
      - Push to `cmdstan/make/local` the jenkins parameter `writeFile(file: "cmdstan/make/local", text: make_local_macosx)`
      - Run performance shotguns `sh "./runPerformanceTests.py -j${env.PARALLEL} --runs=${shotguns_runs_macosx} --name=macos_shotgun_perf --tests-file=shotgun_perf_all.tests"`
      - archiveArtifacts `'*.xml'`