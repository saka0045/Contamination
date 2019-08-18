#!/bin/bash

##################################################
#Global Variables
##################################################

SAMPLE1_DIR=""
SCRIPT_DIR=""
OUTDIR=""
SAMPLE1_NAME=""
R1_RESULT1_FILE=""
R2_RESULT1_FILE=""
R1_FASTQ=""
CMD=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
concatenates fastq files from all lanes, but separate out by
different reads

OPTIONS:
    -h  [optional] help, show this message
    -a  [required] input directory for sample 1
    -o  [required] output directory

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "ha:o:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		a) SAMPLE1_DIR=${OPTARG} ;;
		o) OUTDIR=${OPTARG} ;;
    esac
done

if [[ -z $SAMPLE1_DIR ]]; then
    echo -e "ERROR: -a option is required\n"
    exit 1
fi

if [[ -z $OUTDIR ]]; then
    echo -e "ERROR: -o option is required\n"
    exit 1
fi

# Directory of script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#Get sample1 name
SAMPLE1_NAME=${SAMPLE1_DIR##*/}
R1_FASTQ=${SAMPLE1_NAME}_combined_R1.temp.fastq
R2_FASTQ=${SAMPLE1_NAME}_combined_R2.temp.fastq
echo "Sample name: $SAMPLE1_NAME"

# Process R1 fastqs
echo "Processing R1 fastqs in directory: $SAMPLE1_DIR"
find $SAMPLE1_DIR -maxdepth 1 -name "*R1*.fastq.gz" | sort
echo "Saving concatenated fastq file at: $OUTDIR/${R1_FASTQ}"
CMD="qsub -V -m abe -M sakai.yuta@mayo.edu -wd ${OUTDIR} -q sandbox.q -N concatenateR1Fastq ${SCRIPT_DIR}/concatenate_fastq.sh -d ${SAMPLE1_DIR} -o ${OUTDIR} -r R1 -f ${R1_FASTQ}"
echo "Executing command: ${CMD}"
${CMD}

# Process R2 fastqs
echo "Processing R2 fastqs in directory: ${SAMPLE1_DIR}"
find $SAMPLE1_DIR -maxdepth 1 -name "*R2*.fastq.gz" | sort
echo "Saving concatenated fastq file at: $OUTDIR/${R2_FASTQ}"
CMD="qsub -V -m abe -M sakai.yuta@mayo.edu -wd ${OUTDIR} -q sandbox.q -N concatenateR2Fastq ${SCRIPT_DIR}/concatenate_fastq.sh -d ${SAMPLE1_DIR} -o ${OUTDIR} -r R2 -f ${R2_FASTQ}"
echo "Executing command: ${CMD}"
${CMD}

# Make result file
R1_RESULT1_FILE=${OUTDIR}/${SAMPLE1_NAME}_combined_R1_fastq_results.txt
touch ${R1_RESULT1_FILE}
echo "Line count for ${R1_FASTQ}:" >> ${R1_RESULT1_FILE}

# qsub and count the lines in the R1 fastq file
echo "Counting lines in ${R1_FASTQ}"
# wait for concatenateFastq to finish before qsubbing this
CMD="qsub -hold_jid concatenateR1Fastq -V -m abe -M sakai.yuta@mayo.edu -wd ${OUTDIR} -q sandbox.q -N countR1FastqLine ${SCRIPT_DIR}/count_fastq_lines.sh -o ${OUTDIR} -f ${R1_FASTQ} -r ${R1_RESULT1_FILE}"
echo "Executing command: ${CMD}"
${CMD}

# Entry for R2
R2_RESULT1_FILE=${OUTDIR}/${SAMPLE1_NAME}_combined_R2_fastq_results.txt
touch ${R2_RESULT1_FILE}
echo "Line count for ${R2_FASTQ}:" >> ${R2_RESULT1_FILE}

# qsub and count the lines in the R2 fastq file
echo "Counting lines in ${R2_FASTQ}"
# wait for concatenateFastq to finish before qsubbing this
CMD="qsub -hold_jid concatenateR2Fastq -V -m abe -M sakai.yuta@mayo.edu -wd ${OUTDIR} -q sandbox.q -N countR2FastqLine ${SCRIPT_DIR}/count_fastq_lines.sh -o ${OUTDIR} -f ${R2_FASTQ} -r ${R2_RESULT1_FILE}"
echo "Executing command: ${CMD}"
${CMD}
