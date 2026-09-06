import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:notes_app/core/theme/tokens/app_radii.dart';
import 'package:notes_app/core/theme/tokens/note_swatches.dart';
import 'package:notes_app/core/widgets/paper_stage.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';
import 'package:notes_app/features/auth/presentation/otp_boxes.dart';

const Color _ink = Color(0xFF2B261F);

/// Port of `features/auth/AuthScreen.tsx` — email + OTP login
/// (feature-audit #2). See `session_controller.dart`'s doc comment for how
/// the OTP itself is generated and delivered without a real backend.
class const AuthScreen({super.key}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends ConsumerState<AuthScreen> {
  final _emailController = TextEditingController();
  String _otp = '';
  bool _sent = false;
  bool _busy = false;
  String? _error;

  /// The code `sendOtp` generated, shown directly in the sheet — see
  /// `session_controller.dart`'s doc comment on why this replaces the
  /// source's "check your terminal" hint.
  String? _shownCode;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendCode() {
    setState(() {
      _busy = true;
      _error = null;
    });
    final outcome = ref
        .read(sessionControllerProvider.notifier)
        .sendOtp(_emailController.text);
    setState(() {
      _busy = false;
      if (!outcome.result.ok) {
        _error = outcome.result.error ?? 'Could not send the code';
        return;
      }
      _shownCode = outcome.code;
      _sent = true;
    });
  }

  void _verifyCode() {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = ref
        .read(sessionControllerProvider.notifier)
        .verifyOtp(_emailController.text, _otp);
    setState(() {
      _busy = false;
      if (!result.ok) _error = result.error ?? 'Could not verify the code';
      // On success, SessionController's state change drives the router's
      // redirect (app_router.dart) away from this screen — no explicit
      // navigation call needed here, matching the source's own approach of
      // conditionally rendering off session state rather than navigating.
    });
  }

  void _useAnotherEmail() {
    setState(() {
      _sent = false;
      _otp = '';
      _error = null;
      _shownCode = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final swatches = theme.extension<NoteSwatches>()!;
    final radii = theme.extension<AppRadii>()!;

    final title = _sent ? 'Enter the code' : 'Write it down';
    final description = _sent
        ? 'We sent a short code to ${_emailController.text}. '
              'It fades in 10 minutes.'
        : 'A quiet board for lists and little ideas. No password — '
              'just a code.';

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
                    _sent ? 'Almost there' : 'Your notebook',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    title,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      fontSize: 45.6,
                      height: 0.92,
                      letterSpacing: -2.28,
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
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                    decoration: BoxDecoration(
                      color: swatches.resolveHex(_sent ? '#E7A3A3' : '#C5CA8A'),
                      borderRadius: radii.heroRadius,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!_sent) ...[
                          Text(
                            'Email',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _ink.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _emailController,
                            autofocus: true,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: _ink),
                            decoration: InputDecoration(
                              hintText: 'you@email.com',
                              hintStyle: TextStyle(
                                color: _ink.withValues(alpha: 0.4),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.8),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(999),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ] else ...[
                          Text(
                            'Six digits',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: _ink.withValues(alpha: 0.6),
                            ),
                          ),
                          if (_shownCode != null) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text.rich(
                                TextSpan(
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: _ink,
                                  ),
                                  children: [
                                    const TextSpan(
                                      text:
                                          'There is no email backend '
                                          'yet, so here is your code: ',
                                    ),
                                    TextSpan(
                                      text: _shownCode,
                                      style: const TextStyle(
                                        fontFamily: 'monospace',
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                          const SizedBox(height: 16),
                          OtpBoxes(
                            value: _otp,
                            onChange: (value) => setState(() => _otp = value),
                          ),
                        ],
                        if (_error != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            _error!,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF7A2418),
                            ),
                          ),
                        ],
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: FilledButton(
                            onPressed: _busy || (_sent && _otp.length != 6)
                                ? null
                                : (_sent ? _verifyCode : _sendCode),
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1814),
                              shape: const StadiumBorder(),
                            ),
                            child: Text(
                              _busy
                                  ? 'One moment…'
                                  : _sent
                                  ? 'Open my board'
                                  : 'Send me a code',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  if (_sent)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: _TextLink(
                            label: 'Use another email',
                            onPressed: _busy ? null : _useAnotherEmail,
                          ),
                        ),
                        _TextLink(
                          label: 'Send again',
                          onPressed: _busy ? null : _sendCode,
                        ),
                      ],
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        'We’ll keep this board just for you.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurface.withValues(
                            alpha: 0.55,
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

/// A compact text-button link — the default [TextButton] padding/text
/// size made "Use another email" and "Send again" wide enough to overflow
/// this narrow a row on real screen widths, a genuine layout bug caught by
/// `auth_screen_test.dart` (not just a test-viewport artifact).
class const _TextLink({
  required final String label,
  required final VoidCallback? onPressed,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.zero,
        minimumSize: const Size(0, 36),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: Text(
        label,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
    );
  }
}
