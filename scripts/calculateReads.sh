#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

OUTDIR=""
SAMPLE1_NAME=""
SAMPLE2_NAME=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF


OPTIONS:
    -h  [optional] help, show this message
    -o  [required] output directory where {Sample}.results.txt is from countFastqFile.sh
    -a  [required] sample 1 name
    -b  [required] sample 2 name

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "ho:a:b:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		o) OUTDIR=${OPTARG} ;;
		a) SAMPLE1_NAME=${OPTARG} ;;
		b) SAMPLE2_NAME=${OPTARG} ;;
    esac
done

# Define variables
RESULT1_FILE=${OUTDIR}/${SAMPLE1_NAME}.results.txt
RESULT2_FILE=${OUTDIR}/${SAMPLE2_NAME}.results.txt

source ${RESULT1_FILE}
source ${RESULT2_FILE}

echo "${TOTAL_READS_SAMPLE_R1}"