#!/usr/bin/env node
// Gera a configuração de marca do tenant para o app e os sites.
// Uso: node tools/tenant/generate.mjs [tenantId]   (padrão: liveapp)
// Saídas (não versionadas): apps/mobile/lib/core/tenant/tenant.generated.dart,
//                           apps/admin/src/tenant.generated.ts, apps/portal/src/tenant.generated.ts
import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'node:fs';
import { dirname, join, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';
import { validateTenant } from './schema.mjs';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..', '..');

export function loadTenant(id, baseDir = root) {
  const file = join(baseDir, 'tenants', id, 'tenant.json');
  const tenant = JSON.parse(readFileSync(file, 'utf8'));
  const errors = validateTenant(tenant, id);
  if (errors.length) throw new Error(`tenant ${id} inválido:\n- ${errors.join('\n- ')}`);
  return tenant;
}

const dartStr = (s) => `'${String(s).replace(/\\/g, '\\\\').replace(/'/g, "\\'").replace(/\$/g, '\\$')}'`;
const dartColor = (hex) => `Color(0xFF${hex.slice(1).toUpperCase()})`;

export function toDart(t) {
  const th = t.theme;
  return `// GERADO por tools/tenant/generate.mjs a partir de tenants/${t.id}/tenant.json. Não edite.
// ignore_for_file: type=lint
import 'dart:ui';

import 'tenant_config.dart';

const TenantConfig generatedTenant = TenantConfig(
  id: ${dartStr(t.id)},
  appName: ${dartStr(t.appName)},
  defaultApiBaseUrl: ${dartStr(t.apiBaseUrl)},
  portalBaseUrl: ${dartStr(t.portalBaseUrl)},
  supportEmail: ${dartStr(t.supportEmail)},
  defaultLocale: ${dartStr(t.defaultLocale)},
  supportedLocales: [${t.supportedLocales.map(dartStr).join(', ')}],
  themeModes: [${t.themeModes.map(dartStr).join(', ')}],
  fontFamily: ${dartStr(th.fontFamily)},
  colors: TenantColors(
    primary: ${dartColor(th.primary)},
    primaryAction: ${dartColor(th.primaryAction)},
    onPrimaryAction: ${dartColor(th.onPrimaryAction)},
    secondary: ${dartColor(th.secondary)},
    onSecondary: ${dartColor(th.onSecondary)},
    darkBackground: ${dartColor(th.darkBackground)},
    lightBackground: ${dartColor(th.lightBackground)},
  ),
);
`;
}

export function toTs(t) {
  const brand = {
    id: t.id,
    appName: t.appName,
    apiBaseUrl: t.apiBaseUrl,
    portalBaseUrl: t.portalBaseUrl,
    supportEmail: t.supportEmail,
    defaultLocale: t.defaultLocale,
    supportedLocales: t.supportedLocales,
    theme: t.theme,
  };
  return `// GERADO por tools/tenant/generate.mjs a partir de tenants/${t.id}/tenant.json. Não edite.\nexport const tenant = ${JSON.stringify(brand, null, 2)} as const;\n`;
}

function write(file, content) {
  mkdirSync(dirname(file), { recursive: true });
  writeFileSync(file, content);
  console.log(`gerado: ${file.replace(root + '/', '')}`);
}

if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const id = process.argv[2] ?? 'liveapp';
  try {
    const t = loadTenant(id);
    write(join(root, 'apps/mobile/lib/core/tenant/tenant.generated.dart'), toDart(t));
    for (const app of ['admin', 'portal']) {
      if (existsSync(join(root, 'apps', app))) write(join(root, 'apps', app, 'src/tenant.generated.ts'), toTs(t));
    }
  } catch (err) {
    console.error(err.message);
    process.exit(1);
  }
}
