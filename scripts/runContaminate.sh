#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

declare -A FQ_ARR2
SAMPLE1_DIR=""
SAMPLE2_DIR=""
OUTDIR=""
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
    -i  [required] input directory for sample 1
    -d  [required] input directory for sample 2
    -o  [required] output directory

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

        echo "Sleeping for ${SLEEP_TIME} seconds"
        sleep ${SLEEP_TIME}
        WAIT_TIME=$(($WAIT_TIME + $SLEEP_TIME))

        JOB_RUNNING=$(${QSTAT} -u '*' | gawk -F " " -v JID="${JOB_ID}" '$1==JID{print $1}')
    done
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

# Define variables
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
QDIR="/usr/local/biotools/oge/ge2011.11/bin/linux-x64"
QSUB="${QDIR}/qsub"
QSTAT="${QDIR}/qstat"
QSUB_ARGS="-terse -V -q sandbox.q -m abe -M sakai.yuta@mayo.edu -wd ${OUTDIR} -j y"
ERR_GENERAL=1
RESULT_FILE=${OUTDIR}/arrayResults.txt
COUNT_FASTQ_JOBS=()

#Process first sample R1 fastq files
CMD="${QSUB} ${QSUB_ARGS} -N countFastq ${SCRIPT_DIR}/countFastqFile.sh -s ${SAMPLE1_DIR} -r R1 -f ${RESULT_FILE}"
echo "CMD=${CMD}"
JOB_ID=$(${CMD})
COUNT_FASTQ_JOBS+=("${JOB_ID}")
echo "COUNT_FASTQ_JOBS+=${JOB_ID}"

#Process first sample R2 fastq files
CMD="${QSUB} ${QSUB_ARGS} -N countFastq ${SCRIPT_DIR}/countFastqFile.sh -s ${SAMPLE1_DIR} -r R2 -f ${RESULT_FILE}"
echo "CMD=${CMD}"
JOB_ID=$(${CMD})
COUNT_FASTQ_JOBS+=("${JOB_ID}")
echo "COUNT_FASTQ_JOBS+=${JOB_ID}"

for JOB_ID in ${COUNT_FASTQ_JOBS:-}; do
    waitForJob ${JOB_ID} 10800 10
done

echo "script is done running!"
