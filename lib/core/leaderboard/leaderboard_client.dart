import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:game_jam/core/config/leaderboard_config.dart';
import 'package:http/http.dart' as http;

class LeaderboardClient {
  const LeaderboardClient();

  Future<bool> submitScore({
    required String playerName,
    required int elapsedTimeInMs,
    String? seedCode,
  }) async {
    final String endpoint = LeaderboardConfig.submitUrl.trim();
    if (endpoint.isEmpty) {
      debugPrint('[leaderboard] skip submit: missing endpoint config');
      return false;
    }

    final String key = LeaderboardConfig.resolveSubmitKey();
    if (key.isEmpty) {
      debugPrint('[leaderboard] skip submit: missing auth config');
      return false;
    }

    final Uri? uri = Uri.tryParse(endpoint);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      debugPrint('[leaderboard] skip submit: invalid endpoint');
      return false;
    }

    final String method = String.fromCharCodes([80, 79, 83, 84]);
    final String authHeader = String.fromCharCodes([
      120,
      45,
      108,
      101,
      97,
      100,
      101,
      114,
      98,
      111,
      97,
      114,
      100,
      45,
      107,
      101,
      121,
    ]);

    final Map<String, Object> payload = <String, Object>{
      'name': playerName,
      'timeMs': elapsedTimeInMs,
    };
    final String normalizedSeed = (seedCode ?? '').trim();
    if (normalizedSeed.isNotEmpty) {
      payload['seed'] = normalizedSeed;
    }

    final http.Request request = http.Request(method, uri)
      ..headers['content-type'] = 'application/json'
      ..headers[authHeader] = key
      ..body = jsonEncode(payload);

    try {
      final http.StreamedResponse response = await request.send();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      }
      debugPrint('[leaderboard] submit failed: status=${response.statusCode}');
      return false;
    } catch (error) {
      debugPrint('[leaderboard] submit failed: $error');
      return false;
    }
  }
}
