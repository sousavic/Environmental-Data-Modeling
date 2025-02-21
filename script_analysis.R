## script_analise.R

Part I

# Analysis Script: Transferability of Bioindicators
# Author: Victoria Sousa and Renato Bolson
# Description: This script performs the statistical analysis for the study on the transferability of bioindicators based on stream fish assemblages.
# The objective is to assess how bioindicators, derived from fish assemblages, respond to environmental pressures across different spatial scales.
# The script includes data preprocessing, calculation of the Anthropogenic Pressure Index (IPA), selection of functional metrics, and regression modeling.

# Initial setup
rm(list=ls(all=TRUE))  # Clear the environment
setwd("./dataset")  # Set the working directory

# Load required packages
library(vegan)
library(cluster)
library(dplyr)

# Load datasets
MET.IBI <- read.table("metricas.txt", header = TRUE)
LU100 <- read.table("impactos_100.txt", header = TRUE)
LUrip <- read.table("LUrip.txt", header = TRUE)
LUdre <- read.table("LUdrenagem.txt", header = TRUE)
ENVlandscape <- read.csv("dados_ambientais.csv", header = TRUE)
DistEucl <- read.table("distEuc.txt", header = TRUE)
DistRio <- read.table("distRio.txt", header = TRUE)

# Define row names
rownames(MET.IBI) <- MET.IBI$Ponto
rownames(LU100) <- LU100$Ponto
rownames(LUrip) <- LUrip$Ponto
rownames(LUdre) <- LUdre$Ponto
rownames(ENVlandscape) <- ENVlandscape$Ponto
rownames(DistEucl) <- DistEucl$Ponto
rownames(DistRio) <- DistRio$Ponto

# Remove identified outliers
outliers <- c(32, 172, 232, 245, 299, 300, 274)
MET.IBI <- MET.IBI[!rownames(MET.IBI) %in% outliers, ]
LU100 <- LU100[!rownames(LU100) %in% outliers, ]
LUrip <- LUrip[!rownames(LUrip) %in% outliers, ]
LUdre <- LUdre[!rownames(LUdre) %in% outliers, ]
ENVlandscape <- ENVlandscape[!rownames(ENVlandscape) %in% outliers, ]
DistEucl <- DistEucl[!rownames(DistEucl) %in% outliers, ]
DistRio <- DistRio[!rownames(DistRio) %in% outliers, ]

# Anthropogenic Pressure Index (IPA)
# IPA measures the degree of human impact on the environment based on land use metrics.
weights <- c(SILVI = 0, AGRI = 1, Pastagem = 1, INFURB = 1, AGUA = 1, RODO = 1)
IPA100 <- rowSums(LU100[, names(weights)] * weights)
IPArip <- rowSums(LUrip[, names(weights)] * weights)
IPAdre <- rowSums(LUdre[, names(weights)] * weights)
IPAfull <- (IPA100 + IPArip + IPAdre)
IPAfull <- IPAfull / max(IPAfull)  # Normalize values to range 0-1

# Remove metrics with more than 80% zeros or ones
MET.IBI.out <- decostand(MET.IBI[, -c(1:2)], "range")
met.OUT <- names(which(colMeans(MET.IBI.out == 0) > 0.8 | colMeans(MET.IBI.out == 1) > 0.8))
MET.IBI.out <- MET.IBI[, !colnames(MET.IBI) %in% met.OUT]

# Log transformation for normalization of selected metrics
MET.IBI.out$Ab_total_especies <- log(MET.IBI.out$Ab_total_especies + 1)

# Part II

# Regressions and Statistical Models
# This section applies linear regression models to evaluate the relationship between functional metrics of fish assemblages and the IPA.
# The goal is to identify significant predictors of anthropogenic pressure and assess their reliability across different regions.

# Load processed data
IPAfull <- read.table("../results/IPA.txt", header = TRUE)
MET.IBI <- read.table("../results/MetricasIBI.txt", header = TRUE)

# Select metrics for analysis
MET.SEL.FREQ <- colnames(MET.IBI[, -c(1:2)])

# Normalize selected metrics
MET.IBI.range <- decostand(MET.IBI[, MET.SEL.FREQ], "range")

# Create regression models to predict environmental impact
models <- lapply(MET.SEL.FREQ, function(met) {
  mod <- lm(scale(MET.IBI.range[, met]) ~ scale(IPAfull[, 1]))
  summary(mod)
})

# Extract coefficients and p-values
results <- data.frame(Metric = MET.SEL.FREQ,
                      Beta = sapply(models, function(m) m$coefficients[2, 1]),
                      P_value = sapply(models, function(m) m$coefficients[2, 4]))

# Filter significant metrics
results <- results[results$P_value < 0.05, ]

# Save results
write.table(results, "../results/Selected_Metrics.txt", sep="\t", row.names=FALSE)

# Completion message
gcat("Processing complete. Results saved in the 'results' folder.")


# Part III
                                       
# Assessing Transferability
# This section evaluates the robustness of the models across different drainage areas.
# It processes data for a specific drainage and applies the same methodology to other drainages by changing the drainage ID.

# Load environmental and distance matrices
ENVlandscape <- read.table("../results/Env.txt", header = TRUE)
DistEucl <- read.table("../results/distEuc2.txt", header = TRUE, row.names = 1)
DistRio <- read.table("../results/distRio2.txt", header = TRUE)

# Process data for Drainage 1 (DRE1) - Change '1' to another drainage ID to analyze different areas
IPAfull.dre1 <- IPAfull[IPAfull$Drenagem == "1", 1]
MET.IBI.dre1 <- MET.IBI[MET.IBI$Drenagem == "1", ]
names(IPAfull.dre1) <- rownames(MET.IBI.dre1)

# Select significant metrics for further validation
MET.IBI.sel <- MET.IBI[, MET.SEL.FREQ]
MET.IBI.sel <- MET.IBI.sel[MET.IBI$Drenagem == "1", ]
CORRELS <- cor(MET.IBI.sel, IPAfull.dre1)
invert <- names(CORRELS[CORRELS > 0])
MET.IBI.sel[, invert] <- 1 - MET.IBI.sel[, invert]

# Remove correlated metrics (r > 0.7)
tmp <- cor(MET.IBI.sel)
tmp[upper.tri(tmp)] <- 0
tmp <- tmp[apply(tmp, 2, function(x) all(x < 0.7)), ]
VecMET.IBI <- colnames(tmp)

# Compute IBI for Drainage 1
IBI <- rowMeans(MET.IBI.sel[, VecMET.IBI])

# Save processed data
write.table(IBI, "../results/IBI_DRE1.txt", sep="\t", row.names=TRUE)

# Completion message
gcat("Processing complete. Results saved in the 'results' folder.")
