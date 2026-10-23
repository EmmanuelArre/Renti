import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/form_widgets.dart';
import 'package:renti/core/widgets/listing_widgets.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/features/arrendador/publish_screen.dart';
import 'package:renti/features/arrendatario/duration_screen.dart';
import 'package:renti/models/listing.dart';
import 'package:renti/repositories/property_repository.dart';
import 'package:renti/shared/screens/chat_screen.dart';
import 'package:renti/shared/widgets/report_sheet.dart';

/// 09 · Detalle del alojamiento (estudiante, arrendador dueño o administrador).
class ListingDetailScreen extends StatefulWidget {
  final Listing listing;
  const ListingDetailScreen({super.key, required this.listing});

  @override
  State<ListingDetailScreen> createState() => _ListingDetailScreenState();
}

class _ListingDetailScreenState extends State<ListingDetailScreen> {
  List<String> _fotos = const [];
  bool _cargandoFotos = true;
  int _pagina = 0;

  Listing get l => widget.listing;

  @override
  void initState() {
    super.initState();
    _cargarFotos();
  }

  Future<void> _cargarFotos() async {
    try {
      final f = await PropertyRepository.instance.imagenes(l.id);
      if (mounted) setState(() => _fotos = f);
    } catch (_) {
      // Se queda con la portada.
    } finally {
      if (mounted) setState(() => _cargandoFotos = false);
    }
  }

  bool get _esDueno => appState.user?.uid == l.ownerId;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    final fotos = _fotos.isNotEmpty
        ? _fotos
        : (l.cover == null ? const <String>[] : <String>[l.cover!]);
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  SizedBox(
                    height: 320,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (fotos.isEmpty)
                          const ListingImage(radius: BorderRadius.zero)
                        else
                          PageView.builder(
                            itemCount: fotos.length,
                            onPageChanged: (i) => setState(() => _pagina = i),
                            itemBuilder: (_, i) => ListingImage(
                              photo: fotos[i],
                              radius: BorderRadius.zero,
                            ),
                          ),
                        if (_cargandoFotos)
                          const Positioned(
                            right: 16,
                            bottom: 48,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2.4, color: Colors.white),
                            ),
                          ),
                        Positioned(
                          left: RentiTheme.pad,
                          top: top + 12,
                          child: const CircleBackButton(),
                        ),
                        if (appState.isTenant)
                          Positioned(
                            right: RentiTheme.pad,
                            top: top + 12,
                            child: ListenableBuilder(
                              listenable: appState,
                              builder: (_, __) => HeartButton(
                                active: appState.isFavorite(l.id),
                                size: 40,
                                onTap: () =>
                                    toggleFavoriteWithFeedback(context, l),
                              ),
                            ),
                          ),
                        if (fotos.length > 1)
                          Positioned(
                            bottom: 40,
                            left: 0,
                            right: 0,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                for (var i = 0; i < fotos.length; i++)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    margin:
                                        const EdgeInsets.symmetric(horizontal: 4),
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: i == _pagina
                                          ? Colors.white
                                          : Colors.white.withValues(alpha: 0.45),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -24),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                          RentiTheme.pad, 24, RentiTheme.pad, 8),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(30)),
                      ),
                      child: _Body(listing: l, esDueno: _esDueno),
                    ),
                  ),
                ],
              ),
            ),
          ),
          _BottomBar(listing: l, esDueno: _esDueno),
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  final Listing listing;
  final bool esDueno;
  const _BottomBar({required this.listing, required this.esDueno});

  @override
  Widget build(BuildContext context) {
    Widget? contenido;
    if (appState.isTenant) {
      final disponible = listing.isPublic;
      contenido = Row(
        children: [
          Expanded(
            child: SecondaryButton(
              label: 'Contactar',
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ChatScreen(otherId: listing.ownerId, name: listing.landlord),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PrimaryButton(
              label: disponible ? 'Reservar' : 'No disponible',
              onPressed: disponible
                  ? () => Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DurationScreen(listing: listing),
                        ),
                      )
                  : null,
            ),
          ),
        ],
      );
    } else if (appState.isLandlord && esDueno) {
      contenido = PrimaryButton(
        label: 'Editar propiedad',
        onPressed: () async {
          final nav = Navigator.of(context);
          await nav.push(
            MaterialPageRoute(builder: (_) => PublishScreen(editing: listing)),
          );
          // Al volver, esta copia ya pudo cambiar: se cierra el detalle.
          if (context.mounted) nav.pop();
        },
      );
    } else if (appState.isAdmin) {
      contenido = _AdminActions(listing: listing);
    }
    if (contenido == null) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.fromLTRB(
        RentiTheme.pad,
        14,
        RentiTheme.pad,
        14 + MediaQuery.of(context).padding.bottom,
      ),
      decoration: BoxDecoration(
        color: context.card,
        border: Border(top: BorderSide(color: context.line)),
      ),
      child: contenido,
    );
  }
}

class _AdminActions extends StatefulWidget {
  final Listing listing;
  const _AdminActions({required this.listing});

  @override
  State<_AdminActions> createState() => _AdminActionsState();
}

class _AdminActionsState extends State<_AdminActions> {
  bool _ocupado = false;

  Future<void> _moderar(String estado) async {
    String motivo = '';
    if (estado != Moderacion.aprobada) {
      final texto = await pedirMotivo(context, estado);
      if (texto == null) return; // canceló
      motivo = texto;
    }
    setState(() => _ocupado = true);
    final error =
        await appState.moderarPropiedad(widget.listing, estado, motivo: motivo);
    if (!mounted) return;
    setState(() => _ocupado = false);
    if (error != null) {
      showSnack(context, error);
      return;
    }
    Navigator.of(context).pop();
    showSnack(context, 'Publicación ${Moderacion.etiqueta(estado).toLowerCase()}');
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: PrimaryButton(
            label: 'Aprobar',
            color: RentiColors.green,
            height: 50,
            loading: _ocupado,
            onPressed: () => _moderar(Moderacion.aprobada),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SecondaryButton(
            label: 'Rechazar',
            height: 50,
            onPressed: _ocupado ? null : () => _moderar(Moderacion.rechazada),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: SecondaryButton(
            label: 'Desactivar',
            height: 50,
            textColor: Colors.redAccent,
            onPressed: _ocupado ? null : () => _moderar(Moderacion.desactivada),
          ),
        ),
      ],
    );
  }
}

/// Pide al administrador una nota al rechazar o desactivar. Devuelve null si
/// cancela.
Future<String?> pedirMotivo(BuildContext context, String estado) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(estado == Moderacion.rechazada
          ? 'Rechazar publicación'
          : 'Desactivar publicación'),
      content: TextField(
        controller: c,
        maxLines: 3,
        maxLength: 200,
        decoration: const InputDecoration(
          hintText: 'Motivo (se enviará al arrendador)',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(ctx, c.text.trim()),
          child: const Text('Confirmar'),
        ),
      ],
    ),
  );
}

class _Body extends StatelessWidget {
  final Listing listing;
  final bool esDueno;
  const _Body({required this.listing, required this.esDueno});

  String get _initials => listing.landlord
      .split(' ')
      .where((s) => s.isNotEmpty)
      .take(2)
      .map((s) => s[0])
      .join();

  @override
  Widget build(BuildContext context) {
    final feats = <String>[
      '🛏️ ${listing.bedrooms} habitación${listing.bedrooms == 1 ? '' : 'es'}',
      '🚿 ${listing.bathrooms} baño${listing.bathrooms == 1 ? '' : 's'}',
      if (listing.services.contains('Wi-Fi')) '📶 Wi-Fi',
      if (listing.shared) '👥 Compartido',
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (esDueno || appState.isAdmin) ...[
          Row(
            children: [
              StatusBadge(
                Moderacion.etiqueta(listing.moderation),
                color: listing.moderation == Moderacion.aprobada
                    ? RentiColors.green
                    : listing.moderation == Moderacion.pendiente
                        ? RentiColors.yellow
                        : RentiColors.orange,
                textColor: listing.moderation == Moderacion.pendiente
                    ? RentiColors.ink
                    : Colors.white,
              ),
              const SizedBox(width: 8),
              StatusBadge(
                listing.isAvailable ? 'DISPONIBLE' : 'RENTADO',
                color: listing.isAvailable ? RentiColors.green : RentiColors.blue,
              ),
            ],
          ),
          const SizedBox(height: 14),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                listing.title,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: context.ink,
                ),
              ),
            ),
            if (listing.rating != null) ...[
              const Icon(Icons.star_rounded, color: RentiColors.yellow, size: 22),
              const SizedBox(width: 4),
              Text(
                '${listing.rating!.toStringAsFixed(1)} · ${listing.reviews} reseñas',
                style: TextStyle(fontWeight: FontWeight.w800, color: context.ink),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '📍 ${listing.distance.replaceAll('de la universidad', 'de tu universidad')}',
          style: TextStyle(
            color: context.muted,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          listing.address,
          style: TextStyle(color: context.muted, fontSize: 14),
        ),
        const SizedBox(height: 10),
        Text(
          '${formatMoney(listing.price)} / mes',
          style: const TextStyle(
            color: RentiColors.orange,
            fontSize: 26,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [for (final f in feats) _FeatureChip(f)],
        ),
        const SectionTitle('Servicios incluidos',
            padding: EdgeInsets.fromLTRB(0, 24, 0, 12)),
        PillWrap(
          options: listing.services,
          isSelected: (_) => false,
          onTap: (_) {},
        ),
        const SectionTitle('Sobre este alojamiento',
            padding: EdgeInsets.fromLTRB(0, 24, 0, 8)),
        Text(
          listing.description,
          style: TextStyle(color: context.muted, fontSize: 16, height: 1.45),
        ),
        const SectionTitle('Arrendador', padding: EdgeInsets.fromLTRB(0, 22, 0, 12)),
        Row(
          children: [
            Avatar(_initials, size: 56),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    listing.landlord,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    listing.publishedAgo,
                    style: TextStyle(color: context.muted, fontSize: 13.5),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (appState.isTenant) ...[
          const SizedBox(height: 18),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => mostrarReporte(
                context,
                tipo: TipoReporte.propiedad,
                objetivoId: listing.id,
                objetivoNombre: listing.title,
              ),
              icon: const Icon(Icons.flag_outlined, size: 18, color: Colors.redAccent),
              label: const Text(
                'Reportar esta publicación',
                style: TextStyle(
                    color: Colors.redAccent, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
        const SizedBox(height: 16),
      ],
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String text;
  const _FeatureChip(this.text);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: context.card,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: context.line, width: 1.5),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: context.ink,
          ),
        ),
      );
}
