import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/core/database/recently_played_dao.dart';

void main() {
  group('RecentlyPlayedDao Constants & Configuration', () {
    test('tableName is properly defined', () {
      expect(RecentlyPlayedDao.tableName, 'recently_played');
    });

    test('maxHistoryLimit is bounded to reasonable value', () {
      expect(RecentlyPlayedDao.maxHistoryLimit, 50);
    });
  });
}
