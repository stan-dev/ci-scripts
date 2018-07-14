FROM ubuntu

ENV TZ 'America/New_York'
RUN echo $TZ > /etc/timezone && \
  apt-get update && apt-get install -y tzdata && \
  rm /etc/localtime && \
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
  dpkg-reconfigure -f noninteractive tzdata

# Build system pre-reqs
RUN apt-get update && apt-get install -y \
  openjdk-8-jre \
  make \
  latexmk \
  texlive-latex-recommended \
  texlive-latex-extra \
  r-base \
  pandoc \
  libxml2-dev \
  libcurl4-openssl-dev \
  libssl-dev \
  pandoc-citeproc \
  openmpi-bin \
  doxygen \
  opencl-headers \
  libclc-amdgcn mesa-opencl-icd clinfo \
  clang-format-5.0 \
  clang-3.9 \
  mpich \
  git

RUN echo "r <- getOption('repos'); r['CRAN'] <- 'http://cran.us.r-project.org'; options(repos = r);" > ~/.Rprofile
RUN Rscript -e "Sys.setenv(MAKEFLAGS = '-j32'); install.packages(c('rstan', 'tidyverse', 'bookdown'))"

RUN update-alternatives --install /usr/bin/clang-format clang-format /usr/bin/clang-format-5.0 100
RUN update-alternatives --install /usr/bin/clang clang /usr/bin/clang-3.9 100

# Begin actual Jenkins agent setup

ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000

ENV HOME /home/${user}
RUN groupadd -g ${gid} ${group}
RUN useradd -c "Jenkins user" -d $HOME -u ${uid} -g ${gid} -m ${user}
LABEL Description="This is a base image, which provides the Jenkins agent executable (agent.jar)" Vendor="Jenkins project" Version="3.20"

ARG AGENT_WORKDIR=/home/${user}/agent

RUN curl --create-dirs -sSLo /usr/share/jenkins/agent.jar http://d1m1s1b1.stat.columbia.edu:8080/jnlpJars/agent.jar \
  && chmod 755 /usr/share/jenkins \
  && chmod 644 /usr/share/jenkins/agent.jar

USER ${user}
ENV AGENT_WORKDIR=${AGENT_WORKDIR}
RUN mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR}

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}

# This is sort of a hack; it's epyc specific. I think we should parameterize it
# later.
CMD java -jar /usr/share/jenkins/agent.jar -jnlpUrl http://d1m1s1b1.stat.columbia.edu:8080/computer/epyc/slave-agent.jnlp -secret 09565877413dd13f0dfe028837f74fd7bbb2cfa7233e2311321d434cd3c41f7a -workDir "/home/jenkins/jenkins-agent"
