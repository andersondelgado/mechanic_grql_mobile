import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/currency_provider.dart';
import '../providers/metodos_pago_provider.dart';
import '../../../../models/metodo_pago.dart';
import '../../../../models/currency.dart';

class MetodosPagoPage extends HookConsumerWidget {
  const MetodosPagoPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyState = ref.watch(currencyProvider);
    final metodosState = ref.watch(metodosPagoProvider);
    final user = ref.watch(authProvider).user;
    final isAdmin = user?.role == 'admin';

    final countries = [
      {'code': 'ALL', 'label': 'Todos', 'flag': '🌎'},
      {'code': 'VE', 'label': 'Venezuela', 'flag': '🇻🇪'},
      {'code': 'CO', 'label': 'Colombia', 'flag': '🇨🇴'},
      {'code': 'US', 'label': 'USA', 'flag': '🇺🇸'},
      {'code': 'ES', 'label': 'España', 'flag': '🇪🇸'},
      {'code': 'GLOBAL', 'label': 'Cripto', 'flag': '🌐'},
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Métodos de Pago & Monedas',
          style: TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        actions: [
          // Botón selector de moneda activa
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            child: InkWell(
              onTap: () => _showCurrencySelector(context, ref),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currencyState.activeCurrency.flag,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      currencyState.activeCurrency.code,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 12,
                      ),
                    ),
                    const Icon(
                      Icons.arrow_drop_down,
                      size: 16,
                      color: AppColors.primary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.secondary),
            onPressed: () {
              ref.read(currencyProvider.notifier).fetchCurrencies();
              ref.read(metodosPagoProvider.notifier).fetchMetodos();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(currencyProvider.notifier).fetchCurrencies();
          await ref.read(metodosPagoProvider.notifier).fetchMetodos();
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Banner de Geolocalización Dinámica
            _buildGeolocationBanner(context, ref, currencyState, metodosState),

            const SizedBox(height: 16),

            // Sección: Tasas de Cambio del Día
            _buildRatesBanner(context, ref, currencyState, isAdmin),

            const SizedBox(height: 20),

            // Filtro por País (Chips)
            SizedBox(
              height: 40,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: countries.length,
                separatorBuilder: (_, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final c = countries[index];
                  final isSelected = metodosState.selectedCountry == c['code'];
                  return ChoiceChip(
                    avatar: Text(c['flag']!),
                    label: Text(c['label']!),
                    selected: isSelected,
                    onSelected: (_) {
                      ref
                          .read(metodosPagoProvider.notifier)
                          .setSelectedCountry(c['code']!);
                    },
                    selectedColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : AppColors.secondary,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 12,
                    ),
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.primary
                            : Colors.grey.shade300,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 16),

            // Encabezado de la lista
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cuentas Disponibles (${metodosState.filteredMethods.length})',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.secondary,
                  ),
                ),
                Text(
                  'Toca para copiar',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Lista de Métodos de Pago
            if (metodosState.filteredMethods.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  children: [
                    Icon(Icons.credit_card_off,
                        size: 48, color: Colors.grey.shade400),
                    const SizedBox(height: 12),
                    const Text(
                      'No hay métodos registrados para este país',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              )
            else
              ...metodosState.filteredMethods.map((metodo) {
                return _buildPaymentCard(context, ref, metodo, isAdmin);
              }),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Tarjeta de Tasas de Cambio
  Widget _buildRatesBanner(
    BuildContext context,
    WidgetRef ref,
    CurrencyState state,
    bool isAdmin,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
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
              const Row(
                children: [
                  Icon(Icons.currency_exchange,
                      color: Colors.cyanAccent, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tasas del Taller (Ref: 1 USD)',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.history, color: Colors.white70),
                    tooltip: 'Histórico de tasas del día',
                    onPressed: () => _showHistorySheet(context, ref, state),
                  ),
                  IconButton(
                    icon: const Icon(Icons.calculate, color: Colors.white70),
                    tooltip: 'Calculadora de conversión',
                    onPressed: () => _showConverterSheet(context, ref, state),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 72,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: state.currencies.length,
              separatorBuilder: (_, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final curr = state.currencies[index];
                return InkWell(
                  onTap: () {
                    if (isAdmin && curr.code != 'USD') {
                      _showEditRateDialog(context, ref, curr);
                    } else {
                      ref.read(currencyProvider.notifier).setCurrency(curr.code);
                    }
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: curr.code == state.activeCurrency.code
                            ? AppColors.primary
                            : Colors.white12,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            Text(curr.flag,
                                style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              curr.code,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            if (isAdmin && curr.code != 'USD') ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.edit,
                                  size: 10, color: Colors.white38),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${curr.rate} ${curr.symbol}',
                          style: const TextStyle(
                            color: Colors.cyanAccent,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Tarjeta de Método de Pago Individual
  Widget _buildPaymentCard(
    BuildContext context,
    WidgetRef ref,
    MetodoPago metodo,
    bool isAdmin,
  ) {
    IconData typeIcon = Icons.account_balance;
    Color iconColor = AppColors.primary;
    Color iconBg = AppColors.primary.withValues(alpha: 0.1);

    if (metodo.type == 'pago_movil') {
      typeIcon = Icons.phone_android;
      iconColor = Colors.teal;
      iconBg = Colors.teal.withValues(alpha: 0.1);
    } else if (metodo.type == 'zelle') {
      typeIcon = Icons.bolt;
      iconColor = Colors.purple;
      iconBg = Colors.purple.withValues(alpha: 0.1);
    } else if (metodo.type == 'usdt') {
      typeIcon = Icons.currency_bitcoin;
      iconColor = Colors.amber.shade800;
      iconBg = Colors.amber.shade100;
    } else if (metodo.type == 'divisa') {
      typeIcon = Icons.payments;
      iconColor = Colors.green;
      iconBg = Colors.green.withValues(alpha: 0.1);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: metodo.isActive ? Colors.grey.shade200 : Colors.grey.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: true,
        leading: CircleAvatar(
          backgroundColor: iconBg,
          child: Icon(typeIcon, color: iconColor),
        ),
        title: Row(
          children: [
            Expanded(
              child: Text(
                metodo.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.secondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                metodo.currency,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
        subtitle: Text(
          metodo.bankName ?? metodo.email ?? metodo.phone ?? 'Toca para ver datos',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                if (metodo.bankName != null)
                  _buildDetailRow(context, 'Banco', metodo.bankName!),
                if (metodo.phone != null)
                  _buildDetailRow(context, 'Teléfono', metodo.phone!,
                      canCopy: true),
                if (metodo.taxId != null)
                  _buildDetailRow(context, 'Cédula / RIF', metodo.taxId!,
                      canCopy: true),
                if (metodo.beneficiary != null)
                  _buildDetailRow(context, 'Titular', metodo.beneficiary!),
                if (metodo.accountNumber != null)
                  _buildDetailRow(context, 'Cuenta', metodo.accountNumber!,
                      canCopy: true),
                if (metodo.email != null)
                  _buildDetailRow(context, 'Correo / Zelle', metodo.email!,
                      canCopy: true),
                if (metodo.binanceId != null)
                  _buildDetailRow(context, 'Binance Pay ID', metodo.binanceId!,
                      canCopy: true),
                if (metodo.walletAddress != null)
                  _buildDetailRow(
                    context,
                    'Billetera (${metodo.network ?? "TRC20"})',
                    metodo.walletAddress!,
                    canCopy: true,
                  ),
                if (metodo.instructions != null &&
                    metodo.instructions!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade200),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.amber.shade900),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            metodo.instructions!,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (isAdmin)
                      TextButton.icon(
                        icon: Icon(
                          metodo.isActive ? Icons.pause_circle : Icons.play_circle,
                          size: 16,
                          color: metodo.isActive ? Colors.orange : Colors.green,
                        ),
                        label: Text(
                          metodo.isActive ? 'Pausar' : 'Activar',
                          style: TextStyle(
                            fontSize: 12,
                            color: metodo.isActive ? Colors.orange : Colors.green,
                          ),
                        ),
                        onPressed: () {
                          ref
                              .read(metodosPagoProvider.notifier)
                              .toggleStatus(metodo.id);
                        },
                      ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                      ),
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text(
                        'Copiar Todo',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () {
                        Clipboard.setData(
                            ClipboardData(text: metodo.copyableDetails));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '¡Datos de ${metodo.title} copiados al portapapeles!'),
                            duration: const Duration(seconds: 2),
                            backgroundColor: AppColors.secondary,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value,
      {bool canCopy = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
          ),
          if (canCopy)
            InkWell(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copiado: $value'),
                    duration: const Duration(seconds: 1),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Icon(Icons.copy, size: 14, color: AppColors.primary),
              ),
            ),
        ],
      ),
    );
  }

  // Modal para cambiar la moneda activa
  void _showCurrencySelector(BuildContext context, WidgetRef ref) {
    final currencyState = ref.read(currencyProvider);
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Seleccionar Moneda de Visualización',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 12),
                ...currencyState.currencies.map((curr) {
                  final isSelected =
                      curr.code == currencyState.activeCurrency.code;
                  return ListTile(
                    leading: Text(curr.flag, style: const TextStyle(fontSize: 24)),
                    title: Text(
                      '${curr.code} - ${curr.name}',
                      style: TextStyle(
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? AppColors.primary : AppColors.secondary,
                      ),
                    ),
                    subtitle: Text(
                      curr.code == 'USD'
                          ? 'Moneda Base (\$)'
                          : '1 USD = ${curr.rate} ${curr.symbol}',
                      style: const TextStyle(fontSize: 12),
                    ),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      ref.read(currencyProvider.notifier).setCurrency(curr.code);
                      Navigator.pop(context);
                    },
                  );
                }),
              ],
            ),
          ),
        );
      },
    );
  }

  // Modal para Calculadora de Conversión
  void _showConverterSheet(
      BuildContext context, WidgetRef ref, CurrencyState state) {
    double amount = 100.0;
    String fromCode = 'USD';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                top: 20,
                left: 20,
                right: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Calculadora Multimoneda',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          decoration: InputDecoration(
                            labelText: 'Monto a convertir',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onChanged: (val) {
                            setModalState(() {
                              amount = double.tryParse(val) ?? 0.0;
                            });
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: fromCode,
                        items: state.currencies.map((c) {
                          return DropdownMenuItem(
                            value: c.code,
                            child: Text('${c.flag} ${c.code}'),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setModalState(() => fromCode = val);
                          }
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Equivalencias:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...state.currencies.where((c) => c.code != fromCode).map((target) {
                    final notifier = ref.read(currencyProvider.notifier);
                    final result = notifier.convert(amount, fromCode, target.code);
                    return Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      margin: const EdgeInsets.only(bottom: 6),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(target.flag),
                              const SizedBox(width: 8),
                              Text(target.code,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                          Text(
                            '${result.toStringAsFixed(target.decimals)} ${target.symbol}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Modal para editar tasa (Admin)
  void _showEditRateDialog(
      BuildContext context, WidgetRef ref, Currency currency) {
    final controller = TextEditingController(text: currency.rate.toString());
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Editar Tasa (${currency.code})'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ingrese la nueva tasa de 1 USD a ${currency.name}:'),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  suffixText: currency.symbol,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () async {
                final newRate = double.tryParse(controller.text);
                if (newRate != null && newRate > 0) {
                  await ref
                      .read(currencyProvider.notifier)
                      .updateExchangeRate(currency.code, newRate);
                  if (context.mounted) Navigator.pop(context);
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGeolocationBanner(
    BuildContext context,
    WidgetRef ref,
    CurrencyState currencyState,
    MetodosPagoState metodosState,
  ) {
    final country = metodosState.detectedCountry;
    final isConfigured =
        ref.read(currencyProvider.notifier).isRateConfiguredForCountry(country);

    String countryName = 'Venezuela';
    String countryFlag = '🇻🇪';
    String localCurrency = 'VES';
    if (country == 'CO') {
      countryName = 'Colombia';
      countryFlag = '🇨🇴';
      localCurrency = 'COP';
    } else if (country == 'US') {
      countryName = 'Estados Unidos';
      countryFlag = '🇺🇸';
      localCurrency = 'USD';
    } else if (country == 'ES') {
      countryName = 'España';
      countryFlag = '🇪🇸';
      localCurrency = 'EUR';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isConfigured ? Colors.indigo.shade100 : Colors.amber.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.location_on,
                    color: Colors.indigo, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ubicación Detectada (Geolocalización)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '$countryFlag $countryName ($localCurrency)',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                    ),
                  ],
                ),
              ),
              FilterChip(
                label: Text(
                  metodosState.filterByLocation ? 'Filtrado' : 'Solo mi país',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: metodosState.filterByLocation
                        ? Colors.white
                        : AppColors.primary,
                  ),
                ),
                selected: metodosState.filterByLocation,
                selectedColor: AppColors.primary,
                backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                onSelected: (val) {
                  ref
                      .read(metodosPagoProvider.notifier)
                      .setFilterByLocation(val);
                },
              ),
            ],
          ),
          if (!isConfigured) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.amber.shade200),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.amber, size: 16),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Tasa no configurada para $localCurrency. Los métodos en moneda local no se mostrarán al cliente hasta fijar la tasa.',
                      style:
                          TextStyle(fontSize: 11, color: Colors.amber.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showHistorySheet(
      BuildContext context, WidgetRef ref, CurrencyState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.history, color: AppColors.primary),
                      SizedBox(width: 8),
                      Text(
                        'Histórico de Tasas del Día',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Registro cronológico de snapshots de tasas registradas en el taller.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: state.rateHistory.isEmpty
                    ? const Center(
                        child: Text(
                          'No hay registros históricos aún.',
                          style: TextStyle(color: Colors.grey),
                        ),
                      )
                    : ListView.separated(
                        itemCount: state.rateHistory.length,
                        separatorBuilder: (_, index) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final item = state.rateHistory[index];
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: CircleAvatar(
                              backgroundColor:
                                  AppColors.primary.withValues(alpha: 0.1),
                              child: Text(
                                item.currency,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                            title: Text(
                              '${item.rate} ${item.currency} / USD',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                            subtitle: Text(
                              'Fuente: ${item.source} • ${item.recordedAt.split('T').first}',
                              style: const TextStyle(
                                  fontSize: 11, color: Colors.grey),
                            ),
                            trailing: item.notes != null
                                ? Text(
                                    item.notes!,
                                    style: const TextStyle(
                                        fontSize: 11, color: Colors.grey),
                                  )
                                : null,
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
