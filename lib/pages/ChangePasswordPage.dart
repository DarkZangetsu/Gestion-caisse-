import 'package:flutter/material.dart';

import '../widgets/login/ChangePasswordForm.dart';

class ChangePasswordPage extends StatelessWidget {
  const ChangePasswordPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Modifier le mot de passe'),
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