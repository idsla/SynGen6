#if (!require("BiocManager", quietly = TRUE))
# install.packages("BiocManager")

#BiocManager::install("snpStats")

library(PhenotypeSimulator)
library(tidyverse)

file_path <- "./gen_data/all_hg38_snp.csv"  # replace with your generated SNP data file path
snp_data <- read_csv(file_path)

genotypes = snp_data %>% select(3:ncol(.)) %>% as.matrix()

noiseBg <- noiseBgEffects(N = nrow(genotypes), P = 1)
causalSNPs <- getCausalSNPs(N=nrow(genotypes), NrCausalSNPs = round(0.1*ncol(genotypes)),genotypes=genotypes)
causalSNPs <- standardiseGenotypes(genotypes)
geneticFixed <- geneticFixedEffects(N=nrow(genotypes), X_causal=causalSNPs, P=1, id_samples = 1:nrow(genotypes))

genVar <- 0.9
noiseVar <- 1- genVar
# rescale phenotype components
genBg_ind_scaled <- rescaleVariance(geneticFixed$independent, genVar)
noiseBg_ind_scaled <- rescaleVariance(noiseBg$independent, noiseVar)

# combine components into final phenotype
Y <- scale(genBg_ind_scaled$component + noiseBg_ind_scaled$component)

# transform to binary
sigmoid <- function(x) {
  1 / (1 + exp(-x))
}

Y_sigmoid <- sigmoid(Y)
threshold <- median(Y_sigmoid)
Y_binary <- as.integer(Y_sigmoid >= threshold)

pheno_data <- snp_data %>%
    select(SampleID) %>%
    mutate(PhenotypeCondition = Y_binary)

write_csv(pheno_data, "./gen_data/all_hg38_phenotype.csv", col_names = TRUE)  # replace with your output file path
