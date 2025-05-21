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
  DateTime selectedDate = DateTime.now();
  String? selectedCustomerId;
  List<Map<String, dynamic>> customerSuggestions = [];
  bool isSearching = false;
  bool customerFound = false;
  String? errorMessage;

  @override
  void dispose() {
    customerNameController.dispose();
    phoneController.dispose();
    balanceController.dispose();
    amountPaidController.dispose();
    amountTakenController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
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
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add New Transaction',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              _buildCustomerSearch(),
              if (errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 14),
                ),
              ],
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
                  enabled: !customerFound,
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter phone number' : null,
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
                  enabled: !customerFound,
                ),
                keyboardType: TextInputType.number,
                validator: (value) => value!.isEmpty
                    ? 'Please enter previous balance'
                    : (double.tryParse(value) != null
                        ? null
                        : 'Invalid number'),
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: customerFound ? null : () => _selectDate(context),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: customerFound ? _submitTransaction : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 15,
                    ),
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Add',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              if (customerFound) ...[
                const SizedBox(height: 12),
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
        ),
      ),
    );
  }

  Widget _buildCustomerSearch() {
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
            suffixIcon: isSearching
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
            constraints: const BoxConstraints(maxHeight: 150),
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: customerSuggestions.length,
              itemBuilder: (context, index) {
                final customer = customerSuggestions[index];
                return ListTile(
                  title: Text(customer['name']),
                  subtitle: Text(customer['phone']),
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
      final snapshot = await FirebaseFirestore.instance
          .collection('customers')
          .where('name_lower', isGreaterThanOrEqualTo: query.toLowerCase())
          .where('name_lower', isLessThanOrEqualTo: '${query.toLowerCase()}\uf8ff')
          .get();
      print('Customer suggestions fetched: ${snapshot.docs.length} results');

      setState(() {
        isSearching = false;
        customerSuggestions = snapshot.docs.map((doc) {
          final data = doc.data();
          return {
            'id': doc.id,
            'name': data['name'],
            'phone': data['phone'],
            'balance': data['balance'],
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
    setState(() {
      selectedCustomerId = customer['id'];
      customerNameController.text = customer['name'] ?? '';
      phoneController.text = customer['phone'] ?? '';
      balanceController.text = customer['balance']?.toString() ?? '0';
      customerFound = true;
      customerSuggestions = [];
      errorMessage = null;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
      builder: (context, child) => Theme(
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
      if (selectedCustomerId == null || customerNameController.text.trim().isEmpty) {
        print('Step 1 Failed: Customer selection is incomplete');
        throw Exception('Customer selection is incomplete');
      }
      print('Step 1 Passed: Customer ID: $selectedCustomerId, Name: ${customerNameController.text}');

      // Validate and parse numerical inputs
      final amountPaidText = amountPaidController.text.trim();
      final amountTakenText = amountTakenController.text.trim();
      final previousBalanceText = balanceController.text.trim();
      print('Step 2: Validating inputs - Amount Paid: $amountPaidText, Amount Taken: $amountTakenText, Previous Balance: $previousBalanceText');
      if (amountPaidText.isEmpty || amountTakenText.isEmpty || previousBalanceText.isEmpty) {
        print('Step 2 Failed: One or more inputs are empty');
        throw Exception('Amount paid, amount taken, or previous balance cannot be empty');
      }

      final amountPaid = double.tryParse(amountPaidText);
      final amountTaken = double.tryParse(amountTakenText);
      final previousBalance = double.tryParse(previousBalanceText);
      if (amountPaid == null || amountTaken == null || previousBalance == null) {
        print('Step 2 Failed: Invalid numerical input');
        throw Exception('Invalid numerical input: Ensure all amounts are valid numbers');
      }
      print('Step 2 Passed: Parsed values - Amount Paid: $amountPaid, Amount Taken: $amountTaken, Previous Balance: $previousBalance');

      // Calculate new balance
      final newBalance = previousBalance - amountPaid + amountTaken;
      print('Step 3: Calculated new balance: $newBalance');
      if (newBalance < -1000000 || newBalance > 1000000) {
        print('Step 3 Failed: New balance out of range: $newBalance');
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('New balance must be between -1,000,000 and 1,000,000'),
            backgroundColor: Colors.red,
          ),
        );
        setState(() => isSearching = false);
        return;
      }
      print('Step 3 Passed: New balance is within range');

      // Validate selectedDate
      if (selectedDate == null) {
        print('Step 4 Failed: Selected date is null');
        throw Exception('Selected date is invalid');
      }
      print('Step 4 Passed: Selected date: $selectedDate');

      // Perform Firestore operations (temporarily without transaction)
      print('Step 5: Performing direct Firestore operations...');
      final transactionRef = FirebaseFirestore.instance.collection('transactions').doc();
      await transactionRef.set({
        'customer_id': selectedCustomerId,
        'customer_name': customerNameController.text.trim(),
        'phone': phoneController.text.trim(),
        'previous_balance': previousBalance,
        'amount_paid': amountPaid,
        'amount_taken': amountTaken,
        'new_balance': newBalance,
        'date': Timestamp.fromDate(selectedDate),
      });
      print('Step 5 Passed: Transaction data set successfully');

      // Show success message
      if (!mounted) return;
      print('Step 6: Showing success message');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully (no balance update)'),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
      print('Step 6 Passed: Success message shown, form reset');
    } on FirebaseException catch (e) {
      print('FirebaseException in _submitTransaction: ${e.code} - ${e.message}');
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
      print('PlatformException in _submitTransaction: ${e.code} - ${e.message}');
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
      setState(() => isSearching = false);
      print('Step 7: Transaction process completed (success or failure)');
    }
  }

  void _resetForm() {
    setState(() {
      customerNameController.clear();
      phoneController.clear();
      balanceController.clear();
      amountPaidController.clear();
      amountTakenController.clear();
      selectedDate = DateTime.now();
      selectedCustomerId = null;
      customerFound = false;
      customerSuggestions = [];
      errorMessage = null;
    });
    print('Form reset completed');
  }
}