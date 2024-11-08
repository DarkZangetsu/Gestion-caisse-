import 'package:caisse/pages/home_page.dart';
import 'package:caisse/pages/modification_page.dart';
import 'package:caisse/pages/payment_page.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const HomePage(),
        '/payement': (context) => const PaymentPage(),
        '/modification' : (context) => const ModificationPage(),
      },
    );
  }
}