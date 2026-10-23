import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/features/arrendatario/results_screen.dart';
import 'package:renti/features/perfil/notifications_screen.dart';
import 'package:renti/shared/screens/listing_detail_screen.dart';
import 'package:renti/shared/screens/messages_screen.dart';

/// 04 · Inicio
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final first = appState.userName.split(' ').first;
        final recomendados = ([...appState.listings]
              ..sort((a, b) => (b.rating ?? 0).compareTo(a.rating ?? 0)))
            .take(6)
            .toList();
        return RefreshList(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        first.isEmpty ? 'Hola 👋' : 'Hola, $first 👋',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '¿Dónde quieres vivir?',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                _RoundAction(
                  icon: Icons.notifications_none_rounded,
                  badge: appState.unreadNotifications,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                ),
                const SizedBox(width: 8),
                _RoundAction(
                  icon: Icons.chat_bubble_outline_rounded,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MessagesScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: () => appState.setTab(1),
              child: Container(
                height: 66,
                padding: const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: context.card,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: softShadow(0.1),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: context.muted, size: 28),
                    const SizedBox(width: 14),
                    Text(
                      'Ciudad, universidad o zona',
                      style: TextStyle(color: context.muted, fontSize: 17),
                    ),
                  ],
                ),
              ),
            ),
            const SectionTitle('Explora por tipo',
                padding: EdgeInsets.fromLTRB(0, 26, 0, 14)),
            Row(
              children: [
                for (var i = 0; i < Catalogos.categorias.length; i++) ...[
                  if (i > 0) const SizedBox(width: 10),
                  Expanded(
                    child: _Category(
                      Catalogos.categorias[i].$1,
                      Catalogos.categorias[i].$2,
                    ),
                  ),
                ],
              ],
            ),
            const SectionTitle('Recomendados para ti',
                padding: EdgeInsets.fromLTRB(0, 24, 0, 14)),
            if (appState.loading && appState.listings.isEmpty)
              const SizedBox(height: 180, child: LoadingView())
            else if (appState.loadError != null && appState.listings.isEmpty)
              ErrorView(
                message: appState.loadError!,
                onRetry: appState.cargarTodo,
              )
            else if (recomendados.isEmpty)
              const SizedBox(
                height: 220,
                child: EmptyView(
                  icon: Icons.home_work_outlined,
                  title: 'Aún no hay alojamientos publicados',
                  subtitle: 'Vuelve pronto o desliza hacia abajo para actualizar.',
                ),
              )
            else
              SizedBox(
                height: 232,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    for (final l in recomendados)
                      CompactListingCard(
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
        );
      },
    );
  }
}

class _RoundAction extends StatelessWidget {
  final IconData icon;
  final int badge;
  final VoidCallback onTap;
  const _RoundAction({required this.icon, required this.onTap, this.badge = 0});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 42,
            height: 42,
            margin: const EdgeInsets.only(top: 4),
            decoration: BoxDecoration(
              color: context.card,
              shape: BoxShape.circle,
              boxShadow: softShadow(0.1),
            ),
            child: Icon(icon, size: 21, color: context.ink),
          ),
          if (badge > 0)
            Positioned(
              right: -2,
              top: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: RentiColors.orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  badge > 9 ? '9+' : '$badge',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Category extends StatelessWidget {
  final String emoji;
  final String label;
  const _Category(this.emoji, this.label);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        appState.filters.types = {label};
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ResultsScreen()),
        );
      },
      child: Container(
        height: 78,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(20),
          boxShadow: softShadow(0.1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(emoji, style: const TextStyle(fontSize: 26)),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
