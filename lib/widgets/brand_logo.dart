import 'package:flutter/material.dart';

import '../constants/app_info.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final Widget? logoImage;

  const BrandLogo({super.key, this.size = 64, this.logoImage});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF0875E1),
        borderRadius: BorderRadius.circular(size * 0.22),
      ),
      alignment: Alignment.center,
      child:
          logoImage ??
          Text(
            appName,
            style: TextStyle(
              color: Colors.white,
              fontSize: size * 0.31,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.5,
            ),
          ),
    );
  }
}
