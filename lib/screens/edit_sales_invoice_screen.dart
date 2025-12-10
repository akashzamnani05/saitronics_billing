import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saitronics_billing/models/invoice_item.dart';
import 'package:saitronics_billing/models/item.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/sales_invoice.dart';
import 'package:saitronics_billing/utils/sales_invoice_pdf_generator.dart';
import '../services/firebase_service.dart';

class EditSalesInvoiceScreen extends StatefulWidget {
  final SalesInvoice invoice;

  const EditSalesInvoiceScreen({super.key, required this.invoice});

  @override
  State<EditSalesInvoiceScreen> createState() => _EditSalesInvoiceScreenState();
}

class _EditSalesInvoiceScreenState extends State<EditSalesInvoiceScreen> {
  Party? _selectedParty;
  DateTime _invoiceDate = DateTime.now();
  final _invoiceNumberController = TextEditingController();
  final _salesPersonNameController = TextEditingController();
  final List<_InvoiceLineItem> _lineItems = [];
  bool _isLoading = false;
  double _discount = 0.0;

  @override
  void initState() {
    super.initState();
    _loadInvoiceData();
  }

  Future<void> _loadInvoiceData() async {
    // Load party
    final party = await FirebaseService.getPartyById(widget.invoice.partyId);
    
    setState(() {
      _selectedParty = party;
      _invoiceDate = widget.invoice.invoiceDate;
      _invoiceNumberController.text = widget.invoice.invoiceNumber;
      _salesPersonNameController.text = widget.invoice.salesPersonName;
      _discount = widget.invoice.discount;
      
      // Load items
      _lineItems.clear();
      for (var item in widget.invoice.items) {
        _lineItems.add(_InvoiceLineItem(
          itemId: item.itemId,
          itemName: item.itemName,
          hsnCode: item.hsnCode,
          quantity: item.quantity,
          price: item.price,
          gstPercent: item.gstPercent,
          description: item.description,
        ));
      }
    });
  }

  Future<void> _downloadPdf(SalesInvoice invoice) async {
    if (_selectedParty == null) return;

    try {
      await SalesInvoicePdfGenerator.previewPdf(
        invoice,
        _selectedParty!,
        paidAmount: invoice.grandTotal,
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
    _salesPersonNameController.dispose();
    super.dispose();
  }

  double get _subtotal {
    return _lineItems.fold(0, (sum, item) => sum + item.subtotal);
  }

  double get _totalGST {
    return _lineItems.fold(0, (sum, item) => sum + item.gstAmount);
  }

  double get _grandTotal {
    return _subtotal + _totalGST;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Sales Invoice'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.save_rounded),
            onPressed: _selectedParty != null && _lineItems.isNotEmpty
                ? _updateSalesInvoice
                : null,
            tooltip: 'Update Invoice',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Party Selection Section
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.purple[50]!, Colors.white],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Bill To',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
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
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.receipt_long, color: Colors.purple[700], size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Invoice Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _invoiceNumberController,
                          decoration: InputDecoration(
                            labelText: 'Invoice Number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            prefixIcon: const Icon(Icons.tag),
                          ),
                          readOnly: true, // Can't change invoice number
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: InkWell(
                          onTap: () => _selectDate(context),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Invoice Date',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.calendar_today),
                            ),
                            child: Text(
                              DateFormat('dd MMM yyyy').format(_invoiceDate),
                              style: const TextStyle(fontSize: 15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Salesperson Name Field
                  TextFormField(
                    controller: _salesPersonNameController,
                    decoration: InputDecoration(
                      labelText: 'Salesperson Name',
                      hintText: 'Enter salesperson name',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                    textCapitalization: TextCapitalization.words,
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1.5),

            // Items Section
            Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.purple[50],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.inventory_2, color: Colors.purple[700], size: 20),
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Items',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      ElevatedButton.icon(
                        onPressed: _selectedParty != null ? _showAddItemDialog : null,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Item'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.purple,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Items Table
                  if (_lineItems.isNotEmpty)
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white,
                      ),
                      child: Column(
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              headingRowColor: MaterialStateProperty.all(Colors.purple[50]),
                              headingRowHeight: 45,
                              dataRowHeight: 60,
                              columnSpacing: 20,
                              horizontalMargin: 16,
                              columns: const [
                                DataColumn(
                                  label: Text(
                                    'NO',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'ITEM NAME',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'HSN',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                DataColumn(
                                  label: Text(
                                    'QTY',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text(
                                    'RATE',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text(
                                    'GST %',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text(
                                    'AMOUNT',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                  numeric: true,
                                ),
                                DataColumn(
                                  label: Text(
                                    'ACTION',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                              ],
                              rows: _lineItems.asMap().entries.map((entry) {
                                final index = entry.key;
                                final item = entry.value;
                                return DataRow(
                                  cells: [
                                    DataCell(Text('${index + 1}')),
                                    DataCell(
                                      SizedBox(
                                        width: 180,
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.itemName,
                                              style: const TextStyle(fontWeight: FontWeight.w600),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                            if (item.description.isNotEmpty) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                item.description,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey[600],
                                                  fontStyle: FontStyle.italic,
                                                ),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 2,
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(item.hsnCode)),
                                    DataCell(Text(item.quantity.toStringAsFixed(0))),
                                    DataCell(Text('₹${item.price.toStringAsFixed(2)}')),
                                    DataCell(Text('${item.gstPercent.toStringAsFixed(0)}%')),
                                    DataCell(
                                      Text(
                                        '₹${item.total.toStringAsFixed(2)}',
                                        style: const TextStyle(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    DataCell(
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 22),
                                        onPressed: () {
                                          setState(() {
                                            _lineItems.removeAt(index);
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),

                  if (_lineItems.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(40),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          Text(
                            'No items added',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Click "Add Item" to add products',
                            style: TextStyle(color: Colors.grey[500], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

            // Totals Section
            if (_lineItems.isNotEmpty)
              Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 20,
                          decoration: BoxDecoration(
                            color: Colors.purple,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Payment Summary',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildTotalRow('Subtotal (Excl. GST)', _subtotal, false),
                    const SizedBox(height: 10),
                    _buildTotalRow('CGST @9%', _totalGST / 2, false),
                    const SizedBox(height: 6),
                    _buildTotalRow('SGST @9%', _totalGST / 2, false),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 1),
                    ),
                    Row(
                      children: [
                        const Expanded(
                          child: Text(
                            'Discount (₹)',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                        SizedBox(
                          width: 130,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '0.00',
                              prefixText: '₹ ',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            controller: TextEditingController(text: _discount.toString()),
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
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, thickness: 2),
                    ),
                    _buildTotalRow(
                      'Grand Total (Incl. GST)',
                      (_grandTotal - _discount).clamp(0, double.infinity),
                      true,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 80),
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
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _selectedParty != null && !_isLoading
                    ? _updateSalesInvoice
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle_outline),
                          const SizedBox(width: 8),
                          Text(
                            'Update Invoice - ₹${(_grandTotal - _discount).toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
              ),
            )
          : null,
    );
  }

  Widget _buildPartyDetails(Party party) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.purple[100]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.purple[400]!, Colors.purple[600]!],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    party.name[0].toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      party.phone,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  party.address,
                  style: TextStyle(color: Colors.grey[700], fontSize: 13),
                ),
              ),
            ],
          ),
          if (party.gstNumber.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.receipt, size: 16, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  'GST: ${party.gstNumber}',
                  style: TextStyle(color: Colors.grey[700], fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ],
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
            fontSize: isBold ? 17 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 19 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? Colors.purple : Colors.black87,
          ),
        ),
      ],
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
          
          // When editing, we need to consider currently selected items
          // and add back their quantity to available stock for display
          final availableItems = items.where((item) {
            // Find if this item is already in the invoice
            final existingItem = widget.invoice.items.firstWhere(
              (invItem) => invItem.itemId == item.id,
              orElse: () => InvoiceItem(
                itemId: '',
                itemName: '',
                hsnCode: '',
                quantity: 0,
                price: 0,
                gstPercent: 0,
                description: '',
              ),
            );
            
            // Add back the quantity that was originally in the invoice
            final effectiveStock = item.currentStock + existingItem.quantity;
            return effectiveStock > 0;
          }).toList();

          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Select Item', style: TextStyle(fontSize: 20)),
            content: SizedBox(
              width: double.maxFinite,
              child: availableItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.inventory_2_outlined, size: 60, color: Colors.grey[300]),
                          const SizedBox(height: 16),
                          const Text('No items with stock available'),
                        ],
                      ),
                    )
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: availableItems.length,
                      itemBuilder: (context, index) {
                        final item = availableItems[index];
                        
                        // Calculate effective stock for display
                        final existingItem = widget.invoice.items.firstWhere(
                          (invItem) => invItem.itemId == item.id,
                          orElse: () => InvoiceItem(
                            itemId: '',
                            itemName: '',
                            hsnCode: '',
                            quantity: 0,
                            price: 0,
                            gstPercent: 0,
                            description: '',
                          ),
                        );
                        final effectiveStock = item.currentStock + existingItem.quantity;
                        
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: Container(
                              width: 45,
                              height: 45,
                              decoration: BoxDecoration(
                                color: Colors.purple[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory, color: Colors.purple[700]),
                            ),
                            title: Text(
                              item.name,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Stock: ${effectiveStock.toStringAsFixed(0)}'),
                                Text(
                                  '₹${item.sellingPrice.toStringAsFixed(2)} | GST: ${item.gstPercent}%',
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                            onTap: () {
                              Navigator.pop(context);
                              _showQuantityDialog(item, effectiveStock);
                            },
                          ),
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

  void _showQuantityDialog(Item item, double effectiveStock) {
    final quantityController = TextEditingController(text: '1');
    final priceController = TextEditingController(text: item.sellingPrice.toString());
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.purple[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.inventory, color: Colors.purple[700], size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Add ${item.name}',
                style: const TextStyle(fontSize: 18),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green[700], size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Available Stock: ${effectiveStock.toStringAsFixed(0)}',
                      style: TextStyle(
                        color: Colors.green[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: quantityController,
                decoration: InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.production_quantity_limits),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: InputDecoration(
                  labelText: 'Selling Price',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  prefixIcon: const Icon(Icons.currency_rupee),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description (Optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  hintText: 'Add item details...',
                  prefixIcon: const Icon(Icons.description),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
              ),
            ],
          ),
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

              if (quantity <= 0 || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Please enter valid quantity and price')),
                );
                return;
              }

              if (quantity > effectiveStock) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Insufficient stock! Available: ${effectiveStock.toStringAsFixed(0)}'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              setState(() {
                _lineItems.add(_InvoiceLineItem(
                  itemId: item.id,
                  itemName: item.name,
                  hsnCode: item.hsnCode,
                  quantity: quantity,
                  price: price,
                  gstPercent: item.gstPercent,
                  description: descriptionController.text.trim(),
                ));
              });
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.purple,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text('Add Item'),
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

  Future<void> _updateSalesInvoice() async {
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

    try {
      final invoiceItems = _lineItems
          .map((item) => InvoiceItem(
                itemId: item.itemId,
                itemName: item.itemName,
                hsnCode: item.hsnCode,
                quantity: item.quantity,
                price: item.price,
                gstPercent: item.gstPercent,
                description: item.description,
              ))
          .toList();

      final updatedInvoice = SalesInvoice(
        id: widget.invoice.id,
        partyId: _selectedParty!.id,
        partyName: _selectedParty!.name,
        items: invoiceItems,
        invoiceDate: _invoiceDate,
        invoiceNumber: _invoiceNumberController.text,
        createdAt: widget.invoice.createdAt,
        discount: _discount,
        salesPersonName: _salesPersonNameController.text.trim(),
      );

      // Update invoice with inventory handling
      final result = await FirebaseService.updateSalesInvoice(
        updatedInvoice,
        widget.invoice,
      );

      // Update party balance
      final oldAmount = widget.invoice.grandTotal;
      final newAmount = updatedInvoice.grandTotal;
      final balanceDifference = newAmount - oldAmount;

      if (balanceDifference != 0) {
        // Get current party balance
        final partyDoc = await FirebaseFirestore.instance
            .collection('parties')
            .doc(_selectedParty!.id)
            .get();

        if (partyDoc.exists) {
          final partyData = partyDoc.data();
          if (partyData != null) {
            double currentBalance = (partyData['balance'] ?? 0).toDouble();
            List<String> transactionHistory =
                List<String>.from(partyData['transactionHistory'] ?? []);

            // Remove old transaction entry
            transactionHistory.removeWhere((entry) {
              return entry.contains('Invoice: ${widget.invoice.invoiceNumber}');
            });

            // Add new transaction entry
            final newBalance = currentBalance + balanceDifference;
            final historyEntry =
                '+₹${newAmount.abs().toStringAsFixed(2)} - Invoice: ${widget.invoice.invoiceNumber} (Updated)';
            transactionHistory.add(historyEntry);

            await FirebaseFirestore.instance
                .collection('parties')
                .doc(_selectedParty!.id)
                .update({
              'balance': newBalance,
              'transactionHistory': transactionHistory,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          }
        }
      }

      // Update transaction record
      final transactionQuery = await FirebaseFirestore.instance
          .collection('transactions')
          .where('invoiceId', isEqualTo: widget.invoice.id)
          .get();

      if (transactionQuery.docs.isNotEmpty) {
        final transactionDoc = transactionQuery.docs.first;
        await FirebaseService.updateTransaction(
          transactionDoc.id,
          newAmount,
          transactionDoc.data()['isPaid'] ?? false,
          transactionDoc.data()['paymentMethod'],
          _discount,
          _lineItems.length,
        );
      }

      setState(() {
        _isLoading = false;
      });

      if (mounted) {
        if (result.contains('successfully')) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.check_circle, color: Colors.green[700], size: 30),
                  ),
                  const SizedBox(width: 12),
                  const Text('Success!'),
                ],
              ),
              content: const Text(
                'Sales invoice updated successfully.',
                style: TextStyle(fontSize: 15),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  child: const Text('OK'),
                ),
                ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.pop(context);
                    await _downloadPdf(updatedInvoice);
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  },
                  icon: const Icon(Icons.picture_as_pdf),
                  label: const Text('Download PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result)),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating invoice: $e'),
            backgroundColor: Colors.red,
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
  final String description;

  _InvoiceLineItem({
    required this.itemId,
    required this.itemName,
    required this.hsnCode,
    required this.quantity,
    required this.price,
    required this.gstPercent,
    this.description = '',
  });

  double get total => quantity * price;
  double get subtotal => total / (1 + gstPercent / 100);
  double get gstAmount => total - subtotal;
  double get cgst => gstAmount / 2;
  double get sgst => gstAmount / 2;
}
