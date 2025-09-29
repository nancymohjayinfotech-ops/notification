import 'package:flutter/material.dart';

class MyContainer extends StatelessWidget {
  const MyContainer({
    super.key,
    required this.height,
    required this.width,
    required this.radius,
    required this.color,
    this.child,
  });

  final double height;
  final double width;
  final double radius;
  final Color color;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Center(child: child),
    );
  }
}
