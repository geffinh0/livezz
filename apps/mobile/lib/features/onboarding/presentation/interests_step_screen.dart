import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_choice_chips.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../auth/presentation/auth_widgets.dart';
import '../application/onboarding_flow.dart';
import '../data/profile_api.dart';
import 'onboarding_widgets.dart';

final _interestsProvider = FutureProvider.autoDispose<List<Interest>>(
  (ref) => ref.read(onboardingFlowProvider).interests(),
  retry: (retryCount, error) => null,
);

/// ENT12: categorias do servidor; até 10; pular permitido.
class InterestsStepScreen extends ConsumerStatefulWidget {
  const InterestsStepScreen({super.key});
  @override
  ConsumerState<InterestsStepScreen> createState() =>
      _InterestsStepScreenState();
}

class _InterestsStepScreenState extends ConsumerState<InterestsStepScreen> {
  static const max = 10;
  final _selected = <String>{};
  bool _busy = false;
  String? _error;

  Future<void> _save(List<String> ids) async {
    final l = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(onboardingFlowProvider).setInterests(ids);
    } on Object catch (e) {
      if (!mounted) return;
      setState(() => _error = authErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final items = ref.watch(_interestsProvider);
    return OnboardingScaffold(
      id: 'onboarding.interests',
      title: l.onboardingInterestsTitle,
      step: 3,
      children: [
        Text(l.interestsIntro),
        const SizedBox(height: AppSpace.lg),
        switch (items) {
          AsyncData(:final value) when value.isEmpty => StateView.empty(
            title: l.interestsEmptyTitle,
            message: l.interestsEmptyBody,
          ),
          AsyncData(:final value) => AppChoiceChips<Interest>(
            options: value,
            selected: {
              for (final i in value)
                if (_selected.contains(i.id)) i,
            },
            labelOf: (i) => i.name,
            idOf: (i) => 'onboarding.interests.${i.id}',
            max: max,
            onToggle: (i) => setState(() {
              if (!_selected.remove(i.id)) _selected.add(i.id);
            }),
          ),
          AsyncError(:final error) => StateView.forFailure(
            context,
            error,
            onRetry: () => ref.invalidate(_interestsProvider),
          ),
          _ => const StateView.loading(),
        },
        if (_selected.length >= max) ...[
          const SizedBox(height: AppSpace.sm),
          Text(l.interestsLimit, style: Theme.of(context).textTheme.bodySmall),
        ],
        AuthError(_error),
        const SizedBox(height: AppSpace.xl),
        TestId(
          'onboarding.interests.submit',
          child: AppButton(
            label: l.actionContinue,
            loading: _busy,
            onPressed: _selected.isEmpty
                ? null
                : () => _save(_selected.toList()),
          ),
        ),
        TestId(
          'onboarding.interests.skip',
          child: AppButton(
            label: l.actionSkip,
            variant: AppButtonVariant.text,
            onPressed: _busy ? null : () => _save(const []),
          ),
        ),
      ],
    );
  }
}
