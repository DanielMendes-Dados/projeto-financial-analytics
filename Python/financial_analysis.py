"""
Financial Analytics — Análise em Python
Autor  : Daniel Mendes
Projeto: Financial Analytics Dashboard (SQL Server → Power BI → Python → GitHub)
Saída  : 5 gráficos analíticos com a identidade visual do dashboard, salvos em charts/
"""

import os
import pyodbc
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np

# ─────────────────────────────────────────────
# 1. CONEXÃO
# ─────────────────────────────────────────────
SERVER   = "localhost"       # ex.: localhost\\SQLEXPRESS
DATABASE = "Financial_Analytics"
# Autenticação do Windows (trusted connection)
CONN_STR = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
)
# Alternativa com autenticação SQL:
# CONN_STR += f"UID=seu_usuario;PWD=sua_senha;"

conn = pyodbc.connect(CONN_STR)

# ─────────────────────────────────────────────
# 2. PALETA E TEMA (mesma do Power BI)
# ─────────────────────────────────────────────
BG       = "#0A3D2B"   # verde escuro (fundo)
CARD     = "#0D4F37"   # verde card
GOLD     = "#C9A84C"   # dourado
TEAL     = "#4ECDC4"   # turquesa
ORANGE   = "#E8956D"   # laranja
BLUE     = "#64B5F6"   # azul claro
WHITE70  = "#FFFFFFB3"
WHITE40  = "#FFFFFF66"

PALETTE  = [GOLD, TEAL, ORANGE, BLUE]

# Gráficos salvos em charts/, na raiz do repositório (independe da pasta de execução)
OUTPUT_DIR = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "charts")
os.makedirs(OUTPUT_DIR, exist_ok=True)


def br(valor, casas=1):
    """Formata número no padrão brasileiro (vírgula decimal)."""
    return f"{valor:,.{casas}f}".replace(",", "X").replace(".", ",").replace("X", ".")


def style_axes(ax, title="", xlabel="", ylabel=""):
    """Aplica o tema escuro do dashboard a um gráfico."""
    ax.set_facecolor(CARD)
    ax.tick_params(colors=WHITE70, labelsize=9)
    ax.xaxis.label.set_color(WHITE70)
    ax.yaxis.label.set_color(WHITE70)
    for spine in ax.spines.values():
        spine.set_edgecolor("#FFFFFF15")
    ax.grid(axis="y", color="#FFFFFF12", linewidth=0.6, linestyle="--")
    ax.set_axisbelow(True)
    if title:
        ax.set_title(title, color=GOLD, fontsize=11, fontweight="bold", pad=12)
    if xlabel:
        ax.set_xlabel(xlabel, color=WHITE40, fontsize=9)
    if ylabel:
        ax.set_ylabel(ylabel, color=WHITE40, fontsize=9)


def nota_ano_parcial(fig, anos_parciais):
    """Rodapé explicando anos com menos de 12 meses."""
    if anos_parciais:
        texto = " · ".join(f"*{a}: {m} meses apurados" for a, m in anos_parciais.items())
        fig.text(0.01, 0.01, texto, color=WHITE40, fontsize=8, ha="left")


def save_fig(fig, name):
    path = os.path.join(OUTPUT_DIR, name)
    fig.savefig(path, dpi=150, bbox_inches="tight", facecolor=BG)
    print(f"  ✔  Salvo: charts/{name}")
    plt.close(fig)


# ─────────────────────────────────────────────
# 3. CARGA DOS DADOS
# ─────────────────────────────────────────────
print("Carregando dados do SQL Server…")

df_receita = pd.read_sql("""
    SELECT ano, Linha_Servico, SUM(Receita) AS Receita
    FROM vw_Receita_Composicao
    GROUP BY ano, Linha_Servico
    ORDER BY ano
""", conn)

df_meta = pd.read_sql("""
    SELECT ano, SUM(Receita_Realizada) AS Realizado, SUM(Meta_Anual) AS Meta
    FROM vw_Performance_vs_Meta
    GROUP BY ano
    ORDER BY ano
""", conn)

df_ind = pd.read_sql("""
    SELECT ano, Meses_Apurados,
           Margem_Bruta_Pct   AS Margem_Bruta,
           Margem_EBIT_Pct    AS Margem_EBIT,
           Margem_Liquida_Pct AS Margem_Liquida
    FROM vw_Indicadores_Rentabilidade
    ORDER BY ano
""", conn)

df_despesas = pd.read_sql("""
    SELECT Centro_Custo, SUM(Total_Despesas) AS Total
    FROM vw_Despesas_Centro_Custo
    GROUP BY Centro_Custo
    ORDER BY Total DESC
""", conn)

conn.close()
print("Dados carregados.\n")

# Anos com menos de 12 meses (ex.: 2026 vai até novembro)
parciais = {int(r.ano): int(r.Meses_Apurados) for r in df_ind.itertuples() if r.Meses_Apurados < 12}
rotulo = lambda a: f"{a}*" if int(a) in parciais else str(a)

# ─────────────────────────────────────────────
# GRÁFICO 1 — Receita Bruta por Ano
# ─────────────────────────────────────────────
print("Gráfico 1 — Receita Bruta por Ano…")

receita_anual = df_receita.groupby("ano")["Receita"].sum().reset_index()
completos = receita_anual[~receita_anual["ano"].isin(parciais)]
anos_cagr = len(completos) - 1
cagr = ((completos["Receita"].iloc[-1] / completos["Receita"].iloc[0]) ** (1 / anos_cagr) - 1) * 100

fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)
bars = ax.bar([rotulo(a) for a in receita_anual["ano"]],
              receita_anual["Receita"] / 1_000_000,
              color=GOLD, width=0.55, zorder=3)
for bar in bars:
    h = bar.get_height()
    ax.text(bar.get_x() + bar.get_width() / 2, h + 0.05,
            f"R$ {br(h)} Mi", ha="center", va="bottom",
            color=GOLD, fontsize=9, fontweight="bold")

style_axes(ax,
           title=f"RECEITA BRUTA CRESCE {br(cagr)}% AO ANO "
                 f"({completos['ano'].iloc[0]}–{completos['ano'].iloc[-1]})",
           ylabel="Receita (R$ Mi)")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"R$ {x:.0f} Mi"))
nota_ano_parcial(fig, parciais)
fig.tight_layout(pad=1.5)
save_fig(fig, "01_receita_bruta_anual.png")

# ─────────────────────────────────────────────
# GRÁFICO 2 — Receita por Linha de Serviço (barras empilhadas)
# ─────────────────────────────────────────────
print("Gráfico 2 — Receita por Linha de Serviço…")

pivot = df_receita.pivot_table(index="ano", columns="Linha_Servico",
                               values="Receita", aggfunc="sum").fillna(0)
mix = (pivot.sum() / pivot.sum().sum() * 100).sort_values(ascending=False)
pivot = pivot[mix.index]  # maior linha na base da pilha

x      = np.arange(len(pivot.index))
bottom = np.zeros(len(pivot.index))

fig, ax = plt.subplots(figsize=(11, 5), facecolor=BG)
for i, linha in enumerate(pivot.columns):
    vals = pivot[linha].values / 1_000_000
    ax.bar(x, vals, bottom=bottom, label=f"{linha} ({br(mix[linha], 0)}%)",
           color=PALETTE[i % len(PALETTE)], width=0.55, zorder=3)
    bottom += vals

ax.set_xticks(x)
ax.set_xticklabels([rotulo(a) for a in pivot.index])
ax.legend(loc="upper left", framealpha=0, labelcolor=WHITE70, fontsize=8)
style_axes(ax,
           title=f"MIX DE RECEITA ESTÁVEL: {mix.index[0].upper()} RESPONDE POR {br(mix.iloc[0], 0)}%",
           ylabel="Receita (R$ Mi)")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"R$ {x:.0f} Mi"))
nota_ano_parcial(fig, parciais)
fig.tight_layout(pad=1.5)
save_fig(fig, "02_receita_por_linha.png")

# ─────────────────────────────────────────────
# GRÁFICO 3 — Realizado vs Meta por Ano
# ─────────────────────────────────────────────
print("Gráfico 3 — Realizado vs Meta…")

df_meta["Gap_Pct"] = (df_meta["Realizado"] / df_meta["Meta"] - 1) * 100
gaps_completos = df_meta[~df_meta["ano"].isin(parciais)]["Gap_Pct"].abs()

anos  = [rotulo(a) for a in df_meta["ano"]]
x     = np.arange(len(anos))
width = 0.35

fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)
b1 = ax.bar(x - width/2, df_meta["Realizado"] / 1_000_000, width, label="Realizado", color=TEAL, zorder=3)
b2 = ax.bar(x + width/2, df_meta["Meta"] / 1_000_000,      width, label="Meta",      color=GOLD, zorder=3)

for bar in list(b1) + list(b2):
    h = bar.get_height()
    ax.text(bar.get_x() + bar.get_width() / 2, h + 0.05, br(h),
            ha="center", va="bottom", color=WHITE70, fontsize=8)
for xi, gap in zip(x, df_meta["Gap_Pct"]):
    ax.text(xi - width/2, 0.25, f"{br(gap)}%", ha="center", va="bottom",
            color=BG, fontsize=8, fontweight="bold")

ax.set_xticks(x)
ax.set_xticklabels(anos)
ax.legend(framealpha=0, labelcolor=WHITE70, fontsize=9)
style_axes(ax,
           title=f"RECEITA FICA DE {br(gaps_completos.min(), 0)}% A {br(gaps_completos.max(), 0)}% "
                 f"ABAIXO DA META EM TODOS OS ANOS COMPLETOS",
           ylabel="Receita (R$ Mi)")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"R$ {x:.0f} Mi"))
nota_ano_parcial(fig, parciais)
fig.tight_layout(pad=1.5)
save_fig(fig, "03_realizado_vs_meta.png")

# ─────────────────────────────────────────────
# GRÁFICO 4 — Evolução das Margens (%)
# ─────────────────────────────────────────────
print("Gráfico 4 — Evolução das Margens…")

anos_m  = [rotulo(a) for a in df_ind["ano"]]
margens = {
    "Margem Bruta":   (df_ind["Margem_Bruta"],   GOLD),
    "Margem EBIT":    (df_ind["Margem_EBIT"],    TEAL),
    "Margem Líquida": (df_ind["Margem_Liquida"], ORANGE),
}

fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)
for label, (vals, cor) in margens.items():
    ax.plot(anos_m, vals, marker="o", label=label, color=cor, linewidth=2.2, markersize=5, zorder=3)
    for x_pos, y_val in zip(anos_m, vals):
        ax.text(x_pos, y_val + 0.8, f"{br(y_val)}%", ha="center", va="bottom", color=cor, fontsize=8)

ebit = df_ind["Margem_EBIT"]
ax.legend(framealpha=0, labelcolor=WHITE70, fontsize=9)
style_axes(ax,
           title=f"MARGEM EBIT SOBE DE {br(ebit.iloc[0])}% PARA {br(ebit.iloc[-1])}%",
           ylabel="Margem sobre a receita líquida (%)")
ax.set_ylim(0, df_ind["Margem_Bruta"].max() * 1.15)
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x:.0f}%"))
nota_ano_parcial(fig, parciais)
fig.tight_layout(pad=1.5)
save_fig(fig, "04_evolucao_margens.png")

# ─────────────────────────────────────────────
# GRÁFICO 5 — Custos e Despesas por Centro de Custo
# ─────────────────────────────────────────────
print("Gráfico 5 — Despesas por Centro de Custo…")

participacao = df_despesas["Total"].iloc[0] / df_despesas["Total"].sum() * 100

fig, ax = plt.subplots(figsize=(9, 4), facecolor=BG)
cores = [ORANGE] + [TEAL] * (len(df_despesas) - 1)
bars  = ax.barh(df_despesas["Centro_Custo"], df_despesas["Total"] / 1_000_000,
                color=cores, height=0.55, zorder=3)
for bar in bars:
    w = bar.get_width()
    ax.text(w + 0.1, bar.get_y() + bar.get_height() / 2, f"R$ {br(w)} Mi",
            va="center", color=WHITE70, fontsize=9)

ax.invert_yaxis()
ax.set_xlim(0, df_despesas["Total"].max() / 1_000_000 * 1.2)
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"R$ {x:.0f} Mi"))
ax.tick_params(axis="y", labelsize=9)
style_axes(ax,
           title=f"{df_despesas['Centro_Custo'].iloc[0].upper()} CONCENTRA "
                 f"{br(participacao, 0)}% DOS CUSTOS E DESPESAS",
           xlabel="Total no período (R$ Mi)")
ax.grid(axis="x", color="#FFFFFF12", linewidth=0.6, linestyle="--")
ax.grid(axis="y", visible=False)
fig.tight_layout(pad=1.5)
save_fig(fig, "05_despesas_centro_custo.png")

# ─────────────────────────────────────────────
print("\n✅  5 gráficos salvos em charts/.")
