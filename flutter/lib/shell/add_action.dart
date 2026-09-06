/// Matches `AddAction` in `features/shell/AppTabs.tsx` — the seven-item
/// "Add…" menu opened from the dock's + button. The source also supports
/// `` `saved:${id}` `` for the user's own saved templates
/// (`SavedTemplate`), which isn't modeled in this build — see
/// `note_editor_screen.dart`'s doc comment on "Save as template".
enum AddAction { note, list, daily, idea, meeting, reminder, capture }
