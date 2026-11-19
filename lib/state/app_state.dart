import 'package:flutter/material.dart';
import '../constants/app_info.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/order.dart';
import '../models/chat.dart';
import '../models/pickup_point.dart';
import '../models/report.dart';

class _MockCredential {
  final String userId;
  // ห้ามใช้จริง ต้องเปลี่ยนเป็น hash ฝั่ง server
  final String password;

  const _MockCredential({required this.userId, required this.password});
}

class AppState extends ChangeNotifier {
  static final AppState _instance = AppState._internal();
  factory AppState() => _instance;

  AppState._internal() {
    _initMockData();
  }

  // Mock-only credentials; never use plaintext passwords outside this prototype.
  final Map<String, _MockCredential> _credentialsByPhone = {};
  List<UserModel> users = [];
  UserModel currentUser = UserModel(
    id: 'guest_01',
    name: 'ผู้เยี่ยมชม',
    role: UserRole.guest,
  );

  bool get isLoggedIn => currentUser.role != UserRole.guest;
  bool get isAdmin => currentUser.role == UserRole.admin;

  // Cart
  List<ProductModel> cartItems = [];

  // Products
  List<ProductModel> products = [];

  // Orders (Escrow)
  List<OrderModel> orders = [];

  // Chats
  List<ChatConversation> conversations = [];

  // Suggested public meeting points.
  List<PickupPointModel> pickupPoints = [];

  // Reports (Trust & Safety / Admin)
  List<ReportModel> reports = [];

  // Notifications
  List<Map<String, dynamic>> notifications = [];

  void _initMockData() {
    users = [
      UserModel(
        id: 'user_01',
        name: 'กานต์ รัตนพันธ์',
        phone: '0800000001',
        phoneVerified: true,
        homeLat: 12.6112,
        homeLng: 102.1031,
        homeLabel: 'อำเภอเมืองจันทบุรี',
        role: UserRole.member,
        rating: 4.9,
        reviewCount: 38,
        successfulDeals: 24,
      ),
      UserModel(
        id: 'user_02',
        name: 'พีรภัทร ชาญวิทย์',
        phone: '0800000002',
        phoneVerified: true,
        homeLat: 12.6230,
        homeLng: 101.9990,
        homeLabel: 'อำเภอท่าใหม่',
        role: UserRole.member,
        rating: 4.9,
        reviewCount: 42,
        successfulDeals: 31,
      ),
      UserModel(
        id: 'admin_01',
        name: 'ผู้ดูแลระบบ',
        phone: '0800000009',
        phoneVerified: true,
        homeLat: 12.6112,
        homeLng: 102.1031,
        homeLabel: 'อำเภอเมืองจันทบุรี',
        role: UserRole.admin,
        rating: 5.0,
        reviewCount: 99,
        successfulDeals: 150,
      ),
    ];
    _credentialsByPhone.addAll({
      '0800000001': const _MockCredential(
        userId: 'user_01',
        password: 'password123',
      ),
      '0800000002': const _MockCredential(
        userId: 'user_02',
        password: 'password123',
      ),
      '0800000009': const _MockCredential(
        userId: 'admin_01',
        password: 'password123',
      ),
    });
    currentUser = users.first;

    pickupPoints = [
      PickupPointModel(
        id: 'p1',
        name: 'จุดสาธารณะตัวอย่าง เขตเมือง',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในเขตเมือง',
        zone: 'เขตเมือง',
        openHours: '07:30 - 20:00 น.',
      ),
      PickupPointModel(
        id: 'p2',
        name: 'จุดสาธารณะตัวอย่าง ท่าใหม่',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในอำเภอท่าใหม่',
        zone: 'ท่าใหม่',
        openHours: '08:00 - 21:00 น.',
      ),
      PickupPointModel(
        id: 'p3',
        name: 'จุดสาธารณะตัวอย่าง ขลุง',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในอำเภอขลุง',
        zone: 'ขลุง',
        openHours: '08:30 - 18:30 น.',
      ),
      PickupPointModel(
        id: 'p4',
        name: 'จุดสาธารณะตัวอย่าง แหลมสิงห์',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในอำเภอแหลมสิงห์',
        zone: 'แหลมสิงห์',
        openHours: '08:00 - 22:00 น.',
      ),
      PickupPointModel(
        id: 'p5',
        name: 'จุดสาธารณะตัวอย่าง นายายอาม',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในอำเภอนายายอาม',
        zone: 'นายายอาม',
        openHours: '06:00 - 22:00 น.',
      ),
    ];

    products = [
      ProductModel(
        id: 'prod_1',
        title: 'หนังสือ Calculus 1 ฉบับสรุปสอบ',
        description:
            'มีไฮไลท์จุดสำคัญและข้อสอบเก่าย้อนหลัง 5 ปี พร้อมเฉลยละเอียด สภาพ 95% ไม่มีรอยฉีกขาด',
        price: 180.0,
        type: ListingType.sell,
        category: 'หนังสือ',
        condition: 'สภาพดีมาก (95%)',
        pickupPoint: 'จุดสาธารณะตัวอย่าง เขตเมือง',
        imageUrl:
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500',
        sellerId: 'user_02',
        sellerName: 'พีรภัทร ชาญวิทย์',
        sellerAreaLabel: 'อำเภอเมืองจันทบุรี',
        sellerRating: 4.9,
        sellerReviewCount: 42,
        viewCount: 128,
        favoriteCount: 14,
      ),
      ProductModel(
        id: 'prod_2',
        title: 'เครื่องคิดเลขวิทยาศาสตร์ Casio fx-991EX (ClassWiz)',
        description:
            'ใช้งานแคลคูลัสและสถิติได้สบาย อยากแลกเปลี่ยนกับเครื่องคิดเลขการเงิน หรือขายในราคาพิเศษ แบตเตอรี่เพิ่งเปลี่ยนใหม่',
        price: 650.0,
        tradeFor:
            'เครื่องคิดเลขการเงิน Texas Instruments หรือหนังสือ Data Structure',
        type: ListingType.trade,
        category: 'อุปกรณ์และเครื่องเขียน',
        condition: 'สภาพดี (90%)',
        pickupPoint: 'จุดสาธารณะตัวอย่าง ขลุง',
        imageUrl:
            'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=500',
        sellerId: 'user_03',
        sellerName: 'ณัฐชา เกียรติสกุล',
        sellerAreaLabel: 'อำเภอท่าใหม่',
        sellerRating: 5.0,
        sellerReviewCount: 18,
        viewCount: 94,
        favoriteCount: 19,
      ),
      ProductModel(
        id: 'prod_3',
        title: 'เสื้อกาวน์แลปวิทยาศาสตร์ ไซส์ M (ส่งต่อฟรี)',
        description:
            'เรียนจบแลปแล้วไม่ได้ใช้ สภาพยังดีมาก ซักรีดสะอาด ส่งต่อให้น้องเฟรชชี่ที่จำเป็นต้องใช้ฟรี ไม่มีค่าใช้จ่ายครับ',
        price: 0.0,
        type: ListingType.donate,
        category: 'เสื้อผ้า & เครื่องแต่งกาย',
        condition: 'สภาพดีมาก (95%)',
        pickupPoint: 'จุดสาธารณะตัวอย่าง ท่าใหม่',
        imageUrl:
            'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=500',
        sellerId: 'user_04',
        sellerName: 'ธนกฤต มั่นคง',
        sellerAreaLabel: 'อำเภอขลุง',
        sellerRating: 4.8,
        sellerReviewCount: 29,
        viewCount: 210,
        favoriteCount: 35,
      ),
      ProductModel(
        id: 'prod_4',
        title: 'โต๊ะญี่ปุ่นพับได้ ไม้แท้ สำหรับบ้าน',
        description:
            'ขนาด 60x40 ซม. ขาพับเก็บได้ แข็งแรงทนทาน น้ำหนักเบา ขนย้ายง่าย',
        price: 150.0,
        type: ListingType.sell,
        category: 'ของใช้ในบ้าน & เฟอร์นิเจอร์',
        condition: 'สภาพดี (85%)',
        pickupPoint: 'จุดสาธารณะตัวอย่าง แหลมสิงห์',
        imageUrl:
            'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=500',
        sellerId: 'user_05',
        sellerName: 'อภิสิทธิ์ วงศ์วิไล',
        sellerAreaLabel: 'อำเภอแหลมสิงห์',
        sellerRating: 4.7,
        sellerReviewCount: 15,
        viewCount: 88,
        favoriteCount: 8,
      ),
      ProductModel(
        id: 'prod_5',
        title: 'iPad Sleeve ซองหนังใส่แท็บเล็ต 11 นิ้ว มีช่องใส่ปากกา',
        description:
            'วัสดุหนัง PU กันกระแทกได้ดี ด้านในบุกำมะหยี่นุ่ม ไม่ทำให้เครื่องเป็นรอย สีเขียวพาสเทล',
        price: 120.0,
        type: ListingType.sell,
        category: 'ไอที & อิเล็กทรอนิกส์',
        condition: 'ใหม่เอี่ยม (100%)',
        pickupPoint: 'จุดสาธารณะตัวอย่าง เขตเมือง',
        imageUrl:
            'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500',
        sellerId: 'user_06',
        sellerName: 'มนัสวี โสภณ',
        sellerAreaLabel: 'อำเภอนายายอาม',
        sellerRating: 4.9,
        sellerReviewCount: 22,
        viewCount: 145,
        favoriteCount: 27,
      ),
      ProductModel(
        id: 'prod_6',
        title: 'ไม้แบดมินตัน Yonex Nanoray + ซองสะพาย',
        description:
            'เอ็นขึ้น 24 ปอนด์ พร้อมกริปใหม่ อยากแลกเปลี่ยนกับไม้เทเบิลเทนนิส หรือลูกบาสเกตบอล',
        price: 450.0,
        tradeFor: 'ไม้ปิงปอง Butterfly หรือ ลูกบาส Molten เบอร์ 7',
        type: ListingType.trade,
        category: 'ของสะสม & กีฬา',
        condition: 'สภาพดี (85%)',
        pickupPoint: 'จุดสาธารณะตัวอย่าง ท่าใหม่',
        imageUrl:
            'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=500',
        sellerId: 'user_07',
        sellerName: 'วรภัทร ชาญยุทธ',
        sellerAreaLabel: 'อำเภอเมืองจันทบุรี',
        sellerRating: 4.8,
        sellerReviewCount: 11,
        viewCount: 65,
        favoriteCount: 5,
      ),
    ];

    // Seed an active Escrow Order (UC-02)
    orders = [
      OrderModel(
        id: 'ORD-2026-0901',
        productId: 'prod_1',
        productTitle: 'หนังสือ Calculus 1 สำหรับวิศวกรรมศาสตร์ ฉบับสรุปสอบ',
        productPrice: 180.0,
        productImageUrl:
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500',
        buyerId: 'user_01',
        buyerName: 'กานต์ รัตนพันธ์',
        sellerId: 'user_02',
        sellerName: 'พีรภัทร ชาญวิทย์',
        pickupPoint: 'จุดสาธารณะตัวอย่าง เขตเมือง',
        scheduledTime: 'วันนี้ เวลา 17:30 น.',
        paymentMethod: 'PromptPay (QR Code)',
        status: OrderStatus.escrowHolding, // Step 1: Escrow Holding!
        note: 'นัดรับที่โต๊ะหน้า SCB นะครับ',
      ),
      OrderModel(
        id: 'ORD-2026-0814',
        productId: 'prod_5',
        productTitle: 'iPad Sleeve ซองหนังใส่แท็บเล็ต 11 นิ้ว',
        productPrice: 120.0,
        productImageUrl:
            'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500',
        buyerId: 'user_01',
        buyerName: 'กานต์ รัตนพันธ์',
        sellerId: 'user_06',
        sellerName: 'มนัสวี โสภณ',
        pickupPoint: 'จุดสาธารณะตัวอย่าง ขลุง',
        scheduledTime: '2 ก.ย. 2026 เวลา 13:00 น.',
        paymentMethod: 'Mobile Banking',
        status: OrderStatus.completed,
      ),
    ];

    // Seed Conversations (FR-03)
    conversations = [
      ChatConversation(
        id: 'chat_01',
        peerId: 'user_02',
        peerName: 'พีรภัทร ชาญวิทย์',
        peerAvatar:
            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=150',
        productId: 'prod_1',
        productTitle: 'หนังสือ Calculus 1 สรุปสอบ',
        productPrice: 180.0,
        productImageUrl:
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500',
        lastMessage: 'ผมชำระเงินผ่านระบบ Escrow แล้วครับ เจอกันที่คอมเพล็กซ์นะ',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 12)),
        unreadCount: 1,
        messages: [
          ChatMessage(
            id: 'm1',
            senderId: 'user_01',
            text: 'สวัสดีครับ สนใจหนังสือแคล 1 ยังอยู่ไหมครับ',
            timestamp: DateTime.now().subtract(const Duration(hours: 2)),
            isMe: true,
          ),
          ChatMessage(
            id: 'm2',
            senderId: 'user_02',
            text:
                'ยังอยู่ครับ สะดวกนัดรับที่จุดสาธารณะในเขตเมืองช่วงเย็นไหมครับ',
            timestamp: DateTime.now().subtract(
              const Duration(hours: 1, minutes: 40),
            ),
            isMe: false,
          ),
          ChatMessage(
            id: 'm3',
            senderId: 'user_01',
            text: 'ผมชำระเงินผ่านระบบ Escrow แล้วครับ เจอกันที่คอมเพล็กซ์นะ',
            timestamp: DateTime.now().subtract(const Duration(minutes: 12)),
            isMe: true,
          ),
        ],
      ),
      ChatConversation(
        id: 'chat_02',
        peerId: 'user_03',
        peerName: 'ณัฐชา เกียรติสกุล',
        peerAvatar:
            'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        productId: 'prod_2',
        productTitle: 'เครื่องคิดเลขวิทยาศาสตร์ Casio fx-991EX',
        productPrice: 650.0,
        productImageUrl:
            'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=500',
        lastMessage: 'มีหนังสือ Data Structures แลกได้ไหมคะ',
        lastMessageTime: DateTime.now().subtract(const Duration(hours: 5)),
        unreadCount: 0,
        messages: [
          ChatMessage(
            id: 'm20',
            senderId: 'user_03',
            text: 'มีหนังสือ Data Structures แลกได้ไหมคะ',
            timestamp: DateTime.now().subtract(const Duration(hours: 5)),
            isMe: false,
          ),
        ],
      ),
    ];

    // Seed Reports for Admin Dashboard (FR-11, UC-03)
    reports = [
      ReportModel(
        id: 'REP-001',
        orderId: 'ORD-2026-0899',
        reporterId: 'user_09',
        reporterName: 'ศราวุธ วงษา',
        reportedUserName: 'ร้านตัวอย่าง (ไม่ระบุตัวตน)',
        reason: 'สินค้าไม่ตรงปก / สภาพเสียหายหนัก',
        details:
            'ผู้ขายแจ้งว่าสภาพ 90% แต่สินค้าจริงจอแตกใช้งานไม่ได้ ขอระงับการปล่อยเงิน Escrow และขอคืนเงินครับ',
        amount: 850.0,
        status: ReportStatus.pending,
      ),
      ReportModel(
        id: 'REP-002',
        reporterId: 'user_10',
        reporterName: 'กนกวรรณ รุ่งโรจน์',
        reportedUserName: 'user_fake_00',
        reason: 'พฤติกรรมน่าสงสัย / หลอกให้โอนนอกระบบ Escrow',
        details:
            'ผู้ขายทักแชทมาขอให้โอนเงินนอกช่องทางที่ตกลงกัน โปรดตรวจสอบข้อมูลก่อนทำรายการ',
        status: ReportStatus.investigating,
      ),
    ];

    // Seed Notifications (FR-10)
    notifications = [
      {
        'title': 'ระบบพักเงิน Escrow คุ้มครองแล้ว',
        'body':
            'ยอดเงิน 180.00 บาท ของคำสั่งซื้อ ORD-2026-0901 ถูกพักไว้อย่างปลอดภัย ผู้ขายจะได้รับเงินเมื่อคุณกดยืนยันรับสินค้า',
        'time': '12 นาทีที่แล้ว',
        'type': 'escrow',
        'read': false,
      },
      {
        'title': 'มีข้อความใหม่จาก พีรภัทร ชาญวิทย์',
        'body': 'ยังอยู่ครับ สะดวกนัดรับที่จุดสาธารณะในเขตเมืองช่วงเย็นไหมครับ',
        'time': '1 ชั่วโมงที่แล้ว',
        'type': 'chat',
        'read': true,
      },
      {
        'title': 'ประกาศจาก $appName',
        'body':
            'ยินดีต้อนรับสู่ตลาดซื้อขาย แลกเปลี่ยน และแบ่งปันสิ่งของในชุมชน',
        'time': '1 วันที่แล้ว',
        'type': 'system',
        'read': true,
      },
    ];
  }

  // Actions
  bool isPhoneRegistered(String phone) =>
      _credentialsByPhone.containsKey(phone);

  bool loginWithPhoneAndPassword(String phone, String password) {
    final credential = _credentialsByPhone[phone];
    if (credential == null || credential.password != password) return false;

    final userIndex = users.indexWhere((user) => user.id == credential.userId);
    if (userIndex == -1) {
      throw StateError(
        'Mock credential references a missing user: ${credential.userId}',
      );
    }

    currentUser = users[userIndex];
    notifyListeners();
    return true;
  }

  bool registerPhoneAccount({
    required String name,
    required String phone,
    required String password,
  }) {
    if (_credentialsByPhone.containsKey(phone)) return false;

    final user = UserModel(
      id: 'user_${DateTime.now().microsecondsSinceEpoch}',
      name: name.trim(),
      phone: phone,
      phoneVerified: true,
      role: UserRole.member,
    );
    users.add(user);
    _credentialsByPhone[phone] = _MockCredential(
      userId: user.id,
      password: password,
    );
    currentUser = user;
    notifyListeners();
    return true;
  }

  void updateCurrentUserArea({
    required double latitude,
    required double longitude,
    required String label,
  }) {
    currentUser = currentUser.copyWith(
      homeLat: latitude,
      homeLng: longitude,
      homeLabel: label,
    );
    final userIndex = users.indexWhere((user) => user.id == currentUser.id);
    if (userIndex != -1) users[userIndex] = currentUser;
    notifyListeners();
  }

  void loginAsGuest() {
    currentUser = UserModel(
      id: 'guest_01',
      name: 'ผู้เยี่ยมชม',
      role: UserRole.guest,
      rating: 0,
      reviewCount: 0,
      successfulDeals: 0,
    );
    notifyListeners();
  }

  void addProduct(ProductModel product) {
    products.insert(0, product);
    notifyListeners();
  }

  void updateProductStatus(String id, ListingStatus newStatus) {
    final index = products.indexWhere((p) => p.id == id);
    if (index != -1) {
      products[index] = products[index].copyWith(status: newStatus);
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  void addToCart(ProductModel product) {
    if (!cartItems.any((item) => item.id == product.id)) {
      cartItems.add(product);
      notifyListeners();
    }
  }

  void removeFromCart(String productId) {
    cartItems.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clearCart() {
    cartItems.clear();
    notifyListeners();
  }

  // Create Order (UC-02)
  OrderModel createOrder({
    required ProductModel product,
    required String pickupPoint,
    required String scheduledTime,
    required String paymentMethod,
    String note = '',
  }) {
    final newOrder = OrderModel(
      id: 'ORD-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      productId: product.id,
      productTitle: product.title,
      productPrice: product.price,
      productImageUrl: product.imageUrl,
      buyerId: currentUser.id,
      buyerName: currentUser.name,
      sellerId: product.sellerId,
      sellerName: product.sellerName,
      pickupPoint: pickupPoint,
      scheduledTime: scheduledTime,
      paymentMethod: paymentMethod,
      status: OrderStatus.escrowHolding,
      note: note,
    );

    orders.insert(0, newOrder);
    // Add notification
    notifications.insert(0, {
      'title': 'คำสั่งซื้อใหม่เข้าระบบ Escrow แล้ว',
      'body':
          'คำสั่งซื้อ ${newOrder.id} ได้รับการคุ้มครองด้วยระบบพักเงินแล้ว นัดรับได้ที่ $pickupPoint',
      'time': 'เมื่อสักครู่',
      'type': 'escrow',
      'read': false,
    });

    notifyListeners();
    return newOrder;
  }

  // Escrow State Progression (UC-02)
  void setOrderPickupScheduled(String orderId) {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      orders[index] = orders[index].copyWith(
        status: OrderStatus.pickupScheduled,
      );
      notifyListeners();
    }
  }

  void confirmBuyerReceived(String orderId) {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      // Transition from buyerConfirmed to completed
      orders[index] = orders[index].copyWith(status: OrderStatus.completed);
      notifications.insert(0, {
        'title': 'ปล่อยเงิน Escrow สำเร็จ!',
        'body':
            'คุณได้กดยืนยันรับสินค้าสำหรับคำสั่งซื้อ $orderId เรียบร้อยแล้ว ระบบได้โอนเงินให้ผู้ขายแล้ว',
        'time': 'เมื่อสักครู่',
        'type': 'escrow',
        'read': false,
      });
      notifyListeners();
    }
  }

  void disputeOrder(String orderId, String reason, String details) {
    final index = orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final order = orders[index];
      orders[index] = order.copyWith(status: OrderStatus.disputed);

      // Create a report for admin
      reports.insert(
        0,
        ReportModel(
          id: 'DISP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
          orderId: orderId,
          reporterId: currentUser.id,
          reporterName: currentUser.name,
          reportedUserName: order.sellerName,
          reason: reason,
          details: details,
          amount: order.productPrice,
          status: ReportStatus.pending,
        ),
      );

      notifications.insert(0, {
        'title': 'เปิดข้อพิพาทและระงับการจ่ายเงิน Escrow',
        'body': 'คำสั่งซื้อ $orderId มีรายงานปัญหา ทีมดูแลกำลังตรวจสอบ',
        'time': 'เมื่อสักครู่',
        'type': 'warning',
        'read': false,
      });

      notifyListeners();
    }
  }

  void submitReport({
    required String reportedUser,
    required String reason,
    required String details,
  }) {
    reports.insert(
      0,
      ReportModel(
        id: 'REP-${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}',
        reporterId: currentUser.id,
        reporterName: currentUser.name,
        reportedUserName: reportedUser,
        reason: reason,
        details: details,
        status: ReportStatus.pending,
      ),
    );
    notifyListeners();
  }

  // Admin Resolution (FR-11)
  void resolveDispute(String reportId, ReportStatus resolution) {
    final repIndex = reports.indexWhere((r) => r.id == reportId);
    if (repIndex != -1) {
      final report = reports[repIndex];
      reports[repIndex] = report.copyWith(status: resolution);

      // If associated with an order
      if (report.orderId.isNotEmpty) {
        final ordIndex = orders.indexWhere((o) => o.id == report.orderId);
        if (ordIndex != -1) {
          if (resolution == ReportStatus.refunded) {
            // Refund buyer
            orders[ordIndex] = orders[ordIndex].copyWith(
              status: OrderStatus.completed,
              note: 'คืนเงินให้ผู้ซื้อเรียบร้อยตามคำตัดสินข้อพิพาท',
            );
          } else if (resolution == ReportStatus.released) {
            // Release to seller
            orders[ordIndex] = orders[ordIndex].copyWith(
              status: OrderStatus.completed,
              note: 'ปล่อยเงินให้ผู้ขายเรียบร้อยตามคำตัดสินข้อพิพาท',
            );
          }
        }
      }
      notifyListeners();
    }
  }

  // Pickup Points Management (FR-11)
  void addPickupPoint(PickupPointModel point) {
    pickupPoints.add(point);
    notifyListeners();
  }

  void togglePickupPointActive(String id) {
    final index = pickupPoints.indexWhere((p) => p.id == id);
    if (index != -1) {
      pickupPoints[index] = pickupPoints[index].copyWith(
        isActive: !pickupPoints[index].isActive,
      );
      notifyListeners();
    }
  }

  void deletePickupPoint(String id) {
    pickupPoints.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  // Chat message sending (FR-03)
  void sendChatMessage(String conversationId, String text) {
    final index = conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conv = conversations[index];
      final newMsg = ChatMessage(
        id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        senderId: currentUser.id,
        text: text,
        timestamp: DateTime.now(),
        isMe: true,
      );
      final updatedMessages = List<ChatMessage>.from(conv.messages)
        ..add(newMsg);
      conversations[index] = conv.copyWith(
        messages: updatedMessages,
        lastMessage: text,
        lastMessageTime: DateTime.now(),
      );
      notifyListeners();
    }
  }
}
