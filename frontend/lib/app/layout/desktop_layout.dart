import 'package:flutter/material.dart';

import 'package:barbearia_frontend/app/routes/app_router.dart';
import 'package:barbearia_frontend/core/network/api_client.dart';
import 'package:barbearia_frontend/core/responsive/app_platform.dart';

class DesktopLayout extends StatefulWidget {
  const DesktopLayout({
    super.key,
    required this.initialRoute,
    required this.initialContent,
  });

  final String initialRoute;
  final Widget initialContent;

  @override
  State<DesktopLayout> createState() => _DesktopLayoutState();

  static DesktopLayoutScope of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<DesktopLayoutScope>()!;
}

class _DesktopLayoutState extends State<DesktopLayout> {
  late String currentRoute;
  late Widget currentContent;

  @override
  void initState() {
    super.initState();
    currentRoute = widget.initialRoute;
    currentContent = widget.initialContent;
  }

  void open(String route) {
    if (route == currentRoute) return;
    setState(() {
      currentRoute = route;
      currentContent = AppRouter.desktopPage(route);
    });
  }

  Widget navigation() => SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'N&E',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                children: [
                  _navigationItem(AppRouter.home, 'Agendamentos'),
                  _navigationItem(AppRouter.catalog, 'Serviços'),
                  _navigationItem(AppRouter.dashboard, 'Dashboard'),
                ],
              ),
            ),
            if (AppPlatform.native)
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações'),
                onTap: () => open(AppRouter.settingsRoute),
              ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sair'),
              onTap: () {
                ApiClient.signOut();
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppRouter.login,
                  (_) => false,
                );
              },
            ),
          ],
        ),
      );

  Widget _navigationItem(String route, String label) => ListTile(
        selected: currentRoute == route,
        selectedTileColor: const Color(0xFFE9E9E9),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(label),
        onTap: () => open(route),
      );

  String get title => switch (currentRoute) {
        AppRouter.catalog => 'Serviços',
        AppRouter.dashboard => 'Dashboard',
        AppRouter.newAppointment => 'Novo agendamento',
        AppRouter.settingsRoute => 'Configurações',
        _ => 'Agendamentos',
      };

  @override
  Widget build(BuildContext context) {
    final scope = DesktopLayoutScope(
      open: open,
      route: currentRoute,
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F7F7),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                SizedBox(
                  width: 216,
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF303030)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: navigation(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Material(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      side: const BorderSide(color: Color(0xFF303030)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        if (currentRoute != AppRouter.home) ...[
                          SizedBox(
                            height: 56,
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'Voltar',
                                  onPressed: () => open(AppRouter.home),
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                  ),
                                  child: Text(
                                    title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                        ],
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 150),
                            child: KeyedSubtree(
                              key: ValueKey(currentRoute),
                              child: currentContent,
                            ),
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
      ),
    );
    return scope;
  }
}

class DesktopLayoutScope extends InheritedWidget {
  const DesktopLayoutScope({
    super.key,
    required this.open,
    required this.route,
    required super.child,
  });

  final void Function(String route) open;
  final String route;

  @override
  bool updateShouldNotify(DesktopLayoutScope oldWidget) =>
      route != oldWidget.route;
}
