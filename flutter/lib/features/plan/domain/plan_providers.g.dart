// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'plan_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// `agenda` in `NotesApp.tsx` — recomputed only when the notes it depends
/// on change.

@ProviderFor(planAgenda)
final planAgendaProvider = PlanAgendaProvider._();

/// `agenda` in `NotesApp.tsx` — recomputed only when the notes it depends
/// on change.

final class PlanAgendaProvider
    extends $FunctionalProvider<NoteAgenda, NoteAgenda, NoteAgenda>
    with $Provider<NoteAgenda> {
  /// `agenda` in `NotesApp.tsx` — recomputed only when the notes it depends
  /// on change.
  PlanAgendaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planAgendaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planAgendaHash();

  @$internal
  @override
  $ProviderElement<NoteAgenda> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  NoteAgenda create(Ref ref) {
    return planAgenda(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NoteAgenda value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NoteAgenda>(value),
    );
  }
}

String _$planAgendaHash() => r'c8d99533af600cab792f6a77c3fb804adf08b4a1';
