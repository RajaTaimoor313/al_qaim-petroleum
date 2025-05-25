import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'customer_tab.dart';
import 'dash_board_tab.dart';
import 'data_entry_tab.dart';
import 'test_query.dart';
import 'export_data.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Test Firestore connectivity (keeping the function but removing from AppBar)
  void _testFirestore() async {
    try {
      print('Testing Firestore connectivity...');
      await FirebaseFirestore.instance.collection('test').add({
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'Hello from Al Qaim app',
      });
      print('Firestore test successful');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Firestore test successful'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('Firestore test error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Firestore test error: $e\nEnsure your device has internet access.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  void _toggleDrawer() {
    if (_scaffoldKey.currentState!.isDrawerOpen) {
      _scaffoldKey.currentState!.closeDrawer();
    } else {
      _scaffoldKey.currentState!.openDrawer();
    }
  }

  void _openTestQuery() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const TestQuery()));
  }

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;
    final mediaQuerySize = MediaQuery.of(context).size;

    return Scaffold(
      key: _scaffoldKey,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(15)),
          child: AppBar(
            title: const Text(
              'AL QAIM PETROLEUM',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            centerTitle: true,
            backgroundColor: Colors.transparent,
            // Always show the menu button in AppBar for mobile
            leading:
                isMobile
                    ? IconButton(
                      icon: const Icon(Icons.menu, color: Colors.white),
                      onPressed: _toggleDrawer,
                    )
                    : null,
            actions: [
              // Remove debug button
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
      drawer:
          isMobile
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
                        // This adds the automatic back button
                        leading: IconButton(
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      Expanded(child: _buildPanelShow()),
                    ],
                  ),
                ),
              )
              : null,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child:
              isMobile
                  ? _buildSelectedScreen()
                  : Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 250,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.all(Radius.circular(15)),
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
                          height:
                              mediaQuerySize.height -
                              kToolbarHeight -
                              8, // SafeArea height adjusting for padding
                          margin: const EdgeInsets.only(left: 8.0),
                          child: _buildSelectedScreen(),
                        ),
                      ),
                    ],
                  ),
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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 70,
                width: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      blurRadius: 8,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    Icons.local_gas_station,
                    color: Colors.green.shade900,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'AL QAIM PETROLEUM',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        _buildPanelItem(0, Icons.dashboard, 'Dashboard'),
        _buildPanelItem(1, Icons.info, 'Add Data'),
        _buildPanelItem(2, Icons.people, 'Customers'),
        _buildPanelItem(3, Icons.file_download, 'Export'),
      ],
    );
  }

  Widget _buildPanelItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(
        icon,
        color: Colors.white,
        // Force a specific size to ensure visibility on web
        size: 24,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight:
              _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      selectedColor: Colors.white,
      onTap: () {
        setState(() => _selectedIndex = index);
        // Only close drawer, don't navigate on desktop
        if (MediaQuery.of(context).size.width < 600) {
          Navigator.pop(context);
        }
      },
    );
  }

  Widget _buildSelectedScreen() {
    // Use LayoutBuilder to get constraints passed to screen
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
        return const ExportData();
      default:
        return const Dashboard();
    }
  }
}
