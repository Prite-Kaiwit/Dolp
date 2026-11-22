import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';

import '../../constants/app_info.dart';
import '../../constants/community_areas.dart';
import '../../models/geo_location.dart';
import '../../models/product.dart';
import '../../screens/auth/login_screen.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/info_banner.dart';
import '../../widgets/nearby_products_map.dart';
import '../../widgets/product_card.dart';
import '../order/cart_screen.dart';
import '../profile/notifications_screen.dart';
import 'product_detail_screen.dart';
import 'search_filter_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  static const _filters = ['ทั้งหมด', 'ขาย', 'แลกเปลี่ยน', 'บริจาค/ส่งต่อฟรี'];

  String _selectedFilter = _filters.first;
  double _selectedRadiusKm = kDefaultRadiusKm;
  bool _showMap = false;

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final selectedType = _listingTypeFor(_selectedFilter);
        final products = appState.productsNearby(
          radiusKm: _selectedRadiusKm,
          type: selectedType,
        );
        final unreadNotifs = appState.notifications
            .where((notification) => !(notification['read'] as bool))
            .length;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.aquaPale,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('🛍️', style: TextStyle(fontSize: 18)),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          appName,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.oceanBlue,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.aquaPale,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'ชุมชนใกล้คุณ',
                            style: TextStyle(
                              color: AppColors.deepNavy,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      appState.isLoggedIn
                          ? 'สวัสดี, ${appState.currentUser.name}'
                          : 'ผู้เยี่ยมชม (Guest)',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.graySecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.notifications_outlined,
                      color: AppColors.deepNavy,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    ),
                  ),
                  if (unreadNotifs > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.error,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$unreadNotifs',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppColors.deepNavy,
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const CartScreen(),
                      ),
                    ),
                  ),
                  if (appState.cartItems.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.aquaPale,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${appState.cartItems.length}',
                          style: const TextStyle(
                            color: AppColors.deepNavy,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.oceanBlue,
            onRefresh: () async {
              await Future<void>.delayed(const Duration(milliseconds: 300));
              if (mounted) setState(() {});
            },
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                CustomSearchBar(
                  readOnly: true,
                  onTap: _openSearch,
                  onFilterTap: _openSearch,
                ),
                const SizedBox(height: 16),
                InfoBanner(onLearnMore: _showSafetyInfoSheet),
                const SizedBox(height: 16),
                _buildAreaSelector(appState),
                if (appState.isLocationApproximate) ...[
                  const SizedBox(height: 8),
                  _buildApproximateLocationNotice(appState),
                ],
                const SizedBox(height: 16),
                _buildRadiusOptions(),
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _filters.map((filter) {
                      final isSelected = _selectedFilter == filter;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(filter),
                          selected: isSelected,
                          selectedColor: AppColors.aquaPale,
                          backgroundColor: AppColors.grayBg,
                          labelStyle: TextStyle(
                            color: AppColors.deepNavy,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: 12,
                          ),
                          showCheckmark: false,
                          onSelected: (_) =>
                              setState(() => _selectedFilter = filter),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ใกล้คุณ (${products.length})',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepNavy,
                      ),
                    ),
                    SegmentedButton<bool>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment<bool>(
                          value: false,
                          icon: Icon(Icons.view_list_outlined),
                          label: Text('รายการ'),
                        ),
                        ButtonSegment<bool>(
                          value: true,
                          icon: Icon(Icons.map_outlined),
                          label: Text('แผนที่'),
                        ),
                      ],
                      selected: {_showMap},
                      onSelectionChanged: (selection) =>
                          setState(() => _showMap = selection.first),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (_showMap)
                  NearbyProductsMap(
                    products: products,
                    userLocation: appState.currentLocation,
                    radiusKm: _selectedRadiusKm,
                  )
                else if (products.isEmpty)
                  _buildEmptyState()
                else
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 0.65,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final nearby = products[index];
                      return ProductCard(
                        nearbyProduct: nearby,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (_) => ProductDetailScreen(
                              product: nearby.product,
                              nearbyDistanceKm: nearby.distanceKm,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAreaSelector(AppState appState) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        if (!appState.isLoggedIn) {
          _openLogin();
        } else {
          _showAreaPicker(appState);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.grayLine),
        ),
        child: Row(
          children: [
            const Icon(Icons.near_me_outlined, color: AppColors.oceanBlue),
            const SizedBox(width: 8),
            const Text(
              'ใกล้ฉัน',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                appState.isLocationApproximate
                    ? 'พื้นที่โดยประมาณ'
                    : appState.currentUser.homeLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.graySecondary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.graySecondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApproximateLocationNotice(AppState appState) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.aquaPale,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.oceanBlue,
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Text(
              'ใช้ตำแหน่งโดยประมาณ',
              style: TextStyle(fontSize: 12, color: AppColors.deepNavy),
            ),
          ),
          TextButton(
            onPressed: () {
              if (!appState.isLoggedIn) {
                _openLogin();
              } else {
                _showAreaPicker(appState);
              }
            },
            child: const Text('ตั้งพื้นที่ของคุณ'),
          ),
        ],
      ),
    );
  }

  Widget _buildRadiusOptions() {
    return Row(
      children: [
        const Text(
          'รัศมี',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: AppColors.deepNavy,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Wrap(
            spacing: 6,
            children: kRadiusOptionsKm.map((radius) {
              final selected = radius == _selectedRadiusKm;
              return ChoiceChip(
                label: Text('${radius.toInt()} กม.'),
                selected: selected,
                showCheckmark: false,
                labelStyle: TextStyle(fontSize: 11, color: AppColors.deepNavy),
                selectedColor: AppColors.aquaPale,
                onSelected: (_) => setState(() => _selectedRadiusKm = radius),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    final nextRadii = kRadiusOptionsKm
        .where((radius) => radius > _selectedRadiusKm)
        .toList();
    final nextRadius = nextRadii.isEmpty ? null : nextRadii.first;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      child: Column(
        children: [
          const Icon(
            Icons.location_searching_rounded,
            size: 44,
            color: AppColors.graySecondary,
          ),
          const SizedBox(height: 12),
          Text(
            nextRadius == null
                ? 'ไม่มีสินค้าในพื้นที่นี้'
                : 'ยังไม่มีสินค้าในรัศมี ${_selectedRadiusKm.toInt()} กม.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.graySecondary,
              fontSize: 14,
            ),
          ),
          if (nextRadius != null) ...[
            const SizedBox(height: 10),
            OutlinedButton(
              onPressed: () => setState(() => _selectedRadiusKm = nextRadius),
              child: const Text('ขยายรัศมี'),
            ),
          ],
        ],
      ),
    );
  }

  ListingType? _listingTypeFor(String filter) {
    switch (filter) {
      case 'ขาย':
        return ListingType.sell;
      case 'แลกเปลี่ยน':
        return ListingType.trade;
      case 'บริจาค/ส่งต่อฟรี':
        return ListingType.donate;
      default:
        return null;
    }
  }

  void _openSearch() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const SearchFilterScreen()),
    );
  }

  void _openLogin() {
    Navigator.push(
      context,
      MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
    );
  }

  Future<void> _showAreaPicker(AppState appState) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _AreaPickerSheet(
        onSelect: (location, label) {
          appState.updateCurrentUserArea(
            latitude: location.lat,
            longitude: location.lng,
            label: label,
          );
          Navigator.pop(sheetContext);
        },
      ),
    );
  }

  void _showSafetyInfoSheet() {
    showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'นัดรับและซื้อขายอย่างระมัดระวัง',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'พูดคุยรายละเอียดและตกลงสถานที่นัดรับกับอีกฝ่ายก่อนเดินทาง '
              'เลือกจุดสาธารณะที่เหมาะสม ตรวจสอบสินค้าก่อนชำระเงิน '
              'และอย่าแชร์ข้อมูลส่วนตัวในที่สาธารณะ',
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.graySecondary,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('เข้าใจแล้ว'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AreaPickerSheet extends StatefulWidget {
  final void Function(GeoLocation location, String label) onSelect;

  const _AreaPickerSheet({required this.onSelect});

  @override
  State<_AreaPickerSheet> createState() => _AreaPickerSheetState();
}

class _AreaPickerSheetState extends State<_AreaPickerSheet> {
  CommunityArea? _selectedArea;
  bool _isLoading = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
        child: ListView(
          shrinkWrap: true,
          children: [
            const Text(
              'เลือกพื้นที่ใกล้ฉัน',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
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
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _error!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ),
            const SizedBox(height: 8),
            RadioGroup<CommunityArea>(
              groupValue: _selectedArea,
              onChanged: (value) => setState(() => _selectedArea = value),
              child: Column(
                children: kDemoCommunityAreas
                    .map(
                      (area) => RadioListTile<CommunityArea>(
                        value: area,
                        title: Text(area.label),
                        activeColor: AppColors.oceanBlue,
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _selectedArea == null
                  ? null
                  : () => widget.onSelect(
                      _selectedArea!.location,
                      _selectedArea!.label,
                    ),
              child: const Text('บันทึกพื้นที่'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _useCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        setState(() => _error = 'กรุณาเปิดบริการตำแหน่งของอุปกรณ์');
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(
          () => _error = 'ไม่ได้รับอนุญาตให้ใช้ตำแหน่ง เลือกพื้นที่เองได้',
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
      widget.onSelect(
        GeoLocation(position.latitude, position.longitude),
        'ตำแหน่งปัจจุบัน',
      );
    } on LocationServiceDisabledException {
      if (mounted) setState(() => _error = 'กรุณาเปิดบริการตำแหน่งของอุปกรณ์');
    } on PermissionDeniedException {
      if (mounted) {
        setState(
          () => _error = 'ไม่ได้รับอนุญาตให้ใช้ตำแหน่ง เลือกพื้นที่เองได้',
        );
      }
    } on PermissionDefinitionsNotFoundException {
      if (mounted) {
        setState(() => _error = 'ยังไม่ได้ตั้งค่าการขอสิทธิ์ตำแหน่งของแอป');
      }
    } on TimeoutException {
      if (mounted) {
        setState(() => _error = 'ค้นหาตำแหน่งไม่สำเร็จ กรุณาลองอีกครั้ง');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        setState(() => _error = error.message ?? 'ไม่สามารถอ่านตำแหน่งได้');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
