import 'package:gestion_caisse_flutter/composants/MyTextFormField.dart';
import 'package:gestion_caisse_flutter/composants/texts.dart';
import 'package:gestion_caisse_flutter/mode/dark_mode.dart';
import 'package:gestion_caisse_flutter/mode/light_mode.dart';
import 'package:gestion_caisse_flutter/providers/theme_provider.dart';
import 'package:flutter/material.dart';
import 'package:gestion_caisse_flutter/models/chantier.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final uuid = Uuid();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController(text: widget.chantier?.name);
    _budgetController =
        TextEditingController(text: widget.chantier?.budgetMax?.toString());
    _dateDebut = widget.chantier?.startDate;
    _dateFin = widget.chantier?.endDate;
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
          data: isDarkMode
              ? darkTheme.copyWith(
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                )
              : lightTheme.copyWith(
                  textButtonTheme: TextButtonThemeData(
                    style: TextButton.styleFrom(
                      foregroundColor: isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ),
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              date != null
                  ? DateFormat('dd/MM/yyyy').format(date)
                  : 'Sélectionner',
              style: date == null ? const TextStyle(color: Colors.grey) : null,
            ),
            const Icon(Icons.calendar_today, size: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(themeProvider) == ThemeMode.dark;
    return Consumer(
      builder: (context, ref, child) {
        final userId = ref.watch(currentUserProvider)?.id ?? '';

        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dialogWidth =
                  constraints.maxWidth > 600 ? 600.0 : constraints.maxWidth;

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
                            decimal: true),
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
                                backgroundColor: const Color(0xffea6b24)),
                            onPressed: () {
                              // Validation uniquement pour le nom du chantier
                              if (_nomController.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content: Text(
                                          'Le nom du chantier est requis')),
                                );
                                return;
                              }

                              // Parse le budget seulement s'il est renseigné
                              double? budget;
                              if (_budgetController.text.isNotEmpty) {
                                budget =
                                    double.tryParse(_budgetController.text);
                              }

                              final nouveauChantier = Chantier(
                                id: widget.chantier?.id ?? uuid.v4(),
                                userId: widget.chantier?.userId ?? userId,
                                name: _nomController.text,
                                budgetMax: budget,
                                startDate: _dateDebut,
                                endDate: _dateFin,
                                createdAt: widget.chantier?.createdAt ??
                                    DateTime.now(),
                                updatedAt: DateTime.now(),
                              );
                              widget.onSave(nouveauChantier);
                            },
                            icon: Icon(
                              widget.chantier == null ? Icons.add : Icons.save,
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
