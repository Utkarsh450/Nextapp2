import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/notebooks/domain/notebooks_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('seeds Inbox/Home/Work, matching sample_notes.dart', () {
    final notebooks = container.read(notebooksControllerProvider);
    expect(notebooks.map((n) => n.id), ['inbox', 'home', 'work']);
  });

  test('addNotebook appends a new notebook', () {
    final notebook = container
        .read(notebooksControllerProvider.notifier)
        .addNotebook('Travel', '#D4C4E8');
    expect(notebook.name, 'Travel');
    expect(
      container.read(notebooksControllerProvider).map((n) => n.id),
      contains(notebook.id),
    );
  });

  test('renameNotebook updates the matching notebook only', () {
    container
        .read(notebooksControllerProvider.notifier)
        .renameNotebook('work', 'Job');
    final notebooks = container.read(notebooksControllerProvider);
    expect(notebooks.firstWhere((n) => n.id == 'work').name, 'Job');
    expect(notebooks.firstWhere((n) => n.id == 'home').name, 'Home');
  });

  test('recolorNotebook updates the matching notebook only', () {
    container
        .read(notebooksControllerProvider.notifier)
        .recolorNotebook('inbox', '#E7A3A3');
    final notebooks = container.read(notebooksControllerProvider);
    expect(notebooks.firstWhere((n) => n.id == 'inbox').color, '#E7A3A3');
  });
}
