-- =============================================================================
-- Arquivo: 03_create_indexes.sql
-- Descricao: Criacao de indices para otimizacao de consultas
-- Projeto: AFYA PBD26 - Sistema de Prontuario Eletronico do Paciente
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Indices da tabela PACIENTES
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_PACIENTES_NOME
    ON PACIENTES (NOME);

CREATE INDEX IDX_PACIENTES_DT_NASC
    ON PACIENTES (DT_NASCIMENTO);

CREATE INDEX IDX_PACIENTES_ATIVO
    ON PACIENTES (ATIVO);

-- -----------------------------------------------------------------------------
-- Indices da tabela MEDICOS
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_MEDICOS_NOME
    ON MEDICOS (NOME);

CREATE INDEX IDX_MEDICOS_ESPECIALIDADE
    ON MEDICOS (ID_ESPECIALIDADE);

CREATE INDEX IDX_MEDICOS_ATIVO
    ON MEDICOS (ATIVO);

-- -----------------------------------------------------------------------------
-- Indices da tabela CONSULTAS
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_CONSULTAS_PACIENTE
    ON CONSULTAS (ID_PACIENTE);

CREATE INDEX IDX_CONSULTAS_MEDICO
    ON CONSULTAS (ID_MEDICO);

CREATE INDEX IDX_CONSULTAS_DT
    ON CONSULTAS (DT_CONSULTA);

CREATE INDEX IDX_CONSULTAS_STATUS
    ON CONSULTAS (STATUS);

CREATE INDEX IDX_CONSULTAS_PAC_DT
    ON CONSULTAS (ID_PACIENTE, DT_CONSULTA DESC);

CREATE INDEX IDX_CONSULTAS_MED_DT
    ON CONSULTAS (ID_MEDICO, DT_CONSULTA DESC);

-- -----------------------------------------------------------------------------
-- Indices da tabela DIAGNOSTICOS
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_DIAGNOSTICOS_CONSULTA
    ON DIAGNOSTICOS (ID_CONSULTA);

CREATE INDEX IDX_DIAGNOSTICOS_CID
    ON DIAGNOSTICOS (CODIGO_CID);

-- -----------------------------------------------------------------------------
-- Indices da tabela PRESCRICOES
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_PRESCRICOES_CONSULTA
    ON PRESCRICOES (ID_CONSULTA);

CREATE INDEX IDX_PRESCRICOES_MEDICO
    ON PRESCRICOES (ID_MEDICO);

CREATE INDEX IDX_PRESCRICOES_STATUS
    ON PRESCRICOES (STATUS);

CREATE INDEX IDX_PRESCRICOES_DT_VALIDADE
    ON PRESCRICOES (DT_VALIDADE);

-- -----------------------------------------------------------------------------
-- Indices da tabela ITENS_PRESCRICAO
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_ITENS_PRESC_PRESCRICAO
    ON ITENS_PRESCRICAO (ID_PRESCRICAO);

CREATE INDEX IDX_ITENS_PRESC_MEDICAMENTO
    ON ITENS_PRESCRICAO (ID_MEDICAMENTO);

-- -----------------------------------------------------------------------------
-- Indices da tabela RESULTADOS_EXAMES
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_RESULT_EXAME_CONSULTA
    ON RESULTADOS_EXAMES (ID_CONSULTA);

CREATE INDEX IDX_RESULT_EXAME_EXAME
    ON RESULTADOS_EXAMES (ID_EXAME);

CREATE INDEX IDX_RESULT_EXAME_STATUS
    ON RESULTADOS_EXAMES (STATUS);

CREATE INDEX IDX_RESULT_EXAME_DT_SOL
    ON RESULTADOS_EXAMES (DT_SOLICITACAO);

-- -----------------------------------------------------------------------------
-- Indices da tabela INTERNACOES
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_INTERNACOES_PACIENTE
    ON INTERNACOES (ID_PACIENTE);

CREATE INDEX IDX_INTERNACOES_MEDICO
    ON INTERNACOES (ID_MEDICO);

CREATE INDEX IDX_INTERNACOES_LEITO
    ON INTERNACOES (ID_LEITO);

CREATE INDEX IDX_INTERNACOES_STATUS
    ON INTERNACOES (STATUS);

CREATE INDEX IDX_INTERNACOES_DT_INT
    ON INTERNACOES (DT_INTERNACAO);

-- -----------------------------------------------------------------------------
-- Indices da tabela ALERGIAS
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_ALERGIAS_PACIENTE
    ON ALERGIAS (ID_PACIENTE);

-- -----------------------------------------------------------------------------
-- Indices da tabela LOGS_AUDITORIA
-- -----------------------------------------------------------------------------
CREATE INDEX IDX_LOGS_AUD_USUARIO
    ON LOGS_AUDITORIA (ID_USUARIO);

CREATE INDEX IDX_LOGS_AUD_TABELA
    ON LOGS_AUDITORIA (TABELA);

CREATE INDEX IDX_LOGS_AUD_DT
    ON LOGS_AUDITORIA (DT_ACAO);

CREATE INDEX IDX_LOGS_AUD_OPERACAO
    ON LOGS_AUDITORIA (OPERACAO);

COMMIT;
