import 'package:barbearia_frontend/app/theme/app_theme.dart';
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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  late String currentRoute;
  late Widget currentContent;

  @override
  void initState() {
    super.initState();
    currentRoute = widget.initialRoute;
    currentContent = widget.initialContent;
  }

  void open(String route) {
    _scaffoldKey.currentState?.closeDrawer();
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
                  for (final (route, label) in AppRouter.adminDestinations)
                    _navigationItem(route, label),
                  if (AppPlatform.web) logoutButton(),
                ],
              ),
            ),
            if (AppPlatform.native)
              ListTile(
                leading: const Icon(Icons.settings_outlined),
                title: const Text('Configurações'),
                onTap: () => open(AppRouter.settingsRoute),
              ),
            if (AppPlatform.native) logoutButton(),
          ],
        ),
      );

  Widget logoutButton() => ListTile(
        leading: const Icon(Icons.logout),
        title: const Text('Sair'),
        onTap: () async {
          try {
            await ApiClient.logout();
          } catch (error) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Não foi possível sair. $error')),
              );
            }
            return;
          }
          if (!mounted) return;
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRouter.login,
            (_) => false,
          );
        },
      );

  Widget _navigationItem(String route, String label) => ListTile(
        selected: currentRoute == route,
        selectedTileColor: Theme.of(context).colorScheme.secondaryContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        title: Text(label),
        onTap: () => open(route),
      );

  String get title => switch (currentRoute) {
        AppRouter.catalog => 'Serviços',
        AppRouter.dashboard => 'Dashboard',
        AppRouter.employees => 'Funcionários',
        AppRouter.availability => 'Disponibilidade',
        AppRouter.newAppointment => 'Novo agendamento',
        AppRouter.settingsRoute => 'Configurações',
        _ => 'Agendamentos',
      };

  @override
  Widget build(BuildContext context) {
    final scope = DesktopLayoutScope(
      open: open,
      route: currentRoute,
      child: LayoutBuilder(builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return Scaffold(
          key: _scaffoldKey,
          appBar: wide
              ? null
              : AppBar(
                  title: Text(title), actions: const [ThemeToggleButton()]),
          drawer: wide ? null : Drawer(child: navigation()),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainerLow,
          body: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(wide ? 12 : 0),
              child: Row(
                children: [
                  if (wide)
                    SizedBox(
                      width: 216,
                      child: Material(
                        color: Theme.of(context).colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: Color(0xFF303030)),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: navigation(),
                      ),
                    ),
                  if (wide) const SizedBox(width: 12),
                  Expanded(
                    key: const ValueKey('admin-content'),
                    child: Material(
                      color: Theme.of(context).colorScheme.surface,
                      shape: wide
                          ? RoundedRectangleBorder(
                              side: const BorderSide(color: Color(0xFF303030)),
                              borderRadius: BorderRadius.circular(16),
                            )
                          : null,
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          if (wide)
                            const Align(
                              alignment: Alignment.centerRight,
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: ThemeToggleButton(),
                              ),
                            ),
                          if (wide && currentRoute != AppRouter.home) ...[
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
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(height: 1),
                          ],
                          Expanded(
                            key: const ValueKey('page-content'),
                            child: KeyedSubtree(
                              key: ValueKey(currentRoute),
                              child: currentContent,
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
      }),
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
