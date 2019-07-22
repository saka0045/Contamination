#!/usr/bin/env python3


def main():

    hereditary_snp_file = open("/Users/m006703/Contamination/Hereditary/snps_covered_by_Hereditary.txt", "r")
    hereditary_filtered_snp_file = open("/Users/m006703/Contamination/Hereditary/microhap-filtered-rsid.txt", "w")

    # Gather information from the grepped BED file
    bed_file_info = gather_bed_file_info(hereditary_snp_file)

    print(bed_file_info)

    # Make BED file filtered for complete Microhap sites
    written_snps = []
    for microhap in bed_file_info.keys():
        if microhap == "na":
            for snp in bed_file_info[microhap]:
                rsid = snp["rsid"]
                hereditary_filtered_snp_file.write(rsid + "\n")
        else:
            number_of_snps = int(microhap.split(":")[1])
            number_of_covered_snps = len(bed_file_info[microhap])
            if number_of_snps == number_of_covered_snps:
                for snp in bed_file_info[microhap]:
                    rsid = snp["rsid"]
                    if rsid not in written_snps:
                        written_snps.append(rsid)
                        hereditary_filtered_snp_file.write(rsid + "\n")

    hereditary_snp_file.close()
    hereditary_filtered_snp_file.close()


def gather_bed_file_info(hereditary_snp_file):
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
    return bed_file_info


if __name__ == "__main__":
    main()
