import 'package:caisse/composants/boutons.dart';
import 'package:caisse/composants/textfields.dart';
import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _value = 1;

  final filterChoice = [
    "Tous",
    "Quotidien",
    "Hebdomadaire",
    "Mensuel",
    "Annuel"
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Expanded(
          child: TextButton(
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(color: Colors.grey, width: 1.0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                  titlePadding: const EdgeInsets.all(0.0),
                  title: Container(
                    padding: const EdgeInsets.symmetric(
                        vertical: 8.0, horizontal: 16.0),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom:
                                BorderSide(width: 0.5, color: Colors.grey))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.account_balance_outlined,
                                color: Colors.blue),
                            SizedBox(width: 8.0),
                            Text(
                              "Comptes",
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            )
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(Icons.edit, color: Colors.blue.shade400),
                          label: Text(
                            "Modifier",
                            style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue.shade400),
                          ),
                          style: ElevatedButton.styleFrom(
                            elevation: 0,
                            backgroundColor: Colors.transparent,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const MyContainer(
                        border: Border(bottom: BorderSide(width: 0.2, color: Colors.grey)),
                        child: MyTextfields(
                          prefixIcon: Icon(Icons.search),
                        ),
                      ),
                      
                      const SizedBox(height: 16.0),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8.0),
                        width: double.infinity,
                        child: const Column(
                          children: [
                            Text("Texte"),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16.0),
                      MyContainer(
                        border: const Border(top: BorderSide(width: 0.2, color: Colors.grey)),
                        child: MyButtons(
                          backgroundColor: Colors.blue,
                          onPressed: () {},
                          child: const MyText(
                            texte: "Ajouter un compte",
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
              ;
            },
            //child:
            child: const Row(
              children: [
                Text(
                  "Livre de Caisse",
                  style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0),
                ),
                Icon(Icons.arrow_drop_down_outlined, color: Colors.white)
              ],
            ),
          ),
        ),
        actions: const [
          AppbarActionList(icon: Icons.list_alt_outlined, color: Colors.white),
          AppbarActionList(icon: Icons.search, color: Colors.white),
          AppbarActionList(icon: Icons.more_vert),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: const [
            DrawerHeader(child: Text("Header")),
            DrawerListMenu(
                icon: Icons.phone_android_outlined,
                texte: "Supprimer la publicité"),
            DrawerListMenu(icon: Icons.list_alt_rounded, texte: "Résumé"),
            DrawerListMenu(
                icon: Icons.list_alt_rounded, texte: "Comptes Résumé"),
            DrawerListMenu(icon: Icons.list, texte: "Transactions-Tous les"),
            DrawerListMenu(icon: Icons.group, texte: "Comptes"),
            DrawerListMenu(icon: Icons.swap_horiz, texte: "Transférer"),
            DrawerListMenu(
                icon: Icons.save_sharp, texte: "Rapports-Tous les comptes"),
            DrawerListMenu(
                icon: Icons.swap_horiz, texte: "Changer en Revenu Dépenses"),
            DrawerListMenu(
                icon: Icons.money_rounded, texte: "Calculatrice de trésorerie"),
            DrawerListMenu(
                icon: Icons.swap_vert, texte: "Sauvegarde et Restauration"),
            DrawerListMenu(icon: Icons.settings, texte: "Paramètres"),
            DrawerListMenu(icon: Icons.help_outline, texte: "Aide"),
            DrawerListMenu(icon: Icons.star, texte: "Evaluez-nous"),
            DrawerListMenu(icon: Icons.share, texte: "Recommander"),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TwoButtons(
                texte: "Réçu",
                backgroundColor: Colors.green,
              ),
            ),
            Expanded(
              child: TwoButtons(
                texte: "Payé",
                backgroundColor: Colors.red,
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(8.0),
                height: 60,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: filterChoice.length,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: ChoiceChip(
                        selectedColor: Colors.blue,
                        labelPadding: const EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 2.0),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                        side: const BorderSide(
                          color: Colors.white,
                        ),
                        label: Text(
                          filterChoice[index],
                          style: TextStyle(
                              color:
                                  _value == index ? Colors.white : Colors.black,
                              fontSize: 14.0),
                        ),
                        selected: _value == index,
                        onSelected: (bool selected) {
                          setState(() {
                            _value = selected ? index : null;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyContainer extends StatelessWidget {
  const MyContainer({
    super.key,
    this.child, this.border,
  });

  final Widget? child;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      decoration: BoxDecoration(
          border: border),
      child: child,
    );
  }
}

class TwoButtons extends StatelessWidget {
  const TwoButtons({super.key, required this.texte, this.backgroundColor});

  final Color? backgroundColor;
  final String texte;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FloatingActionButton(
        backgroundColor: backgroundColor,
        elevation: 0.3,
        onPressed: () {},
        child: Text(
          texte,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class AppbarActionList extends StatelessWidget {
  const AppbarActionList({super.key, this.onPressed, this.icon, this.color});

  final void Function()? onPressed;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: () {},
      icon: Icon(
        icon,
        color: color ?? Colors.black,
      ),
    );
  }
}

class DrawerListMenu extends StatelessWidget {
  const DrawerListMenu({
    super.key,
    required this.icon,
    required this.texte,
    this.onTap,
  });

  final IconData icon;
  final String texte;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(texte),
      onTap: onTap,
    );
  }
}
