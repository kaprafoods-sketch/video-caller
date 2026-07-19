import 'package:flutter/material.dart';

import '../l10n/genre_labels.dart';
import '../l10n/strings.dart';
import '../models/movie_genre.dart';
import '../services/movie_service.dart';
import '../theme/app_theme.dart';

/// Inline editor for the user's favorite genres. Edited where it's used
/// (the lobby) rather than on a separate settings screen; saves to
/// users/{uid}.genrePreferences via [MovieService].
class GenrePreferencesCard extends StatefulWidget {
  const GenrePreferencesCard({
    super.key,
    required this.uid,
    required this.initialGenres,
    this.movieService,
  });

  final String uid;
  final List<MovieGenre> initialGenres;
  final MovieService? movieService;

  @override
  State<GenrePreferencesCard> createState() => _GenrePreferencesCardState();
}

class _GenrePreferencesCardState extends State<GenrePreferencesCard> {
  late Set<MovieGenre> _selected;
  bool _saving = false;
  late final MovieService _service = widget.movieService ?? MovieService();

  @override
  void initState() {
    super.initState();
    _selected = widget.initialGenres.toSet();
  }

  bool get _dirty =>
      !const SetEquality().equals(_selected, widget.initialGenres.toSet());

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _service.updateGenrePreferences(
        uid: widget.uid,
        genres: _selected.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.genrePreferencesSaved)),
      );
    } on MovieNightException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
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
              AppStrings.genrePreferencesTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.genrePreferencesHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final genre in MovieGenre.values)
                  FilterChip(
                    label: Text(genreLabel(genre)),
                    selected: _selected.contains(genre),
                    onSelected: (on) => setState(() {
                      if (on) {
                        _selected.add(genre);
                      } else {
                        _selected.remove(genre);
                      }
                    }),
                  ),
              ],
            ),
            if (_dirty) ...[
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.tonal(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(AppStrings.saveGenres),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Minimal set equality so we avoid pulling in the `collection` package
/// (staying within the 7-dependency budget).
class SetEquality {
  const SetEquality();

  bool equals(Set<MovieGenre> a, Set<MovieGenre> b) =>
      a.length == b.length && a.containsAll(b);
}
