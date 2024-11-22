import 'package:caisse/check_connexion/service_connexion_reseau.dart';
import 'package:flutter/material.dart';

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