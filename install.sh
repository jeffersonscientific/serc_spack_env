#!/bin/bash
#SBATCH --job-name=SpackBuilds
#SBATCH --output=SpackBuilds_%A_%a.out
#SBATCH --error=SpackBuilds_%A_%a.err
#SBATCH --time=1-00:00:00
#SBATCH --ntasks=1 # how to scale the following to multiple tasks?
#SBATCH --cpus-per-task=8
#SBATCH --mem-per-cpu=4G
#SBATCH -p serc,normal
##SBATCH -C CPU_MNF:INTEL
#
# usage:
# ./insttall.sh {arch} {npes} {spack_env}
# TODO: for Intel compilers, we might actually need a more current GCC compiler. Ugh! So we could try a spack load, or maybe
#  we just need to build in multiple steps (for each compiler)
#
# NOTE: At this time, I think this will not parallelize across nodes, but
#   we need to look into this more carefully.
NPES=8

if [[ ! -z ${SLURM_CPUS_PER_TASK} ]]; then
	NPES=${SLURM_CPUS_PER_TASK}
fi
if [[ ! -z $2 ]]; then
    NPES=$2
fi
# This is the general install script for SERC on the Sherlock HPC system @ Stanford.
# 
#set -x #debug
#
#global variables
# NOTE: gcc@10.1.0 might be a little buggy and 11.2 is now the 'recommended' version,
# so let's give it a go!
#GCC_VER="10.1.0"
GCC_VER="11.2.0"
INTEL_VER="2021.2.0"
ONEAPI_VER="2021.3.0"
#SPACK_ENV="intel_202102"
#
if [[ ! -z $3 ]]; then
    SPACK_EN=$3
fi
#
CORECOUNT=${NPES} #main core count for compiling jobs
#
#ARCH="x86_64" #this is the main target, select either x86_64, zen2, or skylake_avx512
ARCH=$(basename $(pwd))
if [[ ! -z $1 ]]; then
	ARCH=$1
fi
#
echo "*** Building for ARCH=${ARCH}; CPUs=${CORECOUNT}"
#exit 1
#
#the compilers we will need.
compilers=(
    intel@${INTEL_VER}
     gcc@${GCC_VER}
     oneapi@${ONEAPI_VER}
)
#
# MPIs... well, 
mpis_gcc=(
    mpich
    openmpi
)
mpis_intel=(
    intel-oneapi-mpi
    mpich
)
#
#This is the ccache stuff commented out its really for testing and debugging.
#spack install -j${CORECOUNT} ccache
#now put ccache in the path
#CCACHE_PATH=`spack location --install-dir ccache`
#export PATH=$PATH:${CCACHE_PATH}/bin
#
# if it does not exist, clone the spack repo into this current directory
if [[ ! -d "spack" ]]; then
	git clone https://github.com/spack/spack.git
fi
#
# yoder: Removing the copy *.yaml to defaults step:
#  1) We're better off copying to the defaults/.. level. See Spack docs, but there is a directory based hierarchy
#   to configuration files; the recommendation is to leave 'default' alone and configure at the site, then local
#   (~/.spack) levels. You can also use custom config hierarchies with the --config-scope= option; priority
#   is lowest -> highest .
#
#source the spack environment from relative path
source spack/share/spack/setup-env.sh
#
#
# remove compiler config?:
# it may be necessary to clean this out, but see below; what we really want to do is use the compiler find --scope=site option
#rm ${HOME}/.spack/linux/compilers.yaml
spack compiler find --scope=site

#install compilers
echo "*** Installing compilers:"
#fix was added due to zen2 not having optimizations w/ 4.8.5 compiler
spack --config-scope=config_cees/ install -j${CORECOUNT} gcc@${GCC_VER}%gcc@4.8.5 target=x86_64
spack --config-scope=config_cees/ install -j${CORECOUNT} intel-oneapi-compilers@${INTEL_VER}%gcc@4.8.5 target=x86_64
spack --config-scope=config_cees/ install -j${CORECOUNT} intel-oneapi-compilers@${ONEAPI_VER}%gcc@4.8.5 target=x86_64

#now add the compilers
# GCC:
# use??  --config-scope=config_cees/
spack compiler find --scope=site `spack location --install-dir gcc@${GCC_VER}`
#spack compiler find --scope=site `spack location --install-dir gcc@${GCC_VER}`/bin
#
# ICX:
spack compiler find --scope=site `spack location --install-dir  intel-oneapi-compilers@${ONEAPI_VER}`/compiler/${ONEAPI_VER}/linux/bin
#
# ICC, etc.:
# NOTE: Intel compiler needs to know where gcc et al. are, and in some cases, we need a newer version. To use the
#  preferred gcc, there are two (good) options: 1) set the modules = [] value in compilers.yaml (or equivalently
#  in the {environment}/spack.yaml file), or to set flags:{cflags, cxxflags:, cppflags: values}. It would be nice to
#  be able to do this from the command line, but I'm not seeing it.
#  https://spack.readthedocs.io/en/latest/getting_started.html
#
# I wish this worked, but it does not:
#spack compiler add --scope=site `spack location --install-dir  intel-oneapi-compilers@${INTEL_VER}`/compiler/${INTEL_VER}/linux/bin/intel64 --cflags="-gcc-name `spack location --install-dir gcc@${GCC_VER}`/bin/gcc" --cxxflags="-gxx-name `spack location --install-dir gcc@${GCC_VER}`/bin/g++" --fflags="-gcc-name `spack location --install-dir gcc@${GCC_VER}`/bin/gcc"
# icc
spack compiler find --scope=site `spack location --install-dir  intel-oneapi-compilers@${INTEL_VER}`/compiler/${INTEL_VER}/linux/bin/intel64

# are we using an environment?
#if [[ ! -z ${SPACK_ENV} ]]; then
#    spack env activate ${SPACK_ENV}
#    if [[ ! $?=0 ]]; then
#        echo "Error activating Spack environment: ${SPACK_ENV}"
#        exit 1
#    fi
#fi
spack compiler find --scope=site


#
#############SOFTWARE INSTALL########################
#
# Yoder: NOTE: in principle, at least in an environment, I think all of these install statements can be shortened to:
# spack --config-scope=config_cees/ --config-scope=config_${compiler}/ install -j${CORECOUNT}
# At least in an environment, spack will then install everything in packages.yaml. Alternatively,
# an environment can be installed with a spack.yaml or spack.lock
#
for compiler in "${compilers[@]}"
do
	echo "*** Installing Compiler $compiler stack..."
	if [[ ! -d config_${compiler} ]]; then
		mkdir config_${compiler}
	fi
    mpis=${mpis_gcc[@]}
    if [[ ${compiler} = intel* || ${compiler} = oneapi* ]]; then
        mpis=${mpis_intel[@]}
        # load GCC?
        # Turns out some Intel packages require a new GCC, and in fact compile components with that GCC.
        spack load gcc@${GCC_VER}
    fi
    #
    echo "MPIs: ${mpis}"
    echo "*** *** ***"
	#
    # Serial installs
    for pkg in proj swig geos maven intel-oneapi-tbb intel-oneapi-mkl intel-tbb
    #for pkg in proj swig geos
    do
        spack --config-scope=config_cees/ --config-scope=config_${compiler}/ install -j${CORECOUNT} ${pkg} %${compiler} target=${ARCH}
    done
    #
    # Parallel installs
    for mpi in ${mpis[@]}
    do
        echo "*** MPI: ${mpi}"
        echo "*** Installing MPI dep packages: $compiler::${mpi}"
        # install MPI implicitly from mpi dep. packages.
        #spack --config-scope=config_cees/ --config-scope=config_${compiler}/ install -j${CORECOUNT} $mpi %${compiler} target=${ARCH}
        #
        # TODO: catch an mpi install fail. No point in going forward after that, right?
        #
        # main packages:
        for pkg in hdf5 netcdf-c netcdf-fortran netcdf-cxx4 cdo parallel-netcdf petsc fftw parallelio cgal
        do
            echo "*** Package: $pkg"
            spack --config-scope=config_cees/ --config-scope=config_${compiler}/ install -j${CORECOUNT} $pkg  %${compiler} ^$mpi target=${ARCH}
        done
        #
        # aux packages and problem children:
        #for pkg in freetype dealii xios
        #do
        #    echo "*** Package: $pkg"
        #    spack --config-scope=config_cees/ --config-scope=config_${compiler}/ install -j${CORECOUNT} $pkg  %${compiler} ^$mpi target=${ARCH}
        #done
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

spack --config-scope=config_cees/ module lmod refresh --delete-tree -y


exit 0

