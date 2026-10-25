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

    String? extractId() {
      final id = json['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
      final qId = json['quote_id']?.toString().trim();
      if (qId != null && qId.isNotEmpty) return qId;
      final underId = json['_id']?.toString().trim();
      if (underId != null && underId.isNotEmpty) return underId;
      return null;
    }

    String? extractVehicleId() {
      final vFk = json['vehicles_fk_id']?.toString().trim();
      if (vFk != null && vFk.isNotEmpty) return vFk;
      if (vehicle != null && vehicle is Map) {
        final vId = vehicle['id']?.toString().trim() ?? vehicle['vehicle_id']?.toString().trim();
        if (vId != null && vId.isNotEmpty) return vId;
      }
      return null;
    }

    final realId = extractId();

    return Cotizacion(
      id: realId,
      quoteNumber: json['quote_number']?.toString() ??
          (realId != null ? 'COT-${realId.substring(0, realId.length >= 6 ? 6 : realId.length).toUpperCase()}' : 'COT-001'),
      clientsFkId: json['clients_fk_id']?.toString(),
      vehiclesFkId: extractVehicleId(),
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
