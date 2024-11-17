import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/users_provider.dart';
import 'custom_text_field.dart';
import 'custom_button.dart';


class ChangePasswordForm extends ConsumerStatefulWidget {
  const ChangePasswordForm({super.key});

  @override
  ConsumerState<ChangePasswordForm> createState() => _ChangePasswordFormState();
}

class _ChangePasswordFormState extends ConsumerState<ChangePasswordForm> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  var _isCurrentPasswordVisible = false;
  var _isNewPasswordVisible = false;
  var _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handlePasswordChange() {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      // Utiliser Future.delayed pour exécuter le code asynchrone
      Future.delayed(Duration.zero, () async {
        try {
          // Vérifier d'abord le mot de passe actuel
          final currentUser = ref.read(currentUserProvider);
          if (currentUser == null) {
            throw Exception('Utilisateur non connecté');
          }

          // Vérifier le mot de passe actuel en tentant une connexion
          await ref.read(databaseHelperProvider).signInUser(
            currentUser.email,
            _currentPasswordController.text,
          );

          // Si la connexion réussit, mettre à jour le mot de passe
          await ref.read(databaseHelperProvider).updateUserPassword(
            currentUser.id,
            _newPasswordController.text,
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Mot de passe modifié avec succès'),
                backgroundColor: Colors.green,
              ),
            );
            Navigator.of(context).pop(); // Fermer la page après succès
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(e.toString()),
                backgroundColor: Colors.red,
              ),
            );
          }
        } finally {
          if (mounted) {
            setState(() {
              _isLoading = false;
            });
          }
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Modifier le mot de passe',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              label: 'Mot de passe actuel',
              controller: _currentPasswordController,
              obscureText: !_isCurrentPasswordVisible,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                  });
                },
                icon: Icon(_isCurrentPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer votre mot de passe actuel';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Nouveau mot de passe',
              controller: _newPasswordController,
              obscureText: !_isNewPasswordVisible,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isNewPasswordVisible = !_isNewPasswordVisible;
                  });
                },
                icon: Icon(_isNewPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nouveau mot de passe';
                }
                if (value.length < 6) {
                  return 'Le mot de passe doit contenir au moins 6 caractères';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              label: 'Confirmer le nouveau mot de passe',
              controller: _confirmPasswordController,
              obscureText: !_isConfirmPasswordVisible,
              suffixIcon: IconButton(
                onPressed: () {
                  setState(() {
                    _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                  });
                },
                icon: Icon(_isConfirmPasswordVisible
                    ? Icons.visibility_off
                    : Icons.visibility),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez confirmer le nouveau mot de passe';
                }
                if (value != _newPasswordController.text) {
                  return 'Les mots de passe ne correspondent pas';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            CustomButton(
              text: 'Changer le mot de passe',
              onPressed: () {
                if (!_isLoading) {
                  _handlePasswordChange();
                }
              },
              isLoading: _isLoading,
            ),
          ],
        ),
      ),
    );
  }
}