FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y wget git r-base r-cran-remotes r-cran-v8 libxml2-dev libssl-dev libcurl4-openssl-dev
ENV LANG=C.UTF-8
RUN Rscript -e 'remotes::install_github("r-lib/revdepcheck", update = "always")'

