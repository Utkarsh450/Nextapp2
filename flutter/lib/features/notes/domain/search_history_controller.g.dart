// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Direct port of `rememberSearch` (`lib/notes/storage.ts`) — moves a
/// query to the front of the recents list, de-duplicating, capped at
/// [searchRecentsLimit]. **In-memory only**, matching every other
/// controller in this build; the source persists this to a `Prefs` row.

@ProviderFor(SearchHistoryController)
final searchHistoryControllerProvider = SearchHistoryControllerProvider._();

/// Direct port of `rememberSearch` (`lib/notes/storage.ts`) — moves a
/// query to the front of the recents list, de-duplicating, capped at
/// [searchRecentsLimit]. **In-memory only**, matching every other
/// controller in this build; the source persists this to a `Prefs` row.
final class SearchHistoryControllerProvider
    extends $NotifierProvider<SearchHistoryController, List<String>> {
  /// Direct port of `rememberSearch` (`lib/notes/storage.ts`) — moves a
  /// query to the front of the recents list, de-duplicating, capped at
  /// [searchRecentsLimit]. **In-memory only**, matching every other
  /// controller in this build; the source persists this to a `Prefs` row.
  SearchHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'searchHistoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$searchHistoryControllerHash();

  @$internal
  @override
  SearchHistoryController create() => SearchHistoryController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<String> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<String>>(value),
    );
  }
}

String _$searchHistoryControllerHash() =>
    r'716915bc29987cfcc271acf321388cfa1d214512';

/// Direct port of `rememberSearch` (`lib/notes/storage.ts`) — moves a
/// query to the front of the recents list, de-duplicating, capped at
/// [searchRecentsLimit]. **In-memory only**, matching every other
/// controller in this build; the source persists this to a `Prefs` row.

abstract class _$SearchHistoryController extends $Notifier<List<String>> {
  List<String> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<String>, List<String>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<String>, List<String>>,
              List<String>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
