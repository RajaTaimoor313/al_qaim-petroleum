import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'auth/activity_service.dart';
import 'auth/password_screen.dart';
import 'customer_tab.dart';
import 'dash_board_tab.dart';
import 'data_entry_tab.dart';
import 'export_data.dart';
import 'hbl_pos_tab.dart';
import 'stock_tab.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum ChartTimeFrame { daily, weekly, monthly, annual }

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with WidgetsBindingObserver {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final ActivityService _activityService = ActivityService();
  @override
  void initState() {
    super.initState();
    _activityService.startActivityTimer(context);
    WidgetsBinding.instance.addObserver(this);
  }

  Future<void> _handleAppClose() async {
    _activityService.stopTimer();
    await _authService.signOut();
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const PasswordScreen(
            destination: HomePage(),
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activityService.stopTimer();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _handleAppClose();
    }
  }

  void _toggleDrawer() {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.closeDrawer();
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
    _activityService.resetTimer(context);
  }

  Future<void> _logout() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Logout'),
          ),
        ],
      ),
    ) ?? false;

    if (shouldLogout) {
      await _handleAppClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    _activityService.resetTimer(context);
    
    final bool isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: ClipRRect(
          child: AppBar(
            title: Text(
              'AL QAIM PETROLEUM',
              style: GoogleFonts.lato(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 24,
                letterSpacing: 1.2,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            leading: isMobile
              ? IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: _toggleDrawer,
                )
              : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout, color: Colors.white),
                onPressed: _logout,
                tooltip: 'Logout',
              ),
            ],
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: isMobile
        ? Drawer(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green, Colors.green],
                  begin: Alignment.topRight,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  AppBar(
                    automaticallyImplyLeading: true,
                    backgroundColor: Colors.transparent,
                    elevation: 0,
                    leading: IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  Expanded(child: _buildPanelShow()),
                  ListTile(
                    leading: const Icon(
                      Icons.logout,
                      color: Colors.white,
                      size: 24,
                    ),
                    title: const Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _logout();
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          )
        : null,
      body: Container(
        color: Colors.grey.shade50,
        child: isMobile
          ? _buildSelectedScreen()
          : Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 250,
                  height: MediaQuery.of(context).size.height,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.green, Colors.green],
                      begin: Alignment.topRight,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: _buildPanelShow(),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(8.0),
                    child: _buildSelectedScreen(),
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Widget _buildPanelShow() {
    return ListView(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(vertical: 24.0),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green, Colors.green],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.local_gas_station,
                color: Colors.white,
                size: 54,
              ),
              const SizedBox(height: 16),
              Text(
                'AL QAIM PETROLEUM',
                style: GoogleFonts.lato(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Logged in as ',
                style: GoogleFonts.lato(
                  color: Colors.white70,
                  fontSize: 16,
                  fontStyle: FontStyle.italic,
                ),
              ),
              FutureBuilder<String?>(
                future: SharedPreferences.getInstance().then((prefs) => prefs.getString('user_role')),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      snapshot.data!,
                      style: GoogleFonts.lato(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
        _buildNavigationItem(
          icon: Icons.dashboard,
          title: 'Dashboard',
          index: 0,
        ),
        _buildNavigationItem(
          icon: Icons.add_chart,
          title: 'Add Data',
          index: 1,
        ),
        _buildNavigationItem(
          icon: Icons.people,
          title: 'Customers',
          index: 2,
        ),
        _buildNavigationItem(
          icon: Icons.point_of_sale,
          title: 'HBL Point of Sale',
          index: 3,
        ),
        _buildNavigationItem(
          icon: Icons.inventory,
          title: 'Stock',
          index: 4,
        ),
        _buildNavigationItem(
          icon: Icons.show_chart,
          title: 'View Chart',
          index: 5,
        ),
        _buildNavigationItem(
          icon: Icons.file_download,
          title: 'Export',
          index: 6,
        ),
      ],
    );
  }

  Widget _buildNavigationItem({
    required IconData icon,
    required String title,
    required int index,
  }) {
    final bool isSelected = _selectedIndex == index;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: isSelected ? Colors.white.withOpacity(0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(8.0),
        border: isSelected 
          ? Border.all(color: Colors.white.withOpacity(0.3), width: 1.0)
          : null,
      ),
      child: ListTile(
        leading: Icon(
          icon,
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.8),
          size: isSelected ? 26 : 24,
        ),
        title: Text(
          title,
          style: GoogleFonts.lato(
            color: isSelected ? Colors.white : Colors.white.withOpacity(0.9),
            fontSize: 16,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
        selected: isSelected,
        selectedTileColor: Colors.transparent,
        onTap: () {
          setState(() {
            _selectedIndex = index;
          });
          if (MediaQuery.of(context).size.width < 600) {
            Navigator.pop(context);
          }
        },
      ),
    );
  }

  Widget _buildSelectedScreen() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SizedBox(height: constraints.maxHeight, child: _getScreen());
      },
    );
  }

  Widget _getScreen() {
    switch (_selectedIndex) {
      case 0:
        return const Dashboard();
      case 1:
        return const AddData();
      case 2:
        return const Customers();
      case 3:
        return const HBLPointOfSale();
      case 4:
        return const StockTab();
      case 5:
        return const ViewChartTab(); // Placeholder for chart view
      case 6:
        return const ExportData();
      default:
        return const Dashboard();
    }
  }
}

// Replace the ViewChartTab placeholder with a real chart view
class ViewChartTab extends StatefulWidget {
  const ViewChartTab({Key? key}) : super(key: key);

  @override
  State<ViewChartTab> createState() => _ViewChartTabState();
}

class _ViewChartTabState extends State<ViewChartTab> {
  ChartTimeFrame selectedTimeFrame = ChartTimeFrame.daily;
  bool isChartLoading = false;
  List<MonthlyData> monthlyData = [];
  String errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchChartDataOnly();
  }

  Future<void> _fetchChartDataOnly() async {
    try {
      setState(() {
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
        errorMessage = 'Failed to load chart data:  [0m${e.toString().split('\n')[0]}';
      });
    }
  }

  Future<List<MonthlyData>> _fetchChartData() async {
    List<MonthlyData> result = [];
    final now = DateTime.now();
    final currentYear = now.year;
    final currentMonth = now.month;
    switch (selectedTimeFrame) {
      case ChartTimeFrame.daily:
        final startOfRange = DateTime(now.year, now.month, now.day - 4);
        final endOfRange = DateTime(now.year, now.month, now.day + 2, 23, 59, 59);
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
          allSalesSnapshot = null;
        }
        Map<String, MonthlyData> dailyData = {};
        for (int i = -3; i <= 1; i++) {
          final date = DateTime(now.year, now.month, now.day + i);
          final label = DateFormat('dd MMM').format(date);
          dailyData[label] = MonthlyData(label: label, petrolLitres: 0, dieselLitres: 0);
        }
        if (allSalesSnapshot != null) {
          for (var doc in allSalesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['custom_date'] as Timestamp).toDate();
            final label = DateFormat('dd MMM').format(date);
            if (dailyData.containsKey(label)) {
              dailyData[label]!.petrolLitres += (data['petrol_litres'] ?? 0).toDouble();
              dailyData[label]!.dieselLitres += (data['diesel_litres'] ?? 0).toDouble();
            }
          }
        }
        result = dailyData.values.toList();
        break;
      case ChartTimeFrame.weekly:
        // For simplicity, show 5 weeks (current and previous 4)
        final List<DateTime> weekStarts = [];
        final List<String> weekLabels = [];
        DateTime weekStart = now.subtract(Duration(days: now.weekday - 1));
        for (int i = 4; i >= 0; i--) {
          final start = weekStart.subtract(Duration(days: 7 * i));
          weekStarts.add(start);
          weekLabels.add('Wk ${DateFormat('dd MMM').format(start)}');
        }
        final startOfRange = weekStarts.first;
        final endOfRange = weekStarts.last.add(const Duration(days: 6, hours: 23, minutes: 59, seconds: 59));
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
          allSalesSnapshot = null;
        }
        Map<String, MonthlyData> weeklyData = {for (var l in weekLabels) l: MonthlyData(label: l, petrolLitres: 0, dieselLitres: 0)};
        if (allSalesSnapshot != null) {
          for (var doc in allSalesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['custom_date'] as Timestamp).toDate();
            for (int i = 0; i < weekStarts.length; i++) {
              final start = weekStarts[i];
              final end = start.add(const Duration(days: 6));
              if (!date.isBefore(start) && !date.isAfter(end)) {
                final label = weekLabels[i];
                weeklyData[label]!.petrolLitres += (data['petrol_litres'] ?? 0).toDouble();
                weeklyData[label]!.dieselLitres += (data['diesel_litres'] ?? 0).toDouble();
                break;
              }
            }
          }
        }
        result = weeklyData.values.toList();
        break;
      case ChartTimeFrame.monthly:
        final List<DateTime> monthStarts = [];
        final List<String> monthLabels = [];
        for (int i = -3; i <= 1; i++) {
          int targetMonth = currentMonth + i;
          int targetYear = currentYear;
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
        final startOfRange = monthStarts.first;
        final endOfRange = DateTime(monthStarts.last.year, monthStarts.last.month + 1, 0, 23, 59, 59);
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
          allSalesSnapshot = null;
        }
        final Map<int, MonthlyData> monthlyDataMap = {};
        for (int i = 0; i < 5; i++) {
          monthlyDataMap[i] = MonthlyData(label: monthLabels[i], petrolLitres: 0, dieselLitres: 0);
        }
        if (allSalesSnapshot != null) {
          for (var doc in allSalesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['custom_date'] as Timestamp).toDate();
            for (int i = 0; i < monthStarts.length; i++) {
              final start = monthStarts[i];
              final end = (i == monthStarts.length - 1)
                  ? DateTime(start.year, start.month + 1, 0, 23, 59, 59)
                  : monthStarts[i + 1].subtract(const Duration(days: 1));
              if (!date.isBefore(start) && !date.isAfter(end)) {
                monthlyDataMap[i]!.petrolLitres += (data['petrol_litres'] ?? 0).toDouble();
                monthlyDataMap[i]!.dieselLitres += (data['diesel_litres'] ?? 0).toDouble();
                break;
              }
            }
          }
        }
        result = monthlyDataMap.values.toList();
        break;
      case ChartTimeFrame.annual:
        final List<int> years = [for (int i = 4; i >= 0; i--) currentYear - i];
        final List<String> yearLabels = [for (final y in years) y.toString()];
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
          allSalesSnapshot = null;
        }
        Map<String, MonthlyData> annualData = {for (var l in yearLabels) l: MonthlyData(label: l, petrolLitres: 0, dieselLitres: 0)};
        if (allSalesSnapshot != null) {
          for (var doc in allSalesSnapshot.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final date = (data['custom_date'] as Timestamp).toDate();
            final label = date.year.toString();
            if (annualData.containsKey(label)) {
              annualData[label]!.petrolLitres += (data['petrol_litres'] ?? 0).toDouble();
              annualData[label]!.dieselLitres += (data['diesel_litres'] ?? 0).toDouble();
            }
          }
        }
        result = annualData.values.toList();
        break;
    }
    return result;
  }

  double _calculateMaxY() {
    if (monthlyData.isEmpty) return 5000.0;
    double maxValue = 0;
    for (var data in monthlyData) {
      maxValue = max(maxValue, max(data.petrolLitres, data.dieselLitres));
    }
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

  double max(double a, double b) => a > b ? a : b;

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
          _buildFilterOption(ChartTimeFrame.daily, isMobile ? 'D' : 'Daily', isMobile),
          _buildFilterOption(ChartTimeFrame.weekly, isMobile ? 'W' : 'Weekly', isMobile),
          _buildFilterOption(ChartTimeFrame.monthly, isMobile ? 'M' : 'Monthly', isMobile),
          _buildFilterOption(ChartTimeFrame.annual, isMobile ? 'Y' : 'Yearly', isMobile),
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
              getTextStyles: (value) => TextStyle(
                color: Colors.grey.shade700,
                fontWeight: FontWeight.bold,
                fontSize: isMobile ? 9 : 11,
              ),
              margin: isMobile ? 10 : 16,
              getTitles: (double value) {
                final index = value.toInt();
                if (index >= 0 && index < monthlyData.length) {
                  final label = monthlyData[index].label;
                  if (isMobile && label.length > 5) {
                    return '${label.substring(0, 4)}..';
                  }
                  return label;
                }
                return '';
              },
              rotateAngle: isMobile ? 30 : 0,
            ),
            leftTitles: SideTitles(
              showTitles: true,
              getTextStyles: (value) => TextStyle(
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
            show: !isMobile,
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final bool isTablet = MediaQuery.of(context).size.width >= 600 && MediaQuery.of(context).size.width < 1024;
    final double chartHeight = isMobile ? 300 : isTablet ? 380 : 450;
    final double titleFontSize = isMobile ? 16.0 : 20.0;
    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(isMobile ? 12.0 : 15.0),
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
              child: isChartLoading
                  ? Center(
                      child: CircularProgressIndicator(
                        color: Colors.green.shade600,
                      ),
                    )
                  : monthlyData.isEmpty
                      ? Center(
                          child: Text(
                            errorMessage.isNotEmpty ? errorMessage : 'No data available for the chart',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        )
                      : LayoutBuilder(
                          builder: (context, constraints) {
                            final availableWidth = constraints.maxWidth;
                            final barWidth = isMobile ? 8.0 : 18.0;
                            final barGroupWidth = barWidth * 2 + (isMobile ? 1.0 : 2.0);
                            final totalBarGroupsWidth = barGroupWidth * monthlyData.length;
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
                          },
                        ),
            ),
          ),
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
      ),
    );
  }
}

class MonthlyData {
  final String label;
  double petrolLitres;
  double dieselLitres;
  MonthlyData({required this.label, required this.petrolLitres, required this.dieselLitres});
}
