import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../../../vehiculos/presentation/providers/vehiculos_provider.dart';
import '../../../recepciones/presentation/providers/recepciones_provider.dart';
import '../../../finanzas/presentation/providers/facturas_provider.dart';
import '../../../finanzas/presentation/providers/currency_provider.dart';

class DashboardPage extends HookConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final isAdmin = user?.role == 'admin';

    final dashboardState = ref.watch(dashboardProvider);
    final myVehicles = ref.watch(vehiculosProvider);
    final myReceptions = ref.watch(recepcionesProvider);
    final myFacturas = ref.watch(facturasProvider);
    final currencyState = ref.watch(currencyProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(dashboardProvider.notifier).fetchStats();
          if (!isAdmin) {
            ref.invalidate(vehiculosProvider);
            ref.invalidate(recepcionesProvider);
            ref.invalidate(facturasProvider);
          }
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              expandedHeight: 220.0,
              floating: false,
              pinned: true,
              backgroundColor: AppColors.primary,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                      colors: [Color(0xFF2563EB), Color(0xFF1E3A8A)],
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 30,
                                backgroundColor: Colors.white24,
                                child: Text(
                                  (user?.username.trim().isNotEmpty == true)
                                      ? user!.username
                                            .trim()
                                            .substring(0, 1)
                                            .toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Bienvenido de vuelta,',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    Text(
                                      user?.username ?? 'Usuario',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.5,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.logout, color: Colors.white),
                  tooltip: 'Cerrar sesión',
                  onPressed: () {
                    ref.read(authProvider.notifier).logout();
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner de Multimoneda y Métodos de Pago
                    InkWell(
                      onTap: () => context.go('/metodos-pago'),
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.08),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.payments_outlined,
                                  color: Colors.cyanAccent, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text(
                                        'Métodos de Pago & Monedas',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(currencyState.activeCurrency.flag),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Zelle, Pago Móvil, Divisa, USDT • Ref: 1 USD = ${currencyState.activeCurrency.rate} ${currencyState.activeCurrency.symbol}',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.white54, size: 14),
                          ],
                        ),
                      ),
                    ),

                    const Text(
                      'Resumen General',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Dashboard con métricas reales de la Lambda (Operativas y Financieras)
                    dashboardState.when(
                      data: (stats) => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 16,
                            crossAxisSpacing: 16,
                            childAspectRatio: 1.05,
                            children: isAdmin
                                ? [
                                    _buildStatCard(
                                      'Clientes',
                                      '${stats.totalClients}',
                                      Icons.people,
                                      AppColors.primary,
                                      subtitle: 'Clientes registrados',
                                      badgeText: 'Clientes',
                                      badgeColor: AppColors.primary,
                                      badgeBgColor: const Color(0xFFEFF6FF),
                                    ),
                                    _buildStatCard(
                                      'Vehículos',
                                      '${stats.totalVehicles}',
                                      Icons.directions_car,
                                      AppColors.success,
                                      subtitle: 'En base de datos',
                                      badgeText: 'Vehículos',
                                      badgeColor: AppColors.success,
                                      badgeBgColor: const Color(0xFFECFDF5),
                                    ),
                                    _buildStatCard(
                                      'En Taller',
                                      '${stats.vehiclesInShop}',
                                      Icons.build_circle,
                                      AppColors.warning,
                                      subtitle: 'Vehículos en taller',
                                      badgeText: 'En Proceso',
                                      badgeColor: const Color(0xFFD97706),
                                      badgeBgColor: const Color(0xFFFEF3C7),
                                    ),
                                    _buildStatCard(
                                      'Reparaciones',
                                      '${stats.completedRepairs}',
                                      Icons.verified,
                                      const Color(0xFF8B5CF6),
                                      subtitle: 'Reparaciones concluidas',
                                      badgeText: 'Histórico',
                                      badgeColor: const Color(0xFF7C3AED),
                                      badgeBgColor: const Color(0xFFF3E8FF),
                                    ),
                                  ]
                                : [
                                    _buildStatCard(
                                      'Mis Autos',
                                      '${myVehicles.asData?.value.length ?? 0}',
                                      Icons.directions_car,
                                      AppColors.primary,
                                      subtitle: 'Registrados a tu nombre',
                                    ),
                                    _buildStatCard(
                                      'En Proceso',
                                      '${myReceptions.asData?.value.where((r) => r.status == 'pending').length ?? 0}',
                                      Icons.build_circle,
                                      AppColors.warning,
                                      subtitle: 'Servicios activos',
                                    ),
                                    _buildStatCard(
                                      'Facturas',
                                      '${myFacturas.asData?.value.length ?? 0}',
                                      Icons.receipt,
                                      AppColors.success,
                                      subtitle: 'Histórico de pagos',
                                    ),
                                    _buildStatCard(
                                      'Alertas',
                                      '0',
                                      Icons.notifications,
                                      const Color(0xFF8B5CF6),
                                      subtitle: 'Notificaciones',
                                    ),
                                  ],
                          ),

                          if (isAdmin) ...[
                            const SizedBox(height: 28),
                            const Text(
                              'Resumen Financiero',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              childAspectRatio: 0.95,
                              children: [
                                _buildFinancialCard(
                                  title: 'Ingresos del Mes',
                                  mainValue: _formatCurrency(stats.totalIncomeMonth),
                                  subValue: 'Histórico: ${_formatCurrency(stats.totalIncomeAll)}',
                                  icon: Icons.trending_up,
                                  iconColor: AppColors.success,
                                  iconBgColor: const Color(0xFFECFDF5),
                                  mainValueColor: AppColors.success,
                                ),
                                _buildFinancialCard(
                                  title: 'Egresos del Mes',
                                  mainValue: _formatCurrency(stats.totalExpensesMonth),
                                  subValue: 'Histórico: ${_formatCurrency(stats.totalExpensesAll)}',
                                  icon: Icons.trending_down,
                                  iconColor: AppColors.danger,
                                  iconBgColor: const Color(0xFFFEF2F2),
                                  mainValueColor: AppColors.danger,
                                ),
                                _buildFinancialCard(
                                  title: 'Balance en Caja',
                                  mainValue: _formatCurrency(stats.balanceMonth),
                                  subValue: 'Global: ${_formatCurrency(stats.totalBalanceAll)}',
                                  icon: Icons.account_balance_wallet,
                                  iconColor: AppColors.primary,
                                  iconBgColor: const Color(0xFFEFF6FF),
                                  mainValueColor: stats.balanceMonth >= 0
                                      ? AppColors.primary
                                      : AppColors.danger,
                                ),
                                _buildFinancialCard(
                                  title: 'Cuentas por Cobrar',
                                  mainValue: _formatCurrency(stats.accountsReceivableTotal),
                                  subValue: 'Por pagar: ${_formatCurrency(stats.accountsPayableTotal)}',
                                  icon: Icons.receipt_long,
                                  iconColor: const Color(0xFFD97706),
                                  iconBgColor: const Color(0xFFFEF3C7),
                                  mainValueColor: const Color(0xFFD97706),
                                ),
                              ],
                            ),

                            // Evolución Financiera Mensual
                            _buildMonthlyBreakdown(stats.monthlyBreakdown),
                          ],
                        ],
                      ),
                      loading: () => const Center(
                        child: Padding(
                          padding: EdgeInsets.all(48.0),
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      error: (err, _) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'Inconveniente al cargar estadísticas: $err',
                            style: const TextStyle(color: AppColors.danger, fontSize: 13),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.verified_user,
                            size: 48,
                            color: AppColors.primary.withValues(alpha: 0.8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            isAdmin
                                ? 'Plataforma Administrativa Activa'
                                : 'Conectado de forma segura',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: AppColors.secondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Toda tu información está protegida por nuestra arquitectura en la nube con cifrado integral.',
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double val) {
    final isNegative = val < 0;
    final absVal = val.abs();
    final parts = absVal.toStringAsFixed(2).split('.');
    final integerPart = parts[0];
    final decimalPart = parts[1];

    final buffer = StringBuffer();
    for (int i = 0; i < integerPart.length; i++) {
      if (i > 0 && (integerPart.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(integerPart[i]);
    }

    return '${isNegative ? "- " : ""}USD ${buffer.toString()},$decimalPart';
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
    String? badgeText,
    Color? badgeColor,
    Color? badgeBgColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              if (badgeText != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: badgeBgColor ?? Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    badgeText,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: badgeColor ?? Colors.grey.shade600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.secondary,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle ?? title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFinancialCard({
    required String title,
    required String mainValue,
    required String subValue,
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    Color? mainValueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600,
                    letterSpacing: 0.4,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 18),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mainValue,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: mainValueColor ?? AppColors.secondary,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                subValue,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthlyBreakdown(List<MonthlyBreakdownModel> breakdown) {
    if (breakdown.isEmpty) return const SizedBox.shrink();

    final maxVal = breakdown.fold<double>(
      100.0,
      (max, m) => [max, m.income, m.expenses].reduce((a, b) => a > b ? a : b),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: AppColors.primary, size: 20),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Evolución Financiera',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.secondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Ingresos vs Egresos por período',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: AppColors.success,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Ingresos',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF87171),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      'Egresos',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...breakdown.map((m) {
          final incPct = maxVal > 0 ? (m.income / maxVal).clamp(0.0, 1.0) : 0.0;
          final expPct = maxVal > 0 ? (m.expenses / maxVal).clamp(0.0, 1.0) : 0.0;
          final isPositive = m.balance >= 0;

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      m.month.isEmpty ? 'Período' : m.month.toUpperCase(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.secondary,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPositive ? const Color(0xFFDCFCE7) : const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        _formatCurrency(m.balance),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isPositive ? const Color(0xFF15803D) : const Color(0xFFB91C1C),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Ingresos', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      _formatCurrency(m.income),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: incPct,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Egresos', style: TextStyle(fontSize: 11, color: Colors.grey)),
                    Text(
                      _formatCurrency(m.expenses),
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppColors.danger,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: expPct,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF87171)),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}
