import 'dart:convert';
import 'dart:io';
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/purchase_invoice.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PurchaseReportExcelExporter {
  static const String COMPANY_NAME = "SAITRONICS";
  static const String COMPANY_PHONE = "Phone No: 9359023027";

  /// Main export function (works on both Web and Mobile)
  static Future<String?> exportToExcel({
    required List<PurchaseInvoice> invoices,
    required Map<String, Party?> partyCache,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      // Create Excel file with explicit constructor
      final excel = Excel.createExcel();
      
      // Get or create the Purchase Report sheet
      Sheet sheet;
      if (excel.sheets.containsKey('Purchase Report')) {
        sheet = excel.sheets['Purchase Report']!;
      } else {
        excel.rename('Sheet1', 'Purchase Report');
        sheet = excel.sheets['Purchase Report']!;
      }

      // Add company header
      _addCompanyHeader(sheet);

      // Add date range
      _addDateRange(sheet, startDate, endDate);

      // Add column headers
      _addColumnHeaders(sheet);

      // Add data rows
      _addDataRows(sheet, invoices, partyCache);

      // Add total row
      _addTotalRow(sheet, invoices);

      // Style the sheet
      _styleSheet(sheet);

      // Save file based on platform
      if (kIsWeb) {
        return await _saveExcelFileWeb(excel, startDate, endDate);
      } else {
        return await _saveExcelFileMobile(excel, startDate, endDate);
      }
    } catch (e) {
      print('Error exporting to Excel: $e');
      return null;
    }
  }

  /// Add company header (SAI and phone number)
  static void _addCompanyHeader(Sheet sheet) {
    // SAI
    var cell = sheet.cell(CellIndex.indexByString('A1'));
    cell.value = TextCellValue(COMPANY_NAME);
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 16,
      horizontalAlign: HorizontalAlign.Left,
    );

    // Phone number
    cell = sheet.cell(CellIndex.indexByString('A2'));
    cell.value = TextCellValue(COMPANY_PHONE);
    cell.cellStyle = CellStyle(
      fontSize: 10,
      horizontalAlign: HorizontalAlign.Left,
    );

    // Empty row
    sheet.cell(CellIndex.indexByString('A3'));
  }

  /// Add date range header
  static void _addDateRange(Sheet sheet, DateTime startDate, DateTime endDate) {
    final dateFormat = DateFormat('dd/MM/yyyy');
    
    // "Purchase Report"
    var cell = sheet.cell(CellIndex.indexByString('A4'));
    cell.value = TextCellValue('Purchase Report');
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 14,
      horizontalAlign: HorizontalAlign.Left,
    );

    // Date range
    cell = sheet.cell(CellIndex.indexByString('A5'));
    cell.value = TextCellValue('Dated: ${dateFormat.format(startDate)}-${dateFormat.format(endDate)}');
    cell.cellStyle = CellStyle(
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
    );

    // "Total Purchase"
    cell = sheet.cell(CellIndex.indexByString('A6'));
    cell.value = TextCellValue('Total Purchase');
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
    );

    // Empty row
    sheet.cell(CellIndex.indexByString('A7'));
  }

  /// Add column headers
  static void _addColumnHeaders(Sheet sheet) {
    final headers = [
      'Date',
      'Invoice No.',
      'Original Invoice No.',
      'Party GSTIN',
      'Party Name',
      'Item Name',
      'HSN Code',
      'Quantity',
      'Price/Unit',
      'SGST',
      'CGST',
      'IGST',
      'Amount',
    ];

    for (int i = 0; i < headers.length; i++) {
      final cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 7));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        backgroundColorHex: ExcelColor.grey50,
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }
  }

  /// Add data rows
  static void _addDataRows(
    Sheet sheet,
    List<PurchaseInvoice> invoices,
    Map<String, Party?> partyCache,
  ) {
    int rowIndex = 8; // Start after headers
    final dateFormat = DateFormat('dd/MM/yyyy');

    for (var invoice in invoices) {
      for (var item in invoice.items) {
        final party = partyCache[invoice.partyId];

        // Column values
        final rowData = [
          dateFormat.format(invoice.invoiceDate), // Date
          invoice.invoiceNumber, // Invoice No.
          '', // Original Invoice No. (empty as per your CSV)
          party?.gstNumber ?? '', // Party GSTIN
          party?.name ?? invoice.partyName, // Party Name
          item.itemName, // Item Name
          item.hsnCode, // HSN Code
          '${item.quantity.toStringAsFixed(1)} PCS', // Quantity
          item.basePricePerUnit.toStringAsFixed(2), // Price/Unit
          item.sgst > 0 ? item.sgst.toStringAsFixed(2) : '', // SGST
          item.cgst > 0 ? item.cgst.toStringAsFixed(2) : '', // CGST
           '', // IGST
          item.total.toStringAsFixed(2), // Amount
        ];

        for (int i = 0; i < rowData.length; i++) {
          final cell = sheet.cell(CellIndex.indexByColumnRow(
            columnIndex: i,
            rowIndex: rowIndex,
          ));
          
          // Set value based on column type
          if (i == 8 || i == 9 || i == 10 || i == 11 || i == 12) {
            // Numeric columns (Price/Unit, SGST, CGST, IGST, Amount)
            final value = double.tryParse(rowData[i].toString().replaceAll(',', ''));
            if (value != null) {
              cell.value = DoubleCellValue(value);
            } else {
              cell.value = TextCellValue(rowData[i].toString());
            }
          } else {
            cell.value = TextCellValue(rowData[i].toString());
          }

          // Add borders
          cell.cellStyle = CellStyle(
            fontSize: 10,
            horizontalAlign: i >= 8 ? HorizontalAlign.Right : HorizontalAlign.Left,
            bottomBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.grey50),
            topBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.grey50),
            leftBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.grey50),
            rightBorder: Border(borderStyle: BorderStyle.Thin, borderColorHex: ExcelColor.grey50),
          );
        }

        rowIndex++;
      }
    }
  }

  /// Add total row at the bottom
  static void _addTotalRow(Sheet sheet, List<PurchaseInvoice> invoices) {
    int lastDataRow = 8; // Start row
    for (var invoice in invoices) {
      lastDataRow += invoice.items.length;
    }

    // Calculate totals
    double totalAmount = 0;
    double totalSGST = 0;
    double totalCGST = 0;
    double totalIGST = 0;

    for (var invoice in invoices) {
      for (var item in invoice.items) {
        totalAmount += item.total;
        totalSGST += item.sgst;
        totalCGST += item.cgst;
        // totalIGST += item.igst;
      }
    }

    // Add "TOTAL" label
    var cell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: 0,
      rowIndex: lastDataRow,
    ));
    cell.value = TextCellValue('TOTAL');
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Left,
      backgroundColorHex: ExcelColor.grey50,
    );

    // Add SGST total
    cell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: 9,
      rowIndex: lastDataRow,
    ));
    cell.value = DoubleCellValue(totalSGST);
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      backgroundColorHex: ExcelColor.grey50,
    );

    // Add CGST total
    cell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: 10,
      rowIndex: lastDataRow,
    ));
    cell.value = DoubleCellValue(totalCGST);
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      backgroundColorHex: ExcelColor.grey50,
    );

    // Add IGST total (if any)
    if (totalIGST > 0) {
      cell = sheet.cell(CellIndex.indexByColumnRow(
        columnIndex: 11,
        rowIndex: lastDataRow,
      ));
      cell.value = DoubleCellValue(totalIGST);
      cell.cellStyle = CellStyle(
        bold: true,
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Right,
        backgroundColorHex: ExcelColor.grey50,
      );
    }

    // Add total amount
    cell = sheet.cell(CellIndex.indexByColumnRow(
      columnIndex: 12,
      rowIndex: lastDataRow,
    ));
    cell.value = DoubleCellValue(totalAmount);
    cell.cellStyle = CellStyle(
      bold: true,
      fontSize: 11,
      horizontalAlign: HorizontalAlign.Right,
      backgroundColorHex: ExcelColor.grey50,
    );
  }

  /// Apply styling to the sheet
  static void _styleSheet(Sheet sheet) {
    // Set column widths
    sheet.setColumnWidth(0, 12); // Date
    sheet.setColumnWidth(1, 12); // Invoice No.
    sheet.setColumnWidth(2, 18); // Original Invoice No.
    sheet.setColumnWidth(3, 18); // Party GSTIN
    sheet.setColumnWidth(4, 20); // Party Name
    sheet.setColumnWidth(5, 25); // Item Name
    sheet.setColumnWidth(6, 12); // HSN Code
    sheet.setColumnWidth(7, 12); // Quantity
    sheet.setColumnWidth(8, 12); // Price/Unit
    sheet.setColumnWidth(9, 12); // SGST
    sheet.setColumnWidth(10, 12); // CGST
    sheet.setColumnWidth(11, 12); // IGST
    sheet.setColumnWidth(12, 15); // Amount
  }

  /// Save Excel file for WEB - Downloads directly in browser
  static Future<String> _saveExcelFileWeb(
    Excel excel,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final dateFormat = DateFormat('ddMMyyyy');
    final fileName =
        'Purchase_Report_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}.xlsx';

    // Encode to bytes
    final bytes = excel.encode();
    if (bytes == null) {
      throw Exception('Failed to generate Excel file');
    }

    // Create a single download using Blob
    final blob = html.Blob([bytes]);
    final url = html.Url.createObjectUrlFromBlob(blob);
    
    // Use a more controlled approach
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName;
    
    // Trigger download
    anchor.click();
    
    // Small delay before cleanup to ensure download starts
    await Future.delayed(const Duration(milliseconds: 100));
    html.Url.revokeObjectUrl(url);

    return 'Downloaded: $fileName';
  }

  /// Save Excel file for MOBILE - Saves to device storage
  static Future<String> _saveExcelFileMobile(
    Excel excel,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Request storage permission
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          throw Exception('Storage permission denied');
        }
      }
    }

    final dateFormat = DateFormat('ddMMyyyy');
    final fileName =
        'Purchase_Report_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}.xlsx';

    late String filePath;

    if (Platform.isAndroid) {
      // For Android, save to Downloads folder
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      filePath = '${directory.path}/$fileName';
    } else if (Platform.isIOS) {
      // For iOS, save to Documents directory
      final directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$fileName';
    } else {
      throw UnsupportedError('Platform not supported');
    }

    // Save the file
    final fileBytes = excel.encode();
    if (fileBytes != null) {
      final file = File(filePath);
      await file.writeAsBytes(fileBytes);
    }

    return filePath;
  }

  /// Get summary statistics
  static Map<String, dynamic> getSummary(List<PurchaseInvoice> invoices) {
    double totalAmount = 0;
    double totalSGST = 0;
    double totalCGST = 0;
    double totalIGST = 0;
    int totalItems = 0;

    for (var invoice in invoices) {
      for (var item in invoice.items) {
        totalAmount += item.total;
        totalSGST += item.sgst;
        totalCGST += item.cgst;
        // totalIGST += item.igst;
        totalItems++;
      }
    }

    return {
      'totalInvoices': invoices.length,
      'totalItems': totalItems,
      'totalAmount': totalAmount,
      'totalSGST': totalSGST,
      'totalCGST': totalCGST,
      'totalIGST': totalIGST,
      'totalGST': totalSGST + totalCGST + totalIGST,
    };
  }
}








class PurchaseReportPdfGenerator {
  static const String COMPANY_NAME = "SAITRONICS";
  static const String COMPANY_PHONE = "Phone No: 9359023027";

  /// Main PDF generation function (works on both Web and Mobile)
  static Future<String?> generatePdf({
    required List<PurchaseInvoice> invoices,
    required Map<String, Party?> partyCache,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final pdf = pw.Document();
      final dateFormat = DateFormat('dd/MM/yyyy');

      // Calculate totals
      double totalAmount = 0;
      double totalSGST = 0;
      double totalCGST = 0;
      double totalIGST = 0;

      for (var invoice in invoices) {
        for (var item in invoice.items) {
          totalAmount += item.total;
          totalSGST += item.sgst;
          totalCGST += item.cgst;
          // totalIGST += item.igst;
        }
      }

      // Build data rows
      final List<List<String>> tableData = [];
      for (var invoice in invoices) {
        for (var item in invoice.items) {
          final party = partyCache[invoice.partyId];
          tableData.add([
            dateFormat.format(invoice.invoiceDate),
            invoice.invoiceNumber,
            '', // Original Invoice No.
            party?.gstNumber ?? '',
            party?.name ?? invoice.partyName,
            item.itemName,
            item.hsnCode,
            '${item.quantity.toStringAsFixed(1)} PCS',
            item.basePricePerUnit.toStringAsFixed(2),
            item.sgst > 0 ? item.sgst.toStringAsFixed(2) : '',
            item.cgst > 0 ? item.cgst.toStringAsFixed(2) : '',
            '', // IGST
            item.total.toStringAsFixed(2),
          ]);
        }
      }

      // Add page with landscape orientation for better table fit
      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4.landscape,
          margin: const pw.EdgeInsets.all(20),
          build: (context) => [
            // Company Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  COMPANY_NAME,
                  style: pw.TextStyle(
                    fontSize: 20,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  COMPANY_PHONE,
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.SizedBox(height: 16),
                pw.Text(
                  'Purchase Report',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Dated: ${dateFormat.format(startDate)}-${dateFormat.format(endDate)}',
                  style: const pw.TextStyle(fontSize: 11),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Total Purchase',
                  style: pw.TextStyle(
                    fontSize: 11,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 16),
              ],
            ),

            // Data Table
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              columnWidths: {
                0: const pw.FlexColumnWidth(1.5), // Date
                1: const pw.FlexColumnWidth(1.5), // Invoice No.
                2: const pw.FlexColumnWidth(2), // Original Invoice No.
                3: const pw.FlexColumnWidth(2), // Party GSTIN
                4: const pw.FlexColumnWidth(2.5), // Party Name
                5: const pw.FlexColumnWidth(3), // Item Name
                6: const pw.FlexColumnWidth(1.5), // HSN Code
                7: const pw.FlexColumnWidth(1.5), // Quantity
                8: const pw.FlexColumnWidth(1.5), // Price/Unit
                9: const pw.FlexColumnWidth(1.2), // SGST
                10: const pw.FlexColumnWidth(1.2), // CGST
                11: const pw.FlexColumnWidth(1.2), // IGST
                12: const pw.FlexColumnWidth(1.5), // Amount
              },
              children: [
                // Header Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey300,
                  ),
                  children: [
                    _buildHeaderCell('Date'),
                    _buildHeaderCell('Invoice No.'),
                    _buildHeaderCell('Original Invoice No.'),
                    _buildHeaderCell('Party GSTIN'),
                    _buildHeaderCell('Party Name'),
                    _buildHeaderCell('Item Name'),
                    _buildHeaderCell('HSN Code'),
                    _buildHeaderCell('Quantity'),
                    _buildHeaderCell('Price/Unit'),
                    _buildHeaderCell('SGST'),
                    _buildHeaderCell('CGST'),
                    _buildHeaderCell('IGST'),
                    _buildHeaderCell('Amount'),
                  ],
                ),
                // Data Rows
                ...tableData.map((row) => pw.TableRow(
                  children: row.asMap().entries.map((entry) {
                    final index = entry.key;
                    final value = entry.value;
                    // Right align numeric columns (8-12)
                    final align = index >= 8 
                        ? pw.TextAlign.right 
                        : pw.TextAlign.left;
                    return _buildDataCell(value, align);
                  }).toList(),
                )),
                // Total Row
                pw.TableRow(
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                  ),
                  children: [
                    _buildTotalCell('TOTAL', pw.TextAlign.left),
                    _buildTotalCell('', pw.TextAlign.left),
                    _buildTotalCell('', pw.TextAlign.left),
                    _buildTotalCell('', pw.TextAlign.left),
                    _buildTotalCell('', pw.TextAlign.left),
                    _buildTotalCell('', pw.TextAlign.left),
                    _buildTotalCell('', pw.TextAlign.left),
                    _buildTotalCell('', pw.TextAlign.right),
                    _buildTotalCell('', pw.TextAlign.right),
                    _buildTotalCell(totalSGST.toStringAsFixed(2), pw.TextAlign.right),
                    _buildTotalCell(totalCGST.toStringAsFixed(2), pw.TextAlign.right),
                    _buildTotalCell(totalIGST > 0 ? totalIGST.toStringAsFixed(2) : '', pw.TextAlign.right),
                    _buildTotalCell(totalAmount.toStringAsFixed(2), pw.TextAlign.right),
                  ],
                ),
              ],
            ),
          ],
        ),
      );

      // Save based on platform
      if (kIsWeb) {
        return await _savePdfWeb(pdf, startDate, endDate);
      } else {
        return await _savePdfMobile(pdf, startDate, endDate);
      }
    } catch (e) {
      print('Error generating PDF: $e');
      return null;
    }
  }

  static pw.Widget _buildHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildDataCell(String text, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(3),
      child: pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 7),
        textAlign: align,
      ),
    );
  }

  static pw.Widget _buildTotalCell(String text, pw.TextAlign align) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8,
          fontWeight: pw.FontWeight.bold,
        ),
        textAlign: align,
      ),
    );
  }

  /// Save PDF for WEB - Downloads directly in browser
  static Future<String> _savePdfWeb(
    pw.Document pdf,
    DateTime startDate,
    DateTime endDate,
  ) async {
    final dateFormat = DateFormat('ddMMyyyy');
    final fileName =
        'Purchase_Report_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}.pdf';

    // Generate PDF bytes
    final bytes = await pdf.save();

    // Create download
    final blob = html.Blob([bytes], 'application/pdf');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final anchor = html.AnchorElement()
      ..href = url
      ..download = fileName;
    
    anchor.click();
    
    await Future.delayed(const Duration(milliseconds: 100));
    html.Url.revokeObjectUrl(url);

    return 'Downloaded: $fileName';
  }

  /// Save PDF for MOBILE - Saves to device storage
  static Future<String> _savePdfMobile(
    pw.Document pdf,
    DateTime startDate,
    DateTime endDate,
  ) async {
    // Request storage permission
    if (Platform.isAndroid) {
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        final manageStatus = await Permission.manageExternalStorage.request();
        if (!manageStatus.isGranted) {
          throw Exception('Storage permission denied');
        }
      }
    }

    final dateFormat = DateFormat('ddMMyyyy');
    final fileName =
        'Purchase_Report_${dateFormat.format(startDate)}_${dateFormat.format(endDate)}.pdf';

    late String filePath;

    if (Platform.isAndroid) {
      final directory = Directory('/storage/emulated/0/Download');
      if (!await directory.exists()) {
        await directory.create(recursive: true);
      }
      filePath = '${directory.path}/$fileName';
    } else if (Platform.isIOS) {
      final directory = await getApplicationDocumentsDirectory();
      filePath = '${directory.path}/$fileName';
    } else {
      throw UnsupportedError('Platform not supported');
    }

    // Save the file
    final file = File(filePath);
    await file.writeAsBytes(await pdf.save());

    return filePath;
  }
}