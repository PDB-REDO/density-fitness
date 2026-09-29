density-fitness
===============

[![github CI](https://github.com/PDB-REDO/density-fitness/actions/workflows/cmake-multi-platform.yml/badge.svg)](https://github.com/PDB-REDO/density-fitness/actions)

This is the repository for density-fitness, an application to calculate density statistics. This program is part of the [PDB-REDO](https://pdb-redo.eu/) suite
of programs.

Installation
------------

The easiest way to install density-fitness is by installing [CCP4](https://www.ccp4.ac.uk/download/index.php)

It is possible to install density-fitness on Linux without having CCP4. In that case you will have install some dependencies first. On Debian this boils down to:

```console
sudo apt-get update && sudo apt-get install libcatch2-dev nlohmann-json3-dev libeigen3-dev libccp4-dev libclipper-dev libgsl-dev
```

And on Ubuntu, slightly different:

```console
sudo apt-get update && sudo apt-get install catch2 nlohmann-json3-dev libeigen3-dev libccp4-dev libclipper-dev libgsl-dev
```

After that, building and installing should be as simple as:

```console
git clone https://github.com/PDB-REDO/density-fitness.git
cd density-fitness
cmake -S . -B build
cmake --build build
sudo cmake --install build
```

Please note that density-fitness built this way still requires a CCD components.cif file. This file should be located in '/usr/share/libcifpp/' or '/var/cache/libcifpp/'. You can of course also provide your own version of this file using the command line arguments (See [options](#options) below).

If you want to install the classic way, you have to install all dependencies first. See the documentation for [`libpdb-redo`](https://github.com/PDB-REDO/libpdb-redo) on installing all prerequisites.

Usage
-----

# Name

density-fitness - Calculates per-residue electron density scores real-space R, real-space correlation coefficient, EDIAm, and OPIA

# Synopsis

```
density-fitness [OPTION] <mtz-file> <coordinates-file> [output]

density-fitness [OPTION] --hklin=<mtz-file> --xyzin=<coordinates-file> [--output=<output>]

density-fitness [OPTION] --fomap=<fo-map-file> --dfmap=<df-map-file> --reslo=<low-resolution> --reshi=<high-resolution> --xyzin=<coordinates-file> [--output=<output>]
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
  The coordinates file in either PDB or mmCIF format. This file may be compressed with gzip.

* **--hklin**
  The MTZ file containing the observed structure factors. If this option is specified, the maps are calculated
  using the information in this file.

* **--fomap and --dfmap**
  The 2mFo-DFc and mFo-DFc map files respectively. Both are required if these are specified, and in that case
  the resolution must also be specified.

* **--reslo and --reshi**
  The low and high resolution for the specified map files.

* **--sampling-rate**
  The sampling rate to use when creating maps. Default is 1.5.

* **--recalc**
  By default the maps are read from the MTZ file, but you can also opt to recalculate the maps, e.g. when the
  structure no longer corresponds to the structure used to calculate the maps in the MTZ file.

* **--aniso-scaling**
  Accepted values for this option are none, observed and calculated. Used when recalculating maps.

* **--no-bulk**
  When specified, a bulk solvent mask is not used in recalculating the maps.

* **--compounds**
  Specify the path of the CCD file components.cif. By default the one installed by libcifpp is used, use this
  option to override this default.

* **--ccd-dict**
  A dictionary file in CCD format containing information for residues in this specific target. This option can
  be specified multiple times.

* **--restraint-dict**
  A file containing restraints for residues in this specific target, in CCP4 monomer library format. This option
  can be specified multiple times.

* **--mmcif-dictionary**
  Specify the path to the mmcif pdbx dictionary file. The default is to use the dictionary installed by libcifpp,
  use this option to override this default.

* **--electron-scattering**
  Use electron scattering factors instead of X-ray scattering factors.

* **--no-edia**
  Skip the EDIA score calculation.

* **--use-auth-ids**
  By default, when reading mmCIF files, the label_xxx_id is used in the edstats output. Use this flag to force
  output with the auth_xxx_ids.

* **--output-format**
  By default a JSON file is written, unless the filename ends with .eds. Use this option to force output in
  edstats or json format.

* **--output,-o**
  Write the output to this file instead of to stdout.

* **--quiet**
  Do not print any verbose output.

* **--verbose,-v**
  Be more verbose, useful to diagnose validation errors.

* **--version**
  Print version information and exit.

* **--help,-h**
  Display the help message and exit.

# References

References:
* Building and rebuilding N-glycans in protein structure models
  Van Beusekom, B. et al. (2019). Acta Cryst. D75, 416-425.
  DOI: 10.1107/S2059798319003875
* Statistical quality indicators for electron-density maps
  Tickle, I. J. (2012). Acta Cryst. D68, 454-467.
  DOI: 10.1107/S0907444911035918
* Estimating Electron Density Support for Individual Atoms and Molecular Fragments in X-ray Structures
  Meyder A., et al. (2017) Journal of Chemical Information and Modeling 57(10), 2437-2447.
  DOI: 10.1021/acs.jcim.7b00391

# Author

Written by Maarten L. Hekkelman &lt;[maarten@hekkelman.com](mailto:maarten@hekkelman.com)&gt;

# Reporting Bugs

Report bugs at <https://github.com/PDB-REDO/density-fitness/issues>
