import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/clientes/presentation/pages/cliente_form_page.dart';
import '../../features/vehiculos/presentation/pages/vehiculos_page.dart';
import '../../features/recepciones/presentation/pages/recepciones_page.dart';
import '../../features/peritajes/presentation/pages/peritajes_page.dart';
import '../../features/peritajes/presentation/pages/peritaje_form_page.dart';
import '../../features/peritajes/presentation/pages/informe_peritaje_page.dart';
import '../../features/peritajes/presentation/pages/camera_page.dart';
import '../../features/recepciones/presentation/pages/recepcion_form_page.dart';
import '../../features/inventario/presentation/pages/inventario_page.dart';
import '../../features/finanzas/presentation/pages/facturas_page.dart';
import '../../features/finanzas/presentation/pages/metodos_pago_page.dart';
import '../../features/cliente_portal/presentation/pages/consulta_cliente_page.dart';
import '../../features/cliente_portal/presentation/pages/portal_cliente_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../models/cliente.dart';
import '../../models/vehiculo.dart';
import '../../models/peritaje.dart';
import '../widgets/bottom_nav_bar.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';
      final isGuestRoute = state.matchedLocation.startsWith('/consulta-cliente') ||
          state.matchedLocation.startsWith('/portal-cliente') ||
          state.matchedLocation.startsWith('/peritajes/informe');

      if (!isLoggedIn && !isLoggingIn && !isGuestRoute) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginPage()),
      GoRoute(
        path: '/consulta-cliente',
        builder: (context, state) => const ConsultaClientePage(),
      ),
      GoRoute(
        path: '/portal-cliente',
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final vehicle = extra?['vehicle'] as Vehiculo?;
          final client = extra?['client'] as Cliente?;
          if (vehicle == null) {
            return Scaffold(
              appBar: AppBar(title: const Text('Portal del Cliente')),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_car_outlined, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Vehículo no encontrado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No se proporcionaron datos del vehículo para mostrar en el portal.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        onPressed: () => context.go('/consulta-cliente'),
                        icon: const Icon(Icons.search),
                        label: const Text('Volver a Consulta'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
          return PortalClientePage(vehicle: vehicle, client: client);
        },
      ),
      GoRoute(
        path: '/peritajes/informe',
        builder: (context, state) {
          if (state.extra is Peritaje) {
            final peritaje = state.extra as Peritaje;
            return InformePeritajePage(
              peritaje: peritaje,
              isGuestMode: !authState.isAuthenticated,
            );
          } else if (state.extra is Map<String, dynamic>) {
            final map = state.extra as Map<String, dynamic>;
            final peritaje = map['peritaje'] as Peritaje;
            final isGuest = (map['isGuestMode'] as bool?) ?? !authState.isAuthenticated;
            return InformePeritajePage(
              peritaje: peritaje,
              isGuestMode: isGuest,
            );
          }
          return Scaffold(
            appBar: AppBar(title: const Text('Informe de Peritaje')),
            body: const Center(child: Text('No se encontraron datos del peritaje')),
          );
        },
      ),
      ShellRoute(
        builder: (context, state, child) {
          return AppBottomNavBar(child: child);
        },
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => const DashboardPage(),
          ),
          GoRoute(
            path: '/clientes',
            builder: (context, state) => const ClientesPage(),
          ),
          GoRoute(
            path: '/vehiculos',
            builder: (context, state) => const VehiculosPage(),
          ),
          GoRoute(
            path: '/recepciones',
            builder: (context, state) => const RecepcionesPage(),
          ),
          GoRoute(
            path: '/peritajes',
            builder: (context, state) => const PeritajesPage(),
          ),
          GoRoute(
            path: '/inventario',
            builder: (context, state) => const InventarioPage(),
          ),
          GoRoute(
            path: '/facturas',
            builder: (context, state) => const FacturasPage(),
          ),
          GoRoute(
            path: '/metodos-pago',
            builder: (context, state) => const MetodosPagoPage(),
          ),
        ],
      ),
      GoRoute(
        path: '/clientes/nuevo',
        builder: (context, state) => const ClienteFormPage(),
      ),
      GoRoute(
        path: '/recepciones/nueva',
        builder: (context, state) => const RecepcionFormPage(),
      ),
      GoRoute(
        path: '/peritajes/nuevo',
        builder: (context, state) => const PeritajeFormPage(),
      ),
      GoRoute(
        path: '/clientes/:id/editar',
        builder: (context, state) {
          final cliente = state.extra as Cliente?;
          return ClienteFormPage(cliente: cliente);
        },
      ),
      GoRoute(
        path: '/peritajes/camara',
        builder: (context, state) {
          final peritaje = state.extra as Peritaje;
          return CameraPage(peritaje: peritaje);
        },
      ),
    ],
  );
});
