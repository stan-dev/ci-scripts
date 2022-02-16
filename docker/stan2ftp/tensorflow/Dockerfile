FROM tensorflow/tensorflow

ARG PUID
ARG PGID

USER root

RUN addgroup -gid ${PGID} jenkins
RUN adduser --disabled-password --gecos '' --ingroup jenkins --uid ${PUID} jenkins

USER jenkins
WORKDIR /home/jenkins

RUN pip3 install tfp-nightly==0.11.0.dev20200516 --user