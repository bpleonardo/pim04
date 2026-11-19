class ServicePriceChange {
  const ServicePriceChange(
      {required this.oldPrice,
      required this.newPrice,
      required this.changedAt});
  final double oldPrice, newPrice;
  final DateTime changedAt;
  factory ServicePriceChange.fromJson(Map<String, dynamic> json) =>
      ServicePriceChange(
          oldPrice: (json['oldPrice'] as num).toDouble(),
          newPrice: (json['newPrice'] as num).toDouble(),
          changedAt: DateTime.parse(json['changedAt'] as String));
}
