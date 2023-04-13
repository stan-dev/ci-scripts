#Use Official Docker Images for OCAML/OPAM
#https://github.com/ocaml/infrastructure/wiki/Containers
FROM ocaml/opam:alpine-ocaml-4.12

#Switch to root user so we can install apk packages
USER root

ARG PUID
ARG PGID

RUN addgroup -g ${PGID} jenkins && \
    adduser -D -u ${PUID} -G jenkins jenkins

#Set our distro_style
LABEL distro_style="apk"

#Install os dependencies
RUN apk update && apk --no-cache add build-base file bzip2 git tar curl ca-certificates openssl m4 bash docker jq git-subtree

# Add a recent version of the Skopeo package, which is used for looking up the correct multiarch docker image
# http://dl-cdn.alpinelinux.org/alpine/v3.14/community/aarch64/containers-common-0.38.11-r0.apk
RUN curl https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/x86_64/containers-common-0.44.3-r0.apk -o cont.apk && \
    curl https://dl-cdn.alpinelinux.org/alpine/latest-stable/community/x86_64/skopeo-1.5.2-r0.apk -o skopeo.apk && \
    apk add cont.apk && \
    apk add skopeo.apk

#Switch back to the normal user
USER jenkins

#Init opam, create and switch to 4.12.0, update shell environment
RUN opam init --disable-sandboxing -y
RUN opam switch create 4.12.0
RUN opam switch 4.12.0
RUN eval $(opam env)

RUN opam repo add internet https://opam.ocaml.org

COPY ./scripts/install_build_deps.sh ./
RUN opam update; bash -x install_build_deps.sh

RUN opam install odoc -y

#Specify our entrypoint
ENTRYPOINT [ "opam", "config", "exec", "--" ]

# Build with:
# cd stanc3
# docker build -t stanorg/stanc3:staticfi --build-arg PUID=990 --progress=plain --build-arg PGID=986 -f ../ci-scripts/docker/stanc3/static/Dockerfile .