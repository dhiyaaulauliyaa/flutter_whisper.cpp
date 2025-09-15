# WARP.md

This file provides guidance to WARP (warp.dev) when working with code in this repository.

## Project Overview

This is a Flutter application that provides offline automatic speech recognition (ASR) using OpenAI's Whisper model. The app records audio, converts it to the required format, and transcribes it using a Rust-based Whisper implementation via Flutter Rust Bridge (FFI).

## Key Architecture Components

### Flutter-Rust Bridge Integration
- **Primary bridge file**: `lib/bridge_generated.dart` (auto-generated, do not edit manually)
- **Rust API**: `rs_whisper_gpt/src/api.rs` - contains the main `run_whisper_model` function
- **FFI setup**: Dynamic library loading in `lib/main.dart` with platform-specific paths
- **Bridge generation command**: 
  ```bash
  flutter_rust_bridge_codegen --rust-input rs_whisper_gpt/src/api.rs --dart-output lib/bridge_generated.dart -c ios/Runner/bridge_generated.h -e macos/Runner/
  ```

### Audio Processing Pipeline
1. **Recording**: Uses `record` package to capture .m4a audio on iOS
2. **Conversion**: FFmpeg converts .m4a to 16kHz mono WAV format required by Whisper
3. **Transcription**: Rust code processes WAV file through Whisper model
4. **Playback**: `audioplayers` package handles audio playback

### Platform Support
- ✅ iOS (17.0.3+, XCode 15.0+)
- ✅ macOS (Sonoma 14.0+, XCode 15.0+)  
- ❌ Android, Linux, Windows (not yet tested)
- ⚠️ iOS Simulator not supported (FFmpeg library conflict)

## Essential Development Commands

### Setup and Dependencies
```bash
# Install required system dependencies (macOS with Homebrew)
brew install cmake

# Add iOS targets for Rust
rustup target add aarch64-apple-ios
rustup target add x86_64-apple-ios
rustup target add aarch64-apple-ios-sim

# Install Flutter dependencies
flutter pub get

# Build Rust library
cd rs_whisper_gpt && cargo build

# Build Rust library for release (recommended)
cd rs_whisper_gpt && cargo build --release

# Build Rust library for iOS (required for device deployment)
cd rs_whisper_gpt && IPHONEOS_DEPLOYMENT_TARGET=12.0 cargo build --release --target aarch64-apple-ios

# Run code generation (after Rust API changes)
flutter_rust_bridge_codegen --rust-input rs_whisper_gpt/src/api.rs --dart-output lib/bridge_generated.dart -c ios/Runner/bridge_generated.h -e macos/Runner/

# Generate additional code (freezed, build_runner)
flutter packages pub run build_runner build
```

### Running and Testing
```bash
# Run on specific device (required - simulator not supported)
flutter run -d [device_id]

# List available devices
flutter devices

# Run tests
flutter test

# Run integration tests  
flutter test integration_test/
```

### Rust Development
```bash
# Build Rust crate
cd rs_whisper_gpt
cargo build --release

# Check Rust code
cargo check
cargo clippy
```

## Model Configuration

### Default Model Setup
- Model file: `ggml-base.en.bin` (English-only base model)
- Location: Must be accessible to XCode project in `Runner/Runner` directory
- Model loading: Handled via iOS bundle resource lookup in Rust code

### Changing Models
1. Download new model from [whisper.cpp models](https://github.com/ggerganov/whisper.cpp/tree/master/models)
2. Add model file to XCode project in `Runner/Runner` directory
3. Update model filename in `rs_whisper_gpt/src/api.rs` line 92
4. Regenerate bridge code with `flutter_rust_bridge_codegen`
5. For multilingual models, use `.bin` instead of `.en.bin` and update language parameter

## Critical Implementation Details

### Rust-iOS Integration
- Uses Objective-C runtime bindings to access iOS bundle resources
- Model path resolution via `NSBundle.mainBundle.resourcePath`
- Memory management with `autoreleasepool` for iOS compatibility

### Audio Format Requirements
- Sample rate: 16kHz
- Channels: Mono (1 channel)  
- Format: 16-bit PCM WAV
- Conversion handled automatically via FFmpeg

### Flutter State Management
- Two main UI states: `AudioRecorder` (recording) and `AudioPlayer` (playback/transcription)
- State switching based on `showPlayer` boolean
- Timer-based recording duration tracking

### Performance Optimizations
- Whisper inference uses single thread (`params.set_n_threads(1)`)
- iOS build flags include `-O3 -DNDEBUG` for performance
- Translation enabled by default (`params.set_translate(true)`)

## File Structure Significance

- `lib/main.dart` - Main app with recording/playback state management
- `lib/audio_player.dart` - Audio playback and transcription UI
- `rs_whisper_gpt/src/api.rs` - Core Whisper inference logic  
- `rs_whisper_gpt/Cargo.toml` - Rust dependencies including whisper-rs
- Platform folders (`ios/`, `macos/`) - Native build configuration

## Known Limitations

- iOS Simulator incompatible due to FFmpeg library conflicts
- Android/Linux/Windows support not implemented
- Model files must be manually added to XCode project
- Recording format limited to .m4a on iOS (converted to WAV)

## Troubleshooting Common Issues

- **CMake not found**: Install CMake with `brew install cmake` (required for whisper-rs-sys compilation)
- **whisper-rs API errors**: The project uses whisper-rs v0.12.0 (updated from v0.8.0) for CMake compatibility
- **Bridge generation errors**: Ensure flutter_rust_bridge versions match between Dart and Rust dependencies
- **Model not found**: Verify model file is added to XCode project and path matches `api.rs`
- **Recording fails**: Check microphone permissions and device capabilities
- **Transcription errors**: Ensure audio format meets Whisper requirements (16kHz mono WAV)
- **Rust build failures**: Clean cargo cache with `cargo clean` and rebuild if encountering dependency conflicts
