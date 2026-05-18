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
MEETING_OPTIONS = CONFIG.get('meeting_options', {})

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
last_detected_foreign_language = COUNTERPART_LANGUAGE
speaker_segment_counter = 0


def normalize_code(code):
    if code in SUPPORTED_LANGUAGES:
        return SUPPORTED_LANGUAGES[code].get('argos_code', code)
    return code


def get_translation(source_code, target_code):
    source_code = normalize_code(source_code)
    target_code = normalize_code(target_code)

    if source_code == target_code:
        return None

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


def translate_text(text, source_code, target_code):
    if source_code == target_code:
        return text

    translator = get_translation(source_code, target_code)

    if not translator:
        return text

    try:
        return translator.translate(text)
    except Exception:
        return text


def determine_single_target_language(detected_language):
    global last_detected_foreign_language

    if detected_language == USER_LANGUAGE:
        return last_detected_foreign_language

    last_detected_foreign_language = detected_language
    return USER_LANGUAGE


def determine_meeting_targets(detected_language):
    targets = []

    if MEETING_OPTIONS.get('output_to_user_language', True):
        targets.append(USER_LANGUAGE)

    if MEETING_OPTIONS.get('output_to_counterpart_language', True):
        targets.append(COUNTERPART_LANGUAGE)

    if MEETING_OPTIONS.get('output_to_common_language', True):
        targets.append(MEETING_OPTIONS.get('common_language', 'en'))

    for lang in MEETING_OPTIONS.get('meeting_output_languages', []):
        targets.append(lang)

    unique_targets = []

    for target in targets:
        if target and target not in unique_targets and target != detected_language:
            unique_targets.append(target)

    return unique_targets


def classify_speaker_segment(detected_language):
    global speaker_segment_counter
    speaker_segment_counter += 1

    if not MEETING_OPTIONS.get('speaker_separation', False):
        return 'speaker_unknown'

    participant_map = MEETING_OPTIONS.get('participant_language_map', {})

    for speaker_id, language in participant_map.items():
        if language == detected_language:
            return speaker_id

    return f'segment_{speaker_segment_counter}'


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

        text = ''.join(segment.text for segment in segments).strip()

        if not text:
            continue

        detected_language = info.language or USER_LANGUAGE
        speaker_id = classify_speaker_segment(detected_language)

        console.print(f'[magenta]SPEAKER:[/magenta] {speaker_id}')
        console.print(f'[cyan]DETECTED:[/cyan] {detected_language}')
        console.print(f'[yellow]SOURCE:[/yellow] {text}')

        if MEETING_MODE:
            targets = determine_meeting_targets(detected_language)

            if not targets:
                console.print('[yellow]No target language selected.[/yellow]')
                continue

            user_translation_for_voice = None

            for target_language in targets:
                translated = translate_text(
                    text,
                    detected_language,
                    target_language,
                )

                console.print(
                    f'[green]TRANSLATED {detected_language}->{target_language}:[/green] {translated}'
                )

                if target_language == USER_LANGUAGE:
                    user_translation_for_voice = translated

            if user_translation_for_voice:
                try:
                    engine.say(user_translation_for_voice)
                    engine.runAndWait()
                except Exception:
                    pass

            continue

        target_language = determine_single_target_language(detected_language)
        translated = translate_text(text, detected_language, target_language)

        console.print(f'[cyan]TARGET:[/cyan] {target_language}')
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
