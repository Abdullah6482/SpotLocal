import 'package:flutter_test/flutter_test.dart';
import 'package:spotlocal/core/models/track.dart';
import 'package:spotlocal/features/ui/models/track_sort_option.dart';
import 'package:spotlocal/features/ui/utils/track_sorter.dart';

void main() {
  group('TrackSorter Tests', () {
    final track1 = Track(
      id: 1,
      title: 'Zebra',
      artist: 'Coldplay',
      durationMs: 300000,
      filePath: '/path/1.mp3',
      folderPath: '/path',
      fileHash: 'h1',
      dateAdded: DateTime(2026, 9, 1),
    );

    final track2 = Track(
      id: 2,
      title: 'Apple',
      artist: 'Adele',
      durationMs: 150000,
      filePath: '/path/2.mp3',
      folderPath: '/path',
      fileHash: 'h2',
      dateAdded: DateTime(2026, 9, 5),
    );

    final track3 = Track(
      id: 3,
      title: 'Banana',
      artist: 'Bruno Mars',
      durationMs: 200000,
      filePath: '/path/3.mp3',
      folderPath: '/path',
      fileHash: 'h3',
      dateAdded: DateTime(2026, 9, 3),
    );

    final tracks = [track1, track2, track3];

    test('sorts by title ascending', () {
      final sorted = TrackSorter.sort(tracks, TrackSortOption.titleAsc);
      expect(sorted.map((t) => t.title).toList(), ['Apple', 'Banana', 'Zebra']);
    });

    test('sorts by title descending', () {
      final sorted = TrackSorter.sort(tracks, TrackSortOption.titleDesc);
      expect(sorted.map((t) => t.title).toList(), ['Zebra', 'Banana', 'Apple']);
    });

    test('sorts by duration ascending', () {
      final sorted = TrackSorter.sort(tracks, TrackSortOption.durationAsc);
      expect(sorted.first.title, 'Apple');
      expect(sorted.last.title, 'Zebra');
    });

    test('sorts by date added descending (recently added first)', () {
      final sorted = TrackSorter.sort(tracks, TrackSortOption.dateAddedDesc);
      expect(sorted.first.title, 'Apple'); // Sep 5
      expect(sorted[1].title, 'Banana');    // Sep 3
      expect(sorted.last.title, 'Zebra');   // Sep 1
    });
  });
}
