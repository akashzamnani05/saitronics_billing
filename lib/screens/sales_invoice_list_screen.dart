import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saitronics_billing/models/sales_invoice.dart';
import 'package:saitronics_billing/utils/sales_invoice_pdf_generator.dart';
import '../services/firebase_service.dart';
import 'create_sales_invoice_screen.dart';

class SalesInvoicesListScreen extends StatelessWidget {
  const SalesInvoicesListScreen({super.key});

  Future<void> _downloadPdf(
      BuildContext context, SalesInvoice invoice) async {
    try {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Get party details
      final party = await FirebaseService.getPartyById(invoice.partyId);

      // Close loading
      if (context.mounted) {
        Navigator.pop(context);
      }

      if (party == null) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Party details not found')),
          );
        }
        return;
      }

      // Generate and share PDF
      await SalesInvoicePdfGenerator.sharePdf(
        invoice,
        party,
        paidAmount: invoice.grandTotal,
        logoPath: 'assets/images/logo.jpg', // Adjust based on your payment tracking
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context); // Close loading if still open
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  // Add this method in SalesInvoicesListScreen class

Future<void> _deleteInvoice(BuildContext context, SalesInvoice invoice) async {
  // Show confirmation dialog
  final confirm = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Invoice'),
      content: Text(
        'Are you sure you want to delete invoice ${invoice.invoiceNumber}?\n\nThis will restore the inventory items and update party balance.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );

  if (confirm != true) return;

  try {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    // Get party document
    final partyDoc = await FirebaseFirestore.instance
        .collection('parties')
        .doc(invoice.partyId)
        .get();
    
    if (partyDoc.exists) {
      final partyData = partyDoc.data();
      
      if (partyData != null) {
        // Get current balance and transaction history
        double currentBalance = (partyData['balance'] ?? 0).toDouble();
        List<String> transactionHistory = List<String>.from(partyData['transactionHistory'] ?? []);
        
        // Remove transaction entry that matches this invoice number
        // Looking for pattern like: "+₹2000.00 - Invoice: P-0037"
        transactionHistory.removeWhere((entry) {
          return entry.contains('Invoice: ${invoice.invoiceNumber}');
        });
        
        // Subtract the invoice amount from balance
        double newBalance = currentBalance - invoice.grandTotal;
        
        // Update party document
        await FirebaseFirestore.instance
            .collection('parties')
            .doc(invoice.partyId)
            .update({
          'balance': newBalance,
          'transactionHistory': transactionHistory,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }

    // Restore inventory for each item
    for (var item in invoice.items) {
      final currentItem = await FirebaseService.getItemById(item.itemId);
      if (currentItem != null) {
        await FirebaseService.updateItemStock(
          item.itemId,
          currentItem.currentStock + item.quantity,
        );
      }
    }

    // Delete the invoice
    await FirebaseService.deleteSalesInvoice(invoice.id);

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice deleted, inventory restored, and party balance updated'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      Navigator.pop(context); // Close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error deleting invoice: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Invoices'),
        backgroundColor: Colors.purple,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<SalesInvoice>>(
        stream: FirebaseService.getSalesInvoices(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final invoices = snapshot.data ?? [];

          if (invoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  const Text(
                    'No sales invoices yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Create your first sales invoice',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return InkWell(
                onLongPress: () => _deleteInvoice(context, invoice),
                child: Card(
                  margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: ExpansionTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.purple,
                      child: Text(
                        invoice.partyName[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(
                      invoice.partyName,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice: ${invoice.invoiceNumber}'),
                        Text(
                          'Date: ${DateFormat('dd MMM yyyy').format(invoice.invoiceDate)}',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${invoice.grandTotal.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          '${invoice.items.length} items',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Download Button Placeholder (will be implemented later)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: () => _downloadPdf(context, invoice),
                                  icon: const Icon(Icons.download, size: 18),
                                  label: const Text('Download PDF'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.purple,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Items:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            ...invoice.items.map((item) {
                              return Padding(
                                padding: const EdgeInsets.symmetric(vertical: 4),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            item.itemName,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          Text(
                                            'HSN: ${item.hsnCode} | Qty: ${item.quantity.toStringAsFixed(0)} | GST: ${item.gstPercent}%',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      '₹${item.subtotal.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Taxable Amount:'),
                                Text('₹${invoice.subtotal.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('SGST @9%:'),
                                Text(
                                    '₹${(invoice.totalGst / 2).toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('CGST @9%:'),
                                Text(
                                    '₹${(invoice.totalGst / 2).toStringAsFixed(2)}'),
                              ],
                            ),
                            if(invoice.discount > 0)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Discount:'),
                                Text(
                                    '- ₹${(invoice.discount)}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  '₹${invoice.grandTotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.purple,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.purple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateSalesInvoiceScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}