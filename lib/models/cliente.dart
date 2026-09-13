class Cliente {
  final String? id;
  final String nombre;
  final String ci;
  final String telefono;
  final String? email;
  final String? whatsapp;
  final String? direccion;
  final String? status;
  final String? source;

  Cliente({
    this.id,
    required this.nombre,
    required this.ci,
    required this.telefono,
    this.email,
    this.whatsapp,
    this.direccion,
    this.status,
    this.source,
  });

  factory Cliente.fromJson(Map<String, dynamic> json) => Cliente(
    id: json['client_id']?.toString() ?? json['id']?.toString(),
    nombre:
        json['client_name']?.toString() ??
        json['name']?.toString() ??
        json['nombre']?.toString() ??
        '',
    ci:
        json['tax_id']?.toString() ??
        json['identification_card']?.toString() ??
        json['ci']?.toString() ??
        '',
    telefono:
        json['cell_phone']?.toString() ??
        json['phone']?.toString() ??
        json['telefono']?.toString() ??
        json['home_phone']?.toString() ??
        '',
    email: json['email']?.toString(),
    whatsapp: json['whatsapp']?.toString(),
    direccion: (json['address'] ?? json['direccion'])?.toString(),
    status: json['status']?.toString(),
    source: json['source']?.toString(),
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'client_id': id,
    if (id != null) 'id': id,
    'client_name': nombre,
    'tax_id': ci,
    'cell_phone': telefono,
    'name': nombre,
    'identification_card': ci,
    'phone': telefono,
    if (email != null) 'email': email,
    if (whatsapp != null) 'whatsapp': whatsapp,
    if (direccion != null) 'address': direccion,
    if (direccion != null) 'direccion': direccion,
    if (status != null) 'status': status,
    if (source != null) 'source': source,
  };
}
