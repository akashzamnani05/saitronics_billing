import 'package:cloud_firestore/cloud_firestore.dart';

class Item {
  final String id;
  final String name;
  final String description;
  final String hsnCode;
  final double sellingPrice;
  final double purchasePrice;
  final double gstPercent;
  final double openingStock;
  final double currentStock;
  final String category;
  final DateTime createdAt;
  final DateTime updatedAt;

  Item({
    required this.id,
    required this.name,
    required this.description,
    required this.hsnCode,
    required this.sellingPrice,
    required this.purchasePrice,
    required this.gstPercent,
    required this.openingStock,
    required this.currentStock,
    required this.category,
    required this.createdAt,
    required this.updatedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'hsnCode': hsnCode,
      'sellingPrice': sellingPrice,
      'purchasePrice': purchasePrice,
      'gstPercent': gstPercent,
      'openingStock': openingStock,
      'currentStock': currentStock,
      'category': category,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  factory Item.fromMap(Map<String, dynamic> map) {
    return Item(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      hsnCode: map['hsnCode'] ?? '',
      sellingPrice: (map['sellingPrice'] ?? 0).toDouble(),
      purchasePrice: (map['purchasePrice'] ?? 0).toDouble(),
      gstPercent: (map['gstPercent'] ?? 0).toDouble(),
      openingStock: (map['openingStock'] ?? 0).toDouble(),
      currentStock: (map['currentStock'] ?? 0).toDouble(),
      category: map['category'] ?? 'A',
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      updatedAt: (map['updatedAt'] as Timestamp).toDate(),
    );
  }

  Item copyWith({
    String? id,
    String? name,
    String? description,
    String? hsnCode,
    double? sellingPrice,
    double? purchasePrice,
    double? gstPercent,
    double? openingStock,
    double? currentStock,
    String? category,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      sellingPrice: sellingPrice ?? this.sellingPrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      gstPercent: gstPercent ?? this.gstPercent,
      openingStock: openingStock ?? this.openingStock,
      currentStock: currentStock ?? this.currentStock,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}