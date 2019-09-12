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

##################################################
#Global Variables
##################################################

R1File=""
R2File=""
REFERENCE=""
SampleName=""
SortFlag=""
LANE=""

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hi:f:r:s:n:l:" OPTION
do
    case $OPTION in
        h) usage ; exit ;;
        i) R1File=${OPTARG} ;;
        f) R2File=${OPTARG} ;;
        r) REFERENCE=${OPTARG} ;;
        s) SampleName=${OPTARG} ;;
        n) SortFlag=${OPTARG} ;;
        l) LANE=${OPTARG} ;;
    esac
done

if [[ ! -z "${R2File}" ]]; then
	echo "Using $R1File $R2File and $REFERENCE for $SampleName ${LANE}"

	/biotools/biotools/sentieon/201808.03/bin/bwa mem -R "@RG\tID:${SampleName}\tPU:ILLUMINA\tSM:${SampleName}\tPL:ILLUMINA\tLB:LIB\tCN:CGSL" -K 10000000 -t 32 \
	${REFERENCE} ${R1File} ${R2File} | /usr/local/biotools/samtools/1.3/samtools view -bS > ${SampleName}_${LANE}_unsorted.bam

	if [[ "${SortFlag}" = "NAME" ]]; then
		/usr/local/biotools/samtools/1.3/samtools sort -n -o ${SampleName}_${LANE}.bam ${SampleName}_${LANE}_unsorted.bam
	else
		/usr/local/biotools/samtools/1.3/samtools sort -o ${SampleName}_${LANE}.bam ${SampleName}_${LANE}_unsorted.bam
	fi

	#/usr/local/biotools/samtools/1.3/samtools index ${SampleName}.bam
else
	/biotools/biotools/sentieon/201808.03/bin/bwa mem -R "@RG\tID:${SampleName}\tPU:ILLUMINA\tSM:${SampleName}\tPL:ILLUMINA\tLB:LIB\tCN:CGSL" -K 10000000 -t 32 \
	${REFERENCE} ${R1File} | /usr/local/biotools/samtools/1.3/samtools view -bS > ${SampleName}_junctions_unsorted.bam
	/usr/local/biotools/samtools/1.3/samtools sort -o ${SampleName}_junctions.bam ${SampleName}_junctions_unsorted.bam
	
fi
