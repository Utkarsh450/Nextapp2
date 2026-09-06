import 'package:flutter/foundation.dart';

/// A tracked habit. Matches `Habit` in `lib/notes/types.ts`.
@immutable
class const Habit({
  required final String id,
  required final String ownerEmail,
  required final String name,
  required final String color,
  required final int createdAt,
}) {
  @override
  bool operator ==(Object other) => other is Habit && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

/// One day a habit was checked off. Matches `HabitCheck`.
@immutable
class const HabitCheck({
  required final String ownerEmail,
  required final String habitId,

  /// `YYYY-MM-DD` — see `docs/flutter-architecture.md` §7.
  required final String date,
}) {
  @override
  bool operator ==(Object other) =>
      other is HabitCheck && other.habitId == habitId && other.date == date;

  @override
  int get hashCode => Object.hash(habitId, date);
}
