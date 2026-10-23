import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/features/arrendador/publish_screen.dart';
import 'package:renti/features/perfil/notifications_screen.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/models/rental.dart';
import 'package:renti/shared/screens/listing_detail_screen.dart';

/// 21 · Panel del arrendador
class LandlordDashboardScreen extends StatelessWidget {
  const LandlordDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final list = appState.myListings;
        final rented = list.where((l) => l.status == ListingStatus.rentado).length;
        final activas = appState.rentals
            .where((r) => r.state == RentalState.activa)
            .toList();
        final income = activas.fold<int>(0, (s, r) => s + r.monthlyPrice);
        final first = appState.userName.split(' ').first;
        return RefreshList(
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Panel',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: context.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Hola, $first 👋',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: context.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const NotificationsScreen()),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: context.card,
                          shape: BoxShape.circle,
                          boxShadow: softShadow(0.1),
                        ),
                        child: Icon(Icons.notifications_none_rounded,
                            color: context.ink),
                      ),
                      if (appState.unreadNotifications > 0)
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 12,
                            height: 12,
                            decoration: const BoxDecoration(
                              color: RentiColors.orange,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                _Stat(RentiColors.blue, '${list.length}', 'Propiedades'),
                const SizedBox(width: 12),
                _Stat(RentiColors.orange, '$rented', 'Rentadas'),
                const SizedBox(width: 12),
                _Stat(RentiColors.green, '${list.length - rented}', 'Disponibles'),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(24, 22, 24, 26),
              decoration: BoxDecoration(
                color: RentiColors.blue,
                borderRadius: BorderRadius.circular(26),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ingresos mensuales (rentas activas)',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    formatMoney(income),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 40,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            WhiteCard(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
              border: Border.all(color: RentiColors.orange, width: 2),
              onTap: () => appState.setTab(2),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: const BoxDecoration(
                      color: RentiColors.yellow,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '${appState.pendingRequests}',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: RentiColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Solicitudes pendientes',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: context.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Revisa y responde a tiempo',
                          style: TextStyle(color: context.muted, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                const Expanded(child: SectionTitle('Mis propiedades')),
                GestureDetector(
                  onTap: () => appState.setTab(1),
                  child: const Text(
                    'Ver todas',
                    style: TextStyle(
                      color: RentiColors.blue,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            if (appState.loading && list.isEmpty)
              const SizedBox(height: 160, child: LoadingView())
            else if (appState.loadError != null && list.isEmpty)
              ErrorView(message: appState.loadError!, onRetry: appState.cargarTodo)
            else if (list.isEmpty)
              SizedBox(
                height: 260,
                child: EmptyView(
                  icon: Icons.add_home_work_outlined,
                  title: 'Aún no has publicado propiedades',
                  subtitle: 'Publica la primera para empezar a recibir solicitudes.',
                  actionLabel: 'Publicar propiedad',
                  onAction: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PublishScreen()),
                  ),
                ),
              )
            else
              for (final l in list.take(3))
                ListingCard(
                  listing: l,
                  showStatus: true,
                  showHeart: false,
                  locationIsAddress: true,
                  subtitle: l.publishedAgo,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => ListingDetailScreen(listing: l)),
                  ),
                ),
          ],
        );
      },
    );
  }
}

class _Stat extends StatelessWidget {
  final Color dot;
  final String value;
  final String label;
  const _Stat(this.dot, this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 16, 12, 14),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(22),
          boxShadow: softShadow(0.1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 11,
              height: 11,
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.w800,
                color: context.ink,
              ),
            ),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: TextStyle(
                  color: context.muted,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
