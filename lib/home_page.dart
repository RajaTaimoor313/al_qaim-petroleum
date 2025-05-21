import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'customer_tab.dart';
import 'dash_board_tab.dart';
import 'data_entry_tab.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Test Firestore connectivity
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = MediaQuery.of(context).size.width < 600;

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
            leading: isMobile
                ? IconButton(
                    icon: const Icon(Icons.menu, color: Colors.white),
                    onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                  )
                : null,
            actions: [
              IconButton(
                icon: const Icon(Icons.bug_report, color: Colors.white),
                onPressed: _testFirestore,
                tooltip: 'Test Firestore',
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
      drawer: isMobile ? _buildDrawer() : null,
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: isMobile
            ? _buildSelectedScreen()
            : Row(
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
                      margin: const EdgeInsets.only(left: 8.0),
                      child: _buildSelectedScreen(),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.green, Colors.green],
            begin: Alignment.topRight,
            end: Alignment.bottomRight,
          ),
        ),
        child: _buildPanelShow(),
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
      ],
    );
  }

  Widget _buildPanelItem(int index, IconData icon, String title) {
    return ListTile(
      leading: Icon(icon, color: Colors.white),
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
        if (MediaQuery.of(context).size.width < 600) Navigator.pop(context);
      },
    );
  }

  Widget _buildSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return const Dashboard();
      case 1:
        return const AddData();
      case 2:
        return const Customers();
      default:
        return const Dashboard();
    }
  }
}