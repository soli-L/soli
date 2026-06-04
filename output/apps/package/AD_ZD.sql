
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD" authid current_user as
/* $Header: ADZDXS.pls 120.25.12020000.23 2022/01/19 05:19:39 jwsmith ship $ */

/*
** Helper Functions
*/

procedure LOG(X_MODULE in varchar2, X_LOG_TYPE in varchar2, X_MESSAGE in varchar2 );
procedure ERROR(X_MODULE varchar2, X_MESSAGE varchar2);
procedure EXEC(X_SQL in varchar2, X_LOG_MOD in varchar2, X_IGNORE in boolean default false);
procedure EXEC(X_SQL in clob, X_LOG_MOD in varchar2, X_IGNORE in boolean default false);
procedure LOAD_DDL(X_PHASE in varchar2,  X_SQL In varchar2);

function  APPS_SCHEMA return varchar2;
function  APPLSYS_SCHEMA return varchar2;

function  IS_EDITIONS_ENABLED RETURN VARCHAR2;
function  GET_RUN_EDITION return VARCHAR2;
function  GET_EDITION(x_edition_type in varchar2 default NULL) RETURN VARCHAR2;
function  GET_EDITION_TYPE(x_edition_name in varchar2 default NULL) RETURN VARCHAR2;
function  CHECK_SPACE RETURN VARCHAR2;

function  CHECK_DBMS_ACTUALIZE_ALL RETURN number;
function  CHECK_DBMS_PATCHES_APPLIED RETURN number;
procedure SET_EDITION(x_edition_type in varchar2);

procedure CREATE_EDITION;
procedure RETIRE_EDITION(x_edition_type in varchar2);
procedure DROP_EDITION(x_edition_type in varchar2);
procedure DROP_OLD_EDITIONS;

procedure ALTER_LOGON_TRIGGER(X_STATUS in varchar2);
function  LOGON_TRIGGER_STATUS return varchar2;
procedure KILL_SESSIONS(X_EDITION_TYPE in varchar2);

/*
** Phase Control
*/

procedure PREPARE(X_MODE in varchar2 default NULL);
procedure FINALIZE(X_MODE in varchar2 default NULL);
procedure COMPILE(X_MODE in varchar2 default NULL);
procedure CUTOVER(X_MODE in varchar2 default NULL);
procedure CLEANUP(X_MODE in varchar2 default NULL);
procedure ABORT(X_MODE in varchar2 default NULL);

procedure GRANT_PRIVS( X_PERMISSIONS in VARCHAR2,
                       X_OBJECT_NAME in VARCHAR2,
                       X_GRANTEE     in VARCHAR2,
                       X_OPTIONS     in VARCHAR2 default NULL,
                       X_GRANT_TO_TABLE in BOOLEAN default TRUE);

procedure REVOKE_PRIVS( X_PERMISSIONS in VARCHAR2,
                       X_OBJECT_NAME in VARCHAR2,
                       X_GRANTEE     in VARCHAR2,
                       X_OPTIONS     in VARCHAR2 default NULL,
                       X_REVOKE_FROM_TABLE in BOOLEAN default TRUE);

/*
** Bug 22929709 - Procedure to actualize object in current edition
*/
procedure ACTUALIZE_OBJECT(X_OWNER       in varchar2,
                           X_OBJECT_NAME in varchar2,
                           X_OBJECT_TYPE in varchar2);

end;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD" as
/* $Header: ADZDXB.pls 120.52.12020000.98 2023/06/13 19:39:09 jwsmith ship $ */


/*
** --------------------------------------------------------------------
**    Helper Functions
** --------------------------------------------------------------------
*/


/*
** log message
*/
procedure LOG(X_MODULE varchar2, X_LOG_TYPE varchar2, X_MESSAGE varchar2) is
begin
  ad_zd_log.message(x_module, x_log_type, x_message);
end;

/*
** log error message and raise exception
*/
procedure ERROR(X_MODULE varchar2, X_MESSAGE varchar2) is
begin
  ad_zd_log.message(x_module, 'ERROR', x_message);
  raise_application_error(-20001, x_message);
end;



/*
** Execute constructed SQL statement (VARCHAR2 version)
**   X_SQL     - statement to execute
**   X_LOG_MOD - calling module (for logging)
**   X_IGNORE  - ignore errors
**
** Note: ignores "success with compilation error"
*/
procedure EXEC(X_SQL in varchar2, X_LOG_MOD in varchar2, X_IGNORE in boolean default false) is
  SUCCESS_WITH_COMPILATION_ERROR exception;
  pragma exception_init(success_with_compilation_error, -24344);

  DEADLOCK_DETECTED_ERROR exception;
  pragma exception_init(deadlock_detected_error, -00060);
begin

  log(x_log_mod, 'STATEMENT', 'SQL: '||x_sql);
  execute immediate x_sql;

exception
  when deadlock_detected_error then
    -- Bug 21670164 - raise deadlock error irrespective of x_ignore parameter
    log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM||', SQL: '||x_sql);
    raise;
  when success_with_compilation_error then
    -- ignore "success with compilation error"
    log(x_log_mod, 'STATEMENT', 'Ignored: '||SQLERRM);
  when others then
    -- ignore or raise other errors as requested
    if x_ignore then
      log(x_log_mod, 'STATEMENT', 'Ignored: '||SQLERRM);
    else
      log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM||', SQL: '||x_sql);
      raise;
    end if;
end;


/*
** Execute constructed SQL statement (LOB version)
**   X_SQL     - statement to execute
**   X_LOG_MOD - calling module (for logging)
**   X_IGNORE  - ignore errors
**
** Note: ignores "success with compilation error"
*/
procedure EXEC(X_SQL in clob, X_LOG_MOD in varchar2, X_IGNORE in boolean default false) is
  SUCCESS_WITH_COMPILATION_ERROR exception;
  pragma exception_init(success_with_compilation_error, -24344);

  DEADLOCK_DETECTED_ERROR exception;
  pragma exception_init(deadlock_detected_error, -00060);

  L_CUR integer;
  L_RET integer;
begin

  log(x_log_mod, 'STATEMENT', 'SQL(CLOB): '||dbms_lob.substr(x_sql, 3900));

  l_cur :=  dbms_sql.open_cursor;
  dbms_sql.parse(l_cur, x_sql, dbms_sql.native);
  l_ret := dbms_sql.execute(l_cur);
  dbms_sql.close_cursor(l_cur);

exception
  when deadlock_detected_error then
    -- Bug 21670164 - raise deadlock error irrespective of x_ignore parameter
    if dbms_sql.is_open(l_cur) then
      dbms_sql.close_cursor(l_cur);
    end if;
    log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM||', SQL: '||x_sql);
    raise;
  when success_with_compilation_error then
    if dbms_sql.is_open(l_cur) then
      dbms_sql.close_cursor(l_cur);
   end if;
    -- ignore "success with compilation error"
    log(x_log_mod, 'STATEMENT', 'Ignored: '||SQLERRM);
  when others then
    if dbms_sql.is_open(l_cur) then
      dbms_sql.close_cursor(l_cur);
    end if;
    -- ignore or raise other errors as requested
    if x_ignore then
      log(x_log_mod, 'STATEMENT', 'Ignored: '||SQLERRM);
    else
      log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM||', SQL(CLOB): '||dbms_lob.substr(x_sql, 3900));
      raise;
    end if;
end;


/*
** Store statement for deferred for execution
**   x_phase - execution phase where statement should be run
**   x_sql   - sql statement or pl/sql block to be executed.
*/
procedure LOAD_DDL(X_PHASE in varchar2,  X_SQL in varchar2) is
begin
  ad_zd_parallel_exec.load(
    x_phase => x_phase,
    x_sql   => to_clob(x_sql),
    x_unique => true); -- check for uniqueness
end;


/*
** Return APPS schema name
*/
function APPS_SCHEMA return varchar2 is
  L_SCHEMA varchar2(30);
begin
  select oracle_username into l_schema
  from   ebs_system.fnd_oracle_userid
  where  read_only_flag ='U';

  return l_schema;
end;


/*
** Return APPLSYS schema name
*/
function APPLSYS_SCHEMA return varchar2 is
  L_SCHEMA varchar2(30);
begin
  select oracle_username into l_schema
  from   ebs_system.fnd_oracle_userid
  where  read_only_flag ='E';

  return l_schema;
end;

/*
** Update LOGON trigger status.
   X_STATUS - 'ENABLE' or 'DISABLE' the trigger
*/
procedure ALTER_LOGON_TRIGGER(X_STATUS varchar2)
is
begin
  ebs_system.ad_zd_sys.alter_logon_trigger(x_status);
end;

/*
** Return LOGON trigger status [ENABLED | DISABLED]
*/
function LOGON_TRIGGER_STATUS return varchar2 is
  L_STATUS varchar2(8) := null;
  C_MODULE  varchar2(80) := 'ad.plsql.ad_zd.logon_trigger_status';
begin

  select status into l_status
  from  dba_triggers
  where owner='EBS_SYSTEM'
  and   trigger_name='EBS_LOGON';

  return l_status;
exception
  when no_data_found then
    error(c_module, 'EBS_SYSTEM.EBS_LOGON trigger does not exist');
end LOGON_TRIGGER_STATUS;


/*
** Is database editioned ('Y'/'N')
*/
function IS_EDITIONS_ENABLED return varchar2 is
  C_MODULE            varchar2(80) := 'ad.plsql.ad_zd.is_editions_enabled';
  L_EDITIONS_ENABLED  varchar2(30);
begin
  -- test if this is an editioned database, do nothing if not.
  select du.editions_enabled
  into   l_editions_enabled
  from   ebs_system.fnd_oracle_userid fou, dba_users du
  where  fou.read_only_flag = 'U'
    and  du.username = fou.oracle_username;

  return l_editions_enabled;
end;

/*
** Get Run Edition of database
*/
function GET_RUN_EDITION return varchar2 is
begin
  return ebs_system.ad_zd_sys.get_run_edition;
end;

/*
** Gets the name of the indicated edition type (NULL if none)
**   x_edition_type - type of edition to query
**     'RUN'     - current run edition
**     'PATCH'   - current patch edition
**     'OLD'     - old run edition (to be cleaned up after patch)
**     NULL      - current edition
*/
function GET_EDITION(x_edition_type in varchar2 default NULL) return varchar2 is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd.get_edition';
  L_RUN_EDITION     varchar2(30);
  L_EDITION         varchar2(30);
begin
  if x_edition_type is NULL then
     return sys_context('userenv', 'current_edition_name');
  end if;

  l_run_edition := get_run_edition;
  if x_edition_type = 'RUN' then
     return l_run_edition;
  end if;

  if x_edition_type = 'PATCH' then
     /* PATCH edition is always the child of the run edition */
     begin
       select aed.edition_name into l_edition
       from   all_editions AED
       where  aed.parent_edition_name = l_run_edition;
     exception
       when no_data_found then
          l_edition := NULL;
     end;
     return l_edition;
  end if;

  if x_edition_type = 'OLD' then
     /* OLD edition is always the parent of the run edition */
     begin
       select aed.parent_edition_name into l_edition
       from   all_editions AED
       where  aed.edition_name = l_run_edition;
     exception
       when no_data_found then
           l_edition := NULL;
     end;
     return l_edition;
  end if;

  log(c_module, 'ERROR', 'Invalid Edition Type: '||x_edition_type);
  return NULL;
end;


/*
** Sets the current edition based on type
**   x_edition_type - type of edition to set
**     'RUN'     - run edition
**     'PATCH'   - patch edition
**
** Note: this procedure will not take effect until the next top-level SQL call
*/
procedure SET_EDITION(x_edition_type in varchar2) is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd.set_edition';
  L_EDITION         varchar2(30);
begin
  l_edition := get_edition(x_edition_type);

  if (l_edition is not null) then
     log(c_module, 'STATEMENT', 'Setting current edition to '||l_edition);
     dbms_session.set_edition_deferred(l_edition);
  else
     error(c_module, 'Unable to set edition. Invalid edition type : '||x_edition_type);
  end if;
end;


/*
** Gets the edition type (NULL return means unused or non-existent edition)
**   x_edition - name of the edition
**     Pass NULL to find the current edition type
*/
function GET_EDITION_TYPE(x_edition_name in varchar2 default NULL) return varchar2 is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd.get_edition_type';
  L_EDITION_TYPE varchar2(8)  := NULL;
  L_EDITION      varchar2(30);
begin
  if (x_edition_name is NULL) then
     l_edition := sys_context('userenv', 'current_edition_name');
  else
     l_edition := upper(x_edition_name);
  end if;

  if l_edition = get_edition('RUN') then
    l_edition_type := 'RUN';
  elsif l_edition = get_edition('PATCH') then
    l_edition_type := 'PATCH';
  elsif l_edition = get_edition('OLD') then
    l_edition_type := 'OLD';
  end if;

  return l_edition_type;
end GET_EDITION_TYPE;


/*
** Check if there is enough free space in critical tablespaces
**    Free space requirements
**    SYSTEM tablespace: 25 GB free
**    APPS_TS_SEED tablespace: 5 GB free
**
**    RETURNS -  Y - Enough free space
**            -  N - Not enough free space
*/
function CHECK_SPACE return varchar2 is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd.check_space';
  L_ALLOCATED_BYTES number;
  L_FREE_BYTES      number;
  V_COUNT           number := 0;

  cursor C_FREE_SPACE(p_tablespace varchar2) is
    select df.bytes       allocated_bytes,
           sum(fs.bytes)  free_bytes
    from dba_free_space fs,
         (select sum(bytes) bytes
          from   dba_data_files
          where  tablespace_name = p_tablespace ) df
    where fs.tablespace_name   = p_tablespace
    group by df.bytes;

  type TS_NAMES_T is table of varchar2(30);
  type TS_FREE_T is table of number;

  TS_NAMES ts_names_t;   -- tablespace name list
  TS_FREE  ts_free_t;    -- tablespace minimum freespace list (gigabytes)
  TS_COUNT number;       -- number of tablespaces to check
begin

  -- tablespace requirements
  ts_names := new ts_names_t('SYSTEM', 'APPS_TS_SEED');
  ts_free  := new ts_free_t (25, 5);  -- gigabytes
  ts_count := 2;

  -- check each tablespace for required freespace
  for i in 1..ts_count loop

    select count(*) into v_count
    from   dba_data_files
    where tablespace_name = ts_names(i)
    and autoextensible = 'YES';

    if (v_count = 0) then
      open  c_free_space(ts_names(i));
      fetch c_free_space into l_allocated_bytes, l_free_bytes;
      close c_free_space;

      if l_free_bytes < (ts_free(i)*power(2, 30)) then
        log(c_module, 'WARNING',
            'Not enough free space in '||ts_names(i)||' tablespace. '||ts_free(i)||'GB free space required.');
        return 'N';
      end if;
    end if;

  end loop;

  return 'Y';
end check_space;



/*
** Drop Covered Objects
**
** Drop objects in old editions that have a replacement object in any newer edition.
*/
procedure DROP_COVERED_OBJECTS
IS
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd.drop_covered_objects';
  L_RUN_EDITION     varchar2(30) := get_run_edition;
  L_PASS            number;
  L_COBJ_DROPPED    number;
  L_COBJ_ERRORS     number;
  L_COBJ_CHECK      number;
  C_USER_CANCEL     exception;
    pragma exception_init(c_user_cancel, -1013);

  -- Covered Objects are
  --    actual objects in an Old Edition
  --    that have a replacement object in a newer edition

  type T_OBJ_REC is record
  ( edition_name    dba_objects_ae.edition_name%type,
    owner           dba_objects_ae.owner%type,
    object_type     dba_objects_ae.object_type%type,
    object_name     dba_objects_ae.object_name%type );

  type T_OBJ_TAB is table of t_obj_rec index by binary_integer;

  L_COBJS t_obj_tab;

  cov_objs SYS_REFCURSOR;

BEGIN
  log(c_module, 'PROCEDURE', 'begin');

  log(c_module, 'EVENT', 'Report: @ADZDSHOWCOBJS');

  -- repeat the procedure until no covered objects remain
  l_pass := 0;
  loop
    l_pass := l_pass+1;
    log(c_module, 'STATEMENT', 'Drop covered objects, pass #'||to_char(l_pass));

    -- Get covered objects to be dropped in this pass (to limit)
    -- This query only returns objects with no dependents
    --  and must be processed repeatedly to get all objects.
    open cov_objs for
      'select co.edition_name, co.owner, co.object_type, co.object_name '
   ||     'from dba_objects_ae co '
   ||    'where co.object_type <> ''NON-EXISTENT'' '
   ||      'and co.edition_name is not null '
   ||      'and co.edition_name < '''|| l_run_edition ||''' '
   ||      'and exists '
   ||            '( select null from dba_objects_ae ro /* replacement object */ '
   ||              'where ro.owner        = co.owner '
   ||              'and   ro.object_name  = co.object_name '
   ||              'and   ro.namespace    = co.namespace '
   ||              'and   ro.edition_name > co.edition_name '
   ||              'and   ro.edition_name <= '''|| l_run_edition ||''' ) '
   ||      'and not exists '
   ||            '( select null from sys.dependency$ dep /* dependents */ '
   ||              'where  dep.p_obj# = co.object_id ) '
   ||    'order by co.edition_name desc';

    fetch cov_objs bulk collect into l_cobjs limit 100000;
    close cov_objs;

    -- Drop covered objects
    l_cobj_dropped := 0;
    l_cobj_errors  := 0;
    for i in 1 .. l_cobjs.count loop
      begin
        ebs_system.ad_zd_sys.drop_covered_object(
            l_cobjs(i).owner, l_cobjs(i).object_name,
            l_cobjs(i).object_type, l_cobjs(i).edition_name);

        -- verify drop (this should not be necessary, but DB bugs can cause an infinite loop)
        select count(1) into l_cobj_check
        from  dba_objects_ae co
        where co.owner =  l_cobjs(i).owner
          and co.object_name = l_cobjs(i).object_name
          and co.object_type = l_cobjs(i).object_type
          and co.edition_name = l_cobjs(i).edition_name;

        if l_cobj_check > 0 then
          log(c_module, 'WARNING', 'Could not drop covered object '||
                '['||l_cobjs(i).edition_name||'] '||l_cobjs(i).owner||'.'||l_cobjs(i).object_name||' ('||l_cobjs(i).object_type||'): '||SQLERRM);
          l_cobj_errors := l_cobj_errors + 1;
        else
          l_cobj_dropped := l_cobj_dropped + 1;
        end if;

        if mod(l_cobj_dropped, 250) = 0 then
          log(c_module, 'STATEMENT', 'Drop covered objects, pass #'||to_char(l_pass)||' running, '||
                'dropped: '||to_char(l_cobj_dropped)||', errors: '||l_cobj_errors);
        end if;
      exception
        when c_user_cancel then
          error(c_module, 'Cleanup cancelled');
        when others then
          log(c_module, 'WARNING', 'Could not drop covered object '||
                '['||l_cobjs(i).edition_name||'] '||l_cobjs(i).owner||'.'||l_cobjs(i).object_name||' ('||l_cobjs(i).object_type||'): '||SQLERRM);

          l_cobj_errors := l_cobj_errors + 1;
      end;
    end loop;

    log(c_module, 'EVENT', 'Drop covered objects, pass #'||to_char(l_pass)||' complete, '||
          'dropped: '||to_char(l_cobj_dropped)||', errors: '||l_cobj_errors );
    exit when l_cobj_dropped = 0;
  end loop;

  if l_cobj_errors > 0 then
    log(c_module, 'WARNING', 'Could not remove all covered objects');
  end if;

  commit;
  log(c_module, 'PROCEDURE', 'end');
end;


/*
** Drop Covered Objects - Alternate method
**
** Drop objects in old editions that have a replacement object in any newer edition.
** This alternate method works around database bugs by simply executing a drop
** command in every parent edition of the actual object, regardless of whether
** anything appears to exist in that edition.
*/
procedure DROP_COVERED_OBJECTS_ALT
IS
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd.drop_covered_objects_alt';
  C_USER_CANCEL     exception;
    pragma exception_init(c_user_cancel, -1013);
  L_RUN_EDITION     varchar2(30) := get_run_edition;

  -- Actual objects visible in the run edition that have a covered object
  cursor C_ACTUALS_WITH_COVERED(X_RUN_EDITION varchar2) is
    select ao.owner, ao.object_name, ao.object_type, ao.namespace, ao.edition_name
    from  dba_objects ao /* actual objects */
    where ao.edition_name is not null
      and exists
            ( select null from dba_objects_ae co /* covered object */
              where co.owner        = ao.owner
              and   co.object_name  = ao.object_name
              and   co.namespace    = ao.namespace
              and   co.object_type  <> 'NON-EXISTENT'
              and   co.edition_name < ao.edition_name
              and   co.edition_name < x_run_edition )
    order by ao.owner, ao.object_name, ao.object_type;

  type T_OBJ_REC is record
    ( edition_name    dba_objects_ae.edition_name%type);

  type T_OBJ_TAB is table of t_obj_rec index by binary_integer;

  L_COBJS t_obj_tab;

  cov_objs SYS_REFCURSOR;

begin
  log(c_module, 'PROCEDURE', 'begin');

  for arec in c_actuals_with_covered(l_run_edition) loop
      -- Parent Editions for an editioned object
      -- cursor C_PARENT_EDITIONS(X_OWNER varchar2, X_OBJECT_NAME varchar2,
      --                         X_NAMESPACE varchar2, X_EDITION_NAME varchar2) is
      open cov_objs for
       'select * from '
||       '( select '
||           'eusr.edition_name edition_name '
||           '/*, obj.type# o_type, bobj.type# b_type*/ '
||         'from '
||             'sys.obj$ obj /* actual or stub object */ '
||           ', sys.obj$ bobj /* base object for stub object */ '
||           ', ( select '
||                   'xusr.user# '
||                 ', xusr.ext_username user_name '
||                 ', ed.name edition_name '
||               'from '
||                   '(select * from sys.user$ where type# = 2) xusr '
||                 ', (select * from sys.obj$ where owner# = 0 and type# = 57) ed '
||               'where xusr.spare2 = ed.obj# '
||               'union '
||               'select '
||                   'busr.user# '
||                 ', busr.name user_name '
||                 ', ''ORA$BASE'' edition_name '
||               'from '
||                   '(select * from sys.user$ where type# = 1 or user# = 1) busr '
||             ') eusr '
||         'where eusr.user_name = :x_owner '
||           'and obj.owner#    = eusr.user# '
||           'and obj.name      = :x_object_name '
||           'and obj.namespace = :x_namespace '
||           'and obj.remoteowner is null '
||           'and bobj.obj#(+) = obj.dataobj# '
||       ') x '
||     'where edition_name < :x_edition_name '
||     'order by edition_name DESC '
        using arec.owner, arec.object_name, arec.namespace, arec.edition_name;
      fetch cov_objs bulk collect into l_cobjs limit 100000;
      close cov_objs;
   for i in 1 .. l_cobjs.count loop
      begin
        log(c_module, 'STATEMENT', 'Dropping covered object: '||
                '['||l_cobjs(i).edition_name||'] '||arec.owner||'.'||arec.object_name||' ('||arec.object_type||')');
        ebs_system.ad_zd_sys.drop_covered_object(arec.owner, arec.object_name, arec.object_type, l_cobjs(i).edition_name);
      exception
        when c_user_cancel then
          error(c_module, 'Cleanup cancelled');
        when others then
          log(c_module, 'ERROR', 'Could not drop covered object '||
                '['||l_cobjs(i).edition_name||'] '||arec.owner||'.'||arec.object_name||' ('||arec.object_type||'): '||SQLERRM);
      end;
    end loop;
  end loop;

  log(c_module, 'PROCEDURE', 'end');
end;


/*
** --------------------------------------------------------------------
**    Edition Control
** --------------------------------------------------------------------
*/


/*
** Create new database Edition as child of current edition
**
** Note: New edition names are expected to sort after old edition names.
*/
procedure CREATE_EDITION is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd.create_edition';
  L_EDITION     varchar2(30);
  L_CUR_EDITION varchar2(30);
  L_DT_FMT    varchar2(30) := 'YYYYMMDD_HH24MI';
begin

  -- must not be an existing patch edition
  if ad_zd.get_edition('PATCH') is not null then
    error(c_module, 'Patch Edition already exists');
  end if;

  -- Generate new edition name
  l_cur_edition := ad_zd.get_edition('RUN');
  l_edition := 'V_'||to_char(SYSDATE, l_dt_fmt);

  if greatest(l_edition,l_cur_edition) = l_cur_edition then
    l_edition := 'V_'||to_char(to_date(substr(l_cur_edition,3),l_dt_fmt)+1/(24*60),l_dt_fmt);
  end if;

  log(c_module, 'EVENT', 'Create Edition : '||l_edition);
  exec('create edition '||l_edition, c_module);
  exec('grant use on edition '||l_edition||' to PUBLIC', c_module);

end;


/*
** Retire Edition
**   Revoke grants to USE edition, if it exists
**   x_edition_type - type of edition to retire
**     'PATCH'   - patch edition
**     'OLD'     - old edition
*/
procedure RETIRE_EDITION(X_EDITION_TYPE in varchar2) is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd.retire_edition';
  L_EDITION     varchar2(30);
  L_GRANTOR     varchar2(30);
  L_OWNER       varchar2(30) := 'SYS';
begin

  -- get edition and validate
  l_edition := ad_zd.get_edition(x_edition_type);
  if (l_edition is null) then
    log(c_module, 'STATEMENT', 'Edition Type '||nvl(x_edition_type, 'NULL')||' does not exist.');
    return;
  end if;
  if (l_edition = get_edition('RUN')) then
    error(c_module, 'Cannot retire RUN edition.');
  end if;

  -- do it
  begin
    log(c_module, 'EVENT', 'Retire Edition: '||l_edition);
    exec('revoke use on edition '||l_edition||' from PUBLIC', c_module);
  exception
    when others then
      log(c_module, 'STATEMENT', 'Edition '||l_edition||' is already retired');
  end;

end;

/*
** Drop old editions 19C implementation
**  Bug 31070005, jwsmith
*/
procedure DROP_OLD_EDITIONS_ST (X_MODE in varchar2 default NULL) is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd.drop_old_editions_st';
  TYPE L_EDITION_LIST IS TABLE of dba_editions.edition_name%type;
  EDITION_LIST      l_edition_list := l_edition_list();
  L_INDEX_NOT_EMPTY number := 0;

  -- For 19c add the check for dba_editions.usable = YES
  -- Check this flag to prevent calling the drop edition again when we have already dropped it.
  -- In 19c the DB marks the edition dba_editions.usable = NO when drop edition is called
  cursor C_OLD_EDITIONS_19C is
    select oe.edition_name
    from dba_editions oe, database_properties re
    where re.property_name = 'DEFAULT_EDITION'
      and oe.edition_name < re.property_value
      and oe.usable = 'YES'
    order by oe.edition_name;

begin
  log(c_module, 'PROCEDURE', '19c Implementation - begin: no parameter(s)');

  open c_old_editions_19C;
  fetch c_old_editions_19C bulk collect into edition_list;
  close c_old_editions_19C;

  if edition_list.COUNT > 0 then

    for l_index in edition_list.FIRST .. edition_list.LAST loop

      -- In 19C no need to test if edition is empty of objects
      log(c_module,'STATEMENT','19c Implementation - Drop edition');
      -- drop empty old edition
      begin
        ebs_system.ad_zd_sys.drop_edition(edition_list(l_index));

      exception
        when others then
          log(c_module, 'WARNING', '19C implementation - Could not drop edition '||edition_list(l_index) || SQLERRM);
      end;

    end loop;
  end if;

  log(c_module, 'PROCEDURE', 'end');
end;


/*
** Drop old editions which have no actual objects
** 11gR2 and 12.1.0.2 implementation
*/
procedure DROP_OLD_EDITIONS_AD is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd.drop_old_editions_ad';
  L_EMPTY           varchar2(2);
  L_COUNT           number := 0;
  C_EMPTY_EDITION   exception;
  TYPE L_EDITION_LIST IS TABLE of dba_editions.edition_name%type;
  EDITION_LIST      l_edition_list := l_edition_list();
  L_INDEX_NOT_EMPTY number := 0;

  -- Old Editions
  cursor C_OLD_EDITIONS is
    select oe.edition_name
    from dba_editions oe, database_properties re
    where re.property_name = 'DEFAULT_EDITION'
      and oe.edition_name < re.property_value
    order by oe.edition_name;
begin

  log(c_module, 'PROCEDURE', 'begin: no parameter(s)');

  open c_old_editions;
  fetch c_old_editions bulk collect into edition_list;
  close c_old_editions;

  if edition_list.COUNT = 0 then
    raise c_empty_edition;
  end if;
  for l_index in edition_list.FIRST .. edition_list.LAST loop
    -- test if edition is empty of objects
    begin
      select 'N' into l_empty
      from dba_objects_ae obj
      where obj.edition_name = edition_list(l_index)
        and obj.object_type <> 'NON-EXISTENT'
        and rownum = 1;
    exception
      when no_data_found then
        l_empty := 'Y';
    end;
    if l_empty = 'N' then
       l_index_not_empty := l_index;
    end if;
    exit when l_empty = 'N';

    -- drop empty old edition
    begin
      ebs_system.ad_zd_sys.drop_edition(edition_list(l_index));
    exception
      when others then
        log(c_module, 'WARNING', 'Could not drop empty edition '||edition_list(l_index) || SQLERRM);
        exit;
    end;
  end loop;
  if (l_empty = 'N') then
    log(c_module, 'STATEMENT', 'Drop old editions stopped at edition '||edition_list(l_index_not_empty) || ' because edition contains actualized objects.');
  end if;
  exception
      when c_empty_edition then
        log(c_module, 'STATEMENT', 'No old edition to drop');
      when others then
        null;

  log(c_module, 'PROCEDURE', 'end');
end;


/*
** Drop old editions which have no actual objects
**  For 11gR2 and 12.1.0.2 implementation use drop_old_editions_ad
**  For 19c and later implementation use ad_zd.drop_old_editions_st
**
*/
procedure DROP_OLD_EDITIONS is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd.drop_old_editions';
  L_CALL_AD_VERSION BOOLEAN default TRUE;
begin
  log(c_module, 'PROCEDURE', 'begin');
  l_call_ad_version := TRUE;
$if DBMS_DB_VERSION.VERSION >= 19 $then
  -- Database version 19 or later
  -- Before we use the Native Cleanup, we need to verify all DB patches are in place
  -- This check is only valid if we are on 19c or later and checks that the minimum 19.13 ru is present.
  -- Since drop_old_editions is a public interface, we also need the check here as well as in
  -- ad_zd.cleanup
  if ((CHECK_DBMS_PATCHES_APPLIED = 1) or
      (ad_db_utils.is_adb = 'Y')) then
      log(c_module,'STATEMENT','19c Implementation - Always drop OLD editions');
      log(c_module,'STATEMENT','19c Implementation - Call drop_old_editions_st.');
      l_call_ad_version := FALSE;
      ad_zd.drop_old_editions_st('FULL');
  end if;
$end

if (l_call_ad_version) then
    ad_zd.drop_old_editions_ad;
end if;
  log(c_module, 'PROCEDURE', 'end');
end;

/*
** Drop unwanted database edition
**   x_edition_type - type of edition to drop
**     'PATCH'   - current patch edition
**     'OLD'     - old run edition (to be cleaned up after patch)
*/
procedure DROP_EDITION(x_edition_type in varchar2) is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd.drop_edition';
  L_EDITION     varchar2(30);
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_edition_type);

  -- get edition and validate
  l_edition := ad_zd.get_edition(x_edition_type);
  if (l_edition is null) then
    error(c_module, 'Edition Type '||nvl(x_edition_type, 'NULL')||' does not exist.');
  end if;
  if (l_edition = get_edition('RUN')) then
    error(c_module, 'Cannot drop RUN edition.');
  end if;

  -- do it
  if x_edition_type = 'OLD' then
    ad_zd.drop_old_editions;
  else
    ebs_system.ad_zd_sys.drop_edition(l_edition);
  end if;

  log(c_module, 'PROCEDURE', 'end');
end;


/*
** --------------------------------------------------------------------
**    Phase Control
** --------------------------------------------------------------------
*/


/*
** Prepare System (create Patch Edition)
**   X_MODE - unused
*/
procedure PREPARE(X_MODE in varchar2 default NULL) is
  C_MODULE         varchar2(80) := 'ad.plsql.ad_zd.prepare';
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_mode);
  ad_zd_log.clear;

  -- Clear ALL ddls
  ad_zd_parallel_exec.cleanup;

  -- TODO: verify EBS_LOGON trigger exists and is enabled.

  -- Check freespace: does not work
  /*
  if check_space = 'N' then
     log(c_module, 'WARNING', 'Not Enough free space');
  end if;
  */

  log(c_module, 'EVENT', 'Prepare System');

  -- Create Patch Edition
  ad_zd.create_edition;

  log(c_module, 'PROCEDURE', 'end');
  -- commit;
end;


/*
** Finalize System (step 1 of finalize process)
**   X_MODE - controls finalize processing
**     QUICK - standard finalize processing (default)
**     FULL  - recompute dictionary stats
*/
procedure FINALIZE(X_MODE in varchar2 default NULL) is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd.finalize';
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_mode);

  if (get_edition_type = 'RUN') and (get_edition('PATCH') is not null) then
     error(c_module, 'Finalize can only be run from the Patch Edition.');
  end if;

  log(c_module, 'EVENT', 'Finalize System');

  -- Finalize sub components
  ad_zd_table.finalize;
  ad_zd_mview.finalize;

  -- Execute stored FINALIZE DDL
  log(c_module, 'EVENT', 'Executing FINALIZE actions');
  ad_zd_parallel_exec.execute('FINALIZE', 1, 1, NULL);

  --For ADB-D instances Skipping the gather schema statistics
  --until we get a fix for AD Bug#33016624 from ST
  if ad_db_utils.is_adb = 'N' then
    -- Gather SYS stats
    log(c_module, 'STATEMENT', 'Gather stats for SYS');
    dbms_stats.gather_schema_stats(
        'SYS',
        options=>'GATHER STALE',
        estimate_percent => DBMS_STATS.AUTO_SAMPLE_SIZE,
        method_opt => 'FOR ALL COLUMNS SIZE AUTO',
        cascade => TRUE);
  end if;

  if (x_mode = 'FULL') then
    null; -- TODO: gather stats on patched tables
  end if;

  log(c_module, 'PROCEDURE', 'end');
end;

/*
** Compile System (step 2 of finialize process)
**   must be called as a top level command
**
** X_MODE: NULL     - compile current edition
**         'FULL'   - compile entire system (all editions)
**         'REPEAT' - compile current edition until invalid count stops decreasing
*/
procedure COMPILE(X_MODE in varchar2 default NULL) is
  C_MODULE        varchar2(80) := 'ad.plsql.ad_zd.compile';
  PREV_COUNT      number;
  CUR_COUNT       number;
  NOT_IMPLEMENTED exception;   pragma exception_init(not_implemented, -6550);
begin
  -- compile according to specified mode
  if x_mode = 'REPEAT' then
    log(c_module, 'EVENT', 'Compile Edition: '||get_edition||', In a Loop');
    prev_count := 999999999;
    loop
      select count(*) into cur_count
      from ad_objects
      where status='INVALID';
      exit when cur_count = 0 or cur_count = prev_count;
      compile;
      prev_count := cur_count;
    end loop;
  elsif x_mode = 'FULL' then
    log(c_module, 'EVENT', 'Compile System');
    execute immediate 'begin sys.utl_recomp.recomp_parallel; end;';
  else
    begin
      log(c_module, 'EVENT', 'Compile Edition: '||get_edition);
      execute immediate 'begin sys.utl_recomp.recomp_parallel(flags => sys.utl_recomp.new_edition); end;';
    exception
      when not_implemented then
        log(c_module, 'STATEMENT', 'Note: Edition-specific compilation not supported on this system.');
        compile('FULL');
    end;
  end if;
end;

/*
** Disable the system logon trigger
**
*/
procedure DISABLE_SYSTEM_LOGON_TRIGGER is
begin
  -- Disable the system.ebs_logon trigger if exists and in enabled mode.
  -- Call it dynamically
  declare
    l_exists varchar(20);
  begin
     select 'x' into l_exists from dba_triggers
     where trigger_name='EBS_LOGON' and owner='SYSTEM' and status='ENABLED';
     -- NEVER CHANGE SYS TO EBS_SYSTEM IN THE BELOW LINE
     execute immediate 'begin sys.ad_zd_sys.alter_logon_trigger(''DISABLE''); end;';
  exception
    when no_data_found then
      null;
    when others then
       raise;
  end;
end;

/*
** Cutover to patch edition
**
** X_MODE - indicates how to process cutover actions
**   (default) - execute cutover actions inline
**   'QUICK'   - assume cutover actions were processed externally
**               by parallel workers, just do edition cutover
**
** Note: this API now supports running in the Run Edition when
** there is no Patch Edition.  This is to support "developer mode",
** which lets you execute cutover actions without actually changing
** editions.
*/
procedure CUTOVER(X_MODE in varchar2 default NULL) is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd.cutover';
  L_EDITION     varchar2(30);
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_mode);

  -- If there is a Patch Edition, then we must be in it
  l_edition := ad_zd.get_edition('PATCH');
  if (l_edition is not null) and (l_edition <> sys_context('userenv', 'current_edition_name')) then
    error(c_module, 'Cutover can only be run from the Patch Edition.');
  end if;

  -- Execute stored FINALIZE DDL
  log(c_module, 'EVENT', 'Executing FINALIZE actions (second pass)');
  ad_zd_parallel_exec.execute('FINALIZE', 1, 1, NULL);

  log(c_module, 'EVENT', 'Cutover System');

  -- Execute cutover actions
  if (x_mode is null) then
    -- Execute stored CUTOVER DDL
    log(c_module, 'EVENT', 'Executing CUTOVER actions');
    ad_zd_parallel_exec.execute('CUTOVER', 1, 1, NULL);

    -- Cutover sub-components
    ad_zd_seed.cutover;
    ad_zd_mview.cutover(x_execute => 1);
  end if;

  -- switch default edition to patch edition
  if (l_edition is not null) then
    log(c_module, 'EVENT', 'Switching to Patch Edition');
    exec('alter database default edition = '||l_edition, c_module);
    sys.dbms_result_cache.invalidate('SYS', 'DATABASE_PROPERTIES');
  end if;

  -- Disable the system.ebs_logon trigger if exists
  disable_system_logon_trigger;


  -- Bug 27595967, jwsmith, Remove abort rows as ABORT is no longer valid after cutover
  ad_zd_parallel_exec.cleanup('ABORT');

  -- Kill Old Sessions
  log(c_module, 'EVENT', 'Killing old sessions');
  kill_sessions('OLD');

  log(c_module, 'PROCEDURE', 'end');
end;


/*
** Cleanup obsolete objects and data
**
** X_MODE
**   'QUICK'  - minimal cleanup required to start a new patching cycle
**    NULL    - standard cleanup, includes drop covered objects
**   'FULL'   - also marks unused columns (todo: drop old editions)
*/
procedure CLEANUP(X_MODE in varchar2 default NULL) is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd.cleanup';
  L_EDITION     varchar2(30);
  L_CALL_AD_VERSION BOOLEAN default TRUE;
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_mode);

  l_edition := ad_zd.get_edition('RUN');
  if (l_edition <> sys_context('userenv', 'current_edition_name'))  then
    error(c_module, 'Cleanup can only be run from the Run Edition');
  end if;

  if (ad_zd.get_edition('PATCH') is not null) then
    error(c_module, 'Cannot Cleanup while Patch Edition exists');
  end if;

  log(c_module, 'EVENT', 'Cleanup System');

--
-- if 19c or above then drop covered objects is handled
-- in drop edition statement
-- Bug 31070005 jwsmith Uptake Native Cleanup
-- Note: Once moved to Native Cleanup, you can no longer use the old implementation
-- as the editions are marked unused by the DB once a drop statement is issued.
-- New: 8/10/22 Backout Native cleanup uptake for on-premise due to new ST bug
-- Bug 34480024 - CREATE EDITION AND DROP EDITION IS BLOCKED BY CLEANUP_NON_EXIST_OBJ
 l_call_ad_version := TRUE;
$if DBMS_DB_VERSION.VERSION >= 19 $then
  -- Database version 19 or later
  -- Before we use the Native Cleanup, we need to verify all DB patches are in place
  -- This check is only valid if we are on 19c or later and checks that the minimum 19.13 ru is present.
  if ((CHECK_DBMS_PATCHES_APPLIED = 1) or
      (ad_db_utils.is_adb = 'Y')) then
     log(c_module,'STATEMENT','19c Implementation - Drop covered objects deferred to Native Cleanup Background Job');
     l_call_ad_version := FALSE;
  end if;
$end

if (l_call_ad_version) then
   -- old implementation
   -- Drop covered objects, except in QUICK mode
   log(c_module,'STATEMENT','Not using native cleanup as not ADB-D.');
   if (nvl(x_mode,'STANDARD') <> 'QUICK') then
     log(c_module, 'EVENT', 'Drop Covered Objects');
     drop_covered_objects;
   end if;

   -- In FULL cleanup, Drop remaining covered objects with alternate algorithm
   -- This method works around database bugs that can prevent dropping of old editions
   if (x_mode = 'FULL') then
     log(c_module, 'EVENT', 'Drop Covered Objects - alternate method');
     drop_covered_objects_alt;
   end if;
end if;

  -- Execute stored CLEANUP DDL
  ad_zd_parallel_exec.execute('CLEANUP', 1, 1, NULL);

  -- Cleanup sub-components
  ad_zd_seed.cleanup;
  ad_zd_table.cleanup(NULL, NULL, x_mode);

  -- remove stored DDLs which should no longer be used
  ad_zd_parallel_exec.cleanup('FINALIZE');
  ad_zd_parallel_exec.cleanup('CUTOVER');
  ad_zd_parallel_exec.cleanup('ABORT');

-- if 19c native cleanup then no need to check if cleanup mode is full
-- Bug 31070005 jwsmith
if (l_call_ad_version) then
  if ( x_mode = 'FULL') then
    ad_zd.drop_old_editions_ad();
  end if;
else
  -- Database version 19 or later
  -- No need to check for DB RU 19.13 again as we already checked in this routine.
     log(c_module,'STATEMENT','19c Implementation - Always drop OLD editions');
     ad_zd.drop_old_editions_st(x_mode);
end if;
  log(c_module, 'PROCEDURE', 'end');
end;


/*
** Abort patch edition
**
** X_MODE - unused
*/
procedure ABORT(X_MODE in varchar2 default null) is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd.abort';
  L_EDITION     varchar2(30);
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_mode);

  -- Must have Patch Edition
  l_edition := ad_zd.get_edition('PATCH');
  if (l_edition is null)  then
    error(c_module, 'There is no Patch Edition to abort.');
  end if;
  -- Must be in Run Edition
  if (get_edition_type <> 'RUN') then
    error(c_module, 'Abort can only be run from the Run Edition.');
  end if;

  -- Kill sessions connected to patch edition, other wise cannot drop it.
  log(c_module, 'EVENT', 'Killing Patch Edition Sessions');
  kill_sessions('PATCH');

  log(c_module, 'EVENT', 'Aborting Patch Edition');
  -- Cleanup deferred DDLs that are no longer relevant
  ad_zd_parallel_exec.cleanup('CUTOVER');
  ad_zd_parallel_exec.cleanup('CLEANUP');

  -- Undo any effectively editioned changes
  ad_zd_seed.abort;
  ad_zd_table.abort;

  -- Add product specific APIs
  exec('begin fnd_conc.cancel_patch_requests; end;', c_module, true);

  -- Drop Pach Edition
  ad_zd.retire_edition('PATCH');
  -- per bug 16237350 - we need to kill again right before the drop edition
  log(c_module, 'EVENT', 'Killing Patch Edition Sessions');
  kill_sessions('PATCH');
  -- end fix for bug 16237350
  ad_zd.drop_edition('PATCH');

  if (nvl(x_mode,0) <> 'ADOP') then
  -- Execute stored ABORT DDL
    ad_zd_parallel_exec.execute('ABORT', 1, 1, NULL);
  end if;

  log(c_module, 'PROCEDURE', 'end');
end;

/*
** Kill sessions
**/
procedure KILL_SESSIONS(x_edition_type VARCHAR2) is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd.kill_sessions';

  -- Sessions of editions specified by parameter
  cursor C_KILL is
  select
    'alter system kill session '||''''||s.sid||','||s.serial#||',@'||s.inst_id||'''' kill
      from
          gv$session s
        , gv$process p
        , dba_objects_ae e
        , dba_users u
       where s.type <> 'BACKGROUND'
         and p.addr    = s.paddr
         and p.inst_id = s.inst_id
         and e.object_id = s.session_edition_id
         and e.object_name = ad_zd.get_edition(x_edition_type)
         and e.object_type = 'EDITION'
         and u.username = s.username
         and u.editions_enabled = 'Y';
begin
  log(c_module, 'PROCEDURE', 'begin: ');

  for srec in c_kill loop
    exec(srec.kill, c_module, true);
  end loop;

  log(c_module, 'PROCEDURE', 'end');
end;

/*
*  Give grants on objects in APPS schema
*  X_GRANT_TO_TABLE:
*    - This parameter is applicable only when the target object on which
*      the grant needed is EV.
*    - This parameter decides whether permission to be granted on
*      the underlying table also.
*        TRUE(default): Grant permission on EV and its underlying table
*        FALSE:         Grant permission to EV only.
*/
procedure GRANT_PRIVS(
  X_PERMISSIONS in VARCHAR2,
  X_OBJECT_NAME in VARCHAR2,
  X_GRANTEE in VARCHAR2,
  X_OPTIONS in VARCHAR2 default NULL,
  X_GRANT_TO_TABLE in BOOLEAN default TRUE)
is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd.grant_privs';
  L_APPS_SCHEMA  varchar2(30);
  L_OBJECT_TYPE  varchar2(30);
  L_OBJECT_OWNER varchar2(30);
  L_OBJECT_NAME  varchar2(30);
  L_CURSOR       integer;
  L_STMT         varchar2(1000);
  L_EDITION_NAME varchar2(30);
  L_ERRMSG       varchar2(2000) := '';
  L_TABLE_NAME   varchar2(30);
  L_PERMISSIONS  VARCHAR2(400);
begin

  l_object_owner := ad_zd.apps_schema;
  l_object_name  := x_object_name;
  l_permissions  := x_permissions;

  -- Find object type and edition (owned by APPS in primary namespace)
  begin
    select object_type, edition_name
    into   l_object_type, l_edition_name
    from   dba_objects
    where  owner       = l_object_owner
      and  object_name = l_object_name
      and  object_type NOT LIKE '%PARTITION'
      and  namespace   = 1;
  exception
    when no_data_found then
      l_errmsg := l_object_owner||'.'||l_object_name||' does not exist';
      raise;
  end;

  -- loop to resolve synonyms
  while (l_object_type = 'SYNONYM')
  loop
    begin
      select syn.table_owner, syn.table_name, obj.object_type, obj.edition_name
      into   l_object_owner, l_object_name, l_object_type, l_edition_name
      from   dba_synonyms syn, dba_objects obj
      where  syn.owner        = l_object_owner
        and  syn.synonym_name = l_object_name
        and  obj.owner        = syn.table_owner
        and  obj.object_name  = syn.table_name
        and  obj.object_type NOT LIKE '%PARTITION'
        and  obj.namespace    = 1;
    exception
      when no_data_found then
        l_errmsg := 'Synonym '||x_object_name||' pointing to a non-existent object';
        raise;
    end;
  end loop;

  -- If target object is an EV then grant on table as well
  if (x_grant_to_table and l_object_type='VIEW' and l_object_name like '%#')
  then
    l_table_name := ad_zd_table.ev_table(l_object_owner, l_object_name);

    l_permissions:=regexp_replace(x_permissions,'(^|,)[[:space:]]*UNDER[[:space:]]*(,|$)',',');
    l_permissions:=regexp_replace(l_permissions,',,',',');
    l_permissions:=regexp_replace(l_permissions,'^,|,$','');

    if (l_permissions is not null)
    then
      l_stmt := 'grant '||l_permissions||' on '||
                  '"'||l_object_owner||'"."'||l_table_name||'" to '||
                  x_grantee||' '||x_options;
      log(c_module, 'STATEMENT', 'SQL: '||l_stmt);
      exec(l_stmt, c_module);
    end if;

    l_permissions:=regexp_replace(l_permissions,'ALTER','');
    l_permissions:=regexp_replace(l_permissions,'INDEX','');
    l_permissions:=regexp_replace(l_permissions,',,',',');
    l_permissions:=regexp_replace(l_permissions,'^,|,$','');
  end if;

  if (l_permissions is not null)
  then
    -- execute grant on target object
    -- for editioned object, use actual edition

    l_stmt := 'grant '||l_permissions||' on '||
                 '"'||l_object_owner||'"."'||l_object_name||'" to '||
                 x_grantee||' '||x_options;
    -- check if editioned stub object
    if (l_edition_name < sys_context('userenv', 'current_edition_name'))
    then
      -- grant in actual edition
      log(c_module, 'STATEMENT', 'SQL['||l_edition_name||']: '||l_stmt);
      l_cursor := dbms_sql.open_cursor(security_level=>2);
      dbms_sql.parse(l_cursor, l_stmt, dbms_sql.native, l_edition_name, null, false);
      dbms_sql.close_cursor(l_cursor);
    else
      -- grant in current edition
      log(c_module, 'STATEMENT', 'SQL: '||l_stmt);
      exec(l_stmt, c_module);
    end if;
  end if;
exception
  when others then
    if dbms_sql.is_open(l_cursor) then
      dbms_sql.close_cursor(l_cursor);
    end if;
    if (l_errmsg = '') then
      l_errmsg := SQLERRM;
    end if;
    log(c_module, 'ERROR', 'ERROR: '||l_errmsg);
    raise;
end GRANT_PRIVS;

/*
** Revoke grants on APPS objects
*  X_REVOKE_FROM_TABLE:
*    - This parameter is applicable only when the target object on which
*      the grant revoked is EV.
*    - This parameter decides whether permission need to be revoked from
*      the underlying table also.
*        TRUE(default): Revoke permission from EV and as well as from its
*                       underlying table
*        FALSE:         Revoke permission from EV only.
*/
procedure REVOKE_PRIVS(
  X_PERMISSIONS in VARCHAR2,
  X_OBJECT_NAME in VARCHAR2,
  X_GRANTEE in VARCHAR2,
  X_OPTIONS in VARCHAR2 default NULL,
  X_REVOKE_FROM_TABLE in BOOLEAN default TRUE)
is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd.revoke_privs';
  L_APPS_SCHEMA  varchar2(30);
  L_OBJECT_TYPE  varchar2(30);
  L_OBJECT_OWNER varchar2(30);
  L_OBJECT_NAME  varchar2(30);
  L_CURSOR       integer;
  L_STMT         varchar2(1000);
  L_EDITION_NAME varchar2(30);
  L_ERRMSG       varchar2(2000) := '';
  L_TABLE_NAME   varchar2(30);
  L_PERMISSIONS  VARCHAR2(400);

  CAN_NOT_REVOKE_PRIV_ERROR exception;
  pragma exception_init(can_not_revoke_priv_error, -01927);

begin

  l_object_owner := ad_zd.apps_schema;
  l_object_name  := x_object_name;
  l_permissions  := x_permissions;

  -- Find object type and edition (owned by APPS in primary namespace)
  begin
    select object_type, edition_name
    into   l_object_type, l_edition_name
    from   dba_objects
    where  owner       = l_object_owner
      and  object_name = l_object_name
      and  object_type NOT LIKE '%PARTITION'
      and  namespace   = 1;
  exception
    when no_data_found then
      l_errmsg := l_object_owner||'.'||l_object_name||' does not exist';
      raise;
  end;

  -- loop to resolve synonyms
  while (l_object_type = 'SYNONYM')
  loop
    begin
      select syn.table_owner, syn.table_name, obj.object_type, obj.edition_name
      into   l_object_owner, l_object_name, l_object_type, l_edition_name
      from   dba_synonyms syn, dba_objects obj
      where  syn.owner        = l_object_owner
        and  syn.synonym_name = l_object_name
        and  obj.owner        = syn.table_owner
        and  obj.object_name  = syn.table_name
        and  obj.object_type NOT LIKE '%PARTITION'
        and  obj.namespace    = 1;
    exception
      when no_data_found then
        l_errmsg := 'Synonym '||x_object_name||' pointing to a non-existent object';
        raise;
    end;
  end loop;

  -- If target object is an EV then revoke from table as well
  -- if x_revoke_from_table is true
  if (x_revoke_from_table and l_object_type='VIEW' and l_object_name like '%#')
  then
    l_table_name := ad_zd_table.ev_table(l_object_owner, l_object_name);

    l_permissions:=regexp_replace(x_permissions,'(^|,)[[:space:]]*UNDER[[:space:]]*(,|$)',',');
    l_permissions:=regexp_replace(l_permissions,',,',',');
    l_permissions:=regexp_replace(l_permissions,'^,|,$','');

    if (l_permissions is not null)
    then
      l_stmt := 'revoke '||l_permissions||' on '||
                  '"'||l_object_owner||'"."'||l_table_name||'" from '||
                  x_grantee||' '||x_options;
      log(c_module, 'STATEMENT', 'SQL: '||l_stmt);
      -- If revoking grant to table fails with ORA-01927 error
      -- then ignore, as this is implicit revoke
      begin
        exec(l_stmt, c_module);
      exception
        when can_not_revoke_priv_error then
          null;
      end;
    end if;

    l_permissions:=regexp_replace(l_permissions,'ALTER','');
    l_permissions:=regexp_replace(l_permissions,'INDEX','');
    l_permissions:=regexp_replace(l_permissions,',,',',');
    l_permissions:=regexp_replace(l_permissions,'^,|,$','');
  end if;

  if (l_permissions is not null)
  then
    -- execute revoke on target object
    -- for editioned object, use actual edition

    l_stmt := 'revoke '||l_permissions||' on '||
                 '"'||l_object_owner||'"."'||l_object_name||'" from '||
                 x_grantee||' '||x_options;
    -- check if editioned stub object
    if (l_edition_name < sys_context('userenv', 'current_edition_name'))
    then
      -- revoke in actual edition
      log(c_module, 'STATEMENT', 'SQL['||l_edition_name||']: '||l_stmt);
      l_cursor := dbms_sql.open_cursor(security_level=>2);
      dbms_sql.parse(l_cursor, l_stmt, dbms_sql.native, l_edition_name, null, false);
      dbms_sql.close_cursor(l_cursor);
    else
      -- revoke in current edition
      log(c_module, 'STATEMENT', 'SQL: '||l_stmt);
      exec(l_stmt, c_module);
    end if;
  end if;
exception
  when others then
    if dbms_sql.is_open(l_cursor) then
      dbms_sql.close_cursor(l_cursor);
    end if;
    if (l_errmsg = '') then
      l_errmsg := SQLERRM;
    end if;
    log(c_module, 'ERROR', 'ERROR: '||l_errmsg);
    raise;
end REVOKE_PRIVS;

/*
** Procedure To actualize an object in current edition
*/
procedure ACTUALIZE_OBJECT(
  X_OWNER       in VARCHAR2,
  X_OBJECT_NAME in VARCHAR2,
  X_OBJECT_TYPE in VARCHAR2)
is
begin
  ebs_system.ad_zd_sys.actualize_object(x_owner, x_object_name, x_object_type);
end;

/*
** Is dbms_editions_utilties.actualize_all installed?
** Bug 32356916 - JWSMITH IMPLEMENT NEW RDBMS ACTUALIZE_ALL ROUTINE
** Called from OtherPhases.pm
*/
function CHECK_DBMS_ACTUALIZE_ALL return number is
  C_MODULE varchar2(80) := 'ad.plsql.ad_zd.check_dbms_actualize_all';
  V_COUNT  number := 0;

begin
  log(c_module, 'PROCEDURE', 'begin');

  select /*+ opt_param('container_data', 'all') */ count(*) into v_count
  from  sys.all_procedures
  where object_type = 'PACKAGE'
  and   object_name = 'DBMS_EDITIONS_UTILITIES2'
  and   owner = 'SYS'
  and   procedure_name = 'ACTUALIZE_ALL';

  if (v_count > 0 ) then
    log(c_module, 'STATEMENT', 'SYS.DBMS_EDITIONS_UTILITIES2.ACTUALIZE_ALL FOUND IN DB');
  end if;

  log(c_module, 'PROCEDURE', 'end');

  return v_count;
end;

/*
** Native cleanup requires many RDBMS fixes to be applied before
** we can utilize this feature. All of the patches are included in
** 19.18 and is RU minimum.
*/
function CHECK_DBMS_PATCHES_APPLIED return number is
  C_MODULE           varchar2(80) := 'ad.plsql.ad_zd.check_dbms_patches_applied';
  V_COUNT            number := 0;
  L_STMT             varchar2(1000);
  DB_RU_VERSION      number := 0;
  DB_VERSION_NUMBER  pls_integer :=DBMS_DB_VERSION.VERSION;

begin
  log(c_module, 'PROCEDURE', 'begin');

-- Get complete DB RU version - 19.18, 19.8, 23
  l_stmt := 'select to_number(substr(version_full,instr(version_full,''.'',1,1) +1,
                    instr(version_full,''.'',1,2) - instr(version_full,''.'',1,1) -1)) from v$instance';
  execute immediate l_stmt into db_ru_version;
  log(c_module, 'STATEMENT', 'DB RU Version: '||to_char(db_version_number)||'.'||to_char(db_ru_version));

  if (db_version_number > 19 or (db_version_number = 19 and db_ru_version >=  18)) then
    v_count := 1;
    log(c_module, 'STATEMENT', 'Native Cleanup Patches are present.');
  else
    log(c_module, 'STATEMENT', 'Incompatible DB version. You must be on 19.18 or greater for Native Cleanup.');
  end if;

  return v_count;
  log(c_module, 'PROCEDURE', 'end');

  exception
    when others then
      log(c_module, 'ERROR', SQLERRM||', SQL: '||l_stmt);
      raise;
end;

end AD_ZD;
