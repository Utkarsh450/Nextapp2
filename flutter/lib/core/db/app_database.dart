import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import 'package:notes_app/core/db/tables.dart';

part 'app_database.g.dart';

/// The app's single local SQLite database (`notes_personal.sqlite` in the
/// platform app-support directory), replacing the source app's Dexie
/// (`notes-personal-v1`) database one-for-one.
///
/// Schema `v1` here is the *union* of Dexie's v1–v3 migrations
/// (`lib/notes/storage.ts`) — there's no reason to replay that history on a
/// fresh install. DAOs (one per feature, added alongside each screen) are
/// the only code that touches this class directly; everything above the
/// `data/` layer goes through a DAO.
@DriftDatabase(
  tables: [
    Notes,
    Notebooks,
    Templates,
    Habits,
    HabitChecks,
    Attachments,
    Prefs,
  ],
)
class AppDatabase extends _$AppDatabase {
  // Primary-constructor sugar doesn't fit: this forwards through a function
  // call (`_openConnection()`), not a plain field/super forward, and a
  // class can only declare one primary constructor — so both constructors
  // here stay explicit.
  // ignore: unnecessary_type_name_in_constructor
  AppDatabase() : super(_openConnection());

  /// For tests: inject an in-memory executor instead of opening a real file
  /// (see `docs/flutter-architecture.md` §8 — DAO tests, incl. multi-account
  /// isolation, run against an in-memory database).
  // ignore: unnecessary_type_name_in_constructor
  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;
}

QueryExecutor _openConnection() {
  return driftDatabase(name: 'notes_personal');
}
