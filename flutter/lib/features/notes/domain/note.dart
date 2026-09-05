import 'package:flutter/foundation.dart';
import 'package:notes_app/features/notes/domain/note_reminders.dart';

/// Sentinel default for `copyWith`'s `trashedAt` parameter, so "clear the
/// due-trash timestamp" (an explicit `null`) is distinguishable from
/// "leave it alone" (the parameter wasn't passed at all).
const Object _unset = Object();

/// A single note. Field set and semantics are a direct port of `Note` in
/// `lib/notes/types.ts`.
///
/// `attachments` is intentionally not modeled yet — the source keeps it as
/// an inline array, but `docs/flutter-architecture.md` §2 moves attachment
/// bytes to a separate relational table once persistence is wired up. Until
/// the note editor needs it, adding the field here would be speculative.
@immutable
class const Note({
  required final int id,
  required final String ownerEmail,
  required final int createdAt,
  required final int updatedAt,
  required final String color,
  final String title = '',
  final String tag = '',
  final String preview = '',
  final String notebookId = 'inbox',
  final String notebook = 'Inbox',
  final String? logo,
  final bool confirmed = false,
  final String body = '',
  final bool pinned = false,
  final bool archived = false,
  final int? trashedAt,

  /// `YYYY-MM-DD`, kept as a string — see
  /// `docs/flutter-architecture.md` §7 for why date-only fields don't
  /// become [DateTime].
  final String? dueAt,

  /// `HH:mm`, kept as a string for the same reason as [dueAt].
  final String? dueTime,
  final int alertMinutes = -1,
  final String? remindAt,
  final List<String> labels = const [],
  final int order = 0,
}) {
  /// `dueAt`/`dueTime`/`alertMinutes`/`remindAt` always change together as
  /// one consistent set (mirroring the source's `reminderFields()`) — use
  /// [withReminder] for those, not this. `trashedAt` can be explicitly
  /// cleared via the sentinel default: pass `null` to clear it, or omit it
  /// to leave it alone.
  Note copyWith({
    String? title,
    String? tag,
    String? preview,
    String? notebookId,
    String? notebook,
    String? logo,
    bool? confirmed,
    int? updatedAt,
    String? body,
    bool? pinned,
    bool? archived,
    Object? trashedAt = _unset,
    String? color,
    List<String>? labels,
    int? order,
  }) {
    return Note(
      id: id,
      ownerEmail: ownerEmail,
      title: title ?? this.title,
      tag: tag ?? this.tag,
      preview: preview ?? this.preview,
      notebookId: notebookId ?? this.notebookId,
      notebook: notebook ?? this.notebook,
      logo: logo ?? this.logo,
      confirmed: confirmed ?? this.confirmed,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      body: body ?? this.body,
      pinned: pinned ?? this.pinned,
      archived: archived ?? this.archived,
      trashedAt: identical(trashedAt, _unset)
          ? this.trashedAt
          : trashedAt as int?,
      color: color ?? this.color,
      dueAt: dueAt,
      dueTime: dueTime,
      alertMinutes: alertMinutes,
      remindAt: remindAt,
      labels: labels ?? this.labels,
      order: order ?? this.order,
    );
  }

  /// Replaces the due-date/alert set atomically — see
  /// `note_reminders.dart`'s `resolveReminderFields`, which is what
  /// computes a consistent [ReminderFields] to pass here.
  Note withReminder(ReminderFields fields) => Note(
    id: id,
    ownerEmail: ownerEmail,
    title: title,
    tag: tag,
    preview: preview,
    notebookId: notebookId,
    notebook: notebook,
    logo: logo,
    confirmed: confirmed,
    createdAt: createdAt,
    updatedAt: updatedAt,
    body: body,
    pinned: pinned,
    archived: archived,
    trashedAt: trashedAt,
    color: color,
    dueAt: fields.dueAt,
    dueTime: fields.dueTime,
    alertMinutes: fields.alertMinutes,
    remindAt: fields.remindAt,
    labels: labels,
    order: order,
  );

  @override
  bool operator ==(Object other) => other is Note && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Note#$id($title)';
}
