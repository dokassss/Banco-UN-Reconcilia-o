-- ============================================================
-- Banco Un — Modelo de Dados
-- P1: SQL-Based Financial Reconciliation Model
-- ============================================================

CREATE TABLE clientes (
    id_cliente       INTEGER PRIMARY KEY,
    nome             VARCHAR,
    cpf              VARCHAR,
    data_nascimento  DATE,
    data_cadastro    DATE,
    uf               VARCHAR(2),
    status_cliente   VARCHAR  -- ativo | bloqueado | encerrado
);

CREATE TABLE contas (
    id_conta       INTEGER PRIMARY KEY,
    id_cliente     INTEGER,  -- FK → clientes
    data_abertura  DATE,
    status_conta   VARCHAR,  -- ativa | bloqueada | encerrada
    tipo_conta     VARCHAR   -- corrente | poupanca
);

CREATE TABLE cartoes (
    id_cartao         INTEGER PRIMARY KEY,
    id_conta          INTEGER,   -- FK → contas
    id_cliente        INTEGER,   -- FK → clientes
    data_emissao      DATE,
    data_validade     DATE,
    limite_total      DECIMAL,
    limite_disponivel DECIMAL,
    status_cartao     VARCHAR,   -- ativo | bloqueado | cancelado
    tipo_cartao       VARCHAR    -- fisico | virtual
);

CREATE TABLE transacoes (
    id_transacao       INTEGER PRIMARY KEY,
    id_cartao          INTEGER,  -- FK → cartoes
    id_cliente         INTEGER,  -- FK → clientes
    data_transacao     DATE,
    data_processamento DATE,     -- pode diferir da data_transacao (virada de mês)
    valor              DECIMAL,
    tipo_transacao     VARCHAR,  -- compra | estorno | saque | pagamento
    status_transacao   VARCHAR,  -- aprovada | negada | estornada | pendente
    estabelecimento    VARCHAR,
    categoria          VARCHAR,  -- alimentacao | transporte | saude | outros
    parcelas           INTEGER   -- 1 = à vista
);

CREATE TABLE faturas (
    id_fatura       INTEGER PRIMARY KEY,
    id_cartao       INTEGER,  -- FK → cartoes
    id_cliente      INTEGER,  -- FK → clientes
    mes_referencia  VARCHAR,  -- formato AAAA-MM
    data_vencimento DATE,
    data_fechamento DATE,
    valor_total     DECIMAL,
    valor_minimo    DECIMAL,
    valor_pago      DECIMAL,
    status_fatura   VARCHAR,  -- aberta | fechada | paga | parcialmente_paga | vencida
    dias_atraso     INTEGER   -- 0 = em dia
);

CREATE TABLE pagamentos (
    id_pagamento     INTEGER PRIMARY KEY,
    id_fatura        INTEGER,  -- FK → faturas
    id_cliente       INTEGER,  -- FK → clientes
    data_pagamento   DATE,
    valor_pago       DECIMAL,
    tipo_pagamento   VARCHAR,  -- boleto | debito_automatico | pix
    status_pagamento VARCHAR   -- confirmado | pendente | devolvido
);

CREATE TABLE lancamentos_contabeis (
    id_lancamento     INTEGER PRIMARY KEY,
    id_transacao      INTEGER,  -- FK → transacoes (nullable: ajustes manuais não têm par)
    id_fatura         INTEGER,  -- FK → faturas
    id_cliente        INTEGER,  -- FK → clientes
    data_lancamento   DATE,
    data_competencia  DATE,     -- período contábil (pode diferir de data_lancamento)
    valor             DECIMAL,
    tipo_lancamento   VARCHAR,  -- debito | credito
    conta_contabil    VARCHAR,  -- código no plano de contas
    descricao         VARCHAR,
    origem            VARCHAR,  -- transacao | pagamento | ajuste_manual | estorno
    status_lancamento VARCHAR   -- conciliado | pendente | divergente
);
