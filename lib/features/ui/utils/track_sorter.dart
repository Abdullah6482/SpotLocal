import '../../../core/models/track.dart';
import '../models/track_sort_option.dart';

class TrackSorter {
  /// Returns a new sorted list of tracks according to the chosen [TrackSortOption].
  static List<Track> sort(List<Track> tracks, TrackSortOption option) {
    final list = List<Track>.from(tracks);

    switch (option) {
      case TrackSortOption.titleAsc:
        list.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
        break;
      case TrackSortOption.titleDesc:
        list.sort((a, b) => b.title.toLowerCase().compareTo(a.title.toLowerCase()));
        break;
      case TrackSortOption.artistAsc:
        list.sort((a, b) {
          final artistA = (a.artist ?? '').toLowerCase();
          final artistB = (b.artist ?? '').toLowerCase();
          final comp = artistA.compareTo(artistB);
          return comp != 0 ? comp : a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
      case TrackSortOption.artistDesc:
        list.sort((a, b) {
          final artistA = (a.artist ?? '').toLowerCase();
          final artistB = (b.artist ?? '').toLowerCase();
          final comp = artistB.compareTo(artistA);
          return comp != 0 ? comp : b.title.toLowerCase().compareTo(a.title.toLowerCase());
        });
        break;
      case TrackSortOption.albumAsc:
        list.sort((a, b) {
          final albumA = (a.album ?? '').toLowerCase();
          final albumB = (b.album ?? '').toLowerCase();
          final comp = albumA.compareTo(albumB);
          if (comp != 0) return comp;
          final trackNumComp = (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
          return trackNumComp != 0 ? trackNumComp : a.title.toLowerCase().compareTo(b.title.toLowerCase());
        });
        break;
      case TrackSortOption.durationAsc:
        list.sort((a, b) => a.durationMs.compareTo(b.durationMs));
        break;
      case TrackSortOption.durationDesc:
        list.sort((a, b) => b.durationMs.compareTo(a.durationMs));
        break;
      case TrackSortOption.dateAddedDesc:
        list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
        break;
      case TrackSortOption.dateAddedAsc:
        list.sort((a, b) => a.dateAdded.compareTo(b.dateAdded));
        break;
    }

    return list;
  }
}
