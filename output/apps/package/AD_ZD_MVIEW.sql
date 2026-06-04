
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_MVIEW" AUTHID CURRENT_USER AS
-- $Header: ADZDMVS.pls 120.16.12020000.2 2012/12/12 16:14:12 asutrala ship $

/*=================================================================*
 *                     Below apis needed for xdf                   *
 *=================================================================*/

procedure PATCH(p_mvdef CLOB);

procedure PATCH(p_owner varchar2,
                p_name varchar2,
                p_type varchar2 default null);


/*=================================================================*
 *                     Below apis needed for ad_mv                 *
 *=================================================================*/

procedure DROP_MVQ(p_owner varchar2 default ' ',
                   p_mvname varchar2);

procedure INSTALL_MVQ_ARCH(p_mvdef CLOB,
                           p_skipmv number default 0);

procedure DROP_MV (
              X_MVIEW_OWNER    in  varchar2,
              X_MVIEW_NAME     in  varchar2,
              X_DROP_STMT      in  varchar2,
              X_UPD_STMT       in  varchar2,
              X_DROPPED        out nocopy varchar2 );

/*=================================================================*
 *                     Below apis given by GB                      *
 *=================================================================*/

procedure UPGRADE(p_owner varchar2,
                  p_mview_name varchar2);

procedure UPGRADE_DB(x_execute number default 1);

function GENERATE(p_owner varchar2,
                  p_mvname varchar2)
return clob;

function GET_MVQ_NAME(name varchar2, ext varchar2 default ' ')
return varchar2;

function GET_MV_NAME(name varchar2, ext varchar2 default ' ')
return varchar2;

procedure FINALIZE;

procedure CUTOVER(x_execute number default 0);

procedure PATCH_LOG(p_owner varchar2,
                    p_tabname varchar2);

/*=================================================================*
 *                     Global Constant Variables                   *
 *=================================================================*/

-- For MVQ View
g_mvq_char constant varchar2(1) := '#';

-- For MVLog View
g_mvl_char constant varchar2(1) := '~';
g_mvm_char constant varchar2(1) := '-';

end AD_ZD_MVIEW;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_MVIEW" AS
-- $Header: ADZDMVB.pls 120.38.12020000.36 2022/04/14 15:43:30 jwsmith ship $


/*******************************************************************
 *                                                                 *
 *                     FORWARD DECLARATIONS                        *
 *                                                                 *
 *******************************************************************/
function GENERATE(p_owner varchar2,
                  p_mvname varchar2,
                  p_build_deferred boolean) return clob;

/*******************************************************************
 *                                                                 *
 *                         UTILITY APIS                            *
 *                                                                 *
 *******************************************************************/

type ddl_defs is table of CLOB index by BINARY_INTEGER;

-- Diagnostic Log shortcut
procedure LOG(p_module varchar2, p_log_type varchar2, p_message varchar2)
is
begin
   AD_ZD_LOG.Message('ad.plsql.ad_zd_mview.'||p_module,  p_log_type, p_message);
end;


/*-----------------------------------------------------------------+
 |                                                                 |
 |  SPLITNAMEOWNER                                                 |
 |     Return owner, name without quotes                           |
 |                                                                 |
 |      If quotes = 0, then extowner and extname will not contain  |
 |           double quotes (")                                     |
 |      Else if quotes > 0, then these will contain double         |
 |           quotes (")                                            |
 |                                                                 |
 +-----------------------------------------------------------------*/
procedure SPLITNAMEOWNER(
  name in varchar2,
  extowner out nocopy varchar2,
  extname out nocopy varchar2,
  quotes  in number)
is
  pos number;
begin
   pos := instr(name, '.');
   if (pos > 0)
   THEN
      -- Owner also present.
      extowner := substr(upper(name), 1, pos-1);
      extowner := trim(extowner);
      extowner := trim(both '"' from extowner);
      extname := substr(name, pos+1);
      extname := trim(extname);
      extname := trim(both '"' from extname);
   ELSE
      extowner := null;
      extname := trim(name);
      extname := trim(both '"' from extname);
   END IF;

   if (quotes > 0)
   then
      if (extowner is not null)
      then
         extowner := '"' || extowner || '"';
      end if;
      if (extname is not null)
      then
         extname := '"' || extname || '"';
      end if;

   end if;
end;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  CONVERT_NAME                                                   |
 |     Translates Name from one form to another                    |
 |       flag = 1         translates from mv to mvq format         |
 |              any other translates from mvq to mv format         |
 |       ext  = #  extension character for mvq                     |
 |            = T  extension character for trigger view            |
 |            = L  extension character for mvlog view              |
 |                                                                 |
 +-----------------------------------------------------------------*/
function CONVERT_NAME(name varchar2, flag number, ext  varchar2)
  return varchar2
is
  ch varchar2(1);
  ow varchar2(32);
  nm varchar2(32);
  l_tmpname varchar2(65);
  retname varchar2(65);
begin
   l_tmpname := trim(name);
   ch := substr(l_tmpname, 1, 1);
   if(ch = '"')
   then
      l_tmpname := trim(both '"' from l_tmpname);
   end if;

   splitnameowner(l_tmpname, ow, nm, 0);

   if (flag = 1)
   then
      retname := substr(nm, 1, (30-length(ext)))||ext;
   else
      retname := regexp_replace(nm, ext||'$', '', 1, 1, 'i');
      -- Hack for MTH_ENTITY_PLANNED_USAGE_SM_MV and MTH_ENTITY_PLANNED_USAGE_HR_MV mviews
      -- Because these two mviews are having length 30 so attach V at the end after conversion
      -- if after conversion ended with _M
      if (length(retname) = 29 and retname like '%_M')
      then
         retname := retname||'V';
      end if;

   end if;

   if (ch = '"')
   then
      if (ow is not null)
      then
         retname := '"'||ow||'"."'||retname||'"';
      else
         retname := '"'||retname||'"';
      end if;
   else
      if (ow is not null)
      then
         retname := ow||'.'||retname;
      end if;
   end if;
   return retname;
end;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  get_proper_position                                            |
 |                                                                 |
 |  Tasks :-                                                       |
 |      Process the input string and returns the position          |
 |        where the clause has to add                              |
 |      Order of checking the words should match with the proper   |
 |      syntax                                                     |
 |             USING (NO )?INDEX                                   |
 |             NEVER REFRESH                                       |
 |             REFRESH                                             |
 |             FOR UPDATE                                          |
 |             ENABLE QUERY REWRITE                                |
 |             DISABLE QUERY REWRITE                               |
 |                                                                 |
 +-----------------------------------------------------------------*/
function get_proper_position(p_string clob)
return number
is
l_pos number;
begin
  l_pos := regexp_instr(p_string, 'USING (NO )?INDEX');
  if (l_pos = 0)
  then
     l_pos := instr(p_string, 'NEVER REFRESH');
     if (l_pos = 0)
     then
        l_pos := instr(p_string, 'REFRESH');
        if (l_pos = 0)
        then
           l_pos := instr(p_string, 'FOR UPDATE');
              if (l_pos = 0)
              then
                 l_pos := instr(p_string, 'ENABLE QUERY REWRITE');
                 if (l_pos = 0)
                 then
                    l_pos := instr(p_string, 'DISABLE QUERY REWRITE');
                 end if; -- ENABLE QUERY REWRITE
              end if; -- FOR UPDATE
        end if; -- REFRESH
     end if; -- NEVER REFRESH
  end if; -- USING (NO )?INDEX
  return l_pos;
end;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  INCLUDE_PREBUILT                                               |
 |                                                                 |
 |  Tasks :-                                                       |
 |      Process the input string and returns the modified string   |
 |      contains prebuilt syntax                                   |
 |                                                                 |
 +-----------------------------------------------------------------*/
function INCLUDE_PREBUILT(p_string clob)
  return clob
is
  l_retstring clob;
  l_pos number;
  l_prebuilt_clause varchar2(25) := ' ON PREBUILT TABLE ';
begin

   if (length(p_string) > 0)
   then
     l_pos := instr(p_string, 'PREBUILT');
     if (l_pos = 0)
     then
        l_pos := get_proper_position(p_string);
        l_retstring := substr(p_string, l_pos);
        l_retstring := l_prebuilt_clause || l_retstring;
     else
        l_retstring := p_string;
     end if;
   else
     l_retstring := l_prebuilt_clause;
   end if;
   return l_retstring;
end;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  INCLUDE_BUILD                                                  |
 |                                                                 |
 |  Tasks :-                                                       |
 |      Process the input string and returns the modified string   |
 |      contains build syntax                                      |
 +-----------------------------------------------------------------*/
function INCLUDE_BUILD(p_string clob)
  return clob
is
  l_retstring clob;
  l_pos number;
  l_temp1 clob;
  l_build_clause varchar2(25) := ' BUILD DEFERRED ';
begin
   if (length(p_string) > 0)
   then
     l_pos := instr(p_string, 'BUILD');
     if (l_pos = 0)
     then
        l_pos := get_proper_position(p_string);
        if (l_pos = 0)
        then
          -- No required tokens exist. So Add at the end.
          l_retstring := p_string || ' ' || l_build_clause;
        else
          -- Add in the middle
          l_temp1 := l_build_clause || ' ' || substr(p_string, l_pos);
          l_retstring := substr(p_string, 1, l_pos-1) || ' ' || l_temp1;
        end if;
     else
        l_retstring := regexp_replace(p_string, '[[:space:]]*BUILD[[:space:]]+IMMEDIATE',
                                      l_build_clause, 1, 1, 'i');
     end if;
   else
     l_retstring := l_build_clause;
   end if;
   return l_retstring;
end;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  EXPAND_QUERY                                                   |
 |     Takes the command as input and executes it.                 |
 |     Execute Immediate is more efficient than dbms_sql.parse     |
 |     Refer :- http://download.oracle.com/docs/cd/B28359_01/      |
 |             appdev.111/b28370/dynamic.htm                       |
 |                                                                 |
 +-----------------------------------------------------------------*/
function  EXPAND_QUERY(p_query clob)
  return clob
is
  L_MODULE                varchar2(80) := 'EXPAND_QUERY';
  L_EXP_SELECT_QUERY      clob;
  L_CON_UNION             varchar2(100);
  L_STMT                  varchar2(1000);
  RU_VERSION              number;
begin
   -- Expand the select query
$if DBMS_DB_VERSION.VER_LE_11 $then
   dbms_sql2.expand_sql_text(p_query, l_exp_select_query);
$else
    --Bug 20355871
   begin
     select value into l_con_union
     from v$parameter
     where name='_connect_by_use_union_all';
   exception
   when no_data_found then
     l_con_union := 'true';
   end;

   $if DBMS_DB_VERSION.VERSION >= 19 $then
     begin
      -- Bug 32967252 - ADB CHANGES - CHANGE THE CODE SETTING _CONNECT_BY_USE_UNION_ALL PARAMETER
      -- Database version 19 or later
      -- We need to set connect by use union all if database release update level is
      -- less than equal to 19.13
      -- Get 2nd digit so the comparison works (19.8 against 19.13 should be less
      l_stmt := 'select substr(version_full, instr(version_full,''.'',1,1)+1,
                 instr(version_full,''.'',1,2) - instr(version_full,''.'',1,1) -1)
                 from v$instance';
      execute immediate l_stmt into ru_version;
      if (ru_version <=  13 ) then
        execute immediate 'alter session set "_connect_by_use_union_all" = "old_plan_mode"';
      end if;
      -- change by Kevin
      dbms_utility.expand_sql_text(p_query, l_exp_select_query);
      if (ru_version <=  13 ) then
        execute immediate 'alter session set "_connect_by_use_union_all" =' || l_con_union;
      end if;
    exception
    when others then
      log(l_module, 'ERROR', SQLERRM||', SQL: '||l_stmt);
      raise;
    end;
  $else
     execute immediate 'alter session set "_connect_by_use_union_all" = "old_plan_mode"';
     dbms_utility.expand_sql_text(p_query, l_exp_select_query);
     execute immediate 'alter session set "_connect_by_use_union_all" =' || l_con_union;
  $end

$end
   return l_exp_select_query;
end;

-- Execute SQL
procedure EXEC(
  X_MODULE       varchar2,
  X_COMMAND      clob,
  X_OWNER        varchar2 default null)
IS
  L_STMT         clob;
  L_CUR          integer;
  ROWS_PROCESSED integer;
  e_rowid_prebuilt exception;
  PRAGMA EXCEPTION_INIT(e_rowid_prebuilt, -12058);
  e_udt_prebuilt exception;
  PRAGMA EXCEPTION_INIT(e_udt_prebuilt, -32304);
  e_shape_mismatch exception;
  PRAGMA EXCEPTION_INIT(e_shape_mismatch, -12060);
  e_table_already_referenced exception;
  PRAGMA EXCEPTION_INIT(e_table_already_referenced, -32334);
  e_mv_not_exists exception;
  PRAGMA EXCEPTION_INIT(e_mv_not_exists, -12003);
begin
  l_cur := dbms_sql.open_cursor;

  if (x_owner is null) then
    log(x_module, 'STATEMENT', 'SQL: '||substr(x_command, 1, 3900));
    dbms_sql.parse(l_cur, x_command, dbms_sql.native);
  else
    l_stmt := 'begin '||x_owner||'.apps_ddl.apps_ddl(:stmt); end;';
    log(x_module, 'STATEMENT', 'SQL['||x_owner||']: '||substr(x_command, 1, 3900));
    dbms_sql.parse(l_cur, l_stmt, dbms_sql.native);
    dbms_sql.bind_variable(l_cur, 'stmt', x_command);
  end if;

  rows_processed := dbms_sql.execute(l_cur);
  dbms_sql.close_cursor(l_cur);

exception
  when e_udt_prebuilt   or
       e_rowid_prebuilt or
       e_shape_mismatch or
       e_table_already_referenced THEN
    dbms_sql.close_cursor(l_cur);
    log(x_module, 'STATEMENT', SQLERRM||', SQL: '||substr(x_command, 1, 3900));
    raise;

  when e_mv_not_exists then
    if (regexp_instr(x_command,
          'DROP[[:space:]]+MATERIALIZED[[:space:]]+VIEW', 1, 1, 0, 'i') >= 0) then
      dbms_sql.close_cursor(l_cur);
      log(x_module, 'STATEMENT', SQLERRM||', SQL: '||substr(x_command, 1, 3900));
      raise;
    else
      dbms_sql.close_cursor(l_cur);
      log(x_module, 'ERROR', SQLERRM||', SQL: '||substr(x_command, 1, 3900));
      raise;
    end if;

  when others then
    dbms_sql.close_cursor(l_cur);
    log(x_module, 'ERROR', SQLERRM||', SQL: '||substr(x_command, 1, 3900));
    raise;
end;


procedure install_mvlog(p_owner varchar2, p_mview_name varchar2)
is
  c_module varchar2(25) := 'install_mvlog';
  l_mvloglname varchar2(32);
  l_mvlogmname varchar2(32);
  l_ctblname varchar2(128);
  l_mvlogddl clob;
  l_commentpart1 clob;
  l_commentpart2 clob;
begin
   log(c_module, 'STATEMENT', 'Saving MV Log definition');

   l_mvloglname := get_mvq_name(p_mview_name, g_mvl_char);
   l_mvlogmname := get_mvq_name(p_mview_name, g_mvm_char);
   SELECT log_table
   INTO   l_ctblname
   FROM   dba_mview_logs
   WHERE  master=p_mview_name
   AND    log_owner=p_owner;

   l_mvlogddl := dbms_metadata.get_ddl('MATERIALIZED_VIEW_LOG',
                                       l_ctblname,
                                       p_owner);

   -- The max length of comment can be 4000
   if (length(l_mvlogddl) > 4000)
   then
      l_commentpart1 :=  'COMMENT ON TABLE "'||p_owner||'"."'||l_mvloglname||'" is '''||substr(l_mvlogddl, 1, 4000)||'''';
      l_commentpart2 :=  'COMMENT ON TABLE "'||p_owner||'"."'||l_mvlogmname||'" is '''||substr(l_mvlogddl, 4001)||'''';
   else
      l_commentpart1 := 'COMMENT ON TABLE "'||p_owner||'"."'||l_mvloglname||'" is '''||l_mvlogddl||'''';
   end if;

   exec(c_module, 'create or replace view "'||p_owner||'"."'||l_mvloglname||'" as select * from dual');
   exec(c_module, l_commentpart1);
   if (length(l_mvlogddl) > 4000)
   then
      exec(c_module, 'create or replace view "'||p_owner||'"."'||l_mvlogmname||'" as select * from dual');
      exec(c_module, l_commentpart2);
   end if;
end install_mvlog;


procedure recreate_mvlog(p_owner varchar2, p_mview_name varchar2)
IS
c_module varchar2(25) := 'recreate_mvlog';
l_mvlogddlpart1 clob := ' ';
l_mvlogddlpart2 clob := ' ';
l_mvlogddl clob;
l_exist number;
begin
  log(c_module, 'STATEMENT', 'Recreating MV Log');

   SELECT count(1)
   INTO   l_exist
   FROM   dba_mview_logs
   WHERE  log_owner=p_owner
   AND    master=p_mview_name;

   if (l_exist = 0)
   then
      SELECT count(1)
      INTO   l_exist
      FROM   dba_tab_comments
      WHERE  owner=p_owner
      AND    table_name=get_mvq_name(p_mview_name, g_mvl_char)
      AND    table_type='VIEW';

      if (l_exist > 0)
      then
         SELECT nvl(trim(comments), ' ')
         INTO   l_mvlogddlpart1
         FROM   dba_tab_comments
         WHERE  owner=p_owner
         AND    table_name=get_mvq_name(p_mview_name, g_mvl_char)
         AND    table_type='VIEW';
      end if;

      SELECT count(1)
      INTO   l_exist
      FROM   dba_tab_comments
      WHERE  owner=p_owner
      AND    table_name=get_mvq_name(p_mview_name, g_mvm_char)
      AND    table_type='VIEW';

      if (l_exist > 0)
      then
         SELECT nvl(trim(comments), ' ')
         INTO   l_mvlogddlpart2
         FROM   dba_tab_comments
         WHERE  owner=p_owner
         AND    table_name=get_mvq_name(p_mview_name, g_mvm_char)
         AND    table_type='VIEW';
      end if;

      l_mvlogddl := l_mvlogddlpart1||l_mvlogddlpart2;

      if (l_mvlogddl <> '  ')
      then
         exec(c_module, l_mvlogddl);
      end if;
   end if;
   exec(c_module, 'drop view "'||p_owner||'"."'||get_mvq_name(p_mview_name, g_mvl_char)||'"');

   SELECT count(1)
   INTO   l_exist
   FROM   dba_views
   WHERE  owner=p_owner
   AND    view_name=get_mvq_name(p_mview_name, g_mvm_char);

   if (l_exist > 0)
   then
      exec(c_module, 'drop view "'||p_owner||'"."'||get_mvq_name(p_mview_name, g_mvm_char)||'"');
   end if;
end recreate_mvlog;

function FETCH_DDL(p_type IN varchar2,
                     p_owner IN varchar2,
                     p_object_name IN varchar2) return CLOB
is
c_module varchar2(25) := 'fetch_ddl';
l_ddls sys.ku$_ddls;
l_ddl CLOB;
l_open_handle number;
l_transform_handle number;

begin
  log(c_module, 'PROCEDURE', 'begin: '||p_type||'.'||p_owner||'.'||p_object_name);

  l_open_handle := dbms_metadata.open(p_type);
  dbms_metadata.set_filter(l_open_handle, 'SCHEMA', p_owner);
  dbms_metadata.set_filter(l_open_handle, 'NAME', p_object_name);
  l_transform_handle := dbms_metadata.add_transform(l_open_handle, 'DDL');
  dbms_metadata.set_transform_param(l_transform_handle, 'SQLTERMINATOR', false);
  l_ddls := dbms_metadata.fetch_ddl(l_open_handle);
  dbms_metadata.close(l_open_handle);

  if (l_ddls.count > 0) then
    l_ddl := dbms_lob.substr(l_ddls(1).ddltext);
  end if;

  log(c_module, 'PROCEDURE', 'end');
  return l_ddl;

end FETCH_DDL;

procedure STORE_DEFS(p_owner IN varchar2,
                     p_mview_name IN varchar2,
                     p_ddl_defs IN OUT NOCOPY ddl_defs)
IS
c_module varchar2(25) := 'store_defs';
l_grant varchar2(32000);

cursor dep_indexes is
SELECT owner,
       index_name
FROM   dba_indexes
WHERE  owner = p_owner
AND    table_name = p_mview_name
AND    index_name not like 'I_SNAP$%';

cursor dep_triggers is
SELECT owner,
       trigger_name
FROM   dba_triggers
WHERE  owner = p_owner
AND    table_name = p_mview_name;

cursor dep_constraints is
SELECT owner,
       constraint_name
FROM   dba_constraints
WHERE  owner = p_owner
AND    table_name = p_mview_name
AND    generated = 'USER NAME';

cursor dep_grants is
SELECT distinct grantee,
       privilege,
       grantable,
       hierarchy
FROM   dba_tab_privs
WHERE  owner = p_owner
AND    table_name = p_mview_name
AND    grantee <> 'SYSTEM';

BEGIN
  log(c_module, 'PROCEDURE', 'begin: '||p_owner||'.'||p_mview_name);

  log(c_module, 'STATEMENT', 'Getting Index Definitions');
  for objs in dep_indexes
  loop
    begin
      p_ddl_defs(p_ddl_defs.count + 1) := fetch_ddl('INDEX', p_owner, objs.index_name);

    exception
      when others then
        log(c_module, 'ERROR', 'Strange Exception for index '||objs.index_name||' of '||p_owner||'.'||p_mview_name||'    '||SQLCODE);
        raise;
    end;
  end loop;

  log(c_module, 'STATEMENT', 'Getting Trigger Definitions');
  for objs in dep_triggers
  loop
    begin
      p_ddl_defs(p_ddl_defs.count + 1) := fetch_ddl('TRIGGER', p_owner, objs.trigger_name);

    exception
      when others then
        log(c_module, 'ERROR', 'Strange Exception for trigger '||objs.trigger_name||' of '||p_owner||'.'||p_mview_name||'    '||SQLCODE);
        raise;
    end;
  end loop;

  log(c_module, 'STATEMENT', 'Getting Constraint Definitions');
  for objs in dep_constraints
  loop
    begin
      p_ddl_defs(p_ddl_defs.count + 1) := fetch_ddl('CONSTRAINT', p_owner, objs.constraint_name);

    exception
      when others then
        log(c_module, 'ERROR', 'Strange Exception for constraint '||objs.constraint_name||' of '||p_owner||'.'||p_mview_name||'    '||SQLCODE);
        raise;
    end;
  end loop;

  log(c_module, 'STATEMENT', 'Getting Grant Definitions');
  for objs in dep_grants
  loop
    l_grant := 'GRANT ';
    begin
      l_grant := l_grant|| objs.privilege || ' ON "' ||
                            p_owner || '"."'||p_mview_name || '" TO "' ||
                            objs.grantee || '" ' ;

      if (nvl(objs.grantable, 'NO') = 'YES' ) then
        l_grant := l_grant || ' WITH GRANT OPTION ';
      end if;

      if (nvl(objs.hierarchy, 'NO') = 'YES' and objs.privilege='SELECT' ) then
        l_grant := l_grant || ' WITH HIERARCHY OPTION ';
      end if;

      p_ddl_defs(p_ddl_defs.count + 1) := l_grant;

    exception
      when others then
        log(c_module, 'ERROR', 'Strange Exception for grant of '||p_owner||'.'||p_mview_name||'    '||SQLCODE||'   '||l_grant);
        raise;
    end;
  end loop;

  log(c_module, 'PROCEDURE', 'end: '||p_owner||'.'||p_mview_name);

END STORE_DEFS;

-- Drop MV Container Table and recreate MV from MVQ
procedure DROP_RECREATE(
  p_owner varchar2,
  p_mview_name varchar2)
is
  c_module varchar2(25) := 'drop_recreate';
  l_exp_mvdef clob;
  l_exist number;
  l_phase varchar2(80) := ad_zd_parallel_exec.C_PHASE_CUTOVER;
  l_ddl_defs ddl_defs;
  l_build_deferred boolean := false;
begin
  log(c_module, 'PROCEDURE', 'begin: '||p_owner||'.'||p_mview_name);

  if (ad_zd.get_edition('PATCH') is null) then
    l_phase := ad_zd_parallel_exec.C_PHASE_UPGRADE_MVIEW;
	--This change is for bug#26720905 fix.
	--For Downtime patching build deferred is always set as true for
	--both new and old mvs.
	l_build_deferred :=true;
  end if;

  -- If MVLog exist then install mvlog marker
  select count(1) into l_exist
  from   dba_mview_logs
  where  log_owner=p_owner and master=p_mview_name;

  if (l_exist > 0) then
    install_mvlog(p_owner, p_mview_name);
  end if;

  -- If Container Table exists, then drop it
  select count(1) into l_exist
  from   dba_tables
  where  owner=p_owner and table_name=p_mview_name;

  if (l_exist > 0) then
    -- Backup secondary object definitions of container table
    log(c_module, 'STATEMENT', 'Backing up dependent object DDLs of container table '||p_owner||'.'||p_mview_name);
    store_defs(p_owner, p_mview_name, l_ddl_defs);

    log(c_module, 'STATEMENT', 'Dropping container table');
    exec(c_module, 'drop table '||p_owner||'."'||p_mview_name||'"');

    -- Bug 23755141: This is not a new MView. Hence we will include BUILD DEFERRED
    -- at a later point of time.
    l_build_deferred := true;
  end if;

  -- Generate MV definition
  l_exp_mvdef := generate(p_owner, p_mview_name, l_build_deferred);
  log(c_module, 'STATEMENT', 'Creating MV Definition with empty container table');
  begin
    exec(c_module, l_exp_mvdef);
  exception
    when others then
      log(c_module, 'ERROR', 'MV creation failed. Storing all dependent DDLs in AD_ZD_DDL_HANDLER table');
      for idx in 1..l_ddl_defs.count
      loop
        ad_zd_parallel_exec.load(
          x_phase => l_phase,
          x_sql   => l_ddl_defs(idx),
          x_unique => true);
        log(c_module, 'ERROR', l_ddl_defs(idx));
      end loop;
      raise;
  end;

  log(c_module, 'STATEMENT', 'Creating dependent objects of container table');
  for idx in 1..l_ddl_defs.count
  loop
    begin
      exec(c_module, l_ddl_defs(idx));
    exception
      when others then
        log(c_module, 'ERROR', 'Dependent object creation failed. Storing DDL in AD_ZD_DDL_HANDLER table');
        ad_zd_parallel_exec.load(
          x_phase => l_phase,
          x_sql   => l_ddl_defs(idx),
          x_unique => true);
        log(c_module, 'ERROR', l_ddl_defs(idx));
    end;
  end loop;

  -- If saved MV Log data exists, recreate MV Log
  select count(1) into l_exist
  from   dba_views
  where  owner=p_owner
  and    view_name=get_mvq_name(p_mview_name, g_mvl_char);

  if (l_exist > 0) then
    recreate_mvlog(p_owner, p_mview_name);
  end if;

  log(c_module, 'PROCEDURE', 'end');
end;


-- Get MVQ defintiion and comment
-- GB: why are we selecting from dual?
procedure get_mvq_definition(p_owner IN varchar2,
                             p_mvqname IN varchar2,
                             p_mvqdef OUT NOCOPY CLOB,
                             p_comment OUT NOCOPY CLOB)
IS
c_module varchar2(25) := 'get_mvq_definition';
BEGIN
  log(c_module, 'STATEMENT', 'Getting Logical Definition from '||p_owner||'.'||p_mvqname);

  begin
    SELECT dbms_metadata.get_ddl('VIEW', p_mvqname, p_owner)
    INTO   p_mvqdef
    FROM   dual;
  exception
    when others then
      log(c_module, 'ERROR', 'Strange Exception '||p_owner||'.'||p_mvqname||'    '||SQLCODE);
      p_mvqdef := null;
      p_comment := null;
      raise;
  end;

  begin
    SELECT dbms_metadata.get_dependent_ddl('COMMENT', p_mvqname, p_owner)
    INTO   p_comment
    FROM   dual;
  exception
    when others then
      if (SQLCODE = -31608) then
        p_comment := null;
      else
	log(c_module, 'ERROR', 'Exception while calling
        	dbms_metadata.get_dependent_ddl to get the comment'||SQLCODE);
        raise;
      end if;
  end;
end get_mvq_definition;

-- Regenerate MV from MVQ
procedure process_mv(p_owner  varchar2,
                     p_mview_name varchar)
is
  c_module varchar2(25) := 'process_mv';
  l_exp_mvdef clob;
  l_dropmv clob;
  l_prebuilt number;
  l_mvexist number;
  l_syn_exist number;
  l_owner varchar2(32);
  l_appsname varchar2(30);
  l_mvqdef clob;
  l_mvqcomment clob;
  l_mvq_name varchar2(30) := get_mvq_name(p_mview_name);

begin
  log(c_module, 'PROCEDURE', 'begin: '||p_owner||'.'||p_mview_name);

  l_appsname := ad_zd.apps_schema;
  l_owner := trim(nvl(p_owner, l_appsname));

  -- Check if MV exists
  select count(1) into l_mvexist
  from   dba_mviews
  where  owner=l_owner and  mview_name=p_mview_name;

  -- Drop existing MV if it exists
  if (l_mvexist = 1) then
    log(c_module, 'STATEMENT', 'Dropping old MV, preserve container table');
    l_dropmv :=
      'drop materialized view '||l_owner||'."'||p_mview_name||'" preserve table';
    exec(c_module, l_dropmv);
  end if;

  get_mvq_definition(l_owner, l_mvq_name, l_mvqdef, l_mvqcomment);

  -- Check if prebuilt table exists
  select count(1) into l_prebuilt
  from   dba_tables
  where  owner=l_owner and table_name=p_mview_name;

  if l_prebuilt = 0 then

    -- create MV and table
    drop_recreate(l_owner, p_mview_name);

  else

    -- create MV with pre-built table
    l_exp_mvdef := generate(l_owner, p_mview_name);

    declare
      e_rowid_prebuilt exception;
      PRAGMA EXCEPTION_INIT(e_rowid_prebuilt, -12058);
      e_udt_prebuilt exception;
      PRAGMA EXCEPTION_INIT(e_udt_prebuilt, -32304);
      e_shape_mismatch exception;
      PRAGMA EXCEPTION_INIT(e_shape_mismatch, -12060);
      e_table_already_referenced exception;
      PRAGMA EXCEPTION_INIT(e_table_already_referenced, -32334);
    begin
      log(c_module, 'STATEMENT', 'Creating revised MV Definition for original container table');
      exec(c_module, l_exp_mvdef, l_owner);
    exception
      when e_udt_prebuilt   or
           e_rowid_prebuilt or
           e_shape_mismatch or
           e_table_already_referenced
      then
        drop_recreate(l_owner, p_mview_name);
    end;

  end if;


  -- If the MV is not in APPS create synonym
  if (upper(l_owner) <> l_appsname) then

    -- test if synonym exists
    select count(1) INTO l_syn_exist
    from   dba_synonyms
    where  synonym_name=p_mview_name
      and  owner=l_appsname
      and  table_owner=upper(l_owner)
      and  table_name=synonym_name;

    if (l_syn_exist = 0) then
      log(c_module, 'STATEMENT', 'Creating APPS synonym for non-APPS MV');
      exec(c_module, 'CREATE OR REPLACE SYNONYM '||
                       l_appsname||'."'||p_mview_name||'" FOR "'||
                       l_owner||'"."'||p_mview_name || '"');
    end if;

    -- FUTURE: grant to APPS
    --    exec(c_module, 'GRANT ALL ON "'||l_owner||'"."'||p_mview_name||
    --                     '" TO '||l_appsname||' WITH GRANT OPTION');

  end if;

  -- Execute automatic refresh if needed:
  if (instr(l_mvqdef, '/*AUTOREFRESH*/')) > 0 then
     dbms_mview.refresh(p_owner||'.'||p_mview_name,'?');
     log(c_module, 'STATEMENT', 'Refreshed MV as AUTOREFRESH commentis present');
  end if;

  log(c_module, 'PROCEDURE', 'end');
end process_mv;


/*-----------------------------------------------------------------+
 |                                                                 |
 |  GET_COLUMN_ALIAS                                               |
 |                                                                 |
 |  Tasks :-                                                       |
 |      Takes the input string and returns the column alias string |
 |      the column alias string                                    |
 |                                                                 |
 +-----------------------------------------------------------------*/
procedure get_column_alias(l_cmt1 IN CLOB,
                           l_cmt OUT NOCOPY CLOB,
                           l_column_alias OUT NOCOPY CLOB)
IS
c_module varchar2(25) := 'get_column_alias';
l_ctr number :=0;
l_dquote number :=0;
l_itr number :=1;
l_copy_cmt1 clob;
l_chr varchar2(1);
BEGIN

-- Trim all the new line, space and tab characters
   l_copy_cmt1 := trim(leading fnd_const.newline from l_cmt1);
   l_copy_cmt1 := trim(leading ' ' from l_copy_cmt1);
   l_copy_cmt1 := trim(leading fnd_const.newline from l_copy_cmt1);
   l_copy_cmt1 := trim(leading '	' from l_copy_cmt1);
   l_copy_cmt1 := trim(leading fnd_const.newline from l_copy_cmt1);
   l_copy_cmt1 := trim(leading ' ' from l_copy_cmt1);
   l_chr := substr(l_copy_cmt1, 1, 1);




   l_copy_cmt1 := trim(leading '	' from l_copy_cmt1);
--   log(c_module, 'Input string = ' || l_cmt1);
--   log(c_module, 'Modified Input string = ' || l_copy_cmt1);
--   log(c_module, 'l_chr = ' || l_chr);
   if (l_chr = '(')
   THEN
      loop
--        log(c_module, 'Came into loop');
        l_chr := substr(l_cmt1, l_itr, 1);
--        log(c_module, 'l_chr = ' || l_chr);
        if (l_chr = '"')
        THEN
           if (l_dquote = 0)
           THEN
               l_dquote := 1;
           ELSE
               l_dquote := 0;
           END IF;
        END IF;
        if (l_dquote = 0 and l_chr = '(')
        THEN
           l_ctr :=  l_ctr + 1;
--           log(c_module, 'Increased = ' || l_ctr);
        END IF;

        if (l_dquote = 0 and l_chr = ')')
        THEN
           l_ctr :=  l_ctr - 1;
--           log(c_module, 'Decreased = ' || l_ctr);
        END IF;

        l_itr := l_itr + 1;
        exit when ((l_chr is null)or((l_ctr = 0) and (l_chr = ')')));
      end loop;
      l_column_alias := substr(l_cmt1, 1, l_itr);
      l_cmt := substr(l_cmt1, l_itr+1);
   ELSE
 --     log(c_module, 'Didnot go into loop');
      l_cmt := l_cmt1;
      l_column_alias := null;
   END IF;
--   log(c_module, 'Output column alias = ' || l_column_alias);
--   log(c_module, 'Output comment = ' || l_cmt);
END get_column_alias;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  GENERATE_MVQDEF                                                |
 |     This api tkaes the MV definition as input and generates     |
 |         MVQ definition and its comment.                         |
 |                                                                 |
 |     Input :- "CREATE MATERIALIZED VIEW "owner"."mvname"....     |
 |                 statement                                       |
 |     Output :- MVQ Definition and its comment                    |
 |                                                                 |
 +-----------------------------------------------------------------*/
procedure generate_mvqdef(p_mvdef IN CLOB,
                          p_owner OUT nocopy VARCHAR2,
                          p_mvname OUT nocopy VARCHAR2,
                          p_mvqdef OUT NOCOPY CLOB,
                          p_comment OUT NOCOPY CLOB)
is
  c_module varchar2(25) := 'generate_mvqdef';
  pos number := 0;
  text CLOB;
  l_cmt CLOB;
  l_column_alias CLOB := null;
  l_cmt1 CLOB;
  rempart CLOB;
  l_mvdef CLOB;
  mvname VARCHAR2(32);
  mvnamequot VARCHAR2(32);
  mvqname VARCHAR2(32);
  owner varchar2(32);
  ownerquot varchar2(32);
  l_tmp varchar2(100);
  l_table_Exist number;
begin
  log(c_module, 'PROCEDURE', 'begin');
  l_mvdef := p_mvdef;

  /*---------------------------------------------------------------------+
   |                                                                     |
   |  Step 1:                                                            |
   |  Remove CREATE MATERIALIZED VIEW from mv definition                 |
   |                                                                     |
   |    CREATE MATERIALIZED VIEW "APPS"."FINALMV" ("A", "C", "B", "D")   |
   |    ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255  |
   |    NOCOMPRESS LOGGING                                               |
   |    TABLESPACE "SYSTEM"                                              |
   |    BUILD IMMEDIATE                                                  |
   |    USING INDEX                                                      |
   |    REFRESH FORCE ON DEMAND                                          |
   |    USING DEFAULT LOCAL ROLLBACK SEGMENT                             |
   |    USING ENFORCED CONSTRAINTS DISABLE QUERY REWRITE                 |
   |    AS select t1.a, t1.c, t2.b, t2.d from mv1 t1, mv2 t2             |
   +---------------------------------------------------------------------*/
   text := regexp_replace(l_mvdef, '[[:space:]]*CREATE[[:space:]]+' ||
                                   '(MATERIALIZED[[:space:]]+VIEW|SNAPSHOT)' ||
                                   '[[:space:]]+',
                          '', 1, 1, 'i');

  /*---------------------------------------------------------------------+
   |                                                                     |
   |  Step 2:                                                            |
   |  Extract owner and mvname.                                          |
   |  Hint: Search for first space or ( character. Till that letter is   |
   |        the name. Care must be taken that sometimes owner might not  |
   |        be there and quotes might not be there                       |
   |                                                                     |
   |    "APPS"."FINALMV" ("A", "C", "B", "D")                            |
   |    ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255  |
   |    NOCOMPRESS LOGGING                                               |
   |    TABLESPACE "SYSTEM"                                              |
   |    BUILD IMMEDIATE                                                  |
   |    USING INDEX                                                      |
   |    REFRESH FORCE ON DEMAND                                          |
   |    USING DEFAULT LOCAL ROLLBACK SEGMENT                             |
   |    USING ENFORCED CONSTRAINTS DISABLE QUERY REWRITE                 |
   |    AS select t1.a, t1.c, t2.b, t2.d from mv1 t1, mv2 t2             |
   +---------------------------------------------------------------------*/
   pos := regexp_instr(text, '[ ('||fnd_const.newline||']');

   l_tmp := substr(text,1, pos-1);
   l_tmp := regexp_replace(l_tmp, fnd_const.newline, ' ');

   splitnameowner(l_tmp, ownerquot, mvnamequot, 0);
   pos := instr(l_tmp, '.');
   if (substr(l_tmp,pos+1,1) <> '"') then
      mvnamequot := upper(mvnamequot);
   end if;
   p_owner := ownerquot;
   p_mvname := mvnamequot;
   mvqname := get_mvq_name(mvnamequot);
   mvqname := '"'||mvqname||'"';
   owner   := '"'||ownerquot||'"';
   --log(c_module, 'STATEMENT', 'MVQ Name = '||mvqname);
   --log(c_module, 'STATEMENT', 'mvnamequot= '||mvnamequot);
   --log(c_module, 'STATEMENT', 'Ownerquot = '||ownerquot);

  /*---------------------------------------------------------------------+
   |                                                                     |
   |  Step 3:                                                            |
   |  Remove owner and mvname.                                           |
   |                                                                     |
   |    "APPS"."FINALMV" ("A", "C", "B", "D")                            |
   |    ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255  |
   |    NOCOMPRESS LOGGING                                               |
   |    TABLESPACE "SYSTEM"                                              |
   |    BUILD IMMEDIATE                                                  |
   |    USING INDEX                                                      |
   |    REFRESH FORCE ON DEMAND                                          |
   |    USING DEFAULT LOCAL ROLLBACK SEGMENT                             |
   |    USING ENFORCED CONSTRAINTS DISABLE QUERY REWRITE                 |
   |    AS select t1.a, t1.c, t2.b, t2.d from mv1 t1, mv2 t2             |
   +---------------------------------------------------------------------*/
-- We are done with the naming stuff. Hence remove the mview name from the text

   text := regexp_replace(text, '((")?'||ownerquot||'(")?.)?(")?'||mvnamequot||'(")?[[:space:]]*', '', 1, 1, 'i');
   text := trim(text);

  /*---------------------------------------------------------------------+
   |                                                                     |
   |  Step 4:                                                            |
   |  Extract mv attributes.                                             |
   |  Hint: Extract till AS keyword                                      |
   |                                                                     |
   |     ("A", "C", "B", "D")                                            |
   |    ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255  |
   |    NOCOMPRESS LOGGING                                               |
   |    TABLESPACE "SYSTEM"                                              |
   |    BUILD IMMEDIATE                                                  |
   |    USING INDEX                                                      |
   |    REFRESH FORCE ON DEMAND                                          |
   |    USING DEFAULT LOCAL ROLLBACK SEGMENT                             |
   |    USING ENFORCED CONSTRAINTS DISABLE QUERY REWRITE                 |
   |    AS select t1.a, t1.c, t2.b, t2.d from mv1 t1, mv2 t2             |
   +---------------------------------------------------------------------*/
   pos := regexp_instr(text, '([[:space:]]|'||fnd_const.newline||
                             ')?AS('||
                              fnd_const.newline||'|[[:space:]])', 1, 1, 0, 'i');

  --log(c_module, 'STATEMENT', 'step4 pos = '||pos);
  --log(c_module, 'STATEMENT', 'regext_instr worked');
  -- l_cmt1 doesn't really contain only the comment part or attributes
  -- It may also contain the column alias.
   l_cmt1 := substr(text, 1, pos-1);
   text := substr(text, pos);
  /*---------------------------------------------------------------------+
   |                                                                     |
   |  Step 5:                                                            |
   |  Extract column alias and comment from the attributes.              |
   |                                                                     |
   |     ("A", "C", "B", "D")                                            |
   |    ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255  |
   |    NOCOMPRESS LOGGING                                               |
   |    TABLESPACE "SYSTEM"                                              |
   |    BUILD IMMEDIATE                                                  |
   |    USING INDEX                                                      |
   |    REFRESH FORCE ON DEMAND                                          |
   |    USING DEFAULT LOCAL ROLLBACK SEGMENT                             |
   |    USING ENFORCED CONSTRAINTS DISABLE QUERY REWRITE                 |
   +---------------------------------------------------------------------*/
  get_column_alias(l_cmt1, l_cmt, l_column_alias);

  /*---------------------------------------------------------------------+
   |                                                                     |
   |  Step 6:                                                            |
   |  escape single quotes in the comment.                               |
   |                                                                     |
   |     ("A", "C", "B", "D")                                            |
   |    ORGANIZATION HEAP PCTFREE 10 PCTUSED 40 INITRANS 1 MAXTRANS 255  |
   |    NOCOMPRESS LOGGING                                               |
   |    TABLESPACE "SYSTEM"                                              |
   |    BUILD IMMEDIATE                                                  |
   |    USING INDEX                                                      |
   |    REFRESH FORCE ON DEMAND                                          |
   |    USING DEFAULT LOCAL ROLLBACK SEGMENT                             |
   |    USING ENFORCED CONSTRAINTS DISABLE QUERY REWRITE                 |
   +---------------------------------------------------------------------*/
  -- Escape single quotes
   l_cmt := regexp_replace(l_cmt, '''', '''''');

  /*---------------------------------------------------------------------+
   |                                                                     |
   |  Step 7:                                                            |
   |  If comment contains PREBUILT option but table doesn't exist        |
   |        then remove it                                               |
   |                                                                     |
   +---------------------------------------------------------------------*/
/*

   Do not delete the below code. It may happen we need to reenable the code
   SELECT count(1)
   INTO   l_table_exist
   FROM   dba_tables
   WHERE  owner=nvl(upper(owner), upper('APPS'))
   AND    table_name=mvnamequot;

   if (l_table_exist = 0)
   then
      l_cmt := regexp_replace(l_cmt, 'ON PREBUILT TABLE', ' ', 1, 1, 'i');
      l_cmt := regexp_replace(l_cmt, 'WITH REDUCED PRECISION', ' ', 1, 1, 'i');
      l_cmt := regexp_replace(l_cmt, 'WITHOUT REDUCED PRECISION', ' ', 1, 1, 'i');
   end if;

--   log(c_module, 'step7 l_cmt = '||l_cmt);
*/
  /*---------------------------------------------------------------------+
   |                                                                     |
   |  Step 8:                                                            |
   |  Extract select query                                               |
   |  Hint: Extract the clause after the AS keyword from the remaining   |
   |        part                                                         |
   |                                                                     |
   |    AS select t1.a, t1.c, t2.b, t2.d from mv1 t1, mv2 t2             |
   +---------------------------------------------------------------------*/
-- Now right after ' as ' word this is the select query.
   pos := regexp_instr(text, 'AS', 1, 1, 0, 'i');
   --log(c_module, 'STATEMENT', 'step6 as position is = '||pos);
   rempart := substr(text, pos+3);

-- Now construct a MVQ ddl and its comment
   if (length(ownerquot) > 0) then
     -- log(c_module, 'STATEMENT', 'owner present');
     p_mvqdef := 'CREATE OR REPLACE VIEW '||owner||'.'||mvqname||l_column_alias||' AS '||rempart;
     -- log(c_module, 'STATEMENT', 'done string mvqdef');
     p_comment := 'COMMENT ON TABLE '||owner||'.'||mvqname||' is '''||l_cmt||'''';
     -- log(c_module, 'STATEMENT', 'done string comment');
   else
     -- log(c_module, 'STATEMENT', 'owner not present');
     p_mvqdef := 'CREATE OR REPLACE VIEW '||mvqname||l_column_alias||' AS '||rempart;
     -- log(c_module, 'STATEMENT', 'done string mvqdef');
     p_comment := 'COMMENT ON TABLE '||mvqname||' is '''||l_cmt||'''';
     -- log(c_module, 'STATEMENT', 'done string comment');
   end if;

  log(c_module, 'PROCEDURE', 'end');
END generate_mvqdef;


-- Create MV based on MVQ
procedure install_mv(p_owner varchar2,
                     p_mvname varchar2)
is
  c_module varchar2(25) := 'install_mv';
  l_mvq_name varchar2(30) := get_mvq_name(p_mvname);
  l_mv_exist number;
  l_mvq_exist number;
  l_mvl_exist number;
  l_mv_text clob;
  l_mvq_text clob;
  l_exp_mvdef clob;
  l_stmt clob;
  l_appsname varchar2(30);
  l_owner    varchar2(30);

BEGIN
   log(c_module, 'PROCEDURE', 'begin: '||p_owner||'.'||p_mvname);

   l_appsname := ad_zd.apps_schema;
   l_owner := trim(nvl(p_owner, l_appsname));

   -- Verify MVQ exists (it must)
   SELECT count(1)
   INTO   l_mvq_exist
   FROM   dba_views
   WHERE  owner=l_owner and view_name=l_mvq_name;

   if (l_mvq_exist = 0) then
      log(c_module, 'ERROR', 'Logical View '||l_mvq_name||' does not exist');
      RAISE_APPLICATION_ERROR(-20001, 'Logical View '||l_mvq_name||' does not exist');
   end if;

   -- Check if MV exists (it might)
   SELECT count(1)
   INTO   l_mv_exist
   FROM   dba_mviews
   WHERE  owner=l_owner and mview_name=p_mvname;

   if (l_mv_exist = 0) then

      log(c_module, 'STATEMENT', 'MV missing, create it');
      process_mv(l_owner, p_mvname);

   else

      log(c_module, 'STATEMENT', 'MV exists, checking definition');

      delete from ad_zd_clob
      where  owner=l_owner and name in
               (p_mvname, get_mvq_name(p_mvname));

      -- Get MV query text into CLOB
      insert into ad_zd_clob(owner, name, query)
        select owner, mview_name, to_lob(query)
        from   dba_mviews
        where  owner=l_owner and mview_name=p_mvname;

      select query into l_mv_text
      from   ad_zd_clob
      where  owner=l_owner and name=p_mvname;

      -- Get MVQ query text into CLOB
      insert into ad_zd_clob(owner, name, query)
        select owner, view_name, to_lob(text)
        from   dba_views
        where  owner=l_owner and view_name=l_mvq_name;

      select query into l_mvq_text
      from   ad_zd_clob
      where  owner=l_owner and name=l_mvq_name;

      -- Compare query text, process if different
      if (dbms_lob.compare(expand_query(l_mvq_text), l_mv_text) <> 0) then
        log(c_module, 'STATEMENT', 'MV definition is out of date, revising...');
        process_mv(l_owner, p_mvname);
      else
        $IF DBMS_DB_VERSION.VER_LE_11 $THEN
           -- No action is required
        $ELSE
           log(c_module, 'STATEMENT', 'Compiling materialized view ' ||l_owner ||'.'||p_mvname ||' with evaluate using current edition clause');
           l_stmt := 'alter materialized view '||l_owner||'."'||p_mvname||'" '|| 'evaluate using current edition';
           exec(c_module, l_stmt);
        $END
        log(c_module, 'STATEMENT', 'MV definition is up to date');
        -- possibly compile to mark as up to date
      end if;

   END IF;

   -- test if MV Log exists
   -- TODO: do not create a junk object just to store one bit of information
   select count(1) into l_mvl_exist
   from   dba_views
   where  owner=l_owner and view_name=get_mvq_name(p_mvname, g_mvl_char);

   if (l_mvl_exist > 0) then
     recreate_mvlog(l_owner, p_mvname);
   end if;


   -- If any exceptions then skip to next iteration
   log(c_module, 'PROCEDURE', 'end');
END install_mv;


-- Generate and Install MVQ
procedure install_mvq(p_mvdef clob,
                      p_owner out nocopy varchar2,
                      p_mvname out nocopy varchar2)
is
  c_module varchar2(25) := 'install_mvq';
  l_mvqdef clob;
  l_comment clob;
begin
  generate_mvqdef(p_mvdef, p_owner, p_mvname, l_mvqdef, l_comment);
  exec(c_module, l_mvqdef);
  exec(c_module, l_comment);
end;


-- Returns MV definition based on MVQ
function TRANSFORM_TO_MV(
  P_MVQDEF clob,
  P_MVQCOMMENT clob,
  P_PREBUILT number,
  P_BUILD_DEFERRED boolean default false) return clob
is
  C_MODULE varchar2(25) := 'transform_to_mv';
  L_MVDEF clob := null;
  L_MODMVQDEF clob := null;
  L_PART1 clob;
  L_ATTRIBUTES clob;
  L_PREBUILT_ATTRIBUTES clob;
  L_QUERY clob;
  L_EXPQUERY clob;
  L_POS number := 0;
  L_MVQNAME varchar2(65);
  L_MVNAME varchar2(65);
  L_COLSTRING clob;
  L_TMP1 clob;
  L_TMP2 clob;
begin
  l_modmvqdef := p_mvqdef;

  /*
  ** Remove CREATE OR REPLACE FORCE VIEW from mvq definition
  **
  **   CREATE OR REPLACE FORCE VIEW
  **     "APPS"."V1_MV#" ("A", "B", "C", "D") AS
  **     select "A","B","C","D" from mv1
  */
  l_part1 := regexp_replace(l_modmvqdef,
      '[[:space:]]*CREATE[[:space:]]+(OR[[:space:]]+REPLACE[[:space:]]+)?(FORCE[[:space:]]+)?(EDITIONABLE[[:space:]]+)?VIEW[[:space:]]+',
      '', 1, 1, 'i');

  /*
  ** Extract/remove mvq name, next word, up to '('
  **
  **     "APPS"."V1_MV#" ("A", "B", "C", "D") AS
  **     select "A","B","C","D" from mv1
  */
  l_pos := regexp_instr(l_part1, ' |\(');
  l_mvqname := substr(l_part1,1, l_pos-1);
  l_mvname :=  get_mv_name(l_mvqname);
  -- ###GB: wouldn't this be better:
  -- ###    l_part1 := substr(l_part1, l_pos);
  l_part1 := regexp_replace(l_part1, l_mvqname||'[[:space:]]*', '', 1, 1, 'i');

  log(c_module, 'STATEMENT', 'Transforming Logical Definition to MV Definition:  '||l_mvqname||' -> '||l_mvname);


  /*
  ** Extract/remove column string, up to AS keyword
  **
  **     ("A", "B", "C", "D") AS
  **     select "A","B","C","D" from mv1
  */
  l_pos := regexp_instr(l_part1,
      '([[:space:]]|'||fnd_const.newline||')?AS('||fnd_const.newline||'|[[:space:]])',
      1, 1, 0, 'i');
  if (l_pos > 0) then
    l_colstring := substr(l_part1, 1, l_pos-1);
  else
    l_colstring := ' ';
  end if;

  l_part1 := substr(l_part1, l_pos);

  /*
  ** Extract/expand query, everything after the AS keyword
  **
  **      AS
  **     select "A","B","C","D" from mv1
  */
  l_query := substr(l_part1, 4);
  l_expquery := expand_query(l_query);

  /*
  ** Extract MV attributes from MVQ comment
  **
  **     COMMENT ON TABLE "APPS"."V1_MV#" IS '<mv_attributes>'
  */
  if (nvl(p_mvqcomment,'X') <> 'X') then
    l_attributes := regexp_replace(p_mvqcomment,
        '[[:space:]]*COMMENT[[:space:]]+ON[[:space:]]+TABLE[[:space:]]+(")?(.)+(")?[[:space:]]+IS[[:space:]]+''',
        '', 1, 1, 'i');
    -- unescape quotes
    l_attributes := regexp_replace(l_attributes,'''''','''');
    -- trim space
    l_attributes := trim(l_attributes);
    -- Remove the last single quote
    l_attributes := substr(l_attributes, 1, length(l_attributes)-1);
  else
    l_attributes := ' ';
  end if;

  /*
  ** Generate or remove prebuilt table clause
  */
  if (p_prebuilt > 0) then
    l_prebuilt_attributes := include_prebuilt(l_attributes);
  elsif(p_build_deferred = true) then
    l_tmp1 := regexp_replace(l_attributes,
        'ON[[:space:]]+PREBUILT[[:space:]]+TABLE', ' ', 1, 1, 'i');
    l_tmp2 := regexp_replace(l_tmp1,
        'WITH[[:space:]]+REDUCED[[:space:]]+PRECISION', ' ', 1, 1, 'i');
    l_tmp1 := regexp_replace(l_tmp2,
        'WITHOUT[[:space:]]+REDUCED[[:space:]]+PRECISION', ' ', 1, 1, 'i');

    -- If flow come up to here means, mv has to create it as a fresh.
    -- So by default create mv with BUILD DEFERRED
    l_prebuilt_attributes := include_build(l_tmp1);
  else
    l_prebuilt_attributes := l_attributes;
  end if;

$if DBMS_DB_VERSION.VER_LE_11 $then
  l_mvdef := 'CREATE MATERIALIZED VIEW '||l_mvname||' '||l_colstring||
             ' '||l_prebuilt_attributes||' AS '||l_expquery;
$else
  if (instr(l_prebuilt_attributes, 'EVALUATE USING CURRENT EDITION') = 0) then
    if (instr(l_prebuilt_attributes, 'DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE') > 0) then
      l_prebuilt_attributes := replace(l_prebuilt_attributes, 'DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE',
                                       'EVALUATE USING CURRENT EDITION DISABLE ON QUERY COMPUTATION DISABLE QUERY REWRITE');
    elsif (instr(l_prebuilt_attributes, 'DISABLE QUERY REWRITE') > 0) then
      l_prebuilt_attributes := replace(l_prebuilt_attributes, 'DISABLE QUERY REWRITE',
                                       'EVALUATE USING CURRENT EDITION DISABLE QUERY REWRITE');
    elsif (instr(l_prebuilt_attributes, 'ENABLE ON QUERY COMPUTATION ENABLE QUERY REWRITE') > 0) then
      l_prebuilt_attributes := replace(l_prebuilt_attributes, 'ENABLE ON QUERY COMPUTATION ENABLE QUERY REWRITE',
                                       'EVALUATE USING CURRENT EDITION ENABLE ON QUERY COMPUTATION ENABLE QUERY REWRITE');
    elsif (instr(l_prebuilt_attributes, 'ENABLE QUERY REWRITE') > 0) then
      l_prebuilt_attributes := replace(l_prebuilt_attributes, 'ENABLE QUERY REWRITE',
                                       'EVALUATE USING CURRENT EDITION ENABLE QUERY REWRITE');
    else
      l_prebuilt_attributes := l_prebuilt_attributes||' EVALUATE USING CURRENT EDITION ';
    end if;
  end if;

  l_mvdef := 'CREATE MATERIALIZED VIEW '||l_mvname||' '||l_colstring||
             ' '||l_prebuilt_attributes||' AS '||l_expquery;

$end

  return l_mvdef;
END transform_to_mv;



/*******************************************************************
 *                                                                 *
 *                           PUBLIC APIS                           *
 *                                                                 *
 *******************************************************************/


/*=================================================================*
 *                     Below apis needed for xdf                   *
 *=================================================================*/

/*-----------------------------------------------------------------+
 |                                                                 |
 |  get_mvq_name                                                   |
 |     Translates MV Name into MVQ Name                            |
 |                                                                 |
 +-----------------------------------------------------------------*/
function GET_MVQ_NAME(name varchar2, ext varchar2 default ' ')
return varchar2
IS
BEGIN
   if (ext = ' ')
   then
      return convert_name(name, 1, g_mvq_char);
   else
      return convert_name(name, 1, ext);
   end if;
end;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  GET_MV_NAME                                                    |
 |     Translates MVQ Name into MV Name                            |
 |                                                                 |
 +-----------------------------------------------------------------*/
function GET_MV_NAME(name varchar2, ext varchar2 default ' ')
return varchar2
IS
BEGIN
   if (ext = ' ')
   then
      return convert_name(name, 0, g_mvq_char);
   else
      return convert_name(name, 0, ext);
   end if;
end;


/*=================================================================*
 *                     Below apis needed for ad_mv                 *
 *=================================================================*/

/*-----------------------------------------------------------------+
 |                                                                 |
 | INSTALL_MVQ_ARCH                                                |
 |                                                                 |
 |      p_mvdef  => MV ddl                                         |
 |      p_skipmv => 1  Only installs MVQ. This mode will be used   |
 |                     from patch                                  |
 |                  0  Installs both MVQ and MV. Assumes that MV   |
 |                     doesn't exist                               |
 |    Installs MVQ and expanded MV                                 |
 |    Called from patch and ad_mv                                  |
 +-----------------------------------------------------------------*/
procedure INSTALL_MVQ_ARCH(p_mvdef CLOB,
                           p_skipmv number default 0)
IS
c_module varchar2(25) := 'install_mvq_arch';
l_owner varchar2(65);
l_mvname varchar2(65);
BEGIN
  log(c_module, 'PROCEDURE', 'begin');
  install_mvq(p_mvdef, l_owner, l_mvname);

  if (p_skipmv = 0)
  then
    install_mv(l_owner, l_mvname);
  end if;
  log(c_module, 'PROCEDURE', 'end');
end;

/*+----------------------------------------------------------------+
  |                                                                |
  | DROP_MVQ                                                       |
  |                                                                |
  |    Takes the MV Owner and MV Name and drop its                 |
  |      corresponding MVQ.                                        |
  |    Mainly this api is used in ad_mv package while              |
  |    droping the MView                                           |
  +----------------------------------------------------------------+*/

procedure DROP_MVQ(p_owner varchar2 default ' ',
                   p_mvname varchar2)
is
c_module varchar2(25) := 'drop_mvq';
l_mvname varchar2(30);
l_exist number;
l_statement varchar2(200);
l_appsname varchar2(30);
l_owner varchar2(30);
begin
   log(c_module, 'PROCEDURE', 'begin: '||p_owner||'.'||p_mvname);

   l_appsname := ad_zd.apps_schema;
   if(length(trim(nvl(p_owner, ' '))) > 0)
   then
      l_owner := upper(trim(p_owner));
   else
      l_owner := l_appsname;
   end if;
   SELECT count(1)
   INTO   l_exist
   FROM   dba_views
   WHERE  owner=l_owner
   AND    view_name=get_mvq_name(p_mvname)
   AND    EDITIONING_VIEW='N';

   If (l_exist > 0)
   then
      log(c_module, 'STATEMENT', 'Dropping Logical View: '||get_mvq_name(p_mvname));
      l_statement := 'DROP VIEW '||l_owner||'."'||get_mvq_name(p_mvname)||'" CASCADE CONSTRAINTS';
      exec(c_module, l_statement);
   end if;

   SELECT count(1)
   INTO   l_exist
   FROM   dba_views
   WHERE  owner=l_owner
   AND    view_name=get_mvq_name(p_mvname, g_mvl_char)
   AND    EDITIONING_VIEW='N';

   If (l_exist > 0)
   then
      l_statement := 'DROP VIEW '||l_owner||'."'||get_mvq_name(p_mvname, g_mvl_char)||'" CASCADE CONSTRAINTS';
      exec(c_module, l_statement);
   end if;

   SELECT count(1)
   INTO   l_exist
   FROM   dba_views
   WHERE  owner=l_owner
   AND    view_name=get_mvq_name(p_mvname, g_mvm_char)
   AND    EDITIONING_VIEW='N';

   If (l_exist > 0)
   then
      l_statement := 'DROP VIEW '||p_owner||'."'||get_mvq_name(l_mvname, g_mvm_char)||'" CASCADE CONSTRAINTS';
      exec(c_module, l_statement);
   end if;
   log(c_module, 'PROCEDURE', 'end');
end;


/*=================================================================*
 *                     Below apis given by GB                      *
 *=================================================================*/

/*-----------------------------------------------------------------+
 |                                                                 |
 |  PATCH                                                          |
 |     This api would be called from two places. One from xdf file |
 |     And other place is from FIX_MATERIALIZED_VIEWS procedure.   |
 |                                                                 |
 |     Input :- "CREATE MATERIALIZED VIEW "owner"."mvname"....     |
 |                 statement                                       |
 |     Database always gives the ddl in the above format.          |
 |     And xdf also should give in the same above format           |
 |                                                                 |
 |     Tasks :-                                                    |
 |          1. Parse the given mv ddl and generate MVQ definition  |
 |             and its corresponding comment.                      |
 |          2. Execute both the above MVQ ddl and comment stmts.   |
 |                                                                 |
 |     Notes :- MVQ is just a normal view in db                    |
 |              All the Mview attributes will be added as          |
 |              comments to MVQ                                    |
 |                                                                 |
 +-----------------------------------------------------------------*/
-- TODO: Try to use the dbms_metadata to convert the ddl into xml format
-- always do execute immediate. Because it installs only MVQ
procedure PATCH(p_mvdef CLOB)
is
c_module varchar2(25) := 'patch';
l_mvqdef CLOB;
l_comment CLOB;
l_mvdef CLOB;
BEGIN
  log(c_module, 'PROCEDURE', 'begin');
  install_mvq_arch(p_mvdef => p_mvdef,
                   p_skipmv => 1);
  log(c_module, 'PROCEDURE', 'end');
end;

/*-----------------------------------------------------------------+
 |                                                                 |
 | PATCH                                                           |
 |                                                                 |
 |      p_owner       => owner                                     |
 |      p_name        => object name                               |
 |      p_type        => object type. default is null              |
 |                                                                 |
 |                                                                 |
 |    Notes: This api will actualize the mvq for those mviews      |
 |           which are dependent on the given object               |
 |                                                                 |
 |           Later in the cutover these mviews will be recreated   |
 |           so that the new/revised vpd policies will be involed  |
 |           in the expanded mview definition                      |
 +-----------------------------------------------------------------*/
procedure PATCH(p_owner varchar2,
                p_name varchar2,
                p_type varchar2 default null)
IS
c_module varchar2(25) := 'patch';

cursor depobjs is
SELECT owner,
       name
FROM   dba_dependencies
WHERE  referenced_name=upper(p_name)
AND    referenced_owner=upper(p_owner)
AND    referenced_type=upper(nvl(p_type, referenced_type))
AND    type='MATERIALIZED VIEW';

l_exist number;
l_mvqname varchar2(30);
BEGIN
   if (p_owner is null or p_name is null) then
       log(c_module, 'ERROR','Either p_owner or p_name is null');
       raise_application_error(-20001, 'null passed to one of the parameter');
   end if;

   for obj in depobjs
   loop
      l_mvqname := get_mvq_name(obj.name);
      SELECT count(1)
      INTO   l_exist
      FROM   dba_views
      WHERE  owner=obj.owner
      AND    view_name=l_mvqname;

      if (l_exist > 0)
      then
         exec(c_module,
              'alter view '||obj.owner||'.'||l_mvqname||' compile');
      end if;

   end loop;
end;


-- Generate MV create statement from MVQ
function GENERATE(p_owner varchar2,
                  p_mvname varchar2,
                  p_build_deferred boolean) return clob
is
  c_module varchar2(25) := 'generate';
  l_mvq_name varchar2(30) := get_mvq_name(p_mvname);
  l_mvqdef CLOB;
  l_mvdef CLOB := null;
  l_tmpmvdef CLOB := null;
  l_mvqcomment CLOB;
  l_mvq_exist number;
  l_prebuilt number;
  l_dummy1 varchar2(100);
  l_dummy2 varchar2(100);
begin
  -- Get MVQ definition
  select count(1) into l_mvq_exist
  from   dba_views
  where  owner=p_owner and view_name=l_mvq_name;

  if (l_mvq_exist > 0) then
    get_mvq_definition(p_owner, l_mvq_name, l_mvqdef, l_mvqcomment);
  else
    l_tmpmvdef := dbms_metadata.get_ddl('MATERIALIZED_VIEW', p_mvname, p_owner);
    generate_mvqdef(l_tmpmvdef, l_dummy1, l_dummy2, l_mvqdef, l_mvqcomment);
  end if;

  -- Check for Prebuilt table
  select count(1) into l_prebuilt
  from   dba_tables
  where  owner=p_owner and table_name=p_mvname;

  if ('X' <> nvl(l_mvqdef, 'X')) then
    l_mvdef := transform_to_mv(l_mvqdef, l_mvqcomment, l_prebuilt, p_build_deferred);
  end if;

  return l_mvdef;
end;

-- Generate MV create statement from MVQ
function GENERATE(p_owner varchar2,
                  p_mvname varchar2) return clob
is
begin
  return generate(p_owner, p_mvname, false);
end;


/*-----------------------------------------------------------------+
 |                                                                 |
 |  PATCH_LOG                                                      |
 |     Revise MVLogs                                               |
 |                                                                 |
 |  Tasks :-                                                       |
 |      This api would be called from finalize                     |
 |      Refreshes all the patched tables if outdated               |
 |                                                                 |
 | TODO : Create MVLOG using PURGE syntax                          |
 |                                                                 |
 +-----------------------------------------------------------------*/
procedure PATCH_LOG(p_owner varchar2,
                    p_tabname varchar2)
is
c_module varchar2(25) := 'patch_log';

cursor mvlogcols(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
  select basecol, latestcol, mvlcol
  from
    (
      select
          ad_zd_table.ev_view_column(mvlc.column_name) as basecol
        , max(tabc.column_name) as latestcol
        , max(mvlc.column_name) as mvlcol
      from
          dba_tab_cols tabc
        , dba_mview_log_filter_cols mvlc
      where mvlc.owner   = x_table_owner
        and mvlc.name    = x_table_name
        and tabc.owner      = mvlc.owner
        and tabc.table_name = mvlc.name
        and ad_zd_table.ev_view_column(tabc.column_name) =
              ad_zd_table.ev_view_column(mvlc.column_name)
      group by ad_zd_table.ev_view_column(mvlc.column_name)
      order by ad_zd_table.ev_view_column(mvlc.column_name)
    )
  where latestcol<>mvlcol;

l_first boolean := TRUE;
l_query CLOB;
l_latest_name_inmvlog DBA_MVIEW_LOG_FILTER_COLS.column_name%TYPE;

BEGIN
  log(c_module, 'PROCEDURE', 'begin: '||p_owner||'.'||p_tabname);

  l_query := 'ALTER MATERIALIZED VIEW LOG FORCE ON '||p_owner||
            '.'||p_tabname||' ADD (';
  for mvlogcol in mvlogcols(p_owner, p_tabname)
  loop
    IF(l_first = TRUE)
    THEN
       l_query := l_query||mvlogcol.latestcol||' ';
       l_first := FALSE;
    ELSE
       l_query := l_query||', '||mvlogcol.latestcol;
    END IF;
  end loop;

  IF(l_first = FALSE)
  THEN
     l_query := l_query||') INCLUDING NEW VALUES';
  exec(c_module, l_query);
  END IF;
  log(c_module, 'PROCEDURE', 'end');
end;


/*
** FINALIZE
**   - Patch MV Log tables with revised columns
**   - Store upgrade call for MVs with revised definition
**   - Store DDL to alter evaluation edition
*/
procedure FINALIZE
is
  C_MODULE           varchar2(25) := 'finalize';
  L_MVLOG_EXIST      number := 0;
  L_STMT             clob;
  type MV_LIST_T     is table of binary_integer index by varchar2(64);
  L_MV_LIST          mv_list_t;
  -- patched tables
  cursor C_PATCHED_TABLES is
    select owner, name
    from   ad_patched_tables;

  -- out of date MVs
  cursor C_OOD_MVS is
    select
        emv.owner     owner
      , emv.lv_name   lv_name
      , emv.lv_status lv_status
      , emv.mv_name   mv_name
    from
      ( select
            lvv.owner     owner
          , lvv.view_name lv_name
          , lvx.actual lv_actual
          , lvx.status lv_status
          , case when lvx.actual='N' then
                 case when lvx.status='VALID' then NULL else sysdate end
            else
                lvx.mtime
            end lv_changed
          , ad_zd_mview.get_mv_name(lvv.view_name) mv_name
          , mvo.created   mv_changed
        from
            ad_objects lvx
          , dba_views lvv
          , dba_objects mvo
        where lvv.owner in
                ( select oracle_username from ebs_system.fnd_oracle_userid
                  where  read_only_flag in ('A', 'E', 'U', 'B') )
          and not exists
            ( select 'X'
              from   fnd_oracle_userid fou
                   , fnd_product_installations fpi
                   , ad_obsolete_objects aoo
              where fpi.application_id  = aoo.application_id
                and ( fou.oracle_id     = fpi.oracle_id
                or fou.read_only_flag   = 'U')
                and fou.oracle_username = lvv.owner
                and aoo.object_name = substr(lvv.view_name, 1, length(lvv.view_name)-1))
          and lvv.view_name like '%#'
          and lvv.editioning_view = 'N'
          and lvx.owner  = lvv.owner
          and lvx.object_name   = lvv.view_name
          and lvx.object_type   = 'VIEW'
          and mvo.owner(+)       = lvv.owner
          and mvo.object_name(+) = substr(lvv.view_name, 1, length(lvv.view_name)-1)
          and mvo.object_type(+) = 'MATERIALIZED VIEW' ) emv
    where (emv.lv_status = 'INVALID' or
           (emv.lv_actual = 'Y' and (emv.mv_changed is null or emv.lv_changed > emv.mv_changed)));

  cursor C_MVS is
    select mv.owner,
           mv.mview_name
    from   dba_mviews mv
    where mv.owner in
            ( select oracle_username from fnd_oracle_userid
              where  read_only_flag in ('A', 'E', 'U', 'B') )
      and mv.mview_name not like '%$';   /* Ignore interim MV created for Table-Redefinition */

begin
  log(c_module, 'PROCEDURE', 'begin');

  -- check if patched table has MV logs
  for ptbl in c_patched_tables loop
    begin
      select 1 into l_mvlog_exist from dual
      where exists (select null
                    from  dba_mview_logs
                    where log_owner = ptbl.owner
                      and master    = ptbl.name);

      log(c_module, 'STATEMENT', 'Revising MV Log on table '||ptbl.owner||'.'||ptbl.name);
      patch_log(ptbl.owner, ptbl.name);
    exception
      when no_data_found then
        null;
    end;
  end loop;


  -- check for materialized view queries that have been touched
  for mv in c_ood_mvs loop
     -- store cutover action
     l_stmt := 'begin '||ad_zd.apps_schema||'.ad_zd_mview.upgrade('''||
                mv.owner||''','''||mv.mv_name||'''); end;';

     log(c_module, 'STATEMENT', 'Storing cutover action for: '||mv.mv_name);
     ad_zd_parallel_exec.load('CUTOVER', l_stmt, true);
     $if not DBMS_DB_VERSION.VER_LE_11 $then
       l_mv_list(mv.owner|| '.'||mv.mv_name) := 1;
     $end
  end loop;


$if DBMS_DB_VERSION.VER_LE_11 $then
  -- no MV evaliation edition syntax in DB 11
$else
  log(c_module, 'STATEMENT', 'Storing MV evaluation edition cutover DDLs');
  for mv in c_mvs loop
     -- Don't Store DDL if MV (or MV#) has been changed as within ad_zd_mview.upgrade()
     -- "evaluate using current edition" DDL will be executed for same MV.
     -- This is to avoid "ORA-12003: materialized view does not exist" during parallel
     -- CUTOVER DDL processing.
     if( l_mv_list.exists(mv.owner||'.'||mv.mview_name)) then
        null;
     else
       -- store cutover action
       l_stmt := 'alter materialized view '||mv.owner||'."'||mv.mview_name||'" '||
                      'evaluate using current edition';
       ad_zd_parallel_exec.load('CUTOVER', l_stmt, true);
     end if;
  end loop;
$end

  log(c_module, 'PROCEDURE', 'end');
  commit;

end FINALIZE;


/*
** CUTOVER
**   -- no action here, cutover DDL is pre-computed in finalize
*/
procedure CUTOVER(x_execute number default 0)
is
  C_MODULE varchar2(25) := 'cutover';
BEGIN
  null;
end;


/*
** Upgrade MV for Online Patching
**
** Note: can be called repeatedly during development
** for new or changed Logical Definitions (MV#)
*/
procedure UPGRADE(p_owner varchar2,
                  p_mview_name varchar2)
is
  c_module varchar2(25) := 'upgrade';
  l_mvdef clob;
  l_mvq_exist number;
  l_dummy1 varchar2(100);
  l_dummy2 varchar2(100);
BEGIN
  log(c_module, 'PROCEDURE', 'begin: '||p_owner||'.'||p_mview_name);

  -- Check if MVQ exist or not
  select count(1)
  into   l_mvq_exist
  from   dba_views
  where  owner=p_owner
  and    view_name=get_mvq_name(p_mview_name);

  -- if MVQ does not exist, create it
  if (l_mvq_exist = 0) then
    -- Dont get the query directly from data dictionary. Because
    -- from ad_mv if the mv is new then the api cannot get the sql query
    -- from data dictionary. It has to parse query only.
    l_mvdef := dbms_metadata.get_ddl('MATERIALIZED_VIEW', p_mview_name, p_owner);
    install_mvq(l_mvdef, l_dummy1, l_dummy2);
  end if;

  -- Create MV Implementation from Logical Definition
  install_mv(p_owner, p_mview_name);

  log(c_module, 'PROCEDURE', 'end');
end;

/*+----------------------------------------------------------------+
  |                                                                |
  | UPGRADE_DB                                                     |
  |                                                                |
  |    Main api to be called from AD_ZD_PREP                       |
  |                                                                |
  +----------------------------------------------------------------+*/

procedure UPGRADE_DB(x_execute number default 1)
is
  C_MODULE varchar2(25) := 'upgrade_db';

  -- MVs to upgrade
  cursor C_MVS is
    select m.owner owner,
           m.mview_name name
    from   dba_mviews m
    where m.owner in
            ( select oracle_username from fnd_oracle_userid
              where  read_only_flag in ('A', 'E', 'U', 'B') )
      /* To handle restart MV case where MVQ is created and MV is not */
      --and not exists
      --    ( select 'X' from dba_views v
      --      where  v.owner = m.owner
      --      and    v.view_name = ad_zd_mview.get_mvq_name(m.mview_name) )
      and not exists
            ( select 'X'
              from   fnd_oracle_userid fou
                   , fnd_product_installations fpi
                   , ad_obsolete_objects aoo
              where fpi.application_id  = aoo.application_id
                and ( fou.oracle_id       = fpi.oracle_id
                or  fou.read_only_flag='U' )
                and fou.oracle_username = m.owner
                and aoo.object_name     = m.mview_name
                and aoo.object_type     = 'MATERIALIZED VIEW' )
    union
    select v.owner owner,
           ad_zd_mview.get_mv_name(v.view_name) name
    from   dba_views v
    where v.view_name like '%'||'#'
      and v.editioning_view = 'N'
      and v.owner in
            ( select oracle_username from fnd_oracle_userid
              where  read_only_flag in ('A', 'E', 'U', 'B') )
      and not exists
            ( select 'X' from dba_objects m
              where m.owner      = v.owner
                and m.object_name = ad_zd_mview.get_mv_name(v.view_name)
                and m.object_type = 'MATERIALIZED VIEW'
                and m.status      = 'VALID' )
      and not exists
            ( select 'X'
              from   fnd_oracle_userid fou
                   , fnd_product_installations fpi
                   , ad_obsolete_objects aoo
              where fpi.application_id  = aoo.application_id
                and ( fou.oracle_id       = fpi.oracle_id
                or fou.read_only_flag = 'U')
                and fou.oracle_username = v.owner
                and aoo.object_name     = v.view_name
                and aoo.object_type     = 'VIEW' );

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_execute);

  for obj in c_mvs loop
    if (x_execute = 1) then
      upgrade(obj.owner, obj.name);
    else
      ad_zd_parallel_exec.load(
          ad_zd_parallel_exec.c_phase_upgrade_mview,
          'begin '||ad_zd.apps_schema||'.ad_zd_mview.upgrade('''||
                    obj.owner||''','''||obj.name||'''); end;');
    end if;
  end loop;

  log(c_module, 'PROCEDURE', 'end');
end;

/*+----------------------------------------------------------------+
  |                                                                |
  | DROP_MV                                                        |
  |                                                                |
  |   - Drops the given materialized view and its logical view     |
  |     If Running in PATCH edition                                |
  |         Stores deferred DDL to drop MV in next CLEANUP         |
  |     If running in RUN edition                                  |
  |         Drops MV immediately                                   |
  |                                                                |
  +----------------------------------------------------------------+*/

procedure DROP_MV (
              X_MVIEW_OWNER    in  varchar2,
              X_MVIEW_NAME     in  varchar2,
              X_DROP_STMT      in  varchar2,
              X_UPD_STMT       in  varchar2,
              X_DROPPED        out nocopy varchar2 )
is
  C_MODULE varchar2(80) := 'DROP_MV';
  l_mv_owner varchar2(30);
  l_lv_name     varchar2(30);
  l_appsname    varchar2(30);
  l_defer_stmt  varchar2(2000);
begin
  l_appsname := ad_zd.apps_schema;
  l_mv_owner := trim(nvl(x_mview_owner, l_appsname));
  log(C_MODULE, 'PROCEDURE', 'begin: '|| l_mv_owner ||'.'||x_mview_name);

  -- Drop Logical view pointing to the materialized view
  ad_zd_mview.drop_mvq(l_mv_owner, x_mview_name);

  -- (Deferred) drop materialized view logic
  if ad_zd.get_edition_type = 'RUN' then
    -- Drop materialized view
    log(c_module, 'STATEMENT', 'Drop MV '||l_mv_owner||'.'||x_mview_name);
    begin
      exec(c_module, x_drop_stmt);

      -- Update dropped status
      if (x_upd_stmt is not null) then
        exec(c_module, x_upd_stmt);
      end if;

      X_DROPPED := 'Y';

    exception
      when others then
        -- ORA-12003 is materialized view doesn't exist.
        if (sqlcode <> -12003) then
          log(c_module, 'ERROR', 'Error while dropping MV '
          ||l_mv_owner||'.'||x_mview_name || ': ' || substr(sqlerrm, 1, 2000));

          X_DROPPED := 'N';

        else
          -- MV doesn't exist. Update dropped status to 'Y'
          if (x_upd_stmt is not null) then
            exec(c_module, x_upd_stmt);
          end if;

          X_DROPPED := 'Y';

        end if;
    end;

  else  -- If running from PATCH edition

    -- Defer drop MV to next cleanup
    log (c_module, 'STATEMENT', 'Defer drop MV ' ||
         l_mv_owner||'.'||x_mview_name|| ' to next cleanup');

    -- TODO: add update statement
    if (x_upd_stmt is not null) then
       l_defer_stmt := 'begin execute immediate '''|| regexp_replace(x_drop_stmt, '''', '''''')  || '''; ' ||
                           'execute immediate ''' || regexp_replace(x_upd_stmt, '''', '''''') ||
                         '''; exception when others then null; end;';

      ad_zd.load_ddl ('CLEANUP', l_defer_stmt);
    else
      ad_zd.load_ddl ('CLEANUP', x_drop_stmt);
    end if;

    -- Return 'N' as the table object is not deleted yet.
    X_DROPPED := 'N';
  end if;

  log( c_module, 'PROCEDURE', 'end');
  commit;
end DROP_MV;

END AD_ZD_MVIEW;