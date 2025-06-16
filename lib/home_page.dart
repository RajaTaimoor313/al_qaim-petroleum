import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'auth/activity_service.dart';
import 'auth/password_screen.dart';
import 'customer_tab.dart';
import 'dash_board_tab.dart';
import 'data_entry_tab.dart';
import 'export_data.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';

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
    final mediaQuerySize = MediaQuery.of(context).size;

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
        ListTile(
          leading: const Icon(Icons.dashboard, color: Colors.white),
          title: Text(
            'Dashboard',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: _selectedIndex == 0,
          onTap: () {
            setState(() {
              _selectedIndex = 0;
            });
            if (MediaQuery.of(context).size.width < 600) {
              Navigator.pop(context);
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.add_chart, color: Colors.white),
          title: Text(
            'Add Data',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: _selectedIndex == 1,
          onTap: () {
            setState(() {
              _selectedIndex = 1;
            });
            if (MediaQuery.of(context).size.width < 600) {
              Navigator.pop(context);
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.people, color: Colors.white),
          title: Text(
            'Customers',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: _selectedIndex == 2,
          onTap: () {
            setState(() {
              _selectedIndex = 2;
            });
            if (MediaQuery.of(context).size.width < 600) {
              Navigator.pop(context);
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.file_download, color: Colors.white),
          title: Text(
            'Export',
            style: GoogleFonts.lato(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          selected: _selectedIndex == 3,
          onTap: () {
            setState(() {
              _selectedIndex = 3;
            });
            if (MediaQuery.of(context).size.width < 600) {
              Navigator.pop(context);
            }
          },
        ),
      ],
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
        return const ExportData();
      default:
        return const Dashboard();
    }
  }
}
