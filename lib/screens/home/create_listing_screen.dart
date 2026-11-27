import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../../constants/categories.dart';
import '../../constants/listing_limits.dart';
import '../../models/geo_location.dart';
import '../../models/product.dart';
import '../../models/product_image_data.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../utils/listing_validation.dart';
import '../../widgets/location_picker.dart';
import '../../widgets/product_image.dart';
import '../auth/login_screen.dart';

typedef ListingImagePickHandler =
    Future<List<XFile>?> Function(ImageSource source, {required int limit});

class CreateListingScreen extends StatefulWidget {
  final String? productId;
  final ListingImagePickHandler? pickImages;

  const CreateListingScreen({super.key, this.productId, this.pickImages});

  @override
  State<CreateListingScreen> createState() => _CreateListingScreenState();
}

class _CreateListingScreenState extends State<CreateListingScreen> {
  final _titleController = TextEditingController();
  final _priceController = TextEditingController();
  final _tradeForController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imagePicker = ImagePicker();
  final _categories = kListingCategories;
  final _conditions = const [
    'ใหม่เอี่ยม (100% ยังไม่แกะกล่อง)',
    'สภาพดีมาก (95%)',
    'สภาพดี (85-90%)',
    'สภาพใช้งานทั่วไป (70-80%)',
  ];

  ProductModel? _editingProduct;
  String? _accessError;
  String? _selectedCategory;
  String _selectedCondition = 'สภาพดีมาก (95%)';
  ListingType _listingType = ListingType.sell;
  PickupType _pickupType = PickupType.discussInChat;
  LocationSelection _location = const LocationSelection(
    exactLocation: null,
    locationLabel: '',
    exactAddress: '',
  );
  GeoLocation? _initialExactLocation;
  String _initialExactAddress = '';
  List<ProductImageData> _images = [];
  bool _isPickingImages = false;

  bool get _isEditing => widget.productId != null;

  @override
  void initState() {
    super.initState();
    if (widget.productId != null) _loadProductForEditing(widget.productId!);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _tradeForController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _loadProductForEditing(String productId) {
    final appState = AppState();
    final index = appState.products.indexWhere((item) => item.id == productId);
    if (index == -1) {
      _accessError = 'ไม่พบประกาศที่ต้องการแก้ไข';
      return;
    }

    final product = appState.products[index];
    if (product.sellerId != appState.currentUser.id) {
      _accessError = 'คุณไม่มีสิทธิ์แก้ไขประกาศนี้';
      return;
    }

    _editingProduct = product;
    _titleController.text = product.title;
    _priceController.text = product.price == 0 ? '' : '${product.price}';
    _tradeForController.text = product.tradeFor;
    _descriptionController.text = product.description;
    _selectedCategory = _categories.contains(product.category)
        ? product.category
        : null;
    _selectedCondition = _conditions.contains(product.condition)
        ? product.condition
        : _conditions.first;
    _listingType = product.type;
    _pickupType = product.pickupType;
    _images = product.productImages.isNotEmpty
        ? List<ProductImageData>.of(product.productImages)
        : [?product.coverImage];

    final exact = appState.getExactLocationFor(
      productId,
      appState.currentUser.id,
    );
    if (exact != null) {
      _initialExactLocation = GeoLocation(exact.exactLat, exact.exactLng);
      _initialExactAddress = exact.exactAddress;
      _location = LocationSelection(
        exactLocation: _initialExactLocation,
        locationLabel: product.locationLabel,
        exactAddress: exact.exactAddress,
      );
    } else {
      _location = LocationSelection(
        exactLocation: null,
        locationLabel: product.locationLabel,
        exactAddress: '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();
    if (!appState.isLoggedIn) return _buildLoginPrompt();
    if (_accessError != null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'แก้ไขประกาศ' : 'ลงประกาศสินค้า'),
        ),
        body: Center(child: Text(_accessError!)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'แก้ไขประกาศ' : 'ลงประกาศสินค้าใหม่'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('ประเภทประกาศ'),
              const SizedBox(height: 8),
              SegmentedButton<ListingType>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: ListingType.sell, label: Text('ขาย')),
                  ButtonSegment(
                    value: ListingType.trade,
                    label: Text('แลกเปลี่ยน'),
                  ),
                  ButtonSegment(
                    value: ListingType.donate,
                    label: Text('บริจาค'),
                  ),
                ],
                selected: {_listingType},
                onSelectionChanged: (selection) =>
                    setState(() => _listingType = selection.first),
              ),
              const SizedBox(height: 20),
              _buildSectionTitle('รูปภาพสินค้า'),
              const SizedBox(height: 4),
              const Text(
                'เลือกได้สูงสุด $kMaxListingImages รูป แตะรูปเพื่อตั้งเป็นรูปปก',
                style: TextStyle(color: AppColors.graySecondary, fontSize: 12),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 116,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    for (var index = 0; index < _images.length; index++)
                      _buildImageTile(index),
                    if (_images.length < kMaxListingImages)
                      _buildAddImageButton(),
                  ],
                ),
              ),
              if (_images.length < kMinListingImages)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text(
                    'กรุณาเลือกรูปสินค้าอย่างน้อย 1 รูป',
                    style: TextStyle(color: AppColors.error, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 20),
              _buildSectionTitle('ชื่อสินค้า'),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('listing-title'),
                controller: _titleController,
                maxLength: kMaxListingTitleLength,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) => setState(() {}),
                validator: (_) => validateListingTitle(_titleController.text),
                decoration: const InputDecoration(
                  hintText: 'เช่น หนังสืออ่านเล่น โต๊ะพับ เสื้อแจ็กเก็ต',
                ),
              ),
              const SizedBox(height: 8),
              if (_listingType == ListingType.sell) ...[
                _buildSectionTitle('ราคาขาย (บาท)'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const ValueKey('listing-price'),
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => setState(() {}),
                  validator: (_) => validateListingPrice(_priceController.text),
                  decoration: const InputDecoration(
                    hintText: 'เช่น 150 หรือ 99.99',
                    prefixText: '฿ ',
                  ),
                ),
                const SizedBox(height: 16),
              ] else if (_listingType == ListingType.trade) ...[
                _buildSectionTitle('ราคาประเมิน (ไม่บังคับ)'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const ValueKey('listing-price'),
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => setState(() {}),
                  validator: (_) => validateListingPrice(
                    _priceController.text,
                    required: false,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'เว้นว่างได้',
                    prefixText: '฿ ',
                  ),
                ),
                const SizedBox(height: 8),
                _buildSectionTitle('ต้องการแลกกับอะไร'),
                const SizedBox(height: 6),
                TextFormField(
                  key: const ValueKey('listing-trade-for'),
                  controller: _tradeForController,
                  maxLength: kMaxTradeRequestLength,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  onChanged: (_) => setState(() {}),
                  validator: (_) =>
                      validateTradeRequest(_tradeForController.text),
                  decoration: const InputDecoration(
                    hintText: 'ระบุสิ่งที่ต้องการแลก',
                  ),
                ),
                const SizedBox(height: 8),
              ] else ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.successPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ฟรี · ไม่มีค่าใช้จ่าย',
                    style: TextStyle(
                      color: AppColors.listingDonate,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _buildSectionTitle('หมวดหมู่สินค้า'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                key: const ValueKey('listing-category'),
                isExpanded: true,
                initialValue: _selectedCategory,
                decoration: InputDecoration(
                  hintText: 'เลือกหมวดหมู่',
                  errorText: _selectedCategory == null
                      ? 'กรุณาเลือกหมวดหมู่'
                      : null,
                ),
                items: _categories
                    .map(
                      (category) => DropdownMenuItem(
                        value: category,
                        child: Text(
                          category,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setState(() {
                  _selectedCategory = value;
                }),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('สภาพสินค้า'),
              const SizedBox(height: 6),
              DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: _selectedCondition,
                items: _conditions
                    .map(
                      (condition) => DropdownMenuItem(
                        value: condition,
                        child: Text(
                          condition,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) setState(() => _selectedCondition = value);
                },
              ),
              const SizedBox(height: 16),
              _buildSectionTitle('รูปแบบการนัดรับ'),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  _pickupChip(PickupType.sellerHome, 'บ้านผู้ขาย'),
                  _pickupChip(PickupType.agreedSpot, 'จุดที่ตกลงกัน'),
                  _pickupChip(PickupType.discussInChat, 'คุยกันในแชท'),
                ],
              ),
              if (_pickupType == PickupType.sellerHome)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text(
                    'นัดรับในที่ปลอดภัย และอย่ากรอกที่อยู่จริงในชื่อหรือรายละเอียดประกาศ',
                    style: TextStyle(color: AppColors.warning, fontSize: 12),
                  ),
                ),
              const SizedBox(height: 16),
              LocationPicker(
                initialLocation: _initialExactLocation,
                initialLocationLabel: _location.locationLabel,
                initialExactAddress: _initialExactAddress,
                onChanged: (value) => setState(() => _location = value),
              ),
              const SizedBox(height: 16),
              _buildSectionTitle(
                'รายละเอียดเพิ่มเติม (ไม่เกิน $kMaxListingDescriptionLength ตัวอักษร)',
              ),
              const SizedBox(height: 6),
              TextFormField(
                key: const ValueKey('listing-description'),
                controller: _descriptionController,
                maxLength: kMaxListingDescriptionLength,
                maxLines: 4,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                onChanged: (_) => setState(() {}),
                validator: (_) =>
                    validateListingDescription(_descriptionController.text),
                decoration: InputDecoration(
                  hintText: 'อธิบายสภาพสินค้า ตำหนิ และรายละเอียดที่จำเป็น',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  key: const ValueKey('publish-listing'),
                  onPressed: _isFormValid ? _submitListing : null,
                  child: Text(
                    _isEditing ? 'บันทึกการแก้ไข' : 'เผยแพร่ประกาศ',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Scaffold(
      appBar: AppBar(title: const Text('ลงประกาศสินค้า')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('เข้าสู่ระบบก่อนลงประกาศ'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
                ),
                child: const Text('เข้าสู่ระบบ'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) => Text(
    title,
    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
  );

  Widget _pickupChip(PickupType type, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: _pickupType == type,
      showCheckmark: false,
      selectedColor: AppColors.aquaPale,
      onSelected: (_) => setState(() => _pickupType = type),
    );
  }

  Widget _buildImageTile(int index) {
    final image = _images[index];
    final isCover = index == 0;
    return GestureDetector(
      key: ValueKey('listing-image-$index'),
      onTap: () => _setCover(index),
      child: Container(
        width: 100,
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCover ? AppColors.oceanBlue : AppColors.grayLine,
            width: isCover ? 2 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ProductImage(source: image),
              if (isCover)
                const Positioned(left: 4, top: 4, child: _CoverBadge()),
              Positioned(
                right: 2,
                top: 2,
                child: IconButton(
                  tooltip: 'ลบรูป ${index + 1}',
                  onPressed: () => _removeImage(index),
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white.withValues(alpha: 0.9),
                    minimumSize: const Size(28, 28),
                    padding: EdgeInsets.zero,
                  ),
                  icon: const Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: AppColors.error,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddImageButton() {
    return OutlinedButton(
      key: const ValueKey('add-listing-image'),
      onPressed: _isPickingImages ? null : _showImageSourceOptions,
      child: SizedBox(
        width: 88,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _isPickingImages
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.add_photo_alternate_outlined),
            const SizedBox(height: 4),
            const Text('เพิ่มรูป', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
    );
  }

  bool get _isFormValid {
    if (validateListingTitle(_titleController.text) != null ||
        validateListingDescription(_descriptionController.text) != null ||
        _selectedCategory == null ||
        _images.length < kMinListingImages ||
        _location.exactLocation == null ||
        _location.locationLabel.trim().isEmpty) {
      return false;
    }
    if (_listingType == ListingType.sell &&
        validateListingPrice(_priceController.text) != null) {
      return false;
    }
    if (_listingType == ListingType.trade &&
        (validateListingPrice(_priceController.text, required: false) != null ||
            validateTradeRequest(_tradeForController.text) != null)) {
      return false;
    }
    return true;
  }

  Future<void> _showImageSourceOptions() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('เลือกจากแกลเลอรี่'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('ถ่ายภาพ'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
          ],
        ),
      ),
    );
    if (source != null) await _pickImages(source);
  }

  Future<void> _pickImages(ImageSource source) async {
    final remaining = kMaxListingImages - _images.length;
    if (remaining <= 0) {
      _showMessage('เลือกได้สูงสุด $kMaxListingImages รูป');
      return;
    }

    setState(() => _isPickingImages = true);
    try {
      final handler = widget.pickImages ?? _pickImagesWithPlugin;
      final picked = await handler(source, limit: remaining);
      if (!mounted || picked == null || picked.isEmpty) return;

      final selected = picked.take(remaining).toList();
      final bytes = await Future.wait<Uint8List>(
        selected.map((file) => file.readAsBytes()),
      );
      if (!mounted) return;
      setState(() {
        _images.addAll(bytes.map(ProductImageData.memory));
      });
      if (picked.length > remaining) {
        _showMessage('เลือกเพิ่มได้อีกไม่เกิน $remaining รูป');
      }
    } on PlatformException catch (error) {
      if (mounted) {
        final code = error.code.toLowerCase();
        final denied = code.contains('denied') || code.contains('permission');
        _showMessage(
          denied
              ? 'ไม่ได้รับอนุญาตให้เข้าถึงกล้องหรือรูปภาพ'
              : 'ไม่สามารถเลือกรูปภาพได้: ${error.message ?? error.code}',
        );
      }
    } finally {
      if (mounted) setState(() => _isPickingImages = false);
    }
  }

  Future<List<XFile>?> _pickImagesWithPlugin(
    ImageSource source, {
    required int limit,
  }) async {
    if (source == ImageSource.gallery) {
      return _imagePicker.pickMultiImage(
        maxWidth: kListingImageMaxWidth.toDouble(),
        imageQuality: kListingImageQuality,
        limit: limit,
        requestFullMetadata: false,
      );
    }
    final image = await _imagePicker.pickImage(
      source: source,
      maxWidth: kListingImageMaxWidth.toDouble(),
      imageQuality: kListingImageQuality,
      requestFullMetadata: false,
    );
    return image == null ? null : [image];
  }

  void _setCover(int index) {
    if (index == 0) return;
    setState(() {
      final image = _images.removeAt(index);
      _images.insert(0, image);
    });
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  void _submitListing() {
    if (!_isFormValid) return;
    final appState = AppState();
    final price =
        _listingType == ListingType.donate ||
            _priceController.text.trim().isEmpty
        ? 0.0
        : parseListingPrice(_priceController.text);
    final productImages = List<ProductImageData>.of(_images);
    final coverUrl = productImages.first.url ?? '';
    final exactLocation = _location.exactLocation!;

    try {
      if (_editingProduct == null) {
        appState.addListing(
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          tradeFor: _tradeForController.text,
          type: _listingType,
          category: _selectedCategory!,
          condition: _selectedCondition,
          exactLocation: exactLocation,
          locationLabel: _location.locationLabel,
          exactAddress: _location.exactAddress,
          pickupType: _pickupType,
          imageUrl: coverUrl,
          productImages: productImages,
        );
      } else {
        appState.updateListing(
          id: _editingProduct!.id,
          title: _titleController.text,
          description: _descriptionController.text,
          price: price,
          tradeFor: _tradeForController.text,
          type: _listingType,
          category: _selectedCategory!,
          condition: _selectedCondition,
          exactLocation: exactLocation,
          locationLabel: _location.locationLabel,
          exactAddress: _location.exactAddress,
          pickupType: _pickupType,
          imageUrl: coverUrl,
          productImages: productImages,
        );
      }
    } on StateError catch (error) {
      _showMessage(error.message.toString());
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isEditing ? 'แก้ไขประกาศเรียบร้อย' : 'ลงประกาศเรียบร้อย',
        ),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.pop(context);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _CoverBadge extends StatelessWidget {
  const _CoverBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.oceanBlue,
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Text(
          'รูปปก',
          style: TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
