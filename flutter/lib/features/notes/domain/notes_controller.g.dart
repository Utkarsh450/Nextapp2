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

String _$notesControllerHash() => r'9e42b0852b58f919ed19434bb83393a29edbb2c1';

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

/// `board.notebookId` — the Today dashboard's notebook tiles and (once
/// built) the Notebooks library both drive this filter down into
/// [visibleNoteListProvider].

@ProviderFor(NoteNotebookFilter)
final noteNotebookFilterProvider = NoteNotebookFilterProvider._();

/// `board.notebookId` — the Today dashboard's notebook tiles and (once
/// built) the Notebooks library both drive this filter down into
/// [visibleNoteListProvider].
final class NoteNotebookFilterProvider
    extends $NotifierProvider<NoteNotebookFilter, String?> {
  /// `board.notebookId` — the Today dashboard's notebook tiles and (once
  /// built) the Notebooks library both drive this filter down into
  /// [visibleNoteListProvider].
  NoteNotebookFilterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteNotebookFilterProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteNotebookFilterHash();

  @$internal
  @override
  NoteNotebookFilter create() => NoteNotebookFilter();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String?>(value),
    );
  }
}

String _$noteNotebookFilterHash() =>
    r'3ca7c79102105c43aa9cecba73545b30db73731b';

/// `board.notebookId` — the Today dashboard's notebook tiles and (once
/// built) the Notebooks library both drive this filter down into
/// [visibleNoteListProvider].

abstract class _$NoteNotebookFilter extends $Notifier<String?> {
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

/// `board.search` — shared between the main notes list and the search
/// overlay (`search_overlay_screen.dart`), matching the source: typing in
/// the search field live-filters [visibleNoteListProvider] too, not just
/// the overlay's own match list.

@ProviderFor(NoteSearchQuery)
final noteSearchQueryProvider = NoteSearchQueryProvider._();

/// `board.search` — shared between the main notes list and the search
/// overlay (`search_overlay_screen.dart`), matching the source: typing in
/// the search field live-filters [visibleNoteListProvider] too, not just
/// the overlay's own match list.
final class NoteSearchQueryProvider
    extends $NotifierProvider<NoteSearchQuery, String> {
  /// `board.search` — shared between the main notes list and the search
  /// overlay (`search_overlay_screen.dart`), matching the source: typing in
  /// the search field live-filters [visibleNoteListProvider] too, not just
  /// the overlay's own match list.
  NoteSearchQueryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteSearchQueryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteSearchQueryHash();

  @$internal
  @override
  NoteSearchQuery create() => NoteSearchQuery();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(String value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<String>(value),
    );
  }
}

String _$noteSearchQueryHash() => r'c03e06ce8bef48fd69c278a4dda8ab455fe286d0';

/// `board.search` — shared between the main notes list and the search
/// overlay (`search_overlay_screen.dart`), matching the source: typing in
/// the search field live-filters [visibleNoteListProvider] too, not just
/// the overlay's own match list.

abstract class _$NoteSearchQuery extends $Notifier<String> {
  String build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<String, String>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<String, String>,
              String,
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

String _$visibleNoteListHash() => r'8a04c9358191374e23c2ac6ff901e553d726bf26';

/// `searchHits` in `NotesApp.tsx` — always `all`/no-notebook, unlike
/// [visibleNoteListProvider], but still respects the current label/color
/// filter, matching the source exactly.

@ProviderFor(searchHits)
final searchHitsProvider = SearchHitsProvider._();

/// `searchHits` in `NotesApp.tsx` — always `all`/no-notebook, unlike
/// [visibleNoteListProvider], but still respects the current label/color
/// filter, matching the source exactly.

final class SearchHitsProvider
    extends $FunctionalProvider<List<Note>, List<Note>, List<Note>>
    with $Provider<List<Note>> {
  /// `searchHits` in `NotesApp.tsx` — always `all`/no-notebook, unlike
  /// [visibleNoteListProvider], but still respects the current label/color
  /// filter, matching the source exactly.
  SearchHitsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHitsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHitsHash();

  @$internal
  @override
  $ProviderElement<List<Note>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  List<Note> create(Ref ref) {
    return searchHits(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Note> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Note>>(value),
    );
  }
}

String _$searchHitsHash() => r'2092414b4550ed742b0032d758d55fe417404572';

/// `dash` in `NotesApp.tsx` — the Today dashboard's aggregate summary,
/// recomputed only when the notes or notebooks it depends on change.

@ProviderFor(noteDashboardData)
final noteDashboardDataProvider = NoteDashboardDataProvider._();

/// `dash` in `NotesApp.tsx` — the Today dashboard's aggregate summary,
/// recomputed only when the notes or notebooks it depends on change.

final class NoteDashboardDataProvider
    extends
        $FunctionalProvider<
          dash.NoteDashboard,
          dash.NoteDashboard,
          dash.NoteDashboard
        >
    with $Provider<dash.NoteDashboard> {
  /// `dash` in `NotesApp.tsx` — the Today dashboard's aggregate summary,
  /// recomputed only when the notes or notebooks it depends on change.
  NoteDashboardDataProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'noteDashboardDataProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$noteDashboardDataHash();

  @$internal
  @override
  $ProviderElement<dash.NoteDashboard> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  dash.NoteDashboard create(Ref ref) {
    return noteDashboardData(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(dash.NoteDashboard value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<dash.NoteDashboard>(value),
    );
  }
}

String _$noteDashboardDataHash() => r'6415a054f0f5adff615db3ee45c4b0e2f70248f1';

/// `showToday` in `NotesApp.tsx` — Today is shown only when the notes tab
/// has no active filter of any kind, search included.

@ProviderFor(showTodayDashboard)
final showTodayDashboardProvider = ShowTodayDashboardProvider._();

/// `showToday` in `NotesApp.tsx` — Today is shown only when the notes tab
/// has no active filter of any kind, search included.

final class ShowTodayDashboardProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// `showToday` in `NotesApp.tsx` — Today is shown only when the notes tab
  /// has no active filter of any kind, search included.
  ShowTodayDashboardProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'showTodayDashboardProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$showTodayDashboardHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return showTodayDashboard(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$showTodayDashboardHash() =>
    r'bd9f32d5e7dba071fe8f8109d7fdb4823c4a5277';

/// `notebookCounts` in `NotesApp.tsx` — live (not archived/trashed) note
/// counts keyed by `notebookId`, feeding both the Today dashboard's tiles
/// and the Notebooks library (feature-audit #11).

@ProviderFor(liveNotebookCounts)
final liveNotebookCountsProvider = LiveNotebookCountsProvider._();

/// `notebookCounts` in `NotesApp.tsx` — live (not archived/trashed) note
/// counts keyed by `notebookId`, feeding both the Today dashboard's tiles
/// and the Notebooks library (feature-audit #11).

final class LiveNotebookCountsProvider
    extends
        $FunctionalProvider<
          Map<String, int>,
          Map<String, int>,
          Map<String, int>
        >
    with $Provider<Map<String, int>> {
  /// `notebookCounts` in `NotesApp.tsx` — live (not archived/trashed) note
  /// counts keyed by `notebookId`, feeding both the Today dashboard's tiles
  /// and the Notebooks library (feature-audit #11).
  LiveNotebookCountsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'liveNotebookCountsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$liveNotebookCountsHash();

  @$internal
  @override
  $ProviderElement<Map<String, int>> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Map<String, int> create(Ref ref) {
    return liveNotebookCounts(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Map<String, int> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Map<String, int>>(value),
    );
  }
}

String _$liveNotebookCountsHash() =>
    r'472bf4fe89afddee9c423d03af8c02b430719512';

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

/// Looks up one note by id, for the editor route (`/notes/:id/edit`).
/// `null` once a note is deleted forever while its editor is still open.

@ProviderFor(noteById)
final noteByIdProvider = NoteByIdFamily._();

/// Looks up one note by id, for the editor route (`/notes/:id/edit`).
/// `null` once a note is deleted forever while its editor is still open.

final class NoteByIdProvider extends $FunctionalProvider<Note?, Note?, Note?>
    with $Provider<Note?> {
  /// Looks up one note by id, for the editor route (`/notes/:id/edit`).
  /// `null` once a note is deleted forever while its editor is still open.
  NoteByIdProvider._({
    required NoteByIdFamily super.from,
    required int super.argument,
  }) : super(
         retry: null,
         name: r'noteByIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$noteByIdHash();

  @override
  String toString() {
    return r'noteByIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<Note?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Note? create(Ref ref) {
    final argument = this.argument as int;
    return noteById(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Note? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Note?>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is NoteByIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$noteByIdHash() => r'7197a625ab4b55e2793735e828c2a4d6d5c94014';

/// Looks up one note by id, for the editor route (`/notes/:id/edit`).
/// `null` once a note is deleted forever while its editor is still open.

final class NoteByIdFamily extends $Family
    with $FunctionalFamilyOverride<Note?, int> {
  NoteByIdFamily._()
    : super(
        retry: null,
        name: r'noteByIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Looks up one note by id, for the editor route (`/notes/:id/edit`).
  /// `null` once a note is deleted forever while its editor is still open.

  NoteByIdProvider call(int id) => NoteByIdProvider._(argument: id, from: this);

  @override
  String toString() => r'noteByIdProvider';
}
