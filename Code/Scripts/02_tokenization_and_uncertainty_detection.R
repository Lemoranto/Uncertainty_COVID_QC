# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
model_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Udpipe"

# Import textual database
input_file <- file.path(import_data_path, "QC.conf_texts.csv")
QC.conf_texts <- read.csv(input_file, header = TRUE, sep=",")

# Packages
library(udpipe)
library(dplyr)
library(dplyr)
library(cld3)

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