class Cotizacion {
  final String? id;
  final String? quoteNumber;
  final String? clientsFkId;
  final String? vehiclesFkId;
  final String? clientName;
  final String? licensePlate;
  final String? quoteDate;
  final String? validUntil;
  final double subtotal;
  final double taxAmount;
  final double total;
  final String status;
  final String? notes;
  final List<Map<String, dynamic>> items;

  Cotizacion({
    this.id,
    this.quoteNumber,
    this.clientsFkId,
    this.vehiclesFkId,
    this.clientName,
    this.licensePlate,
    this.quoteDate,
    this.validUntil,
    this.subtotal = 0.0,
    this.taxAmount = 0.0,
    this.total = 0.0,
    this.status = 'pendiente',
    this.notes,
    this.items = const [],
  });

  factory Cotizacion.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    final client = (json['clients'] is List && (json['clients'] as List).isNotEmpty)
        ? json['clients'][0]
        : null;
    final vehicle = (json['vehicles'] is List && (json['vehicles'] as List).isNotEmpty)
        ? json['vehicles'][0]
        : null;

    final clientName = client?['client_name'] ?? json['client_name'] ?? json['owner_name'];
    final plate = vehicle?['license_plate'] ?? json['license_plate'];

    List<Map<String, dynamic>> parseItems(dynamic val) {
      if (val is List) {
        return val.map((e) => (e is Map) ? e.cast<String, dynamic>() : <String, dynamic>{}).toList();
      }
      return [];
    }

    return Cotizacion(
      id: json['id']?.toString() ?? json['quote_id']?.toString(),
      quoteNumber: json['quote_number']?.toString() ??
          (json['id'] != null ? 'COT-${json['id'].toString().substring(0, 6).toUpperCase()}' : 'COT-001'),
      clientsFkId: json['clients_fk_id']?.toString(),
      vehiclesFkId: json['vehicles_fk_id']?.toString(),
      clientName: clientName?.toString(),
      licensePlate: plate?.toString(),
      quoteDate: json['quote_date']?.toString() ?? json['created_at']?.toString(),
      validUntil: json['valid_until']?.toString(),
      subtotal: parseDouble(json['subtotal']),
      taxAmount: parseDouble(json['tax_amount']),
      total: parseDouble(json['total'] ?? json['total_amount'] ?? json['cost_estimate']),
      status: json['status']?.toString() ?? 'pendiente',
      notes: json['notes']?.toString() ?? json['observations']?.toString(),
      items: parseItems(json['quote_items'] ?? json['items']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (quoteNumber != null) 'quote_number': quoteNumber,
    if (clientsFkId != null) 'clients_fk_id': clientsFkId,
    if (vehiclesFkId != null) 'vehicles_fk_id': vehiclesFkId,
    'quote_date': quoteDate,
    'valid_until': validUntil,
    'subtotal': subtotal,
    'tax_amount': taxAmount,
    'total': total,
    'status': status,
    'notes': notes,
  };
}
