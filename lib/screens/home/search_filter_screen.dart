import 'package:flutter/material.dart';

import '../../constants/app_info.dart';
import '../../models/nearby_product.dart';
import '../../models/product.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/product_card.dart';
import 'product_detail_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  static const _all = 'ทั้งหมด';
  static const _fullPriceRange = RangeValues(0, 1000000);
  static const _categories = [
    _all,
    'หนังสือ',
    'อุปกรณ์และเครื่องเขียน',
    'เสื้อผ้า & เครื่องแต่งกาย',
    'ไอที & อิเล็กทรอนิกส์',
    'ของใช้ในบ้าน & เฟอร์นิเจอร์',
    'ของสะสม & กีฬา',
  ];
  static const _types = [_all, 'ขาย', 'แลกเปลี่ยน', 'บริจาค/ฟรี'];

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = _all;
  String _selectedType = _all;
  double _radiusKm = kDefaultRadiusKm;
  RangeValues _priceRange = _fullPriceRange;
  SortBy _sortBy = SortBy.nearest;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(title: const Text('ค้นหาและกรองสินค้า')),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                onFilterTap: _openFilterModal,
              ),
            ),
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: _categories.map((category) {
                  final selected = _selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(category),
                      selected: selected,
                      selectedColor: AppColors.aquaPale,
                      backgroundColor: AppColors.grayBg,
                      labelStyle: TextStyle(
                        color: AppColors.deepNavy,
                        fontSize: 12,
                      ),
                      showCheckmark: false,
                      onSelected: (_) =>
                          setState(() => _selectedCategory = category),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Text(
                        'เรียงตาม',
                        style: TextStyle(
                          color: AppColors.graySecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<SortBy>(
                        value: _sortBy,
                        isDense: true,
                        underline: const SizedBox.shrink(),
                        items: const [
                          DropdownMenuItem(
                            value: SortBy.nearest,
                            child: Text('ใกล้สุด'),
                          ),
                          DropdownMenuItem(
                            value: SortBy.newest,
                            child: Text('ใหม่สุด'),
                          ),
                          DropdownMenuItem(
                            value: SortBy.priceAsc,
                            child: Text('ราคาต่ำ-สูง'),
                          ),
                          DropdownMenuItem(
                            value: SortBy.priceDesc,
                            child: Text('ราคาสูง-ต่ำ'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) setState(() => _sortBy = value);
                        },
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _openFilterModal,
                        icon: const Icon(Icons.tune_rounded, size: 18),
                        label: const Text('ตัวกรอง'),
                      ),
                    ],
                  ),
                  _buildActiveFilters(),
                ],
              ),
            ),
            const Divider(height: 16),
            Expanded(
              child: ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  final results = appState.productsNearby(
                    radiusKm: _radiusKm,
                    category: _selectedCategory == _all
                        ? null
                        : _selectedCategory,
                    type: _listingTypeFor(_selectedType),
                    minPrice: _priceRange.start > 0 ? _priceRange.start : null,
                    maxPrice: _priceRange.end < _fullPriceRange.end
                        ? _priceRange.end
                        : null,
                    query: _searchController.text,
                    sortBy: _sortBy,
                  );

                  if (results.isEmpty) return _buildEmptyState();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: results.length,
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: productCardGridAspectRatio(
                          MediaQuery.textScalerOf(context),
                        ),
                      ),
                      itemBuilder: (context, index) {
                        final nearby = results[index];
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
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveFilters() {
    final filters = <Widget>[];
    if (_radiusKm != kDefaultRadiusKm) {
      filters.add(
        _buildActiveBadge(
          'รัศมี ${_radiusKm.toInt()} กม.',
          () => setState(() => _radiusKm = kDefaultRadiusKm),
        ),
      );
    }
    if (_selectedCategory != _all) {
      filters.add(
        _buildActiveBadge(
          _selectedCategory,
          () => setState(() => _selectedCategory = _all),
        ),
      );
    }
    if (_selectedType != _all) {
      filters.add(
        _buildActiveBadge(
          'ประเภท: $_selectedType',
          () => setState(() => _selectedType = _all),
        ),
      );
    }
    if (_priceRange != _fullPriceRange) {
      filters.add(
        _buildActiveBadge(
          '฿${_priceRange.start.round()}–฿${_priceRange.end.round()}',
          () => setState(() => _priceRange = _fullPriceRange),
        ),
      );
    }
    if (filters.isEmpty) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(spacing: 6, runSpacing: 4, children: filters),
    );
  }

  Widget _buildActiveBadge(String label, VoidCallback onRemove) {
    return InputChip(
      label: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          color: AppColors.deepNavy,
          fontWeight: FontWeight.w600,
        ),
      ),
      onDeleted: onRemove,
      deleteIconColor: AppColors.deepNavy,
      backgroundColor: AppColors.aquaPale,
      visualDensity: VisualDensity.compact,
      side: BorderSide.none,
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 52,
              color: AppColors.graySecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'ไม่พบสินค้าตามเงื่อนไขที่ค้นหา',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'ลองปรับคำค้นหาหรือเปลี่ยนตัวกรองดูนะครับ',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.graySecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _resetFilters,
              child: const Text('ล้างตัวกรองทั้งหมด'),
            ),
          ],
        ),
      ),
    );
  }

  void _openFilterModal() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setModalState) => SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.8,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'ตัวกรองสินค้า',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.deepNavy,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'รัศมีค้นหา',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              Slider(
                value: _radiusKm,
                min: 1,
                max: 20,
                divisions: 19,
                label: '${_radiusKm.toInt()} กม.',
                activeColor: AppColors.aqua,
                onChanged: (value) {
                  setModalState(() => _radiusKm = value);
                  setState(() {});
                },
              ),
              Text(
                '${_radiusKm.toInt()} กม.',
                style: const TextStyle(color: AppColors.graySecondary),
              ),
              const SizedBox(height: 16),
              const Text(
                'ประเภทธุรกรรม',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: _types.map((type) {
                  final selected = _selectedType == type;
                  return ChoiceChip(
                    label: Text(type),
                    selected: selected,
                    selectedColor: AppColors.aquaPale,
                    labelStyle: TextStyle(
                      color: AppColors.deepNavy,
                      fontSize: 12,
                    ),
                    onSelected: (_) {
                      setModalState(() => _selectedType = type);
                      setState(() {});
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Text(
                'ช่วงราคา (฿${_priceRange.start.round()} - ฿${_priceRange.end.round()})',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              RangeSlider(
                values: _priceRange,
                min: _fullPriceRange.start,
                max: _fullPriceRange.end,
                divisions: 100,
                activeColor: AppColors.aqua,
                inactiveColor: AppColors.grayLine,
                labels: RangeLabels(
                  '฿${_priceRange.start.round()}',
                  '฿${_priceRange.end.round()}',
                ),
                onChanged: (values) {
                  setModalState(() => _priceRange = values);
                  setState(() {});
                },
              ),
              const SizedBox(height: 20),
              OutlinedButton(
                onPressed: () {
                  _resetFilters();
                  setModalState(() {});
                },
                child: const Text('ล้างตัวกรองทั้งหมด'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text('ใช้ตัวกรองนี้'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _selectedCategory = _all;
      _selectedType = _all;
      _radiusKm = kDefaultRadiusKm;
      _priceRange = _fullPriceRange;
      _sortBy = SortBy.nearest;
    });
  }

  ListingType? _listingTypeFor(String type) {
    switch (type) {
      case 'ขาย':
        return ListingType.sell;
      case 'แลกเปลี่ยน':
        return ListingType.trade;
      case 'บริจาค/ฟรี':
        return ListingType.donate;
      default:
        return null;
    }
  }
}
