import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:saitronics_billing/models/transaction.dart';
import 'package:saitronics_billing/utils/party_history_pdf_generator.dart';
import '../services/firebase_service.dart';
import 'add_edit_party_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Parties'),
        backgroundColor: Colors.green.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<List<Party>>(
        stream: FirebaseService.getParties(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final allParties = snapshot.data ?? [];
          
          final filteredParties = allParties.where((party) {
            return _searchQuery.isEmpty ||
                party.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                party.phone.contains(_searchQuery) ||
                party.gstNumber.toLowerCase().contains(_searchQuery.toLowerCase());
          }).toList();

          if (allParties.isEmpty) {
            return _buildEmptyState();
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {});
            },
            child: Column(
              children: [
                _buildCompactHeader(allParties),
                Expanded(
                  child: filteredParties.isEmpty
                      ? _buildNoResultsState()
                      : ListView.builder(
                          padding: const EdgeInsets.all(8),
                          itemCount: filteredParties.length,
                          itemBuilder: (context, index) {
                            final party = filteredParties[index];
                            return _buildCompactPartyCard(context, party);
                          },
                        ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditPartyScreen(),
            ),
          );
        },
        backgroundColor: Colors.green.shade600,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCompactHeader(List<Party> parties) {
    final toReceive = parties.fold<double>(
      0,
      (sum, party) => sum + (party.balance > 0 ? party.balance : 0),
    );
    final toPay = parties.fold<double>(
      0,
      (sum, party) => sum + (party.balance < 0 ? party.balance.abs() : 0),
    );

    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Stats Row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.green.shade600, Colors.green.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_downward,
                              size: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${_formatNumber(toReceive)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'To Receive',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade600, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.arrow_upward,
                              size: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '₹${_formatNumber(toPay)}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'To Pay',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.blue.shade600, Colors.blue.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withOpacity(0.3),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.people,
                              size: 18,
                              color: Colors.white.withOpacity(0.9),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${parties.length}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Total Parties',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withOpacity(0.9),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: const TextStyle(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          setState(() {
                            _searchQuery = '';
                          });
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 8),
                filled: true,
                fillColor: Colors.grey[50],
                isDense: true,
              ),
              style: const TextStyle(fontSize: 14),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactPartyCard(BuildContext context, Party party) {
    final balanceColor = party.balance > 0
        ? Colors.green.shade700
        : party.balance < 0
            ? Colors.red.shade700
            : Colors.grey.shade700;

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onLongPress: () => _deleteParty(context, party),
        onTap: () => _showPartyDetails(context, party),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.green.shade600.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(
                  Icons.person,
                  color: Colors.green.shade600,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              
              // Party Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      party.name,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (party.phone.isNotEmpty) ...[
                          Icon(Icons.phone, size: 10, color: Colors.grey[600]),
                          const SizedBox(width: 3),
                          Text(
                            party.phone,
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                        if (party.phone.isNotEmpty && party.gstNumber.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('•', style: TextStyle(color: Colors.grey[600])),
                          ),
                        if (party.gstNumber.isNotEmpty)
                          Expanded(
                            child: Text(
                              'GST: ${party.gstNumber}',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[600],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Balance
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    party.balance == 0 ? 'Settled' : party.getBalanceStatus(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: balanceColor,
                    ),
                  ),
                  if (party.balance != 0) ...[
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: balanceColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        party.balance > 0 ? 'Receive' : 'Pay',
                        style: TextStyle(
                          fontSize: 10,
                          color: balanceColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
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
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => PartyDetailsSheet(party: party),
    );
  }

  String _formatNumber(double value) {
    if (value >= 100000) {
      return '${(value / 100000).toStringAsFixed(1)}L';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}K';
    }
    return value.toStringAsFixed(0);
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No parties found',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first party',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          const Text(
            'No parties match your search',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  void _deleteParty(BuildContext context, Party party) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Party'),
        content: Text('Are you sure you want to delete "${party.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final result = await FirebaseService.deleteParty(party.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(result)),
                );
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
// PARTY DETAILS SHEET WITH TABS
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
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Color get balanceColor => widget.party.balance > 0
      ? Colors.green.shade700
      : widget.party.balance < 0
          ? Colors.red.shade700
          : Colors.grey.shade700;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.95,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Compact Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade600.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.person,
                          color: Colors.green.shade600,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.party.name,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.party.getBalanceStatus(),
                              style: TextStyle(
                                fontSize: 14,
                                color: balanceColor,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, size: 20),
                            color: Colors.green.shade600,
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => AddEditPartyScreen(party: widget.party),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, size: 20),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: Colors.white,
              child: TabBar(
                controller: _tabController,
                labelColor: Colors.green.shade600,
                unselectedLabelColor: Colors.grey,
                indicatorColor: Colors.green.shade600,
                labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                tabs: const [
                  Tab(text: 'Details'),
                  Tab(text: 'History'),
                  Tab(text: 'Unpaid'),
                ],
              ),
            ),

            // Tab Views
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDetailsTab(),
                  _buildHistoryTab(scrollController),
                  _buildUnpaidTab(scrollController),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // DETAILS TAB
  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (widget.party.phone.isNotEmpty)
            _buildDetailCard(Icons.phone, 'Phone', widget.party.phone, Colors.blue),
          if (widget.party.email.isNotEmpty)
            _buildDetailCard(Icons.email, 'Email', widget.party.email, Colors.orange),
          if (widget.party.address.isNotEmpty)
            _buildDetailCard(Icons.location_on, 'Address', widget.party.address, Colors.red),
          if (widget.party.gstNumber.isNotEmpty)
            _buildDetailCard(Icons.receipt_long, 'GST Number', widget.party.gstNumber, Colors.purple),
          
          const SizedBox(height: 16),
          
          // Balance Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.party.balance > 0
                    ? [Colors.green.shade600, Colors.green.shade700]
                    : widget.party.balance < 0
                        ? [Colors.red.shade600, Colors.red.shade700]
                        : [Colors.grey.shade600, Colors.grey.shade700],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: balanceColor.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      widget.party.balance > 0
                          ? Icons.arrow_downward
                          : widget.party.balance < 0
                              ? Icons.arrow_upward
                              : Icons.check_circle,
                      color: Colors.white.withOpacity(0.9),
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.party.balance > 0
                          ? 'You will receive'
                          : widget.party.balance < 0
                              ? 'You will pay'
                              : 'Settled',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${widget.party.balance.abs().toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(IconData icon, String label, String value, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // HISTORY TAB
  Widget _buildHistoryTab(ScrollController controller) {
    return Column(
      children: [
        // Date Filter
        Padding(
  padding: const EdgeInsets.all(12),
  child: Row(
    children: [
      // ---------- existing Filter button ----------
      Expanded(
        child: OutlinedButton.icon(
          onPressed: _selectDateRange,
          icon: const Icon(Icons.date_range, size: 18),
          label: Text(
            _selectedDateRange == null
                ? 'Filter by date'
                : '${DateFormat('dd MMM').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM').format(_selectedDateRange!.end)}',
            style: const TextStyle(fontSize: 13),
          ),
          style: OutlinedButton.styleFrom(
            foregroundColor: Colors.green.shade600,
            padding: const EdgeInsets.symmetric(vertical: 10),
            side: BorderSide(color: Colors.green.shade600),
          ),
        ),
      ),

      // ---------- clear filter ----------
      if (_selectedDateRange != null)
        IconButton(
          icon: const Icon(Icons.clear, size: 18, color: Colors.red),
          onPressed: () => setState(() => _selectedDateRange = null),
        ),

      const SizedBox(width: 8),

      // ---------- NEW DOWNLOAD BUTTON ----------
      SizedBox(
        width: 48,
        child: OutlinedButton(
          onPressed: () async {
            // collect the same list that is shown in the UI
            final snapshot = await FirebaseService.getTransactionsByParty(widget.party.id).first;
            var txns = snapshot ?? [];

            if (_selectedDateRange != null) {
              final start = _selectedDateRange!.start.subtract(const Duration(days: 1));
              final end   = _selectedDateRange!.end.add(const Duration(days: 1));
              txns = txns
                  .where((t) => t.transactionDate.isAfter(start) && t.transactionDate.isBefore(end))
                  .toList();
            }

            if (txns.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('No transactions to export')),
              );
              return;
            }

            final pdfBytes = await PdfGenerator.createPartyHistoryPdf(
              party: widget.party,
              transactions: txns,
              dateRange: _selectedDateRange,
            );

            await Printing.layoutPdf(
              onLayout: (format) async => pdfBytes,
              name:
                  '${widget.party.name.replaceAll(' ', '_')}_history_${_selectedDateRange == null ? 'all' : '${DateFormat('ddMMMyyyy').format(_selectedDateRange!.start)}-${DateFormat('ddMMMyyyy').format(_selectedDateRange!.end)}'}.pdf',
            );
          },
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            side: BorderSide(color: Colors.green.shade600),
          ),
          child: const Icon(Icons.download, size: 18, color: Colors.green),
        ),
      ),
    ],
  ),
),
        
        Expanded(
          child: StreamBuilder<List<Transaction>>(
            stream: FirebaseService.getTransactionsByParty(widget.party.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              var txns = snapshot.data ?? [];
              
              // Apply date filter
              if (_selectedDateRange != null) {
                final start = _selectedDateRange!.start.subtract(const Duration(days: 1));
                final end = _selectedDateRange!.end.add(const Duration(days: 1));
                txns = txns.where((t) => 
                  t.transactionDate.isAfter(start) && 
                  t.transactionDate.isBefore(end)
                ).toList();
              }

              if (txns.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 48, color: Colors.grey[400]),
                      const SizedBox(height: 12),
                      Text(
                        _selectedDateRange == null 
                            ? 'No transactions yet' 
                            : 'No transactions in selected range',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: txns.length,
                itemBuilder: (context, index) => _buildTransactionCard(txns[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  // UNPAID TAB
  Widget _buildUnpaidTab(ScrollController controller) {
    return StreamBuilder<List<Transaction>>(
      stream: FirebaseService.getUnpaidTransactionsByParty(widget.party.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final txns = snapshot.data ?? [];
        
        if (txns.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_circle, size: 48, color: Colors.green[400]),
                const SizedBox(height: 12),
                const Text(
                  'All cleared!',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  'No pending payments',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        final totalUnpaid = txns.fold(0.0, (sum, t) => sum + t.netAmount);

        return Column(
          children: [
            // Unpaid Summary Card
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.red.shade600, Colors.red.shade700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Unpaid',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '₹${totalUnpaid.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${txns.length} pending',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: ListView.builder(
                controller: controller,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                itemCount: txns.length,
                itemBuilder: (context, index) => _buildTransactionCard(
                  txns[index],
                  showPayButton: true,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTransactionCard(Transaction txn, {bool showPayButton = false}) {
    final isSale = txn.type == TransactionType.sale;
    final color = isSale ? Colors.green.shade700 : Colors.orange.shade700;
    final icon = isSale ? Icons.arrow_downward : Icons.arrow_upward;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        txn.invoiceNumber,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '₹${txn.netAmount.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Text(
                          txn.typeLabel,
                          style: TextStyle(
                            fontSize: 10,
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(Icons.calendar_today, size: 10, color: Colors.grey[600]),
                      const SizedBox(width: 3),
                      Text(
                        DateFormat('dd MMM yyyy').format(txn.transactionDate),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: txn.isPaid 
                              ? Colors.green.withOpacity(0.1) 
                              : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(
                            color: txn.isPaid ? Colors.green : Colors.red,
                          ),
                        ),
                        child: Text(
                          txn.isPaid ? 'Paid' : 'Unpaid',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: txn.isPaid ? Colors.green : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (showPayButton && !txn.isPaid) ...[
              const SizedBox(width: 8),
              SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: () => _markAsPaid(txn),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    minimumSize: const Size(0, 0),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  child: const Text(
                    'Pay',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
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
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.light(primary: Colors.green.shade600),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
    }
  }

  Future<void> _markAsPaid(Transaction txn) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mark as Paid'),
        content: Text(
          'Mark invoice ${txn.invoiceNumber} as paid?\n\nAmount: ₹${txn.netAmount.toStringAsFixed(2)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green.shade600,
            ),
            child: const Text('Mark Paid'),
          ),
        ],
      ),
    );
    
    if (confirm != true) return;

    final result = await FirebaseService.updateTransactionPaymentStatus(
      txn.id,
      true,
      'Cash',
    );
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result)),
      );
    }
  }
}