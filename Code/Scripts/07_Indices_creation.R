# Packages
library(tidyverse)
library(dplyr)
library(readxl)

# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
dictionary_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Dictionnaries"


# Importing the database and deleting useless variables
input_file <- file.path(import_data_path, "QC.conf_fullannotated.csv")
QC.unc.data_persanddict <- read.csv(input_file, header = TRUE, sep=",")

QC.unc.data_persanddict$X<-NULL
QC.unc.data_persanddict$X.1<-NULL
QC.unc.data_persanddict$X.2<-NULL
QC.unc.data_persanddict$X.3<-NULL
QC.unc.data_persanddict$X.4<-NULL
QC.unc.data_persanddict$X.5<-NULL


# Deleting useless transcripts (small press briefings and conferences before 2020)
-QC.unc.data_persanddict <- subset(QC.unc.data_persanddict, Points_presse_conf != 1)
QC.unc.data_persanddict <- QC.unc.data_persanddict %>%
  filter(date >= as.Date("2020-01-01"))

# Creating a variable named 'Journalist' identifiying journalists speakers
variables <- c("presse_canadienne", "Noovo", "cogeco", "Journal_de_québec",
               "Devoir", "TVA", "Radio_Canada", "Journal_de_Montréal", "La_Presse", "Le_soleil", "X98.5")
QC.unc.data_persanddict <- QC.unc.data_persanddict %>%
  mutate(Journalist = ifelse(rowSums(select(., all_of(variables))) >= 1, 1, 0))


# Create a reduced database containing only one row per sentence named QC.unc.data_persanddict_redux   

# Reduce the QC.unc.data_persanddict database to a single row per 
# identifier using 'unique_phrase_id', while retaining the variables that 
# identify the sentences 'unique_phrase_id', 'doc_id', and 'date', and 
# filling the NAs with 0s

QC.unc.data_persanddict_redux <- QC.unc.data_persanddict %>%
  group_by(unique_phrase_id, doc_id, date, sentence_id) %>%
  summarize(across(c(uncertainty, Boileau, COVID, evidence, anti, groups_large, 
                     groups_eco, hospitals, measures, polarity_sentence, implementation, vaccination, CIQ, Legault, Dubé, 
                     Arruda, Guilbault, McCann, Massé, Opatrny, couvre_feu, Journalist), 
                   ~ if (cur_column() == "polarity_sentence") first(.) else as.integer(any(. == 1, na.rm = TRUE))))



# Creating the variable dictionary (positive for one category), dictionary_strong (positive for two without vaccination), 
# dictionary_full (with vaccination) 

QC.unc.data_persanddict_redux$dictionary <- as.integer(rowSums
                                                       (QC.unc.data_persanddict_redux[c
                                                       ("evidence", "anti", "groups_eco", 
                                                       "hospitals", "measures", "implementation", "COVID")]) > 0)

QC.unc.data_persanddict_redux$dictionary_strong <- as.integer(rowSums(
                                                  QC.unc.data_persanddict_redux[c(
                                                  "evidence", "groups_large", "hospitals", 
                                                  "measures", "implementation", "COVID")]) >= 2 & 
                                                  QC.unc.data_persanddict_redux$vaccination != 1)

QC.unc.data_persanddict_redux$dictionary_full <- as.integer(rowSums
                                                 (QC.unc.data_persanddict_redux
                                                 [c("evidence", "anti", "groups_large", 
                                                 "groups_eco", "hospitals", "measures", 
                                                 "implementation", "vaccination", "CIQ", "COVID")]) > 0)

# Importing sentences
QC.unc.data_persanddict_filtered <- QC.unc.data_persanddict %>%
  filter(token_id == 1) %>%
  select(unique_phrase_id, sentence)

# Joining with QC.unc.data_persanddict_redux
QC.unc.data_persanddict_redux <- left_join(QC.unc.data_persanddict_redux, 
                                           QC.unc.data_persanddict_filtered, 
                                           by = "unique_phrase_id")


# Cleaning the database 

# Deleting McCann (health minister) after her resignation on 22/06/2020
QC.unc.data_persanddict_redux$McCann[QC.unc.data_persanddict_redux$McCann == 1 & 
                                       QC.unc.data_persanddict_redux$date > "2020-06-22"] <- NA

# When no policymakers is present and there is duplicates, delete
QC.unc.data_persanddict_redux <- QC.unc.data_persanddict_redux %>%
  group_by(date, doc_id) %>%
  filter(!all(Legault == 0 & Dubé == 0 & Arruda == 0 & Boileau == 0 & McCann == 0 & Guilbault == 0 & Massé == 0 & Opatrny == 0)) %>%
  ungroup()


# VARIABLES CREATIONS

# Generate all uncertainty count variables as well as the creation of 
# variables by type of speaker: executive (Legault, Dubé, McCann, Guilbault), 
# public health (Arruda, Boileau), and complete (Legault, Dubé, McCann, Guilbault, Arruda, Boileau)

uncertainty_count_persons <- QC.unc.data_persanddict_redux %>%
  group_by(doc_id, date) %>%
  summarize(
    
    # Sentences count
    sentence_count = n_distinct(sentence_id),
    Arruda_sentence_count = n_distinct(sentence_id[Arruda==TRUE]),
    Boileau_sentence_count = n_distinct(sentence_id[Boileau==TRUE]),
    McCann_sentence_count = n_distinct(sentence_id[McCann==TRUE]),
    Guilbault_sentence_count = n_distinct(sentence_id[Guilbault==TRUE]),
    Legault_sentence_count = n_distinct(sentence_id[Legault==TRUE]),
    Dubé_sentence_count = n_distinct(sentence_id[Dubé==TRUE]),
    Massé_sentence_count = n_distinct(sentence_id[Massé==TRUE]),
    Opatrny_sentence_count = n_distinct(sentence_id[Opatrny==TRUE]),
    
    # Sentences and uncertainty count per speaker
    Legault_dictionary_strong_count = sum(Legault & dictionary_strong & uncertainty, na.rm = TRUE),
    Arruda_dictionary_strong_count = sum(Arruda & dictionary_strong & uncertainty, na.rm = TRUE),
    Dubé_dictionary_strong_count = sum(Dubé & dictionary_strong & uncertainty, na.rm = TRUE),
    Boileau_dictionary_strong_count = sum(Boileau & dictionary_strong & uncertainty, na.rm = TRUE),
    McCann_dictionary_strong_count = sum(McCann & dictionary_strong & uncertainty, na.rm = TRUE),
    Guilbault_dictionary_strong_count = sum(Guilbault & dictionary_strong & uncertainty, na.rm = TRUE),
    Opatrny_dictionary_strong_count = sum(Opatrny & dictionary_strong & uncertainty, na.rm = TRUE),
    Massé_dictionary_strong_count = sum(Massé & dictionary_strong & uncertainty, na.rm = TRUE),
    
    # Proportions per speaker
    Legault_uncertaintydictionary_per_sentence = sum(Legault_dictionary_strong_count, na.rm = TRUE) / Legault_uncertainty_count,
    Arruda_uncertaintydictionary_per_sentence = sum(Arruda_dictionary_strong_count, na.rm = TRUE) / Arruda_uncertainty_count,
    Dubé_uncertaintydictionary_per_sentence = sum(Dubé_dictionary_strong_count, na.rm = TRUE) / Dubé_uncertainty_count,
    Boileau_uncertaintydictionary_per_sentence = sum(Boileau_dictionary_strong_count, na.rm = TRUE) / Boileau_uncertainty_count,
    Guilbault_uncertaintydictionary_per_sentence = sum(Guilbault_dictionary_strong_count, na.rm = TRUE) / Guilbault_uncertainty_count,
    McCann_uncertaintydictionary_per_sentence = sum(McCann_dictionary_strong_count, na.rm = TRUE) / McCann_uncertainty_count,
    Opatrny_uncertaintydictionary_per_sentence = sum(Opatrny_dictionary_strong_count, na.rm = TRUE) / Opatrny_uncertainty_count,
    Massé_uncertaintydictionary_per_sentence = sum(Massé_dictionary_strong_count, na.rm = TRUE) / Massé_uncertainty_count)

# Adding the variable for proportion of sentences with negative polarity + dictionary
uncertainty_count_persons <- uncertainty_count_persons %>%
  left_join(QC.unc.data_persanddict_redux %>%
              group_by(doc_id) %>%
              summarise(negative_polarity_dictionary_count = sum(polarity_sentence < 0 & dictionary_strong == 1 & (Legault == 1 | Dubé == 1 | McCann == 1 | Guilbault == 1)),
                        total_dictionary_count_2 = sum(dictionary_strong == 1 & (Legault == 1 | Dubé == 1 | McCann == 1 | Guilbault == 1))),
            by = "doc_id") %>%
  mutate(PolDicFullneg = (negative_polarity_dictionary_count / total_dictionary_count_2)*100)

# Adding the variable for proportion of sentences with evidence + dictionary
uncertainty_count_persons <- uncertainty_count_persons %>%
  left_join(QC.unc.data_persanddict_redux %>%
              group_by(doc_id) %>%
              summarise(evidence_count = sum(evidence == 1 & dictionary_strong == 1  & (Legault == 1 | Dubé == 1 | McCann == 1 | Guilbault == 1)),
                        total_evidence_count = sum(dictionary_strong == 1 & (Legault == 1 | Dubé == 1 | McCann == 1 | Guilbault == 1))),
            by = "doc_id") %>%
  mutate(EXP = (evidence_count / total_evidence_count)*100)

# Deleting count errors
variables <- c("Arruda_sentence_count", "Legault_sentence_count", "Boileau_sentence_count", "McCann_sentence_count",
               "Guilbault_sentence_count", "Dubé_sentence_count", "Massé_sentence_count", "Opatrny_sentence_count")
uncertainty_count_persons <- uncertainty_count_persons %>%
  mutate(across(all_of(variables), ~ifelse(. <= 6, 0, .)))




# Creating a unique identifier variable 'ID' to facilitate analysis
# based on the date across all databases

# Lading all databases (stringency and epidemiological data)
QC_data_file <- file.path(import_data_path, "QC.IRPPstringency_data")
QC_data <- read.csv(QC_data_file)

hospi_file <- file.path(import_data_path, "QC.COVID_data.xlsx")
hospi <- read_excel(hospi_file, sheet = 1)

vacc_file <- file.path(import_data_path, "QC.vax_data.csv")
vacc <- read_csv2(vacc_file)

# Convert the 'date' variable to 'datetime' in the 'vacc' dataset
vacc$date <- as.POSIXct(vacc$date, format="%Y-%m-%d")

# Convert the 'date' variable to 'datetime' in the 'uncertainty_count_persons' dataset
uncertainty_count_persons$date <- as.POSIXct(uncertainty_count_persons$date, format="%Y-%m-%d")

# Convert the 'date' variable to 'datetime' in the 'QC_data' dataset
QC_data$date <- as.POSIXct(QC_data$date, format="%Y-%m-%d")

# Convert the 'date' variable to 'date' in the 'uncertainty_count_persons' dataset
uncertainty_count_persons$date <- as.Date(uncertainty_count_persons$date, format="%Y-%m-%d %H:%M:%S")

# Convert the 'date' variable to 'date' in the 'QC_data' dataset
QC_data$date <- as.Date(QC_data$date, format="%Y-%m-%d %H:%M:%S")

# Create a vector of all dates
all_dates <- sort(unique(c(hospi$date, vacc$date, uncertainty_count_persons$date, QC_data$date)))

# Create a lookup table for dates and IDs
date_id_table <- data.frame(date = all_dates, ID = seq_along(all_dates))

# Merge the lookup tables with the datasets
hospi <- left_join(hospi, date_id_table, by = "date")
vacc <- left_join(vacc, date_id_table, by = "date")
uncertainty_count_persons <- left_join(uncertainty_count_persons, date_id_table, by = "date")
QC_data <- left_join(QC_data, date_id_table, by = "date")
QC_data$ID <- as.numeric(QC_data$ID)
vacc$ID <- as.numeric(vacc$ID)
uncertainty_count_persons$ID <- as.numeric(uncertainty_count_persons$ID)
hospi$ID <- as.numeric(hospi$ID)


# Delete the duplicates from a dictionary (manual annotation)

# Load the dictionary
dictionary_file <- file.path(dictionary_path, "Dictionary", "QC.unc.dictionary_doublons_v2.csv")
dictionary <- read.csv2(dictionary_file, stringsAsFactors = FALSE, sep=";")

# Merge dataframes on 'doc_id'
df <- merge(uncertainty_count_persons, dictionary, by = 'doc_id', all.x = TRUE)

# Split into three parts
df_suppression <- df %>% filter(mode == "suppression")
df_fusion <- df %>% filter(mode == "fusion")

# Handle the "suppression" part
df <- df %>% filter(!doc_id %in% df_suppression$doc_id)

# Handle the "fusion" part
df_fusion <- df_fusion %>% 
  group_by(ID) %>%
  summarise(date = first(date),
            doc_id = first(doc_id),
            type = first(type),
            Locuteurs = first(Locuteurs),
            mode = first(mode),
            across(-c(date, doc_id, type, Locuteurs, mode), median, na.rm = TRUE)) %>%
  ungroup()

# Remove rows that have been merged
df <- df %>% filter(!ID %in% df_fusion$ID)

# Add the merged rows
df <- bind_rows(df, df_fusion)

# Remove dictionary columns and rename the original dataset
df <- df %>% select(-c(type, Locuteurs, mode))
uncertainty_count_persons <- df



# CREATING THE UNCERTAINTY VARIABLE

uncertainty_count_persons$full_uncdict_sen <- coalesce(uncertainty_count_persons$Legault_uncertaintydictionary_per_sentence, 0) + coalesce(uncertainty_count_persons$Dubé_uncertaintydictionary_per_sentence, 0)+ coalesce(uncertainty_count_persons$Arruda_uncertaintydictionary_per_sentence, 0)+ coalesce(uncertainty_count_persons$McCann_uncertaintydictionary_per_sentence, 0 )+ coalesce(uncertainty_count_persons$Guilbault_uncertaintydictionary_per_sentence, 0 )+ coalesce(uncertainty_count_persons$Boileau_uncertaintydictionary_per_sentence, 0 )
uncertainty_count_persons$full_uncdict_sen[uncertainty_count_persons$full_uncdict_sen == 0] <- NA
ncertainty_count_persons$UDictFull <- (uncertainty_count_persons$full_uncdict_sen - min(uncertainty_count_persons$full_uncdict_sen, na.rm = TRUE)) / (max(uncertainty_count_persons$full_uncdict_sen, na.rm = TRUE) - min(uncertainty_count_persons$full_uncdict_sen, na.rm = TRUE)) * 100 
uncertainty_count_persons[is.na(uncertainty_count_persons)] <- NA


# Export database
output_file <- file.path(export_path, "QC.unc_data_persanddict_daily.csv")
write.csv(uncertainty_count_persons, file = output_file, row.names = FALSE)



# Check for remaining duplicates (two conferences on the same day)
# based on the date across all datasets

doublons <- uncertainty_count_persons %>%
  group_by(ID) %>%
  filter(n() > 1) %>%
  select(date, UDictFull, doc_id)

# Reduce the dataset to selected columns
redux <- uncertainty_count_persons %>% select(ID, date, UDictFull)


# Validate the variables

library(dplyr)

# Randomly select 100 rows based on the specified conditions
EXP_validate <- QC.unc.data_persanddict_redux %>%
  filter(evidence == 1 & dictionary_strong == 1 & (Legault == 1 | Dubé == 1 | McCann == 1 | Guilbault == 1)) %>%
  select(date, doc_id, unique_phrase_id, sentence) %>%
  sample_n(100)

# Save the dataframe as .csv
output_file <- file.path(export_path, "EXP_validate.csv")
write.csv(EXP_validate, file = output_file, row.names = FALSE)

# Randomly select 100 rows based on the new conditions
UDictFull_validate <- QC.unc.data_persanddict_redux %>%
  filter(uncertainty == 1 & dictionary_strong == 1 & (Legault == 1 | Dubé == 1 | McCann == 1 | Guilbault == 1 | Arruda == 1 | Boileau == 1)) %>%
  select(date, doc_id, unique_phrase_id, sentence) %>%
  sample_n(100)

# Save the new dataframe as .csv
output_file <- file.path(export_path, "UDictFull_validate.csv")
write.csv(UDictFull_validate, file = output_file, row.names = FALSE)

# Randomly select 100 rows based on the specified conditions for PolDicFullneg
PolDicFullneg_validate <- QC.unc.data_persanddict_redux %>%
  filter(polarity_sentence < 0 & dictionary_strong == 1 & (Legault == 1 | Dubé == 1 | McCann == 1 | Guilbault == 1)) %>%
  select(date, doc_id, unique_phrase_id, sentence) %>%
  sample_n(100)

# Save the new dataframe as .csv
output_file <- file.path(export_path, "PolDicFullneg_validate.csv")
write.csv(PolDicFullneg_validate, file = output_file, row.names = FALSE)
