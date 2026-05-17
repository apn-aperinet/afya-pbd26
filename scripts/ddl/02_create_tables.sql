-- =============================================================================
-- Arquivo: 02_create_tables.sql
-- Descricao: Criacao das tabelas principais do sistema
-- Projeto: AFYA PBD26 - Sistema de Prontuario Eletronico do Paciente
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Tabela: USUARIOS
-- Descricao: Usuarios do sistema (medicos, enfermeiros, administradores)
-- -----------------------------------------------------------------------------
CREATE TABLE USUARIOS (
    ID_USUARIO      NUMBER(10)      NOT NULL,
    NOME            VARCHAR2(100)   NOT NULL,
    EMAIL           VARCHAR2(150)   NOT NULL,
    SENHA_HASH      VARCHAR2(255)   NOT NULL,
    PERFIL          VARCHAR2(30)    NOT NULL,
    ATIVO           CHAR(1)         DEFAULT 'S' NOT NULL,
    DT_CRIACAO      DATE            DEFAULT SYSDATE NOT NULL,
    DT_ATUALIZACAO  DATE,
    DT_ULTIMO_LOGIN DATE,
    CONSTRAINT PK_USUARIOS PRIMARY KEY (ID_USUARIO),
    CONSTRAINT UK_USUARIOS_EMAIL UNIQUE (EMAIL),
    CONSTRAINT CK_USUARIOS_ATIVO CHECK (ATIVO IN ('S', 'N')),
    CONSTRAINT CK_USUARIOS_PERFIL CHECK (PERFIL IN ('ADMIN', 'MEDICO', 'ENFERMEIRO', 'RECEPCAO', 'FARMACIA'))
);

COMMENT ON TABLE  USUARIOS               IS 'Usuarios do sistema PBD26';
COMMENT ON COLUMN USUARIOS.ID_USUARIO    IS 'Identificador unico do usuario';
COMMENT ON COLUMN USUARIOS.NOME          IS 'Nome completo do usuario';
COMMENT ON COLUMN USUARIOS.EMAIL         IS 'E-mail de acesso ao sistema';
COMMENT ON COLUMN USUARIOS.SENHA_HASH    IS 'Hash da senha do usuario';
COMMENT ON COLUMN USUARIOS.PERFIL        IS 'Perfil de acesso: ADMIN, MEDICO, ENFERMEIRO, RECEPCAO, FARMACIA';
COMMENT ON COLUMN USUARIOS.ATIVO         IS 'Indicador de usuario ativo (S/N)';
COMMENT ON COLUMN USUARIOS.DT_CRIACAO    IS 'Data de criacao do registro';
COMMENT ON COLUMN USUARIOS.DT_ATUALIZACAO IS 'Data da ultima atualizacao do registro';
COMMENT ON COLUMN USUARIOS.DT_ULTIMO_LOGIN IS 'Data e hora do ultimo login';

-- -----------------------------------------------------------------------------
-- Tabela: ESPECIALIDADES
-- Descricao: Especialidades medicas
-- -----------------------------------------------------------------------------
CREATE TABLE ESPECIALIDADES (
    ID_ESPECIALIDADE  NUMBER(5)     NOT NULL,
    DESCRICAO         VARCHAR2(100) NOT NULL,
    CODIGO_CBO        VARCHAR2(10),
    ATIVO             CHAR(1)       DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_ESPECIALIDADES PRIMARY KEY (ID_ESPECIALIDADE),
    CONSTRAINT UK_ESPECIALIDADES_DESC UNIQUE (DESCRICAO),
    CONSTRAINT CK_ESPECIALIDADES_ATIVO CHECK (ATIVO IN ('S', 'N'))
);

COMMENT ON TABLE  ESPECIALIDADES              IS 'Especialidades medicas reconhecidas';
COMMENT ON COLUMN ESPECIALIDADES.ID_ESPECIALIDADE IS 'Identificador unico da especialidade';
COMMENT ON COLUMN ESPECIALIDADES.DESCRICAO    IS 'Descricao da especialidade medica';
COMMENT ON COLUMN ESPECIALIDADES.CODIGO_CBO   IS 'Codigo CBO da especialidade';
COMMENT ON COLUMN ESPECIALIDADES.ATIVO        IS 'Indicador de especialidade ativa (S/N)';

-- -----------------------------------------------------------------------------
-- Tabela: MEDICOS
-- Descricao: Dados dos medicos cadastrados
-- -----------------------------------------------------------------------------
CREATE TABLE MEDICOS (
    ID_MEDICO        NUMBER(10)    NOT NULL,
    ID_USUARIO       NUMBER(10)    NOT NULL,
    ID_ESPECIALIDADE NUMBER(5)     NOT NULL,
    CRM              VARCHAR2(20)  NOT NULL,
    UF_CRM           CHAR(2)       NOT NULL,
    NOME             VARCHAR2(100) NOT NULL,
    CPF              CHAR(11)      NOT NULL,
    DT_NASCIMENTO    DATE,
    TELEFONE         VARCHAR2(20),
    ATIVO            CHAR(1)       DEFAULT 'S' NOT NULL,
    DT_CRIACAO       DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_MEDICOS PRIMARY KEY (ID_MEDICO),
    CONSTRAINT UK_MEDICOS_CRM UNIQUE (CRM, UF_CRM),
    CONSTRAINT UK_MEDICOS_CPF UNIQUE (CPF),
    CONSTRAINT FK_MEDICOS_USUARIO FOREIGN KEY (ID_USUARIO) REFERENCES USUARIOS (ID_USUARIO),
    CONSTRAINT FK_MEDICOS_ESP FOREIGN KEY (ID_ESPECIALIDADE) REFERENCES ESPECIALIDADES (ID_ESPECIALIDADE),
    CONSTRAINT CK_MEDICOS_ATIVO CHECK (ATIVO IN ('S', 'N')),
    CONSTRAINT CK_MEDICOS_UF CHECK (UF_CRM IN ('AC','AL','AP','AM','BA','CE','DF','ES','GO','MA',
                                                'MT','MS','MG','PA','PB','PR','PE','PI','RJ','RN',
                                                'RS','RO','RR','SC','SP','SE','TO'))
);

COMMENT ON TABLE  MEDICOS              IS 'Cadastro de medicos do sistema';
COMMENT ON COLUMN MEDICOS.ID_MEDICO    IS 'Identificador unico do medico';
COMMENT ON COLUMN MEDICOS.ID_USUARIO   IS 'Referencia ao usuario do sistema';
COMMENT ON COLUMN MEDICOS.ID_ESPECIALIDADE IS 'Referencia a especialidade medica';
COMMENT ON COLUMN MEDICOS.CRM          IS 'Numero do Conselho Regional de Medicina';
COMMENT ON COLUMN MEDICOS.UF_CRM       IS 'Estado do CRM';
COMMENT ON COLUMN MEDICOS.NOME         IS 'Nome completo do medico';
COMMENT ON COLUMN MEDICOS.CPF          IS 'CPF do medico (somente digitos)';
COMMENT ON COLUMN MEDICOS.DT_NASCIMENTO IS 'Data de nascimento do medico';
COMMENT ON COLUMN MEDICOS.TELEFONE     IS 'Telefone de contato';
COMMENT ON COLUMN MEDICOS.ATIVO        IS 'Indicador de medico ativo (S/N)';

-- -----------------------------------------------------------------------------
-- Tabela: PACIENTES
-- Descricao: Cadastro de pacientes
-- -----------------------------------------------------------------------------
CREATE TABLE PACIENTES (
    ID_PACIENTE      NUMBER(10)    NOT NULL,
    NOME             VARCHAR2(100) NOT NULL,
    CPF              CHAR(11),
    CNS              VARCHAR2(15),
    DT_NASCIMENTO    DATE          NOT NULL,
    SEXO             CHAR(1)       NOT NULL,
    NOME_MAE         VARCHAR2(100),
    TELEFONE         VARCHAR2(20),
    EMAIL            VARCHAR2(150),
    LOGRADOURO       VARCHAR2(200),
    NUMERO           VARCHAR2(10),
    COMPLEMENTO      VARCHAR2(50),
    BAIRRO           VARCHAR2(100),
    CIDADE           VARCHAR2(100),
    UF               CHAR(2),
    CEP              CHAR(8),
    TIPO_SANGUINEO   VARCHAR2(5),
    ATIVO            CHAR(1)       DEFAULT 'S' NOT NULL,
    DT_CRIACAO       DATE          DEFAULT SYSDATE NOT NULL,
    DT_ATUALIZACAO   DATE,
    CONSTRAINT PK_PACIENTES PRIMARY KEY (ID_PACIENTE),
    CONSTRAINT UK_PACIENTES_CPF UNIQUE (CPF),
    CONSTRAINT UK_PACIENTES_CNS UNIQUE (CNS),
    CONSTRAINT CK_PACIENTES_SEXO CHECK (SEXO IN ('M', 'F', 'I')),
    CONSTRAINT CK_PACIENTES_ATIVO CHECK (ATIVO IN ('S', 'N')),
    CONSTRAINT CK_PACIENTES_TS CHECK (TIPO_SANGUINEO IN ('A+','A-','B+','B-','AB+','AB-','O+','O-'))
);

COMMENT ON TABLE  PACIENTES              IS 'Cadastro de pacientes atendidos';
COMMENT ON COLUMN PACIENTES.ID_PACIENTE  IS 'Identificador unico do paciente';
COMMENT ON COLUMN PACIENTES.NOME         IS 'Nome completo do paciente';
COMMENT ON COLUMN PACIENTES.CPF          IS 'CPF do paciente (somente digitos)';
COMMENT ON COLUMN PACIENTES.CNS          IS 'Cartao Nacional de Saude';
COMMENT ON COLUMN PACIENTES.DT_NASCIMENTO IS 'Data de nascimento';
COMMENT ON COLUMN PACIENTES.SEXO         IS 'Sexo: M=Masculino, F=Feminino, I=Indeterminado';
COMMENT ON COLUMN PACIENTES.NOME_MAE     IS 'Nome da mae do paciente';
COMMENT ON COLUMN PACIENTES.TIPO_SANGUINEO IS 'Tipo sanguineo do paciente';
COMMENT ON COLUMN PACIENTES.ATIVO        IS 'Indicador de paciente ativo (S/N)';

-- -----------------------------------------------------------------------------
-- Tabela: ALERGIAS
-- Descricao: Alergias cadastradas para os pacientes
-- -----------------------------------------------------------------------------
CREATE TABLE ALERGIAS (
    ID_ALERGIA   NUMBER(10)    NOT NULL,
    ID_PACIENTE  NUMBER(10)    NOT NULL,
    DESCRICAO    VARCHAR2(200) NOT NULL,
    TIPO         VARCHAR2(50),
    GRAVIDADE    VARCHAR2(20),
    DT_REGISTRO  DATE          DEFAULT SYSDATE NOT NULL,
    OBSERVACOES  VARCHAR2(500),
    CONSTRAINT PK_ALERGIAS PRIMARY KEY (ID_ALERGIA),
    CONSTRAINT FK_ALERGIAS_PACIENTE FOREIGN KEY (ID_PACIENTE) REFERENCES PACIENTES (ID_PACIENTE),
    CONSTRAINT CK_ALERGIAS_GRAVIDADE CHECK (GRAVIDADE IS NULL OR GRAVIDADE IN ('LEVE', 'MODERADA', 'GRAVE'))
);

COMMENT ON TABLE  ALERGIAS             IS 'Alergias registradas dos pacientes';
COMMENT ON COLUMN ALERGIAS.ID_ALERGIA  IS 'Identificador unico da alergia';
COMMENT ON COLUMN ALERGIAS.ID_PACIENTE IS 'Referencia ao paciente';
COMMENT ON COLUMN ALERGIAS.DESCRICAO   IS 'Descricao da alergia';
COMMENT ON COLUMN ALERGIAS.TIPO        IS 'Tipo da alergia (medicamento, alimento, etc.)';
COMMENT ON COLUMN ALERGIAS.GRAVIDADE   IS 'Gravidade: LEVE, MODERADA, GRAVE';

-- -----------------------------------------------------------------------------
-- Tabela: CONSULTAS
-- Descricao: Registro de consultas medicas
-- -----------------------------------------------------------------------------
CREATE TABLE CONSULTAS (
    ID_CONSULTA       NUMBER(10)    NOT NULL,
    ID_PACIENTE       NUMBER(10)    NOT NULL,
    ID_MEDICO         NUMBER(10)    NOT NULL,
    DT_CONSULTA       DATE          NOT NULL,
    DT_AGENDAMENTO    DATE,
    TIPO_ATENDIMENTO  VARCHAR2(30)  NOT NULL,
    STATUS            VARCHAR2(20)  DEFAULT 'AGENDADA' NOT NULL,
    QUEIXA_PRINCIPAL  VARCHAR2(500),
    ANAMNESE          CLOB,
    EXAME_FISICO      CLOB,
    HIPOTESE_DX       VARCHAR2(500),
    CONDUTA           CLOB,
    OBSERVACOES       VARCHAR2(1000),
    DT_CRIACAO        DATE          DEFAULT SYSDATE NOT NULL,
    DT_ATUALIZACAO    DATE,
    CONSTRAINT PK_CONSULTAS PRIMARY KEY (ID_CONSULTA),
    CONSTRAINT FK_CONSULTAS_PACIENTE FOREIGN KEY (ID_PACIENTE) REFERENCES PACIENTES (ID_PACIENTE),
    CONSTRAINT FK_CONSULTAS_MEDICO FOREIGN KEY (ID_MEDICO) REFERENCES MEDICOS (ID_MEDICO),
    CONSTRAINT CK_CONSULTAS_STATUS CHECK (STATUS IN ('AGENDADA','CONFIRMADA','EM_ATENDIMENTO','REALIZADA','CANCELADA','NAO_COMPARECEU')),
    CONSTRAINT CK_CONSULTAS_TIPO CHECK (TIPO_ATENDIMENTO IN ('CONSULTA','RETORNO','URGENCIA','EMERGENCIA','TELECONSULTA'))
);

COMMENT ON TABLE  CONSULTAS                IS 'Registro de consultas e atendimentos medicos';
COMMENT ON COLUMN CONSULTAS.ID_CONSULTA    IS 'Identificador unico da consulta';
COMMENT ON COLUMN CONSULTAS.ID_PACIENTE    IS 'Referencia ao paciente';
COMMENT ON COLUMN CONSULTAS.ID_MEDICO      IS 'Referencia ao medico responsavel';
COMMENT ON COLUMN CONSULTAS.DT_CONSULTA    IS 'Data e hora da consulta';
COMMENT ON COLUMN CONSULTAS.TIPO_ATENDIMENTO IS 'Tipo: CONSULTA, RETORNO, URGENCIA, EMERGENCIA, TELECONSULTA';
COMMENT ON COLUMN CONSULTAS.STATUS         IS 'Status: AGENDADA, CONFIRMADA, EM_ATENDIMENTO, REALIZADA, CANCELADA, NAO_COMPARECEU';
COMMENT ON COLUMN CONSULTAS.QUEIXA_PRINCIPAL IS 'Queixa principal relatada pelo paciente';
COMMENT ON COLUMN CONSULTAS.ANAMNESE       IS 'Anamnese completa da consulta';
COMMENT ON COLUMN CONSULTAS.EXAME_FISICO   IS 'Resultado do exame fisico';
COMMENT ON COLUMN CONSULTAS.HIPOTESE_DX    IS 'Hipotese diagnostica';
COMMENT ON COLUMN CONSULTAS.CONDUTA        IS 'Conduta medica definida';

-- -----------------------------------------------------------------------------
-- Tabela: DIAGNOSTICOS
-- Descricao: Diagnosticos vinculados as consultas (CID-10)
-- -----------------------------------------------------------------------------
CREATE TABLE DIAGNOSTICOS (
    ID_DIAGNOSTICO  NUMBER(10)   NOT NULL,
    ID_CONSULTA     NUMBER(10)   NOT NULL,
    CODIGO_CID      VARCHAR2(10) NOT NULL,
    DESCRICAO       VARCHAR2(300),
    TIPO            CHAR(1)      DEFAULT 'P' NOT NULL,
    CONSTRAINT PK_DIAGNOSTICOS PRIMARY KEY (ID_DIAGNOSTICO),
    CONSTRAINT FK_DIAGNOSTICOS_CONSULTA FOREIGN KEY (ID_CONSULTA) REFERENCES CONSULTAS (ID_CONSULTA),
    CONSTRAINT CK_DIAGNOSTICOS_TIPO CHECK (TIPO IN ('P', 'S'))
);

COMMENT ON TABLE  DIAGNOSTICOS              IS 'Diagnosticos (CID-10) vinculados as consultas';
COMMENT ON COLUMN DIAGNOSTICOS.ID_DIAGNOSTICO IS 'Identificador unico do diagnostico';
COMMENT ON COLUMN DIAGNOSTICOS.ID_CONSULTA  IS 'Referencia a consulta';
COMMENT ON COLUMN DIAGNOSTICOS.CODIGO_CID   IS 'Codigo CID-10 do diagnostico';
COMMENT ON COLUMN DIAGNOSTICOS.DESCRICAO    IS 'Descricao do diagnostico';
COMMENT ON COLUMN DIAGNOSTICOS.TIPO         IS 'Tipo: P=Principal, S=Secundario';

-- -----------------------------------------------------------------------------
-- Tabela: MEDICAMENTOS
-- Descricao: Cadastro de medicamentos
-- -----------------------------------------------------------------------------
CREATE TABLE MEDICAMENTOS (
    ID_MEDICAMENTO  NUMBER(10)    NOT NULL,
    NOME_GENERICO   VARCHAR2(200) NOT NULL,
    NOME_COMERCIAL  VARCHAR2(200),
    PRINCIPIO_ATIVO VARCHAR2(200),
    FORMA_FARM      VARCHAR2(50),
    CONCENTRACAO    VARCHAR2(50),
    REGISTRO_ANVISA VARCHAR2(20),
    CONTROLADO      CHAR(1)       DEFAULT 'N' NOT NULL,
    ATIVO           CHAR(1)       DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_MEDICAMENTOS PRIMARY KEY (ID_MEDICAMENTO),
    CONSTRAINT CK_MEDICAMENTOS_CONTROLADO CHECK (CONTROLADO IN ('S', 'N')),
    CONSTRAINT CK_MEDICAMENTOS_ATIVO CHECK (ATIVO IN ('S', 'N'))
);

COMMENT ON TABLE  MEDICAMENTOS                IS 'Cadastro de medicamentos do sistema';
COMMENT ON COLUMN MEDICAMENTOS.ID_MEDICAMENTO IS 'Identificador unico do medicamento';
COMMENT ON COLUMN MEDICAMENTOS.NOME_GENERICO  IS 'Nome generico do medicamento';
COMMENT ON COLUMN MEDICAMENTOS.NOME_COMERCIAL IS 'Nome comercial/marca';
COMMENT ON COLUMN MEDICAMENTOS.PRINCIPIO_ATIVO IS 'Principio ativo do medicamento';
COMMENT ON COLUMN MEDICAMENTOS.FORMA_FARM     IS 'Forma farmaceutica (comprimido, capsula, xarope, etc.)';
COMMENT ON COLUMN MEDICAMENTOS.CONCENTRACAO   IS 'Concentracao do medicamento';
COMMENT ON COLUMN MEDICAMENTOS.REGISTRO_ANVISA IS 'Numero de registro na ANVISA';
COMMENT ON COLUMN MEDICAMENTOS.CONTROLADO     IS 'Indicador de medicamento controlado (S/N)';

-- -----------------------------------------------------------------------------
-- Tabela: PRESCRICOES
-- Descricao: Prescricoes medicas vinculadas as consultas
-- -----------------------------------------------------------------------------
CREATE TABLE PRESCRICOES (
    ID_PRESCRICAO  NUMBER(10)   NOT NULL,
    ID_CONSULTA    NUMBER(10)   NOT NULL,
    ID_MEDICO      NUMBER(10)   NOT NULL,
    DT_PRESCRICAO  DATE         DEFAULT SYSDATE NOT NULL,
    DT_VALIDADE    DATE,
    STATUS         VARCHAR2(20) DEFAULT 'ATIVA' NOT NULL,
    OBSERVACOES    VARCHAR2(500),
    CONSTRAINT PK_PRESCRICOES PRIMARY KEY (ID_PRESCRICAO),
    CONSTRAINT FK_PRESCRICOES_CONSULTA FOREIGN KEY (ID_CONSULTA) REFERENCES CONSULTAS (ID_CONSULTA),
    CONSTRAINT FK_PRESCRICOES_MEDICO FOREIGN KEY (ID_MEDICO) REFERENCES MEDICOS (ID_MEDICO),
    CONSTRAINT CK_PRESCRICOES_STATUS CHECK (STATUS IN ('ATIVA', 'DISPENSADA', 'CANCELADA', 'VENCIDA'))
);

COMMENT ON TABLE  PRESCRICOES               IS 'Prescricoes medicas emitidas nas consultas';
COMMENT ON COLUMN PRESCRICOES.ID_PRESCRICAO IS 'Identificador unico da prescricao';
COMMENT ON COLUMN PRESCRICOES.ID_CONSULTA   IS 'Referencia a consulta geradora';
COMMENT ON COLUMN PRESCRICOES.ID_MEDICO     IS 'Referencia ao medico prescritor';
COMMENT ON COLUMN PRESCRICOES.DT_PRESCRICAO IS 'Data de emissao da prescricao';
COMMENT ON COLUMN PRESCRICOES.DT_VALIDADE   IS 'Data de validade da prescricao';
COMMENT ON COLUMN PRESCRICOES.STATUS        IS 'Status: ATIVA, DISPENSADA, CANCELADA, VENCIDA';

-- -----------------------------------------------------------------------------
-- Tabela: ITENS_PRESCRICAO
-- Descricao: Itens (medicamentos) de cada prescricao
-- -----------------------------------------------------------------------------
CREATE TABLE ITENS_PRESCRICAO (
    ID_ITEM_PRESCRICAO NUMBER(10)    NOT NULL,
    ID_PRESCRICAO      NUMBER(10)    NOT NULL,
    ID_MEDICAMENTO     NUMBER(10)    NOT NULL,
    POSOLOGIA          VARCHAR2(200) NOT NULL,
    QUANTIDADE         NUMBER(5,0)   NOT NULL,
    UNIDADE            VARCHAR2(20)  NOT NULL,
    DURACAO_DIAS       NUMBER(3,0),
    ORIENTACOES        VARCHAR2(500),
    CONSTRAINT PK_ITENS_PRESCRICAO PRIMARY KEY (ID_ITEM_PRESCRICAO),
    CONSTRAINT FK_ITENS_PRESC_PRESCRICAO FOREIGN KEY (ID_PRESCRICAO) REFERENCES PRESCRICOES (ID_PRESCRICAO),
    CONSTRAINT FK_ITENS_PRESC_MEDICAMENTO FOREIGN KEY (ID_MEDICAMENTO) REFERENCES MEDICAMENTOS (ID_MEDICAMENTO)
);

COMMENT ON TABLE  ITENS_PRESCRICAO                  IS 'Itens de medicamentos de cada prescricao';
COMMENT ON COLUMN ITENS_PRESCRICAO.ID_ITEM_PRESCRICAO IS 'Identificador unico do item';
COMMENT ON COLUMN ITENS_PRESCRICAO.ID_PRESCRICAO    IS 'Referencia a prescricao';
COMMENT ON COLUMN ITENS_PRESCRICAO.ID_MEDICAMENTO   IS 'Referencia ao medicamento';
COMMENT ON COLUMN ITENS_PRESCRICAO.POSOLOGIA        IS 'Posologia (dose e frequencia)';
COMMENT ON COLUMN ITENS_PRESCRICAO.QUANTIDADE       IS 'Quantidade prescrita';
COMMENT ON COLUMN ITENS_PRESCRICAO.UNIDADE          IS 'Unidade de medida (cp, ml, etc.)';
COMMENT ON COLUMN ITENS_PRESCRICAO.DURACAO_DIAS     IS 'Duracao do tratamento em dias';
COMMENT ON COLUMN ITENS_PRESCRICAO.ORIENTACOES      IS 'Orientacoes de uso';

-- -----------------------------------------------------------------------------
-- Tabela: EXAMES
-- Descricao: Tipos de exames disponiveis
-- -----------------------------------------------------------------------------
CREATE TABLE EXAMES (
    ID_EXAME    NUMBER(10)    NOT NULL,
    CODIGO      VARCHAR2(20)  NOT NULL,
    DESCRICAO   VARCHAR2(200) NOT NULL,
    TIPO        VARCHAR2(50),
    PREPARACAO  VARCHAR2(500),
    ATIVO       CHAR(1)       DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_EXAMES PRIMARY KEY (ID_EXAME),
    CONSTRAINT UK_EXAMES_CODIGO UNIQUE (CODIGO),
    CONSTRAINT CK_EXAMES_ATIVO CHECK (ATIVO IN ('S', 'N'))
);

COMMENT ON TABLE  EXAMES            IS 'Catalogo de tipos de exames disponiveis';
COMMENT ON COLUMN EXAMES.ID_EXAME   IS 'Identificador unico do tipo de exame';
COMMENT ON COLUMN EXAMES.CODIGO     IS 'Codigo do exame (tabela TUSS/CBHPM)';
COMMENT ON COLUMN EXAMES.DESCRICAO  IS 'Descricao do exame';
COMMENT ON COLUMN EXAMES.TIPO       IS 'Tipo do exame (laboratorial, imagem, etc.)';
COMMENT ON COLUMN EXAMES.PREPARACAO IS 'Instrucoes de preparacao para o exame';
COMMENT ON COLUMN EXAMES.ATIVO      IS 'Indicador de exame ativo (S/N)';

-- -----------------------------------------------------------------------------
-- Tabela: RESULTADOS_EXAMES
-- Descricao: Resultados de exames dos pacientes
-- -----------------------------------------------------------------------------
CREATE TABLE RESULTADOS_EXAMES (
    ID_RESULTADO    NUMBER(10)    NOT NULL,
    ID_CONSULTA     NUMBER(10)    NOT NULL,
    ID_EXAME        NUMBER(10)    NOT NULL,
    DT_SOLICITACAO  DATE          DEFAULT SYSDATE NOT NULL,
    DT_COLETA       DATE,
    DT_RESULTADO    DATE,
    STATUS          VARCHAR2(20)  DEFAULT 'SOLICITADO' NOT NULL,
    RESULTADO       CLOB,
    LAUDO           CLOB,
    OBSERVACOES     VARCHAR2(500),
    CONSTRAINT PK_RESULTADOS_EXAMES PRIMARY KEY (ID_RESULTADO),
    CONSTRAINT FK_RESULT_EXAME_CONSULTA FOREIGN KEY (ID_CONSULTA) REFERENCES CONSULTAS (ID_CONSULTA),
    CONSTRAINT FK_RESULT_EXAME_EXAME FOREIGN KEY (ID_EXAME) REFERENCES EXAMES (ID_EXAME),
    CONSTRAINT CK_RESULT_EXAME_STATUS CHECK (STATUS IN ('SOLICITADO','COLETADO','EM_ANALISE','DISPONIVEL','CANCELADO'))
);

COMMENT ON TABLE  RESULTADOS_EXAMES              IS 'Resultados de exames solicitados nas consultas';
COMMENT ON COLUMN RESULTADOS_EXAMES.ID_RESULTADO IS 'Identificador unico do resultado';
COMMENT ON COLUMN RESULTADOS_EXAMES.ID_CONSULTA  IS 'Referencia a consulta de solicitacao';
COMMENT ON COLUMN RESULTADOS_EXAMES.ID_EXAME     IS 'Referencia ao tipo de exame';
COMMENT ON COLUMN RESULTADOS_EXAMES.DT_SOLICITACAO IS 'Data de solicitacao do exame';
COMMENT ON COLUMN RESULTADOS_EXAMES.DT_COLETA    IS 'Data da coleta';
COMMENT ON COLUMN RESULTADOS_EXAMES.DT_RESULTADO IS 'Data de disponibilizacao do resultado';
COMMENT ON COLUMN RESULTADOS_EXAMES.STATUS       IS 'Status: SOLICITADO, COLETADO, EM_ANALISE, DISPONIVEL, CANCELADO';
COMMENT ON COLUMN RESULTADOS_EXAMES.RESULTADO    IS 'Resultado do exame';
COMMENT ON COLUMN RESULTADOS_EXAMES.LAUDO        IS 'Laudo medico do exame';

-- -----------------------------------------------------------------------------
-- Tabela: LEITOS
-- Descricao: Cadastro de leitos hospitalares
-- -----------------------------------------------------------------------------
CREATE TABLE LEITOS (
    ID_LEITO    NUMBER(10)   NOT NULL,
    CODIGO      VARCHAR2(20) NOT NULL,
    ANDAR       VARCHAR2(10),
    ALA         VARCHAR2(50),
    TIPO        VARCHAR2(30) NOT NULL,
    STATUS      VARCHAR2(20) DEFAULT 'DISPONIVEL' NOT NULL,
    ATIVO       CHAR(1)      DEFAULT 'S' NOT NULL,
    CONSTRAINT PK_LEITOS PRIMARY KEY (ID_LEITO),
    CONSTRAINT UK_LEITOS_CODIGO UNIQUE (CODIGO),
    CONSTRAINT CK_LEITOS_TIPO CHECK (TIPO IN ('ENFERMARIA','UTI','APARTAMENTO','ISOLAMENTO','OBSERVACAO')),
    CONSTRAINT CK_LEITOS_STATUS CHECK (STATUS IN ('DISPONIVEL','OCUPADO','MANUTENCAO','INTERDITADO')),
    CONSTRAINT CK_LEITOS_ATIVO CHECK (ATIVO IN ('S', 'N'))
);

COMMENT ON TABLE  LEITOS          IS 'Cadastro de leitos hospitalares';
COMMENT ON COLUMN LEITOS.ID_LEITO IS 'Identificador unico do leito';
COMMENT ON COLUMN LEITOS.CODIGO   IS 'Codigo identificador do leito';
COMMENT ON COLUMN LEITOS.ANDAR    IS 'Andar onde o leito esta localizado';
COMMENT ON COLUMN LEITOS.ALA      IS 'Ala/setor do leito';
COMMENT ON COLUMN LEITOS.TIPO     IS 'Tipo: ENFERMARIA, UTI, APARTAMENTO, ISOLAMENTO, OBSERVACAO';
COMMENT ON COLUMN LEITOS.STATUS   IS 'Status: DISPONIVEL, OCUPADO, MANUTENCAO, INTERDITADO';

-- -----------------------------------------------------------------------------
-- Tabela: INTERNACOES
-- Descricao: Registro de internacoes hospitalares
-- -----------------------------------------------------------------------------
CREATE TABLE INTERNACOES (
    ID_INTERNACAO   NUMBER(10)    NOT NULL,
    ID_PACIENTE     NUMBER(10)    NOT NULL,
    ID_MEDICO       NUMBER(10)    NOT NULL,
    ID_LEITO        NUMBER(10)    NOT NULL,
    DT_INTERNACAO   DATE          NOT NULL,
    DT_ALTA         DATE,
    MOTIVO          VARCHAR2(500) NOT NULL,
    DIAGNOSTICO_INT VARCHAR2(300),
    STATUS          VARCHAR2(20)  DEFAULT 'INTERNADO' NOT NULL,
    OBSERVACOES     VARCHAR2(1000),
    DT_CRIACAO      DATE          DEFAULT SYSDATE NOT NULL,
    CONSTRAINT PK_INTERNACOES PRIMARY KEY (ID_INTERNACAO),
    CONSTRAINT FK_INTERNACOES_PACIENTE FOREIGN KEY (ID_PACIENTE) REFERENCES PACIENTES (ID_PACIENTE),
    CONSTRAINT FK_INTERNACOES_MEDICO FOREIGN KEY (ID_MEDICO) REFERENCES MEDICOS (ID_MEDICO),
    CONSTRAINT FK_INTERNACOES_LEITO FOREIGN KEY (ID_LEITO) REFERENCES LEITOS (ID_LEITO),
    CONSTRAINT CK_INTERNACOES_STATUS CHECK (STATUS IN ('INTERNADO','ALTA','OBITO','TRANSFERIDO')),
    CONSTRAINT CK_INTERNACOES_DATAS CHECK (DT_ALTA IS NULL OR DT_ALTA >= DT_INTERNACAO)
);

COMMENT ON TABLE  INTERNACOES                IS 'Registro de internacoes hospitalares';
COMMENT ON COLUMN INTERNACOES.ID_INTERNACAO  IS 'Identificador unico da internacao';
COMMENT ON COLUMN INTERNACOES.ID_PACIENTE    IS 'Referencia ao paciente internado';
COMMENT ON COLUMN INTERNACOES.ID_MEDICO      IS 'Referencia ao medico responsavel';
COMMENT ON COLUMN INTERNACOES.ID_LEITO       IS 'Referencia ao leito ocupado';
COMMENT ON COLUMN INTERNACOES.DT_INTERNACAO  IS 'Data e hora da internacao';
COMMENT ON COLUMN INTERNACOES.DT_ALTA        IS 'Data e hora da alta';
COMMENT ON COLUMN INTERNACOES.MOTIVO         IS 'Motivo da internacao';
COMMENT ON COLUMN INTERNACOES.STATUS         IS 'Status: INTERNADO, ALTA, OBITO, TRANSFERIDO';

-- -----------------------------------------------------------------------------
-- Tabela: LOGS_AUDITORIA
-- Descricao: Log de auditoria de acoes dos usuarios
-- -----------------------------------------------------------------------------
CREATE TABLE LOGS_AUDITORIA (
    ID_LOG        NUMBER(15)    NOT NULL,
    ID_USUARIO    NUMBER(10),
    DT_ACAO       DATE          DEFAULT SYSDATE NOT NULL,
    TABELA        VARCHAR2(50)  NOT NULL,
    ID_REGISTRO   NUMBER(15),
    OPERACAO      VARCHAR2(10)  NOT NULL,
    DADOS_ANTES   CLOB,
    DADOS_DEPOIS  CLOB,
    IP_ORIGEM     VARCHAR2(45),
    CONSTRAINT PK_LOGS_AUDITORIA PRIMARY KEY (ID_LOG),
    CONSTRAINT FK_LOGS_AUD_USUARIO FOREIGN KEY (ID_USUARIO) REFERENCES USUARIOS (ID_USUARIO),
    CONSTRAINT CK_LOGS_AUD_OPERACAO CHECK (OPERACAO IN ('INSERT', 'UPDATE', 'DELETE', 'SELECT'))
);

COMMENT ON TABLE  LOGS_AUDITORIA              IS 'Log de auditoria de todas as operacoes no sistema';
COMMENT ON COLUMN LOGS_AUDITORIA.ID_LOG       IS 'Identificador unico do log';
COMMENT ON COLUMN LOGS_AUDITORIA.ID_USUARIO   IS 'Referencia ao usuario que executou a acao';
COMMENT ON COLUMN LOGS_AUDITORIA.DT_ACAO      IS 'Data e hora da acao';
COMMENT ON COLUMN LOGS_AUDITORIA.TABELA       IS 'Tabela onde a operacao foi realizada';
COMMENT ON COLUMN LOGS_AUDITORIA.ID_REGISTRO  IS 'ID do registro afetado';
COMMENT ON COLUMN LOGS_AUDITORIA.OPERACAO     IS 'Tipo de operacao: INSERT, UPDATE, DELETE, SELECT';
COMMENT ON COLUMN LOGS_AUDITORIA.DADOS_ANTES  IS 'Estado do registro antes da alteracao (JSON)';
COMMENT ON COLUMN LOGS_AUDITORIA.DADOS_DEPOIS IS 'Estado do registro apos a alteracao (JSON)';
COMMENT ON COLUMN LOGS_AUDITORIA.IP_ORIGEM    IS 'IP de origem da requisicao';

COMMIT;
