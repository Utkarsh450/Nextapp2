import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'onboarding_controller.g.dart';

/// Direct port of `lib/onboarding.ts` — which emails have finished the
/// onboarding flow. **In-memory only**, matching every other controller in
/// this build: the source persists this to `localStorage`, so (like
/// session state) it resets on every app restart here instead of a Drift
/// table — there's no equivalent of "already onboarded" surviving a real
/// app restart yet.
@riverpod
class OnboardingController extends _$OnboardingController {
  @override
  Set<String> build() => {};

  bool isDone(String email) => state.contains(email.trim().toLowerCase());

  void markDone(String email) {
    state = {...state, email.trim().toLowerCase()};
  }
}
