#!/usr/bin/env bash

##################################################
#DEFAULT VALUES
##################################################


##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
concatenates fastq files from all lanes, but separate out by
different reads

OPTIONS:
    -h  [optional] help, show this message
    -f  [required] fastq file

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "hf:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		f) FQ_FILE=${OPTARG} ;;
    esac
done

/bin/zcat ${FQ_FILE} | /usr/bin/wc -l