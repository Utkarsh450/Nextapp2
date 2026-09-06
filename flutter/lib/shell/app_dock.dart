import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:notes_app/shell/add_action.dart';

const Color _ink = Color(0xFF2B261F);
const Color _barLight = Color(0xFF1A1814);
const Color _barDark = Color(0xFF0E0C0A);
const Color _pink = Color(0xFFE7A3A3);

/// One row of the dock's "Add…" menu — matches `ADD_ITEMS` in
/// `features/shell/AppTabs.tsx`. `SAVED_TONES`/saved-template rows have no
/// equivalent (see `add_action.dart`'s doc comment).
const List<(AddAction action, String label, Color tone, IconData icon)>
_addItems = [
  (AddAction.note, 'Note', Color(0xFFC5CA8A), Icons.edit_note),
  (AddAction.list, 'Checklist', Color(0xFFE7A3A3), Icons.checklist_outlined),
  (AddAction.daily, 'Daily log', Color(0xFFA9D4C4), Icons.wb_sunny_outlined),
  (AddAction.idea, 'Idea', Color(0xFFD4C4E8), Icons.lightbulb_outline),
  (AddAction.meeting, 'Meeting', Color(0xFFBEC3BC), Icons.groups_outlined),
  (
    AddAction.reminder,
    'Reminder',
    Color(0xFFE8C44A),
    Icons.notifications_outlined,
  ),
  (AddAction.capture, 'Quick capture', Color(0xFFE89569), Icons.mic_none),
];

const double _addRowHeight = 53.6;

/// `.app-add-list { max-height: min(18.5rem, 46dvh) }`.
double _addListMaxHeight(BuildContext context) =>
    math.min(296, MediaQuery.sizeOf(context).height * 0.46);

/// The sheet's total rendered height once open — title row + padding +
/// however much of the (possibly-scrollable) list is visible. Used to size
/// the dock's own box tall enough to keep the sheet hit-testable; see
/// `AppDock.build`'s doc comment.
double _addSheetHeight(BuildContext context) {
  final listHeight = math.min(
    _addItems.length * _addRowHeight,
    _addListMaxHeight(context),
  );
  // Padding (16.8 + 13.6) + title line + the gap below it.
  const chrome = 16.8 + 13.6 + 20.16 + 4;
  return listHeight + chrome;
}

/// The app's single custom-painted bottom dock — `docs/design-system.md`
/// §7 ("Navigation — bottom dock"), ported from `features/shell/AppTabs.tsx`.
/// A dark pill bar holds the four tabs split around an empty center slot; a
/// circular "bump" lifted above the bar's top edge holds the white + button,
/// which flips to pink and rotates 45° when the "Add…" menu is open. All
/// pixel values below are rem→px conversions (×16) from `app/globals.css`'s
/// `--dock-*` custom properties, matching the project-wide convention of
/// hardcoding source-exact geometry for bespoke, highly specific widgets
/// like this one rather than routing it through the generic spacing scale.
class const AppDock({
  required final int currentIndex,
  required final bool planAlert,
  required final bool open,
  required final ValueChanged<int> onTabTap,
  required final VoidCallback onPlusTap,
  required final VoidCallback onPlusHold,
  required final ValueChanged<AddAction> onPick,
  super.key,
}) extends StatelessWidget {
  static const double _barHeight = 67.2;
  static const double _bumpSize = 67.2;
  static const double _plusSize = 49.6;
  static const double _lift = 9.92;
  static const double _slotWidth = 72.8;

  static const List<(IconData filled, IconData outlined, String label)> _tabs =
      [
        (Icons.description, Icons.description_outlined, 'Notes'),
        (Icons.menu_book, Icons.menu_book_outlined, 'Books'),
        (Icons.calendar_today, Icons.calendar_today_outlined, 'Plan'),
        (Icons.person, Icons.person_outline, 'You'),
      ];

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final barColor = dark ? _barDark : _barLight;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final bottomPad = math.max(bottomInset, 7.2);
    // `.app-dock`'s own (closed) box height: padding-top (bump/2 - lift) +
    // bar height.
    const closedBoxHeight = _bumpSize / 2 - _lift + _barHeight;
    // `.app-add-wrap`'s `bottom: calc(var(--dock-bar) + 0.28rem)`.
    const sheetBottom = _barHeight + 4.48;
    // Unlike CSS's `position: absolute` (which paints outside its parent's
    // box without affecting layout), a Flutter `Positioned` child that
    // overflows its `Stack`'s own `size` still paints fine but stops being
    // hit-testable — `size.contains(position)` is checked on the ancestor
    // box before hit-testing ever reaches an overflowing descendant. So the
    // box has to actually grow to fit the open sheet, not just render past
    // its edge; the bar and bump stay `bottom`-anchored (not `top`-anchored)
    // so that growth only adds space *above* them, leaving their own
    // position unchanged.
    final boxHeight = open
        ? math.max(closedBoxHeight, sheetBottom + _addSheetHeight(context))
        : closedBoxHeight;

    return Padding(
      padding: EdgeInsets.fromLTRB(12, 0, 12, bottomPad),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 448),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                height: boxHeight,
                child: Stack(
                  children: [
                    if (open)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: sheetBottom,
                        child: _AddSheet(barColor: barColor, onPick: onPick),
                      ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: _barHeight,
                      child: _DockBar(
                        barColor: barColor,
                        currentIndex: currentIndex,
                        planAlert: planAlert,
                        onTabTap: onTabTap,
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: _barHeight - _lift,
                      height: _bumpSize,
                      child: Center(
                        child: _FabBump(
                          barColor: barColor,
                          open: open,
                          onTap: onPlusTap,
                          onHold: onPlusHold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10.4),
              Container(
                width: 134,
                height: 5,
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class const _DockBar({
  required final Color barColor,
  required final int currentIndex,
  required final bool planAlert,
  required final ValueChanged<int> onTabTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppDock._barHeight,
      decoration: BoxDecoration(
        color: barColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                for (var i = 0; i < 2; i++)
                  _TabItem(
                    index: i,
                    selected: currentIndex == i,
                    alert: i == 2 && planAlert,
                    onTap: () => onTabTap(i),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppDock._slotWidth),
          Expanded(
            child: Row(
              children: [
                for (var i = 2; i < 4; i++)
                  _TabItem(
                    index: i,
                    selected: currentIndex == i,
                    alert: i == 2 && planAlert,
                    onTap: () => onTabTap(i),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class const _TabItem({
  required final int index,
  required final bool selected,
  required final bool alert,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final (filled, outlined, label) = AppDock._tabs[index];
    final color = selected
        ? Colors.white
        : Colors.white.withValues(alpha: 0.55);
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            constraints: const BoxConstraints(minHeight: 48),
            alignment: Alignment.center,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(selected ? filled : outlined, size: 20, color: color),
                    if (alert)
                      Positioned(
                        right: -4,
                        top: -2,
                        child: Container(
                          key: const Key('plan-alert-dot'),
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: _pink,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10.88,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The dark circular "bump" the FAB grows out of, plus the white (pink when
/// open) + button itself. A manual 480ms press-and-hold timer — matching
/// the source's own `window.setTimeout(..., 480)` — bypasses the Add menu
/// and jumps straight to quick capture; releasing before that fires the
/// normal open/close toggle instead.
class const _FabBump({
  required final Color barColor,
  required final bool open,
  required final VoidCallback onTap,
  required final VoidCallback onHold,
}) extends StatefulWidget {
  @override
  State<_FabBump> createState() => _FabBumpState();
}

class _FabBumpState extends State<_FabBump> {
  Timer? _timer;
  bool _held = false;
  bool _pressed = false;

  void _startHoldTimer() {
    _held = false;
    _timer = Timer(const Duration(milliseconds: 480), () {
      _held = true;
      widget.onHold();
    });
  }

  void _cancelHoldTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelHoldTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppDock._bumpSize,
      height: AppDock._bumpSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: widget.barColor,
              shape: BoxShape.circle,
            ),
          ),
          GestureDetector(
            onTapDown: (_) {
              setState(() => _pressed = true);
              _startHoldTimer();
            },
            onTapUp: (_) {
              setState(() => _pressed = false);
              _cancelHoldTimer();
              if (_held) {
                _held = false;
                return;
              }
              if (!widget.open) unawaited(HapticFeedback.selectionClick());
              widget.onTap();
            },
            onTapCancel: () {
              setState(() => _pressed = false);
              _cancelHoldTimer();
            },
            child: AnimatedScale(
              scale: _pressed ? 0.92 : 1,
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: AppDock._plusSize,
                height: AppDock._plusSize,
                decoration: BoxDecoration(
                  color: widget.open ? _pink : Colors.white,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: AnimatedRotation(
                    turns: widget.open ? 0.125 : 0,
                    duration: const Duration(milliseconds: 320),
                    curve: Curves.easeOut,
                    child: const Icon(Icons.add, size: 22, color: _barLight),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The "Add…" sheet — `.app-add-sheet`'s radial-gradient mask, reproduced
/// as a `Path.combine` circular cutout at the bottom-center where the FAB
/// pokes through, so the sheet visually connects to the dock's bump.
class const _AddSheet({
  required final Color barColor,
  required final ValueChanged<AddAction> onPick,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final maxListHeight = _addListMaxHeight(context);
    return ClipPath(
      clipper: const _NotchedSheetClipper(),
      child: Container(
        color: barColor,
        padding: const EdgeInsets.fromLTRB(11.2, 16.8, 11.2, 13.6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Add...',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.8,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.34,
              ),
            ),
            const SizedBox(height: 4),
            ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxListHeight),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    for (final (action, label, tone, icon) in _addItems)
                      _AddRow(
                        label: label,
                        tone: tone,
                        icon: icon,
                        onTap: () => onPick(action),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class const _AddRow({
  required final String label,
  required final Color tone,
  required final IconData icon,
  required final VoidCallback onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: Colors.white.withValues(alpha: 0.1),
        child: Container(
          constraints: const BoxConstraints(minHeight: 53.6),
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle),
                child: Icon(icon, size: 18, color: _ink),
              ),
              const SizedBox(width: 14),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16.32,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.32,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `--add-notch: calc(var(--dock-plus) / 2 + 0.38rem)` (30.88px radius),
/// centered at `50% calc(100% + var(--dock-lift) + 0.28rem)` — 14.4px below
/// the sheet's own bottom edge, so only the notch's shallow upper cap bites
/// into the sheet.
class const _NotchedSheetClipper() extends CustomClipper<Path> {
  static const double _notchRadius = 30.88;
  static const double _notchOffsetBelowBottom = 14.4;

  @override
  Path getClip(Size size) {
    final sheetPath = Path()
      ..addRRect(
        RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(28)),
      );
    final notchPath = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, size.height + _notchOffsetBelowBottom),
          radius: _notchRadius,
        ),
      );
    return Path.combine(PathOperation.difference, sheetPath, notchPath);
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
