import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Port of `components/ui/PaytmTick.tsx` — the fully animated "mark done"
/// checkmark that existed in the source but was never wired to any screen.
/// Per `docs/feature-audit.md`, the Flutter port makes this a real, tappable
/// gesture (on `NoteCard` for now; `NoteDetail` later).
///
/// Timings are transcribed from `app/globals.css`'s `paytm-*` keyframes:
/// circle pop 500ms (`0%→60%→80%→100%` scale `0→1.12→0.96→1`), two ripple
/// rings 1100ms each (`scale 0.85→2.15`, `opacity .45→0`) with the second
/// delayed 180ms, and a checkmark stroke-draw 350ms starting 280ms in. The
/// source's own `setTimeout` window (1200ms) is used as the single
/// controller duration — it already truncates the second ripple slightly
/// short of its full 1100ms, which this reproduces rather than "fixes".
class const PaytmTick({
  required final bool active,
  required final VoidCallback onToggle,
  super.key,
}) extends StatefulWidget {
  @override
  State<PaytmTick> createState() => _PaytmTickState();
}

class _PaytmTickState extends State<PaytmTick>
    with SingleTickerProviderStateMixin {
  static const _totalMs = 1200;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: _totalMs),
  )..value = widget.active ? 1 : 0;

  late final Animation<double> _circleScale =
      TweenSequence<double>([
        TweenSequenceItem(tween: Tween(begin: 0, end: 1.12), weight: 60),
        TweenSequenceItem(tween: Tween(begin: 1.12, end: 0.96), weight: 20),
        TweenSequenceItem(tween: Tween(begin: 0.96, end: 1), weight: 20),
      ]).animate(
        CurvedAnimation(
          parent: _controller,
          curve: const Interval(0, 500 / _totalMs),
        ),
      );

  late final Animation<double> _ripple1 = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 1100 / _totalMs, curve: Curves.easeOut),
  );
  late final Animation<double> _ripple2 = CurvedAnimation(
    parent: _controller,
    curve: const Interval(180 / _totalMs, 1, curve: Curves.easeOut),
  );
  late final Animation<double> _checkDraw = CurvedAnimation(
    parent: _controller,
    curve: const Interval(
      280 / _totalMs,
      630 / _totalMs,
      curve: Curves.easeOut,
    ),
  );

  @override
  void didUpdateWidget(PaytmTick oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!oldWidget.active && widget.active) {
      unawaited(HapticFeedback.selectionClick());
      _controller.forward(from: 0);
    } else if (oldWidget.active && !widget.active) {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onToggle();
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.active ? 'Mark as open' : 'Mark as done',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _handleTap,
        child: SizedBox(
          width: 22,
          height: 22,
          child: widget.active
              ? _buildActive(context)
              : _buildInactive(context),
        ),
      ),
    );
  }

  Widget _buildInactive(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.7),
        border: Border.all(
          color: const Color(0xFFD4D4D8).withValues(alpha: 0.8), // zinc-300/80
        ),
      ),
      child: const Center(
        child: Icon(Icons.check, size: 12, color: Colors.grey),
      ),
    );
  }

  Widget _buildActive(BuildContext context) {
    final accent = Theme.of(context).colorScheme.secondary;
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            _ripple(accent, _ripple1),
            _ripple(accent, _ripple2),
            Transform.scale(
              scale: _circleScale.value,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent,
                  boxShadow: [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.45),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: CustomPaint(
                    size: const Size(14, 14),
                    painter: _CheckPainter(progress: _checkDraw.value),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _ripple(Color accent, Animation<double> anim) {
    // scale 0.85 -> 2.15, opacity 0.45 -> 0, over the animation's own range.
    final scale = 0.85 + anim.value * (2.15 - 0.85);
    final opacity = 0.45 * (1 - anim.value);
    return Opacity(
      opacity: opacity.clamp(0, 1),
      child: Transform.scale(
        scale: scale,
        child: DecoratedBox(
          decoration: BoxDecoration(shape: BoxShape.circle, color: accent),
          child: const SizedBox(width: 22, height: 22),
        ),
      ),
    );
  }
}

/// Draws the checkmark path (`M14,27.5 L22.5,36 L38.5,18` in a 52×52
/// viewBox) partially, per [progress] — Flutter's answer to the source's
/// `stroke-dasharray`/`stroke-dashoffset` draw-in.
class const _CheckPainter({required final double progress})
    extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 52;
    final path = Path()
      ..moveTo(14 * scale, 27.5 * scale)
      ..lineTo(22.5 * scale, 36 * scale)
      ..lineTo(38.5 * scale, 18 * scale);

    final metric = path.computeMetrics().first;
    final extracted = metric.extractPath(
      0,
      metric.length * progress.clamp(0, 1),
    );

    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5 * scale
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(extracted, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
