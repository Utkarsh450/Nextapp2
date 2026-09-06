import 'package:flutter/foundation.dart';

/// A single notebook. Field set matches `Notebook` in `lib/notes/types.ts`.
@immutable
class const Notebook({
  required final String id,
  required final String ownerEmail,
  required final String name,
  required final String color,
  required final int createdAt,
}) {
  Notebook copyWith({String? name, String? color}) => Notebook(
    id: id,
    ownerEmail: ownerEmail,
    name: name ?? this.name,
    color: color ?? this.color,
    createdAt: createdAt,
  );

  @override
  bool operator ==(Object other) => other is Notebook && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Notebook($id, $name)';
}
