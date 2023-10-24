# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
dictionary_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Dictionnaries"

# Packages
library(dplyr)
library(stringr)
library(readr)

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
