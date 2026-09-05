/// Build-time app configuration.
///
/// Per `docs/apps-script-integration.md` §7 and `docs/flutter-architecture.md`
/// §5: the Flutter app never talks to Apps Script or holds its shared
/// secret. It only calls the Next.js `/api/auth/*` routes, and the base URL
/// for those is the one thing that must stay swappable without a code
/// change — supplied at build time, never hardcoded, never committed.
///
/// Usage:
/// ```sh
/// flutter run --dart-define=AUTH_API_ORIGIN=https://your-deployment.example.com
/// ```
abstract final class AppConfig {
  /// Base origin of the deployed Next.js API (e.g. a Vercel URL). Empty
  /// until a real value is supplied at build time.
  ///
  /// Known blocker: `public/auth-origin.json` in the Next.js repo still
  /// points at a throwaway devtunnel. A real hosted origin must replace it
  /// before this can be set to anything usable — see
  /// `docs/flutter-architecture.md` §9.1.
  static const String authApiOrigin = String.fromEnvironment(
    'AUTH_API_ORIGIN',
  );

  /// Whether a real auth origin has been configured for this build.
  static bool get hasAuthApiOrigin => authApiOrigin.isNotEmpty;
}
