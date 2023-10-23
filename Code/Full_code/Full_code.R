library(readtext)
library(dplyr)
library(stringr)

# Base path
import_texts_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Press_conferences"
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
model_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Udpipe"
dictionary_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Dictionnaries"



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
QC.unc.data_persanddict$Before_2020_conf <- QC.conf_texts$Before_2020_conf[match(QC.unc.data_persanddict$doc_id, QC.conf_texts$doc_ID)]

# Exporting textual database
output_file <- file.path(export_path, "QC.conf_texts.csv")
write.csv(QC.conf_texts, file = output_file, row.names = FALSE)

# Importer les conférences de presse
QC.conf_texts <- read.csv("/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_texts.csv", header = TRUE, sep=",")

# Charger le modèle udpipe
library(udpipe)
library(dplyr)
udpipe_download_model("french")
model<-udpipe_load_model("/Users/antoine/Documents/R/french-gsd-ud-2.5-191206.udpipe")

# Prétraitement des données : tokénisation des conférences
annotated_data <- udpipe_annotate(model, x = QC.conf_texts$conf_txt, doc_id = QC.conf_texts$doc_ID)
QC.conf_tokenised <- as.data.frame(annotated_data)

# Ajouter les informations de date (et autre) à la base de données
QC.conf_tokenised$date <- QC.conf_texts$date[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]
QC.conf_tokenised$Boileau_conf <- QC.conf_texts$Boileau_conf[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]
QC.conf_tokenised$Points_presse_conf <- QC.conf_texts$Points_presse_conf[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]
QC.conf_tokenised$Youtube_conf <- QC.conf_texts$Youtube_conf[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]
QC.conf_tokenised$Ministres_conf <- QC.conf_texts$Ministres_conf[match(QC.conf_tokenised$doc_id, QC.conf_texts$doc_ID)]

# Chargement de la bibliothèque dplyr et cld3 pour la détection des phrases
# en anglais
library(dplyr)
library(cld3)

# Détecter les langues présentes dans les conférences de presse
# et notamment l'anglais
QC.conf_tokenised <- QC.conf_tokenised %>%
  mutate(lang = detect_language(sentence))

# Sélection des lignes de la variable 'feats' qui contiennent "Foreign=Yes" 
# pour supprimer les portions en anglais
english_sentences <- QC.conf_tokenised %>%
  filter(grepl("en", lang)) %>%
  group_by(doc_id, sentence_id) %>%
  slice_head(n = 1)

# Enregistrement des lignes contenant des phrases en anglais 
# dans une nouvelle base de données appelée 'QC.conf_tokenised_english'
QC.conf_tokenised_english <- english_sentences

# Sélection des lignes restantes qui ne contiennent pas "Foreign=Yes"
QC.conf_tokenised <- QC.conf_tokenised %>%
  anti_join(english_sentences, by = c("doc_id", "sentence_id"))

#Exporter la base de données
library(openxlsx)
write.xlsx(QC.conf_tokenised, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_tokenised.xlsx", rowNames = FALSE)
write.csv(QC.conf_tokenised, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_tokenised.csv")

#Chercher les phrases qui contiennent un marqueur d'incertitude (proche du CIRST)

QC.conf_tokenised_2 <- QC.conf_tokenised %>%
  group_by(date) %>%
  mutate(uncertainty = ifelse(grepl("Mood=Cnd", feats) | 
                                (lemma == "pouvoir" & upos == "VERB" & !grepl("Form=Inf", feats)) |
                                lemma %in% c("possible", "possiblement", "probable", "probablement", "improbable") |
                                lemma %in% c("incertain", "incertaine", "incertaines", "incertains", "incertitude", "incertitudes", "hypothèse") | # champs de l'incertitude
                                (lemma == "suspect" & upos == "ADJ") | lemma == "suspicion" | # quelque chose de suspect
                                (upos == "VERB" & (lemma == "penser" | lemma == "croire" | lemma == "espérer" | lemma == "questionner" | lemma == "soupçonner")), # verbes d'incertitude
                              1, 0))

#Exporter la base de données
library(openxlsx)
write.xlsx(QC.conf_tokenised_2, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_uncertainty.xlsx", rowNames = FALSE)
write.csv(QC.conf_tokenised_2, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_uncertainty.csv")


# Importer la base tokénisée avec analyse des marqueurs d'incertitude
QC.conf_token_uncertainty <- read.csv("/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_uncertainty.csv", header = TRUE, sep=",")

#Charger la librairie
library(stringr)
library(dplyr)

#Identifier Dubé

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

#Identifier Legault

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

#Identifier Guilbault

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

#Identifier McCann

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


#Identifier Arruda

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


#Identifier Massé

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


#Identifier Lucie Opatrny

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

#Identifier Boileau

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


#Exporter la base de données avec l'identification des locuteurs

library(openxlsx)
write.xlsx(QC.conf_token_uncertainty, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_pers.xlsx", rowNames = FALSE)
write.csv(QC.conf_token_uncertainty, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_pers.csv")       


# Importer le dictionnaire
dictionnary <- read.csv2("/Users/antoine/Documents/Recherches/Incertitude/Code R/Dictionary/Dictionary/QC.unc.dictionary.csv", sep=";")

# Importer la base de données tokénisée avec locuteurs identifiés
QC.conf_token_dict <- read.csv("/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_pers.csv", header = TRUE, sep=",")

# Créer une nouvelle colonne "phrase_id" qui combine les colonnes "sentence_id" et "doc_id"
QC.conf_token_dict$unique_phrase_id <- paste(QC.conf_token_dict$doc_id, QC.conf_token_dict$sentence_id, sep="_")



# Fonction du dictionnaire pour les modes racines et complet
findWords <- function(words, token, mode) {
  if (mode == "racine") {
    # Chercher les mots qui commencent par le mot recherché
    return(any(sapply(words, function(x) if(nchar(x)>0) any(grepl(paste0("^", x), token, ignore.case = TRUE)) else FALSE)))
  } else if (mode == "complet") {
    # Chercher l'expression exacte dans la phrase
    return(any(sapply(words, function(x) if(nchar(x)>0) any(grepl(paste0("\\b", x, "\\b"), token, ignore.case = TRUE)) else FALSE)))
  } else {
    return(FALSE)
  }
}




# Fonction pour le mode "lemmes"
findLemmes <- function(lemmes, QC.conf_token_dict, i) {
  # Séparer les lemmes à rechercher en mots individuels
  search_words <- unlist(strsplit(lemmes, " "))
  
  # Chercher le premier mot dans la ligne actuelle
  if (any(grepl(paste0("^", search_words[1], "$"), QC.conf_token_dict[i, "lemma"], ignore.case = TRUE))) {
    if (length(search_words) == 1) {
      # Si c'est le seul mot de l'expression à chercher, alors la recherche est vérifiée
      return(TRUE)
    } else {
      # Sinon, chercher les autres mots dans les lignes suivantes de la même phrase
      next_i <- i + 1
      search_index <- 2
      while (next_i <= nrow(QC.conf_token_dict) && QC.conf_token_dict[next_i, "unique_phrase_id"] == QC.conf_token_dict[i, "unique_phrase_id"]) {
        if (any(grepl(paste0("^", search_words[search_index], "$"), QC.conf_token_dict[next_i, "lemma"], ignore.case = TRUE))) {
          if (search_index == length(search_words)) {
            # Si on a trouvé tous les mots de l'expression, alors la recherche est vérifiée
            return(TRUE)
          } else {
            # Sinon, continuer à chercher les mots suivants
            search_index <- search_index + 1
          }
        }
        next_i <- next_i + 1
      }
    }
  }
  
  
  # Si on arrive jusqu'ici, la recherche n'a pas été vérifiée
  return(FALSE)
}



#Fonction pour le mode Token
findTokens <- function(tokens, QC.conf_token_dict, i) {
  # Séparer les tokens à rechercher en mots individuels
  search_words <- unlist(strsplit(tokens, " "))
  
  # Initialiser les indices de recherche
  next_i <- i + 1
  search_index <- 2
  
  # Chercher le premier mot dans la ligne actuelle
  if (any(grepl(paste0("^", search_words[1], "$"), QC.conf_token_dict[i, "token"], ignore.case = TRUE))) {
    if (length(search_words) == 1) {
      # Si c'est le seul mot de l'expression à chercher, alors la recherche est vérifiée
      return(TRUE)
    } else {
      # Sinon, chercher les autres mots dans les lignes suivantes de la même phrase
      while (next_i <= nrow(QC.conf_token_dict) && QC.conf_token_dict[next_i, "unique_phrase_id"] == QC.conf_token_dict[i, "unique_phrase_id"]) {
        # Vérifier si le prochain mot recherché est directement présent sur la ligne suivante
        if (any(grepl(paste0("^", search_words[search_index], "$"), QC.conf_token_dict[next_i, "token"], ignore.case = TRUE))) {
          # Si oui, passer au mot suivant à chercher
          search_index <- search_index + 1
          if (search_index > length(search_words)) {
            # Si on a trouvé tous les mots de l'expression, alors la recherche est vérifiée
            return(TRUE)
          }
        } else {
          # Si non, arrêter la recherche pour cette expression
          break
        }
        next_i <- next_i + 1
      }
    }
  }
  
  # Si on arrive jusqu'ici, la recherche n'a pas été vérifiée
  return(FALSE)
}



#Appliquer la recherche par dictionnaire et les fonctions

#Sélectionner les colonnes du dictionnaire
cols_to_check <- colnames(dictionnary)[!grepl("mode", colnames(dictionnary))]

# Boucler sur chaque ligne de QC.conf_token_dict pour chercher les mots de chaque catégorie
for (i in seq_len(nrow(QC.conf_token_dict))) {
  # Récupérer le token, la lemma et la sentence_id correspondante
  token <- QC.conf_token_dict[i, "token"]
  lemma <- QC.conf_token_dict[i, "lemma"]
  sentence_id <- QC.conf_token_dict[i, "unique_phrase_id"]
  
  # Vérifier chaque mot pour chaque catégorie
  for (col in cols_to_check) {
    words_to_check <- dictionnary[, col]
    mode_to_check <- dictionnary[, "mode"]
    
    if (length(words_to_check) > 0) {
      word_found <- FALSE
      
      # Vérifier si le token correspond à un mot de la catégorie
      for (j in seq_along(words_to_check)) {
        word_to_check <- words_to_check[j]
        mode <- mode_to_check[j]
        if (!is.na(word_to_check) && nchar(word_to_check) > 0) {
          if (mode == "lemmes") {
            # Chercher les lemmes de manière spécifique
            if (findLemmes(word_to_check, QC.conf_token_dict, i)) {
              word_found <- TRUE
              break
            }
          } else if (mode == "token") {
            # Chercher les correspondances de tokens
            if (findTokens(word_to_check, QC.conf_token_dict, i)) {
              word_found <- TRUE
              break
            }
          } else {
            # Chercher les mots de manière générale
            if (findWords(word_to_check, token, mode)) {
              word_found <- TRUE
              break
            }
          }
        }
      }
      
      # Si le token correspond à un mot de la catégorie, mettre la variable correspondante à 1
      if (word_found) {
        QC.conf_token_dict[i, col] <- 1
        
        # Mettre à 1 pour chaque ligne appartenant à la même phrase et au même document
        same_phrase <- QC.conf_token_dict$unique_phrase_id == QC.conf_token_dict[i, "unique_phrase_id"]
        QC.conf_token_dict[same_phrase, col] <- 1
      }
    }
  }
}



#Exporter la base de données
library(openxlsx)
write.xlsx(QC.conf_token_dict, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_dictpers.xlsx", rowNames = FALSE)
write.csv(QC.conf_token_dict, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_dictpers.csv")



# Charger les packages nécessaires
library(dplyr)
library(stringr)
library(readr)

sample_QC.conf <- read.csv("/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_token_dictpers.csv", header = TRUE, sep=",")


# Création d'un dataframe vide pour stocker les personnes présentes
Conf_pers_full <- data.frame(Gender = integer(), Name = character(), First_name = character(), doc_id = integer(), sentence_id = integer(), sentence = character(), stringsAsFactors = FALSE)

# Recherche des locuteurs et extraction des informations
for (i in 1:(nrow(sample_QC.conf) - 8)) {
  current_token <- sample_QC.conf$token[i]
  if (current_token %in% c("M.", "Mme")) {
    for (j in 1:8) {
      if (sample_QC.conf$token[i + j] == ":") {
        # Extraction du genre
        Gender <- ifelse(current_token == "M.", 0, 1)
        
        # Extraction du nom de famille
        Name <- sample_QC.conf$token[i + 1]
        
        # Extraction du prénom, s'il est présent
        if (j > 2) {
          First_name <- gsub("[()]", "", sample_QC.conf$token[i + 3])
        } else {
          First_name <- NA
        }
        
        # Extraction de doc_id, sentence_id et sentence
        doc_id <- sample_QC.conf$doc_id[i]
        sentence_id <- sample_QC.conf$sentence_id[i]
        sentence <- sample_QC.conf$sentence[i]
        date <- sample_QC.conf$date[i]
        
        # Ajout des informations extraites au dataframe Conf_pers_full
        Conf_pers_full <- rbind(Conf_pers_full, data.frame(Gender, Name, First_name, doc_id, sentence_id, sentence, date, stringsAsFactors = FALSE))
        break
      }
    }
  }
}

# Création du dataframe Conf_pers_clean en supprimant les doublons et en filtrant les lignes dont 'Name' et 'First_name' ne contiennent que 'M.', 'le', '...', et ':'
exact_expressions_to_remove <- c(
  "M.", "le", "Mme", "I'm", "la", "It's", "So", "hein", "I", 
  "Is", "Mrs.", "Mr", "Di", "(", "OK", "That's", "Vien", "Ms.", "Mr.", "D'", "Des", "So...", ",", ".", "demande"
)

Conf_pers_clean <- Conf_pers_full %>%
  distinct(Name, .keep_all = TRUE) %>%
  filter(
    !(Name %in% exact_expressions_to_remove | grepl(pattern, Name)),
    is.na(First_name) | !(First_name %in% exact_expressions_to_remove | grepl(pattern, First_name))
  )


# Création d'un dataframe vide pour stocker les informations des décideurs
QC.conf.decideurs_incipit <- data.frame(Gender = integer(), Name = character(), First_name = character(), doc_id = integer(), date = character(), stringsAsFactors = FALSE)

# Recherche des informations sur les décideurs
for (i in 1:(nrow(sample_QC.conf) - 60)) {
  current_token <- tolower(sample_QC.conf$token[i])
  if (current_token == "conférence" && tolower(sample_QC.conf$token[i + 1]) == "de" && tolower(sample_QC.conf$token[i + 2]) == "presse" && tolower(sample_QC.conf$token[i + 3]) == "de") {
    for (j in 1:90) {
      if (tolower(sample_QC.conf$token[i + j]) == "salle") {
        break
      }
      if (tolower(sample_QC.conf$token[i + j]) %in% c("m.", "mme")) {
        # Extraction du genre
        Gender <- ifelse(tolower(sample_QC.conf$token[i + j]) == "m.", 0, 1)
        
        # Extraction du nom de famille
        Name <- sample_QC.conf$token[i + j + 2]
        
        # Extraction du prénom
        First_name <- sample_QC.conf$token[i + j + 1]
        
        # Extraction de doc_id et date
        doc_id <- sample_QC.conf$doc_id[i]
        date <- sample_QC.conf$date[i]
        
        # Ajout des informations extraites au dataframe QC.conf.decideurs_incipit
        QC.conf.decideurs_incipit <- rbind(QC.conf.decideurs_incipit, data.frame(Gender, Name, First_name, doc_id, date, stringsAsFactors = FALSE))
      }
    }
  }
}

# Suppression des doublons et conservation des colonnes 'Gender', 'Name' et 'First_name'
QC.conf.decideurs_incipitclean <- unique(QC.conf.decideurs_incipit[, c("Gender", "Name", "First_name")])

# Suppression des lignes contenant un signe de ponctuation dans la colonne 'Name'
QC.conf.decideurs_incipitclean <- QC.conf.decideurs_incipitclean[
  !grepl('[[:punct:]]', QC.conf.decideurs_incipitclean$Name) & 
    !grepl('\\ba\\b|ministre', QC.conf.decideurs_incipitclean$Name, ignore.case = TRUE), 
]


#Exporter les base de données
library(openxlsx)
write.csv(Conf_pers_clean, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.Conf_pers_clean.csv")
write.csv(Conf_pers_full, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QConf_pers_full.csv")
write.csv(QC.conf.decideurs_incipit, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.conf.decideurs_incipit.csv")
write.csv(QC.conf.decideurs_incipitclean, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.conf.decideurs_incipitclean.csv")





#Charger le fichier 'QC.conf.dict_media.csv' et extraire la liste des médias
QC.conf.dict_media <- read.csv("/Users/antoine/Documents/Recherches/Conf_media/Code R/Archives/Dictionnaire/QC.conf.dict_media.csv", header = TRUE, sep = ";")
media_names <- QC.conf.dict_media

#Initialiser la colonne 'media' dans le dataframe 'Conf_pers_full' avec des valeurs NA
Conf_pers_clean$media <- NA

# Fonction pour vérifier si un média est trouvé dans les tokens suivants
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



# Identifier et attribuer les médias aux journalistes
n <- nrow(sample_QC.conf)
current_media <- NA
for (i in 1:n) {
  current_token <- sample_QC.conf$token[i]
  
  # Identifier le modérateur ou la modératrice
  if (current_token %in% c("Le", "La") && sample_QC.conf$token[i + 1] %in% c("Modérateur", "Modératrice") && sample_QC.conf$token[i + 2] == ":") {
    current_media <- find_media_until_next_speaker(i + 3, sample_QC.conf$token, media_names, speaker = "moderator")
  }
  
  # Attribuer les médias aux journalistes
  if (current_token %in% c("M.", "Mme")) {
    for (j in 1:8) {
      if (sample_QC.conf$token[i + j] == ":") {
        loc_name <- sample_QC.conf$token[i + 1]
        loc_row <- which(Conf_pers_clean$Name == loc_name)
        
        # Vérifiez si loc_row a des valeurs
        has_loc_row <- length(loc_row) > 0
        
        # Attribuer le média actuel au locuteur si modérateur avait trouvé un média
        if (!is.na(current_media) && has_loc_row) {
          Conf_pers_clean$media[loc_row] <- current_media
          current_media <- NA
        }
        
        # Chercher le média dans les tokens suivants pour le journaliste
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





# Charger le fichier 'QC.conf.dict_decideurs.csv' et extraire la liste des noms des décideurs
QC.conf.dict_decideurs <- read.csv("/Users/antoine/Documents/Recherches/Conf_media/Code R/Archives/Dictionnaire/QC.conf.dict_decideurs.csv", header = TRUE, sep = ";")
decideur_names <- QC.conf.dict_decideurs$Name

# # Initialiser un nouveau dataframe Conf_journalist
Conf_journalist <- data.frame()

# Parcourir chaque doc_id
for (doc in unique(Conf_pers_clean$doc_id)) {
  # Filtrer les lignes avec le même doc_id
  temp_df <- Conf_pers_clean[Conf_pers_clean$doc_id == doc, ]
  
  # Parcourir chaque nom dans temp_df
  for (name in unique(temp_df$Name)) {
    # Ignorer les noms des décideurs
    if (name %in% decideur_names) {
      next
    }
    
    # Filtrer les lignes avec le même nom et trier par sentence_id
    name_rows <- temp_df[temp_df$Name == name, ]
    name_rows <- name_rows[order(name_rows$sentence_id), ]
    
    # Trouver la première occurrence avec un média
    first_media <- name_rows$media[!is.na(name_rows$media)][1]
    
    if (!is.na(first_media)) {
      # Conserver la première occurrence avec un média
      first_row <- name_rows[which(!is.na(name_rows$media))[1], ]
      
      # Ajouter la première occurrence avec un média à Conf_journalist
      Conf_journalist <- rbind(Conf_journalist, first_row)
      
      # Vérifier si le nom du média change à un nouvel doc_id
      new_media_count <- 1
      for (idx in 2:nrow(name_rows)) {
        if (!is.na(name_rows$media[idx]) && name_rows$media[idx] != first_media) {
          # Créer une nouvelle colonne 'new_media', 'new_media_2', etc., avec le nouveau média
          new_media_col <- paste0("new_media_", new_media_count)
          if (!new_media_col %in% colnames(Conf_journalist)) {
            Conf_journalist[[new_media_col]] <- NA
          }
          Conf_journalist[nrow(Conf_journalist), new_media_col] <- name_rows$media[idx]
          
          # Mettre à jour le média actuel et incrémenter le compteur de nouveaux médias
          first_media <- name_rows$media[idx]
          new_media_count <- new_media_count + 1
        }
      }
    }
  }
}

# Supprimer la colonne 'sentence' et réinitialiser les index de ligne
Conf_journalist <- Conf_journalist[!names(Conf_journalist) %in% "sentence"]
rownames(Conf_journalist) <- NULL

# Filtrage pour créer la base de tous les journalistes par conférences
Conf_journalist <- Conf_journalist %>%
  filter(!grepl("^(M\\.|le|Le|la|\\(|:)$", Name))

# Filtrage pour créer la liste des journalises
Conf_journalist_clean <- Conf_journalist %>%
  distinct(Name, .keep_all = TRUE) %>%
  filter(!grepl("^(M\\.|le|Le|la|\\(|:)$", Name))

#Exporter la base de données
library(openxlsx)
write.xlsx(Conf_journalist, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.Conf_journalist.xlsx", rowNames = FALSE)
write.csv(Conf_journalist, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.Conf_journalist.csv")
write.csv(Conf_journalist_clean, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.Conf_journalist_clean.csv")







#Annoter les genres

# Ajouter les colonnes 'man' et 'woman' à la base de données 'sample_QC.conf'
sample_QC.conf$man <- 0
sample_QC.conf$woman <- 0

# Parcourir les lignes pour identifier le genre du locuteur
n <- nrow(sample_QC.conf)
current_gender <- NA
for (i in 1:n) {
  current_token <- sample_QC.conf$token[i]
  
  # Vérifier si un nouveau locuteur est rencontré
  if (current_token %in% c("Le", "La", "M.", "Mme") && any(sapply(2:7, function(j) sample_QC.conf$token[i + j] == ":"))) {
    if (current_token %in% c("Le", "M.")) {
      current_gender <- "man"
    } else {
      current_gender <- "woman"
    }
  }
  
  # Attribuer la valeur appropriée pour 'man' ou 'woman' selon le genre du locuteur actuel
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

# Annoter en fonction les médias 
Conf_journalist_clean<-read.csv("/Users/antoine/Documents/Recherches/Conf_media/Data/QC.Conf_journalist_clean.csv", header = TRUE, sep=",")

# Étape 1 : Formaliser les noms des médias dans 'Conf_journalist_clean'
Conf_journalist_clean$media <- gsub("lapresse", "La Presse", Conf_journalist_clean$media)
Conf_journalist_clean$media <- gsub("radio-canada", "Radio Canada", Conf_journalist_clean$media)
Conf_journalist_clean$media <- gsub("cogéco", "cogeco", Conf_journalist_clean$media)

# Étape 2 : Extraire tous les noms de médias uniques et créer autant de variables vides dans 'sample_QC.conf'
unique_media_names <- unique(Conf_journalist_clean$media)
formatted_media_names <- gsub(" ", "_", unique_media_names)

for (media_name in formatted_media_names) {
  sample_QC.conf[[media_name]] <- 0
}


# Étape 3 : Assigner 1 à chaque ligne où le locuteur appartient au média concerné
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
          
          # Réinitialiser les variables de médias
          for (media_name in formatted_media_names) {
            sample_QC.conf[[media_name]][i] <- 0
          }
          
          # Attribuer 1 à la variable du média correspondant
          sample_QC.conf[[formatted_media_name]][i] <- 1
        }
        break
      }
    }
  } else {
    if (i > 1) {
      # Propager la valeur des variables de médias à la ligne suivante
      for (media_name in formatted_media_names) {
        sample_QC.conf[[media_name]][i] <- sample_QC.conf[[media_name]][i - 1]
      }
    }
  }
}

#Exporter la base de données
write.csv(sample_QC.conf, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.Conf_annotated_media.csv")


# Annoter les décideurs
decideurs <- read.csv("/Users/antoine/Documents/Recherches/Conf_media/Code R/Archives/Dictionnaire/QC.conf.dict_decideurs.csv", header = TRUE, sep=";")

# Fonction pour détecter un décideur
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

# Créer la variable 'decisionmaker'
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

#Exporter la base de données
write.csv(sample_QC.conf, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.Conf_annotated.csv")


library(quanteda)
library(dplyr)
library(stringr)

# Charger les données
data <- read.csv("/Users/antoine/Documents/Recherches/Conf_media/Data/QC.Conf_annotated.csv", header = TRUE, sep=",")

# Charger le dictionnaire de sentiment et les données
load("/Users/antoine/Documents/Recherches/Conf_media/Code R/Sentiments/sentiment_list.RData")
sentiment_dict <- sentiment_list
positive_words <- sentiment_dict[["POSITIVE"]][["__"]]
sentiment_dict[["POSITIVE"]] <- positive_words

# Fonction pour vérifier si un mot contient une étoile
has_star <- function(word) {
  grepl("\\*", word)
}

# Fonction pour enlever l'étoile d'un mot
remove_star <- function(word) {
  gsub("\\*", "", word)
}

# Fonction pour rechercher dans les mots avec étoile
search_star_word <- function(word, token) {
  starts_with(remove_star(word), token)
}

# Fonction pour rechercher dans les expressions
search_expression <- function(words, tokens, i) {
  # Rechercher une correspondance avec le premier mot de l'expression
  first_word <- remove_star(words[1])
  start_index <- which(str_starts(tokens[(i+1):length(tokens)], first_word))[1] + i
  
  # Vérifier si les mots suivants correspondent à l'expression
  if(length(words) > 1) {
    end_index <- min(start_index + length(words) - 1, length(tokens))
    expression <- paste(tokens[start_index:end_index], collapse = " ")
    return(expression == paste(words, collapse = " "))
  }
  return(TRUE)
}

# Calculer la polarité pour chaque token en tenant compte des lemmes et des conflits
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

# S'assurer que les tailles des variables negative et positive sont identiques
if(length(data$negative) != length(data$positive)) {
  data$negative[length(data$negative)+1:length(data$positive)] <- 0
  data$positive[length(data$positive)+1:length(data$negative)] <- 0
}


# Calculer la polarité par phrase en tenant compte des lemmes et des conflits
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


# Joindre la variable 'polarity_sentence' de 'data_sentiment' dans 'data' en fonction des variables 'doc_id' et 'sentence_id'
data <- data %>%
  left_join(data_sentiment, by = c("doc_id", "sentence_id"))

# Créer le dataframe QC.conf_pol_analysis
QC.conf_pol_analysis <- data_sentiment

# Sauvegarder
write.csv(QC.conf_pol_analysis, file = "/Users/antoine/Documents/Recherches/Conf_media/Data/QC.conf_pol_analysis.csv", row.names = FALSE)

#Exporter la base de données
write.csv(data, file = "/Users/antoine/Documents/Recherches/Incertitude/Données/QC.conf_fullannotated_3.csv")
