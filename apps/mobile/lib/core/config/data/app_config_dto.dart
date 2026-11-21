import 'package:json_annotation/json_annotation.dart';

import '../domain/app_config.dart';

part 'app_config_dto.g.dart';

/// DTO de `GET /v1/config` (docs/API.md). Converte para a entidade.
@JsonSerializable(createToJson: false)
class AppConfigDto {
  const AppConfigDto({
    required this.configVersion,
    required this.minAppVersion,
    required this.maintenance,
    this.flags = const {},
    this.limits = const {},
    this.discoverTabs = const [],
    this.legalTexts = const {},
    this.allowedRegions = const [],
  });

  factory AppConfigDto.fromJson(Map<String, dynamic> json) =>
      _$AppConfigDtoFromJson(json);

  final int configVersion;
  final String minAppVersion;
  final MaintenanceDto maintenance;
  final Map<String, bool> flags;
  final Map<String, int> limits;
  final List<String> discoverTabs;
  final Map<String, LegalTextDto> legalTexts;
  final List<String> allowedRegions;

  AppConfig toEntity() => AppConfig(
    configVersion: configVersion,
    minAppVersion: minAppVersion,
    maintenance: Maintenance(
      active: maintenance.active,
      retryAfter: maintenance.retryAfterSeconds == null
          ? null
          : Duration(seconds: maintenance.retryAfterSeconds!),
    ),
    flags: Map.unmodifiable(flags),
    limits: Map.unmodifiable(limits),
    discoverTabs: List.unmodifiable(discoverTabs),
    legalTexts: Map.unmodifiable({
      for (final e in legalTexts.entries)
        e.key: LegalText(version: e.value.version, url: Uri.parse(e.value.url)),
    }),
    allowedRegions: List.unmodifiable(allowedRegions),
  );
}

@JsonSerializable(createToJson: false)
class MaintenanceDto {
  const MaintenanceDto({required this.active, this.retryAfterSeconds});
  factory MaintenanceDto.fromJson(Map<String, dynamic> json) =>
      _$MaintenanceDtoFromJson(json);
  final bool active;
  final int? retryAfterSeconds;
}

@JsonSerializable(createToJson: false)
class LegalTextDto {
  const LegalTextDto({required this.version, required this.url});
  factory LegalTextDto.fromJson(Map<String, dynamic> json) =>
      _$LegalTextDtoFromJson(json);
  final int version;
  final String url;
}

/// Aplica um `config.updated` parcial sobre o JSON completo mais recente.
/// Campos de topo são substituídos; `flags` e `limits` são mesclados por chave.
Map<String, dynamic> mergeConfigJson(
  Map<String, dynamic> current,
  Map<String, dynamic> partial,
) {
  final out = Map<String, dynamic>.of(current);
  for (final e in partial.entries) {
    if ((e.key == 'flags' || e.key == 'limits') &&
        e.value is Map &&
        out[e.key] is Map) {
      out[e.key] = {
        ...(out[e.key] as Map).cast<String, dynamic>(),
        ...(e.value as Map).cast<String, dynamic>(),
      };
    } else {
      out[e.key] = e.value;
    }
  }
  return out;
}
