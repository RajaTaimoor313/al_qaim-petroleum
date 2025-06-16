// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Customers extends StatefulWidget {
  const Customers({super.key});

  @override
  State<Customers> createState() => _CustomersState();
}

class _CustomersState extends State<Customers> {
  bool isAddingCustomer = false;
  bool isViewingCustomers = true;
  String searchQuery = '';
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController addressController = TextEditingController();
  final TextEditingController searchController = TextEditingController();
  final TextEditingController pageNumberController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    balanceController.dispose();
    addressController.dispose();
    searchController.dispose();
    pageNumberController.dispose();
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
                'Customers',
                style: TextStyle(
                  fontSize: titleFontSize,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (!isMobile) // Use regular buttons in desktop
                Row(
                  children: [
                    ElevatedButton.icon(
                      onPressed:
                          _isLoading
                              ? null
                              : () => setState(() {
                                isAddingCustomer = true;
                                isViewingCustomers = false;
                                _clearForm();
                              }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isAddingCustomer
                                ? Colors.green.shade700
                                : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.person_add, size: 20),
                      label: Text(
                        'Add Customer',
                        style: TextStyle(fontSize: buttonTextFontSize),
                      ),
                    ),
                    SizedBox(width: buttonSpacing),
                    ElevatedButton.icon(
                      onPressed:
                          _isLoading
                              ? null
                              : () => setState(() {
                                isAddingCustomer = false;
                                isViewingCustomers = true;
                              }),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isViewingCustomers
                                ? Colors.green.shade700
                                : Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: const Icon(Icons.people, size: 20),
                      label: Text(
                        'View Customers',
                        style: TextStyle(fontSize: buttonTextFontSize),
                      ),
                    ),
                  ],
                ),
              if (isMobile) // Use icon buttons in mobile
                Row(
                  children: [
                    IconButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () => setState(() {
                                isAddingCustomer = true;
                                isViewingCustomers = false;
                                _clearForm();
                              }),
                      icon: Icon(
                        Icons.person_add,
                        color:
                            isAddingCustomer
                                ? Colors.green.shade700
                                : Colors.green,
                      ),
                      tooltip: 'Add Customer',
                    ),
                    IconButton(
                      onPressed:
                          _isLoading
                              ? null
                              : () => setState(() {
                                isAddingCustomer = false;
                                isViewingCustomers = true;
                              }),
                      icon: Icon(
                        Icons.people,
                        color:
                            isViewingCustomers
                                ? Colors.green.shade700
                                : Colors.green,
                      ),
                      tooltip: 'View Customers',
                    ),
                  ],
                ),
            ],
          ),
          SizedBox(height: isMobile ? 12.0 : 20.0),
          if (isAddingCustomer)
            Expanded(child: _buildAddCustomerForm(isMobile)),
          if (isViewingCustomers) ...[
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search customers by name or phone...',
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
                    onChanged:
                        (value) =>
                            setState(() => searchQuery = value.toLowerCase()),
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
            _buildCustomersList(isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildAddCustomerForm(bool isMobile) {
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
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              validator:
                  (value) =>
                      value!.isEmpty ? 'Please enter customer name' : null,
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.phone,
              validator:
                  (value) =>
                      value!.isEmpty
                          ? 'Please enter phone number'
                          : (RegExp(r'^\d{10,}$').hasMatch(value)
                              ? null
                              : 'Invalid phone number'),
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: balanceController,
              decoration: InputDecoration(
                labelText: 'Previous Balance',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Please enter previous balance';
                final balance = double.tryParse(value);
                if (balance == null) return 'Invalid number';
                if (balance < 0) {
                  return 'Balance must be a Positive Value';
                }
                return null;
              },
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: addressController,
              decoration: InputDecoration(
                labelText: 'CNIC',
                hintText: '13-digit CNIC number (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              // Making CNIC field optional
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Optional field
                }
                // If provided, validate it has 13 digits
                if (!RegExp(r'^\d{13}$').hasMatch(value)) {
                  return 'CNIC should have 13 digits';
                }
                return null;
              },
            ),
            SizedBox(height: spacing),
            TextFormField(
              controller: pageNumberController,
              decoration: InputDecoration(
                labelText: 'Page Number',
                hintText: 'Enter page number in register (optional)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              keyboardType: TextInputType.number,
              // Making Page Number field optional
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return null; // Optional field
                }
                // If provided, validate it's a number
                if (!RegExp(r'^\d+$').hasMatch(value)) {
                  return 'Page Number should be a valid number';
                }
                return null;
              },
            ),
            SizedBox(height: spacing + 4.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submitCustomerForm,
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
                child:
                    _isLoading
                        ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                        : Text(
                          'Submit',
                          style: TextStyle(fontSize: isMobile ? 14.0 : 16.0),
                        ),
              ),
            ),
            // Add padding below submit button for any device
            SizedBox(height: spacing * 4),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomersList(bool isMobile) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('customers').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            print('Error fetching customers: ${snapshot.error}');
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
                'No customers found',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            );
          }

          final customers =
              snapshot.data!.docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final name =
                    data['name_lower']?.toLowerCase() ??
                    data['name']?.toLowerCase() ??
                    '';
                final phone = data['phone']?.toLowerCase() ?? '';
                return name.contains(searchQuery) ||
                    phone.contains(searchQuery);
              }).toList();

          return ListView.builder(
            itemCount: customers.length,
            itemBuilder: (context, index) {
              final customer = customers[index];
              final data = customer.data() as Map<String, dynamic>;
              final balance =
                  data['balance'] is num
                      ? (data['balance'] as num).toDouble()
                      : 0.0;

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
                  title: Text(
                    data['name'],
                    style: TextStyle(
                      fontSize: isMobile ? 16.0 : 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Balance: ',
                            style: TextStyle(
                              fontSize: isMobile ? 12.0 : 14.0,
                              color: Colors.black,
                            ),
                          ),
                          Text(
                            'Rs. ${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isMobile ? 12.0 : 14.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (context) =>
                                  CustomerDetailsPage(customerId: customer.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 8.0 : 12.0,
                        vertical: isMobile ? 4.0 : 8.0,
                      ),
                    ),
                    child: Text(
                      'View',
                      style: TextStyle(fontSize: isMobile ? 12.0 : 14.0),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _submitCustomerForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final name = nameController.text.trim();
        final phone = phoneController.text.trim();
        final cnic = addressController.text.trim();
        final pageNumber = pageNumberController.text.trim();
        if (name.isEmpty || phone.isEmpty) {
          throw Exception('Name or phone cannot be empty');
        }
        
        final docId = FirebaseFirestore.instance.collection('customers').doc().id;
        final docRef = FirebaseFirestore.instance
            .collection('customers')
            .doc(docId);

        // Create a batch write to ensure atomicity
        final batch = FirebaseFirestore.instance.batch();
        
        // Add the customer document
        batch.set(docRef, {
          'name': name,
          'name_lower': name.toLowerCase(),
          'phone': phone,
          'balance': double.parse(balanceController.text.trim()),
          'cnic': cnic,
          'page_number': pageNumber,
          'created_at': FieldValue.serverTimestamp(),
        });

        // Add an initial transaction record if there's a previous balance
        final initialBalance = double.parse(balanceController.text.trim());
        if (initialBalance > 0) {
          final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
          batch.set(transactionRef, {
            'customer_id': docId,
            'customer_name': name,
            'phone': phone,
            'previous_balance': initialBalance,
            'amount_taken': 0.0,
            'amount_paid': 0.0,
            'new_balance': initialBalance,
            'date': FieldValue.serverTimestamp(),
          });
        }

        // Commit the batch
        await batch.commit();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer added successfully'),
            backgroundColor: Colors.green,
          ),
        );
        _clearForm();
        setState(() {
          isAddingCustomer = false;
          isViewingCustomers = true;
          _isLoading = false;
        });
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error adding customer: $e\nEnsure your device has internet access. Try updating the Firestore plugin.',
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  void _clearForm() {
    nameController.clear();
    phoneController.clear();
    balanceController.clear();
    addressController.clear();
    pageNumberController.clear();
  }
}

class CustomerDetailsPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double padding = isMobile ? 12.0 : 16.0;
    final double cardPadding = isMobile ? 12.0 : 16.0;
    final double titleFontSize = isMobile ? 20.0 : 24.0;
    final double headerFontSize = isMobile ? 18.0 : 20.0;
    final double avatarRadius = isMobile ? 24.0 : 30.0;
    final double spacing = isMobile ? 12.0 : 16.0;
    final double dividerHeight = isMobile ? 16.0 : 24.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Customer Details',
          style: TextStyle(fontSize: isMobile ? 18.0 : 20.0),
        ),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(padding),
        child: StreamBuilder<DocumentSnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('customers')
                  .doc(customerId)
                  .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              print(
                'Error fetching customer details: ${snapshot.error}',
              );
              return Center(
                child: Text(
                  'Error: ${snapshot.error}\nEnsure your device has internet access.',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const Center(
                child: Text(
                  'Customer not found',
                  style: TextStyle(color: Colors.grey),
                ),
              );
            }

            final customer =
                snapshot.data!.data() as Map<String, dynamic>;

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('transactions')
                  .where('customer_id', isEqualTo: customerId)
                  .orderBy('custom_date', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, transactionSnapshot) {
                if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (transactionSnapshot.hasError) {
                  return Center(
                    child: Text(
                      'Error: ${transactionSnapshot.error}\nEnsure your device has internet access.',
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }

                double displayBalance = customer['balance']?.toDouble() ?? 0.0;
                Color balanceColor = displayBalance >= 0 ? Colors.green : Colors.red;

                if (transactionSnapshot.hasData && transactionSnapshot.data!.docs.isNotEmpty) {
                  final transactions = transactionSnapshot.data!.docs;
                  final latestTransaction = transactions.first.data() as Map<String, dynamic>;
                  displayBalance = latestTransaction['new_balance']?.toDouble() ?? displayBalance;
                  balanceColor = displayBalance >= 0 ? Colors.green : Colors.red;
                }

                return SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(cardPadding),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  CircleAvatar(
                                    radius: avatarRadius,
                                    backgroundColor: Colors.green,
                                    child: Text(
                                      customer['name'][0].toUpperCase(),
                                      style: TextStyle(
                                        fontSize: avatarRadius * 0.8,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: spacing),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          customer['name'],
                                          style: TextStyle(
                                            fontSize: titleFontSize,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              Divider(height: dividerHeight),
                              _buildInfoRow(
                                Icons.phone,
                                'Phone',
                                customer['phone'],
                                isMobile: isMobile,
                              ),
                              _buildInfoRow(
                                Icons.credit_card,
                                'CNIC',
                                customer['cnic'] ?? 'N/A',
                                isMobile: isMobile,
                              ),
                              _buildInfoRow(
                                Icons.book,
                                'Page Number',
                                customer['page_number'] ?? 'N/A',
                                isMobile: isMobile,
                              ),
                              _buildInfoRow(
                                Icons.account_balance_wallet,
                                'Balance',
                                'Rs. ${displayBalance.toStringAsFixed(2)}',
                                valueColor: balanceColor,
                                isMobile: isMobile,
                              ),
                              _buildInfoRow(
                                Icons.calendar_today,
                                'Created',
                                customer['created_at'] != null
                                    ? DateFormat('dd/MM/yyyy').format(
                                      (customer['created_at'] as Timestamp).toDate(),
                                    )
                                    : 'N/A',
                                isMobile: isMobile,
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: spacing + 4.0),
                      Text(
                        'Transaction History',
                        style: TextStyle(
                          fontSize: headerFontSize,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: spacing),
                      if (transactionSnapshot.hasData && transactionSnapshot.data!.docs.isNotEmpty)
                        _buildTransactionsList(
                          transactionSnapshot.data!.docs,
                          isMobile,
                        )
                      else
                        Center(
                          child: Text(
                            'No transactions found',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: isMobile ? 14.0 : 16.0,
                            ),
                          ),
                        ),
                      SizedBox(height: spacing), // Add bottom padding
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    IconData icon,
    String label,
    String value, {
    Color? valueColor,
    bool isMobile = false,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: isMobile ? 4.0 : 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green, size: isMobile ? 16.0 : 20.0),
          SizedBox(width: isMobile ? 4.0 : 8.0),
          Text(
            '$label: ',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 14.0 : 16.0,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 14.0 : 16.0,
              color: valueColor ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionsList(List<DocumentSnapshot> transactions, bool isMobile) {
    return Column(
      children: List.generate(
        transactions.length,
        (index) {
          final transaction = transactions[index].data() as Map<String, dynamic>;
          final date = (transaction['custom_date'] as Timestamp).toDate();
          final amountPaid = transaction['amount_paid']?.toDouble() ?? 0.0;
          final amountTaken = transaction['amount_taken']?.toDouble() ?? 0.0;
          final newBalance = transaction['new_balance']?.toDouble() ?? 0.0;
          final previousBalance = transaction['previous_balance']?.toDouble() ?? 0.0;

          return Card(
            margin: EdgeInsets.symmetric(
              vertical: isMobile ? 8.0 : 12.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(10),
                      topRight: Radius.circular(10),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'Transaction #${transactions.length - index}',
                        style: TextStyle(
                          fontSize: isMobile ? 16.0 : 18.0,
                          fontWeight: FontWeight.bold,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        DateFormat('dd/MM/yyyy').format(date),
                        style: TextStyle(
                          fontSize: isMobile ? 14.0 : 16.0,
                          color: Colors.green.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTransactionRow(
                        'Previous Balance',
                        'Rs. ${previousBalance.toStringAsFixed(2)}',
                        Colors.grey.shade700,
                        isMobile,
                      ),
                      SizedBox(height: isMobile ? 8.0 : 12.0),
                      _buildTransactionRow(
                        'Amount Paid',
                        'Rs. ${amountPaid.toStringAsFixed(2)}',
                        Colors.green,
                        isMobile,
                      ),
                      SizedBox(height: isMobile ? 8.0 : 12.0),
                      _buildTransactionRow(
                        'Amount Taken',
                        'Rs. ${amountTaken.toStringAsFixed(2)}',
                        Colors.red,
                        isMobile,
                      ),
                      SizedBox(height: isMobile ? 8.0 : 12.0),
                      Divider(color: Colors.grey.shade300),
                      SizedBox(height: isMobile ? 8.0 : 12.0),
                      _buildTransactionRow(
                        'New Balance',
                        'Rs. ${newBalance.toStringAsFixed(2)}',
                        newBalance >= 0 ? Colors.green : Colors.red,
                        isMobile,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTransactionRow(String label, String value, Color valueColor, bool isMobile, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isMobile ? 14.0 : 16.0,
            color: Colors.grey.shade700,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isMobile ? 14.0 : 16.0,
            color: valueColor,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
