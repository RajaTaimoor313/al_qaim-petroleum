import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

enum ChartTimeFrame { daily, weekly, monthly, annual }

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  DateTime selectedDate = DateTime.now();
  bool isLoading = true;
  bool isChartLoading = false;
  bool hasError = false;
  String errorMessage = '';
  ChartTimeFrame selectedTimeFrame = ChartTimeFrame.daily;
  bool showAmountView = true;

  // Data values
  double totalCredits = 0;
  double totalRecovery = 0;
  double receivableAmount = 0;

  // Added for fuel sales data
  double petrolLitres = 0;
  double petrolRupees = 0;
  double dieselLitres = 0;
  double dieselRupees = 0;

  List<MonthlyData> monthlyData = [];

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

      final DateTime startOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
      );
      final DateTime endOfDay = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        23,
        59,
        59,
      );

      // Use try-catch for each query to handle individual failures
      QuerySnapshot? transactionsSnapshot;
      QuerySnapshot? customersSnapshot;
      QuerySnapshot? salesSnapshot;

      try {
        transactionsSnapshot = await FirebaseFirestore.instance.collection('transactions')
          .where('custom_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('custom_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .limit(100)
          .get();
      } catch (e) {
        debugPrint('Error fetching transactions: $e');
        transactionsSnapshot = null;
      }

      try {
        customersSnapshot = await FirebaseFirestore.instance.collection('customers')
          .limit(100)
          .get();
      } catch (e) {
        debugPrint('Error fetching customers: $e');
        customersSnapshot = null;
      }

      try {
        salesSnapshot = await FirebaseFirestore.instance.collection('sales')
          .where('custom_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('custom_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
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
      if (customersSnapshot != null) {
        for (var doc in customersSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          totalReceivable += data['balance'] is num ? (data['balance'] as num).toDouble() : 0.0;
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
        isLoading = false;
      });

      // Fetch chart data
      await _fetchChartDataOnly();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Error loading dashboard data: ${e.toString().split('\n')[0]}';
      });
    }
  }

  Future<List<MonthlyData>> _fetchChartData() async {
    List<MonthlyData> result = [];

    try {
      // Get current date/time values to use as reference points
      final now = DateTime.now();
      final currentYear = now.year;
      final currentMonth = now.month;
      
      switch (selectedTimeFrame) {
        case ChartTimeFrame.daily:
          // For daily view: show current day with 3 days before and 1 day after
          final dayLabels = [
            DateFormat('dd MMM').format(DateTime(now.year, now.month, now.day - 3)),
            DateFormat('dd MMM').format(DateTime(now.year, now.month, now.day - 2)),
            DateFormat('dd MMM').format(DateTime(now.year, now.month, now.day - 1)),
            DateFormat('dd MMM').format(now),
            DateFormat('dd MMM').format(DateTime(now.year, now.month, now.day + 1)),
          ];
          
          // Calculate date range for query (4 days before to 2 days after to include partial days)
          final startOfRange = DateTime(now.year, now.month, now.day - 4);
          final endOfRange = DateTime(now.year, now.month, now.day + 2, 23, 59, 59);
          
          // Use server-side filtering and limit
          QuerySnapshot? allSalesSnapshot;
          try {
            allSalesSnapshot = await FirebaseFirestore.instance
                .collection('sales')
                .where('custom_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
                .where('custom_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfRange))
                .orderBy('custom_date')
                .limit(200)
                .get();
          } catch (e) {
            debugPrint('Error fetching daily sales data: $e');
            allSalesSnapshot = null;
          }
              
          // Create a map with data aggregated by day
          Map<String, MonthlyData> dailyData = {};
          
          // Initialize map with the 5 days we want to display
          for (int i = -3; i <= 1; i++) {
            final day = DateTime(now.year, now.month, now.day + i);
            final dayKey = '${day.year}-${day.month}-${day.day}';
            
            dailyData[dayKey] = MonthlyData(
              year: day.year,
              month: day.month,
              day: day.day,
              petrolLitres: 0,
              dieselLitres: 0,
              label: dayLabels[i + 3],
            );
          }
          
          // Fill in actual data
          if (allSalesSnapshot != null) {
            for (var doc in allSalesSnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final saleDate = data['date'] as Timestamp?;
              
              if (saleDate != null) {
                final saleDateTimeUTC = saleDate.toDate();
                // Only process data for the 5 days we care about
                if (saleDateTimeUTC.day >= now.day - 3 && 
                    saleDateTimeUTC.day <= now.day + 1 &&
                    saleDateTimeUTC.month == now.month &&
                    saleDateTimeUTC.year == now.year) {
                  
                  final dayKey = '${saleDateTimeUTC.year}-${saleDateTimeUTC.month}-${saleDateTimeUTC.day}';
                  
                  final petrolLitres = data['petrol_litres'] is num ? (data['petrol_litres'] as num).toDouble() : 0.0;
                  final dieselLitres = data['diesel_litres'] is num ? (data['diesel_litres'] as num).toDouble() : 0.0;
                  
                  if (dailyData.containsKey(dayKey)) {
                    dailyData[dayKey]!.petrolLitres += petrolLitres;
                    dailyData[dayKey]!.dieselLitres += dieselLitres;
                  }
                }
              }
            }
          }
          
          // Convert map to sorted list
          final sortedKeys = [
            '${now.year}-${now.month}-${now.day - 3}',
            '${now.year}-${now.month}-${now.day - 2}',
            '${now.year}-${now.month}-${now.day - 1}',
            '${now.year}-${now.month}-${now.day}',
            '${now.year}-${now.month}-${now.day + 1}',
          ];
          
          // Create result in the correct order
          for (var key in sortedKeys) {
            if (dailyData.containsKey(key)) {
              result.add(dailyData[key]!);
            }
          }
          
          break;
          
        case ChartTimeFrame.weekly:
          // For weekly view: current week, 3 weeks before, 1 week after
          // First, create formatted labels for the weeks
          final List<String> weekLabels = [];
          final List<DateTime> weekStarts = [];
          
          // Calculate week start dates
          for (int i = -3; i <= 1; i++) {
            // Find the start of the week (assuming week starts on Monday)
            final targetDate = now.add(Duration(days: 7 * i));
            final weekdayOffset = targetDate.weekday - DateTime.monday;
            final weekStart = targetDate.subtract(Duration(days: weekdayOffset));
            weekStarts.add(weekStart);
            
            // Create label like "20-26 Jun"
            final weekEnd = weekStart.add(const Duration(days: 6));
            weekLabels.add('${DateFormat('dd').format(weekStart)}-${DateFormat('dd MMM').format(weekEnd)}');
          }
          
          // Calculate date range for query (add buffer days to include partial weeks)
          final startOfRange = weekStarts.first.subtract(const Duration(days: 1));
          final endOfRange = weekStarts.last.add(const Duration(days: 8));
          
          QuerySnapshot? allSalesSnapshot;
          try {
            allSalesSnapshot = await FirebaseFirestore.instance
                .collection('sales')
                .where('custom_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
                .where('custom_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfRange))
                .orderBy('custom_date')
                .limit(500)
                .get();
          } catch (e) {
            debugPrint('Error fetching weekly sales data: $e');
            allSalesSnapshot = null;
          }
              
          // Initialize weekly data with the 5 weeks we want to display
          final Map<int, MonthlyData> weeklyData = {};
          
          for (int i = 0; i < 5; i++) {
            final weekStart = weekStarts[i];
            weeklyData[i] = MonthlyData(
              year: weekStart.year,
              month: weekStart.month,
              day: weekStart.day,
              petrolLitres: 0,
              dieselLitres: 0,
              label: weekLabels[i],
            );
          }
          
          // Process sales data and aggregate by week
          if (allSalesSnapshot != null) {
            for (var doc in allSalesSnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final saleDate = data['date'] as Timestamp?;
              
              if (saleDate != null) {
                final saleDateTimeUTC = saleDate.toDate();
                
                // Find which week this date belongs to
                for (int i = 0; i < weekStarts.length; i++) {
                  final weekStart = weekStarts[i];
                  final weekEnd = weekStart.add(const Duration(days: 6));
                  
                  if (saleDateTimeUTC.isAfter(weekStart.subtract(const Duration(seconds: 1))) && 
                      saleDateTimeUTC.isBefore(weekEnd.add(const Duration(days: 1)))) {
                    
                    final petrolLitres = data['petrol_litres'] is num ? (data['petrol_litres'] as num).toDouble() : 0.0;
                    final dieselLitres = data['diesel_litres'] is num ? (data['diesel_litres'] as num).toDouble() : 0.0;
                    
                    weeklyData[i]!.petrolLitres += petrolLitres;
                    weeklyData[i]!.dieselLitres += dieselLitres;
                    break;
                  }
                }
              }
            }
          }
          
          // Create result in the correct order
          for (int i = 0; i < 5; i++) {
            if (weeklyData.containsKey(i)) {
              result.add(weeklyData[i]!);
            }
          }
          
          break;
          
        case ChartTimeFrame.monthly:
          // For monthly view: current month, 3 months before, 1 month after
          final List<DateTime> monthStarts = [];
          final List<String> monthLabels = [];
          
          // Calculate month start dates and labels
          for (int i = -3; i <= 1; i++) {
            int targetMonth = currentMonth + i;
            int targetYear = currentYear;
            
            // Handle year boundary
            if (targetMonth < 1) {
              targetMonth += 12;
              targetYear -= 1;
            } else if (targetMonth > 12) {
              targetMonth -= 12;
              targetYear += 1;
            }
            
            final monthStart = DateTime(targetYear, targetMonth, 1);
            monthStarts.add(monthStart);
            monthLabels.add(DateFormat('MMM yy').format(monthStart));
          }
          
          // Calculate date range for query
          final startOfRange = monthStarts.first;
          final endOfRange = DateTime(
            monthStarts.last.year, 
            monthStarts.last.month + 1, 
            0, 
            23, 59, 59
          ); // Last day of the last month
          
          QuerySnapshot? allSalesSnapshot;
          try {
            allSalesSnapshot = await FirebaseFirestore.instance
                .collection('sales')
                .where('custom_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
                .where('custom_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfRange))
                .orderBy('custom_date')
                .limit(1000)
                .get();
          } catch (e) {
            debugPrint('Error fetching monthly sales data: $e');
            allSalesSnapshot = null;
          }
              
          // Initialize monthly data with the 5 months we want to display
          final Map<int, MonthlyData> monthlyDataMap = {};
          
          for (int i = 0; i < 5; i++) {
            final monthStart = monthStarts[i];
            monthlyDataMap[i] = MonthlyData(
              year: monthStart.year,
              month: monthStart.month,
              day: 1,
              petrolLitres: 0,
              dieselLitres: 0,
              label: monthLabels[i],
            );
          }
          
          // Process sales data and aggregate by month
          if (allSalesSnapshot != null) {
            for (var doc in allSalesSnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final saleDate = data['date'] as Timestamp?;
              
              if (saleDate != null) {
                final saleDateTimeUTC = saleDate.toDate();
                
                // Find which month this date belongs to
                for (int i = 0; i < monthStarts.length; i++) {
                  final monthStart = monthStarts[i];
                  final monthEnd = (i < monthStarts.length - 1) 
                      ? monthStarts[i + 1].subtract(const Duration(seconds: 1))
                      : DateTime(monthStart.year, monthStart.month + 1, 0, 23, 59, 59);
                  
                  if (saleDateTimeUTC.isAfter(monthStart.subtract(const Duration(seconds: 1))) && 
                      saleDateTimeUTC.isBefore(monthEnd.add(const Duration(seconds: 1)))) {
                    
                    final petrolLitres = data['petrol_litres'] is num ? (data['petrol_litres'] as num).toDouble() : 0.0;
                    final dieselLitres = data['diesel_litres'] is num ? (data['diesel_litres'] as num).toDouble() : 0.0;
                    
                    monthlyDataMap[i]!.petrolLitres += petrolLitres;
                    monthlyDataMap[i]!.dieselLitres += dieselLitres;
                    break;
                  }
                }
              }
            }
          }
          
          // Create result in the correct order
          for (int i = 0; i < 5; i++) {
            if (monthlyDataMap.containsKey(i)) {
              result.add(monthlyDataMap[i]!);
            }
          }
          
          break;
          
        case ChartTimeFrame.annual:
          // For annual view: current year, 3 years before, 1 year after
          final List<int> years = [
            currentYear - 3,
            currentYear - 2,
            currentYear - 1,
            currentYear,
            currentYear + 1,
          ];
          
          // Calculate date range for query
          final startOfRange = DateTime(years.first, 1, 1);
          final endOfRange = DateTime(years.last, 12, 31, 23, 59, 59);
          
          QuerySnapshot? allSalesSnapshot;
          try {
            allSalesSnapshot = await FirebaseFirestore.instance
                .collection('sales')
                .where('custom_date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfRange))
                .where('custom_date', isLessThanOrEqualTo: Timestamp.fromDate(endOfRange))
                .orderBy('custom_date')
                .limit(2000)
                .get();
          } catch (e) {
            debugPrint('Error fetching annual sales data: $e');
            allSalesSnapshot = null;
          }
              
          // Initialize yearly data with the 5 years we want to display
          final Map<int, MonthlyData> yearlyData = {};
          
          for (int i = 0; i < 5; i++) {
            yearlyData[i] = MonthlyData(
              year: years[i],
              month: 1,
              day: 1,
              petrolLitres: 0,
              dieselLitres: 0,
              label: years[i].toString(),
            );
          }
          
          // Process sales data and aggregate by year
          if (allSalesSnapshot != null) {
            for (var doc in allSalesSnapshot.docs) {
              final data = doc.data() as Map<String, dynamic>;
              final saleDate = data['date'] as Timestamp?;
              
              if (saleDate != null) {
                final saleDateTimeUTC = saleDate.toDate();
                final year = saleDateTimeUTC.year;
                
                // Find which of our 5 years this date belongs to
                for (int i = 0; i < years.length; i++) {
                  if (year == years[i]) {
                    final petrolLitres = data['petrol_litres'] is num ? (data['petrol_litres'] as num).toDouble() : 0.0;
                    final dieselLitres = data['diesel_litres'] is num ? (data['diesel_litres'] as num).toDouble() : 0.0;
                    
                    yearlyData[i]!.petrolLitres += petrolLitres;
                    yearlyData[i]!.dieselLitres += dieselLitres;
                    break;
                  }
                }
              }
            }
          }
          
          // Create result in the correct order
          for (int i = 0; i < 5; i++) {
            if (yearlyData.containsKey(i)) {
              result.add(yearlyData[i]!);
            }
          }
          
          break;
      }
    } catch (e) {
      // Error handled in the UI
    }

    return result;
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
                  _buildMonthlyChart(context, isMobile, isTablet),
                  SizedBox(height: verticalSpacing),
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

    // Date widget with tap functionality to change date
    final dateWidget = GestureDetector(
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
              children: [titleWidget, const SizedBox(height: 8), dateWidget],
            )
          : Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [titleWidget, dateWidget],
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
      ],
    );
    }
    
    // Build fuel cards if showAmountView is false
    else {
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
          const SizedBox(height: 8),
          _buildStatInfoRow(
            trendUp ? Icons.trending_up : Icons.trending_down,
            trend,
            title == 'Receivable Amount'
                ? 'current total balance'
                : DateFormat('MMM d, yyyy').format(selectedDate),
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

  Widget _buildMonthlyChart(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    // Adjust chart height based on device type
    final double chartHeight = isMobile ? 300 : isTablet ? 380 : 450;
    final double titleFontSize = isMobile ? 16.0 : 20.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                'Fuel Chart',
                style: TextStyle(
                  fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            ),
            _buildTimeFrameFilter(isMobile),
          ],
        ),
        const SizedBox(height: 16),
            Container(
          height: chartHeight,
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
          child: Padding(
            padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
            child:
                isChartLoading
                    ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.green.shade600,
                      ),
                    )
                    : monthlyData.isEmpty
                    ? Center(
                      child: Text(
                        'No data available for the chart',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          // Calculate available width for the chart
                          final availableWidth = constraints.maxWidth;
                          // Calculate bar width based on available space
                          final barWidth = isMobile ? 8.0 : 18.0;
                          final barGroupWidth = barWidth * 2 + (isMobile ? 1.0 : 2.0);
                          final totalBarGroupsWidth = barGroupWidth * monthlyData.length;
                          
                          // Determine if we need horizontal scrolling
                          final needsScrolling = totalBarGroupsWidth > availableWidth - 20;
                          
                          return needsScrolling
                            ? SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: max(totalBarGroupsWidth + 40, availableWidth),
                                  height: chartHeight - (isMobile ? 16 : 32),
                                  child: _buildChart(isMobile, barWidth),
                                ),
                              )
                            : SizedBox(
                                width: availableWidth,
                                height: chartHeight - (isMobile ? 16 : 32),
                                child: _buildChart(isMobile, barWidth),
                              );
                        }
                      ),
          ),
        ),
        // Adjust legend spacing for mobile
        SizedBox(height: isMobile ? 8 : 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Petrol', Colors.green.shade400, isMobile),
            SizedBox(width: isMobile ? 12 : 24),
            _buildLegendItem('Diesel', Colors.red.shade400, isMobile),
          ],
        ),
      ],
    );
  }
  
  // Extracted chart building to reduce code duplication
  Widget _buildChart(bool isMobile, double barWidth) {
    return Padding(
      padding: EdgeInsets.only(
        right: isMobile ? 12.0 : 24.0,
        bottom: isMobile ? 12.0 : 24.0,
        top: isMobile ? 12.0 : 24.0,
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: _calculateMaxY(),
          minY: 0,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.blueGrey.shade800,
              getTooltipItem: (
                group,
                groupIndex,
                rod,
                rodIndex,
              ) {
                final data = monthlyData[group.x.toInt()];
                final String period = data.label;
                String value = rod.y.toStringAsFixed(2);
                return BarTooltipItem(
                  '$period\n${rodIndex == 0 ? 'Petrol' : 'Diesel'}: $value L',
                  const TextStyle(color: Colors.white),
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: SideTitles(
              showTitles: true,
              getTextStyles:
                  (value) => TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 9 : 11,
                  ),
              margin: isMobile ? 10 : 16,
              getTitles: (double value) {
                final index = value.toInt();
                if (index >= 0 &&
                    index < monthlyData.length) {
                  if (isMobile) {
                    final label = monthlyData[index].label;
                    if (label.length > 5) {
                      return '${label.substring(0, 4)}..';
                    }
                  }
                  return monthlyData[index].label;
                }
                return '';
              },
              rotateAngle: isMobile ? 30 : 0,
            ),
            leftTitles: SideTitles(
              showTitles: true,
              getTextStyles:
                  (value) => TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: isMobile ? 9 : 12,
                  ),
              margin: isMobile ? 8 : 12,
              reservedSize: isMobile ? 28 : 35,
              interval: _getIntervalForTimeFrame(),
              getTitles: (value) {
                if (value == 0) return '0';
                return isMobile
                    ? NumberFormat.compact().format(value)
                    : NumberFormat.compact().format(value);
              },
            ),
          ),
          gridData: FlGridData(
            show: !isMobile, // Hide grid on mobile for cleaner look
            drawHorizontalLine: true,
            horizontalInterval: _getIntervalForTimeFrame(),
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade200,
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(
            show: true,
            border: Border(
              bottom: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
              left: BorderSide(
                color: Colors.grey.shade300,
                width: 1,
              ),
            ),
          ),
          barGroups: List.generate(monthlyData.length, (index) {
            final data = monthlyData[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  y: data.petrolLitres,
                  colors: [Colors.green.shade400],
                  width: barWidth,
                borderRadius: BorderRadius.circular(3),
              ),
                BarChartRodData(
                  y: data.dieselLitres,
                  colors: [Colors.red.shade400],
                  width: barWidth,
                  borderRadius: BorderRadius.circular(3),
            ),
          ],
              barsSpace: isMobile ? 1 : 2,
            );
          }),
        ),
      ),
    );
  }

  Widget _buildTimeFrameFilter(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildFilterOption(
            ChartTimeFrame.daily,
            isMobile ? 'D' : 'Daily',
            isMobile,
          ),
          _buildFilterOption(
            ChartTimeFrame.weekly,
            isMobile ? 'W' : 'Weekly',
            isMobile,
          ),
          _buildFilterOption(
            ChartTimeFrame.monthly,
            isMobile ? 'M' : 'Monthly',
            isMobile,
          ),
          _buildFilterOption(
            ChartTimeFrame.annual,
            isMobile ? 'Y' : 'Yearly',
            isMobile,
          ),
        ],
      ),
    );
  }

  Widget _buildFilterOption(
    ChartTimeFrame timeFrame,
    String label,
    bool isMobile,
  ) {
    final bool isSelected = selectedTimeFrame == timeFrame;
    final double fontSize = isMobile ? 9.0 : 12.0;

    return GestureDetector(
      onTap: () {
        if (selectedTimeFrame != timeFrame) {
          setState(() {
            selectedTimeFrame = timeFrame;
          });
          _fetchChartDataOnly();
        }
      },
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 6.0 : 12.0,
          vertical: isMobile ? 4.0 : 8.0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? Colors.green : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: fontSize,
          ),
        ),
      ),
    );
  }

  double _calculateMaxY() {
    if (monthlyData.isEmpty) return 5000.0;

    double maxValue = 0;
    for (var data in monthlyData) {
      maxValue = max(maxValue, max(data.petrolLitres, data.dieselLitres));
    }

    // Different scale based on time frame
    double interval;
    switch (selectedTimeFrame) {
      case ChartTimeFrame.daily:
        interval = 1000.0;
        break;
      case ChartTimeFrame.weekly:
        interval = 5000.0;
        break;
      case ChartTimeFrame.monthly:
        interval = 20000.0;
        break;
      case ChartTimeFrame.annual:
        interval = 250000.0;
        break;
    }

    // Round up to the nearest interval
    return ((maxValue / interval).ceil() * interval + interval).toDouble();
  }

  double _getIntervalForTimeFrame() {
    switch (selectedTimeFrame) {
      case ChartTimeFrame.daily:
        return 1000.0;
      case ChartTimeFrame.weekly:
        return 5000.0;
      case ChartTimeFrame.monthly:
        return 20000.0;
      case ChartTimeFrame.annual:
        return 250000.0;
    }
  }

  Widget _buildLegendItem(String label, Color color, bool isMobile) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey.shade700,
            fontSize: isMobile ? 12 : 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  double max(double a, double b) {
    return a > b ? a : b;
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

  // New method to only update chart data when time frame changes
  Future<void> _fetchChartDataOnly() async {
    try {
      // Create a variable to track only chart loading state
      setState(() {
        // Only set loading state for the chart
        isChartLoading = true;
      });
      
      final List<MonthlyData> chartData = await _fetchChartData();
      
      setState(() {
        monthlyData = chartData;
        isChartLoading = false;
      });
    } catch (e) {
      setState(() {
        isChartLoading = false;
        hasError = true;
        errorMessage = 'Failed to load chart data: ${e.toString().split('\n')[0]}';
      });
    }
  }
}

class MonthlyData {
  final int year;
  final int month;
  final int day;
  double petrolLitres;
  double dieselLitres;
  final String label;

  MonthlyData({
    required this.year,
    required this.month,
    this.day = 1,
    required this.petrolLitres,
    required this.dieselLitres,
    String? label,
  }) : label = label ?? DateFormat('MMM').format(DateTime(year, month, day));
}
