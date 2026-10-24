class Recepcion {
  final String? id;
  final String? receiptNumber;
  final String vehiclesFkId;
  final String? employeesFkId;
  final String? entryDate;
  final String? exitDate;
  final String? ownerName;
  final String? ownerTaxId;
  final String? phone;
  final String? email;
  final String? address;
  final String? licensePlate;
  final String? brand;
  final String? model;
  final String? year;
  final String? color;
  final String? mileage;
  final String? vin;
  final String? fuelLevel;
  final String? reasonForEntry;
  final String? workPerformed;
  final String status;
  final List<Map<String, dynamic>> checklistExternal;
  final List<Map<String, dynamic>> checklistInternal;
  final List<Map<String, dynamic>> damagePoints;
  final String? clientSignature;
  final String? clientSignatureDate;

  Recepcion({
    this.id,
    this.receiptNumber,
    required this.vehiclesFkId,
    this.employeesFkId,
    this.entryDate,
    this.exitDate,
    this.ownerName,
    this.ownerTaxId,
    this.phone,
    this.email,
    this.address,
    this.licensePlate,
    this.brand,
    this.model,
    this.year,
    this.color,
    this.mileage,
    this.vin,
    this.fuelLevel = '1/2',
    this.reasonForEntry,
    this.workPerformed,
    this.status = 'pendiente',
    this.checklistExternal = const [],
    this.checklistInternal = const [],
    this.damagePoints = const [],
    this.clientSignature,
    this.clientSignatureDate,
  });

  String get code {
    if (receiptNumber != null && receiptNumber!.isNotEmpty) return receiptNumber!;
    if (id == null || id!.isEmpty) return 'REC-001';
    final cleanId = id!.replaceAll('-', '');
    return 'REC-${cleanId.length >= 6 ? cleanId.substring(0, 6).toUpperCase() : cleanId.toUpperCase()}';
  }

  factory Recepcion.fromJson(Map<String, dynamic> json) {
    final client = (json['clients'] is List && (json['clients'] as List).isNotEmpty)
        ? json['clients'][0]
        : (json['client'] is Map ? json['client'] : null);

    final vehicle = (json['vehicles'] is List && (json['vehicles'] as List).isNotEmpty)
        ? json['vehicles'][0]
        : (json['vehicle'] is Map ? json['vehicle'] : null);

    List<Map<String, dynamic>> parseList(dynamic val) {
      if (val is List) {
        return val.map((e) => (e is Map) ? e.cast<String, dynamic>() : <String, dynamic>{}).toList();
      }
      return [];
    }

    final rawStatus = json['status']?.toString() ??
        (json['exit_date'] != null ? 'completado' : 'en_proceso');

    return Recepcion(
      id: json['receipt_id']?.toString() ?? json['id']?.toString(),
      receiptNumber: json['receipt_number']?.toString(),
      vehiclesFkId: json['vehicles_fk_id']?.toString() ?? '',
      employeesFkId: json['employees_fk_id']?.toString(),
      entryDate: json['entry_date']?.toString() ?? json['created_at']?.toString(),
      exitDate: json['exit_date']?.toString(),
      ownerName: client?['client_name']?.toString() ?? json['owner_name']?.toString() ?? json['client_name']?.toString(),
      ownerTaxId: client?['tax_id']?.toString() ?? json['owner_tax_id']?.toString(),
      phone: client?['phone']?.toString() ?? json['phone']?.toString(),
      email: client?['email']?.toString() ?? json['email']?.toString(),
      address: client?['address']?.toString() ?? json['address']?.toString(),
      licensePlate: vehicle?['license_plate']?.toString() ?? json['license_plate']?.toString() ?? 'SIN PLACA',
      brand: vehicle?['brand']?.toString() ?? json['brand']?.toString(),
      model: vehicle?['model']?.toString() ?? json['model']?.toString(),
      year: vehicle?['year']?.toString() ?? json['year']?.toString(),
      color: vehicle?['color']?.toString() ?? json['color']?.toString(),
      mileage: json['mileage']?.toString() ?? vehicle?['mileage']?.toString(),
      vin: vehicle?['vin']?.toString() ?? json['vin']?.toString(),
      fuelLevel: json['fuel_level']?.toString() ?? '1/2',
      reasonForEntry: json['reason_for_entry']?.toString(),
      workPerformed: json['work_performed']?.toString(),
      status: rawStatus,
      checklistExternal: parseList(json['checklist_external']),
      checklistInternal: parseList(json['checklist_internal']),
      damagePoints: parseList(json['damage_points']),
      clientSignature: json['client_signature']?.toString(),
      clientSignatureDate: json['client_signature_date']?.toString(),
    );
  }

  Recepcion copyWith({
    String? id,
    String? receiptNumber,
    String? vehiclesFkId,
    String? employeesFkId,
    String? entryDate,
    String? exitDate,
    String? ownerName,
    String? ownerTaxId,
    String? phone,
    String? email,
    String? address,
    String? licensePlate,
    String? brand,
    String? model,
    String? year,
    String? color,
    String? mileage,
    String? vin,
    String? fuelLevel,
    String? reasonForEntry,
    String? workPerformed,
    String? status,
    List<Map<String, dynamic>>? checklistExternal,
    List<Map<String, dynamic>>? checklistInternal,
    List<Map<String, dynamic>>? damagePoints,
    String? clientSignature,
    String? clientSignatureDate,
  }) {
    return Recepcion(
      id: id ?? this.id,
      receiptNumber: receiptNumber ?? this.receiptNumber,
      vehiclesFkId: vehiclesFkId ?? this.vehiclesFkId,
      employeesFkId: employeesFkId ?? this.employeesFkId,
      entryDate: entryDate ?? this.entryDate,
      exitDate: exitDate ?? this.exitDate,
      ownerName: ownerName ?? this.ownerName,
      ownerTaxId: ownerTaxId ?? this.ownerTaxId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      licensePlate: licensePlate ?? this.licensePlate,
      brand: brand ?? this.brand,
      model: model ?? this.model,
      year: year ?? this.year,
      color: color ?? this.color,
      mileage: mileage ?? this.mileage,
      vin: vin ?? this.vin,
      fuelLevel: fuelLevel ?? this.fuelLevel,
      reasonForEntry: reasonForEntry ?? this.reasonForEntry,
      workPerformed: workPerformed ?? this.workPerformed,
      status: status ?? this.status,
      checklistExternal: checklistExternal ?? this.checklistExternal,
      checklistInternal: checklistInternal ?? this.checklistInternal,
      damagePoints: damagePoints ?? this.damagePoints,
      clientSignature: clientSignature ?? this.clientSignature,
      clientSignatureDate: clientSignatureDate ?? this.clientSignatureDate,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'receipt_id': id,
    if (receiptNumber != null) 'receipt_number': receiptNumber,
    'vehicles_fk_id': vehiclesFkId,
    if (employeesFkId != null) 'employees_fk_id': employeesFkId,
    if (entryDate != null) 'entry_date': entryDate,
    if (exitDate != null) 'exit_date': exitDate,
    if (ownerName != null) 'owner_name': ownerName,
    if (ownerTaxId != null) 'owner_tax_id': ownerTaxId,
    if (phone != null) 'phone': phone,
    if (email != null) 'email': email,
    if (address != null) 'address': address,
    if (licensePlate != null) 'license_plate': licensePlate,
    if (brand != null) 'brand': brand,
    if (model != null) 'model': model,
    if (year != null) 'year': year,
    if (color != null) 'color': color,
    if (mileage != null) 'mileage': mileage,
    if (vin != null) 'vin': vin,
    if (fuelLevel != null) 'fuel_level': fuelLevel,
    if (reasonForEntry != null) 'reason_for_entry': reasonForEntry,
    if (workPerformed != null) 'work_performed': workPerformed,
    'status': status,
    if (clientSignature != null) 'client_signature': clientSignature,
    if (clientSignatureDate != null) 'client_signature_date': clientSignatureDate,
  };
}
