#!/bin/bash
# This is the general install script for SERC on the Sherlock HPC system @ Stanford.
# 
#
#
#set -x #debug


#global variables
CORECOUNT=16 #main core count for compiling jobs
ARCH="x86_64" #this is the main target, select either x86_64, zen2, or skylake_avx512

#the compilers we will need.
compilers=(
    %gcc@10.1.0
    %intel@2021.2.0
)

mpis=(
    openmpi
    mpich
)




#This is the ccache stuff commented out its really for testing and debugging.
#spack install -j${CORECOUNT} ccache
#now put ccache in the path
#CCACHE_PATH=`spack location --install-dir ccache`
#export PATH=$PATH:${CCACHE_PATH}/bin


#clone the spack repo into this current directory
git clone https://github.com/spack/spack.git


#backup old yaml files
mv spack/etc/spack/defaults/packages.yaml spack/etc/spack/defaults/packages.yaml_bak
mv spack/etc/spack/defaults/modules.yaml spack/etc/spack/defaults/modules.yaml_bak

#copy over the configuration files:
cp defaults/modules.yaml spack/etc/spack/defaults/modules.yaml
cp defaults/packages.yaml spack/etc/spack/defaults/packages.yaml


#source the spack environment
source spack/share/spack/setup-env.sh

#install compilers
spack install -j${CORECOUNT} gcc@10.1.0%gcc@4.8.5 target=${ARCH}
spack install -j${CORECOUNT} intel-oneapi-compilers@2021.2.0%gcc@4.8.5 target=${ARCH}

#now add the compilers - gcc
spack load gcc@10.1.0
spack compiler find
spack compiler add

#redundant add:
GCC_PATH=`spack location --install-dir gcc@10.1.0`
export PATH=$PATH:${GCC_PATH}/bin
spack compiler find
spack compiler add

#icc
spack load intel-oneapi-compilers@2021.2.0
spack compiler find
spack compiler add

#redundant add:
#ICC_PATH=`spack location --install-dir intel-oneapi-compilers@2021.2.0`
#export PATH=$PATH:${ICC_PATH}/bin
#sorry heuristics approach...
export PATH=$PATH:`spack location --install-dir  intel-oneapi-compilers`/compiler/2021.2.0/linux/bin/intel64:`spack location --install-dir  intel-oneapi-compilers`/compiler/2021.2.0/linux/bin
spack compiler find
spack compiler add




#############SOFTWARE INSTALL########################

for compiler in "${compilers[@]}"
do
    # Serial installs
    spack install -j${CORECOUNT} proj $compiler target=${ARCH}
    spack install -j${CORECOUNT} swig $compiler target=${ARCH}
    spack install -j${CORECOUNT} maven $compiler target=${ARCH}
    spack install -j${CORECOUNT} geos $compiler target=${ARCH}

    # Parallel installs
    for mpi in "${mpis[@]}"
    do
        spack install -j${CORECOUNT} $mpi $compiler target=${ARCH}
        spack install -j${CORECOUNT} cdo  $compiler ^$mpi target=${ARCH}
        spack install -j${CORECOUNT} parallel-netcdf $compiler ^$mpi target=${ARCH}
        spack install -j${CORECOUNT} petsc $compiler ^$mpi target=${ARCH}
		spack install -j${CORECOUNT} netcdf-fortran $compiler ^$mpi target=${ARCH}
		spack install -j${CORECOUNT} netcdf-c $compiler ^$mpi target=${ARCH}
		spack install -j${CORECOUNT} netcdf-cxx4 $compiler ^$mpi target=${ARCH}
		spack install -j${CORECOUNT} hdf5 $compiler ^$mpi target=${ARCH}
		spack install -j${CORECOUNT} fftw $compiler ^$mpi target=${ARCH}
		spack install -j${CORECOUNT} parallelio $compiler ^$mpi target=${ARCH}
		spack install -j${CORECOUNT} dealii $compiler ^$mpi target=${ARCH}
		spack install -j${CORECOUNT} cgal $compiler ^$mpi target=${ARCH}
    done
done


#################END_OF_SOFTWARE_INSTALLS####################################
