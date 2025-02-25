## script_analise.R



# Analysis Script: Transferability of Bioindicators
# Author: Victoria Sousa and Renato Bolson
# Description: This script performs the statistical analysis for the study on the transferability of bioindicators based on stream fish assemblages.
# The objective is to assess how bioindicators, derived from fish assemblages, respond to environmental pressures across different spatial scales.
# The script includes data preprocessing, calculation of the Anthropogenic Pressure Index (IPA), selection of functional metrics, and regression modeling.


# Initial setup
rm(list=ls(all=TRUE))  # Clear the environment
setwd("./dataset")  # Set working directory to where the dataset is located

# Load required packages
library(vegan)
library(cluster)
library(dplyr)

# ==================================================
# 1. Load Datasets
# ==================================================

MET.IBI <- read.table("metricas.txt", header = TRUE)
LU100 <- read.table("impactos_100.txt", header = TRUE)
LUrip <- read.table("LUrip.txt", header = TRUE)
LUdre <- read.table("LUdrenagem.txt", header = TRUE)
ENVlandscape <- read.csv("dados_ambientais.csv", header = TRUE)
DistEucl <- read.table("distEuc.txt", header = TRUE)
DistRio <- read.table("distRio.txt", header = TRUE)

# Set row names for easy reference
datasets <- list(MET.IBI, LU100, LUrip, LUdre, ENVlandscape, DistEucl, DistRio)
for (df in datasets) {
  rownames(df) <- df$Ponto
}

# ==================================================
# 2. Remove Outliers
# ==================================================
outliers <- c(32, 172, 232, 245, 299, 300, 274)

MET.IBI <- MET.IBI[!rownames(MET.IBI) %in% outliers, ]
LU100 <- LU100[!rownames(LU100) %in% outliers, ]
LUrip <- LUrip[!rownames(LUrip) %in% outliers, ]
LUdre <- LUdre[!rownames(LUdre) %in% outliers, ]
ENVlandscape <- ENVlandscape[!rownames(ENVlandscape) %in% outliers, ]
DistEucl <- DistEucl[!rownames(DistEucl) %in% outliers, ]
DistRio <- DistRio[!rownames(DistRio) %in% outliers, ]

# ==================================================
# 3. Calculate Anthropogenic Pressure Index (IPA)
# ==================================================

p1 <- 0 #SILVI.
p2 <- 1 #AGRI.
p3 <- 1 #Pastagem.
p4 <- 1 #INFURB.
p5 <- 1 #AGUA.
p6 <- 1 #RODO.

##IPA100
IPA100.p<-(LU100$AGRI. * p2)+(LU100$Pastagem. * p3)+
  (LU100$INFURB. * p4)+(LU100$AGUA. * p5)+(LU100$RODO. * p6)
max(IPA100.p)
IPA100<-IPA100.p

#IPArip
IPArip.p<-(LUrip$AGRI. * p2)+(LUrip$Pastagem. * p3)+
  (LUrip$INFURB. * p4)+(LUrip$AGUA. * p5)+(LUrip$RODO. * p6)
max(IPArip.p)
IPArip<-IPArip.p

#IPAdre
IPAdre.p<-(LUdre$AGRI. * p2)+(LUdre$Pastagem. * p3)+
  (LUdre$INFURB. * p4)+(LUdre$AGUA. * p5)+(LUdre$RODO. * p6)
max(IPAdre.p)
IPAdre<-IPAdre.p
IPAfull <- (IPA100 + IPArip + IPAdre)

# Normalize IPA to range 0 - 1
IPAfull <- IPAfull / max(IPAfull)

# ==================================================
# 4. Remove Uninformative Metrics
# ==================================================

MET.IBI.norm <- decostand(MET.IBI[, -c(1:2)], "range")
high_zero <- names(which(colMeans(MET.IBI.norm == 0) > 0.8))
high_one <- names(which(colMeans(MET.IBI.norm == 1) > 0.8))
metrics_to_remove <- unique(c(high_zero, high_one))

MET.IBI <- MET.IBI[, !colnames(MET.IBI) %in% metrics_to_remove]

# Apply log transformation for selected metrics
MET.IBI$Ab_total_especies <- log(MET.IBI$Ab_total_especies + 1)

# ==================================================
# 5. Regression Analysis: Predicting Environmental Impact
# ==================================================

# Load processed data
write.table(IPAfull, "../results/IPA.txt", sep="\t", row.names=TRUE)
write.table(MET.IBI, "../results/MetricasIBI.txt", sep="\t", row.names=TRUE)

# Select metrics for regression
MET.SEL.FREQ <- colnames(MET.IBI[, -c(1:2)])

# Normalize selected metrics
MET.IBI.range <- decostand(MET.IBI[, MET.SEL.FREQ], "range")

# Apply regression models
models <- lapply(MET.SEL.FREQ, function(met) {
  mod <- lm(scale(MET.IBI.range[, met]) ~ scale(IPAfull))
  summary(mod)
})

# Extract coefficients and p-values
results <- data.frame(Metric = MET.SEL.FREQ,
                      Beta = sapply(models, function(m) m$coefficients[2, 1]),
                      P_value = sapply(models, function(m) m$coefficients[2, 4]))

# Save significant metrics
results <- results[results$P_value < 0.05, ]
write.table(results, "../results/Selected_Metrics.txt", sep="\t", row.names=FALSE)

# ==================================================
# 6. Transferability Analysis Across Drainages
# ==================================================

# Load environmental and distance matrices
ENVlandscape <- read.table("../results/Env.txt", header = TRUE)
DistEucl <- read.table("../results/distEuc2.txt", header = TRUE, row.names = 1)
DistRio <- read.table("../results/distRio2.txt", header = TRUE)

# Process data for Drainage 1 (DRE1) - Can be changed to another drainage
IPAfull.dre1 <- IPAfull[names(IPAfull) %in% rownames(MET.IBI.dre1)]

# Select significant metrics for validation
MET.IBI.sel <- MET.IBI[, MET.SEL.FREQ]
MET.IBI.sel <- MET.IBI.sel[MET.IBI$Drenagem == "1", ]
CORRELS <- cor(MET.IBI.sel, IPAfull.dre1)
invert <- names(CORRELS[CORRELS > 0])
MET.IBI.sel[, invert] <- 1 - MET.IBI.sel[, invert]

# Remove correlated metrics (r > 0.7)
tmp <- cor(MET.IBI.sel)
tmp[upper.tri(tmp)] <- 0
VecMET.IBI <- colnames(MET.IBI.sel)[apply(tmp, 2, function(x) all(abs(x) < 0.7))]

# Compute IBI
IBI <- rowMeans(MET.IBI.sel[, VecMET.IBI])

# Save final results
write.table(IBI, "../results/IBI_DRE1.txt", sep="\t", row.names=TRUE)

# Completion message
cat("Processing complete. Results saved in the 'results' folder.\n")

# ==================================================
# Description: This script continues the statistical analysis by applying regression models 
# to assess the relationship between functional metrics and the Anthropogenic Pressure Index (IPA).
# It also evaluates the transferability of models across different drainages.
# ==================================================

# Initial setup
rm(list=ls(all=TRUE))  # Clear environment
setwd("./dataset")  # Set working directory

# Load required packages
library(vegan)
library(cluster)
library(dplyr)

# ==================================================
# 1. Load Processed Data
# ==================================================
IPAfull <- read.table("../results/IPA.txt", header = TRUE)
MET.IBI <- read.table("../results/MetricasIBI.txt", header = TRUE)

# ==================================================
# 2. Remove Uninformative Metrics
# ==================================================

# Define metrics to exclude
metrics_to_remove <- c("Ab_rel_Siluri_Characi", "Riq_rel_Erythrinidae", "Ab_rel_detritivoro", 
                       "Ab_rel_Poeciliidae", "Ab_rel_Callichthyidae", "Ab_rel_Poecilia_reticulata",
                       "Ab_rel_Cicliformes", "Ab_rel_Crenuchidae", "Riq_Crenuchidae", "Riq_Gymnotiformes",
                       "Ab_rel_algivoro", "Ab_rel_piscivoro", "Riq_algivoro", "Riq_piscivoro", 
                       "Riq_rel_piscivoro", "Riq_Siluriformes", "Riq_Cyprinidontiformes", "Riq_Cicliformes",
                       "Riq_Poecilia_reticulata", "Riq_Callichthyidae", "Riq_rel_Callichthyidae", 
                       "Riq_Erythrinidae", "Riq_rel_Gymnotidae", "Riq_Heptapteridae", "Riq_Loricariidae",
                       "Riq_Poeciliidae", "Ab_rel_Cyprinidontiformes", "Ab_rel_Gymnotiformes", 
                       "Ab_rel_Erythrinidae", "Ab_rel_Gymnotidae")

# Remove these metrics
MET.IBI <- MET.IBI[, !colnames(MET.IBI) %in% metrics_to_remove]

# Log transform selected variables
metrics_to_transform <- c("Riq_rel_Crenuchidae", "Ab_rel_Heptapteridae", "Ab_rel_Loricariidae")
MET.IBI[, metrics_to_transform] <- log(MET.IBI[, metrics_to_transform] + 1)

# ==================================================
# 3. Normalize Data
# ==================================================
MET.IBI.range <- decostand(MET.IBI[,-c(1:2)], "range")
MET.IBI.range <- cbind(MET.IBI[, c(1:2)], MET.IBI.range)

# ==================================================
# 4. Regression Analysis: Identifying Significant Metrics
# ==================================================
IPAfull.dre1 <- MET.IBI[MET.IBI$Drenagem == "1", ]
MET.IBI.dre1 <- MET.IBI[MET.IBI$Drenagem == "1", ]
names(IPAfull.dre1) <- rownames(MET.IBI.dre1)

METselLIST <- list()
for (k in 1:3000) {
  MET.sel <- list()
  aleats <- sample(rownames(MET.IBI.dre1), 2 * nrow(MET.IBI.dre1) / 3)
  
  for (i in 3:ncol(MET.IBI)) {
    nomeMET <- colnames(MET.IBI)[i]
    rod.MET.IBI.dre1 <- MET.IBI.dre1[aleats, nomeMET]
    rod.IPAfull.dre1 <- IPAfull.dre1[aleats]
    
    MET.valid.dre1 <- MET.IBI.dre1[!rownames(MET.IBI.dre1) %in% aleats, nomeMET]
    IPA.valid.dre1 <- IPAfull.dre1[!names(IPAfull.dre1) %in% aleats]
    
    if (all(rod.MET.IBI.dre1 == 0)) next
    
    mod <- summary(lm(rod.MET.IBI.dre1 ~ rod.IPAfull.dre1))
    pvalue <- mod$coefficients[2, 4]
    
    if (pvalue > 0.05) next
    
    mod.valid <- summary(lm(MET.valid.dre1 ~ IPA.valid.dre1))
    pvalue.valid <- mod.valid$coefficients[2, 4]
    
    if (pvalue.valid > 0.05) next
    
    MET.sel[[nomeMET]] <- c(mod.valid$coefficients[1, 1], mod.valid$coefficients[2, 1], pvalue.valid)
  }
  METselLIST[[k]] <- as.data.frame(do.call(cbind, MET.sel))
  print(k)
}

# ==================================================
# 5. Selecting Most Frequent Metrics
# ==================================================

FreqMETRICAS <- table(unlist(lapply(METselLIST, colnames)))
MET.SEL.FREQ <- names(FreqMETRICAS[FreqMETRICAS > 0])

# Compute mean coefficients
INTmets <- bind_rows(METselLIST, .id = "column_label")[rownames(bind_rows(METselLIST, .id = "column_label")) == "int",]
BETAmets <- bind_rows(METselLIST, .id = "column_label")[rownames(bind_rows(METselLIST, .id = "column_label")) == "beta",]

intsMET <- colMeans(INTmets, na.rm = TRUE)
betasMET <- colMeans(BETAmets, na.rm = TRUE)

# ==================================================
# 6. Model Transferability Analysis
# ==================================================
MET.IBI.sel <- MET.IBI.range[, MET.SEL.FREQ]
METdre1COR <- MET.IBI.sel[MET.IBI$Drenagem == 1, ]
CORRELS <- cor(METdre1COR, IPAfull.dre1)
invert <- names(CORRELS[CORRELS > 0])
MET.IBI.sel[, invert] <- 1 - MET.IBI.sel[, invert]

# Remove correlated metrics (r > 0.7)
tmp <- cor(MET.IBI.sel)
tmp[upper.tri(tmp)] <- 0
VecMET.IBI <- colnames(tmp)[apply(tmp, 2, function(x) all(abs(x) < 0.7))]

# Compute IBI for Drainage 1
IBI <- rowMeans(MET.IBI.sel[, VecMET.IBI])

# ==================================================
# 7. Save Results
# ==================================================
write.table(IBI, "../results/IBI_DRE1.txt", sep="\t", row.names=TRUE)

# Completion message
cat("Processing complete. Results saved in the 'results' folder.\n")

