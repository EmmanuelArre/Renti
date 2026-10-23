import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';

final Map<String, Uint8List> _photoCache = {};

/// Decodifica una foto base64 (con caché para no repetir el trabajo al
/// reconstruir listas). Devuelve null si no hay foto o es inválida.
Uint8List? decodePhoto(String? b64) {
  if (b64 == null || b64.isEmpty) return null;
  final key = '${b64.length}:${b64.hashCode}';
  final cached = _photoCache[key];
  if (cached != null) return cached;
  try {
    final bytes = base64Decode(b64);
    if (_photoCache.length > 60) _photoCache.clear();
    return _photoCache[key] = bytes;
  } catch (_) {
    return null;
  }
}

/// Imagen de relleno (degradado azul → naranja con casita) o la foto real.
class ListingImage extends StatelessWidget {
  final double? height;
  final double? width;
  final BorderRadius radius;
  final Widget? overlay;

  /// Foto en base64 (miniatura de portada o foto completa). Si es null o no
  /// se puede decodificar, se muestra el degradado con la casita.
  final String? photo;
  const ListingImage({
    super.key,
    this.height,
    this.width,
    this.radius = const BorderRadius.all(Radius.circular(24)),
    this.overlay,
    this.photo,
  });

  @override
  Widget build(BuildContext context) {
    final bytes = decodePhoto(photo);
    return Container(
      height: height,
      width: width,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RentiColors.blue, RentiColors.orange],
        ),
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (bytes != null)
            Image.memory(
              bytes,
              fit: BoxFit.cover,
              gaplessPlayback: true,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
          if (bytes == null) Positioned(
            left: 28,
            top: 22,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
          ),
          if (bytes == null)
            Center(
              child: FittedBox(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.home_rounded,
                    size: 90,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ),
            ),
          if (overlay != null) overlay!,
        ],
      ),
    );
  }
}

/// Tarjeta grande de alojamiento (resultados, favoritos, mis alojamientos).
class ListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  final bool showStatus;
  final bool locationIsAddress;
  final bool showHeart;
  final String? subtitle; // reemplaza la ubicación (ej. "Publicado hace 2 semanas")
  final Widget? footer; // acciones debajo de la información (editar, etc.)
  const ListingCard({
    super.key,
    required this.listing,
    required this.onTap,
    this.showStatus = false,
    this.locationIsAddress = false,
    this.showHeart = true,
    this.subtitle,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final fav = appState.isFavorite(listing.id);
        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(24),
              boxShadow: softShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListingImage(
                  height: 190,
                  photo: listing.cover,
                  radius: const BorderRadius.vertical(top: Radius.circular(24)),
                  overlay: Stack(
                    children: [
                      if (showStatus)
                        Positioned(
                          left: 14,
                          top: 14,
                          child: StatusBadge(
                            listing.status == ListingStatus.rentado
                                ? 'RENTADO'
                                : 'DISPONIBLE',
                            color: listing.status == ListingStatus.rentado
                                ? RentiColors.orange
                                : RentiColors.green,
                          ),
                        ),
                      if (showHeart && appState.isTenant)
                        Positioned(
                          right: 14,
                          top: 14,
                          child: HeartButton(
                            active: fav,
                            size: 36,
                            onTap: () => toggleFavoriteWithFeedback(context, listing),
                          ),
                        ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: context.ink,
                              ),
                            ),
                          ),
                          if (listing.rating != null) ...[
                            const Icon(Icons.star_rounded,
                                color: RentiColors.yellow, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              listing.rating!.toStringAsFixed(1),
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                color: context.ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.location_on, size: 16, color: Colors.redAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              subtitle ?? (locationIsAddress ? listing.address : listing.distance),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: context.muted, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${formatMoney(listing.price)} / mes',
                        style: const TextStyle(
                          color: RentiColors.orange,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                if (footer != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    child: footer!,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Tarjeta compacta del carrusel "Recomendados para ti".
class CompactListingCard extends StatelessWidget {
  final Listing listing;
  final VoidCallback onTap;
  const CompactListingCard({super.key, required this.listing, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: 218,
            margin: const EdgeInsets.only(bottom: 14, right: 12),
            decoration: BoxDecoration(
              color: context.card,
              borderRadius: BorderRadius.circular(22),
              boxShadow: softShadow(),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ListingImage(
                  height: 104,
                  photo: listing.cover,
                  radius: const BorderRadius.vertical(top: Radius.circular(22)),
                  overlay: appState.isTenant
                      ? Positioned(
                          right: 12,
                          top: 12,
                          child: HeartButton(
                            active: appState.isFavorite(listing.id),
                            onTap: () =>
                                toggleFavoriteWithFeedback(context, listing),
                          ),
                        )
                      : null,
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              listing.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: context.ink,
                              ),
                            ),
                          ),
                          if (listing.rating != null) ...[
                            const Icon(Icons.star_rounded,
                                color: RentiColors.yellow, size: 17),
                            Text(
                              ' ${listing.rating!.toStringAsFixed(1)}',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: context.ink,
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📍 ${listing.distance}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.muted, fontSize: 12.5),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${formatMoney(listing.price)} / mes',
                        style: const TextStyle(
                          color: RentiColors.orange,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


/// Alterna el favorito y avisa si el servidor rechazó el cambio.
Future<void> toggleFavoriteWithFeedback(
    BuildContext context, Listing listing) async {
  final error = await appState.toggleFavorite(listing);
  if (error != null && context.mounted) showSnack(context, error);
}
