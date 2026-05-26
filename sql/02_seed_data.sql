-- ============================================================
-- Banco Un — Dados Iniciais (seed manual)
-- Usado para validar a estrutura antes da geração em volume
-- ============================================================

INSERT INTO clientes VALUES
(1, 'Ana Lima',     '111.111.111-11', '1990-03-15', '2023-01-10', 'SP', 'ativo'),
(2, 'Bruno Souza',  '222.222.222-22', '1985-07-22', '2023-02-14', 'RJ', 'ativo'),
(3, 'Carla Mendes', '333.333.333-33', '1995-11-05', '2023-03-01', 'MG', 'bloqueado'),
(4, 'Diego Alves',  '444.444.444-44', '1988-01-30', '2022-12-20', 'SP', 'ativo'),
(5, 'Eva Costa',    '555.555.555-55', '2000-06-18', '2024-01-05', 'BA', 'encerrado');

INSERT INTO contas VALUES
(1, 1, '2023-01-10', 'ativa',    'corrente'),
(2, 2, '2023-02-14', 'ativa',    'corrente'),
(3, 3, '2023-03-01', 'bloqueada','corrente'),
(4, 4, '2022-12-20', 'ativa',    'corrente');

INSERT INTO cartoes VALUES
(1, 1, 1, '2023-01-15', '2027-01-15', 5000.00,  3200.00, 'ativo',    'fisico'),
(2, 2, 2, '2023-02-20', '2027-02-20', 8000.00,  6500.00, 'ativo',    'fisico'),
(3, 3, 3, '2023-03-05', '2027-03-05', 3000.00,  3000.00, 'bloqueado','fisico'),
(4, 4, 4, '2022-12-25', '2026-12-25', 10000.00, 4000.00, 'ativo',    'fisico'),
(5, 1, 1, '2024-01-01', '2028-01-01', 2000.00,  1500.00, 'ativo',    'virtual');

INSERT INTO transacoes VALUES
(1,  1, 1, '2026-05-02', '2026-05-02',  250.00, 'compra',  'aprovada',  'Supermercado Extra', 'alimentacao', 1),
(2,  1, 1, '2026-05-05', '2026-05-05',   89.90, 'compra',  'aprovada',  'Uber',               'transporte',  1),
(3,  2, 2, '2026-05-03', '2026-05-03', 1200.00, 'compra',  'aprovada',  'Samsung Store',      'outros',      3),
(4,  2, 2, '2026-05-10', '2026-05-10',   45.00, 'compra',  'aprovada',  'iFood',              'alimentacao', 1),
(5,  4, 4, '2026-05-01', '2026-05-01', 3500.00, 'compra',  'aprovada',  'Apple Store',        'outros',      6),
(6,  4, 4, '2026-05-08', '2026-05-08',  200.00, 'compra',  'aprovada',  'Posto Shell',        'transporte',  1),
(7,  1, 1, '2026-05-15', '2026-05-15',  150.00, 'compra',  'aprovada',  'Farmácia Drogasil',  'saude',       1),
(8,  2, 2, '2026-05-18', '2026-05-18',  320.00, 'estorno', 'estornada', 'Samsung Store',      'outros',      1),
(9,  4, 4, '2026-05-20', '2026-05-20',   80.00, 'compra',  'aprovada',  'Spotify',            'outros',      1),
(10, 1, 1, '2026-05-22', '2026-05-23',  500.00, 'compra',  'aprovada',  'Americanas',         'outros',      2);

-- Lançamentos contábeis correspondentes (com divergências plantadas intencionalmente)
-- Transações 4 e 8 não têm lançamento → divergência tipo "transação sem lançamento"
-- Lançamento 8 tem data_competencia errada (maio → janeiro) → divergência de competência
-- Lançamento 9 é ajuste manual sem id_transacao correspondente
INSERT INTO lancamentos_contabeis VALUES
(1, 1,    NULL, 1, '2026-05-02', '2026-05-02',  250.00, 'debito', '1.1.3.01', 'Compra Supermercado Extra', 'transacao',     'conciliado'),
(2, 2,    NULL, 1, '2026-05-05', '2026-05-05',   89.90, 'debito', '1.1.3.01', 'Compra Uber',               'transacao',     'conciliado'),
(3, 3,    NULL, 2, '2026-05-03', '2026-05-03', 1200.00, 'debito', '1.1.3.01', 'Compra Samsung Store',      'transacao',     'conciliado'),
(4, 5,    NULL, 4, '2026-05-01', '2026-05-01', 3500.00, 'debito', '1.1.3.01', 'Compra Apple Store',        'transacao',     'conciliado'),
(5, 6,    NULL, 4, '2026-05-08', '2026-05-08',  200.00, 'debito', '1.1.3.01', 'Compra Posto Shell',        'transacao',     'conciliado'),
(6, 7,    NULL, 1, '2026-05-15', '2026-05-15',  150.00, 'debito', '1.1.3.01', 'Compra Farmácia Drogasil',  'transacao',     'conciliado'),
(7, 9,    NULL, 4, '2026-05-20', '2026-05-20',   80.00, 'debito', '1.1.3.01', 'Compra Spotify',            'transacao',     'conciliado'),
(8, 10,   NULL, 1, '2026-05-23', '2026-01-01',  500.00, 'debito', '1.1.3.01', 'Compra Americanas',         'transacao',     'pendente'),
(9, NULL, NULL, 2, '2026-05-12', '2026-05-12',   75.00, 'debito', '1.1.3.01', 'Ajuste manual tarifa',      'ajuste_manual', 'pendente');
