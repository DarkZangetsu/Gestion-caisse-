import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';

class TabHeader extends StatelessWidget {
  const TabHeader({
    super.key,
    required this.flex,
    required this.text,
    this.textAlign,
  });

  final int flex;
  final String text;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      flex: flex,
      child: MyText(
        texte: text,
        fontWeight: FontWeight.bold,
        textAlign: textAlign,
      ),
    );
  }
}