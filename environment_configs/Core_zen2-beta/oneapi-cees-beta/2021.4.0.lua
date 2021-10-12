-- -*- lua
whatis([[Name : oneapi ]])
whatis([[Version : 2021.4.0]])
whatis([[Target: x86_64]])
whatis([[Short description : Wrapper module script to load intel-oneapi-compilers for use with beta LLVM, oneapi/ compilers]])
help([[Wrapper modle for intel-oneapi oneapi/ (LLVM based) compilers ]])
family("compiler")
--
depends_on("intel-oneapi-compilers-cees-beta/2021.4.0")
--
-- NOTE: how do we script the module naming scheme?
prepend_path("MODULEPATH", "/home/groups/s-ees/share/spack_sw/cees/spack/share/spack/lmod_zen2_zen2-beta/linux-centos7-x86_64/oneapi/2021.4.0")
--
-- TODO: might need/benefit from full paths?
-- setenv("CC", "")
setenv("CC", "icx")
setenv("CXX", "icpx")
setenv("FC", "ifx")
setenv("F77", "ifx")
setenv("F90", "ifx")
--
