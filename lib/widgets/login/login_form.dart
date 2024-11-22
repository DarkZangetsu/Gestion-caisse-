import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/users_provider.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';

class LoginForm extends ConsumerStatefulWidget {
  const LoginForm({super.key});

  @override
  ConsumerState<LoginForm> createState() => _LoginFormState();
}

class _LoginFormState extends ConsumerState<LoginForm> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: "user@gmail.com"); 
  final _passwordController = TextEditingController();
  var _isDisplay = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      try {
        await ref.read(userStateProvider.notifier).signInUser(
          _emailController.text.trim(),
          _passwordController.text,
        );
      } catch (e) {
        if (mounted) {
          print(e.toString());
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Une erreur s'est produit! verifier votre connexion ou bien votre mot de passe"),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    final userState = ref.watch(userStateProvider);

    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomTextField(
            label: 'Mot de passe',
            controller: _passwordController,
            obscureText: _isDisplay,
            suffixIcon: IconButton(
              onPressed: () {
                setState(() {
                  _isDisplay = !_isDisplay;
                });
              }, 
              icon: Icon(_isDisplay ? Icons.visibility_off : Icons.visibility),
              ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Veuillez entrer votre mot de passe';
              }
              if (value.length < 6) {
                return 'Le mot de passe doit contenir au moins 6 caractères';
              }
              return null;
            },
          ),
          const SizedBox(height: 24),
          CustomButton(
            text: 'Se connecter',
            onPressed: _handleLogin,
            isLoading: userState is AsyncLoading,
          ),
          if (userState is AsyncError) ...[
            const SizedBox(height: 16),
            Text(
              (userState.error as dynamic).toString(),
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}