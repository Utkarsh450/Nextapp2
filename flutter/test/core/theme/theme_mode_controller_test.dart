import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notes_app/core/theme/theme_mode_controller.dart';

void main() {
  test('defaults to light, matching the source app', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(themeModeControllerProvider), ThemeMode.light);
  });

  test('toggle flips between light and dark', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(themeModeControllerProvider.notifier)
      ..toggle();
    expect(container.read(themeModeControllerProvider), ThemeMode.dark);

    notifier.toggle();
    expect(container.read(themeModeControllerProvider), ThemeMode.light);
  });
}
