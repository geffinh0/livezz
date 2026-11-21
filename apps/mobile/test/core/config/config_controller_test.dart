import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/core/config/application/config_controller.dart';
import 'package:livezz_mobile/core/config/data/config_repository.dart';
import 'package:livezz_mobile/core/config/data/key_value_store.dart';
import 'package:livezz_mobile/core/errors/app_failure.dart';
import 'package:livezz_mobile/core/http/api_client.dart';

Map<String, dynamic> cfg({int version = 1, bool lucky = false}) => {
  'configVersion': version,
  'minAppVersion': '0.1.0',
  'maintenance': {'active': false, 'retryAfterSeconds': null},
  'flags': {'pk': true, 'luckyGift': lucky},
  'limits': {'chatMaxLength': 200},
  'discoverTabs': ['popular'],
  'legalTexts': {
    'terms': {'version': 1, 'url': 'http://localhost:3002/legal/termos'},
  },
  'allowedRegions': ['BR'],
};

class Adapter implements HttpClientAdapter {
  Object Function() next = cfg;
  int calls = 0;
  @override
  Future<ResponseBody> fetch(
    RequestOptions o,
    Stream<Uint8List>? s,
    Future<void>? c,
  ) async {
    calls++;
    final r = next();
    if (r is DioExceptionType) throw DioException(requestOptions: o, type: r);
    return ResponseBody.fromString(
      jsonEncode(r),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  late Adapter adapter;
  late MemoryStore store;
  late ProviderContainer container;

  ProviderContainer make() {
    final api = ApiClient(
      apiBaseUrl: 'http://x',
      appVersion: '0.1.0',
      language: () => 'pt-BR',
      onGate: (_) {},
      adapter: adapter,
    );
    return ProviderContainer(
      overrides: [
        configRepositoryProvider.overrideWithValue(
          ConfigRepository(api, store),
        ),
      ],
    );
  }

  setUp(() {
    adapter = Adapter();
    store = MemoryStore();
    container = make();
  });
  tearDown(() => container.dispose());

  test('carrega do servidor e converte para a entidade', () async {
    final c = await container.read(configControllerProvider.future);
    expect(c.configVersion, 1);
    expect(c.isEnabled('pk'), isTrue);
    expect(c.isEnabled('luckyGift'), isFalse);
    expect(c.isEnabled('naoExiste'), isFalse);
    expect(c.limits['chatMaxLength'], 200);
    expect(c.legalTexts['terms']?.url.path, '/legal/termos');
  });

  test('sem rede usa a última config válida do cache', () async {
    await container.read(configControllerProvider.future);
    container.dispose();
    adapter.next = () => DioExceptionType.connectionError;
    container = make();
    final c = await container.read(configControllerProvider.future);
    expect(c.configVersion, 1);
  });

  test('sem rede e sem cache: erro de rede', () async {
    adapter.next = () => DioExceptionType.connectionError;
    await expectLater(
      container.read(configControllerProvider.future),
      throwsA(isA<NetworkFailure>()),
    );
  });

  test(
    'config.updated com versão maior mescla flags e salva no cache',
    () async {
      await container.read(configControllerProvider.future);
      final ctrl = container.read(configControllerProvider.notifier);
      await ctrl.applyRemote({
        'configVersion': 2,
        'flags': {'luckyGift': true},
        'maintenance': {'active': true, 'retryAfterSeconds': 300},
      });
      final c = container.read(configControllerProvider).value!;
      expect(c.configVersion, 2);
      expect(c.isEnabled('luckyGift'), isTrue);
      expect(c.isEnabled('pk'), isTrue, reason: 'flags não citadas continuam');
      expect(c.maintenance.active, isTrue);
      expect(c.maintenance.retryAfter, const Duration(seconds: 300));
      final saved =
          jsonDecode(store.data.values.single) as Map<String, dynamic>;
      expect(saved['configVersion'], 2);
    },
  );

  test('config.updated com versão igual ou menor é ignorado', () async {
    await container.read(configControllerProvider.future);
    final ctrl = container.read(configControllerProvider.notifier);
    await ctrl.applyRemote({
      'configVersion': 1,
      'flags': {'pk': false},
    });
    expect(
      container.read(configControllerProvider).value!.isEnabled('pk'),
      isTrue,
    );
  });

  test('refresh pega versão nova; falha mantém a atual', () async {
    await container.read(configControllerProvider.future);
    final ctrl = container.read(configControllerProvider.notifier);
    adapter.next = () => cfg(version: 3, lucky: true);
    await ctrl.refresh();
    expect(container.read(configControllerProvider).value!.configVersion, 3);
    adapter.next = () => DioExceptionType.connectionError;
    await ctrl.refresh();
    expect(container.read(configControllerProvider).value!.configVersion, 3);
  });
}
