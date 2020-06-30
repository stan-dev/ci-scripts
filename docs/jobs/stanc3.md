## Stanc3

### History

- History can be found [here](https://jenkins.mc-stan.org/job/stanc3/job/master/)

### Jenkinsfile

Link to Jenkins project: [Stanc3](https://jenkins.mc-stan.org/job/stanc3/job/master/)
Parameters:  

- `compile_all` - Try compiling all models in test/integration/good

Stages:  

1. [Kill previous builds](https://github.com/stan-dev/stanc3/blob/master/Jenkinsfile#L29)
   - If not on `develop` or `master` branch, clean all build history. This frees up some space with builds that we don't really need :)
2. [Build](https://github.com/stan-dev/stanc3/blob/master/Jenkinsfile#L37)
   - Build using [Dockerfile](https://github.com/stan-dev/stanc3/blob/master/docker/debian/Dockerfile) with arguments `-u root --entrypoint=\'\'`
     - `eval \$(opam env)`
     - `dune build @install`
     - `sh "mkdir -p bin && mv _build/default/src/stanc/stanc.exe bin/stanc"`
     - Stash `bin/stanc, notes/working-models.txt` for later use
3. [Test](https://github.com/stan-dev/stanc3/blob/master/Jenkinsfile#L56)
   - Will run in parallel
     - Dune tests
       - Run tests using [Dockerfile](https://github.com/stan-dev/stanc3/blob/master/docker/debian/Dockerfile) with arguments `-u root --entrypoint=\'\'`
       - `eval \$(opam env)`
       - `dune runtest`
     - Try to compile all good integration models ( Only when `params.compile_all`, on a linux agent )
       - Unstash build files from previous step
       - Clone CmdStan Performance Tests
       - `writeFile(file:"performance-tests-cmdstan/cmdstan/make/local", text:"O=0\nCXXFLAGS+=-o/dev/null -S -Wno-unused-command-line-argument")`
       - `cd performance-tests-cmdstan`
       - `cd cmdstan; make -j${env.PARALLEL} build; cd ..`
       - `cp ../bin/stanc cmdstan/bin/stanc`
       - Clone stanc3
       - `CXX="${CXX}" ./runPerformanceTests.py --runs=0 stanc3/test/integration/good || true`
       - Gather `performance-tests-cmdstan/performance.xml` for [Xunit Plugin](https://plugins.jenkins.io/xunit/)
     - Run all models end-to-end ( linux agent )
       - Unstash build files from previous step
       - Clone CmdStan Performance Tests
       - `cd performance-tests-cmdstan`
       - `git show HEAD --stat`
       - `echo "example-models/regression_tests/mother.stan" > all.tests`
       - `cat known_good_perf_all.tests >> all.tests`
       - `echo "" >> all.tests`
       - `cat shotgun_perf_all.tests >> all.tests`
       - `cat all.tests`
       - `echo "CXXFLAGS+=-march=core2" > cmdstan/make/local`
       - `cd cmdstan; git show HEAD --stat; STANC2=true make -j4 build; cd ..`
       - `CXX="${CXX}" ./compare-compilers.sh "--tests-file all.tests --num-samples=10" "\$(readlink -f ../bin/stanc)"`
       - Gather `performance-tests-cmdstan/performance.xml` for [Xunit Plugin](https://plugins.jenkins.io/xunit/)
       - Archive artifacts `performance-tests-cmdstan/performance.xml`
       - Gather `performance-tests-cmdstan/performance.xml` for the [Performance report plugin](https://jenkins.io/doc/pipeline/steps/performance/)
    - TFP tests
      - Using `tensorflow/tensorflow@sha256:4be8a8bf5e249fce61d8bedc5fd733445962c34bf6ad51a16f9009f125195ba9` as Docker image with arguments `-u root`
      - `pip3 install tfp-nightly==0.9.0.dev20191216`
      - `python3 test/integration/tfp/tests.py`
4. [Build and test static release binaries](https://github.com/stan-dev/stanc3/blob/master/Jenkinsfile#L158)
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
        - Stash `bin/*` for later use 
      - Build stanc.js
        - Build using [Dockerfile](https://github.com/stan-dev/stanc3/blob/master/docker/debian/Dockerfile) with arguments `-u root --entrypoint=\'\'`
        - `eval \$(opam env)`
        - `dune subst`
        - `dune build --profile release src/stancjs`
        - ```mkdir -p bin && mv `find _build -name stancjs.bc.js` bin/stanc.js```
        - ```mv `find _build -name index.html` bin/load_stanc.html```
        - Stash `bin/*` for later use 
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
        - Stash `bin/*` for later use 
      - Build & test static Windows binary ( WSL label )
        - `bat "bash -cl \"eval \$(opam env) make clean; dune subst; dune build -x windows; dune runtest --verbose\""`
        - `bat """bash -cl "rm -rf bin/*; mkdir -p bin; mv _build/default.windows/src/stanc/stanc.exe bin/windows-stanc" """`
        - `bat "bash -cl \"mv _build/default.windows/src/stan2tfp/stan2tfp.exe bin/windows-stan2tfp\""`
        - Stash `bin/*` for later use 
5. [Release tag and publish binaries](https://github.com/stan-dev/stanc3/blob/master/Jenkinsfile#L247)
    - Only when master branch, linux agent.
    - Unstash all the builds above ( windows-exe, linux-exe, mac-exe, js-exe )   
    - Will use ghr to create the release
    - `wget https://github.com/tcnksm/ghr/releases/download/v0.12.1/ghr_v0.12.1_linux_amd64.tar.gz`
    - `tar -zxvpf ghr_v0.12.1_linux_amd64.tar.gz`
    - `./ghr_v0.12.1_linux_amd64/ghr -recreate ${tagName()} bin/`
6. [Post action](https://github.com/stan-dev/stanc3/blob/master/Jenkinsfile#L264)
    - Notify status through email   