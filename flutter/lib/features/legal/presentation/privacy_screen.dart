import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Port of `app/privacy/page.tsx` — a static privacy policy page
/// (feature-audit #15).
class const PrivacyScreen({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurface.withValues(alpha: 0.65);
    final body = theme.textTheme.bodyLarge?.copyWith(height: 1.6);

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
          children: [
            Text(
              'NOTES',
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 2.3,
                color: muted,
              ),
            ),
            const SizedBox(height: 12),
            Text('Privacy policy', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(
              'Last updated 2 September 2026',
              style: theme.textTheme.bodyMedium?.copyWith(color: muted),
            ),
            const SizedBox(height: 20),
            Text(
              'Notes is a personal notebook. Notes, notebooks, templates, '
              'and attachments stay on your device, isolated to the email '
              'you sign in with.',
              style: body,
            ),
            const SizedBox(height: 14),
            Text(
              'We use your email only to send a one-time sign-in code. We '
              'do not operate a public feed, do not sell data, and do not '
              'require contacts, location, or advertising identifiers.',
              style: body,
            ),
            const SizedBox(height: 14),
            Text(
              'If you allow notifications on the Android app, Notes '
              'schedules a local lock-screen alert for dates and times you '
              'set on your own notes. Alerts stay on the device. We do not '
              'send push notifications from a server.',
              style: body,
            ),
            const SizedBox(height: 14),
            Text(
              'You can export or delete your notes from the You tab. '
              'Signing out does not upload your notes.',
              style: body,
            ),
            const SizedBox(height: 28),
            TextButton(
              onPressed: () => context.pop(),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              child: const Text('Back to Notes'),
            ),
          ],
        ),
      ),
    );
  }
}
