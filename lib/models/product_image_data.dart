import 'dart:typed_data';

class ProductImageData {
  final String? url;
  final Uint8List? bytes;

  const ProductImageData.network(this.url) : bytes = null;
  const ProductImageData.memory(this.bytes) : url = null;
}
