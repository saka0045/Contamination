#!/usr/bin/env python3
"""
Script to parse the vcf and collect the allele frequency of each variant.
Outputs a csv file with allele frequency per line
"""

__author__ = "Yuta Sakai"

import argparse
import os
import gzip


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-i", "--inputFile", dest="input_file", required=True,
        help="Input vcf file, must be gzipped"
    )
    parser.add_argument(
        "-o", "--ouputDir", dest="output_dir", required=True,
        help="Directory to save output file"
    )

    args = parser.parse_args()

    input_file = os.path.abspath(args.input_file)
    out_path = os.path.abspath(args.output_dir)

    # Add / at the end if it is not included in the output path
    if out_path.endswith("/"):
        out_path = out_path
    else:
        out_path = out_path + "/"

    vcf_file = gzip.open(input_file, "rt")

    # Skip past the headers
    for line in vcf_file:
        if line.startswith("#CHROM"):
            break

    # Start collecting information
    allele_frequency_list = []
    for line in vcf_file:
        line = line.rstrip()
        line_item = line.split("\t")
        vcf_format = line_item[8]
        format_result = line_item[9]
        format_list = vcf_format.split(":")
        format_result_list = format_result.split(":")
        # Figure out where AF lies in FORMAT
        allele_frequency_index = format_list.index("AF")
        # Pull the AF information out of the VCF
        allele_frequency = format_result_list[allele_frequency_index]
        # If the variant has multiple alternate alleles, add all of the AF in the list
        if "," in allele_frequency:
            multiple_allele_frequency = allele_frequency.split(",")
            for item in multiple_allele_frequency:
                allele_frequency_list.append(item)
        else:
            allele_frequency_list.append(allele_frequency)

    result_file = open(out_path + "allele_frequency.csv", "w")

    for item in allele_frequency_list:
        result_file.write(item + "\n")

    vcf_file.close()
    result_file.close()

    print("Script is done running")


if __name__ == "__main__":
    main()
