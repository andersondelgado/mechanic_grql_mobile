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
    id: json['id']?.toString(),
    nombre: json['name'] ?? json['nombre'] ?? '',
    ci: json['identification_card'] ?? json['ci'] ?? '',
    telefono: json['phone'] ?? json['telefono'] ?? '',
    email: json['email'],
    whatsapp: json['whatsapp'],
    direccion: json['address'] ?? json['direccion'],
    status: json['status'],
    source: json['source'],
  );

  Map<String, dynamic> toJson() => {
    'name': nombre,
    'identification_card': ci,
    'phone': telefono,
    if (email != null) 'email': email,
    if (whatsapp != null) 'whatsapp': whatsapp,
    if (direccion != null) 'address': direccion,
    if (status != null) 'status': status,
    if (source != null) 'source': source,
  };
}
