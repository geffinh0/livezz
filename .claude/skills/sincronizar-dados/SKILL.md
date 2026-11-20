---
name: sincronizar-dados
description: Compara docs/DATABASE.md, docs/API.md e docs/EVENTOS-TEMPO-REAL.md com o código (modelos do app, DTOs, mock-server, fixtures) e corrige os documentos.
---

1. Peça ao subagente `guardiao-dados` o levantamento completo de divergências.
2. Para cada divergência:
   - código tem dado/endpoint/evento que o documento não tem → adicione ao documento (status correto, "Usada por", 🔒 se for dado pessoal, Histórico);
   - documento tem algo que o código já implementa diferente → descubra qual está certo pela especificação; se não der para saber, **pergunte**;
   - campo sem uso em nenhuma tela → pergunte se remove;
   - dado pessoal sem 🔒 ou sem regra de retenção → marque e registre em `docs/QUESTOES-ABERTAS.md` se faltar decisão.
3. Atualize os status (`proposta` / `em uso no mock` / `validada`) e o Histórico do DATABASE.md.
4. Mostre um resumo: o que foi adicionado, corrigido, removido e o que ficou pendente de resposta.
