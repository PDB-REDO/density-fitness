density-fitness
===============

This is the repository for density-fitness, an application to calculate density statisctics. This program is part of the [PDB-REDO](https://pdb.redo.eu/) suite
of programs.

Installation
------------

To install, first install  [`libcifpp`](https://github.com/PDB-REDO/libcifpp) and [`libpdb-redo`](https://github.com/PDB-REDO/libpdb-redo) then use

```
./configure
make
sudo make install
```


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
  The coordinates file in either PDB or mmCIF format. This file may be compressed
  with gzip or bzip2.
  **--fomap** and **--dfmap**
  The _2mFo-DFc_ and _mFo-DFc_ map files respectively. Both are required
  and if these are specified, the resolution **must** also be specified.
* **--reslo** and **--reshi**
  The low and high resolution for the specied map files.
* **--hklin**
  The MTZ file. If this option is specified, the maps will be calculated using
  the information in this file.
* **--sampling-rate**
  The sampling rate to use when creating maps. Default is 0.75.
* **--recalc**
  By default the maps are read from the MTZ file, but you can also opt to
  recalculate the maps, e.g. when the structure no longer corresponds to
  the structure used to calculate the maps in the MTZ file.
* **--aniso-scaling**
  Accepted values for this option are _observed_ and _calculated_ or _none_.
  Used when recalculating maps.
* **--no-bulk**
  When specified, a bulk solvent mask is not used in recalculating the maps.
* **--dict**=&lt;file&gt;
  Dictionary file containing restraints for residues in this specific target.
* **--no-validate**
  Omit the validation of the input mmCIF file. This will force output even in
  case the input file contains errors.
* **--electron-scattering**
  Use electron scattering factors instead of X-ray scattering factors.
* **--use-auth-ids**
  By default, when reading mmCIF files, the label_xxx_id is used in the
  edstats output. Use this flag to force output with the auth_xxx_ids.
* **--output-format**
  By default a JSON file is written, unless the filename ends with .eds.
  Use this option to force output in _edstats_ or _json_ format.
* **--verbose**,**-V**
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

Report bugs at https://github.com/PDB-REDO/density-fitness/issues
