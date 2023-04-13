# Base image
FROM debian:buster-slim

ARG STANC3_BRANCH=master
ENV STANC3_BRANCH_ENV=${STANC3_BRANCH}

ARG STANC3_ORG=stan-dev
ENV STANC3_ORG_ENV=${STANC3_ORG}

# Update repositories and install OS deps
RUN apt-get update
RUN apt-get install build-essential file opam curl bzip2 git tar curl ca-certificates openssl m4 bash -y

RUN update-ca-certificates -f

# Identify architecture being built for and cache
RUN echo $(dpkg --print-architecture) > ./arch

# Translate dpkg architecture naming to QEMU architecture
RUN if [ $(cat ./arch) = "arm64" ]; then \
      QEMU_ARCH="aarch64"; \
    elif [ $(cat ./arch) = "ppc64el" ]; then \
      QEMU_ARCH="ppc64le"; \
    elif [ $(cat ./arch) = "armhf" ]; then \
      QEMU_ARCH="arm"; \
    elif [ $(cat ./arch) = "armel" ]; then \
      QEMU_ARCH="arm"; \
    else \
      QEMU_ARCH=$(cat ./arch); \
    fi && \
    echo $QEMU_ARCH > ./qarch

# Download needed QEMU binary and place in /usr/bin
RUN curl -L https://github.com/multiarch/qemu-user-static/releases/download/v6.0.0-2/x86_64_qemu-$(cat ./qarch)-static.tar.gz | tar -xzf - -C /usr/bin

RUN opam init --disable-sandboxing -y
RUN eval $(opam env)

# Native-code compilation not available on MIPS, fall back to bytecode
RUN if [ $(cat ./arch) = "mips64el" ]; then \
    opam switch create 4.12.0 --packages=ocaml-variants.4.12.0+options,ocaml-option-bytecode-only && opam switch 4.12.0; \
  else \
    opam switch create 4.12.0 && opam switch 4.12.0; \
  fi

RUN eval $(opam env) && opam repo add internet https://opam.ocaml.org

RUN curl https://raw.githubusercontent.com/${STANC3_ORG_ENV}/stanc3/${STANC3_BRANCH_ENV}/scripts/install_build_deps.sh | bash

# Cleanup
RUN rm ./arch && rm ./qarch