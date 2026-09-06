import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/auth/domain/onboarding_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('no one starts onboarded', () {
    final notifier = container.read(onboardingControllerProvider.notifier);
    expect(notifier.isDone('ada@example.com'), isFalse);
  });

  test('markDone is per-email and case/whitespace-insensitive', () {
    final notifier = container.read(onboardingControllerProvider.notifier)
      ..markDone(' Ada@Example.com ');

    expect(notifier.isDone('ada@example.com'), isTrue);
    expect(notifier.isDone('someone-else@example.com'), isFalse);
  });

  test('marking the same email done twice is a no-op', () {
    container.read(onboardingControllerProvider.notifier)
      ..markDone('ada@example.com')
      ..markDone('ada@example.com');
    expect(container.read(onboardingControllerProvider), hasLength(1));
  });
}
