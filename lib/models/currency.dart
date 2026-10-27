class Currency {
  final String code;
  final String name;
  final String symbol;
  final double rate;
  final bool isBase;
  final int decimals;
  final String flag;
  final List<String> countries;

  const Currency({
    required this.code,
    required this.name,
    required this.symbol,
    required this.rate,
    required this.isBase,
    required this.decimals,
    required this.flag,
    required this.countries,
  });

  factory Currency.fromJson(Map<String, dynamic> json) {
    return Currency(
      code: json['code'] as String? ?? 'USD',
      name: json['name'] as String? ?? '',
      symbol: json['symbol'] as String? ?? '\$',
      rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
      isBase: json['is_base'] as bool? ?? false,
      decimals: (json['decimals'] as num?)?.toInt() ?? 2,
      flag: json['flag'] as String? ?? '🌐',
      countries: (json['countries'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() => {
        'code': code,
        'name': name,
        'symbol': symbol,
        'rate': rate,
        'is_base': isBase,
        'decimals': decimals,
        'flag': flag,
        'countries': countries,
      };

  Currency copyWith({
    String? code,
    String? name,
    String? symbol,
    double? rate,
    bool? isBase,
    int? decimals,
    String? flag,
    List<String>? countries,
  }) {
    return Currency(
      code: code ?? this.code,
      name: name ?? this.name,
      symbol: symbol ?? this.symbol,
      rate: rate ?? this.rate,
      isBase: isBase ?? this.isBase,
      decimals: decimals ?? this.decimals,
      flag: flag ?? this.flag,
      countries: countries ?? this.countries,
    );
  }
}

class RateHistoryEntry {
  final String id;
  final String currency;
  final double rate;
  final String source;
  final String recordedAt;
  final String? notes;

  const RateHistoryEntry({
    required this.id,
    required this.currency,
    required this.rate,
    required this.source,
    required this.recordedAt,
    this.notes,
  });

  factory RateHistoryEntry.fromJson(Map<String, dynamic> json) {
    return RateHistoryEntry(
      id: json['id'] as String? ?? 'hist-${DateTime.now().millisecondsSinceEpoch}',
      currency: json['currency'] as String? ?? 'VES',
      rate: (json['rate'] as num?)?.toDouble() ?? 1.0,
      source: json['source'] as String? ?? 'Manual',
      recordedAt: json['recorded_at'] as String? ?? DateTime.now().toIso8601String(),
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'currency': currency,
        'rate': rate,
        'source': source,
        'recorded_at': recordedAt,
        'notes': notes,
      };
}
