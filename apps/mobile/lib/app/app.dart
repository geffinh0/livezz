import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../core/config/application/config_controller.dart';
import '../core/i18n/locales.dart';
import '../core/theme/app_theme.dart';
import '../features/entry/application/entry_providers.dart';
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
    // ENT01: registro do aparelho em segundo plano (não bloqueia a abertura).
    unawaited(ref.read(deviceRegistrationProvider.future));
  }

  @override
  void dispose() {
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
