#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

SAMPLE1_DIR=""
SAMPLE2_DIR=""
OUTDIR=""
CMD=""
BC="/usr/bin/bc"
SCRIPT_DIR="/dlmp/sandbox/cgslIS/Yuta/Contamination/scripts"
QDIR="/usr/local/biotools/oge/ge2011.11/bin/linux-x64"
QSUB="${QDIR}/qsub"
QSTAT="${QDIR}/qstat"
SAMPLE1_PERCENT=""

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
    -b  [required] input directory for sample 2
    -o  [required] output directory
    -p  [required] percent (0-100) of sample 1 used to contaminate with sample 2

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "ha:b:o:p:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		a) SAMPLE1_DIR=${OPTARG} ;;
		b) SAMPLE2_DIR=${OPTARG} ;;
		o) OUTDIR=${OPTARG} ;;
		p) SAMPLE1_PERCENT=${OPTARG} ;;
    esac
done

if [[ -z ${SAMPLE1_DIR} ]]; then
    echo -e "ERROR: -a option is required\n"
    exit 1
fi

if [[ -z ${SAMPLE2_DIR} ]]; then
    echo -e "Error: -b option is required"
    exit 1
fi

if [[ -z ${OUTDIR} ]]; then
    echo -e "ERROR: -o option is required\n"
    exit 1
fi

if [[ -z ${SAMPLE1_PERCENT} ]]; then
    echo -e "ERROR: -p option is required\n"
    exit 1
fi

# Make log directory if it doesn't exist:
LOG_DIR=${OUTDIR}/logs
if [[ ! -d "${LOG_DIR}" ]]; then
    mkdir ${LOG_DIR}
    echo "Making logs directory at: ${LOG_DIR}"
else
    echo "Log directory ${LOG_DIR} already exists, skipping creation of log directory"
fi

# Define variables
OUTDIR=${OUTDIR%/}
SAMPLE1_DIR=${SAMPLE1_DIR%/}
SAMPLE2_DIR=${SAMPLE2_DIR%/}
QSUB_ARGS="-terse -V -q sandbox.q -m abe -M sakai.yuta@mayo.edu -o ${LOG_DIR} -j y"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

CMD="${QSUB} ${QSUB_ARGS} -N runContaminate ${SCRIPT_DIR}/contaminate.sh -a ${SAMPLE1_DIR} -b ${SAMPLE2_DIR} -o ${OUTDIR} -p ${SAMPLE1_PERCENT} -s ${SCRIPT_DIR}"
echo "Excuting command: ${CMD}"
${CMD}