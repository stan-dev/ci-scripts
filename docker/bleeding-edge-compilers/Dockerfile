# Base image, use lunar so we can install latest gcc from the ppa
FROM ubuntu:lunar

USER root

ARG PUID
ARG PGID

ENV TZ="America/New_York"

# Install OS depdencies
RUN apt-get update -y && apt-get install wget git curl xz-utils build-essential libmpc-dev jq gcc-multilib software-properties-common cmake make ninja-build sudo dos2unix python3 python3-pip \
    libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget  \
    libncursesw5-dev xz-utils tk-dev libxml2-dev libxmlsec1-dev libffi-dev liblzma-dev -y

RUN ln -sf python3 /usr/bin/python
RUN update-alternatives --install /usr/bin/python python /usr/bin/python3 10

# Install latest gcc, g++ from ubuntu toolchain ppa
# https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test
# https://gcc.gnu.org/releases.html
RUN LATEST_RELEASE=$(curl https://api.github.com/repos/gcc-mirror/gcc/tags | jq '.[]|select(.name | startswith("releases/gcc-"))' | jq '.name' | head -1 | grep -Eo '[0-9][0-9]\.[0-9]\.[0-9]+') && \
    major=$(echo $LATEST_RELEASE | cut -d. -f1) && \
    add-apt-repository ppa:ubuntu-toolchain-r/test -y && apt-get update -y && apt-get install gcc-${major} g++-${major} -y && \
    echo "${major}" > gcc-major-version.txt && cat gcc-major-version.txt && \
    # Set gcc and g++ to latest version
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-"${major}" "${major}" && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-"${major}" "${major}"

# Add Jenkins user and group
RUN addgroup -gid ${PGID} jenkins
RUN adduser --disabled-password --gecos '' --ingroup jenkins --uid ${PUID} jenkins

RUN chown -R jenkins:jenkins /usr/local
RUN chown -f -R jenkins:jenkins /etc || true

USER jenkins
WORKDIR /home/jenkins

# Download the source code, build & install libcxx
RUN git clone --depth=1 https://github.com/llvm/llvm-project.git && \
    cd llvm-project && \
    mkdir build && cd build && \
    cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles" ../llvm && \
    make clang && \
    make check-clang && \
    clang --help && \
    cd .. && rm -rf build && mkdir build && cd build && \
    cmake -G Ninja -S ../runtimes -B build -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;third-party;test-suite" -D CMAKE_CXX_COMPILER=clang++ -D CMAKE_C_COMPILER=clang && \
    ninja -C build cxx cxxabi unwind && \
    ninja -C build check-cxx check-cxxabi check-unwind && \
    ninja -C build install-cxx install-cxxabi install-unwind && \
    ldconfig /usr/local/lib && \
    cd ../../ && rm -rf llvm-project

# Update LD_LIBRARY_PATH
ENV LD_LIBRARY_PATH="/usr/local/lib:${PATH}"

# Add latest clang,llvm to PATH
ENV PATH="/home/jenkins/llvm-clang-latest/bin:${PATH}"
