import 'package:flutter/painting.dart';

/// Parses a `#RRGGBB` or `#AARRGGBB` hex string into a [Color].
///
/// Kept as the single conversion point for the literal hex values recorded
/// in `docs/design-system.md`, so no widget hand-parses color strings.
Color colorFromHex(String hex) {
  final buffer = StringBuffer();
  final cleaned = hex.replaceFirst('#', '');
  if (cleaned.length == 6) buffer.write('ff');
  buffer.write(cleaned);
  return Color(int.parse(buffer.toString(), radix: 16));
}
