import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Port of `components/ui/OtpBoxes.tsx` — six single-digit boxes acting on
/// one 6-character [value] string: typing a digit advances focus, an empty
/// box's backspace moves back a box and trims [value], and a multi-digit
/// paste into any box fills the whole code at once.
class const OtpBoxes({
  required final String value,
  required final ValueChanged<String> onChange,
  super.key,
}) extends StatefulWidget {
  @override
  State<OtpBoxes> createState() => _OtpBoxesState();
}

class _OtpBoxesState extends State<OtpBoxes> {
  final List<FocusNode> _nodes = List.generate(6, (_) => FocusNode());
  late List<TextEditingController> _controllers;

  static String _digitAt(String value, int index) =>
      index < value.length ? value[index] : '';

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      6,
      (i) => TextEditingController(text: _digitAt(widget.value, i)),
    );
  }

  @override
  void didUpdateWidget(covariant OtpBoxes oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value == widget.value) return;
    for (var i = 0; i < 6; i++) {
      final digit = _digitAt(widget.value, i);
      if (_controllers[i].text != digit) {
        _controllers[i].value = TextEditingValue(
          text: digit,
          selection: TextSelection.collapsed(offset: digit.length),
        );
      }
    }
    if (widget.value.length < 6) {
      _nodes[widget.value.length].requestFocus();
    }
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _handleChanged(int index, String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.length > 1) {
      widget.onChange(digits.substring(0, digits.length.clamp(0, 6)));
      return;
    }
    final chars = List<String>.generate(6, (i) => _digitAt(widget.value, i));
    chars[index] = digits;
    widget.onChange(chars.join());
    if (digits.isNotEmpty && index < 5) _nodes[index + 1].requestFocus();
  }

  KeyEventResult _handleKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _digitAt(widget.value, index).isEmpty &&
        index > 0) {
      _nodes[index - 1].requestFocus();
      widget.onChange(
        widget.value.substring(0, (index - 1).clamp(0, widget.value.length)),
      );
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < 6; i++)
          SizedBox(
            width: 44,
            height: 56,
            child: Focus(
              onKeyEvent: (node, event) => _handleKey(i, event),
              child: TextField(
                controller: _controllers[i],
                focusNode: _nodes[i],
                autofocus: i == 0,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                // The first box accepts up to 6 characters so a paste (or
                // SMS autofill) landing there — the common case, since it's
                // the one that's focused first — reaches `_handleChanged`
                // whole; a `TextField` with `maxLength: 1` would silently
                // truncate a paste before `onChanged` ever saw more than
                // one character, unlike the source's dedicated `onPaste`.
                maxLength: i == 0 ? 6 : 1,
                style: theme.textTheme.titleLarge?.copyWith(
                  color: const Color(0xFF2B261F),
                ),
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (raw) => _handleChanged(i, raw),
              ),
            ),
          ),
      ],
    );
  }
}
