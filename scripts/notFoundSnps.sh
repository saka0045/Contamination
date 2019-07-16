#!/bin/bash

while read SNP; do
	if ! grep -wq "$SNP" /Users/m006703/Contamination/files/grepped_final_rsid.txt; then
		echo "$SNP doesn't exist"
	fi
done < /Users/m006703/Contamination/files/final_rsid.txt
