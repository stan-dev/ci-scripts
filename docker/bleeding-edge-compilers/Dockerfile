# Base image, use lunar so we can install latest gcc from the ppa
FROM ubuntu:lunar

# Install OS depdencies
RUN apt-get update -y && apt-get install wget git curl xz-utils build-essential libmpc-dev jq gcc-multilib software-properties-common cmake ninja-build -y

# Set our working dir to /tmp
WORKDIR /tmp

# Download and install the latest version of LLVM and CLANG
RUN LATEST_RELEASE_ARCHIVE=$(curl -s https://api.github.com/repos/llvm/llvm-project/releases/latest | grep browser_download_url | cut -d\" -f4 | egrep 'clang%2Bllvm-(.*?)-x86_64-linux-gnu-ubuntu-22.04.tar.xz') && \
    wget -O llvm-clang-latest.tar.xz $LATEST_RELEASE_ARCHIVE && \
    tar -xvf llvm-clang-latest.tar.xz && mv "clang+llvm"* llvm-clang-latest && \
    LATEST_RELEASE=$(echo $LATEST_RELEASE_ARCHIVE | grep -Eo '[0-9][0-9]\.[0-9]\.[0-9]+' | head -1) && \
    major=$(echo $LATEST_RELEASE | cut -d. -f1) && \
    echo "${major}" > clang-major-version.txt && \
    rm -rf llvm-clang-latest.tar.xz

# Add latest clang,llvm to PATH
ENV PATH="${PATH}:/tmp/llvm-clang-latest/bin"

# Download the source code, build & install libcxx
RUN git clone https://github.com/llvm/llvm-project.git && \
    cd llvm-project && \
    mkdir build && cd build && \
    cmake -G Ninja -S ../runtimes -B build -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind" -D CMAKE_CXX_COMPILER=clang++ -D CMAKE_C_COMPILER=clang && \
    ninja -C build cxx cxxabi unwind && \
    ninja -C build check-cxx check-cxxabi check-unwind && \
    ninja -C build install-cxx install-cxxabi install-unwind

# Install latest gcc, g++ from ubuntu toolchain ppa
# https://launchpad.net/~ubuntu-toolchain-r/+archive/ubuntu/test
# https://gcc.gnu.org/releases.html
RUN LATEST_RELEASE=$(curl https://api.github.com/repos/gcc-mirror/gcc/tags | jq '.[]|select(.name | startswith("releases/gcc-"))' | jq '.name' | head -1 | grep -Eo '[0-9][0-9]\.[0-9]\.[0-9]+') && \
    major=$(echo $LATEST_RELEASE | cut -d. -f1) && \
    add-apt-repository ppa:ubuntu-toolchain-r/test -y && apt-get update -y && apt-get install gcc-${major} g++-${major} -y && \
    echo "${major}" > gcc-major-version.txt && \
    # Set gcc and g++ to latest version
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-"${major}" "${major}" && \
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-"${major}" "${major}"