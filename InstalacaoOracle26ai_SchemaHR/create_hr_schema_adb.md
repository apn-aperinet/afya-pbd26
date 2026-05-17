# Criação do Schema HR — Oracle Autonomous Database (ADB)

**Schema:** HR | **Banco:** Oracle AI Database 26ai — Autonomous Database (OCI)  
**Data de execução:** 2026-04-12  
**Script:** `create_hr_schema_adb.sql`

---

## Sobre o Schema HR

O schema HR (Human Resources) é o schema de exemplo oficial da Oracle, distribuído junto ao banco de dados desde o Oracle 8i. Ele modela uma empresa fictícia com funcionários, departamentos, cargos e localidades geográficas.

> **Atenção sobre versões:** Existe o HR clássico (IDs de regiões 1–4, datas nos anos 1990) e o HR moderno Oracle 23ai (IDs 10/20/30/40/50, datas nos anos 2010, telefones no formato internacional, 5 regiões com Oceania separada). Este documento usa a **versão Oracle 23ai**, extraída diretamente do on-premises Oracle 26ai para garantir paridade entre os ambientes.

---

## Diagrama de Relacionamento

```
REGIONS ──< COUNTRIES ──< LOCATIONS ──< DEPARTMENTS ──< EMPLOYEES
                                                              │
                                              JOBS ───────────┤
                                                              │
                                         EMPLOYEES (manager)──┤
                                                              │
                                         JOB_HISTORY ─────────┘
```

---

## Objetos Criados

| Tipo | Nome | Descrição |
|------|------|-----------|
| TABLE | REGIONS | 5 regiões geográficas |
| TABLE | COUNTRIES | 25 países |
| TABLE | LOCATIONS | 23 escritórios/endereços |
| TABLE | DEPARTMENTS | 27 departamentos |
| TABLE | JOBS | 19 cargos com faixas salariais |
| TABLE | EMPLOYEES | 107 funcionários |
| TABLE | JOB_HISTORY | 10 registros de histórico de cargos |
| SEQUENCE | LOCATIONS_SEQ | Gerador de IDs para locations |
| SEQUENCE | DEPARTMENTS_SEQ | Gerador de IDs para departments |
| SEQUENCE | EMPLOYEES_SEQ | Gerador de IDs para employees |
| INDEX | 11 índices | Desempenho em FKs e buscas comuns |
| VIEW | EMP_DETAILS_VIEW | Visão desnormalizada completa do funcionário |
| PROCEDURE | SECURE_DML | Restringe DML fora do horário comercial |
| PROCEDURE | ADD_JOB_HISTORY | Insere registro no histórico de cargos |
| TRIGGER | SECURE_EMPLOYEES | Chama SECURE_DML antes de qualquer DML em EMPLOYEES |
| TRIGGER | UPDATE_JOB_HISTORY | Grava histórico ao mudar cargo ou departamento |

---

## Pré-requisitos

- Conexão como **ADMIN** no ADB (Oracle Autonomous Database)
- Acesso ao **SQL Developer Web** (Database Actions) ou SQLcl com wallet configurado
- Política de senha do ADB ativa — a senha do usuário HR deve ter no mínimo 8 caracteres, maiúsculas, minúsculas, número e caractere especial

> **Política de senha no ADB:** O ADB possui um mandatory profile que não pode ser desabilitado, diferente do on-premises onde é possível alterar ou remover o profile. Senhas simples como `hr` são rejeitadas.

---

## Parte 1 — Criação do Usuário HR

> Execute como **ADMIN**. Se o usuário HR já existir de uma execução anterior, execute o `DROP` primeiro.

```sql
-- Remove HR completamente (tabelas, objetos, grants — tudo)
DROP USER hr CASCADE;

-- Cria o usuário HR com senha compatível com a política do ADB
CREATE USER hr IDENTIFIED BY "YourSecurePassword123#";

-- Privilégios básicos de conexão e criação de objetos
GRANT CONNECT, RESOURCE TO hr;

-- Define tablespace padrão e cota ilimitada
ALTER USER hr DEFAULT TABLESPACE DATA QUOTA UNLIMITED ON DATA;

-- Define tablespace temporária (para ordenações e operações de sort)
ALTER USER hr TEMPORARY TABLESPACE TEMP;

-- Privilégios adicionais necessários para o schema HR completo
GRANT CREATE VIEW, ALTER SESSION, CREATE SEQUENCE TO hr;
GRANT CREATE SYNONYM, CREATE DATABASE LINK TO hr;
GRANT EXECUTE ON sys.dbms_stats TO hr;

-- Habilita o schema para acesso via ORDS (Oracle REST Data Services)
-- Permite que o HR seja acessado como API REST no ADB
BEGIN
    ords_admin.enable_schema(
        p_enabled             => TRUE,
        p_schema              => 'HR',
        p_url_mapping_type    => 'BASE_PATH',
        p_url_mapping_pattern => 'peeps',
        p_auto_rest_auth      => TRUE
    );
    COMMIT;
END;
/
```

---

## Parte 2 — Criação das Tabelas

> A partir daqui execute conectado como **HR** (ou como ADMIN usando o prefixo `hr.`).

### Ordem de criação — dependências de FK

```
REGIONS → COUNTRIES → LOCATIONS → DEPARTMENTS ←→ EMPLOYEES → JOB_HISTORY
                                                      ↑
                                                    JOBS
```

> A FK `departments.manager_id → employees.employee_id` cria uma dependência circular entre DEPARTMENTS e EMPLOYEES. Por isso ela é adicionada via `ALTER TABLE` **depois** que ambas as tabelas existem.

```sql
-- REGIONS: tabela raiz da hierarquia geográfica
-- PK inline evita ALTER TABLE separado e garante que a PK existe
-- antes de qualquer FK referenciar esta tabela
CREATE TABLE hr.regions (
    region_id   NUMBER       CONSTRAINT region_id_nn NOT NULL,
    region_name VARCHAR2(25),
    CONSTRAINT  reg_id_pk    PRIMARY KEY (region_id)
);

-- COUNTRIES: referencia REGIONS via region_id
-- country_name tem VARCHAR2(60) para acomodar nomes longos
-- como "United Kingdom of Great Britain and Northern Ireland"
CREATE TABLE hr.countries (
    country_id   CHAR(2)      CONSTRAINT country_id_nn NOT NULL,
    country_name VARCHAR2(60),
    region_id    NUMBER,
    CONSTRAINT   country_c_id_pk PRIMARY KEY (country_id),
    CONSTRAINT   countr_reg_fk   FOREIGN KEY (region_id) REFERENCES hr.regions(region_id)
);

-- LOCATIONS: endereços físicos dos escritórios
-- Referencia COUNTRIES via country_id
CREATE TABLE hr.locations (
    location_id    NUMBER(4)    CONSTRAINT loc_id_pk   PRIMARY KEY,
    street_address VARCHAR2(40),
    postal_code    VARCHAR2(12),
    city           VARCHAR2(30) CONSTRAINT loc_city_nn NOT NULL,
    state_province VARCHAR2(25),
    country_id     CHAR(2),
    CONSTRAINT loc_c_id_fk FOREIGN KEY (country_id) REFERENCES hr.countries(country_id)
);

-- Sequence para geração automática de location_id
CREATE SEQUENCE hr.locations_seq START WITH 3300 INCREMENT BY 100 MAXVALUE 9900 NOCYCLE NOCACHE;

-- DEPARTMENTS: referencia LOCATIONS e futuramente EMPLOYEES (manager_id)
-- A FK dept_mgr_fk é criada depois via ALTER TABLE por causa da dependência circular
CREATE TABLE hr.departments (
    department_id   NUMBER(4)    CONSTRAINT dept_id_pk   PRIMARY KEY,
    department_name VARCHAR2(30) CONSTRAINT dept_name_nn NOT NULL,
    manager_id      NUMBER(6),
    location_id     NUMBER(4),
    CONSTRAINT dept_loc_fk FOREIGN KEY (location_id) REFERENCES hr.locations(location_id)
);

CREATE SEQUENCE hr.departments_seq START WITH 280 INCREMENT BY 10 MAXVALUE 9990 NOCYCLE NOCACHE;

-- JOBS: cargos com faixa salarial mínima e máxima
CREATE TABLE hr.jobs (
    job_id     VARCHAR2(10)  CONSTRAINT job_id_pk    PRIMARY KEY,
    job_title  VARCHAR2(35)  CONSTRAINT job_title_nn NOT NULL,
    min_salary NUMBER(6),
    max_salary NUMBER(6)
);

-- EMPLOYEES: tabela central do schema
-- Auto-referência: manager_id aponta para employee_id da mesma tabela (SELF JOIN)
-- commission_pct: apenas para funcionários de vendas (SA_MAN, SA_REP)
CREATE TABLE hr.employees (
    employee_id    NUMBER(6)    CONSTRAINT emp_emp_id_pk    PRIMARY KEY,
    first_name     VARCHAR2(20),
    last_name      VARCHAR2(25) CONSTRAINT emp_last_name_nn NOT NULL,
    email          VARCHAR2(25) CONSTRAINT emp_email_nn     NOT NULL,
    phone_number   VARCHAR2(20),
    hire_date      DATE         CONSTRAINT emp_hire_date_nn NOT NULL,
    job_id         VARCHAR2(10) CONSTRAINT emp_job_nn       NOT NULL,
    salary         NUMBER(8,2),
    commission_pct NUMBER(2,2),
    manager_id     NUMBER(6),
    department_id  NUMBER(4),
    CONSTRAINT emp_salary_min CHECK (salary > 0),
    CONSTRAINT emp_email_uk   UNIQUE (email),
    CONSTRAINT emp_dept_fk    FOREIGN KEY (department_id) REFERENCES hr.departments(department_id),
    CONSTRAINT emp_job_fk     FOREIGN KEY (job_id)        REFERENCES hr.jobs(job_id),
    CONSTRAINT emp_manager_fk FOREIGN KEY (manager_id)    REFERENCES hr.employees(employee_id)
);

CREATE SEQUENCE hr.employees_seq START WITH 207 INCREMENT BY 1 NOCACHE NOCYCLE;

-- JOB_HISTORY: histórico de cargos anteriores
-- PK composta: um funcionário pode ter múltiplos registros, mas não dois na mesma data de início
-- CHECK: end_date deve ser posterior a start_date
CREATE TABLE hr.job_history (
    employee_id   NUMBER(6)    CONSTRAINT jhist_employee_nn   NOT NULL,
    start_date    DATE         CONSTRAINT jhist_start_date_nn NOT NULL,
    end_date      DATE         CONSTRAINT jhist_end_date_nn   NOT NULL,
    job_id        VARCHAR2(10) CONSTRAINT jhist_job_nn        NOT NULL,
    department_id NUMBER(4),
    CONSTRAINT jhist_emp_id_st_date_pk PRIMARY KEY (employee_id, start_date),
    CONSTRAINT jhist_date_interval     CHECK (end_date > start_date),
    CONSTRAINT jhist_emp_fk  FOREIGN KEY (employee_id)   REFERENCES hr.employees(employee_id),
    CONSTRAINT jhist_job_fk  FOREIGN KEY (job_id)        REFERENCES hr.jobs(job_id),
    CONSTRAINT jhist_dept_fk FOREIGN KEY (department_id) REFERENCES hr.departments(department_id)
);

-- FK tardia: resolvendo a dependência circular DEPARTMENTS ↔ EMPLOYEES
-- Só pode ser criada depois que EMPLOYEES já existe
ALTER TABLE hr.departments ADD CONSTRAINT dept_mgr_fk
    FOREIGN KEY (manager_id) REFERENCES hr.employees(employee_id);
```

---

## Parte 3 — Dados

### Estratégia de inserção — FK circular

> EMPLOYEES referencia DEPARTMENTS e DEPARTMENTS referencia EMPLOYEES (manager_id).  
> Para inserir dados sem violar FKs, as constraints são temporariamente desabilitadas durante o INSERT e reabilitadas após o COMMIT.

```sql
-- Desabilita FKs que criam dependência circular durante a carga de dados
ALTER TABLE hr.employees  DISABLE CONSTRAINT emp_dept_fk;
ALTER TABLE hr.employees  DISABLE CONSTRAINT emp_manager_fk;
ALTER TABLE hr.departments DISABLE CONSTRAINT dept_mgr_fk;
```

### Regiões (5 registros)

> Versão Oracle 23ai: IDs múltiplos de 10 e 5 regiões (Oceania e Africa separadas).  
> O HR clássico tinha apenas 4 regiões (IDs 1–4) com "Middle East and Africa" unificado.

```sql
INSERT INTO hr.regions VALUES (10, 'Europe');
INSERT INTO hr.regions VALUES (20, 'Americas');
INSERT INTO hr.regions VALUES (30, 'Asia');
INSERT INTO hr.regions VALUES (40, 'Oceania');
INSERT INTO hr.regions VALUES (50, 'Africa');
```

### Países (25 registros)

> Diferenças em relação ao HR clássico:
> - Reino Unido: `UK` → `GB` com nome completo (60 chars)
> - Argentina (`AR`) adicionada, HongKong (`HK`) removida
> - Israel e Kuwait movidos de "Middle East and Africa" para "Asia"

```sql
INSERT INTO hr.countries VALUES ('AR', 'Argentina',                                           20);
INSERT INTO hr.countries VALUES ('AU', 'Australia',                                           40);
INSERT INTO hr.countries VALUES ('BE', 'Belgium',                                             10);
INSERT INTO hr.countries VALUES ('BR', 'Brazil',                                              20);
INSERT INTO hr.countries VALUES ('CA', 'Canada',                                              20);
INSERT INTO hr.countries VALUES ('CH', 'Switzerland',                                         10);
INSERT INTO hr.countries VALUES ('CN', 'China',                                               30);
INSERT INTO hr.countries VALUES ('DE', 'Germany',                                             10);
INSERT INTO hr.countries VALUES ('DK', 'Denmark',                                             10);
INSERT INTO hr.countries VALUES ('EG', 'Egypt',                                               50);
INSERT INTO hr.countries VALUES ('FR', 'France',                                              10);
INSERT INTO hr.countries VALUES ('GB', 'United Kingdom of Great Britain and Northern Ireland', 10);
INSERT INTO hr.countries VALUES ('IL', 'Israel',                                              30);
INSERT INTO hr.countries VALUES ('IN', 'India',                                               30);
INSERT INTO hr.countries VALUES ('IT', 'Italy',                                               10);
INSERT INTO hr.countries VALUES ('JP', 'Japan',                                               30);
INSERT INTO hr.countries VALUES ('KW', 'Kuwait',                                              30);
INSERT INTO hr.countries VALUES ('ML', 'Malaysia',                                            30);
INSERT INTO hr.countries VALUES ('MX', 'Mexico',                                              20);
INSERT INTO hr.countries VALUES ('NG', 'Nigeria',                                             50);
INSERT INTO hr.countries VALUES ('NL', 'Netherlands',                                         10);
INSERT INTO hr.countries VALUES ('SG', 'Singapore',                                           30);
INSERT INTO hr.countries VALUES ('US', 'United States of America',                            20);
INSERT INTO hr.countries VALUES ('ZM', 'Zambia',                                              50);
INSERT INTO hr.countries VALUES ('ZW', 'Zimbabwe',                                            50);
```

### Localizações (23 registros)

```sql
INSERT INTO hr.locations VALUES (1000, '1297 Via Cola di Rie',                     '00989',       'Roma',               NULL,              'IT');
INSERT INTO hr.locations VALUES (1100, '93091 Calle della Testa',                  '10934',       'Venice',             NULL,              'IT');
INSERT INTO hr.locations VALUES (1200, '2017 Shinjuku-ku',                         '1689',        'Tokyo',              'Tokyo Prefecture', 'JP');
INSERT INTO hr.locations VALUES (1300, '9450 Kamiya-cho',                          '6823',        'Hiroshima',          NULL,              'JP');
INSERT INTO hr.locations VALUES (1400, '2014 Jabberwocky Rd',                      '26192',       'Southlake',          'Texas',           'US');
INSERT INTO hr.locations VALUES (1500, '2011 Interiors Blvd',                      '99236',       'South San Francisco','California',      'US');
INSERT INTO hr.locations VALUES (1600, '2007 Zagora St',                           '50090',       'South Brunswick',    'New Jersey',      'US');
INSERT INTO hr.locations VALUES (1700, '2004 Charade Rd',                          '98199',       'Seattle',            'Washington',      'US');
INSERT INTO hr.locations VALUES (1800, '147 Spadina Ave',                          'M5V 2L7',     'Toronto',            'Ontario',         'CA');
INSERT INTO hr.locations VALUES (1900, '6092 Boxwood St',                          'YSW 9T2',     'Whitehorse',         'Yukon',           'CA');
INSERT INTO hr.locations VALUES (2000, '40-5-12 Laogianggen',                      '190518',      'Beijing',            NULL,              'CN');
INSERT INTO hr.locations VALUES (2100, '1298 Vileparle (E)',                        '490231',      'Bombay',             'Maharashtra',     'IN');
INSERT INTO hr.locations VALUES (2200, '12-98 Victoria Street',                    '2901',        'Sydney',             'New South Wales', 'AU');
INSERT INTO hr.locations VALUES (2300, '198 Clementi North',                       '540198',      'Singapore',          NULL,              'SG');
INSERT INTO hr.locations VALUES (2400, '8204 Arthur St',                           NULL,          'London',             NULL,              'GB');
INSERT INTO hr.locations VALUES (2500, 'Magdalen Centre, The Oxford Science Park', 'OX9 9ZB',     'Oxford',             'Oxford',          'GB');
INSERT INTO hr.locations VALUES (2600, '9702 Chester Road',                        '09629850293', 'Stretford',          'Manchester',      'GB');
INSERT INTO hr.locations VALUES (2700, 'Schwanthalerstr. 7031',                    '80925',       'Munich',             'Bavaria',         'DE');
INSERT INTO hr.locations VALUES (2800, 'Rua Frei Caneca 1360 ',                    '01307-002',   'Sao Paulo',          'Sao Paulo',       'BR');
INSERT INTO hr.locations VALUES (2900, '20 Rue des Corps-Saints',                  '1730',        'Geneva',             'Geneve',          'CH');
INSERT INTO hr.locations VALUES (3000, 'Murtenstrasse 921',                        '3095',        'Bern',               'BE',              'CH');
INSERT INTO hr.locations VALUES (3100, 'Pieter Breughelstraat 837',                '3029SK',      'Utrecht',            'Utrecht',         'NL');
INSERT INTO hr.locations VALUES (3200, 'Mariano Escobedo 9991',                    '11932',       'Mexico City',        'Distrito Federal','MX');
```

### Cargos (19 registros)

```sql
INSERT INTO hr.jobs VALUES ('AC_ACCOUNT', 'Public Accountant',                     4200,  9000);
INSERT INTO hr.jobs VALUES ('AC_MGR',     'Accounting Manager',                    8200, 16000);
INSERT INTO hr.jobs VALUES ('AD_ASST',    'Administration Assistant',              3000,  6000);
INSERT INTO hr.jobs VALUES ('AD_PRES',    'President',                            20080, 40000);
INSERT INTO hr.jobs VALUES ('AD_VP',      'Administration Vice President',        15000, 30000);
INSERT INTO hr.jobs VALUES ('FI_ACCOUNT', 'Accountant',                           4200,  9000);
INSERT INTO hr.jobs VALUES ('FI_MGR',     'Finance Manager',                      8200, 16000);
INSERT INTO hr.jobs VALUES ('HR_REP',     'Human Resources Representative',       4000,  9000);
INSERT INTO hr.jobs VALUES ('IT_PROG',    'Programmer',                           4000, 10000);
INSERT INTO hr.jobs VALUES ('MK_MAN',     'Marketing Manager',                    9000, 15000);
INSERT INTO hr.jobs VALUES ('MK_REP',     'Marketing Representative',             4000,  9000);
INSERT INTO hr.jobs VALUES ('PR_REP',     'Public Relations Representative',      4500, 10500);
INSERT INTO hr.jobs VALUES ('PU_CLERK',   'Purchasing Clerk',                     2500,  5500);
INSERT INTO hr.jobs VALUES ('PU_MAN',     'Purchasing Manager',                   8000, 15000);
INSERT INTO hr.jobs VALUES ('SA_MAN',     'Sales Manager',                       10000, 20080);
INSERT INTO hr.jobs VALUES ('SA_REP',     'Sales Representative',                 6000, 12008);
INSERT INTO hr.jobs VALUES ('SH_CLERK',   'Shipping Clerk',                       2500,  5500);
INSERT INTO hr.jobs VALUES ('ST_CLERK',   'Stock Clerk',                          2008,  5000);
INSERT INTO hr.jobs VALUES ('ST_MAN',     'Stock Manager',                        5500,  8500);
```

### Funcionários (107 registros) e Departamentos (27 registros)

> Inseridos com FKs circulares desabilitadas. Abaixo os primeiros registros como exemplo — o script completo contém todos os 107 funcionários.

```sql
-- Exemplos representativos da hierarquia
INSERT INTO hr.employees VALUES (100,'Steven',    'King',     'SKING',    '1.515.555.0100',DATE '2013-06-17','AD_PRES', 24000, NULL, NULL, 90); -- Presidente
INSERT INTO hr.employees VALUES (101,'Neena',     'Yang',     'NYANG',    '1.515.555.0101',DATE '2015-09-21','AD_VP',   17000, NULL,  100, 90); -- VP, reporta a King
INSERT INTO hr.employees VALUES (145,'John',      'Singh',    'JSINGH',   '44.1632.960000', DATE '2014-10-01','SA_MAN', 14000, .04,  100, 80); -- Sales Manager com comissão
INSERT INTO hr.employees VALUES (178,'Kimberely', 'Grant',    'KGRANT',   '44.1632.960033', DATE '2017-05-24','SA_REP',  7000, .15,  149,NULL); -- Sem departamento (dept_id NULL)
-- ... (107 funcionários no total)

-- Departamentos com manager_id (requer emp_dept_fk desabilitado)
INSERT INTO hr.departments VALUES (10,  'Administration',       200, 1700);
INSERT INTO hr.departments VALUES (90,  'Executive',            100, 1700); -- manager = Steven King
INSERT INTO hr.departments VALUES (120, 'Treasury',            NULL, 1700); -- sem gerente
-- ... (27 departamentos no total)
```

### Histórico de Cargos (10 registros)

```sql
-- Registra cargos anteriores de funcionários que mudaram de posição
INSERT INTO hr.job_history VALUES (101, DATE '2007-09-21', DATE '2011-10-27', 'AC_ACCOUNT', 110); -- Neena Yang: foi AC_ACCOUNT
INSERT INTO hr.job_history VALUES (101, DATE '2011-10-28', DATE '2015-03-15', 'AC_MGR',     110); -- Neena Yang: depois AC_MGR
INSERT INTO hr.job_history VALUES (102, DATE '2011-01-13', DATE '2016-07-24', 'IT_PROG',     60); -- Lex Garcia: foi IT_PROG
INSERT INTO hr.job_history VALUES (114, DATE '2016-03-24', DATE '2017-12-31', 'ST_CLERK',    50);
INSERT INTO hr.job_history VALUES (122, DATE '2017-01-01', DATE '2017-12-31', 'ST_CLERK',    50);
INSERT INTO hr.job_history VALUES (176, DATE '2016-03-24', DATE '2016-12-31', 'SA_REP',      80);
INSERT INTO hr.job_history VALUES (176, DATE '2017-01-01', DATE '2017-12-31', 'SA_MAN',      80);
INSERT INTO hr.job_history VALUES (200, DATE '2005-09-17', DATE '2011-06-17', 'AD_ASST',     90);
INSERT INTO hr.job_history VALUES (200, DATE '2012-07-01', DATE '2016-12-31', 'AC_ACCOUNT',  90);
INSERT INTO hr.job_history VALUES (201, DATE '2014-02-17', DATE '2017-12-19', 'MK_REP',      20);

COMMIT;

-- Reabilita FKs após carga completa
ALTER TABLE hr.employees  ENABLE CONSTRAINT emp_dept_fk;
ALTER TABLE hr.employees  ENABLE CONSTRAINT emp_manager_fk;
ALTER TABLE hr.departments ENABLE CONSTRAINT dept_mgr_fk;
```

---

## Parte 4 — Índices

> Índices criados em colunas de FK e de busca frequente para otimizar JOINs e filtros.

```sql
-- Índices em EMPLOYEES
CREATE INDEX hr.emp_department_ix     ON hr.employees  (department_id);  -- JOIN com DEPARTMENTS
CREATE INDEX hr.emp_job_ix            ON hr.employees  (job_id);          -- JOIN com JOBS
CREATE INDEX hr.emp_manager_ix        ON hr.employees  (manager_id);      -- SELF JOIN hierárquico
CREATE INDEX hr.emp_name_ix           ON hr.employees  (last_name, first_name); -- busca por nome

-- Índices em DEPARTMENTS
CREATE INDEX hr.dept_location_ix      ON hr.departments(location_id);     -- JOIN com LOCATIONS

-- Índices em JOB_HISTORY
CREATE INDEX hr.jhist_job_ix          ON hr.job_history(job_id);
CREATE INDEX hr.jhist_employee_ix     ON hr.job_history(employee_id);
CREATE INDEX hr.jhist_department_ix   ON hr.job_history(department_id);

-- Índices em LOCATIONS
CREATE INDEX hr.loc_city_ix           ON hr.locations  (city);
CREATE INDEX hr.loc_state_province_ix ON hr.locations  (state_province);
CREATE INDEX hr.loc_country_ix        ON hr.locations  (country_id);      -- JOIN com COUNTRIES
```

---

## Parte 5 — View

> `EMP_DETAILS_VIEW` desnormaliza as 6 tabelas principais em uma única visão.  
> Útil para relatórios e consultas analíticas sem escrever JOINs repetidamente.  
> `WITH READ ONLY` impede INSERT/UPDATE/DELETE direto na view.

```sql
CREATE OR REPLACE VIEW hr.emp_details_view AS
SELECT e.employee_id, e.job_id, e.manager_id, e.department_id,
       d.location_id, l.country_id,
       e.first_name, e.last_name, e.salary, e.commission_pct,
       d.department_name, j.job_title,
       l.city, l.state_province, c.country_name, r.region_name
FROM   hr.employees e, hr.departments d, hr.jobs j,
       hr.locations l, hr.countries c,   hr.regions r
WHERE  e.department_id = d.department_id
  AND  d.location_id   = l.location_id
  AND  l.country_id    = c.country_id
  AND  c.region_id     = r.region_id
  AND  j.job_id        = e.job_id
WITH READ ONLY;
```

---

## Parte 6 — Procedures e Triggers

### SECURE_DML

> Restringe operações DML (INSERT, UPDATE, DELETE) fora do horário comercial.  
> Lança `ORA-20205` se executada fora de seg–sex, 08:00–18:00.

```sql
CREATE OR REPLACE PROCEDURE hr.secure_dml IS
BEGIN
    IF TO_CHAR(SYSDATE, 'HH24:MI') NOT BETWEEN '08:00' AND '18:00'
        OR TO_CHAR(SYSDATE, 'DY') IN ('SAT', 'SUN') THEN
        RAISE_APPLICATION_ERROR(-20205,
            'You may only make changes during normal office hours');
    END IF;
END secure_dml;
/
```

### ADD_JOB_HISTORY

> Insere um registro em JOB_HISTORY. Chamada automaticamente pelo trigger `UPDATE_JOB_HISTORY`.

```sql
CREATE OR REPLACE PROCEDURE hr.add_job_history (
    p_emp_id        job_history.employee_id%TYPE,
    p_start_date    job_history.start_date%TYPE,
    p_end_date      job_history.end_date%TYPE,
    p_job_id        job_history.job_id%TYPE,
    p_department_id job_history.department_id%TYPE
) IS
BEGIN
    INSERT INTO hr.job_history (employee_id, start_date, end_date, job_id, department_id)
    VALUES (p_emp_id, p_start_date, p_end_date, p_job_id, p_department_id);
END add_job_history;
/
```

### SECURE_EMPLOYEES (trigger)

> Dispara **antes** de qualquer DML em EMPLOYEES.  
> Chama `SECURE_DML` para verificar horário — se fora do horário, a operação é bloqueada.

```sql
CREATE OR REPLACE TRIGGER hr.secure_employees
    BEFORE INSERT OR UPDATE OR DELETE ON hr.employees
BEGIN
    hr.secure_dml;
END secure_employees;
/
```

### UPDATE_JOB_HISTORY (trigger)

> Dispara **após** cada linha atualizada em EMPLOYEES quando `job_id` ou `department_id` muda.  
> Grava automaticamente o cargo anterior em JOB_HISTORY usando `:old` (valores antes do UPDATE).

```sql
CREATE OR REPLACE TRIGGER hr.update_job_history
    AFTER UPDATE OF job_id, department_id ON hr.employees
    FOR EACH ROW
BEGIN
    hr.add_job_history(:old.employee_id, :old.hire_date, SYSDATE,
                       :old.job_id, :old.department_id);
END;
/
```

---

## Verificação Final

```sql
SELECT 'REGIONS'     AS tabela, COUNT(*) AS registros FROM hr.regions     UNION ALL
SELECT 'COUNTRIES',             COUNT(*)              FROM hr.countries   UNION ALL
SELECT 'LOCATIONS',             COUNT(*)              FROM hr.locations   UNION ALL
SELECT 'DEPARTMENTS',           COUNT(*)              FROM hr.departments UNION ALL
SELECT 'JOBS',                  COUNT(*)              FROM hr.jobs        UNION ALL
SELECT 'EMPLOYEES',             COUNT(*)              FROM hr.employees   UNION ALL
SELECT 'JOB_HISTORY',           COUNT(*)              FROM hr.job_history
ORDER BY 1;
```

**Resultado esperado:**

| TABELA | REGISTROS |
|--------|-----------|
| COUNTRIES | 25 |
| DEPARTMENTS | 27 |
| EMPLOYEES | 107 |
| JOB_HISTORY | 10 |
| JOBS | 19 |
| LOCATIONS | 23 |
| REGIONS | 5 |

---

## Diferenças entre HR Clássico e HR Oracle 23ai

| Aspecto | HR Clássico | HR Oracle 23ai |
|---------|-------------|----------------|
| Regiões | 4 (IDs 1,2,3,4) | 5 (IDs 10,20,30,40,50) |
| Nomes de regiões | Middle East and Africa | Oceania + Africa separadas |
| Reino Unido | `UK` | `GB` (nome completo, 60 chars) |
| Argentina | Ausente | `AR` presente |
| HongKong | `HK` presente | Ausente |
| Israel/Kuwait | Região "Middle East and Africa" | Região "Asia" |
| Datas de contratação | Anos 1980–2000 | Anos 2011–2018 |
| Formato de telefone | `515.123.4567` | `1.515.555.0100` |
| country_name | VARCHAR2(40) | VARCHAR2(60) |

---

## Referências

- [Oracle 23ai — Sample Schemas GitHub](https://github.com/oracle-samples/db-sample-schemas)
- [Oracle Docs — HR Schema Diagram](https://docs.oracle.com/en/database/oracle/oracle-database/23/comsc/schema-diagrams.html)
- [Oracle ADB — Managing Users](https://docs.oracle.com/en/cloud/paas/autonomous-database/serverless/adbsb/manage-users.html)
