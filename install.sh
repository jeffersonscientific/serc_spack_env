#!/bin/bash
#SBATCH --job-name=SpackBuilds
#SBATCH --output=SpackBuilds_%A_%a.out
#SBATCH --error=SpackBuilds_%A_%a.err
#SBATCH --time=1-00:00:00
#SBATCH --ntasks=1 # how to scale the following to multiple tasks?
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=2G
#SBATCH -p serc,normal
##SBATCH -C CPU_MNF:INTEL
#
# NOTE: At this time, I think this will not parallelize across nodes, but
#   we need to look into this more carefully.
NPES=8
if [[ ! -z $2 ]]; then
	NPES=$2
fi
if [[ ! -z ${SLURM_CPUS_PER_TASK} ]]; then
	NPES=${SLURM_CPUS_PER_TASK}
fi

# This is the general install script for SERC on the Sherlock HPC system @ Stanford.
# 
#set -x #debug


#global variables
# NOTE: gcc@10.1.0 might be a little buggy and 11.2 is now the 'recommended' version,
# so let's give it a go!
#GCC_VER="10.1.0"
GCC_VER="11.2.0"
INTEL_VER="2021.2.0"
#
CORECOUNT=${NPES} #main core count for compiling jobs
ARCH="x86_64" #this is the main target, select either x86_64, zen2, or skylake_avx512
if [[ ! -z $1 ]]; then
	ARCH=$1
fi

echo "*** Building for ARCH=${ARCH}; CPUs=${CORECOUNT}"
#exit 1

#the compilers we will need.
#     %intel@${INTEL_VER}
compilers=(
    %intel@${INTEL_VER}
    %gcc@${GCC_VER}
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
if [[ ! -d "spack" ]]; then
	git clone https://github.com/spack/spack.git
fi


for fl in packages.yaml modules.yaml config.yaml
do
	#backup old yaml files
	mv spack/etc/spack/defaults/${fl} spack/etc/spack/defaults/${fl}_bak
	#
	# copy config files:
	cp defaults/${fl} spack/etc/spack/defaults/${fl}
}
done
#mv spack/etc/spack/defaults/packages.yaml spack/etc/spack/defaults/packages.yaml_bak
#mv spack/etc/spack/defaults/modules.yaml spack/etc/spack/defaults/modules.yaml_bak


#copy over the configuration files:
#cp defaults/modules.yaml spack/etc/spack/defaults/modules.yaml
#cp defaults/packages.yaml spack/etc/spack/defaults/packages.yaml


#source the spack environment from relative path
source spack/share/spack/setup-env.sh

#install compilers 
#fix was added due to zen2 not having optimizations w/ 4.8.5 compiler
spack install -j${CORECOUNT} gcc@${GCC_VER}%gcc@4.8.5 target=x86_64
spack install -j${CORECOUNT} intel-oneapi-compilers@${INTEL_VER}%gcc@4.8.5 target=x86_64

#now add the compilers - gcc
spack compiler find `spack location --install-dir gcc@${GCC_VER}`
spack compiler find `spack location --install-dir gcc@${GCC_VER}`/bin


#icc
spack compiler find `spack location --install-dir  intel-oneapi-compilers`/compiler/${INTEL_VER}/linux/bin
spack compiler find `spack location --install-dir  intel-oneapi-compilers`/compiler/${INTEL_VER}/linux/bin/intel64





#############SOFTWARE INSTALL########################

for compiler in "${compilers[@]}"
do
    # Serial installs
    spack install -j${CORECOUNT} proj $compiler target=${ARCH}
    spack install -j${CORECOUNT} swig $compiler target=${ARCH}
    spack install -j${CORECOUNT} maven $compiler target=${ARCH}
    spack install -j${CORECOUNT} geos $compiler target=${ARCH}
    #
    # yoder:
    spack install -j${CORECOUNT} intel-oneapi-tbb $compiler target=${ARCH}
	spack install -j${CORECOUNT} intel-oneapi-mkl $compiler target=${ARCH}
    	
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
		spack install -j${CORECOUNT} cgal $compiler ^$mpi target=${ARCH}
		#
		# problem children:
		spack install -j${CORECOUNT} dealii $compiler ^$mpi target=${ARCH}
		#  eventually, we get this error:
		#  "%gcc@10.1.0" conflicts with "mesa" [GCC 10.1.0 has a bug]
		#
		# yoder:
		spack install -j${CORECOUNT} xios $compiler ^$mpi target=${ARCH}
		#  breaks installing Python or something? also does not seem to want to use the
		#   already built packages; appears to be building new mpich, hdf5, and other things too.
    done
done


#################END_OF_SOFTWARE_INSTALLS####################################


#have spack regenerate module files:

spack module lmod refresh --delete-tree -y


exit 0

