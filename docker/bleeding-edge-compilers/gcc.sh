#!/bin/bash

if [ -z "$CUSTOM_GCC_TAG" ]; then
  LATEST_RELEASE=$(curl https://api.github.com/repos/gcc-mirror/gcc/tags | jq '.[]|select(.name | startswith("releases/gcc-"))' | jq '.name' | head -1 | grep -Eo '[0-9][0-9]\.[0-9]\.[0-9]+')
else
  LATEST_RELEASE="${CUSTOM_GCC_TAG}"
fi

echo "${LATEST_RELEASE}"

major=$(echo $LATEST_RELEASE | cut -d. -f1)

add-apt-repository ppa:ubuntu-toolchain-r/test -y
apt-get update -y
apt-get install gcc-${major} g++-${major} -y

echo "${major}" > gcc-major-version.txt
cat gcc-major-version.txt

update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-"${major}" "${major}"
update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-"${major}" "${major}"