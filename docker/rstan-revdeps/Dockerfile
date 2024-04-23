FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y wget git r-base r-cran-remotes
ENV LANG=C.UTF-8
RUN Rscript -e 'remotes::install_github("r-lib/revdepcheck", update = "always")'
WORKDIR /build/revdeps
