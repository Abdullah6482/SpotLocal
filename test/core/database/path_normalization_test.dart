import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/core/database/db_helper.dart';

void main() {
  group('Folder Path Normalization Tests', () {
    test('normalizes standard Android emulated path', () {
      const raw = '/storage/emulated/0/Music/';
      final normalized = normalizeFolderPath(raw);
      expect(normalized, '/storage/emulated/0/Music');
    });

    test('normalizes SAF URI with primary: prefix', () {
      const raw = 'content://com.android.externalstorage.documents/tree/primary:Music%2FRock';
      final normalized = normalizeFolderPath(raw);
      expect(normalized, '/storage/emulated/0/Music/Rock');
    });

    test('normalizes SAF URI with url-encoded primary%3A prefix', () {
      const raw = 'content://com.android.externalstorage.documents/tree/primary%3ASongs';
      final normalized = normalizeFolderPath(raw);
      expect(normalized, '/storage/emulated/0/Songs');
    });

    test('strips trailing slashes cleanly', () {
      const raw = '/storage/emulated/0/Audio///';
      final normalized = normalizeFolderPath(raw);
      expect(normalized.endsWith('/'), isFalse);
    });
  });
}
