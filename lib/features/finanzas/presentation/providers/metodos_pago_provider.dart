import 'package:hooks_riverpod/hooks_riverpod.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/network/workflow_types.dart';
import '../../../../models/metodo_pago.dart';

const List<MetodoPago> kDefaultMetodosPago = [
  // 🇻🇪 VENEZUELA
  MetodoPago(
    id: 'pm-ve-pago-movil',
    country: 'VE',
    type: 'pago_movil',
    title: 'Pago Móvil (Interbancario)',
    currency: 'VES',
    bankName: '0102 - Banco de Venezuela',
    phone: '0414-1234567',
    taxId: 'J-50123456-7',
    beneficiary: 'Taller Mecánico 360 C.A.',
    instructions:
        'Realizar el pago móvil a tasa oficial del día. Enviar captura con número de referencia bancaria.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-ve-pago-movil-banesco',
    country: 'VE',
    type: 'pago_movil',
    title: 'Pago Móvil Banesco',
    currency: 'VES',
    bankName: '0134 - Banesco Banco Universal',
    phone: '0424-9876543',
    taxId: 'J-50123456-7',
    beneficiary: 'Taller Mecánico 360 C.A.',
    instructions: 'Confirmación inmediata vía WhatsApp.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-ve-efectivo-divisa',
    country: 'VE',
    type: 'divisa',
    title: 'Divisa en Efectivo (USD / EUR)',
    currency: 'USD',
    beneficiary: 'Caja Principal - Taller 360',
    instructions:
        'Pago en taquilla de recepción. Billetes en buen estado sin roturas ni marcas.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-ve-zelle',
    country: 'VE',
    type: 'zelle',
    title: 'Zelle (Dólares USD)',
    currency: 'USD',
    email: 'pagos.taller360@gmail.com',
    beneficiary: 'Taller 360 LLC',
    instructions:
        'Colocar únicamente el número de presupuesto o placa en el concepto.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-ve-usdt-binance',
    country: 'VE',
    type: 'usdt',
    title: 'USDT (Binance Pay / Crypto)',
    currency: 'USDT',
    binanceId: '284910283',
    email: 'binance@taller360.com',
    network: 'Tron (TRC-20) / BSC',
    walletAddress: 'TQrL7YF45dM2qN9c8Pz1V8kJ6xR2mP7tWv',
    instructions: 'Binance Pay sin comisión o por red Tron TRC20.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-ve-transferencia-bs',
    country: 'VE',
    type: 'transferencia',
    title: 'Transferencia Bancaria (Bs)',
    currency: 'VES',
    bankName: '0102 - Banco de Venezuela',
    accountNumber: '0102-0123-45-0000123456',
    taxId: 'J-50123456-7',
    beneficiary: 'Taller Mecánico 360 C.A.',
    instructions: 'Cuenta corriente jurídica.',
    isActive: true,
  ),

  // 🇺🇸 ESTADOS UNIDOS
  MetodoPago(
    id: 'pm-us-zelle',
    country: 'US',
    type: 'zelle',
    title: 'Zelle Direct Pay (USD)',
    currency: 'USD',
    email: 'billing@taller360garage.com',
    phone: '+1 (786) 555-0199',
    beneficiary: 'Taller 360 Garage LLC',
    instructions: 'Direct instant payment via US banking app.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-us-ach',
    country: 'US',
    type: 'transferencia',
    title: 'Wire / ACH Direct Deposit',
    currency: 'USD',
    bankName: 'Chase Bank / Bank of America',
    accountNumber: '9876543210',
    beneficiary: 'Taller 360 Garage LLC',
    instructions: 'Routing (ABA): 021000021.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-us-cash',
    country: 'US',
    type: 'divisa',
    title: 'Cash USD (In-Shop)',
    currency: 'USD',
    beneficiary: 'Cashier Desk',
    instructions: 'Pay at physical reception.',
    isActive: true,
  ),

  // 🇨🇴 COLOMBIA
  MetodoPago(
    id: 'pm-co-nequi',
    country: 'CO',
    type: 'nequi',
    title: 'Nequi / Daviplata',
    currency: 'COP',
    phone: '310-555-0144',
    taxId: 'CC 1020304050',
    beneficiary: 'Taller 360 Colombia SAS',
    instructions: 'Transferencias desde Nequi o Daviplata.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-co-bancolombia',
    country: 'CO',
    type: 'transferencia',
    title: 'Bancolombia (Ahorros)',
    currency: 'COP',
    bankName: 'Bancolombia',
    accountNumber: '123-456789-01',
    taxId: 'NIT 901.234.567-8',
    beneficiary: 'Taller 360 Colombia SAS',
    instructions: 'Transferencia directa o código QR Bancolombia.',
    isActive: true,
  ),

  // 🇪🇸 ESPAÑA / EUROPA
  MetodoPago(
    id: 'pm-es-bizum',
    country: 'ES',
    type: 'bizum',
    title: 'Bizum',
    currency: 'EUR',
    phone: '+34 612 345 678',
    beneficiary: 'Taller 360 Automoción SL',
    instructions: 'Envío instantáneo mediante Bizum con matrícula en el concepto.',
    isActive: true,
  ),
  MetodoPago(
    id: 'pm-es-sepa',
    country: 'ES',
    type: 'transferencia',
    title: 'Transferencia SEPA (IBAN)',
    currency: 'EUR',
    bankName: 'CaixaBank / BBVA',
    accountNumber: 'ES91 2100 0418 4502 0005 1234',
    beneficiary: 'Taller 360 Automoción SL',
    instructions: 'Transferencia bancaria europea en Euros.',
    isActive: true,
  ),

  // 🌐 GLOBAL
  MetodoPago(
    id: 'pm-global-binance-usdt',
    country: 'GLOBAL',
    type: 'usdt',
    title: 'Binance Pay / USDT Global',
    currency: 'USDT',
    binanceId: '284910283',
    network: 'Tron (TRC-20)',
    walletAddress: 'TQrL7YF45dM2qN9c8Pz1V8kJ6xR2mP7tWv',
    instructions: 'Aceptamos USDT para clientes internacionales.',
    isActive: true,
  ),
];

class MetodosPagoState {
  final List<MetodoPago> methods;
  final String selectedCountry;
  final String detectedCountry;
  final bool filterByLocation;
  final bool isLoading;
  final String? error;

  const MetodosPagoState({
    required this.methods,
    this.selectedCountry = 'ALL',
    this.detectedCountry = 'VE',
    this.filterByLocation = false,
    this.isLoading = false,
    this.error,
  });

  List<MetodoPago> get filteredMethods {
    if (filterByLocation) {
      return methods
          .where((m) => m.country == detectedCountry || m.country == 'GLOBAL')
          .toList();
    }
    if (selectedCountry == 'ALL') return methods;
    return methods
        .where((m) => m.country == selectedCountry || m.country == 'GLOBAL')
        .toList();
  }

  /// Filtra dinámicamente según la ubicación y la condición de tasa activa
  List<MetodoPago> getDynamicMethods(bool Function(String country) isRateConfigured) {
    return methods.where((m) {
      if (!m.isActive) return false;
      final matchCountry = m.country == detectedCountry || m.country == 'GLOBAL';
      if (!matchCountry) return false;

      // Si la moneda es USD o USDT, siempre es válida
      if (m.currency.toUpperCase() == 'USD' || m.currency.toUpperCase() == 'USDT') {
        return true;
      }

      // Si es moneda local, debe tener tasa configurada
      return isRateConfigured(m.country);
    }).toList();
  }

  MetodosPagoState copyWith({
    List<MetodoPago>? methods,
    String? selectedCountry,
    String? detectedCountry,
    bool? filterByLocation,
    bool? isLoading,
    String? error,
  }) {
    return MetodosPagoState(
      methods: methods ?? this.methods,
      selectedCountry: selectedCountry ?? this.selectedCountry,
      detectedCountry: detectedCountry ?? this.detectedCountry,
      filterByLocation: filterByLocation ?? this.filterByLocation,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final metodosPagoProvider =
    StateNotifierProvider<MetodosPagoNotifier, MetodosPagoState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return MetodosPagoNotifier(apiClient);
});

class MetodosPagoNotifier extends StateNotifier<MetodosPagoState> {
  final ApiClient _apiClient;

  MetodosPagoNotifier(this._apiClient)
      : super(const MetodosPagoState(methods: kDefaultMetodosPago)) {
    fetchMetodos();
  }

  void setSelectedCountry(String country) {
    state = state.copyWith(selectedCountry: country, filterByLocation: false);
  }

  void setFilterByLocation(bool value) {
    state = state.copyWith(filterByLocation: value);
  }

  void setDetectedCountry(String country) {
    state = state.copyWith(detectedCountry: country);
  }

  Future<void> fetchMetodos() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _apiClient.getEntity(
        'catalogState',
        query: WorkflowQuery(filter: {'name': 'payment_methods'}),
      );

      if (data.isNotEmpty &&
          data[0]['metadata'] != null &&
          data[0]['metadata'] is List) {
        final list = (data[0]['metadata'] as List)
            .map((e) => MetodoPago.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        state = state.copyWith(methods: list, isLoading: false);
        return;
      }
    } catch (_) {}
    state = state.copyWith(isLoading: false);
  }

  Future<bool> toggleStatus(String id) async {
    final updated = state.methods.map((m) {
      if (m.id == id) {
        return MetodoPago(
          id: m.id,
          country: m.country,
          type: m.type,
          title: m.title,
          currency: m.currency,
          bankName: m.bankName,
          phone: m.phone,
          taxId: m.taxId,
          beneficiary: m.beneficiary,
          accountNumber: m.accountNumber,
          email: m.email,
          binanceId: m.binanceId,
          walletAddress: m.walletAddress,
          network: m.network,
          instructions: m.instructions,
          isActive: !m.isActive,
          qrCodeUrl: m.qrCodeUrl,
        );
      }
      return m;
    }).toList();

    state = state.copyWith(methods: updated);

    try {
      await _apiClient.createEntity('catalogState', {
        'name': 'payment_methods',
        'metadata': updated.map((m) => m.toJson()).toList(),
      });
      return true;
    } catch (_) {
      return false;
    }
  }
}
