import 'package:flutter/material.dart';
import 'package:fluttertest/student/widgets/BoldText.dart';

class IconWithText extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color? colorIcon;
  final Color? colorText;
  final double sizeIcon;
  final double sizeText;

  const IconWithText({
    super.key,
    required this.icon,
    required this.text,
    this.colorIcon = Colors.black,
    this.colorText = Colors.black,
    this.sizeIcon = 24,
    this.sizeText = 14,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Icon(
          icon,
          color: colorIcon,
          size: sizeIcon,
        ),
        const SizedBox(width: 5),
        Opacity(
          opacity: 0.5,
        child: BoldText(
          font: 'YourFontFamily',  // Remove or default if BoldText supports it
          text: text,
          color: colorText,
          size: sizeText,
        ),
        ),
      ],
    );
  }
}
