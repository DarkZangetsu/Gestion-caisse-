import 'package:flutter/material.dart';

class MyText extends StatelessWidget {
  const MyText(
      {super.key,
      required this.texte,
      this.color,
      this.fontSize,
      this.fontWeight,
      this.textAlign});

  final String texte;
  final Color? color;
  final double? fontSize;
  final FontWeight? fontWeight;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    return Text(
      texte,
      textAlign: textAlign,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );
  }
}
