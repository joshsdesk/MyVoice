class Word {
  final String id;
  final String wordText; // English word (e.g., "ball")
  final String? category; // Optional category (e.g., "toys", "food")
  final List<Recording> recordings; // All recordings of this word
  final DateTime createdAt;
  final DateTime updatedAt;

  Word({
    required this.id,
    required this.wordText,
    this.category,
    required this.recordings,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wordText': wordText,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Create from JSON (recordings loaded separately)
  factory Word.fromJson(Map<String, dynamic> json, List<Recording> recordings) {
    return Word(
      id: json['id'] as String,
      wordText: json['wordText'] as String,
      category: json['category'] as String?,
      recordings: recordings,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  // Create a copy with some fields updated
  Word copyWith({
    String? id,
    String? wordText,
    String? category,
    List<Recording>? recordings,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Word(
      id: id ?? this.id,
      wordText: wordText ?? this.wordText,
      category: category ?? this.category,
      recordings: recordings ?? this.recordings,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class Recording {
  final String id;
  final String wordId; // Which word this recording belongs to
  final String filePath; // Path to audio file
  final DateTime recordedAt;
  final String? notes; // Optional notes from parent

  Recording({
    required this.id,
    required this.wordId,
    required this.filePath,
    required this.recordedAt,
    this.notes,
  });

  // Convert to JSON for database storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wordId': wordId,
      'filePath': filePath,
      'recordedAt': recordedAt.toIso8601String(),
      'notes': notes,
    };
  }

  // Create from JSON
  factory Recording.fromJson(Map<String, dynamic> json) {
    return Recording(
      id: json['id'] as String,
      wordId: json['wordId'] as String,
      filePath: json['filePath'] as String,
      recordedAt: DateTime.parse(json['recordedAt'] as String),
      notes: json['notes'] as String?,
    );
  }

  // Create a copy with some fields updated
  Recording copyWith({
    String? id,
    String? wordId,
    String? filePath,
    DateTime? recordedAt,
    String? notes,
  }) {
    return Recording(
      id: id ?? this.id,
      wordId: wordId ?? this.wordId,
      filePath: filePath ?? this.filePath,
      recordedAt: recordedAt ?? this.recordedAt,
      notes: notes ?? this.notes,
    );
  }
}
