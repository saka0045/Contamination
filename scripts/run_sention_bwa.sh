#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

INPUT_DIR=""
REFERENCE_FASTA="/dlmp/misc-data/pipelinedata/deployments/mgc/bwa/GRCh37/hs37d5.fa"
OUTDIR=""
SAMPLE_NAME=""
CMD=""
QDIR="/usr/local/biotools/oge/ge2011.11/bin/linux-x64"
QSUB="${QDIR}/qsub"
QSTAT="${QDIR}/qstat"
SENTIEON_ARGS="-v SENTIEON_LICENSE=dlmpcim03.mayo.edu:8990 -l h_vmem=50G -N sentieonBwa"
SCRIPT_DIR="/dlmp/sandbox/cgslIS/Yuta/Contamination/scripts"
ALIGNMENT_JOBS=()
REFERENCE_GENOME="/dlmp/misc-data/pipelinedata/deployments/mgc/bwa/GRCh37/hs37d5.fa"

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

function waitForJob () {
    local WAIT_TIME=0
    local MAX_WAIT=${2:-10800}
    local SLEEP_TIME=${3:-120}

    local JOB_ID="${1}"
    local JOB_RUNNING=$(${QSTAT} -u '*' | gawk -F " " -v JID="${JOB_ID}" '$1==JID{print $1}')

    echo "Waiting for grid job ${JOB_ID} to complete. MAX_WAIT: ${MAX_WAIT}"

    while [[ ${JOB_RUNNING} != "" ]]
    do
        if [[ ${WAIT_TIME} -gt ${MAX_WAIT} ]]; then
            echo "Job processing exceeded timeout value. Job ID: ${JOB_ID}" ${ERR_GENERAL}
            exit ${ERR_GENERAL}
        fi

        QSTS=$(${QSTAT} -u '*' | grep ${JOB_ID} || true)
        QSTS=$(echo ${QSTS} | tr -s ' ' | cut -f5 -d " ")
        if [[ ${QSTS} == "Eqw" ]]; then
            echo "QSTAT indicates job ${JOB_ID} failed." ${ERR_GENERAL}
            exit ${ERR_GENERAL}
        fi

        # echo "Sleeping for ${SLEEP_TIME} seconds"
        sleep ${SLEEP_TIME}
        WAIT_TIME=$(($WAIT_TIME + $SLEEP_TIME))

        JOB_RUNNING=$(${QSTAT} -u '*' | gawk -F " " -v JID="${JOB_ID}" '$1==JID{print $1}')
    done
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

# Align LOO1 fastq files using Jag's script
CMD="${QSUB} ${QSUB_ARGS} ${SENTIEON_ARGS} -wd ${INPUT_DIR} ${SCRIPT_DIR}/sentieon_bwa.sh -i ${INPUT_DIR}/${SAMPLE_NAME}_L001_R1.fastq \
-f ${INPUT_DIR}/${SAMPLE_NAME}_L001_R2.fastq -r ${REFERENCE_GENOME} -s ${SAMPLE_NAME} -n COORD -l L001"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})
ALIGNMENT_JOBS+=("${JOB_ID}")
echo "ALIGNMENT_JOBS+=${JOB_ID}"

# Align LOO2 fastq files using Jag's script
CMD="${QSUB} ${QSUB_ARGS} ${SENTIEON_ARGS} -wd ${INPUT_DIR} ${SCRIPT_DIR}/sentieon_bwa.sh -i ${INPUT_DIR}/${SAMPLE_NAME}_L002_R1.fastq \
-f ${INPUT_DIR}/${SAMPLE_NAME}_L002_R2.fastq -r ${REFERENCE_GENOME} -s ${SAMPLE_NAME} -n COORD -l L002"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})
ALIGNMENT_JOBS+=("${JOB_ID}")
echo "ALIGNMENT_JOBS+=${JOB_ID}"

for JOB_ID in ${ALIGNMENT_JOBS[@]:-}; do
    waitForJob ${JOB_ID} 86400 60
done

# Merge and index BAMs
CMD="${QSUB} ${QSUB_ARGS} -wd ${INPUT_DIR} -N mergeAndIndexBams ${SCRIPT_DIR}/mergeAndIndexBams.sh -a ${SAMPLE_NAME}_L001.bam \
-b ${SAMPLE_NAME}_L002.bam -s ${SAMPLE_NAME}"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})

waitForJob ${JOB_ID} 86400 60

BAM_FILE="${INPUT_DIR}/${SAMPLE_NAME}.bam"
echo "Created BAM file: ${BAM_FILE}"