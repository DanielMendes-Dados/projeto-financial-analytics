"""
Financial Analytics — Python Analysis Script
Author : Daniel Mendes
Project: Financial Analytics Dashboard (SQL Server → Power BI → Python → GitHub)
Charts : 5 analytical visualizations matching the dashboard color identity
"""

import pyodbc
import pandas as pd
import matplotlib.pyplot as plt
import matplotlib.ticker as mticker
import numpy as np
import os

# ─────────────────────────────────────────────
# 1. CONNECTION
# ─────────────────────────────────────────────
SERVER   = "localhost"       # e.g. localhost\\SQLEXPRESS
DATABASE = "Financial_Analytics"
# Windows Auth (trusted connection) — remove UID/PWD lines if using SQL Auth
CONN_STR = (
    f"DRIVER={{ODBC Driver 17 for SQL Server}};"
    f"SERVER={SERVER};"
    f"DATABASE={DATABASE};"
    f"Trusted_Connection=yes;"
)
# SQL Auth alternative:
# CONN_STR += f"UID=your_user;PWD=your_password;"

conn = pyodbc.connect(CONN_STR)

# ─────────────────────────────────────────────
# 2. PALETTE & THEME
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

OUTPUT_DIR = "charts"
os.makedirs(OUTPUT_DIR, exist_ok=True)

def style_axes(ax, title="", xlabel="", ylabel=""):
    """Apply dashboard dark theme to any axes."""
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

def save_fig(fig, name):
    path = os.path.join(OUTPUT_DIR, name)
    fig.savefig(path, dpi=150, bbox_inches="tight", facecolor=BG)
    print(f"  ✔  Saved: {path}")
    plt.close(fig)

# ─────────────────────────────────────────────
# 3. LOAD DATA
# ─────────────────────────────────────────────
print("Loading data from SQL Server…")

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

df_margem = pd.read_sql("""
    SELECT ano,
           Margem_Bruta_Media_Pct  AS Margem_Bruta,
           Margem_EBIT_Media_Pct   AS Margem_EBIT,
           Margem_Liquida_Media_Pct AS Margem_Liquida
    FROM vw_Indicadores_Rentabilidade
    ORDER BY ano
""", conn)

df_despesas = pd.read_sql("""
    SELECT Centro_Custo, SUM(Total_Despesas) AS Total
    FROM vw_Despesas_Centro_Custo
    GROUP BY Centro_Custo
    ORDER BY Total DESC
""", conn)

df_composicao = pd.read_sql("""
    SELECT Linha_Servico, AVG(Participacao_Pct) AS Participacao
    FROM vw_Receita_Composicao
    GROUP BY Linha_Servico
    ORDER BY Participacao DESC
""", conn)

conn.close()
print("Data loaded.\n")

# ─────────────────────────────────────────────
# CHART 1 — Evolução da Receita Bruta por Ano
# ─────────────────────────────────────────────
print("Chart 1 — Receita Bruta por Ano…")

receita_anual = df_receita.groupby("ano")["Receita"].sum().reset_index()

fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)
bars = ax.bar(receita_anual["ano"].astype(str),
              receita_anual["Receita"] / 1_000_000,
              color=GOLD, width=0.55, zorder=3)

# value labels
for bar in bars:
    h = bar.get_height()
    ax.text(bar.get_x() + bar.get_width() / 2, h + 0.05,
            f"R$ {h:.1f} Mi", ha="center", va="bottom",
            color=GOLD, fontsize=9, fontweight="bold")

style_axes(ax,
           title="EVOLUÇÃO DA RECEITA BRUTA (2022–2026)",
           ylabel="Receita (R$ Mi)")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"R$ {x:.0f} Mi"))
fig.tight_layout(pad=1.5)
save_fig(fig, "01_receita_bruta_anual.png")

# ─────────────────────────────────────────────
# CHART 2 — Receita por Linha de Serviço (Stacked Bars)
# ─────────────────────────────────────────────
print("Chart 2 — Receita por Linha de Serviço…")

pivot = df_receita.pivot_table(
    index="ano", columns="Linha_Servico", values="Receita", aggfunc="sum"
).fillna(0)

anos   = pivot.index.astype(str)
linhas = pivot.columns.tolist()
x      = np.arange(len(anos))
bottom = np.zeros(len(anos))

fig, ax = plt.subplots(figsize=(11, 5), facecolor=BG)

for i, linha in enumerate(linhas):
    vals = pivot[linha].values / 1_000_000
    bars = ax.bar(x, vals, bottom=bottom, label=linha,
                  color=PALETTE[i % len(PALETTE)], width=0.55, zorder=3)
    bottom += vals

ax.set_xticks(x)
ax.set_xticklabels(anos)
legend = ax.legend(loc="upper left", framealpha=0,
                   labelcolor=WHITE70, fontsize=8)
style_axes(ax,
           title="RECEITA POR LINHA DE SERVIÇO — BARRAS EMPILHADAS",
           ylabel="Receita (R$ Mi)")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"R$ {x:.0f} Mi"))
fig.tight_layout(pad=1.5)
save_fig(fig, "02_receita_por_linha.png")

# ─────────────────────────────────────────────
# CHART 3 — Realizado vs Meta por Ano
# ─────────────────────────────────────────────
print("Chart 3 — Realizado vs Meta…")

anos  = df_meta["ano"].astype(str).tolist()
x     = np.arange(len(anos))
width = 0.35

fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)

b1 = ax.bar(x - width/2, df_meta["Realizado"] / 1_000_000,
            width, label="Realizado", color=TEAL, zorder=3)
b2 = ax.bar(x + width/2, df_meta["Meta"] / 1_000_000,
            width, label="Meta", color=GOLD, zorder=3)

for bar in list(b1) + list(b2):
    h = bar.get_height()
    ax.text(bar.get_x() + bar.get_width() / 2, h + 0.05,
            f"{h:.1f}", ha="center", va="bottom",
            color=WHITE70, fontsize=8)

ax.set_xticks(x)
ax.set_xticklabels(anos)
ax.legend(framealpha=0, labelcolor=WHITE70, fontsize=9)
style_axes(ax,
           title="REALIZADO VS META ANUAL (R$ Mi)",
           ylabel="Receita (R$ Mi)")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"R$ {x:.0f} Mi"))
fig.tight_layout(pad=1.5)
save_fig(fig, "03_realizado_vs_meta.png")

# ─────────────────────────────────────────────
# CHART 4 — Evolução das Margens (%)
# ─────────────────────────────────────────────
print("Chart 4 — Evolução das Margens…")

anos_m   = df_margem["ano"].astype(str).tolist()
margens  = {
    "Margem Bruta":   (df_margem["Margem_Bruta"],  GOLD),
    "Margem EBIT":    (df_margem["Margem_EBIT"],   TEAL),
    "Margem Líquida": (df_margem["Margem_Liquida"], ORANGE),
}

fig, ax = plt.subplots(figsize=(10, 5), facecolor=BG)

for label, (vals, cor) in margens.items():
    ax.plot(anos_m, vals, marker="o", label=label,
            color=cor, linewidth=2.2, markersize=5, zorder=3)
    for x_pos, y_val in zip(anos_m, vals):
        ax.text(x_pos, y_val + 0.3, f"{y_val:.1f}%",
                ha="center", va="bottom", color=cor, fontsize=8)

ax.legend(framealpha=0, labelcolor=WHITE70, fontsize=9)
style_axes(ax,
           title="EVOLUÇÃO DAS MARGENS ANUAIS (%)",
           ylabel="Margem (%)")
ax.yaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"{x:.1f}%"))
fig.tight_layout(pad=1.5)
save_fig(fig, "04_evolucao_margens.png")

# ─────────────────────────────────────────────
# CHART 5 — Despesas por Centro de Custo
# ─────────────────────────────────────────────
print("Chart 5 — Despesas por Centro de Custo…")

fig, ax = plt.subplots(figsize=(9, 4), facecolor=BG)

cores = [ORANGE, GOLD, TEAL, BLUE]
bars  = ax.barh(df_despesas["Centro_Custo"],
                df_despesas["Total"] / 1_000_000,
                color=cores[:len(df_despesas)], height=0.55, zorder=3)

for bar in bars:
    w = bar.get_width()
    ax.text(w + 0.1, bar.get_y() + bar.get_height() / 2,
            f"R$ {w:.1f} Mi", va="center", color=WHITE70, fontsize=9)

ax.invert_yaxis()
ax.xaxis.set_major_formatter(mticker.FuncFormatter(lambda x, _: f"R$ {x:.0f} Mi"))
ax.tick_params(axis="y", labelsize=9)
style_axes(ax,
           title="DESPESAS POR CENTRO DE CUSTO (R$ Mi)",
           xlabel="Total (R$ Mi)")
ax.grid(axis="x", color="#FFFFFF12", linewidth=0.6, linestyle="--")
ax.grid(axis="y", visible=False)
fig.tight_layout(pad=1.5)
save_fig(fig, "05_despesas_centro_custo.png")

# ─────────────────────────────────────────────
print(f"\n✅  All 5 charts saved to '{OUTPUT_DIR}/' folder.")
