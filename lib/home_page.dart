import 'package:flutter/material.dart';
import 'auth/auth_service.dart';
import 'auth/activity_service.dart';
import 'auth/password_screen.dart';
import 'customer_tab.dart';
import 'dash_board_tab.dart';
import 'data_entry_tab.dart';
import 'export_data.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AuthService _authService = AuthService();
  final ActivityService _activityService = ActivityService();

  @override
  void initState() {
    super.initState();
    _activityService.startActivityTimer(context);
  }

  @override
  void dispose() {
    _activityService.stopTimer();
    super.dispose();
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
        child: Container(
          padding: const EdgeInsets.only(top: 10),
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
      ),
      drawer: isMobile
        ? Drawer(
            child: Container(
              padding: const EdgeInsets.only(top: 10),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(4.0),
          child: isMobile
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
                      height: mediaQuerySize.height - (kToolbarHeight + 18),
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
              SizedBox(height: 10),
              FutureBuilder<String?>(
                future: SharedPreferences.getInstance().then((prefs) => prefs.getString('user_role')),
                builder: (context, snapshot) {
                  if (snapshot.hasData && snapshot.data != null) {
                    return Text(
                      'Logged in as ${snapshot.data!}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    );
                  }
                  return const SizedBox.shrink();
                },
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
      leading: Icon(icon, color: Colors.white, size: 24),
      title: Text(
        title,
        style: TextStyle(
          color: Colors.white,
          fontWeight: _selectedIndex == index ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: _selectedIndex == index,
      selectedColor: Colors.white,
      onTap: () {
        setState(() => _selectedIndex = index);
        if (MediaQuery.of(context).size.width < 600) {
          Navigator.pop(context);
        }
      },
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
