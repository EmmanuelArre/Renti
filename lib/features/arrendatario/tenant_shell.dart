import 'package:flutter/material.dart';

import 'package:renti/core/widgets/role_shell.dart';
import 'package:renti/features/arrendatario/favorites_screen.dart';
import 'package:renti/features/arrendatario/home_screen.dart';
import 'package:renti/features/arrendatario/my_rentals_screen.dart';
import 'package:renti/features/arrendatario/search_screen.dart';
import 'package:renti/features/perfil/profile_screen.dart';

/// Menú del estudiante: Inicio · Buscar · Favoritos · Rentas · Perfil.
class TenantShell extends StatelessWidget {
  const TenantShell({super.key});

  @override
  Widget build(BuildContext context) => const RoleShell(
        tabs: [
          HomeScreen(),
          SearchScreen(),
          FavoritesScreen(),
          MyRentalsScreen(),
          ProfileScreen(),
        ],
      );
}
