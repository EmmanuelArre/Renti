import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/theme/app_theme.dart';

class NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  const NavItem(this.icon, this.activeIcon, this.label);
}

const _tenantItems = [
  NavItem(Icons.home_outlined, Icons.home_rounded, 'Inicio'),
  NavItem(Icons.search_rounded, Icons.search_rounded, 'Buscar'),
  NavItem(Icons.favorite_border_rounded, Icons.favorite_rounded, 'Favoritos'),
  NavItem(Icons.calendar_today_outlined, Icons.calendar_today_rounded, 'Rentas'),
  NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
];

const _landlordItems = [
  NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Panel'),
  NavItem(Icons.home_work_outlined, Icons.home_work_rounded, 'Propiedades'),
  NavItem(Icons.inbox_outlined, Icons.inbox_rounded, 'Solicitudes'),
  NavItem(Icons.history_rounded, Icons.history_rounded, 'Historial'),
  NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
];

const _adminItems = [
  NavItem(Icons.dashboard_outlined, Icons.dashboard_rounded, 'Panel'),
  NavItem(Icons.people_outline_rounded, Icons.people_rounded, 'Usuarios'),
  NavItem(Icons.home_work_outlined, Icons.home_work_rounded, 'Propiedades'),
  NavItem(Icons.flag_outlined, Icons.flag_rounded, 'Reportes'),
  NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Perfil'),
];

/// Pestañas del menú inferior según el rol de la sesión actual.
List<NavItem> navItemsForCurrentRole() {
  if (appState.isAdmin) return _adminItems;
  if (appState.isLandlord) return _landlordItems;
  return _tenantItems;
}

/// Menú inferior de 5 pestañas con punto indicador azul.
class RentiBottomNav extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const RentiBottomNav({super.key, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final items = navItemsForCurrentRole();
    return Container(
      decoration: BoxDecoration(
        color: context.card,
        border: Border(top: BorderSide(color: context.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 72,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: InkWell(
                    onTap: () => onTap(i),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: i == current ? RentiColors.blue : Colors.transparent,
                          ),
                        ),
                        Icon(
                          i == current ? items[i].activeIcon : items[i].icon,
                          size: 26,
                          color: i == current ? RentiColors.blue : context.muted,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          items[i].label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: i == current ? RentiColors.blue : context.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scaffold para pantallas empujadas que igualmente muestran el menú inferior
/// (Resultados, Mensajes, Mis alojamientos, Solicitudes…).
class NavScaffold extends StatelessWidget {
  final int current;
  final Widget body;
  const NavScaffold({super.key, required this.current, required this.body});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(bottom: false, child: body),
      bottomNavigationBar: RentiBottomNav(
        current: current,
        onTap: (i) {
          appState.setTab(i);
          Navigator.of(context).popUntil((r) => r.isFirst);
        },
      ),
    );
  }
}
