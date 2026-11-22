import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

import '../constants/app_info.dart';
import '../constants/community_areas.dart';
import '../constants/listing_limits.dart';
import '../models/geo_location.dart';
import '../theme/app_theme.dart';
import 'osm_tile_layer.dart';

class LocationPicker extends StatefulWidget {
  final GeoLocation? initialLocation;
  final String initialLocationLabel;
  final String initialExactAddress;
  final bool showExactAddressField;
  final bool showPrivacyNotice;
  final String locationLabelTitle;
  final ValueChanged<LocationSelection> onChanged;

  const LocationPicker({
    super.key,
    this.initialLocation,
    this.initialLocationLabel = '',
    this.initialExactAddress = '',
    this.showExactAddressField = true,
    this.showPrivacyNotice = true,
    this.locationLabelTitle = 'ย่านโดยประมาณ',
    required this.onChanged,
  });

  @override
  State<LocationPicker> createState() => _LocationPickerState();
}

class LocationSelection {
  final GeoLocation? exactLocation;
  final String locationLabel;
  final String exactAddress;

  const LocationSelection({
    required this.exactLocation,
    required this.locationLabel,
    required this.exactAddress,
  });
}

class _LocationPickerState extends State<LocationPicker> {
  final _mapController = MapController();
  final _mapKey = GlobalKey();
  late final TextEditingController _locationLabelController;
  late final TextEditingController _exactAddressController;
  GeoLocation? _exactLocation;
  bool _isLoadingLocation = false;
  bool _hasTileError = false;
  bool _draggingPin = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _exactLocation = widget.initialLocation;
    _locationLabelController = TextEditingController(
      text: widget.initialLocationLabel,
    )..addListener(_notifyChanged);
    _exactAddressController = TextEditingController(
      text: widget.initialExactAddress,
    )..addListener(_notifyChanged);
  }

  @override
  void dispose() {
    _locationLabelController
      ..removeListener(_notifyChanged)
      ..dispose();
    _exactAddressController
      ..removeListener(_notifyChanged)
      ..dispose();
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selected = _exactLocation;
    final center = selected ?? kDefaultCenter;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ตำแหน่งสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _isLoadingLocation ? null : _useCurrentLocation,
          icon: _isLoadingLocation
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location_rounded),
          label: Text(
            _isLoadingLocation ? 'กำลังค้นหาตำแหน่ง...' : 'ใช้ตำแหน่งปัจจุบัน',
          ),
        ),
        if (_locationError != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              _locationError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 4),
        const Text(
          'หรือเลือกย่านตัวอย่าง',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.graySecondary,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 4,
          children: kDemoCommunityAreas.map((area) {
            return ActionChip(
              label: Text(area.label),
              onPressed: () {
                _selectLocation(area.location);
                if (_locationLabelController.text.trim().isEmpty) {
                  _locationLabelController.text = area.label;
                }
              },
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        const Text(
          'ปักหมุดบนแผนที่ (แตะเพื่อเลือก หรือกดค้างแล้วลากหมุด)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.graySecondary,
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 230,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              children: [
                FlutterMap(
                  key: _mapKey,
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: LatLng(center.lat, center.lng),
                    initialZoom: 14,
                    backgroundColor: const Color(0xFFE7E9E7),
                    onTap: (_, point) => _selectLocation(
                      GeoLocation(point.latitude, point.longitude),
                    ),
                  ),
                  children: [
                    OsmTileLayer(
                      onError: (error) {
                        if (mounted && !_hasTileError) {
                          setState(() => _hasTileError = true);
                        }
                      },
                    ),
                    if (selected != null)
                      CircleLayer(
                        circles: [
                          CircleMarker(
                            point: LatLng(selected.lat, selected.lng),
                            radius: kLocationPreviewRadiusMeters,
                            useRadiusInMeter: true,
                            color: AppColors.pinkPrimary.withValues(
                              alpha: 0.12,
                            ),
                            borderColor: AppColors.pinkPrimary,
                            borderStrokeWidth: 2,
                          ),
                        ],
                      ),
                    if (selected != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: LatLng(selected.lat, selected.lng),
                            width: 44,
                            height: 50,
                            child: GestureDetector(
                              onPanStart: (_) =>
                                  setState(() => _draggingPin = true),
                              onPanUpdate: _dragPin,
                              onPanEnd: (_) =>
                                  setState(() => _draggingPin = false),
                              child: const Icon(
                                Icons.location_on,
                                size: 42,
                                color: AppColors.pinkPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (_hasTileError)
                  const Positioned.fill(
                    child: ColoredBox(
                      color: Color(0xFFE7E9E7),
                      child: Center(child: Text('โหลดแผนที่ไม่ได้')),
                    ),
                  ),
                const Positioned(left: 8, bottom: 8, child: _MapAttribution()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        TextField(
          key: const ValueKey('listing-location-label'),
          controller: _locationLabelController,
          maxLength: kMaxLocationLabelLength,
          decoration: InputDecoration(
            labelText: widget.locationLabelTitle,
            hintText: 'เช่น ต.ท่าช้าง',
            helperText: 'ระบุย่านกว้าง ๆ เท่านั้น ไม่ต้องกรอกบ้านเลขที่',
            errorText: _locationErrorLabel,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
        const SizedBox(height: 4),
        if (widget.showExactAddressField)
          TextField(
            key: const ValueKey('listing-exact-address'),
            controller: _exactAddressController,
            maxLength: kMaxExactAddressLength,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'ที่อยู่หรือจุดสังเกต (ไม่บังคับ)',
              helperText: 'เห็นเฉพาะคุณ และคู่ที่ตกลงนัดแล้ว',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        if (widget.showPrivacyNotice)
          Text(
            selected == null
                ? 'กรุณาเลือกจุดบนแผนที่หรือย่านตัวอย่าง'
                : 'ผู้ซื้อจะเห็นแค่ตำแหน่งโดยประมาณ ที่อยู่จริงบอกในแชทเมื่อตกลงกัน',
            style: TextStyle(
              fontSize: 12,
              color: selected == null
                  ? AppColors.error
                  : AppColors.graySecondary,
            ),
          ),
      ],
    );
  }

  String? get _locationErrorLabel {
    if (_locationLabelController.text.trim().isEmpty) {
      return 'กรุณากรอกย่านโดยประมาณ';
    }
    return null;
  }

  void _notifyChanged() {
    widget.onChanged(
      LocationSelection(
        exactLocation: _exactLocation,
        locationLabel: _locationLabelController.text.trim(),
        exactAddress: _exactAddressController.text.trim(),
      ),
    );
    if (mounted) setState(() {});
  }

  void _selectLocation(GeoLocation location) {
    setState(() {
      _exactLocation = location;
      _locationError = null;
    });
    _notifyChanged();
  }

  void _dragPin(DragUpdateDetails details) {
    final context = _mapKey.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !_draggingPin) return;
    final localPosition = renderObject.globalToLocal(details.globalPosition);
    final point = _mapController.camera.screenOffsetToLatLng(localPosition);
    _selectLocation(GeoLocation(point.latitude, point.longitude));
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationError = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(
          () => _locationError = 'กรุณาเปิดบริการตำแหน่ง หรือเลือกจุดบนแผนที่',
        );
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
              'ไม่ได้รับอนุญาตให้ใช้ตำแหน่ง กรุณาเลือกจุดบนแผนที่หรือย่านตัวอย่าง',
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
      final location = GeoLocation(position.latitude, position.longitude);
      _selectLocation(location);
      _mapController.move(LatLng(location.lat, location.lng), 14);
    } on LocationServiceDisabledException {
      if (mounted) {
        setState(
          () => _locationError = 'กรุณาเปิดบริการตำแหน่ง หรือเลือกจุดบนแผนที่',
        );
      }
    } on PermissionDeniedException {
      if (mounted) {
        setState(
          () => _locationError =
              'ไม่ได้รับอนุญาตให้ใช้ตำแหน่ง กรุณาเลือกจุดบนแผนที่หรือย่านตัวอย่าง',
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
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10, color: AppColors.inkText),
        ),
      ),
    );
  }
}
