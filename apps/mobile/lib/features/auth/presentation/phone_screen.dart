import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../app/routes.dart';
import '../../../core/config/application/config_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/app_button.dart';
import '../../../core/ui/app_text_field.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../application/auth_flow.dart';
import '../domain/phone.dart';
import 'auth_widgets.dart';
import 'code_screen.dart';

/// ENT04: telefone (país pela config, máscara) e canal SMS/WhatsApp.
class PhoneScreen extends ConsumerStatefulWidget {
  const PhoneScreen({super.key});
  @override
  ConsumerState<PhoneScreen> createState() => _PhoneScreenState();
}

class _PhoneScreenState extends ConsumerState<PhoneScreen> {
  final _ctrl = TextEditingController();
  Country? _country;
  String _channel = 'sms';
  bool _busy = false;
  String? _error;
  String? _fieldError;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _send(Country c) async {
    final l = AppLocalizations.of(context);
    final e164 = toE164(c, _ctrl.text);
    if (e164 == null) {
      setState(() => _fieldError = l.phoneInvalid);
      return;
    }
    setState(() {
      _fieldError = null;
      _busy = true;
      _error = null;
    });
    try {
      final r = await ref
          .read(authFlowProvider)
          .sendCode(channel: _channel, destination: e164, purpose: 'login');
      if (!mounted) return;
      unawaited(
        context.push(
          Routes.entryCode,
          extra: CodeArgs(
            destination: e164,
            channel: _channel,
            purpose: 'login',
            expiresIn: r.expiresIn,
            resendIn: r.resendIn,
          ),
        ),
      );
    } on Object catch (e) {
      setState(() => _error = authErrorText(l, e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final config = ref.watch(configControllerProvider).value;
    final countries = countriesFor(config?.allowedRegions ?? const ['BR']);
    final country =
        _country ??
        (countries.isEmpty ? knownCountries.first : countries.first);
    final channels = [
      if (config?.isEnabled('loginSms') ?? false) 'sms',
      if (config?.isEnabled('loginWhatsapp') ?? false) 'whatsapp',
    ];
    if (channels.isNotEmpty && !channels.contains(_channel)) {
      _channel = channels.first;
    }
    return AuthScaffold(
      id: 'auth.phone',
      title: l.methodPhone,
      children: [
        Text(l.phoneTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: AppSpace.lg),
        Row(
          children: [
            DropdownButton<Country>(
              value: country,
              items: [
                for (final c in countries)
                  DropdownMenuItem(
                    value: c,
                    child: Text(l.countryOption(c.iso, c.dialCode)),
                  ),
              ],
              onChanged: (c) => setState(() => _country = c),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: TestId(
                'auth.phone.input',
                child: AppTextField(
                  label: l.phoneLabel,
                  controller: _ctrl,
                  keyboardType: TextInputType.phone,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.telephoneNumberNational],
                  showCounter: false,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    _MaskFormatter(country.mask),
                  ],
                  hint: country.mask.replaceAll('#', '0'),
                  error: _fieldError,
                  onChanged: (_) {
                    if (_fieldError != null) setState(() => _fieldError = null);
                  },
                  onSubmitted: (_) => _send(country),
                ),
              ),
            ),
          ],
        ),
        if (channels.length > 1) ...[
          const SizedBox(height: AppSpace.lg),
          SegmentedButton<String>(
            segments: [
              ButtonSegment(value: 'sms', label: Text(l.channelSms)),
              ButtonSegment(value: 'whatsapp', label: Text(l.channelWhatsapp)),
            ],
            selected: {_channel},
            onSelectionChanged: (s) => setState(() => _channel = s.first),
          ),
        ],
        AuthError(_error),
        const SizedBox(height: AppSpace.xl),
        TestId(
          'auth.phone.send',
          child: AppButton(
            label: l.actionSendCode,
            loading: _busy,
            onPressed: channels.isEmpty ? null : () => _send(country),
          ),
        ),
      ],
    );
  }
}

class _MaskFormatter extends TextInputFormatter {
  _MaskFormatter(this.mask);
  final String mask;
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = applyMask(newValue.text, mask);
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
