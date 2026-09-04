class Repuesto {
  final String? id;
  final String partCode;
  final String description;
  final String? brand;
  final String? category;
  final double? priceWithoutTax;
  final int? stockMain;

  Repuesto({
    this.id,
    required this.partCode,
    required this.description,
    this.brand,
    this.category,
    this.priceWithoutTax,
    this.stockMain,
  });

  factory Repuesto.fromJson(Map<String, dynamic> json) => Repuesto(
    id: json['part_id'] ?? json['id']?.toString(),
    partCode: json['part_code'] ?? '',
    description: json['description'] ?? '',
    brand: json['brand'],
    category: json['category'],
    priceWithoutTax: json['price_without_tax'] != null ? double.tryParse(json['price_without_tax'].toString()) : null,
    stockMain: json['stock_main'] != null ? int.tryParse(json['stock_main'].toString()) : null,
  );

  Map<String, dynamic> toJson() => {
    if (id != null) 'part_id': id,
    'part_code': partCode,
    'description': description,
    if (brand != null) 'brand': brand,
    if (category != null) 'category': category,
    if (priceWithoutTax != null) 'price_without_tax': priceWithoutTax,
    if (stockMain != null) 'stock_main': stockMain,
  };
}
