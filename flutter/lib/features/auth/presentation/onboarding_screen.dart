import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/core/theme/paper_palette.dart';
import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:notes_app/core/theme/theme_controller.dart';
import 'package:notes_app/core/widgets/paper_stage.dart';
import 'package:notes_app/features/account/domain/profile_controller.dart';
import 'package:notes_app/features/account/domain/user_profile.dart';
import 'package:notes_app/features/auth/domain/onboarding_controller.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';

const Color _ink = Color(0xFF2B261F);

/// Port of `features/auth/OnboardingScreen.tsx` — name entry then paper
/// skin picker (feature-audit #3, #4). Both steps are skippable, matching
/// the source; finishing either way marks the current session's email as
/// onboarded, which drives the router away from here (see
/// `app_router.dart`'s redirect).
class const OnboardingScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  late final TextEditingController _nameController;
  int _step = 0;

  String get _email => ref.read(sessionControllerProvider)!.email;

  @override
  void initState() {
    super.initState();
    final fallback = profileFromEmail(_email);
    _nameController = TextEditingController(
      text: fallback.name == 'You' ? '' : fallback.name,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _finish([String? nextName]) {
    final email = _email;
    final fallback = profileFromEmail(email);
    final name = (nextName ?? _nameController.text).trim();
    final profile = sanitizeProfile(fallback, name: name.isEmpty ? null : name);
    ref.read(profileControllerProvider.notifier).save(email, profile);
    ref.read(onboardingControllerProvider.notifier).markDone(email);
    // SessionController already holds the session; marking onboarding
    // done is what flips app_router.dart's redirect away from here — no
    // explicit navigation call needed, same reasoning as auth_screen.dart.
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final skin = ref.watch(skinControllerProvider);

    final title = _step == 0 ? 'What should we call you?' : 'Pick your paper';
    final description = _step == 0
        ? 'A first name is enough. You can change it later in You.'
        : 'Classic, monsoon, or festival. The board keeps this look.';

    return PaperStage(
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Step ${_step + 1} of 2',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 40.8,
                      height: 0.92,
                      letterSpacing: -2.04,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_step == 0)
                    _NameStep(
                      controller: _nameController,
                      onContinue: () => setState(() => _step = 1),
                    )
                  else
                    _SkinStep(skin: skin, onFinish: _finish),
                  const SizedBox(height: 16),
                  if (_step == 1)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton(
                          onPressed: () => setState(() => _step = 0),
                          child: const Text('Back'),
                        ),
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Skip for now'),
                        ),
                      ],
                    )
                  else
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        onPressed: _finish,
                        child: Text(
                          'Skip for now',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withValues(
                              alpha: 0.65,
                            ),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class const _NameStep({
  required final TextEditingController controller,
  required final VoidCallback onContinue,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(
        color: const Color(0xFFC5CA8A),
        borderRadius: BorderRadius.circular(32),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Name',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: _ink.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            autofocus: true,
            style: const TextStyle(color: _ink),
            onSubmitted: (_) => onContinue(),
            decoration: InputDecoration(
              hintText: 'Ada',
              hintStyle: TextStyle(color: _ink.withValues(alpha: 0.4)),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.8),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(999),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton(
              onPressed: onContinue,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1A1814),
                shape: const StadiumBorder(),
              ),
              child: const Text('Continue'),
            ),
          ),
        ],
      ),
    );
  }
}

class const _SkinStep({
  required final PaperSkin skin,
  required final void Function([String? nextName]) onFinish,
}) extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.85,
          children: [
            for (final item in PaperSkin.values)
              _SkinSwatch(
                skin: item,
                selected: skin == item,
                onTap: () =>
                    ref.read(skinControllerProvider.notifier).setSkin(item),
              ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 56,
          child: FilledButton(
            onPressed: onFinish,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1A1814),
              shape: const StadiumBorder(),
            ),
            child: const Text('Start writing'),
          ),
        ),
      ],
    );
  }
}

class const _SkinSwatch({
  required final PaperSkin skin,
  required final bool selected,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final palette = paperPaletteFor(skin, Brightness.light);
    final radius = BorderRadius.circular(24);
    return Material(
      color: palette.paper,
      borderRadius: radius,
      child: InkWell(
        borderRadius: radius,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: radius,
            border: Border.all(
              color: selected ? palette.ink : Colors.transparent,
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                height: 32,
                decoration: BoxDecoration(
                  color: palette.ink.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                skin.label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: palette.ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
