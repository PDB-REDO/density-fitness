density-fitness
===============

This is the repository for density-fitness, an application to calculate density statisctics. This program is part of the [PDB-REDO](https://pdb.redo.eu/) suite
of programs.

Installation
------------

The easiest way to build and install density-fitness is by using the builder script, this is a CMake file that will build all missing dependencies automatically. Use it like this:

```console
git clone https://github.com/PDB-REDO/density-fitness.git -b density-fitness-builder
cd density-fitness
cmake -S . -B build -DCMAKE_INSTALL_PREFIX=$HOME/.local
cmake --build build
cmake --install build
```

Those commands will create an executable and install it in $HOME/.local. You can specify any other path here of course.

Please note that density-fitness built this way still requires a CCD components.cif file. This file should be located in '/usr/share/libcifpp/' or '/var/cache/libcifpp/'. You can of course also provide your own version of this file using the command line argumentsn (See [options](#options) below).

If you want to install the classic way, you have to install all dependencies first. See the documentation for [`libpdb-redo`](https://github.com/PDB-REDO/libpdb-redo) on installing all prerequisites.

After that, density-fitness can be built as follows:

```console
git clone https://github.com/PDB-REDO/density-fitness.git
cd density-fitness
mkdir build
cd build
cmake ..
cmake --build .
cmake --install .
```

When building on Windows you should replace `cmake --build .` with `cmake --build . --config Release`.

This checks out the source code from github, creates a new directory
where cmake stores its files. Run a configure, build the code and run
tests. And then it installs the library and auxiliary files.

The default is to install everything in `$HOME/.local` on Linux and
`%LOCALAPPDATA%` on Windows (the AppData/Local folder in your home directory).
You can change this by specifying the prefix with the
[CMAKE_INSTALL_PREFIX](https://cmake.org/cmake/help/v3.21/variable/CMAKE_INSTALL_PREFIX.html)
variable.

Usage
-----

# Name

density-fitness - Calculates per-residue electron density scores real-space R, real-space correlation coefficient, EDIAm, and OPIA

# Synopsis

```
density-fitness [OPTION] <mtz-file> <coordinates-file> [output]

density-fitness [OPTION] --hklin=<mtz-file> --xyzin=<coordinates-file[--output=<output>]

density-fitness [OPTION] --fomap=<fo-map-file> --dfmap=<df-map-file> --reslo=<low-resolution> --reshi=<high-resolution> --xyzin=<input [--output=<output>]
```

# Description

The program density-fitness calculates electron density metrics,
for main- (includes Cβ atom) and side-chain atoms of individual residues.

For this calculation, the program uses the structure model in either PDB
or mmCIF format and the electron density from the 2mFo-DFc and mFo-DFc maps.
If these maps are not readily available, the MTZ file and model can be used
to calculate maps clipper. Density-fitness support both X-ray and electron
diffraction data.

This program is essentially a reimplementation of _edstats_, a program
available from the CCP4 suite. However, the output now contains only the
RSR, SRSR and RSCC fields as in _edstats_ with the addition of EDIAm
and OPIA and no longer requires pre-calculated map coefficients.

* The real-space R factor (RSR) is defined (Brändén & Jones, 1990; Jones et al., 1991) as:
  
  RSR = Σ |ρobs - ρcalc| / Σ |ρobs + ρcalc|

  The SRSR is the estimated sigma for RSR.

* The real-space correlation coefficient (RSCC) is defined as:
  
  RSCC = cov(ρobs,ρcalc) / sqrt(var(ρobs) var(ρcalc))
  
  where cov(.,.) and var(.) are the sample covariance and variance (i.e. calculated
  with respect to the sample means of ρobs and ρcalc).

* The EDIAm score is a per-residue score based on the atomic EDIA value and the OPIA
  score gives the percentage of atoms in the residue with EDIA score is above 0.8.

# Options

When using MTZ files, the input and output files do not need the option flag.
If no output file is given, the result is printed to _stdout_.

When using map files, the resolution **must** be specified using the
_reshi_ and _reslo_ options.

* **--xyzin**
  The coordinates file in either PDB or mmCIF format. This file may be compressed with gzip.  --fomap and --dfmap
  The 2mFo-DFc and mFo-DFc map files respectively. Both are required and if these are specified, the resolution
  must also be specified.

* **--reslo and --reshi**
  The low and high resolution for the specified map files.

* **--hklin**
  The MTZ file. If this option is specified, the maps will be calculated using the information in this file.

* **--sampling-rate**
  The sampling rate to use when creating maps. Default is 1.5.

* **--recalc**
  By default the maps are read from the MTZ file, but you can also opt to recalculate the maps, e.g. when the
  structure no longer corresponds to the structure used to calculate the maps in the MTZ file.

* **--aniso-scaling**
  Accepted values for this option are observed and calculated or none.  Used when recalculating maps.

* **--no-bulk**
  When specified, a bulk solvent mask is not used in recalculating the maps.

* **--components (or --compounds)**
  Specify the path of the CCD file components.cif. By default the one installed by libcifpp is used, use this
  option to override this default.

* **--extra-compounds**
  A file containing information for residues in this specific target. This file may be in either CCD or CCP4
  monomer library format.

* **--mmcif-dictionary**
  Specify the path to the mmcif pdbx dictionary file. The default is to use the dictionary installed by libcifpp,
  use this option to override this default.

* **--no-validate**
  Omit the validation of the input mmCIF file. This will force output even in case the input file contains errors.

* **--electron-scattering**
  Use electron scattering factors instead of X-ray scattering factors.

* **--use-auth-ids**
  By default, when reading mmCIF files, the label_xxx_id is used in the edstats output. Use this flag to force
  output with the auth_xxx_ids.

* **--output-format**
  By default a JSON file is written, unless the filename ends with .eds.  Use this option to force output in
  edstats or json format.

* **--verbose,-V**
  Be more verbose, useful to diagnose validation errors.

# References

References:

* Statistical quality indicators for electron-density maps
  Tickle, I. J. (2012). Acta Cryst. D68, 454-467.
  DOI: 10.1107/S0907444911035918
* Estimating Electron Density Support for Individual Atoms and Molecular Fragments in X-ray Structures
  Agnes Meyder, Eva Nittinger, Gudrun Lange, Robert Klein, and Matthias Rarey
  Journal of Chemical Information and Modeling 2017 57 (10), 2437-2447
  DOI: 10.1021/acs.jcim.7b00391

# Author

Written by Maarten L. Hekkelman &lt;[maarten@hekkelman.com](mailto:maarten@hekkelman.com)&gt;

# Reporting Bugs

Report bugs at <https://github.com/PDB-REDO/density-fitness/issues>
