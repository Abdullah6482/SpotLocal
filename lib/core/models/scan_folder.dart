class ScanFolder {
  final int? id;
  final String path;
  final DateTime createdAt;
  final bool isEnabled;

  const ScanFolder({
    this.id,
    required this.path,
    required this.createdAt,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'path': path,
      'created_at': createdAt.millisecondsSinceEpoch,
      'is_enabled': isEnabled ? 1 : 0,
    };
  }

  factory ScanFolder.fromMap(Map<String, dynamic> map) {
    return ScanFolder(
      id: map['id'] as int?,
      path: map['path'] as String,
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
      isEnabled: (map['is_enabled'] as int) == 1,
    );
  }

  ScanFolder copyWith({
    int? id,
    String? path,
    DateTime? createdAt,
    bool? isEnabled,
  }) {
    return ScanFolder(
      id: id ?? this.id,
      path: path ?? this.path,
      createdAt: createdAt ?? this.createdAt,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScanFolder &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          path == other.path &&
          createdAt == other.createdAt &&
          isEnabled == other.isEnabled;

  @override
  int get hashCode =>
      id.hashCode ^ path.hashCode ^ createdAt.hashCode ^ isEnabled.hashCode;
}

