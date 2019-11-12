#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

INPUT_BAM=""
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
    -i  [required] full path to input BAM
    -o  [required] output directory
    -s  [required] sample name, must match the sample name in the BAM file

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hi:o:s:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		i) INPUT_BAM=${OPTARG} ;;
		o) OUTDIR=${OPTARG} ;;
		s) SAMPLE_NAME=${OPTARG} ;;
    esac
done

OUTDIR=${OUTDIR%/}

CMD="${SENTION_DRIVER} -i ${INPUT_BAM} -r ${REFERENCE_FASTA} --algo ${ALGO} --tumor_sample ${SAMPLE_NAME} \
${OUTDIR}/${SAMPLE_NAME}.vcf.gz"
echo "Executing command: ${CMD}"
${CMD}