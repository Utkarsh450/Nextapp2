import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/core/widgets/placeholder_screen.dart';
import 'package:notes_app/features/auth/domain/onboarding_controller.dart';
import 'package:notes_app/features/auth/domain/session_controller.dart';
import 'package:notes_app/features/auth/presentation/auth_screen.dart';
import 'package:notes_app/features/auth/presentation/onboarding_screen.dart';
import 'package:notes_app/features/notebooks/presentation/notebooks_screen.dart';
import 'package:notes_app/features/notes/presentation/note_detail_screen.dart';
import 'package:notes_app/features/notes/presentation/note_editor_screen.dart';
import 'package:notes_app/features/notes/presentation/notes_list_screen.dart';
import 'package:notes_app/features/plan/presentation/plan_screen.dart';
import 'package:notes_app/shell/app_shell.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Ticks [GoRouter]'s `redirect` re-evaluation whenever session/onboarding
/// state changes, without rebuilding the [GoRouter] instance itself (which
/// would remount the whole navigator tree) — the idiomatic bridge between
/// Riverpod state and go_router's `refreshListenable`.
class _RouterRefreshNotifier extends ChangeNotifier {
  // A primary constructor can't run the `ref.listen` body this needs, so
  // this stays a manual constructor.
  // ignore: unnecessary_type_name_in_constructor
  _RouterRefreshNotifier(Ref ref) {
    ref
      ..listen(sessionControllerProvider, (_, _) => notifyListeners())
      ..listen(onboardingControllerProvider, (_, _) => notifyListeners());
  }
}

/// Route table — mapped 1:1 to the screens enumerated in
/// `docs/feature-audit.md` §1, per `docs/flutter-architecture.md` §3.
///
/// The `/auth` → `/onboarding` → shell redirect guard mirrors the branch
/// order in `NotesApp.tsx` (renders `AuthScreen` when there's no session,
/// `OnboardingScreen` when there's a session but onboarding isn't done).
/// One deliberate simplification:
/// the source also has a `loading` branch while its session check makes a
/// network round-trip — there's no backend here to await (session state is
/// synchronous in-memory Riverpod state, per the "no backend/DB for now"
/// instruction), so that branch has nothing to wait for and is skipped.
///
/// **Scaffold-stage placeholder:** `/notes/search` and `/you` still render
/// [PlaceholderScreen] until their real screens are built.
@riverpod
GoRouter appRouter(Ref ref) {
  final refresh = _RouterRefreshNotifier(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/notes',
    refreshListenable: refresh,
    redirect: (context, state) {
      final session = ref.read(sessionControllerProvider);
      final loc = state.matchedLocation;
      if (session == null) {
        return loc == '/auth' ? null : '/auth';
      }
      final onboarded = ref
          .read(onboardingControllerProvider.notifier)
          .isDone(session.email);
      if (!onboarded) {
        return loc == '/onboarding' ? null : '/onboarding';
      }
      if (loc == '/auth' || loc == '/onboarding') return '/notes';
      return null;
    },
    routes: [
      GoRoute(path: '/auth', builder: (context, state) => const AuthScreen()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/privacy',
        builder: (context, state) =>
            const PlaceholderScreen(title: 'Privacy policy'),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notes',
                builder: (context, state) => const NotesListScreen(),
                routes: [
                  GoRoute(
                    path: 'search',
                    builder: (context, state) =>
                        const PlaceholderScreen(title: 'Search'),
                  ),
                  GoRoute(
                    path: ':id',
                    builder: (context, state) => NoteDetailScreen(
                      noteId: int.parse(state.pathParameters['id']!),
                    ),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) => NoteEditorScreen(
                          noteId: int.parse(state.pathParameters['id']!),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/notebooks',
                builder: (context, state) => const NotebooksScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/plan',
                builder: (context, state) => const PlanScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                builder: (context, state) =>
                    const PlaceholderScreen(title: 'You'),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}
