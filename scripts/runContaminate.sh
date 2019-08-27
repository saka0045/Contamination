#!/usr/bin/env bash

##################################################
#DEFAULT VALUES
##################################################

declare -A FQ_ARR1
declare -A FQ_ARR2

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
concatenates fastq files from all lanes, but separate out by
different reads

OPTIONS:
    -h  [optional] help, show this message
    -i  [required] input directory for sample 1
    -d  [required] input directory for sample 2
    -o  [required] output directory

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hi:d:o:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		i) SAMPLE1_DIR=${OPTARG} ;;
		d) SAMPLE2_DIR=${OPTARG} ;;
		o) OUTDIR=${OPTARG} ;;
    esac
done

if [[ -z ${SAMPLE1_DIR} ]]; then
    echo -e "ERROR: -i option is required\n"
    exit 1
fi

if [[ -z ${SAMPLE2_DIR} ]]; then
    echo -e "Error: -d option is required"
    exit 1
fi

if [[ -z ${OUTDIR} ]]; then
    echo -e "ERROR: -o option is required\n"
    exit 1
fi

# Directory of script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Count lines in fastq file for SAMPLE1_DIR
for FQ_FILE in ${SAMPLE1_DIR}/*R1*.fastq.gz; do
    FQ_ARR1[${FQ_FILE##*/}]=$(qsub -V -m abe -M sakai.yuta@mayo.edu -q sandbox.q -N countFastq1 -wd ${OUTDIR} \
    ${SCRIPT_DIR}/countFastqFile.sh -f ${FQ_FILE})
done

for KEY in ${!FQ_ARR1[@]}; do
    echo ${KEY} ${FQ_ARR1[${KEY}]}
done