import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/bottom_nav.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/features/arrendatario/filters_screen.dart';
import 'package:renti/shared/screens/listing_detail_screen.dart';
import 'package:renti/features/arrendatario/map_screen.dart';

/// 07 · Resultados
class ResultsScreen extends StatefulWidget {
  const ResultsScreen({super.key});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  List<Listing> _filtered() => appState.filters.aplicar(appState.listings);

  @override
  Widget build(BuildContext context) {
    final list = _filtered();
    return NavScaffold(
      current: 1,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 0),
            child: Row(
              children: [
                const CircleBackButton(),
                const SizedBox(width: 18),
                Expanded(
                  child: Text(
                    'Alojamientos para ti',
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                ),
                _RoundIcon(
                  icon: Icons.tune_rounded,
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const FiltersScreen()),
                    );
                    if (mounted) setState(() {});
                  },
                ),
                const SizedBox(width: 8),
                _RoundIcon(
                  icon: Icons.map_outlined,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MapScreen()),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 12),
            child: Text(
              '${list.length} resultado${list.length == 1 ? '' : 's'}',
              style: TextStyle(
                color: context.muted,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
          ),
          Expanded(
            child: list.isEmpty
                ? EmptyView(
                    icon: Icons.search_off_rounded,
                    title: 'No hay alojamientos con esos filtros',
                    subtitle: 'Prueba ampliando el precio o quitando filtros.',
                    actionLabel: 'Limpiar filtros',
                    onAction: () => setState(appState.filters.clear),
                  )
                : ListView(
                    padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 0, RentiTheme.pad, 12),
                    children: [
                      for (final l in list)
                        ListingCard(
                          listing: l,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(listing: l)),
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _RoundIcon extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _RoundIcon({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: context.card,
            shape: BoxShape.circle,
            boxShadow: softShadow(0.12),
          ),
          child: Icon(icon, size: 21, color: context.ink),
        ),
      );
}
