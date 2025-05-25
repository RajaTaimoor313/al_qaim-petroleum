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
                      icon:
                          isExporting
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
                        color:
                            hasError
                                ? Colors.red.shade700
                                : Colors.green.shade700,
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
    setState(() {
      isExporting = true;
      statusMessage = 'Exporting data, please wait...';
      hasError = false;
      exportedFilePath = '';
    });

    try {
      final excelFile = excel.Excel.createExcel();

      // Excel.createExcel() automatically creates Sheet1
      // Use the existing Sheet1 to create our custom sheets
      if (excelFile.sheets.containsKey('Sheet1')) {
        // Create custom sheets by copying Sheet1
        excelFile.copy('Sheet1', 'Customers');
        excelFile.copy('Sheet1', 'Transactions');
        excelFile.copy('Sheet1', 'Sales');

        // Now we can delete the original Sheet1
        excelFile.delete('Sheet1');
      }

      final customersSheet = excelFile['Customers'];
      final transactionsSheet = excelFile['Transactions'];
      final salesSheet = excelFile['Sales'];

      final customerHeaders = [
        'Name',
        'Phone',
        'CNIC',
        'Page Number',
        'Balance',
        'Created Date',
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
        'Petrol Amount (Rs)',
        'Diesel Litres',
        'Diesel Amount (Rs)',
        'Total Litres',
        'Total Amount (Rs)',
      ];

      final headerStyle = excel.CellStyle(
        bold: true,
        backgroundColorHex: excel.ExcelColor.fromHexString('#AED581'),
        horizontalAlign: excel.HorizontalAlign.Center,
      );

      for (var i = 0; i < customerHeaders.length; i++) {
        final cell = customersSheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = excel.TextCellValue(customerHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      for (var i = 0; i < transactionHeaders.length; i++) {
        final cell = transactionsSheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = excel.TextCellValue(transactionHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      for (var i = 0; i < salesHeaders.length; i++) {
        final cell = salesSheet.cell(
          excel.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
        );
        cell.value = excel.TextCellValue(salesHeaders[i]);
        cell.cellStyle = headerStyle;
      }

      final Future<QuerySnapshot> customersQuery =
          FirebaseFirestore.instance.collection('customers').get();
      final Future<QuerySnapshot> transactionsQuery =
          FirebaseFirestore.instance
              .collection('transactions')
              .orderBy('date', descending: true)
              .get();
      final Future<QuerySnapshot> salesQuery =
          FirebaseFirestore.instance
              .collection('sales')
              .orderBy('date', descending: true)
              .get();

      final results = await Future.wait([
        customersQuery,
        transactionsQuery,
        salesQuery,
      ]);

      final customersSnapshot = results[0];
      final transactionsSnapshot = results[1];
      final salesSnapshot = results[2];

      int customerRow = 1;
      for (var doc in customersSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> rowData = [
          data['name'] ?? '',
          data['phone'] ?? '',
          data['cnic'] ?? '',
          data['page_number'] ?? '',
          data['balance'] ?? 0.0,
          data['created_at'] != null
              ? DateFormat(
                'dd/MM/yyyy',
              ).format((data['created_at'] as Timestamp).toDate())
              : 'N/A',
        ];

        for (var i = 0; i < rowData.length; i++) {
          final cell = customersSheet.cell(
            excel.CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: customerRow,
            ),
          );
          cell.value = excel.TextCellValue(rowData[i].toString());
        }
        customerRow++;
      }

      int transactionRow = 1;
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final List<dynamic> rowData = [
          data['date'] != null
              ? DateFormat(
                'dd/MM/yyyy',
              ).format((data['date'] as Timestamp).toDate())
              : 'N/A',
          data['customer_name'] ?? '',
          data['phone'] ?? '',
          data['previous_balance'] ?? 0.0,
          data['amount_paid'] ?? 0.0,
          data['amount_taken'] ?? 0.0,
          data['new_balance'] ?? 0.0,
        ];

        for (var i = 0; i < rowData.length; i++) {
          final cell = transactionsSheet.cell(
            excel.CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: transactionRow,
            ),
          );
          cell.value = excel.TextCellValue(rowData[i].toString());
        }
        transactionRow++;
      }

      int salesRow = 1;
      for (var doc in salesSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final petrolLitres =
            data['petrol_litres'] is num
                ? (data['petrol_litres'] as num).toDouble()
                : 0.0;
        final dieselLitres =
            data['diesel_litres'] is num
                ? (data['diesel_litres'] as num).toDouble()
                : 0.0;
        final totalLitres = petrolLitres + dieselLitres;

        final List<dynamic> rowData = [
          data['date'] != null
              ? DateFormat(
                'dd/MM/yyyy',
              ).format((data['date'] as Timestamp).toDate())
              : 'N/A',
          petrolLitres,
          data['petrol_rupees'] ?? 0.0,
          dieselLitres,
          data['diesel_rupees'] ?? 0.0,
          totalLitres,
          data['total_amount'] ?? 0.0,
        ];

        for (var i = 0; i < rowData.length; i++) {
          final cell = salesSheet.cell(
            excel.CellIndex.indexByColumnRow(
              columnIndex: i,
              rowIndex: salesRow,
            ),
          );
          cell.value = excel.TextCellValue(rowData[i].toString());
        }
        salesRow++;
      }

      for (var sheet in excelFile.sheets.values) {
        for (var i = 0; i < 10; i++) {
          sheet.setColumnWidth(i, 20);
        }
      }

      final now = DateTime.now();
      final formattedDate = DateFormat('yyyy-MM-dd_HH-mm-ss').format(now);
      final fileName = 'Al_Qaim_Petroleum_exported_at_$formattedDate.xlsx';

      final fileBytes = excelFile.save();
      if (fileBytes == null) {
        throw Exception('Failed to generate Excel file');
      }

      if (kIsWeb) {
        final blob = html.Blob([
          Uint8List.fromList(fileBytes),
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);

        final anchor =
            html.AnchorElement(href: url)
              ..setAttribute('download', fileName)
              ..style.display = 'none';

        html.document.body?.children.add(anchor);
        anchor.click();

        html.document.body?.children.remove(anchor);
        html.Url.revokeObjectUrl(url);

        setState(() {
          isExporting = false;
          statusMessage = 'Excel file downloaded successfully!';
        });
      } else {
        final downloadsDir = await _getDownloadsDirectory();
        final filePath = path.join(downloadsDir.path, fileName);

        final file = File(filePath);
        await file.writeAsBytes(fileBytes);

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

  Future<Directory> _getDownloadsDirectory() async {
    Directory? directory;
    try {
      if (Platform.isWindows) {
        final home = Platform.environment['USERPROFILE']!;
        directory = Directory('$home\\Downloads');
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
          const SnackBar(
            content: Text('File should have been downloaded to your device'),
          ),
        );
        return;
      }

      final file = File(exportedFilePath);
      if (await file.exists()) {
        if (Platform.isWindows) {
          final folderPath = path.dirname(exportedFilePath);
          await Process.run('explorer.exe', [folderPath]);
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
