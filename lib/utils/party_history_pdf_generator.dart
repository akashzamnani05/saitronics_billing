import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../models/party.dart';
import '../models/transaction.dart';

class PdfGenerator {
  /// Generates a PDF that contains the transaction history of a party.
  /// Returns the PDF as `Uint8List`.
  static Future<Uint8List> createPartyHistoryPdf({
    required Party party,
    required List<Transaction> transactions,
    DateTimeRange? dateRange,
  }) async {
    final pdf = pw.Document();

    // --------------------------------------------------------------
    // Helper: format currency
    // --------------------------------------------------------------
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

    // --------------------------------------------------------------
    // Build the table rows
    // --------------------------------------------------------------
    final rows = <List<pw.Widget>>[
      // Header row
      [
        _cell('Invoice #', isHeader: true),
        _cell('Date', isHeader: true),
        _cell('Type', isHeader: true),
        _cell('Amount', isHeader: true),
        _cell('Status', isHeader: true),
      ],
    ];

    for (final txn in transactions) {
      rows.add([
        _cell(txn.invoiceNumber),
        _cell(DateFormat('dd MMM yyyy').format(txn.transactionDate)),
        _cell(txn.typeLabel),
        _cell(currencyFmt.format(txn.netAmount), align: pw.TextAlign.right),
        _cell(txn.isPaid ? 'Paid' : 'Unpaid',
            color: txn.isPaid ? PdfColors.green700 : PdfColors.red700),
      ]);
    }

    // --------------------------------------------------------------
    // Totals
    // --------------------------------------------------------------
    final total = transactions.fold<double>(0, (s, t) => s + t.netAmount);
    final paid = transactions.where((t) => t.isPaid).fold<double>(0, (s, t) => s + t.netAmount);
    final unpaid = total - paid;

    rows.add([
      _cell('TOTAL', isHeader: true),
      pw.Spacer(),
      pw.Spacer(),
      _cell(currencyFmt.format(total), align: pw.TextAlign.right, isHeader: true),
      pw.Spacer(),
    ]);
    rows.add([
      _cell('Paid', isHeader: true),
      pw.Spacer(),
      pw.Spacer(),
      _cell(currencyFmt.format(paid), align: pw.TextAlign.right, isHeader: true),
      pw.Spacer(),
    ]);
    rows.add([
      _cell('Unpaid', isHeader: true),
      pw.Spacer(),
      pw.Spacer(),
      _cell(currencyFmt.format(unpaid), align: pw.TextAlign.right, isHeader: true),
      pw.Spacer(),
    ]);

    // --------------------------------------------------------------
    // PDF page
    // --------------------------------------------------------------
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Title + date range
              pw.Text(
                '${party.name} – Transaction History',
                style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                dateRange == null
                    ? 'All time'
                    : '${DateFormat('dd MMM yyyy').format(dateRange.start)}  →  ${DateFormat('dd MMM yyyy').format(dateRange.end)}',
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
              pw.SizedBox(height: 20),

              // Table
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                defaultColumnWidth: const pw.FlexColumnWidth(),
                children: rows
                    .map((r) => pw.TableRow(
                          children: r
                              .map((c) => pw.Padding(
                                    padding: const pw.EdgeInsets.all(6),
                                    child: c,
                                  ))
                              .toList(),
                        ))
                    .toList(),
              ),

              pw.Spacer(),

              // Footer
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text(
                  'Generated on ${DateFormat('dd MMM yyyy, HH:mm').format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  // --------------------------------------------------------------
  // Helper: simple cell widget
  // --------------------------------------------------------------
  static pw.Widget _cell(
    String text, {
    bool isHeader = false,
    pw.TextAlign align = pw.TextAlign.left,
    PdfColor? color,
  }) {
    return pw.Text(
      text,
      style: pw.TextStyle(
        fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        fontSize: isHeader ? 11 : 10,
        color: color,
      ),
      textAlign: align,
    );
  }
}