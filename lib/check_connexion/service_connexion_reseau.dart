import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ServiceConnexionReseau {
  static final ServiceConnexionReseau _instance = ServiceConnexionReseau._interne();
  factory ServiceConnexionReseau() => _instance;
  ServiceConnexionReseau._interne();

  final _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _abonnementConnexion;
  bool _boiteDialogueAffichee = false;

  void initialiserSuiviConnexion(BuildContext context) {
    // Annuler l'abonnement précédent s'il existe
    _abonnementConnexion?.cancel();

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

class ConnexionGlobale extends StatefulWidget {
  final Widget child;

  const ConnexionGlobale({Key? key, required this.child}) : super(key: key);

  @override
  _ConnexionGlobaleState createState() => _ConnexionGlobaleState();
}

class _ConnexionGlobaleState extends State<ConnexionGlobale> {
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