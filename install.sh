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
INTEL_VER="2021.3.0"
#
CORECOUNT=${NPES} #main core count for compiling jobs

#ARCH="x86_64" #this is the main target, select either x86_64, zen2, or skylake_avx512
ARCH=$(basename $(pwd))
if [[ ! -z $1 ]]; then
	ARCH=$1
fi

echo "*** Building for ARCH=${ARCH}; CPUs=${CORECOUNT}"
#exit 1

#the compilers we will need.
compilers=(
    intel@${INTEL_VER}
    gcc@${GCC_VER}
    oneapi@${INTEL_VER}
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
#
# yoder: instead of coying the system default files, let's update the 'site' level config.
# also, we'll want to figure out how to update the site-scope compilers.yaml...
#  ... and actually, a better way to do this might be (see this note also in packages.yaml):
  # yoder: intel "incompatible with formal parameter error"
  #  we might need to define a additional custom config like --config-scope=intel@2021.3.0/ where we define these compiler specific configs.
  #  NOTE that this might also be a slicker way to manage the configs from the repo, so the intalls would be like:
  #  spack --config-scope=serc_config --config-scope=compiler_config/ install ...
#for fl in packages.yaml modules.yaml config.yaml
#do
#	#backup old yaml files
#	#mv spack/etc/spack/defaults/${fl} spack/etc/spack/defaults/${fl}_bak
#	#
#	# copy config files:
#	#cp defaults/${fl} spack/etc/spack/defaults/${fl}
#	cp defaults/${fl} spack/etc/spack/
#done

#mv spack/etc/spack/defaults/packages.yaml spack/etc/spack/defaults/packages.yaml_bak
#mv spack/etc/spack/defaults/modules.yaml spack/etc/spack/defaults/modules.yaml_bak


#copy over the configuration files:
#cp defaults/modules.yaml spack/etc/spack/defaults/modules.yaml
#cp defaults/packages.yaml spack/etc/spack/defaults/packages.yaml


#source the spack environment from relative path
source spack/share/spack/setup-env.sh

# remove compiler config?:
# it may be necessary to clean this out, but see below; what we really want to do is use the compiler find --scope=site option
#rm ${HOME}/.spack/linux/compilers.yaml
spack compiler find

#install compilers
echo "*** Installing compilers:"
#fix was added due to zen2 not having optimizations w/ 4.8.5 compiler
spack --config-scope=config_cees/ install -j${CORECOUNT} gcc@${GCC_VER}%gcc@4.8.5 target=x86_64
spack --config-scope=config_cees/ install -j${CORECOUNT} intel-oneapi-compilers@${INTEL_VER}%gcc@4.8.5 target=x86_64

#now add the compilers - gcc
spack --config-scope=config_cees/ compiler find --scope=site `spack location --install-dir gcc@${GCC_VER}`
spack --config-scope=config_cees/ compiler find --scope=site `spack location --install-dir gcc@${GCC_VER}`/bin
#
#icc
spack --config-scope=config_cees/ compiler find --scope=site `spack location --install-dir  intel-oneapi-compilers`/compiler/${INTEL_VER}/linux/bin
spack --config-scope=config_cees/ compiler find --scope=site `spack location --install-dir  intel-oneapi-compilers`/compiler/${INTEL_VER}/linux/bin/intel64


#
#############SOFTWARE INSTALL########################

for compiler in "${compilers[@]}"
do
	echo "*** Installing Compiler $compiler stack..."
	if [[ ! -d config_${compiler} ]]; then
		mkdir config_${compiler}
	fi
	#
    # Serial installs
    for pkg in proj swig maven geos intel-oneapi-tbb intel-oneapi-mkl
    do
        spack --config-scope=config_cees/ --config-scope=config_${compiler}/ install -j${CORECOUNT} ${pkg} %${compiler} target=${ARCH}
    done
    	
    # Parallel installs
    for mpi in "${mpis[@]}"
    do
		echo "*** Installing MPI elements: $compiler-$mpi"
        spack --config-scope=config_cees/ --config-scope=config_${compiler}/ install -j${CORECOUNT} $mpi %${compiler} target=${ARCH}
        #
        # TODO: catch an mpi install fail. No point in going forward after that, right?
        #
        for pkg in cdo parallel-ndtcdf petsc netcdf-c netcdf-fortran netcdf-cx4 hdf5 fftw parallelio cgal dealii xios
        do
            echo "*** Package: $pkg"
            spack --config-scope=config_cees/ --config-scope=config_${compiler}/ install -j${CORECOUNT} $pkg  %${compiler} ^$mpi target=${ARCH}
        done
    #
        # problem children:
        #spack install -j${CORECOUNT} dealii %${compiler} ^$mpi target=${ARCH}
        ## eventually, we get this error:
        #  "%gcc@10.1.0" conflicts with "mesa" [GCC 10.1.0 has a bug]
        #
        # yoder:
        # spack install -j${CORECOUNT} xios %${compiler} ^$mpi target=${ARCH}
        #  breaks installing Python or something? also does not seem to want to use the
        #   already built packages; appears to be building new mpich, hdf5, and other things too.
    done
done


#################END_OF_SOFTWARE_INSTALLS####################################


#have spack regenerate module files:

spack module lmod refresh --delete-tree -y


exit 0

