import 'package:flutter/material.dart';

import '../models/product.dart';
import '../models/product_image_data.dart';
import '../theme/app_theme.dart';

class ProductImage extends StatelessWidget {
  final ProductImageData? source;
  final String? fallbackUrl;
  final BoxFit fit;

  const ProductImage({
    super.key,
    this.source,
    this.fallbackUrl,
    this.fit = BoxFit.cover,
  });

  factory ProductImage.forProduct(
    ProductModel product, {
    Key? key,
    int index = 0,
    BoxFit fit = BoxFit.cover,
  }) {
    final source = index < product.productImages.length
        ? product.productImages[index]
        : index == 0
        ? product.coverImage
        : null;
    return ProductImage(
      key: key,
      source: source,
      fallbackUrl: product.imageUrl,
      fit: fit,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = source?.bytes;
    if (bytes != null) {
      return Image.memory(
        bytes,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }

    final url = source?.url ?? fallbackUrl;
    if (url != null && url.isNotEmpty) {
      return Image.network(
        url,
        fit: fit,
        errorBuilder: (context, error, stackTrace) => _placeholder(),
      );
    }
    return _placeholder();
  }

  Widget _placeholder() {
    return Container(
      color: AppColors.aquaPale,
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_not_supported_outlined,
        color: AppColors.aquaLight,
      ),
    );
  }
}
