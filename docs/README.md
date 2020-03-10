For a tutorial on interacting with the current Jenkins jobs, please see this discourse post:
http://discourse.mc-stan.org/t/new-jenkins-jobs-tutorial/2383

# Contents

- [Contents](#contents)
- [Repositories](#repositories)
- [Agents](#agents)
- [Jobs](#jobs)
  - [CmdStan](#cmdstan)
    - [History](#history)
    - [Jenkinsfile](#jenkinsfile)
  - [Math](#math)
    - [History](#history-1)
    - [Jenkinsfile](#jenkinsfile-1)
  - [Stan](#stan)
    - [History](#history-2)
    - [Jenkinsfile](#jenkinsfile-2)
  - [Stanc3](#stanc3)
    - [History](#history-3)
    - [Jenkinsfile](#jenkinsfile-3)
  - [CmdStan Performance Tests](#cmdstan-performance-tests)
    - [History](#history-4)
    - [Jenkinsfile](#jenkinsfile-4)
  - [Custom CmdStan Performance Tests](#custom-cmdstan-performance-tests)
    - [History](#history-5)
    - [Jenkinsfile](#jenkinsfile-5)
  - [Daily Stan Performance](#daily-stan-performance)
    - [History](#history-6)
    - [Jenkinsfile](#jenkinsfile-6)
  - [Build Docs](#build-docs)
    - [History](#history-7)
    - [Jenkinsfile](#jenkinsfile-7)
- [How To](#how-to)
    - [Extract job logs for debugging](#extract-job-logs-for-debugging)
    - [Check on which machine a job ran](#check-on-which-machine-a-job-ran)

# Repositories

These are the repositories tested/automated using Jenkins:

- [Math](https://github.com/stan-dev/math)
- [Stan](https://github.com/stan-dev/stan)
- [CmdStan](https://github.com/stan-dev/cmdstan)
- [Stanc3](https://github.com/stan-dev/stanc3)
- [Docs](https://github.com/stan-dev/docs)

There is also a dependency between the repos managed by git submodules:
```
math  <-  stan  <- cmdstan
```

Math is standalone.  
Math is a Stan submodule. It's located at `./lib/stan_math`.  
Stan is a CmdStan submodule. It's located at `./stan`.  
  
[Jenkins shared libraries](https://github.com/stan-dev/jenkins-shared-libraries) - This is code used across Jenkins projects, as a package so we don't repeat ourselves.

# Agents

See [agents](agents.md) for more detail about our agents and their spefications. We currently have:
 - 2x MacOS 
 - 2x Windows
 - 2x Linux
 - On-Demand EC2 instances for Linux
 - On-Demand EC2 instances for Windows
        
# Jobs

We test each pull request for the repositories, ignoring the ones that do not touch the source code. To check what considered source code, please check each project [Jenkinsfile](https://github.com/stan-dev/cmdstan/blob/develop/Jenkinsfile#L30)  
We also test every time a merge happens into the `develop` branch.   
Why do we do both? Honestly -- weird stuff happens sometimes and even a merge that seems safe ends up breaking the `develop` branch. (It hasn't happened in a while, but it has happened.) I'd just rather know when that happens.  

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
  
Checkout the [README](jobs/cmdstan.md) for more technical details.  

## Math

Link to Jenkins project: [Math](https://jenkins.mc-stan.org/job/Math%20Pipeline)

### History

- Master history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/job/master/)
- Develop history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/job/develop/)
- PRs history can be found [here](https://jenkins.mc-stan.org/job/Math%20Pipeline/view/change-requests/)

### Jenkinsfile

Parameters:  

- `cmdstan_pr` - CmdStan PR (Example: PR-123)
- `stan_pr` - Stan PR (Example: PR-123)
- `withRowVector` - Run additional distribution tests on RowVectors (takes 5x as long) (Boolean)

Checkout the [README](jobs/math.md) for more technical details.

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

Checkout the [README](jobs/stan.md) for more technical details.

## Stanc3

### History

- History can be found [here](https://jenkins.mc-stan.org/job/stanc3/job/master/)

### Jenkinsfile

Link to Jenkins project: [Stanc3](https://jenkins.mc-stan.org/job/stanc3/job/master/)
Parameters:  

- `compile_all` - Try compiling all models in test/integration/good

Checkout the [README](jobs/stanc3.md) for more technical details.

## CmdStan Performance Tests

### History

- Master history can be found [here](https://jenkins.mc-stan.org/job/CmdStan%20Performance%20Tests/job/master/)
- Custom history can be found [here](https://jenkins.mc-stan.org/job/CmdStan%20Performance%20Tests/job/Custom/)
- Downstream_tests history can be found [here](https://jenkins.mc-stan.org/job/CmdStan%20Performance%20Tests/job/downstream_tests/)

### Jenkinsfile

Link to Jenkins project: [CmdStan Performance Tests](https://jenkins.mc-stan.org/job/CmdStan%20Performance%20Tests)

Parameters:  

- `cmdstan_pr` - CmdStan PR (Example: PR-123) which will be tested against develop
- `stan_pr` - Stan PR (Example: PR-123)
- `math_pr` - Math PR (Example: PR-123)

Checkout the [README](jobs/cmdstan-performance-tests.md) for more technical details.

## Custom CmdStan Performance Tests

### History

- History can be found [here](https://jenkins.mc-stan.org/job/CmdStan%20Performance%20Tests/job/Custom/)

### Jenkinsfile

Link to Jenkins project: [Custom CmdStan Performance Tests](https://jenkins.mc-stan.org/job/CmdStan%20Performance%20Tests/job/Custom/)

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

Checkout the [README](jobs/custom-cmdstan-performance-tests.md) for more technical details.

## Daily Stan Performance

### History

- History can be found [here](https://jenkins.mc-stan.org/job/Daily%20Stan%20Performance/)

### Jenkinsfile

Link to Jenkins project: [CmdStan Performance Tests](https://jenkins.mc-stan.org/job/Daily%20Stan%20Performance/)
This is a visual job rather than scripted Jenkins pipeline, you can find it [here](https://jenkins.mc-stan.org/job/Daily%20Stan%20Performance/configure)  

Parameters:  
None  

Checkout the [README](jobs/daily-stan-performance.md) for more technical details.

## Build Docs

### History

- Master history can be found [here](https://jenkins.mc-stan.org/job/BuildDocs/job/master/)

### Jenkinsfile

Link to Jenkins project: [Stan](https://jenkins.mc-stan.org/job/BuildDocs)

Parameters:  

- `major_version` - Major version of the docs to be built
- `minor_version` - Minor version of the docs to be built

Checkout the [README](jobs/build-docs.md) for more technical details.

# How To

### Extract job logs for debugging

Sometimes you need to get all the logs from a job to debug an issue or look for clues. Doing this through a browser is very slow and painful.  
Let's take as example this [job](https://jenkins.mc-stan.org/job/CmdStan/job/develop/598/) where its url is `https://jenkins.mc-stan.org/job/CmdStan/job/develop/598`.  

To download the entire log all we need to do is append `/consoleText` to the url and then use `wget`. Example:  
`wget https://jenkins.mc-stan.org/job/CmdStan/job/develop/598/consoleText`  

For windows just browse `https://jenkins.mc-stan.org/job/CmdStan/job/develop/598/consoleText` with your browser, right click and save on your machine.

### Check on which machine a job ran

To debug on which machine a job ran just follow the above [Extract job logs for debugging](#extract-job-logs-for-debugging) to get the entire log.  
Then simply open it inside an editor ( Ex. Visual Studio Code ) and `CTRL + F` for `Running on`.  
What you should find looks like: `Running on gelman-group-linux`