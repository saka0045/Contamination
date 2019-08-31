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
Count the lines in the fastq file and divide by 4 to get the read count
Adds the total reads in all lanes for the read orientation (R1 or R2)

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
    echo "Counting lines in ${FQ_FILE}"
    FQ_ARR[${FQ_FILE##*/}]=$(/bin/zcat ${FQ_FILE} | /usr/bin/wc -l)
done

TOTAL_READS_SAMPLE=0
for KEY in ${!FQ_ARR[@]}; do
    echo "lines in ${KEY} is ${FQ_ARR[${KEY}]}"
    COUNT=$((${FQ_ARR[${KEY}]} / 4 ))
    echo "number of reads in ${KEY} is ${COUNT}"
    echo "${KEY}=${COUNT}" >> ${RESULT_FILE}
    TOTAL_READS_SAMPLE=$((${TOTAL_READS_SAMPLE}+${COUNT}))
done

echo "TOTAL_READS_SAMPLE_${READ}=${TOTAL_READS_SAMPLE}" >> ${RESULT_FILE}
