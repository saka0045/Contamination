#!/bin/bash

##################################################
#Global Variables
##################################################

INPUT_DIR=""
SCRIPT_DIR=""
OUTDIR=""
LOG_DIR=""
SAMPLE_NAME=""
R1_RESULT_FILE=""
R2_RESULT_FILE=""
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
    -i  [required] input directory for sample
    -o  [required] output directory

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hi:o:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		i) INPUT_DIR=${OPTARG} ;;
		o) OUTDIR=${OPTARG} ;;
    esac
done

if [[ -z $INPUT_DIR ]]; then
    echo -e "ERROR: -i option is required\n"
    exit 1
fi

if [[ -z $OUTDIR ]]; then
    echo -e "ERROR: -o option is required\n"
    exit 1
fi

# Directory of script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

#Get sample1 name
SAMPLE_NAME=${INPUT_DIR##*/}
R1_FASTQ=${SAMPLE_NAME}_combined_R1.temp.fastq
R2_FASTQ=${SAMPLE_NAME}_combined_R2.temp.fastq
echo "Sample name: $SAMPLE_NAME"

# Make directory under ${OUTDIR} with ${SAMPLE_NAME} if it doesn't exist
OUTDIR=${OUTDIR}/${SAMPLE_NAME}
if [[ -d ${OUTDIR} ]]; then
    echo "Output directory ${OUTDIR} already exists!"
    echo "Aborting script"
    exit 1
else
    mkdir ${OUTDIR}
    echo "Creating output directory ${OUTDIR}"
fi

# Make directory for log files if it doesn't exist already
LOG_DIR=${OUTDIR}/logs
if [[ ! -d "${LOG_DIR}" ]]; then
    mkdir ${LOG_DIR}
    echo "Making logs directory at: ${LOG_DIR}"
else
    echo "Log directory ${LOG_DIR} already exists, skipping creation of log directory"
fi

# Process R1 fastqs
echo "Processing R1 fastqs in directory: $INPUT_DIR"
find $INPUT_DIR -maxdepth 1 -name "*R1*.fastq.gz" | sort
echo "Saving concatenated fastq file at: $OUTDIR/${R1_FASTQ}"
CMD="qsub -V -m abe -M sakai.yuta@mayo.edu -wd ${LOG_DIR} -q sandbox.q -N concatenateR1Fastq ${SCRIPT_DIR}/concatenate_fastq.sh -d ${INPUT_DIR} -o ${OUTDIR} -r R1 -f ${R1_FASTQ}"
echo "Executing command: ${CMD}"
${CMD}

# Process R2 fastqs
echo "Processing R2 fastqs in directory: ${INPUT_DIR}"
find $INPUT_DIR -maxdepth 1 -name "*R2*.fastq.gz" | sort
echo "Saving concatenated fastq file at: $OUTDIR/${R2_FASTQ}"
CMD="qsub -V -m abe -M sakai.yuta@mayo.edu -wd ${LOG_DIR} -q sandbox.q -N concatenateR2Fastq ${SCRIPT_DIR}/concatenate_fastq.sh -d ${INPUT_DIR} -o ${OUTDIR} -r R2 -f ${R2_FASTQ}"
echo "Executing command: ${CMD}"
${CMD}

# Make result file
R1_RESULT_FILE=${OUTDIR}/${SAMPLE_NAME}_combined_R1_fastq_results.txt
touch ${R1_RESULT_FILE}
echo "Line count for ${R1_FASTQ}:" >> ${R1_RESULT_FILE}

# qsub and count the lines in the R1 fastq file
echo "Counting lines in ${R1_FASTQ}"
# wait for concatenateFastq to finish before qsubbing this
CMD="qsub -hold_jid concatenateR1Fastq -V -m abe -M sakai.yuta@mayo.edu -wd ${LOG_DIR} -q sandbox.q -N countR1FastqLine ${SCRIPT_DIR}/count_fastq_lines.sh -o ${OUTDIR} -f ${R1_FASTQ} -r ${R1_RESULT_FILE}"
echo "Executing command: ${CMD}"
${CMD}

# Entry for R2
R2_RESULT_FILE=${OUTDIR}/${SAMPLE_NAME}_combined_R2_fastq_results.txt
touch ${R2_RESULT_FILE}
echo "Line count for ${R2_FASTQ}:" >> ${R2_RESULT_FILE}

# qsub and count the lines in the R2 fastq file
echo "Counting lines in ${R2_FASTQ}"
# wait for concatenateFastq to finish before qsubbing this
CMD="qsub -hold_jid concatenateR2Fastq -V -m abe -M sakai.yuta@mayo.edu -wd ${LOG_DIR} -q sandbox.q -N countR2FastqLine ${SCRIPT_DIR}/count_fastq_lines.sh -o ${OUTDIR} -f ${R2_FASTQ} -r ${R2_RESULT_FILE}"
echo "Executing command: ${CMD}"
${CMD}
