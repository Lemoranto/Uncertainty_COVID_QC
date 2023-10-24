# Code et base de données

## À propos

Cette plateforme contient des codes et des bases de données pour la collecte, le traitement et l'analyse des conférences de presse données par le gouvernement du Québec pendant la pandémie de COVID-19. Les analyses incluent l'identification des différents locuteurs et une analyse de sentiments.

## Description des codes

### Dossier `AutoTranscribeAndScrape`

Ce dossier contient trois types de codes Python :

1. **Récupération des transcriptions** : Les scripts `Extract_conf_covid.py`, `Extract_conf_not_covid.py`, `Extract_pp_covid.py` et `Extract_pp_covid.py` dans le sous-dossier `recup_transcriptions` permettent d'extraire les conférences de presse et les points de presse depuis le 01 janvier 2020 sur la pandémie de COVID-19 depuis le site de l'Assemblée nationale du Québec.

2. **Récupération audio** : Le script `recuperation_audio_conference.py` dans le sous-dossier `AutoTranscribe` permet de récupérer l'audio des conférences de presse non retranscrites à partir de vidéos YouTube.

3. **Transcription automatique** : Le script `transcription.py` utilise Whisper d'OpenAI pour transcrire automatiquement l'audio des conférences de presse manquantes tout en diarisant (distinguant les différents locuteurs).

### Dossier `Code`

- **Traitement complet** : Le script R `Full_code` permet le traitement complet des conférences de presse, incluant la création de la base de données, tokénisation, annotation, analyse des marqueurs d'incertitude, analyse par dictionnaire, analyse de sentiments, création des variables, et la compilation de la base de données.

- **Scripts décomposés** : Le sous-dossier `Scripts` contient le code complet décomposé en différentes étapes.

## Description des données

### Base de données textuelles

- **Conferences de presse** : Le dossier `Press_conferences` contient toutes les conférences de presse données par le gouvernement du Québec pendant la pandémie de COVID-19. Ces conférences sont également compilées dans le fichier `QC.conf_texts.csv`.

- **Transcriptions extraites** : Les conférences de presse extraites du site de l'Assemblée nationale sont également accessibles dans les sous-dossiers du dossier `recup_transcriptions`.

### Base de données numériques

- **Données épidémiologiques** : Le fichier `QC.COVID_data` contient les données épidémiologiques (cas, morts, hospitalisations) du Québec pendant la pandémie, provenant de l'Institut national de santé publique du Québec (INSPQ).

- **Sévérité des mesures sanitaires** : Le fichier `QC.IRPPstringency_data.csv` contient les données sur la sévérité des mesures sanitaires, provenant de l'Institut de recherche en politiques publiques (IRPP).

- **Données de vaccination** : Le fichier `QC.vax_data` contient les données de vaccination, provenant de l'Institut national de santé publique du Québec (INSPQ).
