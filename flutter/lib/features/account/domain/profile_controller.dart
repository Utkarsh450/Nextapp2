import 'package:notes_app/features/account/domain/user_profile.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'profile_controller.g.dart';

/// Direct port of the profile half of `hooks/useSession.ts`'s
/// `saveProfileForEmail`/`readStoredProfiles` (`lib/profile/index.ts`).
/// **In-memory only**, matching every other controller in this build — the
/// source persists this to `localStorage`.
@riverpod
class ProfileController extends _$ProfileController {
  @override
  Map<String, UserProfile> build() => {};

  UserProfile profileFor(String email) {
    final key = email.trim().toLowerCase();
    return state[key] ?? profileFromEmail(email);
  }

  void save(String email, UserProfile profile) {
    final key = email.trim().toLowerCase();
    state = {...state, key: profile};
  }
}
