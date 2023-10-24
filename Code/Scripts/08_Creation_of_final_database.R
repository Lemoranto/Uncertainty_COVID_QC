# Packages
#  Packages 
library(tidyverse)
library(dplyr)
library(readxl)

# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"

# Load the datasets
QC_data_file <- file.path(import_data_path, "QC.IRPPstringency_data")
QC_data <- read.csv(QC_data_file, stringsAsFactors = FALSE) 

Unc_persdict_file <- file.path(import_data_path, "QC.unc_data_persanddict_daily.csv")
Unc_persdict <- read.csv(Unc_persdict_file, stringsAsFactors = FALSE, sep=",")

hospi_file <- file.path(import_data_path, "QC.COVID_data.xlsx")
hospi <- read_excel(hospi_file, sheet = 1)

vacc_file <- file.path(import_data_path, "QC.vax_data.csv")
vacc <- read_csv2(vacc_file)



# Standardize dates by creating an ID identifier variable

# Load the 'hospi', 'vacc', 'Unc_persdict', and 'QC_data' datasets
library(dplyr)
Unc_persdict$ID <- NULL
# Convert the 'date' variable to 'datetime' in the 'vacc' dataset
vacc$date <- as.POSIXct(vacc$date, format="%Y-%m-%d")
# Convert the 'date' variable to 'datetime' in the 'Unc_persdict' dataset
Unc_persdict$date <- as.POSIXct(Unc_persdict$date, format="%Y-%m-%d")
# Convert the 'date' variable to 'datetime' in the 'QC_data' dataset
QC_data$date <- as.POSIXct(QC_data$date, format="%Y-%m-%d")
# Convert the 'date' variable to 'date' in the 'Unc_persdict' dataset
Unc_persdict$date <- as.Date(Unc_persdict$date, format="%Y-%m-%d %H:%M:%S")
# Convert the 'date' variable to 'date' in the 'QC_data' dataset
QC_data$date <- as.Date(QC_data$date, format="%Y-%m-%d %H:%M:%S")
# Create a vector of all dates
all_dates <- sort(unique(c(hospi$date, vacc$date, Unc_persdict$date, QC_data$date)))
# Create a lookup table for dates and IDs
date_id_table <- data.frame(date = all_dates, ID = seq_along(all_dates))
# Merge the lookup tables with the datasets
hospi <- left_join(hospi, date_id_table, by = "date")
vacc <- left_join(vacc, date_id_table, by = "date")
Unc_persdict <- left_join(Unc_persdict, date_id_table, by = "date")
QC_data <- left_join(QC_data, date_id_table, by = "date")
QC_data$ID <- as.numeric(QC_data$ID)
vacc$ID <- as.numeric(vacc$ID)
Unc_persdict$ID <- as.numeric(Unc_persdict$ID)
hospi$ID <- as.numeric(hospi$ID)


# Merge datasets and fill in dates with ID
QC.unc.data_merge <- QC_data[,c("ID","date","stringencyPHM", "stringencyIndex")]
QC.unc.data_merge <- merge(QC.unc.data_merge, Unc_persdict[, c("ID", "EXP", "PolDicFullneg", "UDictFull")], by = "ID", all = TRUE, na.rm = TRUE)
QC.unc.data_merge <- merge(QC.unc.data_merge, hospi[, c("ID", "hospi_total", "cases", "death")], by = "ID", all = TRUE, na.rm = TRUE)
QC.unc.data_merge <- merge(QC.unc.data_merge, vacc[, c("ID", "VAX")], by = "ID", all = TRUE, na.rm = TRUE)
QC.unc.data_merge$date <- as.Date("2020-02-27") + (QC.unc.data_merge$ID - 1)

# Create a 'wave' variable identifying each wave
QC.unc.data_daily <- QC.unc.data_merge
QC.unc.data_daily$wave = ifelse(QC.unc.data_daily$date >= as.Date("2020-02-25") & QC.unc.data_daily$date <= as.Date("2020-07-11"), 1,
                                ifelse(QC.unc.data_daily$date >= as.Date("2020-07-12") & QC.unc.data_daily$date <= as.Date("2021-03-20"), 2,
                                       ifelse(QC.unc.data_daily$date >= as.Date("2021-03-21") & QC.unc.data_daily$date <= as.Date("2021-07-17"), 3,
                                              ifelse(QC.unc.data_daily$date >= as.Date("2021-07-18") & QC.unc.data_daily$date <= as.Date("2021-12-05"), 4,
                                                     ifelse(QC.unc.data_daily$date >= as.Date("2021-12-06") & QC.unc.data_daily$date <= as.Date("2022-03-17"), 5,
                                                            ifelse(QC.unc.data_daily$date >= as.Date("2021-03-18") & QC.unc.data_daily$date <= as.Date("2022-05-28"), 6,
                                                                   NA))))))

# Rename variables
QC.unc.data_daily <- rename(QC.unc.data_daily,
                            SPHM = "stringencyPHM", 
                            SI = "stringencyIndex",
                            TH = "hospi_total",
                            CC = "cases",
                            CD = "death")



# Rescale hostpialization to 100 (TH100)
QC.unc.data_daily$TH100 <- ifelse(is.na(QC.unc.data_daily$TH),NA,(QC.unc.data_daily$TH-min(QC.unc.data_daily$TH,na.rm=T))/(max(QC.unc.data_daily$TH,na.rm=T)-min(QC.unc.data_daily$TH,na.rm=T))*100)

# Rescale vaccination to 100 (VAX100)
QC.unc.data_daily$VAX100 <- ifelse(is.na(QC.unc.data_daily$VAX),NA,(QC.unc.data_daily$VAX-min(QC.unc.data_daily$VAX,na.rm=T))/(max(QC.unc.data_daily$VAX,na.rm=T)-min(QC.unc.data_daily$VAX,na.rm=T))*100)

# Rescale Cases to 100 (CC100)
QC.unc.data_daily$CC100 <- ifelse(is.na(QC.unc.data_daily$CC),NA,(QC.unc.data_daily$CC-min(QC.unc.data_daily$CC,na.rm=T))/(max(QC.unc.data_daily$CC,na.rm=T)-min(QC.unc.data_daily$CC,na.rm=T))*100)

# Rescale Death to 100 (CD100)
QC.unc.data_daily$CD100 <- ifelse(is.na(QC.unc.data_daily$CD),NA,(QC.unc.data_daily$CD-min(QC.unc.data_daily$CD,na.rm=T))/(max(QC.unc.data_daily$CD,na.rm=T)-min(QC.unc.data_daily$CD,na.rm=T))*100)

# Delete lines after the last value of SPHM
QC.unc.data_daily <- QC.unc.data_daily %>% filter(ID <= 810)


# Export database
output_file <- file.path(export_path, "QC.unc.redux_daily.csv")
write.csv(QC.unc.data_daily, file = output_file, row.names = FALSE)
