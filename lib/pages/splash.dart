import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:gestion_caisse_flutter/pages/login_page.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedSplashScreen(
      // Splash content
      splash: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'img/Logo.png',
            height: 100, // Ajustez la taille du logo
          ),
          const SizedBox(height: 20),
          const Text(
            "Bienvenue dans l'application Gestion Caisse",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
      nextScreen: LoginPage(),
      splashIconSize: 250, // Taille totale du splash
      splashTransition: SplashTransition.fadeTransition,
      backgroundColor: Colors.white, // Couleur de fond
      animationDuration:
          const Duration(milliseconds: 2000), // Transition rapide
      duration: 3000, // Durée d'affichage totale
    );
  }
}
