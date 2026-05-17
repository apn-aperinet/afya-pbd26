# afya-pbd26

Sistema de Prontuário Eletrônico do Paciente — Scripts Oracle

## Descrição

Este repositório contém os scripts Oracle SQL para o sistema **AFYA PBD26**, um sistema de gestão de prontuário eletrônico do paciente. Os scripts cobrem todo o ciclo de vida do banco de dados: criação do schema, dados iniciais, views, triggers e stored procedures.

## Estrutura do Projeto

```
afya-pbd26/
├── install.sql                    # Script mestre de instalação
└── scripts/
    ├── ddl/
    │   ├── 01_create_sequences.sql   # Sequences para geração de IDs
    │   ├── 02_create_tables.sql      # Tabelas principais do sistema
    │   └── 03_create_indexes.sql     # Índices para otimização
    ├── dml/
    │   └── 01_seed_data.sql          # Dados iniciais (especialidades, exames, leitos, etc.)
    ├── views/
    │   └── 01_views.sql              # Views para consultas frequentes
    ├── triggers/
    │   └── 01_triggers.sql           # Triggers de automação e auditoria
    └── procedures/
        └── 01_procedures.sql         # Packages e stored procedures
```

## Tabelas

| Tabela              | Descrição                                  |
|---------------------|--------------------------------------------|
| `USUARIOS`          | Usuários do sistema                        |
| `ESPECIALIDADES`    | Especialidades médicas                     |
| `MEDICOS`           | Cadastro de médicos                        |
| `PACIENTES`         | Cadastro de pacientes                      |
| `ALERGIAS`          | Alergias dos pacientes                     |
| `CONSULTAS`         | Consultas e atendimentos                   |
| `DIAGNOSTICOS`      | Diagnósticos CID-10 por consulta           |
| `MEDICAMENTOS`      | Catálogo de medicamentos                   |
| `PRESCRICOES`       | Prescrições médicas                        |
| `ITENS_PRESCRICAO`  | Itens de medicamentos de cada prescrição   |
| `EXAMES`            | Catálogo de exames                         |
| `RESULTADOS_EXAMES` | Resultados de exames solicitados           |
| `LEITOS`            | Cadastro de leitos hospitalares            |
| `INTERNACOES`       | Internações hospitalares                   |
| `LOGS_AUDITORIA`    | Log de auditoria de todas as operações     |

## Packages PL/SQL

| Package             | Descrição                                         |
|---------------------|---------------------------------------------------|
| `PKG_PACIENTES`     | Cadastro, atualização e busca de pacientes        |
| `PKG_CONSULTAS`     | Agendamento, atendimento e encerramento de consultas |
| `PKG_INTERNACOES`   | Internação, alta e transferência de leito         |

## Instalação

### Pré-requisitos

- Oracle Database 12c ou superior
- Usuário com privilégios: `CREATE TABLE`, `CREATE VIEW`, `CREATE SEQUENCE`, `CREATE PROCEDURE`, `CREATE TRIGGER`

### Execução

```bash
sqlplus usuario/senha@banco @install.sql
```

O script `install.sql` executa todos os scripts na ordem correta:

1. Sequences
2. Tabelas
3. Índices
4. Dados iniciais
5. Views
6. Triggers
7. Packages e procedures

### Execução individual

Caso precise executar apenas parte do schema, execute os scripts individualmente na ordem indicada:

```bash
sqlplus usuario/senha@banco @scripts/ddl/01_create_sequences.sql
sqlplus usuario/senha@banco @scripts/ddl/02_create_tables.sql
sqlplus usuario/senha@banco @scripts/ddl/03_create_indexes.sql
sqlplus usuario/senha@banco @scripts/dml/01_seed_data.sql
sqlplus usuario/senha@banco @scripts/views/01_views.sql
sqlplus usuario/senha@banco @scripts/triggers/01_triggers.sql
sqlplus usuario/senha@banco @scripts/procedures/01_procedures.sql
```

## Convenções

- Nomes de objetos em **maiúsculas**
- Prefixo de sequences: `SEQ_`
- Prefixo de índices: `IDX_`
- Prefixo de views: `VW_`
- Prefixo de triggers: `TRG_`
- Prefixo de packages: `PKG_`
- Prefixo de stored procedures: `SP_`
- Prefixo de funções: `FN_`
- Campos de auditoria padrão: `DT_CRIACAO`, `DT_ATUALIZACAO`, `ATIVO`
