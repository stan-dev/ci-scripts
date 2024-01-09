#!/bin/bash

# Script used to install cmdstan on a GColab Machine and create a .tgz archive with the installation

# Arguments:
# $1: cmdstan version in the form of 2.29.0 (major.minor.patch)

# On a fresh colab instance simply run:
# !curl https://raw.githubusercontent.com/stan-dev/ci-scripts/master/release-scripts/build-conda-tgz.sh | bash -s -- 2.29.0
# You can follow all the progress in the console, should take around 10 minutes
# At the end the console will print a URL where you can download the .tgz archive

# Install php
apt install php

VERSION="$1"
INSTALLATION_HOME="/root"

echo "Creating v$VERSION conda .tgz archive !"

# Install cmdstanpy
pip install --upgrade cmdstanpy

# Install cmdstan
python -c "from cmdstanpy import install_cmdstan; install_cmdstan(cores=2, progress=True, version=\"$VERSION\")"

# Create tgz archive
cd $INSTALLATION_HOME/.cmdstan; tar -cf - cmdstan-$VERSION | gzip > $INSTALLATION_HOME/cmdstan-$VERSION.tgz
tar -tzf $INSTALLATION_HOME/cmdstan-$VERSION.tgz | head

FILE="/root/cmdstan-$VERSION.tgz"
URL="https://file.io"
DEFAULT_EXPIRE="1d"

RESPONSE=$(curl -# -F "file=@${FILE}" "${URL}/?expires=${DEFAULT_EXPIRE}")

RETURN=$(echo "$RESPONSE" | php -r 'echo json_decode(fgets(STDIN))->success;')

if [ "1" != "$RETURN" ]; then
    echo "An error occured!\nResponse: ${RESPONSE}"
    exit 1
fi

KEY=$(echo "$RESPONSE" | php -r 'echo json_decode(fgets(STDIN))->key;')
EXPIRY=$(echo "${RESPONSE}" | php -r 'echo json_decode(fgets(STDIN))->link;')

echo "${URL}/${KEY}"  # to terminal