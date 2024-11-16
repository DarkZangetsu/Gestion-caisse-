import 'package:flutter/material.dart';

class PaymentTypeForm extends StatefulWidget {
  final String? initialName;
  final String? initialCategory;
  final Future<bool> Function(String name, String category) onSubmit;

  const PaymentTypeForm({
    Key? key,
    this.initialName,
    this.initialCategory,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<PaymentTypeForm> createState() => _PaymentTypeFormState();
}

class _PaymentTypeFormState extends State<PaymentTypeForm> {
  late TextEditingController _nameController;
  String _selectedCategory = 'dépense';
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    if (widget.initialCategory != null) {
      _selectedCategory = widget.initialCategory!;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final success = await widget.onSubmit(_nameController.text, _selectedCategory);
      if (!mounted) return;

      if (success) {
        // Fermer le formulaire
        Navigator.pop(context);

        // Afficher le dialogue de confirmation
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Succès'),
            content: Text(
                widget.initialName == null
                    ? 'Le type de paiement a été ajouté avec succès.'
                    : 'Le type de paiement a été modifié avec succès.'
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      // Afficher le dialogue d'erreur
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Erreur'),
          content: Text(
              'Une erreur est survenue lors de ${widget.initialName == null ? "l'ajout" : "la modification"} du type de paiement:\n${e.toString()}'
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialName == null ? 'Ajouter un type' : 'Modifier le type'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nom'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Veuillez entrer un nom';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Catégorie',
              ),
              items: const [
                DropdownMenuItem(
                  value: 'revenu',
                  child: Text('Revenu'),
                ),
                DropdownMenuItem(
                  value: 'dépense',
                  child: Text('Dépense'),
                ),
              ],
              onChanged: (String? newValue) {
                if (newValue != null) {
                  setState(() {
                    _selectedCategory = newValue;
                  });
                }
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            await _handleSubmit();
          },
          child: _isLoading
              ? const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
            ),
          )
              : const Text('Enregistrer'),
        ),
      ],
    );
  }
}
