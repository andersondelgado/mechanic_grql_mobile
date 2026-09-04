class Factura {
  final String? id;
  final String? vehiclesFkId;
  final String? clientsFkId;
  final String noteNumber;
  final String? noteDate;
  final String? clientName;
  final String? licensePlate;
  final double? subtotal;
  final double? total;

  Factura({
    this.id,
    this.vehiclesFkId,
    this.clientsFkId,
    required this.noteNumber,
    this.noteDate,
    this.clientName,
    this.licensePlate,
    this.subtotal,
    this.total,
  });

  factory Factura.fromJson(Map<String, dynamic> json) => Factura(
    id: json['delivery_note_id'] ?? json['id']?.toString(),
    vehiclesFkId: json['vehicles_fk_id'],
    clientsFkId: json['clients_fk_id'],
    noteNumber: json['note_number'] ?? '',
    noteDate: json['note_date'],
    clientName: json['client_name'],
    licensePlate: json['license_plate'],
    subtotal: json['subtotal'] != null ? double.tryParse(json['subtotal'].toString()) : null,
    total: json['total'] != null ? double.tryParse(json['total'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'delivery_note_id': id,
    if (vehiclesFkId != null) 'vehicles_fk_id': vehiclesFkId,
    if (clientsFkId != null) 'clients_fk_id': clientsFkId,
    'note_number': noteNumber,
    if (noteDate != null) 'note_date': noteDate,
    if (clientName != null) 'client_name': clientName,
    if (licensePlate != null) 'license_plate': licensePlate,
    if (subtotal != null) 'subtotal': subtotal,
    if (total != null) 'total': total,
  };
}
