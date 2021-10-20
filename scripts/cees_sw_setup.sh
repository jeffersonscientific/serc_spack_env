#!/bin/bash
#
# This script sets up the environment
#
# yoder 22 sept 2021:
# making a few changes:
# 1) instead of explicitly setting the modulefiles, we will leave alone the standard sherlock environment(s) and let users
#    handle that on their own.
# 2) use modulle use {path} to set modules, instead of explicitly modifying the path.
#
#
#
#set -x #debug

#global variables

#directories
# TODO: rename this spack_beta or something...
#BASE_DIST_DIR="/oak/stanford/schools/ees/share/cees/software/spack_"
#BASE_DIST_DIR="/oak/stanford/schools/ees/share/cees/software/spack_sw/cees_serc"
BASE_DIST_DIR="/home/groups/s-ees/share/cees/spack_cees"


#sherlock modules
SHER_MOD_PATH="/share/software/modules/devel:/share/software/modules/math:/share/software/modules/categories"

#serc internal modules
#SERC_MOD_PATH_OAK="/oak/stanford/schools/ees/share/cees/modules/modulefiles"

CEES_MOD_PATH_x86="/home/groups/s-ees/share/cees/modules/modulefiles"
CEES_MOD_PATH_zen2="/home/groups/s-ees/share/cees/modules/modulefiles_zen2"
CEES_MOD_PATH_skylake="/home/groups/s-ees/share/cees/modules/modulefiles_skylake"
#
CEES_MOD_DEPS_PATH_x86="/home/groups/s-ees/share/cees/modules/moduledeps"
CEES_MOD_DEPS_PATH_zen2="/home/groups/s-ees/share/cees/modules/moduledeps_zen2"
CEES_MOD_DEPS_PATH_skylake="/home/groups/s-ees/share/cees/modules/moduledeps_skylake"
#
#####
#
CODE_NAME=`/usr/local/sbin/cpu_codename -c` #the output of the cpu_codename command
#
#conditionals
if [[ ${CODE_NAME} == "RME" ]]; then
#
    #SPACK_MOD_PATH="${BASE_DIST_DIR}/zen2/spack/share/spack/lmod/linux-centos7-x86_64/Core"
    #SPACK_MOD_PATH="${BASE_DIST_DIR}/spack/share/spack/lmod_zen2/linux-centos7-x86_64/Core"
    SPACK_ARCH="zen2"
    SPACK_ENV_NAME="zen2-beta"
    CEES_MOD_PATH=$CEES_MOD_PATH_zen2
#
elif  [[ ${CODE_NAME} == "SKX" ]]; then
#
    #SPACK_MOD_PATH="${BASE_DIST_DIR}/skylake/spack/share/spack/lmod/linux-centos7-x86_64/Core"
    #SPACK_MOD_PATH="${BASE_DIST_DIR}/spack/share/spack/lmod_skylake_avx512/linux-centos7-x86_64/Core"
    #SPACK_ENV_NAME="skylake_avx512"
    SPACK_ARCH="skylake"
    SPACK_ENV_NAME="skylake-beta"
    CEES_MOD_PATH=$CEES_MOD_PATH_skylake

else
    #SPACK_MOD_PATH="${BASE_DIST_DIR}/x86_64/spack/share/spack/lmod/linux-centos7-x86_64/Core"
    #SPACK_MOD_PATH="${BASE_DIST_DIR}/spack/share/spack/lmod_x86_64/linux-centos7-x86_64/Core"
    SPACK_ARCH="x86_64"
    # TODO: build x86?
    SPACK_ENV_NAME="x86_64-beta"
fi
#SPACK_MOD_PATH="${BASE_DIST_DIR}/spack/share/spack/lmod_${SPACK_ENV_NAME}/linux-centos7-x86_64/Core"
SPACK_MOD_PATH="${BASE_DIST_DIR}/spack/share/spack/lmod_${SPACK_ARCH}_${SPACK_ENV_NAME}/linux-centos7-x86_64/Core"

# finally export the module environment 

#export MODULEPATH="${SPACK_MOD_PATH}:${SERC_MOD_PATH}:${SHER_MOD_PATH}"
# TODO: confirm that module use will work with {path1:path2:}. if not, append path or
#  split into a list.
module use ${SPACK_MOD_PATH}
module use ${CEES_MOD_PATH_x86}

if [[ ! -z ${CEES_MOD_PATH} ]]; then
  module use ${CEES_MOD_PATH}
fi





