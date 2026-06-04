
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_SEED" AUTHID CURRENT_USER AS
/* $Header: ADZDSMS.pls 120.12.12020000.8 2016/06/01 07:35:27 sstomar ship $ */

/* EDS Helper Functions */
function EDS_COLUMN return varchar2;
function EDS_TRIGGER(X_TABLE_NAME in varchar2) return varchar2;
function EDS_POLICY return varchar2;
function EDS_FUNCTION(X_TABLE_NAME in varchar2) return varchar2;
function EDS_FCET(X_TABLE_NAME in varchar2) return varchar2;
function EDS_BLOCK(X_TABLE_NAME in varchar2) return varchar2;

/* DB Preparation APIs */
procedure UPGRADE(
  X_TABLE_NAME   in  varchar2,
  X_MODE         in  varchar2 default 'CURRENT');

procedure DOWNGRADE(X_TABLE_NAME in varchar2);

/* Patch Event APIs */
procedure PATCH(X_TABLE_OWNER in varchar2, X_TABLE_NAME in varchar2);
procedure UPGRADE_POLICY(X_TABLE_OWNER in varchar2, X_TABLE_NAME in varchar2);
procedure PREPARE(X_TABLE_NAME in varchar2 );
procedure CUTOVER;
procedure CLEANUP(X_TABLE_NAME in varchar2 default NULL);
procedure ABORT;

procedure ABORT(X_TABLE_OWNER in varchar2, X_TABLE_NAME in varchar2);

/* Function changed - so place at bottom of spec file */
function IS_PREPARED(X_TABLE_NAME in varchar2) return boolean;

END AD_ZD_SEED;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_SEED" AS
/* $Header: ADZDSMB.pls 120.73.12020000.66 2023/03/30 14:06:57 jwsmith ship $ */


/*
** --------------------------------------------------------------------
**    Edition Data Storage - Public Helper Functions
** --------------------------------------------------------------------
*/

/* Editioned Data Storage Column Name */
function EDS_COLUMN return varchar2 is
begin
  return 'ZD_EDITION_NAME';
end;

/* Editioned Data Storage Maintenance Trigger Name */
function EDS_TRIGGER(X_TABLE_NAME in varchar2) return varchar2 is
begin
  return substr(upper(x_table_name), 1, 29)||'+';
end;

/* Editioned Data Storage VPD Function Name */
-- Note: function name must be un-quoted type due to bug in VPD
function EDS_FUNCTION(X_TABLE_NAME in varchar2) return varchar2 is
begin
  return substr(upper(x_table_name), 1, 29)||'=';
end;

/* Editioned Data Storage VPD Policy Name */
function EDS_POLICY return varchar2 is
begin
  return 'ZD_SEED';
end;

/* Editioned Data Storage Synchronization Trigger Name */
function EDS_FCET(X_TABLE_NAME in varchar2) return varchar2 is
begin
  return substr(upper(x_table_name), 1, 29)||'>';
end;

/* Editioned Data Incompatible update blocking Trigger Name */
function EDS_BLOCK(X_TABLE_NAME in varchar2) return varchar2 is
begin
  return substr(upper(x_table_name), 1, 29)||'<';
end;


/*
** --------------------------------------------------------------------
**    Internal
** --------------------------------------------------------------------
*/


-- log shortcut
procedure LOG(X_MODULE varchar2, X_LEVEL varchar2, X_MESSAGE varchar2) is
begin
  ad_zd.log(x_module, x_level, x_message);
end;

-- error shortcut
procedure ERROR(X_MODULE varchar2, X_MESSAGE varchar2) is
begin
  ad_zd.error(x_module, x_message);
end;

-- exec shortcut
procedure EXEC(X_SQL in varchar2, X_LOG_MOD in varchar2, X_IGNORE in boolean default false) is
begin
  ad_zd.exec(x_sql, x_log_mod, x_ignore);
end;

-- Get seed data table details from synonym, and validate along the way
procedure TRANSLATE_SYNONYM(
  X_MODULE       in  varchar2,
  X_SYNONYM_NAME in  varchar2,
  X_CHECK_SEED   in  boolean,
  X_TABLE_OWNER  out nocopy varchar2,
  X_TABLE_NAME   out nocopy varchar2)
is
  L_OWNER            varchar2(30);
  L_VIEW_NAME        varchar2(30);
  L_TABLE_NAME       varchar2(30);
begin
  -- Get EV Name
  begin
    select s.table_owner, s.table_name
    into   l_owner, l_view_name
    from   dba_synonyms s
    where  owner        = ad_zd.apps_schema
    and    synonym_name = x_synonym_name;
  exception when no_data_found then
    error(x_module, 'Synonym does not exist: '||nvl(x_synonym_name,'<null>'));
  end;

  -- Get Table Name
  begin
    l_table_name := ad_zd_table.ev_table(l_owner, l_view_name);
  exception when no_data_found then
    if x_check_seed then
      error(x_module, 'Synonym does not point to an editioning view: '||x_synonym_name);
    else
      l_table_name := l_view_name;
    end if;
  end;

  -- Validate that table suppports Editioned Data Storage
  if x_check_seed then
    if ad_zd_table.is_seed(l_owner, l_table_name) = 'N' then
      error(x_module, 'Synonym does not point to a seed data table: '||x_synonym_name);
    end if;
  end if;

  -- Return results
  x_table_owner := l_owner;
  x_table_name  := l_table_name;
end TRANSLATE_SYNONYM;


/*
** Aquire an exclusive lock on a Table
**   x_log_mod - calling module (for logging)
*/
procedure LOCK_TABLE(X_OWNER in varchar2, X_TABLE_NAME in varchar2, X_LOG_MOD in varchar2) is
begin
  exec('lock table "'||x_owner||'"."'||x_table_name||'" in exclusive mode', x_log_mod);
end LOCK_TABLE;

/*
** Get current rowset filter for table edition
**   X_EDITION_TYPE - 'RUN', 'PATCH', or NULL for current edition
**   null return means filter does not exist
*/
function GET_ROWSET_FILTER(X_TABLE_NAME in varchar2, X_EDITION_TYPE in varchar2) return varchar2
is
  C_MODULE        varchar2(80) := 'ad.plsql.ad_zd_seed.get_rowset_filter';
  L_EDITION       varchar2(30);
  L_ROWSET_FILTER varchar2(64) := null;
  L_CURSOR_ID     integer;
  L_TEMP          integer;
  TYPE L_CUR_TYPE IS REF CURSOR;
  L_CUR           l_cur_type;
begin

  l_edition := ad_zd.get_edition(x_edition_type);

  if l_edition is null then
    return null;
  end if;

  -- Execute EDS filter function in Run Edition
  l_cursor_id := dbms_sql.open_cursor;
  dbms_sql.parse(c             => l_cursor_id,
                 statement     => 'select "'||eds_function(x_table_name)||'"(null,null) from dual',
                 language_flag => dbms_sql.native,
                 edition       => l_edition);
  l_temp := dbms_sql.execute(l_cursor_id);
  l_cur  := dbms_sql.to_refcursor(l_cursor_id);

  fetch l_cur into l_rowset_filter;
  if (dbms_sql.is_open(l_cursor_id) ) then
    dbms_sql.close_cursor(l_cursor_id);
  end if;

  --log(c_module, 'STATEMENT', x_edition_type||' rowset filter for table '||x_table_name||' is: '||l_rowset_filter);
  return l_rowset_filter;

exception
  when others then
    if(dbms_sql.is_open(l_cursor_id) ) then
      dbms_sql.close_cursor(l_cursor_id);
    end if;
    return null;
end GET_ROWSET_FILTER;

/*
** Get current rowset for table edition
**   X_EDITION_TYPE - 'RUN', 'PATCH', or NULL for current edition
*/
function GET_ROWSET(X_TABLE_NAME in varchar2, X_EDITION_TYPE in varchar2) return varchar2
is
  L_ROWSET_FILTER   varchar2(127);
begin
  l_rowset_filter := get_rowset_filter(x_table_name, x_edition_type);
  if (l_rowset_filter is null) then
    return null;
  end if;

  return replace(trim(substr(l_rowset_filter,
                             instr(l_rowset_filter, '=', 1)+1,
                             length(l_rowset_filter))),
                 '''', '');
end GET_ROWSET;

/*
** Compute the rowset to use for prepare or upgrade of seed table
** Note: can be called in run edition during seed table upgrade, but this
**       works and returns 'SET1'
*/
function COMPUTE_PATCH_ROWSET(X_TABLE_NAME in varchar2) return varchar2
is
  C_MODULE       varchar2(80) :=  'ad.plsql.ad_zd_seed.compute_patch_rowset';
  L_RUN_ROWSET   varchar2(30);
  L_PATCH_ROWSET varchar2(30);
begin
  l_run_rowset   := get_rowset(x_table_name, 'RUN');
  l_patch_rowset := get_rowset(x_table_name, 'PATCH');

  -- if patch rowset was already set, then this is the answer
  if (l_patch_rowset is not null and
      (l_run_rowset is null or l_run_rowset <> l_patch_rowset)) then
    log(c_module, 'STATEMENT', 'Existing patch rowset for table '||x_table_name||' is: '||l_patch_rowset);
    return l_patch_rowset;
  end if;

  -- compute new rowset
  if (l_run_rowset is null  or l_run_rowset <> 'SET1') then
    -- upgrading from old style or SET2 -> SET1
    l_patch_rowset := 'SET1';
  else
    -- SET1 -> SET2
    l_patch_rowset := 'SET2';
  end if;

  log(c_module, 'STATEMENT', 'Computed patch rowset for table '||x_table_name||' is: '||l_patch_rowset);
  return l_patch_rowset;
end COMPUTE_PATCH_ROWSET;

/*
** Check if rows in a rowset exist ('Y'|'N')
**   Note: this does not mean the rowset is valid
*/
function ROWSET_EXISTS(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2,
  X_ROWSET      in varchar2) return varchar2
is
  L_EXIST     varchar2(1) :='N';
  L_QUERY_STR varchar2(1000);
begin
  l_query_str := 'select ''Y'' from dual where exists (select /*+ FIRST_ROWS */ null from '
                 ||x_table_owner||'.'||x_table_name||' where zd_edition_name='''||x_rowset||''')';

  execute immediate l_query_str into l_exist;
  return l_exist;
exception
  when others then
    return l_exist;
end ROWSET_EXISTS;


/*
** Set rowset_status
**   Note: this flag is stored as a comment on the ZD_SYNC column
*/
procedure SET_ROWSET_STATUS(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2,
  X_STATUS      in varchar2)
is
  C_MODULE       varchar2(80)  := 'ad.plsql.ad_zd_seed.set_rowset_status';
  L_STMT         varchar2(1000);
begin
  log(c_module, 'STATEMENT',
      'Setting rowset status for '||x_table_owner||'.'||x_table_name||' to '||x_status);
  l_stmt := 'comment on column '||x_table_owner||'.'||x_table_name||'.ZD_SYNC'||
      ' is '''||x_status||'''';
  exec(l_stmt, c_module);
end SET_ROWSET_STATUS;

/*
** Get rowset_status
**   Note: this flag is stored as a comment on the ZD_SYNC column
**         no comment or unexpected comment is assumed to be VALID
*/
function GET_ROWSET_STATUS(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2) return varchar2
is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd_seed.get_rowset_status';
  L_STATUS       varchar2(4000) := null;
begin
  begin
    select comments into l_status from dba_col_comments
    where owner=x_table_owner and table_name=x_table_name and column_name='ZD_SYNC';
  exception
    when no_data_found then null;
  end;

  -- missing or unexecpect comment is upgrade case, assume VALID
  if l_status is null or l_status not in ('VALID','INVALID') then
    return 'UNSET';
  end if;

  return l_status;
end GET_ROWSET_STATUS;


/*
** Check if table is prepared
**   Note: this test is only sensible if called from the patch edition
*/
function IS_PREPARED(X_TABLE_NAME in varchar2) return boolean
is
  C_MODULE       varchar2(80)  := 'ad.plsql.ad_zd_seed.is_prepared';
  L_GUARD        varchar2(30);
  L_DESC         varchar2(4000);
  L_EDITION      varchar2(30);
  L_RUN_ROWSET   varchar2(30);
  L_PATCH_ROWSET varchar2(30);
begin
  l_guard := eds_trigger(x_table_name);

  begin
    select description into l_desc
    from dba_triggers
    where owner = ad_zd.apps_schema
      and trigger_name = l_guard;
  exception
    when no_data_found then
      return false;
  end;

  l_edition := substr(l_desc, instr(l_desc,'[')+1, instr(l_desc,']')-instr(l_desc,'[')-1);

  -- if no tag, this is an old-style guard trigger, use old-style logic
  if l_edition is null then
    l_run_rowset   := get_rowset(x_table_name, 'RUN');
    l_patch_rowset := get_rowset(x_table_name, 'PATCH');

    if (l_patch_rowset is null) then
      return false;
    end if;

    return (l_run_rowset is null or l_run_rowset <> l_patch_rowset);
  end if;

  return l_edition = ad_zd.get_edition;
end IS_PREPARED;


/*
** Acquire an exclusive lock on a procedure entry
**   x_lock_name - lock name
**
** Note: lock will be released if session dies, so should be safe for crash scenario
*/
function ACQUIRE_LOCK(X_LOCK_NAME in varchar2) return varchar2
is
  C_MODULE       varchar2(80)  := 'ad.plsql.ad_zd_seed.acquire_lock';
  L_LOCK_NAME    varchar2(128) := upper(x_lock_name);
  L_LOCK_HANDLE  varchar2(128) := null;
  L_LOCK_STATUS  integer;
begin
  dbms_lock.allocate_unique(lockname => l_lock_name, lockhandle => l_lock_handle);
  l_lock_status := dbms_lock.request(lockhandle        => l_lock_handle,
                                     lockmode          => dbms_lock.x_mode,
                                     timeout           => dbms_lock.maxwait,
                                     release_on_commit => false);

  if (l_lock_status <> 0) then
    error(c_module, 'Unable to acquire lock: '||x_lock_name||
                    ' lock_handle: '||l_lock_handle||' lock_status: '||l_lock_status);
  end if;

  log(c_module, 'STATEMENT', 'Lock acquired: '||x_lock_name||' -> '||l_lock_handle);
  return l_lock_handle;
end ACQUIRE_LOCK;


/*
** Release the exclusive lock on a procedure exit
**   x_lock_handle - lock handle
*/
procedure RELEASE_LOCK(X_LOCK_HANDLE in varchar2)
is
  C_MODULE       varchar2(80)  := 'ad.plsql.ad_zd_seed.release_lock';
  L_LOCK_STATUS  integer;
begin
  if x_lock_handle is null then
    return;
  end if;

  l_lock_status := dbms_lock.release(x_lock_handle);
  if l_lock_status <> 0 then
    error(c_module, 'Unable to release lock: '||x_lock_handle||' lock_status: '||l_lock_status);
  end if;

  log(c_module, 'STATEMENT', 'Lock released: '||x_lock_handle);
end RELEASE_LOCK;

/*
** Choose a parallel_level that is the least of the three limiting factors:
** 1) job_queue_processes/2: half of the available parallel workers for the DB, no less than 2.
** 2) parallel level cap: set at 8 (some systems have very high job_queue_processes capacity).
** 3) chunk count: Do not request more workers than there are chunks of work to be done.
*/

function CALCULATE_PARALLEL_LEVEL(X_CHUNK_COUNT in number) return number
is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd_seed.calculate_parallel_level';
  L_JOB_QUEUE_PROCESSES number;
  L_PARALLEL_CAP number := 8; -- max useful parallel_level for simple DML
  L_PARALLEL_LEVEL number;
begin
   select to_number(value) into l_job_queue_processes
       from v$parameter where name = 'job_queue_processes';
   l_parallel_level := least(greatest(round(l_job_queue_processes/2),2), l_parallel_cap, x_chunk_count);
   log(c_module, 'STATEMENT', 'Calculated parallel_level= '||l_parallel_level);
   return l_parallel_level;
end;

-- New procedure to run DBMS_PARALLEL as we have this code duplicated.
-- jwsmith, Bug 30548993 - SEED MANAGER - REWRITE AND TUNE DELETE STATEMENTS, SYNCHRONIZE_ROWSET
/*
** RUN_IN_PARALLEL
*/
procedure RUN_IN_PARALLEL(
  X_SQL_STMT         in varchar2,
  X_TASK_NAME        in varchar2,
  X_TABLE_OWNER      in varchar2,
  X_TABLE_NAME       in varchar2,
  X_FCET_NAME        in varchar2 default NULL)
is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd_seed.run_in_parallel';
  L_SQL_STMT     varchar2(32767);
  L_ERROR        varchar2(32767);
  L_STATUS       number;
  L_CHUNK_COUNT  number;
  L_PARALLEL_LEVEL number;

  DUPLICATE_TASK_ERROR exception;
    pragma exception_init(duplicate_task_error, -29497);

begin
  -- create task, handle possible conflicting task
  begin
    log(c_module, 'STATEMENT', '['||x_task_name||'] Create Task, SQL: '||x_sql_stmt);
    dbms_parallel_execute.create_task(x_task_name);
  exception
    when duplicate_task_error then
      log(c_module, 'STATEMENT', '['||x_task_name||'] Drop duplicate task');
      dbms_parallel_execute.drop_task(x_task_name);
      log(c_module, 'STATEMENT', '['||x_task_name||'] Create Task (retry)');
      dbms_parallel_execute.create_task(x_task_name);
  end;

  -- create task chunks
  dbms_parallel_execute.create_chunks_by_rowid(
      x_task_name, x_table_owner, x_table_name, true, 10000);

  select count(chunk_id) into l_chunk_count
  from user_parallel_execute_chunks
  where task_name = x_task_name;

  -- if no chunks, then table was empty
  if (l_chunk_count = 0) then
    log(c_module, 'STATEMENT', '['||x_task_name||'] Table was empty, dropping task');
    dbms_parallel_execute.drop_task(x_task_name);
    return;
  end if;

  -- get parallel_level
  l_parallel_level := calculate_parallel_level(l_chunk_count);

  -- run task
  if x_fcet_name is not null then
    log(c_module, 'STATEMENT', '['||x_task_name||'] Executing Task to apply '||x_fcet_name||', chunks: '||to_char(l_chunk_count));
    dbms_parallel_execute.run_task(
        x_task_name, x_sql_stmt, dbms_sql.native,
        apply_crossedition_trigger=>'"'||x_fcet_name||'"',
        parallel_level=>l_parallel_level);
  else
    log(c_module, 'STATEMENT', '['||x_task_name||'] Executing Task, chunks: '||to_char(l_chunk_count));
    dbms_parallel_execute.run_task(
        x_task_name, x_sql_stmt, dbms_sql.native,
        parallel_level=>l_parallel_level);
  end if;
  l_status := dbms_parallel_execute.task_status(x_task_name);

  -- confirm task has finished, retry if needed
  if (l_status = dbms_parallel_execute.chunked) then
    -- Task did not execute, possible syntax error
    log(c_module, 'ERROR', '['||x_task_name||'] Task did not execute, internal error');
  elsif (l_status <> dbms_parallel_execute.finished) then
    -- Task did not finish, retry
    log(c_module, 'WARNING',
        '['||x_task_name||'] Task did not finish, status='||to_char(l_status)||', retrying...');
      dbms_parallel_execute.resume_task(x_task_name);
      l_status := dbms_parallel_execute.task_status(x_task_name);
  end if;

  if (l_status <> dbms_parallel_execute.finished) then
    begin
      select error_code||': '||error_message into l_error
      from dba_parallel_execute_chunks
      where task_name = x_task_name
        and error_message is not null
        and rownum < 2;
    exception
      when no_data_found then
        l_error := '[no error_message found]';
    end;
    error(c_module, '['||x_task_name||'] Task failed, status='||to_char(l_status)||', '||l_error);
  end if;

  log(c_module, 'STATEMENT', '['||x_task_name||'] Task successful, dropping task');
  dbms_parallel_execute.drop_task(x_task_name);
end RUN_IN_PARALLEL;

/*
** Fetch Multiple DDLs
**   x_table_owner  - base table owner
**   x_table_name   - base table name
**   x_object_type  - object type (index | constraint)
**   x_object_owner - index / constraint owner
**   x_object_name  - index / constraint name
*/
function FETCH_MULTIPLE_DDLS(
  X_TABLE_OWNER  in varchar2,
  X_TABLE_NAME   in varchar2,
  X_OBJECT_TYPE  in varchar2,
  X_OBJECT_OWNER in varchar2,
  X_OBJECT_NAME  in varchar2) return SYS.KU$_DDLS
is
   C_MODULE             varchar2(80) := 'ad.plsql.ad_zd_seed.fetch_multiple_ddls';
   L_OPEN_HANDLE        number;
   L_TRANSFORM_HANDLE   number;
   L_DDL_STMTS          sys.ku$_ddls;
begin
  log(c_module, 'STATEMENT',
      'Getting DDLs for '||x_table_owner||'.'||x_table_name||', '||
      x_object_type||', '||x_object_owner||'.'||x_object_name);

  l_open_handle := dbms_metadata.open(x_object_type);
  dbms_metadata.set_filter(l_open_handle, 'SCHEMA', x_object_owner);
  dbms_metadata.set_filter(l_open_handle, 'NAME', x_object_name);
  l_transform_handle := dbms_metadata.add_transform(l_open_handle, 'DDL');
  dbms_metadata.set_transform_param(l_transform_handle, 'SQLTERMINATOR', false);
  l_ddl_stmts := dbms_metadata.fetch_ddl(l_open_handle);
  dbms_metadata.close(l_open_handle);

  return l_ddl_stmts;
end FETCH_MULTIPLE_DDLS;


/*
** Create ZD striping column on seed data table
*/
procedure CREATE_ZD_COLUMN(
  X_OWNER         in varchar2,
  X_TABLE_NAME    in varchar2,
  X_EDITION_NAME  in varchar2)
is
  C_MODULE  varchar2(80) :=  'ad.plsql.ad_zd_seed.create_zd_column';
  L_STMT    varchar2(2000);
begin
  if ad_zd_table.is_seed(x_owner, x_table_name) = 'N' then
    log(c_module, 'STATEMENT', 'Creating EDS Striping Column on '||x_owner||'.'||x_table_name);
    l_stmt := 'alter table '||x_owner||'."'||x_table_name||
              '" add (ZD_EDITION_NAME varchar2(30) default '''||x_edition_name||''' not null)';
  else
    log(c_module, 'STATEMENT', 'Updating existing EDS Striping Column on '||x_owner||'.'||x_table_name);
    l_stmt := 'update '||x_owner||'."'||x_table_name||'"'||
              '  set ZD_EDITION_NAME = '''||x_edition_name||''''||
              '  where ZD_EDITION_NAME != '''||x_edition_name||'''';
  end if;
  exec(l_stmt, c_module);
end CREATE_ZD_COLUMN;

/*
** Create ZD_sync column on seed data table
*/
procedure CREATE_SYNC_COLUMN(
  X_OWNER         in varchar2,
  X_TABLE_NAME    in varchar2)
is
  C_MODULE  varchar2(80) :=  'ad.plsql.ad_zd_seed.create_sync_column';
  L_STMT    varchar2(2000);
  L_EXIST   pls_integer :=0;
begin
  if (ad_zd_table.is_seed(x_owner, x_table_name) = 'Y') then
    -- Check if column already not present
    begin
      select 1 into l_exist from dual
      where exists (select null from dba_tab_columns
                    where owner       = x_owner
                      and table_name  = x_table_name
                      and column_name = 'ZD_SYNC');
   exception
     when no_data_found then
        log(c_module, 'STATEMENT', 'Creating SYNC Column on '||x_owner||'.'||x_table_name);
        l_stmt := 'alter table '||x_owner||'."'||x_table_name||
                  '" add (ZD_SYNC varchar2(30) default ''SYNCED'' not null)';
        exec(l_stmt, c_module);
        ad_zd_table.patch(x_owner,x_table_name);
    end;
  end if;
end CREATE_SYNC_COLUMN;


/*
** Fix unique indexes on seed data table
**
** Add ZD_EDITION_NAME as a leading column on all
** unique Indexes
*/
procedure FIX_INDEXES(X_TABLE_OWNER in varchar2, X_TABLE_NAME in varchar2)
is
  C_MODULE            varchar2(80) := 'ad.plsql.ad_zd_seed.fix_indexes';
  L_IND_OWNER         varchar2(30);
  L_IND_NAME          varchar2(30);
  L_CONSTRAINT_NAME   varchar2(30);
  L_CONSTRAINT_TYPE   varchar2(30);
  L_DDL_STMTS         sys.ku$_ddls;
  L_DDL_STMTS2        sys.ku$_ddls;
  L_DDL_STMT          varchar2(32767);
  L_ORIG_CONS_COLUMNS varchar2(4000);
  L_NEW_CONS_COLUMNS  varchar2(4000);
  L_ORIG_IND_COLUMNS  varchar2(4000);
  L_NEW_IND_COLUMNS   varchar2(4000);
  L_VERSION           varchar2(255);
  L_COMPATIBILITY     varchar2(255);

  cursor C_IND_CUR (x_tab_owner varchar2, x_tab_name varchar2) is
    select i.owner, i.index_name
    from   dba_indexes i
    where  i.table_owner = x_tab_owner
    and    i.table_name  = x_tab_name
    and    i.uniqueness  = 'UNIQUE'
    and    i.index_type  <> 'LOB'
    and    not exists  ( select null
                         from   dba_ind_columns c
                         where  c.index_owner = i.owner
                         and    c.index_name  = i.index_name
                         and    c.column_name = 'ZD_EDITION_NAME' );

  cursor C_CONSTRAINT_CUR (x_tab_owner varchar2, x_tab_name varchar2) is
    select constraint_name, constraint_type, index_owner, index_name
    from dba_constraints o
    where owner           = x_tab_owner
    and   table_name      = x_tab_name
    and   constraint_type in ('U','P')
    and   not exists  ( select null
                        from   dba_cons_columns i
                        where  i.owner = o.owner
                        and    i.constraint_name  = o.constraint_name
                        and    i.column_name = 'ZD_EDITION_NAME' );

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  dbms_utility.db_version( l_version, l_compatibility );

  open  c_constraint_cur(x_table_owner,x_table_name);
  fetch c_constraint_cur INTO l_constraint_name, l_constraint_type, l_ind_owner, l_ind_name;
  while (c_constraint_cur%found) loop
    log(c_module, 'STATEMENT', 'Adding EDS Striping Column to constraint '||l_constraint_name);
    lock_table(x_table_owner,x_table_name,c_module);

    l_ddl_stmts := fetch_multiple_ddls(x_table_owner, x_table_name, 'CONSTRAINT', x_table_owner, l_constraint_name);

    -- Assuming index would be UNIQUE
    if(l_ind_name is not null) then
      l_ddl_stmts2 := fetch_multiple_ddls(x_table_owner, x_table_name, 'INDEX', l_ind_owner, l_ind_name);
    end if;

     -- Constraint columns
    select listagg('"'||column_name||'"', ', ') within group (order by  position)
           into l_orig_cons_columns
    from dba_cons_columns
    where owner=x_table_owner
    and   table_name=x_table_name
    and   constraint_name=l_constraint_name;

    if(l_orig_cons_columns is not null) then
      l_new_cons_columns  := '('||l_orig_cons_columns||', "ZD_EDITION_NAME")';
      l_orig_cons_columns := '('||l_orig_cons_columns||')';
    end if;

    log(c_module, 'STATEMENT', 'Original constraint columns {'||l_orig_cons_columns||'}' );

    -- Index columns (created for above constaint)
    select listagg('"'||column_name||'"', ', ') within group (order by  column_position)
           into l_orig_ind_columns
    from dba_ind_columns
    where table_owner=x_table_owner
    and   table_name=x_table_name
    and   index_owner=l_ind_owner
    and   index_name=l_ind_name;

    if(l_orig_ind_columns is not null) then
      l_new_ind_columns   := '('||l_orig_ind_columns||', "ZD_EDITION_NAME")';
      l_orig_ind_columns  := '('||l_orig_ind_columns||')';
    end if;

    log(c_module, 'STATEMENT', 'Original index columns {'||l_orig_ind_columns||'}' );

    if l_constraint_type = 'U' then
      l_ddl_stmt := 'alter table "'||x_table_owner||'"."'||x_table_name||'" drop constraint '||l_constraint_name||' drop index';
    else
      l_ddl_stmt := 'alter table "'||x_table_owner||'"."'||x_table_name||'" drop constraint '||l_constraint_name||' cascade drop index';
    end if;
    exec(l_ddl_stmt, c_module);


    -- DBMS_METADATA API in 12.1.x DB versions, returns seperate DDLs for
    -- constraints, using indexes but not in prioer versions.
    if(l_version not like '12.%' and l_ind_name is not null) then
      for i in 1 .. l_ddl_stmts2.count loop
        l_ddl_stmt := dbms_lob.substr(l_ddl_stmts2(i).ddltext);
        l_ddl_stmt := replace(l_ddl_stmt, l_orig_cons_columns, l_new_cons_columns);
        l_ddl_stmt := replace(l_ddl_stmt, l_orig_ind_columns, l_new_ind_columns);
        exec(l_ddl_stmt, c_module);
      end loop;
    end if;

    for i in 1 .. l_ddl_stmts.count loop
      l_ddl_stmt := dbms_lob.substr(l_ddl_stmts(i).ddltext);

      if i=1 then
        --l_ddl_stmt := regexp_replace(l_ddl_stmt,'\)',',"ZD_EDITION_NAME")', 1, 1);
        if(l_new_cons_columns is not null) then
          l_ddl_stmt := replace(l_ddl_stmt, l_orig_cons_columns, l_new_cons_columns);
        end if;
        if(l_new_ind_columns is not null) then
          l_ddl_stmt := replace(l_ddl_stmt, l_orig_ind_columns, l_new_ind_columns);
        end if;
      end if;
      exec(l_ddl_stmt, c_module);
    end loop;

    fetch c_constraint_cur INTO l_constraint_name, l_constraint_type, l_ind_owner, l_ind_name;
  end loop;
  close c_constraint_cur;

  open  c_ind_cur(x_table_owner,x_table_name);
  fetch c_ind_cur INTO l_ind_owner, l_ind_name;
  while (c_ind_cur%found) loop
    log(c_module, 'STATEMENT', 'Adding EDS Striping Column to index '||l_ind_owner||'.'||l_ind_name);
    lock_table(x_table_owner,x_table_name,c_module);
    l_ddl_stmts := fetch_multiple_ddls(x_table_owner, x_table_name, 'INDEX', l_ind_owner, l_ind_name);

    l_ddl_stmt := 'drop index "'||l_ind_owner||'"."'||l_ind_name||'"';
    exec(l_ddl_stmt,c_module);

    for i in 1 .. l_ddl_stmts.count loop
      l_ddl_stmt := dbms_lob.substr(l_ddl_stmts(i).ddltext);
      if i=1 then
        l_ddl_stmt := regexp_replace(l_ddl_stmt, '\)\s*([^,)])', ',"ZD_EDITION_NAME") \1', 1, 1);
      end if;
      exec(l_ddl_stmt, c_module);
    end loop;

    fetch c_ind_cur INTO l_ind_owner, l_ind_name;
  end loop;
  close c_ind_cur;

  log(c_module, 'PROCEDURE', 'end');
end FIX_INDEXES;


/*
** Cleanup seed table (internal) - removes old and invalid rowsets
*/
procedure CLEANUP_TABLE(X_TABLE_OWNER in varchar2, X_TABLE_NAME in varchar2) is
  C_MODULE        varchar2(80) := 'ad.plsql.ad_zd_seed.cleanup_table';
  L_RUN_FILTER    varchar2(80);    /* run edition seed data filter */
  L_ROWSET_STATUS varchar2(30);
  L_STMT          varchar2(1000);
begin
  -- Get current rowset info
  l_run_filter := get_rowset_filter(x_table_name, 'RUN');
  l_rowset_status := get_rowset_status(x_table_owner, x_table_name);

  if l_rowset_status = 'INVALID' then
    -- delete all but run rowset
    l_stmt := 'delete /* +rowid(tbl) */ from "'||x_table_owner||'"."'||x_table_name||'" tbl '||
                'where not ('||l_run_filter||') '||
                ' and rowid between :start_id and :end_id ';
  else
    -- delete all but run and patch rowsets
    l_stmt := 'delete /* +rowid(tbl) */ from "'||x_table_owner||'"."'||x_table_name||'" tbl '||
                'where not ('||l_run_filter||') and (zd_edition_name not in (''SET1'', ''SET2'')) '||
                ' and rowid between :start_id and :end_id ';
  end if;

  log(c_module, 'EVENT', 'Cleanup Seed Data Table: '||x_table_owner||'.'||x_table_name||', run rowset filter: '||l_run_filter);
  begin
    run_in_parallel(l_stmt, x_table_name||'|CLEANUP_ROWSET', x_table_owner, x_table_name);
  exception when others then
    error(c_module, 'Could not cleanup seed data table: '||x_table_owner||'.'||x_table_name||
                    ', CODE: '||sqlcode||', MESSAGE: "'||sqlerrm||'"');
  end;
end CLEANUP_TABLE;


/*
** Synchronize changes in run rowset to patch rowset
*/
procedure SYNCHRONIZE_ROWSET(
  X_TABLE_OWNER      in varchar2,
  X_TABLE_NAME       in varchar2,
  X_PATCH_ROWSET     in varchar2,
  X_RUN_ROWSET       in varchar2,
  X_SYNC_KEY_STMT    in varchar2)
is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd_seed.synchronize_rowset';
  L_TRIGGER_NAME varchar2(30) := ad_zd_seed.eds_fcet(x_table_name);
  L_SQL_STMT     varchar2(32767);

  -- jwsmith, bug 31071837 - This task name MUST be unique to run in parallel

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  -- Bug 30548993 - Performance fix for large seed tables, combine the two deletes
  -- and add rowid hint and rowid line to where clause for running in parallel.
  -- Delete extra rows from patch rowset AND
  -- For Bug#24396562:R12.AD.C(DUAL-ROW SET: WHEN PATCH CHANGES KEY-COLUMN-VALUES, SYNCHRONIZATION FAILS)
  -- Delete unsynchronized rows from patch rowset
  log(c_module, 'STATEMENT', 'Delete extra rows from patch rowset');
  l_sql_stmt := 'delete /*+rowid(s1)*/ from "'||x_table_owner||'"."'||x_table_name||'" s1 '||
                'where s1.zd_edition_name='''||x_patch_rowset||''''||
                ' and rowid between :start_id and :end_id ' ||
                ' and (not exists (select null from '||
                                   '"'||x_table_owner||'"."'||x_table_name||'" s2 '||
                                   'where s2.zd_edition_name='''||x_run_rowset||''''||
                                   '  and '||x_sync_key_stmt||') '||
                 ' OR exists (select null from '||
                                   '"'||x_table_owner||'"."'||x_table_name||'" s2 '||
                                   'where s2.zd_edition_name='''||x_run_rowset||''''||
                                   '  and '||x_sync_key_stmt||
                                   '  and s2.zd_sync <> ''SYNCED''))';
  run_in_parallel(l_sql_stmt, x_table_name||'|DELETE_EXTRA_ROWS', x_table_owner, x_table_name);

  -- Execute synchronization trigger for unsynchronized rows in run rowset
  log(c_module, 'STATEMENT', 'Synchronize patch rowset');
  l_sql_stmt := 'update /*+ rowid (tbl) */ '||x_table_owner||'.'||x_table_name||' tbl '||
                '  set zd_sync=zd_sync '||
                'where zd_sync <> ''SYNCED'' '||
                '  and zd_edition_name='''||x_run_rowset||''''||
                '  and rowid between :start_id and :end_id';
  run_in_parallel(l_sql_stmt, x_table_name||'|SYNCHRONIZE_ROWSET', x_table_owner, x_table_name, l_trigger_name);

  log(c_module, 'PROCEDURE', 'end');
end SYNCHRONIZE_ROWSET;


/*
** Create Guard Trigger to populate ZD_EDITION_NAME/ZD_SYNC column on specified table
**
** The guard trigger is responsibile for
**     1) populating the ZD_EDITION_NAME column with rowset tag on INSERT
**     2) recording changes to the rowset by setting ZD_SYNC flag to INSERTED/UPDATED
**     3) preventing writes to the patch rowset until table is prepared for the patch edition
** The sync trigger is responsibile for setting ZD_SYNC flag back to SYNCED when a change
** is synchronized from run rowset to patch rowset.
**
** Note: Guard Trigger is created with comment tag "[X_EDITION_NAME]", which is checked
**       by IS_PREPARED function to verify that table is prepared for patching.
*/
procedure CREATE_GUARD(
  X_TABLE_OWNER    in  varchar2,
  X_TABLE_NAME     in  varchar2,
  X_EDITION_NAME   in  varchar2,
  X_ROWSET         in  varchar2)
is
  C_MODULE            varchar2(80) := 'ad.plsql.ad_zd_seed.create_guard';
  L_EV_NAME           varchar2(30) := substrb(x_table_name,1,29)||'#'; /*ad_zd_table.ev_view*/
  L_TRIG_NAME         varchar2(30) := ad_zd_seed.eds_trigger(x_table_name);
  L_TRIG_BODY         varchar2(32000);
  L_TRIG_STMT         varchar2(32000);
  NL               varchar(1) := '
';

begin

  -- Generate new trigger body
  l_trig_body :=
      NL||' declare'||
      NL||'   l_current varchar2(30) := sys_context(''userenv'', ''current_edition_name'');'||
      NL||'   l_default varchar2(30) := ad_zd.get_run_edition;'||
      NL||' begin '||
      NL||'   if l_current > l_default and l_current != '''||x_edition_name||''' then'||
      NL||'     raise_application_error(-20002,''Seed Data Table '||x_table_name||' has not been prepared for patching'');'||
      NL||'   end if;'||
      NL||'   if INSERTING then '||
      NL||'     :new.zd_edition_name := '''||x_rowset||''';'||
      NL||'     :new.zd_sync := ''INSERTED'';'||
      NL||'   end if;'||
      NL||'   if UPDATING then '||
      NL||'     if :new.zd_sync <> ''INSERTED'' then '||
      NL||'       :new.zd_sync := ''UPDATED'';'||
      NL||'     end if;'||
      NL||'   end if;'||
      NL||' end;';

  -- Create trigger statement with [edition_tag]
  log(c_module, 'STATEMENT', 'Creating EDS Guard Trigger '||l_trig_name);
  l_trig_stmt := ' create or replace trigger "'||ad_zd.apps_schema||'"."'||l_trig_name||'"'||
                 ' /*['||x_edition_name||']*/ '||
                 ' before insert or update or delete on "'||x_table_owner||'"."'||l_ev_name||'"'||
                 ' for each row '||l_trig_body;
  exec(l_trig_stmt, c_module);

end CREATE_GUARD;


/*
** Create VPD Policy and policy function
**
** Every seed data table will have a VPD Policy on it's EV
** The policy filters the correct seed data rowset for the
** current database edition by returning:
**
**     ZD_EDITION_NAME = '<ROWSET_TAG>'
**
*/
procedure CREATE_POLICY(
  X_OWNER        in varchar2,
  X_TABLE_NAME   in varchar2,
  X_EDITION_NAME in varchar2,
  X_ROWSET       in varchar2)
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_seed.create_policy';
  L_CUR             integer;
  L_POLICY_NAME     varchar2(30) := ad_zd_seed.eds_policy;
  L_EV_NAME         varchar2(30) := substrb(x_table_name,1,29)||'#'; /*ad_zd_table.ev_view*/
  L_POLICY_FUNC     varchar2(30) := ad_zd_seed.eds_function(x_table_name);
  L_STMT            varchar2(1000);
  L_TEXT            varchar2(4000);
  POLICY_NOT_FOUND EXCEPTION;
  PRAGMA EXCEPTION_INIT(POLICY_NOT_FOUND, -28102);

  -- Bug 25469830 jwsmith, added chk_option='YES'
  cursor C_POLICY_CUR (x_ev_owner varchar2, x_ev_name varchar2) is
    select policy_name
    from   dba_policies
    where  object_owner = x_ev_owner
    and    object_name  = x_ev_name
    and    policy_name  = ad_zd_seed.eds_policy
    and    sel='YES'
    and    ins='YES'
    and    upd='YES'
    and    del='YES'
    and    idx='YES'
    and    chk_option = 'YES';

begin

  -- Install VPD Policy Function
  log(c_module, 'STATEMENT', 'Creating EDS Filter Function '||l_policy_func);
  l_stmt :=
      'create or replace function '||
      '"'||ad_zd.apps_schema||'"."'||l_policy_func||'"(x_schema in varchar2, x_table in varchar2) '||
      'return varchar2 is '||
      'begin return ''ZD_EDITION_NAME = '''''||x_rowset||'''''''; end;';
  exec(l_stmt, c_module);

  -- Add VPD Policy to EV if missing
  -- Correct VPD policy if not defined correctly
  open  c_policy_cur (x_owner, l_ev_name);
  fetch c_policy_cur INTO l_policy_name;
  if (c_policy_cur%notfound) then
    begin
      dbms_rls.drop_policy(
        object_schema  =>  x_owner,
        object_name    =>  l_ev_name,
        policy_name    =>  l_policy_name);
      log(c_module, 'STATEMENT', 'Recreating EDS Filter Policy '||x_owner||'.'||l_ev_name||', '||l_policy_name);
    exception when policy_not_found then
      log(c_module, 'STATEMENT', 'Creating EDS Filter Policy '||x_owner||'.'||l_ev_name||', '||l_policy_name);
    end;

    -- Bug 25469830 jwsmith, added update_check TRUE
    dbms_rls.add_policy(
      object_schema    =>  x_owner,
      object_name      =>  l_ev_name,
      policy_name      =>  l_policy_name,
      function_schema  =>  ad_zd.apps_schema,
      policy_function  =>  '"'||l_policy_func||'"',
      policy_type      =>  dbms_rls.static,
      statement_types  => 'select, insert, update, delete, index',
      update_check     => TRUE);
  end if;
  close c_policy_cur;

end CREATE_POLICY;


--  Bug 25985045, jwsmith. Create a create_patch_rowset procedure that
--  we can call from two places in create_sync routine. This procedure
--  simply creates the patch rowset for the dual rowset functionality.
procedure CREATE_PATCH_ROWSET(
  X_TABLE_OWNER  in varchar2,
  X_TABLE_NAME   in varchar2,
  X_PATCH_ROWSET in varchar2,
  X_RUN_ROWSET   in varchar2,
  X_COL_LIST     in varchar2,
  X_INDEX_NAME   in varchar2)
is
  C_MODULE         varchar2(80)     := 'ad.plsql.ad_zd_seed.create_patch_rowset';
  L_SQL_STMT       varchar2(32767);
  L_SQL_START      varchar2(200);
  NL               varchar(1) := '
';
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name||', patch rowset= '||
      x_patch_rowset||', run_rowset= '||x_run_rowset||', column list= '||
      x_col_list||', index_name= '||x_index_name);

  -- Bug 25646675 - jwsmith, set inserted/updated rows to synced, does not fire sync trigger
  l_sql_stmt := ' update "'||x_table_owner||'"."'||x_table_name||'" tbl '||
                ' set zd_sync=''SYNCED'' '||
                ' where zd_sync <> ''SYNCED'' and zd_edition_name='''||x_run_rowset||''''||
                ' and rowid between :start_id and :end_id ';
  run_in_parallel(l_sql_stmt, x_table_name||'|UPDATE_SYNCED', x_table_owner, x_table_name);

  -- Bug 25985045 jwsmith, We need to create the patch rowset by
  -- inserting into the Base Table instead of the Editioning View in
  -- order not to violate the VPD policy, as the create_policy is called
  -- after create_sync routine, which calls this routine.
  -- TODO: ??? Make this run_in_parallel ???
  if x_index_name is null then
     l_sql_start := 'insert ';
  else
     l_sql_start := 'insert /*+ ignore_row_on_dupkey_index("'||x_table_name||'","'||x_index_name||'") */ ';
  end if;
  l_sql_stmt := l_sql_start
         ||NL||'into "'||x_table_owner||'"."'||x_table_name||'"'
         ||NL||'  ('||x_col_list||', ZD_EDITION_NAME, ZD_SYNC) '
         ||NL||'select '||x_col_list||', '''||x_patch_rowset||''', ''SYNCED'' '
         ||NL||'from "'||x_table_owner||'"."'||x_table_name||'" '
         ||NL||'where zd_edition_name='''||x_run_rowset||'''';
  exec (l_sql_stmt, c_module);
  commit;

  log(c_module, 'PROCEDURE', 'end');
end CREATE_PATCH_ROWSET;

/*
** Create Data Synchronization from RUN rowset to PATCH rowset
**
** X_COPY_DATA: true to copy the Run Edition seed data to the Patch Edition
**              false to skip the copy (when it was already done)
*/
procedure CREATE_SYNC(
  X_TABLE_OWNER  in varchar2,
  X_TABLE_NAME   in varchar2,
  X_COPY_DATA    in boolean,
  X_PATCH_ROWSET in varchar2,
  X_RUN_ROWSET   in varchar2)
is
  C_MODULE         varchar2(80) := 'ad.plsql.ad_zd_seed.create_sync';
  L_TRIG_NAME      varchar2(30) := ad_zd_seed.eds_fcet(x_table_name);
  L_EV_NAME        varchar2(30) := substrb(x_table_name,1,29)||'#'; /*ad_zd_table.ev_view*/
  L_PATCH_ROWSET_EXISTS varchar2(1);
  L_ROWSET_STATUS  varchar2(30);
  L_STMT           varchar2(32767);
  L_SQL_STMT       varchar2(32767);
  L_SAVE_STMT      varchar2(32767);      /* save data values */
  L_COL_LIST       varchar2(32767);      /* insert-select column names */
  L_UPDATING_COL_STMT varchar2(32767);   /* insert-select column names */
  L_OLD_KEY_STMT   varchar2(3000);       /* get old key values */
  L_NEW_KEY_STMT   varchar2(3000);       /* get new key values */
  L_REC_KEY_STMT   varchar2(3000);       /* key record type */
  L_WHERE_STMT     varchar2(3000);       /* where key */
  L_SYNC_KEY_STMT  varchar2(3000);
  L_FIRST          boolean;
  L_NO_PKEY        boolean;              /* Set to false if table has a Primary key, TRUE otherwise */
  L_INDEX_OWNER    varchar2(30);
  L_INDEX_NAME     varchar2(30);
  L_NEW_EDITION    varchar2(30);    /* patch edition of seed data */
  NL               varchar(1) := '
';

  -- Table columns (excluding zd_edition_name and zd_sync)
  cursor C_TAB_COLS(x_tab_owner varchar2, x_tab_name varchar2 ) is
    select column_name
    from   dba_tab_columns
    where  owner       =  x_tab_owner
      and  table_name  =  x_tab_name
      and  column_name <> 'ZD_EDITION_NAME'
      and  column_name <> 'ZD_SYNC'
    order by column_id;

  -- Unique Key columns
  -- Uses unique index with lowest sorting name (_PK, or _U1) on
  -- assumption that it is a non-updatable primary key.
  cursor C_KEY_COLS(x_owner varchar2, x_tab_name varchar2 ) is
    select
        uk.owner
      , uk.index_name
      , ic.column_name
      , nvl(col.nullable, 'Y') nullable
    from
      ( select * from
        ( select i.owner, i.index_name
          from   dba_indexes i
          where  i.table_owner = x_owner
            and  i.table_name  = x_tab_name
            and  i.uniqueness  = 'UNIQUE'
            and  i.index_type  = 'NORMAL'    /* exclude other index types */
            and  i.index_name not like '%~%' /* exclude revised indexes created by a patch */
          order by 1,2 )
        where rownum = 1 ) uk,
      dba_ind_columns ic, dba_tab_columns col
    where ic.index_owner   = uk.owner
      and ic.index_name    = uk.index_name
      and ic.column_name   <> 'ZD_EDITION_NAME'
      and ic.table_owner   = x_owner
      and ic.table_name    = x_tab_name
      and col.owner        = x_owner
      and col.table_name   = x_tab_name
      and col.column_name  = ic.column_name
    order by ic.column_position;

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  l_new_edition := ad_zd.get_edition;

  -- If copying data, get patch rowset ready for sync
  if x_copy_data then
    l_patch_rowset_exists := rowset_exists(x_table_owner, x_table_name, x_patch_rowset);
    l_rowset_status := get_rowset_status(x_table_owner, x_table_name);
    log(c_module, 'STATEMENT', 'Patch rowset exists: '||l_patch_rowset_exists||', rowset status: '||l_rowset_status);

    -- empty patch rowset is considered invalid
    if l_patch_rowset_exists = 'N' and l_rowset_status <> 'INVALID' then
      set_rowset_status(x_table_owner, x_table_name, 'INVALID');
      l_rowset_status := 'INVALID';
    end if;

    if l_patch_rowset_exists = 'Y' then
      if l_rowset_status = 'INVALID' then
        -- delete existing invalid rowset
        cleanup_table(x_table_owner, x_table_name);
        l_patch_rowset_exists := 'N';
      elsif l_rowset_status = 'UNSET' then
        -- unset patch rowset status is presumed VALID
        set_rowset_status(x_table_owner, x_table_name, 'VALID');
        l_rowset_status := 'VALID';
      end if;
    end if;
  end if;

  -- Construct SQL Fragments that depend on KEY COLUMNS
  l_rec_key_stmt := '  type KEY_R is record (';
  l_old_key_stmt := '';
  l_new_key_stmt := '';
  l_where_stmt  := '  where ';
  l_first := true;
  l_no_pkey := true;
  l_sync_key_stmt := '';

  for crec in c_key_cols(x_table_owner, x_table_name) loop
    -- append seperator string for second and subsequent keys
    if l_first then
      l_no_pkey := false;
      l_first := false;
      -- remember PK name for insert hint
      l_index_owner := crec.owner;
      l_index_name  := crec.index_name;
      l_updating_col_stmt:='updating('''||crec.column_name||''')';
    else
      l_rec_key_stmt := l_rec_key_stmt||',';
      l_old_key_stmt := l_old_key_stmt||NL;
      l_new_key_stmt := l_new_key_stmt||NL;
      l_where_stmt   := l_where_stmt||' and ';
      l_sync_key_stmt:= l_sync_key_stmt||' and ';
      if( l_index_owner=crec.owner and l_index_name=crec.index_name) then
        l_updating_col_stmt:=l_updating_col_stmt||NL||
                             '       OR updating('''||crec.column_name||''')';
      end if;
    end if;

    l_rec_key_stmt := l_rec_key_stmt||
        NL||'    '||crec.column_name||' '||x_table_owner||'.'||x_table_name||'.'||crec.column_name||'%TYPE';

    l_old_key_stmt := l_old_key_stmt||
        '    l_key(idx).'||crec.column_name||' := :old.'||crec.column_name||';';

    l_new_key_stmt := l_new_key_stmt||
        '    l_key(idx).'||crec.column_name||' := :new.'||crec.column_name||';';

    if (crec.nullable = 'N') then
      l_where_stmt    := l_where_stmt||crec.column_name||'=l_key(j).'||crec.column_name;
      l_sync_key_stmt := l_sync_key_stmt||'s1.'||crec.column_name||'=s2.'||crec.column_name;
    else
      l_where_stmt := l_where_stmt||
          '(('||crec.column_name||' is null and l_key(j).'||crec.column_name||
           ' is null) or ('||crec.column_name||'=l_key(j).'||crec.column_name||'))';

      l_sync_key_stmt := l_sync_key_stmt||
          '((s1.'||crec.column_name||' is null and s2.'||crec.column_name||' is null) or (s1.'||
             crec.column_name||'=s2.'||crec.column_name||'))';
    end if;

  end loop;
  l_rec_key_stmt := l_rec_key_stmt||' );';

  -- Construct SQL fragmnets that depend on TABLE COLUMNS
  l_first := TRUE;
  l_save_stmt := '';
  l_col_list  := '';
  for crec in c_tab_cols(x_table_owner, x_table_name) loop
    if l_first then
      l_first := false;
    else
      l_save_stmt := l_save_stmt||NL;
      l_col_list  := l_col_list||', ';
    end if;
   l_save_stmt := l_save_stmt||'    l_data(idx).'||crec.column_name||' := :new.'||crec.column_name||';';
   l_col_list  := l_col_list||crec.column_name;
  end loop;

  -- if there was no PK then we cannot create a sync trigger, copy data and exit
  if (l_no_pkey) then
    log(c_module, 'WARNING', 'Table does not support Synchronization: '||x_table_name);
    if x_copy_data then
      if l_patch_rowset_exists = 'Y' then
        log(c_module, 'STATEMENT', 'Delete patch rowset: '||x_table_name);
        set_rowset_status(x_table_owner, x_table_name, 'INVALID');
        exec('delete from "'||x_table_owner||'"."'||x_table_name||
             '" where zd_edition_name='''||x_patch_rowset||'''', c_module);
      end if;
      create_patch_rowset(x_table_owner, x_table_name, x_patch_rowset, x_run_rowset, l_col_list, l_index_name);
      set_rowset_status(x_table_owner, x_table_name, 'VALID');
    end if;
    return;
  end if;

  --
  -- Create statement for Sync Trigger
  --
  -- - For Each Insert Statement, First it will try to insert the values for patch edition,
  --   if row having same key values already exists, then it will update the existing row
  --
  -- - For Each Update Statement, First it will try to update the row with same key values
  --   in the patch edition, if no rows found exception comes, then it will insert the new row.
  --
  -- - For Each Delete Statement, it will directly try to delete the row from patch edition.
  --
  -- Sync Trigger is responsible for setting the ZD_SYNC flag to SYNCED
  --
  l_stmt:='create or replace trigger '||ad_zd.apps_schema||'."'||l_trig_name||'" /*['||l_new_edition||']*/ '
    ||NL||'  for insert or update or delete on '||x_table_owner||'.'||x_table_name
    ||NL||'  forward crossedition compound trigger '
    ||NL||'  type DATA_T is table of '||x_table_owner||'.'||x_table_name||'%ROWTYPE index by simple_integer;'
    ||NL||   l_rec_key_stmt
    ||NL||'  type KEY_T is table of key_r index by simple_integer;'
    ||NL||'  l_data       data_t;'
    ||NL||'  l_key        key_t;'
    ||NL||'  idx          simple_integer := 0;'
    ||NL||'  l_edition    varchar2(30)   := '''||l_new_edition||''';'
    ||NL||'  l_patch_rowset varchar2(30) := '''||x_patch_rowset||''';'
    ||NL
    ||NL||'BEFORE EACH ROW IS begin'
    ||NL||'  if inserting or updating then'
    ||NL||'    :new.zd_sync := ''SYNCED'';'
    ||NL||'  end if;'
    ||NL||'end BEFORE EACH ROW;'
    ||NL
    ||NL||'AFTER EACH ROW IS begin'
    ||NL||'  idx := idx + 1;'
    ||NL||'  if inserting then'
    ||NL||     l_new_key_stmt
    ||NL||'  else'
    ||NL||     l_old_key_stmt
    ||NL||'  end if;'
    ||NL||'  if inserting or updating then'
    ||NL||     l_save_stmt
    ||NL||'  end if;'
    ||NL||'  l_data(idx).zd_edition_name := l_patch_rowset;'
    ||NL||'  l_data(idx).zd_sync := ''SYNCED'';'
    ||NL||'end AFTER EACH ROW;'
    ||NL
    ||NL||'AFTER STATEMENT IS begin'
    ||NL||' if inserting then'
    ||NL||'   for j in 1..l_key.count loop'
    ||NL||'     begin '
    ||NL||'       insert into '||x_table_owner||'.'||x_table_name
    ||NL||'       values l_data(j);'
    ||NL||'     exception when dup_val_on_index then '
    ||NL||'       update '||x_table_owner||'.'||x_table_name||' set row = l_data(j) '
    ||NL||'       '||l_where_stmt||' and zd_edition_name=l_patch_rowset; '
    ||NL||'     end;'
    ||NL||'   end loop;'
    ||NL||' elsif updating then'
    ||NL||'   for j in 1..l_key.count loop'
    ||NL||'      update '||x_table_owner||'.'||x_table_name||' set row = l_data(j)'
    ||NL||'       '||l_where_stmt||' and zd_edition_name=l_patch_rowset;'
    ||NL||'      if(sql%rowcount = 0) then '
    ||NL||'         insert into '||x_table_owner||'.'||x_table_name
    ||NL||'         values l_data(j); '
    ||NL||'      end if; '
    ||NL||'   end loop;'
    ||NL||' elsif deleting then '
    ||NL||'   forall j in 1..l_key.count'
    ||NL||'     delete from '||x_table_owner||'.'||x_table_name
    ||NL||      l_where_stmt||' and zd_edition_name=l_patch_rowset;'
    ||NL||' end if;'
    ||NL||'end AFTER STATEMENT;'
    ||NL||'end "'||l_trig_name||'";';

  log(c_module, 'STATEMENT', 'Creating EDS Sync Trigger '||l_trig_name);
  exec (l_stmt, c_module);

  --
  -- Syncronized or Copy run rowset data to patch rowset
  --
  if x_copy_data then
    if (l_rowset_status = 'VALID') then
      log(c_module, 'STATEMENT', 'Synchronizing patch rowset '||x_patch_rowset||' for table '||x_table_name);
      synchronize_rowset(x_table_owner, x_table_name, x_patch_rowset, x_run_rowset, l_sync_key_stmt);
    else
      log(c_module, 'STATEMENT', 'Creating patch rowset '||x_patch_rowset||' for table '||x_table_name);
      create_patch_rowset(x_table_owner, x_table_name, x_patch_rowset, x_run_rowset, l_col_list, l_index_name);
      set_rowset_status(x_table_owner, x_table_name, 'VALID');
    end if;
  end if;

  log(c_module, 'PROCEDURE', 'end');
end CREATE_SYNC;



/*
** --------------------------------------------------------------------
**    Database Preparation APIs - Public
** --------------------------------------------------------------------
*/


/*
** Upgrade seed data table to Editioned Data Storage
**
** Table can only be upgraded
**   - Table must be Effectively Editioned (have an EV cover)
**   - Table must not contain a LONG column
**   - In the Patch Edition, Table must be new (not visible in the run edition)
**
** Conversion process:
**   1) Disable product team triggers
**   2) Add ZD_EDITION_NAME column
**   3) Add ZD_EDITION_NAME column to all Unique indexes
**   4) Create Trigger to Populate ZD_EDITION_NAME
**   5) Create VPD Policy and Function to strict access to a specfic PARTITION of the table
**   6) Enable product team triggers
**
** Note: X_TABLE_NAME is the LOGICAL table name (APPS table synonym)
** Note: X_MODE parameter is currently unused
*/
procedure UPGRADE(
  X_TABLE_NAME   in  varchar2,
  X_MODE         in  varchar2 default 'CURRENT')
is
  C_MODULE           varchar2(80) := 'ad.plsql.ad_zd_seed.upgrade';
  L_EDITION          varchar2(30);
  L_TABLE_OWNER      varchar2(30);
  L_TABLE_NAME       varchar2(30);
  L_LOCK_HANDLE      varchar2(128) := null;
  V_PARALLEL         number;
  L_EXISTS           varchar2(1);
  L_PATCH_ROWSET     varchar2(30);
  L_RUN_ROWSET       varchar2(30);
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_name);
  translate_synonym(c_module, x_table_name, false, l_table_owner, l_table_name);

  -- If database is not editioned, save DDL for later execution
  if ad_zd.is_editions_enabled = 'N' then
    -- get parallel servers info
    select to_number(value) into v_parallel
    from v$parameter where name='parallel_max_servers';

    ad_zd_parallel_exec.load('UPGRADE_SEED',
        'begin '||ad_zd.apps_schema||'.ad_zd_seed.upgrade('''||x_table_name||'''); end;',
        true);
    ad_zd_parallel_exec.load('COLLECT_STATS',
        'begin '||ad_zd.apps_schema||'.fnd_stats.gather_table_stats('''||l_table_owner||''','''||l_table_name||''', 100, '||v_parallel||'); end;',
        true);
    commit;
    log(c_module, 'PROCEDURE', 'end');
    return;
  end if;

  l_edition := ad_zd.get_edition;

  -- Table Must have EV
  if ad_zd_table.ev_exists(l_table_owner, l_table_name) = 'N' then
    error(c_module, 'Table must be upgraded for editioning first: '||x_table_name);
  end if;

  -- Cannot re-upgrade existing seed data table,
  -- but ok to upgrade new table with only ZD_EDITION_NAME column
  if (ad_zd_table.is_seed(l_table_owner, l_table_name) = 'Y') then
    -- Check if guard trigger exists
    begin
      -- Using user_objects view instead of user_triggers to work around
      -- the database bug 17777718. We asuume here if the trigger exists
      -- it is created on the proper EV
      select 'Y' into l_exists
      from   user_objects
      where  object_name  = ad_zd_seed.eds_trigger(l_table_name)
      and    object_type  = 'TRIGGER';

      log(c_module, 'WARNING', 'Cannot re-upgrade seed data table: '||x_table_name);
      return;
    exception
      when no_data_found then
        null;
    end;
  end if;

  -- LONG column not supported
  begin
    -- Check if long column exists
    select 'Y' into l_exists from dual
    where exists
            ( select column_name
              from   dba_tab_columns
              where  owner       = l_table_owner
                and    table_name  = l_table_name
                and    data_type = 'LONG' );

    error(c_module, 'Table with long column not supported: '||x_table_name);
    exception
    when no_data_found then
      null;
  end;

  -- In Patch Edition, table must be new (not visible in Run Edition)
  if ad_zd.get_edition_type = 'PATCH' then
    begin
      -- check if synonym exists in the run edition
      select 'Y' into l_exists from dual
      where exists
              ( select syn.object_name from dba_objects_ae syn
                where syn.owner        = ad_zd.apps_schema
                  and syn.object_name  = x_table_name
                  and syn.object_type  = 'SYNONYM'
                  and syn.edition_name =
                    ( select max(ed.edition_name) from dba_objects_ae ed
                      where  ed.owner        = syn.owner
                        and  ed.object_name  = syn.object_name
                        and  ed.edition_name < ad_zd.get_edition ) );
      error(c_module, 'Cannot upgrade existing table from Patch Edition: '
            ||x_table_name);
    exception
      when no_data_found then
        null;
    end;
  end if;

  -- Get lock to ensure only one upgrade is running for this table
  l_lock_handle := acquire_lock(c_module||'.'||l_table_name);

  -- begin block to release lock on an excepton
  begin
    log(c_module, 'EVENT', 'Upgrade seed data table: '||l_table_owner||'.'||l_table_name);
    l_patch_rowset := compute_patch_rowset(l_table_name);

    create_zd_column(l_table_owner, l_table_name, l_patch_rowset);
    create_sync_column(l_table_owner, l_table_name);
    ad_zd_table.patch(l_table_owner, l_table_name);
    fix_indexes(l_table_owner, l_table_name);
    create_guard(l_table_owner, l_table_name, l_edition, l_patch_rowset);
    create_policy(l_table_owner, l_table_name, l_edition, l_patch_rowset);
    commit;

  exception when others then
    -- release lock and rethrow exception
    log(c_module, 'ERROR', 'TABLE: '||x_table_name||', CODE: '||sqlcode||', MESSAGE: "'||sqlerrm||'"');
    log(c_module, 'ERROR', 'TABLE: '||x_table_name||', BACKTRACE: '||dbms_utility.format_error_backtrace);
    -- TODO: reverse actions
    release_lock(l_lock_handle);
    raise;
  end;

  release_lock(l_lock_handle);
  log(c_module, 'PROCEDURE', 'end');
end UPGRADE;


/*
** Revert back the changes done for Editioned Data Storage
**
** Conversion process:
**   1) Remove the ZD_EDITION_NAME column from Unique indexes
**   2) Drop the VPD Policy and Function
**   3) Drop the FCET for data synchronization
**   4) Drop the Trigger to Populate ZD_EDITION_NAME
**   5) Mark the ZD_EDITION_NAME column unused
**   6) Call ad_zd_table.upgrade to refresh EV and synonyms
**   7) Drop SV
**
** Note: X_TABLE_NAME is the LOGICAL table name (APPS table synonym)
*/
procedure DOWNGRADE(X_TABLE_NAME in varchar2)
is
  C_MODULE           varchar2(80) := 'ad.plsql.ad_zd_seed.downgrade';
  L_TABLE_OWNER      varchar2(30);
  L_TABLE_NAME       varchar2(30);
  L_STMT             varchar2(32767);
  L_FCET_NAME        varchar2(30);
  L_TRIG_NAME        varchar2(30);
  L_EDITIONS_ENABLED varchar2(1);
  L_DDL_STMTS        sys.ku$_ddls;

  NO_POLICY_FOUND EXCEPTION;
  PRAGMA EXCEPTION_INIT(NO_POLICY_FOUND, -28102);
  NO_OBJECT_FOUND EXCEPTION;
  PRAGMA EXCEPTION_INIT(NO_OBJECT_FOUND, -4043);
  NO_TRIGGER_FOUND EXCEPTION;
  PRAGMA EXCEPTION_INIT(NO_TRIGGER_FOUND, -4080);
  NO_COLUMN_FOUND EXCEPTION;
  PRAGMA EXCEPTION_INIT(NO_COLUMN_FOUND, -904);
  DUPLICATE_INDEX EXCEPTION;
  PRAGMA EXCEPTION_INIT(DUPLICATE_INDEX, -1408);

  cursor C_IND_CUR (x_tab_owner varchar2, x_tab_name varchar2) is
    select i.owner, i.index_name
    from   dba_indexes i
    where  i.table_owner = x_tab_owner
    and    i.table_name  = x_tab_name
    and    i.uniqueness  = 'UNIQUE'
    and    i.index_type  <> 'LOB'
    and    exists  ( select null
                     from   dba_ind_columns c
                     where  c.index_owner = i.owner
                     and    c.index_name  = i.index_name
                     and    c.column_name = 'ZD_EDITION_NAME' );

  cursor C_CONSTRAINT_CUR (x_tab_owner varchar2, x_tab_name varchar2) is
    select constraint_name, constraint_type
    from dba_constraints o
    where owner           = x_tab_owner
    and   table_name      = x_tab_name
    and   constraint_type in ('U','P')
    and   exists  ( select null
                    from   dba_cons_columns i
                    where  i.owner = o.owner
                    and    i.constraint_name  = o.constraint_name
                    and    i.column_name = 'ZD_EDITION_NAME' );

  cursor C_POLICY_CUR (x_tab_owner varchar2, x_tab_name varchar2) is
    select object_owner, object_name, policy_name, function from dba_policies
    where object_owner = x_tab_owner
    and object_name in (x_tab_name, ad_zd_table.ev_view(x_tab_name))
    and upper(policy_name) like '%ZD_SEED';

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_name);

  l_editions_enabled := ad_zd.is_editions_enabled;
  translate_synonym(c_module, x_table_name, false, l_table_owner, l_table_name);

  log(c_module, 'EVENT', 'Downgrade seed data table: '||l_table_owner||'.'||l_table_name);

  -- Cleanup data copies
  if (l_editions_enabled = 'Y') then
    if ad_zd_table.is_seed(l_table_owner, l_table_name) = 'Y' then
      ad_zd_seed.cleanup(x_table_name);
    end if;
  end if;

  -- Fix Constraints
  for crec in c_constraint_cur(l_table_owner,l_table_name) loop
    log(c_module, 'STATEMENT', 'Fixing Constraint: '||crec.constraint_name);
    lock_table(l_table_owner, l_table_name, c_module);
    l_ddl_stmts := fetch_multiple_ddls(l_table_owner, l_table_name, 'CONSTRAINT', l_table_owner, crec.constraint_name);

    if crec.constraint_type = 'U' then
      l_stmt := 'alter table "'||l_table_owner||'"."'||l_table_name||'" drop constraint '||crec.constraint_name||' drop index';
    else
      l_stmt := 'alter table "'||l_table_owner||'"."'||l_table_name||'" drop constraint '||crec.constraint_name||' cascade drop index';
    end if;
    exec(l_stmt, c_module, true);

    for i in 1 .. l_ddl_stmts.count loop
      l_stmt := dbms_lob.substr(l_ddl_stmts(i).ddltext);
      if i=1 then
        l_stmt := regexp_replace(l_stmt, '[, ]*"ZD_EDITION_NAME"[, ]*', '', 1, 1);
      end if;
      exec(l_stmt, c_module, true);
    end loop;
  end loop;

  -- Fix Indexes
  for irec in c_ind_cur(l_table_owner,l_table_name) loop
    log(c_module, 'STATEMENT', 'Fixing Index: '||irec.owner||'.'||irec.index_name);
    lock_table(l_table_owner, l_table_name, c_module);
    l_ddl_stmts := fetch_multiple_ddls(l_table_owner, l_table_name, 'INDEX', irec.owner, irec.index_name);

    l_stmt := 'drop index "'||irec.owner||'"."'||irec.index_name||'"';
    exec(l_stmt, c_module, true);

    for i in 1 .. l_ddl_stmts.count loop
      begin
        l_stmt := dbms_lob.substr(l_ddl_stmts(i).ddltext);
        if i=1 then
          l_stmt := regexp_replace(l_stmt, '[, ]*"ZD_EDITION_NAME"[, ]*', '', 1, 1);
        end if;
    exec(l_stmt, c_module);
      exception
        when duplicate_index then
          log(c_module, 'STATEMENT', 'Ignored: Such column list already indexed: '||irec.index_name);
        when others then
          log(c_module, 'ERROR', 'Error fixing '||irec.index_name||': '||SQLERRM);
      end;
    end loop;
  end loop;

  -- Drop EDS Policy
  for policyrec in c_policy_cur(l_table_owner, l_table_name) loop
    begin
      log(c_module, 'STATEMENT', 'Dropping EDS Policy: '
                        ||policyrec.object_owner||','||policyrec.object_name||','||policyrec.policy_name);
      dbms_rls.drop_policy(
        object_schema    =>  policyrec.object_owner,
        object_name      =>  policyrec.object_name,
        policy_name      =>  policyrec.policy_name);
    exception when no_policy_found then
      log(c_module, 'STATEMENT', 'Ignored: Policy not found');
    end;
    begin
      l_stmt := 'drop function "'||ad_zd.apps_schema||'"."'||policyrec.function||'"';
      exec(l_stmt, c_module, true);
    end;
  end loop;

  -- Drop EDS Sync Trigger
  l_fcet_name := ad_zd_seed.eds_fcet(l_table_name);
  l_stmt := 'drop trigger "'||ad_zd.apps_schema||'"."'||l_fcet_name||'"';
  exec(l_stmt, c_module, true);

  -- Drop EDS Guard Trigger
  l_trig_name := ad_zd_seed.eds_trigger(l_table_name);
  l_stmt := 'drop trigger "'||ad_zd.apps_schema||'"."'||l_trig_name||'"';
  exec(l_stmt, c_module, true);

  -- Mark EDS Striping Column unused
  l_stmt := 'alter table "'||l_table_owner||'"."'||l_table_name||'" set unused (ZD_EDITION_NAME)';
  exec(l_stmt, c_module, true);

  l_stmt := 'alter table "'||l_table_owner||'"."'||l_table_name||'" set unused (ZD_SYNC)';
  exec(l_stmt, c_module, true);

  -- Regenerate editioning view
  if (l_editions_enabled = 'Y') then
    ad_zd_table.patch(l_table_owner, l_table_name);
  end if;

  commit;
  log(c_module, 'PROCEDURE', 'end');

exception when others then
  log(c_module, 'ERROR', 'TABLE: '||x_table_name||', CODE: '||sqlcode||', MESSAGE: "'||sqlerrm||'"');
  log(c_module, 'ERROR', 'TABLE: '||x_table_name||', BACKTRACE: '||dbms_utility.format_error_backtrace);
  raise;
end DOWNGRADE;


/*
** --------------------------------------------------------------------
**    Patch Event APIs - Public
** --------------------------------------------------------------------
*/


/*
** Patch seed data table
**   - regenerates sync trigger to new table structure
*/
procedure PATCH(X_TABLE_OWNER in varchar2, X_TABLE_NAME in varchar2)
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_seed.patch';
  L_PATCH_ROWSET    varchar2(30);
  L_RUN_ROWSET      varchar2(30);
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  -- If not in patch edition, then do nothing
  if ad_zd.get_edition_type <> 'PATCH' then
    log(c_module, 'PROCEDURE', 'end-noop');
    return;
  end if;

  -- If not prepared then do nothing
  if not is_prepared(x_table_name) then
    log(c_module, 'PROCEDURE', 'end-noop');
    return;
  end if;

  l_patch_rowset := get_rowset(x_table_name, 'PATCH');
  l_run_rowset   := get_rowset(x_table_name, 'RUN');

  -- Recreate sync trigger, no copy
  create_sync(x_table_owner, x_table_name, false, l_patch_rowset, l_run_rowset);

  log(c_module, 'PROCEDURE', 'end');
end PATCH;


/*
** Upgrade Policy
**   Check if the existing seed VPD policy is enabled for select, insert,
**   update, delete and index statement types. If not, then do the
**   DROP_POLICY / ADD_POLICY to recreate the corrected policy.
*/
procedure UPGRADE_POLICY(X_TABLE_OWNER in varchar2, X_TABLE_NAME in varchar2)
is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd_seed.upgrade_policy';
  L_DUMMY        varchar2(80);

  cursor C_FUNC_CUR(x_tab_name varchar2) is
    select name
    from   dba_source
    where  owner = ad_zd.apps_schema
    and    name  = ad_zd_seed.eds_function(x_table_name)
    and    type  = 'FUNCTION';

  cursor C_POLICY_CUR (x_tab_owner varchar2, x_tab_name varchar2) is
    select policy_name
    from   dba_policies
    where  object_owner = x_tab_owner
    and    object_name  = ad_zd_table.ev_view(x_tab_name)
    and    policy_name  = ad_zd_seed.eds_policy
    and    (sel='NO' or ins='NO' or upd='NO' or del='NO' or idx='NO' or chk_option='NO');

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  -- Table must have EDS VPD function
  open  c_func_cur(x_table_name);
  fetch c_func_cur INTO l_dummy;
  if (c_func_cur%notfound) then
    error(c_module, 'Editioned Data Storage VPD function does not exist: '||x_table_name);
  end if;
  close c_func_cur;

  -- Upgrade policy
  open  c_policy_cur(x_table_owner, x_table_name);
  fetch c_policy_cur INTO l_dummy;
  if (c_policy_cur%found) then
    log(c_module, 'STATEMENT', 'Recreating EDS Filter Policy '||x_table_owner||'.'||ad_zd_table.ev_view(x_table_name)||', '||ad_zd_seed.eds_policy);
    dbms_rls.drop_policy(
       object_schema   => x_table_owner,
       object_name     => ad_zd_table.ev_view(x_table_name),
       policy_name     => ad_zd_seed.eds_policy);

    -- Bug 25469830 jwsmith, added update_check TRUE
    dbms_rls.add_policy(
      object_schema    =>  x_table_owner,
      object_name      =>  ad_zd_table.ev_view(x_table_name),
      policy_name      =>  ad_zd_seed.eds_policy,
      function_schema  =>  ad_zd.apps_schema,
      policy_function  =>  '"'||ad_zd_seed.eds_function(x_table_name)||'"',
      policy_type      =>  dbms_rls.static,
      statement_types  => 'select, insert, update, delete, index',
      update_check     => TRUE);
  end if;
  close c_policy_cur;

  log(c_module, 'PROCEDURE', 'end');
end UPGRADE_POLICY;


/*
** Prepare Table for Seed data patching
**   This API must be called before loading data into a seed data table
**   in the patch edition.  The following major actions are performed:
**
**  2). Create/Apply EDS Sync Trigger to synchronize data
**  3). Update VPD Policy function for patch edition
**  1). Create EDS Guard Trigger patch new edition
**
** Note: X_TABLE_NAME is the LOGICAL table name (APPS table synonym)
*/
procedure PREPARE(X_TABLE_NAME in varchar2)
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_seed.prepare';
  L_TABLE_OWNER     varchar2(30);
  L_TABLE_NAME      varchar2(30);
  L_EDITION         varchar2(30)  := sys_context('userenv', 'current_edition_name');
  L_LOCK_HANDLE     varchar2(128) := null;
  L_PATCH_ROWSET    varchar2(30);
  L_RUN_ROWSET      varchar2(30);

  -- Triggers that conflict with rowset synchronization must be temporarily disabled
  --   Disabling the maintenance trigger for a CTXCAT index will require index rebuild
  cursor C_SYNC_CONFLICTS (x_tab_owner varchar2, x_tab_name varchar2) is
    select trg.owner owner, trg.trigger_name, idx.index_name index_name
    from dba_triggers trg, dba_indexes idx
    where trg.table_owner = x_tab_owner
      and trg.table_name = x_tab_name
      and trg.owner <> USER
      and trg.status = 'ENABLED'
      and idx.owner (+) = trg.owner
      and idx.index_name (+) = regexp_replace(trg.trigger_name,'DR\$(.*)TC', '\1')
      and idx.table_owner (+) = x_tab_owner
      and idx.table_name (+) = x_tab_name
      and idx.ityp_owner (+) = 'CTXSYS'
      and idx.ityp_name (+) = 'CTXCAT';

  -- exceptions not caught by "when others"
  C_USER_CANCEL exception;
    pragma exception_init(c_user_cancel, -1013);
  C_SESSION_KILLED  exception;
    pragma exception_init(c_session_killed, -28);
  C_INVALID_ROWID  exception;
    pragma exception_init(c_invalid_rowid, -10632);
  C_CURSOR_INV_PE exception;
    pragma exception_init(c_cursor_inv_pe, -12842);
  C_CURSOR_INV_PART exception;
    pragma exception_init(c_cursor_inv_part, -14403);

begin

  -- If not in patch edition, then do nothing
  if ad_zd.get_edition_type(l_edition) <> 'PATCH' then
    return;
  end if;

  -- If prepare is repeated for the same table, then do nothing
  translate_synonym(c_module, x_table_name, true, l_table_owner, l_table_name);
  if is_prepared(l_table_name) then
    log(c_module, 'PROCEDURE', 'end: table '||x_table_name||' is already prepared');
    return;
  end if;

  log(c_module, 'PROCEDURE', 'begin: '||x_table_name);

  -- Get lock to ensure only one prepare is running for this table
  l_lock_handle := acquire_lock(c_module||'.'||l_table_name);
  if not is_prepared(l_table_name) then
    l_run_rowset   := get_rowset(l_table_name, 'RUN');
    l_patch_rowset := compute_patch_rowset(l_table_name);
    log(c_module, 'EVENT', 'Prepare seed data table: '||l_table_owner||'.'||l_table_name||
                           ', rowset: '||l_run_rowset||' -> '||l_patch_rowset);

    -- Disable conflicting triggers, re-enable at CUTOVER
    for crec in c_sync_conflicts(l_table_owner, l_table_name) loop
      log(c_module, 'STATEMENT', 'Rowset synchronization conflict trigger '||
          crec.owner||'.'||crec.trigger_name||' will be temporarily disabled');
      begin
        exec('alter trigger '||crec.owner||'.'||crec.trigger_name||' disable', c_module);
      exception
        when others then
          error(c_module, 'Cannot disable conflicting trigger '||crec.owner||'.'||crec.trigger_name);
      end;
      ad_zd.load_ddl('CUTOVER', 'alter trigger '||crec.owner||'.'||crec.trigger_name||' enable');
      if crec.index_name is not null then
        ad_zd.load_ddl('CUTOVER', 'alter index '||crec.owner||'.'||crec.index_name||' rebuild');
      end if;
    end loop;

    begin
      -- Create ZD_SYNC column if missing
      create_sync_column(l_table_owner, l_table_name);
      -- store deferred DDL
      ad_zd.load_ddl('CLEANUP', 'begin ad_zd_seed.cleanup('''||x_table_name||'''); end;');
      ad_zd.load_ddl('ABORT', 'begin ad_zd_seed.abort('''||l_table_owner||''','''||l_table_name||'''); end;');
      ad_zd_mview.patch(l_table_owner, l_table_name);
      commit;
    exception
      when others then
        log(c_module, 'ERROR', 'TABLE: '||x_table_name||', CODE: '||sqlcode||', MESSAGE: "'||sqlerrm||'"');
        log(c_module, 'ERROR', 'TABLE: '||x_table_name||', BACKTRACE: '||dbms_utility.format_error_backtrace);
        raise;
    end;

    begin
      create_sync(l_table_owner, l_table_name, true, l_patch_rowset, l_run_rowset);
      create_policy(l_table_owner, l_table_name, l_edition, l_patch_rowset);
      create_guard(l_table_owner, l_table_name, l_edition, l_patch_rowset);
    exception
      when others then
        log(c_module, 'ERROR', 'TABLE: '||x_table_name||', CODE: '||sqlcode||', MESSAGE: "'||sqlerrm||'"');
        log(c_module, 'ERROR', 'TABLE: '||x_table_name||', BACKTRACE: '||dbms_utility.format_error_backtrace);
        log(c_module, 'ERROR', 'Seed data prepare failure: '||x_table_name);
        set_rowset_status(l_table_owner, l_table_name, 'INVALID');
        exec('drop trigger '||ad_zd.apps_schema||'."'||ad_zd_seed.eds_fcet(l_table_name)||'"', c_module, true);
        create_policy(l_table_owner, l_table_name, l_edition, l_run_rowset);
        raise;
    end;

  end if; -- not prepared

  commit;
  release_lock(l_lock_handle);
  log(c_module, 'PROCEDURE', 'end');

exception
  when c_user_cancel or c_session_killed or c_invalid_rowid or c_cursor_inv_pe or c_cursor_inv_part then
    log(c_module, 'ERROR', 'Special Exception during seed data prepare: '||x_table_name||', CODE: '||sqlcode||', MESSAGE: "'||sqlerrm||'"');
    release_lock(l_lock_handle);
    raise;
  when others then
    log(c_module, 'ERROR', 'Exception during seed data prepare: '||x_table_name||', CODE: '||sqlcode||', MESSAGE: "'||sqlerrm||'"');
    release_lock(l_lock_handle);
    raise;
end PREPARE;


/*
** Cutover
*  NOTE: No action in current implementation, just here for consistancy
*/
procedure CUTOVER
is
  C_MODULE            varchar2(80) := 'ad.plsql.ad_zd_seed.cutover';
begin
  null;
end CUTOVER;


/*
** Cleanup - delete old seed data rows
**
** Note: old triggers and policy functions will be handled by
**       central edition manager cleanup
** Note: X_TABLE_NAME is the LOGICAL table name (APPS table synonym)
*/
procedure CLEANUP(X_TABLE_NAME in varchar2 default NULL)
is
  C_MODULE        varchar2(80)     := 'ad.plsql.ad_zd_seed.cleanup';
  L_EDITION       varchar2(30)     := sys_context('userenv', 'current_edition_name');
  L_TABLE_OWNER   varchar2(30);
  L_TABLE_NAME    varchar2(30);

begin
  -- return immediately unless explicit table cleanup
  if x_table_name is null then
    return;
  end if;

  log(c_module, 'PROCEDURE', 'begin: '||x_table_name);

  if ad_zd.get_edition('PATCH') is not null then
    error(c_module, 'Cannot cleanup while Patch Edition exists');
  end if;

  if ad_zd.get_edition_type(l_edition) <> 'RUN' then
    error(c_module, 'Cleanup can only execute in the Run Edition');
  end if;

  -- ignore missing synonym (table must have been dropped)
  begin
    select s.table_owner, s.table_name
    into   l_table_owner, l_table_name
    from   dba_synonyms s
    where  s.owner        = ad_zd.apps_schema
      and  s.synonym_name = x_table_name;
  exception when no_data_found then
    log(c_module, 'STATEMENT', 'Ignored: Synonym does not exist: '||x_table_name);
    log(c_module, 'PROCEDURE', 'end - noop');
    return;
  end;

  -- cleanup explicit table
  translate_synonym(c_module, x_table_name, true, l_table_owner, l_table_name);
  cleanup_table(l_table_owner, l_table_name);

  log(c_module, 'PROCEDURE', 'end');
end CLEANUP;


/*
** Abort
*/
procedure ABORT
is
  C_MODULE            varchar2(80) := 'ad.plsql.ad_zd_seed.abort';
begin
  null; /* noop */
end ABORT;

/*
** Abort a prepared seed data table
*/
procedure ABORT(X_TABLE_OWNER in varchar2, X_TABLE_NAME in varchar2)
is
  C_MODULE          varchar2(80)     := 'ad.plsql.ad_zd_seed.abort';
  C_NO_TABLE        exception;
    pragma exception_init(c_no_table, -942);
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  if (ad_zd.get_edition_type <> 'RUN') then
    error(c_module, 'Abort can only be called from the Run Edition.');
  end if;

  -- patch rowset from aborted patch should be deleted
  set_rowset_status(x_table_owner, x_table_name, 'INVALID');
  cleanup_table(x_table_owner, x_table_name);

  log(c_module, 'PROCEDURE', 'end');

exception
  when c_no_table then
    log(c_module, 'PROCEDURE', 'end - no table');
end ABORT;

END AD_ZD_SEED;
