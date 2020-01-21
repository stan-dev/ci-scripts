For a tutorial on interacting with the current Jenkins jobs, please see this discourse post:
http://discourse.mc-stan.org/t/new-jenkins-jobs-tutorial/2383

# GitHub repos

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

# Build agents

See [agents](agents.md) for more detail about our agents and their spefications. We currently have:
 - 2x MacOS 
 - 2x Windows
 - 2x Linux
 - On-Demand EC2 instances for Linux
 - On-Demand EC2 instances for Windows
        
# Current jobs

We test each pull request for the repositories, soon we will ignore PRs that do not modify the source code to speedup build times and save resources.
We also test every time a merge happens into the `develop` branch.   
Why do we do both? Honestly -- weird stuff happens sometimes and even a merge that seems safe ends up breaking the `develop` branch. (It hasn't happened in a while, but it has happened.) I'd just rather know when that happens.  

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