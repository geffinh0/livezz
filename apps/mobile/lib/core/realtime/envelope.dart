import 'dart:convert';

/// Envelope versionado (ADR 0005): `{ v, id, type, ts, data }`.
class Envelope {
  const Envelope({
    required this.v,
    required this.id,
    required this.type,
    required this.ts,
    required this.data,
  });

  static const supportedVersion = 1;

  final int v;
  final String id;
  final String type;
  final DateTime ts;
  final Map<String, dynamic> data;

  /// Retorna null para mensagem fora do formato (é ignorada com log).
  static Envelope? tryParse(Object? raw) {
    if (raw is! String) return null;
    final Object? json;
    try {
      json = jsonDecode(raw);
    } on FormatException {
      return null;
    }
    if (json is! Map<String, dynamic>) return null;
    final v = json['v'];
    final id = json['id'];
    final type = json['type'];
    final ts = DateTime.tryParse(json['ts'] as String? ?? '');
    final data = json['data'];
    if (v is! int || id is! String || type is! String || ts == null) {
      return null;
    }
    return Envelope(
      v: v,
      id: id,
      type: type,
      ts: ts,
      data: data is Map<String, dynamic> ? data : const {},
    );
  }

  static String encode(String id, String type, Map<String, Object?> data) =>
      jsonEncode({
        'v': supportedVersion,
        'id': id,
        'type': type,
        'ts': DateTime.now().toUtc().toIso8601String(),
        'data': data,
      });
}
