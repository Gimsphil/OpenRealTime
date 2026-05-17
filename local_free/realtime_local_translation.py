import queue
import threading

import numpy as np
import sounddevice as sd
from faster_whisper import WhisperModel
from argostranslate import package, translate
import pyttsx3
from rich.console import Console

console = Console()

SAMPLE_RATE = 16000
BLOCK_DURATION = 3

console.print('[bold green]OpenRealTime Local Mode[/bold green]')

model = WhisperModel('base', device='auto', compute_type='int8')

installed_languages = translate.get_installed_languages()

translator = None

for src in installed_languages:
    for dst in installed_languages:
        if src.code == 'en' and dst.code == 'ko':
            translator = src.get_translation(dst)

if translator is None:
    console.print('[yellow]No Argos translation package installed.[/yellow]')
    console.print('[yellow]Translation will fallback to original text.[/yellow]')

engine = pyttsx3.init()

audio_queue = queue.Queue()


def audio_callback(indata, frames, time, status):
    audio_queue.put(indata.copy())


def process_audio():
    while True:
        chunks = []

        while len(chunks) < int(SAMPLE_RATE / 1024 * BLOCK_DURATION):
            chunks.append(audio_queue.get())

        audio = np.concatenate(chunks, axis=0)
        audio = audio.flatten().astype(np.float32)

        segments, info = model.transcribe(audio)

        text = ''

        for segment in segments:
            text += segment.text

        text = text.strip()

        if not text:
            continue

        console.print(f'[cyan]SOURCE:[/cyan] {text}')

        translated = text

        try:
            if translator:
                translated = translator.translate(text)
        except Exception:
            translated = text

        console.print(f'[green]TRANSLATED:[/green] {translated}')

        try:
            engine.say(translated)
            engine.runAndWait()
        except Exception:
            pass


thread = threading.Thread(target=process_audio, daemon=True)
thread.start()

with sd.InputStream(
    samplerate=SAMPLE_RATE,
    channels=1,
    blocksize=1024,
    callback=audio_callback,
):
    console.print('[bold green]Listening...[/bold green]')

    while True:
        sd.sleep(1000)
