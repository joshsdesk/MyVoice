class ChildProfile {
  final String id;
  final String name;
  final int age;
  final String? photoPath;
  final DateTime createdAt;

  ChildProfile({
    required this.id,
    required this.name,
    required this.age,
    this.photoPath,
    required this.createdAt,
  });

  // Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'age': age,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Create from JSON
  factory ChildProfile.fromJson(Map<String, dynamic> json) {
    return ChildProfile(
      id: json['id'] as String,
      name: json['name'] as String,
      age: json['age'] as int,
      photoPath: json['photoPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Create a copy with some fields updated
  ChildProfile copyWith({
    String? id,
    String? name,
    int? age,
    String? photoPath,
    DateTime? createdAt,
  }) {
    return ChildProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      age: age ?? this.age,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
