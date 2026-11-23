import 'dart:typed_data';

class ProductImageData {
  final String? url;
  final Uint8List? bytes;
  final String? storageKey;

  const ProductImageData.network(this.url) : bytes = null, storageKey = null;
  const ProductImageData.memory(this.bytes) : url = null, storageKey = null;
  const ProductImageData.local({required this.storageKey, this.bytes})
    : url = null;

  Map<String, Object?> toJson() => {
    if (url != null) 'url': url,
    if (storageKey != null) 'storageKey': storageKey,
  };

  factory ProductImageData.fromJson(Map<String, dynamic> json) {
    final key = json['storageKey'] is String
        ? json['storageKey'] as String
        : null;
    if (key != null) return ProductImageData.local(storageKey: key);
    return ProductImageData.network(
      json['url'] is String ? json['url'] as String : null,
    );
  }
}
