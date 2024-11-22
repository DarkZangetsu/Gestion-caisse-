import 'package:flutter/material.dart';

class DrawerListMenu extends StatelessWidget {
  final IconData icon;
  final String texte;
  final GestureTapCallback? onTap;

  const DrawerListMenu({
    super.key,
    required this.icon,
    required this.texte,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: const Color(0xffea6b24),
        size: 24,
      ),
      title: Text(
        texte,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      dense: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16.0,
        vertical: 4.0,
      ),
      hoverColor: const Color(0xffea6b24).withOpacity(0.1),
      selectedTileColor: const Color(0xffea6b24).withOpacity(0.1),
    );
  }
}