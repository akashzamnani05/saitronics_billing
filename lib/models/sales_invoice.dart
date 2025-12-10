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
  final double? finalAmount; // Editable final amount
  final String salesPersonName; // New field for salesperson name

  SalesInvoice({
    required this.id,
    required this.partyId,
    required this.partyName,
    required this.items,
    required this.invoiceDate,
    required this.invoiceNumber,
    required this.createdAt,
    this.discount = 0.0,
    this.finalAmount, // Optional - if null, uses calculated grandTotal
    this.salesPersonName = '', // Default to empty string
  });

  double get subtotal => items.fold(0, (sum, item) => sum + item.subtotal);
  double get totalGst => items.fold(0, (sum, item) => sum + item.gstAmount);
  double get grandTotalBeforeDiscount => subtotal + totalGst;
  double get calculatedGrandTotal => (grandTotalBeforeDiscount - discount).clamp(0, double.infinity);
  
  // This is the amount that will be used for party balance and as invoice final amount
  double get grandTotal => finalAmount ?? calculatedGrandTotal;

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
      'finalAmount': finalAmount, // Store the editable final amount
      'salesPersonName': salesPersonName, // Store salesperson name
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
      finalAmount: map['finalAmount'] != null ? (map['finalAmount'] as num).toDouble() : null,
      salesPersonName: map['salesPersonName'] ?? '', // Load salesperson name
    );
  }

  // Helper method to copy with updated final amount
  SalesInvoice copyWith({
    String? id,
    String? partyId,
    String? partyName,
    List<InvoiceItem>? items,
    DateTime? invoiceDate,
    String? invoiceNumber,
    DateTime? createdAt,
    double? discount,
    double? finalAmount,
    String? salesPersonName,
  }) {
    return SalesInvoice(
      id: id ?? this.id,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      items: items ?? this.items,
      invoiceDate: invoiceDate ?? this.invoiceDate,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      createdAt: createdAt ?? this.createdAt,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      salesPersonName: salesPersonName ?? this.salesPersonName,
    );
  }
}