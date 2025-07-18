import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  DateTime selectedDate = DateTime.now();
  DateTime? rangeStartDate;
  DateTime? rangeEndDate;
  bool isRangeMode = false;
  bool isLoading = true;
  bool hasError = false;
  String errorMessage = '';
  bool showAmountView = true;

  // Data values
  double totalCredits = 0;
  double totalRecovery = 0;
  double receivableAmount = 0;

  // New: Customer stats
  double regularReceivables = 0;
  double defaulterReceivables = 0;
  int totalCustomers = 0;
  int defaulterCount = 0;

  // Added for fuel sales data
  double petrolLitres = 0;
  double petrolRupees = 0;
  double dieselLitres = 0;
  double dieselRupees = 0;

  // Indian Numbering System formatter
  String formatIndianNumber(double number) {
    final formatter = NumberFormat('#,##,##,##,##0.00', 'en_IN');
    return formatter.format(number);
  }

  @override
  void initState() {
    super.initState();
    _fetchDashboardData();
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
      if (!mounted) return;
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      // Always fetch new data when date changes
      await _fetchDashboardData();
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      if (!mounted) return;
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = '';
      });

      DateTime startDate, endDate;
      if (isRangeMode && rangeStartDate != null && rangeEndDate != null) {
        startDate = DateTime(rangeStartDate!.year, rangeStartDate!.month, rangeStartDate!.day);
        endDate = DateTime(rangeEndDate!.year, rangeEndDate!.month, rangeEndDate!.day, 23, 59, 59);
      } else {
        startDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
        endDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      }

      // Use try-catch for each query to handle individual failures
      QuerySnapshot? transactionsSnapshot;
      QuerySnapshot? customersSnapshot;
      QuerySnapshot? salesSnapshot;

      try {
        transactionsSnapshot = await FirebaseFirestore.instance.collection('transactions')
          .where('custom_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('custom_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .limit(100)
          .get();
      } catch (e) {
        debugPrint('Error fetching transactions: $e');
        transactionsSnapshot = null;
      }

      try {
        customersSnapshot = await FirebaseFirestore.instance.collection('customers')
          .get();
      } catch (e) {
        debugPrint('Error fetching customers: $e');
        customersSnapshot = null;
      }

      try {
        salesSnapshot = await FirebaseFirestore.instance.collection('sales')
          .where('custom_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('custom_date', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .limit(100)
          .get();
      } catch (e) {
        debugPrint('Error fetching sales: $e');
        salesSnapshot = null;
      }

      if (!mounted) return;

      double dailyCredits = 0;
      double dailyRecovery = 0;
      List<Map<String, dynamic>> filteredTransactions = [];

      // Process transactions
      if (transactionsSnapshot != null) {
        for (var doc in transactionsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final amountPaid = data['amount_paid'] is num ? (data['amount_paid'] as num).toDouble() : 0.0;
          final amountTaken = data['amount_taken'] is num ? (data['amount_taken'] as num).toDouble() : 0.0;
          
          dailyCredits += amountTaken;
          dailyRecovery += amountPaid;
          
          filteredTransactions.add(data);
        }
      }

      // Process sales data
      double totalPetrolLitres = 0;
      double totalPetrolRupees = 0;
      double totalDieselLitres = 0;
      double totalDieselRupees = 0;

      if (salesSnapshot != null) {
        for (var doc in salesSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalPetrolLitres += data['petrol_litres'] is num ? (data['petrol_litres'] as num).toDouble() : 0.0;
          totalPetrolRupees += data['petrol_rupees'] is num ? (data['petrol_rupees'] as num).toDouble() : 0.0;
          totalDieselLitres += data['diesel_litres'] is num ? (data['diesel_litres'] as num).toDouble() : 0.0;
          totalDieselRupees += data['diesel_rupees'] is num ? (data['diesel_rupees'] as num).toDouble() : 0.0;
        }
      }

      // Calculate total receivable amount from customers
      double totalReceivable = 0;
      double tempRegularReceivables = 0;
      double tempDefaulterReceivables = 0;
      int tempTotalCustomers = 0;
      int tempDefaulterCount = 0;
      if (customersSnapshot != null) {
        for (var doc in customersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          final balance = data['balance'] is num ? (data['balance'] as num).toDouble() : 0.0;
          final isDefaulter = data['is_defaulter'] == true;
          totalReceivable += balance;
          if (isDefaulter) {
            tempDefaulterReceivables += balance;
            tempDefaulterCount++;
          } else {
            tempRegularReceivables += balance;
          }
          tempTotalCustomers++;
        }
      }

      if (!mounted) return;

      setState(() {
        totalCredits = dailyCredits;
        totalRecovery = dailyRecovery;
        receivableAmount = totalReceivable;
        petrolLitres = totalPetrolLitres;
        petrolRupees = totalPetrolRupees;
        dieselLitres = totalDieselLitres;
        dieselRupees = totalDieselRupees;
        regularReceivables = tempRegularReceivables;
        defaulterReceivables = tempDefaulterReceivables;
        totalCustomers = tempTotalCustomers;
        defaulterCount = tempDefaulterCount;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error loading dashboard data: ${e.toString().split('\n')[0]}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 1024;
    final double padding = isMobile ? 12.0 : 16.0;
    final double verticalSpacing = isMobile ? 16.0 : 24.0;
    final double borderRadius = isMobile ? 12.0 : 15.0;
    final double topMargin = 10.0; // Add top margin

    return Container(
      padding: EdgeInsets.only(
        left: padding,
        right: padding,
        bottom: padding,
        top: padding + topMargin, // Add extra top padding
      ),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Fixed header section
          _buildHeader(context, isMobile),
          SizedBox(height: verticalSpacing),
          
          // Scrollable content
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (isLoading)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(verticalSpacing),
                        child: CircularProgressIndicator(
                          color: Colors.green.shade600,
                        ),
                      ),
                    )
                  else if (hasError)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(verticalSpacing),
                        child: Text(
                          errorMessage,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    )
                  else
          _buildSummaryCards(context, isMobile, isTablet),
                  
                  SizedBox(height: verticalSpacing),
                  // Remove chart and its spacing
                  // _buildMonthlyChart(context, isMobile, isTablet),
                  // SizedBox(height: verticalSpacing),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isMobile) {
    final double titleFontSize = isMobile ? 22.0 : 28.0;
    final double subtitleFontSize = isMobile ? 12.0 : 14.0;
    final double dateFontSize = isMobile ? 12.0 : 14.0;
    final double dateIconSize = isMobile ? 14.0 : 18.0;
    final double datePadding = isMobile ? 8.0 : 16.0;

    // Toggle for single date / range mode
    final toggleWidget = Row(
      children: [
        Text('Single Date', style: TextStyle(fontSize: subtitleFontSize)),
        Switch(
          value: isRangeMode,
          onChanged: (val) {
            setState(() {
              isRangeMode = val;
              if (!isRangeMode) {
                rangeStartDate = null;
                rangeEndDate = null;
              }
            });
          },
          activeColor: Colors.green,
        ),
        Text('Date Range', style: TextStyle(fontSize: subtitleFontSize)),
      ],
    );

    // Date widget with tap functionality to change date
    final dateWidget = isRangeMode
        ? GestureDetector(
            onTap: () async {
              final picked = await showDateRangePicker(
                context: context,
                firstDate: DateTime(2020),
                lastDate: DateTime(2101),
                initialDateRange: (rangeStartDate != null && rangeEndDate != null)
                    ? DateTimeRange(start: rangeStartDate!, end: rangeEndDate!)
                    : null,
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
              if (picked != null) {
                setState(() {
                  rangeStartDate = picked.start;
                  rangeEndDate = picked.end;
                });
                await _fetchDashboardData();
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: datePadding,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: dateIconSize,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    (rangeStartDate != null && rangeEndDate != null)
                        ? '${DateFormat('MMM d, yyyy').format(rangeStartDate!)} - ${DateFormat('MMM d, yyyy').format(rangeEndDate!)}'
                        : 'Select Date Range',
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                      fontSize: dateFontSize,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: dateIconSize,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          )
        : GestureDetector(
            onTap: () => _selectDate(context),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: datePadding,
                vertical: isMobile ? 8 : 10,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade100,
                    spreadRadius: 1,
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: dateIconSize,
                    color: Colors.green.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM d, yyyy').format(selectedDate),
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade800,
                      fontSize: dateFontSize,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(
                    Icons.arrow_drop_down,
                    size: dateIconSize,
                    color: Colors.grey.shade600,
                  ),
                ],
              ),
            ),
          );

    // Title widget
    final titleWidget = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
            fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 4),
        Row(
          children: [
            Text(
              'Statistics for ',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontSize: subtitleFontSize,
              ),
            ),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Text(
                DateFormat('MMM d, yyyy').format(selectedDate),
                style: TextStyle(
                  color: Colors.green.shade600,
                  fontWeight: FontWeight.w500,
                  fontSize: subtitleFontSize,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                titleWidget,
                const SizedBox(height: 8),
                toggleWidget,
                const SizedBox(height: 8),
                dateWidget
              ],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                titleWidget,
                Row(
                  children: [
                    toggleWidget,
                    const SizedBox(width: 16),
                    dateWidget,
                  ],
                ),
              ],
            ),
        
        // Add toggle buttons for Amount and Fuel views
        const SizedBox(height: 16),
        _buildViewToggleButtons(isMobile),
      ],
    );
  }

  // Updated method for view toggle buttons styled like Add Transaction/Add Sales
  Widget _buildViewToggleButtons(bool isMobile) {
    final double buttonHeight = 40.0;
    final double buttonRadius = 8.0;
    final double fontSize = isMobile ? 13.0 : 14.0;
    final double gapWidth = 8.0; // Gap between buttons
    
    return SizedBox(
      width: double.infinity,
      height: buttonHeight,
      child: Row(
        children: [
          Expanded(
            child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
                borderRadius: BorderRadius.circular(buttonRadius),
            boxShadow: [
              BoxShadow(
                    color: Colors.grey.shade200,
                spreadRadius: 1,
                    blurRadius: 3,
              ),
            ],
          ),
              child: GestureDetector(
                onTap: () {
                  if (!showAmountView) {
                    setState(() {
                      showAmountView = true;
                    });
                  }
                },
                child: Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: showAmountView ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(buttonRadius),
                  ),
                  child: Center(
                    child: Text(
                      'Amount',
                style: TextStyle(
                        color: showAmountView ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: gapWidth), // Gap between buttons
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(buttonRadius),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    spreadRadius: 1,
                    blurRadius: 3,
                  ),
                ],
              ),
              child: GestureDetector(
                onTap: () {
                  if (showAmountView) {
                    setState(() {
                      showAmountView = false;
                    });
                  }
                },
                child: Container(
                  height: buttonHeight,
                  decoration: BoxDecoration(
                    color: !showAmountView ? Colors.green : Colors.transparent,
                    borderRadius: BorderRadius.circular(buttonRadius),
                  ),
                  child: Center(
                    child: Text(
                      'Fuel',
                      style: TextStyle(
                        color: !showAmountView ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.bold,
                        fontSize: fontSize,
                      ),
                    ),
                  ),
                ),
              ),
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final double cardSpacing = isMobile ? 8.0 : 16.0;

    if (showAmountView) {
    final String statLabel = isRangeMode && rangeStartDate != null && rangeEndDate != null
        ? '${DateFormat('MMM d, yyyy').format(rangeStartDate!)} - ${DateFormat('MMM d, yyyy').format(rangeEndDate!)}'
        : DateFormat('MMM d, yyyy').format(selectedDate);
    if (isMobile) {
      return Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoCard(
              'Total Credits',
              'Rs. ${formatIndianNumber(totalCredits)}',
            Icons.account_balance_wallet,
              Colors.red.shade600,
              Colors.red.shade50,
            context,
            isFullWidth: true,
              isMobile: isMobile,
              trend: '+${_calculatePercentageChange(totalCredits)}%',
              trendUp: true,
              statLabel: statLabel,
          ),
            SizedBox(height: cardSpacing),
          _buildInfoCard(
              'Total Recovery',
              'Rs. ${formatIndianNumber(totalRecovery)}',
              Icons.payments,
              Colors.green.shade600,
              Colors.green.shade50,
            context,
            isFullWidth: true,
              isMobile: isMobile,
              trend: '+${_calculatePercentageChange(totalRecovery)}%',
              trendUp: true,
              statLabel: statLabel,
          ),
            SizedBox(height: cardSpacing),
          _buildInfoCard(
              'Receivable Amount',
              'Rs. ${formatIndianNumber(receivableAmount)}',
            Icons.monetization_on,
            Colors.orange.shade600,
            Colors.orange.shade50,
            context,
            isFullWidth: true,
              isMobile: isMobile,
              trend:
                  totalCredits > totalRecovery
                      ? '+${_calculatePercentageChange(receivableAmount)}%'
                      : '-${_calculatePercentageChange(receivableAmount)}%',
              trendUp: totalCredits > totalRecovery,
              statLabel: '',
          ),
          SizedBox(height: cardSpacing),
          _buildInfoCard(
            'Regular Receivables',
            'Rs. ${formatIndianNumber(regularReceivables)}',
            Icons.check_circle_outline,
            Colors.blue.shade600,
            Colors.blue.shade50,
            context,
            isFullWidth: true,
            isMobile: isMobile,
            trend: '',
            trendUp: true,
            statLabel: '',
          ),
          SizedBox(height: cardSpacing),
          _buildInfoCard(
            'Defaulter Receivables',
            'Rs. ${formatIndianNumber(defaulterReceivables)}',
            Icons.warning_amber_rounded,
            Colors.red.shade800,
            Colors.red.shade100,
            context,
            isFullWidth: true,
            isMobile: isMobile,
            trend: '',
            trendUp: false,
            statLabel: '',
          ),
          SizedBox(height: cardSpacing),
          _buildInfoCard(
            'Total Customers',
            totalCustomers.toString(),
            Icons.people,
            Colors.purple.shade600,
            Colors.purple.shade50,
            context,
            isFullWidth: true,
            isMobile: isMobile,
            trend: '',
            trendUp: true,
            smallText: 'Defaulters: $defaulterCount',
            statLabel: '',
          ),
        ],
      );
    }
    if (isTablet) {
      return Column(
          mainAxisSize: MainAxisSize.min,
        children: [
          Row(
              mainAxisSize: MainAxisSize.min,
            children: [
                Flexible(
                  child: _buildInfoCard(
                    'Total Credits',
                    'Rs. ${formatIndianNumber(totalCredits)}',
                Icons.account_balance_wallet,
                    Colors.red.shade600,
                    Colors.red.shade50,
                    context,
                    isMobile: isMobile,
                    trend: '+${_calculatePercentageChange(totalCredits)}%',
                    trendUp: true,
                    statLabel: statLabel,
                  ),
                ),
                SizedBox(width: cardSpacing),
                Flexible(
                  child: _buildInfoCard(
                    'Total Recovery',
                    'Rs. ${formatIndianNumber(totalRecovery)}',
                    Icons.payments,
                Colors.green.shade600,
                Colors.green.shade50,
                context,
                    isMobile: isMobile,
                    trend: '+${_calculatePercentageChange(totalRecovery)}%',
                    trendUp: true,
                    statLabel: statLabel,
                  ),
              ),
            ],
          ),
            SizedBox(height: cardSpacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _buildInfoCard(
                    'Receivable Amount',
                    'Rs. ${formatIndianNumber(receivableAmount)}',
            Icons.monetization_on,
            Colors.orange.shade600,
            Colors.orange.shade50,
            context,
                    isMobile: isMobile,
                    trend:
                        totalCredits > totalRecovery
                            ? '+${_calculatePercentageChange(receivableAmount)}%'
                            : '-${_calculatePercentageChange(receivableAmount)}%',
                    trendUp: totalCredits > totalRecovery,
                  ),
                ),
                SizedBox(width: cardSpacing),
                Flexible(
                  child: _buildInfoCard(
                    'Regular Receivables',
                    'Rs. ${formatIndianNumber(regularReceivables)}',
                    Icons.check_circle_outline,
                    Colors.blue.shade600,
                    Colors.blue.shade50,
                    context,
                    isMobile: isMobile,
                    trend: '',
                    trendUp: true,
                  ),
                ),
              ],
          ),
          SizedBox(height: cardSpacing),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _buildInfoCard(
                  'Defaulter Receivables',
                  'Rs. ${formatIndianNumber(defaulterReceivables)}',
                  Icons.warning_amber_rounded,
                  Colors.red.shade800,
                  Colors.red.shade100,
                  context,
                  isMobile: isMobile,
                  trend: '',
                  trendUp: false,
                ),
              ),
              SizedBox(width: cardSpacing),
              Flexible(
                child: _buildInfoCard(
                  'Total Customers',
                  totalCustomers.toString(),
                  Icons.people,
                  Colors.purple.shade600,
                  Colors.purple.shade50,
                  context,
                  isMobile: isMobile,
                  trend: '',
                  trendUp: true,
                  smallText: 'Defaulters: $defaulterCount',
                ),
              ),
            ],
          ),
        ],
      );
    }
      // Desktop layout for amount view
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _buildInfoCard(
                  'Total Credits',
                  'Rs. ${formatIndianNumber(totalCredits)}',
                  Icons.account_balance_wallet,
                  Colors.red.shade600,
                  Colors.red.shade50,
                  context,
                  isMobile: isMobile,
                  trend: '+${_calculatePercentageChange(totalCredits)}%',
                  trendUp: true,
                  statLabel: statLabel,
                ),
              ),
              SizedBox(width: cardSpacing),
              Flexible(
                child: _buildInfoCard(
                  'Total Recovery',
                  'Rs. ${formatIndianNumber(totalRecovery)}',
                  Icons.payments,
                  Colors.green.shade600,
                  Colors.green.shade50,
                  context,
                  isMobile: isMobile,
                  trend: '+${_calculatePercentageChange(totalRecovery)}%',
                  trendUp: true,
                  statLabel: statLabel,
                ),
              ),
              SizedBox(width: cardSpacing),
              Flexible(
                child: _buildInfoCard(
                  'Receivable Amount',
                  'Rs. ${formatIndianNumber(receivableAmount)}',
                  Icons.monetization_on,
                  Colors.orange.shade600,
                  Colors.orange.shade50,
                  context,
                  isMobile: isMobile,
                  trend:
                      totalCredits > totalRecovery
                          ? '+${_calculatePercentageChange(receivableAmount)}%'
                          : '-${_calculatePercentageChange(receivableAmount)}%',
                  trendUp: totalCredits > totalRecovery,
                ),
              ),
            ],
          ),
          SizedBox(height: cardSpacing),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _buildInfoCard(
                  'Regular Receivables',
                  'Rs. ${formatIndianNumber(regularReceivables)}',
                  Icons.check_circle_outline,
                  Colors.blue.shade600,
                  Colors.blue.shade50,
                  context,
                  isMobile: isMobile,
                  trend: '',
                  trendUp: true,
                ),
              ),
              SizedBox(width: cardSpacing),
              Flexible(
                child: _buildInfoCard(
                  'Defaulter Receivables',
                  'Rs. ${formatIndianNumber(defaulterReceivables)}',
                  Icons.warning_amber_rounded,
                  Colors.red.shade800,
                  Colors.red.shade100,
                  context,
                  isMobile: isMobile,
                  trend: '',
                  trendUp: false,
                ),
              ),
              SizedBox(width: cardSpacing),
              Flexible(
                child: _buildInfoCard(
                  'Total Customers',
                  totalCustomers.toString(),
                  Icons.people,
                  Colors.purple.shade600,
                  Colors.purple.shade50,
                  context,
                  isMobile: isMobile,
                  trend: '',
                  trendUp: true,
                  smallText: 'Defaulters: $defaulterCount',
                ),
              ),
            ],
          ),
        ],
      );
    }
    
    // Build fuel cards if showAmountView is false
    else {
      final String statLabel = isRangeMode && rangeStartDate != null && rangeEndDate != null
          ? '${DateFormat('MMM d, yyyy').format(rangeStartDate!)} - ${DateFormat('MMM d, yyyy').format(rangeEndDate!)}'
          : DateFormat('MMM d, yyyy').format(selectedDate);
      if (isMobile) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFuelCard(
              'Petrol',
              '${formatIndianNumber(petrolLitres)} L',
              'Rs. ${formatIndianNumber(petrolRupees)}',
              Icons.local_gas_station,
              Colors.orange.shade700,
              Colors.orange.shade50,
              context,
              isFullWidth: true,
              isMobile: isMobile,
              statLabel: statLabel,
            ),
            SizedBox(height: cardSpacing),
            _buildFuelCard(
              'Diesel',
              '${formatIndianNumber(dieselLitres)} L',
              'Rs. ${formatIndianNumber(dieselRupees)}',
              Icons.local_gas_station,
              Colors.blue.shade700,
              Colors.blue.shade50,
              context,
              isFullWidth: true,
              isMobile: isMobile,
              statLabel: statLabel,
            ),
            SizedBox(height: cardSpacing),
            _buildTotalFuelCard(
              'Total Fuel',
              '${formatIndianNumber(petrolLitres + dieselLitres)} L',
              'Rs. ${formatIndianNumber(petrolRupees + dieselRupees)}',
              Icons.local_gas_station,
              Colors.green.shade700,
              Colors.green.shade50,
              context,
              isMobile: isMobile,
              statLabel: statLabel,
            ),
          ],
        );
      }
      if (isTablet) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _buildFuelCard(
                    'Petrol',
                    '${formatIndianNumber(petrolLitres)} L',
                    'Rs. ${formatIndianNumber(petrolRupees)}',
                    Icons.local_gas_station,
                    Colors.orange.shade700,
                    Colors.orange.shade50,
                    context,
                    isMobile: isMobile,
                    statLabel: statLabel,
                  ),
                ),
                SizedBox(width: cardSpacing),
                Flexible(
                  child: _buildFuelCard(
                    'Diesel',
                    '${formatIndianNumber(dieselLitres)} L',
                    'Rs. ${formatIndianNumber(dieselRupees)}',
                    Icons.local_gas_station,
                    Colors.blue.shade700,
                    Colors.blue.shade50,
                    context,
                    isMobile: isMobile,
                    statLabel: statLabel,
                  ),
                ),
              ],
            ),
            SizedBox(height: cardSpacing),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: _buildTotalFuelCard(
                    'Total Fuel',
                    '${formatIndianNumber(petrolLitres + dieselLitres)} L',
                    'Rs. ${formatIndianNumber(petrolRupees + dieselRupees)}',
                    Icons.local_gas_station,
                    Colors.green.shade700,
                    Colors.green.shade50,
                    context,
                    isMobile: isMobile,
                    statLabel: statLabel,
                  ),
                ),
              ],
            ),
          ],
        );
      }
      // Desktop layout for fuel view
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: _buildFuelCard(
                  'Petrol',
                  '${formatIndianNumber(petrolLitres)} L',
                  'Rs. ${formatIndianNumber(petrolRupees)}',
                  Icons.local_gas_station,
                  Colors.orange.shade700,
                  Colors.orange.shade50,
                  context,
                  isMobile: isMobile,
                  statLabel: statLabel,
                ),
              ),
              SizedBox(width: cardSpacing),
              Flexible(
                child: _buildFuelCard(
                  'Diesel',
                  '${formatIndianNumber(dieselLitres)} L',
                  'Rs. ${formatIndianNumber(dieselRupees)}',
                  Icons.local_gas_station,
                  Colors.blue.shade700,
                  Colors.blue.shade50,
                  context,
                  isMobile: isMobile,
                  statLabel: statLabel,
                ),
              ),
              SizedBox(width: cardSpacing),
              Flexible(
                child: _buildTotalFuelCard(
                  'Total Fuel',
                  '${formatIndianNumber(petrolLitres + dieselLitres)} L',
                  'Rs. ${formatIndianNumber(petrolRupees + dieselRupees)}',
                  Icons.local_gas_station,
                  Colors.green.shade700,
                  Colors.green.shade50,
                  context,
                  isMobile: isMobile,
                  statLabel: statLabel,
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  String _calculatePercentageChange(double value) {
    // Placeholder calculation, in a real app this would compare with previous period
    return (value * 0.05).toStringAsFixed(1);
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
    BuildContext context, {
    bool isFullWidth = false,
    bool isMobile = false,
    String trend = '+12%',
    bool trendUp = true,
    String? smallText,
    String? statLabel,
  }) {
    final double cardPadding = isMobile ? 12.0 : 20.0;
    final double titleFontSize = isMobile ? 14.0 : 16.0;
    final double valueFontSize = isMobile ? 20.0 : 26.0;
    final double iconSize = isMobile ? 28.0 : 36.0;
    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: titleFontSize,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: iconSize / 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade900,
            ),
          ),
          if (smallText != null) ...[
            const SizedBox(height: 4),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'Defaulters:',
                    style: TextStyle(
                      fontSize: isMobile ? 10.0 : 12.0,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' ${smallText.replaceFirst('Defaulters:', '').trim()}',
                    style: TextStyle(
                      fontSize: isMobile ? 14.0 : 18.0,
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 8),
         if (statLabel != null && statLabel.isNotEmpty)
            _buildStatInfoRow(
              trendUp ? Icons.trending_up : Icons.trending_down,
              trend,
              statLabel,
              isMobile: isMobile,
              trendUp: trendUp,
            ),
        ],
      ),
    );
  }

  Widget _buildStatInfoRow(
    IconData icon,
    String value,
    String label, {
    bool isMobile = false,
    bool trendUp = true,
  }) {
    final double fontSize = isMobile ? 10.0 : 12.0;
    final double iconSize = isMobile ? 12.0 : 14.0;
    final Color trendColor = trendUp ? Colors.green : Colors.red;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: trendColor, size: iconSize),
        const SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            color: trendColor,
            fontWeight: FontWeight.bold,
            fontSize: fontSize,
          ),
        ),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade600, fontSize: fontSize),
          ),
        ),
      ],
    );
  }

  // New method for fuel card widget with updated font sizes and date position
  Widget _buildFuelCard(
    String title,
    String litres,
    String amount,
    IconData icon,
    Color iconColor,
    Color bgColor,
    BuildContext context, {
    bool isFullWidth = false,
    bool isMobile = false,
    String? statLabel,
  }) {
    final double cardPadding = isMobile ? 12.0 : 20.0;
    final double titleFontSize = isMobile ? 14.0 : 16.0;
    final double valueFontSize = isMobile ? 20.0 : 26.0;
    final double secondaryFontSize = isMobile ? 14.0 : 18.0;
    final double dateFontSize = isMobile ? 10.0 : 12.0;
    final double iconSize = isMobile ? 28.0 : 36.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: titleFontSize,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: iconSize / 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    litres,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: secondaryFontSize,
                      fontWeight: FontWeight.w500,
                      color: iconColor,
                    ),
                  ),
                  if (statLabel != null && statLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        statLabel,
                        style: TextStyle(
                          fontSize: isMobile ? 10.0 : 12.0,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                DateFormat('MMM d, yyyy').format(selectedDate),
                style: TextStyle(
                  fontSize: dateFontSize,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // New method for total fuel card widget with updated font sizes and date position
  Widget _buildTotalFuelCard(
    String title,
    String litres,
    String amount,
    IconData icon,
    Color iconColor,
    Color bgColor,
    BuildContext context, {
    bool isMobile = false,
    String? statLabel,
  }) {
    final double cardPadding = isMobile ? 12.0 : 20.0;
    final double titleFontSize = isMobile ? 14.0 : 16.0;
    final double valueFontSize = isMobile ? 20.0 : 26.0;
    final double secondaryFontSize = isMobile ? 14.0 : 18.0;
    final double dateFontSize = isMobile ? 10.0 : 12.0;
    final double iconSize = isMobile ? 28.0 : 36.0;

    return Container(
      padding: EdgeInsets.all(cardPadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: titleFontSize,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.all(isMobile ? 8 : 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: iconSize / 1.5),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    litres,
                    style: TextStyle(
                      fontSize: valueFontSize,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    amount,
                    style: TextStyle(
                      fontSize: secondaryFontSize,
                      fontWeight: FontWeight.w500,
                      color: iconColor,
                    ),
                  ),
                  if (statLabel != null && statLabel.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        statLabel,
                        style: TextStyle(
                          fontSize: isMobile ? 10.0 : 12.0,
                          color: Colors.grey.shade600,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
              Text(
                DateFormat('MMM d, yyyy').format(selectedDate),
                style: TextStyle(
                  fontSize: dateFontSize,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
