# SpotLocal - Architecture & Rules for AI Agents

## Core Mission
Offline-first Android music player replicating Spotify's UI/UX. Solves the issue of media scanners ingesting WhatsApp notes/ringtones by using **Explicit Scoped Folder Isolation**.

## Non-Negotiable Constraints
1. **Never use Android MediaStore:** Scan ONLY directories explicitly saved in SQLite `scan_folders`.
2. **Never run I/O on UI thread:** File traversal, ID3 parsing, and hashing must happen in a background Dart Isolate.
3. **No audio re-encoding:** Stream raw bytes directly to the hardware decoder via `just_audio`.
4. **Offline first:** Zero network calls. Everything caches to local SQLite via `sqflite`.

## Tech Stack
- Flutter 3.x (Dart) targeting Android (API 24+)
- Playback: `just_audio` + `audio_service`
- Metadata: `metadata_god` or `audiotags`
- Database: `sqflite` + `path_provider`
- State: `flutter_riverpod` (or `flutter_bloc`)
- Design System: Spotify Dark (`#121212`, `#181818`, Green `#1DB954`)