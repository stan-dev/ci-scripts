# Current build machines

- `gelman-group-linux`
    - Operating System: `Ubuntu 18.04.2 LTS`
    - Java version: `1.8.0_232-8u232-b09-0ubuntu1~18.04.1-b09`
    - RAM: `32 GB`
    - CPU: `Intel Xeon CPU E5-2630 v3 @ 2.40GHz`
    - GPU: `NVIDIA Corporation GM107GL [Quadro K620]`
    - Environment variables:
        - `CXX=clang++-6.0`
        - `GCC=g++`
        - `MPICXX=mpicxx.openmpi`
        - `N_TESTS=150`
        - `OPENCL_DEVICE_ID=0`
        - `PARALLEL=16`
    - Labels: `linux` `mpi` `docker` `gpu` `distribution-tests`
    - Disks:
        - `HDD 1 TB`
        
- `gelman-group-mac`
    - Operating System: `OS X 10.11.6 (15G22010)` `(Darwin 15.6.0)`
    - Java version: `9.0.4`
    - RAM: `64 GB`
    - CPU:`Intel Xeon CPU E5-1680 v2 @ 3.00GHz`
    - GPU: 2x`AMD FirePro D700`
    - Environment variables:
        - `CXX=/usr/local/opt/llvm@6/bin/clang++`
        - `GCC=g++`
        - `MPICXX=mpicxx`
        - `N_TESTS=350`
        - `OPENCL_DEVICE_ID=1`
        - `PARALLEL=16`
        - `PATH=$PATH:/usr/local/bin:/Library/TeX/texbin`
    - Labels: `osx` `gpu` `ocaml`
    - Disks:
        - `NVMe SSD 512 GB`
        
- `gelman-group-win-new`
    - Operating System: `Windows 10 Pro (Version 1809) (OS Build 17763.914)`
    - Java version: `1.8.0_161`
    - RAM: `32 GB`
    - Swap: `32 GB`
    - CPU:`Intel i5-6600K CPU @ 3.50GHz`
    - GPU: `Nvidia Titan Xp`
    - Environment variables:
        - `CC=gcc`
        - `CXX=g++`
        - `N_TESTS=100`
        - `OPENCL_DEVICE_ID=0`
        - `PARALLEL=16`
    - Labels: `windows` `wsl` [windows-low-space](https://jenkins.mc-stan.org/job/Clean-windows-workdir/)
    - Disks:
        - `NVMe SSD 256 GB`
        
- `gelman-group-win2`
    - Operating System: `Windows 10 Pro (Version 1809) (OS Build 17763.914)`
    - Java version: `1.8.0_161`
    - RAM: `32 GB`
    - Swap: `32 GB`
    - CPU:`Intel Xeon CPU E5-2630 v3 @ 2.40 GHz`
    - GPU: `Nvidia Quadro K620`
    - Environment variables:
        - `CXX=g++`
        - `GCC=g++`
        - `N_TESTS=100`
        - `PARALLEL=16`
    - Labels: `windows` `wsl`
    - Disks:
        - `HDD 1 TB`

- `old-imac`
    - Operating System: `macOS 10.13.4 (17E199) (Darwin 17.5.0)`
    - Java version: `1.8.0_161`
    - RAM: `16 GB`
    - CPU:`Intel Core i7 CPU 870  @ 2.93GHz`
    - GPU: `ATI Radeon HD 5750`
    - Environment variables:
        - `CXX=/usr/local/opt/llvm@6/bin/clang++`
        - `GCC=g++`
        - `MPICXX=mpicxx`
        - `N_TESTS=500`
        - `OPENCL_DEVICE_ID=1`
        - `PARALLEL=6`
        - `PATH=/Library/TeX/texbin`
    - Labels: `master` `oldimac`
    - Disks:
        - `SSD 256 TB`
        - `SSD 256 TB`

- `master` - Doesn't run much builds on the machine but does some docker builds because of the label `docker-registry`

# Current on-demand build machines ( AWS EC2 Spot )

### Windows

Currently not scaling up because of `cc1plus.exe: out of memory allocating 65536 bytes`

- Instance type: `m5d.8xlarge`
- Operating System: `Windows Server 2019 Datacenter (Version 1809) (OS Build 17763.379)`
- Java version: `1.8.0_222`
- RAM: `128 GB`
- Swap: `25 GB`
- CPU: 32x`3.1 GHz Intel Xeon® Platinum 8175`
- Environment variables:
    - `CXX=g++`
    - `GCC=g++`
    - `N_TESTS=100`
    - `PARALLEL=16`
- Labels: `windows` `wsl`
- Disks:
    - `NVMe SSD 600 GB`
    - `NVMe SSD 600 GB`

### Linux

Operational

- Instance types: `c5d.18xlarge` `m5ad.12xlarge` `m5d.12xlarge` `m5dn.4xlarge` `r5ad.12xlarge`
- Operating System: `Ubuntu 18.04.2 LTS`
- Java version: `1.8.0_232-8u232-b09-0ubuntu1~18.04.1-b09`
- Environment variables:
    - `CXX=clang++-6.0`
    - `GCC=g++`
    - `MPICXX=mpicxx.openmpi`
    - `N_TESTS=300`
    - `PARALLEL=25`
- Labels: `distribution-tests` `linux` `docker` `mpi`