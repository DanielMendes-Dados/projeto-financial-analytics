-- =============================================================================
-- PROJETO FINANCIAL ANALYTICS
-- Banco de Dados: Financial_Analytics
-- Tabelas: Plano_Contas, Centro_Custo, Lancamentos_Financeiros, Metas_Anuais
-- Views: vw_DRE, vw_Indicadores_Rentabilidade, vw_Receita_Composicao,
--        vw_Despesas_Centro_Custo, vw_Performance_vs_Meta, vw_Painel_Executivo_Financeiro
-- Período: Jan/2022 – Nov/2026 (data final fixa, para a base ser reproduzível)
-- Autor: Daniel Mendes
-- =============================================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'Financial_Analytics')
    DROP DATABASE Financial_Analytics;
CREATE DATABASE Financial_Analytics;
GO

USE Financial_Analytics;
GO

-- =============================================================================
-- TABELA 1: PLANO_CONTAS (estrutura DRE)
-- =============================================================================

CREATE TABLE Plano_Contas (
    id_conta     INT IDENTITY(1,1) PRIMARY KEY,
    codigo       VARCHAR(10)   NOT NULL,
    nome_conta   VARCHAR(100)  NOT NULL,
    grupo        VARCHAR(50)   NOT NULL,   -- RECEITA | CUSTO | DESPESA | RES_FINANCEIRO | IMPOSTO
    subgrupo     VARCHAR(50)   NOT NULL,
    tipo_dre     VARCHAR(10)   NOT NULL,   -- POSITIVO | NEGATIVO
    ordem_dre    TINYINT       NOT NULL
);
GO

-- =============================================================================
-- TABELA 2: CENTRO_CUSTO
-- =============================================================================

CREATE TABLE Centro_Custo (
    id_centro   INT IDENTITY(1,1) PRIMARY KEY,
    codigo      VARCHAR(10)  NOT NULL,
    nome_centro VARCHAR(100) NOT NULL,
    responsavel VARCHAR(100) NOT NULL
);
GO

-- =============================================================================
-- TABELA 3: LANCAMENTOS_FINANCEIROS (tabela fato)
-- =============================================================================

CREATE TABLE Lancamentos_Financeiros (
    id_lancamento INT IDENTITY(1,1) PRIMARY KEY,
    data_ref      DATE          NOT NULL,
    id_conta      INT           NOT NULL REFERENCES Plano_Contas(id_conta),
    id_centro     INT                    REFERENCES Centro_Custo(id_centro),
    descricao     VARCHAR(200)  NOT NULL,
    valor         DECIMAL(15,2) NOT NULL,
    tipo          VARCHAR(20)   NOT NULL DEFAULT 'Realizado',  -- Realizado | Orcado
    mes           TINYINT       NOT NULL,
    ano           SMALLINT      NOT NULL
);
GO

-- =============================================================================
-- TABELA 4: METAS_ANUAIS
-- =============================================================================

CREATE TABLE Metas_Anuais (
    id_meta          INT IDENTITY(1,1) PRIMARY KEY,
    ano              SMALLINT      NOT NULL,
    id_conta         INT           NOT NULL REFERENCES Plano_Contas(id_conta),
    valor_meta_anual DECIMAL(15,2) NOT NULL
);
GO

-- =============================================================================
-- DADOS: PLANO DE CONTAS (DRE completo)
-- =============================================================================

INSERT INTO Plano_Contas (codigo, nome_conta, grupo, subgrupo, tipo_dre, ordem_dre) VALUES
-- RECEITAS
('1.1.1', 'Licenças de Software',        'RECEITA',       'Receita Bruta', 'POSITIVO',  1),
('1.1.2', 'Consultoria SAP',             'RECEITA',       'Receita Bruta', 'POSITIVO',  2),
('1.1.3', 'Suporte AMS',                 'RECEITA',       'Receita Bruta', 'POSITIVO',  3),
('1.1.4', 'Manutenção de Sistemas',      'RECEITA',       'Receita Bruta', 'POSITIVO',  4),
-- DEDUÇÕES DA RECEITA
('1.2.1', 'ISS',                         'RECEITA',       'Deducoes',      'NEGATIVO',  5),
('1.2.2', 'PIS / COFINS',                'RECEITA',       'Deducoes',      'NEGATIVO',  6),
('1.2.3', 'Outros Tributos s/ Receita',  'RECEITA',       'Deducoes',      'NEGATIVO',  7),
-- CUSTO DOS SERVIÇOS PRESTADOS
('2.1.1', 'Pessoal Técnico',             'CUSTO',         'CSP',           'NEGATIVO',  8),
('2.1.2', 'Infraestrutura de TI',        'CUSTO',         'CSP',           'NEGATIVO',  9),
('2.1.3', 'Licenças de Terceiros',       'CUSTO',         'CSP',           'NEGATIVO', 10),
-- DESPESAS OPERACIONAIS
('3.1.1', 'Comissões Comerciais',        'DESPESA',       'Comercial',     'NEGATIVO', 11),
('3.1.2', 'Marketing e Eventos',         'DESPESA',       'Comercial',     'NEGATIVO', 12),
('3.2.1', 'Pessoal Administrativo',      'DESPESA',       'Administrativo','NEGATIVO', 13),
('3.2.2', 'Aluguel e Utilities',         'DESPESA',       'Administrativo','NEGATIVO', 14),
('3.2.3', 'Serviços de Terceiros',       'DESPESA',       'Administrativo','NEGATIVO', 15),
('3.3.1', 'Pesquisa e Desenvolvimento',  'DESPESA',       'P&D',           'NEGATIVO', 16),
-- RESULTADO FINANCEIRO
('4.1.1', 'Receitas Financeiras',        'RES_FINANCEIRO','Financeiro',    'POSITIVO', 17),
('4.2.1', 'Despesas Financeiras',        'RES_FINANCEIRO','Financeiro',    'NEGATIVO', 18),
-- IMPOSTOS SOBRE O LUCRO
('5.1.1', 'IR / CSLL',                   'IMPOSTO',       'Impostos',      'NEGATIVO', 19);
GO

-- =============================================================================
-- DADOS: CENTROS DE CUSTO
-- =============================================================================

INSERT INTO Centro_Custo (codigo, nome_centro, responsavel) VALUES
('CC01', 'Desenvolvimento',  'Rafael Souza'),
('CC02', 'Comercial',        'Ana Lima'),
('CC03', 'Administrativo',   'Carla Oliveira'),
('CC04', 'Suporte Técnico',  'Marcos Pinto'),
('CC05', 'Diretoria',        'CEO / Presidência'),
('CC06', 'P&D',              'Lucas Ferreira');
GO

-- =============================================================================
-- DADOS: LANÇAMENTOS FINANCEIROS (Jan/2022 – Nov/2026)
-- Geração via CTE com fatores de crescimento e sazonalidade
-- Receita Bruta base 2022: R$ 420.000/mês | Crescimento ~12% a.a.
-- =============================================================================

WITH
-- Período válido: Jan/2022 a Nov/2026
-- Data final fixa (em vez de GETDATE()) para que a base gerada seja sempre a mesma,
-- independentemente do dia em que o script for executado
Datas AS (
    SELECT ano, mes, DATEFROMPARTS(ano, mes, 1) AS data_ref
    FROM (VALUES (2022),(2023),(2024),(2025),(2026)) v(ano)
    CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) m(mes)
    WHERE DATEFROMPARTS(ano, mes, 1) <= DATEFROMPARTS(2026, 11, 1)
),
-- Fator de crescimento anual (base 2022 = 1.00)
Crescimento AS (
    SELECT ano,
        -- fc: crescimento da receita e custos variáveis (~12% a.a.)
        CASE ano
            WHEN 2022 THEN 1.000
            WHEN 2023 THEN 1.107
            WHEN 2024 THEN 1.238
            WHEN 2025 THEN 1.400
            WHEN 2026 THEN 1.571
        END AS fc,
        -- fc_fixo: crescimento de custos fixos (~6% a.a. — reajuste salarial e aluguel)
        CASE ano
            WHEN 2022 THEN 1.000
            WHEN 2023 THEN 1.060
            WHEN 2024 THEN 1.124
            WHEN 2025 THEN 1.191
            WHEN 2026 THEN 1.262
        END AS fc_fixo
    FROM (VALUES (2022),(2023),(2024),(2025),(2026)) v(ano)
),
-- Fator sazonal mensal (padrão empresa B2B tech)
Sazonal AS (
    SELECT mes,
        CASE mes
            WHEN  1 THEN 0.88  -- Janeiro fraco (planejamento)
            WHEN  2 THEN 0.91  -- Fevereiro recuperando
            WHEN  3 THEN 1.03  -- Março bom (Q1 fechamento)
            WHEN  4 THEN 1.05  -- Abril forte
            WHEN  5 THEN 1.04  -- Maio forte
            WHEN  6 THEN 0.99  -- Junho (meio do ano)
            WHEN  7 THEN 0.95  -- Julho fraco (férias)
            WHEN  8 THEN 0.97  -- Agosto recuperando
            WHEN  9 THEN 1.04  -- Setembro (Q3 fechamento)
            WHEN 10 THEN 1.06  -- Outubro forte
            WHEN 11 THEN 1.08  -- Novembro pico
            WHEN 12 THEN 0.88  -- Dezembro fraco (festas)
        END AS fs
    FROM (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) m(mes)
),
-- Fator especial: eventos pontuais
FatorEspecial AS (
    SELECT ano, mes,
        CASE
            WHEN ano = 2023 AND mes BETWEEN 7 AND 9 THEN 0.93  -- crise pontual Q3/2023
            WHEN ano = 2024 AND mes BETWEEN 4 AND 6 THEN 1.05  -- novos contratos Q2/2024
            WHEN ano = 2026 AND mes >= 6            THEN 1.04  -- aceleração 2026
            ELSE 1.00
        END AS fe
    FROM (VALUES (2022),(2023),(2024),(2025),(2026)) v(ano)
    CROSS JOIN (VALUES (1),(2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12)) m(mes)
),
-- Valores base mensais por conta (base = media 2022)
-- Receita Bruta total base: R$ 420.000/mês
Contas AS (
    SELECT
        id_conta, codigo, grupo, subgrupo,
        CAST(CASE codigo
            -- RECEITAS (% da receita bruta base R$420k)
            WHEN '1.1.1' THEN 159600.00   -- 38% Licenças
            WHEN '1.1.2' THEN 117600.00   -- 28% Consultoria
            WHEN '1.1.3' THEN 100800.00   -- 24% Suporte AMS
            WHEN '1.1.4' THEN  42000.00   -- 10% Manutenção
            -- DEDUÇÕES (~14% rec bruta → ~R$58.800)
            WHEN '1.2.1' THEN  21000.00   --  5% ISS
            WHEN '1.2.2' THEN  31920.00   --  7,6% PIS/COFINS
            WHEN '1.2.3' THEN   5880.00   --  1,4% outros
            -- CUSTO DOS SERVIÇOS (rec líquida ~R$361.200 | CSP ~42%)
            WHEN '2.1.1' THEN 115584.00   -- 32% pessoal técnico
            WHEN '2.1.2' THEN  25284.00   --  7% infra TI
            WHEN '2.1.3' THEN  10836.00   --  3% licenças terceiros
            -- DESPESAS OPERACIONAIS (rec líquida ~28%)
            WHEN '3.1.1' THEN  28896.00   --  8% comissões
            WHEN '3.1.2' THEN   7224.00   --  2% marketing
            WHEN '3.2.1' THEN  36120.00   -- 10% pessoal adm
            WHEN '3.2.2' THEN  14448.00   --  4% aluguel/utilities
            WHEN '3.2.3' THEN  14448.00   --  4% terceiros
            WHEN '3.3.1' THEN   7224.00   --  2% P&D
            -- RESULTADO FINANCEIRO
            WHEN '4.1.1' THEN   3612.00   --  1% rec financeira
            WHEN '4.2.1' THEN   7224.00   --  2% desp financeira
            -- IMPOSTOS SOBRE O LUCRO (~30% do LAIR estimado R$55k)
            WHEN '5.1.1' THEN  16500.00
            ELSE 0
        END AS DECIMAL(15,2)) AS valor_base,
        CASE codigo
            WHEN '1.1.1' THEN 1  WHEN '1.1.2' THEN 2  WHEN '1.1.3' THEN 4
            WHEN '1.1.4' THEN 4  WHEN '1.2.1' THEN 3  WHEN '1.2.2' THEN 3
            WHEN '1.2.3' THEN 3  WHEN '2.1.1' THEN 1  WHEN '2.1.2' THEN 1
            WHEN '2.1.3' THEN 1  WHEN '3.1.1' THEN 2  WHEN '3.1.2' THEN 2
            WHEN '3.2.1' THEN 3  WHEN '3.2.2' THEN 3  WHEN '3.2.3' THEN 3
            WHEN '3.3.1' THEN 6  WHEN '4.1.1' THEN 5  WHEN '4.2.1' THEN 5
            WHEN '5.1.1' THEN 5  ELSE 5
        END AS id_centro_padrao,
        -- Classificação do comportamento do custo
        -- VARIAVEL: acompanha receita 100% (sazonalidade + crescimento)
        -- SEMI_FIXO: acompanha 40% da variação sazonal (pessoal técnico, marketing)
        -- FIXO: cresce só 6%/ano, sem sazonalidade (aluguel, pessoal adm, P&D)
        CASE codigo
            WHEN '1.2.1' THEN 'VARIAVEL'   -- ISS (% receita)
            WHEN '1.2.2' THEN 'VARIAVEL'   -- PIS/COFINS (% receita)
            WHEN '1.2.3' THEN 'VARIAVEL'   -- Outros tributos (% receita)
            WHEN '3.1.1' THEN 'VARIAVEL'   -- Comissões (% vendas)
            WHEN '2.1.1' THEN 'SEMI_FIXO'  -- Pessoal Técnico (folha + variável)
            WHEN '2.1.3' THEN 'SEMI_FIXO'  -- Licenças Terceiros
            WHEN '3.1.2' THEN 'SEMI_FIXO'  -- Marketing
            WHEN '3.2.3' THEN 'SEMI_FIXO'  -- Serviços Terceiros
            WHEN '4.2.1' THEN 'SEMI_FIXO'  -- Despesas Financeiras
            WHEN '5.1.1' THEN 'SEMI_FIXO'  -- IR/CSLL
            WHEN '2.1.2' THEN 'FIXO'       -- Infra TI (contratos anuais)
            WHEN '3.2.1' THEN 'FIXO'       -- Pessoal Administrativo (folha fixa)
            WHEN '3.2.2' THEN 'FIXO'       -- Aluguel e Utilities (contrato fixo)
            WHEN '3.3.1' THEN 'FIXO'       -- P&D (orçamento anual)
            WHEN '4.1.1' THEN 'FIXO'       -- Receitas Financeiras
            ELSE 'VARIAVEL'
        END AS tipo_custo
    FROM Plano_Contas
)
INSERT INTO Lancamentos_Financeiros
    (data_ref, id_conta, id_centro, descricao, valor, tipo, mes, ano)
SELECT
    d.data_ref,
    c.id_conta,
    c.id_centro_padrao,
    c.grupo + ' | ' + c.subgrupo AS descricao,
    ROUND(
        CASE c.tipo_custo
            -- Variável: segue receita completamente (sazonalidade + crescimento + evento)
            WHEN 'VARIAVEL'  THEN c.valor_base * cr.fc * s.fs * fe.fe
            -- Semi-fixo: 60% fixo + 40% da variação sazonal/evento
            WHEN 'SEMI_FIXO' THEN c.valor_base * cr.fc
                                  * (1 + (s.fs  - 1) * 0.40)
                                  * (1 + (fe.fe - 1) * 0.40)
            -- Fixo: cresce só pelo fc_fixo (~6%/a.a.), sem sazonalidade
            WHEN 'FIXO'      THEN c.valor_base * cr.fc_fixo
        END, 2) AS valor,
    'Realizado',
    d.mes,
    d.ano
FROM Datas d
JOIN Crescimento   cr ON cr.ano = d.ano
JOIN Sazonal        s ON s.mes  = d.mes
JOIN FatorEspecial fe ON fe.ano = d.ano AND fe.mes = d.mes
CROSS JOIN Contas   c
WHERE c.valor_base > 0;
GO

-- =============================================================================
-- DADOS: METAS ANUAIS (Receita Bruta | meta ~15% acima do realizado projetado)
-- =============================================================================

INSERT INTO Metas_Anuais (ano, id_conta, valor_meta_anual)
SELECT
    anos.ano,
    pc.id_conta,
    base.valor_base * 12 *
        CASE anos.ano
            WHEN 2022 THEN 1.08
            WHEN 2023 THEN 1.22
            WHEN 2024 THEN 1.38
            WHEN 2025 THEN 1.56
            WHEN 2026 THEN 1.75
        END AS valor_meta_anual
FROM Plano_Contas pc
JOIN (VALUES
    ('1.1.1', 159600.00),
    ('1.1.2', 117600.00),
    ('1.1.3', 100800.00),
    ('1.1.4',  42000.00)
) AS base(codigo, valor_base) ON base.codigo = pc.codigo
CROSS JOIN (VALUES (2022),(2023),(2024),(2025),(2026)) anos(ano);
GO

-- =============================================================================
-- VIEW 1: vw_DRE — Demonstração do Resultado do Exercício (mensal)
-- =============================================================================

CREATE OR ALTER VIEW vw_DRE AS
WITH Base AS (
    SELECT
        lf.ano, lf.mes, lf.data_ref,
        pc.grupo, pc.subgrupo, pc.tipo_dre,
        SUM(lf.valor) AS vl
    FROM Lancamentos_Financeiros lf
    JOIN Plano_Contas pc ON pc.id_conta = lf.id_conta
    WHERE lf.tipo = 'Realizado'
    GROUP BY lf.ano, lf.mes, lf.data_ref, pc.grupo, pc.subgrupo, pc.tipo_dre
),
Calculo AS (
    SELECT
        ano, mes, data_ref,
        SUM(CASE WHEN grupo = 'RECEITA'        AND subgrupo = 'Receita Bruta' THEN vl ELSE 0 END) AS Receita_Bruta,
        SUM(CASE WHEN grupo = 'RECEITA'        AND subgrupo = 'Deducoes'      THEN vl ELSE 0 END) AS Deducoes,
        SUM(CASE WHEN grupo = 'CUSTO'                                          THEN vl ELSE 0 END) AS Custo_Servicos,
        SUM(CASE WHEN grupo = 'DESPESA'        AND subgrupo = 'Comercial'     THEN vl ELSE 0 END) AS Desp_Comercial,
        SUM(CASE WHEN grupo = 'DESPESA'        AND subgrupo = 'Administrativo'THEN vl ELSE 0 END) AS Desp_Administrativa,
        SUM(CASE WHEN grupo = 'DESPESA'        AND subgrupo = 'P&D'           THEN vl ELSE 0 END) AS Desp_PD,
        SUM(CASE WHEN grupo = 'RES_FINANCEIRO' AND tipo_dre = 'POSITIVO'      THEN vl ELSE 0 END) AS Rec_Financeira,
        SUM(CASE WHEN grupo = 'RES_FINANCEIRO' AND tipo_dre = 'NEGATIVO'      THEN vl ELSE 0 END) AS Desp_Financeira,
        SUM(CASE WHEN grupo = 'IMPOSTO'                                        THEN vl ELSE 0 END) AS IR_CSLL
    FROM Base
    GROUP BY ano, mes, data_ref
)
SELECT
    ano, mes, data_ref,
    Receita_Bruta,
    Deducoes,
    Receita_Bruta - Deducoes                                                                                        AS Receita_Liquida,
    Custo_Servicos,
    Receita_Bruta - Deducoes - Custo_Servicos                                                                       AS Lucro_Bruto,
    Desp_Comercial + Desp_Administrativa + Desp_PD                                                                  AS Despesas_Operacionais,
    Receita_Bruta - Deducoes - Custo_Servicos - (Desp_Comercial + Desp_Administrativa + Desp_PD)                    AS EBIT,
    Rec_Financeira - Desp_Financeira                                                                                AS Resultado_Financeiro,
    Receita_Bruta - Deducoes - Custo_Servicos - (Desp_Comercial + Desp_Administrativa + Desp_PD)
        + (Rec_Financeira - Desp_Financeira)                                                                        AS LAIR,
    IR_CSLL,
    Receita_Bruta - Deducoes - Custo_Servicos - (Desp_Comercial + Desp_Administrativa + Desp_PD)
        + (Rec_Financeira - Desp_Financeira) - IR_CSLL                                                              AS Lucro_Liquido,
    -- MARGENS (% sobre Receita Líquida)
    ROUND(CASE WHEN (Receita_Bruta - Deducoes) > 0 THEN
        (Receita_Bruta - Deducoes - Custo_Servicos) / (Receita_Bruta - Deducoes) * 100 END, 2)                      AS Margem_Bruta_Pct,
    ROUND(CASE WHEN (Receita_Bruta - Deducoes) > 0 THEN
        (Receita_Bruta - Deducoes - Custo_Servicos - (Desp_Comercial + Desp_Administrativa + Desp_PD))
        / (Receita_Bruta - Deducoes) * 100 END, 2)                                                                  AS Margem_EBIT_Pct,
    ROUND(CASE WHEN (Receita_Bruta - Deducoes) > 0 THEN
        (Receita_Bruta - Deducoes - Custo_Servicos - (Desp_Comercial + Desp_Administrativa + Desp_PD)
        + (Rec_Financeira - Desp_Financeira) - IR_CSLL)
        / (Receita_Bruta - Deducoes) * 100 END, 2)                                                                  AS Margem_Liquida_Pct
FROM Calculo;
GO

-- =============================================================================
-- VIEW 2: vw_Receita_Composicao — Receita Bruta por Linha de Serviço (mensal)
-- =============================================================================

CREATE OR ALTER VIEW vw_Receita_Composicao AS
SELECT
    lf.ano,
    lf.mes,
    lf.data_ref,
    pc.nome_conta                        AS Linha_Servico,
    SUM(lf.valor)                        AS Receita,
    ROUND(SUM(lf.valor) /
        SUM(SUM(lf.valor)) OVER (PARTITION BY lf.ano, lf.mes) * 100, 2) AS Participacao_Pct
FROM Lancamentos_Financeiros lf
JOIN Plano_Contas pc ON pc.id_conta = lf.id_conta
WHERE lf.tipo = 'Realizado'
  AND pc.grupo = 'RECEITA'
  AND pc.subgrupo = 'Receita Bruta'
GROUP BY lf.ano, lf.mes, lf.data_ref, pc.nome_conta;
GO

-- =============================================================================
-- VIEW 3: vw_Despesas_Centro_Custo — Despesas (Custo + OpEx) por Centro de Custo
-- =============================================================================

CREATE OR ALTER VIEW vw_Despesas_Centro_Custo AS
SELECT
    lf.ano,
    lf.mes,
    lf.data_ref,
    cc.nome_centro                        AS Centro_Custo,
    SUM(lf.valor)                         AS Total_Despesas,
    ROUND(SUM(lf.valor) /
        SUM(SUM(lf.valor)) OVER (PARTITION BY lf.ano, lf.mes) * 100, 2) AS Participacao_Pct
FROM Lancamentos_Financeiros lf
JOIN Plano_Contas pc ON pc.id_conta = lf.id_conta
JOIN Centro_Custo cc ON cc.id_centro = lf.id_centro
WHERE lf.tipo = 'Realizado'
  AND pc.grupo IN ('CUSTO','DESPESA')
GROUP BY lf.ano, lf.mes, lf.data_ref, cc.nome_centro;
GO

-- =============================================================================
-- VIEW 4: vw_Performance_vs_Meta — Receita Realizada vs Orçada por Linha
-- =============================================================================

CREATE OR ALTER VIEW vw_Performance_vs_Meta AS
WITH Realizado AS (
    SELECT lf.ano, pc.id_conta, pc.nome_conta,
           SUM(lf.valor) AS Receita_Realizada
    FROM Lancamentos_Financeiros lf
    JOIN Plano_Contas pc ON pc.id_conta = lf.id_conta
    WHERE lf.tipo = 'Realizado'
      AND pc.subgrupo = 'Receita Bruta'
    GROUP BY lf.ano, pc.id_conta, pc.nome_conta
)
SELECT
    r.ano,
    r.nome_conta           AS Linha_Servico,
    r.Receita_Realizada,
    m.valor_meta_anual     AS Meta_Anual,
    r.Receita_Realizada - m.valor_meta_anual                                     AS Variacao_R$,
    ROUND((r.Receita_Realizada / m.valor_meta_anual - 1) * 100, 2)               AS Variacao_Pct,
    CASE
        WHEN r.Receita_Realizada >= m.valor_meta_anual THEN 'Acima da Meta'
        WHEN r.Receita_Realizada >= m.valor_meta_anual * 0.90 THEN 'Próximo da Meta'
        ELSE 'Abaixo da Meta'
    END AS Status_Meta
FROM Realizado r
JOIN Metas_Anuais m ON m.id_conta = r.id_conta AND m.ano = r.ano;
GO

-- =============================================================================
-- VIEW 5: vw_Indicadores_Rentabilidade — KPIs acumulados por ano
-- Margens anuais = soma do resultado ÷ soma da receita líquida do ano
-- (ponderadas pela receita; a média simples das margens mensais distorce o valor)
-- =============================================================================

CREATE OR ALTER VIEW vw_Indicadores_Rentabilidade AS
SELECT
    ano,
    COUNT(*)                    AS Meses_Apurados,
    SUM(Receita_Bruta)          AS Receita_Bruta_Anual,
    SUM(Receita_Liquida)        AS Receita_Liquida_Anual,
    SUM(Lucro_Bruto)            AS Lucro_Bruto_Anual,
    SUM(EBIT)                   AS EBIT_Anual,
    SUM(Lucro_Liquido)          AS Lucro_Liquido_Anual,
    ROUND(SUM(Lucro_Bruto)   / NULLIF(SUM(Receita_Liquida), 0) * 100, 2) AS Margem_Bruta_Pct,
    ROUND(SUM(EBIT)          / NULLIF(SUM(Receita_Liquida), 0) * 100, 2) AS Margem_EBIT_Pct,
    ROUND(SUM(Lucro_Liquido) / NULLIF(SUM(Receita_Liquida), 0) * 100, 2) AS Margem_Liquida_Pct,
    -- Colunas antigas (média simples das margens mensais), mantidas por compatibilidade
    ROUND(AVG(Margem_Bruta_Pct),  2) AS Margem_Bruta_Media_Pct,
    ROUND(AVG(Margem_EBIT_Pct),   2) AS Margem_EBIT_Media_Pct,
    ROUND(AVG(Margem_Liquida_Pct),2) AS Margem_Liquida_Media_Pct
FROM vw_DRE
GROUP BY ano;
GO

-- =============================================================================
-- VIEW 6: vw_Painel_Executivo_Financeiro — visão consolidada para dashboard
-- =============================================================================

CREATE OR ALTER VIEW vw_Painel_Executivo_Financeiro AS
SELECT
    d.ano,
    d.mes,
    d.data_ref,
    d.Receita_Bruta,
    d.Receita_Liquida,
    d.Lucro_Bruto,
    d.EBIT,
    d.Lucro_Liquido,
    d.Margem_Bruta_Pct,
    d.Margem_EBIT_Pct,
    d.Margem_Liquida_Pct,
    -- Crescimento MoM (mês a mês)
    LAG(d.Receita_Liquida) OVER (ORDER BY d.ano, d.mes)                                AS Rec_Liq_MesAnterior,
    ROUND((d.Receita_Liquida / NULLIF(LAG(d.Receita_Liquida) OVER (ORDER BY d.ano, d.mes), 0) - 1) * 100, 2)
                                                                                        AS Crescimento_MoM_Pct,
    -- Crescimento YoY (ano a ano — mesmo mês)
    LAG(d.Receita_Liquida, 12) OVER (ORDER BY d.ano, d.mes)                            AS Rec_Liq_MesmoMesAnoAnterior,
    ROUND((d.Receita_Liquida / NULLIF(LAG(d.Receita_Liquida, 12) OVER (ORDER BY d.ano, d.mes), 0) - 1) * 100, 2)
                                                                                        AS Crescimento_YoY_Pct,
    -- Acumulado do ano (YTD)
    SUM(d.Receita_Liquida) OVER (PARTITION BY d.ano ORDER BY d.mes)                    AS Receita_Liq_YTD,
    SUM(d.Lucro_Liquido)   OVER (PARTITION BY d.ano ORDER BY d.mes)                    AS Lucro_Liq_YTD
FROM vw_DRE d;
GO

-- =============================================================================
-- VERIFICAÇÃO FINAL
-- =============================================================================

SELECT 'Plano_Contas'            AS Tabela, COUNT(*) AS Registros FROM Plano_Contas
UNION ALL
SELECT 'Centro_Custo',                      COUNT(*)              FROM Centro_Custo
UNION ALL
SELECT 'Lancamentos_Financeiros',           COUNT(*)              FROM Lancamentos_Financeiros
UNION ALL
SELECT 'Metas_Anuais',                      COUNT(*)              FROM Metas_Anuais;

SELECT TOP 5 * FROM vw_DRE ORDER BY ano, mes;
SELECT TOP 5 * FROM vw_Painel_Executivo_Financeiro ORDER BY ano, mes;
GO
