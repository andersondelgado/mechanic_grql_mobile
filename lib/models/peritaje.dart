class Peritaje {
  final String? id;
  final String vehiclesFkId;
  final String inspectionType;
  final String? inspectionDate;
  final String? itemName;
  final bool checkYes;
  final bool checkNo;
  final String? observations;

  Peritaje({
    this.id,
    required this.vehiclesFkId,
    required this.inspectionType,
    this.inspectionDate,
    this.itemName,
    this.checkYes = false,
    this.checkNo = false,
    this.observations,
  });

  factory Peritaje.fromJson(Map<String, dynamic> json) => Peritaje(
    id: json['card_id'] ?? json['id']?.toString(),
    vehiclesFkId: json['vehicles_fk_id'] ?? '',
    inspectionType: json['inspection_type'] ?? 'general',
    inspectionDate: json['inspection_date'],
    itemName: json['item_name'],
    checkYes: json['check_yes'] == true || json['check_yes'] == 1 || json['check_yes'] == 'true',
    checkNo: json['check_no'] == true || json['check_no'] == 1 || json['check_no'] == 'true',
    observations: json['observations'],
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'card_id': id,
    'vehicles_fk_id': vehiclesFkId,
    'inspection_type': inspectionType,
    if (inspectionDate != null) 'inspection_date': inspectionDate,
    if (itemName != null) 'item_name': itemName,
    'check_yes': checkYes,
    'check_no': checkNo,
    if (observations != null) 'observations': observations,
  };
}
