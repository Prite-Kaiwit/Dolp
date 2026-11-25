part of 'app_state.dart';

/// Nearby search, private listing locations, and listing management.
extension AppStateListings on AppState {
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
    if (currentUser.isSuspended) return const [];
    final nearby = <NearbyProduct>[];
    for (final product in products) {
      if (product.status != ListingStatus.active ||
          (userById(product.sellerId)?.isSuspended ?? false) ||
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
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) throw StateError(sessionError);
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
    if (product.status == ListingStatus.active) {
      _notifyAreaSubscribers(product);
    }
    notifyListeners();
    return product;
  }

  void _notifyAreaSubscribers(ProductModel product) {
    for (final user in users) {
      if (user.id == product.sellerId ||
          user.isSuspended ||
          areUsersBlocked(user.id, product.sellerId)) {
        continue;
      }
      final subscription = areaAlertSubscriptionFor(user.id);
      if (!subscription.enabled ||
          (subscription.categories.isNotEmpty &&
              !subscription.categories.contains(product.category))) {
        continue;
      }
      if (distanceKm(subscription.center, product.publicLocation) >
          subscription.radiusKm) {
        continue;
      }
      _notifyUser(
        userId: user.id,
        type: AppNotificationType.newListingNearby,
        title: 'ประกาศใหม่ใกล้พื้นที่ของคุณ',
        body: product.title,
        refType: 'product',
        refId: product.id,
      );
    }
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
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) throw StateError(sessionError);
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
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
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
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) return sessionError;
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
    final sessionError = _expireSuspendedSession();
    if (sessionError != null) throw StateError(sessionError);
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
}
