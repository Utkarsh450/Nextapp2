import 'package:flutter/material.dart';

/// Port of `components/ui/PaperStage.tsx` — a full-bleed paper-colored
/// backdrop for a screen.
///
/// **Not ported:** the `AuthStickers`/`OnboardStickers` decorative doodles
/// (`components/ui/PaperStickers.tsx` isn't built yet, same call-out as
/// elsewhere in this port).
class const PaperStage({required final Widget child, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // A [Material] (not just a [ColoredBox]) — screens built on top of
    // this need a Material ancestor for their form fields/buttons, the
    // same way a [Scaffold] would normally provide one.
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: child,
    );
  }
}
