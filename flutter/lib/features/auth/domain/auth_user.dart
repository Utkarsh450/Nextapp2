/// Direct port of `lib/auth/index.ts`.
library;

String normalizeEmail(String value) => value.trim().toLowerCase();

final RegExp _emailRe = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');

bool isValidEmail(String value) => _emailRe.hasMatch(normalizeEmail(value));

/// A signed-in user, derived deterministically from their email — matches
/// `userFromEmail`.
class const AuthUser({
  required final String email,
  required final String name,
  required final String handle,
  required final String initials,
});

AuthUser userFromEmail(String email) {
  final normalized = normalizeEmail(email);
  final rawLocal = normalized.split('@').firstOrNull ?? '';
  final local = rawLocal.isEmpty ? 'you' : rawLocal;
  final withSpaces = local.replaceAll(RegExp('[._-]+'), ' ');
  final name = withSpaces.replaceAllMapped(
    RegExp(r'\b\w'),
    (m) => m.group(0)!.toUpperCase(),
  );
  final initials = name
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .join()
      .toUpperCase();
  return AuthUser(
    email: normalized,
    name: name.isEmpty ? 'You' : name,
    handle: '@${local.substring(0, local.length.clamp(0, 18))}',
    initials: initials.isEmpty
        ? 'YO'
        : initials.substring(0, initials.length.clamp(0, 2)),
  );
}

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
