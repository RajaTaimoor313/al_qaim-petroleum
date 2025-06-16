import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:path_provider/path_provider.dart';
import 'package:excel/excel.dart' as excel;
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import 'package:universal_html/html.dart' as html;

class ExportData extends StatefulWidget {
  const ExportData({super.key});

  @override
  State<ExportData> createState() => _ExportDataState();
}

class _ExportDataState extends State<ExportData> {
  bool isExporting = false;
  String statusMessage = '';
  bool hasError = false;
  String exportedFilePath = '';

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double padding = isMobile ? 12.0 : 16.0;
    final double borderRadius = isMobile ? 12.0 : 15.0;
    final double titleFontSize = isMobile ? 20.0 : 24.0;
    final double buttonHeight = isMobile ? 48.0 : 56.0;

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Export Data',
            style: TextStyle(
              fontSize: titleFontSize,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),

          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Padding(
              padding: EdgeInsets.all(padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Export All Data to Excel',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This will create an Excel file containing all your Saved data. The file will be saved to your Downloads folder.',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: buttonHeight,
                    child: ElevatedButton.icon(
                      onPressed: isExporting ? null : _exportDataToExcel,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: isExporting
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.download),
                      label: Text(
                        isExporting ? 'Exporting...' : 'Export to Excel',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (statusMessage.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: hasError ? Colors.red.shade50 : Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasError ? Colors.red.shade200 : Colors.green.shade200,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    hasError ? Icons.error : Icons.check_circle,
                    color: hasError ? Colors.red : Colors.green,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      statusMessage,
                      style: TextStyle(
                        color: hasError ? Colors.red.shade700 : Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          if (exportedFilePath.isNotEmpty && !hasError && !kIsWeb) ...[
            const SizedBox(height: 24),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'File Exported Successfully',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Saved to: $exportedFilePath',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _openExportedFile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        icon: const Icon(Icons.folder_open),
                        label: const Text('Open Containing Folder'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _exportDataToExcel() async {
    if (isExporting) return;
    setState(() {
      isExporting = true;
      statusMessage = 'Exporting data, please wait...';
      hasError = false;
      exportedFilePath = '';
    });

    try {
      final excelFile = excel.Excel.createExcel();

      // Excel.createExcel() automatically creates Sheet1
      if (excelFile.sheets.containsKey('Sheet1')) {
        // Create custom sheets by copying Sheet1
        excelFile.copy('Sheet1', 'Customers');
        excelFile.copy('Sheet1', 'Transactions');
        excelFile.copy('Sheet1', 'Sales');

        // Delete the original Sheet1
        excelFile.delete('Sheet1');
      }

      final customersSheet = excelFile['Customers'];
      final transactionsSheet = excelFile['Transactions'];
      final salesSheet = excelFile['Sales'];

      final customerHeaders = [
        'Name', 'Phone', 'CNIC', 'Page Number', 'Balance', 'Created Date',
      ];
      final transactionHeaders = [
        'Date',
        'Customer Name',
        'Phone',
        'Previous Balance',
        'Amount Paid',
        'Amount Taken',
        'New Balance',
      ];
      final salesHeaders = [
        'Date',
        'Petrol Litres',
        'Petrol Rate',
        'Petrol Amount (Rs)',
        'Diesel Litres',
        'Diesel Rate',
        'Diesel Amount (Rs)',
        'Total Amount (Rs)',
      ];

      final headerStyle = excel.CellStyle(
        bold: true,
        backgroundColorHex: excel.ExcelColor.fromHexString('#AED581'),
        horizontalAlign: excel.HorizontalAlign.Center,
      );

      // Add headers to all sheets
      _addHeaders(customersSheet, customerHeaders, headerStyle);
      _addHeaders(transactionsSheet, transactionHeaders, headerStyle);
      _addHeaders(salesSheet, salesHeaders, headerStyle);

      // Fetch data from Firestore
      setState(() => statusMessage = 'Fetching data from database...');
      
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('customers').limit(500).get();
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .orderBy('date', descending: true)
          .limit(1000)
          .get();
      final salesSnapshot = await FirebaseFirestore.instance
          .collection('sales')
          .orderBy('date', descending: true)
          .limit(1000)
          .get();

      // Process data in batches
      await _processCustomersData(customersSnapshot, customersSheet);
      await _processTransactionsData(transactionsSnapshot, transactionsSheet);
      await _processSalesData(salesSnapshot, salesSheet);

      // Format columns
      for (var sheet in excelFile.sheets.values) {
        for (var i = 0; i < 10; i++) {
          sheet.setColumnWidth(i, 20);
        }
      }

      // Generate filename with timestamp
      final fileName = 'Al_Qaim_Petroleum_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.xlsx';
      final fileBytes = excelFile.encode();
      
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      if (kIsWeb) {
        // Simplified web download
        final blob = html.Blob(
          [fileBytes], 
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        );
        final url = html.Url.createObjectUrlFromBlob(blob);
        html.AnchorElement(href: url)
          ..setAttribute('download', fileName)
          ..click();
        html.Url.revokeObjectUrl(url);

        setState(() {
          isExporting = false;
          statusMessage = 'Excel file downloaded successfully!';
        });
      } else {
        // Mobile/desktop download
        final downloadsDir = await _getDownloadsDirectory();
        final filePath = path.join(downloadsDir.path, fileName);
        await File(filePath).writeAsBytes(fileBytes);

        setState(() {
          isExporting = false;
          statusMessage = 'Data exported successfully!';
          exportedFilePath = filePath;
        });
      }
    } catch (e) {
      setState(() {
        isExporting = false;
        statusMessage = 'Error exporting data: ${e.toString().split('\n')[0]}';
        hasError = true;
      });
    }
  }

  void _addHeaders(excel.Sheet sheet, List<String> headers, excel.CellStyle style) {
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = excel.TextCellValue(headers[i]);
      cell.cellStyle = style;
    }
  }

  Future<void> _processCustomersData(
    QuerySnapshot snapshot, 
    excel.Sheet sheet
  ) async {
    int row = 1;
    const batchSize = 100;
    final total = snapshot.docs.length;

    for (int i = 0; i < total; i += batchSize) {
      final end = (i + batchSize < total) ? i + batchSize : total;
      setState(() {
        statusMessage = 'Processing customers (${i + 1}-$end of $total)...';
      });

      for (var doc in snapshot.docs.sublist(i, end)) {
        final data = doc.data() as Map<String, dynamic>;
        final rowData = [
          data['name'] ?? '',
          data['phone'] ?? '',
          data['cnic'] ?? '',
          data['page_number'] ?? '',
          data['balance']?.toString() ?? '0.0',
          data['created_at'] != null
              ? DateFormat('dd/MM/yyyy').format((data['created_at'] as Timestamp).toDate())
              : 'N/A',
        ];

        for (var col = 0; col < rowData.length; col++) {
          sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value = excel.TextCellValue(rowData[col]);
        }
        row++;
      }
    }
  }

  Future<void> _processTransactionsData(
    QuerySnapshot snapshot, 
    excel.Sheet sheet
  ) async {
    int row = 1;
    const batchSize = 100;
    final total = snapshot.docs.length;

    for (int i = 0; i < total; i += batchSize) {
      final end = (i + batchSize < total) ? i + batchSize : total;
      setState(() {
        statusMessage = 'Processing transactions (${i + 1}-$end of $total)...';
      });

      for (var doc in snapshot.docs.sublist(i, end)) {
        final data = doc.data() as Map<String, dynamic>;
        final rowData = [
          data['custom_date'] != null
              ? DateFormat('dd/MM/yyyy').format((data['custom_date'] as Timestamp).toDate())
              : 'N/A',
          data['customer_name'] ?? '',
          data['phone'] ?? '',
          data['previous_balance']?.toString() ?? '0.0',
          data['amount_paid']?.toString() ?? '0.0',
          data['amount_taken']?.toString() ?? '0.0',
          data['new_balance']?.toString() ?? '0.0',
        ];

        for (var col = 0; col < rowData.length; col++) {
          sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value = excel.TextCellValue(rowData[col]);
        }
        row++;
      }
    }
  }

  Future<void> _processSalesData(
    QuerySnapshot snapshot, 
    excel.Sheet sheet
  ) async {
    int row = 1;
    const batchSize = 100;
    final total = snapshot.docs.length;

    for (int i = 0; i < total; i += batchSize) {
      final end = (i + batchSize < total) ? i + batchSize : total;
      setState(() {
        statusMessage = 'Processing sales data (${i + 1}-$end of $total)...';
      });

      for (var doc in snapshot.docs.sublist(i, end)) {
        final data = doc.data() as Map<String, dynamic>;
        final rowData = [
          data['custom_date'] != null
              ? DateFormat('dd/MM/yyyy').format((data['custom_date'] as Timestamp).toDate())
              : 'N/A',
          data['petrol_litres']?.toString() ?? '0.0',
          data['petrol_rate']?.toString() ?? '0.0',
          data['petrol_rupees']?.toString() ?? '0.0',
          data['diesel_litres']?.toString() ?? '0.0',
          data['diesel_rate']?.toString() ?? '0.0',
          data['diesel_rupees']?.toString() ?? '0.0',
          data['total_amount']?.toString() ?? '0.0',
        ];

        for (var col = 0; col < rowData.length; col++) {
          sheet.cell(excel.CellIndex.indexByColumnRow(columnIndex: col, rowIndex: row))
              .value = excel.TextCellValue(rowData[col]);
        }
        row++;
      }
    }
  }

  Future<Directory> _getDownloadsDirectory() async {
    Directory? directory;
    try {
      if (Platform.isWindows) {
        directory = Directory('${Platform.environment['USERPROFILE']}\\Downloads');
      } else if (Platform.isAndroid) {
        directory = await getExternalStorageDirectory();
      } else {
        directory = await getApplicationDocumentsDirectory();
      }
    } catch (e) {
      directory = await getTemporaryDirectory();
    }

    directory ??= await getTemporaryDirectory();
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  void _openExportedFile() async {
    try {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File downloaded to your device')),
        );
        return;
      }

      final file = File(exportedFilePath);
      if (await file.exists()) {
        if (Platform.isWindows) {
          await Process.run('explorer.exe', [path.dirname(exportedFilePath)]);
        } else if (Platform.isAndroid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('File saved to downloads folder')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File not found'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString().split('\n')[0]}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}