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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final party = await FirebaseService.getPartyById(invoice.partyId);

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

      await SalesInvoicePdfGenerator.previewPdf(
        invoice,
        party,
        paidAmount: invoice.grandTotal,
        logoPath: 'assets/images/logo.jpg',
      );
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error generating PDF: $e')),
        );
      }
    }
  }

  Future<void> _deleteInvoice(BuildContext context, SalesInvoice invoice) async {
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
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      final partyDoc = await FirebaseFirestore.instance
          .collection('parties')
          .doc(invoice.partyId)
          .get();
      
      if (partyDoc.exists) {
        final partyData = partyDoc.data();
        
        if (partyData != null) {
          double currentBalance = (partyData['balance'] ?? 0).toDouble();
          List<String> transactionHistory = List<String>.from(partyData['transactionHistory'] ?? []);
          
          transactionHistory.removeWhere((entry) {
            return entry.contains('Invoice: ${invoice.invoiceNumber}');
          });
          
          double newBalance = currentBalance - invoice.grandTotal;
          
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

      for (var item in invoice.items) {
        final currentItem = await FirebaseService.getItemById(item.itemId);
        if (currentItem != null) {
          await FirebaseService.updateItemStock(
            item.itemId,
            currentItem.currentStock + item.quantity,
          );
        }
      }

      await FirebaseService.deleteSalesInvoice(invoice.id);

      if (context.mounted) {
        Navigator.pop(context);
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
        Navigator.pop(context);
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
        elevation: 0,
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
                  Icon(Icons.receipt_long, size: 80, color: Colors.grey[300]),
                  const SizedBox(height: 24),
                  const Text(
                    'No sales invoices yet',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your first sales invoice',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: invoices.length,
            itemBuilder: (context, index) {
              final invoice = invoices[index];
              return InkWell(
                onLongPress: () => _deleteInvoice(context, invoice),
                child: Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Theme(
                    data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      childrenPadding: const EdgeInsets.all(0),
                      leading: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.purple[400]!, Colors.purple[600]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Center(
                          child: Text(
                            invoice.partyName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        invoice.partyName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Padding(
                        padding: const EdgeInsets.only(top: 6),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.purple[50],
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    invoice.invoiceNumber,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.purple[700],
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.calendar_today, size: 12, color: Colors.grey[600]),
                                const SizedBox(width: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(invoice.invoiceDate),
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      trailing: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₹${invoice.grandTotal.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              '${invoice.items.length} items',
                              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w500),
                            ),
                          ),
                        ],
                      ),
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[50],
                            borderRadius: const BorderRadius.only(
                              bottomLeft: Radius.circular(12),
                              bottomRight: Radius.circular(12),
                            ),
                          ),
                          child: Column(
                            children: [
                              const Divider(height: 1),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Download Button
                                    Container(
                                      width: double.infinity,
                                      child: ElevatedButton.icon(
                                        onPressed: () => _downloadPdf(context, invoice),
                                        icon: const Icon(Icons.picture_as_pdf, size: 20),
                                        label: const Text('Download PDF', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 20),
                                    
                                    // Items Section Header
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
                                          'Invoice Items',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    
                                    // Horizontally Scrollable Items Table
                                    Container(
                                      decoration: BoxDecoration(
                                        border: Border.all(color: Colors.grey[300]!),
                                        borderRadius: BorderRadius.circular(8),
                                        color: Colors.white,
                                      ),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: DataTable(
                                          headingRowColor: MaterialStateProperty.all(Colors.purple[50]),
                                          headingRowHeight: 40,
                                          dataRowHeight: 55,
                                          columnSpacing: 20,
                                          horizontalMargin: 12,
                                          columns: const [
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
                                          ],
                                          rows: invoice.items.map((item) {
                                            return DataRow(
                                              cells: [
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
                                                DataCell(Text('${item.gstPercent}%')),
                                                DataCell(
                                                  Text(
                                                    '₹${item.subtotal.toStringAsFixed(2)}',
                                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                                  ),
                                                ),
                                              ],
                                            );
                                          }).toList(),
                                        ),
                                      ),
                                    ),
                                    
                                    const SizedBox(height: 20),
                                    
                                    // Summary Section
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: Colors.grey[300]!),
                                      ),
                                      child: Column(
                                        children: [
                                          _buildSummaryRow('Taxable Amount', '₹${invoice.subtotal.toStringAsFixed(2)}'),
                                          const SizedBox(height: 8),
                                          _buildSummaryRow('SGST @9%', '₹${(invoice.totalGst / 2).toStringAsFixed(2)}'),
                                          const SizedBox(height: 8),
                                          _buildSummaryRow('CGST @9%', '₹${(invoice.totalGst / 2).toStringAsFixed(2)}'),
                                          if (invoice.discount > 0) ...[
                                            const SizedBox(height: 8),
                                            _buildSummaryRow('Discount', '- ₹${invoice.discount.toStringAsFixed(2)}', color: Colors.red),
                                          ],
                                          const Padding(
                                            padding: EdgeInsets.symmetric(vertical: 12),
                                            child: Divider(height: 1, thickness: 1.5),
                                          ),
                                          Row(
                                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                            children: [
                                              const Text(
                                                'Total Amount',
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 17,
                                                ),
                                              ),
                                              Text(
                                                '₹${invoice.grandTotal.toStringAsFixed(2)}',
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 20,
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
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.purple,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateSalesInvoiceScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('New Invoice'),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14),
        ),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
            color: color,
          ),
        ),
      ],
    );
  }
}