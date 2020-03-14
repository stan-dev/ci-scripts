## Stanc3

### History

- History can be found [here](https://jenkins.mc-stan.org/job/stanc3-test-binaries/)

### Getting the binaries

A build usually takes around 10 minutes, after that you can download all the binaries straight from Jenkins.  
Go to the [results page](https://jenkins.mc-stan.org/job/stanc3-test-binaries/) and click your build, you will be sent to a console log page, 
on top-left you need to click on `status`.  
Now you should be able to see a list of `Build Artifacts` from where you can click & download the binary you need.  

You can use:   
`STANC3_TEST_BIN_URL=https://jenkins.mc-stan.org/job/stanc3-test-binaries/{build_number}/artifact` in `make/local`.  
Where `build_number` is your job # from Jenkins, you can find in in the URL of your job or Jenkins UI.  

### Jenkinsfile

Link to Jenkins project: [Stanc3](https://jenkins.mc-stan.org/job/stanc3-test-binaries/)
Parameters:  

- `git_branch` - Please specify a git branch ( develop ), git hash ( aace72b6ccecbb750431c46f418879b325416c7d ), pull request ( PR-123 ), pull request from fork ( PR-123 )

Stages:  

1. [Build](https://github.com/stan-dev/stanc3/blob/master/Jenkinsfile#L37)
   - Build using [Dockerfile](https://github.com/stan-dev/stanc3/blob/master/docker/debian/Dockerfile) with arguments `-u root --entrypoint=\'\'`
     - `eval \$(opam env)`
     - `dune build @install`
     - `sh "mkdir -p bin && mv _build/default/src/stanc/stanc.exe bin/stanc"`
     - Archive `bin/stanc, notes/working-models.txt` for later use
2. [Build and test static release binaries](https://github.com/stan-dev/stanc3/blob/master/Jenkinsfile#L158)
    - Only on master
    - Will run in parallel
      - Build & test Mac OS X binary ( osx & ocaml labels )
        - Update opam and ensure dependencies exist
        - `eval \$(opam env)`
        - `opam update || true`
        - `bash -x scripts/install_build_deps.sh`
        - `dune subst`
        - Build
        - `dune build @install`
        - Test
        - `eval \$(opam env)`
        - `time dune runtest --verbose`
        - ```mkdir -p bin && mv `find _build -name stanc.exe` bin/mac-stanc```
        - `mv _build/default/src/stan2tfp/stan2tfp.exe bin/mac-stan2tfp`
        - Archive `bin/*` for later use 
      - Build stanc.js
        - Build using [Dockerfile](https://github.com/stan-dev/stanc3/blob/master/docker/debian/Dockerfile) with arguments `-u root --entrypoint=\'\'`
        - `eval \$(opam env)`
        - `dune subst`
        - `dune build --profile release src/stancjs`
        - ```mkdir -p bin && mv `find _build -name stancjs.bc.js` bin/stanc.js```
        - ```mv `find _build -name index.html` bin/load_stanc.html```
        - Archive `bin/*` for later use 
      - Build & test a static Linux binary
        - Build using [Dockerfile](https://github.com/stan-dev/stanc3/blob/master/docker/static/Dockerfile) with arguments `-u 1000 --entrypoint=\'\'`
        - `eval \$(opam env)`
        - `dune subst`
        - `dune build @install --profile static`
        - Test
        - `eval \$(opam env)`
        - `time dune runtest --profile static --verbose`
        - ```mkdir -p bin && mv `find _build -name stanc.exe` bin/linux-stanc```
        - ```mv `find _build -name stan2tfp.exe` bin/linux-stan2tfp```
        - Archive `bin/*` for later use 
      - Build & test static Windows binary ( WSL label )
        - `bat "bash -cl \"eval \$(opam env) make clean; dune subst; dune build -x windows; dune runtest --verbose\""`
        - `bat """bash -cl "rm -rf bin/*; mkdir -p bin; mv _build/default.windows/src/stanc/stanc.exe bin/windows-stanc" """`
        - `bat "bash -cl \"mv _build/default.windows/src/stan2tfp/stan2tfp.exe bin/windows-stan2tfp\""`
        - Archive `bin/*` for later use 
