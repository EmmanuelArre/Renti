import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/features/arrendatario/filters_screen.dart';
import 'package:renti/features/arrendatario/results_screen.dart';

/// 05 · Buscar
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final TextEditingController _place =
      TextEditingController(text: appState.filters.place);
  static const _durations = [
    ('1 mes', 1),
    ('3 meses', 3),
    ('6 meses', 6),
    ('Indefinido', 0),
  ];

  @override
  void dispose() {
    _place.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: appState.filters.entryDate ?? now,
      firstDate: now,
      lastDate: DateTime(now.year + 2),
    );
    if (d != null) setState(() => appState.filters.entryDate = d);
  }

  @override
  Widget build(BuildContext context) {
    final f = appState.filters;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: BigTitle('Buscar alojamiento')),
              GestureDetector(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const FiltersScreen()),
                ),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: context.card,
                    shape: BoxShape.circle,
                    boxShadow: softShadow(0.1),
                  ),
                  child: Icon(Icons.tune_rounded, size: 22, color: context.ink),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          RentiTextField(
            label: '¿Dónde?',
            hint: 'Ciudad o zona',
            controller: _place,
          ),
          SelectField(
            label: 'Universidad',
            hint: 'Selecciona tu universidad',
            value: f.university,
            options: Catalogos.universidades,
            onChanged: (v) => setState(() => f.university = v),
          ),
          TappableField(
            label: 'Fecha de entrada',
            text: f.entryDate == null
                ? 'Selecciona una fecha'
                : formatDate(f.entryDate!),
            isHint: f.entryDate == null,
            onTap: _pickDate,
          ),
          const SectionTitle('Duración', padding: EdgeInsets.fromLTRB(0, 26, 0, 12)),
          PillWrap(
            options: [for (final d in _durations) d.$1],
            isSelected: (o) => _durations.firstWhere((d) => d.$1 == o).$2 == f.months,
            onTap: (o) => setState(
                () => f.months = _durations.firstWhere((d) => d.$1 == o).$2),
          ),
          const SizedBox(height: 32),
          PrimaryButton(
            label: 'Buscar alojamientos',
            onPressed: () {
              f.place = _place.text.trim();
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ResultsScreen()),
              );
            },
          ),
        ],
      ),
    );
  }
}
