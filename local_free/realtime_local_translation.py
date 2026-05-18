import json
import queue
import threading
from pathlib import Path

import numpy as np
import pyttsx3
import sounddevice as sd
from argostranslate import translate
from faster_whisper import WhisperModel
from rich.console import Console

console = Console()

SAMPLE_RATE = 16000
BLOCK_DURATION = 3

CONFIG_PATH = Path(__file__).resolve().parent.parent / 'config' / 'languages.json'

with open(CONFIG_PATH, 'r', encoding='utf-8') as f:
    CONFIG = json.load(f)

USER_LANGUAGE = CONFIG.get('default_user_language', 'ko')
COUNTERPART_LANGUAGE = CONFIG.get('default_counterpart_language', 'en')
MEETING_MODE = CONFIG.get('meeting_mode', False)

SUPPORTED_LANGUAGES = {
    item['code']: item
    for item in CONFIG['supported_languages']
}

console.print('[bold green]OpenRealTime Local Multilingual Mode[/bold green]')
console.print(f'[cyan]User language:[/cyan] {USER_LANGUAGE}')
console.print(f'[cyan]Counterpart language:[/cyan] {COUNTERPART_LANGUAGE}')
console.print(f'[cyan]Meeting mode:[/cyan] {MEETING_MODE}')

model = WhisperModel('base', device='auto', compute_type='int8')

installed_languages = translate.get_installed_languages()

translator_cache = {}

engine = pyttsx3.init()

audio_queue = queue.Queue()


def get_translation(source_code, target_code):
    cache_key = f'{source_code}->{target_code}'

    if cache_key in translator_cache:
        return translator_cache[cache_key]

    source_language = None
    target_language = None

    for lang in installed_languages:
        if lang.code == source_code:
            source_language = lang
        if lang.code == target_code:
            target_language = lang

    if not source_language or not target_language:
        return None

    try:
        translation = source_language.get_translation(target_language)
        translator_cache[cache_key] = translation
        return translation
    except Exception:
        return None


last_detected_foreign_language = COUNTERPART_LANGUAGE


def determine_target_language(detected_language):
    global last_detected_foreign_language

    if MEETING_MODE:
        return USER_LANGUAGE

    if detected_language == USER_LANGUAGE:
        return last_detected_foreign_language

    last_detected_foreign_language = detected_language
    return USER_LANGUAGE



def audio_callback(indata, frames, time, status):
    audio_queue.put(indata.copy())



def process_audio():
    while True:
        chunks = []

        while len(chunks) < int(SAMPLE_RATE / 1024 * BLOCK_DURATION):
            chunks.append(audio_queue.get())

        audio = np.concatenate(chunks, axis=0)
        audio = audio.flatten().astype(np.float32)

        segments, info = model.transcribe(
            audio,
            multilingual=True,
        )

        text = ''

        for segment in segments:
            text += segment.text

        text = text.strip()

        if not text:
            continue

        detected_language = info.language or USER_LANGUAGE

        target_language = determine_target_language(detected_language)

        console.print(
            f'[cyan]DETECTED:[/cyan] {detected_language}'
        )

        console.print(
            f'[cyan]TARGET:[/cyan] {target_language}'
        )

        console.print(f'[yellow]SOURCE:[/yellow] {text}')

        translated = text

        source_argos = SUPPORTED_LANGUAGES.get(
            detected_language,
            {}
        ).get('argos_code', detected_language)

        target_argos = SUPPORTED_LANGUAGES.get(
            target_language,
            {}
        ).get('argos_code', target_language)

        translator = get_translation(
            source_argos,
            target_argos,
        )

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
