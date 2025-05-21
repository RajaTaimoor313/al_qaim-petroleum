import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final bool isMobile = screenSize.width < 600;
    final bool isTablet = screenSize.width >= 600 && screenSize.width < 1024;

    return Container(
      padding: EdgeInsets.all(isMobile ? 12.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(15),
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
          _buildHeader(context),
          const SizedBox(height: 24),
          _buildSummaryCards(context, isMobile, isTablet),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Dashboard',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.green.shade800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Welcome back! Here\'s your overview',
              style: TextStyle(
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
            children: [
              Icon(
                Icons.calendar_today,
                size: 18,
                color: Colors.green.shade600,
              ),
              const SizedBox(width: 8),
              Text(
                DateFormat('MMMM d, yyyy').format(DateTime.now()),
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(
    BuildContext context,
    bool isMobile,
    bool isTablet,
  ) {
    if (isMobile) {
      return Column(
        children: [
          _buildInfoCard(
            'Regular Accounts',
            '256',
            Icons.account_balance_wallet,
            Colors.green.shade600,
            Colors.green.shade50,
            context,
            isFullWidth: true,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Closed Accounts',
            '42',
            Icons.people,
            Colors.blue.shade600,
            Colors.blue.shade50,
            context,
            isFullWidth: true,
          ),
          const SizedBox(height: 12),
          _buildInfoCard(
            'Total Revenue',
            '\$1,254,892',
            Icons.monetization_on,
            Colors.orange.shade600,
            Colors.orange.shade50,
            context,
            isFullWidth: true,
          ),
        ],
      );
    }
    if (isTablet) {
      return Column(
        children: [
          Row(
            children: [
              _buildInfoCard(
                'Regular Accounts',
                '256',
                Icons.account_balance_wallet,
                Colors.green.shade600,
                Colors.green.shade50,
                context,
              ),
              const SizedBox(width: 16),
              _buildInfoCard(
                'Closed Accounts',
                '42',
                Icons.people,
                Colors.blue.shade600,
                Colors.blue.shade50,
                context,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoCard(
            'Total Revenue',
            '\$1,254,892',
            Icons.monetization_on,
            Colors.orange.shade600,
            Colors.orange.shade50,
            context,
            isFullWidth: true,
          ),
        ],
      );
    }
    return Row(
      children: [
        _buildInfoCard(
          'Regular Accounts',
          '256',
          Icons.account_balance_wallet,
          Colors.green.shade600,
          Colors.green.shade50,
          context,
        ),
        const SizedBox(width: 16),
        _buildInfoCard(
          'Closed Accounts',
          '42',
          Icons.people,
          Colors.blue.shade600,
          Colors.blue.shade50,
          context,
        ),
        const SizedBox(width: 16),
        _buildInfoCard(
          'Total Revenue',
          '\$1,254,892',
          Icons.monetization_on,
          Colors.orange.shade600,
          Colors.orange.shade50,
          context,
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
    Color bgColor,
    BuildContext context, {
    bool isFullWidth = false,
  }) {
    return Expanded(
      flex: isFullWidth ? 2 : 1,
      child: Container(
        padding: const EdgeInsets.all(20),
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
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              height: 6,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    iconColor.withOpacity(0.3),
                    iconColor.withOpacity(0.05),
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}