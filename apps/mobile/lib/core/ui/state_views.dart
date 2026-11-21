import 'package:material_symbols_icons/symbols.dart';
import 'package:material_ui/material_ui.dart';

import '../../l10n/error_messages.dart';
import '../../l10n/generated/app_localizations.dart';
import '../errors/app_failure.dart';
import '../theme/tokens.dart';
import 'app_button.dart';

/// Estados de tela obrigatórios (Definição de pronto): carregando, vazio,
/// erro, sem conexão e sem permissão.
class StateView extends StatelessWidget {
  const StateView._({
    required this.kind,
    super.key,
    this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  const StateView.loading({Key? key})
    : this._(kind: StateKind.loading, key: key);

  const StateView.empty({
    Key? key,
    String? title,
    String? message,
    String? actionLabel,
    VoidCallback? onAction,
  }) : this._(
         kind: StateKind.empty,
         key: key,
         title: title,
         message: message,
         actionLabel: actionLabel,
         onAction: onAction,
       );

  const StateView.offline({Key? key, VoidCallback? onRetry})
    : this._(kind: StateKind.offline, key: key, onAction: onRetry);

  const StateView.noPermission({Key? key, VoidCallback? onOpenSettings})
    : this._(kind: StateKind.noPermission, key: key, onAction: onOpenSettings);

  const StateView.error({Key? key, String? message, VoidCallback? onRetry})
    : this._(
        kind: StateKind.error,
        key: key,
        message: message,
        onAction: onRetry,
      );

  /// Escolhe a view certa para uma falha (rede → sem conexão; API → texto
  /// do `error.code`).
  static Widget forFailure(
    BuildContext context,
    Object error, {
    VoidCallback? onRetry,
  }) {
    final l = AppLocalizations.of(context);
    return switch (error) {
      NetworkFailure() => StateView.offline(onRetry: onRetry),
      TimeoutFailure() => StateView.error(
        message: l.errorTimeout,
        onRetry: onRetry,
      ),
      ApiFailure(:final code) => StateView.error(
        message: errorMessageFor(l, code),
        onRetry: onRetry,
      ),
      _ => StateView.error(message: l.errorUnknown, onRetry: onRetry),
    };
  }

  final StateKind kind;
  final String? title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final theme = Theme.of(context);
    if (kind == StateKind.loading) {
      return Center(
        key: const ValueKey('state.loading'),
        child: Semantics(
          label: l.stateLoading,
          child: const CircularProgressIndicator(),
        ),
      );
    }
    final (icon, defaultTitle, defaultMessage, defaultAction) = switch (kind) {
      StateKind.empty => (Symbols.inbox, l.stateEmptyTitle, null, null),
      StateKind.offline => (
        Symbols.wifi_off,
        l.stateOfflineTitle,
        l.stateOfflineBody,
        l.actionRetry,
      ),
      StateKind.noPermission => (
        Symbols.lock,
        l.stateNoPermissionTitle,
        l.stateNoPermissionBody,
        l.actionOpenSettings,
      ),
      _ => (Symbols.error, l.stateErrorTitle, l.errorUnknown, l.actionRetry),
    };
    final label = actionLabel ?? defaultAction;
    return Center(
      key: ValueKey('state.${kind.name}'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: AppSpace.lg),
            Text(
              title ?? defaultTitle,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            if ((message ?? defaultMessage) != null) ...[
              const SizedBox(height: AppSpace.sm),
              Text(
                message ?? defaultMessage!,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
            if (onAction != null && label != null) ...[
              const SizedBox(height: AppSpace.xl),
              AppButton(
                key: ValueKey('state.${kind.name}.action'),
                label: label,
                onPressed: onAction,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

enum StateKind { loading, empty, error, offline, noPermission }
