-- =============================================================================
-- Arquivo: 01_views.sql
-- Descricao: Criacao de views para consultas frequentes
-- Projeto: AFYA PBD26 - Sistema de Prontuario Eletronico do Paciente
-- =============================================================================

-- -----------------------------------------------------------------------------
-- View: VW_PACIENTES_ATIVO
-- Descricao: Pacientes ativos com informacoes basicas de contato
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PACIENTES_ATIVO AS
SELECT
    p.ID_PACIENTE,
    p.NOME,
    p.CPF,
    p.CNS,
    p.DT_NASCIMENTO,
    TRUNC(MONTHS_BETWEEN(SYSDATE, p.DT_NASCIMENTO) / 12) AS IDADE,
    p.SEXO,
    p.NOME_MAE,
    p.TELEFONE,
    p.EMAIL,
    p.TIPO_SANGUINEO,
    p.CIDADE,
    p.UF
FROM PACIENTES p
WHERE p.ATIVO = 'S';

COMMENT ON TABLE VW_PACIENTES_ATIVO IS 'Pacientes ativos com idade calculada';

-- -----------------------------------------------------------------------------
-- View: VW_AGENDA_CONSULTAS
-- Descricao: Agenda de consultas com dados de paciente e medico
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_AGENDA_CONSULTAS AS
SELECT
    c.ID_CONSULTA,
    c.DT_CONSULTA,
    c.STATUS,
    c.TIPO_ATENDIMENTO,
    p.ID_PACIENTE,
    p.NOME              AS NOME_PACIENTE,
    p.TELEFONE          AS TELEFONE_PACIENTE,
    m.ID_MEDICO,
    m.NOME              AS NOME_MEDICO,
    m.CRM               AS CRM_MEDICO,
    e.DESCRICAO         AS ESPECIALIDADE,
    c.QUEIXA_PRINCIPAL
FROM CONSULTAS c
JOIN PACIENTES p ON p.ID_PACIENTE = c.ID_PACIENTE
JOIN MEDICOS   m ON m.ID_MEDICO   = c.ID_MEDICO
JOIN ESPECIALIDADES e ON e.ID_ESPECIALIDADE = m.ID_ESPECIALIDADE;

COMMENT ON TABLE VW_AGENDA_CONSULTAS IS 'Agenda de consultas com dados completos de paciente e medico';

-- -----------------------------------------------------------------------------
-- View: VW_HISTORICO_PACIENTE
-- Descricao: Historico de consultas realizadas por paciente
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_HISTORICO_PACIENTE AS
SELECT
    c.ID_CONSULTA,
    c.DT_CONSULTA,
    c.TIPO_ATENDIMENTO,
    p.ID_PACIENTE,
    p.NOME              AS NOME_PACIENTE,
    m.NOME              AS NOME_MEDICO,
    e.DESCRICAO         AS ESPECIALIDADE,
    c.QUEIXA_PRINCIPAL,
    c.HIPOTESE_DX,
    c.CONDUTA,
    d.CODIGO_CID,
    d.DESCRICAO         AS DESCRICAO_DIAGNOSTICO,
    d.TIPO              AS TIPO_DIAGNOSTICO
FROM CONSULTAS c
JOIN PACIENTES    p ON p.ID_PACIENTE        = c.ID_PACIENTE
JOIN MEDICOS      m ON m.ID_MEDICO          = c.ID_MEDICO
JOIN ESPECIALIDADES e ON e.ID_ESPECIALIDADE = m.ID_ESPECIALIDADE
LEFT JOIN DIAGNOSTICOS d ON d.ID_CONSULTA   = c.ID_CONSULTA
WHERE c.STATUS = 'REALIZADA';

COMMENT ON TABLE VW_HISTORICO_PACIENTE IS 'Historico de consultas realizadas com diagnosticos';

-- -----------------------------------------------------------------------------
-- View: VW_PRESCRICOES_ATIVAS
-- Descricao: Prescricoes ativas com detalhamento dos medicamentos
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_PRESCRICOES_ATIVAS AS
SELECT
    pr.ID_PRESCRICAO,
    pr.DT_PRESCRICAO,
    pr.DT_VALIDADE,
    p.ID_PACIENTE,
    p.NOME              AS NOME_PACIENTE,
    m.NOME              AS NOME_MEDICO,
    m.CRM               AS CRM_MEDICO,
    med.NOME_GENERICO   AS MEDICAMENTO,
    med.FORMA_FARM,
    med.CONCENTRACAO,
    ip.POSOLOGIA,
    ip.QUANTIDADE,
    ip.UNIDADE,
    ip.DURACAO_DIAS,
    ip.ORIENTACOES,
    med.CONTROLADO
FROM PRESCRICOES pr
JOIN CONSULTAS c          ON c.ID_CONSULTA    = pr.ID_CONSULTA
JOIN PACIENTES p          ON p.ID_PACIENTE    = c.ID_PACIENTE
JOIN MEDICOS m            ON m.ID_MEDICO      = pr.ID_MEDICO
JOIN ITENS_PRESCRICAO ip  ON ip.ID_PRESCRICAO = pr.ID_PRESCRICAO
JOIN MEDICAMENTOS med     ON med.ID_MEDICAMENTO = ip.ID_MEDICAMENTO
WHERE pr.STATUS = 'ATIVA'
  AND (pr.DT_VALIDADE IS NULL OR pr.DT_VALIDADE >= TRUNC(SYSDATE));

COMMENT ON TABLE VW_PRESCRICOES_ATIVAS IS 'Prescricoes ativas e validas com detalhe dos medicamentos';

-- -----------------------------------------------------------------------------
-- View: VW_EXAMES_PENDENTES
-- Descricao: Exames solicitados ainda pendentes de resultado
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_EXAMES_PENDENTES AS
SELECT
    re.ID_RESULTADO,
    re.DT_SOLICITACAO,
    re.DT_COLETA,
    re.STATUS,
    p.ID_PACIENTE,
    p.NOME          AS NOME_PACIENTE,
    p.TELEFONE      AS TELEFONE_PACIENTE,
    e.CODIGO        AS CODIGO_EXAME,
    e.DESCRICAO     AS DESCRICAO_EXAME,
    e.TIPO          AS TIPO_EXAME,
    m.NOME          AS NOME_MEDICO_SOLICITANTE
FROM RESULTADOS_EXAMES re
JOIN CONSULTAS c ON c.ID_CONSULTA = re.ID_CONSULTA
JOIN PACIENTES p ON p.ID_PACIENTE = c.ID_PACIENTE
JOIN EXAMES    e ON e.ID_EXAME    = re.ID_EXAME
JOIN MEDICOS   m ON m.ID_MEDICO   = c.ID_MEDICO
WHERE re.STATUS IN ('SOLICITADO', 'COLETADO', 'EM_ANALISE');

COMMENT ON TABLE VW_EXAMES_PENDENTES IS 'Exames com resultado pendente';

-- -----------------------------------------------------------------------------
-- View: VW_INTERNACOES_ATIVAS
-- Descricao: Internacoes em curso com dados de leito e medico
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_INTERNACOES_ATIVAS AS
SELECT
    i.ID_INTERNACAO,
    i.DT_INTERNACAO,
    TRUNC(SYSDATE - i.DT_INTERNACAO)  AS DIAS_INTERNADO,
    p.ID_PACIENTE,
    p.NOME          AS NOME_PACIENTE,
    p.DT_NASCIMENTO,
    p.TIPO_SANGUINEO,
    l.CODIGO        AS CODIGO_LEITO,
    l.ALA,
    l.TIPO          AS TIPO_LEITO,
    m.NOME          AS NOME_MEDICO_RESP,
    e.DESCRICAO     AS ESPECIALIDADE,
    i.MOTIVO,
    i.DIAGNOSTICO_INT
FROM INTERNACOES i
JOIN PACIENTES    p ON p.ID_PACIENTE        = i.ID_PACIENTE
JOIN MEDICOS      m ON m.ID_MEDICO          = i.ID_MEDICO
JOIN ESPECIALIDADES e ON e.ID_ESPECIALIDADE = m.ID_ESPECIALIDADE
JOIN LEITOS       l ON l.ID_LEITO           = i.ID_LEITO
WHERE i.STATUS = 'INTERNADO';

COMMENT ON TABLE VW_INTERNACOES_ATIVAS IS 'Internacoes em andamento com dados do leito e equipe medica';

-- -----------------------------------------------------------------------------
-- View: VW_OCUPACAO_LEITOS
-- Descricao: Situacao atual de ocupacao dos leitos
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_OCUPACAO_LEITOS AS
SELECT
    l.ID_LEITO,
    l.CODIGO,
    l.ANDAR,
    l.ALA,
    l.TIPO,
    l.STATUS,
    i.ID_INTERNACAO,
    p.NOME          AS NOME_PACIENTE,
    i.DT_INTERNACAO,
    m.NOME          AS NOME_MEDICO_RESP
FROM LEITOS l
LEFT JOIN INTERNACOES i ON i.ID_LEITO  = l.ID_LEITO AND i.STATUS = 'INTERNADO'
LEFT JOIN PACIENTES   p ON p.ID_PACIENTE = i.ID_PACIENTE
LEFT JOIN MEDICOS     m ON m.ID_MEDICO   = i.ID_MEDICO
WHERE l.ATIVO = 'S'
ORDER BY l.ALA, l.CODIGO;

COMMENT ON TABLE VW_OCUPACAO_LEITOS IS 'Mapa de ocupacao atual de todos os leitos';

-- -----------------------------------------------------------------------------
-- View: VW_ALERGIAS_PACIENTE
-- Descricao: Alergias registradas por paciente com nivel de gravidade
-- -----------------------------------------------------------------------------
CREATE OR REPLACE VIEW VW_ALERGIAS_PACIENTE AS
SELECT
    a.ID_ALERGIA,
    p.ID_PACIENTE,
    p.NOME      AS NOME_PACIENTE,
    a.DESCRICAO AS DESCRICAO_ALERGIA,
    a.TIPO,
    a.GRAVIDADE,
    a.DT_REGISTRO,
    a.OBSERVACOES
FROM ALERGIAS a
JOIN PACIENTES p ON p.ID_PACIENTE = a.ID_PACIENTE
ORDER BY a.GRAVIDADE NULLS LAST, p.NOME;

COMMENT ON TABLE VW_ALERGIAS_PACIENTE IS 'Alergias dos pacientes ordenadas por gravidade';

COMMIT;
