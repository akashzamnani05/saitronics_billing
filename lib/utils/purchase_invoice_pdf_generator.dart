import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:saitronics_billing/models/invoice_item.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/purchase_invoice.dart';


class PurchaseInvoicePdfGenerator {
  // Company Details - Update these with your company info
  static const String companyName = "SAITRONICS";
  static const String companyAddress =
      "NEW PANDIT COLONY, SHOP NO 1 GROUND FLOOR, MALPANI PRIDE, NR RAYMOND SHOWROOM, NASHIK-422002, Nashik, Maharashtra, 422002";
  static const String companyMobile = "9359023027";
  static const String companyGSTIN = "27AAEPZ9949F1ZW";
  static const String companyPAN = "AAEPZ9949F";
  static const String companyEmail = "saitronics.nashik@gmail.com";
  static const String placeOfSupply = "Maharashtra";

  static Future<Uint8List> generatePurchaseInvoice(
    PurchaseInvoice invoice,
    Party party, {
    double paidAmount = 0,
    String? logoPath, // Optional logo path
  }) async {
    final pdf = pw.Document();

    // Load logo if provided
    pw.ImageProvider? logo;
    if (logoPath != null) {
      try {
        final imageData = await rootBundle.load(logoPath);
        final imageBytes = imageData.buffer.asUint8List();
        logo = pw.MemoryImage(imageBytes);
      } catch (e) {
        print('Error loading logo: $e');
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header Section
              _buildHeader(logo),
              pw.SizedBox(height: 15),

              // Invoice Details
              _buildInvoiceDetails(invoice),
              pw.SizedBox(height: 15),

              // Bill From and Ship From Section
              _buildBillFromShipFrom(party),
              pw.SizedBox(height: 15),

              // Items Table
              _buildItemsTable(invoice),
              pw.SizedBox(height: 15),

              // Bottom Section with Terms and Totals
              _buildBottomSection(invoice, paidAmount),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildHeader([pw.ImageProvider? logo]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Logo section
          if (logo != null)
            pw.Container(
              width: 80,
              height: 80,
              child: pw.Image(logo, fit: pw.BoxFit.contain),
            ),
          if (logo != null) pw.SizedBox(width: 15),
          
          // Company details
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  companyName,
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  companyAddress,
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 5),
                pw.Text(
                  'Mobile: $companyMobile',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.Text(
                  'GSTIN: $companyGSTIN',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.normal,
                  ),
                ),
                pw.Text(
                  'PAN Number: $companyPAN',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Email: $companyEmail',
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildInvoiceDetails(PurchaseInvoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          'Purchase No.: ${invoice.invoiceNumber}',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(
          'Purchase Date: ${_formatDate(invoice.invoiceDate)}',
          style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold),
        ),
      ],
    );
  }

  static pw.Widget _buildBillFromShipFrom(Party party) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Bill From
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'BILL FROM',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  party.name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  party.address,
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Mobile: ${party.phone}',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  'Place of Supply: $placeOfSupply',
                  style: const pw.TextStyle(fontSize: 9),
                ),
                if(party.gstNumber.isNotEmpty)
                pw.Text('GSTIN: ${party.gstNumber}',
                    style: const pw.TextStyle(fontSize: 9)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        // Ship From
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey400),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'SHIP FROM',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  party.name,
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  party.address,
                  style: const pw.TextStyle(fontSize: 9),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildItemsTable(PurchaseInvoice invoice) {
  return pw.Container(
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: PdfColors.grey400),
    ),
    child: pw.Column(
      children: [
        // Table Header
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const pw.BoxDecoration(
            color: PdfColors.grey300,
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  'ITEMS',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'HSN',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'QTY.',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'RATE',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'TAX',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'AMOUNT',
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),

        // Table Rows
        ...invoice.items.map((item) => _buildItemRow(item)),

        // Subtotal Row - UPDATED for proper alignment
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: const pw.BoxDecoration(
            border: pw.Border(
              top: pw.BorderSide(color: PdfColors.grey400),
            ),
          ),
          child: pw.Row(
            children: [
              // ITEMS column - empty for subtotal
              pw.Expanded(
                flex: 4,
                child: pw.Text(
                  'SUBTOTAL',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.left,
                ),
              ),
              // HSN column - empty for subtotal
              pw.Expanded(flex: 2, child: pw.Container()),
              // QTY column - show total quantity
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  '${_getTotalQuantity(invoice)} PCS',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // RATE column - empty for subtotal
              pw.Expanded(flex: 2, child: pw.Container()),
              // TAX column - show total GST
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Rs. ${_formatAmount(invoice.totalGst)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ),
              // AMOUNT column - show total
              pw.Expanded(
                flex: 2,
                child: pw.Text(
                  'Rs. ${_formatAmount(invoice.totalBeforeDiscount)}',
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

static pw.Widget _buildItemRow(InvoiceItem item) {
  return pw.Container(
    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    decoration: const pw.BoxDecoration(
      border: pw.Border(
        top: pw.BorderSide(color: PdfColors.grey400),
      ),
    ),
    child: pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // ITEMS column
        pw.Expanded(
          flex: 4,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                item.itemName.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              // Add description if available
              if (item.description.isNotEmpty) ...[
                pw.SizedBox(height: 2),
                pw.Text(
                  item.description,
                  style: pw.TextStyle(
                    fontSize: 8,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
        // HSN column
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            item.hsnCode,
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
        // QTY column
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            '${item.quantity.toInt()} PCS',
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.center,
          ),
        ),
        // RATE column
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            _formatAmount(item.price),
            style: const pw.TextStyle(fontSize: 9),
            textAlign: pw.TextAlign.right,
          ),
        ),
        // TAX column
        pw.Expanded(
          flex: 2,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(
                _formatAmount(item.gstAmount),
                style: const pw.TextStyle(fontSize: 9),
                textAlign: pw.TextAlign.center,
              ),
              pw.Text(
                '(${item.gstPercent.toInt()}%)',
                style: const pw.TextStyle(fontSize: 8),
                textAlign: pw.TextAlign.center,
              ),
            ],
          ),
        ),
        // AMOUNT column
        pw.Expanded(
          flex: 2,
          child: pw.Text(
            _formatAmount(item.total),
            style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
            textAlign: pw.TextAlign.right,
          ),
        ),
      ],
    ),
  );
}

  static pw.Widget _buildBottomSection(
    PurchaseInvoice invoice, double paidAmount) {
  final balanceAmount = invoice.total - paidAmount;
  final cgstAmount = invoice.totalGst / 2;
  final sgstAmount = invoice.totalGst / 2;

  return pw.Column(
    children: [
      // Terms and Amounts Row
      pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Terms and Conditions
          pw.Expanded(
            flex: 3,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'TERMS AND CONDITIONS',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '1. Goods once sold will not be taken back',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.Text(
                    '2. 6 month Warranty',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                ],
              ),
            ),
          ),
          pw.SizedBox(width: 10),
          // Amounts Section
          pw.Expanded(
            flex: 2,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(10),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey400),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  _buildAmountRow(
                      'Taxable Amount', invoice.subtotal, isBold: false),
                  pw.SizedBox(height: 4),
                  _buildAmountRow('CGST @9%', cgstAmount, isBold: false),
                  pw.SizedBox(height: 4),
                  _buildAmountRow('SGST @9%', sgstAmount, isBold: false),
                  pw.SizedBox(height: 4),
                  if(invoice.discount > 0) _buildAmountRow('Discount', invoice.discount,
                      isBold: false),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  _buildAmountRow('Total Amount', invoice.total,
                      isBold: true),
                  pw.SizedBox(height: 4),
                  _buildAmountRow('Paid Amount', paidAmount, isBold: false),
                  pw.SizedBox(height: 4),
                  _buildAmountRow('Balance', balanceAmount, isBold: true),
                  pw.SizedBox(height: 8),
                  pw.Divider(color: PdfColors.grey400),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Total Amount (in words)',
                    style: const pw.TextStyle(fontSize: 8),
                  ),
                  pw.SizedBox(height: 2),
                  pw.Text(
                    _convertAmountToWords(invoice.total),
                    style: pw.TextStyle(
                      fontSize: 9,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      
      // NEW: Signature box
      pw.SizedBox(height: 10),
      pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Container(
                width: 200,
                height: 60,
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey600),
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'AUTHORISED SIGNATORY FOR',
                style: pw.TextStyle(
                  fontSize: 9,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                companyName,
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

  static pw.Widget _buildAmountRow(String label, double amount,
      {required bool isBold}) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
        pw.Text(
          'Rs. ${_formatAmount(amount)}',
          style: pw.TextStyle(
            fontSize: 9,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
          ),
        ),
      ],
    );
  }

  // Helper Methods
  static String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  static String _formatAmount(double amount) {
    return amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
  }

  static int _getTotalQuantity(PurchaseInvoice invoice) {
    return invoice.items
        .fold(0, (sum, item) => sum + item.quantity.toInt());
  }

  static String _convertAmountToWords(double amount) {
    // Simple implementation - you can enhance this
    final intAmount = amount.toInt();
    if (intAmount == 25000) return 'Twenty Five Thousand Rupees';
    if (intAmount == 0) return 'Zero Rupees';

    // Basic conversion for demonstration
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

    if (intAmount < 10) return '${ones[intAmount]} Rupees';
    if (intAmount < 20) return '${teens[intAmount - 10]} Rupees';
    if (intAmount < 100) {
      final ten = intAmount ~/ 10;
      final one = intAmount % 10;
      return '${tens[ten]} ${ones[one]} Rupees'.trim();
    }
    if (intAmount < 1000) {
      final hundred = intAmount ~/ 100;
      final remainder = intAmount % 100;
      String result = '${ones[hundred]} Hundred';
      if (remainder > 0) {
        if (remainder < 10) result += ' ${ones[remainder]}';
        if (remainder >= 10 && remainder < 20)
          result += ' ${teens[remainder - 10]}';
        if (remainder >= 20) {
          final ten = remainder ~/ 10;
          final one = remainder % 10;
          result += ' ${tens[ten]} ${ones[one]}'.trim();
        }
      }
      return '$result Rupees';
    }
    if (intAmount < 100000) {
      final thousand = intAmount ~/ 1000;
      final remainder = intAmount % 1000;
      String result = '';
      if (thousand < 10) result = '${ones[thousand]} Thousand';
      if (thousand >= 10 && thousand < 20)
        result = '${teens[thousand - 10]} Thousand';
      if (thousand >= 20) {
        final ten = thousand ~/ 10;
        final one = thousand % 10;
        result = '${tens[ten]} ${ones[one]} Thousand'.trim();
      }
      if (remainder > 0) {
        if (remainder < 100) {
          if (remainder < 10) result += ' ${ones[remainder]}';
          if (remainder >= 10 && remainder < 20)
            result += ' ${teens[remainder - 10]}';
          if (remainder >= 20) {
            final ten = remainder ~/ 10;
            final one = remainder % 10;
            result += ' ${tens[ten]} ${ones[one]}'.trim();
          }
        } else {
          final hundred = remainder ~/ 100;
          final rem = remainder % 100;
          result += ' ${ones[hundred]} Hundred';
          if (rem > 0) {
            if (rem < 10) result += ' ${ones[rem]}';
            if (rem >= 10 && rem < 20) result += ' ${teens[rem - 10]}';
            if (rem >= 20) {
              final ten = rem ~/ 10;
              final one = rem % 10;
              result += ' ${tens[ten]} ${ones[one]}'.trim();
            }
          }
        }
      }
      return '$result Rupees';
    }

    return '${_formatAmount(amount)} Rupees';
  }

  // Method to preview PDF
  static Future<void> previewPdf(
    PurchaseInvoice invoice,
    Party party, {
    double paidAmount = 0,
    String? logoPath,
  }) async {
    await Printing.layoutPdf(
      onLayout: (format) => generatePurchaseInvoice(
        invoice,
        party,
        paidAmount: paidAmount,
        logoPath: logoPath,
      ),
    );
  }

  // Method to share/download PDF
  static Future<void> sharePdf(
    PurchaseInvoice invoice,
    Party party, {
    double paidAmount = 0,
    String? logoPath,
  }) async {
    final pdfData = await generatePurchaseInvoice(
      invoice,
      party,
      paidAmount: paidAmount,
      logoPath: logoPath,
    );
    await Printing.sharePdf(
      bytes: pdfData,
      filename: 'purchase_invoice_${invoice.invoiceNumber}.pdf',
    );
  }
}