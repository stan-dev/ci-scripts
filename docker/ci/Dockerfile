# Base image
FROM docker.io/nvidia/cuda:11.2.2-devel-ubuntu20.04

# TZ Data available at runtime
# Clang version
# OpenMPI
ENV TZ="America/New_York" \
    CLANG_VERSION="7" LLD_VERSION="7"

# Install os dependencies and pip3
RUN export DEBIAN_FRONTEND=noninteractive && \
    apt-get install -y --no-install-recommends ca-certificates && update-ca-certificates && apt-get update -y && \
    apt-get install -y \
      nano alien bash dpkg git make curl wget cmake autoconf vim automake python3 python3-pip \
      parallel \
      opencl-headers clinfo \
      binutils clang-format clang-${CLANG_VERSION} clang++-${CLANG_VERSION} gcc lld-${LLD_VERSION} lld \
      libxml2-dev linux-headers-generic libopenmpi-dev libxslt-dev mpi mpich && \
    rm -rf /var/lib/apt/lists/* && \
    ln -sf python3 /usr/bin/python && \
    # Setup pip and requirements \
    pip3 install --no-cache --upgrade pip setuptools && \
    hash -r && \
    pip3 install --no-cache cpplint && \
    \
    ln -sf /usr/bin/clang /usr/bin/cc && \
    ln -sf /usr/bin/clang++ /usr/bin/c++ && \
    \
    update-alternatives --install /usr/bin/cc cc /usr/bin/clang 10 && \
    update-alternatives --install /usr/bin/c++ c++ /usr/bin/clang++ 10 && \
    update-alternatives --install /usr/bin/ld ld /usr/bin/lld 10 && \
    # Use python3 instead of python(2) \
    update-alternatives --install /usr/bin/python python /usr/bin/python3 10 && \
    \
    update-alternatives --auto cc && \
    update-alternatives --auto c++ && \
    update-alternatives --auto ld

WORKDIR /tmp

ENV OPENMPI_VERSION="4.1" OPENMPI_MINOR_VERSION="2"
# Install doxygen
RUN wget https://github.com/doxygen/doxygen/releases/download/Release_1_9_7/doxygen-1.9.7.linux.bin.tar.gz && \
    tar -xzvf doxygen-1.9.7.linux.bin.tar.gz && \
    mv doxygen-1.9.7/bin/doxygen /bin/ && \
    chmod +x /bin/doxygen && \
    rm -rf doxygen-* && \
    ## OpenMPI \
    wget https://download.open-mpi.org/release/open-mpi/v${OPENMPI_VERSION}/openmpi-${OPENMPI_VERSION}.${OPENMPI_MINOR_VERSION}.tar.gz && \
    tar xzvf openmpi-${OPENMPI_VERSION}.${OPENMPI_MINOR_VERSION}.tar.gz && \
    cd openmpi-${OPENMPI_VERSION}.${OPENMPI_MINOR_VERSION} && \
    ## Configure and install \
    ./configure CFLAGS=-O3 CXXFLAGS=-O3 --sysconfdir=/mnt/0 --prefix=/opt/openmpi --disable-silent-rules --enable-mpi-cxx --with-devel-headers --enable-binaries && \
    make -j4 && \
    make install && \
    ldconfig && \
    cd .. && \
    rm -rf openmpi-* && \
    cd /opt/openmpi/share/openmpi && \
    ln -s mpiCC-wrapper-data.txt mpiCC.openmpi-wrapper-data.txt && \
    ln -s mpic++-wrapper-data.txt mpic++.openmpi-wrapper-data.txt && \
    ln -s mpicc-wrapper-data.txt mpicc.openmpi-wrapper-data.txt && \
    ln -s mpicxx-wrapper-data.txt mpicxx.openmpi-wrapper-data.txt && \
    ln -s mpicxx-wrapper-data.txt mpif77.openmpi-wrapper-data.txt && \
    ln -s mpif90-wrapper-data.txt mpif90.openmpi-wrapper-data.txt && \
    \
    cd /tmp && \
    wget https://github.com/intel/compute-runtime/releases/download/22.09.22577/intel-gmmlib_22.0.2_amd64.deb && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.10409/intel-igc-core_1.0.10409_amd64.deb && \
    wget https://github.com/intel/intel-graphics-compiler/releases/download/igc-1.0.10409/intel-igc-opencl_1.0.10409_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/22.09.22577/intel-opencl-icd_22.09.22577_amd64.deb && \
    wget https://github.com/intel/compute-runtime/releases/download/22.09.22577/intel-level-zero-gpu_1.3.22577_amd64.deb && \
    dpkg -i *.deb && \
    rm -f *.deb && \
    echo 'libnvidia-opencl.so.1' > /etc/OpenCL/vendors/nvidia.icd

#RUN echo 'ACCEPT_EULA=accept \n\
#ACTIVATION_TYPE=no_license \n\
#INSTALL_MODE=NONRPM \n\
#CONTINUE_WITH_OPTIONAL_ERROR=yes \n\
#PSET_INSTALL_DIR=/opt \n\
#CONTINUE_WITH_INSTALLDIR_OVERWRITE=yes \n\
#COMPONENTS=DEFAULTS \n\
#PSET_MODE=install' > silent_install.cfg && \
#    wget --no-check-certificate ${INTEL_SDK_URL} && \
#    # Install SDK \
#    TARBALL=$(basename ${INTEL_SDK_URL}) \
# && DIR=$(basename ${INTEL_SDK_URL} .tar.gz) \
# && tar zxvf ${TARBALL} \
# && cd ${DIR} && ./install.sh --silent ../silent_install.cfg && \
#    cd .. && rm -rf $TARBALL $DIR silent_install.cfg

# Fix for: Cannot open configuration file /usr/share/openmpi/share/openmpi/mpicxx.openmpi-wrapper-data.txt
# Error parsing data file mpicxx.openmpi: Not found
# See: http://www.open-mpi.org/faq/?category=building#installdirs
ENV OPAL_PREFIX="/opt/openmpi" \
    PATH="$PATH:/opt/openmpi/bin" \
    LD_LIBRARY_PATH="/opt/openmpi/lib"
# export LD_LIBRARY_PATH="/usr/lib/x86_64-linux-gnu/openmpi/lib:/usr/lib:/usr/lib/x86_64-linux-gnu"

# Print version information

# Run MPI hello.c test
#WORKDIR /home/OpenMPi
#RUN wget https://www.open-mpi.org/papers/workshop-2006/hello.c && \
#    mpicc hello.c -o hello && \
#    mpirun --allow-run-as-root -np 4 ./hello

# Set our working directory
WORKDIR /workdir
