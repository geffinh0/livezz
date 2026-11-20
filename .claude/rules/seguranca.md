# Segurança e privacidade (vale para todo o projeto)

Checklist completo em `docs/SEGURANCA.md`. Em toda tarefa:
- Nunca colocar segredo no app, no repositório, em fixture ou em log. O hook `checar-segredos` bloqueia padrões conhecidos.
- Tokens do provedor de vídeo gerados só no servidor, com expiração curta e papel correto.
- Autorização por objeto e por função em todo endpoint (inclusive no mock-server, para o app ser testado do jeito certo).
- Validação de toda entrada; limites de tamanho e frequência.
- Dados 🔒 (CPF, documento, data de nascimento, telefone, chave Pix, e-mail): mínimo necessário, mascarados em tela e log.
- Proteção de menores (ECA Digital): qualquer feature de live, chamada, mensagem ou mídia precisa de denúncia e de ação de moderação correspondente.
- Features 🚩 bloqueadas no servidor quando a flag está desligada, não só escondidas no app.
- Se uma tarefa pedir algo que fere estas regras, pare e explique antes de seguir. Achou um risco crítico? Avise o usuário na hora e registre em `docs/MELHORIAS.md` como `crítica`.
