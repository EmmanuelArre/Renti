import 'package:flutter/material.dart';

import 'package:renti/core/state/app_state.dart';
import 'package:renti/core/widgets/bottom_nav.dart';
import 'package:renti/core/widgets/state_widgets.dart';

/// Contenedor con menú inferior que comparten los tres roles. Cada rol aporta
/// sus propias pestañas (en el mismo orden que [navItemsForCurrentRole]).
class RoleShell extends StatelessWidget {
  final List<Widget> tabs;
  const RoleShell({super.key, required this.tabs});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final index = appState.tab.clamp(0, tabs.length - 1).toInt();
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                if (appState.offline) const OfflineBanner(),
                if (appState.loading)
                  const LinearProgressIndicator(minHeight: 2),
                Expanded(
                  child: IndexedStack(index: index, children: tabs),
                ),
              ],
            ),
          ),
          bottomNavigationBar: RentiBottomNav(
            current: index,
            onTap: appState.setTab,
          ),
        );
      },
    );
  }
}

/// Lista con "tirar para actualizar" que recarga los datos del rol.
class RefreshList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsets padding;
  const RefreshList({
    super.key,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(24, 14, 24, 24),
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () => appState.isAdmin
          ? appState.recargarAdmin()
          : appState.cargarTodo(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: children,
      ),
    );
  }
}
