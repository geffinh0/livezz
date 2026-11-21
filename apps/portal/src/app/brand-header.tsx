import type { Messages } from '../lib/messages';

export function BrandHeader(props: {
  appName: string;
  primary: string;
  onPrimary: string;
  t: Messages;
  configVersion: number | null;
}) {
  const { appName, primary, onPrimary, t, configVersion } = props;
  return (
    <header>
      <p
        data-testid="brand"
        style={{
          display: 'inline-block',
          background: primary,
          color: onPrimary,
          padding: '4px 12px',
          borderRadius: 999,
          fontWeight: 700,
        }}
      >
        {appName}
      </p>
      <h1>{t.title}</h1>
      <p>{t.description}</p>
      <p data-testid="config">
        {configVersion === null ? t.apiOffline : `${t.configVersion}: ${configVersion}`}
      </p>
    </header>
  );
}
