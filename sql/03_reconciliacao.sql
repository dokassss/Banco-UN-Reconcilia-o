-- ============================================================
-- Banco Un — Queries de Conciliação
-- P1: SQL-Based Financial Reconciliation Model
-- ============================================================

-- ------------------------------------------------------------
-- 1. Transações SEM lançamento contábil correspondente
--    Divergência: processamento falhou ou atrasou
-- ------------------------------------------------------------
SELECT
    t.id_transacao,
    t.data_transacao,
    t.valor,
    t.tipo_transacao,
    t.status_transacao,
    t.estabelecimento
FROM transacoes t
LEFT JOIN lancamentos_contabeis l ON t.id_transacao = l.id_transacao
WHERE l.id_lancamento IS NULL;


-- ------------------------------------------------------------
-- 2. Lançamentos SEM transação correspondente (ajustes manuais)
--    Divergência: lançamento manual sem origem operacional
-- ------------------------------------------------------------
SELECT
    l.id_lancamento,
    l.data_lancamento,
    l.valor,
    l.descricao,
    l.origem,
    l.status_lancamento
FROM lancamentos_contabeis l
LEFT JOIN transacoes t ON l.id_transacao = t.id_transacao
WHERE t.id_transacao IS NULL;


-- ------------------------------------------------------------
-- 3. Transações com lançamento, mas VALOR DIVERGENTE
--    Divergência: erro de processamento ou arredondamento
-- ------------------------------------------------------------
SELECT
    t.id_transacao,
    t.valor              AS valor_transacao,
    l.valor              AS valor_lancamento,
    t.valor - l.valor    AS diferenca,
    t.estabelecimento,
    t.data_transacao
FROM transacoes t
INNER JOIN lancamentos_contabeis l ON t.id_transacao = l.id_transacao
WHERE t.valor <> l.valor;


-- ------------------------------------------------------------
-- 4. Lançamentos com DATA DE COMPETÊNCIA errada
--    Divergência: transação em um mês, lançamento em outro
-- ------------------------------------------------------------
SELECT
    t.id_transacao,
    t.data_transacao,
    l.data_competencia,
    t.valor,
    t.estabelecimento
FROM transacoes t
INNER JOIN lancamentos_contabeis l ON t.id_transacao = l.id_transacao
WHERE MONTH(t.data_transacao) <> MONTH(l.data_competencia)
   OR YEAR(t.data_transacao)  <> YEAR(l.data_competencia);


-- ------------------------------------------------------------
-- 5. Visão consolidada — todas as divergências classificadas
-- ------------------------------------------------------------
SELECT
    t.id_transacao,
    t.valor              AS valor_transacao,
    l.valor              AS valor_lancamento,
    t.status_transacao,
    l.status_lancamento,
    CASE
        WHEN l.id_lancamento IS NULL             THEN 'sem_lancamento'
        WHEN t.valor <> l.valor                  THEN 'valor_divergente'
        WHEN MONTH(t.data_transacao) <>
             MONTH(l.data_competencia)            THEN 'competencia_errada'
        ELSE 'ok'
    END AS tipo_divergencia
FROM transacoes t
LEFT JOIN lancamentos_contabeis l ON t.id_transacao = l.id_transacao
ORDER BY tipo_divergencia, t.id_transacao;

-- D1: Transações aprovadas sem lançamento contábil correspondente
SELECT t.id_transacao, t.valor, t.data_transacao, t.estabelecimento
FROM transacoes t
LEFT JOIN lancamentos_contabeis l ON t.id_transacao = l.id_transacao
WHERE l.id_transacao IS NULL
  AND t.status_transacao = 'aprovada';


  -- D3: Lançamentos com valor divergente da transação
SELECT t.id_transacao, t.valor AS valor_transacao, l.valor AS valor_lancamento,
       l.valor - t.valor AS diferenca
FROM transacoes t
INNER JOIN lancamentos_contabeis l ON t.id_transacao = l.id_transacao
WHERE t.valor <> l.valor
  AND t.status_transacao = 'aprovada';


  -- D4: Data de competência no mês errado
SELECT t.id_transacao, t.data_transacao, l.data_competencia,
       MONTH(t.data_transacao) AS mes_transacao,
       MONTH(l.data_competencia) AS mes_competencia
FROM transacoes t
INNER JOIN lancamentos_contabeis l ON t.id_transacao = l.id_transacao
WHERE MONTH(t.data_transacao) <> MONTH(l.data_competencia);

-- ============================================================
-- D2: Lançamentos de ajuste_manual sem transação de origem
-- ============================================================
SELECT
    id_lancamento,
    tipo_lancamento,
    valor,
    data_lancamento,
    status_lancamento
FROM lancamentos_contabeis
WHERE tipo_lancamento = 'ajuste_manual'
  AND id_transacao IS NULL
ORDER BY data_lancamento;


-- ============================================================
-- D5: Pagamentos devolvidos com lançamento marcado como conciliado
-- ============================================================
SELECT
    p.id_pagamento,
    p.id_fatura,
    p.valor_pago     AS valor_pagamento,
    p.data_pagamento,
    p.status_pagamento,
    l.id_lancamento,
    l.status_lancamento
FROM pagamentos p
INNER JOIN lancamentos_contabeis l
    ON l.id_transacao = p.id_pagamento
WHERE p.status_pagamento = 'devolvido'
  AND l.status_lancamento = 'conciliado'
ORDER BY p.data_pagamento;


-- ============================================================
-- D6: Transações com lançamento duplicado
-- ============================================================
SELECT
    id_transacao,
    COUNT(*) AS qtd_lancamentos
FROM lancamentos_contabeis
WHERE id_transacao IS NOT NULL
GROUP BY id_transacao
HAVING COUNT(*) > 1
ORDER BY qtd_lancamentos DESC;


-- ============================================================
-- D7: Transações parceladas (3x) com lançamentos incompletos
-- ============================================================
SELECT
    t.id_transacao,
    t.parcelas,
    COUNT(l.id_lancamento) AS qtd_lancamentos
FROM transacoes t
LEFT JOIN lancamentos_contabeis l
    ON l.id_transacao = t.id_transacao
WHERE t.parcelas = 3
GROUP BY t.id_transacao, t.parcelas
HAVING COUNT(l.id_lancamento) < 3
ORDER BY qtd_lancamentos;


-- ============================================================
-- AGING: Dias em aberto por transação sem lançamento
-- ============================================================
SELECT
    t.id_transacao,
    t.valor,
    t.data_transacao,
    t.status_transacao,
    DATEDIFF('day', t.data_transacao, CURRENT_DATE) AS dias_em_aberto,
    CASE
        WHEN DATEDIFF('day', t.data_transacao, CURRENT_DATE) <= 7  THEN '0-7 dias'
        WHEN DATEDIFF('day', t.data_transacao, CURRENT_DATE) <= 30 THEN '8-30 dias'
        WHEN DATEDIFF('day', t.data_transacao, CURRENT_DATE) <= 90 THEN '31-90 dias'
        ELSE 'mais de 90 dias'
    END AS faixa_aging
FROM transacoes t
LEFT JOIN lancamentos_contabeis l
    ON l.id_transacao = t.id_transacao
WHERE t.status_transacao = 'aprovada'
  AND l.id_transacao IS NULL
ORDER BY dias_em_aberto DESC;


