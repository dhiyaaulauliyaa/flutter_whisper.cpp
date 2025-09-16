# Whisper Models

This directory contains the whisper.cpp model files used by the application.

## Required Models

The following models are required but not included in the git repository due to their large size:

- `ggml-base.en.bin` (~148 MB) - Base English model

## Download Instructions

### Base Model
```bash
# Download the base English model
curl -L "https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-base.en.bin" -o models/ggml-base.en.bin
```

## Model Management

- Models are automatically excluded from git via `.gitignore`
- Ensure models are downloaded before running the application
- Check model file integrity if experiencing issues

## Supported Formats
- `.bin` - Standard whisper.cpp format
- `.ggml` - Legacy whisper.cpp format
- Other ML formats (`.onnx`, `.pt`, `.pth`, `.safetensors`) are also supported