#!/usr/bin/env python3

import argparse
import os

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        '-i', '--inputFile', dest='input_file', required=True,
        help="Path to microhap rsid tsv file"
    )

    args = parser.parse_args()

    input_file = os.path.abspath(args.input_file)
    large_cancer_file = "/Users/m006703/Contamination/files/large_cancer.tsv"

    rsid_file = open(input_file, 'r')
    microhap_dict = {}
    # Skip the header line
    rsid_file.readline()
    for line in rsid_file:
        line = line.rstrip()
        line_item = line.split("\t")
        microhap = line_item[0]
        microhap_dict[microhap] = []
        for index in range (1, len(line_item)):
            microhap_dict[microhap].append(line_item[index])

    large_cancer_rsid_file = open(large_cancer_file, 'r')
    large_cancer_rsid = []
    for line in large_cancer_rsid_file:
        line = line.rstrip()
        large_cancer_rsid.append(line)

    # print(microhap_dict)
    # print(large_cancer_rsid)

    microhap_dict["LargeCancer"] = []

    for snp in large_cancer_rsid:
        if snp in microhap_dict.values():
            print(snp + " found")
        else:
            print(snp + " not found")
            microhap_dict["LargeCancer"].append(snp)

    print(microhap_dict)

    rsid_file.close()
    large_cancer_rsid_file.close()


if __name__ == "__main__":
    main()
