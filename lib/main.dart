import 'dart:async';
import 'package:caisse/pages/ChangePasswordPage.dart';
import 'package:caisse/pages/PersonnelPage.dart';
import 'package:caisse/pages/chantier_page.dart';
import 'package:caisse/pages/home_page.dart';
import 'package:caisse/pages/login_page.dart';
import 'package:caisse/pages/payment_page.dart';
import 'package:caisse/pages/payment_types_page.dart';
import 'package:caisse/pages/todolist_page.dart';
import 'package:caisse/pages/transaction.dart';
import 'package:caisse/providers/auth_guard.dart';
import 'package:caisse/providers/theme_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/supabase_config.dart';
import 'mode/dark_mode.dart';
import 'mode/light_mode.dart';

class ServiceConnexionReseau {
  static final ServiceConnexionReseau _instance = ServiceConnexionReseau._interne();
  factory ServiceConnexionReseau() => _instance;
  ServiceConnexionReseau._interne();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _abonnementConnexion;
  bool _boiteDialogueAffichee = false;

  void initialiserSuiviConnexion(BuildContext context) {
    _abonnementConnexion = _connectivity.onConnectivityChanged.listen((resultats) {
      _gererChangementConnexion(context, resultats);
    });
  }

  void _gererChangementConnexion(BuildContext context, List<ConnectivityResult> resultats) {
    if (resultats.every((resultat) => resultat == ConnectivityResult.none)) {
      if (!_boiteDialogueAffichee) {
        _afficherDialogueAucuneConnexion(context);
      }
    } else {
      if (_boiteDialogueAffichee) {
        Navigator.of(context, rootNavigator: true).pop();
        _boiteDialogueAffichee = false;
      }
    }
  }

  void _afficherDialogueAucuneConnexion(BuildContext context) {
    if (_boiteDialogueAffichee) return;

    _boiteDialogueAffichee = true;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          title: const Text('Connexion Internet'),
          content: const Text('Aucune connexion internet. Veuillez vérifier votre connexion.'),
          actions: [
            TextButton(
              onPressed: () async {
                var resultatsConnexion = await Connectivity().checkConnectivity();
                if (resultatsConnexion.contains(ConnectivityResult.mobile) ||
                    resultatsConnexion.contains(ConnectivityResult.wifi)) {
                  Navigator.of(context, rootNavigator: true).pop();
                  _boiteDialogueAffichee = false;
                }
              },
              child: const Text('Réessayer'),
            )
          ],
        ),
      ),
    );
  }

  void dispose() {
    _abonnementConnexion?.cancel();
  }
}

class WidgetAwareConnexion extends StatefulWidget {
  final Widget child;

  const WidgetAwareConnexion({super.key, required this.child});

  @override
  _EtatWidgetAwareConnexion createState() => _EtatWidgetAwareConnexion();
}

class _EtatWidgetAwareConnexion extends State<WidgetAwareConnexion> {
  late ServiceConnexionReseau _serviceReseau;

  @override
  void initState() {
    super.initState();
    _serviceReseau = ServiceConnexionReseau();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _serviceReseau.initialiserSuiviConnexion(context);
    });
  }

  @override
  void dispose() {
    _serviceReseau.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SupabaseConfig.initialize();

  runApp(
    const ProviderScope(
      child: MaApplication(),
    ),
  );
}

class MaApplication extends ConsumerWidget {
  const MaApplication({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeCourant = ref.watch(themeProvider);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: lightTheme,
      darkTheme: darkTheme,
      themeMode: themeCourant,
      initialRoute: '/login',
      routes: {
        '/login': (context) => const WidgetAwareConnexion(child: LoginPage()),
        '/': (context) => const WidgetAwareConnexion(child: AuthGuard(child: HomePage())),
        '/payement': (context) => const WidgetAwareConnexion(child: AuthGuard(child: PaymentPage())),
        '/chantier': (context) => const WidgetAwareConnexion(child: ChantierPage()),
        '/personnel': (context) => const WidgetAwareConnexion(child: PersonnelPage()),
        '/todos': (context) => const WidgetAwareConnexion(child: TodoListPage()),
        '/payment-types': (context) => const WidgetAwareConnexion(child: PaymentTypesPage()),
        '/change-password': (context) => const WidgetAwareConnexion(child: ChangePasswordPage()),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/transaction') {
          final args = settings.arguments as Map;
          return MaterialPageRoute(
            builder: (context) => WidgetAwareConnexion(
              child: TransactionPage(
                chantierId: args['chantierId'] as String,
              ),
            ),
          );
        }
      },
    );
  }
}