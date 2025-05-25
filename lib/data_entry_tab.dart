// ignore_for_file: avoid_print

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // For PlatformException
import 'package:intl/intl.dart';

class AddData extends StatefulWidget {
  const AddData({super.key});

  @override
  State<AddData> createState() => _AddDataState();
}

class _AddDataState extends State<AddData> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController customerNameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController balanceController = TextEditingController();
  final TextEditingController amountPaidController = TextEditingController();
  final TextEditingController amountTakenController = TextEditingController();
  final TextEditingController pageNumberController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String? selectedCustomerId;
  List<Map<String, dynamic>> customerSuggestions = [];
  bool isSearching = false;
  bool customerFound = false;
  String? errorMessage;

  // Added for the form type selection
  bool showTransactionForm = true;

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    balanceController.dispose();
    amountPaidController.dispose();
    amountTakenController.dispose();
    pageNumberController.dispose();
    petrolLitresController.dispose();
    petrolRupeesController.dispose();
    dieselLitresController.dispose();
    dieselRupeesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double horizontalPadding = isMobile ? 12.0 : 16.0;
    final double verticalPadding = isMobile ? 12.0 : 16.0;
    final double borderRadius = isMobile ? 12.0 : 15.0;
    final double fontSize = isMobile ? 20.0 : 24.0;
    final double spacing = isMobile ? 12.0 : 16.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: verticalPadding,
      ),
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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Add New Data',
              style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: spacing),

            // Form type selector
            Row(
              children: [
                Expanded(
                  flex: 10,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showTransactionForm = true;
                        _resetForm();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          showTransactionForm
                              ? Colors.green
                              : Colors.grey.shade300,
                      foregroundColor:
                          showTransactionForm ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add Transaction'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 10,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() {
                        showTransactionForm = false;
                        _resetForm();
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          !showTransactionForm
                              ? Colors.green
                              : Colors.grey.shade300,
                      foregroundColor:
                          !showTransactionForm ? Colors.white : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Add Sales'),
                  ),
                ),
              ],
            ),
            SizedBox(height: spacing + 4),

            // Show the appropriate form
            showTransactionForm
                ? _buildTransactionForm(spacing, isMobile)
                : _buildSalesForm(spacing, isMobile),
          ],
        ),
      ),
    );
  }

  // Transaction form extracted from the existing form
  Widget _buildTransactionForm(double spacing, bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Transaction Details',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: spacing),
          _buildCustomerSearch(),
          if (errorMessage != null) ...[
            SizedBox(height: spacing - 8),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red, fontSize: isMobile ? 12 : 14),
            ),
          ],
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
              enabled: !customerFound,
            ),
            keyboardType: TextInputType.phone,
            validator:
                (value) => value!.isEmpty ? 'Please enter phone number' : null,
          ),
          SizedBox(height: spacing),
          TextFormField(
            controller: pageNumberController,
            decoration: InputDecoration(
              labelText: 'Page Number',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
              enabled: !customerFound,
            ),
            keyboardType: TextInputType.number,
            readOnly: true,
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
              enabled: !customerFound,
            ),
            keyboardType: TextInputType.number,
            validator:
                (value) =>
                    value!.isEmpty
                        ? 'Please enter previous balance'
                        : (double.tryParse(value) != null
                            ? null
                            : 'Invalid number'),
          ),
          SizedBox(height: spacing),
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing),
          TextFormField(
            controller: amountPaidController,
            decoration: InputDecoration(
              labelText: 'Amount Paid',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              // Trigger a rebuild to update the button state
              setState(() {});
            },
            validator: (value) {
              if (value!.isEmpty) return 'Please enter amount paid';
              final amount = double.tryParse(value);
              if (amount == null) return 'Invalid number';
              if (amount < 0 || amount > 1000000) {
                return 'Amount must be between 0 and 1,000,000';
              }
              return null;
            },
          ),
          SizedBox(height: spacing),
          TextFormField(
            controller: amountTakenController,
            decoration: InputDecoration(
              labelText: 'Amount Taken',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade50,
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              // Trigger a rebuild to update the button state
              setState(() {});
            },
            validator: (value) {
              if (value!.isEmpty) return 'Please enter amount taken';
              final amount = double.tryParse(value);
              if (amount == null) return 'Invalid number';
              if (amount < 0 || amount > 1000000) {
                return 'Amount must be between 0 and 1,000,000';
              }
              return null;
            },
          ),
          SizedBox(height: spacing + 8),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed:
                  isSearching
                      ? null
                      : () async {
                        try {
                          // Prevent multiple submissions by checking if already processing
                          if (isSearching) {
                            print("Submission already in progress");
                            return;
                          }

                          // Validate form
                          if (!customerFound ||
                              selectedCustomerId == null ||
                              amountPaidController.text.trim().isEmpty ||
                              amountTakenController.text.trim().isEmpty) {
                            print("Button pressed but form is not ready");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a customer and enter all required values',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          if (double.tryParse(
                                    amountPaidController.text.trim(),
                                  ) ==
                                  null ||
                              double.tryParse(
                                    amountTakenController.text.trim(),
                                  ) ==
                                  null) {
                            print("Invalid number format in amount fields");
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please enter valid numbers for amount fields',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                            return;
                          }

                          print("Button pressed, form is ready");
                          await _submitTransaction();
                        } catch (e) {
                          print("Error triggering form submission: $e");
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Error: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => isSearching = false);
                          }
                        }
                      },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 12 : 15,
                ),
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  isSearching
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : Text(
                        'Add Transaction',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),
          if (customerFound) ...[
            SizedBox(height: spacing - 4),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _resetForm,
                child: const Text('Reset Form'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // New sales form
  Widget _buildSalesForm(double spacing, bool isMobile) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Daily Sales Entry',
            style: TextStyle(
              fontSize: isMobile ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade800,
            ),
          ),
          SizedBox(height: spacing),
          // Date selector
          InkWell(
            onTap: () => _selectDate(context),
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Date',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(DateFormat('dd/MM/yyyy').format(selectedDate)),
                  const Icon(Icons.calendar_today),
                ],
              ),
            ),
          ),
          SizedBox(height: spacing * 1.5),

          // Petrol Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFFFF5E6), // Lighter orange
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange.shade100, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.local_gas_station,
                      color: Colors.orange.shade700,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'Petrol',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: petrolLitresController,
                        decoration: InputDecoration(
                          labelText: 'Litres',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final amount = double.tryParse(value);
                          if (amount == null) return 'Invalid number';
                          if (amount < 0) return 'Must be positive';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: TextFormField(
                        controller: petrolRupeesController,
                        decoration: InputDecoration(
                          labelText: 'Rupees',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final amount = double.tryParse(value);
                          if (amount == null) return 'Invalid number';
                          if (amount < 0) return 'Must be positive';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: spacing),

          // Diesel Section
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFE6F2FF), // Lighter blue
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade100, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.local_gas_station, color: Colors.blue.shade700),
                    SizedBox(width: 8),
                    Text(
                      'Diesel',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: spacing),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: dieselLitresController,
                        decoration: InputDecoration(
                          labelText: 'Litres',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final amount = double.tryParse(value);
                          if (amount == null) return 'Invalid number';
                          if (amount < 0) return 'Must be positive';
                          return null;
                        },
                      ),
                    ),
                    SizedBox(width: spacing),
                    Expanded(
                      child: TextFormField(
                        controller: dieselRupeesController,
                        decoration: InputDecoration(
                          labelText: 'Rupees',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) return null;
                          final amount = double.tryParse(value);
                          if (amount == null) return 'Invalid number';
                          if (amount < 0) return 'Must be positive';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: spacing + 8),

          // Submit Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isSearching ? null : _submitSales,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 24 : 32,
                  vertical: isMobile ? 12 : 15,
                ),
                disabledBackgroundColor: Colors.grey,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child:
                  isSearching
                      ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          ),
                          SizedBox(width: 10),
                          Text(
                            'Processing...',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                      : Text(
                        'Save Sales Data',
                        style: TextStyle(
                          fontSize: isMobile ? 14 : 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
            ),
          ),

          SizedBox(height: spacing - 4),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: _resetSalesForm,
              child: const Text('Reset Form'),
            ),
          ),
        ],
      ),
    );
  }

  // Add controllers for the sales form
  final TextEditingController petrolLitresController = TextEditingController();
  final TextEditingController petrolRupeesController = TextEditingController();
  final TextEditingController dieselLitresController = TextEditingController();
  final TextEditingController dieselRupeesController = TextEditingController();

  void _resetSalesForm() {
    setState(() {
      petrolLitresController.clear();
      petrolRupeesController.clear();
      dieselLitresController.clear();
      dieselRupeesController.clear();
      selectedDate = DateTime.now();
    });
  }

  // Submission logic for sales data
  Future<void> _submitSales() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please correct the errors in the form'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => isSearching = true);

    try {
      // Parse values
      final petrolLitres =
          double.tryParse(petrolLitresController.text.trim()) ?? 0.0;
      final petrolRupees =
          double.tryParse(petrolRupeesController.text.trim()) ?? 0.0;
      final dieselLitres =
          double.tryParse(dieselLitresController.text.trim()) ?? 0.0;
      final dieselRupees =
          double.tryParse(dieselRupeesController.text.trim()) ?? 0.0;

      // At least one value should be greater than zero
      if (petrolLitres <= 0 &&
          petrolRupees <= 0 &&
          dieselLitres <= 0 &&
          dieselRupees <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter at least one value greater than zero'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isSearching = false);
        return;
      }

      // Create the sales data object
      final salesData = {
        'date': Timestamp.fromDate(selectedDate),
        'petrol_litres': petrolLitres,
        'petrol_rupees': petrolRupees,
        'diesel_litres': dieselLitres,
        'diesel_rupees': dieselRupees,
        'total_amount': petrolRupees + dieselRupees,
        'created_at': FieldValue.serverTimestamp(),
      };

      // Save to Firestore
      await FirebaseFirestore.instance.collection('sales').add(salesData);

      // Show success message
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sales data saved successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Reset the form
      _resetSalesForm();
    } catch (e) {
      print('Error in _submitSales: $e');
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving sales data: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSearching = false);
      }
    }
  }

  // Keep existing methods but update _resetForm to clear all fields
  void _resetForm() {
    setState(() {
      customerNameController.clear();
      phoneController.clear();
      balanceController.clear();
      amountPaidController.clear();
      amountTakenController.clear();
      pageNumberController.clear();
      petrolLitresController.clear();
      petrolRupeesController.clear();
      dieselLitresController.clear();
      dieselRupeesController.clear();
      selectedDate = DateTime.now();
      selectedCustomerId = null;
      customerFound = false;
      customerSuggestions = [];
      errorMessage = null;
    });
    print('Form reset completed');
  }

  Widget _buildCustomerSearch() {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double suggestionMaxHeight = isMobile ? 120.0 : 150.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: customerNameController,
          decoration: InputDecoration(
            labelText: 'Customer Name',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true,
            fillColor: Colors.grey.shade50,
            suffixIcon:
                isSearching
                    ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                    : (customerFound
                        ? const Icon(Icons.check, color: Colors.green)
                        : null),
            enabled: !customerFound,
          ),
          onChanged: (query) {
            if (query.isEmpty) {
              setState(() {
                isSearching = false;
                customerSuggestions = [];
                errorMessage = null;
              });
              return;
            }
            setState(() {
              isSearching = true;
              errorMessage = null;
            });
            _fetchCustomerSuggestions(query);
          },
        ),
        if (customerSuggestions.isNotEmpty && !customerFound)
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  spreadRadius: 1,
                  blurRadius: 5,
                ),
              ],
            ),
            margin: const EdgeInsets.only(top: 4),
            constraints: BoxConstraints(maxHeight: suggestionMaxHeight),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customerSuggestions.length,
              itemBuilder: (context, index) {
                final customer = customerSuggestions[index];
                return ListTile(
                  dense: isMobile,
                  title: Text(
                    customer['name'] ?? '',
                    style: TextStyle(fontSize: isMobile ? 14 : 16),
                  ),
                  subtitle: Text(
                    customer['phone'] ?? '',
                    style: TextStyle(fontSize: isMobile ? 12 : 14),
                  ),
                  onTap: () => _selectCustomer(customer),
                );
              },
            ),
          ),
      ],
    );
  }

  void _fetchCustomerSuggestions(String query) async {
    try {
      print('Fetching customer suggestions for query: $query');
      final snapshot =
          await FirebaseFirestore.instance
              .collection('customers')
              .where('name_lower', isGreaterThanOrEqualTo: query.toLowerCase())
              .where(
                'name_lower',
                isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff',
              )
              .get();
      print('Customer suggestions fetched: ${snapshot.docs.length} results');

      setState(() {
        isSearching = false;
        customerSuggestions =
            snapshot.docs.map((doc) {
              final data = doc.data();
              return {
                'id': doc.id,
                'name': data['name'],
                'phone': data['phone'],
                'balance': data['balance'],
                'page_number': data['page_number'],
              };
            }).toList();
        if (customerSuggestions.isEmpty) {
          errorMessage = 'No customer found with this name';
        } else {
          errorMessage = null;
        }
      });
    } catch (e) {
      print('Error in _fetchCustomerSuggestions: $e');
      setState(() {
        isSearching = false;
        errorMessage =
            'Error fetching customers: $e\nEnsure your device has internet access.';
      });
    }
  }

  void _selectCustomer(Map<String, dynamic> customer) {
    try {
      print(
        'Selecting customer: ${customer['name']}, balance: ${customer['balance']}',
      );

      // Format balance properly
      String formattedBalance = '0';
      if (customer['balance'] != null) {
        if (customer['balance'] is num) {
          formattedBalance = customer['balance'].toString();
        } else if (customer['balance'] is String) {
          // Try to parse and format if it's a string
          final balanceValue = double.tryParse(customer['balance']);
          if (balanceValue != null) {
            formattedBalance = balanceValue.toString();
          }
        }
      }

      setState(() {
        selectedCustomerId = customer['id'];
        customerNameController.text = customer['name'] ?? '';
        phoneController.text = customer['phone'] ?? '';
        pageNumberController.text = customer['page_number'] ?? '';
        balanceController.text = formattedBalance;
        customerFound = true;
        customerSuggestions = [];
        errorMessage = null;

        // Make sure amount fields are initialized if empty
        if (amountPaidController.text.isEmpty) {
          amountPaidController.text = '0';
        }
        if (amountTakenController.text.isEmpty) {
          amountTakenController.text = '0';
        }
      });

      print(
        'Customer selected successfully, customerFound: $customerFound, ID: $selectedCustomerId',
      );
    } catch (e) {
      print('Error in _selectCustomer: $e');
      setState(() {
        errorMessage = 'Error selecting customer: $e';
      });
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder:
          (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: Colors.green,
                onPrimary: Colors.white,
                onSurface: Colors.black,
              ),
            ),
            child: child!,
          ),
    );
    if (picked != null && picked != selectedDate) {
      setState(() => selectedDate = picked);
    }
  }

  Future<void> _submitTransaction() async {
    if (!_formKey.currentState!.validate()) {
      print('Form validation failed');
      return;
    }

    setState(() => isSearching = true);
    try {
      print('Step 1: Starting transaction submission...');

      // Validate selected customer
      if (selectedCustomerId == null ||
          customerNameController.text.trim().isEmpty) {
        print('Step 1 Failed: Customer selection is incomplete');
        throw Exception('Customer selection is incomplete');
      }
      print(
        'Step 1 Passed: Customer ID: $selectedCustomerId, Name: ${customerNameController.text}',
      );

      // Validate and parse numerical inputs
      final amountPaidText = amountPaidController.text.trim();
      final amountTakenText = amountTakenController.text.trim();
      final previousBalanceText = balanceController.text.trim();
      print(
        'Step 2: Validating inputs - Amount Paid: $amountPaidText, Amount Taken: $amountTakenText, Previous Balance: $previousBalanceText',
      );
      if (amountPaidText.isEmpty ||
          amountTakenText.isEmpty ||
          previousBalanceText.isEmpty) {
        print('Step 2 Failed: One or more inputs are empty');
        throw Exception(
          'Amount paid, amount taken, or previous balance cannot be empty',
        );
      }

      final amountPaid = double.tryParse(amountPaidText) ?? 0.0;
      final amountTaken = double.tryParse(amountTakenText) ?? 0.0;
      final previousBalance = double.tryParse(previousBalanceText) ?? 0.0;

      print(
        'Step 2 Passed: Parsed values - Amount Paid: $amountPaid, Amount Taken: $amountTaken, Previous Balance: $previousBalance',
      );

      // Calculate new balance - Amount Paid reduces balance, Amount Taken increases it
      final newBalance = previousBalance - amountPaid + amountTaken;
      print('Step 3: Calculated new balance: $newBalance');
      if (newBalance < -1000000 || newBalance > 1000000) {
        print('Step 3 Failed: New balance out of range: $newBalance');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'New balance must be between -1,000,000 and 1,000,000',
            ),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isSearching = false);
        return;
      }
      print('Step 3 Passed: New balance is within range');

      // No need to validate selectedDate - it's always initialized
      print('Step 4 Passed: Selected date: $selectedDate');

      // Perform Firestore operations
      print('Step 5: Performing Firestore operations...');

      try {
        // Create the transaction data first
        final transactionData = {
          'customer_id': selectedCustomerId,
          'customer_name': customerNameController.text.trim(),
          'phone': phoneController.text.trim(),
          'previous_balance': previousBalance,
          'amount_paid': amountPaid,
          'amount_taken': amountTaken,
          'new_balance': newBalance,
          'date': Timestamp.fromDate(selectedDate),
          'created_at': FieldValue.serverTimestamp(),
        };

        // Verify that we can access the customer document before proceeding
        final customerDoc =
            await FirebaseFirestore.instance
                .collection('customers')
                .doc(selectedCustomerId)
                .get();

        if (!customerDoc.exists) {
          throw Exception(
            'Customer document not found. The customer may have been deleted.',
          );
        }

        // Use a simple set/update approach instead of a transaction to reduce complexity
        // 1. Add the transaction record
        final transactionRef = await FirebaseFirestore.instance
            .collection('transactions')
            .add(transactionData);

        print('Transaction document created with ID: ${transactionRef.id}');

        // 2. Update the customer's balance
        await FirebaseFirestore.instance
            .collection('customers')
            .doc(selectedCustomerId)
            .update({'balance': newBalance});

        print('Customer balance updated successfully');
      } catch (e) {
        print('Firestore operation failed: $e');
        throw Exception('Failed to save transaction: $e');
      }

      print('Step 5 Passed: Transaction completed successfully');

      // Show success message
      if (!mounted) return;
      print('Step 6: Showing success message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully and balance updated'),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
      print('Step 6 Passed: Success message shown, form reset');
    } on FirebaseException catch (e) {
      print(
        'FirebaseException in _submitTransaction: ${e.code} - ${e.message}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firestore error: ${e.message}\nCheck your Firestore rules and internet connection.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } on PlatformException catch (e) {
      print(
        'PlatformException in _submitTransaction: ${e.code} - ${e.message}',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Platform error: ${e.message}\nTry updating the Firestore plugin or restarting the app.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } catch (e, stackTrace) {
      print('Unexpected error in _submitTransaction: $e');
      print('Stack trace: $stackTrace');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unexpected error: $e\nPlease try again or contact support.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => isSearching = false);
      }
      print('Step 7: Transaction process completed (success or failure)');
    }
  }
}
