/// Paginação por cursor (docs/API.md): `{ items: [...], nextCursor: "..." | null }`.
class Page<T> {
  const Page({required this.items, required this.nextCursor});

  factory Page.fromJson(
    Map<String, Object?> json,
    T Function(Map<String, Object?> item) parse,
  ) {
    final raw = json['items'];
    if (raw is! List) throw const FormatException('items ausente');
    return Page(
      items: [for (final i in raw) parse(i as Map<String, Object?>)],
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;
}
