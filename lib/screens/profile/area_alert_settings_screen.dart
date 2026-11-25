import 'package:flutter/material.dart';

import '../../constants/trust_safety_limits.dart';
import '../../models/geo_location.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/location_picker.dart';

class AreaAlertSettingsScreen extends StatefulWidget {
  const AreaAlertSettingsScreen({super.key});

  @override
  State<AreaAlertSettingsScreen> createState() =>
      _AreaAlertSettingsScreenState();
}

class _AreaAlertSettingsScreenState extends State<AreaAlertSettingsScreen> {
  late bool _enabled;
  late double _radiusKm;
  late Set<String> _categories;
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    final user = appState.currentUser;
    final subscription = appState.areaAlertSubscriptionFor(user.id);
    if (!_initialized) {
      _enabled = subscription.enabled;
      _radiusKm = subscription.radiusKm;
      _categories = subscription.categories.toSet();
      _initialized = true;
    }
    final categories =
        appState.products.map((product) => product.category).toSet().toList()
          ..sort();
    return Scaffold(
      appBar: AppBar(title: const Text('แจ้งเตือนสินค้าใกล้พื้นที่')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('เปิดการแจ้งเตือนในพื้นที่'),
            value: _enabled,
            onChanged: (value) => setState(() => _enabled = value),
          ),
          const SizedBox(height: 10),
          Text(
            'รัศมี ${_radiusKm.toStringAsFixed(0)} กม.',
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: AppColors.deepNavy,
            ),
          ),
          Slider(
            value: _radiusKm,
            min: kAreaAlertMinRadiusKm,
            max: kAreaAlertMaxRadiusKm,
            divisions: (kAreaAlertMaxRadiusKm - kAreaAlertMinRadiusKm).round(),
            label: '${_radiusKm.toStringAsFixed(0)} กม.',
            onChanged: (value) => setState(() => _radiusKm = value),
          ),
          const SizedBox(height: 10),
          Text(
            'พื้นที่ที่ใช้: ${user.homeLabel.isEmpty ? 'พื้นที่เริ่มต้น' : user.homeLabel}',
            style: const TextStyle(color: AppColors.graySecondary),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => _changeArea(context, appState),
              icon: const Icon(Icons.location_on_outlined),
              label: const Text('เปลี่ยนพื้นที่'),
            ),
          ),
          const Divider(),
          const Text(
            'หมวดหมู่ (ไม่เลือก = ทุกหมวด)',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final category in categories)
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(category),
              value: _categories.contains(category),
              onChanged: (selected) => setState(() {
                if (selected == true) {
                  _categories.add(category);
                } else {
                  _categories.remove(category);
                }
              }),
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              final error = appState.updateAreaAlertSubscription(
                enabled: _enabled,
                radiusKm: _radiusKm,
                categories: _categories.toList(),
              );
              if (error != null) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(error)));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('บันทึกการตั้งค่าแล้ว')),
                );
              }
            },
            child: const Text('บันทึกการตั้งค่า'),
          ),
        ],
      ),
    );
  }

  Future<void> _changeArea(BuildContext context, AppState appState) async {
    final user = appState.currentUser;
    final initial = user.homeLat != null && user.homeLng != null
        ? GeoLocation(user.homeLat!, user.homeLng!)
        : null;
    LocationSelection? selection;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
          16,
          12,
          16,
          MediaQuery.viewInsetsOf(context).bottom + 16,
        ),
        child: SingleChildScrollView(
          child: LocationPicker(
            initialLocation: initial,
            initialLocationLabel: user.homeLabel,
            showExactAddressField: false,
            locationLabelTitle: 'พื้นที่แจ้งเตือน',
            onChanged: (value) => selection = value,
          ),
        ),
      ),
    );
    if (selection?.exactLocation case final location?) {
      appState.updateCurrentUserArea(
        latitude: location.lat,
        longitude: location.lng,
        label: selection!.locationLabel,
      );
      if (mounted) setState(() {});
    }
  }
}
