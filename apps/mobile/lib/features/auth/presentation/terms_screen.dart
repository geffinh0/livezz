import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/auth/session.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import 'auth_widgets.dart';

/// ENT16: aceite com versão; nova versão exige novo aceite antes de continuar.
class TermsScreen extends ConsumerStatefulWidget {
  const TermsScreen({super.key});
  @override
  ConsumerState<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends ConsumerState<TermsScreen> {
  bool _agreed = false;
  bool _busy = false;
  String? _error;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final pending = ref.watch(sessionProvider)?.pendingTerms ?? const [];
    String docName(String d) => switch (d) {
      'terms' => l.legalTerms,
      'privacy' => l.legalPrivacy,
      _ => l.legalGuidelines,
    };
    return PopScope(
      canPop: false,
      child: AuthScaffold(
        id: 'auth.terms',
        title: l.termsTitle,
        children: [
          Text(l.termsIntro),
          const SizedBox(height: AppSpace.lg),
          for (final t in pending)
            TestId(
              'auth.terms.doc.${t.document}',
              child: ListTile(
                title: Text(docName(t.document)),
                subtitle: Text(l.termsVersion(t.version)),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.push(Routes.legal(t.document)),
              ),
            ),
          TestId(
            'auth.terms.agree',
            child: CheckboxListTile(
              value: _agreed,
              onChanged: (v) => setState(() => _agreed = v ?? false),
              title: Text(l.termsAgree),
              controlAffinity: ListTileControlAffinity.leading,
            ),
          ),
          AuthError(_error),
          const SizedBox(height: AppSpace.xl),
          TestId(
            'auth.terms.accept',
            child: AppButton(
              label: l.termsAccept,
              loading: _busy,
              onPressed: !_agreed
                  ? null
                  : () async {
                      setState(() {
                        _busy = true;
                        _error = null;
                      });
                      try {
                        await ref.read(authFlowProvider).acceptTerms(pending);
                      } on Object catch (e) {
                        setState(() => _error = authErrorText(l, e));
                      } finally {
                        if (mounted) setState(() => _busy = false);
                      }
                    },
            ),
          ),
          TestId(
            'auth.terms.signout',
            child: AppButton(
              label: l.actionSignOut,
              variant: AppButtonVariant.text,
              onPressed: () => ref.read(sessionProvider.notifier).signOut(),
            ),
          ),
        ],
      ),
    );
  }
}
