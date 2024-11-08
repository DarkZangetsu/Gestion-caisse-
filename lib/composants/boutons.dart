import 'package:flutter/material.dart';

class MyButtons extends StatelessWidget {
  const MyButtons(
      {super.key,
      this.child,
      this.backgroundColor,
      this.onPressed,
      this.elevation});

  final Widget? child;
  final Color? backgroundColor;
  final void Function()? onPressed;
  final double? elevation;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        elevation: elevation,
        backgroundColor: backgroundColor,
        textStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(1),
        ),
      ),
      child: child,
    );
  }
}
