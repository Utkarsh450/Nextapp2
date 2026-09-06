import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/plan/domain/note_agenda.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'plan_providers.g.dart';

/// `agenda` in `NotesApp.tsx` — recomputed only when the notes it depends
/// on change.
@riverpod
NoteAgenda planAgenda(Ref ref) {
  final notes = ref.watch(notesControllerProvider);
  return noteAgenda(notes, todayIso());
}
