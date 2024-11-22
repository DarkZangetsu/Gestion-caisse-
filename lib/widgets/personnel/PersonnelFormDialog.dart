import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:gestion_caisse_flutter/models/personnel.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gestion_caisse_flutter/providers/users_provider.dart';

class PersonnelFormDialog extends ConsumerStatefulWidget {
  final Personnel? personnel;
  final void Function(Personnel) onSave;

  const PersonnelFormDialog({
    super.key,
    this.personnel,
    required this.onSave,
  });

  @override
  ConsumerState<PersonnelFormDialog> createState() => _PersonnelFormDialogState();
}

class _PersonnelFormDialogState extends ConsumerState<PersonnelFormDialog> {
  late final TextEditingController _nomController;
  late final TextEditingController _roleController;
  late final TextEditingController _contactController;
  late final TextEditingController _salaireMaxController;
  final _formKey = GlobalKey<FormState>();
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.personnel?.name);
    _roleController = TextEditingController(text: widget.personnel?.role);
    _contactController = TextEditingController(text: widget.personnel?.contact);
    _salaireMaxController = TextEditingController(
      text: widget.personnel?.salaireMax?.toString(),
    );
  }

  @override
  void dispose() {
    _nomController.dispose();
    _roleController.dispose();
    _contactController.dispose();
    _salaireMaxController.dispose();
    super.dispose();
  }

  // Only validate the name field as required
  String? _validateRequired(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ce champ est obligatoire';
    }
    return null;
  }

  // Optional validation for salary - only validate format if value is provided
  String? _validateSalaire(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Return null if empty since field is optional
    }
    if (double.tryParse(value) == null) {
      return 'Veuillez entrer un nombre valide';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    return Consumer(
      builder: (context, ref, child) {
        final userId = ref.watch(currentUserProvider)?.id ?? '';
        final screenSize = MediaQuery.of(context).size;
        final isSmallScreen = screenSize.width < 600;

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? screenSize.width * 0.9 : 500,
              maxHeight: isSmallScreen ? screenSize.height * 0.8 : 600,
            ),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16.0 : 24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.personnel == null
                            ? 'Ajouter un Personnel'
                            : 'Modifier le Personnel',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: isSmallScreen ? 16.0 : 24.0),

                      // Required name field
                      _buildInputField(
                        controller: _nomController,
                        label: 'Nom *',
                        icon: Icons.person,
                        validator: _validateRequired,
                      ),
                      const SizedBox(height: 16),

                      // Optional role field
                      _buildInputField(
                        controller: _roleController,
                        label: 'Rôle (optionnel)',
                        icon: Icons.work,
                      ),
                      const SizedBox(height: 16),

                      // Optional contact field
                      _buildInputField(
                        controller: _contactController,
                        label: 'Contact (optionnel)',
                        icon: Icons.phone,
                        keyboardType: TextInputType.phone,
                      ),
                      const SizedBox(height: 16),

                      // Optional salary field with format validation
                      _buildInputField(
                        controller: _salaireMaxController,
                        label: 'Salaire Maximum (optionnel)',
                        icon: Icons.credit_card,
                        validator: _validateSalaire,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        prefixText: 'Ar ',
                      ),
                      SizedBox(height: isSmallScreen ? 24.0 : 32.0),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: MyText(
                                texte: 'Annuler', color: isDarkMode ? Colors.white : Colors.black54,),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                final nouveauPersonnel = Personnel(
                                  id: widget.personnel?.id ?? uuid.v4(),
                                  userId: widget.personnel?.userId ?? userId,
                                  name: _nomController.text,
                                  role: _roleController.text.isEmpty
                                      ? null
                                      : _roleController.text,
                                  contact: _contactController.text.isEmpty
                                      ? null
                                      : _contactController.text,
                                  salaireMax: _salaireMaxController.text.isEmpty
                                      ? null
                                      : double.tryParse(
                                          _salaireMaxController.text),
                                  createdAt: widget.personnel?.createdAt ??
                                      DateTime.now(),
                                  updatedAt: DateTime.now(),
                                );
                                widget.onSave(nouveauPersonnel);
                                Navigator.of(context).pop();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffea6b24),
                              foregroundColor:
                                  Theme.of(context).colorScheme.onPrimary,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              widget.personnel == null
                                  ? 'Ajouter'
                                  : 'Mettre à jour',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    String? prefixText,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        prefixText: prefixText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        filled: true,
        fillColor: Theme.of(context).colorScheme.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
    );
  }
}
