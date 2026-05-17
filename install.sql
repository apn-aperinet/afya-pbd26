-- =============================================================================
-- Arquivo: install.sql
-- Descricao: Script mestre de instalacao - executa todos os scripts na ordem
--            correta para criar o schema completo do sistema AFYA PBD26
-- Projeto: AFYA PBD26 - Sistema de Prontuario Eletronico do Paciente
--
-- Uso:
--   sqlplus usuario/senha@banco @install.sql
--
-- Obs: Execute com usuario que tenha privilegios de CREATE TABLE, CREATE VIEW,
--      CREATE SEQUENCE, CREATE PROCEDURE, CREATE TRIGGER.
-- =============================================================================

PROMPT ============================================================
PROMPT  AFYA PBD26 - Instalacao do Schema Oracle
PROMPT ============================================================

SET ECHO ON
SET SERVEROUTPUT ON SIZE UNLIMITED
SET DEFINE OFF

-- -----------------------------------------------------------------------------
-- DDL: Sequences
-- -----------------------------------------------------------------------------
PROMPT
PROMPT [1/7] Criando Sequences...
PROMPT

@@scripts/ddl/01_create_sequences.sql

-- -----------------------------------------------------------------------------
-- DDL: Tabelas
-- -----------------------------------------------------------------------------
PROMPT
PROMPT [2/7] Criando Tabelas...
PROMPT

@@scripts/ddl/02_create_tables.sql

-- -----------------------------------------------------------------------------
-- DDL: Indices
-- -----------------------------------------------------------------------------
PROMPT
PROMPT [3/7] Criando Indices...
PROMPT

@@scripts/ddl/03_create_indexes.sql

-- -----------------------------------------------------------------------------
-- DML: Dados iniciais
-- -----------------------------------------------------------------------------
PROMPT
PROMPT [4/7] Inserindo Dados Iniciais...
PROMPT

@@scripts/dml/01_seed_data.sql

-- -----------------------------------------------------------------------------
-- Views
-- -----------------------------------------------------------------------------
PROMPT
PROMPT [5/7] Criando Views...
PROMPT

@@scripts/views/01_views.sql

-- -----------------------------------------------------------------------------
-- Triggers
-- -----------------------------------------------------------------------------
PROMPT
PROMPT [6/7] Criando Triggers...
PROMPT

@@scripts/triggers/01_triggers.sql

-- -----------------------------------------------------------------------------
-- Stored Procedures e Packages
-- -----------------------------------------------------------------------------
PROMPT
PROMPT [7/7] Criando Packages e Procedures...
PROMPT

@@scripts/procedures/01_procedures.sql

-- -----------------------------------------------------------------------------
-- Verificacao final
-- -----------------------------------------------------------------------------
PROMPT
PROMPT ============================================================
PROMPT  Verificacao da instalacao
PROMPT ============================================================

SELECT TABLE_NAME, NUM_ROWS
FROM USER_TABLES
WHERE TABLE_NAME IN (
    'USUARIOS', 'ESPECIALIDADES', 'MEDICOS', 'PACIENTES',
    'ALERGIAS', 'CONSULTAS', 'DIAGNOSTICOS', 'MEDICAMENTOS',
    'PRESCRICOES', 'ITENS_PRESCRICAO', 'EXAMES',
    'RESULTADOS_EXAMES', 'LEITOS', 'INTERNACOES', 'LOGS_AUDITORIA'
)
ORDER BY TABLE_NAME;

SELECT VIEW_NAME
FROM USER_VIEWS
WHERE VIEW_NAME LIKE 'VW_%'
ORDER BY VIEW_NAME;

SELECT OBJECT_NAME, OBJECT_TYPE, STATUS
FROM USER_OBJECTS
WHERE OBJECT_TYPE IN ('PACKAGE', 'PACKAGE BODY', 'TRIGGER')
ORDER BY OBJECT_TYPE, OBJECT_NAME;

PROMPT
PROMPT ============================================================
PROMPT  Instalacao concluida com sucesso!
PROMPT ============================================================
