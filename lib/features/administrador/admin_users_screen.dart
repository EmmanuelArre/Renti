import 'package:flutter/material.dart';

import 'package:renti/core/constants/app_constants.dart';
import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';
import 'package:renti/core/widgets/buttons.dart';
import 'package:renti/core/widgets/common_widgets.dart';
import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/core/widgets/state_widgets.dart';
import 'package:renti/models/app_user.dart';

/// Usuarios: filtro por rol y suspensión/reactivación de cuentas.
class AdminUsersScreen extends StatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  State<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends State<AdminUsersScreen> {
  static const _filtros = {
    'Todos': null,
    'Arrendadores': Roles.arrendador,
    'Estudiantes': Roles.arrendatario,
    'Admins': Roles.administrador,
  };
  String _filtro = 'Todos';
  String _busqueda = '';

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final rol = _filtros[_filtro];
        final q = _busqueda.trim().toLowerCase();
        final lista = appState.adminUsers.where((u) {
          if (rol != null && u.rol != rol) return false;
          return q.isEmpty ||
              u.nombre.toLowerCase().contains(q) ||
              u.email.toLowerCase().contains(q);
        }).toList();
        return RefreshList(
          children: [
            const BigTitle('Usuarios'),
            const SizedBox(height: 14),
            TextField(
              onChanged: (v) => setState(() => _busqueda = v),
              style: TextStyle(color: context.ink),
              decoration: InputDecoration(
                hintText: 'Buscar por nombre o correo',
                prefixIcon: Icon(Icons.search_rounded, color: context.muted),
              ),
            ),
            const SizedBox(height: 12),
            FilterPills(
              options: _filtros.keys.toList(),
              selected: _filtro,
              onChanged: (v) => setState(() => _filtro = v),
            ),
            const SizedBox(height: 16),
            if (appState.loading && appState.adminUsers.isEmpty)
              const SizedBox(height: 200, child: LoadingView())
            else if (lista.isEmpty)
              const SizedBox(
                height: 260,
                child: EmptyView(
                  icon: Icons.people_outline_rounded,
                  title: 'Sin usuarios',
                  subtitle: 'No hay usuarios que coincidan con el filtro.',
                ),
              )
            else
              for (final u in lista) _UserCard(user: u),
          ],
        );
      },
    );
  }
}

class _UserCard extends StatefulWidget {
  final AppUser user;
  const _UserCard({required this.user});

  @override
  State<_UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<_UserCard> {
  bool _ocupado = false;

  Future<void> _cambiar() async {
    final u = widget.user;
    final suspender = u.activo;
    final ok = await confirmar(
      context,
      titulo: suspender ? 'Suspender cuenta' : 'Reactivar cuenta',
      mensaje: suspender
          ? '${u.nombre} no podrá iniciar sesión mientras esté suspendido.'
          : '¿Reactivar la cuenta de ${u.nombre}?',
      aceptar: suspender ? 'Suspender' : 'Reactivar',
      peligroso: suspender,
    );
    if (!ok || !mounted) return;
    setState(() => _ocupado = true);
    final error = await appState.cambiarEstadoUsuario(
        u, suspender ? EstadoCuenta.suspendido : EstadoCuenta.activo);
    if (!mounted) return;
    setState(() => _ocupado = false);
    showSnack(context, error ?? (suspender ? 'Cuenta suspendida' : 'Cuenta reactivada'));
  }

  @override
  Widget build(BuildContext context) {
    final u = widget.user;
    final esYo = u.uid == appState.user?.uid;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: WhiteCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Avatar(u.iniciales, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u.nombre,
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: context.ink)),
                    Text(u.email,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: context.muted, fontSize: 13.5)),
                  ],
                ),
              ),
              StatusBadge(
                u.activo ? 'ACTIVO' : 'SUSPENDIDO',
                color: u.activo ? RentiColors.green : Colors.redAccent,
              ),
            ]),
            const SizedBox(height: 10),
            Text(
              '${Roles.etiqueta(u.rol)}'
              '${u.universidad.isEmpty ? '' : ' · ${u.universidad}'}'
              ' · ${u.proveedor == 'google.com' ? 'Google' : 'Correo'}',
              style: TextStyle(color: context.muted, fontSize: 13.5),
            ),
            if (!esYo && !u.esAdmin) ...[
              const SizedBox(height: 12),
              SecondaryButton(
                label: u.activo ? 'Suspender' : 'Reactivar',
                height: 40,
                textColor: u.activo ? Colors.redAccent : null,
                onPressed: _ocupado ? null : _cambiar,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
