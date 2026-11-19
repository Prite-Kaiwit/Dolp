import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../main_navigation_screen.dart';

class _DemoArea {
  final String label;
  final double latitude;
  final double longitude;

  const _DemoArea(this.label, this.latitude, this.longitude);
}

class LocationPermissionScreen extends StatefulWidget {
  const LocationPermissionScreen({super.key});

  @override
  State<LocationPermissionScreen> createState() =>
      _LocationPermissionScreenState();
}

class _LocationPermissionScreenState extends State<LocationPermissionScreen> {
  static const _demoAreas = [
    _DemoArea('อำเภอเมืองจันทบุรี', 12.6112, 102.1031),
    _DemoArea('อำเภอท่าใหม่', 12.6230, 101.9990),
    _DemoArea('อำเภอขลุง', 12.4600, 102.2200),
    _DemoArea('อำเภอแหลมสิงห์', 12.4810, 102.0720),
    _DemoArea('อำเภอนายายอาม', 12.7800, 101.8300),
  ];

  _DemoArea? _selectedArea;
  bool _isLoading = false;
  String? _locationError;

  void _saveArea(double latitude, double longitude, String label) {
    AppState().updateCurrentUserArea(
      latitude: latitude,
      longitude: longitude,
      label: label,
    );
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      (route) => false,
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _locationError = 'กรุณาเปิดบริการตำแหน่งของอุปกรณ์');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(
          () => _locationError =
              'ไม่ได้รับอนุญาตให้ใช้ตำแหน่ง เลือกพื้นที่เองได้',
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 15),
        ),
      );
      if (!mounted) return;
      _saveArea(position.latitude, position.longitude, 'ตำแหน่งปัจจุบัน');
    } on LocationServiceDisabledException {
      if (mounted) {
        setState(() => _locationError = 'กรุณาเปิดบริการตำแหน่งของอุปกรณ์');
      }
    } on PermissionDeniedException {
      if (mounted) {
        setState(
          () => _locationError =
              'ไม่ได้รับอนุญาตให้ใช้ตำแหน่ง เลือกพื้นที่เองได้',
        );
      }
    } on PermissionDefinitionsNotFoundException {
      if (mounted) {
        setState(
          () => _locationError = 'ยังไม่ได้ตั้งค่าการขอสิทธิ์ตำแหน่งของแอป',
        );
      }
    } on TimeoutException {
      if (mounted) {
        setState(
          () => _locationError = 'ค้นหาตำแหน่งไม่สำเร็จ กรุณาลองอีกครั้ง',
        );
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(
          () => _locationError = error.message ?? 'ไม่สามารถอ่านตำแหน่งได้',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ตั้งค่าพื้นที่ของคุณ')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text(
              'เลือกพื้นที่เพื่อดูประกาศใกล้คุณ',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'ตำแหน่งที่ใช้ในโปรไฟล์เป็นข้อมูลส่วนตัว ผู้ซื้อจะเห็นตำแหน่งประกาศแบบประมาณเท่านั้น.',
              style: TextStyle(color: AppColors.graySecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _isLoading ? null : _useCurrentLocation,
              icon: _isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.my_location_rounded),
              label: Text(
                _isLoading ? 'กำลังค้นหาตำแหน่ง...' : 'ใช้ตำแหน่งปัจจุบัน',
              ),
            ),
            if (_locationError != null) ...[
              const SizedBox(height: 8),
              Text(
                _locationError!,
                style: const TextStyle(color: AppColors.error, fontSize: 12),
              ),
            ],
            const SizedBox(height: 20),
            const Text(
              'หรือตั้งพื้นที่เอง (ตัวอย่าง: จันทบุรี)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            RadioGroup<_DemoArea>(
              groupValue: _selectedArea,
              onChanged: (value) => setState(() => _selectedArea = value),
              child: Column(
                children: _demoAreas
                    .map(
                      (area) => RadioListTile<_DemoArea>(
                        value: area,
                        title: Text(area.label),
                        activeColor: AppColors.pinkPrimary,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _selectedArea == null
                    ? null
                    : () => _saveArea(
                        _selectedArea!.latitude,
                        _selectedArea!.longitude,
                        _selectedArea!.label,
                      ),
                child: const Text('บันทึกพื้นที่'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
