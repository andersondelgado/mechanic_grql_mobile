class Orden {
  final String? id;
  final String orderNumber;
  final String? orderDate;
  final String? entryDate;
  final String? brand;
  final String? model;
  final String? licensePlate;
  final String? color;
  final String? mileage;
  final String? assignedMechanic;
  final String? workPerformed;
  final String? description;
  final double totalCost;
  final double profit;
  final String status;
  final String? vehiclesFkId;
  final String? clientsFkId;
  final String? employeesFkId;
  final String? clientName;
  final String? taxId;

  const Orden({
    this.id,
    required this.orderNumber,
    this.orderDate,
    this.entryDate,
    this.brand,
    this.model,
    this.licensePlate,
    this.color,
    this.mileage,
    this.assignedMechanic,
    this.workPerformed,
    this.description,
    this.totalCost = 0.0,
    this.profit = 0.0,
    this.status = 'pendiente',
    this.vehiclesFkId,
    this.clientsFkId,
    this.employeesFkId,
    this.clientName,
    this.taxId,
  });

  factory Orden.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? 0.0;
    }

    String? extractFk(dynamic fk) {
      if (fk == null) return null;
      if (fk is List && fk.isNotEmpty) {
        final first = fk.first;
        return (first is Map) ? (first['id'] ?? first['_id'])?.toString() : first.toString();
      }
      if (fk is Map) {
        return (fk['id'] ?? fk['_id'])?.toString();
      }
      return fk.toString().trim().isNotEmpty ? fk.toString().trim() : null;
    }

    final client = (json['clients'] is List && (json['clients'] as List).isNotEmpty)
        ? json['clients'][0]
        : null;
    final vehicle = (json['vehicles'] is List && (json['vehicles'] as List).isNotEmpty)
        ? json['vehicles'][0]
        : null;
    final employee = (json['employees'] is List && (json['employees'] as List).isNotEmpty)
        ? json['employees'][0]
        : null;

    final clientName = client?['client_name'] ?? json['client_name'] ?? json['owner_name'];
    final taxId = client?['tax_id'] ?? json['tax_id'] ?? json['owner_tax_id'];
    final plate = vehicle?['license_plate'] ?? json['license_plate'];
    final vBrand = vehicle?['brand'] ?? json['brand'];
    final vModel = vehicle?['model'] ?? json['model'];

    final desc = json['work_performed'] ?? json['description'] ?? json['repair_details'] ?? '';

    return Orden(
      id: json['id']?.toString() ?? json['order_id']?.toString(),
      orderNumber: (json['order_number'] ?? json['orderNumber'] ?? 'ORD-SIN-NUM').toString(),
      orderDate: json['order_date']?.toString(),
      entryDate: json['entry_date']?.toString() ?? json['order_date']?.toString(),
      brand: vBrand?.toString(),
      model: vModel?.toString(),
      licensePlate: plate?.toString(),
      color: json['color']?.toString() ?? vehicle?['color']?.toString(),
      mileage: json['mileage']?.toString() ?? vehicle?['mileage']?.toString(),
      assignedMechanic: employee?['employee_name'] ?? json['assigned_mechanic']?.toString(),
      workPerformed: desc.toString(),
      description: desc.toString(),
      totalCost: parseDouble(json['total_cost'] ?? json['totalCost'] ?? json['cost']),
      profit: parseDouble(json['profit']),
      status: (json['status'] ?? 'pendiente').toString(),
      vehiclesFkId: extractFk(json['vehicles_fk_id']),
      clientsFkId: extractFk(json['clients_fk_id']),
      employeesFkId: extractFk(json['employees_fk_id']),
      clientName: clientName?.toString(),
      taxId: taxId?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'order_number': orderNumber,
      'order_date': orderDate ?? DateTime.now().toIso8601String(),
      'entry_date': entryDate ?? DateTime.now().toIso8601String().split('T')[0],
      if (brand != null) 'brand': brand,
      if (model != null) 'model': model,
      if (licensePlate != null) 'license_plate': licensePlate,
      if (color != null) 'color': color,
      if (mileage != null) 'mileage': mileage,
      if (assignedMechanic != null) 'assigned_mechanic': assignedMechanic,
      if (workPerformed != null) 'work_performed': workPerformed,
      if (description != null) 'description': description,
      'total_cost': totalCost,
      'profit': profit,
      'status': status,
      if (vehiclesFkId != null) 'vehicles_fk_id': vehiclesFkId,
      if (clientsFkId != null) 'clients_fk_id': clientsFkId,
      if (employeesFkId != null) 'employees_fk_id': employeesFkId,
      if (clientName != null) 'client_name': clientName,
      if (taxId != null) 'tax_id': taxId,
    };
  }
}
