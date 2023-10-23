library(readtext)
library(dplyr)
library(stringr)

# Base path
import_texts_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Press_conferences"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"


# Press conferences from the National Assembly website
dir1 <- file.path(import_texts_path, "Texts_assnat")
files1 <- list.files(dir1, pattern = "*.txt", full.names = TRUE)
docs1 <- lapply(files1, readLines)
docs1 <- lapply(docs1, function(lines) {
  text <- paste(lines, collapse = "\n")
  text <- gsub("\r", "", text)
  text <- gsub("\n", " ", text)
  text
})

# Missing press conferences given by the government
dir3 <- file.path(import_texts_path, "Texts_manquants")
files3 <- list.files(dir3, pattern = "*.docx", full.names = TRUE)
docs3 <- readtext(files3)
docs3 <- lapply(docs3$text, function(text) {
  text <- gsub("\r", "", text)
  text <- gsub("\n", " ", text)
  text
})

# Press briefings 
dir4 <- file.path(import_texts_path, "Texts_pointspresse")
files4 <- list.files(dir4, pattern = "*.txt", full.names = TRUE)
docs4 <- lapply(files4, readLines)
docs4 <- lapply(docs4, function(lines) {
  text <- paste(lines, collapse = "\n")
  text <- gsub("\r", "", text)
  text <- gsub("\n", " ", text)
  text
})

# Transcripted missing press conferences 
dir5 <- file.path(import_texts_path, "Texts_youtube")
files5 <- list.files(dir5, pattern = "*.txt", full.names = TRUE)
docs5 <- lapply(files5, readLines)
docs5 <- lapply(docs5, function(lines) {
  text <- paste(lines, collapse = "\n")
  text <- gsub("\r", "", text)
  text <- gsub("\n", " ", text)
  text
})

# Press conferences before 2020
dir6 <- file.path(import_texts_path, "Texts_before_2020")
files6 <- list.files(dir6, pattern = "*.txt", full.names = TRUE)
docs6 <- lapply(files6, readLines)
docs6 <- lapply(docs6, function(lines) {
  text <- paste(lines, collapse = "\n")
  text <- gsub("\r", "", text)
  text <- gsub("\n", " ", text)
  text
})

# Other press conferences from the National Assembly website
dir7 <- file.path(import_texts_path, "Texts_assnat_ministres")
files7 <- list.files(dir7, pattern = "*.txt", full.names = TRUE)
docs7 <- lapply(files7, readLines)
docs7 <- lapply(docs7, function(lines) {
  text <- paste(lines, collapse = "\n")
  text <- gsub("\r", "", text)
  text <- gsub("\n", " ", text)
  text
})

# Combining lists
docs <- c(docs1, docs3, docs4, docs5, docs6, docs7)
files <- c(files1, files3, files4, files5, files6, files7)

# Creating a dataframe
QC.conf_texts <- data.frame(doc_ID = basename(files), conf_txt = unlist(docs))

# Adding identififaction variables
QC.conf_texts <- QC.conf_texts %>%
  mutate(Points_presse_conf = as.integer(grepl("Texts_pointspresse", files)))

QC.conf_texts <- QC.conf_texts %>%
  mutate(Youtube_conf = as.integer(grepl("Texts_youtube", files)))

QC.conf_texts <- QC.conf_texts %>%
  mutate(Before_2020_conf = as.integer(grepl("Texts_before_2020", files)))

QC.conf_texts <- QC.conf_texts %>%
  mutate(Ministres_conf = as.integer(grepl("Texts_assnat_ministres", files)))

# Deleting small texts
QC.conf_texts <- QC.conf_texts %>% 
  mutate(word_count = str_count(conf_txt, "\\w+")) %>% 
  filter(word_count >= 10)

# Cleaning files names
QC.conf_texts$doc_ID <- sub("\\.txt", "", QC.conf_texts$doc_ID)
QC.conf_texts$doc_ID <- sub("\\.docx", "", QC.conf_texts$doc_ID)
QC.conf_texts$doc_ID <- sub("\\Transcription_", "", QC.conf_texts$doc_ID)

# Converting dates
QC.conf_texts$date <- as.Date(ifelse(grepl("_", QC.conf_texts$doc_ID), 
                                     gsub("_", " ", QC.conf_texts$doc_ID), 
                                     NA), 
                              format = "%Y %m %d")

# Creating 'date_str' variable for 'aaaa_mm_jj' format
QC.conf_texts$date_str <- ifelse(grepl("_", QC.conf_texts$doc_ID), 
                                 gsub("_", " ", QC.conf_texts$doc_ID), 
                                 NA)

# Suppressing '_'
QC.conf_texts$doc_ID <- gsub("_", "", QC.conf_texts$doc_ID)

# Creating 'counter'
QC.conf_texts$counter <- ave(QC.conf_texts$doc_ID, QC.conf_texts$doc_ID, FUN = seq_along)

# Adding counter to each date to make a unique ID
QC.conf_texts$doc_ID <- paste0(QC.conf_texts$doc_ID, QC.conf_texts$counter)

# Deleting 'counter' and other useless variables
QC.conf_texts <- QC.conf_texts %>% select(-counter)
QC.conf_texts$date_str<-NULL
QC.conf_texts$word_count<-NULL

# Formating dates into %d/%m/%Y format
QC.conf_texts$date <- as.Date(QC.conf_texts$date, format = "%d/%m/%Y", origin="1970-01-01")

# Deleting conferences before 2020
QC.conf_texts <- QC.conf_texts %>%
  filter(date >= as.Date("2020-03-01"))

# Exporting textual database
output_file <- file.path(export_path, "QC.conf_texts.csv")
write.csv(QC.conf_texts, file = output_file, row.names = FALSE)
