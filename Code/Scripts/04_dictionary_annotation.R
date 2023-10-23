# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
dictionary_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Dictionnaries"

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
