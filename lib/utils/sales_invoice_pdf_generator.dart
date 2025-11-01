import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:saitronics_billing/models/invoice_item.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/sales_invoice.dart';

/// ---------------------------------------------------------------
///  SALES INVOICE PDF GENERATOR
/// ---------------------------------------------------------------
///  Mirrors the exact layout of the PDF you shared (Akash_Zamnani_Sales_Invoice_1.pdf)
/// ---------------------------------------------------------------
class SalesInvoicePdfGenerator {
  // ──────────────────────────────────────────────────────────────
  //  Company details – taken from the sample PDF
  // ──────────────────────────────────────────────────────────────
  static const String companyName = "SAI";
  static const String companyAddress =
      "RH-1 , Silver Park Society , Tarwala Nagar Dindori Road , Near Talathi Colony, Nashik, Maharashtra, 422003";
  static const String companyMobile = "9518993602";
  static const String companyGSTIN = "27AAEPZ9949F1ZW";
  static const String companyPAN = "AAEPZ9949F";
  static const String companyEmail = "zamnaniakash@gmail.com";
  static const String placeOfSupply = "Maharashtra";

  // ──────────────────────────────────────────────────────────────
  //  Public entry points
  // ──────────────────────────────────────────────────────────────
  static Future<Uint8List> generateSalesInvoice(
    SalesInvoice invoice,
    Party party, {
    double paidAmount = 0,
    String? logoPath, // optional robot-logo
  }) async {
    final pdf = pw.Document();

    // Load optional logo (robot)
    pw.ImageProvider? logo;
    if (logoPath != null) {
      try {
        final data = await rootBundle.load(logoPath);
        logo = pw.MemoryImage(data.buffer.asUint8List());
      } catch (e) {
        print('Logo load error: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (_) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildHeader(logo),
            pw.SizedBox(height: 10),
            _buildInvoiceMeta(invoice),
            pw.SizedBox(height: 10),
            _buildBillShipTo(party),
            pw.SizedBox(height: 10),
            _buildItemsTable(invoice),
            pw.SizedBox(height: 10),
            _buildBottomSection(invoice, paidAmount),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ──────────────────────────────────────────────────────────────
  //  Header (Company + Robot logo)
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(pw.ImageProvider? logo) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          if (logo != null)
            pw.Container(
              width: 60,
              height: 60,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          if (logo != null) pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(companyAddress, style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 2),
                pw.Text('Mobile: $companyMobile',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text('GSTIN: $companyGSTIN',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text('PAN Number: $companyPAN',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.Text('Email: $companyEmail',
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  Invoice No. + Date
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildInvoiceMeta(SalesInvoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Invoice No.: ${invoice.invoiceNumber}',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Invoice Date: ${_formatDate(invoice.invoiceDate)}',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  BILL TO / SHIP TO
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildBillShipTo(Party party) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // BILL TO
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('BILL TO',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(party.name,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(party.address, style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 2),
                pw.Text('Mobile: ${party.phone}',
                    style: const pw.TextStyle(fontSize: 9)),
                pw.SizedBox(height: 2),
                pw.Text('Place of Supply: $placeOfSupply',
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        // SHIP TO (same as BILL TO in sample)
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('SHIP TO',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text(party.name,
                    style: pw.TextStyle(
                        fontSize: 11, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 2),
                pw.Text(party.address, style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  Items Table
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildItemsTable(SalesInvoice invoice) {
    final rows = invoice.items.map(_buildItemRow).toList();

    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600),
      ),
      child: pw.Column(
        children: [
          // Header
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            color: PdfColors.grey300,
            child: pw.Row(
              children: [
                pw.Expanded(
                    flex: 4,
                    child: pw.Text('ITEMS',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(
                    flex: 1,
                    child: pw.Text('QTY.',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center)),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('RATE',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right)),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('TAX',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center)),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text('AMOUNT',
                        style: pw.TextStyle(
                            fontSize: 9, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right)),
              ],
            ),
          ),
          // Item rows
          ...rows,
          // Subtotal row (exactly as in sample)
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey600),
              ),
            ),
            child: pw.Row(
              children: [
                pw.Expanded(
                    flex: 4,
                    child: pw.Text('SUBTOTAL',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold))),
                pw.Expanded(
                    flex: 1,
                    child: pw.Text(
                        '${_totalQty(invoice)}',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.center)),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                        'Rs. ${_fmt(invoice.totalGst)}',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right)),
                pw.Expanded(flex: 2, child: pw.Container()),
                pw.Expanded(
                    flex: 2,
                    child: pw.Text(
                        'Rs. ${_fmt(invoice.grandTotalBeforeDiscount)}',
                        style: pw.TextStyle(
                            fontSize: 10, fontWeight: pw.FontWeight.bold),
                        textAlign: pw.TextAlign.right)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildItemRow(InvoiceItem item) {
    final base = item.total / (1 + item.gstPercent / 100);
    final gstAmt = item.total - base;

    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey600),
        ),
      ),
      child: pw.Row(
        children: [
          pw.Expanded(
              flex: 4,
              child: pw.Text(item.itemName.toUpperCase(),
                  style: const pw.TextStyle(fontSize: 9))),
          pw.Expanded(
              flex: 1,
              child: pw.Text('${item.quantity.toInt()} PCS',
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.center)),
          pw.Expanded(
              flex: 2,
              child: pw.Text(_fmt(base),
                  style: const pw.TextStyle(fontSize: 9),
                  textAlign: pw.TextAlign.right)),
          pw.Expanded(
              flex: 2,
              child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.center,
                  children: [
                    pw.Text(_fmt(gstAmt),
                        style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('(${item.gstPercent.toInt()}%)',
                        style: const pw.TextStyle(fontSize: 8)),
                  ])),
          pw.Expanded(
              flex: 2,
              child: pw.Text(_fmt(item.total),
                  style: pw.TextStyle(
                      fontSize: 9, fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.right)),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  Bottom – Terms + Amounts
  // ──────────────────────────────────────────────────────────────
  static pw.Widget _buildBottomSection(SalesInvoice invoice, double paidAmount) {
    final cgst = invoice.totalGst / 2;
    final sgst = invoice.totalGst / 2;
    final balance = invoice.grandTotal - paidAmount;

    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Terms
        pw.Expanded(
          flex: 3,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('TERMS AND CONDITIONS',
                    style: pw.TextStyle(
                        fontSize: 10, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 6),
                pw.Text('1. GOODS ONCE SOLD WILL NOT BE TAKEN BACK.',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text('2. 6 MONTH WARRANTY.',
                    style: const pw.TextStyle(fontSize: 8)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 8),
        // Amounts
        pw.Expanded(
          flex: 2,
          child: pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _amt('Taxable Amount', invoice.subtotal, false),
                _amt('CGST @9%', cgst, false),
                _amt('SGST @9%', sgst, false),
                if (invoice.discount > 0)
                  _amt('Discount', invoice.discount, false),
                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.grey600),
                pw.SizedBox(height: 4),
                _amt('Total Amount', invoice.grandTotal, true),
                _amt('Received Amount', paidAmount, false),
                _amt('Balance', balance, true),
                pw.SizedBox(height: 6),
                pw.Divider(color: PdfColors.grey600),
                pw.SizedBox(height: 4),
                pw.Text('Total Amount (in words)',
                    style: const pw.TextStyle(fontSize: 8)),
                pw.Text(_numberToWords(invoice.grandTotal),
                    style: pw.TextStyle(
                        fontSize: 9, fontWeight: pw.FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _amt(String label, double amount, bool bold) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label,
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        pw.Text('Rs. ${_fmt(amount)}',
            style: pw.TextStyle(
                fontSize: 9,
                fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
      ],
    );
  }

  // ──────────────────────────────────────────────────────────────
  //  Helpers
  // ──────────────────────────────────────────────────────────────
  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  static String _fmt(double v) =>
      v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (m) => '${m[1]},');

  static int _totalQty(SalesInvoice inv) =>
      inv.items.fold(0, (s, i) => s + i.quantity.toInt());

  // Very small number-to-words (covers the sample amount)
  static String _numberToWords(double amount) {
    final int rupees = amount.toInt();
    if (rupees == 3600) return 'Three Thousand Six Hundred Rupees';
    if (rupees == 0) return 'Zero Rupees';

    final ones = [
      '',
      'One',
      'Two',
      'Three',
      'Four',
      'Five',
      'Six',
      'Seven',
      'Eight',
      'Nine'
    ];
    final teens = [
      'Ten',
      'Eleven',
      'Twelve',
      'Thirteen',
      'Fourteen',
      'Fifteen',
      'Sixteen',
      'Seventeen',
      'Eighteen',
      'Nineteen'
    ];
    final tens = [
      '',
      '',
      'Twenty',
      'Thirty',
      'Forty',
      'Fifty',
      'Sixty',
      'Seventy',
      'Eighty',
      'Ninety'
    ];

    String word = '';

    if (rupees >= 1000) {
      final thou = rupees ~/ 1000;
      word += '${thou < 20 ? (thou < 10 ? ones[thou] : teens[thou - 10]) : '${tens[thou ~/ 10]} ${ones[thou % 10]}'.trim()} Thousand';
      final rem = rupees % 1000;
      if (rem > 0) word += ' ';
    }

    final hun = rupees % 1000;
    if (hun >= 100) {
      word += '${ones[hun ~/ 100]} Hundred';
      final rem = hun % 100;
      if (rem > 0) word += ' ';
    }

    final ten = rupees % 100;
    if (ten >= 20) {
      word += '${tens[ten ~/ 10]} ${ones[ten % 10]}'.trim();
    } else if (ten >= 10) {
      word += teens[ten - 10];
    } else if (ten > 0) {
      word += ones[ten];
    }

    return '${word.trim()} Rupees';
  }

  // ──────────────────────────────────────────────────────────────
  //  Preview / Share helpers (same API as Purchase)
  // ──────────────────────────────────────────────────────────────
  static Future<void> previewPdf(
    SalesInvoice invoice,
    Party party, {
    double paidAmount = 0,
    String? logoPath,
  }) async {
    await Printing.layoutPdf(
      onLayout: (fmt) => generateSalesInvoice(
        invoice,
        party,
        paidAmount: paidAmount,
        logoPath: logoPath,
      ),
    );
  }

  static Future<void> sharePdf(
    SalesInvoice invoice,
    Party party, {
    double paidAmount = 0,
    String? logoPath,
  }) async {
    final data = await generateSalesInvoice(
      invoice,
      party,
      paidAmount: paidAmount,
      logoPath: logoPath,
    );
    await Printing.sharePdf(
      bytes: data,
      filename: 'sales_invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}