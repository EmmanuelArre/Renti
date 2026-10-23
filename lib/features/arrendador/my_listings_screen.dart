import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/features/arrendador/publish_screen.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/shared/screens/listing_detail_screen.dart';

/// 22 · Mis propiedades: editar, cambiar disponibilidad y eliminar.
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final list = appState.myListings;
        return RefreshList(
          children: [
            Row(
              children: [
                const Expanded(child: BigTitle('Mis propiedades')),
                GestureDetector(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PublishScreen()),
                  ),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: RentiColors.orange,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: const Text(
                      '+ Publicar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            if (appState.loading && list.isEmpty)
              const SizedBox(height: 200, child: LoadingView())
            else if (list.isEmpty)
              const SizedBox(
                height: 320,
                child: EmptyView(
                  icon: Icons.add_home_work_outlined,
                  title: 'No tienes propiedades publicadas',
                  subtitle: 'Toca "+ Publicar" para agregar la primera.',
                ),
              )
            else
              for (final l in list)
                ListingCard(
                  listing: l,
                  showStatus: true,
                  showHeart: false,
                  locationIsAddress: true,
                  subtitle: '${Moderacion.etiqueta(l.moderation)} · ${l.publishedAgo}',
                  footer: _Actions(listing: l),
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

class _Actions extends StatefulWidget {
  final Listing listing;
  const _Actions({required this.listing});

  @override
  State<_Actions> createState() => _ActionsState();
}

class _ActionsState extends State<_Actions> {
  bool _ocupado = false;

  Future<void> _cambiarDisponibilidad() async {
    final l = widget.listing;
    final nuevo = l.isAvailable ? ListingStatus.rentado : ListingStatus.disponible;
    setState(() => _ocupado = true);
    final error = await appState.cambiarDisponibilidad(l, nuevo);
    if (!mounted) return;
    setState(() => _ocupado = false);
    showSnack(
        context,
        error ??
            (nuevo == ListingStatus.rentado
                ? 'Marcada como rentada'
                : 'Marcada como disponible'));
  }

  Future<void> _eliminar() async {
    final l = widget.listing;
    final ok = await confirmar(
      context,
      titulo: 'Eliminar propiedad',
      mensaje: '¿Eliminar "${l.title}"? Se borrarán sus fotos y se rechazarán '
          'las solicitudes pendientes. Esta acción no se puede deshacer.',
      aceptar: 'Eliminar',
      peligroso: true,
    );
    if (!ok || !mounted) return;
    setState(() => _ocupado = true);
    final error = await appState.eliminarPropiedad(l);
    if (!mounted) return;
    setState(() => _ocupado = false);
    showSnack(context, error ?? 'Propiedad eliminada');
  }

  @override
  Widget build(BuildContext context) {
    final l = widget.listing;
    final editable = l.moderation != Moderacion.desactivada;
    return Column(
      children: [
        if (l.moderation == Moderacion.rechazada ||
            l.moderation == Moderacion.desactivada)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text(
              l.moderation == Moderacion.rechazada
                  ? 'El administrador rechazó esta publicación. Edítala para volver a enviarla a revisión.'
                  : 'El administrador desactivó esta publicación.',
              style: const TextStyle(color: Colors.redAccent, fontSize: 13),
            ),
          ),
        Row(
          children: [
            Expanded(
              child: SecondaryButton(
                label: 'Editar',
                height: 42,
                onPressed: _ocupado || !editable
                    ? null
                    : () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => PublishScreen(editing: l)),
                        ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: SecondaryButton(
                label: l.isAvailable ? 'Marcar rentada' : 'Marcar libre',
                height: 42,
                onPressed: _ocupado ? null : _cambiarDisponibilidad,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              child: SecondaryButton(
                label: '🗑',
                height: 42,
                onPressed: _ocupado ? null : _eliminar,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
