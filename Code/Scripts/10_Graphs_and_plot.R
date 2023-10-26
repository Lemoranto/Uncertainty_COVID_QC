# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Results"

# Importing the database 
input_file <- file.path(import_data_path, "QC.unc.data_daily.csv")
reg_data_daily <- read.csv(input_file, header = TRUE, sep=",")



## CREATING THE GENERAL GRAPH ##

# Packages
library(ggplot2)
library(scales)
library(tidyverse)

# Graph
reg_data_daily$date <- as.Date(reg_data_daily$date)
wave_dates <- c("2020-02-25", "2020-08-23", "2021-03-20", "2021-07-17", "2021-12-05", "2022-03-12")
wave_labels <- c("Wave 1", "Wave 2", "Wave 3", "Wave 4", "Wave 5", "Wave 6")
se_fill <- "#D3D3D3" 

p <- ggplot(data = reg_data_daily, aes(x = date)) +
  geom_smooth(aes(y = SPHM, color = "Stringency"), method = "loess", span = 0.37, se = FALSE, size = 2.3) +
  geom_smooth(aes(y = EVD, color = "Evidence"), method = "loess", span = 0.37, se = FALSE, size = 2.3) +
  geom_smooth(aes(y = UNC, color = "Uncertainty"), method = "loess", span = 0.37, se = FALSE, size = 2.3) +
  geom_smooth(aes(y = NEG, color = "Negative sentiments"), method = "loess", span = 0.37, se = FALSE, size = 2.3) +
  scale_color_manual(name = NULL, 
                     values = c("Stringency" = "#df0806",
                                "Uncertainty" = "black",
                                "Evidence" = "#006400",
                                "Negative sentiments" = "grey",
                                "Uncertainty" = "black"),
                     breaks = c("Stringency", "Projections", "Uncertainty", "Negative sentiments", "Evidence")) +
  scale_y_continuous(limits = c(0, NA)) +
  theme(plot.title = element_text(face = "bold", size = 25, hjust = 0.5),
        axis.text.y = element_text(face = "bold", size = 25),
        legend.text = element_text(face = "bold", size = 25),
        legend.key.size = unit(1.8, "cm"),
        legend.position = "top",  
        legend.background = element_rect(fill = "#DCDCDC", color = "black"), 
        legend.key = element_rect(fill = "#DCDCDC", color = NA),
        axis.title.x = element_blank(),  
        axis.title.y = element_blank(),  
        axis.text.x = element_text(face = "bold", angle = 45, hjust = 1, size = 25),
        legend.justification = c(0.5, 0.5), legend.box.just = "center") +
  guides(color = guide_legend(nrow = 1)) +
  geom_vline(xintercept = as.Date(wave_dates), linetype = "dashed", color = "black") +
  annotate("text", x = as.Date(c("2020-05-01", "2020-11-15", "2021-04-28", "2021-09-05", "2022-01-01", "2022-04-12")), y = Inf, label = wave_labels, vjust = 2, hjust = 0, size = 7, color = "black", fontface = "bold") +
  scale_x_date(breaks = seq(as.Date("2020-03-01"), as.Date("2022-06-01"), by = "1 month"), date_labels = "%b-%Y")  

print(p)

## Export the graph
ggsave(filename = "QC.unc.results_Graph.pdf", plot = p, path = export_path, width = 16, height = 12, units = "in")





## CREATING THE PROJECTION PLOT FROM OLS4 ##

# Load the ggplot2 library for graphics
library(ggplot2)
library(dplyr)

# Models
models <- list()
models[['OLS1']] = lm(lead(SPHM, 1) ~ UNC+CD100+CC100+TH100+lag(SPHM, 1), data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])
models[['OLS2']] = lm(lead(SPHM, 1) ~ UNC+NEG+CD100+CC100+TH100+lag(SPHM, 1), data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])
models[['OLS3']] = lm(lead(SPHM, 1) ~ UNC+EVD+CD100+CC100+TH100+NEG+lag(SPHM, 1), data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])
models[['OLS4']] = lm(lead(SPHM, 1) ~ UNC+EVD+CD100+CC100+TH100+NEG+UNC:EVD+lag(SPHM, 1), data = reg_data_daily[reg_data_daily$wave %in% c(1,2,3,4,5),])

# Extracting coefficients from the OLS4 model
coefficients_OLS4 <- coef(models[['OLS4']])

## Using extracted coefficients in the simulation

# Create a dataframe to store the simulated values
simulation_data_EVD <- data.frame()

# Define UNC levels to use in the simulation
levels_UNC <- seq(0, 100, by = 20)  # Example: levels from 0 to 100 in steps of 20

# Loop to fill the dataframe with simulated values
for(UNC_val in levels_UNC) {
  EVD_vals <- seq(0, 100, by = 1)  # Generate a sequence of values for EVD
  SPHM_simulated <- coefficients_OLS4['(Intercept)'] +
    coefficients_OLS4['UNC'] * UNC_val +
    coefficients_OLS4['EVD'] * EVD_vals +
    coefficients_OLS4['UNC:EVD'] * UNC_val * EVD_vals
  
  # Add the data to the dataframe
  temp_data <- data.frame(EVD = EVD_vals, SPHM = SPHM_simulated, UNC = UNC_val)
  simulation_data_EVD <- rbind(simulation_data_EVD, temp_data)
}

# Plotting
p <- ggplot(simulation_data_EVD, aes(x = EVD, y = SPHM, color = as.factor(UNC))) +
  geom_line(size = 1.5) + 
  labs(title = "Effect of Evidence on Policy Stringency as a Function of Uncertainty",
       x = "Evidence Level",
       y = "Projected Stringency",
       color = "Uncertainty Level") +
  theme_minimal() +
  theme(
    plot.title = element_text(size = 20),
    axis.title.x = element_text(size = 17),
    axis.title.y = element_text(size = 17),
    axis.text.x = element_text(size = 17)
  )  

print(p)

# Export the plot
ggsave(filename = "QC.unc.results_OLS4_projection.pdf", plot = p, path = export_path, width = 10, height = 8)





