# Base path
import_data_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"
export_path <- "/Users/antoine/Documents/GitHub/Uncertainty_COVID_QC/Data/Database"

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
