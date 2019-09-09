#!/bin/bash

##################################################
#Global Variables
##################################################

DIR=""
OUTDIR=""

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
    -f  [required] name of the concatenated fastq file
    -r  [required] R1 or R2

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hd:o:f:r:" OPTION
do
    case $OPTION in
        h) usage ; exit ;;
        d) DIR=${OPTARG} ;;
        o) OUTDIR=${OPTARG} ;;
        f) RESULT_FASTQ=${OPTARG} ;;
        r) READ=${OPTARG} ;;
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

SAMPLE_NAME=${DIR##*/}

/bin/find $DIR -maxdepth 1 -name "*${READ}*.fastq" | /bin/sort | xargs /bin/cat > ${OUTDIR}/${RESULT_FASTQ}
