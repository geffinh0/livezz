import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/config/application/config_controller.dart';
import '../../../core/i18n/locales.dart';
import '../../../core/realtime/realtime_client.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_bottom_sheet.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_dialog.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/ui/test_id.dart';
import '../../../core/video/providers/fake/fake_video_view.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Vitrine da fundação (só debug): marca, tema, idioma, config, tempo real e
/// componentes. Alvo do E2E da Fase 0. Não é tela de produto.
class ShowcaseScreen extends ConsumerWidget {
  const ShowcaseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final tenant = ref.watch(tenantProvider);
    final config = ref.watch(configControllerProvider);
    final status =
        ref.watch(realtimeStatusProvider).value ?? RealtimeStatus.disconnected;
    final mode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    final statusText = switch (status) {
      RealtimeStatus.connected => l.realtimeConnected,
      RealtimeStatus.connecting => l.realtimeConnecting,
      RealtimeStatus.disconnected => l.realtimeDisconnected,
    };

    return Scaffold(
      appBar: AppBar(
        title: TestId(
          'showcase.appName',
          child: Text(
            l.appTitle(tenant.appName),
            key: const ValueKey('showcase.appName'),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpace.lg),
        children: [
          Text(l.showcaseTitle, style: t.headlineSmall),
          const SizedBox(height: AppSpace.md),
          if (config.value case final c?)
            TestId(
              'showcase.configVersion',
              child: Text(
                l.showcaseConfigVersion(c.configVersion),
                key: const ValueKey('showcase.configVersion'),
              ),
            ),
          TestId(
            'showcase.realtime.${status.name}',
            child: Semantics(
              liveRegion: true,
              child: Text(
                statusText,
                key: ValueKey('showcase.realtime.${status.name}'),
              ),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          Text(l.showcaseThemeLabel, style: t.titleMedium),
          const SizedBox(height: AppSpace.sm),
          SegmentedButton<ThemeMode>(
            key: const ValueKey('showcase.themeMode'),
            segments: [
              ButtonSegment(value: ThemeMode.light, label: Text(l.themeLight)),
              ButtonSegment(value: ThemeMode.dark, label: Text(l.themeDark)),
              ButtonSegment(
                value: ThemeMode.system,
                label: Text(l.themeSystem),
              ),
            ],
            selected: {mode},
            onSelectionChanged: (s) =>
                ref.read(themeModeProvider.notifier).set(s.first),
          ),
          const SizedBox(height: AppSpace.md),
          SegmentedButton<String>(
            key: const ValueKey('showcase.locale'),
            segments: [
              for (final tag in tenant.supportedLocales)
                ButtonSegment(
                  value: localeFromTag(tag).languageCode,
                  label: Text(tag),
                ),
            ],
            selected: {locale.languageCode},
            onSelectionChanged: (s) =>
                ref.read(localeProvider.notifier).set(Locale(s.first)),
          ),
          const SizedBox(height: AppSpace.xl),
          AppButton(
            key: const ValueKey('showcase.primary'),
            label: l.showcasePrimaryButton,
            icon: Symbols.videocam,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            key: const ValueKey('showcase.secondary'),
            label: l.showcaseSecondaryButton,
            variant: AppButtonVariant.secondary,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: l.showcaseDangerButton,
            variant: AppButtonVariant.danger,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpace.sm),
          AppButton(
            label: l.showcasePrimaryButton,
            loading: true,
            onPressed: () {},
          ),
          const SizedBox(height: AppSpace.lg),
          AppTextField(
            label: l.showcaseTextFieldLabel,
            helper: l.showcaseTextFieldHelp,
            maxLength: 40,
          ),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            spacing: AppSpace.sm,
            runSpacing: AppSpace.sm,
            children: [
              AppButton(
                key: const ValueKey('showcase.openSheet'),
                label: l.showcaseOpenSheet,
                variant: AppButtonVariant.text,
                onPressed: () => AppBottomSheet.show<void>(
                  context,
                  title: l.showcaseTitle,
                  builder: (_) => Text(l.showcaseSheetBody),
                ),
              ),
              AppButton(
                key: const ValueKey('showcase.openDialog'),
                label: l.showcaseOpenDialog,
                variant: AppButtonVariant.text,
                onPressed: () => AppDialog.confirm(
                  context,
                  title: l.showcaseTitle,
                  message: l.showcaseDialogBody,
                  destructive: true,
                ),
              ),
              AppButton(
                key: const ValueKey('showcase.toast'),
                label: l.showcaseToast,
                variant: AppButtonVariant.text,
                onPressed: () => AppToast.show(context, l.showcaseToastMessage),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.xl),
          AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: FakeVideoView(semanticsLabel: l.showcaseVideoLabel),
            ),
          ),
          const SizedBox(height: AppSpace.xl),
          const SizedBox(height: 240, child: StateView.empty()),
        ],
      ),
    );
  }
}
