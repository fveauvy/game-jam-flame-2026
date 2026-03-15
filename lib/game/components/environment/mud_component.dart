import 'dart:math';

import 'package:flame/components.dart';
import 'package:game_jam/core/config/asset_paths.dart';
import 'package:game_jam/game/my_game.dart';

enum MudAssetPosition {
  cornerBottomLeft,
  cornerBottomRight,
  cornerTopLeft,
  cornerTopRight,
  left,
  right,
  up,
  down,
  plain;

  static const List<String> mudPlainAssets = [
    AssetPaths.mudPlain1,
    AssetPaths.mudPlain2,
    AssetPaths.mudPlain3,
  ];

  String get assetPath => switch (this) {
    MudAssetPosition.cornerBottomLeft => AssetPaths.mudInvertedCornerBottomLeft,
    MudAssetPosition.cornerBottomRight =>
      AssetPaths.mudInvertedCornerBottomRight,
    MudAssetPosition.cornerTopLeft => AssetPaths.mudInvertedCornerTopLeft,
    MudAssetPosition.cornerTopRight => AssetPaths.mudInvertedCornerTopRight,
    MudAssetPosition.left => AssetPaths.mudLeft,
    MudAssetPosition.right => AssetPaths.mudRight,
    MudAssetPosition.up => AssetPaths.mudUp,
    MudAssetPosition.down => AssetPaths.mudDown,
    MudAssetPosition.plain =>
      mudPlainAssets[Random().nextInt(mudPlainAssets.length)],
  };
}

class MudComponent extends SpriteComponent with HasGameReference<MyGame> {
  final MudAssetPosition assetPosition;
  MudComponent({
    required super.position,
    required super.size,
    required this.assetPosition,
  }) : super(priority: 1);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    sprite = Sprite(game.images.fromCache(assetPosition.assetPath));
  }
}
