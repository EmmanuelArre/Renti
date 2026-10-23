import 'package:flutter/material.dart';

import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/features/arrendador/landlord_dashboard_screen.dart';
import 'package:renti/features/arrendador/landlord_history_screen.dart';
import 'package:renti/features/arrendador/my_listings_screen.dart';
import 'package:renti/features/arrendador/requests_screen.dart';
import 'package:renti/features/perfil/profile_screen.dart';

/// Menú del arrendador: Panel · Propiedades · Solicitudes · Historial · Perfil.
class LandlordShell extends StatelessWidget {
  const LandlordShell({super.key});

  @override
  Widget build(BuildContext context) => const RoleShell(
        tabs: [
          LandlordDashboardScreen(),
          MyListingsScreen(),
          RequestsScreen(),
          LandlordHistoryScreen(),
          ProfileScreen(),
        ],
      );
}
