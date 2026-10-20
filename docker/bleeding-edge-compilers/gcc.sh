#!/bin/bash -e

[[ $CUSTOM_GCC_TAG ]]

LATEST_RELEASE="${CUSTOM_GCC_TAG}"
echo "Using custom release tag ${LATEST_RELEASE}"

major=$(echo $LATEST_RELEASE | cut -d. -f1)

add-apt-repository ppa:ubuntu-toolchain-r/test -y
apt-get update -y
apt-get install gcc-${major} g++-${major} -y

echo "${major}" > gcc-major-version.txt
cat gcc-major-version.txt

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-"${major}" "${major}"
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-"${major}" "${major}"
