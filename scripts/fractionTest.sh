#!/usr/bin/env bash

BC="/usr/bin/bc"

FRACTION=$(${BC} -l <<< "24/100")

FRACTION2=$(${BC} -l <<< "(${FRACTION} * 100)")

echo "${FRACTION2}"