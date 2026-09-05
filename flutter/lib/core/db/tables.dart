import 'package:drift/drift.dart';
import 'package:notes_app/core/db/converters.dart';

/// Notes — the core entity. Column set and semantics are a direct port of
/// `Note` in `lib/notes/types.ts`; compound primary key and secondary
/// indexes mirror the Dexie schema in `lib/notes/storage.ts`
/// (`'[ownerEmail+id], ownerEmail, notebookId, trashedAt, archived,
/// updatedAt'`) so every query the source app needs stays indexed.
///
/// `attachments` is **not** a column here — attachment metadata + bytes
/// live in [Attachments], a relational table, per
/// `docs/flutter-architecture.md` §2 (a deliberate improvement over the
/// source's embedded-array-plus-separate-blob-table split).
@TableIndex(name: 'notes_notebook', columns: {#notebookId})
@TableIndex(name: 'notes_trashed_at', columns: {#trashedAt})
@TableIndex(name: 'notes_archived', columns: {#archived})
@TableIndex(name: 'notes_updated_at', columns: {#updatedAt})
class Notes extends Table {
  IntColumn get id => integer()();
  TextColumn get ownerEmail => text()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get tag => text().withDefault(const Constant(''))();
  TextColumn get preview => text().withDefault(const Constant(''))();
  TextColumn get notebookId => text().withDefault(const Constant(''))();
  TextColumn get notebook => text().withDefault(const Constant(''))();
  TextColumn get logo => text().nullable()();
  BoolColumn get confirmed => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
  TextColumn get body => text().withDefault(const Constant(''))();
  BoolColumn get pinned => boolean().withDefault(const Constant(false))();
  BoolColumn get archived => boolean().withDefault(const Constant(false))();
  IntColumn get trashedAt => integer().nullable()();
  TextColumn get color => text()();
  TextColumn get dueAt => text().nullable()();
  TextColumn get dueTime => text().nullable()();
  IntColumn get alertMinutes => integer().withDefault(const Constant(-1))();
  TextColumn get remindAt => text().nullable()();
  TextColumn get labels =>
      text()
          .map(const StringListConverter())
          .withDefault(const Constant('[]'))();
  IntColumn get order => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {ownerEmail, id};
}

/// Notebooks — `Notebook` in `lib/notes/types.ts`.
class Notebooks extends Table {
  TextColumn get id => text()();
  TextColumn get ownerEmail => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {ownerEmail, id};
}

/// Saved templates — `SavedTemplate` in `lib/notes/types.ts`. Optional
/// fields are nullable columns rather than a JSON blob, since every field
/// is queried/displayed individually (template list, apply-template).
class Templates extends Table {
  TextColumn get id => text()();
  TextColumn get ownerEmail => text()();
  TextColumn get name => text()();
  TextColumn get title => text()();
  TextColumn get tag => text()();
  TextColumn get notebookId => text()();
  TextColumn get body => text()();
  TextColumn get color => text().nullable()();
  TextColumn get labels =>
      text()
          .map(const StringListConverter())
          .withDefault(const Constant('[]'))();
  TextColumn get dueAt => text().nullable()();
  TextColumn get dueTime => text().nullable()();
  IntColumn get alertMinutes => integer().withDefault(const Constant(-1))();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {ownerEmail, id};
}

/// Habits — `Habit` in `lib/notes/types.ts`.
class Habits extends Table {
  TextColumn get id => text()();
  TextColumn get ownerEmail => text()();
  TextColumn get name => text()();
  TextColumn get color => text()();
  IntColumn get createdAt => integer()();

  @override
  Set<Column> get primaryKey => {ownerEmail, id};
}

/// Habit check-ins — `HabitCheck` in `lib/notes/types.ts`. Triple-column
/// primary key mirrors Dexie's `'[ownerEmail+habitId+date],
/// [ownerEmail+date], [ownerEmail+habitId]'`; the two extra Dexie indexes
/// (by date-only, by habit-only) are covered by secondary indexes below
/// rather than duplicated compound keys.
@TableIndex(name: 'habit_checks_by_date', columns: {#ownerEmail, #date})
@TableIndex(name: 'habit_checks_by_habit', columns: {#ownerEmail, #habitId})
class HabitChecks extends Table {
  TextColumn get ownerEmail => text()();
  TextColumn get habitId => text()();
  TextColumn get date => text()(); // ISO YYYY-MM-DD, kept as string — see
  // docs/flutter-architecture.md §7 for why date-only fields stay strings.

  @override
  Set<Column> get primaryKey => {ownerEmail, habitId, date};
}

/// Attachment metadata. Bytes live on disk under
/// `<appSupport>/blobs/<ownerEmailHash>/<id>`; this row only tracks where.
/// Replaces the source's `BlobRecord` table plus the note-embedded
/// `Attachment[]` metadata — see `docs/flutter-architecture.md` §2.
class Attachments extends Table {
  TextColumn get id => text()();
  TextColumn get ownerEmail => text()();
  IntColumn get noteId => integer()();
  TextColumn get name => text()();
  TextColumn get mime => text()();
  IntColumn get createdAt => integer()();
  TextColumn get relativePath => text()();

  @override
  Set<Column> get primaryKey => {ownerEmail, id};
}

/// Small per-app key/value store — search recents, the seeded/onboarded
/// flags, theme/skin/layout settings. Deliberately loose-typed (`valueJson`
/// holds arbitrary JSON) to match the source's `prefs: 'key'` Dexie table,
/// which stored heterogeneous value types under one schema.
class Prefs extends Table {
  TextColumn get key => text()();
  TextColumn get valueJson => text()();

  @override
  Set<Column> get primaryKey => {key};
}
