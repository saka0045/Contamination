#!/usr/bin/env bash

##################################################
#Global Variables
##################################################

OUT_SAMPLE1_DIR=""
OUT_SAMPLE2_DIR=""
CONTAMINATED_FASTQ_DIR=""
READ=""
CONATAMINATED_FASTQ_SAMPLE_NAME=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
contaminate the R1 and R2 fastqs from two samples

OPTIONS:
    -h  [optional] help, show this message
    -a  [required] directory of sample 1 with concatenated R1 and R2 fastq
    -b  [required] directory of sample 2 with concatenated R1 and R2 fastq
    -o  [required] output directory to save the contaminated fastqs
    -r  [required] R1 or R2
    -f  [required] contaminated fastq sample name

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "ha:b:o:r:f:" OPTION
do
    case $OPTION in
        h) usage ; exit ;;
        a) OUT_SAMPLE1_DIR=${OPTARG} ;;
        b) OUT_SAMPLE2_DIR=${OPTARG} ;;
        o) CONTAMINATED_FASTQ_DIR=${OPTARG} ;;
        r) READ=${OPTARG} ;;
        f) CONATAMINATED_FASTQ_SAMPLE_NAME=${OPTARG} ;;
    esac
done

SAMPLE1_NAME=${OUT_SAMPLE1_DIR##*/}
SAMPLE2_NAME=${OUT_SAMPLE2_DIR##*/}

/bin/cat ${OUT_SAMPLE1_DIR}/${SAMPLE1_NAME}_${READ}.fastq ${OUT_SAMPLE2_DIR}/${SAMPLE2_NAME}_${READ}.fastq > \
${CONTAMINATED_FASTQ_DIR}/${CONATAMINATED_FASTQ_SAMPLE_NAME}_${READ}.fastq