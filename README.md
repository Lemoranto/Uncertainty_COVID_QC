# Code et base de données

## À propos

Cette plateforme propose des codes et des bases de données dédiés à la collecte, au traitement et à l'analyse des conférences de presse tenues par le gouvernement du Québec durant la pandémie de COVID-19. 

Les analyses englobent :
- L'identification des différents locuteurs (décideurs politiques, représentants de la santé publique, journalistes, genre).
- Une analyse des marqueurs d'incertitude basée sur Claveau et al. (2020).
- Une analyse de sentiments basée sur Duval et Pétry (2016).
- Une analyse par dictionnaire permettant d'identifier les phrases relatives à divers sujets tels que la pandémie, la vaccination, les preuves scientifiques, ou encore les groupes cibles des mesures sanitaires.

## Codes

### Dossier `AutoTranscribeAndScrape`

Ce dossier regroupe trois types de codes Python :

1. **Récupération des transcriptions** : Les scripts situés dans `recup_transcriptions` (`Extract_conf_covid.py`, `Extract_conf_not_covid.py`, `Extract_pp_covid.py`, `Extract_pp_covid.py`) permettent d'extraire les conférences de presse et les points de presse depuis le 01 janvier 2020 depuis le site de l'Assemblée nationale du Québec.

2. **Récupération audio** : `recuperation_audio_conference.py` dans `AutoTranscribe` sert à récupérer l'audio des conférences non transmises ou retranscrites par le gouvernement depuis des vidéos YouTube. L'extraction se base sur le fichier `hyperliens_conferences.csv`.

3. **Transcription automatique** : `transcription.py` exploite Whisper d'OpenAI pour transcrire l'audio des conférences précédemment extraites, tout en distinguant les différents locuteurs. Un fichier `annotations_langues.csv` aide à segmenter manuellement les portions audio en anglais pour éviter leur transcription.

### Dossier `Code`

- **Traitement intégral** : `Full_code` en R assure le traitement complet des conférences, incluant la création de la base de données, tokénisation, annotation, analyses diverses, nettoyage et compilation.

- **Scripts détaillés** : `Scripts` décompose le code complet en étapes distinctes.

## Données

### Bases de données textuelles

- **Conferences de presse** : `Press_conferences` archive toutes les conférences du gouvernement du Québec durant la pandémie. Elles sont aussi regroupées dans `QC.conf_texts.csv`.

- **Transcriptions extraites** : Les conférences extraites du site de l'Assemblée nationale sont accessibles dans les sous-dossiers de `recup_transcriptions`.

- **Transcriptions automatiques** : Les conférences transmises automatiquement sont dans `Texts_youtube` de `Press_conferences`. Après relecture et validation manuelle, les versions originales sont conservées dans `Original_autotranscribed` du dossier `Texts_validation`.

### Bases de données numériques

- **Données épidémiologiques** : `QC.COVID_data` rassemble les données épidémiologiques du Québec durant la pandémie, issues de l'Institut national de santé publique du Québec (INSPQ).

- **Mesures sanitaires** : `QC.IRPPstringency_data.csv` détaille la sévérité des mesures sanitaires, provenant de l'Institut de recherche en politiques publiques (IRPP).

- **Données de vaccination** : `QC.vax_data` contient les données de vaccination, fournies par l'Institut national de santé publique du Québec (INSPQ)..

