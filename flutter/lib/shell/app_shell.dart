import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:notes_app/features/notes/domain/note_dates.dart';
import 'package:notes_app/features/notes/domain/note_templates.dart';
import 'package:notes_app/features/notes/domain/notes_controller.dart';
import 'package:notes_app/features/notes/presentation/create_sheet.dart';
import 'package:notes_app/features/plan/domain/plan_providers.dart';
import 'package:notes_app/shell/add_action.dart';
import 'package:notes_app/shell/app_dock.dart';

/// Wraps the four dock tabs (Notes, Notebooks, Plan, You) in one
/// [StatefulNavigationShell] so each branch keeps its own navigation stack
/// and scroll position, and owns the custom bottom dock's local
/// open/closed state — matching `AppTabs.tsx`'s own `useState` for its Add
/// menu (`docs/flutter-architecture.md` §3, `docs/design-system.md` §7).
class const AppShell({
  required final StatefulNavigationShell navigationShell,
  super.key,
}) extends ConsumerStatefulWidget {
  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  bool _open = false;

  void _toggleMenu() => setState(() => _open = !_open);

  void _closeMenu() {
    if (_open) setState(() => _open = false);
  }

  void _onTabTap(int index) {
    _closeMenu();
    widget.navigationShell.goBranch(
      index,
      initialLocation: index == widget.navigationShell.currentIndex,
    );
  }

  void _openQuickCapture() {
    _closeMenu();
    unawaited(showCreateSheet(context));
  }

  /// Matches `handleAdd` in `features/notes/NotesApp.tsx`.
  void _onPick(AddAction action) {
    _closeMenu();
    if (action == AddAction.capture) {
      unawaited(showCreateSheet(context));
      return;
    }
    final controller = ref.read(notesControllerProvider.notifier);
    final note = switch (action) {
      AddAction.note => controller.createBlank(),
      AddAction.list => controller.createBlank(body: '- [ ] \n- [ ] \n- [ ] '),
      AddAction.daily => controller.openDailyNote(),
      AddAction.idea => controller.createFromTemplate(TemplateKey.idea),
      AddAction.meeting => controller.createFromTemplate(TemplateKey.meeting),
      AddAction.reminder => controller.createBlank(dueAt: todayIso()),
      AddAction.capture => throw StateError('handled above'),
    };
    unawaited(context.push('/notes/${note.id}/edit'));
  }

  @override
  Widget build(BuildContext context) {
    final agenda = ref.watch(planAgendaProvider);
    final planAlert = agenda.overdue.isNotEmpty || agenda.dueToday.isNotEmpty;

    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(child: widget.navigationShell),
          if (_open)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closeMenu,
                child: AnimatedOpacity(
                  opacity: 1,
                  duration: const Duration(milliseconds: 220),
                  child: Container(color: const Color(0x6B1A1814)),
                ),
              ),
            ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: AppDock(
              currentIndex: widget.navigationShell.currentIndex,
              planAlert: planAlert,
              open: _open,
              onTabTap: _onTabTap,
              onPlusTap: _toggleMenu,
              onPlusHold: _openQuickCapture,
              onPick: _onPick,
            ),
          ),
        ],
      ),
    );
  }
}
