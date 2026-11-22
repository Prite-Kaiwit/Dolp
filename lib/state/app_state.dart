import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'dart:typed_data';
import '../constants/chat_limits.dart';
import '../constants/app_info.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/product_image_data.dart';
import '../models/geo_location.dart';
import '../models/nearby_product.dart';
import '../models/order.dart';
import '../models/review.dart';
import '../models/chat.dart';
import '../models/meetup_agreement.dart';
import '../models/pickup_point.dart';
import '../models/report.dart';
import '../utils/distance.dart';

class ExactProductLocation {
  final String exactAddress;
  final double exactLat;
  final double exactLng;

  const ExactProductLocation({
    required this.exactAddress,
    required this.exactLat,
    required this.exactLng,
  });
}

class _PrivateProductLocation {
  final String address;
  final double exactLat;
  final double exactLng;

  const _PrivateProductLocation({
    required this.address,
    required this.exactLat,
    required this.exactLng,
  });
}

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
  final Map<String, _PrivateProductLocation> _exactLocationsByProductId = {};

  GeoLocation get currentLocation {
    final latitude = currentUser.homeLat;
    final longitude = currentUser.homeLng;
    if (latitude == null || longitude == null) return kDefaultCenter;
    return GeoLocation(latitude, longitude);
  }

  bool get isLocationApproximate =>
      currentUser.homeLat == null || currentUser.homeLng == null;

  // Orders and reviews
  List<OrderModel> orders = [];
  List<ReviewModel> reviews = [];
  final Map<String, ListingStatus> _reservedListingPreviousStatus = {};
  int _orderSequence = 0;

  // Chats
  List<ChatConversation> conversations = [];
  List<MeetupAgreement> meetupAgreements = [];
  int _chatSequence = 0;

  // Suggested public meeting points.
  List<SuggestedSpot> pickupPoints = [];

  // Reports (Trust & Safety / Admin)
  List<ReportModel> reports = [];

  // Notifications
  List<Map<String, dynamic>> notifications = [];

  void _initMockData() {
    _exactLocationsByProductId.clear();
    _reservedListingPreviousStatus.clear();
    meetupAgreements.clear();
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
        id: 'user_03',
        name: 'ณัฐชา เกียรติสกุล',
        phoneVerified: true,
        homeLabel: 'อำเภอเมืองจันทบุรี',
        rating: 5.0,
        reviewCount: 18,
      ),
      UserModel(
        id: 'user_04',
        name: 'ธนกฤต มั่นคง',
        phoneVerified: true,
        homeLabel: 'อำเภอเมืองจันทบุรี',
        rating: 4.8,
        reviewCount: 29,
      ),
      UserModel(
        id: 'user_05',
        name: 'อภิสิทธิ์ วงศ์วิไล',
        phoneVerified: true,
        homeLabel: 'อำเภอเมืองจันทบุรี',
        rating: 4.7,
        reviewCount: 15,
      ),
      UserModel(
        id: 'user_06',
        name: 'มนัสวี โสภณ',
        phoneVerified: true,
        homeLabel: 'อำเภอเมืองจันทบุรี',
        rating: 4.9,
        reviewCount: 22,
      ),
      UserModel(
        id: 'user_07',
        name: 'วรภัทร ชาญยุทธ',
        phoneVerified: true,
        homeLabel: 'อำเภอท่าใหม่',
        rating: 4.8,
        reviewCount: 11,
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
      SuggestedSpot(
        id: 'p1',
        name: 'ห้างในย่านเมืองจันทบุรี',
        description: 'พื้นที่สาธารณะสำหรับตกลงนัดรับในย่านเมือง',
        location: GeoLocation(12.6112, 102.1031),
        type: SuggestedSpotType.mall,
        openHours: '07:30 - 20:00 น.',
      ),
      SuggestedSpot(
        id: 'p2',
        name: 'ร้านสะดวกซื้อในย่านท่าใหม่',
        description: 'พื้นที่สาธารณะสำหรับตกลงนัดรับในย่านท่าใหม่',
        location: GeoLocation(12.6230, 101.9990),
        type: SuggestedSpotType.convenienceStore,
        openHours: '08:00 - 21:00 น.',
      ),
      SuggestedSpot(
        id: 'p3',
        name: 'ปั๊มน้ำมันในย่านขลุง',
        description: 'พื้นที่สาธารณะสำหรับตกลงนัดรับในย่านขลุง',
        location: GeoLocation(12.4600, 102.2200),
        type: SuggestedSpotType.gasStation,
        openHours: '08:30 - 18:30 น.',
      ),
      SuggestedSpot(
        id: 'p4',
        name: 'ลานสาธารณะในย่านแหลมสิงห์',
        description: 'พื้นที่สาธารณะสำหรับตกลงนัดรับในย่านแหลมสิงห์',
        location: GeoLocation(12.4810, 102.0720),
        type: SuggestedSpotType.other,
        openHours: '08:00 - 22:00 น.',
      ),
      SuggestedSpot(
        id: 'p5',
        name: 'ห้างในย่านนายายอาม',
        description: 'พื้นที่สาธารณะสำหรับตกลงนัดรับในย่านนายายอาม',
        location: GeoLocation(12.7800, 101.8300),
        type: SuggestedSpotType.mall,
        openHours: '06:00 - 22:00 น.',
      ),
    ];

    products = [
      _seedProduct(
        id: 'prod_1',
        title: 'หนังสือ Calculus 1 ฉบับสรุปสอบ',
        description:
            'มีไฮไลท์จุดสำคัญและข้อสอบเก่าย้อนหลัง 5 ปี พร้อมเฉลยละเอียด สภาพ 95% ไม่มีรอยฉีกขาด',
        price: 180.0,
        type: ListingType.sell,
        category: 'หนังสือ',
        condition: 'สภาพดีมาก (95%)',
        imageUrl:
            'https://images.unsplash.com/photo-1544716278-ca5e3f4abd8c?w=500',
        sellerId: 'user_02',
        sellerName: 'พีรภัทร ชาญวิทย์',
        sellerAreaLabel: 'อำเภอเมืองจันทบุรี',
        locationLabel: 'อำเภอเมืองจันทบุรี',
        exactLocation: _offsetFrom(kDefaultCenter, 0.3, 0),
        pickupType: PickupType.suggestedSpot,
        sellerRating: 4.9,
        sellerReviewCount: 42,
        viewCount: 128,
        favoriteCount: 14,
      ),
      _seedProduct(
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
        imageUrl:
            'https://images.unsplash.com/photo-1587145820266-a5951ee6f620?w=500',
        sellerId: 'user_03',
        sellerName: 'ณัฐชา เกียรติสกุล',
        sellerAreaLabel: 'อำเภอเมืองจันทบุรี',
        locationLabel: 'อำเภอเมืองจันทบุรี',
        exactLocation: _offsetFrom(kDefaultCenter, 1.2, 90),
        pickupType: PickupType.agreedSpot,
        sellerRating: 5.0,
        sellerReviewCount: 18,
        viewCount: 94,
        favoriteCount: 19,
      ),
      _seedProduct(
        id: 'prod_3',
        title: 'เสื้อคลุมสีขาว ไซส์ M (ส่งต่อฟรี)',
        description:
            'ไม่ได้ใช้งานแล้ว สภาพยังดีมาก ซักรีดสะอาด ส่งต่อให้ผู้ที่ต้องการโดยไม่มีค่าใช้จ่าย',
        price: 0.0,
        type: ListingType.donate,
        category: 'เสื้อผ้า & เครื่องแต่งกาย',
        condition: 'สภาพดีมาก (95%)',
        imageUrl:
            'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=500',
        sellerId: 'user_04',
        sellerName: 'ธนกฤต มั่นคง',
        sellerAreaLabel: 'อำเภอเมืองจันทบุรี',
        locationLabel: 'อำเภอเมืองจันทบุรี',
        exactLocation: _offsetFrom(kDefaultCenter, 2.4, 180),
        pickupType: PickupType.discussInChat,
        sellerRating: 4.8,
        sellerReviewCount: 29,
        viewCount: 210,
        favoriteCount: 35,
      ),
      _seedProduct(
        id: 'prod_4',
        title: 'โต๊ะญี่ปุ่นพับได้ ไม้แท้ สำหรับบ้าน',
        description:
            'ขนาด 60x40 ซม. ขาพับเก็บได้ แข็งแรงทนทาน น้ำหนักเบา ขนย้ายง่าย',
        price: 150.0,
        type: ListingType.sell,
        category: 'ของใช้ในบ้าน & เฟอร์นิเจอร์',
        condition: 'สภาพดี (85%)',
        imageUrl:
            'https://images.unsplash.com/photo-1538688525198-9b88f6f53126?w=500',
        sellerId: 'user_05',
        sellerName: 'อภิสิทธิ์ วงศ์วิไล',
        sellerAreaLabel: 'อำเภอเมืองจันทบุรี',
        locationLabel: 'อำเภอเมืองจันทบุรี',
        exactLocation: _offsetFrom(kDefaultCenter, 3.8, 270),
        pickupType: PickupType.sellerHome,
        sellerRating: 4.7,
        sellerReviewCount: 15,
        viewCount: 88,
        favoriteCount: 8,
      ),
      _seedProduct(
        id: 'prod_5',
        title: 'iPad Sleeve ซองหนังใส่แท็บเล็ต 11 นิ้ว มีช่องใส่ปากกา',
        description:
            'วัสดุหนัง PU กันกระแทกได้ดี ด้านในบุกำมะหยี่นุ่ม ไม่ทำให้เครื่องเป็นรอย สีเขียวพาสเทล',
        price: 120.0,
        type: ListingType.sell,
        category: 'ไอที & อิเล็กทรอนิกส์',
        condition: 'ใหม่เอี่ยม (100%)',
        imageUrl:
            'https://images.unsplash.com/photo-1544816155-12df9643f363?w=500',
        sellerId: 'user_06',
        sellerName: 'มนัสวี โสภณ',
        sellerAreaLabel: 'อำเภอเมืองจันทบุรี',
        locationLabel: 'อำเภอเมืองจันทบุรี',
        exactLocation: _offsetFrom(kDefaultCenter, 7.4, 45),
        pickupType: PickupType.suggestedSpot,
        sellerRating: 4.9,
        sellerReviewCount: 22,
        viewCount: 145,
        favoriteCount: 27,
      ),
      _seedProduct(
        id: 'prod_6',
        title: 'ไม้แบดมินตัน Yonex Nanoray + ซองสะพาย',
        description:
            'เอ็นขึ้น 24 ปอนด์ พร้อมกริปใหม่ อยากแลกเปลี่ยนกับไม้เทเบิลเทนนิส หรือลูกบาสเกตบอล',
        price: 450.0,
        tradeFor: 'ไม้ปิงปอง Butterfly หรือ ลูกบาส Molten เบอร์ 7',
        type: ListingType.trade,
        category: 'ของสะสม & กีฬา',
        condition: 'สภาพดี (85%)',
        imageUrl:
            'https://images.unsplash.com/photo-1626224583764-f87db24ac4ea?w=500',
        sellerId: 'user_07',
        sellerName: 'วรภัทร ชาญยุทธ',
        sellerAreaLabel: 'อำเภอท่าใหม่',
        locationLabel: 'อำเภอท่าใหม่',
        exactLocation: _offsetFrom(GeoLocation(12.6230, 101.9990), 0.2, 100),
        pickupType: PickupType.discussInChat,
        sellerRating: 4.8,
        sellerReviewCount: 11,
        viewCount: 65,
        favoriteCount: 5,
      ),
      _seedProduct(
        id: 'prod_7',
        title: 'โคมไฟตั้งโต๊ะปรับระดับได้',
        description: 'โคมไฟ LED ใช้งานปกติ ปรับความสว่างได้ 3 ระดับ',
        price: 250,
        type: ListingType.sell,
        category: 'ของใช้ในบ้าน & เฟอร์นิเจอร์',
        condition: 'สภาพดีมาก',
        imageUrl:
            'https://images.unsplash.com/photo-1507473885765-e6ed057f782c?w=500',
        sellerId: 'user_03',
        sellerName: 'ณัฐชา เกียรติสกุล',
        sellerAreaLabel: 'อำเภอท่าใหม่',
        locationLabel: 'อำเภอท่าใหม่',
        exactLocation: _offsetFrom(GeoLocation(12.6230, 101.9990), 0.4, 95),
        pickupType: PickupType.sellerHome,
      ),
      _seedProduct(
        id: 'prod_8',
        title: 'กระเป๋าผ้าแคนวาส',
        description: 'กระเป๋าผ้าแข็งแรง สภาพดี มีช่องด้านใน',
        price: 0,
        type: ListingType.donate,
        category: 'เสื้อผ้า & เครื่องแต่งกาย',
        condition: 'สภาพดี',
        imageUrl:
            'https://images.unsplash.com/photo-1548036328-c9fa89d128fa?w=500',
        sellerId: 'user_04',
        sellerName: 'ธนกฤต มั่นคง',
        sellerAreaLabel: 'อำเภอท่าใหม่',
        locationLabel: 'อำเภอท่าใหม่',
        exactLocation: _offsetFrom(GeoLocation(12.6230, 101.9990), 0.6, 90),
        pickupType: PickupType.agreedSpot,
      ),
      _seedProduct(
        id: 'prod_9',
        title: 'พัดลมตั้งโต๊ะ USB',
        description: 'พัดลมขนาดเล็ก เสียงเบา ใช้ได้ทั้ง USB และแบตเตอรี่',
        price: 190,
        type: ListingType.sell,
        category: 'ไอที & อิเล็กทรอนิกส์',
        condition: 'สภาพดี',
        imageUrl:
            'https://images.unsplash.com/photo-1581276879432-15e50529f34b?w=500',
        sellerId: 'user_05',
        sellerName: 'อภิสิทธิ์ วงศ์วิไล',
        sellerAreaLabel: 'อำเภอท่าใหม่',
        locationLabel: 'อำเภอท่าใหม่',
        exactLocation: _offsetFrom(GeoLocation(12.6230, 101.9990), 0.9, 110),
        pickupType: PickupType.suggestedSpot,
      ),
      _seedProduct(
        id: 'prod_10',
        title: 'หนังสือทำอาหารไทย',
        description: 'รวมเมนูอาหารไทยพร้อมภาพประกอบ สภาพดี',
        price: 120,
        type: ListingType.sell,
        category: 'หนังสือ',
        condition: 'สภาพดี',
        imageUrl:
            'https://images.unsplash.com/photo-1544947950-fa07a98d237f?w=500',
        sellerId: 'user_06',
        sellerName: 'มนัสวี โสภณ',
        sellerAreaLabel: 'อำเภอท่าใหม่',
        locationLabel: 'อำเภอท่าใหม่',
        exactLocation: _offsetFrom(GeoLocation(12.6230, 101.9990), 1.2, 80),
        pickupType: PickupType.discussInChat,
      ),
      _seedProduct(
        id: 'prod_11',
        title: 'ลูกฟุตบอลฝึกซ้อม',
        description: 'ลูกฟุตบอลขนาดมาตรฐาน ใช้ซ้อมทั่วไป',
        price: 320,
        type: ListingType.sell,
        category: 'ของสะสม & กีฬา',
        condition: 'สภาพดี',
        imageUrl:
            'https://images.unsplash.com/photo-1579952363873-27f3bade9f55?w=500',
        sellerId: 'user_07',
        sellerName: 'วรภัทร ชาญยุทธ',
        sellerAreaLabel: 'อำเภอแหลมสิงห์',
        locationLabel: 'อำเภอแหลมสิงห์',
        exactLocation: _offsetFrom(GeoLocation(12.4810, 102.0720), 0.2, 340),
        pickupType: PickupType.suggestedSpot,
      ),
      _seedProduct(
        id: 'prod_12',
        title: 'ชุดแก้วน้ำเซรามิก',
        description: 'แก้วเซรามิก 2 ใบ ไม่มีรอยบิ่น',
        price: 0,
        type: ListingType.donate,
        category: 'ของใช้ในบ้าน & เฟอร์นิเจอร์',
        condition: 'สภาพดีมาก',
        imageUrl:
            'https://images.unsplash.com/photo-1514228742587-6b1558fcca3d?w=500',
        sellerId: 'user_02',
        sellerName: 'พีรภัทร ชาญวิทย์',
        sellerAreaLabel: 'อำเภอแหลมสิงห์',
        locationLabel: 'อำเภอแหลมสิงห์',
        exactLocation: _offsetFrom(GeoLocation(12.4810, 102.0720), 0.4, 350),
        pickupType: PickupType.agreedSpot,
      ),
      _seedProduct(
        id: 'prod_13',
        title: 'หูฟังมีสาย',
        description: 'หูฟังพร้อมไมโครโฟน ใช้งานได้ปกติ',
        price: 150,
        type: ListingType.sell,
        category: 'ไอที & อิเล็กทรอนิกส์',
        condition: 'สภาพดี',
        imageUrl:
            'https://images.unsplash.com/photo-1505740420928-5e560c06d30e?w=500',
        sellerId: 'user_03',
        sellerName: 'ณัฐชา เกียรติสกุล',
        sellerAreaLabel: 'อำเภอแหลมสิงห์',
        locationLabel: 'อำเภอแหลมสิงห์',
        exactLocation: _offsetFrom(GeoLocation(12.4810, 102.0720), 0.6, 0),
        pickupType: PickupType.discussInChat,
      ),
      _seedProduct(
        id: 'prod_14',
        title: 'เสื้อแจ็กเก็ตมือสอง',
        description: 'เสื้อแจ็กเก็ตสีพื้น ซิปใช้งานได้ทุกส่วน',
        price: 280,
        type: ListingType.sell,
        category: 'เสื้อผ้า & เครื่องแต่งกาย',
        condition: 'สภาพดี',
        imageUrl:
            'https://images.unsplash.com/photo-1551028719-00167b16eac5?w=500',
        sellerId: 'user_04',
        sellerName: 'ธนกฤต มั่นคง',
        sellerAreaLabel: 'อำเภอแหลมสิงห์',
        locationLabel: 'อำเภอแหลมสิงห์',
        exactLocation: _offsetFrom(GeoLocation(12.4810, 102.0720), 0.8, 10),
        pickupType: PickupType.sellerHome,
      ),
      _seedProduct(
        id: 'prod_15',
        title: 'หนังสือนิยายอ่านเพลิน',
        description: 'นิยายอ่านจบแล้ว สภาพดี ส่งต่อให้อ่านฟรี',
        price: 0,
        type: ListingType.donate,
        category: 'หนังสือ',
        condition: 'สภาพดี',
        imageUrl:
            'https://images.unsplash.com/photo-1512820790803-83ca734da794?w=500',
        sellerId: 'user_05',
        sellerName: 'อภิสิทธิ์ วงศ์วิไล',
        sellerAreaLabel: 'อำเภอแหลมสิงห์',
        locationLabel: 'อำเภอแหลมสิงห์',
        exactLocation: _offsetFrom(GeoLocation(12.4810, 102.0720), 1, 330),
        pickupType: PickupType.suggestedSpot,
      ),
    ];

    reviews = _buildSeedReviews();
    _recalculateRatings();

    // Sample orders cover each lifecycle state and both participant roles.
    orders = [
      _seedOrder(
        id: 'ORD-2026-0901',
        productId: 'prod_1',
        buyerId: 'user_01',
        sellerId: 'user_02',
        status: OrderStatus.pending,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        agreedPlaceLabel: 'ห้างในย่านเมืองจันทบุรี',
        agreedTime: DateTime.now().add(const Duration(days: 1)),
      ),
      _seedOrder(
        id: 'ORD-2026-0814',
        productId: 'prod_5',
        buyerId: 'user_01',
        sellerId: 'user_06',
        status: OrderStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 10)),
        completedAt: DateTime.now().subtract(const Duration(days: 9)),
      ),
      _seedOrder(
        id: 'ORD-2026-0808',
        productId: 'prod_2',
        buyerId: 'user_01',
        sellerId: 'user_03',
        status: OrderStatus.cancelled,
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        cancelledBy: 'user_01',
        cancelReason: 'เปลี่ยนใจ',
        cancelledAt: DateTime.now().subtract(const Duration(days: 13)),
      ),
      _seedOrder(
        id: 'ORD-2026-0801',
        productId: 'prod_14',
        buyerId: 'user_02',
        sellerId: 'user_04',
        status: OrderStatus.disputed,
        createdAt: DateTime.now().subtract(const Duration(days: 18)),
        previousStatus: OrderStatus.pending,
      ),
    ];
    _setSeedListingStatus('prod_1', ListingStatus.reserved);
    _setSeedListingStatus('prod_14', ListingStatus.reserved);
    _setSeedListingStatus('prod_5', ListingStatus.sold);

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
        buyerId: 'user_01',
        sellerId: 'user_02',
        lastMessage: 'ตกลงครับ เจอกันที่จุดสาธารณะในเขตเมืองนะครับ',
        lastMessageTime: DateTime.now().subtract(const Duration(minutes: 12)),
        unreadCount: 1,
        unreadByUser: const {'user_01': 1, 'user_02': 0},
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
            text: 'ตกลงครับ เจอกันที่จุดสาธารณะในเขตเมืองนะครับ',
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
        buyerId: 'user_01',
        sellerId: 'user_03',
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
        orderId: 'ORD-2026-0801',
        reporterId: 'user_09',
        reporterName: 'ศราวุธ วงษา',
        reportedUserName: 'ร้านตัวอย่าง (ไม่ระบุตัวตน)',
        reason: 'สินค้าไม่ตรงปก / สภาพเสียหายหนัก',
        details:
            'ผู้ขายแจ้งว่าสภาพดี แต่สินค้าจริงจอแตกและใช้งานไม่ได้ โปรดช่วยตรวจสอบข้อมูลการนัดรับ',
        status: ReportStatus.pending,
      ),
      ReportModel(
        id: 'REP-002',
        reporterId: 'user_10',
        reporterName: 'กนกวรรณ รุ่งโรจน์',
        reportedUserName: 'user_fake_00',
        reason: 'พฤติกรรมน่าสงสัย / ชักชวนให้โอนก่อนรับสินค้า',
        details:
            'ผู้ขายทักแชทมาขอให้โอนเงินนอกช่องทางที่ตกลงกัน โปรดตรวจสอบข้อมูลก่อนทำรายการ',
        status: ReportStatus.investigating,
      ),
    ];

    // Seed Notifications (FR-10)
    notifications = [
      {
        'title': 'มีคำสั่งซื้อใหม่',
        'body': 'คำสั่งซื้อ ORD-2026-0901 รอนัดรับและชำระเงินหน้างาน',
        'time': '12 นาทีที่แล้ว',
        'type': 'order',
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

  List<ReviewModel> _buildSeedReviews() {
    final seeded = <ReviewModel>[];
    for (final user in users) {
      if (user.reviewCount == 0) continue;
      final fiveStarCount = ((user.rating - 4) * user.reviewCount)
          .round()
          .clamp(0, user.reviewCount);
      for (var index = 0; index < user.reviewCount; index++) {
        seeded.add(
          ReviewModel(
            id: 'seed_review_${user.id}_$index',
            orderId: 'seed_order_${user.id}_$index',
            reviewerId: 'seed_reviewer_${user.id}_$index',
            revieweeId: user.id,
            rating: index < fiveStarCount ? 5 : 4,
            tags: const ['รีวิวตัวอย่าง'],
            comment: 'ตัวอย่างรีวิวจากผู้ใช้ในชุมชน',
            createdAt: DateTime.now().subtract(Duration(days: index + 1)),
          ),
        );
      }
    }
    return seeded;
  }

  void _recalculateRatings() {
    users = users.map((user) {
      final userReviews = reviews
          .where((review) => review.revieweeId == user.id)
          .toList();
      if (userReviews.isEmpty) {
        return user.copyWith(rating: 0, reviewCount: 0);
      }
      final average =
          userReviews.fold<int>(0, (total, review) => total + review.rating) /
          userReviews.length;
      return user.copyWith(
        rating: average,
        reviewCount: userReviews.length,
      );
    }).toList();

    products = products.map((product) {
      final seller = users.where((user) => user.id == product.sellerId).firstOrNull;
      if (seller == null) return product;
      return product.copyWith(
        sellerRating: seller.rating,
        sellerReviewCount: seller.reviewCount,
      );
    }).toList();
    currentUser = users.where((user) => user.id == currentUser.id).firstOrNull ??
        currentUser;
  }

  OrderModel _seedOrder({
    required String id,
    required String productId,
    required String buyerId,
    required String sellerId,
    required OrderStatus status,
    required DateTime createdAt,
    String? agreedPlaceLabel,
    DateTime? agreedTime,
    DateTime? completedAt,
    String? cancelledBy,
    String? cancelReason,
    DateTime? cancelledAt,
    OrderStatus? previousStatus,
  }) {
    final product = products.firstWhere((item) => item.id == productId);
    final events = <OrderEvent>[
      OrderEvent(at: createdAt, actorId: buyerId, status: OrderStatus.pending),
    ];
    if (status != OrderStatus.pending) {
      events.add(
        OrderEvent(
          at: completedAt ?? cancelledAt ?? createdAt.add(const Duration(hours: 1)),
          actorId: cancelledBy ?? buyerId,
          status: status,
        ),
      );
    }
    return OrderModel(
      id: id,
      buyerId: buyerId,
      sellerId: sellerId,
      items: [
        OrderItemSnapshot(
          productId: product.id,
          title: product.title,
          price: product.price,
          coverImage: product.coverImage,
          listingType: product.type,
        ),
      ],
      totalPrice: product.price,
      paymentMethod: PaymentMethod.cashOnHandover,
      pickupType: product.pickupType,
      agreedPlaceLabel: agreedPlaceLabel,
      agreedTime: agreedTime,
      createdAt: createdAt,
      status: status,
      completedAt: completedAt,
      cancelledBy: cancelledBy,
      cancelReason: cancelReason,
      cancelledAt: cancelledAt,
      previousStatus: previousStatus,
      events: events,
    );
  }

  void _setSeedListingStatus(String productId, ListingStatus status) {
    final index = products.indexWhere((product) => product.id == productId);
    if (index != -1) products[index] = products[index].copyWith(status: status);
  }

  ProductModel _seedProduct({
    required String id,
    required String title,
    required String description,
    required double price,
    required ListingType type,
    required String category,
    required String condition,
    required String imageUrl,
    required String sellerId,
    required String sellerName,
    required String sellerAreaLabel,
    required String locationLabel,
    required GeoLocation exactLocation,
    required PickupType pickupType,
    String tradeFor = '',
    double sellerRating = 4.8,
    int sellerReviewCount = 12,
    int viewCount = 45,
    int favoriteCount = 6,
  }) {
    final product = ProductModel(
      id: id,
      title: title,
      description: description,
      price: price,
      tradeFor: tradeFor,
      type: type,
      category: category,
      condition: condition,
      publicLocation: obfuscate(exactLocation, id),
      locationLabel: locationLabel,
      pickupType: pickupType,
      imageUrl: imageUrl,
      sellerId: sellerId,
      sellerName: sellerName,
      sellerAreaLabel: sellerAreaLabel,
      sellerRating: sellerRating,
      sellerReviewCount: sellerReviewCount,
      viewCount: viewCount,
      favoriteCount: favoriteCount,
    );
    _exactLocationsByProductId[id] = _PrivateProductLocation(
      address: 'ที่อยู่ตัวอย่าง $locationLabel',
      exactLat: exactLocation.lat,
      exactLng: exactLocation.lng,
    );
    return product;
  }

  GeoLocation _offsetFrom(
    GeoLocation origin,
    double distanceKm,
    double bearingDegrees,
  ) {
    const earthRadiusKm = 6371.0;
    final angularDistance = distanceKm / earthRadiusKm;
    final bearing = bearingDegrees * math.pi / 180;
    final latitude = origin.lat * math.pi / 180;
    final longitude = origin.lng * math.pi / 180;
    final targetLatitude = math.asin(
      math.sin(latitude) * math.cos(angularDistance) +
          math.cos(latitude) * math.sin(angularDistance) * math.cos(bearing),
    );
    final targetLongitude =
        longitude +
        math.atan2(
          math.sin(bearing) * math.sin(angularDistance) * math.cos(latitude),
          math.cos(angularDistance) -
              math.sin(latitude) * math.sin(targetLatitude),
        );
    final normalizedLongitude =
        (targetLongitude + 3 * math.pi) % (2 * math.pi) - math.pi;
    return GeoLocation(
      targetLatitude * 180 / math.pi,
      normalizedLongitude * 180 / math.pi,
    );
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

  List<NearbyProduct> productsNearby({
    double radiusKm = kDefaultRadiusKm,
    String? category,
    ListingType? type,
    num? minPrice,
    num? maxPrice,
    String? query,
    SortBy sortBy = SortBy.nearest,
  }) {
    if (!radiusKm.isFinite || radiusKm < 0) {
      throw ArgumentError.value(
        radiusKm,
        'radiusKm',
        'Must be a finite non-negative value.',
      );
    }

    final normalizedCategory = category?.trim();
    final normalizedQuery = query?.trim().toLowerCase();
    final blockedUserIds = _blockedUserIdsFor(currentUser.id);
    final nearby = <NearbyProduct>[];
    for (final product in products) {
      if (product.status != ListingStatus.active ||
          product.sellerId == currentUser.id ||
          blockedUserIds.contains(product.sellerId)) {
        continue;
      }
      if (normalizedCategory != null &&
          normalizedCategory.isNotEmpty &&
          product.category != normalizedCategory) {
        continue;
      }
      if (type != null && product.type != type) continue;
      if (product.type != ListingType.donate &&
          ((minPrice != null && product.price < minPrice) ||
              (maxPrice != null && product.price > maxPrice))) {
        continue;
      }
      if (normalizedQuery != null &&
          normalizedQuery.isNotEmpty &&
          !product.title.toLowerCase().contains(normalizedQuery) &&
          !product.description.toLowerCase().contains(normalizedQuery) &&
          !product.category.toLowerCase().contains(normalizedQuery) &&
          !product.locationLabel.toLowerCase().contains(normalizedQuery)) {
        continue;
      }

      final distance = distanceKm(currentLocation, product.publicLocation);
      if (distance <= radiusKm) {
        nearby.add(NearbyProduct(product: product, distanceKm: distance));
      }
    }

    switch (sortBy) {
      case SortBy.nearest:
        nearby.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
        break;
      case SortBy.newest:
        nearby.sort(
          (a, b) => b.product.createdAt.compareTo(a.product.createdAt),
        );
        break;
      case SortBy.priceAsc:
        nearby.sort((a, b) => a.product.price.compareTo(b.product.price));
        break;
      case SortBy.priceDesc:
        nearby.sort((a, b) => b.product.price.compareTo(a.product.price));
        break;
    }
    return nearby;
  }

  ExactProductLocation? getExactLocationFor(
    String productId,
    String requesterUserId,
  ) {
    if (requesterUserId != currentUser.id) return null;
    final productIndex = products.indexWhere(
      (product) => product.id == productId,
    );
    if (productIndex == -1) return null;

    final product = products[productIndex];
    if (requesterUserId != product.sellerId &&
        !_hasAcceptedMeetup(productId, requesterUserId)) {
      return null;
    }
    final exact = _exactLocationsByProductId[productId];
    if (exact == null) return null;
    return ExactProductLocation(
      exactAddress: exact.address,
      exactLat: exact.exactLat,
      exactLng: exact.exactLng,
    );
  }

  Set<String> _blockedUserIdsFor(String userId) => const {};

  bool _hasAcceptedMeetup(String productId, String requesterUserId) {
    final product = products.where((item) => item.id == productId).firstOrNull;
    if (product == null) return false;
    return meetupAgreements.any((agreement) {
      if (agreement.productId != productId ||
          agreement.status != MeetupStatus.accepted) {
        return false;
      }
      final conversation = conversations
          .where((item) => item.id == agreement.conversationId)
          .firstOrNull;
      return conversation != null &&
          conversation.buyerId == requesterUserId &&
          conversation.sellerId == product.sellerId;
    });
  }

  ProductModel addListing({
    required String title,
    required String description,
    required double price,
    required String tradeFor,
    required ListingType type,
    required String category,
    required String condition,
    required GeoLocation exactLocation,
    required String locationLabel,
    required String exactAddress,
    required PickupType pickupType,
    required String imageUrl,
    required List<ProductImageData> productImages,
  }) {
    if (!isLoggedIn) {
      throw StateError('กรุณาเข้าสู่ระบบก่อนลงประกาศ');
    }

    final id = 'prod_${DateTime.now().microsecondsSinceEpoch}';
    final product = ProductModel(
      id: id,
      title: title.trim(),
      description: description.trim(),
      price: price,
      tradeFor: tradeFor.trim(),
      type: type,
      category: category,
      condition: condition,
      publicLocation: obfuscate(exactLocation, id),
      locationLabel: locationLabel.trim(),
      pickupType: pickupType,
      imageUrl: imageUrl,
      productImages: List.unmodifiable(productImages),
      sellerId: currentUser.id,
      sellerName: currentUser.name,
      sellerAreaLabel: locationLabel.trim().isNotEmpty
          ? locationLabel.trim()
          : currentUser.homeLabel,
      sellerRating: currentUser.rating,
      sellerReviewCount: currentUser.reviewCount,
    );

    products.insert(0, product);
    _exactLocationsByProductId[id] = _PrivateProductLocation(
      address: exactAddress.trim(),
      exactLat: exactLocation.lat,
      exactLng: exactLocation.lng,
    );
    notifyListeners();
    return product;
  }

  ProductModel updateListing({
    required String id,
    required String title,
    required String description,
    required double price,
    required String tradeFor,
    required ListingType type,
    required String category,
    required String condition,
    required GeoLocation exactLocation,
    required String locationLabel,
    required String exactAddress,
    required PickupType pickupType,
    required String imageUrl,
    required List<ProductImageData> productImages,
  }) {
    final index = _ownedListingIndex(id);
    final previous = products[index];
    final updated = previous.copyWith(
      title: title.trim(),
      description: description.trim(),
      price: price,
      tradeFor: tradeFor.trim(),
      type: type,
      category: category,
      condition: condition,
      publicLocation: obfuscate(exactLocation, id),
      locationLabel: locationLabel.trim(),
      pickupType: pickupType,
      imageUrl: imageUrl,
      productImages: List.unmodifiable(productImages),
      sellerAreaLabel: locationLabel.trim().isNotEmpty
          ? locationLabel.trim()
          : currentUser.homeLabel,
    );
    products[index] = updated;
    _exactLocationsByProductId[id] = _PrivateProductLocation(
      address: exactAddress.trim(),
      exactLat: exactLocation.lat,
      exactLng: exactLocation.lng,
    );
    notifyListeners();
    return updated;
  }

  String? setListingStatus(String id, ListingStatus newStatus) {
    final index = _ownedListingIndex(id);
    if (products[index].status == ListingStatus.reserved) {
      if (newStatus == ListingStatus.hidden) {
        _reservedListingPreviousStatus[id] = ListingStatus.hidden;
        notifyListeners();
        return null;
      }
      return 'ประกาศนี้ถูกจองอยู่ จึงเปลี่ยนสถานะไม่ได้';
    }
    products[index] = products[index].copyWith(status: newStatus);
    notifyListeners();
    return null;
  }

  String? deleteListing(String id) {
    final index = _ownedListingIndex(id);
    final hasUnfinishedOrder = orders.any(
      (order) =>
          order.items.any((item) => item.productId == id) &&
          order.status != OrderStatus.completed &&
          order.status != OrderStatus.cancelled,
    );
    if (hasUnfinishedOrder) {
      return 'ลบประกาศไม่ได้ เนื่องจากยังมีออเดอร์ที่ดำเนินการไม่เสร็จ';
    }

    products.removeAt(index);
    _exactLocationsByProductId.remove(id);
    notifyListeners();
    return null;
  }

  int _ownedListingIndex(String id) {
    if (!isLoggedIn) throw StateError('กรุณาเข้าสู่ระบบก่อนจัดการประกาศ');
    final index = products.indexWhere((product) => product.id == id);
    if (index == -1) throw StateError('ไม่พบประกาศนี้');
    if (products[index].sellerId != currentUser.id) {
      throw StateError('ไม่มีสิทธิ์จัดการประกาศนี้');
    }
    return index;
  }

  void addProduct(
    ProductModel product, {
    GeoLocation? exactLocation,
    String exactAddress = '',
  }) {
    products.insert(0, product);
    if (exactLocation != null) {
      _exactLocationsByProductId[product.id] = _PrivateProductLocation(
        address: exactAddress,
        exactLat: exactLocation.lat,
        exactLng: exactLocation.lng,
      );
    }
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
    _exactLocationsByProductId.remove(id);
    notifyListeners();
  }

  String? addToCart(ProductModel product) {
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนเพิ่มสินค้าลงตะกร้า';
    final actual = products.where((item) => item.id == product.id).firstOrNull;
    if (actual == null) return 'ไม่พบสินค้านี้';
    if (actual.sellerId == currentUser.id) {
      return 'เพิ่มประกาศของตัวเองลงตะกร้าไม่ได้';
    }
    if (actual.status != ListingStatus.active) return 'สินค้านี้ไม่พร้อมขาย';
    if (cartItems.any((item) => item.id == actual.id)) return null;
    cartItems.add(actual);
    notifyListeners();
    return null;
  }

  void removeFromCart(String productId) {
    cartItems.removeWhere((item) => item.id == productId);
    notifyListeners();
  }

  void clearCart() {
    cartItems.clear();
    notifyListeners();
  }

  String? cartItemUnavailableReason(ProductModel cartItem) {
    final current = products
        .where((product) => product.id == cartItem.id)
        .firstOrNull;
    if (current == null || current.status != ListingStatus.active) {
      return 'ไม่พร้อมขาย';
    }
    return null;
  }

  OrderCreationResult createOrderForSeller(
    String sellerId, {
    required PaymentMethod paymentMethod,
  }) {
    if (!isLoggedIn) {
      return const OrderCreationResult.failure('เข้าสู่ระบบก่อนสั่งซื้อ');
    }
    final sellerCartItems = cartItems
        .where((item) => item.sellerId == sellerId)
        .toList();
    if (sellerCartItems.isEmpty) {
      return const OrderCreationResult.failure('ไม่มีสินค้าของผู้ขายรายนี้ในตะกร้า');
    }

    final currentProducts = <ProductModel>[];
    for (final item in sellerCartItems) {
      final current = products.where((product) => product.id == item.id).firstOrNull;
      if (current == null ||
          current.sellerId != sellerId ||
          current.status != ListingStatus.active) {
        return OrderCreationResult.failure(
          'สินค้า "${item.title}" ไม่พร้อมขายแล้ว กรุณานำออกจากตะกร้า',
        );
      }
      if (current.sellerId == currentUser.id) {
        return const OrderCreationResult.failure('ซื้อประกาศของตัวเองไม่ได้');
      }
      currentProducts.add(current);
    }

    final itemIds = currentProducts.map((item) => item.id).toSet();
    final meetup = acceptedMeetupForSeller(sellerId, itemIds);
    final now = DateTime.now();
    final order = OrderModel(
      id: 'ORD-${now.microsecondsSinceEpoch}-${_orderSequence++}',
      buyerId: currentUser.id,
      sellerId: sellerId,
      items: currentProducts
          .map(
            (product) => OrderItemSnapshot(
              productId: product.id,
              title: product.title,
              price: product.price,
              coverImage: product.coverImage,
              listingType: product.type,
            ),
          )
          .toList(growable: false),
      totalPrice: currentProducts.fold(0, (total, product) => total + product.price),
      paymentMethod: paymentMethod,
      pickupType: meetup?.pickupType ?? currentProducts.first.pickupType,
      agreedPlaceLabel: meetup?.placeLabel,
      agreedTime: meetup?.scheduledAt,
      meetupId: meetup?.id,
      createdAt: now,
      status: OrderStatus.pending,
      events: [OrderEvent(at: now, actorId: currentUser.id, status: OrderStatus.pending)],
    );

    for (final product in currentProducts) {
      final index = products.indexWhere((item) => item.id == product.id);
      _reservedListingPreviousStatus[product.id] = product.status;
      products[index] = product.copyWith(status: ListingStatus.reserved);
    }
    orders.insert(0, order);
    cartItems.removeWhere((item) => item.sellerId == sellerId);
    notifications.insert(0, {
      'title': 'มีคำสั่งซื้อใหม่',
      'body': '${currentUser.name} ตกลงซื้อสินค้า ${order.items.length} รายการ',
      'time': 'เมื่อสักครู่',
      'type': 'order',
      'read': false,
    });
    notifyListeners();
    return OrderCreationResult.success(order);
  }

  MeetupAgreement? acceptedMeetupForSeller(
    String sellerId,
    Set<String> productIds,
  ) {
    final accepted = meetupAgreements.where((agreement) {
      if (agreement.status != MeetupStatus.accepted ||
          !productIds.contains(agreement.productId)) {
        return false;
      }
      final conversation = conversations
          .where((item) => item.id == agreement.conversationId)
          .firstOrNull;
      return conversation != null &&
          conversation.buyerId == currentUser.id &&
          conversation.sellerId == sellerId;
    }).toList()
      ..sort((a, b) {
        final aAt = a.respondedAt ?? a.createdAt;
        final bAt = b.respondedAt ?? b.createdAt;
        return bAt.compareTo(aAt);
      });
    return accepted.firstOrNull;
  }

  String? markOrderHandedOver(String orderId) {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return 'ไม่พบคำสั่งซื้อนี้';
    final order = orders[index];
    if (!isLoggedIn || currentUser.id != order.sellerId) {
      return 'เฉพาะผู้ขายของคำสั่งซื้อนี้เท่านั้นที่ยืนยันส่งมอบได้';
    }
    if (order.status != OrderStatus.pending) {
      return 'คำสั่งซื้อนี้ไม่ได้อยู่ในสถานะรอนัดรับ';
    }
    orders[index] = order.copyWith(handedOverAt: DateTime.now());
    notifyListeners();
    return null;
  }

  String? completeOrder(String orderId) {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return 'ไม่พบคำสั่งซื้อนี้';
    final order = orders[index];
    if (!isLoggedIn || currentUser.id != order.buyerId) {
      return 'เฉพาะผู้ซื้อของคำสั่งซื้อนี้เท่านั้นที่ยืนยันรับสินค้าได้';
    }
    if (order.status != OrderStatus.pending) {
      return 'เปลี่ยนสถานะได้เฉพาะคำสั่งซื้อที่รอนัดรับ';
    }
    final now = DateTime.now();
    orders[index] = order.copyWith(
      status: OrderStatus.completed,
      completedAt: now,
      events: [
        ...order.events,
        OrderEvent(at: now, actorId: currentUser.id, status: OrderStatus.completed),
      ],
    );
    for (final item in order.items) {
      final productIndex = products.indexWhere((p) => p.id == item.productId);
      if (productIndex != -1) {
        products[productIndex] = products[productIndex].copyWith(
          status: ListingStatus.sold,
        );
      }
      _reservedListingPreviousStatus.remove(item.productId);
    }
    _incrementSuccessfulDeals(order);
    notifyListeners();
    return null;
  }

  String? cancelOrder(String orderId, String reason) {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return 'ไม่พบคำสั่งซื้อนี้';
    final order = orders[index];
    if (!isLoggedIn ||
        (currentUser.id != order.buyerId && currentUser.id != order.sellerId)) {
      return 'คุณไม่มีสิทธิ์ยกเลิกคำสั่งซื้อนี้';
    }
    if (order.status != OrderStatus.pending) {
      return 'ยกเลิกได้เฉพาะคำสั่งซื้อที่รอนัดรับ';
    }
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) return 'กรุณาระบุเหตุผลในการยกเลิก';
    if (trimmedReason.length > 200) return 'เหตุผลต้องไม่เกิน 200 ตัวอักษร';
    final now = DateTime.now();
    orders[index] = order.copyWith(
      status: OrderStatus.cancelled,
      cancelledBy: currentUser.id,
      cancelReason: trimmedReason,
      cancelledAt: now,
      events: [
        ...order.events,
        OrderEvent(at: now, actorId: currentUser.id, status: OrderStatus.cancelled),
      ],
    );
    _restoreReservedProducts(order);
    notifyListeners();
    return null;
  }

  String? disputeOrder(String orderId, String reason, String details) {
    final index = orders.indexWhere((order) => order.id == orderId);
    if (index == -1) return 'ไม่พบคำสั่งซื้อนี้';
    final order = orders[index];
    if (!isLoggedIn ||
        (currentUser.id != order.buyerId && currentUser.id != order.sellerId)) {
      return 'เฉพาะผู้ซื้อหรือผู้ขายของคำสั่งซื้อนี้เท่านั้นที่รายงานได้';
    }
    if (order.status != OrderStatus.pending) {
      return 'รายงานปัญหาได้เฉพาะคำสั่งซื้อที่รอนัดรับ';
    }
    final now = DateTime.now();
    final targetId = currentUser.id == order.buyerId
        ? order.sellerId
        : order.buyerId;
    final target = users.where((user) => user.id == targetId).firstOrNull;
    orders[index] = order.copyWith(
      status: OrderStatus.disputed,
      previousStatus: order.status,
      events: [
        ...order.events,
        OrderEvent(at: now, actorId: currentUser.id, status: OrderStatus.disputed),
      ],
    );
    reports.insert(
      0,
      ReportModel(
        id: 'DISP-${now.microsecondsSinceEpoch}',
        orderId: orderId,
        reporterId: currentUser.id,
        reporterName: currentUser.name,
        reportedUserName: target?.name ?? targetId,
        reason: reason,
        details: details,
      ),
    );
    notifications.insert(0, {
      'title': 'รายงานปัญหาคำสั่งซื้อ',
      'body': 'คำสั่งซื้อ $orderId ถูกส่งให้ทีมดูแลตรวจสอบ',
      'time': 'เมื่อสักครู่',
      'type': 'warning',
      'read': false,
    });
    notifyListeners();
    return null;
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

  String? resolveDispute(String reportId, ReportResolution resolution) {
    if (!isAdmin) return 'เฉพาะผู้ดูแลระบบเท่านั้นที่จัดการรายงานได้';
    final repIndex = reports.indexWhere((r) => r.id == reportId);
    if (repIndex == -1) return 'ไม่พบรายงานนี้';
    final report = reports[repIndex];
    final now = DateTime.now();
    if (resolution == ReportResolution.accountSuspended) {
      reports[repIndex] = report.copyWith(
        status: ReportStatus.accountSuspended,
      );
      notifyListeners();
      return null;
    }

    final orderIndex = orders.indexWhere((order) => order.id == report.orderId);
    if (orderIndex != -1) {
      final order = orders[orderIndex];
      if (order.status != OrderStatus.disputed) {
        return 'คำสั่งซื้อนี้ไม่ได้อยู่ระหว่างตรวจสอบปัญหา';
      }
      if (resolution == ReportResolution.close) {
        final restoredStatus = order.previousStatus ?? OrderStatus.pending;
        orders[orderIndex] = order.copyWith(
          status: restoredStatus,
          clearPreviousStatus: true,
          events: [
            ...order.events,
            OrderEvent(at: now, actorId: currentUser.id, status: restoredStatus),
          ],
        );
      } else {
        orders[orderIndex] = order.copyWith(
          status: OrderStatus.cancelled,
          cancelledBy: currentUser.id,
          cancelReason: 'ยกเลิกโดยผู้ดูแลระบบหลังตรวจสอบรายงาน',
          cancelledAt: now,
          clearPreviousStatus: true,
          events: [
            ...order.events,
            OrderEvent(at: now, actorId: currentUser.id, status: OrderStatus.cancelled),
          ],
        );
        _restoreReservedProducts(order);
      }
    }
    reports[repIndex] = report.copyWith(status: ReportStatus.resolved);
    notifyListeners();
    return null;
  }

  void _restoreReservedProducts(OrderModel order) {
    for (final item in order.items) {
      final index = products.indexWhere(
        (product) => product.id == item.productId,
      );
      if (index == -1 || products[index].status != ListingStatus.reserved) {
        _reservedListingPreviousStatus.remove(item.productId);
        continue;
      }
      final previousStatus =
          _reservedListingPreviousStatus.remove(item.productId) ??
          ListingStatus.active;
      products[index] = products[index].copyWith(status: previousStatus);
    }
  }

  void _incrementSuccessfulDeals(OrderModel order) {
    users = users.map((user) {
      if (user.id == order.buyerId || user.id == order.sellerId) {
        return user.copyWith(successfulDeals: user.successfulDeals + 1);
      }
      return user;
    }).toList();
    currentUser =
        users.where((user) => user.id == currentUser.id).firstOrNull ??
        currentUser;
  }

  UserModel? userById(String userId) =>
      users.where((user) => user.id == userId).firstOrNull;

  List<ReviewModel> reviewsForUser(String userId) {
    final result = reviews
        .where((review) => review.revieweeId == userId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return result;
  }

  bool hasReviewedOrder(String orderId, String reviewerId) => reviews.any(
    (review) => review.orderId == orderId && review.reviewerId == reviewerId,
  );

  String? submitReview({
    required String orderId,
    required int rating,
    required List<String> tags,
    required String comment,
  }) {
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งรีวิว';
    final order = orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null) return 'ไม่พบคำสั่งซื้อนี้';
    if (order.status != OrderStatus.completed) {
      return 'รีวิวได้หลังคำสั่งซื้อสำเร็จเท่านั้น';
    }
    if (currentUser.id != order.buyerId && currentUser.id != order.sellerId) {
      return 'คุณไม่ใช่ผู้ซื้อหรือผู้ขายของคำสั่งซื้อนี้';
    }
    if (hasReviewedOrder(orderId, currentUser.id)) {
      return 'คุณรีวิวคำสั่งซื้อนี้ไปแล้ว';
    }
    if (rating < 1 || rating > 5) return 'คะแนนต้องอยู่ระหว่าง 1 ถึง 5';
    if (comment.length > 500) return 'ความคิดเห็นต้องไม่เกิน 500 ตัวอักษร';
    final revieweeId = currentUser.id == order.buyerId
        ? order.sellerId
        : order.buyerId;
    reviews.add(
      ReviewModel(
        id: 'review_${DateTime.now().microsecondsSinceEpoch}',
        orderId: orderId,
        reviewerId: currentUser.id,
        revieweeId: revieweeId,
        rating: rating,
        tags: List.unmodifiable(tags),
        comment: comment.trim(),
        createdAt: DateTime.now(),
      ),
    );
    _recalculateRatings();
    notifyListeners();
    return null;
  }

  ChatConversation? conversationForOrder(String orderId) {
    final order = orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null ||
        (currentUser.id != order.buyerId && currentUser.id != order.sellerId)) {
      return null;
    }
    for (final item in order.items) {
      final existing = conversations.where(
        (conversation) =>
            conversation.productId == item.productId &&
            conversation.buyerId == order.buyerId &&
            conversation.sellerId == order.sellerId,
      ).firstOrNull;
      if (existing != null) return existing;
    }
    final product = products
        .where((item) => item.id == order.items.first.productId)
        .firstOrNull;
    if (product == null) return null;
    final buyer = userById(order.buyerId);
    final seller = userById(order.sellerId);
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: _nextChatId('chat'),
      peerId: currentUser.id == order.buyerId ? order.sellerId : order.buyerId,
      peerName: currentUser.id == order.buyerId
          ? seller?.name ?? product.sellerName
          : buyer?.name ?? 'ผู้ซื้อ',
      peerAvatar: currentUser.id == order.buyerId
          ? seller?.avatarUrl ?? ''
          : buyer?.avatarUrl ?? '',
      productId: product.id,
      productTitle: product.title,
      productPrice: product.price,
      productImageUrl: product.imageUrl,
      productImage: product.coverImage,
      buyerId: order.buyerId,
      sellerId: order.sellerId,
      lastMessage: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
      lastMessageTime: now,
      unreadByUser: {order.buyerId: 0, order.sellerId: 0},
      messages: [
        ChatMessage(
          id: _nextChatId('msg'),
          senderId: 'system',
          text: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
          timestamp: now,
          isMe: false,
          isSystemPrompt: true,
          type: ChatMessageType.system,
        ),
      ],
    );
    conversations.insert(0, conversation);
    notifyListeners();
    return conversation;
  }

  String? sharedAddressForOrder(String orderId) {
    final order = orders.where((item) => item.id == orderId).firstOrNull;
    if (order == null || currentUser.id != order.buyerId) return null;
    for (final item in order.items) {
      final conversation = conversations.where(
        (chat) =>
            chat.productId == item.productId &&
            chat.buyerId == order.buyerId &&
            chat.sellerId == order.sellerId,
      ).firstOrNull;
      if (conversation == null) continue;
      final address = conversation.messages
          .where(
            (message) =>
                message.type == ChatMessageType.addressShare &&
                message.recipientId == currentUser.id,
          )
          .lastOrNull;
      if (address != null) return address.text;
    }
    return null;
  }

  int get pendingOrderCount =>
      orders.where((order) => order.status == OrderStatus.pending).length;

  int get completedOrderCount =>
      orders.where((order) => order.status == OrderStatus.completed).length;

  // Pickup Points Management (FR-11)
  void addPickupPoint(SuggestedSpot point) {
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

  ChatConversation? openConversationForProduct(String productId) {
    if (!isLoggedIn) return null;
    final product = products.where((item) => item.id == productId).firstOrNull;
    if (product == null || product.sellerId == currentUser.id) return null;

    final existing = conversations.where(
      (conversation) =>
          conversation.productId == productId &&
          conversation.buyerId == currentUser.id &&
          conversation.sellerId == product.sellerId,
    );
    if (existing.isNotEmpty) return existing.first;

    final seller = users.firstWhere(
      (user) => user.id == product.sellerId,
      orElse: () => UserModel(id: product.sellerId, name: product.sellerName),
    );
    final now = DateTime.now();
    final conversation = ChatConversation(
      id: _nextChatId('chat'),
      peerId: seller.id,
      peerName: seller.name,
      peerAvatar: seller.avatarUrl,
      buyerId: currentUser.id,
      sellerId: seller.id,
      productId: product.id,
      productTitle: product.title,
      productPrice: product.price,
      productImageUrl: product.imageUrl,
      productImage: product.coverImage,
      lastMessage: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
      lastMessageTime: now,
      unreadByUser: {currentUser.id: 0, seller.id: 0},
      messages: [
        ChatMessage(
          id: _nextChatId('msg'),
          senderId: 'system',
          text: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
          timestamp: now,
          isMe: false,
          isSystemPrompt: true,
          type: ChatMessageType.system,
        ),
      ],
    );
    conversations.insert(0, conversation);
    notifyListeners();
    return conversation;
  }

  int unreadCountFor(ChatConversation conversation, String userId) =>
      conversation.buyerId != userId && conversation.sellerId != userId
      ? 0
      : conversation.unreadByUser[userId] ??
            (conversation.buyerId == userId ? conversation.unreadCount : 0);

  List<ChatConversation> get conversationsForCurrentUser => isLoggedIn
      ? conversations.where(_isConversationParticipant).toList()
      : const [];

  UserModel? conversationPeer(ChatConversation conversation) {
    final peerId = currentUser.id == conversation.buyerId
        ? conversation.sellerId
        : conversation.buyerId;
    return users.where((user) => user.id == peerId).firstOrNull;
  }

  void markConversationRead(String conversationId) {
    final index = conversations.indexWhere((item) => item.id == conversationId);
    if (index == -1 || !_isConversationParticipant(conversations[index])) {
      return;
    }
    final conversation = conversations[index];
    final unread = Map<String, int>.of(conversation.unreadByUser)
      ..[currentUser.id] = 0;
    conversations[index] = conversation.copyWith(
      unreadCount: currentUser.id == conversation.buyerId
          ? 0
          : conversation.unreadCount,
      unreadByUser: unread,
    );
    notifyListeners();
  }

  void ensureConversationSafetyMessage(String conversationId) {
    final conversation = conversations
        .where((item) => item.id == conversationId)
        .firstOrNull;
    if (conversation == null ||
        !_isConversationParticipant(conversation) ||
        conversation.messages.any(
          (message) => message.type == ChatMessageType.system,
        )) {
      return;
    }
    final messages = List<ChatMessage>.of(conversation.messages)
      ..insert(
        0,
        ChatMessage(
          id: 'safety_${conversation.id}',
          senderId: 'system',
          text: 'อย่าโอนเงินก่อนเห็นสินค้า และนัดในที่สาธารณะถ้าเป็นไปได้',
          timestamp: conversation.messages.isEmpty
              ? DateTime.now()
              : conversation.messages.first.timestamp,
          isMe: false,
          isSystemPrompt: true,
          type: ChatMessageType.system,
        ),
      );
    final index = conversations.indexWhere((item) => item.id == conversationId);
    conversations[index] = conversation.copyWith(messages: messages);
    notifyListeners();
  }

  String? sendTextMessage(String conversationId, String text) {
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งข้อความ';
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 'กรุณาพิมพ์ข้อความ';
    if (trimmed.length > kMaxChatMessageLength) {
      return 'ข้อความต้องไม่เกิน $kMaxChatMessageLength ตัวอักษร';
    }
    final conversation = _participantConversation(conversationId);
    if (conversation == null) return 'ไม่พบบทสนทนาหรือคุณไม่มีสิทธิ์ส่งข้อความ';
    _appendChatMessage(conversation, ChatMessageType.text, trimmed);
    return null;
  }

  String? sendImageMessage(String conversationId, Uint8List bytes) {
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งรูปภาพ';
    if (bytes.isEmpty) return 'ไม่พบข้อมูลรูปภาพ';
    if (bytes.lengthInBytes > kMaxChatImageBytes) {
      return 'รูปภาพต้องมีขนาดไม่เกิน 5 MB';
    }
    final conversation = _participantConversation(conversationId);
    if (conversation == null) return 'ไม่พบบทสนทนาหรือคุณไม่มีสิทธิ์ส่งรูปภาพ';
    _appendChatMessage(
      conversation,
      ChatMessageType.image,
      'ส่งรูปภาพ',
      image: ProductImageData.memory(bytes),
    );
    return null;
  }

  String? proposeMeetup({
    required String conversationId,
    required PickupType pickupType,
    required String placeLabel,
    required DateTime scheduledAt,
    String note = '',
    GeoLocation? spotLocation,
  }) {
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนเสนอนัดรับ';
    final conversation = _participantConversation(conversationId);
    if (conversation == null) return 'ไม่พบบทสนทนาหรือคุณไม่มีสิทธิ์เสนอนัด';
    if (pickupType == PickupType.discussInChat) {
      return 'กรุณาเลือกวิธีนัดรับ';
    }
    final now = DateTime.now();
    if (!scheduledAt.isAfter(now) ||
        scheduledAt.isAfter(
          now.add(const Duration(days: kMeetupMaxDaysAhead)),
        )) {
      return 'วันนัดต้องอยู่ภายใน $kMeetupMaxDaysAhead วันข้างหน้า';
    }
    final product = products
        .where((item) => item.id == conversation.productId)
        .firstOrNull;
    if (product == null) return 'ไม่พบประกาศสินค้านี้';
    final label = pickupType == PickupType.sellerHome
        ? 'บ้านผู้ขาย (ย่าน ${product.locationLabel})'
        : placeLabel.trim();
    if (label.isEmpty) return 'กรุณาระบุสถานที่นัดรับ';
    if (label.length > kPlaceLabelMaxLength) {
      return 'ชื่อสถานที่ต้องไม่เกิน $kPlaceLabelMaxLength ตัวอักษร';
    }
    if (pickupType == PickupType.agreedSpot && spotLocation == null) {
      return 'กรุณาเลือกพิกัดของจุดที่ตกลงกัน';
    }
    if (note.trim().length > kMeetupNoteMaxLength) {
      return 'หมายเหตุต้องไม่เกิน $kMeetupNoteMaxLength ตัวอักษร';
    }
    final agreementId = _nextChatId('meetup');
    // Supersede only pending agreements; shared address messages remain history and are not resent.
    for (var index = 0; index < meetupAgreements.length; index++) {
      final old = meetupAgreements[index];
      if (old.conversationId == conversationId &&
          old.status == MeetupStatus.proposed) {
        meetupAgreements[index] = MeetupAgreement(
          id: old.id,
          conversationId: old.conversationId,
          productId: old.productId,
          proposerId: old.proposerId,
          responderId: old.responderId,
          pickupType: old.pickupType,
          placeLabel: old.placeLabel,
          spotLocation: old.spotLocation,
          scheduledAt: old.scheduledAt,
          note: old.note,
          status: MeetupStatus.superseded,
          createdAt: old.createdAt,
          respondedAt: now,
        );
      }
    }
    final agreement = MeetupAgreement(
      id: agreementId,
      conversationId: conversationId,
      productId: conversation.productId,
      proposerId: currentUser.id,
      responderId: currentUser.id == conversation.buyerId
          ? conversation.sellerId
          : conversation.buyerId,
      pickupType: pickupType,
      placeLabel: label,
      spotLocation: pickupType == PickupType.sellerHome ? null : spotLocation,
      scheduledAt: scheduledAt,
      note: note.trim(),
      status: MeetupStatus.proposed,
      createdAt: now,
    );
    meetupAgreements.add(agreement);
    _appendChatMessage(
      conversation,
      ChatMessageType.meetupProposal,
      'ข้อเสนอนัดรับ',
      meetupId: agreementId,
    );
    return null;
  }

  String? respondMeetup(String meetupId, {required bool accept}) {
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนตอบรับนัด';
    final index = meetupAgreements.indexWhere((item) => item.id == meetupId);
    if (index == -1) return 'ไม่พบข้อเสนอนัดรับ';
    final agreement = meetupAgreements[index];
    if (!_isConversationParticipantById(agreement.conversationId)) {
      return 'คุณไม่มีสิทธิ์ตอบข้อเสนอนี้';
    }
    if (agreement.status != MeetupStatus.proposed) {
      return 'ข้อเสนอนี้ถูกตอบหรือเปลี่ยนไปแล้ว';
    }
    if (agreement.proposerId == currentUser.id) {
      return 'ผู้เสนอนัดไม่สามารถตอบข้อเสนอของตัวเองได้';
    }
    if (agreement.responderId != currentUser.id) {
      return 'เฉพาะผู้รับข้อเสนอเท่านั้นที่ตอบได้';
    }
    meetupAgreements[index] = MeetupAgreement(
      id: agreement.id,
      conversationId: agreement.conversationId,
      productId: agreement.productId,
      proposerId: agreement.proposerId,
      responderId: agreement.responderId,
      pickupType: agreement.pickupType,
      placeLabel: agreement.placeLabel,
      spotLocation: agreement.pickupType == PickupType.sellerHome
          ? null
          : agreement.spotLocation,
      scheduledAt: agreement.scheduledAt,
      note: agreement.note,
      status: accept ? MeetupStatus.accepted : MeetupStatus.declined,
      createdAt: agreement.createdAt,
      respondedAt: DateTime.now(),
    );
    final conversation = _participantConversation(agreement.conversationId)!;
    _appendChatMessage(
      conversation,
      ChatMessageType.system,
      accept ? 'ตกลงนัดรับแล้ว' : 'ปฏิเสธข้อเสนอนัดรับ',
    );
    return null;
  }

  MeetupAgreement? activeAgreementFor(String conversationId) {
    final accepted = meetupAgreements.where(
      (item) =>
          item.conversationId == conversationId &&
          item.status == MeetupStatus.accepted,
    );
    if (accepted.isEmpty) return null;
    return accepted.reduce(
      (a, b) => a.respondedAt!.isAfter(b.respondedAt!) ? a : b,
    );
  }

  String? shareExactAddress(String conversationId) {
    if (!isLoggedIn) return 'เข้าสู่ระบบก่อนส่งที่อยู่';
    final conversation = _participantConversation(conversationId);
    if (conversation == null) return 'ไม่พบบทสนทนาหรือคุณไม่มีสิทธิ์ส่งที่อยู่';
    final product = products
        .where((item) => item.id == conversation.productId)
        .firstOrNull;
    if (product == null || product.sellerId != currentUser.id) {
      return 'เฉพาะเจ้าของประกาศเท่านั้นที่ส่งที่อยู่จริงได้';
    }
    final agreement = activeAgreementFor(conversationId);
    if (agreement == null) return 'ต้องมีนัดรับที่ตกลงแล้วก่อนส่งที่อยู่จริง';
    final privateLocation = _exactLocationsByProductId[product.id];
    if (privateLocation == null || privateLocation.address.trim().isEmpty) {
      return 'ผู้ขายยังไม่ได้บันทึกที่อยู่ กรุณาพิมพ์ที่อยู่ในแชทด้วยตนเอง';
    }
    final recipientId = agreement.proposerId == currentUser.id
        ? agreement.responderId
        : agreement.proposerId;
    _appendChatMessage(
      conversation,
      ChatMessageType.addressShare,
      privateLocation.address,
      recipientId: recipientId,
    );
    return null;
  }

  ChatConversation? _participantConversation(String conversationId) {
    if (!_isConversationParticipantById(conversationId)) return null;
    return conversations.firstWhere((item) => item.id == conversationId);
  }

  bool _isConversationParticipantById(String conversationId) {
    final conversation = conversations
        .where((item) => item.id == conversationId)
        .firstOrNull;
    return conversation != null && _isConversationParticipant(conversation);
  }

  bool _isConversationParticipant(ChatConversation conversation) =>
      currentUser.id == conversation.buyerId ||
      currentUser.id == conversation.sellerId;

  void _appendChatMessage(
    ChatConversation conversation,
    ChatMessageType type,
    String text, {
    ProductImageData? image,
    String? meetupId,
    String? recipientId,
  }) {
    final index = conversations.indexWhere(
      (item) => item.id == conversation.id,
    );
    final now = DateTime.now();
    final message = ChatMessage(
      id: _nextChatId('msg'),
      senderId: currentUser.id,
      text: text,
      timestamp: now,
      isMe: true,
      type: type,
      image: image,
      meetupId: meetupId,
      recipientId: recipientId,
    );
    final messages = List<ChatMessage>.of(conversation.messages)..add(message);
    final recipient =
        recipientId ??
        (currentUser.id == conversation.buyerId
            ? conversation.sellerId
            : conversation.buyerId);
    final unread = Map<String, int>.of(conversation.unreadByUser);
    unread[recipient] = (unread[recipient] ?? 0) + 1;
    conversations[index] = conversation.copyWith(
      messages: messages,
      lastMessage: type == ChatMessageType.image
          ? 'ส่งรูปภาพ'
          : type == ChatMessageType.meetupProposal
          ? 'ข้อเสนอนัดรับ'
          : text,
      lastMessageTime: now,
      unreadCount: conversation.unreadCount + 1,
      unreadByUser: unread,
    );
    notifyListeners();
  }

  String _nextChatId(String prefix) =>
      '${prefix}_${DateTime.now().microsecondsSinceEpoch}_${_chatSequence++}';
}
