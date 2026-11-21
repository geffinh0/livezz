// Mapa error.code (docs/API.md, Catálogo de erros) → texto traduzido.
// Um teste garante que todo código do catálogo tem texto em pt e en.
import 'generated/app_localizations.dart';

String errorMessageFor(AppLocalizations l, String code) {
  switch (code) {
    case 'nao_autenticado':
      return l.errorNaoAutenticado;
    case 'token_expirado':
      return l.errorTokenExpirado;
    case 'sessao_substituida':
      return l.errorSessaoSubstituida;
    case 'verificacao_idade_necessaria':
      return l.errorVerificacaoIdadeNecessaria;
    case 'sem_permissao':
      return l.errorSemPermissao;
    case 'nao_encontrado':
      return l.errorNaoEncontrado;
    case 'validacao':
      return l.errorValidacao;
    case 'conflito':
      return l.errorConflito;
    case 'limite_excedido':
      return l.errorLimiteExcedido;
    case 'saldo_insuficiente':
      return l.errorSaldoInsuficiente;
    case 'idade_nao_verificada':
      return l.errorIdadeNaoVerificada;
    case 'menor_de_idade':
      return l.errorMenorDeIdade;
    case 'conta_suspensa':
      return l.errorContaSuspensa;
    case 'conta_banida':
      return l.errorContaBanida;
    case 'regiao_bloqueada':
      return l.errorRegiaoBloqueada;
    case 'atualizacao_obrigatoria':
      return l.errorAtualizacaoObrigatoria;
    case 'manutencao':
      return l.errorManutencao;
    case 'codigo_invalido':
      return l.errorCodigoInvalido;
    case 'codigo_expirado':
      return l.errorCodigoExpirado;
    case 'username_indisponivel':
      return l.errorUsernameIndisponivel;
    case 'live_encerrada':
      return l.errorLiveEncerrada;
    case 'expulso_da_live':
      return l.errorExpulsoDaLive;
    case 'silenciado':
      return l.errorSilenciado;
    case 'convite_expirado':
      return l.errorConviteExpirado;
    case 'funcionalidade_desligada':
      return l.errorFuncionalidadeDesligada;
    case 'pagamento_pendente':
      return l.errorPagamentoPendente;
    case 'pagamento_falhou':
      return l.errorPagamentoFalhou;
    case 'saque_abaixo_minimo':
      return l.errorSaqueAbaixoMinimo;
    case 'dados_recebimento_incompletos':
      return l.errorDadosRecebimentoIncompletos;
    case 'erro_interno':
      return l.errorErroInterno;
    default:
      return l.errorUnknown;
  }
}

/// Códigos conhecidos pelo app (iguais ao catálogo da API).
const knownErrorCodes = <String>[
  'nao_autenticado',
  'token_expirado',
  'sessao_substituida',
  'verificacao_idade_necessaria',
  'sem_permissao',
  'nao_encontrado',
  'validacao',
  'conflito',
  'limite_excedido',
  'saldo_insuficiente',
  'idade_nao_verificada',
  'menor_de_idade',
  'conta_suspensa',
  'conta_banida',
  'regiao_bloqueada',
  'atualizacao_obrigatoria',
  'manutencao',
  'codigo_invalido',
  'codigo_expirado',
  'username_indisponivel',
  'live_encerrada',
  'expulso_da_live',
  'silenciado',
  'convite_expirado',
  'funcionalidade_desligada',
  'pagamento_pendente',
  'pagamento_falhou',
  'saque_abaixo_minimo',
  'dados_recebimento_incompletos',
  'erro_interno',
];
