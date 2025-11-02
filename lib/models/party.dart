import 'package:cloud_firestore/cloud_firestore.dart';

class Party {
  final String id;
  final String name;
  final String address;
  final String email;
  final String gstNumber;
  final String panNumber;
  final String phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double balance; // positive = party owes us, negative = we owe party
  final List<String> transactionHistory; // stores invoice numbers with amounts

  Party({
    required this.id,
    required this.name,
    required this.address,
    required this.email,
    required this.gstNumber,
    required this.panNumber,
    required this.phone,
    required this.createdAt,
    required this.updatedAt,
    this.balance = 0.0,
    this.transactionHistory = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'address': address,
      'email': email,
      'gstNumber': gstNumber,
      'panNumber': panNumber,
      'phone': phone,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'balance': balance,
      'transactionHistory': transactionHistory,
    };
  }

  factory Party.fromMap(Map<String, dynamic> map) {
    return Party(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      email: map['email'] ?? '',
      gstNumber: map['gstNumber'] ?? '',
      panNumber: map['panNumber'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
      balance: (map['balance'] ?? 0.0).toDouble(),
      transactionHistory: List<String>.from(map['transactionHistory'] ?? []),
    );
  }

  Party copyWith({
    String? id,
    String? name,
    String? address,
    String? email,
    String? gstNumber,
    String? panNumber,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? balance,
    List<String>? transactionHistory,
  }) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      email: email ?? this.email,
      gstNumber: gstNumber ?? this.gstNumber,
      panNumber: panNumber ?? this.panNumber,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      balance: balance ?? this.balance,
      transactionHistory: transactionHistory ?? this.transactionHistory,
    );
  }

  /// Returns a formatted string showing the balance status
  String getBalanceStatus() {
    if (balance > 0) {
      return 'To Receive: ₹${balance.toStringAsFixed(2)}';
    } else if (balance < 0) {
      return 'To Pay: ₹${balance.abs().toStringAsFixed(2)}';
    } else {
      return 'Settled';
    }
  }

  /// Returns color code for balance display
  /// Green for positive (money to receive), Red for negative (money to pay)
  String getBalanceColor() {
    if (balance > 0) return 'green';
    if (balance < 0) return 'red';
    return 'grey';
  }
}