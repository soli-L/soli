
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_REDEFINITION" AUTHID CURRENT_USER AS
/* $Header: ADZDRDFS.pls 120.0.12020000.2 2015/04/17 07:07:17 sstomar noship $ */

/* --------------------------------------------------
             Private APIs
 -----------------------------------------------------*/

function GET_REDEF_METHOD(
  x_table_owner    varchar2,
  x_table_name     varchar2) return pls_integer;

function INTERIM_TABLE(X_TABLE_NAME varchar2) return VARCHAR2;

procedure START_TABLE_REDEF(
   x_table_owner varchar2,
   x_table_name varchar2,
   x_redef_method integer);

procedure CREATE_INTERIM_TABLE(
  x_table_owner varchar2,
  x_table_name varchar2);

procedure COPY_TABLE_DEPENDENTS(
  x_table_owner varchar2,
  x_table_name varchar2);

/* --------------------------------------------------
             Public APIs
 -----------------------------------------------------*/

-- This API will be populated in DDL_HANDLER table for cutover phase.
procedure FINALIZE(
  x_table_owner varchar2,
  x_table_name varchar2);

-- This API will be populated in DDL_HANDLER table for cutover phase.
procedure CUTOVER(
  x_table_owner varchar2,
  x_table_name varchar2);

-- Aborts the Redefinitions steps
procedure ABORT(
  x_table_owner varchar2,
  x_table_name varchar2);

-- Provides an interface that integrates several Table redefinition steps
procedure REDEFINE_TABLE(
  x_table_owner        varchar2,
  x_table_name         varchar2,
  x_interim_table_name varchar2 default null);

-- For future: If adop automatically finds and redefines those table
procedure REDEFINE_TABLES;

-- Compuete STATS for a given table to get the list of tables which need to be redefined
procedure COMPUTE_STATS(
  x_table_owner varchar2,
  x_table_name varchar2);

--  An interface API to Compuete STATS on ALL E-Biz tables.
procedure COMPUTE_STATS_ALL;


end AD_ZD_REDEFINITION;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_REDEFINITION" as
/* $Header: ADZDRDFB.pls 120.0.12020000.7 2022/01/18 08:17:34 rsatyava ship $ */

C_PACKAGE  CONSTANT varchar2(200) := 'ad.plsql.ad_zd_redefinition.';

/*--------------------------------------------------------------------
                    Internal

---------------------------------------------------------------------*/

-- log shortcut
procedure LOG(X_MODULE varchar2, X_LOG_TYPE varchar2, X_MESSAGE varchar2) is
begin
  ad_zd.log(x_module, x_log_type, x_message);
end;

-- error shortcut
procedure ERROR(X_MODULE varchar2, X_MESSAGE varchar2) is
begin
  ad_zd.error(x_module, x_message);
end;

-- exec shortcut (varchar2)
procedure EXEC(
  X_SQL        in varchar2,
  X_LOG_MOD    in varchar2,
  X_IGNORE     in boolean default false) is
begin
  ad_zd.exec(x_sql, x_log_mod, x_ignore);
end;

-- exec shortcut (clob)
procedure EXEC(
  X_SQL        in clob,
  X_LOG_MOD    in varchar2,
  X_IGNORE     in boolean default false) is
begin
  ad_zd.exec(x_sql, x_log_mod, x_ignore);
end;


-- Returns the interm table
function INTERIM_TABLE(X_TABLE_NAME varchar2) return varchar2
is
begin
  return substrb(upper(x_table_name),1,29)||'$';
end;

-- Desc:
--   Use PK method in following cases:
--     If primary key defined
--     If unique key defined on "all key columns as not null"
--     If unique index defined on "all indexed columns as not null"
--  in other cases we have no option but to use rowid
--
function GET_REDEF_METHOD(
  X_TABLE_OWNER   IN varchar2,
  X_TABLE_NAME    IN varchar2)
     return pls_integer
is
  C_MODULE varchar2(80) := c_package||'get_redef_method';
  NO_PRIMARY_KEY_ERROR exception;
  pragma exception_init(NO_PRIMARY_KEY_ERROR, -12089);

  L_USE_METHOD pls_integer := 0;
  L_PKEY_EXISTS integer := 0;
  L_UKEY_WITH_NULL_COL pls_integer := 1;

  -- Unique Constraints on NOT-NULL column
  cursor C_UNIQUE_CONS is
    select constraint_name
      from dba_constraints
      where owner = x_table_owner
        and table_name = x_table_name
        and constraint_type in('U')
        and status = 'ENABLED';

  cursor C_UNIQUE_INDEXES is
    select owner, index_name
     from   dba_indexes
     where  table_owner = x_table_owner
     and    table_name  = x_table_name
     and    uniqueness  = 'UNIQUE'
     and    status      = 'VALID';
begin

  log(c_module, 'PROCEDURE', 'begin:'|| x_table_owner || '.' || x_table_name);

  -- Let dbms_redefinition.can_redef_table check required criteria:
  begin
    dbms_redefinition.can_redef_table(x_table_owner, x_table_name, dbms_redefinition.cons_use_pk);
    l_use_method := dbms_redefinition.cons_use_pk;
  exception
    when no_primary_key_error then
      log(c_module,'WARNING', 'Table '||x_table_owner||'.'||X_table_name ||
                            ' cannot be redefined online with no primary key, will try ROWID to redefine');
      begin
        dbms_redefinition.can_redef_table(x_table_owner, x_table_name, dbms_redefinition.cons_use_rowid);
        l_use_method := dbms_redefinition.cons_use_rowid;
      exception
        when others then
          log(c_module,'ERROR', 'Table '||x_table_owner||'.'||X_table_name ||
                           ' cannot be redefined online with ROWID: ' || substr(sqlerrm, 1, 2000));
      end;
  end;

  return l_use_method;

  /* ALTERNATIVE WAY: we shouod check instead of can_redef_table ->

  -- Check if primary key exists
  select 1 into l_pkey_exists from dual
  where exists (select null
                from dba_constraints
                where owner = x_tab_owner
                  and table_name = x_tab_name
                  and constraint_type = 'P'
                  and status = 'ENABLED' );

   if l_pkey_exists > 0 then
     l_use_method := dbms_redefinition.cons_use_pk;
     return l_use_method;
   end if;

  -- check for unique key with all "not null" columns
  for l_cons in c_unique_cons loop

    select 1 into l_ukey_with_null_col from dual
    where exists
      (select null
       from dba_cons_columns conc,
            dba_tab_columns tabc
       where conc.owner = x_table_owner
         and conc.table_name = x_table_name
         and conc.constraint_name = l_con.constraint_name
         and tabc.owner = conc.owner
         and tabc.table_name = conc.table_name
         and tabc.column_name = conc.column_name
         and tabc.nullable='Y');

    -- If there is NO NOT NULL column in an UNIQUE key
    if l_ukey_with_null_col = 0 then
      l_use_method := dbms_redefinition.cons_use_pk;
      return l_use_method;
    end if;
  end loop;

  -- check for unique index with all "not null" columns
  for l_ind in c_unique_indexes loop
    select 1 into l_ukey_with_null_col from dual
    where exists
      (select null
       from dba_ind_columns idxc,
            dba_tab_columns tabc
       where idxc.index_owner = l_ind.owner
         and idxc.table_owner = x_table_owner
         and idxc.table_name = x_table_name
         and idxc.index_name = l_ind.index_name
         and tabc.owner = idxc.table_owner
         and tabc.table_name = idxc.table_name
         and tabc.column_name = idxc.column_name
         and tabc.nullable='Y');

    if(l_ukey_with_null_col = 0) then
      l_use_method := dbms_redefinition.cons_use_pk;
      return c_use_pk;
    end if;

  end loop;

  -- none of the above cases match. Use rowid
  l_use_method := dbms_redefinition.cons_use_rowid;
  return c_use_rowid;

  */

  log(c_module, 'PROCEDURE', 'end');
end GET_REDEF_METHOD;

-- Drops temporary objects created by DBMS_REDEFINITION API
--
procedure DROP_INTERIM_OBJECTS(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2,
  X_INTERIM_TABLE_NAME in varchar2)
is
  C_MODULE VARCHAR2(200) := c_package||'drop_interim_objects';
  L_TABLE_EXISTS pls_integer :=0 ;
begin

  begin
    select 1 into l_table_exists from dual
    where exists
      (select null
       from dba_tables
       where owner = x_table_owner
         and table_name = interim_table(x_table_name));
  exception
    when no_data_found then
      null;
  end;

  if(l_table_exists = 1) then
    dbms_redefinition.abort_redef_table(
       uname      => x_table_owner,
       orig_table => x_table_name,
       int_table  => '"' || interim_table(x_table_name) || '"' );

    exec('drop materialized view "'||x_table_owner||'"."'||interim_table(x_table_name)||'"',
         c_module, true);

    if(x_interim_table_name is null) then
      exec('drop table "'||x_table_owner||'"."'||interim_table(x_table_name)||'" cascade constraints',
           c_module, true);
    end if;
  end if;

end DROP_INTERIM_OBJECTS;


-- Create interim table which will have all the columns
-- of base table excpet UNUSED columns.
--
procedure CREATE_INTERIM_TABLE(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME in varchar2)
is
  C_MODULE VARCHAR2(200) := c_package||'create_interim_table';
  L_CREATE_STMT VARCHAR2(1000);
  L_FIRST_COL_IN_MAP boolean := true;
  L_TABLE_EXISTS pls_integer :=0 ;
  L_DDL clob;
  OBJECT_IS_ALREADY_USED_ERROR exception;
  pragma exception_init(object_is_already_used_error, -955);

--Assumption here is that Table Redefination is being called only from Patch edition
--Bug 23320643 is logged to preserve the middle version columns which are being used
--in run edition

  cursor C_OBSOLETE_COLUMNS(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
   select col.owner, col.table_name, col.column_name, col.nullable, col.data_default
      from  dba_tab_columns col
    where col.owner      = x_table_owner
     and col.table_name  = x_table_name
     and col.column_name not in ('ZD_EDITION_NAME', 'ZD_SYNC')
     and not exists
       ( select evc.table_column_name
           from  dba_editioning_view_cols evc
         where evc.owner     = x_table_owner
           and evc.view_name = substrb(x_table_name, 1, 29)||'#'
           and evc.table_column_name = col.column_name )
   order by col.owner, col.table_name, col.column_name;

begin

  log(c_module, 'PROCEDURE', 'begin:'|| x_table_owner || '.' || x_table_name);


   for colrec in c_obsolete_columns(x_table_owner, x_table_name) loop
      exec('alter table "'||colrec.owner||'"."'||colrec.table_name||'"'||
           '  set unused ('||colrec.column_name||')', c_module);
    end loop;


  l_ddl := dbms_metadata.get_ddl('TABLE', x_table_name, x_table_owner);

  -- TODO: Make table-name replacement logic more efficient sothat if there is any
  --       other object with same-name as table, it does not replace
  l_ddl := replace(l_ddl, '."'||x_table_name ||'"', '."'|| interim_table(x_table_name) ||'"');

  -- Create interim table
  exec(l_ddl, c_module, false);

  log(c_module, 'PROCEDURE', 'end');

end CREATE_INTERIM_TABLE;

--
--
-- Starts the defenition of table defenition
--
procedure START_TABLE_REDEF(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME in varchar2,
  X_REDEF_METHOD in integer)
is
  C_MODULE VARCHAR2(200) := c_package||'start_table_redef';
begin
  log(c_module, 'PROCEDURE', 'begin:'|| x_table_owner || '.' || x_table_name);

  dbms_redefinition.start_redef_table(
    uname        => x_table_owner,
    orig_table   => x_table_name,
    int_table    => '"' || interim_table(x_table_name) || '"',
    col_mapping  => null,
    options_flag => x_redef_method);

  ad_zd.load_ddl('ABORT','begin ad_zd_redefinition.abort('''||x_table_owner||''','''||x_table_name||'''); end;');

  log(c_module, 'PROCEDURE', 'end');

end START_TABLE_REDEF;

-- If you manually create dependent objects on the interim table,
-- you must then use the REGISTER_DEPENDENT_OBJECT procedure
-- to register the dependent objects.
procedure REGISTER_DEPENDENT_OBJECT(x_table_owner varchar2, x_table_name varchar2)
is
begin

  null;

end REGISTER_DEPENDENT_OBJECT;

-- Copy the dependent of a table
--  - Indexes
--  - Triggers
--  - grants
--
-- TODO: VPD policy have to check
--
procedure COPY_TABLE_DEPENDENTS(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME in varchar2)
is
  C_MODULE varchar2(200) := c_package||'copy_table_dependents';
  L_NUM_ERRORS pls_integer;
  L_ERR_OBJ_TYPE varchar2(30);
  L_ERR_OBJ_NAME varchar2(30);
  L_ERR_DDL_TEXT varchar2(2000);

begin
  log(c_module, 'PROCEDURE', 'begin:'|| x_table_owner || '.' || x_table_name);

  dbms_redefinition.copy_table_dependents(
    uname            => x_table_owner,
    orig_table       => x_table_name,
    int_table        => '"'|| interim_table(x_table_name) || '"',
    copy_indexes     => dbms_redefinition.cons_orig_params,  /* specify that indexes should be cloned
                                                                with their original storage parameters */
    copy_triggers    => true,
    copy_constraints => true,  /* Looks like [COPY_CONSTRAINT=true] is not working if interim table
                                   is being defined by using DBMS_METADATA */
    copy_privileges  => true,
    ignore_errors    => true,   -- TODO: make it [FALSE]
    num_errors       => l_num_errors,
    copy_statistics  => true,
    copy_mvlog       => true);


  if (l_num_errors > 0) then
    for l_err in
       (select object_type, object_name, dbms_lob.substr(ddl_txt,2000,1) ddl_txt
        from  dba_redefinition_errors
        where base_table_owner = x_table_owner
          and base_table_name = x_table_name)
    loop
      log(c_module, 'ERROR', l_err.object_type || ':' || l_err.object_name || ' :- '|| l_err.ddl_txt );
    end loop;
    --error(c_module, 'Error occured when copying table dependents: ' || x_table_owner ||'.' || x_table_name);
  end if;

  log(c_module, 'PROCEDURE', 'end');
end COPY_TABLE_DEPENDENTS;

/*-------------------------------------------------------------------

                    PUBLIC APIs  for table redefinition

---------------------------------------------------------------------*/


--
-- Finalize phase
procedure FINALIZE(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2)
is
  C_MODULE varchar2(100) := c_package||'finalize';
begin
  log(c_module, 'PROCEDURE', 'begin: '|| x_table_owner ||'.' || x_table_name);

  -- sync-up interim table
  dbms_redefinition.sync_interim_table(
      x_table_owner,
      x_table_name,
      '"' || ad_zd_redefinition.interim_table(x_table_name)||'"');

  -- NOTE: Gather stats is automatically taken-care by  dbms_redefinition
  log(c_module, 'PROCEDURE', 'end');

end FINALIZE;

-- Complete the redefinition
--
procedure CUTOVER(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME in varchar2)
is
  C_MODULE varchar2(100) := c_package||'cutover';
begin
  log(c_module, 'PROCEDURE', 'begin: '|| x_table_owner ||'.' || x_table_name);

  dbms_redefinition.finish_redef_table(
    uname      => x_table_owner,
    orig_table => x_table_name,
    int_table  => '"' || interim_table(x_table_name) || '"' );

  log(c_module, 'STATEMENT', 'Load DDL to drop interim table "'||x_table_owner||'"."'||interim_table(x_table_name)||'" in CLEANUP phase');

  ad_zd.load_ddl('CLEANUP','drop table "'||x_table_owner||'"."'||interim_table(x_table_name)||'"');
  log(c_module, 'PROCEDURE', 'end');
end CUTOVER;

--
-- If in case redefinition process needs to be aborted.
procedure ABORT(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2)
is
   C_MODULE varchar2(100) := c_package||'abort';
   INTRIM_TBL_NOT_EXISTS exception;
   pragma exception_init(INTRIM_TBL_NOT_EXISTS, -942);
begin
  log(c_module, 'PROCEDURE', 'begin:' || x_table_owner ||'.' || x_table_name);

  dbms_redefinition.abort_redef_table(
    uname => x_table_owner,
    orig_table => x_table_name,
    int_table => '"' || interim_table(x_table_name) || '"' );

  log(c_module, 'PROCEDURE', 'end');
exception
  when intrim_tbl_not_exists then
    log(c_module, 'WARNING', ' Interim table '|| interim_table(x_table_name) || ' does not exist. This error can be safely ignored ' );
  when others then
    error(c_module,  'Error: '  || x_table_owner ||'.' || x_table_name || ' -> ' || substr(sqlerrm, 1, 2000));
end ABORT;


--
-- Redefine a table by using dbms_redefinition
-- TODO: X_INTERIM_TABLE_NAME is required for a case where a non-partitioned
--       table to be redefined to a partitioned table. IN this case, user
--       should create INTERIM-TABLE on the kepy columns and pass to this API
procedure REDEFINE_TABLE(
  X_TABLE_OWNER        varchar2,
  X_TABLE_NAME         varchar2,
  X_INTERIM_TABLE_NAME varchar2)
is
  C_MODULE varchar2(200) := c_package||'redefine_table';
  L_REDEF_METHOD pls_integer;
  INVALID_TYPE_OF_REDEF_METHOD exception;
  pragma exception_init(INVALID_TYPE_OF_REDEF_METHOD, -42005);
begin
  log(c_module, 'PROCEDURE', 'begin:'|| x_table_owner || '.' || x_table_name);

  if(x_interim_table_name is not null and
         interim_table(x_table_name) <> upper(x_interim_table_name)) then
    error(c_module, 'ERROR: Invalid interim table name ''' ||
            x_interim_table_name || '''. Interim table name must be ' ||
            'original table name appended with ''$''. For example, ' ||
            'TEST_TAB would become TEST_TAB$.');
  else
    l_redef_method := get_redef_method(x_table_owner, x_table_name);
    begin
      dbms_redefinition.can_redef_table(x_table_owner, x_table_name, l_redef_method);
    exception
      when invalid_type_of_redef_method then
        log(c_module,'ERROR',
            'Table '||x_table_owner||'.'||X_table_name||
            ' cannot be redefined online with specified method');
        return;
    end;

    drop_interim_objects(x_table_owner, x_table_name, x_interim_table_name);

    -- If interim table is not given, create it
    if(x_interim_table_name is null) then
      create_interim_table(x_table_owner, x_table_name);
    end if;

    start_table_redef(x_table_owner, x_table_name, l_redef_method);
    copy_table_dependents(x_table_owner, x_table_name);

    -- copy_vpd policy

    ad_zd.load_ddl('FINALIZE',
                   'begin ad_zd_redefinition.finalize('||
                   ''''||x_table_owner||''','''||x_table_name||'''); end;');

    ad_zd.load_ddl('CUTOVER',
                   'begin ad_zd_redefinition.cutover('''||x_table_owner||''','''||x_table_name||'''); end;');

  end if;

  log(c_module, 'PROCEDURE', 'end');

exception
  when others then
    error(c_module,  'Error: '  || x_table_owner ||'.' || x_table_name || ' -> ' || substr(sqlerrm, 1, 2000));
    -- TODO: we can ABORT current redefinition and start fresh one.
    --       NOTE: If there is a in-progress table-redef then get_redef_method() itself fails.
end REDEFINE_TABLE;


-- This API might be called from adop - or from command-line also
--
-- E-biz tables:
--  1) Row chaining tables, with row chaining more than 20% --> ((chain_cnt/num_rows)*100 > 20)
--  2) High water mark tables with more than 20% empty blocks --> ((empty_blocks/blocks)*100 > 20)
--  3) Only consider the tables that have rows and allocated blocks and
--     only those tables with more than the initial extent size.
--
procedure REDEFINE_TABLES is
  C_MODULE varchar2(100) := c_package||'redefine_tables';
  L_BLOCK_SIZE number;
  L_DEGREE_OF_PARALLEL number;

  cursor C_REDEF_TABLES is
    select tab.owner table_owner,
           tab.table_name
    from dba_tables tab
    where tab.owner in (
            select oracle_username
            from ebs_system.fnd_oracle_userid
            where read_only_flag in ('A','B','E'))
     and exists (
           select null
           from dba_editioning_views ev
           where ev.owner= tab.owner
             and ev.table_name = tab.table_name)
     and not exists (
           select null
           from dba_tab_columns tabc
           where tabc.data_type in ('RAW','LONG RAW')
             and tabc.table_name = tab.table_name
             and tabc.owner = tab.owner )
     and tab.num_rows > 0
     and tab.blocks   > 0
     and ((tab.empty_blocks * l_block_size) > tab.initial_extent)
     and (
          ((tab.chain_cnt/tab.num_rows)*100 > 20) or
          ((tab.empty_blocks/tab.blocks)*100 > 20)
         )
     and tab.table_name not in
           ( 'AD_DEFERRED_JOBS',
             'AD_TABLE_INDEX_INFO',
             'FND_INSTALL_PROCESSES' )
   order by tab.owner, tab.table_name;

begin

  log(c_module, 'PROCEDURE', 'begin');

  select to_number(value) into l_block_size
  from gv$parameter
  where name = 'db_block_size';

  select MIN(to_number(value)) into l_degree_of_parallel
  from v$parameter
  where name='parallel_max_servers' or name = 'cpu_count';

  --exec('alter session force parallel dml parallel '|| l_degree_of_parallel , c_module, true, null);
  exec('alter session force parallel query parallel '|| l_degree_of_parallel , c_module, true);

  -- AD BUG 32837821 - SYS.%VIEWS OR TABLE QUERY CHANGES FOR AD_ZD_REDEFINITION
  -- Commented out the following code,as we cannot access sys.redef_dep_error$ in ADB instance
  -- clear any error before starting redefinition
  --  [grant DELETE on sys.redef_dep_error$ to apps]
  --delete from sys.redef_dep_error$;
  --commit;

  for l_tab in c_redef_tables loop
    -- Assume its a normal table, not a partioned table
    -- If redefining a partitioned table with the rowid method,
    --  then enable row movement on the interim table.
    --  ALTER TABLE ... ENABLE ROW MOVEMENT;

    -- AD BUG 32837821 - SYS.%VIEWS OR TABLE QUERY CHANGES FOR AD_ZD_REDEFINITION
    -- ST Bug 32519081 - ATPD MIGRATION: ADMIN DOES NOT HAVE GRANT PRIVS ON SYS.REDEF_DEP_ERROR$
    -- The dbms_redefinition.abort_redef_table procedure cleans up errors that occur
    -- during the redefinition process
    -- Invoke ad_zd_redefinition.abort which inturn invokes dbms_redefinition.abort_redef_table
    -- which "pops the stack" and allows you to start over.
    abort(l_tab.table_owner, l_tab.table_name);
    redefine_table(l_tab.table_owner, l_tab.table_name);
  end loop;
  log(c_module, 'PROCEDURE', 'end');

end REDEFINE_TABLES;



/*-----------------------------------------------------------------------------

                     PUBLIC APIs to gather table stats

-------------------------------------------------------------------------------*/

procedure COMPUTE_STATS(
  X_TABLE_OWNER varchar2,
  X_TABLE_NAME varchar2)
is
  C_MODULE varchar2(200) := c_package||'compute_stats';
  L_STMT varchar2(127);
begin

  log(c_module, 'PROCEDURE', 'begin:'|| x_table_owner || '.' || x_table_name);
  --TODO:
  -- 1- populate DDLs to execute them in-parallel
  -- 2- Compute stats on Indexes? (GB? )
  --
  -- SQL> analyze table sh_u1.SH_HWM_TEST_TAB compute statistics
  --        for table for all indexes for all indexed columns;
  --
  l_stmt := 'analyze table "'||x_table_owner||'"."'||x_table_name||'" compute statistics';
  exec(l_stmt, c_module, true);

  log(c_module, 'PROCEDURE', 'end');

end COMPUTE_STATS;

-- Picks up all the tables on which stats not gathered after:
--  -- 1) Ran finalize in full mode.  If this was never run, then use 12.2.0 upgrade time.
--  --    This is the "last_gather_stats_time".
--  -- 2) Gather stats for tables where dba_objects.last_ddl_time > last_gather_status_time.
--  -- 3) Customer can manually run gather status on any other tables they are concerned about
procedure COMPUTE_STATS_ALL
is
  C_MODULE varchar2(200) := c_package||'compute_stats_all';
  L_DEGREE_OF_PARALLEL number;
  L_EBS_122_APPLIED_DATE date;


  cursor C_TABLES is
    select tab.owner, tab.table_name
    from dba_tables tab,
         dba_objects obj
    where tab.owner in (
            select oracle_username
            from ebs_system.fnd_oracle_userid
            where read_only_flag in ('A','B','E'))
     and exists (
           select null
           from dba_editioning_views ev
           where ev.owner= tab.owner
             and ev.table_name = tab.table_name)
     and obj.owner = tab.owner
     and obj.object_name = tab.table_name
     -- Since [ finalize_mode=full ] is not being stored in adop* tables
     -- so using below criteria.
     and (obj.last_ddl_time > nvl(tab.last_analyzed, sysdate-365)
          or obj.last_ddl_time > l_ebs_122_applied_date)
     and not exists (
           select null
           from dba_tab_columns tabc
           where tabc.data_type in ('RAW','LONG RAW')
             and tabc.table_name = tab.table_name
             and tabc.owner = tab.owner )
     and tab.table_name not in
           ( 'AD_DEFERRED_JOBS',
             'AD_TABLE_INDEX_INFO',
             'FND_INSTALL_PROCESSES' )
   order by tab.owner, tab.table_name;

begin

  log(c_module, 'PROCEDURE', 'begin');

  select MIN(to_number(value)) into l_degree_of_parallel
  from v$parameter
  where name='parallel_max_servers' or name = 'cpu_count';

  select max(last_update_date) into l_ebs_122_applied_date
  from ad_applied_patches
  where patch_name ='10124646'; -- 12.2 Upgrade driver

  --exec('alter session force parallel dml parallel '|| l_degree_of_parallel , c_module, true, null);
  exec('alter session force parallel query parallel '|| l_degree_of_parallel , c_module, true);

  for l_rec in c_tables loop
    compute_stats(l_rec.owner, l_rec.table_name);
  end loop;

  log(c_module, 'PROCEDURE', 'end');

end COMPUTE_STATS_ALL;

end AD_ZD_REDEFINITION;
