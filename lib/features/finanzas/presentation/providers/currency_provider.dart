import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/providers.dart';
import '../../../../core/network/workflow_types.dart';
import '../../../../models/currency.dart';

const List<Currency> kDefaultCurrencies = [
  Currency(
    code: 'USD',
    name: 'Dólar Estadounidense',
    symbol: '\$',
    rate: 1.0,
    isBase: true,
    decimals: 2,
    flag: '🇺🇸',
    countries: ['US', 'VE', 'PA', 'EC', 'GLOBAL'],
  ),
  Currency(
    code: 'VES',
    name: 'Bolívar Digital',
    symbol: 'Bs.',
    rate: 50.0,
    isBase: false,
    decimals: 2,
    flag: '🇻🇪',
    countries: ['VE'],
  ),
  Currency(
    code: 'EUR',
    name: 'Euro',
    symbol: '€',
    rate: 0.92,
    isBase: false,
    decimals: 2,
    flag: '🇪🇺',
    countries: ['ES', 'EU'],
  ),
  Currency(
    code: 'COP',
    name: 'Peso Colombiano',
    symbol: 'COP\$',
    rate: 4150.0,
    isBase: false,
    decimals: 0,
    flag: '🇨🇴',
    countries: ['CO'],
  ),
  Currency(
    code: 'USDT',
    name: 'Tether USD (Binance)',
    symbol: 'USDT',
    rate: 1.0,
    isBase: false,
    decimals: 2,
    flag: '🟡',
    countries: ['GLOBAL', 'VE', 'US', 'CO', 'ES'],
  ),
];

class CurrencyState {
  final List<Currency> currencies;
  final Currency activeCurrency;
  final List<RateHistoryEntry> rateHistory;
  final String detectedCountry;
  final double? latitude;
  final double? longitude;
  final bool isLoading;
  final String? error;

  const CurrencyState({
    required this.currencies,
    required this.activeCurrency,
    this.rateHistory = const [],
    this.detectedCountry = 'VE',
    this.latitude,
    this.longitude,
    this.isLoading = false,
    this.error,
  });

  CurrencyState copyWith({
    List<Currency>? currencies,
    Currency? activeCurrency,
    List<RateHistoryEntry>? rateHistory,
    String? detectedCountry,
    double? latitude,
    double? longitude,
    bool? isLoading,
    String? error,
  }) {
    return CurrencyState(
      currencies: currencies ?? this.currencies,
      activeCurrency: activeCurrency ?? this.activeCurrency,
      rateHistory: rateHistory ?? this.rateHistory,
      detectedCountry: detectedCountry ?? this.detectedCountry,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final currencyProvider =
    StateNotifierProvider<CurrencyNotifier, CurrencyState>((ref) {
  final apiClient = ref.read(apiClientProvider);
  return CurrencyNotifier(apiClient);
});

class CurrencyNotifier extends StateNotifier<CurrencyState> {
  final ApiClient _apiClient;
  static const String _prefKey = 'selected_currency_code';

  CurrencyNotifier(this._apiClient)
      : super(CurrencyState(
          currencies: kDefaultCurrencies,
          activeCurrency: kDefaultCurrencies.first,
        )) {
    _init();
  }

  Future<void> _init() async {
    await _loadSavedPreference();
    await fetchCurrencies();
    await fetchRateHistory();
  }

  Future<void> _loadSavedPreference() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedCode = prefs.getString(_prefKey);
      if (savedCode != null) {
        final match = state.currencies.firstWhere(
          (c) => c.code.toUpperCase() == savedCode.toUpperCase(),
          orElse: () => state.activeCurrency,
        );
        state = state.copyWith(activeCurrency: match);
      }
    } catch (_) {}
  }

  String detectCountryFromCoordinates(double lat, double lon) {
    if (lat >= 0.6 && lat <= 12.5 && lon >= -73.5 && lon <= -59.8) {
      return 'VE';
    } else if (lat >= -4.3 && lat <= 12.5 && lon >= -79.1 && lon <= -66.8) {
      return 'CO';
    } else if (lat >= 24.5 && lat <= 49.5 && lon >= -125.0 && lon <= -66.9) {
      return 'US';
    } else if (lat >= 35.0 && lat <= 44.0 && lon >= -9.5 && lon <= 4.5) {
      return 'ES';
    }
    return 'GLOBAL';
  }

  void setLocationCoordinates(double lat, double lon) {
    final country = detectCountryFromCoordinates(lat, lon);
    state = state.copyWith(
      detectedCountry: country,
      latitude: lat,
      longitude: lon,
    );
  }

  bool isRateConfiguredForCountry(String country) {
    String currencyCode;
    switch (country.toUpperCase()) {
      case 'VE':
        currencyCode = 'VES';
        break;
      case 'CO':
        currencyCode = 'COP';
        break;
      case 'ES':
        currencyCode = 'EUR';
        break;
      case 'US':
        return true;
      case 'GLOBAL':
        return true;
      default:
        return true;
    }

    final curr = state.currencies.firstWhere(
      (c) => c.code.toUpperCase() == currencyCode.toUpperCase(),
      orElse: () => const Currency(
        code: '',
        name: '',
        symbol: '',
        rate: 0,
        isBase: false,
        decimals: 2,
        flag: '',
        countries: [],
      ),
    );
    return curr.rate > 0;
  }

  Future<void> fetchCurrencies() async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _apiClient.getEntity(
        'catalogState',
        query: WorkflowQuery(filter: {'name': 'currency_settings'}),
      );

      if (data.isNotEmpty &&
          data[0]['metadata'] != null &&
          data[0]['metadata'] is List) {
        final list = (data[0]['metadata'] as List)
            .map((e) => Currency.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        final currentCode = state.activeCurrency.code;
        final newActive = list.firstWhere(
          (c) => c.code.toUpperCase() == currentCode.toUpperCase(),
          orElse: () => list.first,
        );

        state = state.copyWith(
          currencies: list,
          activeCurrency: newActive,
          isLoading: false,
        );
        return;
      }
    } catch (_) {
      // Usar defaults si falla la red
    }
    state = state.copyWith(isLoading: false);
  }

  Future<void> fetchRateHistory() async {
    try {
      final data = await _apiClient.getEntity(
        'catalogState',
        query: WorkflowQuery(filter: {'name': 'exchange_rate_history'}),
      );

      if (data.isNotEmpty &&
          data[0]['metadata'] != null &&
          data[0]['metadata'] is List) {
        final list = (data[0]['metadata'] as List)
            .map((e) =>
                RateHistoryEntry.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();

        list.sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
        state = state.copyWith(rateHistory: list);
      }
    } catch (_) {}
  }

  Future<void> setCurrency(String code) async {
    final match = state.currencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => state.activeCurrency,
    );
    state = state.copyWith(activeCurrency: match);

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKey, match.code);
    } catch (_) {}
  }

  Future<bool> updateExchangeRate(
    String code,
    double newRate, {
    String source = 'Manual App',
    String? notes,
  }) async {
    if (newRate <= 0) return false;

    final updated = state.currencies.map((c) {
      if (c.code.toUpperCase() == code.toUpperCase()) {
        return c.copyWith(rate: newRate);
      }
      return c;
    }).toList();

    final newActive = updated.firstWhere(
      (c) => c.code == state.activeCurrency.code,
      orElse: () => updated.first,
    );

    // Nuevo snapshot para el histórico
    final newEntry = RateHistoryEntry(
      id: 'hist-${DateTime.now().millisecondsSinceEpoch}',
      currency: code.toUpperCase(),
      rate: newRate,
      source: source,
      recordedAt: DateTime.now().toIso8601String(),
      notes: notes ?? 'Actualizado desde App Móvil',
    );

    final updatedHistory = [newEntry, ...state.rateHistory];

    state = state.copyWith(
      currencies: updated,
      activeCurrency: newActive,
      rateHistory: updatedHistory,
    );

    try {
      await _apiClient.createEntity('catalogState', {
        'name': 'currency_settings',
        'metadata': updated.map((c) => c.toJson()).toList(),
      });

      await _apiClient.createEntity('catalogState', {
        'name': 'exchange_rate_history',
        'metadata': updatedHistory.map((h) => h.toJson()).toList(),
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  double convert(double amount, String fromCode, String toCode) {
    if (amount == 0 || fromCode.toUpperCase() == toCode.toUpperCase()) {
      return amount;
    }

    final fromCurr = state.currencies.firstWhere(
      (c) => c.code.toUpperCase() == fromCode.toUpperCase(),
      orElse: () => const Currency(
        code: 'USD',
        name: 'USD',
        symbol: '\$',
        rate: 1.0,
        isBase: true,
        decimals: 2,
        flag: '',
        countries: [],
      ),
    );

    final toCurr = state.currencies.firstWhere(
      (c) => c.code.toUpperCase() == toCode.toUpperCase(),
      orElse: () => const Currency(
        code: 'USD',
        name: 'USD',
        symbol: '\$',
        rate: 1.0,
        isBase: true,
        decimals: 2,
        flag: '',
        countries: [],
      ),
    );

    final inUSD = fromCurr.rate > 0 ? amount / fromCurr.rate : amount;
    return inUSD * toCurr.rate;
  }

  String formatAmount(
    double amountInUSD, {
    String? targetCode,
    bool showSymbol = true,
  }) {
    final code = targetCode ?? state.activeCurrency.code;
    final curr = state.currencies.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
      orElse: () => state.activeCurrency,
    );

    final converted = curr.code == 'USD'
        ? amountInUSD
        : convert(amountInUSD, 'USD', curr.code);

    if (curr.code == 'VES') {
      return 'Bs. ${NumberFormat("#,##0.00", "es_VE").format(converted)}';
    } else if (curr.code == 'USD') {
      return '\$${NumberFormat("#,##0.00", "en_US").format(converted)}';
    } else if (curr.code == 'EUR') {
      return '${NumberFormat("#,##0.00", "es_ES").format(converted)} €';
    } else if (curr.code == 'COP') {
      return 'COP\$ ${NumberFormat("#,##0", "es_CO").format(converted)}';
    }

    return '${NumberFormat("#,##0.00").format(converted)} ${curr.symbol}';
  }
}
