import 'package:go_router/go_router.dart';
import 'package:notes_app/core/widgets/placeholder_screen.dart';
import 'package:notes_app/features/notes/presentation/note_editor_screen.dart';
import 'package:notes_app/features/notes/presentation/notes_list_screen.dart';
import 'package:notes_app/features/plan/presentation/plan_screen.dart';
import 'package:notes_app/shell/app_shell.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_router.g.dart';

/// Route table — mapped 1:1 to the screens enumerated in
/// `docs/feature-audit.md` §1, per `docs/flutter-architecture.md` §3.
///
/// **Scaffold-stage placeholder:** every branch except `/notes`,
/// `/notes/:id/edit`, and `/plan` still renders [PlaceholderScreen] until
/// its real screen is built — `/notes/:id` (the read-only `NoteDetail`
/// view) is still a placeholder, so note cards open straight into the
/// editor for now; see `note_editor_screen.dart`'s doc comment. The
/// `/auth` → `/onboarding` → shell
/// redirect guard (session-null / not-onboarded, mirroring the branch order
/// in `NotesApp.tsx`) is **not yet wired** — it depends on the real
/// `SessionNotifier`, which is built alongside the auth screen. Per the
/// porting brief, screen order starts with the notes/habit core flow, not
/// auth, so the app opens straight into the shell for now; the guard is
/// added in `redirect` here without touching this file's route shape once
/// that notifier exists.
final GoRouter _router = GoRouter(
  initialLocation: '/notes',
  routes: [
    GoRoute(
      path: '/auth',
      builder: (context, state) => const PlaceholderScreen(title: 'Auth'),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) =>
          const PlaceholderScreen(title: 'Onboarding'),
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
                  builder: (context, state) => PlaceholderScreen(
                    title: 'Note ${state.pathParameters['id']}',
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
              builder: (context, state) =>
                  const PlaceholderScreen(title: 'Notebooks'),
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

@riverpod
GoRouter appRouter(Ref ref) => _router;
