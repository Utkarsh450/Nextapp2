/// Direct port of `lib/profile/index.ts`.
library;

const List<String> profileHues = [
  '#18181b',
  '#7c3aed',
  '#0f766e',
  '#be185d',
  '#c2410c',
  '#1d4ed8',
  '#a16207',
];

String _emailKey(String value) => value.trim().toLowerCase();

class const UserProfile({
  required final String name,
  required final String handle,
  final String bio = '',
  final String location = '',
  final String website = '',
  final String hue = '#18181b',
  final String? avatar,
});

String initialsFromName(String name) {
  final initials = name
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .map((part) => part[0])
      .join()
      .toUpperCase();
  final trimmed = initials.substring(0, initials.length.clamp(0, 2));
  return trimmed.isEmpty ? 'YO' : trimmed;
}

/// Matches `normalizeHandle`.
String normalizeHandle(String value) {
  final cleaned = value
      .trim()
      .replaceFirst(RegExp('^@+'), '')
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9._]'), '');
  final slice = cleaned.substring(0, cleaned.length.clamp(0, 18));
  return '@${slice.isEmpty ? 'you' : slice}';
}

/// Matches `sanitizeWebsite`.
String sanitizeWebsite(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '';
  final withScheme =
      RegExp('^https?://', caseSensitive: false).hasMatch(trimmed)
      ? trimmed
      : 'https://$trimmed';
  return withScheme.substring(0, withScheme.length.clamp(0, 80));
}

/// Matches `profileFromEmail`.
UserProfile profileFromEmail(String email) {
  final rawLocal = _emailKey(email).split('@').firstOrNull ?? '';
  final local = rawLocal.isEmpty ? 'you' : rawLocal;
  final name = local
      .replaceAll(RegExp('[._-]+'), ' ')
      .replaceAllMapped(RegExp(r'\b\w'), (m) => m.group(0)!.toUpperCase());
  return UserProfile(
    name: name.isEmpty ? 'You' : name,
    handle: normalizeHandle(local),
  );
}

/// Matches `sanitizeProfile`.
UserProfile sanitizeProfile(
  UserProfile fallback, {
  String? name,
  String? handle,
  String? bio,
  String? location,
  String? website,
  String? hue,
  Object? avatar = _unset,
}) {
  final resolvedHue = profileHues.contains(hue) ? hue! : fallback.hue;
  final resolvedAvatar = identical(avatar, _unset)
      ? fallback.avatar
      : (avatar == null ||
            (avatar is String && avatar.startsWith('data:image/')))
      ? avatar as String?
      : fallback.avatar;
  final trimmedName = (name ?? fallback.name).trim();
  return UserProfile(
    name: trimmedName.isEmpty
        ? fallback.name
        : trimmedName.substring(0, trimmedName.length.clamp(0, 40)),
    handle: normalizeHandle(handle ?? fallback.handle),
    bio: (bio ?? fallback.bio).trim().substring(
      0,
      (bio ?? fallback.bio).trim().length.clamp(0, 160),
    ),
    location: (location ?? fallback.location).trim().substring(
      0,
      (location ?? fallback.location).trim().length.clamp(0, 40),
    ),
    website: sanitizeWebsite(website ?? fallback.website),
    hue: resolvedHue,
    avatar: resolvedAvatar,
  );
}

const Object _unset = Object();

extension on List<String> {
  String? get firstOrNull => isEmpty ? null : first;
}
