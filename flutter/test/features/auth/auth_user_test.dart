import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/auth/domain/auth_user.dart';

void main() {
  group('isValidEmail', () {
    test('accepts a normal address', () {
      expect(isValidEmail('Ada@Example.com'), isTrue);
    });

    test('rejects a string with no domain', () {
      expect(isValidEmail('ada@'), isFalse);
    });

    test('rejects an empty string', () {
      expect(isValidEmail(''), isFalse);
    });
  });

  group('userFromEmail', () {
    test('title-cases the local part into a name', () {
      final user = userFromEmail('ada.lovelace@example.com');
      expect(user.name, 'Ada Lovelace');
      expect(user.handle, '@ada.lovelace');
      expect(user.initials, 'AL');
      expect(user.email, 'ada.lovelace@example.com');
    });

    test('normalizes casing and whitespace', () {
      final user = userFromEmail('  Ada@Example.COM  ');
      expect(user.email, 'ada@example.com');
    });

    test('falls back to "you" for an empty local part', () {
      final user = userFromEmail('@example.com');
      expect(user.name, 'You');
      expect(user.handle, '@you');
    });

    test('truncates a long handle to 18 characters of the local part', () {
      final user = userFromEmail('${'a' * 30}@example.com');
      expect(user.handle, '@${'a' * 18}');
    });
  });
}
