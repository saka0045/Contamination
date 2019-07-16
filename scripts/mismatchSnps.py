#!/usr/bin/env python3

import json

final_rsid_file = open("/Users/m006703/Contamination/files/final_rsid.txt", "r")
grepped_rsid_file = open("/Users/m006703/Contamination/files/grepped_final_rsid.txt", "r")
bed_file = open("/Users/m006703/Contamination/files/contamination_target.bed", "w")

final_rsid_snps = []
for line in final_rsid_file:
    line = line.rstrip()
    final_rsid_snps.append(line)

# print(final_rsid_snps)
# print(len(final_rsid_snps))

grepped_rsid_snps = []
for line in grepped_rsid_file:
    line = line.rstrip()
    line_item = line.split("\t")
    snp_info = line_item[3]
    # convert the snp info string into dictionary
    snp_info_dict = json.loads(snp_info)
    grepped_snp_id = snp_info_dict["ID"]
    if grepped_snp_id not in grepped_rsid_snps:
        grepped_rsid_snps.append(grepped_snp_id)
        chrom_number = str(line_item[0])
        chrom = "chr" + chrom_number
        start_pos = line_item[1]
        stop_pos = line_item[2]
        bed_file.write(chrom + "\t" + start_pos + "\t" + stop_pos + "\n")

# print(grepped_rsid_snps)
print(len(grepped_rsid_snps))

for snp in final_rsid_snps:
    if snp not in grepped_rsid_snps:
        print(snp + " not found")

final_rsid_file.close()
grepped_rsid_file.close()
bed_file.close()