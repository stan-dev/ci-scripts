#!/usr/bin/env groovy

def installDockerBuildX(){
    def latest = """LATEST=\$(wget -qO- "https://api.github.com/repos/docker/buildx/releases/latest" | jq -r .name)
              |wget https://github.com/docker/buildx/releases/download/\$LATEST/buildx-\$LATEST.linux-amd64
              |chmod a+x buildx-\$LATEST.linux-amd64
              |mkdir -p ~/.docker/cli-plugins
              |mv buildx-\$LATEST.linux-amd64 ~/.docker/cli-plugins/docker-buildx""".stripMargin()

    sh (returnStdout: true, script: "${latest}").trim()
}

pipeline {
    agent { label 'gg-linux' }
	environment {
		DOCKERHUB_CREDENTIALS=credentials('acdd7926-9ee7-4f51-863f-14ee5bca1f4c')
	}
    stages {

        stage("stanc3 multiarch") {
            when { changeset "docker/stanc3/multiarch/Dockerfile"}
           steps{
               script { installDockerBuildX() }
               sh """
                   docker run --rm --privileged multiarch/qemu-user-static --reset -p yes
                   docker buildx create --name stanc3_builder || true
                   docker buildx use stanc3_builder
                   docker buildx inspect --bootstrap
                   echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                   cd docker/stanc3/multiarch
                   docker buildx build -t stanorg/stanc3:multiarch --platform linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/mips64le,linux/s390x --push .
               """
               deleteDir()
           }
       }

        stage("stanc3 static") {
            when { changeset "docker/stanc3/static/Dockerfile"}
           steps{
               script { installDockerBuildX() }
               sh """
                   git clone https://github.com/stan-dev/stanc3.git
                   cd stanc3
                   echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                   pwd
                   docker build -t stanorg/stanc3:static -f ../docker/stanc3/static/Dockerfile .
                   docker push stanorg/stanc3:static
               """
               deleteDir()
           }
        }

        stage("stanc3 debian") {
           when { changeset "docker/stanc3/debian/Dockerfile"}
           steps{
               script { installDockerBuildX() }
               sh """
                   git clone https://github.com/stan-dev/stanc3.git
                   cd stanc3
                   echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                   pwd
                   docker build -t stanorg/stanc3:debian -f ../docker/stanc3/debian/Dockerfile .
                   docker push stanorg/stanc3:debian
               """
               deleteDir()
           }
       }

        stage("stanc3 debian-windows") {
            when { changeset "docker/stanc3/debian-windows/Dockerfile"}
            steps{
                script { installDockerBuildX() }
                sh """
                    git clone https://github.com/stan-dev/stanc3.git
                    cd stanc3
                    echo $DOCKERHUB_CREDENTIALS_PSW | docker login -u $DOCKERHUB_CREDENTIALS_USR --password-stdin
                    pwd
                    docker build -t stanorg/stanc3:debian-windows -f ../docker/stanc3/debian-windows/Dockerfile .
                    docker push stanorg/stanc3:debian-windows
                """
                deleteDir()
            }
        }

    }
}
