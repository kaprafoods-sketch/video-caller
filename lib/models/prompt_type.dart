/// The kind of sealed prompt a partner can write.
enum PromptType {
  /// An answer to a shared question; pairs on the question's id.
  question,

  /// A free-form confession; all confessions share one pair key so any two
  /// (one per partner) unlock together, oldest-first.
  confession;

  static PromptType fromName(String? name) {
    for (final t in PromptType.values) {
      if (t.name == name) return t;
    }
    return PromptType.confession;
  }
}

/// The pair key confessions share (questions use their own id instead).
const String kConfessionPairKey = 'confession';
