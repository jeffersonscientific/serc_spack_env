# The SERC Spack environment

This is the Spack environment for SERC users on the Sherlock HPC System @ Stanford University.

By launching the install script it will; clone spack, copy over the configuration files, download and compile the needed compilers, and install software. 

It will also install a hierarchical, LMOD based, set of "Core" modules that is helpful for many different packages. The Configuration is designed to limit a single installation per package, so workflows like:

    module load {preferred_compiler}/
    module load {preferred_mpi}/
    module load netcdf-cees/

should work smoothly.


## Files that may need to be modified

### In this Repo:
- `install.sh`: The install script should be modified for your platform of choice. Currently its hard coded for gcc 4.8.5 as its core compiler (CentOS 7).
- NOTE: The `defaults/*.yaml` schema was replaced to use custom configurations; `site` scope configuration would also be a good option. Using custom configurations (ie, `spack --config-scope={custom_config_path}` option)  makes the install process, outside the `install.sh` script a little bit more complicated, but avoids the need to backup and copy files.
  - More information on configuration scopes: https://spack.readthedocs.io/en/latest/configuration.html
  - For the time being, we provide two levels of custom configuratiton:
    - `config_cees/`: General configuration for this SW stack, nominally based on the `gcc` installation.
    - `config_{compiler@version}`: Additional configuration modifications for a given compiler.
    - NOTE: In some cases it may become necessary to provide an MPI level configuration as well.
- Configuratiton files of particular interest:
  - `modules.yaml`: This config file defines how modules are named, what information is included (eg. `bin`, `include`, etc. paths). Additionally, the core compiler is explicitly specified -- in this case, `gcc@4.8.5`, consistent with CentOS 7. This should not require compiler-level modifications.
  - `packages.yaml`: This is where the magic happens. This file can and should be modified to specify and define SW installations for your stack. In particular, use this file to define SW versions that are compatible with the restt of your SW stack. This is especially useful to modify the SW stack for a different compiler or MPI.
  - `compilers.yaml`: This one we can define, at least partially, en-script, but it can be important to look for conflicting `compiler.yaml` files at the local configuration level (`~/.spack/compilers.yaml`) that might have been created during development. They can point to bogus or missing compilers and create compile-time problems.

## Known issues

- The intel compilers can be finicky when downloading. Intel recently openned up the compiler downloads outside of Parallel Studio with their OneAPI initiative. Commenting out anything intel might be ideal in the install.sh script (although the intel compilers don't actually have to be built- which is nice). 
- About those Intel compilers:
   - For classic compilers, `icc`, 'icpc`, etc. designated as `intel@{version}`:
     - `v2021.3.0`, though apparently the version recommended by Spack, appear incompatible with most packags of interest here, at least with `mpich` MPI. A major culprit appears to be the `google-test` package, but generally after downgrading a large number of packages, `hdf5` fails to build in a way that does not seem resolvable... 
     - exept by using `v2021.2.01`, where amlost everythign works quite easily (with the configuration in this repo).
     - Building `openmpi`, at least `>= 4.x`, is nearly impossible. There are some workarounds in the blogosphere, but they are complicated and it is much easier to use `mpich`, `intel-oneapi-mpi`, or `openmpu%gcc`.
   - For the newer LLVM based compilers, `icx`, `icpx`, etc. designated as `oneapi@{version}`:
     -  It _looks like_ `v2021.3.0` is a good recommendation, but there appear to still be bugs building some packages.
     -  Again, it _looks like_ `intel-oneapi-mpi` will be preferred, if not necessary. There appear to be issues compiling with `mpich` (ie, it breaks for `hdf5`, and might be relatedc to an alleged persistent bug in the LLVM Fortran compiler(s) ); It appears that the `openmpi` problem applies here as well as with classic compilers, but that needs to be confirmed. 
- In some cases, Intel compilers require a newer version of the `gcc` compiler(s). In some cases, somewhere in the compile script (at the compiler or package level), certain components will actually be compiled with `gcc`, and so the default `gcc`, etc. need to refer to recent `gcc` compilers (not the CentOS 7 core `gcc@4.8.5`). One resolution appears to do a `spack load gcc@${GCC_VER}`, but it is not clear if there is a better solution or if a more targeted approach is necessary (eg., can the `gcc` compiler, perhaps via environment variables, be specified for a specific package?).
- Current Spack bug where architecture is not fixed. This means that, in some cases, even if you specify an architecture, eg. `target=zen2`, it will build some packages to the local architecture. Therefore, you must build packages on the intended target architecture. This creates bigger problems when building generic `x86-64` packages, as some components will be built to the host architecture. Will submit a ticket soon. 
- Generally, it seems that `hdf5@1.12` is not ready for prime time, or at least other packages are not ready for it. Several packages, including `dealii` may require `hdf5@1.10.2:1.10.7`, or more particularly `<@1.12.x`. It may be possible to work around this by specifying the `API` option in the HDF5 build, if `hdf5@1.12` is a must.
- Other packages that won't build?
