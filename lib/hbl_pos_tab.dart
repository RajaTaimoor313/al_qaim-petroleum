import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class HBLPointOfSale extends StatefulWidget {
  const HBLPointOfSale({super.key});

  @override
  State<HBLPointOfSale> createState() => _HBLPointOfSaleState();
}

class _HBLPointOfSaleState extends State<HBLPointOfSale> {
  bool isAddingSale = false;
  bool isViewingSales = true;
  bool isViewingSettlements = false;
  String searchQuery = '';
  final TextEditingController dateController = TextEditingController();
  final TextEditingController amountController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController amountReceivedController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  
  // Settlement related state
  Set<String> selectedSales = {};
  bool isSettlementMode = false;
  Set<String> settledSales = {}; // Track which sales have been settled

  // Indian Numbering System formatter
  String formatIndianNumber(double number) {
    final formatter = NumberFormat('#,##,##,##,##0.00', 'en_IN');
    return formatter.format(number);
  }

  @override
  void dispose() {
    dateController.dispose();
    amountController.dispose();
    searchController.dispose();
    amountReceivedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double padding = isMobile ? 12.0 : 16.0;
    final double borderRadius = isMobile ? 12.0 : 15.0;
    final double buttonSpacing = isMobile ? 8.0 : 10.0;
    final double titleFontSize = isMobile ? 20.0 : 24.0;
    final double buttonTextFontSize = isMobile ? 12.0 : 14.0;

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HBL Point of Sale',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isMobile)
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                isAddingSale = true;
                                isViewingSales = false;
                                isViewingSettlements = false;
                                _clearForm();
                              }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isAddingSale
                            ? Colors.green.shade700
                            : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 20),
                      label: Text(
                        'Add Sale',
                        style: TextStyle(fontSize: buttonTextFontSize),
                      ),
                    ),
                    SizedBox(width: buttonSpacing),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                isAddingSale = false;
                                isViewingSales = true;
                                isViewingSettlements = false;
                                selectedSales.clear();
                                isSettlementMode = false;
                              }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isViewingSales
                            ? Colors.green.shade700
                            : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.receipt_long, size: 20),
                      label: Text(
                        'View Sales',
                        style: TextStyle(fontSize: buttonTextFontSize),
                      ),
                    ),
                    SizedBox(width: buttonSpacing),
                    ElevatedButton.icon(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                isAddingSale = false;
                                isViewingSales = false;
                                isViewingSettlements = true;
                                selectedSales.clear();
                                isSettlementMode = false;
                              }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isViewingSettlements
                            ? Colors.green.shade700
                            : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.account_balance_wallet, size: 20),
                      label: Text(
                        'View Settlements',
                        style: TextStyle(fontSize: buttonTextFontSize),
                      ),
                    ),
                  ],
                ),
              if (isMobile)
                Row(
                  children: [
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                isAddingSale = true;
                                isViewingSales = false;
                                isViewingSettlements = false;
                                _clearForm();
                              }),
                      icon: Icon(
                        Icons.add_shopping_cart,
                        color: isAddingSale
                            ? Colors.green.shade700
                            : Colors.green,
                      ),
                      tooltip: 'Add Sale',
                    ),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                isAddingSale = false;
                                isViewingSales = true;
                                isViewingSettlements = false;
                                selectedSales.clear();
                                isSettlementMode = false;
                              }),
                      icon: Icon(
                        Icons.receipt_long,
                        color: isViewingSales
                            ? Colors.green.shade700
                            : Colors.green,
                      ),
                      tooltip: 'View Sales',
                    ),
                    IconButton(
                      onPressed: _isLoading
                          ? null
                          : () => setState(() {
                                isAddingSale = false;
                                isViewingSales = false;
                                isViewingSettlements = true;
                                selectedSales.clear();
                                isSettlementMode = false;
                              }),
                      icon: Icon(
                        Icons.account_balance_wallet,
                        color: isViewingSettlements
                            ? Colors.green.shade700
                            : Colors.green,
                      ),
                      tooltip: 'View Settlements',
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: isMobile ? 12.0 : 20.0),
          if (isAddingSale)
            Expanded(child: _buildAddSaleForm(isMobile)),
          if (isViewingSales) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search sales by date...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: isMobile ? 8.0 : 12.0,
                        horizontal: isMobile ? 12.0 : 16.0,
                      ),
                    ),
                    onChanged: (value) =>
                        setState(() => searchQuery = value.toLowerCase()),
                  ),
                ),
                SizedBox(width: isMobile ? 8.0 : 12.0),
                ElevatedButton(
                  onPressed: selectedSales.isEmpty ? null : () => _showSettlementDialog(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: selectedSales.isEmpty ? Colors.grey : Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12.0 : 16.0,
                      vertical: isMobile ? 8.0 : 10.0,
                    ),
                  ),
                  child: Text(
                    'Settlement',
                    style: TextStyle(fontSize: buttonTextFontSize),
                  ),
                ),
                SizedBox(width: isMobile ? 8.0 : 12.0),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? 12.0 : 16.0,
                      vertical: isMobile ? 8.0 : 10.0,
                    ),
                  ),
                  child: Text(
                    'Refresh',
                    style: TextStyle(fontSize: buttonTextFontSize),
                  ),
                ),
              ],
            ),
            SizedBox(height: isMobile ? 12.0 : 16.0),
            _buildSalesList(isMobile),
          ],
          if (isViewingSettlements) ...[
            SizedBox(height: isMobile ? 12.0 : 16.0),
            _buildSettlementsList(isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildAddSaleForm(bool isMobile) {
    final double spacing = isMobile ? 12.0 : 16.0;

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: spacing * 1.5),
            TextFormField(
              controller: dateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
                suffixIcon: const Icon(Icons.calendar_today),
              ),
              onTap: () async {
                final DateTime? picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2030),
                );
                if (picked != null) {
                  setState(() {
                    dateController.text = '${picked.day}/${picked.month}/${picked.year}';
                  });
                }
              },
              validator: (value) =>
                  value!.isEmpty ? 'Please select a date' : null,
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Please enter amount';
                final amount = double.tryParse(value);
                if (amount == null) return 'Invalid number';
                if (amount < 0) return 'Amount must be non-negative';
                return null;
              },
            ),
            SizedBox(height: spacing + 4.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitSaleForm,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: isMobile ? 24.0 : 32.0,
                    vertical: isMobile ? 10.0 : 12.0,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Submit Sale',
                        style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                      ),
              ),
            ),
            SizedBox(height: spacing * 4),
          ],
        ),
      ),
    );
  }

  Widget _buildSalesList(bool isMobile) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hbl_sales').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}\nEnsure your device has internet access.',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No sales found',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          // Get all sales and filter by search
          final allSales = snapshot.data!.docs.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final date = data['date']?.toLowerCase() ?? '';
            return date.contains(searchQuery);
          }).toList();

          // Get settled sales from settlements collection using StreamBuilder
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('hbl_settlements').snapshots(),
            builder: (context, settlementsSnapshot) {
              Set<String> settledSaleIds = {};
              
              if (settlementsSnapshot.hasData) {
                for (var settlement in settlementsSnapshot.data!.docs) {
                  final data = settlement.data() as Map<String, dynamic>;
                  final selectedSales = data['selected_sales'] as List<dynamic>? ?? [];
                  settledSaleIds.addAll(selectedSales.cast<String>());
                }
              }

              // Separate sales into settled and unsettled
              List<DocumentSnapshot> unsettledSales = [];
              List<DocumentSnapshot> settledSales = [];

              for (var sale in allSales) {
                if (settledSaleIds.contains(sale.id)) {
                  settledSales.add(sale);
                } else {
                  unsettledSales.add(sale);
                }
              }

              return ListView(
                children: [
                  // Unsettled Sales Section
                  if (unsettledSales.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12.0 : 16.0,
                        vertical: isMobile ? 8.0 : 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.pending, color: Colors.orange.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Unsettled Sales (${unsettledSales.length})',
                            style: TextStyle(
                              fontSize: isMobile ? 16.0 : 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    ...unsettledSales.asMap().entries.map((entry) {
                      final index = entry.key;
                      final sale = entry.value;
                      return _buildSaleCard(sale, index, unsettledSales.length, isMobile, false);
                    }).toList(),
                    SizedBox(height: 16),
                  ],
                  
                  // Settled Sales Section
                  if (settledSales.isNotEmpty) ...[
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 12.0 : 16.0,
                        vertical: isMobile ? 8.0 : 12.0,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle, color: Colors.green.shade700),
                          SizedBox(width: 8),
                          Text(
                            'Settled Sales (${settledSales.length})',
                            style: TextStyle(
                              fontSize: isMobile ? 16.0 : 18.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    ...settledSales.asMap().entries.map((entry) {
                      final index = entry.key;
                      final sale = entry.value;
                      return _buildSaleCard(sale, index, settledSales.length, isMobile, true);
                    }).toList(),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildSaleCard(DocumentSnapshot sale, int index, int totalLength, bool isMobile, bool isSettled) {
    final data = sale.data() as Map<String, dynamic>;
    final amount = data['amount']?.toDouble() ?? 0.0;

    return Card(
      margin: EdgeInsets.symmetric(vertical: isMobile ? 4.0 : 8.0),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.symmetric(
          vertical: isMobile ? 8.0 : 16.0,
          horizontal: isMobile ? 12.0 : 16.0,
        ),
        leading: isSettled 
          ? Icon(Icons.check_circle, color: Colors.green, size: 24)
          : Checkbox(
              value: selectedSales.contains(sale.id),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    selectedSales.add(sale.id);
                  } else {
                    selectedSales.remove(sale.id);
                  }
                });
              },
              activeColor: Colors.green,
            ),
        title: Text(
          'Sale #${totalLength - index}',
          style: TextStyle(
            fontSize: isMobile ? 16.0 : 20.0,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'Date: ${data['date'] ?? 'N/A'}',
              style: TextStyle(
                fontSize: isMobile ? 12.0 : 14.0,
                color: Colors.grey.shade700,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Amount: Rs. ${formatIndianNumber(amount)}',
              style: TextStyle(
                fontSize: isMobile ? 12.0 : 14.0,
                fontWeight: FontWeight.bold,
                color: isSettled ? Colors.green : Colors.orange,
              ),
            ),
            if (isSettled) ...[
              SizedBox(height: 2),
              Text(
                'Status: Settled',
                style: TextStyle(
                  fontSize: isMobile ? 10.0 : 12.0,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
        trailing: data['timestamp'] != null
            ? Text(
                _formatDate(data['timestamp'] as Timestamp),
                style: TextStyle(
                  fontSize: isMobile ? 10.0 : 12.0,
                  color: Colors.grey.shade600,
                ),
              )
            : const Text('N/A'),
      ),
    );
  }

  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _submitSaleForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final date = dateController.text.trim();
        final amount = double.parse(amountController.text.trim());

        await FirebaseFirestore.instance.collection('hbl_sales').add({
          'date': date,
          'amount': amount,
          'timestamp': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
        setState(() {
          isAddingSale = false;
          isViewingSales = true;
          _isLoading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error adding sale: $e'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    dateController.clear();
    amountController.clear();
  }

  Future<void> _showSettlementDialog(BuildContext context) async {
    // Calculate total amount of selected sales
    double totalAmount = 0.0;
    List<String> selectedSaleDates = [];
    
    final salesQuery = await FirebaseFirestore.instance
        .collection('hbl_sales')
        .where(FieldPath.documentId, whereIn: selectedSales.toList())
        .get();
    
    for (var doc in salesQuery.docs) {
      final data = doc.data();
      totalAmount += (data['amount'] ?? 0.0);
      selectedSaleDates.add(data['date'] ?? 'N/A');
    }
    
    amountReceivedController.clear();
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Create Settlement'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Selected Sales: ${selectedSaleDates.join(', ')}'),
              const SizedBox(height: 8),
              Text('Total Amount: Rs. ${formatIndianNumber(totalAmount)}'),
              const SizedBox(height: 16),
              TextField(
                controller: amountReceivedController,
                decoration: const InputDecoration(
                  labelText: 'Amount Received',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final amountReceived = double.tryParse(amountReceivedController.text) ?? 0.0;
                final expenses = totalAmount - amountReceived;
                Navigator.of(context).pop({
                  'totalAmount': totalAmount,
                  'amountReceived': amountReceived,
                  'expenses': expenses,
                  'selectedSaleDates': selectedSaleDates,
                  'selectedSaleIds': selectedSales.toList(),
                });
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    
    if (result != null) {
      await _createSettlement(result);
    }
  }
  
  Future<void> _createSettlement(Map<String, dynamic> settlementData) async {
    try {
      await FirebaseFirestore.instance.collection('hbl_settlements').add({
        'settlement_date': DateTime.now(),
        'selected_sales': settlementData['selectedSaleIds'],
        'selected_sale_dates': settlementData['selectedSaleDates'],
        'total_amount': settlementData['totalAmount'],
        'amount_received': settlementData['amountReceived'],
        'expenses': settlementData['expenses'],
        'timestamp': FieldValue.serverTimestamp(),
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settlement created successfully'),
          backgroundColor: Colors.green,
        ),
      );
      
      setState(() {
        selectedSales.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating settlement: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildSettlementsList(bool isMobile) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('hbl_settlements').orderBy('timestamp', descending: true).snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}\nEnsure your device has internet access.',
                style: const TextStyle(color: Colors.red),
              ),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.account_balance_wallet_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No settlements found',
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: isMobile ? 16.0 : 18.0,
                    ),
                  ),
                ],
              ),
            );
          }

          final settlements = snapshot.data!.docs;

          if (isMobile) {
            // Mobile view - Card-based layout
            return ListView.builder(
              itemCount: settlements.length,
              itemBuilder: (context, index) {
                final data = settlements[index].data() as Map<String, dynamic>;
                final settlementDate = data['settlement_date'] != null
                    ? _formatDate(data['settlement_date'] as Timestamp)
                    : 'N/A';
                final sales = (data['selected_sale_dates'] as List<dynamic>?)?.join(', ') ?? 'N/A';
                final totalAmount = data['total_amount']?.toDouble() ?? 0.0;
                final amountReceived = data['amount_received']?.toDouble() ?? 0.0;
                final expenses = data['expenses']?.toDouble() ?? 0.0;

                return Card(
                  margin: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'Settlement #${settlements.length - index}',
                                style: TextStyle(
                                  fontSize: 14.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade800,
                                ),
                              ),
                            ),
                            Spacer(),
                            Icon(Icons.calendar_today, size: 16, color: Colors.grey.shade600),
                            SizedBox(width: 4),
                            Text(
                              settlementDate,
                              style: TextStyle(
                                fontSize: 12.0,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        _buildMobileSettlementRow('Sales Dates', sales, Icons.receipt),
                        SizedBox(height: 8),
                        _buildMobileSettlementRow('Total Amount', 'Rs. ${formatIndianNumber(totalAmount)}', Icons.account_balance_wallet),
                        SizedBox(height: 8),
                        _buildMobileSettlementRow('Amount Received', 'Rs. ${formatIndianNumber(amountReceived)}', Icons.payments),
                        SizedBox(height: 8),
                        _buildMobileSettlementRow(
                          'Expenses', 
                          'Rs. ${formatIndianNumber(expenses)}', 
                          Icons.trending_down,
                          valueColor: expenses > 0 ? Colors.red : Colors.green,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            // Desktop view - Enhanced table
            return Container(
              margin: EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    spreadRadius: 1,
                    blurRadius: 5,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columnSpacing: 24.0,
                  dataTextStyle: TextStyle(fontSize: 14.0),
                  headingTextStyle: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                  headingRowColor: MaterialStateProperty.all(Colors.green.shade50),
                  border: TableBorder.all(
                    color: Colors.grey.shade200,
                    width: 1,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  columns: const [
                    DataColumn(label: Text('Settlement #')),
                    DataColumn(label: Text('Date')),
                    DataColumn(label: Text('Sales Dates')),
                    DataColumn(label: Text('Total Amount')),
                    DataColumn(label: Text('Amount Received')),
                    DataColumn(label: Text('Expenses')),
                  ],
                  rows: settlements.asMap().entries.map((entry) {
                    final index = entry.key;
                    final data = entry.value.data() as Map<String, dynamic>;
                    final settlementDate = data['settlement_date'] != null
                        ? _formatDate(data['settlement_date'] as Timestamp)
                        : 'N/A';
                    final sales = (data['selected_sale_dates'] as List<dynamic>?)?.join(', ') ?? 'N/A';
                    final totalAmount = data['total_amount']?.toDouble() ?? 0.0;
                    final amountReceived = data['amount_received']?.toDouble() ?? 0.0;
                    final expenses = data['expenses']?.toDouble() ?? 0.0;

                    return DataRow(
                      color: MaterialStateProperty.all(
                        index % 2 == 0 ? Colors.grey.shade50 : Colors.white,
                      ),
                      cells: [
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Settlement #${settlements.length - index}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade800,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(settlementDate)),
                        DataCell(
                          Container(
                            constraints: BoxConstraints(maxWidth: 400.0),
                            child: Text(
                              sales,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            'Rs. ${formatIndianNumber(totalAmount)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Text(
                            'Rs. ${formatIndianNumber(amountReceived)}',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: expenses > 0 ? Colors.red.shade100 : Colors.green.shade100,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Rs. ${formatIndianNumber(expenses)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: expenses > 0 ? Colors.red.shade800 : Colors.green.shade800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            );
          }
        },
      ),
    );
  }

  Widget _buildMobileSettlementRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade600),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12.0,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14.0,
                  fontWeight: FontWeight.bold,
                  color: valueColor ?? Colors.black87,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
} 