import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

import 'package:gestion_caisse_flutter/composants/MyTextFormField.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/mode/dark_mode.dart';
import 'package:gestion_caisse_flutter/mode/light_mode.dart';
import 'package:gestion_caisse_flutter/models/chantier.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
import 'package:gestion_caisse_flutter/providers/users_provider.dart';

class ChantierFormDialog extends ConsumerStatefulWidget {
  final Chantier? chantier;
  final void Function(Chantier) onSave;

  const ChantierFormDialog({
    super.key,
    this.chantier,
    required this.onSave,
  });

  @override
  ConsumerState<ChantierFormDialog> createState() => _ChantierFormDialogState();
}

class _ChantierFormDialogState extends ConsumerState<ChantierFormDialog> {
  late final TextEditingController _nomController;
  late final TextEditingController _budgetController;
  late DateTime? _dateDebut;
  late DateTime? _dateFin;
  Color? _selectedColor;
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.chantier?.name);
    _budgetController = TextEditingController(
      text: widget.chantier?.budgetMax?.toString(),
    );
    _dateDebut = widget.chantier?.startDate;
    _dateFin = widget.chantier?.endDate;
    _selectedColor = widget.chantier?.colorValue;
  }

  @override
  void dispose() {
    _nomController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate
          ? (_dateDebut ?? DateTime.now())
          : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      cancelText: 'Annuler',
      confirmText: 'Confirmer',
      builder: (context, Widget? child) {
        return Theme(
          data: isDarkMode ? darkTheme : lightTheme,
          child: child ?? const SizedBox(),
        );
      },
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _dateDebut = picked;
        } else {
          _dateFin = picked;
        }
      });
    }
  }

  Widget _buildDateField({
    required String label,
    required DateTime? date,
    required bool isStartDate,
    required BuildContext context,
  }) {
    return InkWell(
      onTap: () => _selectDate(context, isStartDate),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: '$label (optionnel)',
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 8,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? DateFormat('dd/MM/yyyy').format(date)
                  : 'Sélectionner',
              style: date == null
                  ? const TextStyle(color: Colors.grey)
                  : null,
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  Future<void> _pickColor(BuildContext context) async {
    Color pickedColor = _selectedColor ?? Colors.blue;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choisissez une couleur'),
        content: SingleChildScrollView(
          child: ColorPicker(
            pickerColor: pickedColor,
            onColorChanged: (color) {
              pickedColor = color;
            },
            showLabel: true,
            pickerAreaHeightPercent: 0.8,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
            onPressed: () {
              setState(() {
                _selectedColor = pickedColor;
              });
              Navigator.of(context).pop();
            },
            child: const Text('Confirmer',
              style: TextStyle(
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer(
      builder: (context, ref, child) {
        final userId = ref.watch(currentUserProvider)?.id ?? '';

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dialogWidth = constraints.maxWidth > 600
                  ? 600.0
                  : constraints.maxWidth;

              return Container(
                width: dialogWidth,
                constraints: const BoxConstraints(maxHeight: 600),
                padding: const EdgeInsets.all(24),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        widget.chantier == null
                            ? 'Ajouter un Chantier'
                            : 'Modifier le Chantier',
                        style: Theme.of(context).textTheme.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      MyTextFormField(
                        budgetController: _nomController,
                        labelText: 'Nom du chantier *',
                      ),
                      const SizedBox(height: 16),
                      MyTextFormField(
                        budgetController: _budgetController,
                        labelText: 'Budget Maximum (optionnel)',
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: () => _pickColor(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                          decoration: BoxDecoration(
                            color: _selectedColor ?? colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDarkMode
                                  ? colorScheme.outline.withOpacity(0.3)
                                  : colorScheme.outline.withOpacity(0.2),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                spreadRadius: 1,
                                blurRadius: 3,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                _selectedColor == null
                                    ? 'Sélectionner une couleur'
                                    : 'Couleur sélectionnée',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: _selectedColor == null
                                      ? (isDarkMode ? Colors.white70 : Colors.black54)
                                      : Colors.white,
                                ),
                              ),
                              Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: _selectedColor ?? colorScheme.primary,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      spreadRadius: 1,
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          if (constraints.maxWidth > 450) {
                            return Row(
                              children: [
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Date de début',
                                    date: _dateDebut,
                                    isStartDate: true,
                                    context: context,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: _buildDateField(
                                    label: 'Date de fin',
                                    date: _dateFin,
                                    isStartDate: false,
                                    context: context,
                                  ),
                                ),
                              ],
                            );
                          } else {
                            return Column(
                              children: [
                                _buildDateField(
                                  label: 'Date de début',
                                  date: _dateDebut,
                                  isStartDate: true,
                                  context: context,
                                ),
                                const SizedBox(height: 16),
                                _buildDateField(
                                  label: 'Date de fin',
                                  date: _dateFin,
                                  isStartDate: false,
                                  context: context,
                                ),
                              ],
                            );
                          }
                        },
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(),
                            child: MyText(
                              texte: 'Annuler',
                              color: isDarkMode ? Colors.white : Colors.black54,
                            ),
                          ),
                          const SizedBox(width: 12),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xffea6b24),
                            ),
                            onPressed: () {
                              if (_nomController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Le nom du chantier est requis',
                                    ),
                                  ),
                                );
                                return;
                              }

                              double? budget;
                              if (_budgetController.text.isNotEmpty) {
                                budget = double.tryParse(
                                  _budgetController.text,
                                );
                              }

                              final nouveauChantier = Chantier(
                                id: widget.chantier?.id ?? uuid.v4(),
                                userId: widget.chantier?.userId ?? userId,
                                name: _nomController.text,
                                budgetMax: budget,
                                startDate: _dateDebut,
                                endDate: _dateFin,
                                color: _selectedColor?.value,
                                createdAt: widget.chantier?.createdAt
                                    ?? DateTime.now(),
                                updatedAt: DateTime.now(),
                              );

                              widget.onSave(nouveauChantier);
                              Navigator.of(context).pop();
                            },
                            icon: Icon(
                              widget.chantier == null
                                  ? Icons.add
                                  : Icons.save,
                              color: Colors.white,
                            ),
                            label: MyText(
                              texte: widget.chantier == null
                                  ? 'Ajouter'
                                  : 'Mettre à jour',
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}