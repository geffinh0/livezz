# Segurança, privacidade e proteção

> Este produto mexe com **dinheiro real, dados pessoais e público adulto em tempo real**. Segurança não é uma fase: cada item da especificação é revisado contra este documento.
> O subagente `revisor-seguranca` usa este arquivo como checklist.

## 1. O que proteger (ativos)
| Ativo | Por que importa |
| --- | --- |
| Saldos (moedas, diamantes) e ledger | Fraude vira prejuízo direto do cliente |
| Saques e dados de recebimento (CPF, Pix) | Desvio de dinheiro, vazamento de dado pessoal |
| Contas de usuário e sessões | Sequestro de conta gasta saldo alheio |
| Segredos (certificado do provedor de vídeo, chaves de pagamento, chaves de push) | Uso indevido gera custo e fraude |
| Conteúdo ao vivo | Exposição de menores, conteúdo ilegal, responsabilidade legal |
| Painel admin | Acesso total ao negócio |

## 2. Ameaças principais e controles
| Ameaça | Controles obrigatórios |
| --- | --- |
| Manipular preço/saldo pelo app | Servidor autoritativo; preço sempre do catálogo; validação de saldo no servidor; ledger com idempotência |
| Duplo envio / corrida | Chave de idempotência; transação + bloqueio de conta no backend; testes de concorrência |
| Compra falsa | Validar recibo da Google Play no servidor; Pix só com confirmação do PSP; nunca confiar no app |
| Estorno após gastar | RN-24: saldo negativo bloqueia, conta sinalizada; retenção de diamantes recém-recebidos antes do saque (RN-25) |
| Lavagem/abuso via presentes entre contas próprias | Limites, detecção de padrões (SEG05), retenção antes do saque, KYC no saque |
| Sequestro de conta | Tokens curtos, refresh rotativo com detecção de reuso, rate limit em login e código, troca de senha derruba sessões, alertas de novo dispositivo |
| Enumeração de usuários | Mensagens de erro neutras em login/recuperação |
| Bots e contas falsas | Captcha sob demanda, integridade do app, limite por dispositivo/telefone |
| Vazamento de segredo | Segredos só em variáveis de ambiente do servidor; nunca no app, no repositório ou em log; hook `checar-segredos` |
| Acesso indevido no painel | 2FA, papéis mínimos, auditoria de toda ação, sessão curta, IP registrado |
| Injeção (SQL, comandos, HTML no chat) | Validação de entrada com schema; consultas parametrizadas; escape na exibição |
| Upload malicioso | Tipos e tamanhos restritos, URLs de upload assinadas e de curta duração, moderação antes de publicar |
| Menor de idade na plataforma | Verificação de idade confiável (RN-01), denúncia prioritária, preservação de evidências (SEG07) |
| Conteúdo ilegal ao vivo | Denúncia, moderação em tempo real, encerramento imediato, presença na câmera, diretrizes claras |
| Assédio e spam | Bloqueio, limites de mensagens, filtros de texto, sanções |
| Abuso de chamadas/lives pagas | Preço e consentimento explícitos, contador de custo, reembolso inicial (RN-50), denúncia |

## 3. Checklist do app Android (baseado em OWASP MASVS)
- [ ] Tokens em armazenamento seguro (Keystore via flutter_secure_storage); nada sensível em SharedPreferences, logs ou capturas.
- [ ] Somente HTTPS/WSS; sem tráfego em texto puro; considerar *certificate pinning* na Fase 12.
- [ ] `allowBackup` desligado ou com regras de exclusão de dados sensíveis.
- [ ] Ofuscação e minificação no build de release.
- [ ] Nenhum segredo no APK (o app só tem IDs públicos).
- [ ] Deep links validados (nunca executar ação sensível só por abrir link).
- [ ] Permissões pedidas no momento do uso, com explicação; nada além do necessário.
- [ ] Telas sensíveis (saque, dados de recebimento) bloqueiam captura de tela.
- [ ] Logs de release sem dados pessoais.
- [ ] WebViews (recarga, termos) sem JavaScript desnecessário e só para domínios do tenant.

## 4. Checklist da API (baseado em OWASP API Security Top 10)
- [ ] Autorização por objeto em todo endpoint (o usuário só acessa o que é dele ou público).
- [ ] Autorização por função (rotas de host, moderador, admin).
- [ ] Validação de toda entrada (tipos, limites, formatos) e respostas sem dados excessivos.
- [ ] Rate limit e limites de recurso (tamanho de página, upload, mensagens).
- [ ] Idempotência em operações de valor.
- [ ] Flags desligadas bloqueiam também no servidor (`funcionalidade_desligada`).
- [ ] Erros sem stack trace, SQL ou detalhes internos; `requestId` para suporte.
- [ ] Inventário de endpoints = `docs/API.md` (nada fora do contrato).
- [ ] Rotas `/__mock/*` **impossíveis** de existir no backend real.

## 5. Dados pessoais (LGPD)
- Coletar só o necessário; finalidade explícita nos termos.
- Campos 🔒 do `docs/DATABASE.md`: criptografados em repouso, mascarados na exibição, acesso no painel por papel e auditado.
- Direitos do titular: exportar e excluir (CFG12), corrigir (PER02/CFG02).
- Retenção definida por tipo de dado (RN-80) e aplicada por rotina automática.
- Incidente com dado pessoal: plano de resposta com o cliente (quem avisa, prazos, registro).

## 6. Proteção de crianças e adolescentes (ECA Digital, Lei 15.211/2025)
- Autodeclaração de idade não basta; verificação confiável (ENT09) antes de liberar o uso (momento em Q-08).
- Menor detectado: bloqueio imediato (ENT10).
- Denúncia de possível menor: prioridade máxima, alerta imediato, encerramento preventivo da live permitido ao moderador.
- Preservar evidências e seguir fluxo de comunicação às autoridades definido pelo jurídico do cliente.
- Nenhuma publicidade ou recurso desenhado para atrair menores.
- **Validar todo este item com advogado do cliente antes da publicação.**

## 7. Segredos e configuração
- `.env` nunca é commitado; `.env.example` lista as variáveis sem valores.
- Cada tenant tem seus próprios segredos no ambiente do backend dele.
- Rotação de segredos documentada; acesso aos ambientes só para quem precisa.

## 8. Revisões obrigatórias
- Toda mudança em auth, economia, saques, moderação, dados pessoais ou flags de risco → `revisor-seguranca`.
- Antes da Fase 13: revisão completa deste documento + teste de intrusão básico + revisão jurídica.

## 9. Portal web, conectores e detecção (decisões de 2026-11-20)
- **Portal (ADR 0008):** link de uso único, curta duração e vinculado ao usuário; trocado por sessão própria do portal; CSP, cookies seguros e CSRF; confirmação de pagamento só por webhook com assinatura verificada.
- **Conectores (ADR 0007):** credenciais dos provedores configuradas pelo comprador ficam criptografadas no servidor, são só de escrita no painel, nunca chegam ao app e toda alteração é auditada. Webhooks de cada provedor validados (assinatura, origem, idempotência).
- **Sessão única (ADR 0009):** login novo revoga a sessão anterior e derruba a conexão em tempo real; refresh token da sessão revogada é rejeitado.
- **Detecção de conteúdo (ADR 0010):** conteúdo proibido encerra a live e gera denúncia com evidência; nunca é monetizado nem convertido em privado. A conversão automática para privada só acontece por ausência de rosto/corpo.
- **Idade (Q-08/Q-41):** autodeclaração + sinal da loja no cadastro e verificação forte para transmitir e sacar. O ECA Digital acabou com a autodeclaração para conteúdo restrito a adultos: **validar com advogado antes de publicar**.
