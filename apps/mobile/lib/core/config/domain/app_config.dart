import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_config.freezed.dart';

/// Config pública do app vinda do servidor (`GET /v1/config`, ConfigApp).
/// O servidor é autoritativo: flags e limites nunca são decididos no app.
@freezed
abstract class AppConfig with _$AppConfig {
  const AppConfig._();

  const factory AppConfig({
    required int configVersion,
    required String minAppVersion,
    required Maintenance maintenance,
    required Map<String, bool> flags,
    required Map<String, int> limits,
    required List<String> discoverTabs,
    required Map<String, LegalText> legalTexts,
    required List<String> allowedRegions,
  }) = _AppConfig;

  /// Flag ausente ou desconhecida = desligada (contrato).
  bool isEnabled(String flag) => flags[flag] ?? false;
}

@freezed
abstract class Maintenance with _$Maintenance {
  const factory Maintenance({required bool active, Duration? retryAfter}) =
      _Maintenance;
}

@freezed
abstract class LegalText with _$LegalText {
  const factory LegalText({required int version, required Uri url}) =
      _LegalText;
}
