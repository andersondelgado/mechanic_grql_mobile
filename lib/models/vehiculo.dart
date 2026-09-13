class Vehiculo {
  final String? id;
  final String clientsFkId;
  final String? clientName;
  final String? brand;
  final String? model;
  final String licensePlate;
  final String? color;
  final String? vin;

  Vehiculo({
    this.id,
    required this.clientsFkId,
    this.clientName,
    this.brand,
    this.model,
    required this.licensePlate,
    this.color,
    this.vin,
  });

  factory Vehiculo.fromJson(Map<String, dynamic> json) => Vehiculo(
    id: json['vehicle_id']?.toString() ?? json['id']?.toString(),
    clientsFkId: json['clients_fk_id']?.toString() ?? '',
    clientName: json['client_name']?.toString() ??
        ((json['clients'] != null && (json['clients'] as List).isNotEmpty)
            ? json['clients'][0]['client_name']?.toString()
            : null),
    brand: json['brand']?.toString(),
    model: json['model']?.toString(),
    licensePlate: json['license_plate']?.toString() ?? '',
    color: json['color']?.toString(),
    vin: json['vin']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'vehicle_id': id,
    if (id != null) 'id': id,
    'clients_fk_id': clientsFkId,
    if (brand != null) 'brand': brand,
    if (model != null) 'model': model,
    'license_plate': licensePlate,
    if (color != null) 'color': color,
    if (vin != null) 'vin': vin,
  };
}
