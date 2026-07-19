/// A shared question two partners can each answer. Content is a localizable
/// catalog (like movie or mood data), kept out of AppStrings so the list can
/// grow without churning the UI-chrome strings.
class PromptQuestion {
  final String id;
  final String text;

  const PromptQuestion(this.id, this.text);
}

/// The built-in question deck. [id] is stable and used as the pair key, so
/// renaming [text] never breaks previously sealed answers.
const List<PromptQuestion> kPromptQuestions = [
  PromptQuestion('q_first_impression', 'What was your first impression of me?'),
  PromptQuestion('q_feel_loved', 'When do you feel most loved by me?'),
  PromptQuestion('q_proud', 'What is something I did that made you proud?'),
  PromptQuestion('q_miss_most', 'What do you miss most when we are apart?'),
  PromptQuestion('q_small_thing', 'What small thing of mine makes you smile?'),
  PromptQuestion('q_adventure', 'Where in the world should we go together next?'),
  PromptQuestion('q_learned', 'What have you learned about love from us?'),
  PromptQuestion('q_grateful', 'What are you most grateful for about us right now?'),
  PromptQuestion('q_future', 'What are you looking forward to in our future?'),
  PromptQuestion('q_support', 'How can I support you better this week?'),
];

PromptQuestion? promptQuestionById(String id) {
  for (final q in kPromptQuestions) {
    if (q.id == id) return q;
  }
  return null;
}
