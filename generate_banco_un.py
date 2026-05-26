"""
generate_banco_un.py
--------------------
Gera dados simulados para todas as 7 tabelas do Banco Un
e exporta arquivos CSV que podem ser carregados no DuckDB.

Divergências plantadas intencionalmente (para o P1):
  D1 - Transações sem lançamento contábil correspondente
  D2 - Lançamentos sem transação (ajuste_manual)
  D3 - Lançamentos com valor diferente da transação
  D4 - Data de competência errada (virada de mês)
  D5 - Pagamento devolvido com lançamento já conciliado
  D6 - Lançamento duplicado (mesmo id_transacao, 2 lançamentos)
  D7 - Compra parcelada com lançamentos incompletos

Uso:
    pip install faker
    python generate_banco_un.py

Saída: arquivos CSV na pasta ./data/
"""

import csv
import random
import os
from datetime import date, timedelta
from faker import Faker

fake = Faker("pt_BR")
random.seed(42)
Faker.seed(42)

# ─────────────────────────────────────────────
# Configuração de volume
# ─────────────────────────────────────────────
N_CLIENTES     = 200
N_CONTAS       = 220   # alguns clientes com mais de 1 conta
N_CARTOES      = 260   # alguns clientes com cartão físico + virtual
N_TRANSACOES   = 1200
N_FATURAS      = 400
N_PAGAMENTOS   = 380

OUTPUT_DIR = "./data"
os.makedirs(OUTPUT_DIR, exist_ok=True)

# ─────────────────────────────────────────────
# Helpers
# ─────────────────────────────────────────────
def random_date(start: date, end: date) -> date:
    delta = (end - start).days
    return start + timedelta(days=random.randint(0, delta))

def write_csv(filename: str, rows: list[dict]):
    if not rows:
        return
    path = os.path.join(OUTPUT_DIR, filename)
    with open(path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=rows[0].keys())
        writer.writeheader()
        writer.writerows(rows)
    print(f"  ✓ {filename:<45} {len(rows):>5} linhas")

# ─────────────────────────────────────────────
# 1. CLIENTES
# ─────────────────────────────────────────────
print("\n[1/7] Gerando clientes...")
ufs = ["SP","RJ","MG","RS","BA","PR","SC","CE","PE","GO"]
status_cliente = ["ativo"] * 14 + ["bloqueado"] * 2 + ["encerrado"] * 1

clientes = []
cpfs_usados = set()
for i in range(1, N_CLIENTES + 1):
    cpf = fake.cpf()
    while cpf in cpfs_usados:
        cpf = fake.cpf()
    cpfs_usados.add(cpf)
    clientes.append({
        "id_cliente":       i,
        "nome":             fake.name(),
        "cpf":              cpf,
        "data_nascimento":  random_date(date(1960, 1, 1), date(2003, 12, 31)),
        "data_cadastro":    random_date(date(2018, 1, 1), date(2025, 12, 31)),
        "uf":               random.choice(ufs),
        "status_cliente":   random.choice(status_cliente),
    })
write_csv("clientes.csv", clientes)
ids_clientes = [c["id_cliente"] for c in clientes]
clientes_ativos = [c["id_cliente"] for c in clientes if c["status_cliente"] == "ativo"]

# ─────────────────────────────────────────────
# 2. CONTAS
# ─────────────────────────────────────────────
print("[2/7] Gerando contas...")
status_conta = ["ativa"] * 12 + ["bloqueada"] * 2 + ["encerrada"] * 1
tipo_conta   = ["corrente"] * 3 + ["poupanca"] * 1

contas = []
for i in range(1, N_CONTAS + 1):
    id_cli = random.choice(ids_clientes)
    cliente_cadastro = next(c["data_cadastro"] for c in clientes if c["id_cliente"] == id_cli)
    contas.append({
        "id_conta":      i,
        "id_cliente":    id_cli,
        "data_abertura": random_date(cliente_cadastro, date(2025, 12, 31)),
        "status_conta":  random.choice(status_conta),
        "tipo_conta":    random.choice(tipo_conta),
    })
write_csv("contas.csv", contas)
ids_contas = [c["id_conta"] for c in contas]
contas_ativas = [c["id_conta"] for c in contas if c["status_conta"] == "ativa"]

# ─────────────────────────────────────────────
# 3. CARTOES
# ─────────────────────────────────────────────
print("[3/7] Gerando cartões...")
status_cartao = ["ativo"] * 12 + ["bloqueado"] * 2 + ["cancelado"] * 1
tipo_cartao   = ["fisico"] * 2 + ["virtual"] * 1

cartoes = []
for i in range(1, N_CARTOES + 1):
    id_conta = random.choice(ids_contas)
    id_cliente = next(c["id_cliente"] for c in contas if c["id_conta"] == id_conta)
    data_emissao = random_date(date(2019, 1, 1), date(2025, 6, 30))
    limite_total = round(random.choice([1000, 2000, 3000, 5000, 8000, 10000, 15000, 20000]), 2)
    proporcao_usada = random.uniform(0.0, 0.95)
    limite_disponivel = round(limite_total * (1 - proporcao_usada), 2)
    cartoes.append({
        "id_cartao":           i,
        "id_conta":            id_conta,
        "id_cliente":          id_cliente,
        "data_emissao":        data_emissao,
        "data_validade":       data_emissao.replace(year=data_emissao.year + 5),
        "limite_total":        limite_total,
        "limite_disponivel":   limite_disponivel,
        "status_cartao":       random.choice(status_cartao),
        "tipo_cartao":         random.choice(tipo_cartao),
    })
write_csv("cartoes.csv", cartoes)
ids_cartoes = [c["id_cartao"] for c in cartoes]
cartoes_ativos = [c["id_cartao"] for c in cartoes if c["status_cartao"] == "ativo"]

# ─────────────────────────────────────────────
# 4. TRANSAÇÕES
# ─────────────────────────────────────────────
print("[4/7] Gerando transações...")
tipo_transacao   = ["compra"] * 8 + ["estorno"] * 1 + ["saque"] * 1
status_transacao = ["aprovada"] * 10 + ["negada"] * 1 + ["estornada"] * 1 + ["pendente"] * 1
categorias = ["alimentacao","transporte","saude","outros","vestuario","lazer","educacao","servicos"]
estabelecimentos = [
    "Supermercado Extra","iFood","Uber","Farmácia Droga Raia","Netshoes","Netflix",
    "Shopee","Amazon","Posto Shell","Padaria do João","Magazine Luiza","Casas Bahia",
    "Cinemark","Riachuelo","Claro Telecomunicações","Hospital São Luiz","Decathlon",
    "Kalunga","Smart Fit","Mercado Livre",
]

transacoes = []
# IDs reservados para divergências plantadas
IDS_SEM_LANCAMENTO  = set(range(1, 51))       # D1: 50 transações sem lançamento
IDS_VALOR_DIVERGENTE = set(range(51, 81))      # D3: 30 com valor errado no lançamento
IDS_DATA_COMPETENCIA = set(range(81, 101))     # D4: 20 com data_competencia errada
IDS_DUPLICATA        = set(range(101, 116))    # D6: 15 com lançamento duplicado
IDS_PARCELADO_INCOMPLETO = set(range(116, 131)) # D7: 15 parceladas com lançamentos incompletos

for i in range(1, N_TRANSACOES + 1):
    id_cartao = random.choice(cartoes_ativos if cartoes_ativos else ids_cartoes)
    id_cliente = next(c["id_cliente"] for c in cartoes if c["id_cartao"] == id_cartao)
    data_trans = random_date(date(2025, 1, 1), date(2026, 4, 30))
    data_proc  = data_trans + timedelta(days=random.randint(0, 2))
    valor = round(random.uniform(5.0, 2000.0), 2)
    tipo  = "compra" if i not in range(900, 950) else "estorno"
    # Parcelamento: transações D7 terão 3 parcelas
    if i in IDS_PARCELADO_INCOMPLETO:
        parcelas = 3
    elif i % 7 == 0:
        parcelas = random.randint(2, 12)
    else:
        parcelas = 1
    transacoes.append({
        "id_transacao":       i,
        "id_cartao":          id_cartao,
        "id_cliente":         id_cliente,
        "data_transacao":     data_trans,
        "data_processamento": data_proc,
        "valor":              valor,
        "tipo_transacao":     tipo,
        "status_transacao":   "aprovada",
        "estabelecimento":    random.choice(estabelecimentos),
        "categoria":          random.choice(categorias),
        "parcelas":           parcelas,
    })
write_csv("transacoes.csv", transacoes)
ids_transacoes = [t["id_transacao"] for t in transacoes]

# ─────────────────────────────────────────────
# 5. FATURAS
# ─────────────────────────────────────────────
print("[5/7] Gerando faturas...")
status_fatura = ["paga","fechada","aberta","parcialmente_paga","vencida"]

faturas = []
meses_ref = [f"2025-{str(m).zfill(2)}" for m in range(1, 13)] + ["2026-01","2026-02","2026-03","2026-04"]

for i in range(1, N_FATURAS + 1):
    id_cartao  = random.choice(ids_cartoes)
    id_cliente = next(c["id_cliente"] for c in cartoes if c["id_cartao"] == id_cartao)
    mes_ref    = random.choice(meses_ref)
    ano, mes   = int(mes_ref[:4]), int(mes_ref[5:])
    # fechamento no dia 20, vencimento no dia 5 do mês seguinte
    data_fechamento = date(ano, mes, 20)
    mes_v = mes + 1 if mes < 12 else 1
    ano_v = ano if mes < 12 else ano + 1
    data_vencimento = date(ano_v, mes_v, 5)
    valor_total  = round(random.uniform(50, 5000), 2)
    valor_minimo = round(valor_total * 0.15, 2)
    status = random.choice(status_fatura)
    if status == "paga":
        valor_pago = valor_total
        dias_atraso = 0
    elif status == "parcialmente_paga":
        valor_pago = round(random.uniform(valor_minimo, valor_total - 1), 2)
        dias_atraso = random.randint(0, 120)
    elif status == "vencida":
        valor_pago = 0
        dias_atraso = random.randint(1, 180)
    else:
        valor_pago = 0
        dias_atraso = 0
    faturas.append({
        "id_fatura":        i,
        "id_cartao":        id_cartao,
        "id_cliente":       id_cliente,
        "mes_referencia":   mes_ref,
        "data_vencimento":  data_vencimento,
        "data_fechamento":  data_fechamento,
        "valor_total":      valor_total,
        "valor_minimo":     valor_minimo,
        "valor_pago":       valor_pago,
        "status_fatura":    status,
        "dias_atraso":      dias_atraso,
    })
write_csv("faturas.csv", faturas)
ids_faturas = [f["id_fatura"] for f in faturas]

# ─────────────────────────────────────────────
# 6. PAGAMENTOS
# ─────────────────────────────────────────────
print("[6/7] Gerando pagamentos...")

# IDs de pagamentos que serão devolvidos (D5)
IDS_PAGAMENTO_DEVOLVIDO = set(range(1, 21))  # 20 pagamentos devolvidos

pagamentos = []
for i in range(1, N_PAGAMENTOS + 1):
    id_fatura  = random.choice(ids_faturas)
    id_cliente = next(f["id_cliente"] for f in faturas if f["id_fatura"] == id_fatura)
    fatura     = next(f for f in faturas if f["id_fatura"] == id_fatura)
    data_pag   = random_date(date(2025, 1, 1), date(2026, 4, 30))
    # D5: pagamentos devolvidos
    if i in IDS_PAGAMENTO_DEVOLVIDO:
        status_pag = "devolvido"
        valor_pago = round(float(fatura["valor_total"]), 2)
    else:
        status_pag = "confirmado"
        valor_pago = round(random.uniform(float(fatura["valor_minimo"]), float(fatura["valor_total"])), 2)
    pagamentos.append({
        "id_pagamento":    i,
        "id_fatura":       id_fatura,
        "id_cliente":      id_cliente,
        "data_pagamento":  data_pag,
        "valor_pago":      valor_pago,
        "tipo_pagamento":  random.choice(["boleto","pix","debito_automatico"]),
        "status_pagamento": status_pag,
    })
write_csv("pagamentos.csv", pagamentos)

# ─────────────────────────────────────────────
# 7. LANÇAMENTOS CONTÁBEIS
# ─────────────────────────────────────────────
print("[7/7] Gerando lançamentos contábeis...")

lancamentos = []
lid = 1  # contador de id_lancamento

def add_lancamento(id_transacao, id_fatura, id_cliente, data_lanc, data_comp,
                   valor, tipo_lanc, conta_contabil, descricao, origem, status_lanc):
    global lid
    lancamentos.append({
        "id_lancamento":    lid,
        "id_transacao":     id_transacao,
        "id_fatura":        id_fatura,
        "id_cliente":       id_cliente,
        "data_lancamento":  data_lanc,
        "data_competencia": data_comp,
        "valor":            valor,
        "tipo_lancamento":  tipo_lanc,
        "conta_contabil":   conta_contabil,
        "descricao":        descricao,
        "origem":           origem,
        "status_lancamento": status_lanc,
    })
    lid += 1

# Lançamentos normais para transações que NÃO estão nos grupos de divergência
transacoes_normais = [
    t for t in transacoes
    if t["id_transacao"] not in IDS_SEM_LANCAMENTO
    and t["id_transacao"] not in IDS_PARCELADO_INCOMPLETO
]

for t in transacoes_normais:
    id_trans = t["id_transacao"]
    id_cli   = t["id_cliente"]
    data_t   = t["data_transacao"]
    valor    = float(t["valor"])
    # D3: valor divergente
    if id_trans in IDS_VALOR_DIVERGENTE:
        valor_lanc = round(valor + random.uniform(0.01, 50.0), 2)
        status_l   = "divergente"
    else:
        valor_lanc = valor
        status_l   = "conciliado"
    # D4: data de competência errada (mês seguinte)
    if id_trans in IDS_DATA_COMPETENCIA:
        data_comp = (data_t.replace(day=1) + timedelta(days=32)).replace(day=1)
    else:
        data_comp = data_t
    # Fatura associada (busca a mais próxima do cartão)
    id_fat = random.choice(ids_faturas)
    add_lancamento(
        id_transacao  = id_trans,
        id_fatura     = id_fat,
        id_cliente    = id_cli,
        data_lanc     = data_t + timedelta(days=random.randint(0, 1)),
        data_comp     = data_comp,
        valor         = valor_lanc,
        tipo_lanc     = "debito",
        conta_contabil= "1.1.3.01",
        descricao     = f"Transação {id_trans} — {t['estabelecimento']}",
        origem        = "transacao",
        status_lanc   = status_l,
    )
    # D6: duplicata — mesmo id_transacao, segundo lançamento
    if id_trans in IDS_DUPLICATA:
        add_lancamento(
            id_transacao  = id_trans,
            id_fatura     = id_fat,
            id_cliente    = id_cli,
            data_lanc     = data_t + timedelta(days=1),
            data_comp     = data_comp,
            valor         = valor_lanc,
            tipo_lanc     = "debito",
            conta_contabil= "1.1.3.01",
            descricao     = f"DUPLICATA Transação {id_trans} — reprocessamento incorreto",
            origem        = "transacao",
            status_lanc   = "pendente",
        )

# D7: parceladas incompletas — gerar apenas 1 dos 3 lançamentos esperados
for t in transacoes:
    if t["id_transacao"] in IDS_PARCELADO_INCOMPLETO:
        id_fat = random.choice(ids_faturas)
        add_lancamento(
            id_transacao  = t["id_transacao"],
            id_fatura     = id_fat,
            id_cliente    = t["id_cliente"],
            data_lanc     = t["data_transacao"] + timedelta(days=1),
            data_comp     = t["data_transacao"],
            valor         = round(float(t["valor"]) / 3, 2),
            tipo_lanc     = "debito",
            conta_contabil= "1.1.3.02",
            descricao     = f"Parcela 1/3 — Transação {t['id_transacao']} (lançamentos 2 e 3 ausentes)",
            origem        = "transacao",
            status_lanc   = "pendente",
        )
# D1: transações IDS_SEM_LANCAMENTO → sem nenhum lançamento (nada gerado aqui — é a ausência)

# D2: lançamentos de ajuste_manual sem transação (50 registros)
for _ in range(50):
    id_cli = random.choice(ids_clientes)
    id_fat = random.choice(ids_faturas)
    data_aj = random_date(date(2025, 1, 1), date(2026, 4, 30))
    add_lancamento(
        id_transacao  = None,
        id_fatura     = id_fat,
        id_cliente    = id_cli,
        data_lanc     = data_aj,
        data_comp     = data_aj,
        valor         = round(random.uniform(1.0, 500.0), 2),
        tipo_lanc     = random.choice(["debito","credito"]),
        conta_contabil= "9.9.9.01",
        descricao     = "Ajuste manual — sem transação operacional de origem",
        origem        = "ajuste_manual",
        status_lanc   = "pendente",
    )

# D5: lançamentos de pagamentos devolvidos marcados como conciliado
for pag in pagamentos:
    if pag["id_pagamento"] in IDS_PAGAMENTO_DEVOLVIDO:
        add_lancamento(
            id_transacao  = None,
            id_fatura     = pag["id_fatura"],
            id_cliente    = pag["id_cliente"],
            data_lanc     = pag["data_pagamento"],
            data_comp     = pag["data_pagamento"],
            valor         = float(pag["valor_pago"]),
            tipo_lanc     = "credito",
            conta_contabil= "2.1.1.01",
            descricao     = f"Pagamento devolvido — id_pagamento {pag['id_pagamento']} — status incorreto",
            origem        = "pagamento",
            status_lanc   = "conciliado",  # ← PROBLEMA: devolvido mas marcado como conciliado
        )

# Lançamentos normais de pagamentos confirmados
for pag in pagamentos:
    if pag["id_pagamento"] not in IDS_PAGAMENTO_DEVOLVIDO:
        add_lancamento(
            id_transacao  = None,
            id_fatura     = pag["id_fatura"],
            id_cliente    = pag["id_cliente"],
            data_lanc     = pag["data_pagamento"],
            data_comp     = pag["data_pagamento"],
            valor         = float(pag["valor_pago"]),
            tipo_lanc     = "credito",
            conta_contabil= "2.1.1.01",
            descricao     = f"Pagamento confirmado — id_pagamento {pag['id_pagamento']}",
            origem        = "pagamento",
            status_lanc   = "conciliado",
        )

write_csv("lancamentos_contabeis.csv", lancamentos)

# ─────────────────────────────────────────────
# Resumo das divergências plantadas
# ─────────────────────────────────────────────
print(f"""
╔══════════════════════════════════════════════════════════╗
║         DIVERGÊNCIAS PLANTADAS — RESUMO                 ║
╠══════════════════════════════════════════════════════════╣
║  D1 Transações sem lançamento          {len(IDS_SEM_LANCAMENTO):>4} transações    ║
║  D2 Lançamentos ajuste_manual (sem TX)   50 lançamentos  ║
║  D3 Valor divergente no lançamento     {len(IDS_VALOR_DIVERGENTE):>4} transações    ║
║  D4 Data de competência errada         {len(IDS_DATA_COMPETENCIA):>4} transações    ║
║  D5 Pagamento devolvido + conciliado   {len(IDS_PAGAMENTO_DEVOLVIDO):>4} pagamentos    ║
║  D6 Lançamento duplicado               {len(IDS_DUPLICATA):>4} transações    ║
║  D7 Parcelado incompleto (1 de 3)      {len(IDS_PARCELADO_INCOMPLETO):>4} transações    ║
╚══════════════════════════════════════════════════════════╝

Arquivos gerados em ./data/
Próximo passo: carregar os CSVs no DuckDB (load_banco_un.sql)
""")
