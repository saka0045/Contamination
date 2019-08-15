#!/bin/bash

##################################################
#Global Variables
##################################################

DIR=""
OUTDIR=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
concatenates fastq files from all lanes, but separate out by
different reads

OPTIONS:
    -h  [optional] help, show this message
    -d  [required] input directory
    -o  [required] output directory

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hd:o:" OPTION
do
    case $OPTION in
        h) usage ; exit ;;
        d) DIR=${OPTARG} ;;
        o) OUTDIR=${OPTARG} ;;
    esac
done

if [[ -z $DIR ]]; then
    echo -e "ERROR: -d option is required\n"
    exit 1
fi

if [[ -z $OUTDIR ]]; then
    echo -e "ERROR: -o option is required\n"
    exit 1
fi

SAMPLENAME=${DIR##*/}
R1FASTQ=${SAMPLENAME}_combined_R1.fastq

/bin/find $DIR -maxdepth 1 -name "*R1*.fastq.gz" | /bin/sort | xargs /bin/zcat > ${OUTDIR}/${R1FASTQ}
