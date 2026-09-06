// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'habits_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Holds the habit list. **In-memory only**, per the "no backend/DB for
/// now" instruction — and, unlike `NotesController`, starts genuinely
/// empty rather than from placeholder demo data: the source has no habit
/// equivalent of `lib/notes/seed.ts`, so an empty list *is* what a fresh
/// account looks like (the suggested-habit chips exist for exactly this
/// state — see `habits_board.dart`).

@ProviderFor(HabitsController)
final habitsControllerProvider = HabitsControllerProvider._();

/// Holds the habit list. **In-memory only**, per the "no backend/DB for
/// now" instruction — and, unlike `NotesController`, starts genuinely
/// empty rather than from placeholder demo data: the source has no habit
/// equivalent of `lib/notes/seed.ts`, so an empty list *is* what a fresh
/// account looks like (the suggested-habit chips exist for exactly this
/// state — see `habits_board.dart`).
final class HabitsControllerProvider
    extends $NotifierProvider<HabitsController, List<Habit>> {
  /// Holds the habit list. **In-memory only**, per the "no backend/DB for
  /// now" instruction — and, unlike `NotesController`, starts genuinely
  /// empty rather than from placeholder demo data: the source has no habit
  /// equivalent of `lib/notes/seed.ts`, so an empty list *is* what a fresh
  /// account looks like (the suggested-habit chips exist for exactly this
  /// state — see `habits_board.dart`).
  HabitsControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitsControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitsControllerHash();

  @$internal
  @override
  HabitsController create() => HabitsController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<Habit> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<Habit>>(value),
    );
  }
}

String _$habitsControllerHash() => r'0448364618049549675eb7a289d806a278b3a910';

/// Holds the habit list. **In-memory only**, per the "no backend/DB for
/// now" instruction — and, unlike `NotesController`, starts genuinely
/// empty rather than from placeholder demo data: the source has no habit
/// equivalent of `lib/notes/seed.ts`, so an empty list *is* what a fresh
/// account looks like (the suggested-habit chips exist for exactly this
/// state — see `habits_board.dart`).

abstract class _$HabitsController extends $Notifier<List<Habit>> {
  List<Habit> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<Habit>, List<Habit>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<Habit>, List<Habit>>,
              List<Habit>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Holds every habit check-in. Split from [HabitsController] the same way
/// the source splits `habits`/`checks` in `useHabits.ts`.

@ProviderFor(HabitChecksController)
final habitChecksControllerProvider = HabitChecksControllerProvider._();

/// Holds every habit check-in. Split from [HabitsController] the same way
/// the source splits `habits`/`checks` in `useHabits.ts`.
final class HabitChecksControllerProvider
    extends $NotifierProvider<HabitChecksController, List<HabitCheck>> {
  /// Holds every habit check-in. Split from [HabitsController] the same way
  /// the source splits `habits`/`checks` in `useHabits.ts`.
  HabitChecksControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'habitChecksControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$habitChecksControllerHash();

  @$internal
  @override
  HabitChecksController create() => HabitChecksController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<HabitCheck> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<HabitCheck>>(value),
    );
  }
}

String _$habitChecksControllerHash() =>
    r'afab7f7cd6844e9fe001450ac3554aefec8ea2fc';

/// Holds every habit check-in. Split from [HabitsController] the same way
/// the source splits `habits`/`checks` in `useHabits.ts`.

abstract class _$HabitChecksController extends $Notifier<List<HabitCheck>> {
  List<HabitCheck> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<List<HabitCheck>, List<HabitCheck>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<HabitCheck>, List<HabitCheck>>,
              List<HabitCheck>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
