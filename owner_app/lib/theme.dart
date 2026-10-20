import 'package:flutter/material.dart';

const kNavy = Color(0xFF1A3A5C);
const kAmber = Color(0xFFF0A500);
const kBg = Color(0xFFF5F7FA);
const kRed = Color(0xFFC62828);
const kGreen = Color(0xFF2E7D32);

class Card2 extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  const Card2({super.key, required this.child, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Padding(padding: const EdgeInsets.all(14), child: child),
        ),
      ),
    );
  }
}
