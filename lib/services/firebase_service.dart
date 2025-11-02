import 'package:cloud_firestore/cloud_firestore.dart' hide Transaction;
import 'package:saitronics_billing/models/item.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/purchase_invoice.dart';
import 'package:saitronics_billing/models/sales_invoice.dart';
import 'package:saitronics_billing/models/transaction.dart';

import '../models/category.dart';

class FirebaseService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Collection references
  static CollectionReference get _itemsCollection =>
      _firestore.collection('items');
  static CollectionReference get _partiesCollection =>
      _firestore.collection('parties');
  static CollectionReference get _purchaseInvoicesCollection =>
      _firestore.collection('purchaseInvoices');
  static CollectionReference get _salesInvoicesCollection =>
      _firestore.collection('salesInvoices');
  static CollectionReference get _categoriesCollection =>
      _firestore.collection('categories');
      static CollectionReference get _transactionsCollection =>
    _firestore.collection('transactions');

  static CollectionReference get _counterCollection => _firestore.collection('counters');


   static Future<String> generatePurchaseInvoiceNumber() async {
    final counterRef = _counterCollection.doc('purchaseInvoice');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int newNumber = 1;
      if (snapshot.exists) {
        final currentNumber = snapshot.get('lastNumber') ?? 0;
        newNumber = currentNumber + 1;
      }

      // Update Firestore with the new number
      transaction.set(counterRef, {'lastNumber': newNumber});

      // Format it as PUR-0001, PUR-0002, etc.
      final formatted = 'P-${newNumber.toString().padLeft(4, '0')}';
      return formatted;
    });
  }

  static Future<String> generateSalesInvoiceNumber() async {
    final counterRef = _counterCollection.doc('saleInvoice');

    return _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(counterRef);

      int newNumber = 1;
      if (snapshot.exists) {
        final currentNumber = snapshot.get('lastNumber') ?? 0;
        newNumber = currentNumber + 1;
      }

      // Update Firestore with the new number
      transaction.set(counterRef, {'lastNumber': newNumber});

      // Format it as PUR-0001, PUR-0002, etc.
      final formatted = 'S-${newNumber.toString().padLeft(4, '0')}';
      return formatted;
    });
  }

  // ========== ITEM OPERATIONS ==========

  // Create Item
  static Future<String> createItem(Item item) async {
    try {
      await _itemsCollection.doc(item.id).set(item.toMap());
      return 'Item created successfully';
    } catch (e) {
      return 'Error creating item: $e';
    }
  }

  // Get all items
  static Stream<List<Item>> getItems() {
    return _itemsCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Item.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get single item
  static Future<Item?> getItemById(String id) async {
    try {
      final doc = await _itemsCollection.doc(id).get();
      if (doc.exists) {
        return Item.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting item: $e');
      return null;
    }
  }

  // Update Item
  static Future<String> updateItem(Item item) async {
    try {
      await _itemsCollection.doc(item.id).update(item.toMap());
      return 'Item updated successfully';
    } catch (e) {
      return 'Error updating item: $e';
    }
  }

  // Delete Item
  static Future<String> deleteItem(String id) async {
    try {
      await _itemsCollection.doc(id).delete();
      return 'Item deleted successfully';
    } catch (e) {
      return 'Error deleting item: $e';
    }
  }

  // Update Item Stock
  static Future<String> updateItemStock(
      String itemId, double newStock) async {
    try {
      await _itemsCollection.doc(itemId).update({
        'currentStock': newStock,
        'updatedAt': Timestamp.now(),
      });
      return 'Stock updated successfully';
    } catch (e) {
      return 'Error updating stock: $e';
    }
  }

  // ========== PARTY OPERATIONS ==========

  // Create Party
  static Future<String> createParty(Party party) async {
    try {
      await _partiesCollection.doc(party.id).set(party.toMap());
      return 'Party created successfully';
    } catch (e) {
      return 'Error creating party: $e';
    }
  }

  // Get all parties
  static Stream<List<Party>> getParties() {
    return _partiesCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Party.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Get single party
  static Future<Party?> getPartyById(String id) async {
    try {
      final doc = await _partiesCollection.doc(id).get();
      if (doc.exists) {
        return Party.fromMap(doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting party: $e');
      return null;
    }
  }

  // Update Party
  static Future<String> updateParty(Party party) async {
    try {
      await _partiesCollection.doc(party.id).update(party.toMap());
      return 'Party updated successfully';
    } catch (e) {
      return 'Error updating party: $e';
    }
  }

  // Delete Party
  static Future<String> deleteParty(String id) async {
    try {
      await _partiesCollection.doc(id).delete();
      return 'Party deleted successfully';
    } catch (e) {
      return 'Error deleting party: $e';
    }
  }


  static Future<void> migrateParties() async {
  final parties = await _firestore.collection('parties').get();
  
  for (var doc in parties.docs) {
    await doc.reference.update({
      'balance': 0.0,
      'transactionHistory': [],
    });
  }
}

  static Future<void> updatePartyBalance(
  String partyId,
  double amount,
  String invoiceNumber,
  {required bool isCredit}
) async {
  final partyRef = _firestore.collection('parties').doc(partyId);
  
  await _firestore.runTransaction((transaction) async {
    final partyDoc = await transaction.get(partyRef);
    
    if (!partyDoc.exists) throw Exception('Party not found');
    
    final currentBalance = partyDoc.data()?['balance'] ?? 0.0;
    final currentHistory = List<String>.from(partyDoc.data()?['transactionHistory'] ?? []);
    
    final newBalance = currentBalance + amount;
    final historyEntry = '${isCredit ? '+' : '-'}₹${amount.abs().toStringAsFixed(2)} - Invoice: $invoiceNumber';
    
    currentHistory.add(historyEntry);
    
    transaction.update(partyRef, {
      'balance': newBalance,
      'transactionHistory': currentHistory,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  });
}

  // ========== PURCHASE INVOICE OPERATIONS ==========

  // Create Purchase Invoice and update inventory
  static Future<String> createPurchaseInvoice(
      PurchaseInvoice invoice) async {
    try {
      // Use a batch write for atomic operations
      WriteBatch batch = _firestore.batch();

      // Add the invoice
      batch.set(_purchaseInvoicesCollection.doc(invoice.id), invoice.toMap());

      // Update stock for each item
      for (var invoiceItem in invoice.items) {
        final itemDoc = _itemsCollection.doc(invoiceItem.itemId);
        final itemSnapshot = await itemDoc.get();

        if (itemSnapshot.exists) {
          final currentStock =
              (itemSnapshot.data() as Map<String, dynamic>)['currentStock'] ??
                  0;
          batch.update(itemDoc, {
            'currentStock': currentStock + invoiceItem.quantity,
            'updatedAt': Timestamp.now(),
          });
        }
      }

      await batch.commit();
      return 'Purchase invoice created and inventory updated successfully';
    } catch (e) {
      return 'Error creating purchase invoice: $e';
    }
  }

  // Get all purchase invoices
  static Stream<List<PurchaseInvoice>> getPurchaseInvoices() {
    return _purchaseInvoicesCollection
        .orderBy('invoiceDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return PurchaseInvoice.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }



// Delete Purchase Invoice
static Future<String> deletePurchaseInvoice(String id) async {
  try {
    await _purchaseInvoicesCollection.doc(id).delete();
    return 'Purchase invoice deleted successfully';
  } catch (e) {
    return 'Error deleting purchase invoice: $e';
  }
}

// Delete Sales Invoice
static Future<String> deleteSalesInvoice(String id) async {
  try {
    await _salesInvoicesCollection.doc(id).delete();
    return 'Sales invoice deleted successfully';
  } catch (e) {
    return 'Error deleting sales invoice: $e';
  }
}

  // ========== SALES INVOICE OPERATIONS ==========

  // Create Sales Invoice and update inventory
  static Future<String> createSalesInvoice(SalesInvoice invoice) async {
    try {
      // First check if all items have sufficient stock
      for (var invoiceItem in invoice.items) {
        final itemDoc = await _itemsCollection.doc(invoiceItem.itemId).get();
        if (itemDoc.exists) {
          final currentStock =
              (itemDoc.data() as Map<String, dynamic>)['currentStock'] ?? 0;
          if (currentStock < invoiceItem.quantity) {
            return 'Insufficient stock for ${invoiceItem.itemName}. Available: $currentStock';
          }
        } else {
          return 'Item ${invoiceItem.itemName} not found';
        }
      }

      // Use a batch write for atomic operations
      WriteBatch batch = _firestore.batch();

      // Add the invoice
      batch.set(_salesInvoicesCollection.doc(invoice.id), invoice.toMap());

      // Update stock for each item
      for (var invoiceItem in invoice.items) {
        final itemDoc = _itemsCollection.doc(invoiceItem.itemId);
        final itemSnapshot = await itemDoc.get();

        final currentStock =
            (itemSnapshot.data() as Map<String, dynamic>)['currentStock'] ?? 0;
        batch.update(itemDoc, {
          'currentStock': currentStock - invoiceItem.quantity,
          'updatedAt': Timestamp.now(),
        });
      }

      await batch.commit();
      return 'Sales invoice created and inventory updated successfully';
    } catch (e) {
      return 'Error creating sales invoice: $e';
    }
  }

  // Get all sales invoices
  static Stream<List<SalesInvoice>> getSalesInvoices() {
    return _salesInvoicesCollection
        .orderBy('invoiceDate', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return SalesInvoice.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // ========== CATEGORY OPERATIONS ==========

  // Create Category
  static Future<String> createCategory(Category category) async {
    try {
      // Check if category already exists
      final existingCategories = await _categoriesCollection
          .where('name', isEqualTo: category.name)
          .get();

      if (existingCategories.docs.isNotEmpty) {
        return 'Category already exists';
      }

      await _categoriesCollection.doc(category.id).set(category.toMap());
      return 'Category created successfully';
    } catch (e) {
      return 'Error creating category: $e';
    }
  }

  // Get all categories
  static Stream<List<Category>> getCategories() {
    return _categoriesCollection.orderBy('name').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Category.fromMap(doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  // Delete Category
  static Future<String> deleteCategory(String id) async {
    try {
      // Check if any items are using this category
      final itemsWithCategory = await _itemsCollection
          .where('category', isEqualTo: id)
          .get();

      if (itemsWithCategory.docs.isNotEmpty) {
        return 'Cannot delete category. ${itemsWithCategory.docs.length} items are using it.';
      }

      await _categoriesCollection.doc(id).delete();
      return 'Category deleted successfully';
    } catch (e) {
      return 'Error deleting category: $e';
    }
  }

  // Initialize default categories if none exist
  static Future<void> initializeDefaultCategories() async {
    try {
      final snapshot = await _categoriesCollection.get();
      if (snapshot.docs.isEmpty) {
        final defaultCategories = ['A', 'B', 'C'];
        for (var name in defaultCategories) {
          final category = Category(
            id: name.toLowerCase(),
            name: name,
            createdAt: DateTime.now(),
          );
          await _categoriesCollection.doc(category.id).set(category.toMap());
        }
      }
    } catch (e) {
      print('Error initializing categories: $e');
    }
  }



  // ========== TRANSACTION OPERATIONS ==========

// Create Transaction
static Future<String> createTransaction(Transaction transaction) async {
  try {
    await _transactionsCollection.doc(transaction.id).set(transaction.toMap());
    return 'Transaction recorded successfully';
  } catch (e) {
    return 'Error creating transaction: $e';
  }
}

// Get all transactions
static Stream<List<Transaction>> getTransactions() {
  return _transactionsCollection
      .orderBy('transactionDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return Transaction.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  });
}

// Get transactions by type
static Stream<List<Transaction>> getTransactionsByType(TransactionType type) {
  return _transactionsCollection
      .where('type', isEqualTo: type.name)
      .orderBy('transactionDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return Transaction.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  });
}

// 1. All Transactions (sorted by date descending)
static Stream<List<Transaction>> getTransactionsByParty(String partyId) {
  return FirebaseFirestore.instance
      .collection('transactions')
      .where('partyId', isEqualTo: partyId)
      .orderBy('transactionDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Transaction.fromMap(doc.data()))
          .toList());
}

// 2. Unpaid Transactions
static Stream<List<Transaction>> getUnpaidTransactionsByParty(String partyId) {
  return FirebaseFirestore.instance
      .collection('transactions')
      .where('partyId', isEqualTo: partyId)
      .where('isPaid', isEqualTo: false)
      .orderBy('transactionDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs
          .map((doc) => Transaction.fromMap(doc.data()))
          .toList());
}

// Get transactions by date range
static Stream<List<Transaction>> getTransactionsByDateRange(
    DateTime startDate, DateTime endDate) {
  return _transactionsCollection
      .where('transactionDate',
          isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
      .where('transactionDate',
          isLessThanOrEqualTo: Timestamp.fromDate(endDate))
      .orderBy('transactionDate', descending: true)
      .snapshots()
      .map((snapshot) {
    return snapshot.docs.map((doc) {
      return Transaction.fromMap(doc.data() as Map<String, dynamic>);
    }).toList();
  });
}

// Delete Transaction
static Future<String> deleteTransaction(String id) async {
  try {
    await _transactionsCollection.doc(id).delete();
    return 'Transaction deleted successfully';
  } catch (e) {
    return 'Error deleting transaction: $e';
  }
}

// Update Transaction payment status
static Future<String> updateTransactionPaymentStatus(
    String id, bool isPaid, String? paymentMethod) async {
  try {
    await _transactionsCollection.doc(id).update({
      'isPaid': isPaid,
      'paymentMethod': paymentMethod,
    });
    return 'Payment status updated successfully';
  } catch (e) {
    return 'Error updating payment status: $e';
  }
}
}


