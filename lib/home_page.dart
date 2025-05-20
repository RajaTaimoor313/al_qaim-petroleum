import 'package:al_qaim/dash_board_tab.dart';
import 'package:al_qaim/data_entry_tab.dart';
import 'package:flutter/material.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final double _maxPanelWidth = 250.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight),
        child: ClipRRect(
          borderRadius: BorderRadius.all(Radius.circular(15)),
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
            flexibleSpace: Container(
              decoration: BoxDecoration(
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
      body: Padding(
        padding: const EdgeInsets.all(4.0),
        child: Row(
          children: [
            Container(
              width: _maxPanelWidth,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(15)),
                gradient: LinearGradient(
                  colors: [
                    Colors.green,
                    Colors.green.shade800,
                  ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomRight,
                ),
              ),
              child: _buildPanelShow(),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.only(left: 4.0, right: 4.0),
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
        _buildpanelItem(0, Icons.dashboard, 'Dashboard'),
        _buildpanelItem(1, Icons.info, 'Add Data'),
        _buildpanelItem(2, Icons.people, 'Customers'),
      ],
    );
  }

  Widget _buildpanelItem(int index, IconData icon, String title) {
    return Container(
      padding: const EdgeInsets.all(2.0),
      child: ListTile(
        leading: Icon(
          icon,
          color: Colors.white,
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
        onTap: () => setState(() {
          _selectedIndex = index;
        }),
      ),
    );
  }

  Widget _buildSelectedScreen() {
    switch (_selectedIndex) {
      case 0:
        return Dashboard();
      case 1:
        return AddData();
      case 2:
        return _buildCustomersContent();
      default:
        return Dashboard();
    }
  }
  
  Widget _buildCustomersContent() {
    return Container(
      padding: const EdgeInsets.all(16.0),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Customer List',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: ListView.builder(
              itemCount: 10,
              itemBuilder: (context, index) {
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.green,
                      child: Text('${index + 1}'),
                    ),
                    title: Text('Customer ${index + 1}'),
                    subtitle: Text('Last purchase: ${10000 + (index * 500)}'),
                    trailing: Icon(Icons.arrow_forward_ios),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  

}
