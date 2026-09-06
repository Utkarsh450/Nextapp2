import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';

void main() {
  late ProviderContainer container;

  setUp(() => container = ProviderContainer());
  tearDown(() => container.dispose());

  test('starts with no session', () {
    expect(container.read(sessionControllerProvider), isNull);
  });

  test('sendOtp rejects an invalid email without generating a code', () {
    final outcome = container
        .read(sessionControllerProvider.notifier)
        .sendOtp('not-an-email');
    expect(outcome.result.ok, isFalse);
    expect(outcome.code, isNull);
  });

  test('verifyOtp with the right code signs in and sets the session', () {
    final notifier = container.read(sessionControllerProvider.notifier);
    final outcome = notifier.sendOtp('ada@example.com');
    expect(outcome.result.ok, isTrue);
    final code = outcome.code!;

    final result = notifier.verifyOtp('ada@example.com', code);
    expect(result.ok, isTrue);
    expect(result.session?.email, 'ada@example.com');
    expect(result.session?.name, 'Ada');
    expect(container.read(sessionControllerProvider)?.email, 'ada@example.com');
  });

  test('verifyOtp with the wrong code fails without signing in', () {
    final notifier = container.read(sessionControllerProvider.notifier);
    final outcome = notifier.sendOtp('ada@example.com');
    final wrong = outcome.code == '111111' ? '222222' : '111111';

    final result = notifier.verifyOtp('ada@example.com', wrong);
    expect(result.ok, isFalse);
    expect(result.error, 'That code is incorrect');
    expect(container.read(sessionControllerProvider), isNull);
  });

  test('verifyOtp with no pending code (never sent) fails as expired', () {
    final notifier = container.read(sessionControllerProvider.notifier);
    final result = notifier.verifyOtp('nobody@example.com', '123456');
    expect(result.ok, isFalse);
    expect(result.error, 'Code expired. Request a new one.');
  });

  test('verifyOtp rejects a non-6-digit code before checking it', () {
    final notifier = container.read(sessionControllerProvider.notifier)
      ..sendOtp('ada@example.com');
    final result = notifier.verifyOtp('ada@example.com', '123');
    expect(result.ok, isFalse);
    expect(result.error, 'Enter the 6-digit code');
  });

  test('locks out after 5 wrong attempts', () {
    final notifier = container.read(sessionControllerProvider.notifier);
    final outcome = notifier.sendOtp('ada@example.com');
    final wrong = outcome.code == '111111' ? '222222' : '111111';

    for (var i = 0; i < 5; i++) {
      notifier.verifyOtp('ada@example.com', wrong);
    }
    final result = notifier.verifyOtp('ada@example.com', outcome.code!);
    expect(result.ok, isFalse);
    expect(result.error, 'Too many attempts. Request a new code.');
  });

  test('logout clears the session', () {
    final notifier = container.read(sessionControllerProvider.notifier);
    final outcome = notifier.sendOtp('ada@example.com');
    notifier.verifyOtp('ada@example.com', outcome.code!);
    expect(container.read(sessionControllerProvider), isNotNull);

    notifier.logout();
    expect(container.read(sessionControllerProvider), isNull);
  });
}
