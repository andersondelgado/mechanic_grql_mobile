import 'inspection_analysis.dart';

class Peritaje {
  final String? id;
  final String vehiclesFkId;
  final String? clientsFkId;
  final String? employeesFkId;
  final String inspectionType;
  final String? inspectionDate;
  final String? itemName;
  final bool checkYes;
  final bool checkNo;
  final String? observations;
  final String? status;
  final double? costEstimate;

  // Enriched fields from related tables
  final String? clientName;
  final String? clientTaxId;
  final String? clientPhone;
  final String? clientEmail;
  final String? clientAddress;
  final String? licensePlate;
  final String? vehicleBrand;
  final String? vehicleModel;
  final String? vehicleYear;
  final String? vehicleColor;
  final String? vehicleVin;
  final String? vehicleMileage;
  final String? inspectorName;
  final InspectionAnalysis? analysis;

  // Digital Signature
  final String? clientSignature;
  final String? clientSignatureDate;

  Peritaje({
    this.id,
    required this.vehiclesFkId,
    this.clientsFkId,
    this.employeesFkId,
    this.inspectionType = 'general',
    this.inspectionDate,
    this.itemName,
    this.checkYes = false,
    this.checkNo = false,
    this.observations,
    this.status = 'pending',
    this.costEstimate,
    this.clientName,
    this.clientTaxId,
    this.clientPhone,
    this.clientEmail,
    this.clientAddress,
    this.licensePlate,
    this.vehicleBrand,
    this.vehicleModel,
    this.vehicleYear,
    this.vehicleColor,
    this.vehicleVin,
    this.vehicleMileage,
    this.inspectorName,
    this.analysis,
    this.clientSignature,
    this.clientSignatureDate,
  });

  String get code {
    if (id == null || id!.isEmpty) return 'PER-001';
    final cleanId = id!.replaceAll('-', '');
    return 'PER-${cleanId.length >= 4 ? cleanId.substring(cleanId.length - 4).toUpperCase() : cleanId.toUpperCase()}';
  }

  factory Peritaje.fromJson(Map<String, dynamic> json) {
    final client = (json['clients'] is List && (json['clients'] as List).isNotEmpty)
        ? json['clients'][0]
        : (json['client'] is Map ? json['client'] : null);

    final vehicle = (json['vehicles'] is List && (json['vehicles'] as List).isNotEmpty)
        ? json['vehicles'][0]
        : (json['vehicle'] is Map ? json['vehicle'] : null);

    final employee = (json['employees'] is List && (json['employees'] as List).isNotEmpty)
        ? json['employees'][0]
        : (json['employee'] is Map ? json['employee'] : null);

    InspectionAnalysis? parsedAnalysis;
    if (json['inspection_analysis'] is List && (json['inspection_analysis'] as List).isNotEmpty) {
      parsedAnalysis = InspectionAnalysis.fromJson((json['inspection_analysis'] as List)[0]);
    } else if (json['analysis'] is Map) {
      parsedAnalysis = InspectionAnalysis.fromJson(json['analysis']);
    }

    double? parseCost(dynamic v) {
      if (v == null) return null;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString());
    }

    String? extractId() {
      final id = json['id']?.toString().trim();
      if (id != null && id.isNotEmpty) return id;
      final cId = json['card_id']?.toString().trim();
      if (cId != null && cId.isNotEmpty) return cId;
      final underId = json['_id']?.toString().trim();
      if (underId != null && underId.isNotEmpty) return underId;
      return null;
    }

    String extractVehicleId() {
      final vFk = json['vehicles_fk_id']?.toString().trim();
      if (vFk != null && vFk.isNotEmpty) return vFk;
      if (vehicle != null && vehicle is Map) {
        final vId = vehicle['id']?.toString().trim() ?? vehicle['vehicle_id']?.toString().trim();
        if (vId != null && vId.isNotEmpty) return vId;
      }
      return '';
    }

    return Peritaje(
      id: extractId(),
      vehiclesFkId: extractVehicleId(),
      clientsFkId: json['clients_fk_id']?.toString(),
      employeesFkId: json['employees_fk_id']?.toString(),
      inspectionType: json['inspection_type']?.toString() ?? 'revisión',
      inspectionDate: json['inspection_date']?.toString() ?? json['created_at']?.toString(),
      itemName: json['item_name']?.toString() ?? 'Peritaje Técnico Automotriz',
      checkYes: json['check_yes'] == true || json['check_yes'] == 1 || json['check_yes'] == 'true',
      checkNo: json['check_no'] == true || json['check_no'] == 1 || json['check_no'] == 'true',
      observations: json['observations']?.toString(),
      status: json['status']?.toString() ?? 'completado',
      costEstimate: parseCost(json['cost_estimate']),
      clientName: client?['client_name']?.toString() ?? json['client_name']?.toString(),
      clientTaxId: client?['tax_id']?.toString() ?? json['client_tax_id']?.toString(),
      clientPhone: client?['phone']?.toString() ?? json['client_phone']?.toString(),
      clientEmail: client?['email']?.toString(),
      clientAddress: client?['address']?.toString(),
      licensePlate: vehicle?['license_plate']?.toString() ?? json['license_plate']?.toString() ?? 'SIN PLACA',
      vehicleBrand: vehicle?['brand']?.toString() ?? json['brand']?.toString(),
      vehicleModel: vehicle?['model']?.toString() ?? json['model']?.toString(),
      vehicleYear: vehicle?['year']?.toString() ?? json['year']?.toString(),
      vehicleColor: vehicle?['color']?.toString() ?? json['color']?.toString(),
      vehicleVin: vehicle?['vin']?.toString(),
      vehicleMileage: json['mileage']?.toString() ?? vehicle?['mileage']?.toString(),
      inspectorName: employee != null
          ? '${employee['first_name'] ?? ''} ${employee['last_name'] ?? ''}'.trim()
          : json['inspector_name']?.toString(),
      analysis: parsedAnalysis,
      clientSignature: json['client_signature']?.toString(),
      clientSignatureDate: json['client_signature_date']?.toString(),
    );
  }

  Peritaje copyWith({
    String? id,
    String? vehiclesFkId,
    String? clientsFkId,
    String? employeesFkId,
    String? inspectionType,
    String? inspectionDate,
    String? itemName,
    bool? checkYes,
    bool? checkNo,
    String? observations,
    String? status,
    double? costEstimate,
    String? clientName,
    String? clientTaxId,
    String? clientPhone,
    String? clientEmail,
    String? clientAddress,
    String? licensePlate,
    String? vehicleBrand,
    String? vehicleModel,
    String? vehicleYear,
    String? vehicleColor,
    String? vehicleVin,
    String? vehicleMileage,
    String? inspectorName,
    InspectionAnalysis? analysis,
    String? clientSignature,
    String? clientSignatureDate,
  }) {
    return Peritaje(
      id: id ?? this.id,
      vehiclesFkId: vehiclesFkId ?? this.vehiclesFkId,
      clientsFkId: clientsFkId ?? this.clientsFkId,
      employeesFkId: employeesFkId ?? this.employeesFkId,
      inspectionType: inspectionType ?? this.inspectionType,
      inspectionDate: inspectionDate ?? this.inspectionDate,
      itemName: itemName ?? this.itemName,
      checkYes: checkYes ?? this.checkYes,
      checkNo: checkNo ?? this.checkNo,
      observations: observations ?? this.observations,
      status: status ?? this.status,
      costEstimate: costEstimate ?? this.costEstimate,
      clientName: clientName ?? this.clientName,
      clientTaxId: clientTaxId ?? this.clientTaxId,
      clientPhone: clientPhone ?? this.clientPhone,
      clientEmail: clientEmail ?? this.clientEmail,
      clientAddress: clientAddress ?? this.clientAddress,
      licensePlate: licensePlate ?? this.licensePlate,
      vehicleBrand: vehicleBrand ?? this.vehicleBrand,
      vehicleModel: vehicleModel ?? this.vehicleModel,
      vehicleYear: vehicleYear ?? this.vehicleYear,
      vehicleColor: vehicleColor ?? this.vehicleColor,
      vehicleVin: vehicleVin ?? this.vehicleVin,
      vehicleMileage: vehicleMileage ?? this.vehicleMileage,
      inspectorName: inspectorName ?? this.inspectorName,
      analysis: analysis ?? this.analysis,
      clientSignature: clientSignature ?? this.clientSignature,
      clientSignatureDate: clientSignatureDate ?? this.clientSignatureDate,
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'card_id': id,
    'vehicles_fk_id': vehiclesFkId,
    if (clientsFkId != null) 'clients_fk_id': clientsFkId,
    if (employeesFkId != null) 'employees_fk_id': employeesFkId,
    'inspection_type': inspectionType,
    if (inspectionDate != null) 'inspection_date': inspectionDate,
    if (itemName != null) 'item_name': itemName,
    'check_yes': checkYes,
    'check_no': checkNo,
    if (observations != null) 'observations': observations,
    if (status != null) 'status': status,
    if (costEstimate != null) 'cost_estimate': costEstimate,
    if (clientSignature != null) 'client_signature': clientSignature,
    if (clientSignatureDate != null) 'client_signature_date': clientSignatureDate,
  };
}
