import 'dart:math';

import 'package:notes_app/features/auth/domain/auth_user.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'session_controller.g.dart';

/// The signed-in session — matches `AuthSession` (`lib/auth/index.ts`).
class const AuthSession({
  required final String email,
  required final String name,
  required final String handle,
});

class const SendOtpResult({required final bool ok, final String? error});

class const VerifyOtpResult({
  required final bool ok,
  final String? error,
  final AuthSession? session,
});

/// One pending code — matches the dev/no-Apps-Script-configured branch of
/// `lib/auth/otp.ts`'s `sendEmailOtp`/`verifyEmailOtp` (10-minute expiry,
/// 5-try limit). The source hashes the code server-side, since its memory
/// store could in principle be inspected by something other than the
/// legitimate client; that threat model doesn't apply to state living only
/// in this device's own process, so the code is kept as plain text here —
/// simpler, with no real security given up.
class _PendingOtp {
  // `tries` is mutated after construction (see `verifyOtp`), so it can't
  // be a `final` declaring parameter — Dart's primary-constructor sugar
  // only turns `final` parameters into fields.
  // ignore: unnecessary_type_name_in_constructor
  _PendingOtp({required this.code, required this.expiresAtMs});

  final String code;
  final int expiresAtMs;
  int tries = 0;
}

/// Direct port of `hooks/useSession.ts`'s `sendOtp`/`verifyOtp`/`logout`,
/// minus the network calls — there's no Apps Script backend in this build
/// (per the "no backend/DB for now" instruction), so this always takes the
/// source's own dev-only fallback path (`lib/auth/otp.ts`, no
/// `APPS_SCRIPT_URL` configured) rather than actually sending an email.
///
/// **Deliberate deviation:** that fallback path normally prints the code
/// to the *server's* terminal (`console.info('[notes otp] …')`) for a
/// developer to read — there is no terminal a phone's end user can see, so
/// `sendOtp`'s result carries the generated code directly, and
/// `auth_screen.dart` shows it in the sheet instead of a "check your
/// terminal" hint. The OTP mechanism itself (expiry, try limit, wrong-code
/// error) is otherwise a faithful, real port, not a shortcut.
@riverpod
class SessionController extends _$SessionController {
  final Map<String, _PendingOtp> _pending = {};

  @override
  AuthSession? build() => null;

  /// Returns the generated code alongside the result so the UI can show
  /// it — see the class doc comment on why.
  ({SendOtpResult result, String? code}) sendOtp(String email) {
    final normalized = normalizeEmail(email);
    if (!isValidEmail(normalized)) {
      return (
        result: const SendOtpResult(
          ok: false,
          error: 'Enter a valid email address',
        ),
        code: null,
      );
    }
    final code = (100000 + Random().nextInt(900000)).toString();
    _pending[normalized] = _PendingOtp(
      code: code,
      expiresAtMs: DateTime.now().millisecondsSinceEpoch + 10 * 60 * 1000,
    );
    return (result: const SendOtpResult(ok: true), code: code);
  }

  VerifyOtpResult verifyOtp(String email, String otp) {
    final normalized = normalizeEmail(email);
    final code = otp.replaceAll(RegExp(r'\s'), '');
    if (!isValidEmail(normalized)) {
      return const VerifyOtpResult(
        ok: false,
        error: 'Enter a valid email address',
      );
    }
    if (!RegExp(r'^\d{6}$').hasMatch(code)) {
      return const VerifyOtpResult(ok: false, error: 'Enter the 6-digit code');
    }
    final record = _pending[normalized];
    if (record == null ||
        record.expiresAtMs < DateTime.now().millisecondsSinceEpoch) {
      _pending.remove(normalized);
      return const VerifyOtpResult(
        ok: false,
        error: 'Code expired. Request a new one.',
      );
    }
    if (record.tries >= 5) {
      _pending.remove(normalized);
      return const VerifyOtpResult(
        ok: false,
        error: 'Too many attempts. Request a new code.',
      );
    }
    record.tries += 1;
    if (record.code != code) {
      return const VerifyOtpResult(ok: false, error: 'That code is incorrect');
    }
    _pending.remove(normalized);
    final user = userFromEmail(normalized);
    final session = AuthSession(
      email: user.email,
      name: user.name,
      handle: user.handle,
    );
    state = session;
    return VerifyOtpResult(ok: true, session: session);
  }

  void logout() => state = null;
}
