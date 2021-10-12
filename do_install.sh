#!/bin/bash
#SBATCH --job-name=SpackInstaller
#SBATCH --partition=serc,normal
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=2g
#SBATCH --output=SpackInstaller_out_%j.out
#SBATCH --error=SpackInstaller_out_%j.out
#SBATCH --time=16:00:00
#
module purge
#
#
# CONSIDER (but after the set-env.sh)
# module load icc ifort
# spack find
# module unload icc ifort
#
module load gcc/10.

SPK_ENV="matrix"
if [[ ! -z $1 ]]; then
  SPK_ENV=$1
fi
#
PKG=""
if [[ ! -z $2 ]]; then
  PKG=$2
fi
#
. spack/share/spack/setup-env.sh
#
spack env activate $SPK_ENV
spack concretize --force
spack install -y $2

