import 'package:flutter/material.dart';

class BoldText extends StatelessWidget {
  final double size;
  final String font;
  final String text;
  final Color? color;
  final TextAlign? align;
  final TextOverflow textOverflow;

  const BoldText({
    super.key,
    this.size = 20,
    required this.font,
    required this.text,
    this.color,
    this.align,
    this.textOverflow = TextOverflow.ellipsis,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: textOverflow,
      textAlign: align,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        fontSize: size,
        color: color,
        fontFamily: font,
      ),
    );
  }
}
