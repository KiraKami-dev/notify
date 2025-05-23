class UserProfile {
  final String userId;
  final String? avatarUrl;
  final String? mood;
  final DateTime lastUpdated;

  UserProfile({
    required this.userId,
    this.avatarUrl,
    this.mood,
    required this.lastUpdated,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'avatarUrl': avatarUrl,
      'mood': mood,
      'lastUpdated': lastUpdated,
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      userId: map['userId'] as String,
      avatarUrl: map['avatarUrl'] as String?,
      mood: map['mood'] as String?,
      lastUpdated: (map['lastUpdated'] as dynamic).toDate(),
    );
  }

  UserProfile copyWith({
    String? avatarUrl,
    String? mood,
  }) {
    return UserProfile(
      userId: userId,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      mood: mood ?? this.mood,
      lastUpdated: DateTime.now(),
    );
  }
} 