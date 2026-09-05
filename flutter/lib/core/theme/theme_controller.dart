import 'package:notes_app/core/theme/paper_skin.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_controller.g.dart';

/// Holds the active [PaperSkin].
///
/// **Scaffold-stage placeholder:** defaults to [PaperSkin.classic] every
/// launch. Theme *mode* (light/dark) already follows the system setting via
/// `MaterialApp.themeMode` in `app.dart`, matching the source's behavior.
/// Persisting the user's skin/theme/layout choice to the `Prefs` table
/// (mirroring `lib/theme.ts`'s three `localStorage` keys) is real Account
/// (#14) screen work and lands with that screen, not before — see
/// `docs/flutter-architecture.md` §6.
@riverpod
class SkinController extends _$SkinController {
  @override
  PaperSkin build() => PaperSkin.classic;

  // A setter would read as `notifier.skin = x`, which hides that this is a
  // Riverpod state mutation rather than a plain property write — an action
  // method is the idiomatic Notifier API shape.
  // ignore: use_setters_to_change_properties
  void setSkin(PaperSkin skin) => state = skin;
}
