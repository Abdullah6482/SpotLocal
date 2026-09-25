<div align="center">

  # 🎵 SpotLocal

  **An offline-first Android music player replicating Spotify's UI/UX, powered by Explicit Scoped Folder Isolation.**

  [![CI](https://github.com/Abdullah6482/SpotLocal/actions/workflows/flutter_ci.yml/badge.svg)](https://github.com/Abdullah6482/SpotLocal/actions/workflows/flutter_ci.yml)
  [![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
  [![Android](https://img.shields.io/badge/Android-API%2024%2B-3DDC84?logo=android&logoColor=white)](https://developer.android.com)
  [![State Management](https://img.shields.io/badge/State-Riverpod-42A5F5)](https://riverpod.dev)
  [![Database](https://img.shields.io/badge/Database-SQLite%20%2F%20sqflite-003B57?logo=sqlite&logoColor=white)](https://pub.dev/packages/sqflite)
  [![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

</div>

---

## 🚀 The Core Mission

Standard Android music apps rely on Android's `MediaStore`, which indiscriminately ingests **WhatsApp voice notes, call recordings, system ringtones, and notification sounds** into your music library.

**SpotLocal** solves this by enforcing **Explicit Scoped Folder Isolation**. It scans **ONLY** directories explicitly added to SQLite `scan_folders` by the user, providing a pristine, clutter-free Spotify-grade music experience.

---

## ✨ Key Features

### 🎨 Dynamic Player Background Gradient
- Real-time color palette extraction (`palette_generator`) directly from local MP3 album art bytes.
- Animated 500ms `LinearGradient` background transition matching the active track's mood.

### 🎵 Categorized Horizontal Album Carousels
- Replaces generic vertical tracklists with categorized horizontal scrolling rows grouped by album.
- Built with nested `ListView.builder`s to maintain maximum rendering performance on large audio collections.

### 📻 Docked Persistent Mini-Player
- A persistent mini-player resting immediately above the `BottomNavigationBar`.
- Seamless track info display, play/pause controls, and interactive modal expansion while browsing Home, Search, or Library tabs.

### ⏱️ Smart Sleep Timer & Playback Speed
- **Sleep Timer:** Preset timers (15m, 30m, 45m, 60m) or automatic pause on "End of Current Track".
- **Variable Playback Speed:** Fine-grained speed adjustments (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x) with pitch preservation.
- **Audio Fading:** Smooth volume attenuation on pause to prevent clicking artifacts.

### ❤️ Liked Songs & Recently Played History
- Instant one-tap favorite toggling with indexed SQLite persistence.
- Automatic recently played track history deduplication (capped at top 50 plays).
- Multi-criteria sorting (Title, Artist, Duration, Date Added).

### 📜 Offline Embedded ID3 Lyrics
- Parses unsynchronized ID3 `USLT` frames directly from local audio tags (`audiotags`) without an internet connection.
- Displays lyrics inside a sleek, drag-handle translucent modal (`DraggableScrollableSheet`).

### 🔄 Auto-Sync & Background Isolate Scanner
- **Zero UI Stutter:** File traversal, ID3 extraction, and SHA-256 hashing run completely inside background Dart Isolates.
- **Sanitization & Resilience:** Automatic fallback titles from sanitized filenames if ID3 headers are missing or corrupted.
- **Auto-Reload:** Automatically updates track collections when scanning finishes or folders are toggled.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.x (Dart)** | Cross-platform mobile UI targeting Android (API 24+) |
| **State Management** | **Flutter Riverpod** | Reactive, compile-safe application state |
| **Audio Engine** | **`just_audio` + `audio_service`** | Low-latency audio decoding and background lock-screen notifications |
| **Local Database** | **`sqflite` + `path_provider`** | Offline-first track, playlist, favorites, and history persistence |
| **Background Scanning** | **Dart Background Isolates** | Zero UI thread stuttering during ID3 tag extraction and SHA-256 hashing |
| **Metadata & Color** | **`audiotags` + `palette_generator`** | Offline USLT frame parsing and dynamic color scheme extraction |
| **Design System** | **Spotify Dark** | Pure dark theme (`#121212`, `#181818`, Green `#1DB954`) |

For an in-depth architectural breakdown, check out [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md).

---

## 🧪 Automated Testing Suite

SpotLocal emphasizes high code reliability through an automated test suite:

```bash
# Run unit and widget test suites
flutter test

# Generate test coverage report
flutter test --coverage
```

### Coverage Highlights:
- **Core Domain:** Track model serialization, ScanFolder validation, and Android SAF path normalization.
- **Player State:** State transitions, copyWith immutability, playback speed, and repeat/shuffle synchronization.
- **Sleep Timer:** Countdown ticks, end-of-track triggers, and cancellation callbacks.
- **Audio Utilities:** Volume fading linear interpolation and scanner filename sanitization.
- **Database DAOs:** Favorites queries and recently played listening history pruning.

---

## 📦 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.10.0`)
- Android SDK (Targeting API level 24+)
- An Android Device or Emulator

### Installation & Local Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/Abdullah6482/SpotLocal.git
   cd SpotLocal
   ```

2. **Install Flutter dependencies:**
   ```bash
   flutter pub get
   ```

3. **Run on a connected Android device:**
   ```bash
   flutter run
   ```

4. **Build a Release APK:**
   ```bash
   flutter build apk --release --split-per-abi
   ```
   The APKs will be generated under `build/app/outputs/flutter-apk/`.

---

## 🗺️ Product Roadmap

- [x] Background Dart Isolate file scanner
- [x] Scoped folder isolation via SQLite
- [x] Dynamic album art gradient backdrop
- [x] Offline embedded ID3 lyrics
- [x] Sleep timer & variable playback speeds
- [x] Liked songs & recently played history
- [ ] In-app 5-band Graphic Equalizer
- [ ] Export / import playlists as M3U8

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
