import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/sales_invoice.dart';
import 'package:saitronics_billing/services/firebase_service.dart';
import 'package:saitronics_billing/utils/GST_sales_report_generator.dart';
// import 'package:saitronics_billing/utils/GST_sales_report_generator.dart';

class GSTSalesReport extends StatefulWidget {
  const GSTSalesReport({Key? key}) : super(key: key);

  @override
  State<GSTSalesReport> createState() => _GSTSalesReportState();
}

class _GSTSalesReportState extends State<GSTSalesReport> {
  DateFilterType _selectedFilter = DateFilterType.thisMonth;
  DateTime? _customStartDate;
  DateTime? _customEndDate;
  List<SalesInvoice> _filteredInvoices = [];

  // ✅ Cache to store fetched parties
  final Map<String, Party?> _partyCache = {};

  // ✅ Fetch a single party (with caching)
  Future<Party?> _fetchParty(String id) async {
    if (_partyCache.containsKey(id)) {
      return _partyCache[id];
    }

    try {
      final party = await FirebaseService.getPartyById(id);
      _partyCache[id] = party;
      return party;
    } catch (e) {
      print('Error fetching party: $e');
      _partyCache[id] = null;
      return null;
    }
  }

  // ✅ Preload all parties for filtered invoices
  Future<void> _preloadParties() async {
    final uniqueIds = _filteredInvoices.map((inv) => inv.partyId).toSet();
    await Future.wait(uniqueIds.map((id) => _fetchParty(id)));
  }

  Future<void> _exportReport(String format) async {
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );

      // Determine date range based on filter
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      
      DateTime startDate;
      DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

      switch (_selectedFilter) {
        case DateFilterType.today:
          startDate = today;
          break;
        case DateFilterType.thisWeek:
          final weekday = now.weekday;
          startDate = today.subtract(Duration(days: weekday - 1));
          break;
        case DateFilterType.lastWeek:
          final weekday = now.weekday;
          endDate = today.subtract(Duration(days: weekday));
          startDate = endDate.subtract(const Duration(days: 6));
          break;
        case DateFilterType.thisMonth:
          startDate = DateTime(now.year, now.month, 1);
          break;
        case DateFilterType.lastMonth:
          startDate = DateTime(now.year, now.month - 1, 1);
          endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
          break;
        case DateFilterType.custom:
          if (_customStartDate == null || _customEndDate == null) {
            Navigator.of(context).pop(); // Close loading dialog
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Please select both start and end dates'),
                backgroundColor: Colors.orange,
              ),
            );
            return;
          }
          startDate = _customStartDate!;
          endDate = DateTime(
            _customEndDate!.year,
            _customEndDate!.month,
            _customEndDate!.day,
            23,
            59,
            59,
          );
          break;
      }

      String? filePath;
      if (format == 'excel') {
        filePath = await SalesReportExcelExporter.exportToExcel(
          invoices: _filteredInvoices,
          partyCache: _partyCache,
          startDate: startDate,
          endDate: endDate,
        );
      } else if (format == 'pdf') {
        filePath = await SalesReportPdfGenerator.generatePdf(
          invoices: _filteredInvoices,
          partyCache: _partyCache,
          startDate: startDate,
          endDate: endDate,
        );
      }

      // Close loading dialog
      if (mounted) {
        Navigator.of(context).pop();
      }

      if (filePath != null) {
        // Show success message with file path
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Report exported successfully!\nSaved to: $filePath'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to export report. Please try again.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      // Close loading dialog if still open
      if (mounted) {
        Navigator.of(context).pop();
      }

      // Show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting report: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  Future<void> _showExportOptions() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Export Report'),
          content: const Text('Choose export format:'),
          actions: [
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _exportReport('excel');
              },
              icon: const Icon(Icons.table_chart),
              label: const Text('Excel'),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                _exportReport('pdf');
              },
              icon: const Icon(Icons.picture_as_pdf),
              label: const Text('PDF'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.file_download),
            onPressed: _showExportOptions,
            tooltip: 'Export Report',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterSection(),
          Expanded(
            child: StreamBuilder<List<SalesInvoice>>(
              stream: FirebaseService.getSalesInvoices(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('No sales invoices found'));
                }

                final allInvoices = snapshot.data!;
                _filteredInvoices = _filterInvoices(allInvoices);

                // ✅ Preload all parties before rendering
                return FutureBuilder(
                  future: _preloadParties(),
                  builder: (context, partySnapshot) {
                    if (partySnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    return Column(
                      children: [
                        _buildSummaryCard(),
                        Expanded(child: _buildReportTable()),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ✅ Filter section for date filters
  Widget _buildFilterSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[100],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Filter by Date',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFilterChip('Today', DateFilterType.today),
              _buildFilterChip('This Week', DateFilterType.thisWeek),
              _buildFilterChip('Last Week', DateFilterType.lastWeek),
              _buildFilterChip('This Month', DateFilterType.thisMonth),
              _buildFilterChip('Last Month', DateFilterType.lastMonth),
              _buildFilterChip('Custom', DateFilterType.custom),
            ],
          ),
          if (_selectedFilter == DateFilterType.custom)
            _buildCustomDatePicker(),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, DateFilterType type) {
    final isSelected = _selectedFilter == type;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedFilter = type;
          if (type != DateFilterType.custom) {
            _customStartDate = null;
            _customEndDate = null;
          }
        });
      },
      selectedColor: Theme.of(context).primaryColor,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black87,
      ),
    );
  }

  Widget _buildCustomDatePicker() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildDateButton(
              label: 'Start Date',
              date: _customStartDate,
              onTap: () => _selectDate(true),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildDateButton(
              label: 'End Date',
              date: _customEndDate,
              onTap: () => _selectDate(false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateButton({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: const Icon(Icons.calendar_today, size: 16),
      label: Text(
        date != null ? DateFormat('dd/MM/yyyy').format(date) : label,
      ),
    );
  }

  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          isStartDate ? (_customStartDate ?? DateTime.now()) : (_customEndDate ?? DateTime.now()),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _customStartDate = picked;
        } else {
          _customEndDate = picked;
        }
      });
    }
  }

  // ✅ Summary card
  Widget _buildSummaryCard() {
    final totalAmount = _filteredInvoices.fold<double>(
      0,
      (sum, invoice) => sum + invoice.grandTotal,
    );
    final totalInvoices = _filteredInvoices.length;
    final totalItems = _filteredInvoices.fold<int>(
      0,
      (sum, invoice) => sum + invoice.items.length,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryItem('Total Invoices', totalInvoices.toString(), Icons.receipt_long),
          _buildSummaryItem('Total Items', totalItems.toString(), Icons.shopping_cart),
          _buildSummaryItem(
              'Total Amount', '₹${totalAmount.toStringAsFixed(2)}', Icons.currency_rupee),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.green[700]),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }

  // ✅ Report table with party info - matching CSV columns exactly
  Widget _buildReportTable() {
    if (_filteredInvoices.isEmpty) {
      return const Center(child: Text('No invoices found for selected date range'));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.grey[300]),
          columns: const [
            DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Invoice No.', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Party GSTIN', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Party Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Item Name', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('HSN Code', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Quantity', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Price/Unit', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('SGST', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('CGST', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('IGST', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: _buildTableRows(),
        ),
      ),
    );
  }

  List<DataRow> _buildTableRows() {
    final List<DataRow> rows = [];

    for (var invoice in _filteredInvoices) {
      for (var item in invoice.items) {
        final party = _partyCache[invoice.partyId]; // ✅ Get party from cache
        rows.add(
          DataRow(
            cells: [
              DataCell(Text(DateFormat('dd/MM/yyyy').format(invoice.invoiceDate))),
              DataCell(Text(invoice.invoiceNumber)),
              DataCell(Text(party?.gstNumber ?? '')), // ✅ GSTIN fetched from cache
              DataCell(Text(party?.name ?? invoice.partyName)), // ✅ Party Name fetched from cache
              DataCell(Text(item.itemName)),
              DataCell(Text(item.hsnCode)),
              DataCell(Text("${item.quantity} PCS")),
              DataCell(Text(item.basePricePerUnit.toStringAsFixed(2))),
              DataCell(Text(_getSGST(item))),
              
              DataCell(Text(_getCGST(item))),
              DataCell(Text(_getIGST(item))),
              DataCell(Text(item.total.toStringAsFixed(2))),
            ],
          ),
        );
      }
    }

    return rows;
  }

  String _getSGST(item) => item.sgst > 0 ? item.sgst.toStringAsFixed(2) : '';
  
  String _getCGST(item) => item.cgst > 0 ? item.cgst.toStringAsFixed(2) : '';

  String _getIGST(item) =>  '';
  

  List<SalesInvoice> _filterInvoices(List<SalesInvoice> invoices) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime startDate;
    DateTime endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);

    switch (_selectedFilter) {
      case DateFilterType.today:
        startDate = today;
        break;
      case DateFilterType.thisWeek:
        final weekday = now.weekday;
        startDate = today.subtract(Duration(days: weekday - 1));
        break;
      case DateFilterType.lastWeek:
        final weekday = now.weekday;
        endDate = today.subtract(Duration(days: weekday));
        startDate = endDate.subtract(const Duration(days: 6));
        break;
      case DateFilterType.thisMonth:
        startDate = DateTime(now.year, now.month, 1);
        break;
      case DateFilterType.lastMonth:
        startDate = DateTime(now.year, now.month - 1, 1);
        endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        break;
      case DateFilterType.custom:
        if (_customStartDate == null || _customEndDate == null) {
          return invoices;
        }
        startDate = _customStartDate!;
        endDate = DateTime(
          _customEndDate!.year,
          _customEndDate!.month,
          _customEndDate!.day,
          23,
          59,
          59,
        );
        break;
    }

    return invoices.where((invoice) {
      return invoice.invoiceDate.isAfter(startDate.subtract(const Duration(seconds: 1))) &&
          invoice.invoiceDate.isBefore(endDate.add(const Duration(seconds: 1)));
    }).toList();
  }
}

enum DateFilterType { today, thisWeek, lastWeek, thisMonth, lastMonth, custom }