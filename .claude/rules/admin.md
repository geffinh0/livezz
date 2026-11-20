---
paths:
  - "apps/admin/**/*"
---

# Regras do painel admin (Next.js)

- Next.js (App Router) + TypeScript estrito. Consome `/v1/admin/*` do contrato; nada de acesso direto a dados.
- O painel é onde o comprador configura **tudo** que é configurável (economia, progressão, VIP, diretrizes, detecção, flags, integrações). Ao criar uma regra ou provedor novo no servidor, crie também a tela de configuração correspondente.
- Integrações (ADM19): credenciais só de escrita (nunca exibidas inteiras depois de salvas), botão de testar conexão, confirmação e auditoria.
- Toda tela respeita o papel do usuário (admin, moderador, financeiro, suporte); o servidor é quem decide, o painel só esconde o que não pode.
- Ações destrutivas ou financeiras (banir, ajustar saldo, aprovar saque, ligar flag com risco) exigem confirmação com resumo e motivo obrigatório.
- Ao ligar flag com 🚩, mostrar o aviso de avaliação jurídica (ADR 0006).
- Dados 🔒 sempre mascarados por padrão; revelar exige ação explícita (e gera auditoria no servidor).
- Tabelas com filtros, paginação e exportação CSV quando a especificação pedir.
- Acessível (teclado, contraste, rótulos). Textos em pt-BR.
- Antes de terminar: `npm run lint && npm test`.
