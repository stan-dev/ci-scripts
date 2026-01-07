#!/bin/bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "ERROR: Please specify a version."
    exit 2
fi

VERSION=$1 #should be in MAJOR.MINOR.PATCH form
X86URL="https://github.com/stan-dev/cmdstan/releases/download/v${VERSION}/cmdstan-${VERSION}.tar.gz"
X64TARBALL="cmdstan-${VERSION}.tar.gz"
ARCHS=("arm64" "armel" "armhf" "ppc64el" "s390x")

rm -Rf build
mkdir -p build
cd build

wget -q --show-progress ${X86URL}
for ARCH_NAME in ${ARCHS[@]}
do
    wget -q --show-progress "https://github.com/stan-dev/stanc3/releases/download/v${VERSION}/linux-${ARCH_NAME}-stanc"
done


tar -xzf ${X64TARBALL}
rm cmdstan-${VERSION}/bin/*-stanc


for ARCH_NAME in ${ARCHS[@]}
do
    mv "linux-${ARCH_NAME}-stanc" "cmdstan-${VERSION}/bin/linux-stanc"
    tar -czvf "cmdstan-${VERSION}-linux-${ARCH_NAME}.tar.gz" "cmdstan-${VERSION}"
    rm "cmdstan-${VERSION}/bin/linux-stanc"
done
