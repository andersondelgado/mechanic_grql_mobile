class MetodoPago {
  final String id;
  final String country; // 'VE', 'CO', 'US', 'ES', 'GLOBAL'
  final String type; // 'pago_movil', 'zelle', 'divisa', 'usdt', 'transferencia', 'nequi', 'bizum'
  final String title;
  final String currency;
  final String? bankName;
  final String? phone;
  final String? taxId;
  final String? beneficiary;
  final String? accountNumber;
  final String? email;
  final String? binanceId;
  final String? walletAddress;
  final String? network;
  final String? instructions;
  final bool isActive;
  final String? qrCodeUrl;

  const MetodoPago({
    required this.id,
    required this.country,
    required this.type,
    required this.title,
    required this.currency,
    this.bankName,
    this.phone,
    this.taxId,
    this.beneficiary,
    this.accountNumber,
    this.email,
    this.binanceId,
    this.walletAddress,
    this.network,
    this.instructions,
    required this.isActive,
    this.qrCodeUrl,
  });

  factory MetodoPago.fromJson(Map<String, dynamic> json) {
    return MetodoPago(
      id: json['id'] as String? ?? '',
      country: json['country'] as String? ?? 'VE',
      type: json['type'] as String? ?? 'pago_movil',
      title: json['title'] as String? ?? 'Método de Pago',
      currency: json['currency'] as String? ?? 'VES',
      bankName: json['bank_name'] as String?,
      phone: json['phone'] as String?,
      taxId: json['tax_id'] as String?,
      beneficiary: json['beneficiary'] as String?,
      accountNumber: json['account_number'] as String?,
      email: json['email'] as String?,
      binanceId: json['binance_id'] as String?,
      walletAddress: json['wallet_address'] as String?,
      network: json['network'] as String?,
      instructions: json['instructions'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      qrCodeUrl: json['qr_code_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'country': country,
        'type': type,
        'title': title,
        'currency': currency,
        'bank_name': bankName,
        'phone': phone,
        'tax_id': taxId,
        'beneficiary': beneficiary,
        'account_number': accountNumber,
        'email': email,
        'binance_id': binanceId,
        'wallet_address': walletAddress,
        'network': network,
        'instructions': instructions,
        'is_active': isActive,
        'qr_code_url': qrCodeUrl,
      };

  String get copyableDetails {
    final buffer = StringBuffer();
    buffer.writeln('💳 *DATOS DE PAGO - TALLER 360*');
    buffer.writeln('📌 *Método:* $title ($currency)');
    if (bankName != null && bankName!.trim().isNotEmpty) {
      buffer.writeln('🏦 *Banco:* $bankName');
    }
    if (phone != null && phone!.trim().isNotEmpty) {
      buffer.writeln('📱 *Teléfono:* $phone');
    }
    if (taxId != null && taxId!.trim().isNotEmpty) {
      buffer.writeln('🆔 *Cédula/RIF:* $taxId');
    }
    if (beneficiary != null && beneficiary!.trim().isNotEmpty) {
      buffer.writeln('👤 *Titular:* $beneficiary');
    }
    if (accountNumber != null && accountNumber!.trim().isNotEmpty) {
      buffer.writeln('🔢 *Cuenta:* $accountNumber');
    }
    if (email != null && email!.trim().isNotEmpty) {
      buffer.writeln('📧 *Correo / Zelle:* $email');
    }
    if (binanceId != null && binanceId!.trim().isNotEmpty) {
      buffer.writeln('🟡 *Binance Pay ID:* $binanceId');
    }
    if (walletAddress != null && walletAddress!.trim().isNotEmpty) {
      buffer.writeln('🔗 *Billetera ($network):* $walletAddress');
    }
    if (instructions != null && instructions!.trim().isNotEmpty) {
      buffer.writeln('ℹ️ *Nota:* $instructions');
    }
    return buffer.toString().trim();
  }
}
