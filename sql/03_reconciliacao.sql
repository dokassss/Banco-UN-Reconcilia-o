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
