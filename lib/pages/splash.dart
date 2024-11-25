import 'package:flutter/material.dart';
import 'package:animated_splash_screen/animated_splash_screen.dart';
import 'package:gestion_caisse_flutter/check_connexion/widget_awesome_connexion.dart';
import 'package:gestion_caisse_flutter/pages/login_page.dart';
import 'package:page_transition/page_transition.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class Splash extends StatelessWidget {
  const Splash({super.key});

  @override
  Widget build(BuildContext context) {
    // Obtenir les dimensions de l'écran et le padding de sécurité
    final mediaQuery = MediaQuery.of(context);
    final screenSize = mediaQuery.size;

    // Calculer les dimensions responsives
    final logoSize =
        screenSize.shortestSide * 0.25;
    final fontSize =
        screenSize.shortestSide * 0.045; 
    final spinnerSize =
        screenSize.shortestSide * 0.08; 

    return SafeArea(
      child: AnimatedSplashScreen(
        splash: LayoutBuilder(
          builder: (context, constraints) {
            return Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              padding: EdgeInsets.symmetric(
                horizontal: screenSize.width * 0.05,
                vertical: screenSize.height * 0.02,
              ),
              child: FittedBox(
                fit: BoxFit.contain,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: screenSize.width * 0.9,
                    maxHeight: screenSize.height * 0.8,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.blue.shade50,
                        Colors.white,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.withOpacity(0.1),
                        spreadRadius: 5,
                        blurRadius: 15,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Logo animé
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween<double>(begin: 0.5, end: 1.0),
                          curve: Curves.elasticOut,
                          builder: (context, double value, child) {
                            return Transform.scale(
                              scale: value,
                              child: Container(
                                padding: EdgeInsets.all(logoSize * 0.1),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withOpacity(0.2),
                                      spreadRadius: 2,
                                      blurRadius: 10,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Image.asset(
                                  'img/Logo.png',
                                  height: logoSize,
                                  width: logoSize,
                                  fit: BoxFit.contain,
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: screenSize.height * 0.03),

                        // Texte animé
                        TweenAnimationBuilder(
                          duration: const Duration(milliseconds: 1000),
                          tween: Tween<double>(begin: 0.0, end: 1.0),
                          builder: (context, double value, child) {
                            return Opacity(
                              opacity: value,
                              child: Text(
                                "Bienvenue dans l'application\nCOMPTAH!",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: fontSize,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF2E4057),
                                  height: 1.3,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            );
                          },
                        ),

                        SizedBox(height: screenSize.height * 0.03),

                        // Indicateur de chargement
                        SpinKitFadingCircle(
                          color: Colors.blue.shade300,
                          size: spinnerSize,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
        nextScreen: const WidgetAwareConnexion(child: LoginPage()),
        splashIconSize: double.infinity,
        splashTransition: SplashTransition.fadeTransition,
        pageTransitionType: PageTransitionType.fade,
        backgroundColor: Colors.white,
        animationDuration: const Duration(milliseconds: 1500),
        duration: 3500,
      ),
    );
  }
}
