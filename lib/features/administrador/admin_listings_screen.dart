import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/shared/screens/listing_detail_screen.dart';

/// Moderación de propiedades: filtra por estado y abre el detalle, donde el
/// administrador aprueba, rechaza o desactiva.
class AdminListingsScreen extends StatefulWidget {
  const AdminListingsScreen({super.key});

  @override
  State<AdminListingsScreen> createState() => _AdminListingsScreenState();
}

class _AdminListingsScreenState extends State<AdminListingsScreen> {
  static const _filtros = {
    'Pendientes': Moderacion.pendiente,
    'Aprobadas': Moderacion.aprobada,
    'Rechazadas': Moderacion.rechazada,
    'Desactivadas': Moderacion.desactivada,
  };
  String _filtro = 'Pendientes';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final estado = _filtros[_filtro]!;
        final lista =
            appState.adminListings.where((l) => l.moderation == estado).toList();
        return RefreshList(
          children: [
            const BigTitle('Propiedades'),
            const SizedBox(height: 14),
            FilterPills(
              options: _filtros.keys.toList(),
              selected: _filtro,
              onChanged: (v) => setState(() => _filtro = v),
            ),
            const SizedBox(height: 16),
            if (appState.loading && appState.adminListings.isEmpty)
              const SizedBox(height: 200, child: LoadingView())
            else if (lista.isEmpty)
              const SizedBox(
                height: 260,
                child: EmptyView(
                  icon: Icons.home_work_outlined,
                  title: 'Nada por aquí',
                  subtitle: 'No hay propiedades en este estado.',
                ),
              )
            else
              for (final l in lista)
                ListingCard(
                  listing: l,
                  showStatus: true,
                  showHeart: false,
                  locationIsAddress: true,
                  subtitle: '${l.landlord} · ${l.publishedAgo}',
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(
                      builder: (_) => ListingDetailScreen(listing: l))),
                ),
          ],
        );
      },
    );
  }
}
