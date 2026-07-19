import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../models/movie_night.dart';
import '../models/movie_suggestion.dart';
import '../services/movie_service.dart';
import '../theme/app_theme.dart';

/// The movie-night experience in the lobby: fetch server-side suggestions,
/// vote on them, and reveal matches once both partners have picked.
class MovieNightCard extends StatefulWidget {
  const MovieNightCard({
    super.key,
    required this.coupleId,
    required this.uid,
    this.movieService,
  });

  final String coupleId;
  final String uid;
  final MovieService? movieService;

  @override
  State<MovieNightCard> createState() => _MovieNightCardState();
}

class _MovieNightCardState extends State<MovieNightCard> {
  late final MovieService _service = widget.movieService ?? MovieService();
  bool _suggesting = false;

  Future<void> _suggest() async {
    setState(() => _suggesting = true);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text(AppStrings.suggestingMovies)),
    );
    try {
      await _service.suggestMovies(widget.coupleId);
    } on MovieNightException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _suggesting = false);
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
              AppStrings.movieNightTitle,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              AppStrings.movieNightSubtitle,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<MovieNight?>(
              stream: _service.watchLatestMovieNight(widget.coupleId),
              builder: (context, snap) {
                final night = snap.data;
                if (night == null) {
                  return _buildEmpty(theme);
                }
                return _MovieNightRound(
                  key: ValueKey(night.id),
                  night: night,
                  uid: widget.uid,
                  service: _service,
                  coupleId: widget.coupleId,
                  onSuggestAnother: _suggesting ? null : _suggest,
                  suggesting: _suggesting,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FilledButton.tonal(
          onPressed: _suggesting ? null : _suggest,
          child: _suggesting
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.suggestMovies),
        ),
      ],
    );
  }
}

/// A single movie-night round: shows the suggestions, lets [uid] toggle picks
/// and lock them in, then reveals matches once both partners have voted.
class _MovieNightRound extends StatefulWidget {
  const _MovieNightRound({
    super.key,
    required this.night,
    required this.uid,
    required this.service,
    required this.coupleId,
    required this.onSuggestAnother,
    required this.suggesting,
  });

  final MovieNight night;
  final String uid;
  final MovieService service;
  final String coupleId;
  final VoidCallback? onSuggestAnother;
  final bool suggesting;

  @override
  State<_MovieNightRound> createState() => _MovieNightRoundState();
}

class _MovieNightRoundState extends State<_MovieNightRound> {
  late Set<int> _picks;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _picks = widget.night.votesFor(widget.uid).toSet();
  }

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await widget.service.vote(
        coupleId: widget.coupleId,
        movieNightId: widget.night.id,
        uid: widget.uid,
        tmdbIds: _picks.toList(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.votesSaved)),
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
    final night = widget.night;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (night.bothVoted) _buildMatches(theme, night.matches),
        Text(
          AppStrings.voteHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final movie in night.suggestions)
          _MovieTile(
            movie: movie,
            selected: _picks.contains(movie.tmdbId),
            onTap: () => setState(() {
              if (!_picks.add(movie.tmdbId)) _picks.remove(movie.tmdbId);
            }),
          ),
        const SizedBox(height: AppSpacing.md),
        FilledButton(
          onPressed: _saving ? null : _submit,
          child: _saving
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text(AppStrings.submitVotes),
        ),
        if (widget.night.hasVoted(widget.uid) && !night.bothVoted) ...[
          const SizedBox(height: AppSpacing.sm),
          Text(
            AppStrings.waitingForPartnerVotes,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.sm),
        TextButton(
          onPressed: widget.onSuggestAnother,
          child: const Text(AppStrings.suggestMovies),
        ),
      ],
    );
  }

  Widget _buildMatches(ThemeData theme, List<MovieSuggestion> matches) {
    final colorScheme = theme.colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            matches.isEmpty ? AppStrings.noMatchesYet : AppStrings.itsAMatch,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
          ),
          if (matches.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              matches.map((m) => m.title).join(' · '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MovieTile extends StatelessWidget {
  const _MovieTile({
    required this.movie,
    required this.selected,
    required this.onTap,
  });

  final MovieSuggestion movie;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: selected
            ? colorScheme.secondaryContainer
            : colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: _buildPoster(colorScheme),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        movie.releaseYear == null
                            ? movie.title
                            : '${movie.title} (${movie.releaseYear})',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        movie.overview,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: selected
                      ? colorScheme.primary
                      : colorScheme.outlineVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster(ColorScheme colorScheme) {
    const width = 60.0;
    const height = 90.0;
    final url = movie.posterUrl;
    if (url == null) {
      return Container(
        width: width,
        height: height,
        color: colorScheme.surfaceContainerHigh,
        child: Icon(Icons.movie_outlined, color: colorScheme.outline),
      );
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: colorScheme.surfaceContainerHigh,
        child: Icon(Icons.movie_outlined, color: colorScheme.outline),
      ),
    );
  }
}
