import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:livezz_mobile/app/providers.dart';
import 'package:livezz_mobile/core/config/application/config_controller.dart';
import 'package:livezz_mobile/core/http/app_gate.dart';

import '../../helpers/harness.dart';

void main() {
  test('bloqueio de menor (ENT10) volta depois de atualização obrigatória e manutenção', () async {
    var minVersion = '0.1.0';
    final c = ProviderContainer(
      overrides: testOverrides(
        StubAdapter(
          (o) => jsonBody(200, sampleConfig(minAppVersion: minVersion)),
        ),
      ),
    );
    addTearDown(c.dispose);
    final gate = c.read(appGateProvider.notifier);
    await c.read(configControllerProvider.future);

    gate.set(const GateMinorBlocked('P-1'));
    gate.set(const GateMaintenance(null));
    expect(c.read(appGateProvider), isA<GateMinorBlocked>());

    // Versão mínima sobe (atualização vence)…
    minVersion = '99.0.0';
    await c.read(configControllerProvider.notifier).refresh();
    expect(c.read(appGateProvider), isA<GateUpdateRequired>());
    // …e, com a versão em dia, volta o bloqueio — nunca a tela liberada.
    minVersion = '0.1.0';
    await c.read(configControllerProvider.notifier).refresh();
    expect(c.read(appGateProvider), isA<GateMinorBlocked>());
  });
}
