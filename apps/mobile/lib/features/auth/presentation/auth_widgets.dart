import 'package:material_ui/material_ui.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/error_messages.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Texto humano para qualquer falha das telas de login.
String authErrorText(AppLocalizations l, Object e) => switch (e) {
  ApiFailure(:final code) => errorMessageFor(l, code),
  NetworkFailure() => l.errorNetwork,
  TimeoutFailure() => l.errorTimeout,
  _ => l.errorUnknown,
};

/// Mensagem de erro anunciada pelo leitor de tela.
class AuthError extends StatelessWidget {
  const AuthError(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return TestId(
      'auth.error',
      child: Semantics(
        liveRegion: true,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(top: AppSpace.md),
          child: Text(message!, style: TextStyle(color: scheme.error)),
        ),
      ),
    );
  }
}

/// Esqueleto comum das telas de login: título, conteúdo rolável.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    required this.id,
    required this.title,
    required this.children,
    super.key,
  });
  final String id;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: Text(title)),
    body: SafeArea(
      child: TestId(
        id,
        child: ListView(
          padding: const EdgeInsets.all(AppSpace.xl),
          children: children,
        ),
      ),
    ),
  );
}
