# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
dictionary_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Dictionnaries"

# Packages
library(quanteda)
library(dplyr)
library(stringr)

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
