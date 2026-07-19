import 'package:flutter/material.dart';

import '../l10n/mood_labels.dart';
import '../l10n/strings.dart';
import '../models/mood.dart';
import '../models/mood_entry.dart';
import '../services/mood_service.dart';
import '../theme/app_theme.dart';

class MoodCheckInCard extends StatefulWidget {
  const MoodCheckInCard({
    super.key,
    required this.coupleId,
    required this.uid,
    required this.currentMood,
    this.moodService,
  });

  final String coupleId;
  final String uid;
  final MoodEntry? currentMood;
  final MoodService? moodService;

  @override
  State<MoodCheckInCard> createState() => _MoodCheckInCardState();
}

class _MoodCheckInCardState extends State<MoodCheckInCard> {
  Mood? _selected;
  late final TextEditingController _noteController;
  bool _saving = false;
  late final MoodService _service = widget.moodService ?? MoodService();

  @override
  void initState() {
    super.initState();
    _selected = widget.currentMood?.mood;
    _noteController = TextEditingController(
      text: widget.currentMood?.note ?? '',
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.checkIn(
        coupleId: widget.coupleId,
        uid: widget.uid,
        mood: _selected!,
        note: _noteController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.moodSaved)),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.moodSaveError)),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              AppStrings.checkInTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.checkInSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final mood in Mood.values)
                  ChoiceChip(
                    label: Text('${mood.emoji} ${moodLabel(mood)}'),
                    selected: _selected == mood,
                    onSelected: (_) => setState(() => _selected = mood),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _noteController,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: AppStrings.checkInNoteHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: (_selected == null || _saving) ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(AppStrings.saveMood),
            ),
          ],
        ),
      ),
    );
  }
}
