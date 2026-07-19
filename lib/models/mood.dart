enum Mood {
  happy('😊'),
  loved('🥰'),
  calm('😌'),
  playful('😜'),
  tired('😴'),
  stressed('😣'),
  sad('😢'),
  anxious('😰');

  const Mood(this.emoji);
  final String emoji;

  static Mood? fromName(String? name) {
    for (final m in Mood.values) {
      if (m.name == name) return m;
    }
    return null;
  }
}
