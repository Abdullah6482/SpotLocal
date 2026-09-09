import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/core/models/scan_folder.dart';

void main() {
  group('ScanFolder Model Tests', () {
    final now = DateTime(2026, 9, 2, 10, 30, 0);

    test('should serialize ScanFolder to Map correctly', () {
      final folder = ScanFolder(
        id: 5,
        path: '/storage/emulated/0/Music/Favorites',
        createdAt: now,
        isEnabled: true,
      );

      final map = folder.toMap();

      expect(map['id'], 5);
      expect(map['path'], '/storage/emulated/0/Music/Favorites');
      expect(map['created_at'], now.millisecondsSinceEpoch);
      expect(map['is_enabled'], 1);
    });

    test('should deserialize ScanFolder from Map correctly', () {
      final map = {
        'id': 10,
        'path': '/storage/emulated/0/Download',
        'created_at': now.millisecondsSinceEpoch,
        'is_enabled': 0,
      };

      final folder = ScanFolder.fromMap(map);

      expect(folder.id, 10);
      expect(folder.path, '/storage/emulated/0/Download');
      expect(folder.createdAt, now);
      expect(folder.isEnabled, isFalse);
    });

    test('copyWith updates specified fields', () {
      final folder = ScanFolder(
        id: 1,
        path: '/storage/emulated/0/Podcasts',
        createdAt: now,
        isEnabled: true,
      );

      final disabled = folder.copyWith(isEnabled: false);

      expect(disabled.isEnabled, isFalse);
      expect(disabled.path, folder.path);
      expect(disabled.id, folder.id);
    });
  });
}
