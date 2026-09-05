import 'dart:convert';

import 'package:drift/drift.dart';

/// Stores a `List<String>` as JSON text — used for `Note.labels`, matching
/// how the source app stores the array inline in Dexie (`lib/notes/types.ts`
/// `Note.labels`). Attachments get their own relational table instead (see
/// `docs/flutter-architecture.md` §2), so no list-of-object converter is
/// needed here.
class const StringListConverter()
    extends TypeConverter<List<String>, String> {
  @override
  List<String> fromSql(String fromDb) {
    if (fromDb.isEmpty) return const [];
    final decoded = jsonDecode(fromDb) as List<dynamic>;
    return decoded.cast<String>();
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
