import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_user.dart';
import '../providers/users_provider.dart';
import '../widgets/login/login_form.dart';

class LoginPage extends ConsumerWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;
    final logoHeight = isSmallScreen ? 100.0 : 140.0;

    ref.listen<AsyncValue<AppUser?>>(userStateProvider, (previous, next) {
      next.when(
        data: (user) {
          if (user != null) {
            Navigator.of(context).pushReplacementNamed('/');
          }
        },
        error: (error, stackTrace) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error.toString()),
              backgroundColor: Colors.red,
            ),
          );
        },
        loading: () {},
      );
    });

    return Scaffold(
      body: SafeArea(
        child: Center(
          // Centrer tout le contenu
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: Container(
                  constraints: const BoxConstraints(
                      maxWidth: 400),
                  padding: EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: isSmallScreen ? 20.0 : 40.0,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment
                        .center, 
                    children: [
                      // Logo centré avec Container
                      Container(
                        height: logoHeight,
                        width: double.infinity,
                        alignment: Alignment.center,
                        margin: EdgeInsets.symmetric(
                          vertical: isSmallScreen ? 12.0 : 18.0,
                        ),
                        child: Image.asset(
                          'img/Logo.png',
                          fit: BoxFit.contain,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          'Bienvenue',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                fontSize: isSmallScreen ? 24 : 32,
                              ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Sous-titre centré
                      Container(
                        width: double.infinity,
                        alignment: Alignment.center,
                        child: Text(
                          'Connectez-vous pour continuer',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey,
                                    fontSize: isSmallScreen ? 14 : 16,
                                  ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      // Formulaire de connexion
                      const LoginForm(),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                      SizedBox(height: isSmallScreen ? 24 : 32),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
