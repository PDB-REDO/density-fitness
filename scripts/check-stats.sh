#!/bin/bash

density_fitness="../build/density-fitness --sampling-rate=2.2"

mkmap () {
	pdbid=$1
	grpid=${pdbid:1:2}

	# Fetch structure factors
	sfdir="/srv/data/pdb/structure_factors/$grpid"
	sf="$sfdir/r${pdbid}sf.ent.gz"
	
	if [ ! -f $sf ]; then
		mkdir -p "$sfdir";
		scp "bayes:/DATA/structure_factors/$grpid/r${pdbid}sf.ent.gz" $sfdir/
	fi
	
	cifdir="/srv/data/pdb/mmCIF/$grpid"
	cif="$cifdir/$pdbid.cif.gz"
	
	if [ ! -f $cif ]; then
		mkdir -p "$cifdir";
		scp "bayes:/DATA/mmCIF/$grpid/$pdbid.cif.gz" $cifdir/
	fi
	
	map=${pdbid}-mymap.mtz
	mtz-maker --hklin $sf --xyzin $cif --hklout $map
}

fetchmap () {
	pdbid=$1
	wget "http://www.ebi.ac.uk/pdbe/coordinates/files/${pdbid}_map.mtz"
}

eds () {
	hklin=$1
	xyzin=$2
	edsout=$3

	tmpdir=$(mktemp --directory ./mkmap-temp-XXXX)
	
	if [ ${hklin: -3:3} == ".gz" ]; then
		zcat $hklin > $tmpdir/${hklin%.gz}
		hklin=$tmpdir/${hklin%.gz}
	fi

	if [ ${xyzin: -3:3} == ".gz" ]; then
		zcat $xyzin > $tmpdir/${xyzin%.gz}
		xyzin=$tmpdir/${xyzin%.gz}
	fi
	
	edstats.pl -hklin $hklin -xyzin $xyzin -atomsf atomsf -output $tmpdir/edstats.out -debug

	if [ ! -f $tmpdir/edstats.out ]; then
		echo 'edstats failed!'
		exit
	fi

	perl fmt-eds.pl $tmpdir/edstats.out > $edsout
}

cmp-eds () {
	orig=$1
	redo=$2
	
	R --no-save --args . $orig $redo ${orig%.eds}-${redo%.eds}.svg < /srv/zata/tools/dRSCC.R
}

calc-stats () {
	pdb_file=$1
	mtz_file=${2:-${pdb_file%.pdb}.mtz}
	eds_file=${3:-${pdb_file%.pdb}.eds}

	echo ${density_fitness} --hklin $mtz_file --xyzin $pdb_file --output $eds_file --verbose
}

pdbid=$1
pdb_gz_file=pdb${pdbid}.ent.gz

if [ ! -f ${pdb_gz_file} ]; then
	pdb_gz_file=/srv/data/pdb/pdb/${pdbid:1:2}/pdb${pdbid}.ent.gz
fi

if [ ! -f ${pdb_gz_file} ] && [ -f /srv/data/pdb/mmCIF/${pdbid:1:2}/${pdbid}.cif.gz ]; then
	pdb_gz_file=pdb${pdbid}.ent.gz
	cif2pdb /srv/data/pdb/mmCIF/${pdbid:1:2}/${pdbid}.cif.gz ${pdb_gz_file}
fi

if [ ! -f ${pdb_gz_file} ]; then
	echo "PDB file $pdb_gz_file bestaat niet!\n"
	exit 1
fi

pdb_file=pdb${pdbid}.ent
if [ ! -f $pdb_file ]; then
	echo "Extracting $pdb_file"
	zcat ${pdb_gz_file} > $pdb_file
fi

mtz_file=${pdbid}_map.mtz
if [ ! -f $mtz_file ]; then
	echo "Fetching eds map"
	fetchmap $pdbid
fi

mtz_fix_file=${pdbid}-fix.mtz
if [ ! -f $mtz_fix_file ]; then
	mtzfix HKLIN $mtz_file HKLOUT $mtz_fix_file
	
	if [ $? != 0 ]; then
		echo mtzfix failed
		exit 1
	fi
	
	if [ ! -f $mtz_fix_file ]; then
		ln -s $mtz_file $mtz_fix_file
	fi
fi

args=$(mtzinfo $mtz_fix_file | perl -ne 'if (m/^XDATA/) { my @d=split(m/ +/); print "RESHI=$d[8],RESLO=$d[7]"}')

if [ ! -f fo.map ]; then
	echo 'LABI F1=FWT PHI=PHWT
	XYZL asu
	GRID samp 4.5' |fft HKLIN $mtz_fix_file MAPOUT fo.map |& tee fft-fo.log
fi

if [ ! -f df.map ]; then
	echo 'LABI F1=DELFWT PHI=PHDELWT
	XYZL asu
	GRID samp 4.5' |fft HKLIN $mtz_fix_file MAPOUT df.map |& tee fft-df.log
fi

eds_file=${pdbid}.eds
if [ ! -f $eds_file ]; then
	echo "Creating eds file with edstats"
	# echo $args | edstats MAPIN1 fo.map MAPIN2 df.map XYZIN $pdb_file PDBOUT /dev/null OUTPUT ${pdbid}-edstats.out

	eds ${mtz_file} ${pdb_file} ${eds_file}

	# if [ ! -f ${pdbid}-edstats.out ]; then
	# 	echo 'edstats failed!'
	# 	exit
	# fi

	# perl fmt-eds.pl ${pdbid}-edstats.out > $eds_file
fi

eds_file_mine=${pdbid}-mine.eds
if [ ! -f $eds_file_mine ]; then
	echo "Creating eds file with my stats"
	# ${density_fitness} --hklin $mtz_fix_file --xyzin $pdb_file -o $eds_file_mine --verbose
	${density_fitness} --hklin $mtz_file --xyzin $pdb_file -o $eds_file_mine --verbose
	# calc-stats ${mtz_file} ${pdb_file} ${eds_file_mine}
fi

echo "Vergelijk eds files"
cmp-eds $eds_file ${pdbid}-mine.eds
svg_file=${pdbid}-${pdbid}-mine.svg

perl plot-eds.pl $eds_file $eds_file_mine

# eds_file_mine_recalc=${pdbid}-mine-recalc.eds
# if [ ! -f $eds_file_mine_recalc ]; then
# 	echo "Creating eds file with my stats and recalculated maps"
# 	${density_fitness} --hklin $mtz_file --xyzin $pdb_file --recalc -o $eds_file_mine_recalc --verbose
# fi

# echo "Vergelijk eds files"
# cmp-eds $eds_file ${pdbid}-mine-recalc.eds
# svg_file=${pdbid}-${pdbid}-mine-recalc.svg

# #echo "Toon verschillen"
# #firefox $svg_file

# perl plot-eds.pl $eds_file $eds_file_mine_recalc
