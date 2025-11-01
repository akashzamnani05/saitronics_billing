import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:saitronics_billing/models/invoice_item.dart';

class SalesInvoice {
  final String id;
  final String partyId;
  final String partyName;
  final List<InvoiceItem> items;
  final DateTime invoiceDate;
  final String invoiceNumber;
  final DateTime createdAt;
  final double discount;

  SalesInvoice({
    required this.id,
    required this.partyId,
    required this.partyName,
    required this.items,
    required this.invoiceDate,
    required this.invoiceNumber,
    required this.createdAt,
    this.discount = 0.0,
    
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalGst => items.fold(0, (sum, item) => sum + item.gstAmount);
  double get grandTotalBeforeDiscount => subtotal + totalGst;
   double get grandTotal => (grandTotalBeforeDiscount - discount).clamp(0, double.infinity);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'partyId': partyId,
      'partyName': partyName,
      'items': items.map((item) => item.toMap()).toList(),
      'invoiceDate': Timestamp.fromDate(invoiceDate),
      'invoiceNumber': invoiceNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'discount': discount,
    };
  }

  factory SalesInvoice.fromMap(Map<String, dynamic> map) {
    return SalesInvoice(
      id: map['id'] ?? '',
      partyId: map['partyId'] ?? '',
      partyName: map['partyName'] ?? '',
      items: (map['items'] as List<dynamic>)
          .map((item) => InvoiceItem.fromMap(item))
          .toList(),
      invoiceDate: (map['invoiceDate'] as Timestamp).toDate(),
      invoiceNumber: map['invoiceNumber'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
       discount: (map['discount'] ?? 0).toDouble(),
    );
  }
}