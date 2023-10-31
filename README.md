# Code et base de données (English below)

## À propos

Cette plateforme propose des codes et des bases de données dédiés à la collecte, au traitement et à l'analyse des conférences de presse tenues par le gouvernement du Québec durant la pandémie de COVID-19. 

Les analyses englobent :
- L'identification des différents locuteurs (décideurs politiques, représentants de la santé publique, journalistes, genre).
- Une analyse des marqueurs d'incertitude basée sur [Claveau et al. (2020)](https://papers.ssrn.com/abstract=3747158).
- Une analyse de sentiments basée sur [Duval et Pétry (2016)](https://www.cambridge.org/core/journals/canadian-journal-of-political-science-revue-canadienne-de-science-politique/article/lanalyse-automatisee-du-ton-mediatique-construction-et-utilisation-de-la-version-francaise-du-lexicoder-sentiment-dictionary/7D61B73C4BA44EC0ECB654461F2D4B3C). 
- Une analyse par dictionnaire permettant d'identifier les phrases relatives à divers sujets tels que la pandémie, la vaccination, les preuves scientifiques, ou encore les groupes cibles des mesures sanitaires.

## Brève description des codes

### 📁 Dossier `AutoTranscribeAndScrape`

Ce dossier contient trois types de codes Python :

1. **Extraction des transcriptions gouvernementales (Assemblée nationale du Québec)** :
   - 📄 `Extract_conf_covid.py`
   - 📄 `Extract_conf_not_covid.py`
   - 📄 `Extract_pp_covid.py`
   - 📄 `Extract_pp_covid.py`
   
   Ces scripts, situés dans le sous-dossier `recup_transcriptions`, permettent d'extraire les conférences de presse et les points de presse depuis le 01 janvier 2020 sur la pandémie de COVID-19 depuis le site de l'Assemblée nationale du Québec.

2. **Récupération audio des transcriptions indisponibles** :
   - 📄 `recuperation_audio_conference.py`
   
   Ce script, situé dans le sous-dossier `AutoTranscribe`, permet de récupérer l'audio des conférences de presse non retranscrites à partir de vidéos YouTube en utilisant le fichier 📄 `hyperliens_conferences.csv`.

3. **Transcription automatique des transcriptions indisponibles** :
   - 📄 `transcription.py`
   
   Ce script utilise Whisper d'OpenAI pour transcrire automatiquement l'audio des conférences de presse manquantes. Un fichier 📄 `annotations_langues.csv` est utilisé pour exclure les portions audio en anglais.

### 📁 Dossier `Code`

- **Traitement complet de la base de données textuelle** :
   - 📄 `Full_code.R`
   
   Ce script R assure le traitement complet des conférences, incluant la création de la base de données, tokénisation, annotation, analyses par dictionnaire, analyses de sentiments, création des variables, nettoyage et compilation de la base de données finale.


- **Scripts décomposés** : Le sous-dossier 📁 `Scripts` contient le code complet décomposé en différentes étapes.

## Description des données

### Base de données numériques

- 📄 `QC.unc.data_daily.csv` : est le fichier contenant les indices principaux produits par le code et utilisées dans la production des modèles OLS, SEM et des résultats graphiques concernant l'interaction entre sentinements d'incertitude des décideurs, sentiments négatifs, niveau de preuve et sévérité des mesures sanitaires mises en oeuvre durant la pandémie au Québec. Voici la notice des indices :  
   - ID : Numérotation hebdomadaire
   - date : Date
   - wave : Vagues de contamination officielle [définies par l'INSPQ](https://www.inspq.qc.ca/covid-19/donnees/ligne-du-temps)
   - SPHM : Indice de sévérité des mesures sanitaires (données de l'IRPP, voir ci-dessous)
   - SI : Indice de sévérité des mesures sanitaires + mesures vaccinales (données de l'IRPP, voir ci-dessous)
   - UNC : Indice des sentiments d'incertitude des décideurs et des représentants de la Santé publique (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault, M. Arruda, M. Boileau)
   - EVD : Indice du niveau de preuve scientifique des décideurs politiques (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault)
   - NEG : Indice des sentiments négatifs concernant la pandémie des décideurs politiques (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault)
   - CC100 : Indice sur 100 du nombre de cas confirmés de COVID-19 par jour (données de l'INSPQ, voir ci-dessous)
   - CD100 : Indice sur 100 du nombre de morts confirmées de la COVID-19 par jour (données de l'INSPQ, voir ci-dessous)
   - TH100 : Indice sur 100 du nombre d'hospitalisations dues à la COVID-19 par jour (données de l'INSPQ, voir ci-dessous)
   - VAX100 : Indice sur 100 du nombre de personnes vaccinées contre la COVID-19 par jour (données de l'INSPQ, voir ci-dessous)
   - CC : Nombre de cas confirmés de COVID-19 par jour (données de l'INSPQ, voir ci-dessous)
   - CD : Nombre de morts confirmées de la COVID-19 par jour (données de l'INSPQ, voir ci-dessous)
   - TH : Nombre d'hospitalisations dues à la COVID-19 par jour (données de l'INSPQ, voir ci-dessous)
   - VAX : Nombre de personnes vaccinées contre la COVID-19 par jour (données de l'INSPQ, voir ci-dessous)
   
- 📄 `QC.Conf_pers_clean.csv` : est la base de données contenant l'ensemble des noms et prénoms des personnes s'étant exprimées lors des conférences de presse identifiées par le code

- 📄 `QC.Conf_journalis_clean.csv` : est la base de données contenant l'ensemble des noms et prénoms des journalistes s'étant exprimés lors des conférences de presse, ainsi que leurs médias correspondants, identifiés par le code

- 📄 `QC.Conf_decideurs_incipitclean.csv` : est la base de données contenant l'ensemble des noms et prénoms des décideurs/représentants de la santé publique/experts/invités s'étant exprimés lors des conférences de presse identifiés par le code
   
- 📄 `QC.COVID_data` : rassemble les données épidémiologiques du Québec durant la pandémie, [issues de l'Institut national de santé publique du Québec (INSPQ)](https://www.inspq.qc.ca/covid-19/donnees).

- 📄 `QC.IRPPstringency_data.csv` : détaille la sévérité des mesures sanitaires, [provenant de l'Institut de recherche en politiques publiques (IRPP)](https://centre.irpp.org/fr/data/politiques-provinciales-sur-la-pandemie-de-covid-19/).

- 📄 `QC.vax_data` : contient les données de vaccination, [fournies par l'Institut national de santé publique du Québec (INSPQ)](https://www.inspq.qc.ca/covid-19/donnees).

### Base de données textuelles

- 📄 `QC.conf_texts.csv` : compilation de l'ensemble des conférences de presse du gouvernement du Québec concernant la pandémie de COVID-19.

- 📁 Dossier `Press_conferences` archive toutes les conférences du gouvernement du Québec durant la pandémie individuellement. 

- 📁 Les différents dossiers d'extractions contenus dans `recup_transcriptions` contiennent les conférences de presse extraites du site de l'Assemblée nationale.

- 📁 Dossier `Texts_youtube` (situé dans `Press_conferences`) : Contient les conférences de presse qui ont été automatiquement transcrites puis validées manuellement.
   - 📁 Sous-dossier `Original_autotranscribed` : Contient les transcriptions avant relecture.
   
### Analyses

- 📁 Dossier `Results` archive des résultats d'analyse produits dans le cadre d'une recherche portant sur l'interaction entre les sentiments d'incertitude, les sentiments négatifs, le niveau de preuve et la sévérité des mesures sanitaires durant la pandémie de COVID-19 au Québec.

## Mise à jour à venir

Indices différenciés des sentiments d'incertitude et des sentiments négatifs par catégorie (décideurs politiques, représentants de la santé publique, experts et journalistes).



# Code and Database

## About

This platform provides codes and databases dedicated to the collection, processing, and analysis of press conferences held by the Quebec government during the COVID-19 pandemic.

The analyses include:
- Identification of different speakers (political decision-makers, public health representatives, journalists, gender).
- An analysis of uncertainty markers based on [Claveau et al. (2020)](https://papers.ssrn.com/abstract=3747158).
- A sentiment analysis based on [Duval and Pétry (2016)](https://www.cambridge.org/core/journals/canadian-journal-of-political-science-revue-canadienne-de-science-politique/article/lanalyse-automatisee-du-ton-mediatique-construction-et-utilisation-de-la-version-francaise-du-lexicoder-sentiment-dictionary/7D61B73C4BA44EC0ECB654461F2D4B3C).
- A dictionary-based analysis to identify sentences related to various topics such as the pandemic, vaccination, scientific evidence, and target groups for health measures.

## Brief Code Description

### 📁 Directory `AutoTranscribeAndScrape`

This directory contains three types of Python codes:

1. **Government Transcription Extraction (National Assembly of Quebec)**:
   - 📄 `Extract_conf_covid.py`
   - 📄 `Extract_conf_not_covid.py`
   - 📄 `Extract_pp_covid.py`
   - 📄 `Extract_pp_covid.py`
   
   These scripts, located in the `recup_transcriptions` sub-directory, extract press conferences and press briefings from January 1, 2020, on the COVID-19 pandemic from the National Assembly of Quebec's website.

2. **Audio Retrieval for Unavailable Transcriptions**:
   - 📄 `recuperation_audio_conference.py`
   
   Located in the `AutoTranscribe` sub-directory, this script retrieves the audio of untranscribed press conferences from YouTube videos using the 📄 `hyperliens_conferences.csv` file.

3. **Automatic Transcription of Unavailable Transcriptions**:
   - 📄 `transcription.py`
   
   This script uses OpenAI's Whisper to automatically transcribe the audio of missing press conferences. A 📄 `annotations_langues.csv` file is used to exclude English audio portions.

### 📁 Directory `Code`

- **Complete Processing of Textual Database**:
   - 📄 `Full_code.R`
   
   This R script handles the complete processing of the conferences, including database creation, tokenization, annotation, dictionary-based analysis, sentiment analysis, variable creation, cleaning, and final database compilation.

- **Decomposed Scripts**: The 📁 `Scripts` sub-directory contains the complete code broken down into different steps.

## Data Description

### Numerical Database

- 📄 `QC.unc.data_daily.csv`: This file contains the main indices produced by the code and used in the development of OLS, SEM models, and graphical results concerning the interaction between decision-makers' uncertainty sentiments, negative sentiments, evidence level, and the stringency of health measures implemented during the pandemic in Quebec. Here is a summary of the indices:
   - ID: Weekly numbering
   - date: Date
   - wave: Official contamination waves [defined by INSPQ](https://www.inspq.qc.ca/covid-19/donnees/ligne-du-temps)
   - SPHM: Policy stringency index for NPI excluding vaccination (data from IRPP, see below)
   - SI: Stringency Index including vaccination measures (data from IRPP, see below)
   - UNC: Uncertainty Sentiment Index of decision-makers and public health representatives (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault, M. Arruda, M. Boileau)
   - EVD: Evidence Level Index of decision-makers (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault)
   - NEG: Negative Sentiment Index concerning the pandemic from decision-makers (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault)
   - CC100: Index scaled to 100 of the daily confirmed COVID-19 cases (data from INSPQ, see below)
   - CD100: Index scaled to 100 of the daily confirmed COVID-19 deaths (data from INSPQ, see below)
   - TH100: Index scaled to 100 of daily COVID-19 hospitalizations (data from INSPQ, see below)
   - VAX100: Index scaled to 100 of daily COVID-19 vaccinations (data from INSPQ, see below)
   - CC: Number of daily confirmed COVID-19 cases (data from INSPQ, see below)
   - CD: Number of daily confirmed COVID-19 deaths (data from INSPQ, see below)
   - TH: Number of daily COVID-19 hospitalizations (data from INSPQ, see below)
   - VAX: Number of daily COVID-19 vaccinations (data from INSPQ, see below)
   
- 📄 `QC.Conf_pers_clean.csv`: This database contains the names and first names of individuals who spoke at the press conferences identified by the code.

- 📄 `QC.Conf_journalis_clean.csv`: This database contains the names and first names of journalists who spoke at the press conferences, along with their corresponding media outlets, identified by the code.

- 📄 `QC.Conf_decideurs_incipitclean.csv`: This database contains the names and first names of decision-makers/public health representatives/experts/guests who spoke at the press conferences identified by the code.

- 📄 `QC.COVID_data`: Compiles epidemiological data from Quebec during the pandemic, [sourced from the Quebec National Institute of Public Health (INSPQ)](https://www.inspq.qc.ca/covid-19/donnees).

- 📄 `QC.IRPPstringency_data.csv`: Details the stringency of health measures, [sourced from the Public Policy Research Institute (IRPP)](https://centre.irpp.org/fr/data/politiques-provinciales-sur-la-pandemie-de-covid-19/).

- 📄 `QC.vax_data`: Contains vaccination data, [provided by the Quebec National Institute of Public Health (INSPQ)](https://www.inspq.qc.ca/covid-19/donnees).

### Textual Database

- 📄 `QC.conf_texts.csv`: A compilation of all press conferences held by the Quebec government regarding the COVID-19 pandemic.

- 📁 Directory `Press_conferences` archives each of the Quebec government's press conferences during the pandemic individually.

- 📁 Various extraction folders within `recup_transcriptions` contain press conferences extracted from the National Assembly's website.

- 📁 Directory `Texts_youtube` (located in `Press_conferences`): Contains press conferences that were automatically transcribed and then manually validated.
   - 📁 Sub-directory `Original_autotranscribed`: Contains the transcriptions before review.

### Analyses

- 📁 The `Results` directory archives analysis results from a research project focusing on the interaction between feelings of uncertainty, negative sentiments, the level of evidence, and the stringency of health measures during the COVID-19 pandemic in Quebec.

## Upcoming Updates

Differentiated indices of sentiments of uncertainty and negative sentiments by category (political decision-makers, public health representatives, experts, and journalists).
