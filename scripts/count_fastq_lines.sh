#!/bin/bash

##################################################
#Global Variables
##################################################

OUTDIR=""
RESULTFILE=""
R1FASTQ=""

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

while getopts "ho:f:r:" OPTION
do
    case $OPTION in
        h) usage ; exit ;;
        o) OUTDIR=${OPTARG} ;;
		f) R1FASTQ=${OPTARG} ;;
		r) RESULTFILE=${OPTARG} ;;
    esac
done

/bin/cat ${OUTDIR}/${R1FASTQ} | /usr/bin/wc -l >> ${RESULTFILE}
