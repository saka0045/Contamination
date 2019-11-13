# The script needs to be called with:
# Rscript make_allele_frequency_histogram.R /path/to/allele_frequency.csv sampleName

args <- commandArgs(trailingOnly=TRUE)

# Read in the allele frequency csv
frequency_table <- sapply(read.csv(args[1]), as.numeric)

# Plot histogram
pdf(file = "allele_frequency.pdf", width = 8, height = 8)
hist(frequency_table, freq = TRUE, xlab = "Allele Frequency", ylab = "Count", 
     main = paste("Histogram of Allele Frequency for", args[2]))