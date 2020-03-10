## Daily Stan Performance

### History

- History can be found [here](https://jenkins.mc-stan.org/job/Daily%20Stan%20Performance/)

### Jenkinsfile

Link to Jenkins project: [CmdStan Performance Tests](https://jenkins.mc-stan.org/job/Daily%20Stan%20Performance/)
This is a visual job rather than scripted Jenkins pipeline, you can find it [here](https://jenkins.mc-stan.org/job/Daily%20Stan%20Performance/configure)  


Parameters:  
None  

Stages:  

1. Clean checkout
2. Copy `test/performance/performance.csv` from the old build
3. Run `make math-update`
4. Run `make math-revert`
5. Run tests `./runTests.py src/test/performance`
6. Run Rscript `RScript ../../src/test/performance/plot_performance.R `
7. Archive artifacts `test/performance/performance.csv,test/performance/performance.png`
8. Publish JUnit test result report for `test/**/*.xml`
9. Publish Performance test results report for `test/performance/*.xml`
10. Notify results through email.