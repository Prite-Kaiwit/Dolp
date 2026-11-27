part of 'app_state.dart';

/// Prototype seed data (users, listings, orders, reviews). Not used in production.
extension _AppStateSeed on AppState {
  void _initMockData() {
    _exactLocationsByProductId.clear();
    _reservedListingPreviousStatus.clear();
    _blockedUserPairs.clear();
    _suspendedUserReasons.clear();
    _safetyTipsAcknowledgedBy.clear();
    _areaAlertSubscriptions.clear();
    _notificationSequence = 0;
    _orderSequence = 0;
    _chatSequence = 0;
    cartItems = [];
    orders = [];
    reviews = [];
    conversations = [];
    reports = [];
    notifications = [];
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
    currentUser = users.first;
    _areaAlertSubscriptions['user_01'] = AreaAlertSubscription(
      userId: 'user_01',
      center: GeoLocation(users.first.homeLat!, users.first.homeLng!),
      enabled: true,
      radiusKm: 5,
    );

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
    final seedCreatedAt = DateTime.now();
    products = products.indexed.map((entry) {
      final (index, product) = entry;
      return product.copyWith(
        createdAt: seedCreatedAt.subtract(Duration(days: index % 7)),
      );
    }).toList();

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
    _recalculateSuccessfulDeals();
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

    // Seed Reports use valid users and references for admin review examples.
    reports = [
      ReportModel(
        id: 'REP-001',
        orderId: 'ORD-2026-0801',
        reporterId: 'user_02',
        reportedUserId: 'user_04',
        reason: ReportReason.damagedItem,
        detail:
            'ผู้ขายแจ้งว่าสภาพดี แต่สินค้าจริงจอแตกและใช้งานไม่ได้ โปรดช่วยตรวจสอบข้อมูลการนัดรับ',
        status: ReportStatus.open,
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      ),
      ReportModel(
        id: 'REP-002',
        reporterId: 'user_01',
        reportedUserId: 'user_03',
        productId: 'prod_2',
        reason: ReportReason.paymentScam,
        detail:
            'ผู้ขายทักแชทมาขอให้โอนเงินนอกช่องทางที่ตกลงกัน โปรดตรวจสอบข้อมูลก่อนทำรายการ',
        status: ReportStatus.open,
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
      ),
    ];

    // Seed notifications for the first sample account.
    notifications = [
      AppNotification(
        id: 'notif_seed_order',
        userId: 'user_01',
        type: AppNotificationType.orderStatusChanged,
        title: 'มีคำสั่งซื้อใหม่',
        body: 'คำสั่งซื้อ ORD-2026-0901 รอนัดรับและชำระเงินหน้างาน',
        refType: 'order',
        refId: 'ORD-2026-0901',
        createdAt: DateTime.now().subtract(const Duration(minutes: 12)),
      ),
      AppNotification(
        id: 'notif_seed_chat',
        userId: 'user_01',
        type: AppNotificationType.newMessage,
        title: 'มีข้อความใหม่จาก ณัฐชา เกียรติสกุล',
        body: 'มีหนังสือ Data Structures แลกได้ไหมคะ',
        refType: 'chat',
        refId: 'chat_02',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        readAt: DateTime.now().subtract(const Duration(minutes: 30)),
      ),
      AppNotification(
        id: 'notif_seed_system',
        userId: 'user_01',
        type: AppNotificationType.system,
        title: 'ประกาศจาก $appName',
        body: 'ยินดีต้อนรับสู่ตลาดซื้อขาย แลกเปลี่ยน และแบ่งปันสิ่งของในชุมชน',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        readAt: DateTime.now().subtract(const Duration(hours: 20)),
      ),
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
      return user.copyWith(rating: average, reviewCount: userReviews.length);
    }).toList();

    products = products.map((product) {
      final seller = users
          .where((user) => user.id == product.sellerId)
          .firstOrNull;
      if (seller == null) return product;
      return product.copyWith(
        sellerRating: seller.rating,
        sellerReviewCount: seller.reviewCount,
      );
    }).toList();
    currentUser =
        users.where((user) => user.id == currentUser.id).firstOrNull ??
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
          at:
              completedAt ??
              cancelledAt ??
              createdAt.add(const Duration(hours: 1)),
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
}
