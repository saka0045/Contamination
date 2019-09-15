#!/usr/bin/env bash

##################################################
#Global Variables
##################################################

OUT_SAMPLE1_DIR=""
OUT_SAMPLE2_DIR=""
CONTAMINATED_FASTQ_DIR=""
READ=""
CONATAMINATED_FASTQ_SAMPLE_NAME=""
LANE=""
SAMPLE1_NAME=""
SAMPLE2_NAME=""

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
    -l  [required] lane; L001, L002, etc.

EOF
}

##################################################
##BEGIN PROCESSING
###################################################

while getopts "ha:b:o:r:f:l:" OPTION
do
    case $OPTION in
        h) usage ; exit ;;
        a) SAMPLE1_NAME=${OPTARG} ;;
        b) SAMPLE2_NAME=${OPTARG} ;;
        o) CONTAMINATED_FASTQ_DIR=${OPTARG} ;;
        r) READ=${OPTARG} ;;
        f) CONATAMINATED_FASTQ_SAMPLE_NAME=${OPTARG} ;;
        l) LANE=${OPTARG} ;;
    esac
done

/bin/cat ${CONTAMINATED_FASTQ_DIR}/${SAMPLE1_NAME}_${LANE}_${READ}*.fastq ${CONTAMINATED_FASTQ_DIR}/${SAMPLE2_NAME}_${LANE}_${READ}*.fastq > \
${CONTAMINATED_FASTQ_DIR}/${CONATAMINATED_FASTQ_SAMPLE_NAME}_${LANE}_${READ}.fastq