#!/usr/bin/env bash

##################################################
#Global Variables
##################################################

SAMTOOLS="/usr/local/biotools/samtools/1.3/samtools"
SAMPLENAME=""
IN_BAM1=""
IN_BAM2=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
contaminate the R1 and R2 fastqs from two samples

OPTIONS:
    -h  [optional] help, show this message
    -a  [required] directory of first BAM
    -b  [required] directory of second BAM
    -s  [required] sample name

EOF
}

##################################################
##BEGIN PROCESSING
###################################################

while getopts "ha:b:s:" OPTION
do
    case $OPTION in
        h) usage ; exit ;;
        a) IN_BAM1=${OPTARG} ;;
        b) IN_BAM2=${OPTARG} ;;
        s) SAMPLENAME=${OPTARG} ;;
    esac
done

${SAMTOOLS} merge ${SAMPLENAME}.bam ${IN_BAM1} ${IN_BAM2}
${SAMTOOLS} index ${SAMPLENAME}.bam