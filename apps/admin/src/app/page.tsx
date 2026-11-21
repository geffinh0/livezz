import { headers } from 'next/headers';
import { fetchConfig } from '../lib/api';
import { messages, pickLocale } from '../lib/messages';
import { tenant } from '../tenant.generated';
import { BrandHeader } from './brand-header';

export const dynamic = 'force-dynamic';

export default async function Home() {
  const locale = pickLocale((await headers()).get('accept-language'), tenant.defaultLocale);
  const config = await fetchConfig(locale);
  return (
    <main>
      <BrandHeader
        appName={tenant.appName}
        primary={tenant.theme.primaryAction}
        onPrimary={tenant.theme.onPrimaryAction}
        t={messages[locale]}
        configVersion={config?.configVersion ?? null}
      />
    </main>
  );
}
