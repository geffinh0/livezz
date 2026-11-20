# ADR 0010: Detecção de presença e de conteúdo na live

- Status: aceita
- Data: 2026-11-20

## Contexto
Apps do mercado detectam rosto/corpo no aparelho durante a live e convertem a live em privada em vez de derrubá-la. O usuário quer a conversão automática para privada e que o app passe na revisão da Google Play.

## Opções consideradas
1. Qualquer detecção (inclusive nudez) converte a live em privada: na prática cobraria acesso ao conteúdo que as diretrizes proíbem (RN-83), viola as políticas da loja sobre conteúdo sexual e expõe o comprador a risco jurídico.
2. Separar os casos: ausência de rosto/corpo → privada automaticamente; conteúdo proibido → encerrar e moderar.

## Decisão
Opção 2.
- **Rosto/corpo ausente:** aviso com contagem e conversão automática para privada; volta a pública quando o host reaparecer (RN-48).
- **Conteúdo proibido (nudez, violência e demais itens da RN-83):** live encerrada na hora, denúncia automática com evidência para a moderação (prioridade alta), aviso ao host. Nunca vira privada nem gera cobrança.
- Detecção no aparelho via `DetectionProvider`; a decisão da ação é sempre do servidor.

## Consequências
- O comportamento que o usuário queria para ausência de rosto é mantido.
- Conteúdo proibido nunca é monetizado, o que protege o comprador e a publicação nas lojas.
- Sensibilidade, tempos e ações são configuráveis no painel (ADM21), mas a regra "conteúdo proibido nunca vira privado" não é configurável.
