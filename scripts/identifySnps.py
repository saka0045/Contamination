#!/usr/bin/env python3

hereditary_snp_file = open("/Users/m006703/Contamination/Hereditary/snps_covered_by_Hereditary.txt", "r")
hereditary_filtered_snp_file = open("/Users/m006703/Contamination/Hereditary/microhap-filtered.bed", "w")

bed_file_info = {}
for line in hereditary_snp_file:
    line = line.rstrip()
    line_item = line.split("\t")
    chrom = line_item[0]
    start_pos = line_item[1]
    stop_pos = line_item[2]
    rsid = line_item[3]
    snp_info = {}
    snp_info["rsid"] = rsid
    snp_info["chrom"] = chrom
    snp_info["start"] = start_pos
    snp_info["stop"] = stop_pos
    microhap_sites = line_item[4].split(",")
    for microhap in microhap_sites:
        if microhap not in bed_file_info.keys():
            bed_file_info[microhap] = [snp_info]
        else:
            bed_file_info[microhap].append(snp_info)

print(bed_file_info)

hereditary_snp_file.close()
hereditary_filtered_snp_file.close()
