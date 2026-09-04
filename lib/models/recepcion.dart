class Recepcion {
  final String? id;
  final String vehiclesFkId;
  final String? employeesFkId;
  final String? entryDate;
  final String? ownerName;
  final String? licensePlate;
  final String? brand;
  final String? model;
  final String? reasonForEntry;
  final String? workPerformed;
  final String status; // Virtual field if we manage states in UI, though not in schema natively (maybe derived from exit_date)

  Recepcion({
    this.id,
    required this.vehiclesFkId,
    this.employeesFkId,
    this.entryDate,
    this.ownerName,
    this.licensePlate,
    this.brand,
    this.model,
    this.reasonForEntry,
    this.workPerformed,
    this.status = 'pending',
  });

  factory Recepcion.fromJson(Map<String, dynamic> json) => Recepcion(
    id: json['receipt_id'] ?? json['id']?.toString(),
    vehiclesFkId: json['vehicles_fk_id'] ?? '',
    employeesFkId: json['employees_fk_id'],
    entryDate: json['entry_date'],
    ownerName: json['owner_name'],
    licensePlate: json['license_plate'],
    brand: json['brand'],
    model: json['model'],
    reasonForEntry: json['reason_for_entry'],
    workPerformed: json['work_performed'],
    status: json['exit_date'] != null ? 'completed' : 'pending',
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'receipt_id': id,
    'vehicles_fk_id': vehiclesFkId,
    if (employeesFkId != null) 'employees_fk_id': employeesFkId,
    if (entryDate != null) 'entry_date': entryDate,
    if (ownerName != null) 'owner_name': ownerName,
    if (licensePlate != null) 'license_plate': licensePlate,
    if (brand != null) 'brand': brand,
    if (model != null) 'model': model,
    if (reasonForEntry != null) 'reason_for_entry': reasonForEntry,
    if (workPerformed != null) 'work_performed': workPerformed,
  };
}
