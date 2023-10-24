# Packages
library(readtext)
library(dplyr)
library(udpipe)
library(dplyr)
library(cld3)
library(dplyr)
library(stringr)
library(readr)
library(quanteda)
library(tidyverse)


# Base path
import_texts_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Press_conferences"
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
model_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Udpipe"
dictionary_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Dictionnaries"

## TEXTUAL DATABASE ##

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






## TOKENIZATION AND UNCERTAINTY DETECTION ##

# Import textual database
input_file <- file.path(import_data_path, "QC.conf_texts.csv")
QC.conf_texts <- read.csv(input_file, header = TRUE, sep=",")

# Downloading French udpipe model
udpipe_download_model(language = "french", model_dir = model_path)

# Loading model
model_file <- file.path(model_path, "french-gsd-ud-2.5-191206.udpipe")
model <- udpipe_load_model(model_file)

# Tokenization
annotated_data <- udpipe_annotate(model, x = QC.conf_texts$conf_txt, doc_id = QC.conf_texts$doc_ID)
QC.conf_tokenised <- as.data.frame(annotated_data)

# Adding dates to the database
QC.conf_tokenised$date <- QC.conf_texts$date[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]
QC.conf_tokenised$Points_presse_conf <- QC.conf_texts$Points_presse_conf[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]
QC.conf_tokenised$Youtube_conf <- QC.conf_texts$Youtube_conf[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]
QC.conf_tokenised$Ministres_conf <- QC.conf_texts$Ministres_conf[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]

# Detection of foreign languages
QC.conf_tokenised <- QC.conf_tokenised %>%
  mutate(lang = detect_language(sentence))

# Suppresing english sentences
english_sentences <- QC.conf_tokenised %>%
  filter(grepl("en", lang)) %>%
  group_by(doc_id, sentence_id) %>%
  slice_head(n = 1)

QC.conf_tokenised_english <- english_sentences

QC.conf_tokenised <- QC.conf_tokenised %>%
  anti_join(english_sentences, by = c("doc_id", "sentence_id"))

# Uncertainty detection
QC.conf_tokenised_2 <- QC.conf_tokenised %>%
  group_by(date) %>%
  mutate(uncertainty = ifelse(grepl("Mood=Cnd", feats) | 
                                (lemma == "pouvoir" & upos == "VERB" & !grepl("Form=Inf", feats)) |
                                lemma %in% c("possible", "possiblement", "probable", "probablement", "improbable") |
                                lemma %in% c("incertain", "incertaine", "incertaines", "incertains", "incertitude", "incertitudes", "hypothèse") | # champs de l'incertitude
                                (lemma == "suspect" & upos == "ADJ") | lemma == "suspicion" | # quelque chose de suspect
                                (upos == "VERB" & (lemma == "penser" | lemma == "croire" | lemma == "espérer" | lemma == "questionner" | lemma == "soupçonner")), # verbes d'incertitude
                              1, 0))

# Exporting database
output_file <- file.path(export_path, "QC.conf_token_uncertainty.csv")
write.csv(QC.conf_tokenised_2, file = output_file, row.names = FALSE)










## POLICYMAKERS ANNOTATION ##

# Import database
input_file <- file.path(import_data_path, "QC.conf_token_uncertainty.csv")
QC.conf_token_uncertainty <- read.csv(input_file, header = TRUE, sep=",")

# Packages
library(stringr)
library(dplyr)

# Identify M. Dubé (Health minister)

dube <- 0
prev_doc_id <- QC.conf_token_uncertainty[1, "doc_id"]
for (i in 1:nrow(QC.conf_token_uncertainty)) {
  if (QC.conf_token_uncertainty[i, "doc_id"] != prev_doc_id) {
    dube <- 0
    prev_doc_id <- QC.conf_token_uncertainty[i, "doc_id"]
  }
  if (QC.conf_token_uncertainty[i, "token"] == "M." & dube == 0) {
    if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "Dubé") {
      if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
        dube <- 1
      }
    }
  } else if (dube == 1) {
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
        dube <- 0
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Dubé") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          dube <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Le" | QC.conf_token_uncertainty[i, "token"] == "La") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == "Modérateur" | QC.conf_token_uncertainty[i + 1, "token"] == "Modératrice")) {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          dube <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Journaliste") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == ":")) {
        dube <- 0
      }
    }
  }
  QC.conf_token_uncertainty[i, "Dubé"] <- dube
}

# Identify M. Legault (Prime ministre)

legault <- 0
prev_doc_id <- QC.conf_token_uncertainty[1, "doc_id"]
for (i in 1:nrow(QC.conf_token_uncertainty)) {
  if (QC.conf_token_uncertainty[i, "doc_id"] != prev_doc_id) {
    legault <- 0
    prev_doc_id <- QC.conf_token_uncertainty[i, "doc_id"]
  }
  if (QC.conf_token_uncertainty[i, "token"] == "M." & legault == 0) {
    if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "Legault") {
      if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
        legault <- 1
      }
    }
  } else if (legault == 1) {
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
        legault <- 0
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Legault") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          legault <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Le" | QC.conf_token_uncertainty[i, "token"] == "La") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == "Modérateur" | QC.conf_token_uncertainty[i + 1, "token"] == "Modératrice")) {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          legault <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Journaliste") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == ":")) {
        legault <- 0
      }
    }
  }
  QC.conf_token_uncertainty[i, "Legault"] <- legault
}        

# Identify Mrs Guilbault (Interior minister)

guilbault <- 0
prev_doc_id <- QC.conf_token_uncertainty[1, "doc_id"]
for (i in 1:nrow(QC.conf_token_uncertainty)) {
  if (QC.conf_token_uncertainty[i, "doc_id"] != prev_doc_id) {
    guilbault <- 0
    prev_doc_id <- QC.conf_token_uncertainty[i, "doc_id"]
  }
  if (QC.conf_token_uncertainty[i, "token"] == "Mme" & guilbault == 0) {
    if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "Guilbault") {
      if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
        guilbault <- 1
      }
    }
  } else if (guilbault == 1) {
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
        guilbault <- 0
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Guilbault") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          guilbault <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Le" | QC.conf_token_uncertainty[i, "token"] == "La") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == "Modérateur" | QC.conf_token_uncertainty[i + 1, "token"] == "Modératrice")) {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          guilbault <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Journaliste") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == ":")) {
        guilbault <- 0
      }
    }
  }
  QC.conf_token_uncertainty[i, "Guilbault"] <- guilbault
}    

# Identify Mrs McCann (former health minister before M. Dubé)

mccann <- 0
prev_doc_id <- QC.conf_token_uncertainty[1, "doc_id"]
for (i in 1:nrow(QC.conf_token_uncertainty)) {
  if (QC.conf_token_uncertainty[i, "doc_id"] != prev_doc_id) {
    mccann <- 0
    prev_doc_id <- QC.conf_token_uncertainty[i, "doc_id"]
  }
  if (QC.conf_token_uncertainty[i, "token"] == "Mme" & mccann == 0) {
    if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "McCann") {
      if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
        mccann <- 1
      }
    }
  } else if (mccann == 1) {
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
        mccann <- 0
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "McCann") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          mccann <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Le" | QC.conf_token_uncertainty[i, "token"] == "La") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == "Modérateur" | QC.conf_token_uncertainty[i + 1, "token"] == "Modératrice")) {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          mccann <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Journaliste") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == ":")) {
        mccann <- 0
      }
    }
  }
  QC.conf_token_uncertainty[i, "McCann"] <- mccann
}    


# Identify M. Arruda (National director of public health)

arruda <- 0
prev_doc_id <- QC.conf_token_uncertainty[1, "doc_id"]
for (i in 1:nrow(QC.conf_token_uncertainty)) {
  if (QC.conf_token_uncertainty[i, "doc_id"] != prev_doc_id) {
    arruda <- 0
    prev_doc_id <- QC.conf_token_uncertainty[i, "doc_id"]
  }
  if (QC.conf_token_uncertainty[i, "token"] == "M."| QC.conf_token_uncertainty[i, "token"] == "Dr" & arruda == 0) {
    if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "Arruda") {
      if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == "(") {
        if (i + 3 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 3, "token"] == "Horacio") {
          if (i + 4 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 4, "token"] == ")") {
            if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
              arruda <- 1
            }
          }
        }}}
  } else if (arruda == 1) {
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Horacio") {
        if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
          arruda <- 0
        }}
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Horacio") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          arruda <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Le" | QC.conf_token_uncertainty[i, "token"] == "La") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == "Modérateur" | QC.conf_token_uncertainty[i + 1, "token"] == "Modératrice")) {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          arruda <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Journaliste") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == ":")) {
        arruda <- 0
      }
    }
  }
  QC.conf_token_uncertainty[i, "Arruda"] <- arruda
}                


# Identify M. Massé (public health expert)

massé <- 0
prev_doc_id <- QC.conf_token_uncertainty[1, "doc_id"]
for (i in 1:nrow(QC.conf_token_uncertainty)) {
  if (QC.conf_token_uncertainty[i, "doc_id"] != prev_doc_id) {
    massé <- 0
    prev_doc_id <- QC.conf_token_uncertainty[i, "doc_id"]
  }
  if (QC.conf_token_uncertainty[i, "token"] == "M."| QC.conf_token_uncertainty[i, "token"] == "Dr" & massé == 0) {
    if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "Massé") {
      if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == "(") {
        if (i + 3 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 3, "token"] == "Richard") {
          if (i + 4 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 4, "token"] == ")") {
            if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
              massé <- 1
            }
          }
        }}}
  } else if (massé == 1) {
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Richard") {
        if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
          massé <- 0
        }}
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Richard") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          massé <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Le" | QC.conf_token_uncertainty[i, "token"] == "La") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == "Modérateur" | QC.conf_token_uncertainty[i + 1, "token"] == "Modératrice")) {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          massé <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Journaliste") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == ":")) {
        massé <- 0
      }
    }
  }
  QC.conf_token_uncertainty[i, "Massé"] <- massé
} 


# Identify L. Opatrny (public health expert)

opatrny <- 0
prev_doc_id <- QC.conf_token_uncertainty[1, "doc_id"]
for (i in 1:nrow(QC.conf_token_uncertainty)) {
  if (QC.conf_token_uncertainty[i, "doc_id"] != prev_doc_id) {
    opatrny <- 0
    prev_doc_id <- QC.conf_token_uncertainty[i, "doc_id"]
  }
  if (QC.conf_token_uncertainty[i, "token"] == "Mme"| QC.conf_token_uncertainty[i, "token"] == "Dr" & opatrny == 0) {
    if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "Opatrny") {
      if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == "(") {
        if (i + 3 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 3, "token"] == "Lucie") {
          if (i + 4 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 4, "token"] == ")") {
            if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
              opatrny <- 1
            }
          }
        }}}
  } else if (opatrny == 1) {
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Lucie") {
        if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
          opatrny <- 0
        }}
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Lucie") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          opatrny <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Le" | QC.conf_token_uncertainty[i, "token"] == "La") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == "Modérateur" | QC.conf_token_uncertainty[i + 1, "token"] == "Modératrice")) {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          opatrny <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Journaliste") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == ":")) {
        opatrny <- 0
      }
    }
  }
  QC.conf_token_uncertainty[i, "Opatrny"] <- opatrny
}                

# Identify Boileau (next National director of public health after M. Arruda)

boileau <- 0
prev_doc_id <- QC.conf_token_uncertainty[1, "doc_id"]
for (i in 1:nrow(QC.conf_token_uncertainty)) {
  if (QC.conf_token_uncertainty[i, "doc_id"] != prev_doc_id) {
    boileau <- 0
    prev_doc_id <- QC.conf_token_uncertainty[i, "doc_id"]
  }
  if (QC.conf_token_uncertainty[i, "token"] == "M."| QC.conf_token_uncertainty[i, "token"] == "Dr") {
    if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "Boileau") {
      if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
        boileau <- 1
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M."|QC.conf_token_uncertainty[i, "token"] == "Dr") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] == "Boileau") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == "(") {
          if (i + 3 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 3, "token"] == "Luc") {
            if (i + 4 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 4, "token"] == ")") {
              if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
                boileau <- 1
              }
            }
          }}}}
  } else if (boileau == 1) {
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Boileau") {
        if (i + 5 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 5, "token"] == ":") {
          boileau <- 0
        }}
    }
    if (QC.conf_token_uncertainty[i, "token"] == "M." | QC.conf_token_uncertainty[i, "token"] == "Mme") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 1, "token"] != "Boileau") {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          boileau <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Le" | QC.conf_token_uncertainty[i, "token"] == "La") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == "Modérateur" | QC.conf_token_uncertainty[i + 1, "token"] == "Modératrice")) {
        if (i + 2 <= nrow(QC.conf_token_uncertainty) & QC.conf_token_uncertainty[i + 2, "token"] == ":") {
          boileau <- 0
        }
      }
    }
    if (QC.conf_token_uncertainty[i, "token"] == "Journaliste") {
      if (i + 1 <= nrow(QC.conf_token_uncertainty) & (QC.conf_token_uncertainty[i + 1, "token"] == ":")) {
        boileau <- 0
      }
    }
  }
  QC.conf_token_uncertainty[i, "Boileau"] <- boileau
}    


# Export database
output_file <- file.path(export_path, "QC.conf_token_pers.csv")
write.csv(QC.conf_token_uncertainty, file = output_file, row.names = FALSE)








## DICTIONARY ANNOTATION ## 


# Importing the dictionary
dictionary_file <- file.path(dictionary_path, "QC.unc.dictionary.csv")
dictionnary <- read.csv2(dictionary_file, sep=";")

# Importing the database
input_file <- file.path(import_data_path, "QC.conf_token_pers.csv")
QC.conf_token_dict <- read.csv(input_file, header = TRUE, sep=",")

# Creating "phrase_id" qcombining "sentence_id" and "doc_id"
QC.conf_token_dict$unique_phrase_id <- paste(QC.conf_token_dict$doc_id, QC.conf_token_dict$sentence_id, sep="_")

# Search function for racine (search for the racine of the word) mode and full mode (search for the full word)
findWords <- function(words, token, mode) {
  if (mode == "racine") {
    return(any(sapply(words, function(x) if(nchar(x)>0) any(grepl(paste0("^", x), token, ignore.case = TRUE)) else FALSE)))
  } else if (mode == "complet") {
    return(any(sapply(words, function(x) if(nchar(x)>0) any(grepl(paste0("\\b", x, "\\b"), token, ignore.case = TRUE)) else FALSE)))
  } else {
    return(FALSE)
  }
}




# Search function for the "lemmes" mode
findLemmes <- function(lemmes, QC.conf_token_dict, i) {
  search_words <- unlist(strsplit(lemmes, " "))
  
  if (any(grepl(paste0("^", search_words[1], "$"), QC.conf_token_dict[i, "lemma"], ignore.case = TRUE))) {
    if (length(search_words) == 1) {
      return(TRUE)
    } else {
      next_i <- i + 1
      search_index <- 2
      while (next_i <= nrow(QC.conf_token_dict) && QC.conf_token_dict[next_i, "unique_phrase_id"] == QC.conf_token_dict[i, "unique_phrase_id"]) {
        if (any(grepl(paste0("^", search_words[search_index], "$"), QC.conf_token_dict[next_i, "lemma"], ignore.case = TRUE))) {
          if (search_index == length(search_words)) {
            return(TRUE)
          } else {
            search_index <- search_index + 1
          }
        }
        next_i <- next_i + 1
      }
    }
  }
  
  
  return(FALSE)
}



# Search function for token mode
findTokens <- function(tokens, QC.conf_token_dict, i) {
  search_words <- unlist(strsplit(tokens, " "))
  
  next_i <- i + 1
  search_index <- 2
  
  if (any(grepl(paste0("^", search_words[1], "$"), QC.conf_token_dict[i, "token"], ignore.case = TRUE))) {
    if (length(search_words) == 1) {
      return(TRUE)
    } else {
      while (next_i <= nrow(QC.conf_token_dict) && QC.conf_token_dict[next_i, "unique_phrase_id"] == QC.conf_token_dict[i, "unique_phrase_id"]) {
        if (any(grepl(paste0("^", search_words[search_index], "$"), QC.conf_token_dict[next_i, "token"], ignore.case = TRUE))) {
          search_index <- search_index + 1
          if (search_index > length(search_words)) {
            return(TRUE)
          }
        } else {
          break
        }
        next_i <- next_i + 1
      }
    }
  }
  
  return(FALSE)
}



# Apply the search functions

cols_to_check <- colnames(dictionnary)[!grepl("mode", colnames(dictionnary))]

for (i in seq_len(nrow(QC.conf_token_dict))) {
  token <- QC.conf_token_dict[i, "token"]
  lemma <- QC.conf_token_dict[i, "lemma"]
  sentence_id <- QC.conf_token_dict[i, "unique_phrase_id"]
  
  # verify each word for each category
  for (col in cols_to_check) {
    words_to_check <- dictionnary[, col]
    mode_to_check <- dictionnary[, "mode"]
    
    if (length(words_to_check) > 0) {
      word_found <- FALSE
      
      # veify if a token coressponds
      for (j in seq_along(words_to_check)) {
        word_to_check <- words_to_check[j]
        mode <- mode_to_check[j]
        if (!is.na(word_to_check) && nchar(word_to_check) > 0) {
          if (mode == "lemmes") {
            # search for lemmes
            if (findLemmes(word_to_check, QC.conf_token_dict, i)) {
              word_found <- TRUE
              break
            }
          } else if (mode == "token") {
            # search for tokens
            if (findTokens(word_to_check, QC.conf_token_dict, i)) {
              word_found <- TRUE
              break
            }
          } else {
            # search for whole words
            if (findWords(word_to_check, token, mode)) {
              word_found <- TRUE
              break
            }
          }
        }
      }
      
      # Write 1 if postivie
      if (word_found) {
        QC.conf_token_dict[i, col] <- 1
        
        
        same_phrase <- QC.conf_token_dict$unique_phrase_id == QC.conf_token_dict[i, "unique_phrase_id"]
        QC.conf_token_dict[same_phrase, col] <- 1
      }
    }
  }
}



# Exporting database
output_file <- file.path(export_path, "QC.conf_token_dictpers.csv")
write.csv(QC.conf_token_dict, file = output_file, row.names = FALSE)










## FULL SPEAKER IDENTIFICATION AND ANNOTATION ##



# IDENTIFYING ALL SPEAKERS AND ALL POLICYMAKERS

# Import database
input_file <- file.path(import_data_path, "QC.conf_token_dictpers.csv")
sample_QC.conf <- read.csv(input_file, header = TRUE, sep=",")


# Creating a dataframe to store all the present speakers
Conf_pers_full <- data.frame(Gender = integer(), Name = character(), First_name = character(), doc_id = integer(), sentence_id = integer(), sentence = character(), stringsAsFactors = FALSE)

# Search function of present speakers
for (i in 1:(nrow(sample_QC.conf) - 8)) {
  current_token <- sample_QC.conf$token[i]
  if (current_token %in% c("M.", "Mme")) {
    for (j in 1:8) {
      if (sample_QC.conf$token[i + j] == ":") {
        # Extracting gender
        Gender <- ifelse(current_token == "M.", 0, 1)
        
        # Extracting family name
        Name <- sample_QC.conf$token[i + 1]
        
        # Extracting surname if present
        if (j > 2) {
          First_name <- gsub("[()]", "", sample_QC.conf$token[i + 3])
        } else {
          First_name <- NA
        }
        
        # Extracting doc_id, sentence_id and sentence
        doc_id <- sample_QC.conf$doc_id[i]
        sentence_id <- sample_QC.conf$sentence_id[i]
        sentence <- sample_QC.conf$sentence[i]
        date <- sample_QC.conf$date[i]
        
        # Adding informations
        Conf_pers_full <- rbind(Conf_pers_full, data.frame(Gender, Name, First_name, doc_id, sentence_id, sentence, date, stringsAsFactors = FALSE))
        break
      }
    }
  }
}

# Creating Conf_pers_clean by deleting duplicates and filtering the database
exact_expressions_to_remove <- c(
  "M.", "le", "Mme", "I'm", "la", "It's", "So", "hein", "I", 
  "Is", "Mrs.", "Mr", "Di", "(", "OK", "That's", "Vien", "Ms.", "Mr.", "D'", "Des", 
  "So...", ",", ".", "demande", "...", "Trump", ":", "j'"
)

Conf_pers_clean <- Conf_pers_full %>%
  distinct(Name, .keep_all = TRUE) %>%
  filter(
    !(Name %in% exact_expressions_to_remove),
    is.na(First_name) | !(First_name %in% exact_expressions_to_remove)
  )


# Creation of a dataframe to store policymakers and officials names
QC.conf.decideurs_incipit <- data.frame(Gender = integer(), Name = character(), First_name = character(), doc_id = integer(), date = character(), stringsAsFactors = FALSE)

# Search for informations on policymakers
for (i in 1:(nrow(sample_QC.conf) - 60)) {
  current_token <- tolower(sample_QC.conf$token[i])
  if (current_token == "conférence" && tolower(sample_QC.conf$token[i + 1]) == "de" && tolower(sample_QC.conf$token[i + 2]) == "presse" && tolower(sample_QC.conf$token[i + 3]) == "de") {
    for (j in 1:90) {
      if (tolower(sample_QC.conf$token[i + j]) == "salle") {
        break
      }
      if (tolower(sample_QC.conf$token[i + j]) %in% c("m.", "mme")) {
        # Extracting gender
        Gender <- ifelse(tolower(sample_QC.conf$token[i + j]) == "m.", 0, 1)
        
        # Extracting family name
        Name <- sample_QC.conf$token[i + j + 2]
        
        # Extracting surname
        First_name <- sample_QC.conf$token[i + j + 1]
        
        # Extracting doc_id and date
        doc_id <- sample_QC.conf$doc_id[i]
        date <- sample_QC.conf$date[i]
        
        # Adding informations
        QC.conf.decideurs_incipit <- rbind(QC.conf.decideurs_incipit, data.frame(Gender, Name, First_name, doc_id, date, stringsAsFactors = FALSE))
      }
    }
  }
}

# Deleting duplicates and keeping 'Gender', 'Name' and 'First_name'
QC.conf.decideurs_incipitclean <- unique(QC.conf.decideurs_incipit[, c("Gender", "Name", "First_name")])

# Filtering the database
QC.conf.decideurs_incipitclean <- QC.conf.decideurs_incipitclean[
  !grepl('[[:punct:]]', QC.conf.decideurs_incipitclean$Name) & 
    !grepl('\\ba\\b|ministre', QC.conf.decideurs_incipitclean$Name, ignore.case = TRUE), 
]


# Exporting databases
# All speakers filtered and cleaned databse
output_file <- file.path(export_path, "QC.Conf_pers_clean.csv")
write.csv(Conf_pers_clean, file = output_file, row.names = FALSE)

# All speakers (raw)
output_file <- file.path(export_path, "QConf_pers_full.csv")
write.csv(Conf_pers_full, file = output_file, row.names = FALSE)

# All policymakers (raw)
output_file <- file.path(export_path, "QC.conf.decideurs_incipit.csv")
write.csv(QC.conf.decideurs_incipit, file = output_file, row.names = FALSE)

# All policymakers (clean)
output_file <- file.path(export_path, "QC.conf.decideurs_incipitclean.csv")
write.csv(QC.conf.decideurs_incipitclean, file = output_file, row.names = FALSE)


# IDENTIFYING ALL MEDIAS AND JOURNALISTS


# Importing the media dictionary and extracting media names
dictionary_file <- file.path(dictionary_path, "QC.conf.dict_media.csv")
QC.conf.dict_media <- read.csv2(dictionary_file, header= TRUE, sep=";")
media_names <- QC.conf.dict_media

# Initializing 'media' variable in 'Conf_pers_full' with NA
Conf_pers_clean$media <- NA

# Function to find media in tokens
find_media <- function(i, tokens, media_name_parts, anti_name = NULL) {
  for (k in seq_along(media_name_parts)) {
    if (i + k > length(tokens) || tolower(tokens[i + k]) != tolower(media_name_parts[k])) {
      return(FALSE)
    }
  }
  if (!is.null(anti_name) && i + length(media_name_parts) <= length(tokens) && tolower(tokens[i + length(media_name_parts)]) == tolower(anti_name)) {
    return(FALSE)
  }
  return(TRUE)
}



find_media_until_next_speaker <- function(i, tokens, media_names, speaker = "journalist") {
  while (i <= length(tokens)) {
    for (idx in 1:nrow(media_names)) {
      media_name <- media_names$media_names[idx]
      anti_name <- media_names$anti_name[idx]
      media_name_parts <- unlist(strsplit(media_name, " "))
      if (find_media(i, tokens, media_name_parts, anti_name)) {
        return(media_name)
      }
    }
    if (tokens[i] %in% c("M.", "Mme", "Le", "La") && any(sapply(2:7, function(j) tokens[i + j] == ":"))) {
      break
    }
    i <- i + 1
  }
  return(NA)
}



# Attribute media to journalists
n <- nrow(sample_QC.conf)
current_media <- NA
for (i in 1:n) {
  current_token <- sample_QC.conf$token[i]
  
  # Identifying the moderator speaker
  if (current_token %in% c("Le", "La") && sample_QC.conf$token[i + 1] %in% c("Modérateur", "Modératrice") && sample_QC.conf$token[i + 2] == ":") {
    current_media <- find_media_until_next_speaker(i + 3, sample_QC.conf$token, media_names, speaker = "moderator")
  }
  
  # Attributing media to journalists
  if (current_token %in% c("M.", "Mme")) {
    for (j in 1:8) {
      if (sample_QC.conf$token[i + j] == ":") {
        loc_name <- sample_QC.conf$token[i + 1]
        loc_row <- which(Conf_pers_clean$Name == loc_name)
        
        # Verifying loc_row value
        has_loc_row <- length(loc_row) > 0
        
        # Attributing media to journalists if the moderator name the media
        if (!is.na(current_media) && has_loc_row) {
          Conf_pers_clean$media[loc_row] <- current_media
          current_media <- NA
        }
        
        # Search for the media later in tokens
        current_media <- find_media_until_next_speaker(i + j + 1, sample_QC.conf$token, media_names, speaker = "journalist")
        if (!is.na(current_media) && has_loc_row) {
          Conf_pers_clean$media[loc_row] <- current_media
          current_media <- NA
        }
        break
      }
    }
  }
  
}



# Load the policymakers name dictionary 'QC.conf.dict_decideurs.csv' and extract corresponding names
dictionary_file_2 <- file.path(dictionary_path, "QC.conf.dict_decideurs.csv")
QC.conf.dict_decideurs <- read.csv2(dictionary_file_2, header = TRUE, sep=";") 
decideur_names <- QC.conf.dict_decideurs$Name


# Initialising the Conf_journalist dataframe containing journalists names
Conf_journalist <- data.frame()

# Function for media attribution
for (doc in unique(Conf_pers_clean$doc_id)) {
  temp_df <- Conf_pers_clean[Conf_pers_clean$doc_id == doc, ]
  for (name in unique(temp_df$Name)) {
    if (name %in% decideur_names) {
      next
    }
    
    name_rows <- temp_df[temp_df$Name == name, ]
    name_rows <- name_rows[order(name_rows$sentence_id), ]
    
    first_media <- name_rows$media[!is.na(name_rows$media)][1]
    
    if (!is.na(first_media)) {
      first_row <- name_rows[which(!is.na(name_rows$media))[1], ]
      
      Conf_journalist <- rbind(Conf_journalist, first_row)
      
      new_media_count <- 1
      for (idx in 2:nrow(name_rows)) {
        if (!is.na(name_rows$media[idx]) && name_rows$media[idx] != first_media) {
          new_media_col <- paste0("new_media_", new_media_count)
          if (!new_media_col %in% colnames(Conf_journalist)) {
            Conf_journalist[[new_media_col]] <- NA
          }
          Conf_journalist[nrow(Conf_journalist), new_media_col] <- name_rows$media[idx]
          
          first_media <- name_rows$media[idx]
          new_media_count <- new_media_count + 1
        }
      }
    }
  }
}

# Deleting sentence variable
Conf_journalist <- Conf_journalist[!names(Conf_journalist) %in% "sentence"]
rownames(Conf_journalist) <- NULL

# Filtering the database to create the database of all journalists names by conferences
Conf_journalist <- Conf_journalist %>%
  filter(!grepl("^(M\\.|le|Le|la|\\(|:)$", Name))

# Filtering to create the list of all journalist names without duplicates
Conf_journalist_clean <- Conf_journalist %>%
  distinct(Name, .keep_all = TRUE) %>%
  filter(!grepl("^(M\\.|le|Le|la|\\(|:)$", Name))

# Exporting databases
# All journalists (raw)
output_file <- file.path(export_path, "QC.Conf_journalist.csv")
write.csv(Conf_journalist, file = output_file, row.names = FALSE)

# All journalists (clean)
output_file <- file.path(export_path, "QC.Conf_journalist_clean.csv")
write.csv(Conf_journalist_clean, file = output_file, row.names = FALSE)



# ANNOTATION OF GENDERS AND MEDIAS

# ANNOTATING GENDERS

# Add woman and man to database
sample_QC.conf$man <- 0
sample_QC.conf$woman <- 0

# Identify spekers' gender
n <- nrow(sample_QC.conf)
current_gender <- NA
for (i in 1:n) {
  current_token <- sample_QC.conf$token[i]
  
  if (current_token %in% c("Le", "La", "M.", "Mme") && any(sapply(2:7, function(j) sample_QC.conf$token[i + j] == ":"))) {
    if (current_token %in% c("Le", "M.")) {
      current_gender <- "man"
    } else {
      current_gender <- "woman"
    }
  }
  
  if (!is.na(current_gender)) {
    if (current_gender == "man") {
      sample_QC.conf$man[i] <- 1
      sample_QC.conf$woman[i] <- 0
    } else {
      sample_QC.conf$man[i] <- 0
      sample_QC.conf$woman[i] <- 1
    }
  }
}

# ANNOTATING MEDIAS

# Importing journalists names and medias
input_file <- file.path(import_data_path, "QC.Conf_journalist_clean.csv")
Conf_journalist_clean <- read.csv(input_file, header = TRUE, sep=",")

# Formatting names of 'Conf_journalist_clean'
Conf_journalist_clean$media <- gsub("lapresse", "La Presse", Conf_journalist_clean$media)
Conf_journalist_clean$media <- gsub("radio-canada", "Radio Canada", Conf_journalist_clean$media)
Conf_journalist_clean$media <- gsub("cogéco", "cogeco", Conf_journalist_clean$media)

# Creating media names variables
unique_media_names <- unique(Conf_journalist_clean$media)
formatted_media_names <- gsub(" ", "_", unique_media_names)

for (media_name in formatted_media_names) {
  sample_QC.conf[[media_name]] <- 0
}


# Attributing medias to journalists
for (i in 1:nrow(sample_QC.conf)) {
  current_token <- sample_QC.conf$token[i]
  
  if (current_token %in% c("M.", "Mme")) {
    for (j in 1:8) {
      if (sample_QC.conf$token[i + j] == ":") {
        loc_name <- sample_QC.conf$token[i + 1]
        loc_journalist_row <- which(Conf_journalist_clean$Name == loc_name)
        
        if (length(loc_journalist_row) > 0) {
          loc_media <- Conf_journalist_clean$media[loc_journalist_row]
          formatted_media_name <- gsub(" ", "_", loc_media)
          
          for (media_name in formatted_media_names) {
            sample_QC.conf[[media_name]][i] <- 0
          }
          
          sample_QC.conf[[formatted_media_name]][i] <- 1
        }
        break
      }
    }
  } else {
    if (i > 1) {
      for (media_name in formatted_media_names) {
        sample_QC.conf[[media_name]][i] <- sample_QC.conf[[media_name]][i - 1]
      }
    }
  }
}

# Exporting annotated media database
output_file <- file.path(export_path, "QC.Conf_annotated_media.csv")
write.csv(sample_QC.conf, file = output_file, row.names = FALSE)

# ANNOTATING POLICYMAKERS

# Loading the name dictionary of policymakers
dictionary_file_3 <- file.path(dictionary_path, "QC.conf.dict_decideurs.csv")
decideurs <- read.csv(dictionary_file_3, header = TRUE, sep=";") 

# Fuction to detect a policymaker
is_decisionmaker <- function(df, i, decideurs) {
  if (df$token[i] %in% c("M.", "Mme")) {
    nom <- df$token[i + 1]
    if (nom %in% decideurs$Name) {
      for (j in seq(2, 7)) {
        if (df$token[i + j] == ":") {
          return(TRUE)
        }
      }
    }
  }
  return(FALSE)
}

# Creating the variable 'decisionmaker'
sample_QC.conf <- sample_QC.conf %>%
  mutate(decisionmaker = 0)

current_decisionmaker <- 0
n <- nrow(sample_QC.conf)

for (i in seq_len(n)) {
  if (is_decisionmaker(sample_QC.conf, i, decideurs)) {
    current_decisionmaker <- 1
  } else if (sample_QC.conf$token[i] %in% c("Le", "La") && sample_QC.conf$token[i + 1] %in% c("Modérateur", "Modératrice")) {
    current_decisionmaker <- 0
  } else if (sample_QC.conf$token[i] %in% c("M.", "Mme") && !(sample_QC.conf$token[i + 1] %in% decideurs$Name)) {
    for (j in seq(2, 7)) {
      if (sample_QC.conf$token[i + j] == ":") {
        current_decisionmaker <- 0
        break
      }
    }
  }
  sample_QC.conf$decisionmaker[i] <- current_decisionmaker
}

# Exporting the database
output_file <- file.path(export_path, "QC.Conf_annotated.csv")
write.csv(sample_QC.conf, file = output_file, row.names = FALSE)





## LSDFr SENTIMENT ANALYSIS ##


# Loading database
input_file <- file.path(import_data_path, "QC.Conf_annotated.csv")
data <- read.csv(input_file, header = TRUE, sep=",")

# Loading LSDFr
lsdfr_file <- file.path(dictionary_path, "sentiment_list.RData")
load(lsdfr_file)
sentiment_dict <- sentiment_list
positive_words <- sentiment_dict[["POSITIVE"]][["__"]]
sentiment_dict[["POSITIVE"]] <- positive_words

# Function to check if a word has a star
has_star <- function(word) {
  grepl("\\*", word)
}

# Function to delete the star
remove_star <- function(word) {
  gsub("\\*", "", word)
}

# Search function for words with a star
search_star_word <- function(word, token) {
  starts_with(remove_star(word), token)
}

# Search function
search_expression <- function(words, tokens, i) {
  first_word <- remove_star(words[1])
  start_index <- which(str_starts(tokens[(i+1):length(tokens)], first_word))[1] + i
  if(length(words) > 1) {
    end_index <- min(start_index + length(words) - 1, length(tokens))
    expression <- paste(tokens[start_index:end_index], collapse = " ")
    return(expression == paste(words, collapse = " "))
  }
  return(TRUE)
}

# Compute polarity
data <- data %>%
  mutate(
    negative = ifelse(lemma %in% sentiment_dict[["NEGATIVE"]] | token %in% sentiment_dict[["NEGATIVE"]], 1, 0),
    positive = ifelse(lemma %in% sentiment_dict[["POSITIVE"]] | token %in% sentiment_dict[["POSITIVE"]], 1, 0),
    conflict = ifelse(negative == 1 & positive == 1, 1, 0),
    polarity = case_when(
      conflict == 1 ~ 0,
      positive == 1 ~ 1,
      negative == 1 ~ -1,
      TRUE ~ 0
    )
  )

if(length(data$negative) != length(data$positive)) {
  data$negative[length(data$negative)+1:length(data$positive)] <- 0
  data$positive[length(data$positive)+1:length(data$negative)] <- 0
}


# Compute polarity for each sentence
data %>%
  group_by(doc_id, sentence_id, date) %>%
  filter(upos != "PUNCT") %>%
  summarise(
    negative_tokens = sum(negative),
    positive_tokens = sum(positive),
    conflict_tokens = sum(conflict),
    total_tokens = sum(!is.na(token_id))
  ) %>%
  mutate(polarity_sentence = (positive_tokens - negative_tokens) / total_tokens) %>%
  select(doc_id, sentence_id, polarity_sentence) -> data_sentiment


# Joining 'polarity_sentence' of 'data_sentiment' in 'data' in function of 'doc_id' and 'sentence_id'
data <- data %>%
  left_join(data_sentiment, by = c("doc_id", "sentence_id"))

# Create QC.conf_pol_analysis
QC.conf_pol_analysis <- data_sentiment

# Export databases
output_file <- file.path(export_path, "QC.conf_pol_analysis.csv")
write.csv(QC.conf_pol_analysis, file = output_file, row.names = FALSE)

output_file <- file.path(export_path, "QC.conf_fullannotated.csv")
write.csv(data, file = output_file, row.names = FALSE)








## INDICES CREATION ##



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



# VARIABLES CREATION

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


# CLEANING THE DATABASE : Delete the duplicates from a dictionary (manual annotation)

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





## CREATION OF FINAL DATABASE ## 


# Load the datasets (IRPP DATA, EPIDEMIOLOGICAL DATA FROM INSPQ)
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


# Export final database :-) 
output_file <- file.path(export_path, "QC.unc.redux_daily.csv")
write.csv(QC.unc.data_daily, file = output_file, row.names = FALSE)

