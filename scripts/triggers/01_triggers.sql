-- =============================================================================
-- Arquivo: 01_triggers.sql
-- Descricao: Triggers de automacao e auditoria
-- Projeto: AFYA PBD26 - Sistema de Prontuario Eletronico do Paciente
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Trigger: TRG_PACIENTES_BI
-- Descricao: Gera ID automaticamente ao inserir paciente
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PACIENTES_BI
    BEFORE INSERT ON PACIENTES
    FOR EACH ROW
BEGIN
    IF :NEW.ID_PACIENTE IS NULL THEN
        :NEW.ID_PACIENTE := SEQ_PACIENTES.NEXTVAL;
    END IF;
    :NEW.DT_CRIACAO := SYSDATE;
END TRG_PACIENTES_BI;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_PACIENTES_BU
-- Descricao: Atualiza data de modificacao ao alterar paciente
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PACIENTES_BU
    BEFORE UPDATE ON PACIENTES
    FOR EACH ROW
BEGIN
    :NEW.DT_ATUALIZACAO := SYSDATE;
END TRG_PACIENTES_BU;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_USUARIOS_BI
-- Descricao: Gera ID automaticamente ao inserir usuario
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_USUARIOS_BI
    BEFORE INSERT ON USUARIOS
    FOR EACH ROW
BEGIN
    IF :NEW.ID_USUARIO IS NULL THEN
        :NEW.ID_USUARIO := SEQ_USUARIOS.NEXTVAL;
    END IF;
    :NEW.DT_CRIACAO := SYSDATE;
END TRG_USUARIOS_BI;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_USUARIOS_BU
-- Descricao: Atualiza data de modificacao ao alterar usuario
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_USUARIOS_BU
    BEFORE UPDATE ON USUARIOS
    FOR EACH ROW
BEGIN
    :NEW.DT_ATUALIZACAO := SYSDATE;
END TRG_USUARIOS_BU;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_MEDICOS_BI
-- Descricao: Gera ID automaticamente ao inserir medico
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_MEDICOS_BI
    BEFORE INSERT ON MEDICOS
    FOR EACH ROW
BEGIN
    IF :NEW.ID_MEDICO IS NULL THEN
        :NEW.ID_MEDICO := SEQ_MEDICOS.NEXTVAL;
    END IF;
    :NEW.DT_CRIACAO := SYSDATE;
END TRG_MEDICOS_BI;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_CONSULTAS_BI
-- Descricao: Gera ID automaticamente ao inserir consulta
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_CONSULTAS_BI
    BEFORE INSERT ON CONSULTAS
    FOR EACH ROW
BEGIN
    IF :NEW.ID_CONSULTA IS NULL THEN
        :NEW.ID_CONSULTA := SEQ_CONSULTAS.NEXTVAL;
    END IF;
    :NEW.DT_CRIACAO := SYSDATE;
END TRG_CONSULTAS_BI;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_CONSULTAS_BU
-- Descricao: Atualiza data de modificacao ao alterar consulta
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_CONSULTAS_BU
    BEFORE UPDATE ON CONSULTAS
    FOR EACH ROW
BEGIN
    :NEW.DT_ATUALIZACAO := SYSDATE;
END TRG_CONSULTAS_BU;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_INTERNACOES_AI
-- Descricao: Atualiza status do leito automaticamente ao registrar internacao
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_INTERNACOES_AI
    AFTER INSERT ON INTERNACOES
    FOR EACH ROW
BEGIN
    UPDATE LEITOS
    SET STATUS = 'OCUPADO'
    WHERE ID_LEITO = :NEW.ID_LEITO;
END TRG_INTERNACOES_AI;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_INTERNACOES_AU
-- Descricao: Libera leito automaticamente ao registrar alta ou obito
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_INTERNACOES_AU
    AFTER UPDATE OF STATUS ON INTERNACOES
    FOR EACH ROW
BEGIN
    IF :NEW.STATUS IN ('ALTA', 'OBITO', 'TRANSFERIDO') THEN
        UPDATE LEITOS
        SET STATUS = 'DISPONIVEL'
        WHERE ID_LEITO = :NEW.ID_LEITO;
    END IF;
END TRG_INTERNACOES_AU;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_PRESCRICOES_BU
-- Descricao: Marca prescricoes vencidas automaticamente ao atualizar
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_PRESCRICOES_BU
    BEFORE UPDATE ON PRESCRICOES
    FOR EACH ROW
BEGIN
    IF :NEW.STATUS = 'ATIVA'
       AND :NEW.DT_VALIDADE IS NOT NULL
       AND :NEW.DT_VALIDADE < TRUNC(SYSDATE) THEN
        :NEW.STATUS := 'VENCIDA';
    END IF;
END TRG_PRESCRICOES_BU;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_AUD_PACIENTES
-- Descricao: Auditoria de alteracoes na tabela PACIENTES
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUD_PACIENTES
    AFTER INSERT OR UPDATE OR DELETE ON PACIENTES
    FOR EACH ROW
DECLARE
    v_operacao  VARCHAR2(10);
    v_id        NUMBER;
BEGIN
    IF INSERTING THEN
        v_operacao := 'INSERT';
        v_id       := :NEW.ID_PACIENTE;
    ELSIF UPDATING THEN
        v_operacao := 'UPDATE';
        v_id       := :NEW.ID_PACIENTE;
    ELSE
        v_operacao := 'DELETE';
        v_id       := :OLD.ID_PACIENTE;
    END IF;

    INSERT INTO LOGS_AUDITORIA (
        ID_LOG, TABELA, ID_REGISTRO, OPERACAO, DT_ACAO
    ) VALUES (
        SEQ_LOGS_AUDITORIA.NEXTVAL, 'PACIENTES', v_id, v_operacao, SYSDATE
    );
END TRG_AUD_PACIENTES;
/

-- -----------------------------------------------------------------------------
-- Trigger: TRG_AUD_CONSULTAS
-- Descricao: Auditoria de alteracoes na tabela CONSULTAS
-- -----------------------------------------------------------------------------
CREATE OR REPLACE TRIGGER TRG_AUD_CONSULTAS
    AFTER INSERT OR UPDATE OR DELETE ON CONSULTAS
    FOR EACH ROW
DECLARE
    v_operacao  VARCHAR2(10);
    v_id        NUMBER;
BEGIN
    IF INSERTING THEN
        v_operacao := 'INSERT';
        v_id       := :NEW.ID_CONSULTA;
    ELSIF UPDATING THEN
        v_operacao := 'UPDATE';
        v_id       := :NEW.ID_CONSULTA;
    ELSE
        v_operacao := 'DELETE';
        v_id       := :OLD.ID_CONSULTA;
    END IF;

    INSERT INTO LOGS_AUDITORIA (
        ID_LOG, TABELA, ID_REGISTRO, OPERACAO, DT_ACAO
    ) VALUES (
        SEQ_LOGS_AUDITORIA.NEXTVAL, 'CONSULTAS', v_id, v_operacao, SYSDATE
    );
END TRG_AUD_CONSULTAS;
/
