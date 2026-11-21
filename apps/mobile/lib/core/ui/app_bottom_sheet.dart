import 'package:material_ui/material_ui.dart';

import '../theme/tokens.dart';

/// Bottom sheet padrão: fluxos secundários da live abrem aqui, sem tirar o
/// usuário do vídeo. Arrastar para fechar; altura adaptável.
abstract final class AppBottomSheet {
  static Future<T?> show<T>(
    BuildContext context, {
    required WidgetBuilder builder,
    String? title,
  }) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => Padding(
      padding: EdgeInsetsDirectional.only(
        start: AppSpace.lg,
        end: AppSpace.lg,
        bottom: MediaQuery.viewInsetsOf(ctx).bottom + AppSpace.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsetsDirectional.only(bottom: AppSpace.md),
              child: Text(title, style: Theme.of(ctx).textTheme.titleLarge),
            ),
          Builder(builder: builder),
        ],
      ),
    ),
  );
}
