import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/app/providers.dart';
import 'package:livezz_mobile/core/config/application/config_controller.dart';
import 'package:livezz_mobile/core/config/data/config_repository.dart';
import 'package:livezz_mobile/core/config/data/key_value_store.dart';
import 'package:livezz_mobile/core/http/api_client.dart';
import 'package:livezz_mobile/core/tenant/tenant.generated.dart';
import 'package:livezz_mobile/core/theme/app_theme.dart';
import 'package:livezz_mobile/l10n/generated/app_localizations.dart';
import 'package:material_ui/material_ui.dart';

Map<String, dynamic> sampleConfig({
  int version = 1,
  bool maintenance = false,
  String minAppVersion = '0.1.0',
}) => {
  'configVersion': version,
  'minAppVersion': minAppVersion,
  'maintenance': {
    'active': maintenance,
    'retryAfterSeconds': maintenance ? 300 : null,
  },
  'flags': {'pk': true},
  'limits': {'chatMaxLength': 200},
  'discoverTabs': ['popular'],
  'legalTexts': <String, Object>{},
  'allowedRegions': ['BR'],
};

/// Adaptador HTTP falso: devolve o que [respond] mandar.
class StubAdapter implements HttpClientAdapter {
  StubAdapter(this.respond);
  ResponseBody Function(RequestOptions o) respond;

  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async => respond(o);

  @override
  void close({bool force = false}) {}
}

ResponseBody jsonBody(
  int status,
  Object body, {
  Map<String, List<String>>? h,
}) => ResponseBody.fromString(
  jsonEncode(body),
  status,
  headers: {
    Headers.contentTypeHeader: [Headers.jsonContentType],
    ...?h,
  },
);

List<Override> testOverrides(StubAdapter adapter) => [
  apiClientProvider.overrideWith(
    (ref) => ApiClient(
      apiBaseUrl: 'http://test',
      appVersion: '0.1.0',
      language: () => 'pt-BR',
      onGate: (g) => ref.read(appGateProvider.notifier).set(g),
      adapter: adapter,
    ),
  ),
  configRepositoryProvider.overrideWith(
    (ref) => ConfigRepository(ref.watch(apiClientProvider), MemoryStore()),
  ),
];

/// Monta uma tela com tema, idioma e direção escolhidos.
Widget harness(
  Widget home, {
  List<Override> overrides = const [],
  Locale locale = const Locale('pt'),
  ThemeMode mode = ThemeMode.light,
  TextDirection? direction,
  double textScale = 1,
}) {
  final theme = AppTheme(generatedTenant);
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: mode,
      locale: locale,
      supportedLocales: const [Locale('pt'), Locale('en')],
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context)
            .copyWith(textScaler: TextScaler.linear(textScale)),
        child: direction == null
            ? child!
            : Directionality(textDirection: direction, child: child!),
      ),
      home: home,
    ),
  );
}
