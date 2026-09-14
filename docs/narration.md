# Neural narrator

The seven English act poems now use **Kokoro v1.0, `bm_george`, British English**.
Text remains in `ui/story_book.gd` (`VOICES`). The generator uses a measured reading
pace (0.86–0.92), punctuation-sensitive line breaks, a longer pause before the final
question, and consistent loudness with playback headroom. No pitch shift, vocoder,
or artificial room echo is applied. This is synthetic speech, not an actor recording.

Kokoro runs locally with no account, subscription or paid speech API. Python and the
model are generation tools only: the game plays ordinary mono 24 kHz PCM WAV files.
The generated `narration_cues.gd` records line starts for synchronized subtitles.

## Regenerate

Python 3.12 is installed in the project's ignored `.tools/narration-venv` environment.
The model files are in `.tools/narration-models`. On this machine:

```sh
.tools/narration-venv/bin/python shared/audio/generate_narration.py
```

To create a separate voice audition without replacing game audio:

```sh
.tools/narration-venv/bin/python shared/audio/generate_narration.py --voice bm_fable --act study --output builds/narration-audition
```

For a fresh setup, create a Python 3.12 virtual environment at `.tools/narration-venv`,
install `kokoro-onnx==0.4.9` and `soundfile==0.14.0`, and download these files into
`.tools/narration-models`:

- https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.1/kokoro-v1.0.onnx
- https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.1/voices-v1.0.bin

Keep `.tools/.gdignore` so Godot excludes the tooling and models.
All requested verses are synthesized into staging before replacing the WAV files.
The previous macOS narration and generator are backed up in
`builds/narration-original/` on this machine.

## Sources

- Kokoro model and voice inventory (Apache 2.0): https://huggingface.co/hexgrad/Kokoro-82M
- Voice definitions: https://huggingface.co/hexgrad/Kokoro-82M/blob/main/VOICES.md
- ONNX inference library (MIT) and setup: https://github.com/thewh1teagle/kokoro-onnx

These sources supersede the macOS-voice provenance for `shared/audio/narrator/*.wav`.
Other vocal effects still have their own existing provenance in the asset register.
