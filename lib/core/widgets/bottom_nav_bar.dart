import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../constants/app_colors.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

final bottomNavIndexProvider = StateProvider<int>((ref) => 0);

class AppBottomNavBar extends HookConsumerWidget {
  final Widget child;

  const AppBottomNavBar({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedIndex = ref.watch(bottomNavIndexProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'admin';

    // Tabs del admin
    final adminTabs = [
      const BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Inicio'),
      const BottomNavigationBarItem(icon: Icon(Icons.people_outline), activeIcon: Icon(Icons.people), label: 'Clientes'),
      const BottomNavigationBarItem(icon: Icon(Icons.receipt_long_outlined), activeIcon: Icon(Icons.receipt_long), label: 'Fichas'),
      const BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Peritajes'),
      const BottomNavigationBarItem(icon: Icon(Icons.build_outlined), activeIcon: Icon(Icons.build), label: 'Inventario'),
    ];

    // Tabs del cliente
    final clientTabs = [
      const BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Inicio'),
      const BottomNavigationBarItem(icon: Icon(Icons.directions_car_outlined), activeIcon: Icon(Icons.directions_car), label: 'Mis Autos'),
      const BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: 'Peritajes'),
      const BottomNavigationBarItem(icon: Icon(Icons.receipt_outlined), activeIcon: Icon(Icons.receipt), label: 'Facturas'),
    ];

    final tabs = isAdmin ? adminTabs : clientTabs;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 8)],
        ),
        child: BottomNavigationBar(
          currentIndex: selectedIndex >= tabs.length ? 0 : selectedIndex,
          onTap: (index) {
            ref.read(bottomNavIndexProvider.notifier).state = index;
            if (isAdmin) {
              switch (index) {
                case 0: context.go('/'); break;
                case 1: context.go('/clientes'); break;
                case 2: context.go('/recepciones'); break;
                case 3: context.go('/peritajes'); break;
                case 4: context.go('/inventario'); break;
              }
            } else {
              switch (index) {
                case 0: context.go('/'); break;
                case 1: context.go('/vehiculos'); break;
                case 2: context.go('/peritajes'); break;
                case 3: context.go('/facturas'); break;
              }
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: Colors.grey,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          items: tabs,
        ),
      ),
      floatingActionButton: isAdmin ? FloatingActionButton(
        onPressed: () {
          // TODO: Show Quick Create Sheet or QR Scanner
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.qr_code_scanner, color: Colors.white),
      ) : null,
      floatingActionButtonLocation: isAdmin ? FloatingActionButtonLocation.centerDocked : null,
    );
  }
}

