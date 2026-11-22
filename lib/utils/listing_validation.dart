import '../constants/listing_limits.dart';

final RegExp _listingPricePattern = RegExp(
  '^(?:\\d+|\\d{1,3}(?:,\\d{3})+)(?:\\.\\d{1,$kMaxListingPriceDecimalPlaces})?\$',
);

String? validateListingTitle(String value) {
  final title = value.trim();
  if (title.isEmpty) return 'กรุณากรอกชื่อสินค้า';
  if (title.length > kMaxListingTitleLength) {
    return 'ชื่อสินค้าต้องไม่เกิน $kMaxListingTitleLength ตัวอักษร';
  }
  return null;
}

String? validateListingDescription(String value) {
  if (value.length > kMaxListingDescriptionLength) {
    return 'รายละเอียดต้องไม่เกิน $kMaxListingDescriptionLength ตัวอักษร';
  }
  return null;
}

String? validateTradeRequest(String value) {
  final tradeRequest = value.trim();
  if (tradeRequest.isEmpty) return 'กรุณาระบุสิ่งที่ต้องการแลก';
  if (tradeRequest.length > kMaxTradeRequestLength) {
    return 'ข้อความต้องไม่เกิน $kMaxTradeRequestLength ตัวอักษร';
  }
  return null;
}

String? validateListingPrice(String value, {bool required = true}) {
  final input = value.trim();
  if (input.isEmpty) return required ? 'กรุณากรอกราคา' : null;
  if (!_listingPricePattern.hasMatch(input)) {
    return 'กรุณากรอกราคาเป็นตัวเลข ทศนิยมไม่เกิน 2 ตำแหน่ง';
  }

  final price = double.tryParse(input.replaceAll(',', ''));
  if (price == null) return 'กรุณากรอกราคาเป็นตัวเลข';
  if (price <= 0) return 'ราคาต้องมากกว่า 0 บาท';
  if (price > kMaxListingPrice) {
    return 'ราคาต้องไม่เกิน ${kMaxListingPrice.toStringAsFixed(0)} บาท';
  }
  return null;
}

double parseListingPrice(String value) =>
    double.parse(value.trim().replaceAll(',', ''));
