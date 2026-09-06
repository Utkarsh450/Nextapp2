// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notebooks_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// **In-memory only**, matching every other controller in this build (no
/// Drift wiring yet). The source always loads this array from the account
/// bundle (`bundle.notebooks` in `hooks/useNotes.ts`) — there's no local
/// equivalent to seed from, so this seeds the three notebooks
/// `sample_notes.dart` already references (`inbox`/`home`/`work`) with
/// preset palette colors, giving the Today dashboard's tiles and the future
/// Notebooks library (feature-audit #11) something real to show.

@ProviderFor(NotebooksController)
final notebooksControllerProvider = NotebooksControllerProvider._();

/// **In-memory only**, matching every other controller in this build (no
/// Drift wiring yet). The source always loads this array from the account
/// bundle (`bundle.notebooks` in `hooks/useNotes.ts`) — there's no local
/// equivalent to seed from, so this seeds the three notebooks
/// `sample_notes.dart` already references (`inbox`/`home`/`work`) with
/// preset palette colors, giving the Today dashboard's tiles and the future
/// Notebooks library (feature-audit #11) something real to show.
final class NotebooksControllerProvider
    extends $NotifierProvider<NotebooksController, List<Notebook>> {
  /// **In-memory only**, matching every other controller in this build (no
  /// Drift wiring yet). The source always loads this array from the account
  /// bundle (`bundle.notebooks` in `hooks/useNotes.ts`) — there's no local
  /// equivalent to seed from, so this seeds the three notebooks
  /// `sample_notes.dart` already references (`inbox`/`home`/`work`) with
  /// preset palette colors, giving the Today dashboard's tiles and the future
  /// Notebooks library (feature-audit #11) something real to show.
  NotebooksControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notebooksControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notebooksControllerHash();

  @$internal
  @override
  NotebooksController create() => NotebooksController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Notebook> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Notebook>>(value),
    );
  }
}

String _$notebooksControllerHash() =>
    r'f033106aeb4457451c60c2c55de41f8da597f30d';

/// **In-memory only**, matching every other controller in this build (no
/// Drift wiring yet). The source always loads this array from the account
/// bundle (`bundle.notebooks` in `hooks/useNotes.ts`) — there's no local
/// equivalent to seed from, so this seeds the three notebooks
/// `sample_notes.dart` already references (`inbox`/`home`/`work`) with
/// preset palette colors, giving the Today dashboard's tiles and the future
/// Notebooks library (feature-audit #11) something real to show.

abstract class _$NotebooksController extends $Notifier<List<Notebook>> {
  List<Notebook> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Notebook>, List<Notebook>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Notebook>, List<Notebook>>,
              List<Notebook>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
