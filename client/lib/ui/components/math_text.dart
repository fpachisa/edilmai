import 'package:flutter/material.dart';
import '../../utils/math_formatter.dart';

/// A widget that displays text with formatted mathematical expressions
class MathText extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MathText(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return SelectableText(
      MathFormatter.formatMath(text),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
    );
  }
}

/// A non-selectable version for UI elements where selection isn't needed
class MathTextDisplay extends StatelessWidget {
  final String text;
  final TextStyle? style;
  final TextAlign? textAlign;
  final int? maxLines;
  final TextOverflow? overflow;

  const MathTextDisplay(
    this.text, {
    super.key,
    this.style,
    this.textAlign,
    this.maxLines,
    this.overflow,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      MathFormatter.formatMath(text),
      style: style,
      textAlign: textAlign,
      maxLines: maxLines,
      overflow: overflow,
    );
  }
}