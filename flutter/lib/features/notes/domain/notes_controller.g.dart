// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the notes list itself.
///
/// **In-memory only, per instruction:** no Drift wiring yet, so state
/// resets to [sampleNotes] on every app restart. Mirrors the action set of
/// `hooks/useNotes.ts` for the actions this screen needs; note creation and
/// editing arrive with the note editor screen.

@ProviderFor(NotesController)
final notesControllerProvider = NotesControllerProvider._();

/// Holds the notes list itself.
///
/// **In-memory only, per instruction:** no Drift wiring yet, so state
/// resets to [sampleNotes] on every app restart. Mirrors the action set of
/// `hooks/useNotes.ts` for the actions this screen needs; note creation and
/// editing arrive with the note editor screen.
final class NotesControllerProvider
    extends $NotifierProvider<NotesController, List<Note>> {
  /// Holds the notes list itself.
  ///
  /// **In-memory only, per instruction:** no Drift wiring yet, so state
  /// resets to [sampleNotes] on every app restart. Mirrors the action set of
  /// `hooks/useNotes.ts` for the actions this screen needs; note creation and
  /// editing arrive with the note editor screen.
  NotesControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notesControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notesControllerHash();

  @$internal
  @override
  NotesController create() => NotesController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Note> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Note>>(value),
    );
  }
}

String _$notesControllerHash() => r'9153aad5465f43641b54b834206c64decdecfb00';

/// Holds the notes list itself.
///
/// **In-memory only, per instruction:** no Drift wiring yet, so state
/// resets to [sampleNotes] on every app restart. Mirrors the action set of
/// `hooks/useNotes.ts` for the actions this screen needs; note creation and
/// editing arrive with the note editor screen.

abstract class _$NotesController extends $Notifier<List<Note>> {
  List<Note> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Note>, List<Note>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Note>, List<Note>>,
              List<Note>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// `board.filterKey` — defaults to `all`, matching the source.

@ProviderFor(NoteFilterKey)
final noteFilterKeyProvider = NoteFilterKeyProvider._();

/// `board.filterKey` — defaults to `all`, matching the source.
final class NoteFilterKeyProvider
    extends $NotifierProvider<NoteFilterKey, NoteFilter> {
  /// `board.filterKey` — defaults to `all`, matching the source.
  NoteFilterKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteFilterKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteFilterKeyHash();

  @$internal
  @override
  NoteFilterKey create() => NoteFilterKey();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteFilter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteFilter>(value),
    );
  }
}

String _$noteFilterKeyHash() => r'5274bfca87b6ce2b59e97e979afae312972b6507';

/// `board.filterKey` — defaults to `all`, matching the source.

abstract class _$NoteFilterKey extends $Notifier<NoteFilter> {
  NoteFilter build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NoteFilter, NoteFilter>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoteFilter, NoteFilter>,
              NoteFilter,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// `board.sortKey`. The source defines `newest`/`oldest`/`title`/`tag` at
/// the data layer (`lib/notes/filters.ts`) but — confirmed by a repo-wide
/// search for `setSortKey` — never wires a control to change it in any
/// screen. `newest` (the default) is genuinely the only value the shipped
/// app ever uses; kept as real state here rather than a hardcoded constant
/// so a future sort-control screen is a pure UI addition.

@ProviderFor(NoteSortKey)
final noteSortKeyProvider = NoteSortKeyProvider._();

/// `board.sortKey`. The source defines `newest`/`oldest`/`title`/`tag` at
/// the data layer (`lib/notes/filters.ts`) but — confirmed by a repo-wide
/// search for `setSortKey` — never wires a control to change it in any
/// screen. `newest` (the default) is genuinely the only value the shipped
/// app ever uses; kept as real state here rather than a hardcoded constant
/// so a future sort-control screen is a pure UI addition.
final class NoteSortKeyProvider
    extends $NotifierProvider<NoteSortKey, NoteSort> {
  /// `board.sortKey`. The source defines `newest`/`oldest`/`title`/`tag` at
  /// the data layer (`lib/notes/filters.ts`) but — confirmed by a repo-wide
  /// search for `setSortKey` — never wires a control to change it in any
  /// screen. `newest` (the default) is genuinely the only value the shipped
  /// app ever uses; kept as real state here rather than a hardcoded constant
  /// so a future sort-control screen is a pure UI addition.
  NoteSortKeyProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteSortKeyProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteSortKeyHash();

  @$internal
  @override
  NoteSortKey create() => NoteSortKey();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteSort value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteSort>(value),
    );
  }
}

String _$noteSortKeyHash() => r'a6ed3bff42514fb09b049f381e5968f51d96c52f';

/// `board.sortKey`. The source defines `newest`/`oldest`/`title`/`tag` at
/// the data layer (`lib/notes/filters.ts`) but — confirmed by a repo-wide
/// search for `setSortKey` — never wires a control to change it in any
/// screen. `newest` (the default) is genuinely the only value the shipped
/// app ever uses; kept as real state here rather than a hardcoded constant
/// so a future sort-control screen is a pure UI addition.

abstract class _$NoteSortKey extends $Notifier<NoteSort> {
  NoteSort build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NoteSort, NoteSort>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoteSort, NoteSort>,
              NoteSort,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(NoteColorFilter)
final noteColorFilterProvider = NoteColorFilterProvider._();

final class NoteColorFilterProvider
    extends $NotifierProvider<NoteColorFilter, String?> {
  NoteColorFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteColorFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteColorFilterHash();

  @$internal
  @override
  NoteColorFilter create() => NoteColorFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$noteColorFilterHash() => r'a4712e0ee7ca2e1f6ea510de7e425d4731dc76ea';

abstract class _$NoteColorFilter extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(NoteLabelFilter)
final noteLabelFilterProvider = NoteLabelFilterProvider._();

final class NoteLabelFilterProvider
    extends $NotifierProvider<NoteLabelFilter, String?> {
  NoteLabelFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteLabelFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteLabelFilterHash();

  @$internal
  @override
  NoteLabelFilter create() => NoteLabelFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$noteLabelFilterHash() => r'613061cf2c4de9d34f0fd16f1343c9814e98697e';

abstract class _$NoteLabelFilter extends $Notifier<String?> {
  String? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String?, String?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String?, String?>,
              String?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

@ProviderFor(NoteBoardLayoutController)
final noteBoardLayoutControllerProvider = NoteBoardLayoutControllerProvider._();

final class NoteBoardLayoutControllerProvider
    extends $NotifierProvider<NoteBoardLayoutController, NoteBoardLayout> {
  NoteBoardLayoutControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteBoardLayoutControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteBoardLayoutControllerHash();

  @$internal
  @override
  NoteBoardLayoutController create() => NoteBoardLayoutController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteBoardLayout value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteBoardLayout>(value),
    );
  }
}

String _$noteBoardLayoutControllerHash() =>
    r'ab94600bc753e9001181d7669ae814bda9e3a73e';

abstract class _$NoteBoardLayoutController extends $Notifier<NoteBoardLayout> {
  NoteBoardLayout build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<NoteBoardLayout, NoteBoardLayout>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<NoteBoardLayout, NoteBoardLayout>,
              NoteBoardLayout,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// `shown` in `NotesApp.tsx` — the filtered, sorted list this screen shows.

@ProviderFor(visibleNoteList)
final visibleNoteListProvider = VisibleNoteListProvider._();

/// `shown` in `NotesApp.tsx` — the filtered, sorted list this screen shows.

final class VisibleNoteListProvider
    extends $FunctionalProvider<List<Note>, List<Note>, List<Note>>
    with $Provider<List<Note>> {
  /// `shown` in `NotesApp.tsx` — the filtered, sorted list this screen shows.
  VisibleNoteListProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'visibleNoteListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$visibleNoteListHash();

  @$internal
  @override
  $ProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Note> create(Ref ref) {
    return visibleNoteList(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Note> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Note>>(value),
    );
  }
}

String _$visibleNoteListHash() => r'a7a5a902a6669e553a8fcd2710338b3c9ae3e17c';

@ProviderFor(noteLabelOptions)
final noteLabelOptionsProvider = NoteLabelOptionsProvider._();

final class NoteLabelOptionsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  NoteLabelOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteLabelOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteLabelOptionsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return noteLabelOptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$noteLabelOptionsHash() => r'b43d7c06cdd385be6869c51e2d45a3f401802d93';

@ProviderFor(noteColorOptions)
final noteColorOptionsProvider = NoteColorOptionsProvider._();

final class NoteColorOptionsProvider
    extends $FunctionalProvider<List<String>, List<String>, List<String>>
    with $Provider<List<String>> {
  NoteColorOptionsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteColorOptionsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteColorOptionsHash();

  @$internal
  @override
  $ProviderElement<List<String>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<String> create(Ref ref) {
    return noteColorOptions(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$noteColorOptionsHash() => r'fd450cd79de5e5f8efdafdb3618a8f0240c806cf';

@ProviderFor(upcomingNoteReminders)
final upcomingNoteRemindersProvider = UpcomingNoteRemindersProvider._();

final class UpcomingNoteRemindersProvider
    extends $FunctionalProvider<List<Note>, List<Note>, List<Note>>
    with $Provider<List<Note>> {
  UpcomingNoteRemindersProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'upcomingNoteRemindersProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$upcomingNoteRemindersHash();

  @$internal
  @override
  $ProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Note> create(Ref ref) {
    return upcomingNoteReminders(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Note> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Note>>(value),
    );
  }
}

String _$upcomingNoteRemindersHash() =>
    r'1bbf76399757205cf0129d4c2350fae3a96cf751';
