import 'dart:io';
import 'package:path/path.dart' as p;

class AudioFileValidator {
  static const Set<String> supportedExtensions = {
    '.mp3',
    '.flac',
    '.m4a',
    '.wav',
    '.aac',
    '.ogg',
  };

  /// Checks if file extension is a supported audio type.
  static bool hasSupportedExtension(String filePath) {
    final ext = p.extension(filePath).toLowerCase();
    return supportedExtensions.contains(ext);
  }

  /// Validates that an audio file exists, is non-empty, and has an allowed audio extension.
  static bool isValidAudioFile(File file) {
    if (!hasSupportedExtension(file.path)) return false;
    try {
      final length = file.lengthSync();
      return length > 0;
    } catch (_) {
      return false;
    }
  }

  /// Sanitizes and extracts a fallback song title from the file basename
  /// when ID3 metadata tags are corrupted or absent.
  static String deriveFallbackTitle(String filePath) {
    String name = p.basenameWithoutExtension(filePath);

    // Strip leading track number prefixes like "01 - " or "1. "
    final trackPrefixRegex = RegExp(r'^\d+[\s\-_\.]+');
    name = name.replaceFirst(trackPrefixRegex, '');

    // Replace underscores with spaces and trim
    name = name.replaceAll('_', ' ').trim();

    return name.isNotEmpty ? name : 'Unknown Title';
  }
}
