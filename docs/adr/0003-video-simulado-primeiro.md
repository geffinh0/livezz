# ADR 0003: Vídeo simulado primeiro

- Status: aceita
- Data: 2026-11-20

## Contexto
Sem backend não há servidor de token para o provedor de vídeo. O usuário escolheu construir as telas da live com vídeo simulado e integrar o provedor real depois.

## Decisão
Interface `VideoProvider` com `FakeVideoProvider` agora (câmera local na prévia, vídeos de exemplo em loop, simulação de convidados e PK) e `AgoraVideoProvider` na fase de integrações.

## Consequências
- As telas de live, PK, convidados e chamadas são completas e testáveis sem custo de minutos.
- O fake precisa emitir os mesmos estados que o provedor real (conectando, conectado, reconectando, participante entrou/saiu, falha) para a UI tratar todos os casos desde já.
- Riscos reais de vídeo (latência, qualidade, consumo de bateria e dados) só aparecem na Fase 12; reservar tempo para ajustes.
