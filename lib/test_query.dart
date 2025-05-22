import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class TestQuery extends StatefulWidget {
  const TestQuery({super.key});

  @override
  _TestQueryState createState() => _TestQueryState();
}

class _TestQueryState extends State<TestQuery> {
  bool isLoading = true;
  String result = '';
  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _runTest();
  }

  Future<void> _runTest() async {
    setState(() {
      isLoading = true;
      result = 'Running query test...';
    });

    try {
      // Test daily transactions query
      final startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      
      final snapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .get();

      // Build result text
      StringBuffer buffer = StringBuffer();
      buffer.writeln('Query for ${DateFormat('yyyy-MM-dd').format(selectedDate)}');
      buffer.writeln('Found ${snapshot.docs.length} transactions');
      buffer.writeln('---------------------------------------');
      
      double totalCredits = 0;
      double totalRecovery = 0;
      
      // Display each transaction
      for (var doc in snapshot.docs) {
        final data = doc.data();
        final amountTaken = data['amount_taken'] is num ? (data['amount_taken'] as num).toDouble() : 0.0;
        final amountPaid = data['amount_paid'] is num ? (data['amount_paid'] as num).toDouble() : 0.0;
        final customerName = data['customer_name'] ?? 'Unknown';
        
        buffer.writeln('Transaction ID: ${doc.id}');
        buffer.writeln('Customer: $customerName');
        buffer.writeln('Amount Taken: $amountTaken');
        buffer.writeln('Amount Paid: $amountPaid');
        buffer.writeln('---------------------------------------');
        
        totalCredits += amountTaken;
        totalRecovery += amountPaid;
      }
      
      buffer.writeln('\nTOTAL CREDITS: $totalCredits');
      buffer.writeln('TOTAL RECOVERY: $totalRecovery');
      
      // Also check customers
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();
      
      buffer.writeln('\nFound ${customersSnapshot.docs.length} customers');
      buffer.writeln('---------------------------------------');
      
      double totalBalance = 0;
      for (var doc in customersSnapshot.docs) {
        final data = doc.data();
        final name = data['name'] ?? 'Unknown';
        final balance = data['balance'] is num ? (data['balance'] as num).toDouble() : 0.0;
        
        buffer.writeln('Customer: $name');
        buffer.writeln('Balance: $balance');
        buffer.writeln('---------------------------------------');
        
        totalBalance += balance;
      }
      
      buffer.writeln('\nTOTAL RECEIVABLE: $totalBalance');
      
      setState(() {
        result = buffer.toString();
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        result = 'Error running test: $e';
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Query Test'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runTest,
          ),
          IconButton(
            icon: const Icon(Icons.date_range),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: selectedDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null && picked != selectedDate) {
                setState(() {
                  selectedDate = picked;
                });
                _runTest();
              }
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                child: SelectableText(
                  result,
                  style: const TextStyle(fontFamily: 'Courier', fontSize: 14),
                ),
              ),
      ),
    );
  }
} 