#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

declare -A FQ_ARR
SAMPLE_DIR=""
READ=""
RESULT_FILE=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
concatenates fastq files from all lanes, but separate out by
different reads

OPTIONS:
    -h  [optional] help, show this message
    -s  [required] sample directory
    -r  [required] R1 or R2
    -f  [required] path to result file

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hs:r:f:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		s) SAMPLE_DIR=${OPTARG} ;;
		r) READ=${OPTARG} ;;
		f) RESULT_FILE=${OPTARG} ;;
    esac
done

# Count lines in fastq file for SAMPLE1_DIR
for FQ_FILE in ${SAMPLE_DIR}/*${READ}*.fastq.gz; do
    echo "Counting lines in ${FQ_FILE}" >> ${RESULT_FILE}
    FQ_ARR[${FQ_FILE##*/}]=$(/bin/zcat ${FQ_FILE} | /usr/bin/wc -l)
done

TOTAL_READS_SAMPLE=0
for KEY in ${!FQ_ARR[@]}; do
    COUNT=${FQ_ARR[${KEY}]}
    echo "${KEY}=${COUNT}" >> ${RESULT_FILE}
    TOTAL_READS_SAMPLE=$((${TOTAL_READS_SAMPLE}+${COUNT}))
done

echo "TOTAL_READS_SAMPLE_${READ}=${TOTAL_READS_SAMPLE}" >> ${RESULT_FILE}