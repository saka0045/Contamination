#!/usr/bin/env bash

##################################################
#Global Variables
##################################################

INPUT_FASTQ=""
OUT_FASTQ=""
SEED=""
READS=""
CMD=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
concatenates fastq files from all lanes, but separate out by
different reads

OPTIONS:
    -h  [optional] help, show this message
    -i  [required] full path to input fastq file
    -o  [required] full path to output fastq file
    -s  [required] random seed number
    -r  [required] number of reads to subset to

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hi:o:s:r:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		i) INPUT_FASTQ=${OPTARG} ;;
		o) OUT_FASTQ=${OPTARG} ;;
		s) SEED=${OPTARG} ;;
		r) READS=${OPTARG} ;;
    esac
done

/usr/local/biotools/seqtk/1.3-r106/seqtk sample -s ${SEED} ${INPUT_FASTQ} ${READS} > ${OUT_FASTQ}
