
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_PARALLEL_EXEC" authid current_user  as
/* $Header: ADZDPEXS.pls 120.29.12020000.8 2014/08/26 12:21:25 vgannara ship $ */
C_PACKAGE constant varchar2(80) := 'ad.plsql.ad_zd_parallel_exec.';


/*
** Phase Constants
** NOTE: Phase names must be in sync across the following files
**   1 - Auto-Patch  : Driver file being used for EBR enablement
**   2 - Report file : ADZDEXRPT.sql ( ADZDSHOWDDL.sql )
*/

--
-- Online Patching Enablement Phase Constants
--
C_PHASE_DROP_UNUSED_OBJECT   CONSTANT  varchar2(20) := 'DROP_UNUSED_OBJECT';
-- Copy TYPE and STOP AQ DDLS will be populated
C_PHASE_COPY_TYPE            CONSTANT  varchar2(20) := 'COPY_TYPE';
C_PHASE_COMPILE_TYPE         CONSTANT  varchar2(20) := 'COMPILE_TYPE';
C_PHASE_COPY_EVOLVED_TYPE    CONSTANT  varchar2(20) := 'COPY_EVOLVED_TYPE';
-- ST mover will be called
C_PHASE_FIX_COLUMN           CONSTANT  varchar2(20) := 'FIX_COLUMN';
C_PHASE_FIX_TYPE             CONSTANT  varchar2(20) := 'FIX_TYPE';
C_PHASE_FIX_PUBLIC_SYNONYM   CONSTANT  varchar2(20) := 'FIX_PUBLIC_SYNONYM';
C_PHASE_RECREATE_AQ_OBJECT   CONSTANT  varchar2(20) := 'RECREATE_AQ_OBJECT';
C_PHASE_DROP_OBJECT          CONSTANT  varchar2(20) := 'DROP_OBJECT';
C_PHASE_ENABLE_EDITIONING    CONSTANT  varchar2(20) := 'ENABLE_EDITIONING';

C_PHASE_UPGRADE_TABLE        CONSTANT  varchar2(20) := 'UPGRADE_TABLE';
C_PHASE_UPGRADE_SEED         CONSTANT  varchar2(20) := 'UPGRADE_SEED';
C_PHASE_COLLECT_STATS        CONSTANT  varchar2(20) := 'COLLECT_STATS';
C_PHASE_UPGRADE_MVIEW        CONSTANT  varchar2(20) := 'UPGRADE_MVIEW';

--
-- Online Patching Cycle Phase Constants
--
C_PHASE_CUTOVER              CONSTANT  varchar2(20) := 'CUTOVER';
C_PHASE_ABORT                CONSTANT  varchar2(20) := 'ABORT';
C_PHASE_DROP_COVERED_OBJS    CONSTANT  varchar2(20) := 'DROP_COVERED_OBJS';
C_PHASE_CLEANUP              CONSTANT  varchar2(20) := 'CLEANUP';
C_PHASE_ACTUALIZE_ALL        CONSTANT  varchar2(20) := 'ACTUALIZE_ALL';
C_PHASE_ACTUALIZE_PARENT_OBJS CONSTANT  varchar2(25) := 'ACTUALIZE_PARENT_OBJS';
C_PHASE_ACTUALIZE_CHILD_OBJS  CONSTANT  varchar2(25) := 'ACTUALIZE_CHILD_OBJS';

--
-- Job Status Constants (for AD_ZD_DDL_HANDLER.EXECUTED)
--
C_JOB_STATUS_RUNNING         CONSTANT  varchar2(1) := 'R';
C_JOB_STATUS_NOT_EXECUTED    CONSTANT  varchar2(1) := 'N';
C_JOB_STATUS_SUCCEEDED       CONSTANT  varchar2(1) := 'S';
C_JOB_STATUS_FAILED          CONSTANT  varchar2(1) := 'F';

--
-- Job Status Description Constants (for AD_ZD_DDL_HANDLER.STATUS)
--
C_JOB_STATUS_NOT_EXEC_DESC   CONSTANT  varchar2(8)  := 'NOT-EXEC';
C_JOB_STATUS_RUNNING_DESC    CONSTANT  varchar2(8)  := 'RUNNING';
C_JOB_STATUS_SUCCESS_DESC    CONSTANT  varchar2(8)  := 'SUCCESS';
C_JOB_STATUS_FATAL_DESC      CONSTANT  varchar2(8)  := 'FATAL';
C_JOB_STATUS_ERROR_DESC      CONSTANT  varchar2(8)  := 'ERROR';
C_JOB_STATUS_WARNING_DESC    CONSTANT  varchar2(8)  := 'WARNING'; -- Success with Note


/* ------------------------------------------------------------------

                    Utility APIs

   -----------------------------------------------------------------*/


-- Returns the failed job count for specified phase
function GETFAILED_JOBS(
    X_PHASE             varchar2
   )  return number;


-- Returns the count of not_executed or running jobs in specified phase
function GET_NOT_EXECUTED_JOBS(X_PHASE varchar2) return number;


-- Updates "executed" flag from R/I to N
-- Used to reset jobs to runnable status for retry
procedure UPDATE_STATUS_R_TO_N(X_PHASE in varchar2 default null);

-- Recompiles critical AD objects, used to recover from self-invalidation
procedure RECOMPILE_OBJECTS;

-- Update Jobs Status (EXECUTED and STATUS column of AD_ZD_DDL_HANDLER)
procedure UPDATEjOB_STATUS(
    X_DDL_ID   in number,
    X_EXECUTED in varchar2,
    X_STATUS   in varchar2 default 'SUCCESS',
    X_ERROR    in CLOB default null);

-- Returns error severity ('WARNING', 'ERROR', 'FATAL')
function GET_ERROR_LEVEL(
    X_ERROR_CODE number,
    X_MESSAGE in varchar2 default null) return varchar2;

-- Return ordering index of phase
function GET_PHASE_ORDER(X_PHASE in varchar2) return number;



/* ------------------------------------------------------------------

                    Processing APIs

  ------------------------------------------------------------------*/

-- Worker Execute
--   Each parallel worker is started by calling this procedure.
--   Workers execute open AD_ZD_DDL_HANDLER jobs for the specified phase.
--
-- X_PHASE:          phase of work to process
-- X_MAX_WORKERS:    total number of parallel workers
-- X_CURRENT_WORKER: worker ID of this worker (1..x_max_worksers)
-- Note: X_MODE argument is unused, but retained for compatiblity
PROCEDURE EXECUTE(
    X_PHASE          in varchar2,
    X_MAX_WORKERS    in number,
    X_CURRENT_WORKER in number,
    X_MODE           in varchar2 default null);


-- Loads a SQL into AD_ZD_DDL_HANDLER
--  X_PHASE : Phase of SQL
--  X_SQL   : SQL or PL/SQL block
--  X_UNIQUE: If SQL should be checked for uniqueness within the given phase
--
-- NOTE: Currently this API does not validate if given "phase" is
--       a VALID phase or not.
PROCEDURE LOAD(
    X_PHASE   in varchar2,
    X_SQL     in clob,
    X_UNIQUE  in boolean default false);

-- Deletes from AD_ZD_DDL_HANDLER
-- Note: Phase is not passed, it deletes all records from AD_ZD_DDL_HANDLER
PROCEDURE CLEANUP(
    X_PHASE   in varchar2 default null);

 -- The below API deletes ALL the data from the table
 -- Please use/call with care
 --  PROCEDURE CLEANUP_ALL ;

end AD_ZD_PARALLEL_EXEC;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_PARALLEL_EXEC" as
/* $Header: ADZDPEXB.pls 120.33.12020000.18 2023/04/03 17:49:19 jwsmith ship $ */


/******************************************************************

          Private APIs (Not defined in SPEC )

*******************************************************************/

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



/*
** execute dynamic SQL statement
**   x_sql     - statement to execute
**   x_log_mod - calling module (for logging)
**   x_ignore  - ignore errors
*/
procedure EXEC(
  X_SQL          in clob,
  X_EDITION_NAME in varchar2,
  X_LOG_MOD      in varchar2,
  X_IGNORE       in boolean default false)
is
  L_CUR integer;
  L_RET integer;
begin

  --log(x_log_mod, 'STATEMENT', 'SQL(CLOB): '||dbms_lob.substr(x_sql, 3900));

  l_cur :=  dbms_sql.open_cursor(security_level=>2);
  dbms_sql.parse(l_cur, x_sql, dbms_sql.native, x_edition_name, null, false);
  l_ret := dbms_sql.execute(l_cur);
  dbms_sql.close_cursor(l_cur);
  commit;

exception

  when others then
    if dbms_sql.is_open(l_cur) then
      dbms_sql.close_cursor(l_cur);
    end if;
    if x_ignore then
      log(x_log_mod, 'STATEMENT', 'Ignored: '||SQLERRM);
    else
      log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM);
      raise;
    end if;

end exec;

--
-- Checks if given SQL is already exist?
function IS_DUPLICATE(X_PHASE    varchar2,
                      X_SQL_LOB  clob) return varchar2
is
  L_EXIST varchar2(1);
begin

  select 'Y' into l_exist from dual
  where exists
         ( select  null
           from   ad_zd_ddl_handler
           where  phase = x_phase
           and    dbms_lob.compare(sql_lob, x_sql_lob) = 0
           and    nvl(executed, 'N') <> 'S' );
  return 'Y';

exception
  when no_data_found then
    return 'N';

end IS_DUPLICATE;


--
-- Procedure to generate next batch id
--
FUNCTION GET_NEXT_DDL_ID RETURN NUMBER as
begin
  return ad_zd_ddl_handler_ddl_s.nextval;
end GET_NEXT_DDL_ID;




/********************************************************************

          Utility Functions / Procedures

*********************************************************************/


-- Returns the count of failed jobs.
--
-- If PHASE not supplied, it returns ALL failed jobs
function GETFAILED_JOBS( X_PHASE VARCHAR2)  return number
is
  L_FAILED_COUNT pls_integer;
begin

  select count(1) into l_failed_count
  from  ad_zd_ddl_handler
  where (x_phase is null or phase = x_phase)
    and executed = c_job_status_failed
    and nvl(status, 'ERROR') <> c_job_status_warning_desc;

  return l_failed_count;
end GETFAILED_JOBS;


-- Get status of a stored DDL.
-- TODO: remove, not needed
function GET_STATUS(X_DDL_ID in number) return varchar2
is
  L_STATUS varchar2(1) := 'S';
begin
  select executed into l_status
  from   ad_zd_ddl_handler
  where ddl_id = x_ddl_id;

  return l_status;
exception
  when no_data_found then
    return l_status;
end GET_STATUS;


-- This function return the index of the phase ORDER.
function GET_PHASE_ORDER(X_PHASE varchar2) return number
is
begin

  return
    ( case x_phase
        when C_PHASE_DROP_UNUSED_OBJECT then 1
        when C_PHASE_COPY_TYPE          then 2
        when C_PHASE_COMPILE_TYPE       then 3
        when C_PHASE_COPY_EVOLVED_TYPE  then 4
        when C_PHASE_FIX_COLUMN         then 5
        when C_PHASE_FIX_TYPE           then 6
        when C_PHASE_FIX_PUBLIC_SYNONYM then 7
        when C_PHASE_RECREATE_AQ_OBJECT then 8
        when C_PHASE_DROP_OBJECT        then 9
        when C_PHASE_ENABLE_EDITIONING  then 10
        when C_PHASE_UPGRADE_TABLE      then 11
        when C_PHASE_UPGRADE_SEED       then 12
        when C_PHASE_COLLECT_STATS      then 13
        when C_PHASE_UPGRADE_MVIEW      then 14
        else 0
      end );

end GET_PHASE_ORDER;


-- Returns the count of not_executed or running jobs
-- If PHASE not supplied, it returns ALL not-executed jobs
function GET_NOT_EXECUTED_JOBS(X_PHASE VARCHAR2)  return number
is
  L_NOT_EXECUTED_COUNT pls_integer;
begin
  select count(1) into l_not_executed_count
  from  ad_zd_ddl_handler
  where (x_phase is null or phase = x_phase)
    and executed in (c_job_status_not_executed, c_job_status_running);

  return l_not_executed_count;
end GET_NOT_EXECUTED_JOBS;


-- Updates DDL job status from I or R to N
-- Used when restarting a phase
procedure UPDATE_STATUS_R_TO_N(X_PHASE  varchar2)
is
  C_MODULE varchar2(127) := c_package||'update_status_r_to_n';
begin
  log(c_module, 'EVENT', 'Reset jobs from R (running) to N (not executed) for phase '||x_phase);

  update ad_zd_ddl_handler
    set  executed  = c_job_status_not_executed,
         execution_time = null
  where (x_phase is null or phase= x_phase)
    and executed = c_job_status_running;
  commit;
end UPDATE_STATUS_R_TO_N;


--
-- Procedure to recompile INVALID objects
--
procedure RECOMPILE_OBJECTS
is
  C_MODULE varchar2(80) := c_package||'recompile_objects';
begin
  for obj in
    ( select owner, object_name
      from   dba_invalid_objects
      where  object_name like 'AD_ZD%'
        and  object_type like 'PACKAGE%' )
  loop
    log(c_module, 'STATEMENT', 'Recompiling '||obj.owner||'.'||obj.object_name);
    exec('ALTER PACKAGE '||obj.owner||'.'||obj.object_name||' COMPILE BODY', c_module, true);
  end loop;
end recompile_objects;


-- Update job status
procedure UPDATEJOB_STATUS(
  X_DDL_ID   number,
  X_EXECUTED varchar2,
  X_STATUS   varchar2,
  X_ERROR    CLOB)
is
  C_MODULE varchar2(127) := c_package||'updatejob_status';
begin

  update ad_zd_ddl_handler
    set  executed = x_executed,
         status = nvl(x_status, c_job_status_success_desc),
         execution_time =current_timestamp,
         error = x_error
  where ddl_id=x_ddl_id;
end UPDATEJOB_STATUS;


-- Return Error level based on error code
--   'WARNING'  - ignorable error
--   'ERROR'    - real error, attention required
--   'FATAL'    - unexpected error, processing must exit
function GET_ERROR_LEVEL(X_ERROR_CODE number, X_MESSAGE varchar2) return varchar2
is
begin

  -- Special handling for 942: table or view does not exist
  -- other than DROP statement, return as ERROR
  if (x_error_code= -00942 and x_message is not null and
      not (regexp_instr(x_message, 'DROP[[:space:]]+TABLE', 1, 1, 0, 'i') > 0  or
            regexp_instr(x_message, 'DROP[[:space:]]+VIEW', 1, 1, 0, 'i') > 0 )) then
    return c_job_status_error_desc;
  end if;

  -- Special handling for 1418: index does not exist
  -- other than DROP statement, return as ERROR
  if (x_error_code= -01418 and x_message is not null and
      not (regexp_instr(x_message, 'DROP[[:space:]]+INDEX', 1, 1, 0, 'i') > 0)) then
    return c_job_status_error_desc;
  end if;

  -- Special handling for -12003: materialized view does not exist
  -- other than DROP statement, return as ERROR
  if (x_error_code= -12003 and x_message is not null and
      not (regexp_instr(x_message, 'DROP[[:space:]]+MATERIALIZED[[:space:]]+VIEW', 1, 1, 0, 'i') > 0)) then
    return c_job_status_error_desc;
  end if;

  return
    ( case x_error_code
        when -00942 then c_job_status_warning_desc /* table or view does not exist */
        when -01031 then c_job_status_warning_desc /* Insufficient Privileges */
        when -04043 then c_job_status_warning_desc /* object ... does not exist */
        when -24344 then c_job_status_warning_desc /* success_with_compile_err  */
        when -01418 then c_job_status_warning_desc /* index does not exist */
        when -12003 then c_job_status_warning_desc /* materialized view does not exist */
        when -02289 then c_job_status_warning_desc /* sequence does not exist */

        when -00600 then c_job_status_fatal_desc   /* Internal error code */
        when -01013 then c_job_status_fatal_desc   /* User cancel */
        when -01652 then c_job_status_fatal_desc   /* Unable to extend temp segment */
        when -01653 then c_job_status_fatal_desc   /* unable to extend table ... in tablespace ... */
        when -01654 then c_job_status_fatal_desc   /* unable to extend index ... in tablespace ... */
        when -03113 then c_job_status_fatal_desc   /* end-of-file on communication channel: */
        when -04030 then c_job_status_fatal_desc   /* out of process memory */
	when -04031 then c_job_status_fatal_desc   /* unable to allocate ... bytes of shared memory */
	when -07445 then c_job_status_fatal_desc   /* exception encountered: core dump */
        when -20978 then c_job_status_fatal_desc   /* Cannot drop a type with table dependents, EQ to ORA- */
        when -20979 then c_job_status_fatal_desc   /* User is not edition enabled */

        else c_job_status_error_desc
      end );

end GET_ERROR_LEVEL;




/******************************************************************

          Processing APIs

*******************************************************************/
-- Loads a SQL into AD_ZD_DDL_HANDLER
--   X_PHASE : Phase of SQL
--   X_SQL   : SQL or PL/SQL block
--   X_UNIQUE: If SQL should be checked for uniqueness within the given phase
--
-- NOTE: Currently this API does not validate if given "phase" is
--       a VALID phase or not.
PROCEDURE LOAD(
    X_PHASE   varchar2,
    X_SQL     clob,
    X_UNIQUE  boolean default false)
is
  C_MODULE        varchar2(127) := c_package||'load';
  L_DDL_ID number;
begin

  if (X_SQL is null or x_phase is null) then
    error(c_module, 'Phase and SQL cannot be null');
    return;
  end if;

  -- Supplied SQL should be checked for uniqueness?
  if(x_unique) then
    -- If already exists then don't do any thing.
    if(is_duplicate(x_phase, x_sql) = 'Y' ) then
      log(c_module, 'STATEMENT', 'SQL already exists, ignoring duplicate');
      return;
    end if;
  end if;

  -- If here, this SQL needs to be inserted.
  l_ddl_id := get_next_ddl_id;

  insert into ad_zd_ddl_handler(
    phase          ,
    ddl_id         ,
    sql_lob        ,
    executed       ,
    status         ,
    error          ,
    edition_name   ,
    execution_time)
  values(
    x_phase,
    l_ddl_id,
    x_sql,
    c_job_status_not_executed,
    c_job_status_not_exec_desc,
    null,
    null,
    null);

  commit;
end LOAD;



-- Delete from AD_ZD_DDL_HANDLER
PROCEDURE CLEANUP(X_PHASE  varchar2)
is
  C_MODULE        varchar2(127) := c_package||'cleanup';
begin
  log(c_module, 'STATEMENT', 'Cleanup DDL handler, phase='||nvl(x_phase, 'ALL'));

  --The new phases SYSTEM_CLEANUP,SYS_CLEANUP and XML_SCHEMA_CLEANUP have been introduced
	--for ebs system schema migration compliance
	--The ddls loaded with the phases SYSTEM_CLEANUP,SYS_CLEANUP and XML_SCHEMA_CLEANUP
  --will be handled by Bug#32573930(AD finalize patch)
	--Bug#32573930(AD finalize patch)will ensure to cleanup DDLS from AD_ZD_DDL_HANDLER
	--for the phases SYSTEM_CLEANUP,SYS_CLEANUP and XML_SCHEMA_CLEANUP

  delete from ad_zd_ddl_handler
  where ( ( x_phase is null and executed='S' ) or phase =x_phase );
  commit;

end CLEANUP;


-- Parallel Execute Worker - execute DDLs from ad_zd_ddl_handler table
--
--   X_PHASE          - phase of work to select and execute
--   X_MAX_WORKERS    - total number of parallel workers
--   X_CURRENT_WORKER - worker number for this thread [1..X_MAX_WORKERS]
--   X_STATUS         - unused, pass null for now
--
-- Note: work is evenly distributed across parallel workers by rownumber
procedure EXECUTE(
  X_PHASE          varchar2,
  X_MAX_WORKERS    number,
  X_CURRENT_WORKER number,
  X_MODE           varchar2)
is
  C_MODULE        varchar2(127) := c_package||'execute';
  L_WORKER_HDR    varchar2(127) :=  '['||x_phase||' '||x_max_workers||':'||x_current_worker||'] ';
  L_JOB_HDR       varchar2(250);
  L_ROWCOUNT      integer;
  L_CUR           integer;
  L_RET           number;
  L_ERROR         clob := null;

  -- Store temporary sub string from SQL_LOB to find DDL keywords
  L_SQL_SUBSTR    varchar2(1024);
  L_LONG_ERROR    varchar2(1024);
  L_ERROR_LEVEL   varchar2(30);

  L_STATUS        varchar2(15);

  cursor C_JOBS(P_PHASE varchar2)  is
    select mod((rownum-1), x_max_workers)+1 worker_id,
           row_id, ddl_id, sql_lob, status, edition_name, executed
    from
      ( select rowid row_id, ddl_id, sql_lob, status, edition_name, executed
        from   ad_zd_ddl_handler
        where  phase=p_phase
        order by ddl_id );

begin

  log(c_module, 'PROCEDURE', l_worker_hdr||'begin');

  dbms_application_info.set_module('AD_ZD', x_phase);

  -- Open cursor
  l_cur := dbms_sql.open_cursor;

  -- Loop over Jobs
  for job in c_jobs(x_phase) loop
    -- if job needs to be executed
    if (job.worker_id = x_current_worker and job.executed <> c_job_status_succeeded) then
      begin
        l_error   := null;
        l_job_hdr := l_worker_hdr||'ddl_id='||job.ddl_id||'] ';
        l_job_hdr := '['||x_phase||' '||x_max_workers||':'||x_current_worker||' ddl_id='||job.ddl_id||'] ';

        l_status := job.status;

        -- If job still needs to be executed, mark it as running;
        update ad_zd_ddl_handler
          set  executed = c_job_status_running
            ,  status = c_job_status_running_desc
            ,  execution_time = current_timestamp
            ,  error = NULL
        where rowid = job.row_id
          and executed not in (c_job_status_running, c_job_status_succeeded);

        l_rowcount := sql%rowcount;
        commit;

        ad_zd_ctx.set_ddl_id(job.ddl_id);
        -- If job did not need to be executed, skip to next job
        if l_rowcount = 0 then
          log(c_module, 'STATEMENT', l_job_hdr||'Skipping already executed row');
          continue;
        end if;

        -- Execute Job
        sys.dbms_sql.parse(l_cur, job.sql_lob, dbms_sql.native, job.edition_name, null, false);
        -- Note: explicit execute required for non-DDL statements
        -- TODO: gross
        l_sql_substr := upper(dbms_lob.substr(job.sql_lob, 10, 1));
        if (l_sql_substr is not null and not
               (instr(l_sql_substr, 'CREATE ')   > 0 OR
                instr(l_sql_substr, 'DROP ')     > 0 OR
                instr(l_sql_substr, 'ALTER ')    > 0 OR
                instr(l_sql_substr, 'TRUNCATE ') > 0 OR
                instr(l_sql_substr, 'RENAME ')   > 0 )) then
          l_ret := sys.dbms_sql.execute(l_cur);
        end if;

        if (l_status='ERROR') then
           log(c_module, 'STATEMENT', l_job_hdr||' Job has been succesfully executed.');
        end if;

        ad_zd_ctx.set_ddl_id;

        -- record success
        update ad_zd_ddl_handler
          set  executed = c_job_status_succeeded
            ,  status = c_job_status_success_desc
            ,  execution_time = current_timestamp
            ,  error = NULL
        where rowid = job.row_id;
        commit;

      exception
        when others then
          l_error := sqlerrm;
          l_long_error := dbms_lob.substr(l_error, 200, 1)
                            ||' SQL: '||dbms_lob.substr(job.sql_lob, 200, 1);

          <<error_handler>>
          case
            -- If FATAL error, exit worker
            when (get_error_level(sqlcode)=c_job_status_fatal_desc) then
              updatejob_status(job.ddl_id, c_job_status_failed, c_job_status_fatal_desc, l_error);
              error(c_module, l_job_hdr||'Fatal Error, exiting.  '||l_long_error);

            -- If AD_ZD packages are invalid, exit worker
            when (sqlcode= -04061  and
                  (instr(l_error, 'AD_ZD_TABLE' )  > 0 OR
                   instr(l_error, 'AD_ZD_MVIEW' )  > 0 OR
                   instr(l_error, 'AD_ZD_PREP' )   > 0 OR
                   instr(l_error, 'AD_ZD_SEED' )   > 0 OR
                   instr(l_error, 'AD_ZD_LOG' )    > 0 )) then
              updatejob_status(job.ddl_id, c_job_status_failed, c_job_status_fatal_desc, l_error);
              error(c_module, l_job_hdr||'AD_ZD Packages Invalid, exiting.  '||l_long_error);

            -- mark Job as errored and continue
            else
              l_error_level := get_error_level(sqlcode, l_long_error);
              if (l_error_level = c_job_status_warning_desc) then
                -- treat warning as success, but record warning message
                log(c_module, 'STATEMENT', l_job_hdr||'Ignored: '||l_long_error);
                updatejob_status(job.ddl_id, c_job_status_succeeded, c_job_status_success_desc, l_error);
              else
                -- record error status and message
                log(c_module, 'ERROR', l_job_hdr||l_long_error);
                updatejob_status(job.ddl_id, c_job_status_failed, l_error_level, l_error);
              end if;

          end case error_handler;
          ad_zd_ctx.set_ddl_id;
          commit;
      end;
    end if; /* Job needs to be executed */
  end loop; /* Job Loop */
  commit;

  if dbms_sql.is_open(l_cur) then
    dbms_sql.close_cursor(l_cur);
  end if;
  log(c_module, 'PROCEDURE', l_worker_hdr||'end' );

exception
  when others then
    ad_zd_ctx.set_ddl_id;
    if dbms_sql.is_open(l_cur) then
      dbms_sql.close_cursor(l_cur);
    end if;
    raise;
end EXECUTE;

end AD_ZD_PARALLEL_EXEC;
