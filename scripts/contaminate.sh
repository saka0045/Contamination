#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

declare -A FQ_ARR1
declare -A FQ_ARR2
SAMPLE1_DIR=""
SAMPLE2_DIR=""
OUTDIR=""
CMD=""
BC="/usr/bin/bc"
SCRIPT_DIR=""
QDIR="/usr/local/biotools/oge/ge2011.11/bin/linux-x64"
QSUB="${QDIR}/qsub"
QSTAT="${QDIR}/qstat"
SENTIEON_ARGS="-v SENTIEON_LICENSE=dlmpcim03.mayo.edu:8990 -l h_vmem=50G -N sentieonBwa"
REFERENCE_GENOME="/dlmp/misc-data/pipelinedata/deployments/mgc/bwa/GRCh37/hs37d5.fa"
PANEL_BED_PATH=""
SAMPLE1_PERCENT=""
SAMPLE2_PERCENT=""
SEQTK_JOBS=()
CONCATENATE_FASTQ_JOBS=()
CONTAMINTE_FASTQ_JOBS=()
ALIGNMENT_JOBS=()

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
    -s  [required] directory of script, passed on with runContaminate.sh
    -t  [required] path to target.bed to run verifyBamid

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

while getopts "ha:b:o:p:s:t:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		a) SAMPLE1_DIR=${OPTARG} ;;
		b) SAMPLE2_DIR=${OPTARG} ;;
		o) OUTDIR=${OPTARG} ;;
		p) SAMPLE1_PERCENT=${OPTARG} ;;
		s) SCRIPT_DIR=${OPTARG} ;;
		t) PANEL_BED_PATH=${OPTARG} ;;
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

if [[ -z ${PANEL_BED_PATH} ]]; then
    echo -e "ERROR: -t option is required\n"
    exit 1
fi

# Define variables
OUTDIR=${OUTDIR%/}
SAMPLE1_DIR=${SAMPLE1_DIR%/}
SAMPLE2_DIR=${SAMPLE2_DIR%/}
LOG_DIR=${OUTDIR}/logs
QSUB_ARGS="-terse -V -q sandbox.q -m ae -M sakai.yuta@mayo.edu -o ${LOG_DIR} -j y"
ERR_GENERAL=1
SAMPLE1_NAME=${SAMPLE1_DIR##*/}
SAMPLE2_NAME=${SAMPLE2_DIR##*/}
OUT_SAMPLE1_DIR=${OUTDIR}/${SAMPLE1_NAME}
OUT_SAMPLE2_DIR=${OUTDIR}/${SAMPLE2_NAME}

# Make directory for log files if it doesn't exist already
if [[ ! -d "${LOG_DIR}" ]]; then
    mkdir ${LOG_DIR}
    echo "Making logs directory at: ${LOG_DIR}"
else
    echo "Log directory ${LOG_DIR} already exists, skipping creation of log directory"
fi

# Calculate SAMPLE2_PERCENT
SAMPLE2_PERCENT=$((100 - ${SAMPLE1_PERCENT}))
echo "Using ${SAMPLE1_PERCENT}% for Sample 1 and ${SAMPLE2_PERCENT}% for Sample 2"

# Make directory for output files if it doesn't exist already
CONATAMINATED_FASTQ_SAMPLE_NAME=${SAMPLE1_NAME}_${SAMPLE1_PERCENT}_${SAMPLE2_NAME}_${SAMPLE2_PERCENT}
CONTAMINATED_FASTQ_DIR=${OUTDIR}/${CONATAMINATED_FASTQ_SAMPLE_NAME}

if [[ ! -d "${CONTAMINATED_FASTQ_DIR}" ]]; then
    mkdir ${CONTAMINATED_FASTQ_DIR}
    echo "Making output directory at: ${CONTAMINATED_FASTQ_DIR}"
else
    echo "Output directory at ${CONTAMINATED_FASTQ_DIR} already exists!"
    echo "Aborting script"
    exit 1
fi

# Count lines in fastq file for SAMPLE1_DIR
for FQ_FILE in ${SAMPLE1_DIR}/*.fastq.gz; do
    echo "Counting lines in ${FQ_FILE}"
    LINE=$(/bin/zcat ${FQ_FILE} | /usr/bin/wc -l)
    echo "lines in ${FQ_FILE} is ${LINE}"
    COUNT=$((${LINE} / 4 ))
    echo "number of reads in ${FQ_FILE} is ${COUNT}"
    FQ_ARR1[${FQ_FILE}]=${COUNT}
done

# Add all of the reads up
TOTAL_READS_SAMPLE1=0
for KEY in ${!FQ_ARR1[@]}; do
    COUNT=${FQ_ARR1[${KEY}]}
    TOTAL_READS_SAMPLE1=$((${TOTAL_READS_SAMPLE1}+${COUNT}))
done

echo "Total reads in sample ${SAMPLE1_NAME} is ${TOTAL_READS_SAMPLE1}"

# Count lines in fastq file for SAMPLE2_DIR
for FQ_FILE in ${SAMPLE2_DIR}/*.fastq.gz; do
    echo "Counting lines in ${FQ_FILE}"
    LINE=$(/bin/zcat ${FQ_FILE} | /usr/bin/wc -l)
    echo "lines in ${FQ_FILE} is ${LINE}"
    COUNT=$((${LINE} / 4 ))
    echo "number of reads in ${FQ_FILE} is ${COUNT}"
    FQ_ARR2[${FQ_FILE}]=${COUNT}
done

# Add all of the reads up
TOTAL_READS_SAMPLE2=0
for KEY in ${!FQ_ARR2[@]}; do
    COUNT=${FQ_ARR2[${KEY}]}
    TOTAL_READS_SAMPLE2=$((${TOTAL_READS_SAMPLE2}+${COUNT}))
done

echo "Total reads in sample ${SAMPLE2_NAME} is ${TOTAL_READS_SAMPLE2}"

# Take the lesser of the total sample reads to be the max reads for downsample
if ((${TOTAL_READS_SAMPLE1} > ${TOTAL_READS_SAMPLE2})); then
    MAX_READS=${TOTAL_READS_SAMPLE2}
else
    MAX_READS=${TOTAL_READS_SAMPLE1}
fi

echo "Max reads for downsample is ${MAX_READS}"

# Calculate the number of reads each fastq file needs to downsample to for sample 1 and perform downsample
for KEY in ${!FQ_ARR1[@]}; do
    COUNT=${FQ_ARR1[${KEY}]}
    FRACTION=$(${BC} -l <<< "(${COUNT} / ${TOTAL_READS_SAMPLE1}) * (${SAMPLE1_PERCENT} / 100)")
    # Truncate the TARGET_READ to an integer
    TARGET_READ=$(${BC} <<< "(${FRACTION} * ${MAX_READS}) / 1")
    echo "Target reads for ${KEY} is ${TARGET_READ}"
    FASTQ_PATH=${KEY##*/}
    FASTQ_FILE=${FASTQ_PATH%.*}
    CMD="${QSUB} ${QSUB_ARGS} -N seqtk -l h_vmem=150G ${SCRIPT_DIR}/seqtk.sh -s 100 -i ${KEY} -r ${TARGET_READ} -o ${CONTAMINATED_FASTQ_DIR}/${FASTQ_FILE}"
    echo "Executing command: ${CMD}"
    JOB_ID=$(${CMD})
    SEQTK_JOBS+=("${JOB_ID}")
    echo "SEQTK_JOBS+=${JOB_ID}"
done

# Calculate the number of reads each fastq file needs to downsample to for sample 2 and perform downsample
for KEY in ${!FQ_ARR2[@]}; do
    COUNT=${FQ_ARR2[${KEY}]}
    FRACTION=$(${BC} -l <<< "(${COUNT} / ${TOTAL_READS_SAMPLE2}) * (${SAMPLE2_PERCENT} / 100)")
    # Truncate the TARGET_READ to an integer
    TARGET_READ=$(${BC} <<< "(${FRACTION} * ${MAX_READS}) / 1")
    echo "Target reads for ${KEY} is ${TARGET_READ}"
    FASTQ_PATH=${KEY##*/}
    FASTQ_FILE=${FASTQ_PATH%.*}
    CMD="${QSUB} ${QSUB_ARGS} -N seqtk -l h_vmem=150G ${SCRIPT_DIR}/seqtk.sh -s 100 -i ${KEY} -r ${TARGET_READ} -o ${CONTAMINATED_FASTQ_DIR}/${FASTQ_FILE}"
    echo "Executing command: ${CMD}"
    JOB_ID=$(${CMD})
    SEQTK_JOBS+=("${JOB_ID}")
    echo "SEQTK_JOBS+=${JOB_ID}"
done

for JOB_ID in ${SEQTK_JOBS[@]:-}; do
    waitForJob ${JOB_ID} 86400 60
done

# Contaminate L001 sample 1 and sample 2
CMD="${QSUB} ${QSUB_ARGS} -N contaminateFastq ${SCRIPT_DIR}/contaminate_fastq.sh -a ${SAMPLE1_NAME} -b ${SAMPLE2_NAME} -o ${CONTAMINATED_FASTQ_DIR} \
-l L001 -r R1 -f ${CONATAMINATED_FASTQ_SAMPLE_NAME}"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})
CONTAMINATE_FASTQ_JOBS+=("${JOB_ID}")
echo "CONTAMINATE_FASTQ_JOBS+=${JOB_ID}"
CMD="${QSUB} ${QSUB_ARGS} -N contaminateFastq ${SCRIPT_DIR}/contaminate_fastq.sh -a ${SAMPLE1_NAME} -b ${SAMPLE2_NAME} -o ${CONTAMINATED_FASTQ_DIR} \
-l L001 -r R2 -f ${CONATAMINATED_FASTQ_SAMPLE_NAME}"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})
CONTAMINATE_FASTQ_JOBS+=("${JOB_ID}")
echo "CONTAMINATE_FASTQ_JOBS+=${JOB_ID}"

# Contaminate L002 sample 1 and sample 2
CMD="${QSUB} ${QSUB_ARGS} -N contaminateFastq ${SCRIPT_DIR}/contaminate_fastq.sh -a ${SAMPLE1_NAME} -b ${SAMPLE2_NAME} -o ${CONTAMINATED_FASTQ_DIR} \
-l L002 -r R1 -f ${CONATAMINATED_FASTQ_SAMPLE_NAME}"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})
CONTAMINATE_FASTQ_JOBS+=("${JOB_ID}")
echo "CONTAMINATE_FASTQ_JOBS+=${JOB_ID}"
CMD="${QSUB} ${QSUB_ARGS} -N contaminateFastq ${SCRIPT_DIR}/contaminate_fastq.sh -a ${SAMPLE1_NAME} -b ${SAMPLE2_NAME} -o ${CONTAMINATED_FASTQ_DIR} \
-l L002 -r R2 -f ${CONATAMINATED_FASTQ_SAMPLE_NAME}"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})
CONTAMINATE_FASTQ_JOBS+=("${JOB_ID}")
echo "CONTAMINATE_FASTQ_JOBS+=${JOB_ID}"

for JOB_ID in ${CONTAMINATE_FASTQ_JOBS[@]:-}; do
    waitForJob ${JOB_ID} 86400 60
done

# Align LOO1 fastq files using Jag's script
CMD="${QSUB} ${QSUB_ARGS} ${SENTIEON_ARGS} -wd ${CONTAMINATED_FASTQ_DIR} ${SCRIPT_DIR}/sentieon_bwa.sh -i ${CONTAMINATED_FASTQ_DIR}/${CONATAMINATED_FASTQ_SAMPLE_NAME}_L001_R1.fastq \
-f ${CONTAMINATED_FASTQ_DIR}/${CONATAMINATED_FASTQ_SAMPLE_NAME}_L001_R2.fastq -r ${REFERENCE_GENOME} -s ${CONATAMINATED_FASTQ_SAMPLE_NAME} -n COORD -l L001"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})
ALIGNMENT_JOBS+=("${JOB_ID}")
echo "ALIGNMENT_JOBS+=${JOB_ID}"

# Align LOO2 fastq files using Jag's script
CMD="${QSUB} ${QSUB_ARGS} ${SENTIEON_ARGS} -wd ${CONTAMINATED_FASTQ_DIR} ${SCRIPT_DIR}/sentieon_bwa.sh -i ${CONTAMINATED_FASTQ_DIR}/${CONATAMINATED_FASTQ_SAMPLE_NAME}_L002_R1.fastq \
-f ${CONTAMINATED_FASTQ_DIR}/${CONATAMINATED_FASTQ_SAMPLE_NAME}_L002_R2.fastq -r ${REFERENCE_GENOME} -s ${CONATAMINATED_FASTQ_SAMPLE_NAME} -n COORD -l L002"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})
ALIGNMENT_JOBS+=("${JOB_ID}")
echo "ALIGNMENT_JOBS+=${JOB_ID}"

for JOB_ID in ${ALIGNMENT_JOBS[@]:-}; do
    waitForJob ${JOB_ID} 86400 60
done

# Merge and index BAMs
CMD="${QSUB} ${QSUB_ARGS} -wd ${CONTAMINATED_FASTQ_DIR} -N mergeAndIndexBams ${SCRIPT_DIR}/mergeAndIndexBams.sh -a ${CONATAMINATED_FASTQ_SAMPLE_NAME}_L001.bam \
-b ${CONATAMINATED_FASTQ_SAMPLE_NAME}_L002.bam -s ${CONATAMINATED_FASTQ_SAMPLE_NAME}"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})

waitForJob ${JOB_ID} 86400 60

BAM_FILE="${CONTAMINATED_FASTQ_DIR}/${CONATAMINATED_FASTQ_SAMPLE_NAME}.bam"
echo "Created BAM file: ${BAM_FILE}"

# Run Rohan's verifyBamId script
CMD="${QSUB} ${QSUB_ARGS} -N verifyBamId -l h_vmem=10G ${SCRIPT_DIR}/run_verifybamID_perSample_REV1.sh -i ${BAM_FILE} -o ${CONTAMINATED_FASTQ_DIR} \
-c ${SCRIPT_DIR} -p ${PANEL_BED_PATH} -l TRUE"
echo "Executing command: ${CMD}"
JOB_ID=$(${CMD})

waitForJob ${JOB_ID} 86400 60
: << TEST
# Cleanup
echo "Removing fastq files from ${CONTAMINATED_FASTQ_DIR}"
rm ${CONTAMINATED_FASTQ_DIR}/*.fastq
echo "Removing unsorted BAMs"
rm ${CONTAMINATED_FASTQ_DIR}/*.unsorted.bam
echo "Removing unmerged BAMs"
rm ${CONTAMINATED_FASTQ_DIR}/*L00*.bam
TEST
echo "script is done running!"
