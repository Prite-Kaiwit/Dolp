import '../constants/categories.dart';
import '../constants/shop_limits.dart';
import '../models/shop_profile.dart';

/// Returns a Thai error message for an invalid [shop], or null when valid.
String? validateShopProfile(ShopProfile shop) {
  final name = shop.shopName.trim();
  if (name.isEmpty) return 'กรุณากรอกชื่อร้าน';
  if (name.length > kMaxShopNameLength) {
    return 'ชื่อร้านยาวเกิน $kMaxShopNameLength ตัวอักษร';
  }
  if (shop.description.trim().length > kMaxShopDescriptionLength) {
    return 'คำอธิบายร้านยาวเกิน $kMaxShopDescriptionLength ตัวอักษร';
  }
  if (shop.categories.length < kMinShopCategories) {
    return 'เลือกหมวดสินค้าอย่างน้อย $kMinShopCategories หมวด';
  }
  if (shop.categories.length > kMaxShopCategories) {
    return 'เลือกหมวดสินค้าได้ไม่เกิน $kMaxShopCategories หมวด';
  }
  if (shop.categories.any((c) => !kListingCategories.contains(c))) {
    return 'หมวดสินค้าไม่ถูกต้อง';
  }
  if (shop.openingHours.isEmpty) return 'กรุณาระบุเวลาเปิดอย่างน้อย 1 วัน';
  if (shop.openingHours.days.values.any((d) => d.openMinute == d.closeMinute)) {
    return 'เวลาเปิดและปิดต้องไม่ตรงกัน';
  }
  if (shop.locationLabel.trim().isEmpty) return 'กรุณาเลือกที่ตั้งร้าน';
  return null;
}
