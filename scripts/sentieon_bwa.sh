#!/bin/bash

read -r -d '' DOCS <<DOCS
usage: $0 options

  Delivers the run

  OPTIONS:
	-i is R1 file
        -f is R2 file
        -r is reference , i.e /dlmp/misc-data/pipelinedata/deployments/mgc/bwa/GRCh37/human_g1k_v37.fa
        -s samplename
	

# This script acts as a wrapper for the predict_msi script. Given a run directory,
# it run msi and yield probability file. Certain files must exist in the
# directories passed in. If any files are not present, the script will end. The script ensures all output
# of the ggps is placed in a particular location in the run directory.
#
#
# @input param -i sample Directory. (Required parameter).
# 
DOCS

#REFERENCE=/dlmp/misc-data/pipelinedata/deployments/mgc/bwa/GRCh37/human_g1k_v37.fa


while getopts "hi:f:r:s:n:" OPTION
do
	case $OPTION in
		h) echo "${DOCS}" ; exit ;;
		i) declare -r R1File=`readlink -f "$OPTARG"` ;;
		f) declare -r R2File=`readlink -f "$OPTARG"` ;;
		r) declare -r REFERENCE=`readlink -f "$OPTARG"` ;;
		s) declare -r SampleName=`readlink -f "$OPTARG"` ;;
		n) declare -r SortFlag="$OPTARG" ;;
		?) usage ; exit ;;
	esac
done

if [[ ! -z "${R2File}" ]]; then
	echo "Using $R1File $R2File and $REFERENCE for $SampleName $LaneName"

	/biotools/biotools/sentieon/201808.03/bin/bwa mem -R "@RG\tID:${SampleName}\tPU:ILLUMINA\tSM:${SampleName}\tPL:ILLUMINA\tLB:LIB\tCN:CGSL" -K 10000000 -t 32 \
	${REFERENCE} ${R1File} ${R2File} | /usr/local/biotools/samtools/1.3/samtools view -bS > ${SampleName}_unsorted.bam

	if [[ "${SortFlag}" = "NAME" ]]; then
		/usr/local/biotools/samtools/1.3/samtools sort -n -o ${SampleName}.bam ${SampleName}_unsorted.bam
		/usr/local/biotools/samtools/1.3/samtools index ${SampleName}.bam
	else
		/usr/local/biotools/samtools/1.3/samtools sort -o ${SampleName}.bam ${SampleName}_unsorted.bam
		/usr/local/biotools/samtools/1.3/samtools index ${SampleName}.bam
	fi

	#/usr/local/biotools/samtools/1.3/samtools index ${SampleName}.bam
else
	/biotools/biotools/sentieon/201808.03/bin/bwa mem -R "@RG\tID:${SampleName}\tPU:ILLUMINA\tSM:${SampleName}\tPL:ILLUMINA\tLB:LIB\tCN:CGSL" -K 10000000 -t 32 \
	${REFERENCE} ${R1File} | /usr/local/biotools/samtools/1.3/samtools view -bS > ${SampleName}_junctions_unsorted.bam
	/usr/local/biotools/samtools/1.3/samtools sort -o ${SampleName}_junctions.bam ${SampleName}_junctions_unsorted.bam
	/usr/local/biotools/samtools/1.3/samtools index ${SampleName}_junctions.bam
	
fi
