import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/constants/listing_limits.dart';
import 'package:moor_market/utils/listing_validation.dart';

void main() {
  group('listing price validation', () {
    test(
      'rejects empty, non-numeric, zero, negative, and excess precision',
      () {
        expect(validateListingPrice(''), 'กรุณากรอกราคา');
        expect(validateListingPrice('abc'), isNotNull);
        expect(validateListingPrice('0'), 'ราคาต้องมากกว่า 0 บาท');
        expect(validateListingPrice('-5'), isNotNull);
        expect(validateListingPrice('0.001'), isNotNull);
        expect(validateListingPrice('1,000,001'), isNotNull);
      },
    );

    test('accepts supported price boundaries and two decimal places', () {
      expect(validateListingPrice('1,000,000'), isNull);
      expect(validateListingPrice('99.99'), isNull);
      expect(parseListingPrice('1,000,000'), kMaxListingPrice);
    });

    test('exchange price may be blank while trade request is required', () {
      expect(validateListingPrice('', required: false), isNull);
      expect(validateTradeRequest('  '), isNotNull);
      expect(validateTradeRequest('ต้นไม้'), isNull);
      expect(
        validateTradeRequest('x' * (kMaxTradeRequestLength + 1)),
        isNotNull,
      );
    });
  });

  test('title and description respect the configured length limits', () {
    expect(validateListingTitle('  '), isNotNull);
    expect(validateListingTitle('x' * (kMaxListingTitleLength + 1)), isNotNull);
    expect(
      validateListingDescription('x' * (kMaxListingDescriptionLength + 1)),
      isNotNull,
    );
    expect(validateListingDescription(''), isNull);
  });
}
