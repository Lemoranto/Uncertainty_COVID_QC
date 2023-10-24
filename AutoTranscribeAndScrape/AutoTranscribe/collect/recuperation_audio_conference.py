from yt_dlp import YoutubeDL
from yt_dlp.utils import DownloadError
import os
from os import listdir
from os.path import isfile, join
import pandas as pd
import re

os.chdir(os.getenv("PWD"))

file_path = os.path.join(os.getcwd(), 'data', 'raw', 'hyperliens_conferences.csv')
data = pd.read_csv(file_path, delimiter=';')

audio_path = os.path.join(os.getcwd(), 'data', 'audio')
audio_file_names = [f for f in listdir(audio_path) if isfile(join(audio_path, f))]
audio_file_names_wo_ext = [re.sub(r"\..+", "", f) for f in audio_file_names]

for i in range(data.index.stop):

    if data.Date[i] in audio_file_names_wo_ext:
        print('Already done')
    else:

        def my_hook(d):
            if d['status'] == 'finished':
                print('Done downloading, now converting ...')

        ydl_opts = {
            'outtmpl': f'{os.getcwd()}/data/audio/{data.Date[i]}.%(ext)s',
            'format': 'bestaudio/best',
            'postprocessors': [{
            'key': 'FFmpegExtractAudio',
            'preferredcodec': 'wav',
            'preferredquality': '192',
            }],
            #'logger': MyLogger(),
            'progress_hooks': [my_hook],}

        try:
            with YoutubeDL(ydl_opts) as ydl:
                ydl.download(data.Lien[i])
        except DownloadError as e:
            print(f"Error occurred while downloading {data.Date[i]}: {e}")
            continue
