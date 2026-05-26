-- load_banco_un.sql
-- Carrega os 7 CSVs gerados pelo generate_banco_un.py
-- nas tabelas já existentes do banco_un.db
--
-- Execute no terminal:
--   duckdb C:\projetos\banco-un\banco_un.db < load_banco_un.sql
--
-- OU dentro do DuckDB interativo:
--   .read load_banco_un.sql
--
-- ATENÇÃO: este script DELETA os dados existentes antes de carregar.
-- Execute só uma vez (ou quando quiser recriar tudo do zero).

-- Caminho base dos CSVs (ajuste se necessário)
-- Se rodar o script a partir da pasta do projeto, o caminho ./data/ funciona direto.

-- ─────────────────────────────────────────────
-- Limpar dados existentes (ordem inversa das FKs)
-- ─────────────────────────────────────────────
DELETE FROM lancamentos_contabeis;
DELETE FROM pagamentos;
DELETE FROM faturas;
DELETE FROM transacoes;
DELETE FROM cartoes;
DELETE FROM contas;
DELETE FROM clientes;

-- ─────────────────────────────────────────────
-- Carregar tabelas base
-- ─────────────────────────────────────────────
COPY clientes FROM './data/clientes.csv' (HEADER TRUE, DATEFORMAT '%Y-%m-%d');
COPY contas   FROM './data/contas.csv'   (HEADER TRUE, DATEFORMAT '%Y-%m-%d');
COPY cartoes  FROM './data/cartoes.csv'  (HEADER TRUE, DATEFORMAT '%Y-%m-%d');

-- ─────────────────────────────────────────────
-- Carregar tabelas transacionais
-- ─────────────────────────────────────────────
COPY transacoes FROM './data/transacoes.csv' (HEADER TRUE, DATEFORMAT '%Y-%m-%d');
COPY faturas    FROM './data/faturas.csv'    (HEADER TRUE, DATEFORMAT '%Y-%m-%d');
COPY pagamentos FROM './data/pagamentos.csv' (HEADER TRUE, DATEFORMAT '%Y-%m-%d');

-- lancamentos_contabeis tem id_transacao nullable — DuckDB trata vazio como NULL automaticamente
COPY lancamentos_contabeis FROM './data/lancamentos_contabeis.csv' (HEADER TRUE, DATEFORMAT '%Y-%m-%d');

-- ─────────────────────────────────────────────
-- Validação rápida de volume
-- ─────────────────────────────────────────────
SELECT 'clientes'              AS tabela, COUNT(*) AS linhas FROM clientes
UNION ALL
SELECT 'contas',                           COUNT(*) FROM contas
UNION ALL
SELECT 'cartoes',                          COUNT(*) FROM cartoes
UNION ALL
SELECT 'transacoes',                       COUNT(*) FROM transacoes
UNION ALL
SELECT 'faturas',                          COUNT(*) FROM faturas
UNION ALL
SELECT 'pagamentos',                       COUNT(*) FROM pagamentos
UNION ALL
SELECT 'lancamentos_contabeis',            COUNT(*) FROM lancamentos_contabeis
ORDER BY tabela;
