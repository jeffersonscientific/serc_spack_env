-- -*- lua
whatis([[Name : intel ]])
whatis([[Version : ${INTEL_VER}]])
whatis([[Target: x86_64]])
whatis([[Short description : Wrapper module script to load intel-oneapi-compilers for use with classic, intel/ compilers]])
help([[Wrapper modle for intel-oneapi intel/ compilers ]])
family("compiler")
--
-- NOTE: there may(not) be a (short) hash.
depends_on("intel-oneapi-compilers-cees-beta/2021.2.0-jd7")
-- --
-- NOTE: how do we script the module naming scheme?
prepend_path("MODULEPATH", "/oak/stanford/schools/ees/share/cees/software/spack_sw/cees_serc/spack/share/spack/lmod_zen2/linux-centos7-x86_64/intel/2021.2.0")
 --
 -- TODO: might need/benefit from full paths?
-- setenv("CC", "`which icc`")
setenv("CC", "icc")
setenv("CXX", "icpc")
setenv("FC", "ifort")
setenv("F77", "ifort")
setenv("F90", "ifort")
