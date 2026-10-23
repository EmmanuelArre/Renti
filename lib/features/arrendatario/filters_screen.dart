import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';

/// 06 · Filtros
class FiltersScreen extends StatefulWidget {
  const FiltersScreen({super.key});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  late RangeValues _price;
  late Set<String> _types;
  late Set<String> _services;

  @override
  void initState() {
    super.initState();
    final f = appState.filters;
    _price = f.price;
    _types = {...f.types};
    _services = {...f.services};
  }

  void _toggle(Set<String> set, String v) =>
      setState(() => set.contains(v) ? set.remove(v) : set.add(v));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ScreenHeader(title: 'Filtros'),
                    const SectionTitle('Precio', padding: EdgeInsets.fromLTRB(0, 24, 0, 6)),
                    Text(
                      '${formatMoney(_price.start.round())} — ${formatMoney(_price.end.round())} / mes',
                      style: TextStyle(
                        color: context.muted,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: RentiColors.blue,
                        inactiveTrackColor: context.line,
                        trackHeight: 6,
                        rangeThumbShape: const RoundRangeSliderThumbShape(
                          enabledThumbRadius: 12,
                          elevation: 0,
                        ),
                        thumbColor: Colors.white,
                        overlayColor: RentiColors.blue.withValues(alpha: 0.12),
                      ),
                      child: RangeSlider(
                        values: _price,
                        min: SearchFilters.precioMin,
                        max: SearchFilters.precioMax,
                        divisions: 95,
                        onChanged: (v) => setState(() => _price = v),
                      ),
                    ),
                    const SectionTitle('Tipo'),
                    PillWrap(
                      options: Catalogos.tiposPropiedad,
                      isSelected: _types.contains,
                      onTap: (o) => _toggle(_types, o),
                    ),
                    const SectionTitle('Servicios'),
                    PillWrap(
                      options: Catalogos.servicios,
                      isSelected: _services.contains,
                      onTap: (o) => _toggle(_services, o),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 8, RentiTheme.pad, 16),
              child: Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: 'Limpiar',
                      onPressed: () => setState(() {
                        _price = const RangeValues(
                            SearchFilters.precioMin, SearchFilters.precioMax);
                        _types = {};
                        _services = {};
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: PrimaryButton(
                      label: 'Aplicar filtros',
                      onPressed: () {
                        final f = appState.filters;
                        f.price = _price;
                        f.types = _types;
                        f.services = _services;
                        Navigator.of(context).pop(true);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
