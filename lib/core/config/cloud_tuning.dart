import 'package:flutter/material.dart';

abstract final class CloudTuning {
  // Population and movement.
  static const int minCloudCount = 2;
  static const int maxCloudCount = 4;
  static const double minSpeed = 34;
  static const double maxSpeed = 78;

  // Overall cloud silhouette.
  static const double minWidth = 980;
  static const double maxWidth = 1320;
  static const double minHeightRatio = 0.34;
  static const double maxHeightRatio = 0.42;
  static const double collisionRadiusScale = 0.68;
  static const double blurSigmaScale = 0.05;

  // Lobe generation.
  static const int lobeTemplateCount = 6;
  static const double lobeCenterJitterX = 0.015;
  static const double lobeCenterJitterY = 0.012;
  static const double lobeSizeJitter = 0.06;

  // Cloud visibility and color treatment.
  static const double minOpacity = 0.14;
  static const double maxOpacity = 0.22;
  static const Color baseColor = Color(0xFF769BBB);
  static const Color overlayColor = Color(0xFF5E86AA);
  static const BlendMode baseBlendMode = BlendMode.multiply;
  static const BlendMode overlayBlendMode = BlendMode.overlay;
  static const double overlayOpacityFactor = 0.58;
}
