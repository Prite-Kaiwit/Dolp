import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/custom_search_bar.dart';
import 'product_detail_screen.dart';

class SearchFilterScreen extends StatefulWidget {
  const SearchFilterScreen({super.key});

  @override
  State<SearchFilterScreen> createState() => _SearchFilterScreenState();
}

class _SearchFilterScreenState extends State<SearchFilterScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'ทั้งหมด';
  String _selectedType = 'ทั้งหมด';
  String _selectedZone = 'ทั้งหมด';
  RangeValues _priceRange = const RangeValues(0, 1000);

  final List<String> _categories = [
    'ทั้งหมด',
    'หนังสือ & ชีทเรียน',
    'อุปกรณ์การเรียน & เครื่องเขียน',
    'เสื้อผ้า & เครื่องแต่งกาย',
    'ไอที & อิเล็กทรอนิกส์',
    'ของใช้หอพัก & เฟอร์นิเจอร์',
    'ของสะสม & กีฬา',
  ];

  final List<String> _types = ['ทั้งหมด', 'ขาย', 'แลกเปลี่ยน', 'บริจาค/ฟรี'];

  final List<String> _zones = [
    'ทั้งหมด',
    'โซนกลางมหาวิทยาลัย',
    'โซนการเรียนรู้',
    'โซนไอที',
    'โซนหอพัก',
    'โซนประตูมหาลัย',
  ];

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ค้นหาและกรองสินค้า'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Search Input Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: CustomSearchBar(
                controller: _searchController,
                onChanged: (_) => setState(() {}),
                onFilterTap: () => _openFilterModal(context),
              ),
            ),

            // Horizontal Categories Quick Chips
            SizedBox(
              height: 38,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(cat),
                      selected: isSelected,
                      selectedColor: AppColors.pinkPrimary,
                      backgroundColor: AppColors.grayBg,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.inkText,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(
                          color: isSelected ? AppColors.pinkPrimary : AppColors.grayLine,
                        ),
                      ),
                      showCheckmark: false,
                      onSelected: (_) => setState(() => _selectedCategory = cat),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),

            // Active Filters Summary Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (_selectedType != 'ทั้งหมด')
                    _buildActiveBadge('ประเภท: $_selectedType', () => setState(() => _selectedType = 'ทั้งหมด')),
                  if (_selectedZone != 'ทั้งหมด')
                    _buildActiveBadge('จุดรับ: $_selectedZone', () => setState(() => _selectedZone = 'ทั้งหมด')),
                ],
              ),
            ),
            const Divider(),

            // Search Results Grid
            Expanded(
              child: ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  final query = _searchController.text.trim().toLowerCase();
                  final results = appState.products.where((p) {
                    if (p.status != ListingStatus.active) return false;

                    // Text Query
                    if (query.isNotEmpty) {
                      final matchTitle = p.title.toLowerCase().contains(query);
                      final matchDesc = p.description.toLowerCase().contains(query);
                      final matchCat = p.category.toLowerCase().contains(query);
                      if (!matchTitle && !matchDesc && !matchCat) return false;
                    }

                    // Category
                    if (_selectedCategory != 'ทั้งหมด' && p.category != _selectedCategory) {
                      return false;
                    }

                    // Type
                    if (_selectedType == 'ขาย' && p.type != ListingType.sell) return false;
                    if (_selectedType == 'แลกเปลี่ยน' && p.type != ListingType.trade) return false;
                    if (_selectedType == 'บริจาค/ฟรี' && p.type != ListingType.donate) return false;

                    // Price
                    if (p.type == ListingType.sell && (p.price < _priceRange.start || p.price > _priceRange.end)) {
                      return false;
                    }

                    return true;
                  }).toList();

                  if (results.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.search_off_rounded, size: 56, color: AppColors.graySecondary),
                          const SizedBox(height: 12),
                          const Text(
                            'ไม่พบสินค้าตามเงื่อนไขที่ค้นหา',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.inkText),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'ลองปรับคำค้นหาหรือเปลี่ยนตัวกรองดูนะครับ',
                            style: TextStyle(fontSize: 13, color: AppColors.graySecondary),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _searchController.clear();
                                _selectedCategory = 'ทั้งหมด';
                                _selectedType = 'ทั้งหมด';
                                _selectedZone = 'ทั้งหมด';
                                _priceRange = const RangeValues(0, 1000);
                              });
                            },
                            child: const Text('ล้างตัวกรองทั้งหมด'),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: GridView.builder(
                      itemCount: results.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemBuilder: (context, index) {
                        final product = results[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(product: product),
                              ),
                            );
                          },
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

  Widget _buildActiveBadge(String label, VoidCallback onRemove) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.pinkPale,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.pinkDark, fontWeight: FontWeight.bold)),
          const SizedBox(width: 4),
          InkWell(
            onTap: onRemove,
            child: const Icon(Icons.close, size: 14, color: AppColors.pinkDark),
          ),
        ],
      ),
    );
  }

  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ตัวกรองสินค้าขั้นสูง',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.inkText),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Transaction Type
                  const Text('ประเภทธุรกรรม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _types.map((type) {
                      final isSelected = _selectedType == type;
                      return ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: AppColors.pinkPrimary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.inkText,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          setModalState(() => _selectedType = type);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // Price Range
                  Text(
                    'ช่วงราคา (฿${_priceRange.start.round()} - ฿${_priceRange.end.round()})',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  RangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 2000,
                    divisions: 20,
                    activeColor: AppColors.pinkPrimary,
                    inactiveColor: AppColors.grayLine,
                    labels: RangeLabels('฿${_priceRange.start.round()}', '฿${_priceRange.end.round()}'),
                    onChanged: (values) {
                      setModalState(() => _priceRange = values);
                      setState(() {});
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campus Zone
                  const Text('โซนจุดนัดรับใน มอ.', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: _zones.map((zone) {
                      final isSelected = _selectedZone == zone;
                      return ChoiceChip(
                        label: Text(zone),
                        selected: isSelected,
                        selectedColor: AppColors.greenPrimary,
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : AppColors.inkText,
                          fontSize: 12,
                        ),
                        onSelected: (_) {
                          setModalState(() => _selectedZone = zone);
                          setState(() {});
                        },
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('ใช้ตัวกรองนี้'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
