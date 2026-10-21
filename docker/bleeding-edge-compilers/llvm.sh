#!/bin/bash -e

[[ $CUSTOM_LLVM_TAG ]]

LATEST_RELEASE_VERSION="${CUSTOM_LLVM_TAG}"
echo "Using custom release tag ${LATEST_RELEASE_VERSION}"

git clone -b "llvmorg-${LATEST_RELEASE_VERSION}" --depth=1 https://github.com/llvm/llvm-project.git
prefix=$PWD/llvm
mkdir llvm-build
cd llvm-build

cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX=$prefix -G "Unix Makefiles" ../llvm-project/llvm
make clang -j8
clang --help
cmake -G Ninja -S ../llvm-project/runtimes -B build -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;third-party;test-suite" -D CMAKE_CXX_COMPILER=clang++ -D CMAKE_C_COMPILER=clang -DCMAKE_INSTALL_PREFIX=$prefix
ninja -C build cxx cxxabi unwind
ninja -C build check-cxx check-cxxabi check-unwind
ninja -C build install-cxx install-cxxabi install-unwind
rm -rf ../llvm-project
