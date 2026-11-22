import 'package:flutter/material.dart';

import '../../models/product.dart';
import '../../models/user.dart';
import '../../state/app_state.dart';
import '../../theme/app_theme.dart';
import '../../widgets/nearby_products_map.dart';
import '../../widgets/product_image.dart';
import '../auth/login_screen.dart';
import 'create_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        if (appState.currentUser.role == UserRole.guest) {
          return Scaffold(
            appBar: AppBar(title: const Text('ประกาศของฉัน')),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('เข้าสู่ระบบเพื่อจัดการประกาศของคุณ'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const LoginScreen(),
                      ),
                    ),
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                ],
              ),
            ),
          );
        }

        final myProducts = appState.products
            .where((product) => product.sellerId == appState.currentUser.id)
            .toList();
        final active = myProducts
            .where((product) => product.status == ListingStatus.active)
            .toList();
        final sold = myProducts
            .where((product) => product.status == ListingStatus.sold)
            .toList();
        final hidden = myProducts
            .where((product) => product.status == ListingStatus.hidden)
            .toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('ประกาศของฉัน'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.oceanBlue,
              labelColor: AppColors.oceanBlue,
              unselectedLabelColor: AppColors.graySecondary,
              tabs: [
                Tab(text: 'กำลังขาย (${active.length})'),
                Tab(text: 'ขายแล้ว (${sold.length})'),
                Tab(text: 'ซ่อน (${hidden.length})'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => _openListingForm(),
            backgroundColor: AppColors.oceanBlue,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              'ลงประกาศใหม่',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProductList(active, ListingStatus.active),
              _buildProductList(sold, ListingStatus.sold),
              _buildProductList(hidden, ListingStatus.hidden),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductList(List<ProductModel> products, ListingStatus status) {
    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 54,
              color: AppColors.graySecondary,
            ),
            const SizedBox(height: 12),
            const Text(
              'ยังไม่มีประกาศในหมวดนี้',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.deepNavy,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _openListingForm,
              child: const Text('ลงประกาศเลย'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 88),
      itemCount: products.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) =>
          _buildListingCard(products[index], status),
    );
  }

  Widget _buildListingCard(ProductModel product, ListingStatus status) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: ProductImage.forProduct(product),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.type == ListingType.donate
                            ? 'ฟรี'
                            : '฿${product.price.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: product.type == ListingType.donate
                              ? AppColors.listingDonate
                              : AppColors.oceanBlue,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${product.viewCount} เข้าชม · ${product.favoriteCount} ถูกใจ',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.graySecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<_ListingAction>(
                  tooltip: 'จัดการประกาศ',
                  onSelected: (action) => _handleAction(product, action),
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: _ListingAction.edit,
                      child: Text('แก้ไข'),
                    ),
                    if (status == ListingStatus.active)
                      const PopupMenuItem(
                        value: _ListingAction.hide,
                        child: Text('ซ่อนประกาศ'),
                      ),
                    if (status == ListingStatus.hidden ||
                        status == ListingStatus.sold)
                      const PopupMenuItem(
                        value: _ListingAction.show,
                        child: Text('แสดงอีกครั้ง'),
                      ),
                    if (status != ListingStatus.sold)
                      const PopupMenuItem(
                        value: _ListingAction.sold,
                        child: Text('ทำเครื่องหมายว่าขายแล้ว'),
                      ),
                    const PopupMenuItem(
                      value: _ListingAction.delete,
                      child: Text('ลบประกาศ'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  size: 16,
                  color: AppColors.oceanBlue,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    product.locationLabel,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.graySecondary,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () => _showExactAddress(product),
                  child: const Text('ดูที่อยู่จริง'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: PublicLocationPreview(
                publicLocation: product.publicLocation,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleAction(ProductModel product, _ListingAction action) {
    final appState = AppState();
    switch (action) {
      case _ListingAction.edit:
        _openListingForm(product.id);
        break;
      case _ListingAction.hide:
        appState.setListingStatus(product.id, ListingStatus.hidden);
        break;
      case _ListingAction.show:
        appState.setListingStatus(product.id, ListingStatus.active);
        break;
      case _ListingAction.sold:
        appState.setListingStatus(product.id, ListingStatus.sold);
        break;
      case _ListingAction.delete:
        _confirmDelete(product);
        break;
    }
  }

  Future<void> _openListingForm([String? productId]) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => CreateListingScreen(productId: productId),
      ),
    );
  }

  void _showExactAddress(ProductModel product) {
    final exact = AppState().getExactLocationFor(
      product.id,
      AppState().currentUser.id,
    );
    if (exact == null) {
      _showMessage('ไม่พบข้อมูลที่อยู่จริงของประกาศนี้');
      return;
    }
    showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ที่อยู่หรือจุดสังเกต'),
        content: Text(
          exact.exactAddress.isEmpty
              ? 'คุณยังไม่ได้บันทึกที่อยู่หรือจุดสังเกตไว้'
              : exact.exactAddress,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ปิด'),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('ลบประกาศนี้?'),
        content: const Text('เมื่อลบแล้วจะไม่สามารถกู้คืนประกาศได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('ลบประกาศ'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = AppState().deleteListing(product.id);
    if (error != null) _showMessage(error);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

enum _ListingAction { edit, hide, show, sold, delete }
