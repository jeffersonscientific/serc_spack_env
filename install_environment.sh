#!/bin/bash
#SBATCH --job-name=SpackInstaller
#SBATCH --partition=serc,normal
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=3g
#SBATCH --output=SpackInstaller_out_%j.out
#SBATCH --error=SpackInstaller_out_%j.out
#SBATCH --time=24:00:00
#SBATCH --constraint=CPU_GEN:RME
#
module purge
#
# Spack SW stack environment installer
#
SPK_ENV="toy"
if [[ ! -z $1 ]]; then
  SPACK_ENV_NAME=$1
fi
#
INPUT_CONFIG=""
if [[ ! -z $2 ]]; then
  INPUT_CONFIG=$2
fi
#
NUKE_ENV=0
while getopts e:i:s:n: flag
do
  case "${flag}" in
    e)
    SPACK_ENV_NAME=${OPTARG}
    ;;
    i)
    INPUT_CONFIG=${OPTARG}
    ;;
    s)
    LMOD_SUFFIX_INPUT=${OPTARG}
    ;;
    n)
    NUKE_ENV=1
    ;;
  esac
done
shift $((OPTIND -1))
# INPUT_FILES=(${INPUT_FILES})

#SPACK_ENV_NAME=skylake-beta
#INPUT_CONFIG=environment_configs/cees_beta_skylake_beta_gcc1102_intel202104.yaml
#LMOD_SUFFIX_INPUT=cees-beta
#
CODE_NAME=`/usr/local/sbin/cpu_codename -c` #the output of the cpu_codename command
#
ARCH="x86_64_v3"
if [[ ${CODE_NAME} == "RME" ]]; then
    ARCH="zen2"
elif  [[ ${CODE_NAME} == "SKX" ]]; then
    ARCH="skylake"
    #ARCH="skylake_avx512"
fi
#
LUA_PATH=`pwd`/spack/share/spack/lmod_${ARCH}_${SPACK_ENV_NAME}
#
ONEAPI_VER="2021.4.0"
LMOD_SUFFIX=${SPACK_ENV_NAME}
if [[ ! -z ${LMOD_SUFFIX_INPUT} ]]; then
  LMOD_SUFFIX=${LMOD_SUFFIX_INPUT}
fi
LUA_PATH_INTEL=${LUA_PATH}/linux-centos7-x86_64/Core/intel-${LMOD_SUFFIX}
LUA_PATH_ONEAPI=${LUA_PATH}/linux-centos7-x86_64/Core/oneapi-${LMOD_SUFFIX}
#
# CONSIDER (but after the set-env.sh)
# module load icc ifort
# spack find
# module unload icc ifort
#
echo "*** DEBUG: "
echo "SPACK_ENV_NAME: ${SPACK_ENV_NAME}"
echo "INPUT_CONFIG: ${INPUT_CONFIG}"
echo "LUA_PATH_INTEL: ${LUA_PATH_INTEL}"
echo "LUA_PATH_ONEAPI: ${LUA_PATH_ONEAPI}"
#
#exit 1
module load gcc/10.
. spack/share/spack/setup-env.sh
#
if [[ ${NUKE_ENV} -eq 1 ]]; then
  spack env remove ${SPACK_ENV_NAME}
fi
if [[ ! -d spack/var/spack/environments/${SPACK_ENV_NAME} ]]; then
  spack env create ${SPACK_ENV_NAME} ${INPUT_CONFIG}
fi
#
#
spack env activate ${SPACK_ENV_NAME}
spack concretize --force
spack install -y $2
#
spack module lmod refresh --delete-tree -y
#
#####
for pth in ${LUA_PATH_INTEL} ${LUA_PATH_ONEAPI}
do
    if [[ ! -d ${pth} ]]; then
        mkdir -p ${pth}
    fi
done
#
cat > ${LUA_PATH_INTEL}/${ONEAPI_VER}.lua <<EOF
-- -*- lua
whatis([[Name : intel ]])
whatis([[Version : ${ONEAPI_VER}]])
whatis([[Target: x86_64]])
whatis([[Short description : Wrapper module script to load intel-oneapi-compilers for use with classic, intel/ compilers]])
help([[Wrapper modle for intel-oneapi intel/ compilers ]])
family("compiler")
--
depends_on("intel-oneapi-compilers-${LMOD_SUFFIX}/${ONEAPI_VER}")
--
-- NOTE: how do we script the module naming scheme?
prepend_path("MODULEPATH", "${LUA_PATH}/linux-centos7-x86_64/intel/${ONEAPI_VER}")
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
cat > ${LUA_PATH_ONEAPI}/${ONEAPI_VER}.lua <<EOF
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
prepend_path("MODULEPATH", "${LUA_PATH}/linux-centos7-x86_64/oneapi/${ONEAPI_VER}")
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
