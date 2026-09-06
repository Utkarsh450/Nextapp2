import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notes/domain/search_history_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('starts empty', () {
    expect(container.read(searchHistoryControllerProvider), isEmpty);
  });

  test('remembers a query at the front', () {
    container.read(searchHistoryControllerProvider.notifier)
      ..remember('milk')
      ..remember('eggs');
    expect(container.read(searchHistoryControllerProvider), ['eggs', 'milk']);
  });

  test('re-remembering an existing query moves it to the front', () {
    container.read(searchHistoryControllerProvider.notifier)
      ..remember('milk')
      ..remember('eggs')
      ..remember('milk');
    expect(container.read(searchHistoryControllerProvider), ['milk', 'eggs']);
  });

  test('caps at searchRecentsLimit entries', () {
    final notifier = container.read(searchHistoryControllerProvider.notifier);
    for (var i = 0; i < searchRecentsLimit + 3; i++) {
      notifier.remember('query$i');
    }
    final recents = container.read(searchHistoryControllerProvider);
    expect(recents, hasLength(searchRecentsLimit));
    expect(recents.first, 'query${searchRecentsLimit + 2}');
  });
}
