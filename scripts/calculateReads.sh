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

# If sample name contained "-", the script will not work, below replaces the "-" with "_"
ALTERED_SAMPLE1_NAME=${SAMPLE1_NAME//-/_}
ALTERED_SAMPLE2_NAME=${SAMPLE2_NAME//-/_}
sed -i -e 's/-/_/g' ${RESULT1_FILE}
sed -i -e 's/-/_/g' ${RESULT2_FILE}

source ${RESULT1_FILE}
source ${RESULT2_FILE}


# Calculate the total reads for Sample 1
echo "total reads R1 = ${TOTAL_READS_006_D01S_R1}"