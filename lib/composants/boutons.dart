import 'package:flutter/material.dart';

class MyButtons extends StatelessWidget {
  const MyButtons(
      {super.key, this.child, this.backgroundColor, this.onPressed});

  final Widget? child;
  final Color? backgroundColor;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
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
