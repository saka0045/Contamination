#!/bin/bash

##################################################
#Global Variables
##################################################

OUTDIR=""
RESULT_FILE=""
FASTQ_FILE=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
concatenates fastq files from all lanes, but separate out by
different reads

OPTIONS:
    -h  [optional] help, show this message
    -o  [required] output directory
    -f  [required] fastq file to count
    -r  [required] result file to write the results

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "ho:f:r:" OPTION
do
    case $OPTION in
        h) usage ; exit ;;
        o) OUTDIR=${OPTARG} ;;
		f) FASTQ_FILE=${OPTARG} ;;
		r) RESULT_FILE=${OPTARG} ;;
    esac
done

/bin/cat ${OUTDIR}/${FASTQ_FILE} | /usr/bin/wc -l >> ${RESULT_FILE}
