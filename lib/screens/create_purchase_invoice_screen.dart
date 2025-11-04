import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saitronics_billing/models/invoice_item.dart';
import 'package:saitronics_billing/models/item.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/purchase_invoice.dart';
import 'package:saitronics_billing/models/transaction.dart';
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
  final _partySearchController = TextEditingController();
  bool _isMarkedAsPaid = false;

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
      await PurchaseInvoicePdfGenerator.previewPdf(
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
    _partySearchController.dispose();
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
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Create Purchase Invoice'),
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_selectedParty != null && _lineItems.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: const Icon(Icons.save_rounded, size: 28),
                onPressed: _savePurchaseInvoice,
                tooltip: 'Save Invoice',
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Party Selection Section
            Container(
              margin: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.business, color: Colors.orange[700], size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Bill From',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _showPartySelectionDialog,
                          icon: Icon(_selectedParty == null ? Icons.add : Icons.edit, size: 18),
                          label: Text(_selectedParty == null ? 'Select Party' : 'Change'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_selectedParty != null) ...[
                    const Divider(height: 1),
                    _buildPartyDetails(_selectedParty!),
                  ],
                ],
              ),
            ),

            // Invoice Details Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Number',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _invoiceNumberController,
                          decoration: InputDecoration(
                            hintText: 'Enter invoice number',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invoice Date',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => _selectDate(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[400]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('dd MMM yyyy').format(_invoiceDate)),
                                Icon(Icons.calendar_today, size: 18, color: Colors.orange[700]),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Items Section
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
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
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.orange[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.inventory_2, color: Colors.orange[700], size: 20),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Invoice Items',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            if (_lineItems.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.orange[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_lineItems.length}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.orange[900],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        ElevatedButton.icon(
                          onPressed: _selectedParty != null ? _showAddItemDialog : null,
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Add Item'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  if (_lineItems.isNotEmpty) ...[
                    const Divider(height: 1),
                    // Horizontally Scrollable Items Table
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        child: DataTable(
                          headingRowColor: MaterialStateProperty.all(Colors.orange[50]),
                          headingRowHeight: 40,
                          dataRowHeight: 60,
                          columnSpacing: 20,
                          horizontalMargin: 0,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          columns: const [
                            DataColumn(
                              label: Text(
                                'No.',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Item Name',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'HSN Code',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                            DataColumn(
                              label: Text(
                                'Quantity',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Price',
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
                                'Amount',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                              numeric: true,
                            ),
                            DataColumn(
                              label: Text(
                                'Action',
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
                                    width: 150,
                                    child: Text(
                                      item.itemName,
                                      style: const TextStyle(fontWeight: FontWeight.w500),
                                      overflow: TextOverflow.ellipsis,
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
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
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
                    ),
                  ],

                  if (_lineItems.isEmpty)
                    Padding(
                      padding: const EdgeInsets.all(48),
                      child: Center(
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
                            const SizedBox(height: 16),
                            Text(
                              'No items added yet',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Click "Add Item" to add products to the invoice',
                              style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Summary Section
            if (_lineItems.isNotEmpty)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
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
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.orange[50],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(Icons.receipt_long, color: Colors.orange[700], size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Invoice Summary',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildSummaryRow('Subtotal (Excl. GST)', _subtotal, false),
                    const SizedBox(height: 8),
                    _buildSummaryRow('CGST @9%', totalCgst, false),
                    const SizedBox(height: 8),
                    _buildSummaryRow('SGST @9%', totalSgst, false),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Discount (₹)',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                        ),
                        SizedBox(
                          width: 120,
                          child: TextField(
                            decoration: InputDecoration(
                              hintText: '0.00',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                              prefixText: '₹ ',
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
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: CheckboxListTile(
                        title: const Text(
                          'Mark as Paid',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        subtitle: Text(
                          'Invoice will be marked as paid immediately',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        value: _isMarkedAsPaid,
                        onChanged: (value) {
                          setState(() {
                            _isMarkedAsPaid = value ?? false;
                          });
                        },
                        activeColor: Colors.orange,
                      ),
                    ),
                    const Divider(height: 24, thickness: 2),
                    _buildSummaryRow(
                      'Grand Total (Incl. GST)',
                      (_grandTotal - _discount).clamp(0, double.infinity),
                      true,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 100),
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
                    color: Colors.grey.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _selectedParty != null && !_isLoading
                      ? _savePurchaseInvoice
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                            const Icon(Icons.save_rounded, size: 22),
                            const SizedBox(width: 12),
                            Text(
                              'Save Invoice - ₹${((_grandTotal - _discount).clamp(0, double.infinity)).toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildPartyDetails(Party party) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.orange[400]!, Colors.orange[600]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
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
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      party.phone,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
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
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 18 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            color: isBold ? Colors.black : Colors.grey[700],
          ),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: isBold ? 20 : 15,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: isBold ? Colors.orange : Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showPartySelectionDialog() {
    _partySearchController.clear();
    final FocusNode searchFocusNode = FocusNode();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    FirebaseService.getParties().first.then((parties) {
      Navigator.pop(context);

      List<Party> filteredParties = List.from(parties);

      showDialog(
        context: context,
        builder: (context) => StatefulBuilder(
          builder: (context, setDialogState) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              searchFocusNode.requestFocus();
            });

            return AlertDialog(
              title: const Text('Select Party'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: TextField(
                        controller: _partySearchController,
                        focusNode: searchFocusNode,
                        autofocus: true,
                        decoration: const InputDecoration(
                          hintText: 'Search name, phone, GST...',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onChanged: (value) {
                          final lower = value.toLowerCase();
                          setDialogState(() {
                            filteredParties = parties.where((p) {
                              return p.name.toLowerCase().contains(lower) ||
                                  p.phone.contains(value) ||
                                  p.gstNumber.toLowerCase().contains(lower);
                            }).toList();
                          });
                        },
                      ),
                    ),
                    parties.isEmpty
                        ? const Center(child: Text('No parties found'))
                        : filteredParties.isEmpty
                            ? const Center(child: Text('No matching parties'))
                            : Flexible(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: filteredParties.length,
                                  itemBuilder: (context, index) {
                                    final party = filteredParties[index];
                                    return ListTile(
                                      title: Text(party.name),
                                      subtitle: Text(party.phone),
                                      trailing: party.gstNumber.isNotEmpty
                                          ? Text(party.gstNumber,
                                              style: TextStyle(
                                                  fontSize: 10,
                                                  color: Colors.grey[600]))
                                          : null,
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
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    _partySearchController.clear();
                    Navigator.pop(context);
                  },
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        ),
      ).then((_) {
        searchFocusNode.dispose();
      });
    }).catchError((e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading parties: $e')),
      );
    });
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

    final invoiceId = const Uuid().v4();
    final invoice = PurchaseInvoice(
      id: invoiceId,
      partyId: _selectedParty!.id,
      partyName: _selectedParty!.name,
      items: invoiceItems,
      invoiceDate: _invoiceDate,
      invoiceNumber: _invoiceNumberController.text,
      createdAt: DateTime.now(),
      discount: _discount,
    );

    final result = await FirebaseService.createPurchaseInvoice(invoice);

    if (!_isMarkedAsPaid) {
      final finalAmount = (_grandTotal - _discount).clamp(0, double.infinity);
      await FirebaseService.updatePartyBalance(
        _selectedParty!.id,
        -finalAmount.toDouble(),
        _invoiceNumberController.text,
        isCredit: false,
      );
    }

    final transaction = Transaction(
      id: const Uuid().v4(),
      invoiceId: invoiceId,
      invoiceNumber: _invoiceNumberController.text,
      type: TransactionType.purchase,
      partyId: _selectedParty!.id,
      partyName: _selectedParty!.name,
      amount: _grandTotal,
      subtotal: _subtotal,
      gstAmount: _totalGST,
      discount: _discount,
      itemCount: _lineItems.length,
      transactionDate: _invoiceDate,
      createdAt: DateTime.now(),
      isPaid: _isMarkedAsPaid,
      paymentMethod: _isMarkedAsPaid ? 'Cash' : null,
    );

    await FirebaseService.createTransaction(transaction);

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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.check_circle, color: Colors.green[700], size: 24),
                ),
                const SizedBox(width: 12),
                const Text('Success!'),
              ],
            ),
            content: const Text(
                'Purchase invoice created and inventory updated successfully.'),
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
                  await _downloadPdf(invoice);
                  if (mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: const Icon(Icons.picture_as_pdf),
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

  double get total => quantity * price;
  double get subtotal => total / (1 + gstPercent / 100);
  double get gstAmount => total - subtotal;
  double get cgst => gstAmount / 2;
  double get sgst => gstAmount / 2;
}