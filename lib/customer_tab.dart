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
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    nameController.dispose();
    phoneController.dispose();
    balanceController.dispose();
    addressController.dispose();
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
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
              const Text(
                'Customers',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
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
                    label: const Text('Add Customer'),
                  ),
                  const SizedBox(width: 10),
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
                    label: const Text('View Customers'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          if (isAddingCustomer) _buildAddCustomerForm(),
          if (isViewingCustomers) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Refresh'),
                ),
              ],
            ),
            _buildViewCustomers(isMobile),
          ],
        ],
      ),
    );
  }

  Widget _buildAddCustomerForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                (value) => value!.isEmpty ? 'Please enter customer name' : null,
          ),
          const SizedBox(height: 16),
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
          const SizedBox(height: 16),
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
              if (balance < -1000000 || balance > 1000000) {
                return 'Balance must be between -1,000,000 and 1,000,000';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: addressController,
            decoration: InputDecoration(
              labelText: 'Address',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            validator:
                (value) => value!.isEmpty ? 'Please enter address' : null,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitCustomerForm,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 32,
                  vertical: 12,
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
                      : const Text('Submit', style: TextStyle(fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewCustomers(bool isMobile) {
    return Expanded(
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search customers by name or phone...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged:
                (value) => setState(() => searchQuery = value.toLowerCase()),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection('customers')
                      .snapshots(),
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
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        title: Text(
                          data['name'],
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          data['phone'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => CustomerDetailsPage(
                                      customerId: customer.id,
                                    ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('View'),
                        ),
                      ),
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

  Future<void> _submitCustomerForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        print('Submitting customer form...');
        final name = nameController.text.trim();
        final phone = phoneController.text.trim();
        final address = addressController.text.trim();
        if (name.isEmpty || phone.isEmpty || address.isEmpty) {
          throw Exception('Name, phone, or address cannot be empty');
        }
        print('Adding customer: name=$name, phone=$phone, address=$address, balance=${double.parse(balanceController.text.trim())}');
        final docId =
            FirebaseFirestore.instance.collection('customers').doc().id;
        final docRef = FirebaseFirestore.instance
            .collection('customers')
            .doc(docId);

        await docRef.set({
          'name': name,
          'name_lower': name.toLowerCase(),
          'phone': phone,
          'balance': double.parse(balanceController.text.trim()),
          'address': address,
          'created_at': FieldValue.serverTimestamp(),
        });

        final snapshot = await docRef.get();
        print('Written data: ${snapshot.data()}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Customer added successfully with ID: $docId'),
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
        print('Error in _submitCustomerForm: $e');
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
  }
}

class CustomerDetailsPage extends StatelessWidget {
  final String customerId;

  const CustomerDetailsPage({super.key, required this.customerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Details'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
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
              print('Error fetching customer details: ${snapshot.error}');
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

            final customer = snapshot.data!.data() as Map<String, dynamic>;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundColor: Colors.green,
                              child: Text(
                                customer['name'][0].toUpperCase(),
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    customer['name'],
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Customer ID: $customerId',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _buildInfoRow(Icons.phone, 'Phone', customer['phone']),
                        _buildInfoRow(
                          Icons.home,
                          'Address',
                          customer['address'],
                        ),
                        _buildInfoRow(
                          Icons.account_balance_wallet,
                          'Balance',
                          customer['balance'].toString(),
                          valueColor:
                              customer['balance'] >= 0
                                  ? Colors.green
                                  : Colors.red,
                        ),
                        _buildInfoRow(
                          Icons.calendar_today,
                          'Created',
                          customer['created_at'] != null
                              ? DateFormat('dd/MM/yyyy').format(
                                    (customer['created_at'] as Timestamp).toDate(),
                                  )
                              : 'N/A',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Transaction History',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream:
                        FirebaseFirestore.instance
                            .collection('transactions')
                            .where('customer_id', isEqualTo: customerId)
                            .orderBy('date', descending: true)
                            .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (snapshot.hasError) {
                        print('Error fetching transactions: ${snapshot.error}');
                        return Center(
                          child: Text(
                            'Error: ${snapshot.error}\nEnsure your device has internet access.',
                            style: const TextStyle(color: Colors.red),
                          ),
                        );
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.history, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No transaction history found',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        );
                      }

                      final transactions = snapshot.data!.docs;

                      return ListView.builder(
                        itemCount: transactions.length,
                        itemBuilder: (context, index) {
                          final transaction =
                              transactions[index].data()
                                  as Map<String, dynamic>;
                          final date =
                              (transaction['date'] as Timestamp).toDate();
                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              title: Text(
                                'Date: ${DateFormat('dd/MM/yyyy').format(date)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Amount Paid: ${transaction['amount_paid']}',
                                  ),
                                  Text(
                                    'Amount Taken: ${transaction['amount_taken']}',
                                  ),
                                  Text(
                                    'New Balance: ${transaction['new_balance']}',
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.green),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 16, color: valueColor ?? Colors.black),
          ),
        ],
      ),
    );
  }
}