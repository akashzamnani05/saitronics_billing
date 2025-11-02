import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/transaction.dart';
import '../services/firebase_service.dart';
import 'add_edit_party_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parties'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Compact Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search name, phone, GST...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value.toLowerCase();
                });
              },
            ),
          ),

          // Parties List
          Expanded(
            child: StreamBuilder<List<Party>>(
              stream: FirebaseService.getParties(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final allParties = snapshot.data ?? [];
                final parties = allParties.where((party) {
                  if (_searchQuery.isEmpty) return true;
                  return party.name.toLowerCase().contains(_searchQuery) ||
                      party.phone.contains(_searchQuery) ||
                      party.gstNumber.toLowerCase().contains(_searchQuery) ||
                      party.email.toLowerCase().contains(_searchQuery);
                }).toList();

                if (allParties.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No parties found', style: TextStyle(fontSize: 16, color: Colors.grey)),
                        Text('Tap + to add', style: TextStyle(fontSize: 13, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                if (parties.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 48, color: Colors.grey),
                        SizedBox(height: 12),
                        Text('No matching parties', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(6),
                  itemCount: parties.length,
                  itemBuilder: (context, index) => _buildCompactPartyCard(context, parties[index]),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        mini: true,
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditPartyScreen()),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCompactPartyCard(BuildContext context, Party party) {
    final balanceColor = party.balance > 0
        ? Colors.green
        : party.balance < 0
            ? Colors.red
            : Colors.grey;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      child: InkWell(
        onTap: () => _showPartyDetails(context, party),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: Colors.green,
                child: Text(
                  party.name[0].toUpperCase(),
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (party.phone.isNotEmpty)
                      Text(
                        party.phone,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    if (party.gstNumber.isNotEmpty)
                      Text(
                        'GST: ${party.gstNumber}',
                        style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                      ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: balanceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: balanceColor),
                      ),
                      child: Text(
                        party.getBalanceStatus(),
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: balanceColor),
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, size: 18, color: Colors.blue),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AddEditPartyScreen(party: party)),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minHeight: 28, minWidth: 28),
                    onPressed: () => _deleteParty(context, party),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPartyDetails(BuildContext context, Party party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => PartyDetailsSheet(party: party),
    );
  }

  void _deleteParty(BuildContext context, Party party) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Party'),
        content: Text('Delete "${party.name}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await FirebaseService.deleteParty(party.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ============================================
// COMPACT FULL-SCREEN PARTY DETAILS SHEET
// ============================================
class PartyDetailsSheet extends StatefulWidget {
  final Party party;
  const PartyDetailsSheet({super.key, required this.party});

  @override
  State<PartyDetailsSheet> createState() => _PartyDetailsSheetState();
}

class _PartyDetailsSheetState extends State<PartyDetailsSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get balanceColor => widget.party.balance > 0
      ? Colors.green
      : widget.party.balance < 0
          ? Colors.red
          : Colors.grey;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 1.0,
      minChildSize: 0.9,
      maxChildSize: 1.0,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Compact Header
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  Container(width: 36, height: 4, decoration: BoxDecoration(color: Colors.grey[400], borderRadius: BorderRadius.circular(2))),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: Colors.green,
                        child: Text(widget.party.name[0].toUpperCase(), style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.party.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                            if (widget.party.phone.isNotEmpty)
                              Text(widget.party.phone, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: balanceColor.withOpacity(0.15), borderRadius: BorderRadius.circular(6), border: Border.all(color: balanceColor)),
                        child: Text(widget.party.getBalanceStatus(), style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: balanceColor)),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            TabBar(
              controller: _tabController,
              labelColor: Colors.green,
              unselectedLabelColor: Colors.grey,
              indicatorColor: Colors.green,
              labelPadding: const EdgeInsets.symmetric(vertical: 8),
              tabs: const [
                Tab(icon: Icon(Icons.history, size: 18), text: 'All'),
                Tab(icon: Icon(Icons.payment, size: 18), text: 'Unpaid'),
              ],
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAllTransactionsTab(scrollController),
                  _buildUnpaidTab(scrollController),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ALL TRANSACTIONS (Compact + Date Filter)
  Widget _buildAllTransactionsTab(ScrollController controller) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    _selectedDateRange == null
                        ? 'Filter'
                        : '${DateFormat('dd MMM').format(_selectedDateRange!.start)}-${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    side: const BorderSide(color: Colors.green),
                  ),
                ),
              ),
              if (_selectedDateRange != null)
                IconButton(icon: const Icon(Icons.clear, size: 16, color: Colors.red), onPressed: () => setState(() => _selectedDateRange = null)),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Transaction>>(
            stream: FirebaseService.getTransactionsByParty(widget.party.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12)));

              var txns = snapshot.data ?? [];
              if (_selectedDateRange != null) {
                final start = _selectedDateRange!.start.subtract(const Duration(days: 1));
                final end = _selectedDateRange!.end.add(const Duration(days: 1));
                txns = txns.where((t) => t.transactionDate.isAfter(start) && t.transactionDate.isBefore(end)).toList();
              }

              if (txns.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 40, color: Colors.grey[400]),
                      const SizedBox(height: 8),
                      Text(_selectedDateRange == null ? 'No transactions' : 'None in range', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: txns.length,
                itemBuilder: (_, i) => _buildCompactTxnCard(txns[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  // UNPAID TAB (Compact)
  Widget _buildUnpaidTab(ScrollController controller) {
    return StreamBuilder<List<Transaction>>(
      stream: FirebaseService.getUnpaidTransactionsByParty(widget.party.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(fontSize: 12)));

        final txns = snapshot.data ?? [];
        if (txns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 40, color: Colors.green[400]),
                const SizedBox(height: 8),
                const Text('All paid!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green)),
                Text('No pending', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              ],
            ),
          );
        }

        final total = txns.fold(0.0, (s, t) => s + t.netAmount);

        return Column(
          children: [
            Container(
              margin: const EdgeInsets.all(8),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.red.shade50, borderRadius: BorderRadius.circular(8), border: Border.all(color: Colors.red.shade200)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Unpaid', style: TextStyle(fontSize: 12)),
                      Text('₹${total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(12)),
                    child: Text('${txns.length} pending', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                itemCount: txns.length,
                itemBuilder: (_, i) => _buildCompactTxnCard(txns[i], showPay: true),
              ),
            ),
          ],
        );
      },
    );
  }

  // Compact Transaction Card
  Widget _buildCompactTxnCard(Transaction t, {bool showPay = false}) {
    final isSale = t.type == TransactionType.sale;
    final color = isSale ? Colors.green : Colors.orange;
    final icon = isSale ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 3),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            CircleAvatar(radius: 14, backgroundColor: color.withOpacity(0.1), child: Icon(icon, size: 16, color: color)),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(t.invoiceNumber, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                      Text('₹${t.netAmount.toStringAsFixed(0)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
                    ],
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(3)),
                        child: Text(t.typeLabel, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(width: 6),
                      Text(DateFormat('dd MMM').format(t.transactionDate), style: TextStyle(fontSize: 10, color: Colors.grey[600])),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: t.isPaid ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: t.isPaid ? Colors.green : Colors.red),
                        ),
                        child: Text(t.isPaid ? 'Paid' : 'Unpaid', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: t.isPaid ? Colors.green : Colors.red)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showPay && !t.isPaid)
              SizedBox(
                height: 28,
                child: TextButton(
                  onPressed: () => _markAsPaid(t),
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8), backgroundColor: Colors.green, foregroundColor: Colors.white, minimumSize: const Size(0, 0)),
                  child: const Text('Pay', style: TextStyle(fontSize: 10)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _selectedDateRange,
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: const ColorScheme.light(primary: Colors.green)), child: child!),
    );
    if (picked != null) setState(() => _selectedDateRange = picked);
  }

  Future<void> _markAsPaid(Transaction t) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mark Paid'),
        content: Text('Mark ${t.invoiceNumber} paid?\n₹${t.netAmount.toStringAsFixed(2)}'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.green), child: const Text('Paid')),
        ],
      ),
    );
    if (confirm != true) return;

    final result = await FirebaseService.updateTransactionPaymentStatus(t.id, true, 'Cash');
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result)));
  }
}