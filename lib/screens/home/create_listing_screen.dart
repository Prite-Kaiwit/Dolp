import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';

class CreateListingScreen extends StatefulWidget {
  const CreateListingScreen({super.key});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _tradeForController = TextEditingController();
  final _descriptionController = TextEditingController();

  ListingType _listingType = ListingType.sell;
  String _selectedCategory = 'หนังสือ & ชีทเรียน';
  String _selectedCondition = 'สภาพดีมาก (95%)';
  String _selectedPickupPoint = 'โรงอาหารกลาง 1 (Complex)';
  String _selectedImagePreset = 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500';

  final List<String> _categories = [
    'หนังสือ & ชีทเรียน',
    'อุปกรณ์การเรียน & เครื่องเขียน',
    'เสื้อผ้า & เครื่องแต่งกาย',
    'ไอที & อิเล็กทรอนิกส์',
    'ของใช้หอพัก & เฟอร์นิเจอร์',
    'ของสะสม & กีฬา',
  ];

  final List<String> _conditions = [
    'ใหม่เอี่ยม (100% ยังไม่แกะกล่อง)',
    'สภาพดีมาก (95%)',
    'สภาพดี (85-90%)',
    'สภาพใช้งานทั่วไป (70-80%)',
  ];

  final List<Map<String, String>> _imagePresets = [
    {'name': 'หนังสือ', 'url': 'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500'},
    {'name': 'อุปกรณ์ไอที', 'url': 'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=500'},
    {'name': 'เสื้อผ้า', 'url': 'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=500'},
    {'name': 'ของใช้หอ', 'url': 'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=500'},
    {'name': 'เครื่องเขียน', 'url': 'https://images.unsplash.com/photo-1583485088034-697b5bc54ccd?w=500'},
  ];

  void _submitListing() {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('กรุณากรอกชื่อสินค้า')),
      );
      return;
    }

    double price = 0.0;
    if (_listingType != ListingType.donate) {
      price = double.tryParse(_priceController.text.trim()) ?? 0.0;
    }

    final newProduct = ProductModel(
      id: 'prod_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: _descriptionController.text.trim().isNotEmpty
          ? _descriptionController.text.trim()
          : 'ไม่มีรายละเอียดเพิ่มเติม',
      price: price,
      tradeFor: _tradeForController.text.trim(),
      type: _listingType,
      category: _selectedCategory,
      condition: _selectedCondition,
      pickupPoint: _selectedPickupPoint,
      imageUrl: _selectedImagePreset,
      sellerId: AppState().currentUser.id,
      sellerName: AppState().currentUser.name,
      sellerFaculty: AppState().currentUser.faculty,
      sellerRating: AppState().currentUser.rating,
      sellerReviewCount: AppState().currentUser.reviewCount,
    );

    AppState().addProduct(newProduct);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('ลงประกาศสินค้าสำเร็จแล้ว! สินค้าพร้อมแสดงในหน้าแรก'),
        backgroundColor: AppColors.greenPrimary,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Scaffold(
      appBar: AppBar(
        title: const Text('ลงประกาศสินค้าใหม่'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Transaction Type Segment Selector (Sell / Trade / Donate)
              const Text('ประเภทประกาศ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _buildTypeTab('ขาย', ListingType.sell, AppColors.pinkPrimary),
                  const SizedBox(width: 8),
                  _buildTypeTab('แลกเปลี่ยน', ListingType.trade, AppColors.info),
                  const SizedBox(width: 8),
                  _buildTypeTab('บริจาค / ฟรี', ListingType.donate, AppColors.greenPrimary),
                ],
              ),
              const SizedBox(height: 20),

              // Image Selection / Upload preview
              const Text('รูปภาพสินค้า (เลือกรูปจำลองตัวอย่าง)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 8),
              SizedBox(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePresets.length,
                  itemBuilder: (context, index) {
                    final item = _imagePresets[index];
                    final isSelected = _selectedImagePreset == item['url'];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedImagePreset = item['url']!),
                      child: Container(
                        margin: const EdgeInsets.only(right: 12),
                        width: 90,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSelected ? AppColors.pinkPrimary : AppColors.grayLine,
                            width: isSelected ? 3 : 1,
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.network(item['url']!, fit: BoxFit.cover),
                              if (isSelected)
                                Container(
                                  color: AppColors.pinkPrimary.withValues(alpha: 0.3),
                                  child: const Center(
                                    child: Icon(Icons.check_circle_rounded, color: Colors.white, size: 28),
                                  ),
                                ),
                              Positioned(
                                bottom: 4,
                                left: 4,
                                right: 4,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.6),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['name']!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 20),

              // Title
              const Text('ชื่อสินค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'เช่น สรุปชีท ฟิสิกส์ 1, เสื้อช็อป ไซส์ L',
                ),
              ),
              const SizedBox(height: 16),

              // Price (if Sell or Trade)
              if (_listingType != ListingType.donate) ...[
                Text(
                  _listingType == ListingType.trade ? 'ราคาประเมิน (บาท)' : 'ราคาขาย (บาท)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'เช่น 150',
                    prefixText: '฿ ',
                    prefixStyle: TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkPrimary),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Wishlist for Trade
              if (_listingType == ListingType.trade) ...[
                const Text('สิ่งที่อยากได้ในการแลกเปลี่ยน', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                const SizedBox(height: 6),
                TextField(
                  controller: _tradeForController,
                  decoration: const InputDecoration(
                    hintText: 'เช่น รับแลกกับเครื่องคิดเลข Casio หรือชีท Bio',
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Category Dropdown
              const Text('หมวดหมู่สินค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.grayLine),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCategory,
                    items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCategory = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Condition Dropdown
              const Text('สภาพสินค้า', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.grayBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.grayLine),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedCondition,
                    items: _conditions.map((c) => DropdownMenuItem(value: c, child: Text(c, style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedCondition = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Campus Pickup Point Selection
              const Text('จุดนัดรับที่สะดวกในมหาวิทยาลัย', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppColors.greenPale,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.greenLight),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    isExpanded: true,
                    value: _selectedPickupPoint,
                    items: appState.pickupPoints.map((p) => DropdownMenuItem(value: p.name, child: Text(p.name, style: const TextStyle(fontSize: 13, color: AppColors.greenDark, fontWeight: FontWeight.bold)))).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedPickupPoint = val);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text('รายละเอียดเพิ่มเติม', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              const SizedBox(height: 6),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'อธิบายรายละเอียด สภาพ ตำหนิ (ถ้ามี) เหตุผลที่ส่งต่อ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 30),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _submitListing,
                  child: const Text('เผยแพร่ประกาศทันที', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeTab(String label, ListingType type, Color activeColor) {
    final isSelected = _listingType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _listingType = type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? activeColor : AppColors.grayBg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isSelected ? activeColor : AppColors.grayLine),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.inkText,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
