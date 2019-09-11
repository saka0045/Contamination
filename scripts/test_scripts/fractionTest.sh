#!/usr/bin/env bash

BC="/usr/bin/bc"

FRACTION=$(${BC} -l <<< "24/100")

echo "${FRACTION}"

TOTAL_READS=$(${BC} <<< "(${FRACTION} * 211) / 1")

echo "${TOTAL_READS}"