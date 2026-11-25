import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' show LatLng;

import '../constants/app_info.dart';
import '../models/geo_location.dart';
import '../models/pickup_point.dart';
import '../models/product.dart';
import '../theme/app_theme.dart';
import '../utils/distance.dart';
import 'osm_tile_layer.dart';
import 'product_image.dart';

enum MapPinKind { home, item, spot }

/// Teardrop map pin in the app palette. The tip sits at the bottom center.
class MapPin extends StatelessWidget {
  final MapPinKind kind;
  final ProductModel? product;
  final double size;

  const MapPin({super.key, required this.kind, this.product, this.size = 44});

  double get height => size * 1.3;

  @override
  Widget build(BuildContext context) {
    final color = kind == MapPinKind.spot
        ? AppColors.deepNavy
        : AppColors.oceanBlue;
    final inner = size * 0.74;
    return SizedBox(
      width: size,
      height: height,
      child: CustomPaint(
        painter: _PinPainter(color),
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: EdgeInsets.only(top: (size - inner) / 2),
            child: SizedBox.square(dimension: inner, child: _content(inner)),
          ),
        ),
      ),
    );
  }

  Widget _content(double inner) {
    final product = this.product;
    if (kind == MapPinKind.item && product != null) {
      return Container(
        padding: const EdgeInsets.all(2),
        decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
        ),
        child: ClipOval(child: ProductImage.forProduct(product)),
      );
    }
    final icon = switch (kind) {
      MapPinKind.home => Icons.home_rounded,
      MapPinKind.spot => Icons.storefront_rounded,
      MapPinKind.item => Icons.sell_rounded,
    };
    return Icon(icon, color: AppColors.white, size: inner * 0.62);
  }
}

class _PinPainter extends CustomPainter {
  final Color color;

  const _PinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final c = Offset(r, r);
    final tip = Offset(r, size.height);
    final d = tip.dy - c.dy;
    final phi = math.acos(r / d);
    Offset tangent(double sign) => Offset(
      c.dx + r * math.cos(math.pi / 2 + sign * phi),
      c.dy + r * math.sin(math.pi / 2 + sign * phi),
    );
    final path = Path()
      ..addOval(Rect.fromCircle(center: c, radius: r))
      ..addPolygon([tangent(-1), tip, tangent(1)], true);
    canvas.drawShadow(path, AppColors.deepNavy, 3, false);
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _PinPainter oldDelegate) =>
      oldDelegate.color != color;
}

/// The illustration for one onboarding page, built from real app pieces.
class OnboardingVisual extends StatelessWidget {
  final int page;
  final List<ProductModel> products;
  final SuggestedSpot? spot;

  const OnboardingVisual({
    super.key,
    required this.page,
    required this.products,
    this.spot,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: DecoratedBox(
          position: DecorationPosition.foreground,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.grayLine),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Below this height the overlay cards are trimmed so they
              // don't crowd out the map.
              final compact = constraints.maxHeight < 200;
              return switch (page) {
                0 => _neighborhood(),
                1 => _nearby(compact: compact),
                _ => _meetup(compact: compact),
              };
            },
          ),
        ),
      ),
    );
  }

  Widget _neighborhood() {
    const offsets = [(0.0032, -0.0042), (-0.0030, 0.0040), (0.0040, 0.0036)];
    return _StaticMap(
      center: kDefaultCenter,
      zoom: 15,
      circleRadiusMeters: 500,
      markers: [
        for (var i = 0; i < math.min(products.length, offsets.length); i++)
          _marker(
            _offset(kDefaultCenter, offsets[i]),
            MapPin(kind: MapPinKind.item, product: products[i], size: 42),
          ),
        _marker(kDefaultCenter, const MapPin(kind: MapPinKind.home, size: 48)),
      ],
      overlay: const Positioned(
        left: 12,
        bottom: 12,
        child: _Chip(
          icon: Icons.my_location_rounded,
          label: 'พื้นที่ของคุณ (โดยประมาณ)',
        ),
      ),
    );
  }

  Widget _nearby({required bool compact}) {
    const offsets = [(0.011, -0.013), (-0.014, 0.008), (0.006, 0.017)];
    final featured = products.isEmpty ? null : products.first;
    return _StaticMap(
      center: kDefaultCenter,
      zoom: 12.8,
      circleRadiusMeters: 3000,
      markers: [
        for (var i = 0; i < math.min(products.length, offsets.length); i++)
          _marker(
            _offset(kDefaultCenter, offsets[i]),
            MapPin(kind: MapPinKind.item, product: products[i], size: 38),
          ),
        _marker(kDefaultCenter, const MapPin(kind: MapPinKind.home, size: 40)),
      ],
      overlay: Positioned.fill(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _RadiusChip('1 กม.'),
                  _RadiusChip('3 กม.', selected: true),
                  _RadiusChip('5 กม.'),
                ],
              ),
              const Spacer(),
              if (featured != null && !compact) _ProductPeek(product: featured),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meetup({required bool compact}) {
    final center = spot?.location ?? kDefaultCenter;
    return _StaticMap(
      center: center,
      zoom: 15.5,
      markers: [_marker(center, const MapPin(kind: MapPinKind.spot, size: 48))],
      overlay: Positioned(
        left: 12,
        right: 12,
        bottom: 12,
        child: _MeetupCard(
          placeName: spot?.name ?? 'จุดนัดรับสาธารณะ',
          showDetails: !compact,
        ),
      ),
    );
  }

  static GeoLocation _offset(GeoLocation base, (double, double) delta) =>
      GeoLocation(base.lat + delta.$1, base.lng + delta.$2);

  static Marker _marker(GeoLocation at, MapPin pin) => Marker(
    point: LatLng(at.lat, at.lng),
    width: pin.size,
    height: pin.height,
    alignment: Alignment.topCenter,
    child: pin,
  );
}

class _StaticMap extends StatelessWidget {
  final GeoLocation center;
  final double zoom;
  final double? circleRadiusMeters;
  final List<Marker> markers;
  final Widget overlay;

  const _StaticMap({
    required this.center,
    required this.zoom,
    required this.markers,
    required this.overlay,
    this.circleRadiusMeters,
  });

  @override
  Widget build(BuildContext context) {
    final point = LatLng(center.lat, center.lng);
    final radius = circleRadiusMeters;
    return Stack(
      children: [
        const Positioned.fill(
          child: CustomPaint(painter: _FallbackMapPainter()),
        ),
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // Zoom is tuned for a 300 px tall card; adjust it so a smaller
              // or larger card shows the same area and the pins stay in frame.
              final height = constraints.maxHeight.isFinite
                  ? constraints.maxHeight
                  : 300.0;
              final effectiveZoom =
                  zoom + math.log(math.max(height, 1) / 300) / math.ln2;
              return FlutterMap(
                key: ValueKey(effectiveZoom.toStringAsFixed(2)),
                options: MapOptions(
                  initialCenter: point,
                  initialZoom: effectiveZoom,
                  backgroundColor: Colors.transparent,
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.none,
                  ),
                ),
                children: [
                  const OsmTileLayer(),
                  if (radius != null)
                    CircleLayer(
                      circles: [
                        CircleMarker(
                          point: point,
                          radius: radius,
                          useRadiusInMeter: true,
                          color: AppColors.aqua.withValues(alpha: 0.16),
                          borderColor: AppColors.aqua,
                          borderStrokeWidth: 2,
                        ),
                      ],
                    ),
                  MarkerLayer(markers: markers),
                ],
              );
            },
          ),
        ),
        overlay,
      ],
    );
  }
}

/// Quiet street grid shown under the tiles, so an offline map still reads
/// as a map instead of a blank or broken box.
class _FallbackMapPainter extends CustomPainter {
  const _FallbackMapPainter();

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = AppColors.aquaPale);
    final casing = Paint()
      ..color = AppColors.grayLine
      ..strokeWidth = 9
      ..style = PaintingStyle.stroke;
    final road = Paint()
      ..color = AppColors.white
      ..strokeWidth = 6
      ..style = PaintingStyle.stroke;
    final w = size.width;
    final h = size.height;
    final roads = [
      [Offset(0, h * 0.30), Offset(w, h * 0.22)],
      [Offset(0, h * 0.72), Offset(w, h * 0.80)],
      [Offset(w * 0.28, 0), Offset(w * 0.34, h)],
      [Offset(w * 0.70, 0), Offset(w * 0.62, h)],
      [Offset(0, h * 0.95), Offset(w * 0.55, 0)],
    ];
    for (final paint in [casing, road]) {
      for (final r in roads) {
        canvas.drawLine(r[0], r[1], paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _FallbackMapPainter oldDelegate) => false;
}

final _cardShadow = [
  BoxShadow(
    color: AppColors.deepNavy.withValues(alpha: 0.12),
    blurRadius: 12,
    offset: const Offset(0, 4),
  ),
];

class _Chip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Chip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: _cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.oceanBlue),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.deepNavy,
            ),
          ),
        ],
      ),
    );
  }
}

class _RadiusChip extends StatelessWidget {
  final String label;
  final bool selected;

  const _RadiusChip(this.label, {this.selected = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: selected ? AppColors.oceanBlue : AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: selected ? AppColors.oceanBlue : AppColors.grayLine,
        ),
        boxShadow: _cardShadow,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? AppColors.white : AppColors.deepNavy,
        ),
      ),
    );
  }
}

class _ProductPeek extends StatelessWidget {
  final ProductModel product;

  const _ProductPeek({required this.product});

  String get _priceLabel => switch (product.type) {
    ListingType.sell => '฿${product.price.toStringAsFixed(0)}',
    ListingType.trade => 'แลกเปลี่ยน',
    ListingType.donate => 'แจกฟรี',
  };

  @override
  Widget build(BuildContext context) {
    final km = distanceKm(kDefaultCenter, product.publicLocation);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _cardShadow,
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox.square(
              dimension: 48,
              child: ProductImage.forProduct(product),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.deepNavy,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _priceLabel,
                  maxLines: 1,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: AppColors.oceanBlue,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.near_me_rounded,
            size: 14,
            color: AppColors.graySecondary,
          ),
          const SizedBox(width: 2),
          Text(
            '${km.toStringAsFixed(1)} กม.',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.graySecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _MeetupCard extends StatelessWidget {
  final String placeName;
  final bool showDetails;

  const _MeetupCard({required this.placeName, this.showDetails = true});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: _cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(
                Icons.handshake_outlined,
                size: 16,
                color: AppColors.oceanBlue,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'ข้อเสนอนัดรับ',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.graySecondary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.successPale,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.success,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'ยอมรับแล้ว',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.successDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            placeName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.deepNavy,
            ),
          ),
          if (showDetails) ...[
            const SizedBox(height: 2),
            const Text(
              'เสาร์นี้ 14:00 น. · ชำระเงินสดตอนรับของ',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: AppColors.graySecondary),
            ),
          ],
        ],
      ),
    );
  }
}
