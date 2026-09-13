# 🏛️ SpotLocal Architecture Documentation

This document describes the software architecture, data flow, and design principles behind **SpotLocal**.

---

## 🎯 Architecture Principles

1. **Offline-First & Local Sovereignty**: No network requests required for core audio playback, indexing, or playlist operations.
2. **Explicit Scoped Folder Isolation**: Never rely on Android `MediaStore` queries that pull unwanted voice notes and system sounds. Only scan directories explicitly authorized by the user.
3. **Non-Blocking UI Thread**: Heavy metadata extraction (ID3 parsing, SHA-256 audio hashing, album art resizing) runs exclusively in dedicated background Dart Isolates.
4. **Unidirectional Reactive State**: Flutter Riverpod manages all player state, queue changes, and database sync hooks.

---

## 🏗️ System Overview

```
+-------------------------------------------------------------+
|                      Flutter UI Layer                       |
|   (HomeScreen, LibraryScreen, ExpandedPlayer, MiniPlayer)   |
+------------------------------+------------------------------+
                               | Ref-watch & Listeners
                               v
+-------------------------------------------------------------+
|                     State Management Layer                  |
|          (PlayerNotifier, ScannerNotifier, SleepTimer)      |
+-------------------+---------------------+-------------------+
                    |                     |
                    v                     v
+-----------------------+     +-------------------------------+
|      Audio Handler    |     |         Local Database        |
|     (just_audio +     |     |            (sqflite)          |
|    audio_service)     |     |   tracks, scan_folders,       |
|                       |     |   playlists, playlist_tracks  |
+-----------------------+     +---------------+---------------+
                                              ^
                                              | Batch Writes
                                              |
                              +---------------+---------------+
                              |    Background Isolate Scanner |
                              |  (ID3, audiotags, crypto)     |
                              +-------------------------------+
```

---

## 📁 Database Schema (SQLite)

### `scan_folders`
Stores paths configured by the user for media discovery:
- `id`: INTEGER PRIMARY KEY AUTOINCREMENT
- `path`: TEXT UNIQUE NOT NULL (Normalized path)
- `created_at`: INTEGER NOT NULL (Epoch timestamp)
- `is_enabled`: INTEGER NOT NULL DEFAULT 1

### `tracks`
Normalized audio track metadata:
- `id`: INTEGER PRIMARY KEY AUTOINCREMENT
- `title`: TEXT NOT NULL
- `artist`: TEXT
- `album`: TEXT
- `track_number`: INTEGER
- `duration_ms`: INTEGER NOT NULL
- `file_path`: TEXT UNIQUE NOT NULL
- `folder_path`: TEXT NOT NULL (FOREIGN KEY -> scan_folders.path)
- `file_hash`: TEXT NOT NULL (SHA-256 for duplicate detection)
- `artwork_path`: TEXT
- `date_added`: INTEGER NOT NULL

### `playlists` & `playlist_tracks`
Relational playlist management with user-defined ordering.

---

## 🔄 Background File Scanning Pipeline

1. **Folder Registration**: User selects a folder via SAF (`file_picker`). The path is normalized and saved in `scan_folders`.
2. **Isolate Spawn**: A background Dart Isolate is spawned with a `ReceivePort` / `SendPort` handshake.
3. **Traversal**: Recursive directory crawl looking for valid audio formats (`.mp3`, `.flac`, `.m4a`, `.wav`).
4. **Metadata Extraction**: ID3 tags extracted using `metadata_god` / `audiotags`. Embedded covers written to local cache.
5. **Batch Ingestion**: Tracks are emitted in chunks of 50 to the main isolate and written to SQLite within a single ACID transaction (`db.transaction`).
