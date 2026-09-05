import 'package:flutter/material.dart';
import 'package:notes_app/core/theme/tokens/app_motion.dart';

/// Port of `components/ui/IconButton.tsx` — a 44×44 circular tap target
/// with `active:scale-95` press feedback. Per `docs/design-system.md` §7,
/// this is "the one button variant with a fully specified interaction
/// triad" and the reference for pressed-states elsewhere in the app.
class const PaperIconButton({
  required final String label,
  required final Widget child,
  required final VoidCallback? onPressed,
  super.key,
}) extends StatefulWidget {
  @override
  State<PaperIconButton> createState() => _PaperIconButtonState();
}

class _PaperIconButtonState extends State<PaperIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final motion = theme.extension<AppMotion>()!;
    final overlay = theme.brightness == Brightness.dark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.black.withValues(alpha: 0.05);

    return Semantics(
      button: true,
      label: widget.label,
      child: GestureDetector(
        onTapDown: widget.onPressed == null
            ? null
            : (_) => setState(() => _pressed = true),
        onTapCancel: () => setState(() => _pressed = false),
        onTapUp: (_) => setState(() => _pressed = false),
        onTap: widget.onPressed,
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1,
          duration: motion.press,
          curve: motion.easeOut,
          child: Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _pressed ? overlay : Colors.transparent,
            ),
            child: IconTheme(
              data: IconThemeData(color: theme.colorScheme.onSurface),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
  }
}
