import 'package:flutter/material.dart';

class AppbarActionList extends StatelessWidget {
  final IconData icon;
  final Color? color;
  final void Function()? onPressed;

  const AppbarActionList({
    super.key,
    required this.icon,
    this.color = Colors.white,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, color: Colors.white,),
      color: color,
      splashRadius: 24,
      tooltip: 'Action',
      onPressed: onPressed,
      padding: const EdgeInsets.all(8),
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      splashColor: Colors.white.withOpacity(0.1),
      highlightColor: Colors.white.withOpacity(0.1),
    );
  }
}
