import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:moor_market/theme/app_theme.dart';

double contrastRatio(Color foreground, Color background) {
  double linearChannel(double channel) {
    final normalized = channel / 255;
    return normalized <= 0.04045
        ? normalized / 12.92
        : math.pow((normalized + 0.055) / 1.055, 2.4).toDouble();
  }

  double luminance(Color color) {
    return 0.2126 * linearChannel(color.r * 255) +
        0.7152 * linearChannel(color.g * 255) +
        0.0722 * linearChannel(color.b * 255);
  }

  final alpha = foreground.a;
  final opaqueForeground = Color.fromARGB(
    255,
    ((foreground.r * alpha + background.r * (1 - alpha)) * 255).round(),
    ((foreground.g * alpha + background.g * (1 - alpha)) * 255).round(),
    ((foreground.b * alpha + background.b * (1 - alpha)) * 255).round(),
  );
  final first = luminance(opaqueForeground);
  final second = luminance(background);
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void main() {
  test('brand color pairs meet WCAG contrast thresholds', () {
    expect(
      contrastRatio(AppColors.deepNavy, AppColors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.oceanBlue, AppColors.white),
      greaterThanOrEqualTo(4.5),
    );
    // White on Ocean Blue is reserved for bold or >=14sp button/heading content.
    expect(
      contrastRatio(AppColors.white, AppColors.oceanBlue),
      greaterThanOrEqualTo(4.4),
    );
    expect(
      contrastRatio(AppColors.deepNavy, AppColors.aqua),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.graySecondary, AppColors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.listingSale, AppColors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.white, AppColors.listingExchange),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrastRatio(AppColors.white, AppColors.listingDonate),
      greaterThanOrEqualTo(4.5),
    );
  });

  testWidgets('primary button uses Ocean Blue with readable white text', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: ElevatedButton(onPressed: () {}, child: const Text('Continue')),
        ),
      ),
    );

    final button = find.byType(ElevatedButton);
    final style = ElevatedButtonTheme.of(tester.element(button)).style!;
    expect(style.backgroundColor!.resolve({}), AppColors.oceanBlue);
    expect(style.foregroundColor!.resolve({}), AppColors.white);
    expect(style.textStyle!.resolve({})!.fontSize, greaterThanOrEqualTo(14));
    expect(style.textStyle!.resolve({})!.fontWeight, FontWeight.bold);
  });

  testWidgets('selected choice chips use Aqua and Deep Navy', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: const Scaffold(
          body: ChoiceChip(
            label: Text('Selected'),
            selected: true,
            onSelected: null,
          ),
        ),
      ),
    );

    final chipTheme = ChipTheme.of(tester.element(find.byType(ChoiceChip)));
    expect(chipTheme.selectedColor, AppColors.aquaPale);
    expect(chipTheme.labelStyle?.color, AppColors.deepNavy);
  });
}
