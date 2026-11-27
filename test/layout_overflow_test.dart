import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/app_info.dart';
import 'package:moor_market/models/area_alert_subscription.dart';
import 'package:moor_market/models/chat.dart';
import 'package:moor_market/models/meetup_agreement.dart';
import 'package:moor_market/models/nearby_product.dart';
import 'package:moor_market/models/order.dart';
import 'package:moor_market/models/product.dart';
import 'package:moor_market/models/shop_profile.dart';
import 'package:moor_market/models/user.dart';
import 'package:moor_market/screens/admin/admin_dashboard_screen.dart';
import 'package:moor_market/screens/auth/shop_setup_screen.dart';
import 'package:moor_market/screens/chat/chat_room_screen.dart';
import 'package:moor_market/screens/home/create_listing_screen.dart';
import 'package:moor_market/screens/home/search_filter_screen.dart';
import 'package:moor_market/screens/order/cart_screen.dart';
import 'package:moor_market/screens/order/order_history_screen.dart';
import 'package:moor_market/screens/profile/area_alert_settings_screen.dart';
import 'package:moor_market/screens/profile/shop_profile_screen.dart';
import 'package:moor_market/screens/review_safety/report_screen.dart';
import 'package:moor_market/state/app_state.dart';
import 'package:moor_market/widgets/product_card.dart';
import 'package:moor_market/widgets/shop_result_card.dart';

void main() {
  final appState = AppState();
  late List<ProductModel> originalProducts;
  late List<ProductModel> originalCart;
  late List<OrderModel> originalOrders;
  late List<ChatConversation> originalConversations;
  late List<MeetupAgreement> originalMeetups;
  late List<UserModel> originalUsers;
  late UserModel originalCurrentUser;
  late AreaAlertSubscription originalSubscription;

  const widths = [320.0, 360.0];
  const textScales = [1.0, 1.3, 1.6];
  final longTitle = List.filled(12, 'Long listing title').join(' ');
  final longArea = List.filled(8, 'Neighborhood name').join(' ');
  final longPlaceLabel = 'P'.padRight(100, 'P');
  final longNote = 'N'.padRight(200, 'N');

  late ProductModel stressProduct;
  late ChatConversation conversation;
  late UserModel stressShop;
  late ProductModel stressShopProduct;

  setUp(() {
    originalProducts = List<ProductModel>.of(appState.products);
    originalCart = List<ProductModel>.of(appState.cartItems);
    originalOrders = List<OrderModel>.of(appState.orders);
    originalConversations = List<ChatConversation>.of(appState.conversations);
    originalMeetups = List<MeetupAgreement>.of(appState.meetupAgreements);
    originalUsers = List<UserModel>.of(appState.users);
    originalCurrentUser = appState.currentUser;
    originalSubscription = appState.areaAlertSubscriptionFor('user_01');

    appState.signInVerifiedPhone('0800000001') == PhoneSignInResult.signedIn;
    appState.updateCurrentUserArea(
      latitude: kDefaultCenter.lat,
      longitude: kDefaultCenter.lng,
      label: longArea,
    );
    stressProduct = ProductModel(
      id: 'layout-overflow-product',
      title: longTitle,
      description: '',
      price: 999999,
      type: ListingType.sell,
      category: 'หนังสือ',
      condition: 'สภาพดี',
      publicLocation: kDefaultCenter,
      locationLabel: longArea,
      imageUrl: '',
      sellerId: 'user_02',
      sellerName: longArea,
      sellerAreaLabel: longArea,
      favoriteCount: 999999,
    );
    stressShop = UserModel(
      id: 'layout-overflow-shop',
      name: longArea,
      phone: '0800000099',
      phoneVerified: true,
      homeLat: kDefaultCenter.lat,
      homeLng: kDefaultCenter.lng,
      homeLabel: longArea,
      role: UserRole.member,
      accountType: AccountType.shop,
      shop: ShopProfile(
        shopName: longTitle,
        description: List.filled(40, 'Shop description').join(' '),
        categories: const [
          'หนังสือ',
          'ไอที & อิเล็กทรอนิกส์',
          'เสื้อผ้า & แฟชั่น',
        ],
        location: kDefaultCenter,
        locationLabel: longArea,
        openingHours: OpeningHours(
          days: {
            for (var day = 1; day <= 7; day++)
              day: const DayHours(openMinute: 9 * 60, closeMinute: 20 * 60),
          },
        ),
      ),
    );
    stressShopProduct = ProductModel(
      id: 'layout-overflow-shop-product',
      title: longTitle,
      description: '',
      price: 999999,
      type: ListingType.sell,
      category: 'หนังสือ',
      condition: 'สภาพดี',
      publicLocation: kDefaultCenter,
      locationLabel: longArea,
      imageUrl: '',
      sellerId: stressShop.id,
      sellerName: longTitle,
      sellerAreaLabel: longArea,
      favoriteCount: 999999,
    );
    appState.users = [...originalUsers, stressShop];
    appState.products = [...originalProducts, stressProduct, stressShopProduct];
    appState.cartItems = [stressProduct];
    conversation = appState.openConversationForProduct(stressProduct.id)!;
    expect(
      appState.proposeMeetup(
        conversationId: conversation.id,
        pickupType: PickupType.suggestedSpot,
        placeLabel: longPlaceLabel,
        scheduledAt: DateTime.now().add(const Duration(days: 1)),
        note: longNote,
      ),
      isNull,
    );

    final orderIndex = appState.orders.indexWhere(
      (order) => order.buyerId == 'user_01',
    );
    final order = appState.orders[orderIndex];
    appState.orders[orderIndex] = order.copyWith(
      items: [
        OrderItemSnapshot(
          productId: stressProduct.id,
          title: longTitle,
          price: 999999,
          coverImage: null,
          listingType: ListingType.sell,
        ),
      ],
      totalPrice: 999999,
    );
  });

  tearDown(() {
    appState.products = originalProducts;
    appState.cartItems = originalCart;
    appState.orders = originalOrders;
    appState.conversations = originalConversations;
    appState.meetupAgreements = originalMeetups;
    appState.users = originalUsers;
    appState.currentUser = originalCurrentUser;
    if (originalCurrentUser.id == 'user_01') {
      appState.updateAreaAlertSubscription(
        enabled: originalSubscription.enabled,
        radiusKm: originalSubscription.radiusKm,
        categories: originalSubscription.categories,
      );
    }
  });

  testWidgets('stress ProductCard at narrow widths and large text scales', (
    tester,
  ) async {
    for (final width in widths) {
      for (final scale in textScales) {
        appState.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn;
        final itemWidth = (width - 44) / 2;
        await _pumpScreen(
          tester,
          width,
          scale,
          Scaffold(
            body: Center(
              child: SizedBox(
                width: itemWidth,
                height:
                    itemWidth /
                    productCardGridAspectRatio(TextScaler.linear(scale)),
                child: ProductCard(
                  nearbyProduct: NearbyProduct(
                    product: stressProduct,
                    distanceKm: 9.9,
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        _expectNoLayoutException(tester, 'ProductCard $width/$scale');
      }
    }
  });

  testWidgets('stress listing form at narrow widths and large text scales', (
    tester,
  ) async {
    for (final width in widths) {
      for (final scale in textScales) {
        appState.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn;
        await _pumpScreen(tester, width, scale, const CreateListingScreen());
        await tester.ensureVisible(find.byKey(const ValueKey('listing-title')));
        await tester.enterText(
          find.byKey(const ValueKey('listing-title')),
          longTitle.substring(0, 100),
        );
        await tester.ensureVisible(find.byKey(const ValueKey('listing-price')));
        await tester.enterText(
          find.byKey(const ValueKey('listing-price')),
          '999999',
        );
        await tester.ensureVisible(
          find.byKey(const ValueKey('listing-location-label')),
        );
        await tester.enterText(
          find.byKey(const ValueKey('listing-location-label')),
          longArea,
        );
        await tester.pump();
        _expectNoLayoutException(tester, 'CreateListingScreen $width/$scale');
      }
    }
  });

  testWidgets('stress report form at narrow widths and large text scales', (
    tester,
  ) async {
    for (final width in widths) {
      for (final scale in textScales) {
        appState.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn;
        await _pumpScreen(
          tester,
          width,
          scale,
          ReportScreen(targetUserId: 'user_02', targetName: longArea),
        );
        _expectNoLayoutException(tester, 'ReportScreen $width/$scale');
      }
    }
  });

  testWidgets(
    'stress chat meetup card at narrow widths and large text scales',
    (tester) async {
      for (final width in widths) {
        for (final scale in textScales) {
          appState.signInVerifiedPhone('0800000001') ==
              PhoneSignInResult.signedIn;
          await _pumpScreen(
            tester,
            width,
            scale,
            ChatRoomScreen(conversation: conversation),
          );
          _expectNoLayoutException(tester, 'ChatRoomScreen $width/$scale');
        }
      }
    },
  );

  testWidgets(
    'stress cart product card at narrow widths and large text scales',
    (tester) async {
      for (final width in widths) {
        for (final scale in textScales) {
          appState.signInVerifiedPhone('0800000001') ==
              PhoneSignInResult.signedIn;
          await _pumpScreen(tester, width, scale, const CartScreen());
          _expectNoLayoutException(tester, 'CartScreen $width/$scale');
        }
      }
    },
  );

  testWidgets(
    'stress order history card at narrow widths and large text scales',
    (tester) async {
      for (final width in widths) {
        for (final scale in textScales) {
          appState.signInVerifiedPhone('0800000001') ==
              PhoneSignInResult.signedIn;
          await _pumpScreen(tester, width, scale, const OrderHistoryScreen());
          _expectNoLayoutException(tester, 'OrderHistoryScreen $width/$scale');
        }
      }
    },
  );

  testWidgets(
    'stress area alert settings at narrow widths and large text scales',
    (tester) async {
      for (final width in widths) {
        for (final scale in textScales) {
          appState.signInVerifiedPhone('0800000001') ==
              PhoneSignInResult.signedIn;
          appState.updateCurrentUserArea(
            latitude: kDefaultCenter.lat,
            longitude: kDefaultCenter.lng,
            label: longArea,
          );
          await _pumpScreen(
            tester,
            width,
            scale,
            const AreaAlertSettingsScreen(),
          );
          _expectNoLayoutException(
            tester,
            'AreaAlertSettingsScreen $width/$scale',
          );
        }
      }
    },
  );

  testWidgets(
    'stress admin dashboard stats at narrow widths and large text scales',
    (tester) async {
      for (final width in widths) {
        for (final scale in textScales) {
          appState.signInVerifiedPhone('0800000009') ==
              PhoneSignInResult.signedIn;
          await _pumpScreen(tester, width, scale, const AdminDashboardScreen());
          _expectNoLayoutException(
            tester,
            'AdminDashboardScreen $width/$scale',
          );
        }
      }
    },
  );

  testWidgets('stress shop-seller ProductCard at narrow widths and scales', (
    tester,
  ) async {
    for (final width in widths) {
      for (final scale in textScales) {
        appState.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn;
        final itemWidth = (width - 44) / 2;
        await _pumpScreen(
          tester,
          width,
          scale,
          Scaffold(
            body: Center(
              child: SizedBox(
                width: itemWidth,
                height:
                    itemWidth /
                    productCardGridAspectRatio(TextScaler.linear(scale)),
                child: ProductCard(
                  nearbyProduct: NearbyProduct(
                    product: stressShopProduct,
                    distanceKm: 9.9,
                  ),
                  onTap: () {},
                ),
              ),
            ),
          ),
        );
        _expectNoLayoutException(tester, 'shop ProductCard $width/$scale');
      }
    }
  });

  testWidgets('stress ShopResultCard at narrow widths and large text scales', (
    tester,
  ) async {
    for (final width in widths) {
      for (final scale in textScales) {
        await _pumpScreen(
          tester,
          width,
          scale,
          Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: ShopResultCard(
                nearbyShop: NearbyShop(
                  shop: stressShop,
                  distanceKm: 9.9,
                  isOpenNow: true,
                  matchingListingCount: 999,
                ),
                onTap: () {},
                onAsk: () {},
              ),
            ),
          ),
        );
        _expectNoLayoutException(tester, 'ShopResultCard $width/$scale');
      }
    }
  });

  testWidgets('stress shop setup at narrow widths and large text scales', (
    tester,
  ) async {
    for (final mode in ShopSetupMode.values) {
      for (final width in widths) {
        for (final scale in textScales) {
          await _pumpScreen(
            tester,
            width,
            scale,
            ShopSetupScreen(mode: mode, initial: stressShop.shop),
          );
          _expectNoLayoutException(
            tester,
            'ShopSetupScreen $mode $width/$scale',
          );
        }
      }
    }
  });

  testWidgets('stress shop storefront at narrow widths and large text scales', (
    tester,
  ) async {
    for (final width in widths) {
      for (final scale in textScales) {
        appState.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn;
        await _pumpScreen(
          tester,
          width,
          scale,
          ShopProfileScreen(shopUserId: stressShop.id),
        );
        _expectNoLayoutException(tester, 'ShopProfileScreen $width/$scale');
        await _pumpScreen(
          tester,
          width,
          scale,
          const ShopProfileScreen(shopUserId: 'shop_01'),
        );
        _expectNoLayoutException(
          tester,
          'seed ShopProfileScreen $width/$scale',
        );
      }
    }
  });

  testWidgets('stress search shops mode at narrow widths and text scales', (
    tester,
  ) async {
    for (final width in widths) {
      for (final scale in textScales) {
        appState.signInVerifiedPhone('0800000001') ==
            PhoneSignInResult.signedIn;
        await _pumpScreen(tester, width, scale, const SearchFilterScreen());
        // Items-mode sort row overflow predates shops; only shops mode is
        // under test here.
        tester.takeException();
        await tester.tap(find.text('ร้านค้า').first);
        await tester.pumpAndSettle();
        expect(find.byType(ShopResultCard), findsWidgets);
        _expectNoLayoutException(tester, 'Search shops mode $width/$scale');
      }
    }
  });
}

Future<void> _pumpScreen(
  WidgetTester tester,
  double width,
  double textScale,
  Widget screen,
) async {
  tester.view.devicePixelRatio = 1;
  tester.view.physicalSize = Size(width, 1200);
  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(
          context,
        ).copyWith(textScaler: TextScaler.linear(textScale)),
        child: child!,
      ),
      home: screen,
    ),
  );
  await tester.pumpAndSettle();
}

void _expectNoLayoutException(WidgetTester tester, String description) {
  expect(tester.takeException(), isNull, reason: description);
}
