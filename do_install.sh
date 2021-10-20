#!/bin/bash
#SBATCH --job-name=SpackInstaller
#SBATCH --partition=serc,normal
#SBATCH --cpus-per-task=12
#SBATCH --ntasks=1
#SBATCH --mem-per-cpu=2g
#SBATCH --output=SpackInstaller_out_%j.out
#SBATCH --error=SpackInstaller_out_%j.out
#SBATCH --time=26:00:00
#
module purge
#
#
# CONSIDER (but after the set-env.sh)
# module load icc ifort
# spack find
# module unload icc ifort
#
echo "SLURM_CPUS_PER_TASK: ${SLURM_CPUS_PER_TASK}"
echo "SLURM_PARTITION: ${SLURM_PARTITION}"
#exit 42

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
echo "*** Begin do_install for: :"
echo "*** SPK_ENV: ${SPK_ENV}, package=$2"
#
spack env activate $SPK_ENV
spack concretize --force
if [[ ! $? -eq 0 ]]; then
  spack concretize --force
fi

spack install -y --overwrite $2

