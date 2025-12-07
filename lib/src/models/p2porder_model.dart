// Definición de P2POrder (necesaria para el servicio de Binance)
class P2POrder {
  final double price;
  final double minTrade;

  P2POrder({required this.price, required this.minTrade});

  factory P2POrder.fromJson(Map<String, dynamic> json) {
    final priceString = json['adv']['price'] as String;
    final minTradeString = json['adv']['minSingleTransAmount'] as String;

    return P2POrder(
      price: double.tryParse(priceString) ?? 0.0,
      minTrade: double.tryParse(minTradeString) ?? 0.0,
    );
  }
}
