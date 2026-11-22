import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/providers.dart';
import '../../../core/http/app_gate.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_toast.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';

/// ENT10: menor de idade. Sem acesso ao app e sem "voltar e mudar a data";
/// mostra o e-mail de suporte do tenant e o protocolo para pedir revisão (Q-68).
class MinorBlockedScreen extends ConsumerWidget {
  const MinorBlockedScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final t = Theme.of(context).textTheme;
    final gate = ref.watch(appGateProvider);
    final protocol = gate is GateMinorBlocked ? gate.protocol : null;
    final email = ref.watch(tenantProvider).supportEmail;
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: TestId(
            'minor.blocked',
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsetsDirectional.all(AppSpace.xl),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Symbols.shield_person,
                        size: 56,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: AppSpace.lg),
                    Semantics(
                      header: true,
                      child: Text(
                        l.minorBlockedTitle,
                        style: t.headlineSmall,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: AppSpace.sm),
                    Text(
                      l.minorBlockedBody,
                      style: t.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpace.lg),
                    TestId(
                      'minor.blocked.support',
                      child: SelectableText(
                        l.minorBlockedReview(email),
                        style: t.bodyMedium,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    if (protocol != null) ...[
                      const SizedBox(height: AppSpace.md),
                      TestId(
                        'minor.blocked.protocol',
                        child: SelectableText(
                          l.minorBlockedProtocol(protocol),
                          style: t.titleMedium,
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      TestId(
                        'minor.blocked.copy',
                        child: AppButton(
                          label: l.minorBlockedCopy,
                          variant: AppButtonVariant.secondary,
                          onPressed: () async {
                            await Clipboard.setData(
                              ClipboardData(text: protocol),
                            );
                            if (context.mounted) {
                              AppToast.show(context, l.minorBlockedCopied);
                            }
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
