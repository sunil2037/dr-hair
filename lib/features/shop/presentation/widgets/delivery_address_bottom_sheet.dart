import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../data/models/delivery_address_model.dart';

/// Modal bottom sheet allowing users to view saved delivery addresses, select an
/// active address, or add/edit a detailed address with live validation.
class DeliveryAddressBottomSheet extends StatefulWidget {
  final List<DeliveryAddress> addresses;
  final DeliveryAddress? selectedAddress;
  final ValueChanged<DeliveryAddress> onAddressSelected;
  final void Function(
    List<DeliveryAddress> updatedList,
    DeliveryAddress activeAddress,
  )?
  onAddressesUpdated;

  const DeliveryAddressBottomSheet({
    super.key,
    required this.addresses,
    this.selectedAddress,
    required this.onAddressSelected,
    this.onAddressesUpdated,
  });

  static Future<DeliveryAddress?> show({
    required BuildContext context,
    required List<DeliveryAddress> addresses,
    DeliveryAddress? selectedAddress,
    required ValueChanged<DeliveryAddress> onAddressSelected,
    void Function(
      List<DeliveryAddress> updatedList,
      DeliveryAddress activeAddress,
    )?
    onAddressesUpdated,
  }) {
    return showModalBottomSheet<DeliveryAddress>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DeliveryAddressBottomSheet(
        addresses: addresses,
        selectedAddress: selectedAddress,
        onAddressSelected: onAddressSelected,
        onAddressesUpdated: onAddressesUpdated,
      ),
    );
  }

  @override
  State<DeliveryAddressBottomSheet> createState() =>
      _DeliveryAddressBottomSheetState();
}

class _DeliveryAddressBottomSheetState
    extends State<DeliveryAddressBottomSheet> {
  late List<DeliveryAddress> _addresses;
  DeliveryAddress? _activeAddress;
  bool _isEditingOrAdding = false;
  DeliveryAddress? _addressBeingEdited;

  // Form controllers
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _houseController;
  late TextEditingController _streetController;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _pinController;
  String _selectedTag = 'Home';

  @override
  void initState() {
    super.initState();
    _addresses = List.from(widget.addresses);
    _activeAddress =
        widget.selectedAddress ??
        (_addresses.isNotEmpty ? _addresses.first : null);

    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _houseController = TextEditingController();
    _streetController = TextEditingController();
    _cityController = TextEditingController();
    _stateController = TextEditingController();
    _pinController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _houseController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  void _startAddAddress() {
    setState(() {
      _addressBeingEdited = null;
      _nameController.text = _activeAddress?.name ?? 'Yashveer Soni';
      _phoneController.text =
          _activeAddress?.phone.replaceAll('+91 ', '') ?? '9876543210';
      _houseController.clear();
      _streetController.clear();
      _cityController.text = 'Jaipur';
      _stateController.text = 'Rajasthan';
      _pinController.text = '302020';
      _selectedTag = 'Home';
      _isEditingOrAdding = true;
    });
  }

  void _startEditAddress(DeliveryAddress address) {
    setState(() {
      _addressBeingEdited = address;
      _nameController.text = address.name;
      _phoneController.text = address.phone.replaceAll('+91 ', '');
      _houseController.text = address.houseNumber;
      _streetController.text = address.street;
      _cityController.text = address.city;
      _stateController.text = address.state;
      _pinController.text = address.pinCode;
      _selectedTag = address.tag;
      _isEditingOrAdding = true;
    });
  }

  void _saveFormAddress() {
    if (!_formKey.currentState!.validate()) return;

    final phoneDigits = _phoneController.text.trim().replaceAll(
      RegExp(r'\D'),
      '',
    );
    final formattedPhone = phoneDigits.length == 10
        ? '+91 $phoneDigits'
        : _phoneController.text.trim();

    final saved = DeliveryAddress(
      id:
          _addressBeingEdited?.id ??
          'addr_${DateTime.now().millisecondsSinceEpoch}',
      name: _nameController.text.trim(),
      phone: formattedPhone,
      houseNumber: _houseController.text.trim(),
      street: _streetController.text.trim(),
      city: _cityController.text.trim(),
      state: _stateController.text.trim(),
      pinCode: _pinController.text.trim(),
      tag: _selectedTag,
      isDefault: _addressBeingEdited?.isDefault ?? (_addresses.isEmpty),
    );

    setState(() {
      if (_addressBeingEdited != null) {
        final idx = _addresses.indexWhere(
          (a) => a.id == _addressBeingEdited!.id,
        );
        if (idx != -1) {
          _addresses[idx] = saved;
        } else {
          _addresses.add(saved);
        }
      } else {
        _addresses.insert(0, saved);
      }
      _activeAddress = saved;
      _isEditingOrAdding = false;
    });

    widget.onAddressSelected(saved);
    widget.onAddressesUpdated?.call(_addresses, saved);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.88;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    if (_isEditingOrAdding)
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () =>
                            setState(() => _isEditingOrAdding = false),
                      ),
                    if (_isEditingOrAdding) const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditingOrAdding
                                ? (_addressBeingEdited != null
                                      ? 'Edit Address'
                                      : 'Add New Address')
                                : 'Select Delivery Address',
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isEditingOrAdding
                                ? 'Ensure accurate details for timely courier delivery'
                                : 'Choose where you want your Dr. Hair order delivered',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: AppColors.secondaryDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        LucideIcons.x,
                        size: 20,
                        color: AppColors.secondaryDark,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 20, color: AppColors.border),

              // Body Content
              Flexible(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                  child: _isEditingOrAdding
                      ? _buildAddressForm()
                      : _buildAddressList(),
                ),
              ),

              // Sticky Bottom Actions
              if (!_isEditingOrAdding)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: _activeAddress != null
                          ? 'Deliver to this Address'
                          : 'Select an Address',
                      variant: AppButtonVariant.filled,
                      onPressed: _activeAddress != null
                          ? () {
                              widget.onAddressSelected(_activeAddress!);
                              widget.onAddressesUpdated?.call(
                                _addresses,
                                _activeAddress!,
                              );
                              Navigator.pop(context, _activeAddress);
                            }
                          : null,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Add New Address Button
        InkWell(
          onTap: _startAddAddress,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primary5,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.primary100),
            ),
            child: const Row(
              children: [
                Icon(LucideIcons.plus, size: 18, color: AppColors.primary),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Add New Delivery Address',
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                Icon(
                  LucideIcons.chevronRight,
                  size: 16,
                  color: AppColors.primary,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        const Text(
          'SAVED ADDRESSES',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: AppColors.secondaryDark,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 10),

        if (_addresses.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: const Center(
              child: Text(
                'No saved addresses yet. Tap above to add one.',
                style: TextStyle(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
          )
        else
          ..._addresses.map((address) {
            final isSelected = _activeAddress?.id == address.id;

            return GestureDetector(
              onTap: () {
                setState(() => _activeAddress = address);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary5.withValues(alpha: 0.5)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.border,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isSelected ? 0.04 : 0.02,
                      ),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Radio indicator
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : AppColors.border,
                              width: 2,
                            ),
                            color: isSelected
                                ? AppColors.primary
                                : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(
                                    Icons.check,
                                    size: 13,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                        const SizedBox(width: 10),

                        // Name
                        Expanded(
                          child: Text(
                            address.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                        ),

                        // Tag Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: address.tag == 'Home'
                                ? const Color(0xFFEFF6FF)
                                : const Color(0xFFF3E8FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            address.tag.toUpperCase(),
                            style: TextStyle(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: address.tag == 'Home'
                                  ? const Color(0xFF1D4ED8)
                                  : const Color(0xFF7E22CE),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),

                        // Edit Button
                        IconButton(
                          icon: const Icon(
                            LucideIcons.pencil,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: 'Edit address',
                          onPressed: () => _startEditAddress(address),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Phone
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.phone,
                          size: 12,
                          color: AppColors.secondaryDark,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          address.phone,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.secondaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),

                    // Full Address
                    Text(
                      address.formattedAddress,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  Widget _buildAddressForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Tag Selection
          const Text(
            'ADDRESS TYPE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColors.secondaryDark,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: ['Home', 'Work', 'Other'].map((tag) {
              final isSelected = _selectedTag == tag;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(tag),
                  selected: isSelected,
                  selectedColor: AppColors.primary5,
                  labelStyle: TextStyle(
                    fontSize: 12,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  side: BorderSide(
                    color: isSelected ? AppColors.primary : AppColors.border,
                  ),
                  onSelected: (_) => setState(() => _selectedTag = tag),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),

          // Full Name & Phone
          _buildTextField(
            controller: _nameController,
            label: 'Full Name *',
            hint: 'e.g. Yashveer Soni',
            icon: LucideIcons.userRound,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter full name'
                : null,
          ),
          const SizedBox(height: 12),

          _buildTextField(
            controller: _phoneController,
            label: 'Mobile Number *',
            hint: '10-digit mobile number',
            prefixText: '+91 ',
            icon: LucideIcons.phone,
            keyboardType: TextInputType.phone,
            validator: (v) {
              final digits = (v ?? '').replaceAll(RegExp(r'\D'), '');
              if (digits.length != 10) {
                return 'Please enter a valid 10-digit number';
              }
              return null;
            },
          ),
          const SizedBox(height: 12),

          // Flat / House / Building
          _buildTextField(
            controller: _houseController,
            label: 'House / Flat / Building No. *',
            hint: 'e.g. Flat 402, Royal Residency',
            icon: LucideIcons.home,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter house/building info'
                : null,
          ),
          const SizedBox(height: 12),

          // Street / Area
          _buildTextField(
            controller: _streetController,
            label: 'Area / Street / Colony / Landmark *',
            hint: 'e.g. Shipra Path, Opp. Central Park, Mansarovar',
            icon: LucideIcons.mapPin,
            validator: (v) => (v == null || v.trim().isEmpty)
                ? 'Please enter area/colony'
                : null,
          ),
          const SizedBox(height: 12),

          // PIN code, City, State
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 4,
                child: _buildTextField(
                  controller: _pinController,
                  label: 'PIN Code *',
                  hint: '302020',
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    final clean = (v ?? '').trim();
                    if (clean.length != 6) return '6 digits';
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: _buildTextField(
                  controller: _cityController,
                  label: 'City *',
                  hint: 'Jaipur',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'City required' : null,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 5,
                child: _buildTextField(
                  controller: _stateController,
                  label: 'State *',
                  hint: 'Rajasthan',
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'State required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: AppButton(
              text: _addressBeingEdited != null
                  ? 'Update Address'
                  : 'Save & Select Address',
              variant: AppButtonVariant.filled,
              onPressed: _saveFormAddress,
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: TextButton(
              onPressed: () => setState(() => _isEditingOrAdding = false),
              child: const Text('Back to saved addresses'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    String? prefixText,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13.5, color: AppColors.primaryDark),
          decoration: InputDecoration(
            hintText: hint,
            prefixText: prefixText,
            prefixIcon: icon != null
                ? Icon(icon, size: 16, color: AppColors.primary)
                : null,
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
