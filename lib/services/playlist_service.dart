import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;

import '../models/channel.dart';
import 'm3u_parser.dart';

/// Charge une playlist M3U depuis une URL distante ou depuis les assets locaux.
class PlaylistService {
  /// Télécharge et analyse une playlist M3U depuis une URL.
  static Future<List<Channel>> fetchFromUrl(String url) async {
    final response = await http
        .get(Uri.parse(url))
        .timeout(const Duration(seconds: 20));

    if (response.statusCode == 200) {
      return M3uParser.parse(response.body);
    }
    throw Exception('Échec du téléchargement (code ${response.statusCode}).');
  }

  /// Charge une playlist embarquée dans les assets (ex: assets/channels.m3u).
  static Future<List<Channel>> loadFromAsset(String assetPath) async {
    final content = await rootBundle.loadString(assetPath);
    return M3uParser.parse(content);
  }

  /// Analyse un contenu M3U collé directement (texte brut).
  static List<Channel> parseText(String text) => M3uParser.parse(text);
}
