<div align="center">

  # 🎵 SpotLocal

  **An offline-first Android music player replicating Spotify's UI/UX, powered by Explicit Scoped Folder Isolation.**

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

### 📜 Offline Embedded ID3 Lyrics
- Parses unsynchronized ID3 `USLT` frames directly from local MP3 tags (`audiotags`) without an internet connection.
- Displays lyrics inside a sleek, drag-handle translucent modal (`DraggableScrollableSheet`).

### 🔄 Auto-Sync & Swipe-Down Refresh
- **Auto-Reload:** Automatically updates track collections when scanning finishes, folders are toggled, or when returning to the app/tab.
- **Pull-To-Refresh:** Features a Spotify-green pull-down `RefreshIndicator` on the Home screen.

### 🔍 Clean Search State
- Clean, focused placeholder UI on launch until search text is entered.
- Instant real-time filtering across titles, artists, and albums.

---

## 🛠️ Architecture & Tech Stack

| Layer | Technology | Purpose |
| :--- | :--- | :--- |
| **Framework** | **Flutter 3.x (Dart)** | Cross-platform mobile UI targeting Android (API 24+) |
| **State Management** | **Flutter Riverpod** | Reactive, compile-safe application state |
| **Audio Engine** | **`just_audio` + `audio_service`** | Low-latency audio decoding and background lock-screen notifications |
| **Local Database** | **`sqflite` + `path_provider`** | Offline-first track, playlist, and scan folder persistence |
| **Background Scanning** | **Dart Background Isolates** | Zero UI thread stuttering during ID3 tag extraction and SHA-256 hashing |
| **Metadata & Color** | **`audiotags` + `palette_generator`** | Offline USLT frame parsing and dynamic color scheme extraction |
| **Design System** | **Spotify Dark** | Pure dark theme (`#121212`, `#181818`, Green `#1DB954`) |

---

## 📁 Directory Structure

```
lib/
├── core/
│   ├── audio/            # Lyrics extraction & audio service binding
│   ├── database/         # SQLite helper (DbHelper), migrations, & CRUD
│   └── models/           # Track, ScanFolder, Playlist models
├── features/
│   ├── player/           # Riverpod player state, queue management, controls
│   ├── scanner/          # Background Dart isolate file scanner & notifier
│   └── ui/
│       ├── screens/      # Home, Search, Library, Manage Folders screens
│       ├── theme/        # Spotify dark design system color definitions
│       └── widgets/      # Persistent MiniPlayer, ExpandedPlayerModal
└── main.dart             # Application entry point & Riverpod Scope Initialization
```

---

## 📦 Getting Started

### Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (`>=3.0.0`)
- Android SDK (Targeting API level 24+)
- An Android Device or Emulator

### Installation & Local Setup

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/SpotLocal.git
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
   flutter build apk --release
   ```
   The APK will be generated at `build/app/outputs/flutter-apk/app-release.apk`.

---

## 🤝 Contributing

Contributions, bug reports, and feature requests are welcome!
Please check our [Contributing Guidelines](.github/CONTRIBUTING.md) before submitting a Pull Request.

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
