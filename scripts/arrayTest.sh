#!/usr/bin/env bash

##################################################
#GLOBAL VARIABLES
##################################################

declare -A FQ_ARR1
declare -A FQ_ARR2
RESULT_FILE=""

##################################################
#FUNCTIONS
##################################################

function usage(){
cat << EOF
test script to check arrays

OPTIONS:
    -h  [optional] help, show this message
    -a  [required] input array
    -r  [required] path to output text file

EOF
}

##################################################
#BEGIN PROCESSING
##################################################

while getopts "ha:r:" OPTION
do
    case $OPTION in
		h) usage ; exit ;;
		a) FQ_ARR1=${OPTARG} ;;
		r) RESULT_FILE=${OPTARG} ;;
    esac
done

for KEY in ${!FQ_ARR1[@]}; do
    echo ${KEY} ${FQ_ARR1[${KEY}]} >> ${RESULT_FILE}
done