import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:game_jam/game/character/pools/character_pools_repository.dart';

typedef AssetStringLoader = Future<String> Function(String assetPath);

class JsonCharacterPoolsRepository implements CharacterPoolsRepository {
  JsonCharacterPoolsRepository({
    this.assetPath = _defaultAssetPath,
    AssetStringLoader? loader,
  }) : _loader = loader ?? rootBundle.loadString;

  static const String _defaultAssetPath = 'assets/data/character_pools.json';

  final String assetPath;
  final AssetStringLoader _loader;

  @override
  Future<CharacterPools> loadPools() async {
    final String source = await _loader(assetPath);
    final Object? decoded = jsonDecode(source);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Character pools JSON must be an object');
    }
    return _parse(decoded);
  }

  CharacterPools _parse(Map<String, dynamic> json) {
    final Object? namesRaw = json['names'];
    final Object? colorsRaw = json['colors'];
    if (namesRaw is! Map<String, dynamic>) {
      throw const FormatException('Missing or invalid "names" object');
    }
    if (colorsRaw is! List<dynamic>) {
      throw const FormatException('Missing or invalid "colors" list');
    }

    final List<String> adjectives = _readStringList(namesRaw['adjectives']);
    final List<String> nouns = _readStringList(namesRaw['nouns']);
    final List<String> batches = _readStringList(namesRaw['batches']);
    final List<CharacterColorPoolItem> colors = colorsRaw
        .map((Object? entry) {
          if (entry is! Map<String, dynamic>) {
            throw const FormatException('Color item must be an object');
          }
          final String id = _readRequiredString(entry['id']);
          final String hex = _readRequiredString(entry['hex']);
          return CharacterColorPoolItem(id: id, hex: hex);
        })
        .toList(growable: false);

    if (adjectives.isEmpty || nouns.isEmpty || colors.isEmpty) {
      throw const FormatException(
        'adjectives, nouns and colors must be non-empty',
      );
    }

    return CharacterPools(
      namePool: CharacterNamePool(
        adjectives: adjectives,
        nouns: nouns,
        batches: batches,
      ),
      colors: colors,
    );
  }

  List<String> _readStringList(Object? value) {
    if (value is! List<dynamic>) {
      throw const FormatException('Expected list of strings');
    }
    return value
        .map((Object? item) => _readRequiredString(item))
        .toList(growable: false);
  }

  String _readRequiredString(Object? value) {
    if (value is! String || value.trim().isEmpty) {
      throw const FormatException('Expected non-empty string');
    }
    return value;
  }
}
