-- =============================================================================
-- Arquivo: 01_procedures.sql
-- Descricao: Stored procedures e funcoes do sistema
-- Projeto: AFYA PBD26 - Sistema de Prontuario Eletronico do Paciente
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Package: PKG_PACIENTES
-- Descricao: Procedimentos e funcoes para gestao de pacientes
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_PACIENTES AS

    -- Cadastra um novo paciente
    PROCEDURE SP_INSERIR_PACIENTE(
        p_nome          IN  PACIENTES.NOME%TYPE,
        p_cpf           IN  PACIENTES.CPF%TYPE,
        p_cns           IN  PACIENTES.CNS%TYPE,
        p_dt_nascimento IN  PACIENTES.DT_NASCIMENTO%TYPE,
        p_sexo          IN  PACIENTES.SEXO%TYPE,
        p_nome_mae      IN  PACIENTES.NOME_MAE%TYPE,
        p_telefone      IN  PACIENTES.TELEFONE%TYPE,
        p_email         IN  PACIENTES.EMAIL%TYPE,
        p_id_paciente   OUT PACIENTES.ID_PACIENTE%TYPE
    );

    -- Atualiza dados de um paciente
    PROCEDURE SP_ATUALIZAR_PACIENTE(
        p_id_paciente   IN PACIENTES.ID_PACIENTE%TYPE,
        p_nome          IN PACIENTES.NOME%TYPE,
        p_telefone      IN PACIENTES.TELEFONE%TYPE,
        p_email         IN PACIENTES.EMAIL%TYPE,
        p_logradouro    IN PACIENTES.LOGRADOURO%TYPE,
        p_numero        IN PACIENTES.NUMERO%TYPE,
        p_bairro        IN PACIENTES.BAIRRO%TYPE,
        p_cidade        IN PACIENTES.CIDADE%TYPE,
        p_uf            IN PACIENTES.UF%TYPE,
        p_cep           IN PACIENTES.CEP%TYPE
    );

    -- Inativa um paciente
    PROCEDURE SP_INATIVAR_PACIENTE(
        p_id_paciente IN PACIENTES.ID_PACIENTE%TYPE
    );

    -- Retorna dados de um paciente por ID
    FUNCTION FN_BUSCAR_PACIENTE(
        p_id_paciente IN PACIENTES.ID_PACIENTE%TYPE
    ) RETURN SYS_REFCURSOR;

    -- Busca pacientes por nome (parcial)
    FUNCTION FN_BUSCAR_PACIENTE_NOME(
        p_nome IN PACIENTES.NOME%TYPE
    ) RETURN SYS_REFCURSOR;

    -- Verifica existencia de paciente pelo CPF
    FUNCTION FN_PACIENTE_EXISTE_CPF(
        p_cpf IN PACIENTES.CPF%TYPE
    ) RETURN BOOLEAN;

END PKG_PACIENTES;
/

CREATE OR REPLACE PACKAGE BODY PKG_PACIENTES AS

    PROCEDURE SP_INSERIR_PACIENTE(
        p_nome          IN  PACIENTES.NOME%TYPE,
        p_cpf           IN  PACIENTES.CPF%TYPE,
        p_cns           IN  PACIENTES.CNS%TYPE,
        p_dt_nascimento IN  PACIENTES.DT_NASCIMENTO%TYPE,
        p_sexo          IN  PACIENTES.SEXO%TYPE,
        p_nome_mae      IN  PACIENTES.NOME_MAE%TYPE,
        p_telefone      IN  PACIENTES.TELEFONE%TYPE,
        p_email         IN  PACIENTES.EMAIL%TYPE,
        p_id_paciente   OUT PACIENTES.ID_PACIENTE%TYPE
    ) IS
        v_id PACIENTES.ID_PACIENTE%TYPE;
    BEGIN
        IF FN_PACIENTE_EXISTE_CPF(p_cpf) THEN
            RAISE_APPLICATION_ERROR(-20001, 'Ja existe um paciente cadastrado com este CPF.');
        END IF;

        v_id := SEQ_PACIENTES.NEXTVAL;

        INSERT INTO PACIENTES (
            ID_PACIENTE, NOME, CPF, CNS, DT_NASCIMENTO, SEXO,
            NOME_MAE, TELEFONE, EMAIL, ATIVO, DT_CRIACAO
        ) VALUES (
            v_id, p_nome, p_cpf, p_cns, p_dt_nascimento, p_sexo,
            p_nome_mae, p_telefone, p_email, 'S', SYSDATE
        );

        p_id_paciente := v_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_INSERIR_PACIENTE;

    PROCEDURE SP_ATUALIZAR_PACIENTE(
        p_id_paciente   IN PACIENTES.ID_PACIENTE%TYPE,
        p_nome          IN PACIENTES.NOME%TYPE,
        p_telefone      IN PACIENTES.TELEFONE%TYPE,
        p_email         IN PACIENTES.EMAIL%TYPE,
        p_logradouro    IN PACIENTES.LOGRADOURO%TYPE,
        p_numero        IN PACIENTES.NUMERO%TYPE,
        p_bairro        IN PACIENTES.BAIRRO%TYPE,
        p_cidade        IN PACIENTES.CIDADE%TYPE,
        p_uf            IN PACIENTES.UF%TYPE,
        p_cep           IN PACIENTES.CEP%TYPE
    ) IS
    BEGIN
        UPDATE PACIENTES
        SET NOME         = NVL(p_nome, NOME),
            TELEFONE     = NVL(p_telefone, TELEFONE),
            EMAIL        = NVL(p_email, EMAIL),
            LOGRADOURO   = NVL(p_logradouro, LOGRADOURO),
            NUMERO       = NVL(p_numero, NUMERO),
            BAIRRO       = NVL(p_bairro, BAIRRO),
            CIDADE       = NVL(p_cidade, CIDADE),
            UF           = NVL(p_uf, UF),
            CEP          = NVL(p_cep, CEP),
            DT_ATUALIZACAO = SYSDATE
        WHERE ID_PACIENTE = p_id_paciente
          AND ATIVO = 'S';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20002, 'Paciente nao encontrado ou inativo.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_ATUALIZAR_PACIENTE;

    PROCEDURE SP_INATIVAR_PACIENTE(
        p_id_paciente IN PACIENTES.ID_PACIENTE%TYPE
    ) IS
    BEGIN
        UPDATE PACIENTES
        SET ATIVO          = 'N',
            DT_ATUALIZACAO = SYSDATE
        WHERE ID_PACIENTE = p_id_paciente;

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20003, 'Paciente nao encontrado.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_INATIVAR_PACIENTE;

    FUNCTION FN_BUSCAR_PACIENTE(
        p_id_paciente IN PACIENTES.ID_PACIENTE%TYPE
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT p.ID_PACIENTE, p.NOME, p.CPF, p.CNS, p.DT_NASCIMENTO,
                   TRUNC(MONTHS_BETWEEN(SYSDATE, p.DT_NASCIMENTO) / 12) AS IDADE,
                   p.SEXO, p.NOME_MAE, p.TELEFONE, p.EMAIL,
                   p.LOGRADOURO, p.NUMERO, p.COMPLEMENTO, p.BAIRRO,
                   p.CIDADE, p.UF, p.CEP, p.TIPO_SANGUINEO, p.ATIVO
            FROM PACIENTES p
            WHERE p.ID_PACIENTE = p_id_paciente;
        RETURN v_cursor;
    END FN_BUSCAR_PACIENTE;

    FUNCTION FN_BUSCAR_PACIENTE_NOME(
        p_nome IN PACIENTES.NOME%TYPE
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT p.ID_PACIENTE, p.NOME, p.CPF, p.CNS, p.DT_NASCIMENTO,
                   TRUNC(MONTHS_BETWEEN(SYSDATE, p.DT_NASCIMENTO) / 12) AS IDADE,
                   p.SEXO, p.TELEFONE, p.EMAIL, p.ATIVO
            FROM PACIENTES p
            WHERE UPPER(p.NOME) LIKE UPPER('%' || p_nome || '%')
              AND p.ATIVO = 'S'
            ORDER BY p.NOME;
        RETURN v_cursor;
    END FN_BUSCAR_PACIENTE_NOME;

    FUNCTION FN_PACIENTE_EXISTE_CPF(
        p_cpf IN PACIENTES.CPF%TYPE
    ) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(1) INTO v_count
        FROM PACIENTES
        WHERE CPF = p_cpf;
        RETURN v_count > 0;
    END FN_PACIENTE_EXISTE_CPF;

END PKG_PACIENTES;
/

-- -----------------------------------------------------------------------------
-- Package: PKG_CONSULTAS
-- Descricao: Procedimentos e funcoes para gestao de consultas
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_CONSULTAS AS

    -- Agenda uma nova consulta
    PROCEDURE SP_AGENDAR_CONSULTA(
        p_id_paciente      IN  CONSULTAS.ID_PACIENTE%TYPE,
        p_id_medico        IN  CONSULTAS.ID_MEDICO%TYPE,
        p_dt_consulta      IN  CONSULTAS.DT_CONSULTA%TYPE,
        p_tipo_atendimento IN  CONSULTAS.TIPO_ATENDIMENTO%TYPE,
        p_id_consulta      OUT CONSULTAS.ID_CONSULTA%TYPE
    );

    -- Inicia o atendimento de uma consulta agendada
    PROCEDURE SP_INICIAR_ATENDIMENTO(
        p_id_consulta IN CONSULTAS.ID_CONSULTA%TYPE
    );

    -- Finaliza uma consulta em atendimento
    PROCEDURE SP_FINALIZAR_CONSULTA(
        p_id_consulta    IN CONSULTAS.ID_CONSULTA%TYPE,
        p_queixa         IN CONSULTAS.QUEIXA_PRINCIPAL%TYPE,
        p_anamnese       IN CONSULTAS.ANAMNESE%TYPE,
        p_exame_fisico   IN CONSULTAS.EXAME_FISICO%TYPE,
        p_hipotese_dx    IN CONSULTAS.HIPOTESE_DX%TYPE,
        p_conduta        IN CONSULTAS.CONDUTA%TYPE,
        p_observacoes    IN CONSULTAS.OBSERVACOES%TYPE
    );

    -- Cancela uma consulta
    PROCEDURE SP_CANCELAR_CONSULTA(
        p_id_consulta IN CONSULTAS.ID_CONSULTA%TYPE,
        p_motivo      IN VARCHAR2
    );

    -- Adiciona diagnostico a uma consulta
    PROCEDURE SP_ADICIONAR_DIAGNOSTICO(
        p_id_consulta    IN DIAGNOSTICOS.ID_CONSULTA%TYPE,
        p_codigo_cid     IN DIAGNOSTICOS.CODIGO_CID%TYPE,
        p_descricao      IN DIAGNOSTICOS.DESCRICAO%TYPE,
        p_tipo           IN DIAGNOSTICOS.TIPO%TYPE
    );

    -- Retorna historico de consultas de um paciente
    FUNCTION FN_HISTORICO_CONSULTAS(
        p_id_paciente IN PACIENTES.ID_PACIENTE%TYPE
    ) RETURN SYS_REFCURSOR;

END PKG_CONSULTAS;
/

CREATE OR REPLACE PACKAGE BODY PKG_CONSULTAS AS

    PROCEDURE SP_AGENDAR_CONSULTA(
        p_id_paciente      IN  CONSULTAS.ID_PACIENTE%TYPE,
        p_id_medico        IN  CONSULTAS.ID_MEDICO%TYPE,
        p_dt_consulta      IN  CONSULTAS.DT_CONSULTA%TYPE,
        p_tipo_atendimento IN  CONSULTAS.TIPO_ATENDIMENTO%TYPE,
        p_id_consulta      OUT CONSULTAS.ID_CONSULTA%TYPE
    ) IS
        v_id     CONSULTAS.ID_CONSULTA%TYPE;
        v_count  NUMBER;
    BEGIN
        -- Verifica se o medico ja tem consulta no mesmo horario
        SELECT COUNT(1) INTO v_count
        FROM CONSULTAS
        WHERE ID_MEDICO   = p_id_medico
          AND DT_CONSULTA = p_dt_consulta
          AND STATUS NOT IN ('CANCELADA', 'NAO_COMPARECEU');

        IF v_count > 0 THEN
            RAISE_APPLICATION_ERROR(-20010, 'Medico ja possui consulta agendada neste horario.');
        END IF;

        v_id := SEQ_CONSULTAS.NEXTVAL;

        INSERT INTO CONSULTAS (
            ID_CONSULTA, ID_PACIENTE, ID_MEDICO, DT_CONSULTA,
            DT_AGENDAMENTO, TIPO_ATENDIMENTO, STATUS, DT_CRIACAO
        ) VALUES (
            v_id, p_id_paciente, p_id_medico, p_dt_consulta,
            SYSDATE, p_tipo_atendimento, 'AGENDADA', SYSDATE
        );

        p_id_consulta := v_id;
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_AGENDAR_CONSULTA;

    PROCEDURE SP_INICIAR_ATENDIMENTO(
        p_id_consulta IN CONSULTAS.ID_CONSULTA%TYPE
    ) IS
    BEGIN
        UPDATE CONSULTAS
        SET STATUS = 'EM_ATENDIMENTO',
            DT_ATUALIZACAO = SYSDATE
        WHERE ID_CONSULTA = p_id_consulta
          AND STATUS IN ('AGENDADA', 'CONFIRMADA');

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20011, 'Consulta nao encontrada ou nao pode ser iniciada.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_INICIAR_ATENDIMENTO;

    PROCEDURE SP_FINALIZAR_CONSULTA(
        p_id_consulta    IN CONSULTAS.ID_CONSULTA%TYPE,
        p_queixa         IN CONSULTAS.QUEIXA_PRINCIPAL%TYPE,
        p_anamnese       IN CONSULTAS.ANAMNESE%TYPE,
        p_exame_fisico   IN CONSULTAS.EXAME_FISICO%TYPE,
        p_hipotese_dx    IN CONSULTAS.HIPOTESE_DX%TYPE,
        p_conduta        IN CONSULTAS.CONDUTA%TYPE,
        p_observacoes    IN CONSULTAS.OBSERVACOES%TYPE
    ) IS
    BEGIN
        UPDATE CONSULTAS
        SET STATUS           = 'REALIZADA',
            QUEIXA_PRINCIPAL = p_queixa,
            ANAMNESE         = p_anamnese,
            EXAME_FISICO     = p_exame_fisico,
            HIPOTESE_DX      = p_hipotese_dx,
            CONDUTA          = p_conduta,
            OBSERVACOES      = p_observacoes,
            DT_ATUALIZACAO   = SYSDATE
        WHERE ID_CONSULTA = p_id_consulta
          AND STATUS = 'EM_ATENDIMENTO';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20012, 'Consulta nao encontrada ou nao esta em atendimento.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_FINALIZAR_CONSULTA;

    PROCEDURE SP_CANCELAR_CONSULTA(
        p_id_consulta IN CONSULTAS.ID_CONSULTA%TYPE,
        p_motivo      IN VARCHAR2
    ) IS
    BEGIN
        UPDATE CONSULTAS
        SET STATUS         = 'CANCELADA',
            OBSERVACOES    = 'CANCELAMENTO: ' || p_motivo,
            DT_ATUALIZACAO = SYSDATE
        WHERE ID_CONSULTA = p_id_consulta
          AND STATUS IN ('AGENDADA', 'CONFIRMADA');

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20013, 'Consulta nao encontrada ou nao pode ser cancelada.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_CANCELAR_CONSULTA;

    PROCEDURE SP_ADICIONAR_DIAGNOSTICO(
        p_id_consulta    IN DIAGNOSTICOS.ID_CONSULTA%TYPE,
        p_codigo_cid     IN DIAGNOSTICOS.CODIGO_CID%TYPE,
        p_descricao      IN DIAGNOSTICOS.DESCRICAO%TYPE,
        p_tipo           IN DIAGNOSTICOS.TIPO%TYPE
    ) IS
    BEGIN
        INSERT INTO DIAGNOSTICOS (
            ID_DIAGNOSTICO, ID_CONSULTA, CODIGO_CID, DESCRICAO, TIPO
        ) VALUES (
            SEQ_DIAGNOSTICOS.NEXTVAL, p_id_consulta, p_codigo_cid, p_descricao, p_tipo
        );
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_ADICIONAR_DIAGNOSTICO;

    FUNCTION FN_HISTORICO_CONSULTAS(
        p_id_paciente IN PACIENTES.ID_PACIENTE%TYPE
    ) RETURN SYS_REFCURSOR IS
        v_cursor SYS_REFCURSOR;
    BEGIN
        OPEN v_cursor FOR
            SELECT c.ID_CONSULTA, c.DT_CONSULTA, c.TIPO_ATENDIMENTO, c.STATUS,
                   m.NOME AS NOME_MEDICO, e.DESCRICAO AS ESPECIALIDADE,
                   c.QUEIXA_PRINCIPAL, c.HIPOTESE_DX, c.CONDUTA
            FROM CONSULTAS c
            JOIN MEDICOS m ON m.ID_MEDICO = c.ID_MEDICO
            JOIN ESPECIALIDADES e ON e.ID_ESPECIALIDADE = m.ID_ESPECIALIDADE
            WHERE c.ID_PACIENTE = p_id_paciente
            ORDER BY c.DT_CONSULTA DESC;
        RETURN v_cursor;
    END FN_HISTORICO_CONSULTAS;

END PKG_CONSULTAS;
/

-- -----------------------------------------------------------------------------
-- Package: PKG_INTERNACOES
-- Descricao: Procedimentos para gestao de internacoes
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PACKAGE PKG_INTERNACOES AS

    -- Registra internacao de paciente
    PROCEDURE SP_INTERNAR_PACIENTE(
        p_id_paciente    IN  INTERNACOES.ID_PACIENTE%TYPE,
        p_id_medico      IN  INTERNACOES.ID_MEDICO%TYPE,
        p_id_leito       IN  INTERNACOES.ID_LEITO%TYPE,
        p_motivo         IN  INTERNACOES.MOTIVO%TYPE,
        p_diagnostico    IN  INTERNACOES.DIAGNOSTICO_INT%TYPE,
        p_id_internacao  OUT INTERNACOES.ID_INTERNACAO%TYPE
    );

    -- Registra alta do paciente
    PROCEDURE SP_ALTA_PACIENTE(
        p_id_internacao IN INTERNACOES.ID_INTERNACAO%TYPE,
        p_status_alta   IN VARCHAR2,
        p_observacoes   IN INTERNACOES.OBSERVACOES%TYPE
    );

    -- Transfere paciente para outro leito
    PROCEDURE SP_TRANSFERIR_LEITO(
        p_id_internacao  IN INTERNACOES.ID_INTERNACAO%TYPE,
        p_id_leito_novo  IN INTERNACOES.ID_LEITO%TYPE
    );

END PKG_INTERNACOES;
/

CREATE OR REPLACE PACKAGE BODY PKG_INTERNACOES AS

    PROCEDURE SP_INTERNAR_PACIENTE(
        p_id_paciente    IN  INTERNACOES.ID_PACIENTE%TYPE,
        p_id_medico      IN  INTERNACOES.ID_MEDICO%TYPE,
        p_id_leito       IN  INTERNACOES.ID_LEITO%TYPE,
        p_motivo         IN  INTERNACOES.MOTIVO%TYPE,
        p_diagnostico    IN  INTERNACOES.DIAGNOSTICO_INT%TYPE,
        p_id_internacao  OUT INTERNACOES.ID_INTERNACAO%TYPE
    ) IS
        v_id        INTERNACOES.ID_INTERNACAO%TYPE;
        v_status_leito LEITOS.STATUS%TYPE;
    BEGIN
        -- Verifica disponibilidade do leito
        SELECT STATUS INTO v_status_leito
        FROM LEITOS
        WHERE ID_LEITO = p_id_leito
          AND ATIVO = 'S';

        IF v_status_leito != 'DISPONIVEL' THEN
            RAISE_APPLICATION_ERROR(-20020, 'Leito nao disponivel para internacao.');
        END IF;

        v_id := SEQ_INTERNACOES.NEXTVAL;

        INSERT INTO INTERNACOES (
            ID_INTERNACAO, ID_PACIENTE, ID_MEDICO, ID_LEITO,
            DT_INTERNACAO, MOTIVO, DIAGNOSTICO_INT, STATUS, DT_CRIACAO
        ) VALUES (
            v_id, p_id_paciente, p_id_medico, p_id_leito,
            SYSDATE, p_motivo, p_diagnostico, 'INTERNADO', SYSDATE
        );

        p_id_internacao := v_id;
        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20021, 'Leito nao encontrado ou inativo.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_INTERNAR_PACIENTE;

    PROCEDURE SP_ALTA_PACIENTE(
        p_id_internacao IN INTERNACOES.ID_INTERNACAO%TYPE,
        p_status_alta   IN VARCHAR2,
        p_observacoes   IN INTERNACOES.OBSERVACOES%TYPE
    ) IS
    BEGIN
        IF p_status_alta NOT IN ('ALTA', 'OBITO', 'TRANSFERIDO') THEN
            RAISE_APPLICATION_ERROR(-20022, 'Status de alta invalido.');
        END IF;

        UPDATE INTERNACOES
        SET STATUS      = p_status_alta,
            DT_ALTA     = SYSDATE,
            OBSERVACOES = p_observacoes
        WHERE ID_INTERNACAO = p_id_internacao
          AND STATUS = 'INTERNADO';

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20023, 'Internacao nao encontrada ou paciente ja recebeu alta.');
        END IF;

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_ALTA_PACIENTE;

    PROCEDURE SP_TRANSFERIR_LEITO(
        p_id_internacao  IN INTERNACOES.ID_INTERNACAO%TYPE,
        p_id_leito_novo  IN INTERNACOES.ID_LEITO%TYPE
    ) IS
        v_id_leito_atual INTERNACOES.ID_LEITO%TYPE;
        v_status_leito   LEITOS.STATUS%TYPE;
    BEGIN
        -- Busca leito atual do paciente
        SELECT ID_LEITO INTO v_id_leito_atual
        FROM INTERNACOES
        WHERE ID_INTERNACAO = p_id_internacao
          AND STATUS = 'INTERNADO';

        -- Verifica disponibilidade do novo leito
        SELECT STATUS INTO v_status_leito
        FROM LEITOS
        WHERE ID_LEITO = p_id_leito_novo
          AND ATIVO = 'S';

        IF v_status_leito != 'DISPONIVEL' THEN
            RAISE_APPLICATION_ERROR(-20024, 'Novo leito nao disponivel.');
        END IF;

        -- Atualiza internacao
        UPDATE INTERNACOES
        SET ID_LEITO = p_id_leito_novo
        WHERE ID_INTERNACAO = p_id_internacao;

        -- Libera leito anterior
        UPDATE LEITOS SET STATUS = 'DISPONIVEL' WHERE ID_LEITO = v_id_leito_atual;
        -- Ocupa novo leito
        UPDATE LEITOS SET STATUS = 'OCUPADO'    WHERE ID_LEITO = p_id_leito_novo;

        COMMIT;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            ROLLBACK;
            RAISE_APPLICATION_ERROR(-20025, 'Internacao ou leito nao encontrado.');
        WHEN OTHERS THEN
            ROLLBACK;
            RAISE;
    END SP_TRANSFERIR_LEITO;

END PKG_INTERNACOES;
/
