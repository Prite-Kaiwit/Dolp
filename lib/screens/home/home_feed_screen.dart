import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../state/app_state.dart';
import '../../models/product.dart';
import '../../widgets/product_card.dart';
import '../../widgets/custom_search_bar.dart';
import '../../widgets/campus_banner.dart';
import 'search_filter_screen.dart';
import 'product_detail_screen.dart';
import '../order/cart_screen.dart';
import '../profile/notifications_screen.dart';

class HomeFeedScreen extends StatefulWidget {
  const HomeFeedScreen({super.key});

  @override
  State<HomeFeedScreen> createState() => _HomeFeedScreenState();
}

class _HomeFeedScreenState extends State<HomeFeedScreen> {
  String _selectedFilter = 'ทั้งหมด';
  final List<String> _filters = ['ทั้งหมด', 'ขาย', 'แลกเปลี่ยน', 'บริจาค/ส่งต่อฟรี'];

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
        final products = appState.products.where((p) {
          if (p.status != ListingStatus.active) return false;
          if (_selectedFilter == 'ขาย') return p.type == ListingType.sell;
          if (_selectedFilter == 'แลกเปลี่ยน') return p.type == ListingType.trade;
          if (_selectedFilter == 'บริจาค/ส่งต่อฟรี') return p.type == ListingType.donate;
          return true;
        }).toList();

        final unreadNotifs = appState.notifications.where((n) => !(n['read'] as bool)).length;

        return Scaffold(
          appBar: AppBar(
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.pinkPale,
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
                        const Text(
                          'มอ.Market',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: AppColors.pinkPrimary,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.greenPale,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Campus',
                            style: TextStyle(
                              color: AppColors.greenDark,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Text(
                      appState.isLoggedIn ? 'สวัสดี, ${appState.currentUser.name}' : 'ผู้เยี่ยมชม (Guest)',
                      style: const TextStyle(fontSize: 11, color: AppColors.graySecondary),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              // Notifications
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined, color: AppColors.inkText),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      );
                    },
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
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              // Cart
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.shopping_bag_outlined, color: AppColors.inkText),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                  ),
                  if (appState.cartItems.isNotEmpty)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.pinkPrimary,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${appState.cartItems.length}',
                          style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 6),
            ],
          ),
          body: RefreshIndicator(
            color: AppColors.pinkPrimary,
            onRefresh: () async {
              await Future.delayed(const Duration(milliseconds: 600));
              setState(() {});
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Bar
                  CustomSearchBar(
                    readOnly: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
                      );
                    },
                    onFilterTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  // Campus Banner (Escrow Feature)
                  CampusBanner(
                    onLearnMore: () {
                      _showEscrowInfoSheet(context);
                    },
                  ),
                  const SizedBox(height: 18),

                  // Campus Pickup Points Scroll
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.place_rounded, color: AppColors.greenPrimary, size: 18),
                          SizedBox(width: 4),
                          Text(
                            'จุดนัดรับปลอดภัยใน มอ.',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.inkText,
                            ),
                          ),
                        ],
                      ),
                      Text(
                        '${appState.pickupPoints.length} จุด',
                        style: const TextStyle(fontSize: 12, color: AppColors.graySecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 38,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: appState.pickupPoints.length,
                      itemBuilder: (context, index) {
                        final p = appState.pickupPoints[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.greenPale,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.greenLight),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline, size: 14, color: AppColors.greenPrimary),
                              const SizedBox(width: 4),
                              Text(
                                p.name,
                                style: const TextStyle(
                                  color: AppColors.greenDark,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Type Tabs (All, Sell, Trade, Donate)
                  SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final filter = _filters[index];
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(filter),
                            selected: isSelected,
                            selectedColor: AppColors.pinkPrimary,
                            backgroundColor: AppColors.grayBg,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : AppColors.inkText,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: BorderSide(
                                color: isSelected ? AppColors.pinkPrimary : AppColors.grayLine,
                              ),
                            ),
                            showCheckmark: false,
                            onSelected: (_) => setState(() => _selectedFilter = filter),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Section Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'สินค้าแนะนำใน มอ. (${products.length})',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.inkText,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const SearchFilterScreen()),
                          );
                        },
                        child: const Text(
                          'ดูทั้งหมด >',
                          style: TextStyle(
                            color: AppColors.pinkPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 2-Column Product Grid
                  if (products.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(40),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(Icons.inbox_outlined, size: 48, color: AppColors.graySecondary),
                          const SizedBox(height: 12),
                          Text(
                            'ไม่พบสินค้าในหมวด $_selectedFilter',
                            style: const TextStyle(color: AppColors.graySecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    )
                  else
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 0.65,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
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
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showEscrowInfoSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.grayLine,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Row(
                children: [
                  Icon(Icons.shield_rounded, color: AppColors.greenPrimary, size: 28),
                  SizedBox(width: 8),
                  Text(
                    'ระบบพักเงิน Escrow ทำงานอย่างไร?',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.inkText),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildStepItem('1', 'ผู้ซื้อชำระเงิน', 'เงินจะถูกพักไว้ในบัญชีกลางของระบบอย่างปลอดภัย'),
              _buildStepItem('2', 'นัดหมายส่งมอบ', 'นัดรับสินค้า ณ จุดนัดรับภายในมหาวิทยาลัย (เช่น โรงอาหารกลาง)'),
              _buildStepItem('3', 'ตรวจสอบสินค้า', 'ผู้ซื้อตรวจสภาพสินค้าจริง หากถูกต้องให้กดยืนยันรับสินค้า'),
              _buildStepItem('4', 'โอนเงินให้ผู้ขาย', 'ระบบโอนเงินเข้าบัญชีผู้ขายทันที หรือเปิดข้อพิพาทหากมีปัญหา'),
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
        );
      },
    );
  }

  Widget _buildStepItem(String number, String title, String desc) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: AppColors.pinkPale,
            child: Text(number, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.pinkPrimary)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.inkText)),
                Text(desc, style: const TextStyle(fontSize: 12, color: AppColors.graySecondary)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
