# Referências de mercado: como usar

`relatorio-concorrente.md` é uma análise estática de um app concorrente. Ele serve para **entender o domínio**: que telas um produto maduro tem, quais eventos em tempo real existem, quais regras de negócio aparecem, quais riscos existem.

## Regras obrigatórias
1. **Nunca copie** nomes de endpoints, nomes de eventos, nomes de classes, arquivos `.proto`, textos, assets, cores, fontes ou layout do concorrente. Nossos contratos estão em `docs/API.md` e `docs/EVENTOS-TEMPO-REAL.md`, com nomes próprios.
2. Use o relatório para **perguntar "esquecemos algo?"**, nunca para decidir "como fazer".
3. Tudo no relatório marcado como INFERÊNCIA ou DESCONHECIDO é hipótese. Não trate como regra.
4. Valores de negócio (taxas, conversões, mínimos) **não** vêm do concorrente: são decisões do usuário (`docs/QUESTOES-ABERTAS.md`).
5. Mecânicas excluídas pela ADR 0006 continuam excluídas mesmo que apareçam no relatório.

## O que aprendemos e aplicamos (resumo)
- Economia moedas → presentes → diamantes → saque é o centro; servidor autoritativo e ledger.
- Comando por REST e estado por um canal único de eventos.
- UI em overlays/bottom sheets para manter o usuário no vídeo.
- Promoções, ofertas e banners comandados pelo servidor.
- Tutoriais de primeira vez controlados por flags.
- Muitos perfis (moderador, família, agência, revendedor) decididos pelo servidor.
- Proteções: verificação de idade, presença do rosto na câmera, denúncia, anti-bot no login, uma conexão em tempo real por conta.
- Dívidas a evitar: várias bibliotecas para a mesma coisa, várias fontes, dois fluxos de compra sem padrão.
