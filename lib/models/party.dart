

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
    );
  }
}