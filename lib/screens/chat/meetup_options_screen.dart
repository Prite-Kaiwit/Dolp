import 'package:flutter/material.dart';

import '../../constants/chat_limits.dart';
import '../../models/chat.dart';
import '../../models/geo_location.dart';
import '../../models/product.dart';
import '../../models/pickup_point.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/distance.dart';
import '../../widgets/location_picker.dart';

Future<void> showMeetupOptionsSheet(
  BuildContext context, {
  required ChatConversation conversation,
  required ProductModel product,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) =>
        _MeetupOptionsSheet(conversation: conversation, product: product),
  );
}

class _MeetupOptionsSheet extends StatefulWidget {
  final ChatConversation conversation;
  final ProductModel product;

  const _MeetupOptionsSheet({
    required this.conversation,
    required this.product,
  });

  @override
  State<_MeetupOptionsSheet> createState() => _MeetupOptionsSheetState();
}

class _MeetupOptionsSheetState extends State<_MeetupOptionsSheet> {
  final _placeController = TextEditingController();
  final _noteController = TextEditingController();
  PickupType _pickupType = PickupType.suggestedSpot;
  SuggestedSpot? _suggestedSpot;
  GeoLocation? _selectedLocation;
  String _selectedArea = '';
  DateTime _date = DateTime.now().add(const Duration(days: 1));
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 0);
  String? _error;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final points = AppState().pickupPoints.where((spot) => spot.isActive);
    if (points.isNotEmpty) {
      _suggestedSpot = points.first;
      _placeController.text = points.first.name;
    }
    _placeController.addListener(_refresh);
    _noteController.addListener(_refresh);
  }

  @override
  void dispose() {
    _placeController
      ..removeListener(_refresh)
      ..dispose();
    _noteController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() {
    if (mounted) setState(() {});
  }

  DateTime get _scheduledAt =>
      DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

  bool get _isReady {
    final now = DateTime.now();
    if (!_scheduledAt.isAfter(now) ||
        _scheduledAt.isAfter(
          now.add(const Duration(days: kMeetupMaxDaysAhead)),
        )) {
      return false;
    }
    if (_noteController.text.trim().length > kMeetupNoteMaxLength) return false;
    if (_pickupType == PickupType.agreedSpot) {
      return _selectedLocation != null &&
          _selectedArea.trim().isNotEmpty &&
          _placeController.text.trim().isNotEmpty &&
          _placeController.text.trim().length <= kPlaceLabelMaxLength;
    }
    if (_pickupType == PickupType.suggestedSpot) {
      return _suggestedSpot != null &&
          _placeController.text.trim().isNotEmpty &&
          _placeController.text.trim().length <= kPlaceLabelMaxLength;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final activeSpots = AppState().pickupPoints
        .where((spot) => spot.isActive)
        .toList();
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.grayLine,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'เสนอนัดรับ',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                _choice(PickupType.sellerHome, 'บ้านผู้ขาย'),
                _choice(PickupType.suggestedSpot, 'จุดสาธารณะแนะนำ'),
                _choice(PickupType.agreedSpot, 'จุดอื่นที่ตกลงกัน'),
              ],
            ),
            const SizedBox(height: 12),
            if (_pickupType == PickupType.sellerHome)
              _buildSellerHomeTip()
            else if (_pickupType == PickupType.suggestedSpot)
              _buildSuggestedSpots(activeSpots)
            else
              _buildAgreedSpotPicker(),
            const SizedBox(height: 12),
            if (_pickupType != PickupType.sellerHome) ...[
              TextField(
                controller: _placeController,
                maxLength: kPlaceLabelMaxLength,
                decoration: InputDecoration(
                  labelText: 'ชื่อสถานที่',
                  hintText: 'เช่น หน้าร้านสะดวกซื้อสาขา...',
                  errorText: _placeController.text.trim().isEmpty
                      ? 'กรุณาระบุชื่อสถานที่'
                      : null,
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
            ],
            const Text(
              'วันและเวลา',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickDate,
                    icon: const Icon(Icons.calendar_today_outlined),
                    label: Text(_formatDate(_date)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickTime,
                    icon: const Icon(Icons.schedule),
                    label: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            if (!_scheduledAt.isAfter(DateTime.now()))
              const Text(
                'วันและเวลานัดต้องอยู่ในอนาคต',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              )
            else if (_scheduledAt.isAfter(
              DateTime.now().add(const Duration(days: kMeetupMaxDaysAhead)),
            ))
              const Text(
                'เลือกวันและเวลาได้ไม่เกิน 30 วัน',
                style: TextStyle(color: AppColors.error, fontSize: 12),
              ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteController,
              maxLength: kMeetupNoteMaxLength,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'หมายเหตุ (ไม่บังคับ)',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: !_isReady || _isSubmitting ? null : _submit,
                child: Text(_isSubmitting ? 'กำลังส่ง...' : 'ส่งข้อเสนอนัดรับ'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _choice(PickupType type, String label) => ChoiceChip(
    label: Text(label),
    selected: _pickupType == type,
    onSelected: (_) {
      setState(() {
        _pickupType = type;
        if (type == PickupType.suggestedSpot && _suggestedSpot != null) {
          _placeController.text = _suggestedSpot!.name;
        } else if (type == PickupType.agreedSpot) {
          _placeController.clear();
        }
        _error = null;
      });
    },
  );

  Widget _buildSellerHomeTip() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.greenPale,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(
      'บ้านผู้ขาย (ย่าน ${widget.product.locationLabel})\nนัดช่วงกลางวัน ชวนเพื่อนไปด้วย และแจ้งคนใกล้ชิดก่อนเดินทาง',
      style: const TextStyle(fontSize: 13),
    ),
  );

  Widget _buildSuggestedSpots(List<SuggestedSpot> spots) {
    if (spots.isEmpty) return const Text('ไม่มีจุดแนะนำในขณะนี้');
    return Column(
      children: spots.map((spot) {
        final selected = _suggestedSpot?.id == spot.id;
        final km = distanceKm(widget.product.publicLocation, spot.location);
        return Card(
          color: selected ? AppColors.greenPale : AppColors.white,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 10),
            leading: Icon(
              selected ? Icons.radio_button_checked : Icons.radio_button_off,
              color: selected
                  ? AppColors.greenPrimary
                  : AppColors.graySecondary,
            ),
            title: Text(spot.name),
            subtitle: Text('${spot.type.label} · ${formatDistance(km)}'),
            onTap: () => setState(() {
              _suggestedSpot = spot;
              _placeController.text = spot.name;
            }),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgreedSpotPicker() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'เลือกสถานที่สาธารณะร่วมกัน ไม่ใช่ที่อยู่ผู้ขาย',
        style: TextStyle(fontSize: 12, color: AppColors.graySecondary),
      ),
      const SizedBox(height: 8),
      LocationPicker(
        initialLocation: _selectedLocation ?? widget.product.publicLocation,
        initialLocationLabel: _selectedArea,
        showExactAddressField: false,
        showPrivacyNotice: false,
        locationLabelTitle: 'พื้นที่ของจุดสาธารณะ',
        onChanged: (selection) {
          setState(() {
            _selectedLocation = selection.exactLocation;
            _selectedArea = selection.locationLabel;
          });
        },
      ),
    ],
  );

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(now) ? now : _date,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: now.add(const Duration(days: kMeetupMaxDaysAhead)),
    );
    if (selected != null) setState(() => _date = selected);
  }

  Future<void> _pickTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null) setState(() => _time = selected);
  }

  Future<void> _submit() async {
    if (!_isReady) {
      setState(() => _error = 'กรุณากรอกข้อมูลนัดรับให้ครบถ้วน');
      return;
    }
    setState(() {
      _error = null;
      _isSubmitting = true;
    });
    final spot = _pickupType == PickupType.suggestedSpot
        ? _suggestedSpot
        : null;
    final error = AppState().proposeMeetup(
      conversationId: widget.conversation.id,
      pickupType: _pickupType,
      placeLabel: _pickupType == PickupType.suggestedSpot
          ? _suggestedSpot!.name
          : _placeController.text,
      spotLocation: spot?.location ?? _selectedLocation,
      scheduledAt: _scheduledAt,
      note: _noteController.text,
    );
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _error = error;
        _isSubmitting = false;
      });
      return;
    }
    Navigator.pop(context);
  }

  String _formatDate(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
}

extension on SuggestedSpotType {
  String get label {
    switch (this) {
      case SuggestedSpotType.gasStation:
        return 'ปั๊มน้ำมัน';
      case SuggestedSpotType.mall:
        return 'ห้าง';
      case SuggestedSpotType.convenienceStore:
        return 'ร้านสะดวกซื้อ';
      case SuggestedSpotType.other:
        return 'อื่น ๆ';
    }
  }
}
