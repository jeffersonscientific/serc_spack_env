# The SERC Spack environment

This is the Spack environment for SERC users on the Sherlock HPC System @ Stanford University.

By launching the install script it will; clone spack, copy over the configuration files, download and compile the needed compilers, and install software. 

It has an lmod Core based hierarchy that is helpful for many different packages.

## Files that may need to be modified

### In this Repo:
- `install.sh`: The install script should be modified for your platform of choice. Currently its hard coded for gcc 4.8.5 as its core compiler (CentOS 7).
- `defaults/modules.yaml`: This config file defines how modules are named, what information is included (eg. `bin`, `include`, etc. paths). Additionally, the core compiler is explicitly specified -- in this case, `gcc@4.8.5`, consistent with CentOS 7.
- `packages.yaml` can and should be modified to reflect your SW needs.

## Known issues

- The intel compilers can be finicky when downloading. Intel recently openned up the compiler downloads outside of Parallel Studio with their OneAPI initiative. Commenting out anything intel might be ideal in the install.sh script (although the intel compilers don't actually have to be built- which is nice). 
- Current Spack bug where architecture is not fixed. Will submit a ticket soon. 
- `dealii` and other packages may require `hdf5@1.10.2:1.10.7`, or more particularly `<@1.12.x`. It may be necessary to actually force the lower version in the compile script.
- Other packages that won't build?
