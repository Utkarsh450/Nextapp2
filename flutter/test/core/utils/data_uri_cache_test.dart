import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/utils/data_uri_cache.dart';

void main() {
  test('decodes the base64 payload of a data URI', () {
    final payload = base64Encode(utf8.encode('hello'));
    final bytes = decodeDataUriBytes('data:text/plain;base64,$payload');
    expect(utf8.decode(bytes), 'hello');
  });

  test('returns the same Uint8List instance for the same URI, so Image.memory '
      'keeps hitting the cache instead of re-decoding every rebuild', () {
    final payload = base64Encode(utf8.encode('same photo'));
    final uri = 'data:image/jpeg;base64,$payload';
    final first = decodeDataUriBytes(uri);
    final second = decodeDataUriBytes(uri);
    expect(identical(first, second), isTrue);
  });

  test('decodes two different URIs independently', () {
    final a = decodeDataUriBytes(
      'data:text/plain;base64,${base64Encode(utf8.encode('a'))}',
    );
    final b = decodeDataUriBytes(
      'data:text/plain;base64,${base64Encode(utf8.encode('b'))}',
    );
    expect(utf8.decode(a), 'a');
    expect(utf8.decode(b), 'b');
  });
}
