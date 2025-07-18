import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StockTab extends StatefulWidget {
  const StockTab({super.key});

  @override
  State<StockTab> createState() => _StockTabState();
}

class _StockTabState extends State<StockTab> {
  bool showAdd = true;
  DateTime selectedDate = DateTime.now();
  final TextEditingController petrolController = TextEditingController();
  final TextEditingController dieselController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool isSaving = false;

  @override
  void dispose() {
    petrolController.dispose();
    dieselController.dispose();
    super.dispose();
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

  Future<void> _saveStock() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => isSaving = true);
    try {
      final double petrol = double.tryParse(petrolController.text.trim()) ?? 0.0;
      final double diesel = double.tryParse(dieselController.text.trim()) ?? 0.0;
      await FirebaseFirestore.instance.collection('stock').add({
        'date': Timestamp.fromDate(selectedDate),
        'petrol': petrol,
        'diesel': diesel,
        'created_at': Timestamp.now(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Stock saved successfully'), backgroundColor: Colors.green),
        );
        petrolController.clear();
        dieselController.clear();
        selectedDate = DateTime.now();
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      setState(() => isSaving = false);
    }
  }

  Widget _buildAddForm(bool isMobile, double spacing, double maxWidth) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade100.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.add_circle, color: Colors.green.shade700, size: 28),
                    const SizedBox(width: 8),
                    Text('Add Stock Entry', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                  ],
                ),
                SizedBox(height: spacing * 1.5),
                InkWell(
                  onTap: () => _selectDate(context),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      prefixIcon: const Icon(Icons.calendar_today, color: Colors.green),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(DateFormat('dd/MM/yyyy').format(selectedDate), style: TextStyle(fontWeight: FontWeight.w500)),
                        const Icon(Icons.edit_calendar, color: Colors.green),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: spacing),
                isMobile
                    ? Column(
                        children: [
                          _styledField(
                            controller: petrolController,
                            label: 'Petrol (Litres)',
                            icon: Icons.local_gas_station,
                            color: Colors.orange.shade700,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter petrol stock';
                              final n = double.tryParse(value);
                              if (n == null || n < 0) return 'Invalid number';
                              return null;
                            },
                          ),
                          SizedBox(height: spacing),
                          _styledField(
                            controller: dieselController,
                            label: 'Diesel (Litres)',
                            icon: Icons.local_gas_station,
                            color: Colors.blue.shade700,
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Please enter diesel stock';
                              final n = double.tryParse(value);
                              if (n == null || n < 0) return 'Invalid number';
                              return null;
                            },
                          ),
                        ],
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // If not enough width, stack vertically
                          if (constraints.maxWidth < 500) {
                            return Column(
                              children: [
                                _styledField(
                                  controller: petrolController,
                                  label: 'Petrol (Litres)',
                                  icon: Icons.local_gas_station,
                                  color: Colors.orange.shade700,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter petrol stock';
                                    final n = double.tryParse(value);
                                    if (n == null || n < 0) return 'Invalid number';
                                    return null;
                                  },
                                ),
                                SizedBox(height: spacing),
                                _styledField(
                                  controller: dieselController,
                                  label: 'Diesel (Litres)',
                                  icon: Icons.local_gas_station,
                                  color: Colors.blue.shade700,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter diesel stock';
                                    final n = double.tryParse(value);
                                    if (n == null || n < 0) return 'Invalid number';
                                    return null;
                                  },
                                ),
                              ],
                            );
                          }
                          // Otherwise, use a Row with Expanded
                          return Row(
                            children: [
                              Expanded(
                                child: _styledField(
                                  controller: petrolController,
                                  label: 'Petrol (Litres)',
                                  icon: Icons.local_gas_station,
                                  color: Colors.orange.shade700,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter petrol stock';
                                    final n = double.tryParse(value);
                                    if (n == null || n < 0) return 'Invalid number';
                                    return null;
                                  },
                                ),
                              ),
                              SizedBox(width: spacing),
                              Expanded(
                                child: _styledField(
                                  controller: dieselController,
                                  label: 'Diesel (Litres)',
                                  icon: Icons.local_gas_station,
                                  color: Colors.blue.shade700,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) return 'Please enter diesel stock';
                                    final n = double.tryParse(value);
                                    if (n == null || n < 0) return 'Invalid number';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                SizedBox(height: spacing * 1.5),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save),
                    label: isSaving
                        ? const Text('Saving...', style: TextStyle(fontWeight: FontWeight.bold))
                        : Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: isSaving ? null : _saveStock,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: isMobile ? 24 : 32,
                        vertical: isMobile ? 14 : 18,
                      ),
                      textStyle: TextStyle(fontSize: isMobile ? 15 : 17, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _styledField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color color,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: color),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        filled: true,
        fillColor: Colors.white,
        labelStyle: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
      keyboardType: TextInputType.number,
      validator: validator,
    );
  }

  Widget _buildViewStock(bool isMobile, double spacing, double maxWidth) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 24),
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.green.shade100.withOpacity(0.15),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: SingleChildScrollView(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
            .collection('stock')
            .snapshots()
            .handleError((error) {
          debugPrint('Error in stock stream: $error');
          return null;
        }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: \\${snapshot.error}'));
              }
              double totalPetrol = 0;
              double totalDiesel = 0;
              for (var doc in snapshot.data?.docs ?? []) {
                final data = doc.data() as Map<String, dynamic>;
                totalPetrol += (data['petrol'] is num) ? (data['petrol'] as num).toDouble() : 0.0;
                totalDiesel += (data['diesel'] is num) ? (data['diesel'] as num).toDouble() : 0.0;
              }
              final double cardWidth = isMobile ? double.infinity : (maxWidth / 2) - spacing * 0.75;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(bottom: spacing),
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _showStockHistoryDialog(context, isMobile, spacing, maxWidth);
                        },
                        icon: Icon(Icons.history, color: Colors.white),
                        label: Text('Stock History', style: TextStyle(fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade700,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                          textStyle: TextStyle(fontSize: isMobile ? 14 : 16, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 2,
                        ),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.bar_chart, color: Colors.green.shade700, size: 28),
                      const SizedBox(width: 8),
                      Text('Current Stock', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                    ],
                  ),
                  SizedBox(height: spacing * 1.5),
                  isMobile
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _stockCard(
                              label: 'Petrol',
                              value: totalPetrol,
                              color: Colors.orange.shade700,
                              bgColor: Colors.orange.shade50,
                              icon: Icons.local_gas_station,
                              width: cardWidth,
                            ),
                            SizedBox(height: spacing),
                            _stockCard(
                              label: 'Diesel',
                              value: totalDiesel,
                              color: Colors.blue.shade700,
                              bgColor: Colors.blue.shade50,
                              icon: Icons.local_gas_station,
                              width: cardWidth,
                            ),
                          ],
                        )
                      : SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _stockCard(
                                label: 'Petrol',
                                value: totalPetrol,
                                color: Colors.orange.shade700,
                                bgColor: Colors.orange.shade50,
                                icon: Icons.local_gas_station,
                                width: cardWidth,
                              ),
                              SizedBox(width: spacing),
                              _stockCard(
                                label: 'Diesel',
                                value: totalDiesel,
                                color: Colors.blue.shade700,
                                bgColor: Colors.blue.shade50,
                                icon: Icons.local_gas_station,
                                width: cardWidth,
                              ),
                            ],
                          ),
                        ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _stockCard({
    required String label,
    required double value,
    required Color color,
    required Color bgColor,
    required IconData icon,
    required double width,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        color: bgColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.12),
                radius: 24,
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: color)),
                    const SizedBox(height: 6),
                    Text(
                      '${NumberFormat('#,##,##,##,##0.00', 'en_IN').format(value)} L',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, color: color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStockHistoryDialog(BuildContext context, bool isMobile, double spacing, double maxWidth) async {
    final ScrollController verticalController = ScrollController();
    final ScrollController horizontalController = ScrollController();
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? 8 : 40, vertical: isMobile ? 24 : 40),
          child: Container(
            width: isMobile ? double.infinity : maxWidth + 100,
            padding: EdgeInsets.all(isMobile ? 8 : 24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: StatefulBuilder(
              builder: (context, setState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.history, color: Colors.green.shade700),
                            const SizedBox(width: 8),
                            Text('Stock History', style: TextStyle(fontSize: isMobile ? 18 : 22, fontWeight: FontWeight.bold, color: Colors.green.shade800)),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.close),
                          onPressed: () {
                            verticalController.dispose();
                            horizontalController.dispose();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    SizedBox(height: spacing),
                    SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: FutureBuilder<QuerySnapshot>(
                        future: FirebaseFirestore.instance.collection('stock').orderBy('date').get(),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator());
                          }
                          if (snapshot.hasError) {
                            return Center(child: Text('Error: \\${snapshot.error}'));
                          }
                          final docs = snapshot.data?.docs ?? [];
                          double runningPetrol = 0;
                          double runningDiesel = 0;
                          final rows = <DataRow>[];
                          for (var i = 0; i < docs.length; i++) {
                            final doc = docs[i];
                            final data = doc.data() as Map<String, dynamic>;
                            final date = (data['date'] as Timestamp?)?.toDate();
                            final petrol = (data['petrol'] is num) ? (data['petrol'] as num).toDouble() : 0.0;
                            final diesel = (data['diesel'] is num) ? (data['diesel'] as num).toDouble() : 0.0;
                            runningPetrol += petrol;
                            runningDiesel += diesel;
                            rows.add(DataRow(
                              color: isMobile ? null : MaterialStateProperty.resolveWith<Color?>((Set<MaterialState> states) {
                                return i % 2 == 0 ? Colors.white : Colors.green.shade50;
                              }),
                              cells: [
                                DataCell(Text(date != null ? DateFormat('dd/MM/yyyy').format(date) : '-', style: TextStyle(fontSize: isMobile ? 13 : 16))),
                                DataCell(Text(NumberFormat('#,##,##,##,##0.00', 'en_IN').format(petrol), style: TextStyle(fontSize: isMobile ? 13 : 16))),
                                DataCell(Text(NumberFormat('#,##,##,##,##0.00', 'en_IN').format(diesel), style: TextStyle(fontSize: isMobile ? 13 : 16))),
                                DataCell(Text(NumberFormat('#,##,##,##,##0.00', 'en_IN').format(runningPetrol), style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 16, color: Colors.green.shade800))),
                                DataCell(Text(NumberFormat('#,##,##,##,##0.00', 'en_IN').format(runningDiesel), style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 13 : 16, color: Colors.green.shade800))),
                              ],
                            ));
                          }
                          final table = DataTable(
                            columns: [
                              DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 17))),
                              DataColumn(label: Text('Petrol (Litres)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 17))),
                              DataColumn(label: Text('Diesel (Litres)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 17))),
                              DataColumn(label: Text('Petrol Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 17))),
                              DataColumn(label: Text('Diesel Stock', style: TextStyle(fontWeight: FontWeight.bold, fontSize: isMobile ? 14 : 17))),
                            ],
                            rows: rows,
                            headingRowColor: MaterialStateProperty.all(Colors.green.shade100),
                            dataRowColor: isMobile ? MaterialStateProperty.all(Colors.white) : null,
                            dividerThickness: 1,
                            columnSpacing: isMobile ? 12 : 28,
                            horizontalMargin: isMobile ? 6 : 18,
                            showBottomBorder: true,
                          );
                          // Attach scrollbars to their respective controllers
                          return Scrollbar(
                            controller: verticalController,
                            thumbVisibility: true,
                            interactive: true,
                            child: Scrollbar(
                              controller: horizontalController,
                              thumbVisibility: true,
                              interactive: true,
                              notificationPredicate: (notification) => notification.depth == 1,
                              child: SingleChildScrollView(
                                controller: verticalController,
                                scrollDirection: Axis.vertical,
                                child: SingleChildScrollView(
                                  controller: horizontalController,
                                  scrollDirection: Axis.horizontal,
                                  child: Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: table,
                                  ),
                                ),
                              ),
                            ),
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
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final double spacing = isMobile ? 12.0 : 16.0;
    final double fontSize = isMobile ? 20.0 : 24.0;
    final double maxWidth = isMobile ? 400 : 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 15.0),
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
            'Stock',
            style: TextStyle(fontSize: fontSize, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: spacing),
          Row(
            children: [
              Expanded(
                flex: 10,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAdd = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: showAdd ? Colors.green : Colors.grey.shade300,
                    foregroundColor: showAdd ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    elevation: showAdd ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: showAdd ? Colors.white : Colors.green),
                      const SizedBox(width: 6),
                      const Text('Add'),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 10,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      showAdd = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: !showAdd ? Colors.green : Colors.grey.shade300,
                    foregroundColor: !showAdd ? Colors.white : Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    padding: EdgeInsets.symmetric(vertical: 12),
                    elevation: !showAdd ? 4 : 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bar_chart, color: !showAdd ? Colors.white : Colors.green),
                      const SizedBox(width: 6),
                      const Text('View'),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: spacing + 4),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: spacing),
              child: showAdd ? _buildAddForm(isMobile, spacing, maxWidth) : _buildViewStock(isMobile, spacing, maxWidth),
            ),
          ),
        ],
      ),
    );
  }
} 