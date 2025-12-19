import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HoverTextButton extends StatefulWidget {
  final VoidCallback onPressed;
  final String text;

  const HoverTextButton(
      {super.key, required this.onPressed, required this.text});

  @override
  State<HoverTextButton> createState() => _HoverTextButtonState();
}

class _HoverTextButtonState extends State<HoverTextButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: TextButton(
        onPressed: widget.onPressed,
        child: AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 200),
          style: TextStyle(
            fontSize: _hovered ? 18 : 16,
            color: _hovered ? const Color(0xFF321B58) : Colors.deepPurple,
            fontWeight: FontWeight.bold,
          ),
          child: Text(widget.text),
        ),
      ),
    );
  }
}
