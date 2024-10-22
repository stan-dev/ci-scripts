# Base image, use latest so we can install latest gcc from the ppa
FROM ubuntu:rolling

USER root

ARG PUID
ARG PGID

ARG CUSTOM_GCC_TAG
ARG CUSTOM_LLVM_TAG

RUN echo "$CUSTOM_GCC_TAG"
RUN echo "$CUSTOM_LLVM_TAG"

ARG BUILD_GCC
ARG BUILD_LLVM

RUN echo "$BUILD_GCC"
RUN echo "$BUILD_LLVM"

ENV TZ="America/New_York"

# Install OS depdencies
RUN apt-get update -y && apt-get install wget git curl xz-utils build-essential libmpc-dev jq gcc-multilib software-properties-common cmake make ninja-build sudo dos2unix python3 python3-pip python3-venv \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget  \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y

COPY gcc.sh /tmp/gcc.sh
COPY llvm.sh /tmp/llvm.sh

RUN chmod +x /tmp/gcc.sh && chmod +x /tmp/llvm.sh

RUN ln -sf python3 /usr/bin/python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# Install latest gcc, g++ from ubuntu toolchain ppa
# https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test
# https://gcc.gnu.org/releases.html
RUN if [ -n "$BUILD_GCC" ]; then /tmp/gcc.sh; fi

# Add Jenkins user and group
RUN addgroup -gid ${PGID} jenkins
RUN adduser --disabled-password --gecos '' --ingroup jenkins --uid ${PUID} jenkins

RUN chown -R jenkins:jenkins /usr/local
RUN chown -f -R jenkins:jenkins /etc || true

USER jenkins
WORKDIR /home/jenkins

ENV clangbuild=/home/jenkins/llvm-project/build
ENV PATH=$clangbuild/bin:$PATH
ENV LD_LIBRARY_PATH=$clangbuild/lib:$LD_LIBRARY_PATH

# Download the source code, build & install libcxx
RUN if [ -n "$BUILD_LLVM" ]; then /tmp/llvm.sh; fi

# Update LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH="/usr/local/lib:${PATH}"

# Add latest clang,llvm to PATH
ENV PATH="/home/jenkins/llvm-clang-latest/bin:${PATH}"
