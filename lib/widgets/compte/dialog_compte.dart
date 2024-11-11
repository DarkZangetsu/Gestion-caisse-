import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../classHelper/class_account.dart';
import '../../models/accounts.dart';
import '../../providers/accounts_provider.dart';

class DialogCompte extends ConsumerStatefulWidget {
  final void Function(Account compteSelectionne)? onCompteSelectionne;

  const DialogCompte({Key? key, this.onCompteSelectionne}) : super(key: key);

  static void show(BuildContext context, {void Function(Account compteSelectionne)? onCompteSelectionne}) {
    showDialog(
      context: context,
      builder: (context) => DialogCompte(onCompteSelectionne: onCompteSelectionne),
    );
  }

  @override
  ConsumerState<DialogCompte> createState() => _DialogCompteState();
}

class _DialogCompteState extends ConsumerState<DialogCompte> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final comptesAsync = ref.watch(accountsStateProvider);

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
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
            Expanded(
              child: comptesAsync.when(
                data: (comptes) => _buildComptesList(comptes),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(child: Text('Erreur: $error')),
              ),
            ),
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
      child: const Row(
        children: [
          Icon(Icons.account_balance_wallet, color: Color(0xffea6b24), size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Comptes',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
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
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Rechercher un compte...',
          prefixIcon: const Icon(Icons.search, color: Color(0xffea6b24)),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.withOpacity(0.3)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffea6b24)),
          ),
        ),
      ),
    );
  }

  Widget _buildComptesList(List<Account> comptes) {
    final comptesFiltres = comptes
        .where((compte) => compte.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();

    if (comptesFiltres.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 48, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'Aucun compte trouvé',
              style: TextStyle(color: Colors.grey.withOpacity(0.8), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      itemCount: comptesFiltres.length,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemBuilder: (context, index) {
        final compte = comptesFiltres[index];
        return ListTile(
          leading: const Icon(Icons.account_circle, color: Color(0xffea6b24)),
          title: Text(compte.name, style: const TextStyle(fontSize: 16)),
          subtitle: compte.solde != null
              ? Text(
            'Solde: ${compte.solde!.toStringAsFixed(2)}',
            style: TextStyle(
              color: compte.solde! >= 0 ? Colors.green : Colors.red,
            ),
          )
              : null,
          onTap: () {
            if (widget.onCompteSelectionne != null) {
              widget.onCompteSelectionne!(compte);
            }
            Navigator.pop(context);
          },
        );
      },
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
          await CompteDialog.afficherDialog(context);
        },
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un compte'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xffea6b24),
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
