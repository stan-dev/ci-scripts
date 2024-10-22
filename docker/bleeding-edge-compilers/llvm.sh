#!/bin/bash

echo "${CUSTOM_LLVM_TAG}"

if [ -z "$CUSTOM_LLVM_TAG" ]; then
  LATEST_RELEASE_VERSION=$(curl https://api.github.com/repos/llvm/llvm-project/tags | jq '.[]|select(.name | startswith("llvmorg-"))' | jq '.name' | grep -Eo '[0-9][0-9]\.[0-9]\.[0-9]+' | head -1 )
  echo "Pulling latest release ${LATEST_RELEASE_VERSION}"
else
  LATEST_RELEASE_VERSION="${CUSTOM_LLVM_TAG}"
  echo "Using custom release tag ${LATEST_RELEASE_VERSION}"
fi

echo "${LATEST_RELEASE_VERSION}"

git clone -b "llvmorg-${LATEST_RELEASE_VERSION}" --depth=1 https://github.com/llvm/llvm-project.git
cd llvm-project
mkdir build
cd build

cmake -DLLVM_ENABLE_PROJECTS=clang -DCMAKE_BUILD_TYPE=Release -G "Unix Makefiles" ../llvm
make clang -j8
clang --help
cmake -G Ninja -S ../runtimes -B build -DLLVM_ENABLE_RUNTIMES="libcxx;libcxxabi;libunwind;third-party;test-suite" -D CMAKE_CXX_COMPILER=clang++ -D CMAKE_C_COMPILER=clang
ninja -C build cxx cxxabi unwind
ninja -C build check-cxx check-cxxabi check-unwind
ninja -C build install-cxx install-cxxabi install-unwind
ldconfig /usr/local/lib

cd ../../