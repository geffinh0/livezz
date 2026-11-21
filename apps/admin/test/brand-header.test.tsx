import { cleanup, render, screen } from '@testing-library/react';
import { afterEach, describe, expect, it } from 'vitest';
import { BrandHeader } from '../src/app/brand-header';
import { messages, pickLocale } from '../src/lib/messages';
import { tenant } from '../src/tenant.generated';

afterEach(cleanup);

describe('esqueleto', () => {
  it('mostra a marca do tenant e a versão da config', () => {
    render(
      <BrandHeader
        appName={tenant.appName}
        primary={tenant.theme.primaryAction}
        onPrimary={tenant.theme.onPrimaryAction}
        t={messages['pt-BR']}
        configVersion={3}
      />,
    );
    expect(screen.getByTestId('brand').textContent).toBe('liveapp');
    expect(screen.getByTestId('config').textContent).toBe('Versão da config: 3');
  });

  it('avisa quando a API está fora', () => {
    render(<BrandHeader appName="x" primary="#000" onPrimary="#fff" t={messages.en} configVersion={null} />);
    expect(screen.getByTestId('config').textContent).toBe('Server unavailable right now.');
  });

  it('pt e en têm as mesmas chaves; idioma vem do Accept-Language', () => {
    expect(Object.keys(messages.en).sort()).toEqual(Object.keys(messages['pt-BR']).sort());
    expect(pickLocale('en-US,en;q=0.9', 'pt-BR')).toBe('en');
    expect(pickLocale(null, 'pt-BR')).toBe('pt-BR');
  });
});
