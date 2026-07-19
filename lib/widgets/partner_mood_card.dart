import 'package:flutter/material.dart';

import '../l10n/mood_labels.dart';
import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/mood_entry.dart';
import '../theme/app_theme.dart';

class PartnerMoodCard extends StatelessWidget {
  const PartnerMoodCard({
    super.key,
    required this.partner,
    required this.partnerMood,
  });

  final AppUser? partner;
  final MoodEntry? partnerMood;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (partner == null) {
      return Card(
        color: colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            AppStrings.partnerWaitingToJoin,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      );
    }

    final name =
        partner!.displayName.trim().isEmpty ? 'Partner' : partner!.displayName;

    if (partnerMood == null) {
      return Card(
        color: colorScheme.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Text(
            '$name ${AppStrings.partnerNoMoodSuffix}',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      );
    }

    final mood = partnerMood!;
    final note = mood.note.trim();

    return Card(
      color: colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  mood.mood.emoji,
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    '$name ${AppStrings.partnerMoodPrefix} '
                    '${moodLabel(mood.mood).toLowerCase()}',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colorScheme.onSecondaryContainer,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            if (note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                note,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSecondaryContainer.withValues(
                    alpha: 0.75,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
