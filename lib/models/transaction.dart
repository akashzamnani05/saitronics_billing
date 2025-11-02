// models/transaction.dart

import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  sale,
  purchase,
}

class Transaction {
  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final TransactionType type; // sale or purchase
  final String partyId;
  final String partyName;
  final double amount; // Grand total
  final double subtotal; // Amount before GST
  final double gstAmount; // Total GST
  final double discount;
  final int itemCount;
  final DateTime transactionDate; // Invoice date
  final DateTime createdAt; // When transaction was recorded
  final bool isPaid;
  final String? paymentMethod; // Optional: cash, card, upi, etc.
  final String? notes; // Optional notes

  Transaction({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.type,
    required this.partyId,
    required this.partyName,
    required this.amount,
    required this.subtotal,
    required this.gstAmount,
    required this.discount,
    required this.itemCount,
    required this.transactionDate,
    required this.createdAt,
    this.isPaid = false,
    this.paymentMethod,
    this.notes,
  });

  // For display purposes
  String get typeLabel => type == TransactionType.sale ? 'Sale' : 'Purchase';
  
  // For financial calculations
  double get netAmount => amount - discount;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'invoiceId': invoiceId,
      'invoiceNumber': invoiceNumber,
      'type': type.name, // 'sale' or 'purchase'
      'partyId': partyId,
      'partyName': partyName,
      'amount': amount,
      'subtotal': subtotal,
      'gstAmount': gstAmount,
      'discount': discount,
      'itemCount': itemCount,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
      'notes': notes,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'] ?? '',
      invoiceId: map['invoiceId'] ?? '',
      invoiceNumber: map['invoiceNumber'] ?? '',
      type: map['type'] == 'sale' 
          ? TransactionType.sale 
          : TransactionType.purchase,
      partyId: map['partyId'] ?? '',
      partyName: map['partyName'] ?? '',
      amount: (map['amount'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      gstAmount: (map['gstAmount'] ?? 0).toDouble(),
      discount: (map['discount'] ?? 0).toDouble(),
      itemCount: map['itemCount'] ?? 0,
      transactionDate: (map['transactionDate'] as Timestamp).toDate(),
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      isPaid: map['isPaid'] ?? false,
      paymentMethod: map['paymentMethod'],
      notes: map['notes'],
    );
  }

  Transaction copyWith({
    String? id,
    String? invoiceId,
    String? invoiceNumber,
    TransactionType? type,
    String? partyId,
    String? partyName,
    double? amount,
    double? subtotal,
    double? gstAmount,
    double? discount,
    int? itemCount,
    DateTime? transactionDate,
    DateTime? createdAt,
    bool? isPaid,
    String? paymentMethod,
    String? notes,
  }) {
    return Transaction(
      id: id ?? this.id,
      invoiceId: invoiceId ?? this.invoiceId,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      type: type ?? this.type,
      partyId: partyId ?? this.partyId,
      partyName: partyName ?? this.partyName,
      amount: amount ?? this.amount,
      subtotal: subtotal ?? this.subtotal,
      gstAmount: gstAmount ?? this.gstAmount,
      discount: discount ?? this.discount,
      itemCount: itemCount ?? this.itemCount,
      transactionDate: transactionDate ?? this.transactionDate,
      createdAt: createdAt ?? this.createdAt,
      isPaid: isPaid ?? this.isPaid,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      notes: notes ?? this.notes,
    );
  }
}