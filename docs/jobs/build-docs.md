## Build Docs

### History

- Master history can be found [here](https://jenkins.mc-stan.org/job/BuildDocs/job/master/)

### Jenkinsfile

Link to Jenkins project: [Stan](https://jenkins.mc-stan.org/job/BuildDocs)

Parameters:  

- `major_version` - Major version of the docs to be built
- `minor_version` - Minor version of the docs to be built

Stages:  

1. [Clean checkout for docs](https://github.com/stan-dev/docs/blob/master/Jenkinsfile#L17)
    - Checks out master of `stan-dev/docs`
2. [Create branch for docs](https://github.com/stan-dev/docs/blob/master/Jenkinsfile#L29)
    - Creates a new branch named `docs-$major_version-$minor_version`
3. [Build docs](https://github.com/stan-dev/docs/blob/master/Jenkinsfile#L39)
    - Builds docs based on major/minor version `python build.py $major_version $minor_version`
4. [Add redirects for docs](https://github.com/stan-dev/docs/blob/master/Jenkinsfile#L44)
    - `python add_redirects.py $major_version $minor_version functions-reference`
    - `python add_redirects.py $major_version $minor_version reference-manual`
    - `python add_redirects.py $major_version $minor_version stan-users-guide`
5. [Push PR for docs](https://github.com/stan-dev/docs/blob/master/Jenkinsfile#L51)
    - Pushes the new branchs
    - Create a PR from this branch
6. [Clean checkout for cmdstan](https://github.com/stan-dev/docs/blob/master/Jenkinsfile#L69)
    - Checks out master of `stan-dev/cmdstan`
7. [Build cmdstan manual](https://github.com/stan-dev/docs/blob/master/Jenkinsfile#L81)
    - `make manual`
    - Archives artifacts in `doc/*.pdf`, will later be shown in the job results.