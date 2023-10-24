# Code et base de données

## À propos

Cette plateforme propose des codes et des bases de données dédiés à la collecte, au traitement et à l'analyse des conférences de presse tenues par le gouvernement du Québec durant la pandémie de COVID-19. 

Les analyses englobent :
- L'identification des différents locuteurs (décideurs politiques, représentants de la santé publique, journalistes, genre).
- Une analyse des marqueurs d'incertitude basée sur Claveau et al. (2020).
- Une analyse de sentiments basée sur Duval et Pétry (2016).
- Une analyse par dictionnaire permettant d'identifier les phrases relatives à divers sujets tels que la pandémie, la vaccination, les preuves scientifiques, ou encore les groupes cibles des mesures sanitaires.

## Brève description des codes

### 📁 Dossier `AutoTranscribeAndScrape`

Ce dossier contient trois types de codes Python :

1. **Récupération des transcriptions** :
   - 📄 `Extract_conf_covid.py`
   - 📄 `Extract_conf_not_covid.py`
   - 📄 `Extract_pp_covid.py`
   - 📄 `Extract_pp_covid.py`
   
   Ces scripts, situés dans le sous-dossier `recup_transcriptions`, permettent d'extraire les conférences de presse et les points de presse depuis le 01 janvier 2020 sur la pandémie de COVID-19 depuis le site de l'Assemblée nationale du Québec.

2. **Récupération audio** :
   - 📄 `recuperation_audio_conference.py`
   
   Ce script, situé dans le sous-dossier `AutoTranscribe`, permet de récupérer l'audio des conférences de presse non retranscrites à partir de vidéos YouTube en utilisant le fichier 📄 `hyperliens_conferences.csv`.

3. **Transcription automatique** :
   - 📄 `transcription.py`
   
   Ce script utilise Whisper d'OpenAI pour transcrire automatiquement l'audio des conférences de presse manquantes. Un fichier 📄 `annotations_langues.csv` est utilisé pour exclure les portions audio en anglais.

### 📁 Dossier `Code`

- **Traitement complet** :
   - 📄 `Full_code.R`
   
   Ce script R permet le traitement complet des conférences de presse.

- **Scripts décomposés** : Le sous-dossier 📁 `Scripts` contient le code complet décomposé en différentes étapes.

## Description des données

### Base de données textuelles

- 📁 Dossier `Press_conferences` archive toutes les conférences du gouvernement du Québec durant la pandémie. Elles sont aussi regroupées dans 📄 `QC.conf_texts.csv`.

- 📁 Les différents dossiers d'extractions contenus dans `recup_transcriptions` contiennent les conférences de presse extraites du site de l'Assemblée nationale.

- 📁 Dossier `Texts_youtube` (situé dans `Press_conferences`) : Contient les conférences de presse qui ont été automatiquement transcrites puis validées manuellement.
   - 📁 Sous-dossier `Original_autotranscribed` : Contient les transcriptions avant relecture.

### Base de données numériques

- 📄 `QC.COVID_data` : rassemble les données épidémiologiques du Québec durant la pandémie, issues de l'Institut national de santé publique du Québec (INSPQ).

- 📄 `QC.IRPPstringency_data.csv` : détaille la sévérité des mesures sanitaires, provenant de l'Institut de recherche en politiques publiques (IRPP).

- 📄 `QC.vax_data` : contient les données de vaccination, fournies par l'Institut national de santé publique du Québec (INSPQ).



