import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/account/domain/user_profile.dart';

void main() {
  group('profileFromEmail', () {
    test('title-cases the local part into a name', () {
      final profile = profileFromEmail('ada.lovelace@example.com');
      expect(profile.name, 'Ada Lovelace');
      expect(profile.handle, '@ada.lovelace');
    });

    test('falls back to "you" for an empty local part', () {
      final profile = profileFromEmail('@example.com');
      expect(profile.name, 'You');
      expect(profile.handle, '@you');
    });
  });

  group('normalizeHandle', () {
    test('strips a leading @ and invalid characters', () {
      expect(normalizeHandle('@Ada! Lovelace'), '@adalovelace');
    });

    test('falls back to "you" when nothing is left', () {
      expect(normalizeHandle('@@@'), '@you');
    });

    test('truncates to 18 characters', () {
      expect(normalizeHandle('a' * 30), '@${'a' * 18}');
    });
  });

  group('sanitizeWebsite', () {
    test('adds https:// when no scheme is given', () {
      expect(sanitizeWebsite('example.com'), 'https://example.com');
    });

    test('leaves an existing scheme alone', () {
      expect(sanitizeWebsite('http://example.com'), 'http://example.com');
    });

    test('returns empty for blank input', () {
      expect(sanitizeWebsite('   '), '');
    });
  });

  group('sanitizeProfile', () {
    test('only overrides the fields actually passed', () {
      final fallback = profileFromEmail('ada@example.com');
      final next = sanitizeProfile(fallback, name: 'Ada L.');
      expect(next.name, 'Ada L.');
      expect(next.handle, fallback.handle);
      expect(next.hue, fallback.hue);
    });

    test('falls back to the fallback name when the new name is blank', () {
      final fallback = profileFromEmail('ada@example.com');
      final next = sanitizeProfile(fallback, name: '   ');
      expect(next.name, fallback.name);
    });

    test('rejects a hue outside the preset palette', () {
      final fallback = profileFromEmail('ada@example.com');
      final next = sanitizeProfile(fallback, hue: '#ffffff');
      expect(next.hue, fallback.hue);
    });

    test('accepts a preset hue', () {
      final fallback = profileFromEmail('ada@example.com');
      final next = sanitizeProfile(fallback, hue: profileHues[1]);
      expect(next.hue, profileHues[1]);
    });
  });
}
