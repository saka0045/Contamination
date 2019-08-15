#!/bin/bash

##################################################
#Global Variables
##################################################

DIR=""
OUTDIR=""
SAMPLENAME=""
RESULTFILE=""
R1FASTQ=""
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
    -d  [required] input directory
	-o  [required] output directory

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hd:o:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		d) DIR=${OPTARG} ;;
		o) OUTDIR=${OPTARG} ;;
    esac
done

if [[ -z $DIR ]]; then
    echo -e "ERROR: -d option is required\n"
    exit 1
fi

if [[ -z $OUTDIR ]]; then
    echo -e "ERROR: -o option is required\n"
    exit 1
fi

#Get sample name
SAMPLENAME=${DIR##*/}
R1FASTQ=${SAMPLENAME}_combined_R1.fastq
echo "Sample name: $SAMPLENAME"
# Process R1 fastqs
echo "Processing R1 fastqs in directory: $DIR"
find $DIR -maxdepth 1 -name "*R1*.fastq.gz" | sort
echo "Saving concatenated fastq file at: $OUTDIR/${R1FASTQ}"
CMD="qsub -V -m abe -M sakai.yuta@mayo.edu -wd ${OUTDIR} -q sandbox.q -N concatenateFastq /dlmp/sandbox/cgslIS/Yuta/Contamination/scripts/concatenate_fastq.sh -d ${DIR} -o ${OUTDIR}"
echo "Executing command: ${CMD}"
${CMD}

# Make result file
RESULTFILE=${OUTDIR}/${SAMPLENAME}_combined_R1_fastq_results.txt
touch ${RESULTFILE}
echo "Line count for ${R1FASTQ}:" >> ${RESULTFILE}

# qsub and count the lines in the fastq file
echo "Counting lines in ${R1FASTQ}"
# wait for concatenateFastq to finish before qsubbing this
CMD="qsub -hold_jid concatenateFastq -V -m abe -M sakai.yuta@mayo.edu -wd ${OUTDIR} -q sandbox.q -N countFastqLine /dlmp/sandbox/cgslIS/Yuta/Contamination/scripts/count_fastq_lines.sh -o ${OUTDIR} -f ${R1FASTQ} -r ${RESULTFILE}"
echo "Executing command: ${CMD}"
${CMD}
