import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:saitronics_billing/models/party.dart';
import 'package:uuid/uuid.dart';
import '../services/firebase_service.dart';
import '../widgets/custom_text_field.dart';

class AddEditPartyScreen extends StatefulWidget {
  final Party? party;

  const AddEditPartyScreen({super.key, this.party});

  @override
  State<AddEditPartyScreen> createState() => _AddEditPartyScreenState();
}

class _AddEditPartyScreenState extends State<AddEditPartyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _gstController = TextEditingController();
  final _panController = TextEditingController();

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.party != null) {
      _nameController.text = widget.party!.name;
      _addressController.text = widget.party!.address;
      _emailController.text = widget.party!.email;
      _phoneController.text = widget.party!.phone;
      _gstController.text = widget.party!.gstNumber;
      _panController.text = widget.party!.panNumber;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _gstController.dispose();
    _panController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.party != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Party' : 'Add New Party',
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF4CAF50),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Header Card with Animation
            TweenAnimationBuilder(
              duration: const Duration(milliseconds: 500),
              tween: Tween<double>(begin: 0, end: 1),
              builder: (context, double value, child) {
                return Transform.scale(
                  scale: value,
                  child: Opacity(
                    opacity: value,
                    child: child,
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF4CAF50).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.person_add_alt_1_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing ? 'Update Party Details' : 'Create New Party',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isEditing
                                ? 'Modify party information below'
                                : 'Fill in all the required details',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Basic Information Section
            _buildSectionCard(
              title: 'Basic Information',
              icon: Icons.info_outline_rounded,
              children: [
                CustomTextField(
                  controller: _nameController,
                  label: 'Party Name',
                  hint: 'e.g., ABC Electronics Pvt Ltd',
                  prefixIcon: Icons.business_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter party name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _addressController,
                  label: 'Address',
                  hint: 'Enter complete address',
                  prefixIcon: Icons.location_on_rounded,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.words,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter address';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Contact Information Section
            _buildSectionCard(
              title: 'Contact Information',
              icon: Icons.contact_phone_rounded,
              children: [
                CustomTextField(
                  controller: _phoneController,
                  label: 'Phone Number',
                  hint: 'e.g., 9876543210',
                  prefixIcon: Icons.phone_rounded,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid 10-digit number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _emailController,
                  label: 'Email Address',
                  hint: 'e.g., contact@company.com',
                  prefixIcon: Icons.email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  // validator: (value) {
                  //   if (value == null || value.isEmpty) {
                  //     return 'Please enter email';
                  //   }
                  //   if (!value.contains('@') || !value.contains('.')) {
                  //     return 'Please enter a valid email';
                  //   }
                  //   return null;
                  // },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Tax Information Section
            _buildSectionCard(
              title: 'Tax Information',
              icon: Icons.receipt_long_rounded,
              subtitle: 'Optional details',
              children: [
                CustomTextField(
                  controller: _gstController,
                  label: 'GST Number',
                  hint: 'e.g., 22AAAAA0000A1Z5',
                  prefixIcon: Icons.account_balance_rounded,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    LengthLimitingTextInputFormatter(15),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length != 15) {
                      return 'GST number must be 15 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  controller: _panController,
                  label: 'PAN Number',
                  hint: 'e.g., ABCDE1234F',
                  prefixIcon: Icons.credit_card_rounded,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Z0-9]')),
                    LengthLimitingTextInputFormatter(10),
                  ],
                  validator: (value) {
                    if (value != null && value.isNotEmpty && value.length != 10) {
                      return 'PAN number must be 10 characters';
                    }
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Save Button with Gradient
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF4CAF50), Color(0xFF45A049)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF4CAF50).withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveParty,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            isEditing ? Icons.check_circle_rounded : Icons.person_add_rounded,
                            size: 24,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            isEditing ? 'Update Party' : 'Add Party',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Info Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue[700],
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Important Information',
                          style: TextStyle(
                            color: Colors.blue[900],
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Fields marked with * are mandatory. GST and PAN details are optional but recommended for business transactions.',
                          style: TextStyle(
                            color: Colors.blue[800],
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  size: 22,
                  color: const Color(0xFF4CAF50),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Future<void> _saveParty() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please fill all required fields correctly'),
          backgroundColor: Colors.orange[700],
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final now = DateTime.now();

    final party = Party(
      id: widget.party?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      address: _addressController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      gstNumber: _gstController.text.trim(),
      panNumber: _panController.text.trim(),
      createdAt: widget.party?.createdAt ?? now,
      updatedAt: now,
    );

    final result = widget.party != null
        ? await FirebaseService.updateParty(party)
        : await FirebaseService.createParty(party);

    setState(() {
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result),
          backgroundColor: result.contains('successfully')
              ? Colors.green[700]
              : Colors.red[700],
        ),
      );
      if (result.contains('successfully')) {
        Navigator.pop(context);
      }
    }
  }
}