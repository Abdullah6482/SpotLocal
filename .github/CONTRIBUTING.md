# Contributing to SpotLocal

Thank you for taking the time to contribute to **SpotLocal**! We welcome bug reports, feature suggestions, and code contributions.

## Core Rules & Non-Negotiable Constraints

When contributing code to SpotLocal, please adhere to these strict architectural rules:

1. **Never use Android MediaStore:** All audio scanning MUST operate strictly on directories stored in SQLite `scan_folders`.
2. **Never execute I/O on the UI thread:** File system traversal, ID3 tag parsing, and file hashing MUST run inside background Dart Isolates.
3. **No audio re-encoding:** Stream raw audio bytes directly to the hardware decoder via `just_audio`.
4. **Offline First:** Zero external network calls. Everything must cache locally to SQLite (`sqflite`).
5. **Spotify Dark Design System:** Maintain dark theme branding (`#121212`, `#181818`, Green `#1DB954`).

## Development Workflow

1. **Fork & Clone** the repository.
2. **Create a Feature Branch:**
   ```bash
   git checkout -b feature/my-new-feature
   ```
3. **Run Code Analyzer & Formatting:**
   ```bash
   flutter format .
   flutter analyze
   ```
4. **Commit & Push:**
   Write clear, descriptive commit messages.
5. **Submit a Pull Request:**
   Fill out the [Pull Request Template](PULL_REQUEST_TEMPLATE.md) completely.
