# 📊 Financial Analytics Dashboard

> Pipeline completo de Análise Financeira: SQL Server → Power BI → Python

![Power BI](https://img.shields.io/badge/Power%20BI-F2C811?style=for-the-badge&logo=powerbi&logoColor=black)
![SQL Server](https://img.shields.io/badge/SQL%20Server-CC2927?style=for-the-badge&logo=microsoftsqlserver&logoColor=white)
![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![pandas](https://img.shields.io/badge/pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)
![matplotlib](https://img.shields.io/badge/matplotlib-11557c?style=for-the-badge&logo=python&logoColor=white)

---

## 🎯 Sobre o Projeto

Dashboard financeiro interativo desenvolvido como projeto de portfólio, cobrindo o ciclo completo de análise de dados — desde a modelagem em SQL Server até a visualização em Power BI e análise exploratória em Python.

O projeto simula o ambiente analítico de uma empresa de tecnologia/consultoria SAP com receita anual na faixa de R$ 5–7 Mi, abrangendo 4 páginas analíticas integradas e navegação fluida entre visões estratégicas.

---

## 🏗️ Arquitetura do Pipeline

```
SQL Server (Views)  →  Power BI (Dashboard)  →  Python (Análise)  →  GitHub
      ↓                        ↓                       ↓
  Modelagem               Storytelling            Visualizações
  com Views               com 4 páginas           matplotlib
```

---

## 📁 Estrutura do Repositório

```
financial-analytics/
│
├── sql/                          # Views SQL do projeto
│   ├── vw_DRE_Anual.sql
│   ├── vw_Receita_Composicao.sql
│   ├── vw_Performance_vs_Meta.sql
│   ├── vw_Indicadores_Rentabilidade.sql
│   └── vw_Despesas_Centro_Custo.sql
│
├── python/                       # Script de análise Python
│   └── financial_analysis.py
│
├── Backgrounds/                  # Backgrounds customizados do dashboard
│   ├── bg_01_inicio.png
│   ├── bg_02_dre.png
│   ├── bg_03_receita.png
│   └── bg_04_rentabilidade.png
│
├── charts/                       # Gráficos gerados via Python
│   ├── 01_receita_bruta_anual.png
│   ├── 02_receita_por_linha.png
│   ├── 03_realizado_vs_meta.png
│   ├── 04_evolucao_margens.png
│   └── 05_despesas_centro_custo.png
│
├── screenshots/                  # Capturas das páginas do dashboard Power BI
│   ├── pg_01_inicio.png
│   ├── pg_02_dre.png
│   ├── pg_03_receita.png
│   └── pg_04_rentabilidade.png
│
└── README.md
```

---

## 📊 Páginas do Dashboard

### 1 — Início
Visão consolidada com KPIs estratégicos: Receita Bruta, Margem Líquida, EBIT e Lucro Líquido do período selecionado. Navegação central para as demais páginas analíticas.

### 2 — DRE (Demonstração do Resultado)
Análise da Demonstração do Resultado do Exercício com evolução anual de receitas, custos e resultado líquido. Comparativo entre anos com indicadores de variação.

### 3 — Receita
Decomposição da receita bruta por linha de serviço (Consultoria SAP, Suporte AMS, Licenças de Software, Manutenção de Sistemas) com análise de participação percentual e desempenho vs. meta anual.

### 4 — Rentabilidade
Evolução das margens (Bruta, EBIT e Líquida) ao longo dos anos, indicadores anuais consolidados e análise de despesas por centro de custo.

---

## 🐍 Análise Python

Script independente que conecta diretamente ao SQL Server via `pyodbc` e gera 5 visualizações analíticas em matplotlib com identidade visual alinhada ao dashboard:

| # | Gráfico | Tipo |
|---|---------|------|
| 01 | Evolução da Receita Bruta Anual | Barras verticais |
| 02 | Receita por Linha de Serviço | Barras empilhadas |
| 03 | Realizado vs Meta Anual | Colunas agrupadas |
| 04 | Evolução das Margens (%) | Gráfico de linhas |
| 05 | Despesas por Centro de Custo | Barras horizontais |

### Como executar

```bash
# 1. Criar e ativar ambiente virtual
python -m venv venv
venv\Scripts\activate          # Windows

# 2. Instalar dependências
pip install pyodbc pandas matplotlib numpy

# 3. Configurar conexão em financial_analysis.py
SERVER   = "localhost"         # seu servidor SQL Server
DATABASE = "Financial_Analytics"

# 4. Executar
python financial_analysis.py
# → Gráficos salvos em charts/
```

---

## 🎨 Identidade Visual

Paleta de cores aplicada de forma consistente no Power BI e no Python:

| Cor | Hex | Uso |
|-----|-----|-----|
| Verde Escuro | `#0A3D2B` | Fundo principal |
| Verde Card | `#0D4F37` | Cards e áreas de gráfico |
| Dourado | `#C9A84C` | Destaques e títulos |
| Turquesa | `#4ECDC4` | Série de dados 2 |
| Laranja | `#E8956D` | Série de dados 3 |
| Azul Claro | `#64B5F6` | Série de dados 4 |

---

## 🛠️ Stack Tecnológica

| Camada | Tecnologia |
|--------|-----------|
| Banco de dados | SQL Server 17 |
| Modelagem | Views SQL (5 views analíticas) |
| Visualização | Power BI Desktop |
| Análise | Python 3 · pandas · matplotlib · pyodbc · numpy |
| Versionamento | Git · GitHub |

---

## 👤 Autor

**Daniel Mendes**  
Analista de Dados | Power BI · SQL · Python  
[LinkedIn](https://www.linkedin.com/in/danielmendes-dados) · [GitHub](https://github.com/DanielMendes-Dados)

---

*Projeto desenvolvido para portfólio profissional — dados simulados.*
