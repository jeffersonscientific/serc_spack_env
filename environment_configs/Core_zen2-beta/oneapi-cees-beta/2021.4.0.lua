-- -*- lua
whatis([[Name : intel ]])
whatis([[Version : myModuleVersion () ]])
whatis([[Target: x86_64]])
whatis([[Short description : Wrapper module script to load intel-oneapi-compilers for use with beta LLVM-based, (intel) oneapi/ compilers]])
help([[Wrapper modle for intel-oneapi oneapi/ (beta LLVM based) compilers ]])
family("compiler")
--
VER=myModuleVersion()
--
depends_on(pathJoin("intel-oneapi-compilers-cees-beta", VER))
--depends_on("intel-oneapi-compilers-cees-beta/2021.4.0")
--
-- NOTE: how do we script the module naming scheme?
THIS_MOD=myFileName()

MOD_ROOT=subprocess("dirname $(dirname $(dirname "..THIS_MOD.."))")

--CORE_PATH,MOD_NAME=splitFileName(THIS_MOD)
--CORE_PATH,intel=splitFileName(CORE_PATH)
--CORE_PATH,intel=splitFileName(CORE_PATH)
--
--MOD_ROOT,core=splitFileName(CORE_PATH)
--MOD_ROOT="/home/groups/s-ees/share/cees/spack_cees/spack/share/spack/lmod_zen2_zen2-beta/linux-centos7-x86_64"
--
MOD_PATH=pathJoin(MOD_ROOT, "oneapi", VER)
--
--subprocess("echo \"**DEBUG: "..MOD_PATH.."\"")

prepend_path("MODULEPATH", MOD_PATH)
--prepend_path("MODULEPATH", "/home/groups/s-ees/share/cees/spack_cees/spack/share/spack/lmod_zen2_zen2-beta/linux-centos7-x86_64/intel/2021.4.0")
--
-- TODO: might need/benefit from full paths?
-- setenv("CC", "")
setenv("CC", "icx")
setenv("CXX", "icpx")
setenv("FC", "ifx")
setenv("F77", "ifx")
setenv("F90", "ifx")
--
