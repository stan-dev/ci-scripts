# Base image, use latest so we can install latest gcc from the ppa
FROM ubuntu:rolling

ENV TZ="America/New_York"

# Install OS depdencies
RUN apt-get update -y && apt-get install wget git curl xz-utils build-essential libmpc-dev jq gcc-multilib software-properties-common cmake make ninja-build sudo dos2unix python3 python3-pip python3-venv \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget  \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y

RUN ln -sf python3 /usr/bin/python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

ARG CUSTOM_GCC_TAG

# Install latest gcc, g++ from ubuntu toolchain ppa
# https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test
# https://gcc.gnu.org/releases.html
COPY gcc.sh /tmp/gcc.sh
RUN bash -e /tmp/gcc.sh

#ARG PUID=1000
#ARG PGID=1000

# Add Jenkins user and group
#RUN addgroup -gid ${PGID} jenkins
#RUN adduser --disabled-password --gecos '' --ingroup jenkins --uid ${PUID} jenkins

#RUN chown -R jenkins:jenkins /usr/local
#RUN chown -f -R jenkins:jenkins /etc || true

USER ubuntu
WORKDIR /home/ubuntu

ENV clangbuild=/home/ubuntu/llvm-project/build
ENV PATH=$clangbuild/bin:$PATH
ENV LD_LIBRARY_PATH=$clangbuild/lib

ARG CUSTOM_LLVM_TAG

# Download the source code, build & install libcxx
COPY llvm.sh /tmp/llvm.sh
RUN bash -e /tmp/llvm.sh

# Update LD_LIBRARY_PATH
ENV LLVM_PREFIX=/home/ubuntu/llvm
ENV LD_LIBRARY_PATH=$LLVM_PREFIX/lib
