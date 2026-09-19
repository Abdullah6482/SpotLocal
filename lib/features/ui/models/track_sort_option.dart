enum TrackSortOption {
  titleAsc,
  titleDesc,
  artistAsc,
  artistDesc,
  albumAsc,
  durationAsc,
  durationDesc,
  dateAddedDesc,
  dateAddedAsc,
}

extension TrackSortOptionExtension on TrackSortOption {
  String get label {
    switch (this) {
      case TrackSortOption.titleAsc:
        return 'Title (A-Z)';
      case TrackSortOption.titleDesc:
        return 'Title (Z-A)';
      case TrackSortOption.artistAsc:
        return 'Artist (A-Z)';
      case TrackSortOption.artistDesc:
        return 'Artist (Z-A)';
      case TrackSortOption.albumAsc:
        return 'Album';
      case TrackSortOption.durationAsc:
        return 'Shortest First';
      case TrackSortOption.durationDesc:
        return 'Longest First';
      case TrackSortOption.dateAddedDesc:
        return 'Recently Added';
      case TrackSortOption.dateAddedAsc:
        return 'Oldest Added';
    }
  }
}
