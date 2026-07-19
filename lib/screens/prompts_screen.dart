import 'package:flutter/material.dart';

import '../l10n/prompt_data.dart';
import '../l10n/strings.dart';
import '../models/app_user.dart';
import '../models/prompt.dart';
import '../models/prompt_type.dart';
import '../services/prompt_service.dart';
import '../theme/app_theme.dart';

/// Prompts & confessions: seal an answer or confession, then reveal together
/// once your partner has shared too.
class PromptsScreen extends StatefulWidget {
  const PromptsScreen({super.key, required this.user, this.promptService});

  final AppUser user;
  final PromptService? promptService;

  @override
  State<PromptsScreen> createState() => _PromptsScreenState();
}

class _PromptsScreenState extends State<PromptsScreen> {
  late final PromptService _service = widget.promptService ?? PromptService();
  final TextEditingController _controller = TextEditingController();

  PromptType _type = PromptType.question;
  PromptQuestion _question = kPromptQuestions.first;
  bool _sealing = false;

  String get _coupleId => widget.user.coupleId!;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _seal() async {
    final content = _controller.text.trim();
    if (content.isEmpty) return;

    setState(() => _sealing = true);
    try {
      if (_type == PromptType.question) {
        await _service.answerQuestion(
          coupleId: _coupleId,
          uid: widget.user.uid,
          questionId: _question.id,
          content: content,
        );
      } else {
        await _service.confess(
          coupleId: _coupleId,
          uid: widget.user.uid,
          content: content,
        );
      }
      if (!mounted) return;
      _controller.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text(AppStrings.promptSealed)),
      );
    } on PromptException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } finally {
      if (mounted) setState(() => _sealing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text(AppStrings.promptsTitle)),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                0,
              ),
              child: _buildComposer(theme),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _buildFeed(theme)),
          ],
        ),
      ),
    );
  }

  Widget _buildComposer(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            SegmentedButton<PromptType>(
              segments: const [
                ButtonSegment(
                  value: PromptType.question,
                  label: Text(AppStrings.promptTypeQuestion),
                  icon: Icon(Icons.help_outline),
                ),
                ButtonSegment(
                  value: PromptType.confession,
                  label: Text(AppStrings.promptTypeConfession),
                  icon: Icon(Icons.lock_outline),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (s) => setState(() => _type = s.first),
            ),
            const SizedBox(height: AppSpacing.md),
            if (_type == PromptType.question)
              DropdownButtonFormField<PromptQuestion>(
                value: _question,
                isExpanded: true,
                decoration: const InputDecoration(
                  labelText: AppStrings.pickQuestion,
                ),
                items: [
                  for (final q in kPromptQuestions)
                    DropdownMenuItem(value: q, child: Text(q.text)),
                ],
                onChanged: (q) =>
                    setState(() => _question = q ?? kPromptQuestions.first),
              ),
            if (_type == PromptType.question)
              const SizedBox(height: AppSpacing.md),
            TextField(
              controller: _controller,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: _type == PromptType.question
                    ? AppStrings.yourAnswerHint
                    : AppStrings.yourConfessionHint,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _sealing ? null : _seal,
              child: _sealing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(_type == PromptType.question
                      ? AppStrings.sealAnswer
                      : AppStrings.sealConfession),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              AppStrings.promptsDisclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeed(ThemeData theme) {
    return StreamBuilder<List<Prompt>>(
      stream: _service.watchVisiblePrompts(
        coupleId: _coupleId,
        myUid: widget.user.uid,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final prompts = snap.data ?? const [];
        if (prompts.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Text(
                AppStrings.promptsEmpty,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            0,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          itemCount: prompts.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) => _PromptTile(
            prompt: prompts[i],
            myUid: widget.user.uid,
          ),
        );
      },
    );
  }
}

class _PromptTile extends StatelessWidget {
  const _PromptTile({required this.prompt, required this.myUid});

  final Prompt prompt;
  final String myUid;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mine = prompt.authorUid == myUid;
    final sealed = !prompt.isUnlocked;

    final question = prompt.type == PromptType.question
        ? promptQuestionById(prompt.pairKey)
        : null;

    return Card(
      margin: EdgeInsets.zero,
      color: sealed
          ? colorScheme.surfaceContainerHighest
          : colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  sealed
                      ? Icons.lock_outline
                      : (prompt.type == PromptType.question
                          ? Icons.help_outline
                          : Icons.favorite_outline),
                  size: 18,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    sealed
                        ? AppStrings.promptSealedWaiting
                        : (mine
                            ? AppStrings.promptFromYou
                            : AppStrings.promptFromPartner),
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                if (!sealed)
                  Text(
                    AppStrings.promptRevealedTogether,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
            if (question != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                question.text,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.xs),
            // Sealed prompts are always the viewer's own (rules never return a
            // partner's sealed doc), so showing content here is safe.
            Text(prompt.content, style: theme.textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
