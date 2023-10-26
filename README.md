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

### Base de données textuelles

- 📁 Dossier `Press_conferences` archive toutes les conférences du gouvernement du Québec durant la pandémie. Elles sont aussi compilées dans 📄 `QC.conf_texts.csv`.

- 📁 Les différents dossiers d'extractions contenus dans `recup_transcriptions` contiennent les conférences de presse extraites du site de l'Assemblée nationale.

- 📁 Dossier `Texts_youtube` (situé dans `Press_conferences`) : Contient les conférences de presse qui ont été automatiquement transcrites puis validées manuellement.
   - 📁 Sous-dossier `Original_autotranscribed` : Contient les transcriptions avant relecture.

### Base de données numériques

- 📄 `QC.unc.data_daily.csv` : est le fichier contenant l'ensemble de la base de données traitées par le code et utilisées dans la production des modèles OLS, SEM et des résultats graphiques. Voici 
   - ID : Numérotation de chaque jour 
   - date : Date
   - wave : Vague de contamination officielle définie par l'INSPQ
   - SPHM : Indice de sévérité des mesures sanitaires
   - SI : Indice de sévérité des mesures sanitaires + mesures vaccinales
   - UNC : Indice des sentiments d'incertitude des décideurs et des représentants de la Santé publique (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault, M. Arruda, M. Boileau)
   - EVD : Indice du niveau de preuve scientifique des décideurs (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault)
   - NEG : Indice des sentiments négatifs concerant la pandémie des décideurs (M. Legault, Mme McCann, M. Dubé, Mme. Guilbault)
   - CC100 : Indice mis sur 100 du nombre de cas confirmés de COVID-19 par jour (données de l'INSPQ)
   - CD100 : Indice mis sur 100 du nombre de morts confirmées de la COVID-19 par jour (données de l'INSPQ)
   - TH100 : Indice mis sur 100 du nombre d'hospitalisations dues à la COVID-19 par jour (données de l'INSPQ)
   - VAX100 : Indice mis sur 100 du nombre de personnes vaccinées contre la COVID-19 par jour (données de l'INSPQ)
   - CC : Nombre de cas confirmés de COVID-19 par jour (données de l'INSPQ)
   - CD : Nombre de morts confirmées de la COVID-19 par jour (données de l'INSPQ)
   - TH : Nombre d'hospitalisations dues à la COVID-19 par jour (données de l'INSPQ)
   - VAX : Nombre de personnes vaccinées contre la COVID-19 par jour (données de l'INSPQ)
   
- 📄 `QC.COVID_data` : rassemble les données épidémiologiques du Québec durant la pandémie, [issues de l'Institut national de santé publique du Québec (INSPQ)](https://www.inspq.qc.ca/covid-19/donnees).

- 📄 `QC.IRPPstringency_data.csv` : détaille la sévérité des mesures sanitaires, [provenant de l'Institut de recherche en politiques publiques (IRPP)](https://centre.irpp.org/fr/data/politiques-provinciales-sur-la-pandemie-de-covid-19/).

- 📄 `QC.vax_data` : contient les données de vaccination, [fournies par l'Institut national de santé publique du Québec (INSPQ)](https://www.inspq.qc.ca/covid-19/donnees).



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

### Textual Database

- 📁 Directory `Press_conferences` archives all the press conferences by the Quebec government during the pandemic. They are also compiled in 📄 `QC.conf_texts.csv`.

- 📁 Various extraction directories within `recup_transcriptions` contain press conferences extracted from the National Assembly's website.

- 📁 Directory `Texts_youtube` (located within `Press_conferences`): Contains press conferences that were automatically transcribed and then manually validated.
   - 📁 Sub-directory `Original_autotranscribed`: Contains transcriptions before review.

### Numerical Database

- 📄 `QC.COVID_data`: Compiles epidemiological data [from Quebec during the pandemic, sourced from the Quebec National Institute of Public Health (INSPQ)](https://www.inspq.qc.ca/covid-19/donnees).

- 📄 `QC.IRPPstringency_data.csv`: Details the severity of health measures, [sourced from the Public Policy Research Institute (IRPP)](https://centre.irpp.org/fr/data/politiques-provinciales-sur-la-pandemie-de-covid-19/).

- 📄 `QC.vax_data`: Contains vaccination data, [provided by the Quebec National Institute of Public Health (INSPQ)](https://www.inspq.qc.ca/covid-19/donnees).


