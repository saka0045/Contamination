#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

INPUT_DIR=""
SAMPLE_NAME=""
CMD=""
QDIR="/usr/local/biotools/oge/ge2011.11/bin/linux-x64"
QSUB="${QDIR}/qsub"
QSTAT="${QDIR}/qstat"
SCRIPT_DIR="/dlmp/sandbox/cgslIS/Yuta/Contamination/scripts"

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
command to qsub and run just the Sentieon BWA
This script will align, merge and sort the BAM

OPTIONS:
    -h  [optional] help, show this message
    -i  [required] input directory, must have a BAM file in this directory
    -s  [required] sample name, must match the sample name in the BAM file

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hi:s:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		i) INPUT_DIR=${OPTARG} ;;
		s) SAMPLE_NAME=${OPTARG} ;;
    esac
done

INPUT_DIR=${INPUT_DIR%/}
LOG_DIR=${INPUT_DIR}/logs
QSUB_ARGS="-terse -V -q sandbox.q -m abe -M sakai.yuta@mayo.edu -o ${LOG_DIR} -j y"

# Make logs directory if it doesn't exist
if [[ ! -d "${LOG_DIR}" ]]; then
    mkdir ${LOG_DIR}
    echo "Making logs directory at: ${LOG_DIR}"
else
    echo "Log directory ${LOG_DIR} already exists, skipping creation of log directory"
fi

CMD="${QSUB} ${QSUB_ARGS} -wd ${INPUT_DIR} ${SCRIPT_DIR}/runSenteionBwa.sh -i ${INPUT_DIR} -s ${SAMPLE_NAME}"
echo "Executing command: ${CMD}"
${CMD}