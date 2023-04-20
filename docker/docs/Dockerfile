# Base image for R 4.2.0
FROM r-base:4.2.0

# Install OS Dependencies
RUN apt-get update -y && \
    apt-get install curl libssl-dev libcurl4-openssl-dev libxml2-dev libfontconfig1-dev git texlive-full python3 pandoc -y

# Install R depdendencies
RUN Rscript -e 'install.packages(c("dplyr", "ggplot2", "kableExtra", "bookdown", "pandoc-citeproc"), repos="https://cloud.r-project.org")'