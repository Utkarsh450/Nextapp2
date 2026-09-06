import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'search_history_controller.g.dart';

/// Matches `SEARCH_RECENTS_LIMIT` (`lib/notes/storage.ts`).
const int searchRecentsLimit = 8;

/// Direct port of `rememberSearch` (`lib/notes/storage.ts`) — moves a
/// query to the front of the recents list, de-duplicating, capped at
/// [searchRecentsLimit]. **In-memory only**, matching every other
/// controller in this build; the source persists this to a `Prefs` row.
@riverpod
class SearchHistoryController extends _$SearchHistoryController {
  @override
  List<String> build() => const [];

  void remember(String query) {
    final next = [query, ...state.where((item) => item != query)];
    state = next.take(searchRecentsLimit).toList();
  }
}
