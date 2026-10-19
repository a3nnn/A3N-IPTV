import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'models.dart';

class XtreamException implements Exception {
  final String message;
  XtreamException(this.message);
  @override
  String toString() => message;
}

/// The logged-in session, shared across screens.
class Session {
  static XtreamApi? api;
  static AccountInfo? account;
}

class XtreamApi {
  final String host;
  final String username;
  final String password;

  XtreamApi({required String host, required this.username, required this.password})
      : host = _normalize(host);

  static String _normalize(String h) {
    var x = h.trim();
    while (x.endsWith('/')) {
      x = x.substring(0, x.length - 1);
    }
    if (!x.startsWith('http://') && !x.startsWith('https://')) x = 'http://$x';
    return x;
  }

  String get _u => Uri.encodeComponent(username);
  String get _p => Uri.encodeComponent(password);

  Future<dynamic> _get(Map<String, String> extra) async {
    final uri = Uri.parse('$host/player_api.php').replace(queryParameters: {
      'username': username,
      'password': password,
      ...extra,
    });
    http.Response res;
    try {
      res = await http
          .get(uri, headers: {'User-Agent': AppConfig.userAgent})
          .timeout(const Duration(seconds: 40));
    } catch (_) {
      throw XtreamException('Could not reach the server. Check your internet connection.');
    }
    if (res.statusCode == 401 || res.statusCode == 403) {
      throw XtreamException('Access denied by the server (${res.statusCode}).');
    }
    if (res.statusCode != 200) {
      throw XtreamException('Server error (${res.statusCode}).');
    }
    try {
      return jsonDecode(utf8.decode(res.bodyBytes, allowMalformed: true));
    } catch (_) {
      throw XtreamException('Unexpected response from the server.');
    }
  }

  Future<List<Map<String, dynamic>>> _list(String action, [Map<String, String> extra = const {}]) async {
    final data = await _get({'action': action, ...extra});
    if (data is List) {
      return data.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }
    return [];
  }

  Future<AccountInfo> login() async {
    final data = await _get(const {});
    if (data is! Map) throw XtreamException('Unexpected response from the server.');
    final ui = data['user_info'];
    if (ui is! Map || '${ui['auth']}' != '1') {
      throw XtreamException('Wrong username or password.');
    }
    final info = AccountInfo.fromJson(Map<String, dynamic>.from(ui));
    if (info.status.isNotEmpty && info.status.toLowerCase() != 'active') {
      throw XtreamException('Subscription status: ${info.status}');
    }
    return info;
  }

  Future<List<Category>> liveCategories() async =>
      (await _list('get_live_categories')).map(Category.fromJson).toList();

  Future<List<LiveChannel>> liveStreams() async =>
      (await _list('get_live_streams')).map(LiveChannel.fromJson).toList();

  Future<List<Category>> vodCategories() async =>
      (await _list('get_vod_categories')).map(Category.fromJson).toList();

  Future<List<Movie>> vodStreams() async =>
      (await _list('get_vod_streams')).map(Movie.fromJson).toList();

  Future<List<Category>> seriesCategories() async =>
      (await _list('get_series_categories')).map(Category.fromJson).toList();

  Future<List<Series>> series() async =>
      (await _list('get_series')).map(Series.fromJson).toList();

  Future<SeriesInfo> seriesInfo(int seriesId) async =>
      SeriesInfo.fromJson(await _get({'action': 'get_series_info', 'series_id': '$seriesId'}));

  Future<List<EpgEntry>> shortEpg(int streamId, {int limit = 10}) async {
    final data = await _get({
      'action': 'get_short_epg',
      'stream_id': '$streamId',
      'limit': '$limit',
    });
    if (data is Map && data['epg_listings'] is List) {
      final list = (data['epg_listings'] as List)
          .whereType<Map>()
          .map((e) => EpgEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      list.sort((a, b) => a.start.compareTo(b.start));
      return list;
    }
    return [];
  }

  String liveUrl(LiveChannel c) => '$host/live/$_u/$_p/${c.id}.${AppConfig.liveFormat}';
  String movieUrl(Movie m) => '$host/movie/$_u/$_p/${m.id}.${m.ext}';
  String episodeUrl(Episode e) => '$host/series/$_u/$_p/${e.id}.${e.ext}';
}
