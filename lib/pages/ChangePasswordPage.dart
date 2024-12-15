import 'package:flutter/material.dart';

import '../composants/texts.dart';
import '../widgets/login/ChangePasswordForm.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const MyText(
          texte: 'Modifier le mot de passe',
          color: Colors.white,
        ),
          backgroundColor: const Color(0xff000000),
      ),
      body: const SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: ChangePasswordForm(),
        ),
      ),
    );
  }
}