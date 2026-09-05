import 'package:flutter/material.dart';

/// Temporary stand-in for a not-yet-built screen.
///
/// Used only while routing is scaffolded ahead of the screens themselves
/// (per the porting brief's "theming and routing first" instruction). Every
/// route this backs gets replaced by its real screen during Phase 4,
/// screen-by-screen — this widget should shrink to zero usages over time,
/// not grow.
class const PlaceholderScreen({required final String title, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Center(
        child: Text(
          '$title — not built yet',
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
