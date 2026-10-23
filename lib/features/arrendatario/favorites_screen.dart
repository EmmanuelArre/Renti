import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/shared/screens/listing_detail_screen.dart';

/// 16 · Favoritos (y 16b · estado vacío)
class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final favs = appState.favoriteListings;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(RentiTheme.pad, 14, RentiTheme.pad, 18),
              child: BigTitle('Mis favoritos'),
            ),
            Expanded(
              child: favs.isEmpty
                  ? const _Empty()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(RentiTheme.pad, 4, RentiTheme.pad, 12),
                      children: [
                        for (final l in favs)
                          ListingCard(
                            listing: l,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ListingDetailScreen(listing: l),
                              ),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: context.card,
              shape: BoxShape.circle,
              boxShadow: softShadow(0.1),
            ),
            child: const Icon(
              Icons.favorite_border_rounded,
              size: 58,
              color: RentiColors.orange,
            ),
          ),
          const SizedBox(height: 26),
          Text(
            'Guarda los espacios que\nmás te gusten ❤️',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              height: 1.35,
              color: context.ink,
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: 252,
            child: PrimaryButton(
              label: 'Explorar alojamientos',
              onPressed: () => appState.setTab(1),
            ),
          ),
          const SizedBox(height: 60),
        ],
      ),
    );
  }
}
