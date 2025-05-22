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
  bool hasError = false;
  String errorMessage = '';
  ChartTimeFrame selectedTimeFrame = ChartTimeFrame.monthly;
  
  // Data values
  double totalCredits = 0;
  double totalRecovery = 0;
  double receivableAmount = 0;
  List<MonthlyData> monthlyData = [];
  
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
      setState(() {
        selectedDate = picked;
        isLoading = true;
      });
      // Always fetch new data when date changes
      await _fetchDashboardData();
      
      // Force chart to update with new date range
      final List<MonthlyData> chartData = await _fetchChartData();
      setState(() {
        monthlyData = chartData;
      });
    }
  }
  
  Future<void> _fetchDashboardData() async {
    try {
      setState(() {
        isLoading = true;
        hasError = false;
        errorMessage = '';
      });
      
      // Calculate start and end of the selected date
      final DateTime startOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
      final DateTime endOfDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day, 23, 59, 59);
      
      print('Fetching transactions for date range: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');
      
      // Fetch transactions for the selected date - using direct timestamp comparison to ensure accuracy
      final transactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .get();
      
      // Calculate total credits and recovery for the selected date
      double dailyCredits = 0;
      double dailyRecovery = 0;
      List<Map<String, dynamic>> filteredTransactions = [];
      
      // Manually filter transactions by date to ensure accuracy
      for (var doc in transactionsSnapshot.docs) {
        final data = doc.data();
        final transactionDate = data['date'] as Timestamp?;
        
        if (transactionDate != null) {
          final transactionDateTime = transactionDate.toDate();
          // Check if this transaction falls within our date range
          if (transactionDateTime.isAfter(startOfDay.subtract(const Duration(minutes: 1))) && 
              transactionDateTime.isBefore(endOfDay.add(const Duration(minutes: 1)))) {
            
            // Valid transaction for our date range
            final amountTaken = data['amount_taken'] is num ? (data['amount_taken'] as num).toDouble() : 0.0;
            final amountPaid = data['amount_paid'] is num ? (data['amount_paid'] as num).toDouble() : 0.0;
            final customerName = data['customer_name'] ?? 'Unknown';
            
            // Add to our filtered list
            filteredTransactions.add({
              'id': doc.id,
              'customer_name': customerName,
              'amount_taken': amountTaken,
              'amount_paid': amountPaid,
              'date': transactionDateTime,
            });
            
            // Update totals
            dailyCredits += amountTaken;
            dailyRecovery += amountPaid;
            
            print('Including transaction: ${doc.id} from $customerName - Taken: $amountTaken, Paid: $amountPaid');
          }
        }
      }
      
      print('Daily Credits: $dailyCredits from ${filteredTransactions.length} transactions');
      print('Daily Recovery: $dailyRecovery from ${filteredTransactions.length} transactions');
      
      // Calculate total receivable amount (total of all balances)
      final customersSnapshot = await FirebaseFirestore.instance
          .collection('customers')
          .get();
      
      double totalReceivable = 0;
      for (var doc in customersSnapshot.docs) {
        final data = doc.data();
        final balance = data['balance'] is num ? (data['balance'] as num).toDouble() : 0.0;
        final name = data['name'] ?? 'Unknown';
        
        print('Customer: $name, Balance: $balance');
        totalReceivable += balance;
      }
      
      print('Total Receivable: $totalReceivable from ${customersSnapshot.docs.length} customers');
      
      // Fetch data for the chart based on the selected time frame
      final List<MonthlyData> chartData = await _fetchChartData();
      
      setState(() {
        totalCredits = dailyCredits;
        totalRecovery = dailyRecovery;
        receivableAmount = totalReceivable;
        monthlyData = chartData;
        isLoading = false;
      });
    } catch (e) {
      print('Error fetching dashboard data: $e');
      setState(() {
        isLoading = false;
        hasError = true;
        errorMessage = 'Failed to load dashboard data: $e';
      });
    }
  }
  
  Future<List<MonthlyData>> _fetchChartData() async {
    List<MonthlyData> result = [];
    
    try {
      // Get the current date and time
      final now = DateTime.now();
      
      // Fetch all transactions once for efficiency
      final allTransactionsSnapshot = await FirebaseFirestore.instance
          .collection('transactions')
          .get();
          
      print('Fetched ${allTransactionsSnapshot.docs.length} total transactions for chart');
      
      switch (selectedTimeFrame) {
        case ChartTimeFrame.daily:
          // Show 3 days before selected date, selected date, and 2 days after
          for (int i = -3; i <= 2; i++) {
            final day = selectedDate.add(Duration(days: i));
            final startOfDay = DateTime(day.year, day.month, day.day);
            final endOfDay = DateTime(day.year, day.month, day.day, 23, 59, 59);
            
            double dailyCredits = 0;
            double dailyRecovery = 0;
            int transactionCount = 0;
            
            // Filter transactions for this day
            for (var doc in allTransactionsSnapshot.docs) {
              final data = doc.data();
              final transactionDate = data['date'] as Timestamp?;
              
              if (transactionDate != null) {
                final transactionDateTime = transactionDate.toDate();
                if (transactionDateTime.isAfter(startOfDay) && 
                    transactionDateTime.isBefore(endOfDay)) {
                  
                  final amountTaken = data['amount_taken'] is num ? (data['amount_taken'] as num).toDouble() : 0.0;
                  final amountPaid = data['amount_paid'] is num ? (data['amount_paid'] as num).toDouble() : 0.0;
                  
                  dailyCredits += amountTaken;
                  dailyRecovery += amountPaid;
                  transactionCount++;
                }
              }
            }
            
            result.add(MonthlyData(
              year: day.year,
              month: day.month,
              day: day.day,
              credits: dailyCredits,
              recovery: dailyRecovery,
              label: i == 0 ? 'Selected (${DateFormat('d').format(day)})' : DateFormat('MMM d').format(day),
            ));
          }
          break;
          
        case ChartTimeFrame.weekly:
          // Show 3 weeks before selected date week, selected week, and 2 weeks after
          // Find the start of the week containing the selected date
          final selectedWeekStart = selectedDate.subtract(Duration(days: selectedDate.weekday - 1));
          
          for (int i = -3; i <= 2; i++) {
            final weekStart = selectedWeekStart.add(Duration(days: i * 7));
            final weekEnd = weekStart.add(const Duration(days: 6));
            
            double weeklyCredits = 0;
            double weeklyRecovery = 0;
            int transactionCount = 0;
            
            // Filter transactions for this week
            for (var doc in allTransactionsSnapshot.docs) {
              final data = doc.data();
              final transactionDate = data['date'] as Timestamp?;
              
              if (transactionDate != null) {
                final transactionDateTime = transactionDate.toDate();
                if (transactionDateTime.isAfter(weekStart.subtract(const Duration(hours: 1))) && 
                    transactionDateTime.isBefore(weekEnd.add(const Duration(hours: 23)))) {
                  
                  final amountTaken = data['amount_taken'] is num ? (data['amount_taken'] as num).toDouble() : 0.0;
                  final amountPaid = data['amount_paid'] is num ? (data['amount_paid'] as num).toDouble() : 0.0;
                  
                  weeklyCredits += amountTaken;
                  weeklyRecovery += amountPaid;
                  transactionCount++;
                }
              }
            }
            
            result.add(MonthlyData(
              year: weekStart.year,
              month: weekStart.month,
              day: weekStart.day,
              credits: weeklyCredits,
              recovery: weeklyRecovery,
              label: i == 0 ? 'This Week' : '${DateFormat('MMM d').format(weekStart)}-${DateFormat('d').format(weekEnd)}',
            ));
          }
          break;
          
        case ChartTimeFrame.monthly:
          // Calculate 3 months before, current month, and 2 months after
          final currentYear = selectedDate.year;
          final currentMonth = selectedDate.month;
          
          for (int i = -3; i <= 2; i++) {
            int monthOffset = currentMonth + i;
            int year = currentYear;
            int month = monthOffset;
            
            // Adjust year and month for values outside 1-12 range
            if (monthOffset <= 0) {
              year = currentYear - 1;
              month = 12 + monthOffset; // monthOffset is negative
            } else if (monthOffset > 12) {
              year = currentYear + 1;
              month = monthOffset - 12;
            }
            
            final startOfMonth = DateTime(year, month, 1);
            final endOfMonth = month < 12
                ? DateTime(year, month + 1, 1).subtract(const Duration(seconds: 1))
                : DateTime(year + 1, 1, 1).subtract(const Duration(seconds: 1));
            
            double monthlyCredits = 0;
            double monthlyRecovery = 0;
            int transactionCount = 0;
            
            // Filter transactions for this month
            for (var doc in allTransactionsSnapshot.docs) {
              final data = doc.data();
              final transactionDate = data['date'] as Timestamp?;
              
              if (transactionDate != null) {
                final transactionDateTime = transactionDate.toDate();
                if (transactionDateTime.isAfter(startOfMonth.subtract(const Duration(minutes: 1))) && 
                    transactionDateTime.isBefore(endOfMonth.add(const Duration(minutes: 1)))) {
                  
                  final amountTaken = data['amount_taken'] is num ? (data['amount_taken'] as num).toDouble() : 0.0;
                  final amountPaid = data['amount_paid'] is num ? (data['amount_paid'] as num).toDouble() : 0.0;
                  
                  monthlyCredits += amountTaken;
                  monthlyRecovery += amountPaid;
                  transactionCount++;
                }
              }
            }
            
            String monthLabel = DateFormat('MMM yyyy').format(startOfMonth);
            if (i == 0) {
              monthLabel = 'Current Month';
            }
            
            result.add(MonthlyData(
              year: year,
              month: month,
              credits: monthlyCredits,
              recovery: monthlyRecovery,
              label: monthLabel,
            ));
          }
          break;
          
        case ChartTimeFrame.annual:
          // Show 3 years before selected date year, selected year, and 2 years after
          final currentYear = selectedDate.year;
          
          for (int i = -3; i <= 2; i++) {
            final year = currentYear + i;
            final startOfYear = DateTime(year, 1, 1);
            final endOfYear = DateTime(year, 12, 31, 23, 59, 59);
            
            double yearlyCredits = 0;
            double yearlyRecovery = 0;
            int transactionCount = 0;
            
            // Filter transactions for this year
            for (var doc in allTransactionsSnapshot.docs) {
              final data = doc.data();
              final transactionDate = data['date'] as Timestamp?;
              
              if (transactionDate != null) {
                final transactionDateTime = transactionDate.toDate();
                if (transactionDateTime.isAfter(startOfYear.subtract(const Duration(minutes: 1))) && 
                    transactionDateTime.isBefore(endOfYear.add(const Duration(minutes: 1)))) {
                  
                  final amountTaken = data['amount_taken'] is num ? (data['amount_taken'] as num).toDouble() : 0.0;
                  final amountPaid = data['amount_paid'] is num ? (data['amount_paid'] as num).toDouble() : 0.0;
                  
                  yearlyCredits += amountTaken;
                  yearlyRecovery += amountPaid;
                  transactionCount++;
                }
              }
            }
            
            result.add(MonthlyData(
              year: year,
              month: 1, // Just a placeholder
              credits: yearlyCredits,
              recovery: yearlyRecovery,
              label: i == 0 ? 'This Year' : year.toString(),
            ));
          }
          break;
      }
      
      // Print the result for debugging
      for (var data in result) {
        print('Period: ${data.label} - Credits: ${data.credits}, Recovery: ${data.recovery}');
      }
      
    } catch (e) {
      print('Error in _fetchChartData: $e');
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

    return Container(
      padding: EdgeInsets.all(padding),
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
      child: SingleChildScrollView(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildHeader(context, isMobile),
            SizedBox(height: verticalSpacing),
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
        padding: EdgeInsets.symmetric(horizontal: datePadding, vertical: isMobile ? 8 : 10),
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
            if (isMobile) 
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
    
    return isMobile 
      ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            titleWidget,
            const SizedBox(height: 8),
            dateWidget,
          ],
        )
      : Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            titleWidget,
            dateWidget,
      ],
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    final double cardSpacing = isMobile ? 8.0 : 16.0;
    
    if (isMobile) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildInfoCard(
            'Total Credits',
            'Rs. ${NumberFormat('#,##0.00').format(totalCredits)}',
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
            'Rs. ${NumberFormat('#,##0.00').format(totalRecovery)}',
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
            'Rs. ${NumberFormat('#,##0.00').format(receivableAmount)}',
            Icons.monetization_on,
            Colors.orange.shade600,
            Colors.orange.shade50,
            context,
            isFullWidth: true,
            isMobile: isMobile,
            trend: totalCredits > totalRecovery ? '+${_calculatePercentageChange(receivableAmount)}%' : '-${_calculatePercentageChange(receivableAmount)}%',
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
                  'Rs. ${NumberFormat('#,##0.00').format(totalCredits)}',
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
                  'Rs. ${NumberFormat('#,##0.00').format(totalRecovery)}',
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
          _buildInfoCard(
            'Receivable Amount',
            'Rs. ${NumberFormat('#,##0.00').format(receivableAmount)}',
            Icons.monetization_on,
            Colors.orange.shade600,
            Colors.orange.shade50,
            context,
            isFullWidth: true,
            isMobile: isMobile,
            trend: totalCredits > totalRecovery ? '+${_calculatePercentageChange(receivableAmount)}%' : '-${_calculatePercentageChange(receivableAmount)}%',
            trendUp: totalCredits > totalRecovery,
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _buildInfoCard(
            'Total Credits',
            'Rs. ${NumberFormat('#,##0.00').format(totalCredits)}',
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
            'Rs. ${NumberFormat('#,##0.00').format(totalRecovery)}',
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
            'Rs. ${NumberFormat('#,##0.00').format(receivableAmount)}',
          Icons.monetization_on,
          Colors.orange.shade600,
          Colors.orange.shade50,
          context,
            isMobile: isMobile,
            trend: totalCredits > totalRecovery ? '+${_calculatePercentageChange(receivableAmount)}%' : '-${_calculatePercentageChange(receivableAmount)}%',
            trendUp: totalCredits > totalRecovery,
          ),
        ),
      ],
    );
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
                : 'on selected date',
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
        Icon(
          icon,
          color: trendColor,
          size: iconSize,
        ),
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
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: fontSize,
            ),
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
    // Further reduce chart height on mobile
    final double chartHeight = isMobile ? 280 : 450;
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
                'Performance Chart',
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
            child: monthlyData.isEmpty 
                ? Center(
                    child: Text(
                      'No data available for the chart',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  )
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      // Reduce chart width on mobile to show fewer bars at once but with better visibility
                      width: isMobile 
                          ? monthlyData.length * 60.0  // More compact on mobile
                          : max(MediaQuery.of(context).size.width * 0.85, monthlyData.length * 80.0),
                      height: chartHeight - (isMobile ? 16 : 32), // account for padding
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: isMobile ? 12.0 : 24.0, 
                          bottom: isMobile ? 12.0 : 24.0, 
                          top: isMobile ? 12.0 : 24.0
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
                                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                  final data = monthlyData[group.x.toInt()];
                                  final String period = data.label;
                                  String value = rod.y.toStringAsFixed(2);
                                  return BarTooltipItem(
                                    '$period\n${rodIndex == 0 ? 'Credits' : 'Recovery'}: Rs. $value',
                                    const TextStyle(color: Colors.white),
                                  );
                                },
                              ),
                            ),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: SideTitles(
                                showTitles: true,
                                getTextStyles: (value) => TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 8 : 11,
                                ),
                                margin: isMobile ? 8 : 16,
                                getTitles: (double value) {
                                  final index = value.toInt();
                                  if (index >= 0 && index < monthlyData.length) {
                                    // For mobile, use an even shorter label format
                                    if (isMobile) {
                                      // Show just the day number or abbreviation for cleaner display
                                      final label = monthlyData[index].label;
                                      if (label.contains('Selected')) {
                                        return 'Today';
                                      } else if (label.contains('(')) {
                                        // Extract just the date number
                                        final dateMatch = RegExp(r'\((\d+)\)').firstMatch(label);
                                        if (dateMatch != null) {
                                          return dateMatch.group(1) ?? '';
                                        }
                                      } else if (label.length > 5) {
                                        // Truncate longer labels
                                        return label.substring(0, 4) + '..';
                                      }
                                    }
                                    return monthlyData[index].label;
                                  }
                                  return '';
                                },
                              ),
                              leftTitles: SideTitles(
                                showTitles: true,
                                getTextStyles: (value) => TextStyle(
                                  color: Colors.grey.shade700,
                                  fontWeight: FontWeight.bold,
                                  fontSize: isMobile ? 8 : 12,
                                ),
                                margin: isMobile ? 8 : 16,
                                reservedSize: isMobile ? 40 : 60,
                                interval: _getIntervalForTimeFrame(),
                                getTitles: (value) {
                                  if (value == 0) return '0';
                                  // Use shorter format on mobile
                                  return isMobile
                                      ? NumberFormat.compact().format(value)
                                      : 'Rs. ${NumberFormat.compact().format(value)}';
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
                                bottom: BorderSide(color: Colors.grey.shade300, width: 1),
                                left: BorderSide(color: Colors.grey.shade300, width: 1),
                              ),
                            ),
                            barGroups: List.generate(
                              monthlyData.length,
                              (index) {
                                final data = monthlyData[index];
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      y: data.credits,
                                      colors: [Colors.red.shade400],
                                      width: isMobile ? 6 : 15,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    BarChartRodData(
                                      y: data.recovery,
                                      colors: [Colors.green.shade400],
                                      width: isMobile ? 6 : 15,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ],
                                  barsSpace: isMobile ? 1 : 2,
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        // Adjust legend spacing for mobile
        SizedBox(height: isMobile ? 8 : 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildLegendItem('Credits', Colors.red.shade400, isMobile),
            SizedBox(width: isMobile ? 12 : 24),
            _buildLegendItem('Recovery', Colors.green.shade400, isMobile),
          ],
        ),
      ],
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
          _buildFilterOption(ChartTimeFrame.daily, 'D', isMobile),
          _buildFilterOption(ChartTimeFrame.weekly, 'W', isMobile),
          _buildFilterOption(ChartTimeFrame.monthly, 'M', isMobile),
          _buildFilterOption(ChartTimeFrame.annual, 'Y', isMobile),
        ],
      ),
    );
  }
  
  Widget _buildFilterOption(ChartTimeFrame timeFrame, String label, bool isMobile) {
    final bool isSelected = selectedTimeFrame == timeFrame;
    final double fontSize = isMobile ? 9.0 : 12.0;
    
    return GestureDetector(
      onTap: () {
        if (selectedTimeFrame != timeFrame) {
          setState(() {
            selectedTimeFrame = timeFrame;
            isLoading = true;
          });
          _fetchDashboardData();
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
      maxValue = max(maxValue, max(data.credits, data.recovery));
    }
    
    // Different scale based on time frame
    double interval;
    switch (selectedTimeFrame) {
      case ChartTimeFrame.daily:
        interval = 15000.0;
        break;
      case ChartTimeFrame.weekly:
        interval = 100000.0;
        break;
      case ChartTimeFrame.monthly:
        interval = 500000.0;
        break;
      case ChartTimeFrame.annual:
        interval = 5000000.0;
        break;
    }
    
    // Round up to the nearest interval
    return ((maxValue / interval).ceil() * interval + interval).toDouble();
  }
  
  double _getIntervalForTimeFrame() {
    switch (selectedTimeFrame) {
      case ChartTimeFrame.daily:
        return 15000.0;
      case ChartTimeFrame.weekly:
        return 100000.0;
      case ChartTimeFrame.monthly:
        return 500000.0;
      case ChartTimeFrame.annual:
        return 5000000.0;
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
}

class MonthlyData {
  final int year;
  final int month;
  final int day;
  final double credits;
  final double recovery;
  final String label;
  
  MonthlyData({
    required this.year,
    required this.month,
    this.day = 1,
    required this.credits,
    required this.recovery,
    String? label,
  }) : this.label = label ?? DateFormat('MMM').format(DateTime(year, month, day));
}
