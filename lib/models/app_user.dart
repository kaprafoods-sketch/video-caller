class AppUser {
  final String uid;
  final String displayName;
  final String? photoUrl;
  final List<String> genrePreferences;
  final String? coupleId;

  const AppUser({
    required this.uid,
    required this.displayName,
    this.photoUrl,
    this.genrePreferences = const [],
    this.coupleId,
  });

  factory AppUser.fromMap(String uid, Map<String, dynamic> map) {
    return AppUser(
      uid: uid,
      displayName: map['displayName'] as String? ?? '',
      photoUrl: map['photoUrl'] as String?,
      genrePreferences: map['genrePreferences'] != null
          ? List<String>.from(map['genrePreferences'] as List)
          : const [],
      coupleId: map['coupleId'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'displayName': displayName,
      'photoUrl': photoUrl,
      'genrePreferences': genrePreferences,
      'coupleId': coupleId,
    };
  }

  bool get isPaired => coupleId != null;
}
