# Pull the ubuntu:bionic base image
FROM ubuntu:bionic

# Install OS dependencies
RUN apt-get update -qq && apt-get install -y --no-install-recommends \
    curl ca-certificates \
    rsync git build-essential m4 unzip pkg-config libpcre3-dev \
    python3 python3-pip nodejs

# Install and initialize ocaml
COPY ./scripts/install_ocaml.sh ./
RUN printf "\n" | bash -x install_ocaml.sh "--disable-sandboxing -y"

# Install build dependencies
COPY ./scripts/install_build_deps.sh ./
RUN opam update; bash -x install_build_deps.sh

# Install dev dependencies
COPY ./scripts/install_dev_deps.sh ./
RUN opam update; bash -x install_dev_deps.sh

RUN opam update

# Install Javascript dev environment
COPY ./scripts/install_js_deps.sh ./
RUN opam update; bash -x install_js_deps.sh

# Specify our entrypoint
ENTRYPOINT [ "opam", "config", "exec", "--" ]
