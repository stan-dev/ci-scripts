# Base image
FROM debian:buster-slim

ARG STANC3_BRANCH=master
ENV STANC3_BRANCH_ENV=${STANC3_BRANCH}

ARG STANC3_ORG=stan-dev
ENV STANC3_ORG_ENV=${STANC3_ORG}

ARG PUID
ARG PGID

USER root

RUN addgroup -gid ${PGID} jenkins
RUN addgroup -gid 987 docker
RUN addgroup -gid 988 dockerroot
RUN adduser --disabled-password --gecos '' --ingroup jenkins --ingroup docker --ingroup dockerroot --uid ${PUID} jenkins
#RUN usermod -a -G sudo jenkins
#RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers

# Update repositories and install OS deps
RUN apt-get update -y && apt-get install opam curl bzip2 git tar curl ca-certificates openssl m4 bash -y

RUN update-ca-certificates -f

USER jenkins
WORKDIR /tmp

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

USER root
# Download needed QEMU binary and place in /usr/bin
RUN curl -L https://github.com/multiarch/qemu-user-static/releases/download/v6.0.0-2/x86_64_qemu-$(cat ./qarch)-static.tar.gz | tar -xzf - -C /usr/local/bin
RUN chown -R jenkins:sudo /usr/local
USER jenkins

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

## Base image
#FROM debian:buster-slim
#
#ARG STANC3_BRANCH=master
#ENV STANC3_BRANCH_ENV=${STANC3_BRANCH}
#
#ARG STANC3_ORG=stan-dev
#ENV STANC3_ORG_ENV=${STANC3_ORG}
#
#ARG PUID
#ARG PGID
#
## Set the opam root
#ENV OPAMROOT /usr/local/opam
#
#USER root
#
## Update repositories and install OS deps
#RUN apt-get update && apt-get install opam curl bzip2 git tar curl ca-certificates openssl m4 bash -y
#RUN update-ca-certificates -f
#
## 986 987 988
#RUN addgroup -gid ${PGID} jenkins
#RUN addgroup -gid 987 docker
#RUN addgroup -gid 988 dockerroot
#RUN adduser --disabled-password --gecos '' --ingroup jenkins --ingroup docker --ingroup dockerroot --uid ${PUID} jenkins
#
#RUN usermod -a -G sudo jenkins
#RUN echo '%sudo ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
#RUN chown -R jenkins:sudo /usr/local
#
#USER jenkins
#WORKDIR /tmp
#
## Identify architecture being built for and cache
#RUN echo $(dpkg --print-architecture) > ./arch
#
## Translate dpkg architecture naming to QEMU architecture
#RUN if [ $(cat ./arch) = "arm64" ]; then \
#      QEMU_ARCH="aarch64"; \
#    elif [ $(cat ./arch) = "ppc64el" ]; then \
#      QEMU_ARCH="ppc64le"; \
#    elif [ $(cat ./arch) = "armhf" ]; then \
#      QEMU_ARCH="arm"; \
#    elif [ $(cat ./arch) = "armel" ]; then \
#      QEMU_ARCH="arm"; \
#    else \
#      QEMU_ARCH=$(cat ./arch); \
#    fi && \
#    echo $QEMU_ARCH > ./qarch
#
## Download needed QEMU binary and place in /usr/bin
#RUN curl -L https://github.com/multiarch/qemu-user-static/releases/download/v6.0.0-2/x86_64_qemu-$(cat ./qarch)-static.tar.gz | tar -xzf - -C /usr/bin
#
#RUN opam init --disable-sandboxing -y
#RUN eval $(opam env)
#
## Native-code compilation not available on MIPS, fall back to bytecode
#RUN if [ $(cat ./arch) = "mips64el" ]; then \
#    opam switch create 4.12.0 --packages=ocaml-variants.4.12.0+options,ocaml-option-bytecode-only && opam switch 4.12.0; \
#  else \
#    opam switch create 4.12.0 && opam switch 4.12.0; \
#  fi
#
#RUN eval $(opam env) && opam repo add internet https://opam.ocaml.org
#
#RUN curl https://raw.githubusercontent.com/${STANC3_ORG_ENV}/stanc3/${STANC3_BRANCH_ENV}/scripts/install_build_deps.sh | bash
#
## Cleanup
#RUN rm ./arch && rm ./qarch
#
##mkdir build
##cd build
##cat <<EOF > Dockerfile
##FROM multiarch/qemu-user-static:x86_64-$DOCK_ARCH as qemu
##FROM stanorg/stanc3:multiarchfi@$SHA
##COPY --from=qemu /usr/bin/qemu-$DOCK_ARCH-static /usr/bin
##EOF
##docker build -t stanorg:stanc3-qemu:multiarchfi@$SHA .
##docker run stanorg:stanc3-qemu:multiarchfi@$SHA ...
#
## docker run stanorg/stanc3:multiarchfi@sha256:f5098ad99b4245da5f811e329af326bf241e46c67789e16906da7364b3fb9db1
#
## docker run stanorg/stanc3:multiarchfi@sha256:6dfa0808c4f522fdfa7278d3042810fd313571de56fed8431b12e935f9778682 /bin/bash -c 'echo "Hello!"'
#
## docker run -e PATH='/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin' stanorg/stanc3:multiarchfi@sha256:80d7f87d4b558d139ac8d6f7475009d6e2d0d51de6d4365e11ae7eb11d0cf724 /bin/bash -c 'ls -lhart && whoami $&& echo ${UID} && getent group jenkins'

# docker buildx build -t stanorg/stanc3:multiarchfi --platform linux/arm/v6,linux/arm/v7,linux/arm64,linux/ppc64le,linux/mips64le,linux/s390x --build-arg PUID=990 --progress=plain --build-arg PGID=986 --push .