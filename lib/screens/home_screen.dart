// lib/screens/home_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saitronics_billing/models/purchase_invoice.dart';
import 'package:saitronics_billing/models/sales_invoice.dart';
import 'package:saitronics_billing/models/item.dart';
import 'package:saitronics_billing/models/user_role.dart';
import 'package:saitronics_billing/services/auth_service.dart';

import 'GST_purchase_report.dart';
import 'GST_sales_report.dart';
import 'purchase_invoices_list_screen.dart';
import 'sales_invoice_list_screen.dart';
import 'items_screen.dart';
import 'parties_screen.dart';
import 'today_sales_invoices_screen.dart'; // Import the new screen

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // Indian Rupee Formatter
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');

  @override
  Widget build(BuildContext context) {
    final DateTime now = DateTime.now();
    final DateTime startOfDay = DateTime(now.year, now.month, now.day);
    final DateTime endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Saitronics Inventory'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        elevation: 2,
        actions: [
          FutureBuilder<AppUser?>(
    future: AuthService.getCurrentAppUser(),
    builder: (context, snapshot) {
      final user = snapshot.data;
      return PopupMenuButton(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: Row(
            children: [
              Icon(user?.role == UserRole.admin 
                ? Icons.admin_panel_settings 
                : Icons.business_center),
              SizedBox(width: 8),
              Text(user?.roleLabel ?? ''),
            ],
          ),
        ),
        itemBuilder: (context) => [
          PopupMenuItem(
            child: Text('Logout'),
            onTap: () async {
              await AuthService.logout();
              // Will automatically redirect to login
            },
          ),
        ],
      );
    },
  ),
        ],
      ),
      drawer: _buildSidebar(context),

      body: RefreshIndicator(
        onRefresh: () async => Future.delayed(const Duration(seconds: 1)),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Today's Summary Title
              Text(
                'Today\'s Summary',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade800,
                    ),
              ),
              const SizedBox(height: 12),

              // Purchase & Sales Cards
              Row(
                children: [
                  Expanded(
                    child: _TodayCard(
                      title: 'Purchases',
                      start: startOfDay,
                      end: endOfDay,
                      collection: 'purchaseInvoices',
                      color: Colors.orange,
                      icon: Icons.shopping_cart,
                      amountBuilder: (invoices) => invoices.fold(0.0, (s, i) => s + i.total),
                      gstBuilder: (invoices) => invoices.fold(0.0, (s, i) => s + i.totalGst),
                      onTap: null, // Can add purchase screen later if needed
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TodayCard(
                      title: 'Sales',
                      start: startOfDay,
                      end: endOfDay,
                      collection: 'salesInvoices',
                      color: Colors.purple,
                      icon: Icons.point_of_sale,
                      amountBuilder: (invoices) => invoices.fold(0.0, (s, i) => s + i.grandTotal),
                      gstBuilder: (invoices) => invoices.fold(0.0, (s, i) => s + i.totalGst),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TodaySalesInvoicesScreen(
                              startDate: startOfDay,
                              endDate: endOfDay,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Stock Overview
              Text(
                'Stock Overview',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade800,
                    ),
              ),
              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance.collection('items').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snapshot.data!.docs
                      .map((doc) => Item.fromMap(doc.data()))
                      .toList();

                  final totalItems = items.length;
                  final lowStock = items.where((i) => i.currentStock < 5).length;
                  final totalValue = items.fold(
                      0.0, (s, i) => s + (i.currentStock * i.purchasePrice));

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _StockInfo(
                            label: 'Total Items',
                            value: '$totalItems',
                            icon: Icons.inventory_2,
                            color: Colors.blue,
                          ),
                          _StockInfo(
                            label: 'Low Stock',
                            value: '$lowStock',
                            icon: Icons.warning_amber,
                            color: lowStock > 0 ? Colors.red : Colors.grey,
                          ),
                          _StockInfo(
                            label: 'Stock Value',
                            value: _currency.format(totalValue),
                            icon: Icons.account_balance_wallet,
                            color: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 80), // Extra space for FAB if added later
            ],
          ),
        ),
      ),
    );
  }

  // Sidebar Drawer
  Widget _buildSidebar(BuildContext context) {
    final List<_MenuItem> menuItems = [
      _MenuItem('Items', Icons.inventory_2, Colors.blue, const ItemsScreen()),
      _MenuItem('Parties', Icons.people, Colors.green, const PartiesScreen()),
      _MenuItem('Purchase Invoice', Icons.shopping_cart, Colors.orange, const PurchaseInvoicesListScreen()),
      _MenuItem('Sales Invoice', Icons.point_of_sale, Colors.purple, const SalesInvoicesListScreen()),
      _MenuItem('GST Purchase Report', Icons.book_rounded, Colors.orange.shade700, const GSTPurchaseReport()),
      _MenuItem('GST Sales Report', Icons.book, Colors.purple.shade700, const GSTSalesReport()),
    ];

    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.shade700, Colors.blue.shade500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: const Center(
              child: Text(
                'Saitronics',
                style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: menuItems.length,
              itemBuilder: (context, index) {
                final item = menuItems[index];
                return ListTile(
                  leading: Icon(item.icon, color: item.color),
                  title: Text(item.title),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => item.destination),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// Today Card (Purchase / Sales)
class _TodayCard extends StatelessWidget {
  final String title;
  final DateTime start;
  final DateTime end;
  final String collection;
  final Color color;
  final IconData icon;
  final double Function(List<dynamic>) amountBuilder;
  final double Function(List<dynamic>) gstBuilder;
  final VoidCallback? onTap; // Add onTap callback

  const _TodayCard({
    required this.title,
    required this.start,
    required this.end,
    required this.collection,
    required this.color,
    required this.icon,
    required this.amountBuilder,
    required this.gstBuilder,
    this.onTap, // Optional onTap
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(collection)
                .where('invoiceDate', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
                .where('invoiceDate', isLessThanOrEqualTo: Timestamp.fromDate(end))
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Center(child: CircularProgressIndicator(strokeWidth: 2));
              }

              final docs = snapshot.data!.docs;
              final invoices = collection == 'purchase_invoices'
                  ? docs.map((d) => PurchaseInvoice.fromMap(d.data())).toList()
                  : docs.map((d) => SalesInvoice.fromMap(d.data())).toList();

              final count = invoices.length;
              final amount = amountBuilder(invoices);
              final gst = gstBuilder(invoices);

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, color: color, size: 28),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: color,
                          ),
                        ),
                      ),
                      if (onTap != null)
                        Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: color.withOpacity(0.6),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '$count invoice${count == 1 ? '' : 's'}',
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _currency.format(amount),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'GST: ${_currency.format(gst)}',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹');
}

// Stock Info Tile
class _StockInfo extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StockInfo({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 32, color: color),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}

// Menu Item Model
class _MenuItem {
  final String title;
  final IconData icon;
  final Color color;
  final Widget destination;

  _MenuItem(this.title, this.icon, this.color, this.destination);
}
