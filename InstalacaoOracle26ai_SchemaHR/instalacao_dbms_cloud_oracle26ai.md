# Instalação do DBMS_CLOUD no Oracle 23ai (26ai) On-Premises

**Ambiente:** Oracle AI Database 26ai Enterprise Edition Release 23.26.1.0.0  
**Host:** `ol9-orcl26-ribas` | **IP:** `<IP do banco>:1521`  
**CDB:** `orcl` | **PDB:** `ORCLPDB`  
**Data:** 2026-04-11

---

## Problema

Ao tentar executar os GRANTs necessários para o laboratório de **Select AI**, os seguintes erros ocorreram:

```sql
GRANT EXECUTE ON DBMS_CLOUD_AI TO HR;
GRANT EXECUTE ON DBMS_CLOUD_PIPELINE TO HR;
```

```
ORA-04042: procedure, function, package, or package body does not exist
```

**Causa raiz:** Os pacotes `DBMS_CLOUD_AI` e `DBMS_CLOUD_PIPELINE` fazem parte do **DBMS_CLOUD suite**, que não vem instalado por padrão em ambientes Oracle 23ai on-premises. Esses pacotes são pré-instalados apenas no Oracle Autonomous Database (nuvem).

---

## Diagnóstico

1. **Verificação via MCP Oracle SQLcl** — nenhum objeto DBMS_CLOUD encontrado no banco
2. **Script de instalação encontrado** no servidor:  
   `/u01/app/oracle/product/26ai/dbhome_1/rdbms/admin/dbms_cloud_install.sql`
3. **Primeira tentativa de instalação** falhou com `ORA-01435: user does not exist`  
   → O usuário CDB `C##CLOUD$SERVICE` não existia (pré-requisito não documentado)
4. **Segunda tentativa** (após criar o usuário) falhou com erros de compilação nos package bodies  
   → Dependências internas (`DBMS_SYS_SQL`, `DBMS_PDB_LIB`, `DBMS_LOCK`, `DBMS_PRIV_CAPTURE`) sem grant
5. **Instalação na PDB** necessária pois objetos no CDB root não são acessíveis via GRANT na PDB

---

## Solução Aplicada

### Passo 1 — Criar o usuário CDB `C##CLOUD$SERVICE`

Executado via `DBMS_SCHEDULER` (job externo) como `oracle` OS user no CDB root:

```sql
CREATE USER "C##CLOUD$SERVICE"
  NO AUTHENTICATION
  ACCOUNT LOCK
  DEFAULT TABLESPACE SYSAUX
  QUOTA UNLIMITED ON SYSAUX
  CONTAINER=ALL;

GRANT CREATE SESSION, CREATE TABLE, CREATE VIEW, CREATE SEQUENCE,
      CREATE PROCEDURE, CREATE TRIGGER, CREATE SYNONYM,
      CREATE PUBLIC SYNONYM, DROP PUBLIC SYNONYM,
      SELECT ANY DICTIONARY, ADMINISTER DATABASE TRIGGER,
      UNLIMITED TABLESPACE
TO "C##CLOUD$SERVICE" CONTAINER=ALL;
```

---

### Passo 2 — Instalar o DBMS_CLOUD na ORCLPDB

Criado SQL wrapper em `/tmp/install_pdb_wrapper.sql`:

```sql
ALTER SESSION SET CONTAINER = ORCLPDB;
@/u01/app/oracle/product/26ai/dbhome_1/rdbms/admin/dbms_cloud_install.sql
EXIT;
```

Executado via `DBMS_SCHEDULER` (job externo) com o comando:

```bash
export ORACLE_HOME=/u01/app/oracle/product/26ai/dbhome_1
export ORACLE_SID=orcl
export PATH=$ORACLE_HOME/bin:$PATH
$ORACLE_HOME/bin/sqlplus / as sysdba @/tmp/install_pdb_wrapper.sql
```

O script `dbms_cloud_install.sql` chama internamente:
- `catdbmscloud.sql` — catálogo (tabelas, views, sinônimos)
- `catdbmscloudpls.sql` — specs dos packages
- `prvtdbmscloudpls.sql` — bodies dos packages

---

### Passo 3 — Conceder dependências internas faltando

Os package bodies do `C##CLOUD$SERVICE` referenciam pacotes internos do SYS que não tinham grant. Executado na ORCLPDB como SYS:

```sql
GRANT EXECUTE ON SYS.DBMS_SYS_SQL     TO "C##CLOUD$SERVICE";
GRANT EXECUTE ON SYS.DBMS_PDB_LIB     TO "C##CLOUD$SERVICE";
GRANT EXECUTE ON SYS.DBMS_LOCK        TO "C##CLOUD$SERVICE";
GRANT EXECUTE ON SYS.DBMS_PRIV_CAPTURE TO "C##CLOUD$SERVICE";
```

---

### Passo 4 — Recompilar todos os objetos inválidos

```sql
EXEC UTL_RECOMP.RECOMP_SERIAL();
```

**Resultado — todos os 12 package bodies ficaram VALID:**

| Package Body | Status |
|---|---|
| DBMS_CLOUD | ✅ VALID |
| DBMS_CLOUD_AI | ✅ VALID |
| DBMS_CLOUD_AI_AGENT | ✅ VALID |
| DBMS_CLOUD_CAPABILITY | ✅ VALID |
| DBMS_CLOUD_CORE | ✅ VALID |
| DBMS_CLOUD_INTERNAL | ✅ VALID |
| DBMS_CLOUD_NOTIFICATION | ✅ VALID |
| DBMS_CLOUD_PIPELINE | ✅ VALID |
| DBMS_CLOUD_PIPELINE_INTERNAL | ✅ VALID |
| DBMS_CLOUD_REPO | ✅ VALID |
| DBMS_CLOUD_REQUEST | ✅ VALID |
| DBMS_CLOUD_TASK | ✅ VALID |

---

### Passo 5 — Executar os GRANTs do laboratório

```sql
GRANT EXECUTE ON DBMS_CLOUD_AI TO HR;
GRANT EXECUTE ON DBMS_CLOUD_PIPELINE TO HR;
```

```
Grant bem-sucedido.
Grant bem-sucedido.
```

---

## Objetos Instalados na ORCLPDB

- **Schema:** `C##CLOUD$SERVICE` (usuário CDB comum)
- **Sinônimos públicos** criados para todos os pacotes (acessíveis por qualquer usuário da PDB)
- **Tabelas de metadados:** `DBMS_CLOUD_AI_PROFILE$`, `DBMS_CLOUD_PIPELINE$`, `DBMS_CLOUD_TASK$`, etc.
- **Views DBA/ALL/USER:** `DBA_CLOUD_AI_PROFILES`, `USER_CLOUD_PIPELINES`, etc.

---

## Observações

- O script `dbms_cloud_install.sql` **já está incluído** no Oracle 23ai on-premises (`$ORACLE_HOME/rdbms/admin/`), mas **não é executado automaticamente** durante a instalação do banco
- A documentação oficial para instalação on-premises está na **MOS Note 2748362.1**
- O `DBMS_CLOUD_AI_AGENT` compilou com warnings sobre `SYS.DBMS_SYS_SQL` mas o package body ficou VALID após `UTL_RECOMP`
- Todos os jobs temporários de `DBMS_SCHEDULER` usados durante o processo foram criados com `auto_drop => TRUE`
