#!/usr/bin/env groovy
@Library('StanUtils')
import org.stan.Utils

def utils = new org.stan.Utils()

def cleanCheckout(){
    deleteDir()
    sh """
        git clone https://github.com/$ciscripts_org/ci-scripts.git .
        git checkout $ciscripts_branch
    """
}

// Base tags for master branch
def multiArchTag = ""
def staticTag = ""
def debianTag = ""
def debianWindowsTag = ""

pipeline {
    agent none
	environment {
		GIT_URL="https://github.com/stan-dev/ci-scripts.git"
		BRANCH_NAME="${params.ciscripts_branch}"
	}
	options {
	    skipDefaultCheckout()
	}
    parameters {
        string(defaultValue: 'stan-dev', name: 'stanc3_org', description: "Stanc3 organization to pull scripts. You can also pass this to update main tags in DockerHub")
        string(defaultValue: 'master', name: 'stanc3_branch', description: "Stanc3 branch to pull scripts")
        string(defaultValue: 'stan-dev', name: 'ciscripts_org', description: "Ci-scripts organization to pull Dockerfiles. You can also pass this to update main tags in DockerHub")
        string(defaultValue: 'master', name: 'ciscripts_branch', description: "Ci-scripts branch to pull Dockerfiles")
        string(defaultValue: "", name: 'docs_docker_image_tag', description: "Tag to use for the docs docker image.")

        booleanParam(defaultValue: true, description: 'Build multi-arch docker image', name: 'buildMultiarch')
        booleanParam(defaultValue: true, description: 'Build static docker image', name: 'buildStatic')
        booleanParam(defaultValue: true, description: 'Build debian docker image', name: 'buildDebian')
        booleanParam(defaultValue: true, description: 'Build debian docker image', name: 'buildDebianWindows')

        booleanParam(defaultValue: false, description: 'Whenever to run the job that updates the Docker Hub main tags with the ones from a WIP branch. Make sure to uncheck Docker images builds as they\'re not needed if we ran the build before. Might need rebuild if it\'s a multi-arch image', name: 'replaceMainTags')
    }
    stages {

        stage('Set tags') {
            agent { label 'linux' }
            steps {
                script {
                    println "Setting tags for stanc3 branch ${params.stanc3_branch} or ci-scripts branch ${params.ciscripts_branch}"

                    def stanc3 = params.stanc3_branch.toString()
                    def ciscripts = params.ciscripts_branch.toString()

                    if (stanc3 != "master"){
                        multiArchTag = "multiarch-" + stanc3
                        staticTag = "static-" + stanc3
                        debianTag = "debian-" + stanc3
                        debianWindowsTag = "debian-windows-" + params.stanc3_branch
                        println "Tags set from stanc3 ${params.stanc3_branch}"
                    }
                    else if (ciscripts != "master"){
                        multiArchTag = "multiarch-" + ciscripts
                        staticTag = "static-" + ciscripts
                        debianTag = "debian-" + ciscripts
                        debianWindowsTag = "debian-windows-" + ciscripts
                        println "Tags set from ci-scripts ${params.ciscripts_branch}"
                    }
                    else{
                        multiArchTag = "multiarch"
                        staticTag = "static"
                        debianTag = "debian"
                        debianWindowsTag = "debian-windows"
                        println "Tags set from master"
                    }
                }
            }
        }

        stage("Build Docker Images") {
            parallel {

                stage("stanc3 multiarch") {
                    agent { label 'linux' }
                     when {
                         beforeAgent true
                         allOf {
                             expression { params.buildMultiarch }
                         }
                     }
                     steps{
                         script {
                             cleanCheckout()
                         }
                         sh """
                             docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
                             docker buildx create --name stanc3_builder || true
                             docker buildx use stanc3_builder
                             docker buildx inspect --bootstrap
                             echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                             cd docker/stanc3/multiarch
                             docker buildx build -t stanorg/stanc3:$multiArchTag --build-arg STANC3_BRANCH=${params.stanc3_branch} --build-arg STANC3_ORG=${params.stanc3_org} --platform linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/mips64le,linux/s390x --push .
                         """
                    }
                }

                stage("stanc3 static") {
                    agent { label 'linux' }
                    when {
                        beforeAgent true
                        allOf {
                            expression { params.buildStatic }
                        }
                    }
                    steps{
                        script {
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
                    agent { label 'linux' }
                    when {
                        beforeAgent true
                        allOf {
                            expression { params.buildDebian }
                        }
                    }
                    steps{
                        script {
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
                    agent { label 'linux' }
                    when {
                        beforeAgent true
                        allOf {
                            expression { params.buildDebian }
                        }
                    }
                    steps{
                        script {
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

            }
        }

        stage("update DockerHub main tags") {
            agent { label 'linux' }
            when {
                beforeAgent true
                expression { params.replaceMainTags }
            }
            steps{
                sh """
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin

                    docker tag stanorg/stanc3:multiarch stanorg/stanc3:$multiArchTag
                    docker push stanorg/stanc3:multiarch

                    docker tag stanorg/stanc3:static stanorg/stanc3:$staticTag
                    docker push stanorg/stanc3:static

                    docker tag stanorg/stanc3:debian stanorg/stanc3:$debianTag
                    docker push stanorg/stanc3:debian

                    docker tag stanorg/stanc3:debian-windows stanorg/stanc3:$debianWindowsTag
                    docker push stanorg/stanc3:debian-windows
                """
            }
        }

        stage("Build docker image") {
            agent { label 'linux && triqs' }
            environment { DOCKER_TOKEN = credentials('aada4f7b-baa9-49cf-ac97-5490620fce8a') }
            when {
                beforeAgent true
                expression { 
                    params.docs_docker_image_tag != ""
                }
            }
            steps{
                script {
                    cleanCheckout()
                }
                sh """
                    docker login --username stanorg --password "${DOCKER_TOKEN}"
                    docker build -t stanorg/ci:$docs_docker_image_tag -f docker/docs/Dockerfile --build-arg PUID=\$(id -u) --build-arg PGID=\$(id -g) .
                    docker push stanorg/ci:$docs_docker_image_tag
                """
            }
        }

    }
}
