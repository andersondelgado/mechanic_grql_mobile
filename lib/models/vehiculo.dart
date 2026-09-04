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
    id: json['id']?.toString(),
    clientsFkId: json['clients_fk_id'] ?? '',
    clientName: (json['clients'] != null && (json['clients'] as List).isNotEmpty)
        ? json['clients'][0]['client_name']
        : null,
    brand: json['brand'],
    model: json['model'],
    licensePlate: json['license_plate'] ?? '',
    color: json['color'],
    vin: json['vin'],
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'clients_fk_id': clientsFkId,
    if (brand != null) 'brand': brand,
    if (model != null) 'model': model,
    'license_plate': licensePlate,
    if (color != null) 'color': color,
    if (vin != null) 'vin': vin,
  };
}
