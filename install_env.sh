#!/bin/bash
#SBATCH --job-name=SpackBuilds
#SBATCH --output=SpackBuilds_%A_%a.out
#SBATCH --error=SpackBuilds_%A_%a.out
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
#
#ARCH="x86_64" #this is the main target, select either x86_64, zen2, or skylake_avx512
ARCH=$(basename $(pwd))
if [[ ! -z $1 ]]; then
  ARCH=$1
fi
if [[ ! -z ${SLURM_CPUS_PER_TASK} ]]; then
	NPES=${SLURM_CPUS_PER_TASK}
fi
#
NPES=8
if [[ ! -z $2 ]]; then
    NPES=$2
fi
SPACK_ENV_NAME=${ARCH}
if [[ ! -z $3 ]]; then
    SPACK_ENV_NAME=$3
fi
#
if [[ -z ${SPACK_ENV_NAME} ]]; then
    echo "*** ERROR: SPACK_ENV_NAME must be set for this install script."
    exit 1
fi
#
NUKE_ENV=1
# NOTE: might be good to define spack or SPACK=`pwd`/spack , then local paths, so we can write modules.yaml entries like $spack/share/spack/${SPACK_ENV_NAME}
LMOD_PATH="`pwd`/spack/share/spack/lmod_${SPACK_ENV_NAME}"
TCL_PATH="`pwd`/spack/share/spack/modules_${SPACK_ENV_NAME}"
#
# append module names with this. It is in the modules.yaml file, but we don't
#  know how to get it from there, gracefully, yet.
LMOD_SUFFIX="yoda"
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
ONEAPI_VER="2021.2.0"
#SPACK_ENV_NAME="intel_202102"
#
CORECOUNT=${NPES} #main core count for compiling jobs
#
echo "*** Building for ARCH=${ARCH}; CPUs=${CORECOUNT}, SPACK_ENV_NAME=${SPACK_ENV_NAME}"
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

#exit

# are we using an environment?
if [[ ${NUKE_ENV} != 0 ]]; then spack env remove -y ${SPACK_ENV_NAME}; fi

# NOTE create this even if ${SPACK_ENV_NAME} is empty.
if [[ ! -d config_env_${SPACK_ENV_NAME} ]]; then mkdir config_env_${SPACK_ENV_NAME}; fi
if [[ ! -z ${SPACK_ENV_NAME} ]]; then
    if [[ ! -d spack/var/spack/environments/${SPACK_ENV_NAME} ]]; then
      spack env create ${SPACK_ENV_NAME}
    fi
    spack  --config-scope=config_cees/ --config-scope=config_intel@${INTEL_VER}/ --config-scope=config_oneapi@${ONEAPI_VER}/ env activate ${SPACK_ENV_NAME}
    #

cat > config_env_${SPACK_ENV_NAME}/modules.yaml <<EOF
modules:
  default:
    roots:
      #lmod: ${LMOD_PATH}
      #tcl: ${TCL_PATH}
      lmod: \$spack/share/spack/lmod_${SPACK_ENV_NAME}
      tcl: \$spack/share/spack/modules_${SPACK_ENV_NAME}
EOF
    #
    if [[ ! $?=0 ]]; then
        echo "Error activating Spack environment: ${SPACK_ENV_NAME}"
        exit 1
    fi
fi
    
spack compiler find --scope=site

#echo "Made it to intentional exit..."
#exit 1

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
        #  Nominally, this should be just for classic compilers, but there may be some components where it is not
        #  that icc,etc. need gcc libraries, but that a component must be  build with GNU.
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
        spack --config-scope=config_cees/ --config-scope=config_${compiler}/ --config-scope=config_env_${SPACK_ENV_NAME}/ install -j${CORECOUNT} ${pkg} %${compiler} target=${ARCH}
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
            spack --config-scope=config_cees/ --config-scope=config_${compiler}/ --config-scope=config_env_${SPACK_ENV_NAME}/ install -j${CORECOUNT} $pkg  %${compiler} ^$mpi target=${ARCH}
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

spack --config-scope=config_cees/  --config-scope=config_intel@${INTEL_VER}/ --config-scope=config_env_${SPACK_ENV_NAME}/ module lmod refresh --delete-tree -y

#
# now, write wrapper modules for intel/ and oneapi/
# unload gcc (probably not strictly necessary) and load the oneapi compilers so we can use
#  mod`which icc`, etc. to get compilers... or don't? depend on loading intel-oneapi-compilers to make that work?
spack unload gcc/
spack load intel-oneapi-compilers
#
INTEL_MODULE_PATH=${LMOD_PATH}/linux-centos7-x86_64/Core/intel--${LMOD_SUFFIX}/${INTEL_VER}.lua
ONEAPI_MODULE_PATH=${LMOD_PATH}/linux-centos7-x86_64/Core/oneapi--${LMOD_SUFFIX}/${ONEAPI_VER}.lua

for pth in `dirname ${INTEL_MODULE_PATH}` `dirname ${ONEAPI_MODULE_PATH}`
do
    if [[ ! -d ${pth} ]]; then
        mkdir -p ${pth}
    fi
done
#
cat > ${INTEL_MODULE_PATH} <<EOF
-- -*- lua
whatis([[Name : intel ]])
whatis([[Version : ${INTEL_VER}]])
whatis([[Target: x86_64]])
whatis([[Short description : Wrapper module script to load intel-oneapi-compilers for use with classic, intel/ compilers]])
help([[Wrapper modle for intel-oneapi intel/ compilers ]])
family("compiler")
--
depends_on("intel-oneapi-compilers-${LMOD_SUFFIX}/${INTEL_VER}")
--
-- NOTE: how do we script the module naming scheme?
prepend_path("MODULEPATH", "${LMOD_PATH}/linux-centos7-x86_64/intel/${INTEL_VER}")
--
-- TODO: might need/benefit from full paths?
-- setenv("CC", "`which icc`")
setenv("CC", "icc")
setenv("CXX", "icpc")
setenv("FC", "ifort")
setenv("F77", "ifort")
setenv("F90", "ifort")
--
EOF
#
cat > ${ONEAPI_MODULE_PATH} <<EOF
-- -*- lua
whatis([[Name : oneapi ]])
whatis([[Version : ${ONEAPI_VER}]])
whatis([[Target: x86_64]])
whatis([[Short description : Wrapper module script to load intel-oneapi-compilers for use with beta LLVM, oneapi/ compilers]])
help([[Wrapper modle for intel-oneapi oneapi/ (LLVM based) compilers ]])
family("compiler")
--
depends_on("intel-oneapi-compilers-${LMOD_SUFFIX}/${ONEAPI_VER}")
--
-- NOTE: how do we script the module naming scheme?
prepend_path("MODULEPATH", "${LMOD_PATH}/linux-centos7-x86_64/oneapi/${ONEAPI_VER}")
--
-- TODO: might need/benefit from full paths?
-- setenv("CC", "`which icx`")
setenv("CC", "icx")
setenv("CXX", "icpx")
setenv("FC", "ifx")
setenv("F77", "ifx")
setenv("F90", "ifx")
--
EOF


echo "finised install_env.sh script. exiting..."
exit 0

