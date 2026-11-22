import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../models/nearby_product.dart';
import '../models/geo_location.dart';
import '../screens/home/product_detail_screen.dart';
import '../theme/app_theme.dart';
import '../utils/distance.dart';
import 'osm_tile_layer.dart';
import 'product_image.dart';

class NearbyProductsMap extends StatefulWidget {
  final List<NearbyProduct> products;
  final GeoLocation userLocation;
  final double radiusKm;

  const NearbyProductsMap({
    super.key,
    required this.products,
    required this.userLocation,
    required this.radiusKm,
  });

  @override
  State<NearbyProductsMap> createState() => _NearbyProductsMapState();
}

class _NearbyProductsMapState extends State<NearbyProductsMap> {
  bool _hasTileError = false;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.userLocation.lat, widget.userLocation.lng);

    return SizedBox(
      height: 390,
      child: Stack(
        children: [
          FlutterMap(
            key: ValueKey(
              '${widget.userLocation.lat}:${widget.userLocation.lng}:${widget.radiusKm}',
            ),
            options: MapOptions(
              initialCenter: center,
              initialZoom: _zoomForRadius(widget.radiusKm),
              backgroundColor: const Color(0xFFE7E9E7),
            ),
            children: [
              OsmTileLayer(onError: _handleTileError),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: widget.radiusKm * 1000,
                    useRadiusInMeter: true,
                    color: AppColors.pinkPrimary.withValues(alpha: 0.1),
                    borderColor: AppColors.pinkPrimary,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (final nearby in widget.products)
                    Marker(
                      point: LatLng(
                        nearby.product.publicLocation.lat,
                        nearby.product.publicLocation.lng,
                      ),
                      width: 42,
                      height: 48,
                      child: GestureDetector(
                        onTap: () => _showProduct(context, nearby),
                        child: const Icon(
                          Icons.location_on,
                          color: AppColors.pinkPrimary,
                          size: 38,
                        ),
                      ),
                    ),
                  Marker(
                    point: center,
                    width: 40,
                    height: 40,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.info,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                      child: const Icon(
                        Icons.person_pin_circle,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (_hasTileError)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xFFE7E9E7),
                child: Center(
                  child: Text(
                    'โหลดแผนที่ไม่ได้',
                    style: TextStyle(
                      color: AppColors.graySecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
          const Positioned(left: 8, bottom: 8, child: _MapAttribution()),
        ],
      ),
    );
  }

  void _handleTileError(Object error) {
    if (mounted && !_hasTileError) setState(() => _hasTileError = true);
  }

  Future<void> _showProduct(BuildContext context, NearbyProduct nearby) async {
    await showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: ListTile(
          contentPadding: const EdgeInsets.all(16),
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: ProductImage.forProduct(nearby.product),
            ),
          ),
          title: Text(nearby.product.title),
          subtitle: Text(
            '${formatDistance(nearby.distanceKm)} · ${nearby.product.locationLabel}',
          ),
          onTap: () {
            Navigator.pop(sheetContext);
            Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => ProductDetailScreen(
                  product: nearby.product,
                  nearbyDistanceKm: nearby.distanceKm,
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  double _zoomForRadius(double radiusKm) =>
      (15 - math.log(radiusKm.clamp(1, 20)) / math.ln2).clamp(8, 15);
}

class PublicLocationPreview extends StatefulWidget {
  final GeoLocation publicLocation;

  const PublicLocationPreview({super.key, required this.publicLocation});

  @override
  State<PublicLocationPreview> createState() => _PublicLocationPreviewState();
}

class _PublicLocationPreviewState extends State<PublicLocationPreview> {
  bool _hasTileError = false;

  @override
  Widget build(BuildContext context) {
    final center = LatLng(widget.publicLocation.lat, widget.publicLocation.lng);

    return SizedBox(
      height: 190,
      child: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: center,
              initialZoom: 14,
              backgroundColor: const Color(0xFFE7E9E7),
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              OsmTileLayer(
                onError: (error) {
                  if (mounted && !_hasTileError) {
                    setState(() => _hasTileError = true);
                  }
                },
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: center,
                    radius: 500,
                    useRadiusInMeter: true,
                    color: AppColors.pinkPrimary.withValues(alpha: 0.12),
                    borderColor: AppColors.pinkPrimary,
                    borderStrokeWidth: 2,
                  ),
                ],
              ),
            ],
          ),
          if (_hasTileError)
            const Positioned.fill(
              child: ColoredBox(
                color: Color(0xFFE7E9E7),
                child: Center(child: Text('โหลดแผนที่ไม่ได้')),
              ),
            ),
          const Positioned(left: 8, bottom: 8, child: _MapAttribution()),
        ],
      ),
    );
  }
}

class _MapAttribution extends StatelessWidget {
  const _MapAttribution();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 5, vertical: 3),
        child: Text(
          '© OpenStreetMap contributors',
          style: TextStyle(fontSize: 10, color: AppColors.inkText),
        ),
      ),
    );
  }
}
