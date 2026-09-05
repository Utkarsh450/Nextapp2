import 'package:flutter/material.dart';
import 'package:notes_app/core/theme/tokens/app_spacing.dart';

/// Port of `components/ui/EmptyState.tsx` — one large emoji glyph, muted
/// title text, and an optional primary pill action. Reused across every
/// data-driven screen's empty state (per the code-quality requirement to
/// extract shared layout into `core/widgets` instead of duplicating it).
class const EmptyStateView({
  required final String glyph,
  required final String title,
  final String? actionLabel,
  final VoidCallback? onAction,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final spacing = theme.extension<AppSpacing>()!;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: spacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(glyph, style: const TextStyle(fontSize: 48)),
            SizedBox(height: spacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.65),
                ),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: spacing.xl),
              SizedBox(
                height: 48,
                child: FilledButton(
                  onPressed: onAction,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                    padding: EdgeInsets.symmetric(horizontal: spacing.xl),
                  ),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
