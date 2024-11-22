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