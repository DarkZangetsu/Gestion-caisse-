import 'package:caisse/classHelper/class_account.dart';
import 'package:caisse/composants/texts.dart';
import 'package:flutter/material.dart';

class ListAccount {
  static List<String> comptes = [];
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? _value = 1;
  String defaultAccount = "Livre de Caisse";

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
              DialogCompte.show(
                context,
                comptes: ListAccount.comptes,
                onModifier: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/modification');
                },
                onAjouterCompte: (String compte) {
                  // Action quand on sélectionne un compte
                  setState(() {
                    defaultAccount = compte;
                  });
                  Navigator.pop(context);
                },
              );
            },
            child: Row(
              children: [
                Text(
                  defaultAccount,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14.0),
                ),
                const Icon(Icons.arrow_drop_down_outlined, color: Colors.white)
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
          children: [
            const DrawerHeader(child: Text("Header")),
            DrawerListMenu(
              icon: Icons.business,
              texte: "Chantier",
              onTap: () {
                Navigator.pushNamed(context, '/chantier');
              },
            ),
            DrawerListMenu(
                icon: Icons.people,
                texte: "Personnel",
                onTap: () {
                  Navigator.pushNamed(context, '/personnel');
                  },
            ),
            const DrawerListMenu(icon: Icons.list_alt_rounded, texte: "Résumé"),
            const DrawerListMenu(
                icon: Icons.list_alt_rounded, texte: "Comptes Résumé"),
            const DrawerListMenu(icon: Icons.list, texte: "Transactions-Tous les"),
            const DrawerListMenu(icon: Icons.group, texte: "Comptes"),
            const DrawerListMenu(icon: Icons.swap_horiz, texte: "Transférer"),
            const DrawerListMenu(
                icon: Icons.save_sharp, texte: "Rapports-Tous les comptes"),
            const DrawerListMenu(
                icon: Icons.swap_horiz, texte: "Changer en Revenu Dépenses"),
            const DrawerListMenu(
                icon: Icons.money_rounded, texte: "Calculatrice de trésorerie"),
            const DrawerListMenu(
                icon: Icons.swap_vert, texte: "Sauvegarde et Restauration"),
            const DrawerListMenu(icon: Icons.settings, texte: "Paramètres"),
            const DrawerListMenu(icon: Icons.help_outline, texte: "Aide"),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: TwoButtons(
                texte: "Réçu",
                backgroundColor: Colors.green,
                onPressed: () => Navigator.pushNamed(context, '/payement'),
              ),
            ),
            Expanded(
              child: TwoButtons(
                texte: "Payé",
                backgroundColor: Colors.red,
                onPressed: () => Navigator.pushNamed(context, '/payement'),
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
              Container(
                width: double.infinity,
                height: 40.0,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                ),
                child: const Center(
                  child: MyText(
                    texte: "Tous",
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                ),
                child: DataTable(
                  columnSpacing: 20.0,
                  headingRowColor:
                      WidgetStateProperty.all(Colors.grey.shade300),
                  columns: const [
                    DataColumn(
                      label: MyText(
                        texte: "Date",
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    DataColumn(
                      label: MyText(
                        texte: "Reçu",
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    DataColumn(
                      label: MyText(
                        texte: "Payé",
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                  ],
                  rows: const [
                    DataRow(
                      cells: [
                        DataCell(
                          MyText(
                            texte: "2024-11-07",
                            color: Colors.black87,
                          ),
                        ),
                        DataCell(
                          MyText(
                            texte: "1000 Ar",
                            color: Colors.green,
                          ),
                        ),
                        DataCell(
                          MyText(
                            texte: "500 Ar",
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    DataRow(
                      cells: [
                        DataCell(
                          MyText(
                            texte: "2024-11-06",
                            color: Colors.black87,
                          ),
                        ),
                        DataCell(
                          MyText(
                            texte: "800 Ar",
                            color: Colors.green,
                          ),
                        ),
                        DataCell(
                          MyText(
                            texte: "400 Ar",
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  border: Border(
                    top: BorderSide(
                      color: Colors.grey.shade300,
                      width: 1.0,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          MyText(
                            texte: "Total Reçu:",
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          MyText(
                            texte: "1800 Ar",
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: const [
                          MyText(
                            texte: "Total Payé:",
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                          MyText(
                            texte: "900 Ar",
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Colors.grey.shade300,
                              width: 1.0,
                            ),
                          ),
                        ),
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: const [
                            MyText(
                              texte: "Solde:",
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.black87,
                            ),
                            MyText(
                              texte: "900 Ar",
                              fontWeight: FontWeight.bold,
                              fontSize: 16.0,
                              color: Colors.blue,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
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
    this.child,
    this.border,
  });

  final Widget? child;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      width: double.infinity,
      decoration: BoxDecoration(border: border),
      child: child,
    );
  }
}

class TwoButtons extends StatelessWidget {
  const TwoButtons(
      {super.key, required this.texte, this.backgroundColor, this.onPressed});

  final Color? backgroundColor;
  final String texte;
  final void Function()? onPressed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(4.0),
      child: FloatingActionButton(
        backgroundColor: backgroundColor,
        elevation: 0.3,
        onPressed: onPressed,
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

class DialogCompte extends StatefulWidget {
  final List<String> comptes;
  final Function() onModifier;
  final Function(String) onAjouterCompte;

  const DialogCompte({
    super.key,
    required this.comptes,
    required this.onModifier,
    required this.onAjouterCompte,
  });

  static void show(
    BuildContext context, {
    required List<String> comptes,
    required Function() onModifier,
    required Function(String) onAjouterCompte,
  }) {
    showDialog(
      context: context,
      builder: (context) => DialogCompte(
        comptes: comptes,
        onModifier: onModifier,
        onAjouterCompte: onAjouterCompte,
      ),
    );
  }

  @override
  State<DialogCompte> createState() => _DialogCompteState();
}

class _DialogCompteState extends State<DialogCompte> {
  final TextEditingController _searchController = TextEditingController();
  List<String> _filteredComptes = [];

  @override
  void initState() {
    super.initState();
    _filteredComptes = widget.comptes;
    _searchController.addListener(_filterComptes);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterComptes() {
    setState(() {
      _filteredComptes = widget.comptes
          .where((compte) => compte
              .toLowerCase()
              .contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 400),
        decoration: BoxDecoration(
          color: Theme.of(context).dialogBackgroundColor,
          borderRadius: BorderRadius.circular(2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(),
            _buildSearchBar(),
            _buildComptesList(),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.account_balance_wallet,
            color: Colors.blue,
            size: 24,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Comptes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          IconButton(
            onPressed: widget.onModifier,
            icon: const Icon(Icons.edit),
            tooltip: 'Modifier',
            color: Colors.blue,
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Rechercher un compte...',
          prefixIcon: const Icon(Icons.search, color: Colors.blue),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: Colors.grey.withOpacity(0.3),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(
              color: Colors.blue,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComptesList() {
    return Expanded(
      child: _filteredComptes.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 48,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Aucun compte trouvé',
                    style: TextStyle(
                      color: Colors.grey.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _filteredComptes.length,
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemBuilder: (context, index) {
                return ListTile(
                  leading: const Icon(Icons.account_circle, color: Colors.blue),
                  title: Text(
                    _filteredComptes[index],
                    style: const TextStyle(fontSize: 16),
                  ),
                  onTap: () => widget.onAjouterCompte(_filteredComptes[index]),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  hoverColor: Colors.blue.withOpacity(0.1),
                );
              },
            ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.2),
          ),
        ),
      ),
      child: ElevatedButton.icon(
        onPressed: () async {
          Navigator.pop(context);
          final CompteData? result = await CompteDialog.afficherDialog(context);
          if (result != null) {
            ListAccount.comptes.add(result.nom);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un compte'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}
