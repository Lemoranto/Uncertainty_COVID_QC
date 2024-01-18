# Base path
import_data_path <- "/Users/antoine/Documents/GitHub.nosync/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub.nosync/Uncertainty_COVID_QC/Data/Results"

# Importing the database 
input_file <- file.path(import_data_path, "QC.unc.data_daily.csv")
reg_data_daily <- read.csv(input_file, header = TRUE, sep=",")



## OLS MODELS ##

# Packages
library(modelsummary)
library(flextable)
library(tidyverse)
library(officer)
library(knitr)
library(kableExtra)

# Models
models <- list()
models[['OLS1']] =lm(lead(SPHM, 1) ~ UNC+CD100+CC100+TH100+lag(SPHM, 1), data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])
models[['OLS2']] =lm(lead(SPHM, 1) ~ UNC+NEG+CD100+CC100+TH100+lag(SPHM, 1), data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])
models[['OLS3']] =lm(lead(SPHM, 1) ~ UNC+EVD+CD100+CC100+TH100+NEG+lag(SPHM, 1), data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])
models[['OLS4']] =lm(lead(SPHM, 1) ~ UNC+EVD+CD100+CC100+TH100+NEG+UNC:EVD+lag(SPHM, 1), data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])


cm <- c( '(Intercept)' = '(Intercept)', 'lag(SPHM, 1)'='Stringency - 1', 'CD100' = 'Death','CC100'= 'Cases' , 'TH100'='Hospitalizations','UNC'='Uncertainty' , 'NEG'='Negative sentiments','EVD'='Evidence',
         'UNC:EVD'='Uncertainty * Evidence')
cap <- 'Table 1. Effects of Uncertainty, Evidence, Negative Sentiments and Epidemiological Variable on Policy Stringency: Results from OLS Regression Models'
tab<-modelsummary(models, output='flextable',  coef_map=cm, stars =TRUE, title=cap)

# Printing results
tab %>%autofit()

# Set the export file path for the regression table
table_file_name <- "QC.unc.results_OLS.docx"
table_full_path <- file.path(export_path, table_file_name)

# Create a Word document to store the table
doc <- read_docx() %>% 
  body_add_flextable(tab)

# Save the Word document
print(doc, target = table_full_path)



## SEM MODELS ##

# Packages
library(lavaan)
library(semPlot)
library(dplyr)

# Creating lag and lead variables for policy stringency
reg_data_daily <- reg_data_daily %>%
  mutate(lead_SPHM = lead(SPHM, 1))
reg_data_daily <- reg_data_daily %>%
  mutate(lag_SPHM = lag(SPHM, 1))

# SEM Models
model_spec <- '
  # Chemins directs
  EVD ~ c1*UNC
  NEG ~ c2*EVD
  lead_SPHM ~ c3*EVD + c4*UNC + c5*TH100 + c6*CC100 + c7*CD100 + c8*lag_SPHM + c9*NEG 

  # Effets indirects
  indirect_effct := c1*c3 
  indirect_effct5 := c1*c2*c9
'

# Adjusting data to models
fit <- sem(model_spec, data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])

# Define the export path and file name
file_name <- "QC.unc.results_SEM.txt"
full_path <- file.path(export_path, file_name)

# Export the summary
summary(fit)
summary_results <- capture.output(summary(fit))
writeLines(summary_results, full_path)


# CREATING SEM PLOT #
file_name <- "QC.unc.results_SEM_plot.png"
full_path <- file.path(export_path, file_name)

# Start PNG device
png(filename = full_path, width = 800, height = 600)

# Obtain the p-values of the parameters
pvalues <- parameterEstimates(fit)$pvalue
pvalues[is.na(pvalues)] <- 1  

# Determine the colors of the edges according to significance
sigEdges <- ifelse(pvalues < 0.05, "red", ifelse(pvalues >= 0.05 & pvalues < 0.1, "orange", "black"))

# Create the graph with an even larger size and smaller edge labels
semPaths(fit, 
         what = "paths",
         whatLabels = "est.std", 
         edge.label.cex = 0.6,  
         edge.width = 2, 
         layout = "tree",
         style = "lisrel",  
         curveAdjacent = TRUE,
         nCharNodes = 0,
         edge.color = sigEdges,
         edge.label.color = sigEdges,
         manifests = c("EVD", "lead_SPHM", "UNC", "TH100", "CC100", "CD100", "lag_SPHM", "NEG") 
)

# Get parameter estimates (if needed, but unrelated to plot)
params <- parameterEstimates(fit)

# Close the PNG device
dev.off()

# Print
semPaths(fit, 
         what = "paths",
         whatLabels = "est.std", 
         edge.label.cex = 0.6,  
         edge.width = 2, 
         layout = "tree",
         style = "lisrel",  
         curveAdjacent = TRUE,
         nCharNodes = 0,
         edge.color = sigEdges,
         edge.label.color = sigEdges,
         manifests = c("EVD", "lead_SPHM", "UNC", "TH100", "CC100", "CD100", "lag_SPHM", "NEG") 
)