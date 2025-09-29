import 'package:flutter/material.dart';

class MyForm extends StatelessWidget {
  final String title;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;

  const MyForm({
    super.key,
    required this.title,
    required this.icon,
    this.controller,
    this.obscureText = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: title,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
    );
  }
}
