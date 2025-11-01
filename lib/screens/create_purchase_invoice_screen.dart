import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saitronics_billing/models/invoice_item.dart';
import 'package:saitronics_billing/models/item.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/purchase_invoice.dart';
import 'package:saitronics_billing/utils/purchase_invoice_pdf_generator.dart';
import 'package:uuid/uuid.dart';

import '../services/firebase_service.dart';

class CreatePurchaseInvoiceScreen extends StatefulWidget {
  const CreatePurchaseInvoiceScreen({super.key});

  @override
  State<CreatePurchaseInvoiceScreen> createState() =>
      _CreatePurchaseInvoiceScreenState();
}

class _CreatePurchaseInvoiceScreenState
    extends State<CreatePurchaseInvoiceScreen> {
  Party? _selectedParty;
  DateTime _invoiceDate = DateTime.now();
  final _invoiceNumberController = TextEditingController();
  final List<_InvoiceLineItem> _lineItems = [];
  bool _isLoading = false;
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _generateInvoiceNumber();
  }

  void _generateInvoiceNumber() async {
  setState(() => _invoiceNumberController.text = 'Loading...');
  final invoiceNumber = await FirebaseService.generatePurchaseInvoiceNumber();
  setState(() {
    _invoiceNumberController.text = invoiceNumber;
  });
}

Future<void> _downloadPdf(PurchaseInvoice invoice) async {
    if (_selectedParty == null) return;

    try {
      await PurchaseInvoicePdfGenerator.sharePdf(
        invoice,
        _selectedParty!,
        paidAmount: invoice.total,
        logoPath: 'assets/images/logo.jpg', 
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _invoiceNumberController.dispose();
    super.dispose();
  }

  double get _subtotal => _lineItems.fold(0, (sum, item) => sum + item.subtotal);
  double get _totalGST => _lineItems.fold(0, (sum, item) => sum + item.gstAmount);
  double get _grandTotal => _lineItems.fold(0, (sum, item) => sum + item.total);

  

  @override
  Widget build(BuildContext context) {
    
    final totalCgst = _lineItems.fold(0.0, (sum, item) => sum + item.cgst);
    final totalSgst = _lineItems.fold(0.0, (sum, item) => sum + item.sgst);

    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Purchase Invoice'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _selectedParty != null && _lineItems.isNotEmpty
                ? _savePurchaseInvoice
                : null,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Party Selection Section
            Container(
              color: Colors.grey[100],
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Bill From',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _showPartySelectionDialog,
                        child: Text(_selectedParty == null
                            ? 'Select Party'
                            : 'Change Party'),
                      ),
                    ],
                  ),
                  if (_selectedParty != null) ...[
                    const SizedBox(height: 16),
                    _buildPartyDetails(_selectedParty!),
                  ],
                ],
              ),
            ),

            // Invoice Details
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _invoiceNumberController,
                      decoration: const InputDecoration(
                        labelText: 'Invoice Number',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context),
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Invoice Date',
                          border: OutlineInputBorder(),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('dd MMM yyyy').format(_invoiceDate)),
                            const Icon(Icons.calendar_today, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Items Section Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Items',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton.icon(
                    onPressed: _selectedParty != null ? _showAddItemDialog : null,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Item'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),

            // Items Table Header
            if (_lineItems.isNotEmpty)
              Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const SizedBox(width: 40, child: Text('NO')),
                    const Expanded(flex: 3, child: Text('ITEMS')),
                    const SizedBox(width: 80, child: Text('HSN')),
                    const SizedBox(width: 60, child: Text('QTY')),
                    const SizedBox(width: 80, child: Text('RATE')),
                    const SizedBox(width: 60, child: Text('GST')),
                    const SizedBox(width: 100, child: Text('AMOUNT', textAlign: TextAlign.right)),
                    const SizedBox(width: 40),
                  ],
                ),
              ),

            // Items List
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _lineItems.length,
              itemBuilder: (context, index) {
                return _buildItemRow(index);
              },
            ),

            if (_lineItems.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                alignment: Alignment.center,
                child: Column(
                  children: [
                    Icon(Icons.inventory_2, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No items added',
                      style: TextStyle(color: Colors.grey[600], fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Click "Add Item" to add products',
                      style: TextStyle(color: Colors.grey[500]),
                    ),
                  ],
                ),
              ),

            const Divider(height: 1, thickness: 2),

            if (_lineItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTotalRow('Subtotal (Excl. GST)', _subtotal, false),
                  const SizedBox(height: 8),
                  _buildTotalRow('CGST', totalCgst, false),
                  const SizedBox(height: 4),
                  _buildTotalRow('SGST', totalSgst, false),
                  const Divider(),

                  // 👇 Add discount input field
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Discount (₹)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        width: 120,
                        child: TextField(
                          decoration: const InputDecoration(
                            hintText: '0.00',
                            contentPadding: EdgeInsets.symmetric(horizontal: 8),
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (val) {
                            setState(() {
                              _discount = double.tryParse(val) ?? 0;
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                  const Divider(),

                  _buildTotalRow(
                    'Grand Total (Incl. GST)',
                    (_grandTotal - _discount).clamp(0, double.infinity),
                    true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _lineItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.3),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _selectedParty != null && !_isLoading
                    ? _savePurchaseInvoice
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.all(16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Save Purchase Invoice - ₹${_grandTotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16),
                      ),
              ),
            )
          : null,
    );
  }

  Widget _buildPartyDetails(Party party) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              party.name,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(party.address, style: TextStyle(color: Colors.grey[700])),
            const SizedBox(height: 4),
            Row(
              children: [
                Text('Phone: ${party.phone}',
                    style: TextStyle(color: Colors.grey[700])),
                if (party.gstNumber.isNotEmpty) ...[
                  const SizedBox(width: 16),
                  Text('GST: ${party.gstNumber}',
                      style: TextStyle(color: Colors.grey[700])),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _lineItems[index];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: [
          SizedBox(width: 40, child: Text('${index + 1}')),
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(width: 80, child: Text(item.hsnCode)),
          SizedBox(
            width: 60,
            child: Text('${item.quantity.toStringAsFixed(0)}'),
          ),
          SizedBox(
            width: 80,
            child: Text('₹${item.subtotal.toStringAsFixed(2)}'),
          ),
          SizedBox(
            width: 60,
            child: Text('${item.gstPercent.toStringAsFixed(0)}%'),
          ),
          SizedBox(
            width: 100,
            child: Text(
              '₹${item.total.toStringAsFixed(2)}',
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          SizedBox(
            width: 40,
            child: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
              onPressed: () {
                setState(() {
                  _lineItems.removeAt(index);
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  void _showPartySelectionDialog() {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Party>>(
        stream: FirebaseService.getParties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final parties = snapshot.data ?? [];

          return AlertDialog(
            title: const Text('Select Party'),
            content: SizedBox(
              width: double.maxFinite,
              child: parties.isEmpty
                  ? const Center(child: Text('No parties found'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: parties.length,
                      itemBuilder: (context, index) {
                        final party = parties[index];
                        return ListTile(
                          title: Text(party.name),
                          subtitle: Text(party.phone),
                          onTap: () {
                            setState(() {
                              _selectedParty = party;
                            });
                            Navigator.pop(context);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showAddItemDialog() {
    showDialog(
      context: context,
      builder: (context) => StreamBuilder<List<Item>>(
        stream: FirebaseService.getItems(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = snapshot.data ?? [];

          return AlertDialog(
            title: const Text('Select Item'),
            content: SizedBox(
              width: double.maxFinite,
              child: items.isEmpty
                  ? const Center(child: Text('No items found'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(
                            'Stock: ${item.currentStock.toStringAsFixed(0)} | ₹${item.purchasePrice.toStringAsFixed(2)}',
                          ),
                          trailing: Text('${item.gstPercent}%'),
                          onTap: () {
                            Navigator.pop(context);
                            _showQuantityDialog(item);
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showQuantityDialog(Item item) {
    final quantityController = TextEditingController(text: '1');
    final priceController =
        TextEditingController(text: item.purchasePrice.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add ${item.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Purchase Price',
                border: OutlineInputBorder(),
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final quantity = double.tryParse(quantityController.text) ?? 0;
              final price = double.tryParse(priceController.text) ?? 0;

              if (quantity > 0 && price > 0) {
                setState(() {
                  _lineItems.add(_InvoiceLineItem(
                    itemId: item.id,
                    itemName: item.name,
                    hsnCode: item.hsnCode,
                    quantity: quantity,
                    price: price,
                    gstPercent: item.gstPercent,
                  ));
                });
                Navigator.pop(context);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter valid quantity and price')),
                );
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _invoiceDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null && picked != _invoiceDate) {
      setState(() {
        _invoiceDate = picked;
      });
    }
  }

  Future<void> _savePurchaseInvoice() async {
    if (_selectedParty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a party')),
      );
      return;
    }

    if (_lineItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one item')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final invoiceItems = _lineItems
        .map((item) => InvoiceItem(
              itemId: item.itemId,
              itemName: item.itemName,
              hsnCode: item.hsnCode,
              quantity: item.quantity,
              price: item.price,
              gstPercent: item.gstPercent,
            ))
        .toList();

    final invoice = PurchaseInvoice(
      id: const Uuid().v4(),
      partyId: _selectedParty!.id,
      partyName: _selectedParty!.name,
      items: invoiceItems,
      invoiceDate: _invoiceDate,
      invoiceNumber: _invoiceNumberController.text,
      createdAt: DateTime.now(),
      discount: _discount,
    );

    final result = await FirebaseService.createPurchaseInvoice(invoice);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );

      if (result.contains('successfully')) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Success!'),
            content: const Text(
                'Purchase invoice created and inventory updated successfully.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to previous screen
                },
                child: const Text('OK'),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  Navigator.pop(context); // Close dialog
                  await _downloadPdf(invoice);
                  if (mounted) {
                    Navigator.pop(context); // Go back to previous screen
                  }
                },
                icon: const Icon(Icons.download),
                label: const Text('Download PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        );
      }
    }
  }
}

class _InvoiceLineItem {
  final String itemId;
  final String itemName;
  final String hsnCode;
  final double quantity;
  final double price;
  final double gstPercent;

  _InvoiceLineItem({
    required this.itemId,
    required this.itemName,
    required this.hsnCode,
    required this.quantity,
    required this.price,
    required this.gstPercent,
  });

  /// GST-inclusive subtotal (total value with GST)
  double get total => quantity * price;

  /// Base amount excluding GST
  double get subtotal => total / (1 + gstPercent / 100);

  /// Total GST extracted from price
  double get gstAmount => total - subtotal;

  /// CGST = 50% of total GST
  double get cgst => gstAmount / 2;

  /// SGST = 50% of total GST
  double get sgst => gstAmount / 2;
}