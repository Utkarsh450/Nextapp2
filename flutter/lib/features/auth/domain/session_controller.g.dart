// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(SessionController)
final sessionControllerProvider = SessionControllerProvider._();

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
final class SessionControllerProvider
    extends $NotifierProvider<SessionController, AuthSession?> {
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
  SessionControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sessionControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sessionControllerHash();

  @$internal
  @override
  SessionController create() => SessionController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AuthSession? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AuthSession?>(value),
    );
  }
}

String _$sessionControllerHash() => r'a6098273516d52d2203f9448a7e9119361badb26';

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

abstract class _$SessionController extends $Notifier<AuthSession?> {
  AuthSession? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AuthSession?, AuthSession?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AuthSession?, AuthSession?>,
              AuthSession?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
