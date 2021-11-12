#!/usr/bin/env groovy
@Library('StanUtils')
import org.stan.Utils

def installDockerBuildX(){
    def latest = """LATEST=\$(wget -qO- "https://api.github.com/repos/docker/buildx/releases/latest" | jq -r .name)
              |wget https://github.com/docker/buildx/releases/download/\$LATEST/buildx-\$LATEST.linux-amd64
              |chmod a+x buildx-\$LATEST.linux-amd64
              |mkdir -p ~/.docker/cli-plugins
              |mv buildx-\$LATEST.linux-amd64 ~/.docker/cli-plugins/docker-buildx""".stripMargin()

    sh (returnStdout: true, script: "${latest}").trim()
}

def cleanCheckout(){
    deleteDir()
    checkout([$class: 'GitSCM',
        branches: [[name: "*/$ciscripts_branch"]],
        doGenerateSubmoduleConfigurations: false,
        extensions: [],
        submoduleCfg: [],
        userRemoteConfigs: [[url: "https://github.com/$ciscripts_org/ci-scripts.git", credentialsId: 'a630aebc-6861-4e69-b497-fd7f496ec46b']]])
}

// Base tags for master branch
def multiArchTag = "multiarch"
def staticTag = "static"
def debianTag = "debian"
def debianWindowsTag = "debian-windows"

// Set tags if we're passing different values than master
def setTags(){
    if (params.stanc3_branch != "master"){
        multiArchTag = "multiarch-" + params.stanc3_branch
        staticTag = "static-" + params.stanc3_branch
        debianTag = "debian-" + params.stanc3_branch
        debianWindowsTag = "debian-windows-" + params.stanc3_branch
    }
    else if (params.ciscripts_branch != "master"){
        multiArchTag = "multiarch-" + params.ciscripts_branch
        staticTag = "static-" + params.ciscripts_branch
        debianTag = "debian-" + params.ciscripts_branch
        debianWindowsTag = "debian-windows-" + params.ciscripts_branch
    }
}

def skipMultiArch = false
def skipStatic = false
def skipDebian = false
def skipDebianWindows = false

pipeline {
    agent { label 'gg-linux' }
	environment {
		DOCKERHUB_CREDENTIALS=credentials('acdd7926-9ee7-4f51-863f-14ee5bca1f4c')
	}
	options {
	    skipDefaultCheckout()
	}
    parameters {
        string(defaultValue: 'stan-dev', name: 'stanc3_org', description: "Stanc3 organization to pull scripts. You can also pass this to update main tags in DockerHub")
        string(defaultValue: 'master', name: 'stanc3_branch', description: "Stanc3 branch to pull scripts")
        string(defaultValue: 'stan-dev', name: 'ciscripts_org', description: "Ci-scripts organization to pull Dockerfiles. You can also pass this to update main tags in DockerHub")
        string(defaultValue: 'master', name: 'ciscripts_branch', description: "Ci-scripts branch to pull Dockerfiles")

        booleanParam(defaultValue: true, description: 'Build multi-arch docker image', name: 'buildMultiarch')
        booleanParam(defaultValue: true, description: 'Build static docker image', name: 'buildStatic')
        booleanParam(defaultValue: true, description: 'Build debian docker image', name: 'buildDebian')
        booleanParam(defaultValue: true, description: 'Build debian docker image', name: 'buildDebianWindows')

        booleanParam(defaultValue: false, description: 'Whenever to run the job that updates the Docker Hub main tags with the ones from a WIP branch. Make sure to uncheck Docker images builds as they\'re not needed if we ran the build before. Might need rebuild if it\'s a multi-arch image', name: 'replaceMainTags')

    }
    stages {

        stage('Verify changes') {
            agent { label 'linux' }
            steps {
                script {
                    cleanCheckout()

                    skipMultiArch = utils.verifyChanges(['docker/stanc3/multiarch/Dockerfile'].join(" "))
                    skipStatic = utils.verifyChanges(['docker/stanc3/static/Dockerfile'].join(" "))
                    skipDebian = utils.verifyChanges(['docker/stanc3/debian/Dockerfile'].join(" "))
                    skipDebianWindows = utils.verifyChanges(['docker/stanc3/debian-windows/Dockerfile'].join(" "))
                }
            }
        }

        stage("stanc3 multiarch") {
            when {
                beforeAgent true
                allOf {
                    expression { !skipMultiArch }
                    expression { params.buildMultiarch }
                }
            }
            steps{
                script {
                    setTags()
                    installDockerBuildX()
                    cleanCheckout()
                }
                sh """
                    docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
                    docker buildx create --name stanc3_builder || true
                    docker buildx use stanc3_builder
                    docker buildx inspect --bootstrap
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    cd docker/stanc3/multiarch
                    docker buildx build -t stanorg/stanc3:$multiArchTag --build-arg STANC3_BRANCH=$stanc3_branch --platform linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/mips64le,linux/s390x --push .
                """
           }
       }

        stage("stanc3 static") {
            when {
                beforeAgent true
                allOf {
                    expression { !skipStatic }
                    expression { params.buildStatic }
                }
            }
           steps{
               script {
                   installDockerBuildX()
                   cleanCheckout()
               }
               sh """
                   git clone https://github.com/$stanc3_org/stanc3.git
                   cd stanc3
                   git checkout $stanc3_branch
                   echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                   docker build -t stanorg/stanc3:$staticTag -f ../docker/stanc3/static/Dockerfile .
                   docker push stanorg/stanc3:$staticTag
               """
           }
        }

        stage("stanc3 debian") {
            when {
                beforeAgent true
                allOf {
                    expression { !skipDebian }
                    expression { params.buildDebian }
                }
            }
            steps{
                script {
                    installDockerBuildX()
                    cleanCheckout()
                }
                sh """
                    git clone https://github.com/$stanc3_org/stanc3.git
                    cd stanc3
                    git checkout $stanc3_branch
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker build -t stanorg/stanc3:$debianTag -f ../docker/stanc3/debian/Dockerfile .
                    docker push stanorg/stanc3:$debianTag
                """
           }
       }

        stage("stanc3 debian-windows") {
            beforeAgent true
            when {
                allOf {
                    expression { !skipDebianWindows }
                    expression { params.buildDebian }
                }
            }
            steps{
               script {
                   installDockerBuildX()
                   cleanCheckout()
               }
               sh """
                    git clone https://github.com/$stanc3_org/stanc3.git
                    cd stanc3
                    git checkout $stanc3_branch
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    docker build -t stanorg/stanc3:$debianWindowsTag -f ../docker/stanc3/debian-windows/Dockerfile .
                    docker push stanorg/stanc3:$debianWindowsTag
               """
            }
        }

        stage("update DockerHub main tags") {
            when {
                beforeAgent true
                expression { params.replaceMainTags }
            }
            steps{
                script {
                    setTags()
                    installDockerBuildX()
                }
                sh """
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin

                    echo "Pulling $multiArchTag tag and replacing multiarch"
                    docker pull --platform linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/mips64le,linux/s390x stanorg/stanc3:$multiArchTag
                    docker tag stanorg/stanc3:multiarch stanorg/stanc3:$multiArchTag
                    docker push stanorg/stanc3:multiarch

                    echo "Pulling $staticTag tag and replacing static"
                    docker pull stanorg/stanc3:$staticTag
                    docker tag stanorg/stanc3:static stanorg/stanc3:$staticTag
                    docker push stanorg/stanc3:static

                    echo "Pulling $debianTag tag and replacing debian"
                    docker pull stanorg/stanc3:$debianTag
                    docker tag stanorg/stanc3:debian stanorg/stanc3:$debianTag
                    docker push stanorg/stanc3:debian

                    echo "Pulling $debianWindowsTag tag and replacing debian-windows"
                    docker pull stanorg/stanc3:$debianWindowsTag
                    docker tag stanorg/stanc3:debian-windows stanorg/stanc3:$debianWindowsTag
                    docker push stanorg/stanc3:debian-windows
                """
            }
        }

    }
}
