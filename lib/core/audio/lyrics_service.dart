import 'package:audiotags/audiotags.dart';

class LyricsService {
  /// Extracts embedded unsynchronized ID3 lyrics (USLT frames) from a local audio file.
  static Future<String?> extractLyrics(String filePath) async {
    if (filePath.isEmpty) return null;
    try {
      final tag = await AudioTags.read(filePath);
      if (tag != null && tag.lyrics != null && tag.lyrics!.trim().isNotEmpty) {
        return tag.lyrics!.trim();
      }
    } catch (_) {
      // Return null on parsing errors or unsupported formats
    }
    return null;
  }
}

