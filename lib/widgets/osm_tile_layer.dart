import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';

class OsmTileLayer extends StatelessWidget {
  final ValueChanged<Object>? onError;

  const OsmTileLayer({super.key, this.onError});

  @override
  Widget build(BuildContext context) {
    // The public OSM tile server is for prototypes and light use only. Use a
    // suitable tile provider for a production release.
    return TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'com.example.moor_market',
      errorTileCallback: (tile, error, stackTrace) => onError?.call(error),
    );
  }
}
