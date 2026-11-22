import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/auth/session.dart';
import '../core/config/application/config_controller.dart';
import '../core/i18n/locales.dart';
import '../core/theme/app_theme.dart';
import '../features/entry/application/entry_providers.dart';
import '../features/onboarding/application/onboarding_flow.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'router.dart';

class LivezzApp extends ConsumerStatefulWidget {
  const LivezzApp({super.key});

  @override
  ConsumerState<LivezzApp> createState() => _LivezzAppState();
}

class _LivezzAppState extends ConsumerState<LivezzApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    // ADR 0011: ao voltar do segundo plano, rebusca a config.
    _lifecycle = AppLifecycleListener(
      onResume: () =>
          unawaited(ref.read(configControllerProvider.notifier).refresh()),
    );
    // ENT01: registra/atualiza o aparelho a cada abertura, em segundo plano
    // (não bloqueia a abertura). A resposta também diz se o aparelho foi
    // marcado por bloqueio de menor (ENT10). Depois restaura a sessão.
    unawaited(ref.read(deviceRegistrationProvider.future));
    unawaited(ref.read(sessionProvider.notifier).restore());
    ref.read(realtimeClientProvider); // tempo real acompanha a sessão
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // CFG14: ao entrar numa conta, vale o idioma dela.
    ref.listen(sessionProvider, (prev, next) {
      // Entrou numa conta, ou o idioma da conta acabou de chegar (ex.: /me
      // depois de abrir sem rede).
      if (next == null) return;
      final sameUser = prev?.userId == next.userId;
      if (sameUser && (prev?.language != null || next.language == null)) return;
      unawaited(
        ref.read(onboardingFlowProvider).onAccountLanguage(next.language),
      );
    });
    final tenant = ref.watch(tenantProvider);
    final theme = AppTheme(tenant);
    return MaterialApp.router(
      onGenerateTitle: (ctx) =>
          AppLocalizations.of(ctx).appTitle(tenant.appName),
      theme: theme.light,
      darkTheme: theme.dark,
      themeMode: ref.watch(themeModeProvider),
      locale: ref.watch(localeProvider),
      supportedLocales: [
        for (final tag in tenant.supportedLocales) localeFromTag(tag),
      ],
      localizationsDelegates: [
        AppLocalizations.delegate,
        ...GlobalMaterialLocalizations.delegates,
      ],
      routerConfig: ref.watch(routerProvider),
    );
  }
}
