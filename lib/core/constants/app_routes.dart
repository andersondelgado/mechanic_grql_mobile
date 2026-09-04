import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/clientes/presentation/pages/clientes_page.dart';
import '../../features/clientes/presentation/pages/cliente_form_page.dart';
import '../../features/vehiculos/presentation/pages/vehiculos_page.dart';
import '../../features/recepciones/presentation/pages/recepciones_page.dart';
import '../../features/peritajes/presentation/pages/peritajes_page.dart';
import '../../features/peritajes/presentation/pages/peritaje_form_page.dart';
import '../../features/peritajes/presentation/pages/camera_page.dart';
import '../../features/recepciones/presentation/pages/recepcion_form_page.dart';
import '../../features/inventario/presentation/pages/inventario_page.dart';
import '../../features/finanzas/presentation/pages/facturas_page.dart';
import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../models/cliente.dart';
import '../../models/peritaje.dart';
import '../widgets/bottom_nav_bar.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isAuthenticated;
      final isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';
      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
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
