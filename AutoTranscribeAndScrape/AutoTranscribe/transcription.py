from vosk import Model, KaldiRecognizer, SetLogLevel
import os
from os import listdir
from os.path import isfile, join
from pathlib import Path
from pydub import AudioSegment
import unidecode
from vosk import SetLogLevel
import pandas as pd
import re
from datetime import datetime
import math
from pyannote.audio import Pipeline
from pyannote.core import Timeline
from pyannote.database.util import load_rttm
import language_tool_python
import whisper

whisper_model = whisper.load_model("medium")
pipeline = Pipeline.from_pretrained("pyannote/speaker-diarization@2.1", use_auth_token="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")
tool = language_tool_python.LanguageTool('fr')


def merge_audio_files(audio_files, output_file):
    merged_audio = AudioSegment.empty()
    for audio_file in audio_files:
        segment = AudioSegment.from_wav(audio_file)
        merged_audio += segment
    merged_audio.export(output_file, format='wav')



SetLogLevel(-1)

os.chdir(os.getenv("PWD"))

audio_path = os.path.join(os.getcwd(), 'data', 'audio')
tmp_audio_path = os.path.join(os.getcwd(), 'data', 'audio', 'tmp')
text_path = os.path.join(os.getcwd(), 'data', 'extracted_text')
tmp_text_path = os.path.join(os.getcwd(), 'data', 'extracted_text', 'tmp')
annotations_path = os.path.join(os.getcwd(), 'data', 'raw', 'annotations_langues.csv')

Path(tmp_audio_path).mkdir(exist_ok=True)
Path(text_path).mkdir(exist_ok=True)
Path(tmp_text_path).mkdir(exist_ok=True)

audiofiles = [f for f in listdir(audio_path) if isfile(join(audio_path, f)) and f.endswith('.wav')]
annotations_data = pd.read_csv(annotations_path, delimiter=';')
file_order = {}

for index, row in annotations_data.iterrows():
    date = row['Date']
    if date not in file_order:
        file_order[date] = index

audiofiles = sorted(audiofiles, key=lambda x: file_order.get(re.sub(r"\..+", "", x), float('inf')))



for i in range(len(audiofiles)):
    print('Processing '+audiofiles[i]+' ...', end=' ')
    audio_file_path = os.path.join(audio_path, audiofiles[i])
    date = re.sub(r"\..+", "", audiofiles[i])
    annotations = annotations_data[annotations_data['Date'] == date]
    text_file_path = unidecode.unidecode(os.path.join(text_path, 'Transcription_' + audiofiles[i].replace('.wav', '.txt').replace(' ', '_').lower()))
    if os.path.exists(text_file_path):
        print(f'Transcription already done for {text_file_path}')
        continue
    else:
        df = pd.DataFrame({
            'Date': [],
            'Time': [],
            'Langue': []
        })

    for j, row in annotations.iterrows():
        start_rel = datetime.strptime(row['Debut'], "%H:%M:%S")
        end_rel = datetime.strptime(row['Fin'], "%H:%M:%S")
        start_abs = datetime.strptime("00:00:00", "%H:%M:%S")
        duration = int((end_rel - start_rel).total_seconds())
        time_segs_rel = list(range(0, math.floor(duration), 60))
        time_segs_rel.append(duration)
        time_segs_abs = [time_seg_rel + int((start_rel - start_abs).total_seconds()) for time_seg_rel in time_segs_rel]
        df_tmp = pd.DataFrame({
            'Date': annotations.Date[j],
            'Time': time_segs_abs,
            'Langue': annotations.Langue[j]
        })
        df = pd.concat([df,df_tmp], ignore_index=True)
        print(f"Processing annotation {j+1}/{len(annotations)}...")  # Ajout d'un print pour indiquer l'avancement des annotations

    print("Annotations DataFrame:")
    print(df)




    tmpsplitfiles_fr = []
    if os.path.exists(text_file_path):
        print(f'Transcription already done for {text_file_path}')
        continue
    else:
        print(' - Splitting '+audiofiles[i]+' ...', end=' ')
        counter_count = 1
        tmpsplitfiles_check = sorted([f for f in listdir(tmp_audio_path) if isfile(join(tmp_audio_path, f)) and f.startswith(date)])
        if len(tmpsplitfiles_check) == 0:
            newAudio = AudioSegment.from_wav(audio_file_path)
            s = list(df.Time[0:(len(df.Time)-1)])
            e = list(df.Time[1:(len(df.Time))])
            lang = df.Langue
            for j in range(len(s)):
                t1 = s[j] * 1000 
                t2 = e[j] * 1000 
                tmp_newAudio = newAudio[t1:t2]
                if counter_count < 10:
                    tmp_newAudio.export(os.path.join(tmp_audio_path, date+'_part_'+'0'+str(counter_count)+'_'+lang[counter_count]+'.wav'), format="wav")
                else:
                    tmp_newAudio.export(os.path.join(tmp_audio_path, date+'_part_'+str(counter_count)+'_'+lang[counter_count]+'.wav'), format="wav")
                print(f"Temp audio file {counter_count} created")
                counter_count = counter_count + 1
            print("Temporary audio files:")
            print([f for f in listdir(tmp_audio_path) if isfile(join(tmp_audio_path, f))])
            print('done')
        else:
            print('Temp audio file already made {tmp_audio_path}')


            
        tmpsplitfiles = sorted([f for f in listdir(tmp_audio_path) if isfile(join(tmp_audio_path, f))])
        print("All following temporary split files listed:")
        for tmp_file in tmpsplitfiles:
            print(f" - {tmp_file}")
        tmpsplitfiles_fr = []
        for element in tmpsplitfiles:
            tmp = re.search(".*_fr\.wav", element)
            if tmp:
                tmpsplitfiles_fr.append(tmp.group())
        print('Now merging file...', end=' ')
        merged_audio_file = os.path.join(tmp_audio_path, date + '_merged_audio.wav')
        if os.path.exists(merged_audio_file):
            print(f'Merged audio file already exists for {merged_audio_file}')
        else:
            print('Merging into:'+merged_audio_file+' ...' , end=' ')
            merge_audio_files(sorted([os.path.join(tmp_audio_path, f) for f in tmpsplitfiles_fr]), merged_audio_file)
            print(f"Temp audio file created")
        file_name_only = os.path.basename(merged_audio_file)
        print(f"Performing speaker diarization for {file_name_only}...")

        rttm_file_name = os.path.join(tmp_text_path, f"{date}_diarization.rttm")
        if not os.path.exists(rttm_file_name):
            print(f"Performing speaker diarization for {file_name_only}...")
            diarization = pipeline(merged_audio_file)
            print(f"Speaker diarization done for {merged_audio_file}")
            
            with open(rttm_file_name, "w") as rttm_file:
                diarization.write_rttm(rttm_file)
            print(f"Saving RTTM file as {rttm_file_name}...")
        else:
            print(f'RTTM file already exists for {rttm_file_name}')
            diarization = load_rttm(rttm_file_name)[date + '_merged_audio']

        
        for tmp_audio_file_name in tmpsplitfiles_fr:
            tmp_audio_file_path = os.path.join(tmp_audio_path, tmp_audio_file_name)
            if os.path.exists(tmp_audio_file_path):
                os.remove(tmp_audio_file_path)
        print("Removing temporary French audio files...")
        tmpsplitfiles_en = []
        for element in tmpsplitfiles:
            tmp = re.search(".*_en\.wav", element)
            if tmp:
                tmpsplitfiles_en.append(tmp.group())
        print("Filtering English audio files...")
        for tmp_audio_file_name in tmpsplitfiles_en:
            tmp_audio_file_path = os.path.join(tmp_audio_path, tmp_audio_file_name)
            if os.path.exists(tmp_audio_file_path):
                os.remove(tmp_audio_file_path)
        print("Removing temporary English audio files...")
        tmpsplitfiles_fr = [os.path.basename(merged_audio_file)]

        for k, tmp_audio_file_name in enumerate(tmpsplitfiles_fr):
            print(' - Processing '+tmpsplitfiles_fr[k]+' ...', end=' ')
        tmp_audio_file_path = merged_audio_file
        split_extracted_txt = tmpsplitfiles_fr[k].replace("wav", "txt")
        split_extracted_txt_path = os.path.join(tmp_text_path, split_extracted_txt)
        if os.path.exists(split_extracted_txt_path):
            print('Already done')
        else:
            print('Transcribing audio file using Whisper...')
            result = whisper_model.transcribe(tmp_audio_file_path)
            print("Résultat de la transcription Whisper :")
            print(result)

        if 'segments' in result:
            segments = result['segments']
            words_list = []

            for segment in segments:
                segment_start = segment['start']
                segment_text = segment['text']
                words = segment_text.split()
                word_duration = 0                        

                for i, word in enumerate(words):
                        word_start = segment_start + i * word_duration
                        word_end = word_start + word_duration
                        words_list.append({'word': word, 'start': word_start, 'end': word_end, 'speaker': None})
                words_df = pd.DataFrame(words_list)
        else:
            print("Aucun segment trouvé dans le résultat de la transcription.")
            words_df = pd.DataFrame(columns=['word', 'start', 'end', 'speaker'])


        print(' - Produce transcription for '+date+' ...', end=' ')
        tmptextfiles = []
        for f in listdir(tmp_text_path):
            tmp = re.search(date+".+$", f)
            if tmp:
                tmptextfiles.append(tmp.group())
        tmptextfiles = sorted(tmptextfiles)
        timed_transcript = '\n\n\n Début de la transcription pour ' + date + '\n\n\n'
        time_follow_up = 0
        words_df_with_speaker = words_df.copy()
        print("Attributing speakers to words...")
        for turn, _, speaker in diarization.itertracks(yield_label=True):
            mask = ((words_df_with_speaker["start"] >= turn.start) & (words_df_with_speaker["end"] <= turn.end)) | \
                   ((words_df_with_speaker["start"] >= turn.start) & (words_df_with_speaker["start"] <= turn.end)) | \
                   ((words_df_with_speaker["end"] >= turn.start) & (words_df_with_speaker["end"] <= turn.end)) | \
                   ((words_df_with_speaker["start"] <= turn.start) & (words_df_with_speaker["end"] >= turn.start))
            if mask.any():
                words_df_with_speaker.loc[mask, "speaker"] = speaker
            else:
                words_df_with_speaker.loc[mask, "speaker"] = "Inconnu"
        print("Building timed transcript...")
        for i, row in words_df_with_speaker.iterrows():
            current_time = row["start"]
            if current_time >= time_follow_up * 3 * 60:
                timed_transcript += f'\n\n(suivi temps: {time_follow_up * 3} min)\n\n'
                time_follow_up += 1           
            if i == 0 or row["speaker"] != words_df_with_speaker.loc[i - 1, "speaker"]:
                timed_transcript += f'\n\nLOCUTEUR {row["speaker"]}: '
            timed_transcript += row["word"] + " "   
        timed_transcript += '\n\n\n Fin de la transcription \n\n\n'

        print("Writing transcript to file...")
        with open(text_file_path, 'w') as f:
            f.writelines(timed_transcript)
        print('Full done bébé :D')



