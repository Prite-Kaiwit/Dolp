import 'package:flutter/material.dart';
import '../../models/product.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import 'create_listing_screen.dart';

class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
        final currentUserId = appState.currentUser.id;
        final myProducts = appState.products.where((p) => p.sellerId == currentUserId || p.sellerName == appState.currentUser.name).toList();

        final activeProducts = myProducts.where((p) => p.status == ListingStatus.active).toList();
        final soldProducts = myProducts.where((p) => p.status == ListingStatus.sold).toList();
        final hiddenProducts = myProducts.where((p) => p.status == ListingStatus.hidden).toList();

        return Scaffold(
          appBar: AppBar(
            title: const Text('จัดการประกาศของฉัน'),
            bottom: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.pinkPrimary,
              labelColor: AppColors.pinkPrimary,
              unselectedLabelColor: AppColors.graySecondary,
              tabs: [
                Tab(text: 'กำลังขาย (${activeProducts.length})'),
                Tab(text: 'ขายแล้ว (${soldProducts.length})'),
                Tab(text: 'ซ่อนอยู่ (${hiddenProducts.length})'),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CreateListingScreen()),
              );
            },
            backgroundColor: AppColors.pinkPrimary,
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text('ลงขายใหม่', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildProductList(activeProducts, ListingStatus.active),
              _buildProductList(soldProducts, ListingStatus.sold),
              _buildProductList(hiddenProducts, ListingStatus.hidden),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductList(List<ProductModel> items, ListingStatus status) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.graySecondary),
            const SizedBox(height: 12),
            const Text(
              'ไม่มีรายการสินค้าในหมวดหมู่นี้',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.inkText),
            ),
            const SizedBox(height: 6),
            const Text(
              'คุณสามารถลงขายสินค้า หรือแลกเปลี่ยน/บริจาคได้ทันที',
              style: TextStyle(fontSize: 13, color: AppColors.graySecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CreateListingScreen()),
                );
              },
              child: const Text('+ ลงประกาศเลย'),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = items[index];
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Thumbnail
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 76,
                    height: 76,
                    child: Image.network(product.imageUrl, fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(width: 12),

                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.type == ListingType.donate
                            ? 'ส่งต่อฟรี'
                            : '฿${product.price.toStringAsFixed(0)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.pinkPrimary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.visibility_outlined, size: 12, color: AppColors.graySecondary),
                          const SizedBox(width: 3),
                          Text('${product.viewCount} เข้าชม', style: const TextStyle(fontSize: 11, color: AppColors.graySecondary)),
                          const SizedBox(width: 10),
                          const Icon(Icons.favorite_border, size: 12, color: AppColors.graySecondary),
                          const SizedBox(width: 3),
                          Text('${product.favoriteCount} ถูกใจ', style: const TextStyle(fontSize: 11, color: AppColors.graySecondary)),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Actions
                      Row(
                        children: [
                          if (status == ListingStatus.active) ...[
                            _buildActionButton('ขายแล้ว', () {
                              AppState().updateProductStatus(product.id, ListingStatus.sold);
                            }, AppColors.greenPrimary),
                            const SizedBox(width: 8),
                            _buildActionButton('ซ่อน', () {
                              AppState().updateProductStatus(product.id, ListingStatus.hidden);
                            }, AppColors.graySecondary),
                          ] else if (status == ListingStatus.hidden) ...[
                            _buildActionButton('เปิดขายใหม่', () {
                              AppState().updateProductStatus(product.id, ListingStatus.active);
                            }, AppColors.pinkPrimary),
                          ] else ...[
                            _buildActionButton('ขายใหม่อีกครั้ง', () {
                              AppState().updateProductStatus(product.id, ListingStatus.active);
                            }, AppColors.pinkPrimary),
                          ],
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                            onPressed: () {
                              _showDeleteDialog(context, product.id);
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildActionButton(String label, VoidCallback onTap, Color color) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
        ),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, String productId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('ลบประกาศสินค้านี้?'),
        content: const Text('เมื่อลบแล้วจะไม่สามารถกู้คืนข้อมูลประกาศนี้ได้'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            onPressed: () {
              AppState().deleteProduct(productId);
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('ลบประกาศ'),
          ),
        ],
      ),
    );
  }
}
