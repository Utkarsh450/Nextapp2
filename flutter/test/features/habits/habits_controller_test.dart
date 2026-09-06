import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/habits/domain/habits_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('starts empty — no seed data, matching the source', () {
    expect(container.read(habitsControllerProvider), isEmpty);
    expect(container.read(habitChecksControllerProvider), isEmpty);
  });

  test('addHabit appends a new habit', () {
    final habit = container
        .read(habitsControllerProvider.notifier)
        .addHabit('Stretch', color: '#C5CA8A');
    expect(container.read(habitsControllerProvider), [habit]);
    expect(habit.name, 'Stretch');
    expect(habit.color, '#C5CA8A');
  });

  test('toggleCheck adds then removes a check-in', () {
    final habit = container
        .read(habitsControllerProvider.notifier)
        .addHabit('Read');
    final checksNotifier = container.read(
      habitChecksControllerProvider.notifier,
    )..toggleCheck(habit.id, '2024-01-10');
    expect(container.read(habitChecksControllerProvider), hasLength(1));

    checksNotifier.toggleCheck(habit.id, '2024-01-10');
    expect(container.read(habitChecksControllerProvider), isEmpty);
  });

  test("removeHabit also clears that habit's check-ins", () {
    final habitsNotifier = container.read(habitsControllerProvider.notifier);
    final a = habitsNotifier.addHabit('Write');
    final b = habitsNotifier.addHabit('Move');
    container.read(habitChecksControllerProvider.notifier)
      ..toggleCheck(a.id, '2024-01-10')
      ..toggleCheck(b.id, '2024-01-10');

    habitsNotifier.removeHabit(a.id);

    expect(
      container.read(habitsControllerProvider).map((h) => h.id),
      [b.id],
    );
    final remaining = container.read(habitChecksControllerProvider);
    expect(remaining, hasLength(1));
    expect(remaining.first.habitId, b.id);
  });
}
