import 'dart:math' as math;

import 'package:flutter/material.dart';
import '../constants/app_info.dart';
import '../models/user.dart';
import '../models/product.dart';
import '../models/geo_location.dart';
import '../models/nearby_product.dart';
import '../models/order.dart';
import '../models/chat.dart';
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
    _exactLocationsByProductId.clear();
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
        location: GeoLocation(12.6112, 102.1031),
        type: SuggestedSpotType.mall,
        openHours: '07:30 - 20:00 น.',
      ),
      PickupPointModel(
        id: 'p2',
        name: 'จุดสาธารณะตัวอย่าง ท่าใหม่',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในอำเภอท่าใหม่',
        zone: 'ท่าใหม่',
        location: GeoLocation(12.6230, 101.9990),
        type: SuggestedSpotType.convenienceStore,
        openHours: '08:00 - 21:00 น.',
      ),
      PickupPointModel(
        id: 'p3',
        name: 'จุดสาธารณะตัวอย่าง ขลุง',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในอำเภอขลุง',
        zone: 'ขลุง',
        location: GeoLocation(12.4600, 102.2200),
        type: SuggestedSpotType.gasStation,
        openHours: '08:30 - 18:30 น.',
      ),
      PickupPointModel(
        id: 'p4',
        name: 'จุดสาธารณะตัวอย่าง แหลมสิงห์',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในอำเภอแหลมสิงห์',
        zone: 'แหลมสิงห์',
        location: GeoLocation(12.4810, 102.0720),
        type: SuggestedSpotType.other,
        openHours: '08:00 - 22:00 น.',
      ),
      PickupPointModel(
        id: 'p5',
        name: 'จุดสาธารณะตัวอย่าง นายายอาม',
        description: 'ตำแหน่งตัวอย่างสำหรับตกลงนัดรับในอำเภอนายายอาม',
        zone: 'นายายอาม',
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
      pickupPoint: _legacyPickupPointFor(locationLabel),
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

  String _legacyPickupPointFor(String locationLabel) {
    if (locationLabel.contains('ท่าใหม่')) {
      return 'จุดสาธารณะตัวอย่าง ท่าใหม่';
    }
    if (locationLabel.contains('แหลมสิงห์')) {
      return 'จุดสาธารณะตัวอย่าง แหลมสิงห์';
    }
    return 'จุดสาธารณะตัวอย่าง เขตเมือง';
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
    // Phase 5 will check accepted meetup agreements here.
    return false;
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
      pickupType: product.pickupType,
      agreedPlaceLabel: pickupPoint,
      pickupNote: note,
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
