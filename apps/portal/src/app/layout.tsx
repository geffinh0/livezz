import type { ReactNode } from 'react';
import { tenant } from '../tenant.generated';

export const metadata = { title: tenant.appName };

export default function RootLayout({ children }: { children: ReactNode }) {
  return (
    <html lang={tenant.defaultLocale}>
      <body
        style={{
          margin: 0,
          padding: 24,
          fontFamily: `'${tenant.theme.fontFamily}', system-ui, sans-serif`,
          background: tenant.theme.lightBackground,
        }}
      >
        {children}
      </body>
    </html>
  );
}
