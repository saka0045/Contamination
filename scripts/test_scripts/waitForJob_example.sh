#!/usr/bin/env bash

CMD="${QSUB} ${QSUB_ARGS} -N countFastq ${SCRIPT_DIR}/countFastqFile.sh -s ${SAMPLE1_DIR} -r R2 -f ${RESULT1_FILE}"
echo "CMD=${CMD}"
JOB_ID=$(${CMD})
COUNT_FASTQ_JOBS+=("${JOB_ID}")
echo "COUNT_FASTQ_JOBS+=${JOB_ID}"