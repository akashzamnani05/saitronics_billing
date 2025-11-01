class InvoiceItem {
  final String itemId;
  final String itemName;
  final String hsnCode;
  final double quantity;
  final double price; // price is GST-inclusive
  final double gstPercent;

  InvoiceItem({
    required this.itemId,
    required this.itemName,
    required this.hsnCode,
    required this.quantity,
    required this.price,
    required this.gstPercent,
  });

  /// Base price per unit excluding GST
  double get basePricePerUnit => price / (1 + gstPercent / 100);

  /// GST per unit (extracted from inclusive price)
  double get gstPerUnit => price - basePricePerUnit;

  /// Subtotal (without GST)
  double get subtotal => basePricePerUnit * quantity;

  /// Total GST amount extracted
  double get gstAmount => gstPerUnit * quantity;

  /// Split GST (for display)
  double get cgst => gstAmount / 2;
  double get sgst => gstAmount / 2;

  /// Final total (same as entered inclusive price × quantity)
  double get total => price * quantity;

  Map<String, dynamic> toMap() {
    return {
      'itemId': itemId,
      'itemName': itemName,
      'hsnCode': hsnCode,
      'quantity': quantity,
      'price': price,
      'gstPercent': gstPercent,
    };
  }

  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      itemId: map['itemId'] ?? '',
      itemName: map['itemName'] ?? '',
      hsnCode: map['hsnCode'] ?? '',
      quantity: (map['quantity'] ?? 0).toDouble(),
      price: (map['price'] ?? 0).toDouble(),
      gstPercent: (map['gstPercent'] ?? 0).toDouble(),
    );
  }
}
