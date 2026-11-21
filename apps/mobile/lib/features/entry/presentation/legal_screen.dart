import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../app/providers.dart';
import '../../../core/config/application/config_controller.dart';
import '../../../core/theme/tokens.dart';
import '../../../core/ui/state_views.dart';
import '../../../core/ui/test_id.dart';
import '../../../l10n/generated/app_localizations.dart';

/// Termos e política dentro do app (Q-46). A página vem do portal do tenant;
/// a navegação fica presa ao domínio do portal (outros links são bloqueados).
class LegalScreen extends ConsumerStatefulWidget {
  const LegalScreen({required this.doc, super.key});

  /// `terms`, `privacy` ou `guidelines` (chaves de `legalTexts`).
  final String doc;

  @override
  ConsumerState<LegalScreen> createState() => _LegalScreenState();
}

/// Só URLs do mesmo esquema e host do portal do tenant.
bool isAllowedLegalUrl(Uri? url, Uri portal) =>
    url != null &&
    url.scheme == portal.scheme &&
    url.host == portal.host &&
    url.port == portal.port;

class _LegalScreenState extends ConsumerState<LegalScreen> {
  WebViewController? _controller;
  bool _failed = false;
  bool _loading = true;

  late Uri? _url = ref
      .read(configControllerProvider)
      .value
      ?.legalTexts[widget.doc]
      ?.url;

  @override
  void initState() {
    super.initState();
    final url = _url;
    final portal = Uri.parse(ref.read(tenantProvider).portalBaseUrl);
    // Até a primeira URL passa pela trava do domínio do portal.
    if (url == null || !isAllowedLegalUrl(url, portal)) {
      _url = null;
      return;
    }
    // WebView não roda no build web de teste: lá mostramos o endereço.
    if (kIsWeb) return;
    _controller = WebViewController()
      // Páginas legais do portal são renderizadas no servidor: sem JavaScript.
      ..setJavaScriptMode(JavaScriptMode.disabled)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (r) =>
              isAllowedLegalUrl(Uri.tryParse(r.url), portal)
              ? NavigationDecision.navigate
              : NavigationDecision.prevent,
          onPageFinished: (_) => setState(() => _loading = false),
          onWebResourceError: (e) {
            if (e.isForMainFrame ?? true) setState(() => _failed = true);
          },
        ),
      )
      ..loadRequest(url);
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final url = _url;
    final title = switch (widget.doc) {
      'terms' => l.legalTerms,
      'privacy' => l.legalPrivacy,
      _ => l.legalGuidelines,
    };
    final Widget body;
    if (url == null) {
      body = StateView.empty(title: l.legalUnavailable);
    } else if (_failed) {
      body = StateView.offline(
        onRetry: () {
          setState(() {
            _failed = false;
            _loading = true;
          });
          _controller?.loadRequest(url);
        },
      );
    } else if (_controller == null) {
      body = Padding(
        padding: const EdgeInsets.all(AppSpace.xl),
        child: SelectableText(url.toString()),
      );
    } else {
      body = Stack(
        children: [
          WebViewWidget(controller: _controller!),
          if (_loading) const StateView.loading(),
        ],
      );
    }
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: TestId('legal.${widget.doc}', child: body),
    );
  }
}
