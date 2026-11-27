import 'package:flutter/material.dart';

import '../../constants/categories.dart';
import '../../constants/shop_limits.dart';
import '../../models/geo_location.dart';
import '../../models/shop_profile.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/shop_validation.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/opening_hours_editor.dart';

enum ShopSetupMode { register, convert, edit }

class ShopSetupScreen extends StatefulWidget {
  final ShopSetupMode mode;
  final ShopProfile? initial;
  final ValueChanged<ShopProfile>? onSubmitted;

  const ShopSetupScreen({
    super.key,
    required this.mode,
    this.initial,
    this.onSubmitted,
  });

  @override
  State<ShopSetupScreen> createState() => _ShopSetupScreenState();
}

class _ShopSetupScreenState extends State<ShopSetupScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _descriptionController;
  late List<String> _categories;
  late OpeningHours _hours;
  GeoLocation? _location;
  String _locationLabel = '';

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _nameController = TextEditingController(text: initial?.shopName ?? '');
    _descriptionController = TextEditingController(
      text: initial?.description ?? '',
    );
    _categories = List.of(initial?.categories ?? const []);
    _hours = initial?.openingHours ?? const OpeningHours();
    _location = initial?.location;
    _locationLabel = initial?.locationLabel ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  ShopProfile? get _profile {
    final location = _location;
    if (location == null) return null;
    return ShopProfile(
      shopName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      categories: _categories,
      location: location,
      locationLabel: _locationLabel,
      openingHours: _hours,
    );
  }

  String? get _error {
    final profile = _profile;
    if (profile == null) return 'กรุณาเลือกที่ตั้งร้านบนแผนที่';
    return validateShopProfile(profile);
  }

  void _toggleCategory(String category, bool selected) {
    setState(() {
      if (selected) {
        if (_categories.length < kMaxShopCategories) _categories.add(category);
      } else {
        _categories.remove(category);
      }
    });
  }

  void _submit() {
    final profile = _profile;
    if (profile == null || _error != null) return;
    switch (widget.mode) {
      case ShopSetupMode.register:
        widget.onSubmitted?.call(profile);
      case ShopSetupMode.convert:
      case ShopSetupMode.edit:
        final state = AppState();
        final error = widget.mode == ShopSetupMode.convert
            ? state.convertCurrentUserToShop(profile)
            : state.updateShopProfile(profile);
        if (error != null) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          return;
        }
        widget.onSubmitted?.call(profile);
        Navigator.pop(context);
    }
  }

  String get _title => switch (widget.mode) {
    ShopSetupMode.register => 'ตั้งค่าร้านค้า',
    ShopSetupMode.convert => 'เปลี่ยนเป็นร้านค้า',
    ShopSetupMode.edit => 'แก้ไขข้อมูลร้าน',
  };

  String get _submitLabel => switch (widget.mode) {
    ShopSetupMode.register => 'ถัดไป: ยืนยันเบอร์โทร',
    ShopSetupMode.convert => 'เปลี่ยนเป็นร้านค้า',
    ShopSetupMode.edit => 'บันทึก',
  };

  @override
  Widget build(BuildContext context) {
    final error = _error;
    return Scaffold(
      appBar: AppBar(title: Text(_title)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                key: const ValueKey('shop-name'),
                controller: _nameController,
                maxLength: kMaxShopNameLength,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'ชื่อร้าน',
                  prefixIcon: Icon(
                    Icons.storefront_outlined,
                    color: AppColors.oceanBlue,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                key: const ValueKey('shop-description'),
                controller: _descriptionController,
                maxLength: kMaxShopDescriptionLength,
                maxLines: 3,
                onChanged: (_) => setState(() {}),
                decoration: const InputDecoration(
                  labelText: 'คำอธิบายร้าน',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'หมวดสินค้า',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  for (final category in kListingCategories)
                    FilterChip(
                      label: Text(category),
                      selected: _categories.contains(category),
                      onSelected: (selected) =>
                          _toggleCategory(category, selected),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              LocationPicker(
                title: 'ที่ตั้งร้าน',
                locationLabelTitle: 'ย่านที่ตั้งร้าน',
                showExactAddressField: false,
                showPrivacyNotice: false,
                initialLocation: widget.initial?.location,
                initialLocationLabel: widget.initial?.locationLabel ?? '',
                onChanged: (selection) => setState(() {
                  _location = selection.exactLocation;
                  _locationLabel = selection.locationLabel;
                }),
              ),
              const SizedBox(height: 16),
              const Text(
                'เวลาเปิด-ปิด',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              OpeningHoursEditor(
                value: _hours,
                onChanged: (hours) => setState(() => _hours = hours),
              ),
              const SizedBox(height: 16),
              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    error,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const ValueKey('shop-setup-submit'),
                  onPressed: error == null ? _submit : null,
                  child: Text(
                    _submitLabel,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
