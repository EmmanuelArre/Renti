import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/shared/screens/listing_detail_screen.dart';

/// 08 · Mapa (mapa ilustrado con pines de precio, sin servicio externo).
class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  /// Posiciones del mapa ilustrado (fracción del ancho y del alto). No hay
  /// coordenadas reales: cada propiedad ocupa una posición fija según su id.
  static const _slots = <(double, double)>[
    (0.38, 0.21), (0.59, 0.26), (0.23, 0.49), (0.77, 0.47),
    (0.52, 0.58), (0.30, 0.68), (0.70, 0.66), (0.16, 0.30),
    (0.84, 0.30), (0.50, 0.80), (0.26, 0.84), (0.78, 0.82),
  ];

  late final List<Listing> _listings =
      appState.filters.aplicar(appState.listings).take(_slots.length).toList();

  late final List<(Listing, double, double)> _pins = () {
    final usados = <int>{};
    final out = <(Listing, double, double)>[];
    for (final l in _listings) {
      var i = l.id.hashCode.abs() % _slots.length;
      while (usados.contains(i)) {
        i = (i + 1) % _slots.length;
      }
      usados.add(i);
      out.add((l, _slots[i].$1, _slots[i].$2));
    }
    return out;
  }();

  Listing? _selected;

  @override
  void initState() {
    super.initState();
    _selected = _listings.isEmpty ? null : _listings.first;
  }

  @override
  Widget build(BuildContext context) {
    final dark = context.isDark;
    return Scaffold(
      backgroundColor: dark ? const Color(0xFF1A2033) : RentiColors.mapBackground,
      body: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return Stack(
            children: [
              Positioned.fill(
                child: CustomPaint(painter: _StreetsPainter(dark: dark)),
              ),
              // Universidad
              Positioned(
                left: w * 0.35,
                top: h * 0.35,
                child: FractionalTranslation(
                  translation: const Offset(-0.5, -0.5),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 92,
                        height: 72,
                        decoration: BoxDecoration(
                          color: context.card,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: RentiColors.blue, width: 2.5),
                        ),
                        alignment: Alignment.center,
                        child: const Text('🎓', style: TextStyle(fontSize: 26)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Universidad',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: context.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final p in _pins)
                Positioned(
                  left: w * p.$2,
                  top: h * p.$3,
                  child: FractionalTranslation(
                    translation: const Offset(-0.5, -1),
                    child: _PricePin(
                      price: p.$1.price,
                      selected: p.$1.id == _selected?.id,
                      onTap: () => setState(() => _selected = p.$1),
                    ),
                  ),
                ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 14, 0, 0),
                  child: const CircleBackButton(),
                ),
              ),
              Positioned(
                top: 0,
                right: RentiTheme.pad,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.only(top: 20),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      'Mapa ilustrativo',
                      style: TextStyle(
                          color: context.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              if (_selected != null)
                Positioned(
                  left: RentiTheme.pad,
                  right: RentiTheme.pad,
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                  child: _MapCard(listing: _selected!),
                )
              else
                Positioned(
                  left: RentiTheme.pad,
                  right: RentiTheme.pad,
                  bottom: 24 + MediaQuery.of(context).padding.bottom,
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: context.card,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Text(
                      'No hay alojamientos con esos filtros.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: context.muted, fontSize: 16),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PricePin extends StatelessWidget {
  final int price;
  final bool selected;
  final VoidCallback onTap;
  const _PricePin({required this.price, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = selected ? RentiColors.blue : RentiColors.orange;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              formatMoney(price),
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          Transform.translate(
            offset: const Offset(0, -7),
            child: Icon(Icons.arrow_drop_down_rounded, color: color, size: 26),
          ),
        ],
      ),
    );
  }
}

class _MapCard extends StatelessWidget {
  final Listing listing;
  const _MapCard({required this.listing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: context.card,
        borderRadius: BorderRadius.circular(28),
        boxShadow: softShadow(0.18),
      ),
      child: Row(
        children: [
          ListingImage(
            width: 90,
            height: 90,
            photo: listing.cover,
            radius: const BorderRadius.all(Radius.circular(18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  listing.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  listing.distance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: context.muted, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  '${formatMoney(listing.price)} / mes',
                  style: const TextStyle(
                    color: RentiColors.orange,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                PrimaryButton(
                  label: 'Ver alojamiento',
                  height: 42,
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listing: listing),
                    ),
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

class _StreetsPainter extends CustomPainter {
  final bool dark;
  _StreetsPainter({required this.dark});

  @override
  void paint(Canvas canvas, Size s) {
    final p = Paint()
      ..color = (dark ? Colors.white10 : Colors.white.withValues(alpha: 0.6))
      ..strokeWidth = 7;
    for (final fx in [0.15, 0.41, 0.67, 0.87]) {
      canvas.drawLine(Offset(s.width * fx, 0), Offset(s.width * fx, s.height), p);
    }
    for (final fy in [0.17, 0.285, 0.4, 0.52, 0.64, 0.76]) {
      canvas.drawLine(Offset(0, s.height * fy), Offset(s.width, s.height * fy), p);
    }
  }

  @override
  bool shouldRepaint(covariant _StreetsPainter old) => old.dark != dark;
}
