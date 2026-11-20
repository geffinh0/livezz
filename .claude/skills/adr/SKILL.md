---
name: adr
description: Registra uma decisão de arquitetura como ADR em docs/adr/. Use quando uma escolha técnica importante for feita ou mudada.
argument-hint: [decisão a registrar]
---

Registrar: $ARGUMENTS

1. Veja o maior número em `docs/adr/` e use o próximo.
2. Siga a estrutura de `docs/adr/0000-modelo.md`: contexto, pelo menos duas opções com prós e contras, decisão, consequências.
3. Se a decisão ainda não foi tomada pelo usuário, status `proposta` e pergunte.
4. Atualize `docs/ARQUITETURA.md` (e outros documentos afetados) citando a ADR.
5. Se substitui uma ADR antiga, marque a antiga como "substituída por NNNN".
