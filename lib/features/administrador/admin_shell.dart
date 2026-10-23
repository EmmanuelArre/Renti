import 'package:flutter/material.dart';

import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/features/administrador/admin_dashboard_screen.dart';
import 'package:renti/features/administrador/admin_listings_screen.dart';
import 'package:renti/features/administrador/admin_reports_screen.dart';
import 'package:renti/features/administrador/admin_users_screen.dart';
import 'package:renti/features/perfil/profile_screen.dart';

/// Menú del administrador: Panel · Usuarios · Propiedades · Reportes · Perfil.
class AdminShell extends StatelessWidget {
  const AdminShell({super.key});

  @override
  Widget build(BuildContext context) => const RoleShell(
        tabs: [
          AdminDashboardScreen(),
          AdminUsersScreen(),
          AdminListingsScreen(),
          AdminReportsScreen(),
          ProfileScreen(),
        ],
      );
}
