import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import 'auth_widgets.dart';

/// ENT06 com contas de TESTE do mock (Q-53). O Google real entra na Fase 12
/// atrás do mesmo contrato (`POST /auth/google { idToken }`).
class GoogleTestScreen extends ConsumerStatefulWidget {
  const GoogleTestScreen({super.key});
  @override
  ConsumerState<GoogleTestScreen> createState() => _GoogleTestScreenState();
}

class _GoogleTestScreenState extends ConsumerState<GoogleTestScreen> {
  String? _error;
  bool _busy = false;

  static const accounts = [
    ('new', 'mock-google:google.novo@teste.local'),
    ('existing', 'mock-google:ana@teste.local'),
    ('failing', 'mock-google:erro'),
  ];

  Future<void> _pick(String idToken) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authFlowProvider).google(idToken);
    } on Object catch (e) {
      setState(() => _error = authErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    String label(String k) => switch (k) {
      'new' => l.googleTestNew,
      'existing' => l.googleTestExisting,
      _ => l.googleTestFailing,
    };
    return AuthScaffold(
      id: 'auth.google',
      title: l.methodGoogle,
      children: [
        // Contas simuladas só em build de desenvolvimento: em release, nada de
        // atalho de login falso (o Google real chega na Fase 12).
        Text(kDebugMode ? l.googleTestNotice : l.googleUnavailable),
        const SizedBox(height: AppSpace.lg),
        if (kDebugMode)
          for (final a in accounts)
            TestId(
              'auth.google.${a.$1}',
              child: ListTile(
                leading: const Icon(Symbols.account_circle),
                title: Text(label(a.$1)),
                enabled: !_busy,
                onTap: () => _pick(a.$2),
              ),
            ),
        TestId(
          'auth.google.cancel',
          child: ListTile(
            leading: const Icon(Symbols.close),
            title: Text(l.actionCancel),
            onTap: () => context.pop(),
          ),
        ),
        AuthError(_error),
      ],
    );
  }
}
