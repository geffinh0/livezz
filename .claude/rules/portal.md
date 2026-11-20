---
paths:
  - "apps/portal/**/*"
---

# Regras do portal web do usuário (ADR 0008)

- Next.js + TypeScript estrito, responsivo para celular, marca do tenant, pt-BR e inglês, acessível.
- Páginas: saque, dados de recebimento, recarga, checkout e gestão de assinatura de criador, ganhos e comprovantes (POR01–POR07).
- Entrada pelo app só com link de uso único e curta duração trocado por sessão do portal (`POST /portal/session`). Link nunca vai para log, analytics ou URL de terceiros depois de usado.
- Pagamentos e saques: o portal nunca confirma valor sozinho. Confirmação vem do servidor via webhook do provedor; o portal apenas mostra o status.
- Dados 🔒 (CPF, chave Pix) mascarados após salvos; alteração exige reautenticação; páginas sensíveis sem cache.
- Proteções web: CSP restritiva, cookies `HttpOnly`/`Secure`/`SameSite`, proteção CSRF, sem scripts de terceiros além do provedor de pagamento configurado.
- Toda mudança aqui passa pelo `revisor-seguranca`.
- Antes de terminar: `npm run lint && npm test`.
