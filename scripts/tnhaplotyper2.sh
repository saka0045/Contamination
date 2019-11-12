#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

INPUT_DIR=""
REFERENCE_FASTA="/dlmp/misc-data/pipelinedata/deployments/mgc/bwa/GRCh37/hs37d5.fa"
OUTDIR=""
SAMPLE_NAME=""
CMD=""
SENTION_DRIVER="/biotools/biotools/sentieon/201808.03/bin/sentieon driver"
ALGO="TNhaplotyper2"

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
command to run TNhaplotyper2

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

CMD="${SENTION_DRIVER} -i ${INPUT_DIR}/${SAMPLE_NAME}.bam -r ${REFERENCE_FASTA} --algo ${ALGO} --tumor_sample \
${SAMPLE_NAME} ${INPUT_DIR}/${SAMPLE_NAME}.vcf.gz"
echo "Executing command: ${CMD}"
${CMD}