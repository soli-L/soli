
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_NE" AUTHID CURRENT_USER as
/* $Header: ADZDNES.pls 120.0.12020000.2 2016/10/04 11:25:17 sstomar noship $ */

/*
** Utility Functions (Public)
*/

  function LV_VIEW(X_TABLE_NAME in varchar2) return varchar2;
    pragma restrict_references (lv_view, rnds, wnds, rnps, wnps);

  function LV_VIEW_COLUMN(X_COLUMN_NAME in varchar2) return varchar2;
    pragma restrict_references (lv_view_column, rnds, wnds, rnps, wnps);

  function GET_ROWSET(
             X_TABLE_OWNER in varchar2,
             X_TABLE_NAME in varchar2) return varchar2;


/*
** Patch APIs (public)
*/
  procedure GENERATE_LV(
              X_TABLE_OWNER   in varchar2,
              X_TABLE_NAME    in varchar2);

  procedure CUTOVER(X_OWNER in varchar2);

end AD_ZD_NE;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_NE" as
/* $Header: ADZDNEB.pls 120.0.12020000.2 2016/10/04 11:28:32 sstomar noship $ */

/*
** --------------------------------------------------------------------
**    Internal
** --------------------------------------------------------------------
*/

-- log shortcut
procedure LOG(X_MODULE varchar2, X_LOG_TYPE varchar2, X_MESSAGE varchar2) is
begin
  --ad_zd.log(x_module, x_log_type, x_message);
  null;
end;

-- error shortcut
procedure ERROR(X_MODULE varchar2, X_MESSAGE varchar2) is
begin
  raise_application_error(-20001, '('||x_module||'), '||x_message);
end;

-- exec shortcut (varchar2)
procedure EXEC(
  X_SQL        in varchar2,
  X_LOG_MOD    in varchar2,
  X_IGNORE     in boolean default false) is
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
      error(x_log_mod, SQLERRM||', SQL: '||x_sql);
    end if;
end;


/* ==========================================================================================
**
**    Logical View Utility Functions
**
** =========================================================================================*/

--
-- Return Logical View name for given Table
--
function LV_VIEW(X_TABLE_NAME in varchar2) return varchar2 is
begin
  return substrb(x_table_name,1,29)||'#';
end;

--
-- Return LV View Column name for given Table Column
--
function LV_VIEW_COLUMN(X_COLUMN_NAME in varchar2) return varchar2 is
begin
  if x_column_name like '%#_%' then
    -- this is a versioned column, strip the version
    return substrb(x_column_name, 1, instrb(x_column_name,'#',-1)-1);
  end if;
  return x_column_name;
end;

--
-- Get run edition rowset for seed data table
--
function GET_ROWSET(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME in varchar2) return varchar2
is
  L_SQL    varchar2(1000);
  L_ROWSET varchar2(30);
begin
  l_sql := 'select zd_edition_name'||
           ' from '||x_table_name||'@'||x_table_owner||
           ' where rownum=1';

  begin
    execute immediate l_sql into l_rowset;
  exception
    when others then
      error('get_rowset', SQLERRM||', SQL: '||l_sql);
  end;

  return l_rowset;
end;




--
-- Generate Logical View
--
-- Generates an Logical View for the specified table.
-- Table columns have names with the following structure
--
--       <logical_name>[#<version>]
--
-- The generated Logical View will map each logical column name
-- to the latest version table column for that logical name.
--
procedure GENERATE_LV(
  X_TABLE_OWNER       varchar2,
  X_TABLE_NAME        varchar2 )
is
  C_MODULE            varchar2(127) := 'ad.plsql.ad_zd_ne.generate_lv';
  L_LV_NAME           varchar2(30);
  L_LV_STMT           varchar2(32676);
  L_LV_LOB_STMT       clob;
  L_FIRST             boolean;
  L_SEED              boolean;

  cursor C_LV_COLUMNS(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
    select lvc.view_column_name, lvc.table_column_name, lvc.view_column_id
    from (select
              ad_zd_ne.lv_view_column(col.column_name) view_column_name
            , max(col.column_name) table_column_name
            , min(col.column_id) view_column_id
          from all_tab_columns col
          where col.owner      = x_table_owner
            and col.table_name = x_table_name
          group by ad_zd_ne.lv_view_column(col.column_name)) lvc
    where not exists (
      select 'x' from all_col_comments cmt
      where cmt.owner       = x_table_owner
        and cmt.table_name  = x_table_name
        and cmt.column_name = lvc.table_column_name
        and upper(cmt.comments) = 'OBSOLETE' )
    order by lvc.view_column_id;

begin

  -- set up LV creation statement
  l_lv_name := lv_view(x_table_name);
  l_lv_stmt := 'create or replace view  "'||
                x_table_owner||'"."'||l_lv_name||'" as select ';

  log(c_module, 'STATEMENT', 'Generate LV '||x_table_owner||'.'||l_lv_name);

  begin
    -- Loop thru each LV column
    l_first := true;
    l_seed  := false;
    for lvcrec in c_lv_columns(x_table_owner, x_table_name) loop

      -- add initial statement or separater as needed
      if l_first then
        l_first := false;
        dbms_lob.createtemporary (l_lv_lob_stmt, false, DBMS_LOB.CALL);
        dbms_lob.writeappend(lob_loc => l_lv_lob_stmt,
                             amount  => length(l_lv_stmt),
                             buffer  => l_lv_stmt);
      else
        l_lv_stmt := ', ';
        dbms_lob.writeappend(lob_loc => l_lv_lob_stmt,
                             amount  => length(l_lv_stmt),
                             buffer  => l_lv_stmt);
      end if;

      -- add column mapping to LV creation statement
      l_lv_stmt := lvcrec.table_column_name||' '||lvcrec.view_column_name;
      dbms_lob.writeappend(lob_loc => l_lv_lob_stmt,
                           amount  => length(l_lv_stmt),
                           buffer  => l_lv_stmt);

      -- remember of this is a seed data table
      if (lvcrec.table_column_name = 'ZD_EDITION_NAME') then
        l_seed := true;
      end if;
    end loop;

    -- if no rows returned something is wrong
    if (l_lv_lob_stmt is null or dbms_lob.getlength(l_lv_lob_stmt) = 0 ) then
      error(c_module, 'Table does not exist: '||x_table_owner||'.'||x_table_name);
    end if;

    -- complete the LV creation statement and execute
    l_lv_stmt := ' from "'||x_table_owner||'"."'||x_table_name||'"';
    dbms_lob.writeappend(lob_loc => l_lv_lob_stmt,
                         amount  => length(l_lv_stmt),
                         buffer  => l_lv_stmt);

    -- for seed data tables, add rowset filter
    if (l_seed) then
      l_lv_stmt := ' where zd_edition_name = '''||get_rowset(x_table_owner, x_table_name)||'''';
      dbms_lob.writeappend(lob_loc => l_lv_lob_stmt,
                           amount  => length(l_lv_stmt),
                           buffer  => l_lv_stmt);
    end if;

    exec(l_lv_lob_stmt, c_module);
    dbms_lob.freeTemporary(l_lv_lob_stmt);

  exception
    when others then
      if (dbms_lob.isTemporary(l_lv_lob_stmt)=1) then
        dbms_lob.freeTemporary(l_lv_lob_stmt);
      end if;
      error(c_module, 'Could not generate logical view for '||x_table_owner||'.'||x_table_name);
  end;

end GENERATE_LV;


/*
** --------------------------------------------------------------------
**    Event Interfaces
** --------------------------------------------------------------------
*/


/*
** Cutover Table
**
** X_TABLE_OWNER - table owner
** X_TABLE_NAME  - table name
**
** Cutover revised indexes
** Set obsolete columns to nullable
** remove obsolete column constraints
**
** Note: X_EXECUTE is unused and should be eliminated.  Storage of cutover DDL
** is done in the FINALIZE call.
*/
procedure CUTOVER(X_OWNER in varchar2)
is
  C_MODULE   varchar2(80) := 'ad.plsql.ad_zd_ne.cutover';

  cursor C_LVS(X_OWNER in varchar2) is
    select tab.table_name, lv.view_name
    from all_tables tab, all_views lv
    where tab.owner = x_owner
      and lv.owner = tab.owner
      and lv.view_name = substrb(tab.table_name, 1, 29)||'#'
    order by tab.table_name;

begin
  log(c_module, 'PROCEDURE', 'begin');

  -- re-generate all existing logical views
  for vrec in c_lvs(x_owner) loop
    generate_lv(x_owner, vrec.table_name);
  end loop;

  log(c_module, 'PROCEDURE', 'end');
end CUTOVER;


end;
