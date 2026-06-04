
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_TABLE" AUTHID CURRENT_USER as
/* $Header: ADZDTMS.pls 120.27.12020000.11 2015/07/14 12:21:29 rraam ship $ */



/*
** Utility Functions (Public)
*/

  function EV_EXISTS(
               X_TABLE_OWNER in varchar2,
               X_TABLE_NAME  in varchar2) return varchar2;
    pragma restrict_references (ev_exists, wnds, rnps, wnps);

  function EV_VIEW (
              X_TABLE_NAME     in varchar2 ) return varchar2;
    pragma restrict_references (ev_view, rnds, wnds, rnps, wnps);

  function EV_TABLE (
              X_EV_OWNER       in varchar2,
              X_EV_NAME        in varchar2 ) return varchar2;
    pragma restrict_references (ev_table, wnds, rnps, wnps);

  function EV_VIEW_COLUMN (
              X_COLUMN_NAME    in varchar2 ) return varchar2;
    pragma restrict_references (ev_view_column, rnds, wnds, rnps, wnps);

  function EV_TABLE_COLUMN(
              X_EV_OWNER       in varchar2,
              X_EV_NAME        in varchar2,
              X_COLUMN_NAME    in varchar2) return varchar2;
  pragma restrict_references (ev_table_column, wnds, rnps, wnps);

  function EV_TABLE_COLUMN_REVISION(
	      X_COLUMN_NAME    in varchar2) return varchar2;
  pragma restrict_references (ev_table_column_revision, rnds, wnds, rnps, wnps);

  function IS_SEED (
              X_TABLE_OWNER    in varchar2,
              X_TABLE_NAME     in varchar2 ) return varchar2;
    pragma restrict_references (is_seed, wnds, rnps, wnps);


/*
** Upgrade APIs (public)
*/

  procedure UPGRADE (
              X_TABLE_OWNER    in varchar2,
              X_TABLE_NAME     in varchar2 );

  procedure UPGRADE_DB;

  procedure DOWNGRADE (
              X_TABLE_OWNER    in varchar2,
              X_TABLE_NAME     in varchar2 );


  procedure DROP_TABLE (
              X_TABLE_OWNER    in  varchar2,
              X_TABLE_NAME     in  varchar2,
              X_DROP_STMT      in  varchar2,
              X_UPD_STMT       in  varchar2,
              X_DROPPED        out nocopy varchar2);
/*
** Index APIs (internal)
*/

  function REVISED_INDEX_NAME(X_ORIGINAL_INDEX_NAME in varchar2) return varchar2;
  function REVISED_INDEX_REGEXP return varchar2;

  function ORIGINAL_INDEX_NAME(X_REVISED_INDEX_NAME in varchar2) return varchar2;
  function ORIGINAL_INDEX_REGEXP return varchar2;


  procedure REVISE_INDEXES (
              X_TABLE_OWNER    in varchar2,
              X_TABLE_NAME     in varchar2);

  procedure CUTOVER_INDEXES (
              X_TABLE_OWNER    in varchar2,
              X_TABLE_NAME     in varchar2);
/*
** Patch APIs (public)
*/
  procedure PATCH (
              X_TABLE_OWNER   in varchar2,
              X_TABLE_NAME    in varchar2 );

  procedure APPLY ( X_CET_NAME in varchar2);


/*
** Patch APIs (internal)
*/

  procedure FINALIZE;

  procedure CUTOVER (
              X_TABLE_OWNER   in varchar2 default NULL,
              X_TABLE_NAME    in varchar2 default NULL,
              X_EXECUTE       in boolean  default true );

  procedure CLEANUP (
              X_TABLE_OWNER   in varchar2 default NULL,
              X_TABLE_NAME    in varchar2 default NULL,
              X_CLEAN_MODE    in varchar2 default 'QUICK' );

  procedure ABORT;

  procedure OBSOLETE_COLUMN(
              X_TABLE_OWNER    in     varchar2,
              X_TABLE_NAME     in     varchar2,
              X_COLUMN_NAME    in     varchar2);

  procedure REVOKE_INVALID_GRANTS (
               X_OBJ_OWNER            in varchar2,
               X_OBJ_NAME             in varchar2,
               X_BASE_OBJ_OWNER       in varchar2 default NULL,
               X_BASE_OBJ_NAME        in varchar2 default NULL,
               X_EXCEPTION_LIST       in varchar2 default NULL);

end AD_ZD_TABLE;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_TABLE" as
/* $Header: ADZDTMB.pls 120.78.12020000.86 2023/04/12 00:11:07 jwsmith ship $ */

/*
** --------------------------------------------------------------------
**    Internal
** --------------------------------------------------------------------
*/

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

-- Util function to get Newline
function local_chr(ascii_chr in number) return varchar2 is
    lang varchar2(255);
 begin
    lang := userenv('LANGUAGE');
    return(convert(chr(ascii_chr),
                   substr(lang, instr(lang,'.') + 1), 'US7ASCII'));
 end local_chr;

/*
** Stores patched table name for finalize and cutover processing
** AD_PATCHED_TABLES.STATUS:
**   'N' - New
**   'C' - Completed
**   'U' - Updated
*/
procedure STORE(X_TABLE_OWNER in varchar2, X_TABLE_NAME  in varchar2) is
  L_STATUS varchar2(1);
begin

  -- Get existing table status
  select status
  into   l_status
  from   ad_patched_tables
  where  owner = x_table_owner
  and    name  = x_table_name;

  -- Set "Completed" table back "Updated" status
  if (l_status = 'C') then
    update ad_patched_tables
    set status='U'
    where owner = x_table_owner
    and   name  = x_table_name;
    commit;
  end if;

exception when no_data_found then
  -- Add missing table with "New" status
  insert into ad_patched_tables(owner, name, status)
  values (x_table_owner, x_table_name, 'N');
  commit;

end STORE;



/* ==========================================================================================
**
**    Editioning View Tools
**
** =========================================================================================*/

--
-- Check if Editioning View exists for this table
--   return: 'Y' or 'N'
--
function EV_EXISTS(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2) return varchar2
is
  L_EV_NAME        varchar2(30);
begin
  select /*+ LEADING(EV.EV_USER EV.ev_obj ev.ev) cardinality(ev.ev 100) */ ev.view_name
  into   l_ev_name
  from   dba_editioning_views ev
  where  ev.owner     = x_table_owner
  and    ev.view_name = ad_zd_table.ev_view(x_table_name);

  return 'Y';

exception
  when no_data_found then
    return 'N';
end EV_EXISTS;

--
-- Return Editioning View name for given Table
--
function EV_VIEW(
  X_TABLE_NAME in varchar2) return varchar2
is
begin
  return substrb(x_table_name,1,29)||'#';
end EV_VIEW;

--
-- Return Table name for given Editioning View
--   Note: EV must exist
--
function EV_TABLE( X_EV_OWNER in varchar2,
                   X_EV_NAME  in varchar2) return varchar2
is
  L_TABLE_NAME varchar2(30);
begin
  select ev.table_name
  into   l_table_name
  from   dba_editioning_views ev
  where  ev.owner     = x_ev_owner
  and    ev.view_name = replace(x_ev_name, '$', '#');

  return l_table_name;
end EV_TABLE;

--
-- Return EV View Column name for given Table Column
--
function EV_VIEW_COLUMN(
  X_COLUMN_NAME in varchar2) return varchar2
is
begin
  if x_column_name like '%#_%' then
    -- this is a versioned column, strip the version
    return substrb(x_column_name, 1, instrb(x_column_name,'#',-1)-1);
  end if;
  return x_column_name;
end EV_VIEW_COLUMN;

--
-- Return Table Column for given EV View Column
-- In other words, translate logical table.column to actual table.column
--   Note: EV must exist
--
function EV_TABLE_COLUMN(
  X_EV_OWNER    in varchar2,
  X_EV_NAME     in varchar2,
  X_COLUMN_NAME in varchar2) return varchar2
is
  L_COLUMN_NAME varchar2(30);
begin
  select evc.table_column_name
  into   l_column_name
  from   dba_editioning_view_cols evc
  where  evc.owner     = replace(x_ev_owner, '$', '#')
    and  evc.view_name = x_ev_name
    and  evc.view_column_name = x_column_name;

  return l_column_name;
end EV_TABLE_COLUMN;

--
-- Returns the Table Column Revision Tag for
-- a given column name. Returns '0' if the
-- column name does not have revision tag.
--
function EV_TABLE_COLUMN_REVISION(
  X_COLUMN_NAME in varchar2) return varchar2
is
  l_col_revision varchar2(10);
begin
  if x_column_name like '%#_%' then
    return substrb(x_column_name, instrb(x_column_name,'#', -1) + 1, length(x_column_name));
  end if;
  return '0';
end;


/*
** Is the table a Seed Data Table?  Returns'Y'/'N'
*/
function IS_SEED(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2) return varchar2
is
  L_IS_SEED        varchar2(1);
begin
  begin
    select 'Y'
    into   l_is_seed
    from   dba_tab_columns c
    where  c.owner        = x_table_owner
    and    c.table_name   = x_table_name
    and    c.column_name  = 'ZD_EDITION_NAME';
  exception
    when no_data_found then
      return 'N';
  end;

  return 'Y';
end;


/*
** Fetch Multiple DDLs
**   x_object_type  - object type (TRIGGER)
**   x_object_owner - Trigger owner
**   x_object_name  - trigger name
*/
function FETCH_MULTIPLE_DDLS (
  X_OBJECT_OWNER in varchar2,
  X_OBJECT_NAME  in varchar2,
  X_OBJECT_TYPE  in varchar2) return SYS.KU$_DDLS
is
   C_MODULE             varchar2(80) := 'ad.plsql.ad_zd_table.fetch_multiple_ddls';
   L_OPEN_HANDLE        number;
   L_TRANSFORM_HANDLE   number;
   L_DDL_STMTS          sys.ku$_ddls;
begin
  log(c_module, 'STATEMENT',
      'Getting DDLs for '||x_object_owner||'.'||x_object_name||', '|| x_object_type);

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
** Alter triggers for a given table
**
** X_MODE - COMPILE or 'ENABLE' or 'DISABLE' the trigger
**
*/
procedure ALTER_TRIGGER( X_TRIGGER_OWNER in varchar2,
                         X_TRIGGER_NAME  in varchar2,
                         X_MODE          in varchar2)
is
  C_MODULE            varchar2(80) :=  'ad.plsql.ad_zd_table.alter_trigger';
  L_STMT              varchar2(256);
begin
  l_stmt := 'alter trigger "'||x_trigger_owner||'"."'|| x_trigger_name ||'" '||x_mode;
  exec (l_stmt, c_module, false); -- ignore errors
end;

--
-- Moves a trigger defined on a table / EV to a table synonym
-- This signature becomes non-public, after the changes for Bug 13597311
-- GB TODO: use EV instead of synonym
procedure MOVE_TRIGGER(
  X_TRIGGER_OWNER  varchar2,
  X_TRIGGER_NAME   Varchar2,
  X_TRIGGER_STATUS varchar2,
  X_VALID_STATUS   varchar2,
  X_TABLE_OWNER    varchar2,
  X_TABLE_NAME     varchar2)
is
  C_MODULE         varchar2(127) := 'ad.plsql.ad_zd_table.move_trigger';
  L_DDL_LOB        clob;
  L_INDEX          pls_integer :=0;
  L_SYN_OWNER      varchar2(30);
  L_SYNONYM_NAME   varchar2(30);
  L_DDL_STMTS      sys.ku$_ddls;

 -- Match#1 : exact owner.table
 L_REG_EXP_PATTERN_1 varchar2(127):= '[[:space:]]ON[[:space:]]*("?' || X_TABLE_OWNER ||
                                     '"?)[.]?"?'|| X_TABLE_NAME ||'"?[[:space:]]';

 -- Match#2 : owner.EV
 L_REG_EXP_PATTERN_2   varchar2(127) := '[[:space:]]ON[[:space:]]*("?' || X_TABLE_OWNER ||
                                        '"?)[.]?"?'|| ev_view(X_TABLE_NAME) ||'"?[[:space:]]';

 -- Match#2_1 : trg-owner.EV
 -- SSTOMAR:
 --  It has been found if synonym points to EV then DBMS_METADATA returns
 --  [... ON "trg-owner"."EV-name"] , NOT [ ... ON "ev-owner"."ev-name" ]
 L_REG_EXP_PATTERN_2_1 varchar2(127) := '[[:space:]]ON[[:space:]]*("?' || X_TRIGGER_OWNER ||
                                        '"?)[.]?"?'|| ev_view(X_TABLE_NAME) ||'"?[[:space:]]';

 -- Match#3 : Generic and
 -- For SYNONYM: will be modified for each synonym before match.
 L_REG_EXP_PATTERN_3 varchar2(127):= '[[:space:]]ON[[:space:]]*("?[A-Z_0-9]*"?)[.]?"?' ||
                                     X_TABLE_NAME ||'"?[[:space:]]';

 -- This is used to replace  ALTER TRIGGER ... ENABLE/DISABLE statement
 -- Bug 12820852 ( some triggers has $ in name)
 L_ALTER_REG_PATTERN varchar2(127):= 'ALTER[[:space:]]*TRIGGER[[:space:]]*("?'
                                     || X_TRIGGER_OWNER || '"?)[.]?"?' ||
                                     replace(replace(X_TRIGGER_NAME, '$', '\$'), '+', '\+') ||
                                     '"?[[:space:]]*[A-Z]*(;?)';

 -- Match regular pattern will be replaced with following string [ ON  APPS.<TABLE-SYNONYM> ]
 -- Added new-line for bug-12800936
 L_REG_EXP_REPLACE_STR varchar2(127):= local_chr(10) || ' ON  "' || X_TABLE_OWNER || '"."'|| ev_view(X_TABLE_NAME) ||'"  ';

 -- NOTE : if there is any issue with below SQL
 --        revert back to old one because this has to use only for
 --        'MTL_SYSTEM_ITEMS_B'  table is not being replaced as
 --        synonym is defined on APPS synonym.
 --
 -- Non-Apps synonyms
 --
 cursor C_TAB_SYN (P_TABLE_OWNER varchar2, P_TABLE_NAME varchar2) is
   with p( owner, synonym_name) as
     (
         select owner, synonym_name
         from   dba_synonyms
         where  table_name= p_table_name
         and    table_owner = p_table_owner
      union all
         select s.owner , s.synonym_name
         from   dba_synonyms s,
                p
         where s.table_name = p.synonym_name
         and   s.table_owner = p.owner
         and   s.table_owner in
               ( select oracle_username
                 from ebs_system.fnd_oracle_userid
                 where  read_only_flag in ('A','B', 'E', /*'U',*/ 'C')
                )
     )
     cycle owner, synonym_name set cyclemarker to 'Y' default 'N'
     select distinct synonym_name from p where cyclemarker = 'N'  ;

  SUCEESS_WITH_COMPILE_ERR exception;
  pragma exception_init(suceess_with_compile_err, -24344);

  DEADLOCK_DETECTED_ERR exception;
  pragma exception_init(deadlock_detected_err, -04020);
begin

  log(c_module, 'PROCEDURE', 'begin: ' ||x_trigger_owner||'.'||x_trigger_name);
  --
  -- Bug 13597311. If trigger is in invalid state, then attempt to compile it
  -- If compilation fails with hard ORA error like
  -- ORA-25006: cannot specify this column in UPDATE OF clause
  -- then abort moving the table name to synonym.
  --
  if (upper(x_valid_status) <> 'VALID') THEN
    begin
      alter_trigger(x_trigger_owner, x_trigger_name, 'COMPILE');
    exception
      when suceess_with_compile_err then
        -- progress, assuming the compilation error will go away subsequently
        null;
      when others then
        -- ORA-04045: errors during recompilation/revalidation of ...
        -- ORA-25006: cannot specify this column in UPDATE OF clause
        if((sqlcode = -25006) or
           (sqlcode = -4045 and instr (sqlerrm, 'ORA-25006') > 0 ) ) then
          -- disable the trigger and abandon the movement
          log(c_module, 'ERROR', 'The trigger ' ||x_trigger_owner||'.'||x_trigger_name ||
                             ' is invalid and it could not be compiled.  Autopatch will disable the trigger.' ||
                      ' You must not attempt to use the system before resolving the error with Oracle Support.' ||
                      ' Data consistency may be compromised if you start using the system before resolving the error.' ||
                      ' Error message follows.');
          log(c_module, 'ERROR', sqlerrm);
          -- Can NOT DISABLE a trigger which has ORA-25006 issue.
          --alter_trigger(x_trigger_owner, x_trigger_name, 'DISABLE');
          return;
        end if;
        -- In ALL other cases raise error, so AD_ZD_TABLE.UPGRADE call will be marked as FAILED,
        -- and worker would consider in next attempt.
        log(c_module, 'ERROR', x_trigger_owner||'.'||x_trigger_name || ': '|| sqlerrm);
        raise;
    end;
  end if;

  -- Get DDLs of this trigger.
  l_ddl_stmts := fetch_multiple_ddls(x_trigger_owner,x_trigger_name, 'TRIGGER');
  if(l_ddl_stmts is not null and l_ddl_stmts.count > 0 ) then
    for i in 1 .. l_ddl_stmts.count loop
      l_ddl_lob := l_ddl_stmts(i).ddltext;
      -- Actual trigger definition will have "ON" keyword
      if(i = 1) then
        -- Match <tabe owner>.<table name>
        l_index := regexp_instr(l_ddl_lob, l_reg_exp_pattern_1, 1,1,0, 'i' );
        if(l_index > 0 ) then  -- MATCH#1:
          log(c_module, 'STATEMENT','Index->' || l_index || ' Found match of-> '|| l_reg_exp_pattern_1  );
          -- Start search from that point, replace the owner.table-name with syn-owner.sysn-name
          l_ddl_lob := regexp_replace(l_ddl_lob,
                                       l_reg_exp_pattern_1,
                                       l_reg_exp_replace_str,
                                       l_index, 1, 'i' );    -- first occurrence only
        else
          -- MATCH#2: match <tabl owner>.<EV name>
          l_index := regexp_instr(l_ddl_lob, l_reg_exp_pattern_2, 1,1,0, 'i' );
          if(l_index > 0) then
              log(c_module, 'STATEMENT',
                   'Found match of '||ev_view(X_TABLE_NAME)||' in trigger definition');
              l_ddl_lob := regexp_replace(l_ddl_lob,
                                          l_reg_exp_pattern_2,
                                          l_reg_exp_replace_str, l_index, 1, 'i' );
          else
            -- MATCH#2_1: Match <Trigger owner>.<EV name>
            l_index := regexp_instr(l_ddl_lob, l_reg_exp_pattern_2_1, 1,1,0, 'i' );
            if(l_index > 0) then
                 log(c_module, 'STATEMENT', 'Found match of <trigger owner>.'
                                           || ev_view(X_TABLE_NAME) ||' in trigger definition');
                 l_ddl_lob := regexp_replace(l_ddl_lob,
                                           l_reg_exp_pattern_2_1,
                                           l_reg_exp_replace_str, l_index, 1, 'i' );
            else
              log(c_module, 'STATEMENT',
                          'No match found so far and in last step of matching: ->'   );
              -- MATCH#3: Match with <generic owner name>.<table name>
              l_index := regexp_instr(l_ddl_lob, l_reg_exp_pattern_3, 1,1,0, 'i' );
              if( l_index > 0 ) then
                log(c_module, 'STATEMENT', 'Match found at index : ->'  || l_index );
                l_ddl_lob := regexp_replace(l_ddl_lob,
                                             l_reg_exp_pattern_3,
                                             l_reg_exp_replace_str, l_index, 1,  'i' );
              else
                -- Check if trigger has been defined on any other SYNONYMs ( other than APPS synonym)
                l_index := 0;
                log(c_module, 'STATEMENT','Checking if it has been defined on a table-synonym'  );
                for syn_rec in  c_tab_syn (x_table_owner, x_table_name)  loop
                  l_synonym_name := syn_rec.synonym_name;
                  l_reg_exp_pattern_3 :=  '[[:space:]]ON[[:space:]]*("?[A-Z_0-9]*"?)[.]?"?' || l_synonym_name ||'"?[[:space:]]';
                  l_index := regexp_instr(l_ddl_lob, l_reg_exp_pattern_3, 1,1,0, 'i' );
                  exit when l_index > 0;
                end loop;

                if(l_index > 0 ) then
                  log(c_module, 'STATEMENT',
                           'Found match, Trigger has been defined on table-synonym : ->' ||
                           l_index || ' Pattern->' || l_reg_exp_pattern_3 );
                  l_ddl_lob := regexp_replace(l_ddl_lob,
                                             l_reg_exp_pattern_3,
                                             l_reg_exp_replace_str,
                                             l_index, /* from that position */
                                             1,       /* first occurrence */
                                             'i'      /* case-insensitive */
                                            );
                 end if;
               end if; --- end of MATCH#3
             end if; --- end of MATCH#2_1
           end if; --- end of MATCH#2
         end if; --- end of MATCH#1

         -- Drop trigger
         exec('DROP TRIGGER "'||x_trigger_owner ||'"."'||x_trigger_name||'"', c_module);
       end if; -- end of if [ i =1 ]

       -- Create the trigger on top of EV using synonym
       begin
         exec(l_ddl_lob, c_module);
       exception
         when deadlock_detected_err then
           -- In case of deadlock error, wait for half a second and retry
           -- If it fails again, write the ddl into AD_ZD_DDL_HANDLER table
           -- to run in UPGRADE_TABLE phase.
           DBMS_LOCK.SLEEP(0.500);
           begin
             exec(l_ddl_lob, c_module);
           exception
             when deadlock_detected_err then
               -- Write the DDL into DDL handler table
               ad_zd_parallel_exec.load(ad_zd_parallel_exec.c_phase_upgrade_table, l_ddl_lob);
               error(c_module, 'deadlock detected while trying to '
                           || 'move trigger "' || x_trigger_owner
                           || '"."' || x_trigger_name || '" defined on table "'
                             || x_table_owner || '"."' || x_table_name ||
                             '" to APPS synonym');
           end;
        end;


     end loop;
   end if;

   log(c_module, 'PROCEDURE', 'end');
exception
  when others then
    raise;
end MOVE_TRIGGER;


--
-- Move triggers from Table to EV.
--
-- So:  [ TRIGGERS ] --> [ SYNONYM ] --> [ EV ]---> [ TABLE ]
--
-- Steps
--   1- Drop Trigger
--   2- Recreate Trigger with same definition on top of synonym (EV)
--
procedure MOVE_TRIGGERS(
  X_TABLE_OWNER  varchar2,
  X_TABLE_NAME   varchar2)
is
  C_MODULE        varchar2(127) := 'ad.plsql.ad_zd_table.move_triggers';
  L_VALID_STATUS  varchar2(10);
  L_EV_NAME       varchar2(30);
  L_SYNONYM_NAME  varchar2(30);
  L_SYNONYM_OWNER varchar2(30);

 -- triggers defined on a table
  CURSOR c_trg is
    select owner, trigger_name, trigger_type, status
    from dba_triggers
    where table_owner in
     ( select oracle_username from ebs_system.fnd_oracle_userid
       where  read_only_flag in ('A','B', 'E', 'U', 'C') )
    -- EXCLUDE: trigger generated by the Oracle Text Indexing
    and trigger_name not like 'DR$%'
    -- EXCLUDE: Editioned Data Storage Maintenance Trigger Name
    and trigger_name <> ad_zd_seed.eds_trigger(x_table_name)
    and trigger_name <> ad_zd_seed.eds_fcet(x_table_name)
    -- EXCLUDE: cross edition triggers.
    and crossedition = 'NO'
    and table_owner = x_table_owner
    and (
        (table_name = x_table_name and base_object_type='TABLE')
        or
        (table_name=ev_view(x_table_name) and base_object_type='VIEW')
        )
    and owner in
       (select oracle_username from ebs_system.fnd_oracle_userid
        where  read_only_flag in ('A','B', 'E', 'U', 'C') );

begin
  log(C_MODULE, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  if( ev_exists(X_TABLE_OWNER, X_TABLE_NAME) = 'N' ) then
      log(c_module, 'ERROR', 'EV not found for table '||x_table_owner||'.'||x_table_name);
  else
    begin
      for trg_rec in c_trg loop

      -- Bug 13597311. Adding valid state to decide
      -- whether to force recompile a trigger or not.
      -- This can be also done in CURSOR c_trg by joining
      -- dba_objects. At present there is a huge performance
      -- drop in the resultant query. Taking suggestion from
      -- perf team.
      -- TODO: If perf team can suggest a single query, it would
      --       help optimize further.

        select status
        into   l_valid_status
        from   dba_objects
        where  owner = trg_rec.owner
        and    object_name = trg_rec.trigger_name
        and    object_type = 'TRIGGER';

        move_trigger(
           trg_rec.owner,
           trg_rec.trigger_name,
           trg_rec.status,
           l_valid_status,
           x_table_owner,
           x_table_name);
      end loop;
    exception
      when others then
        raise;
    end;
  end if;
  log(C_MODULE, 'PROCEDURE', 'end');
END MOVE_TRIGGERS;

--
-- Moves VPD policies from table to EV
--
procedure MOVE_VPD_POLICIES(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2,
  X_EV_NAME     in varchar2 )
is
  C_MODULE          varchar2(127) := 'ad.plsql.ad_zd_table.move_vpd_policies';

  L_OBJECT_OWNER    varchar2(30);
  L_OBJECT_NAME     varchar2(30);
  L_POLICY_GROUP    varchar2(30);
  L_POLICY_NAME     varchar2(30);
  L_PF_OWNER        varchar2(30);
  L_PACKAGE         varchar2(30);
  L_FUNCTION        varchar2(65);
  L_SEL             varchar2(3);
  L_INS             varchar2(3);
  L_UPD             varchar2(3);
  L_DEL             varchar2(3);
  L_IDX             varchar2(3);
  L_POLICY_TYPE     varchar2(24);
  L_CHK_OPTION      varchar2(5);
  L_ENABLE          varchar2(5);
  L_STATIC_POLICY   varchar2(5);
  L_LONG_PREDICATE  varchar2(5);

  L_STMT_TYPES      varchar2(64);
  L_FIRST           boolean := true;
  L_SQL             varchar2(32767);
  L_EV_NAME         varchar2(30);

  cursor C_VPD (X_OWNER varchar2, X_NAME varchar2)
  is
    select  object_owner    ,
            object_name     ,
            policy_group    ,
            policy_name     ,
            pf_owner        ,
            package          ,
            function         ,
            sel              ,
            ins              ,
            upd              ,
            del              ,
            idx              ,
            -- chk_option       ,
            decode(chk_option, 'YES', 'true', 'false'),
            --enable           ,
            decode(enable, 'YES', 'true', 'false'),
            --static_policy    ,
            decode(static_policy ,'YES', 'true', 'false'),
            policy_type      ,
            --long_predicate
            decode(long_predicate, 'YES', 'true', 'false')
   from   dba_policies
   where  object_owner = x_owner
   and    object_name  = x_name
   and    policy_name  = UPPER(policy_name)   -- EXCLUDE: internal polciy, if any.
   and    lower(policy_name) <> 'ad_zd_seed'; -- EXCLUDE: AD_ZD_SEED policies .

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);
  begin
    l_ev_name := nvl(X_EV_NAME, ev_view(X_TABLE_NAME));
    open c_vpd(x_table_owner, x_table_name);
    fetch c_vpd INTO
                    l_object_owner    ,
                    l_object_name     ,
                    l_policy_group    ,
                    l_policy_name     ,
                    l_pf_owner        ,
                    l_package         ,
                    l_function        ,
                    l_sel             ,
                    l_ins             ,
                    l_upd             ,
                    l_del             ,
                    l_idx             ,
                    l_chk_option      ,
                    l_enable          ,
                    l_static_policy   ,
                    l_policy_type     ,
                    l_long_predicate  ;

    while (c_vpd%found) loop
      log(c_module, 'STATEMENT', 'Drop VPD policy: ' ||l_policy_name||' from '||x_table_owner||'.'||x_table_name );
      -- If here, policy exist for this table
      -- Drop from table
      l_sql := 'BEGIN  DBMS_RLS.DROP_POLICY ( ' ||
                      ' object_schema =>''' || X_TABLE_OWNER || ''', '  ||
                      ' object_name  => ''' || X_TABLE_NAME || ''', '  ||
                      ' policy_name => ''' || l_policy_name || '''); END; ' ;
      -- Drop policy from table
      exec(l_sql, c_module);

      -- SELECT
      if( l_sel = 'YES' ) then
        l_stmt_types :=  'SELECT ';
        l_first := false;
      end if;

      -- INSERT
      if( l_ins = 'YES' ) then
        if l_first then
          l_stmt_types :=  'INSERT';
          l_first := false;
         else
          l_stmt_types :=  l_stmt_types || ', INSERT';
         END if;
      end if;

      -- UPDATE
      if( l_upd = 'YES' ) then
        if l_first then
          l_stmt_types :=  'UPDATE';
          l_first := false;
         else
          l_stmt_types :=  l_stmt_types || ', UPDATE';
         end if;
      end if;

      -- DELETE
      if( l_del = 'YES' ) then
         if l_first then
          l_stmt_types :=  'DELETE';
          l_first := false;
         else
          l_stmt_types :=  l_stmt_types || ', DELETE';
         end if;
      end if;

      -- INDEX
      if( l_idx = 'YES' ) then
        if l_first then
          l_stmt_types :=  'INDEX';
          l_first := false;
         else
          l_stmt_types :=  l_stmt_types || ', INDEX';
         end if;
      end if;

      if(l_package is not null ) then
       -- "pkg_name"."fun_name"
       l_function :=  l_package || '.' || l_function   ;
      end if;

      if(l_policy_type is not null ) then
        l_policy_type := 'DBMS_RLS.' || l_policy_type;
      end if;

      -- ReAssign VPD to EV
      l_sql := 'BEGIN  DBMS_RLS.ADD_GROUPED_POLICY( ' ||
                    ' object_schema=>''' || x_table_owner || ''', ' ||
                    ' object_name=>''' || l_ev_name || ''', ' ||
                    ' policy_group=>'''  || l_policy_group || ''', ' ||
                    ' policy_name=>'''  || l_policy_name  || ''', ' ||
                    ' function_schema=>''' ||  l_pf_owner || ''', ' ||
                    ' policy_function=>''' || l_function || ''', ' ||
                    ' statement_types=>''' || l_stmt_types || ''', ' || /* statement_types =>'SELECT,INDEX, INSERT, UPDATE, DELETE.*/
                    ' update_check=>' ||  l_chk_option || ', ' ||       /* BOOLEAN value, so extra single quote required otherwise that would become
                                                                           string */
                    ' enable=>' ||  l_enable || ', ' ||                 /* BOOLEAN */
                    ' static_policy=>' ||  l_static_policy || ', ' ||   /* BOOLEAN */
                    ' policy_type=>' ||  l_policy_type || ', ' ||       /* integer VALUE */
                    ' long_predicate=>' || l_long_predicate || ', ' ||  /* BOOLEAN */
                    ' sec_relevant_cols=>NULL, ' ||
                    ' sec_relevant_cols_opt=>NULL); END; '  ;

       log(c_module, 'STATEMENT', 'Add VPD policy: ' ||l_policy_name||' to '||x_table_owner||'.'||l_ev_name );
       exec(l_sql, c_module);

       fetch c_vpd INTO
            l_object_owner    ,
            l_object_name     ,
            l_policy_group    ,
            l_policy_name     ,
            l_pf_owner        ,
            l_package          ,
            l_function         ,
            l_sel              ,
            l_ins              ,
            l_upd              ,
            l_del              ,
            l_idx              ,
            l_chk_option       ,
            l_enable           ,
            l_static_policy    ,
            l_policy_type      ,
            l_long_predicate  ;

    end loop;

    if c_vpd%isopen  then  -- cursor was not already closed
       close c_vpd;
    end if;

  exception
    when others then
     if c_vpd%isopen  then  -- cursor was not already closed
       close c_vpd;
     end if;

     log(c_module, 'ERROR', substr(sqlerrm, 1, 2000));
     raise;
  end;
  log(c_module, 'PROCEDURE', 'end');
END MOVE_VPD_POLICIES ;

--
--  Drops public synonyms and re-create corresponding synonyms in dependent
--  schema.
--
procedure FIX_PUBLIC_SYNONYM (x_table_owner   varchar2,
                              x_table_name    varchar2,
                              x_synonym_name  varchar2,
                              x_ev_name       varchar2)
is
  C_MODULE  varchar2(127) := 'ad.plsql.ad_zd_table.fix_public_synonym';
  L_SQL     varchar2(1024);

  object_already_exists exception;
  pragma EXCEPTION_INIT(object_already_exists, -955);

  -- MV tables already will be excluded by AD_ZD_TABLE.UPGRADE API
  -- Check recursive dependency as well:
  -- e.g: View --> synonym --> public-synonym
  --
  cursor c_dependents (p_synonym_name varchar2) is
     select distinct d.owner --, d1.name, d1.type
     from   dba_dependencies d
     where  d.owner in ( select oracle_username
                          from ebs_system.fnd_oracle_userid
                          where  read_only_flag in ('A','B', 'E', 'U', 'C' )
                          )
     and    d.referenced_type  = 'SYNONYM'
     and    d.referenced_owner = 'PUBLIC'
     and    d.referenced_name  = p_synonym_name
     and not exists ( select 1
                       from  dba_synonyms
                       where owner = d.owner
                       and   synonym_name= p_synonym_name
                       );

  -- create a private synonym if a schema has a grant to an underlying table.
  cursor c_granted_select_schema is
    select distinct grantee
    from dba_tab_privs privs
    where owner = x_table_owner
      and table_name = x_table_name
      and privilege = 'SELECT'
      and privs.grantee in
            (select oracle_username
             from fnd_oracle_userid
             where read_only_flag ='B')
      and not exists ( select 1
                       from  dba_synonyms
                       where owner = privs.grantee
                       and   synonym_name = x_synonym_name
                       );
begin

  log(c_module, 'PROCEDURE',
      'begin: '||x_table_owner||'.'||x_table_name||', '||x_synonym_name);

  for dependent in c_dependents ( x_synonym_name) loop
    begin
      l_sql := 'CREATE SYNONYM "' || dependent.owner|| '"."' || x_synonym_name ||
               '" FOR "'|| x_table_owner || '"."' || nvl(x_ev_name, ev_view(x_table_name)) || '"' ;

      log(c_module, 'STATEMENT', 'Create Synonym: "' || dependent.owner || '"."' || x_synonym_name ||'"') ;
      exec(l_sql, c_module);
    exception
      when object_already_exists then
        log(c_module, 'WARNING', 'Can not create Synonym "' || dependent.owner
               || '"."' || x_synonym_name || '", as there exists an object with'
               || ' same name but not of synonym type');
      when others then
        raise;
    end;

  end loop;

  for l_schema in c_granted_select_schema loop
    begin
      l_sql := 'CREATE SYNONYM "' || l_schema.grantee|| '"."' || x_synonym_name ||
               '" FOR "'|| x_table_owner || '"."' || nvl(x_ev_name, ev_view(x_table_name)) || '"' ;

      log(c_module, 'STATEMENT', 'Create Synonym: "' || l_schema.grantee || '"."' || x_synonym_name ||'"') ;
      exec(l_sql, c_module);
    exception
      when object_already_exists then
        log(c_module, 'WARNING', 'Can not create Synonym "'||l_schema.grantee
               || '"."' || x_synonym_name || '", as there exists an object with'
               || ' same name but not of synonym type');
      when others then
        raise;
    end;
  end loop;


  -- drop public synonym
  l_sql := 'DROP PUBLIC SYNONYM "' || x_synonym_name || '" FORCE' ;
  log(c_module, 'STATEMENT', 'Drop Public Synonym: "' || x_synonym_name ||'"');
  exec (l_sql, c_module, true);

  log(c_module, 'PROCEDURE', 'end');
end FIX_PUBLIC_SYNONYM;

--
--  Drops public synonyms and re-create corresponding synonyms in dependent
--  schema.
--
procedure FIX_PUBLIC_SYNONYMS(x_table_owner  varchar2,
                              x_table_name   varchar2,
                              x_ev_name      varchar2)
is
  C_MODULE          varchar2(127) := 'ad.plsql.ad_zd_table.fix_public_synonyms';

  cursor c_pub_syn is
   select syn.synonym_name
   from  dba_synonyms syn,
         DBA_TABLES tab
   where syn.owner='PUBLIC'
   and   syn.table_owner in ( select oracle_username
                              from ebs_system.fnd_oracle_userid
                              where  read_only_flag in ('E', 'A', 'B', 'C')
                             )
   and syn.table_owner = x_table_owner
   and syn.table_name  = x_table_name
   and tab.owner       = syn.table_owner
   and tab.table_name  = syn.table_name;


begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  for pub_syn in c_pub_syn loop
    fix_public_synonym(x_table_owner, x_table_name, pub_syn.synonym_name, x_ev_name);
  end loop;

  log(c_module, 'PROCEDURE', 'end');
end FIX_PUBLIC_SYNONYMS;


--
-- Generate Editioning View
--
-- Generates an Editioning View for the specified table.
-- Table columns have names with the following structure
--
--       <logical_name>[#<version>]
--
-- The generated editioning view will map each logical column name
-- to the latest version table column for that logical name.
--
procedure GENERATE_EV(
  X_TABLE_OWNER       varchar2,
  X_TABLE_NAME        varchar2 )
is
  C_MODULE            varchar2(127) := 'ad.plsql.ad_zd_table.generate_ev';
  L_EV_NAME           varchar2(30);
  L_EV_STMT           varchar2(32676);
  L_EV_LOB_STMT       clob;
  L_EV_FIRST          boolean;

  cursor C_EV_COLUMNS(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
    select outev.view_column_name, outev.table_column_name, outev.view_column_id
    from (select
            ad_zd_table.ev_view_column(col.column_name) as view_column_name
            , max(col.column_name) as table_column_name
            , min(nvl(evc.view_column_id, 1000+col.column_id)) view_column_id
          from dba_tab_columns col,
               dba_editioning_view_cols evc
          where  col.owner = x_table_owner
            and  col.table_name = x_table_name
            and  evc.owner(+)            = x_table_owner
            and  evc.view_name(+)        = ad_zd_table.ev_view(x_table_name)
            and  evc.view_column_name(+) = ad_zd_table.ev_view_column(col.column_name)
          group by ad_zd_table.ev_view_column(col.column_name)) outev
    where not exists(
      select 'x' from dba_col_comments cmt
      where cmt.owner=x_table_owner
        and cmt.table_name=x_table_name
        and cmt.column_name=outev.table_column_name
        and upper(cmt.comments)='AD_OBSOLETE'
    ) order by outev.view_column_id;

begin

  -- set up EV creation statement
  l_ev_name := ev_view(x_table_name);
  l_ev_stmt := 'create or replace editioning view  "'||
                x_table_owner||'"."'||l_ev_name||'" as select ';

  log(c_module, 'STATEMENT', 'Generate EV '||x_table_owner||'.'||l_ev_name);

  begin
    -- Loop thru each EV column
    l_ev_first := true;
    for evcrec in c_ev_columns(x_table_owner, x_table_name) loop

      -- add initial statement or separater as needed
      if l_ev_first then
        l_ev_first := false;
        dbms_lob.createtemporary (l_ev_lob_stmt, false, DBMS_LOB.CALL);
        dbms_lob.writeappend(lob_loc => l_ev_lob_stmt,
                             amount  => length(l_ev_stmt),
                             buffer  => l_ev_stmt);
      else
        l_ev_stmt := ', ';
        dbms_lob.writeappend(lob_loc => l_ev_lob_stmt,
                             amount  => length(l_ev_stmt),
                             buffer  => l_ev_stmt);
      end if;

      -- add column mapping to EV creation statement
      l_ev_stmt := evcrec.table_column_name||' '||evcrec.view_column_name;
      dbms_lob.writeappend(lob_loc => l_ev_lob_stmt,
                           amount  => length(l_ev_stmt),
                           buffer  => l_ev_stmt);

    end loop;

    -- complete the EV creation statement and execute
    if (l_ev_lob_stmt is not null and dbms_lob.getlength(l_ev_lob_stmt) > 0 ) then

      l_ev_stmt := ' from "'||x_table_owner||'"."'||x_table_name||'"';
      dbms_lob.writeappend(lob_loc => l_ev_lob_stmt,
                           amount  => length(l_ev_stmt),
                           buffer  => l_ev_stmt);

      -- Immediate execute. [patching case]
      exec(l_ev_lob_stmt, c_module);
    end if;  -- END : If l_ev_lob_stmt is not null and dbms_lob.getlength(l_ev_lob_stmt) > 0

    if (dbms_lob.isTemporary(l_ev_lob_stmt)=1) then
      dbms_lob.freeTemporary(l_ev_lob_stmt);
    end if;

  exception
    when others then
      if (dbms_lob.isTemporary(l_ev_lob_stmt)=1) then
        dbms_lob.freeTemporary(l_ev_lob_stmt);
      end if;
      log(c_module, 'ERROR',
          x_table_owner||'.'||x_table_name || ': ' || substr(sqlerrm, 1, 2000));
      raise;
  end;

end GENERATE_EV;


--
-- Install Editioning View
--
-- Only needed for first time installation of an EV.
--   - moves table-level VPD policies to editioning view
--   - copies table-level grants to editioning view
--   - Points table synonyms to editioning view
--
-- Note: assumes EV is already generated
--
procedure INSTALL_EV(
  X_TABLE_OWNER   varchar2,
  X_TABLE_NAME    varchar2 )
is
  C_MODULE        varchar2(80) := 'ad.plsql.ad_zd_table.install_ev';
  C_APPS_SCHEMA   varchar2(30) := ad_zd.apps_schema;
  L_EV_NAME       varchar2(30);
  L_SYN_OWNER     varchar2(30);
  L_SYN_NAME      varchar2(30);
  L_STMT          varchar2(32000);
  L_SYN_EXISTS    boolean;

-- Bug26033762 modified cursor to not return synonyms that contain a db_link.

  cursor C_SYNONYMS(x_table_owner varchar2, x_table_name varchar2, x_ev_name varchar2) is
    select
        syn.owner         owner
      , syn.synonym_name  synonym_name
      , syn.table_name    table_name
    from dba_synonyms syn
    where syn.table_owner = x_table_owner
    and syn.table_name  in (x_table_name, x_ev_name)
    and syn.owner in
          ( select oracle_username
            from   ebs_system.fnd_oracle_userid
            where  read_only_flag in ('A','B', 'E', 'U', 'C') )
    and syn.db_link is null;

begin
  log(c_module, 'PROCEDURE', 'begin: '||X_TABLE_OWNER||'.'||X_TABLE_NAME);

  l_ev_name := ev_view(x_table_name);

  -- loop through synonyms for table/EV
  l_syn_exists := false;
  for synrec in c_synonyms(x_table_owner, x_table_name, l_ev_name) loop
    l_syn_exists := true;

    -- Point table synonyms to EV
    if synrec.table_name <> l_ev_name then
       l_stmt := 'create or replace synonym "'||synrec.owner||'"."'||
                 synrec.synonym_name||'" for "'||x_table_owner||'"."' || l_ev_name ||'"' ;

       log(c_module, 'STATEMENT',
           'Point Synonym "'||synrec.owner||'"."'||synrec.synonym_name||'" to EV');
       exec(l_stmt, c_module);
    end if;
  end loop;

  -- Move VPD policies to EV
  move_vpd_policies(x_table_owner, x_table_name, l_ev_name);
  -- Copy Table Grants to EV
  ebs_system.ad_zd_sys.copy_grants(x_table_owner, x_table_name, l_ev_name);

  -- Create a synonym in APPS schema if there are none.
  -- This is for new table installation.
  if not l_syn_exists then
    l_stmt := 'create synonym "'||c_apps_schema|| '"."' ||x_table_name||
              '" for "'||x_table_owner||'"."'||l_ev_name||'"';
    log(c_module, 'STATEMENT',
        'Create Synonym '||c_apps_schema||'.'||x_table_name||' to EV');
    exec(l_stmt, c_module, true);
  end if;

  log(c_module, 'PROCEDURE', 'end');
end INSTALL_EV;




--
-- Upgrade Effectively Editioned Table
--    - Generate and Install Editioning View
--    - Fix table synonyms to point to EV
--    - Move triggers to EV
--
-- Tables with ZD_EDITION_NAME column are upgraded to seed data tables.
-- Tables with obsolete columns are marked as patched to request cutover processing.
--
procedure UPGRADE(
  X_TABLE_OWNER in  varchar2,
  X_TABLE_NAME  in  varchar2 )
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.upgrade';
  L_EXISTS          varchar2(1);

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  -- Verify table exists
  begin
    select 'Y' into l_exists
    from   dba_tables tab
    where  tab.owner      = x_table_owner
    and    tab.table_name = x_table_name;
  exception
    when no_data_found then
      error(c_module, 'Table '||nvl(x_table_owner,'<null>')||'.'||nvl(x_table_name,'<null>')||' does not exist.');
  end;

  log(c_module,'EVENT',  'Upgrade table: '||x_table_owner||'.'||x_table_name);

  -- Generate Editioning View
  generate_ev(x_table_owner, x_table_name);

  -- Install Editioning View (handles synonyms, VPD policies)
  install_ev(x_table_owner, x_table_name);

  -- Move triggers to EV from table
  move_triggers(x_table_owner, x_table_name);

  -- Cleanup PUBLIC synonyms
  fix_public_synonyms(x_table_owner, x_table_name, ad_zd_table.ev_view(x_table_name));

  -- Upgrade seed data tables
  if is_seed(x_table_owner, x_table_name) = 'Y' then
    ad_zd_seed.upgrade(x_table_name);
  end if;

  -- Store table for Finalize/Cutover processing
  begin
    -- Check if an obsolete column exists
    select 'Y' into l_exists
    from  dba_tab_columns col
        , dba_editioning_views ev
    where col.owner       = x_table_owner
      and col.table_name  = x_table_name
      and col.column_name <> 'ZD_EDITION_NAME'
      and ev.owner      = x_table_owner
      and ev.view_name  = substrb(x_table_name, 1, 29)||'#'
      and not exists
            ( select evc.table_column_name
              from  dba_editioning_view_cols evc
              where evc.owner     = ev.owner
                and evc.view_name = ev.view_name
                and evc.table_column_name = col.column_name )
      and rownum = 1;

    -- Obsolete column found
    -- Mark table as patched so that cutover processing happens
    log(c_module,'STATEMENT', 'Marking table as patched: '||x_table_owner||'.'||x_table_name);
    store(x_table_owner, x_table_name);
  exception
    when no_data_found then
      null;
  end;

  commit;
  log(c_module, 'PROCEDURE', 'end '||x_table_owner ||'.'|| x_table_name);
end UPGRADE;



--
-- Upgrade all developer-managed EBS tables with an editioning view
--
-- Note: we maintain an explicit list of known application-managed
-- tables that are excluded from upgrade (the regexp_like section).
-- This application-managed table name patterns must stay in synch
-- with what is documented in the Database Object Development .
--
procedure UPGRADE_DB
is
  C_MODULE     varchar2(127) := 'ad.plsql.ad_zd_table.upgrade_db';

  -- EBS Tables that need EVs
  --   - owned by EBS product schema
  --   - not a known DB internal table pattern
  --   - not a known application managed table pattern
  --   - not an AD internal table
  --   - not a Queue Table
  --   - not a Materialized View Container Table
  --   - has an APPS synonym
  cursor C_UPGRADE_TABLES is
    select
        tab.owner        table_owner
      , tab.table_name   table_name
    from  dba_tables tab
    where tab.owner in
            ( select oracle_username from   ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A','E','B') )
      and tab.temporary = 'N'
      and tab.secondary = 'N'
        /* not an application-managed dynamic table */
      and not regexp_like(tab.table_name, '^AQ\$', 'c')
      and not regexp_like(tab.table_name, '^AW\$', 'c')
      and not regexp_like(tab.table_name, '^MLOG\$', 'c')
      and not regexp_like(tab.table_name, '^BSC_DI_[0-9_]+$', 'c')
      and not regexp_like(tab.table_name, '^BSC_D_.+$', 'c')
      and not regexp_like(tab.table_name, '^FA_ARCHIVE_ADJUSTMENT_.+$', 'c')
      and not regexp_like(tab.table_name, '^FA_ARCHIVE_DETAIL_.+$', 'c')
      and not regexp_like(tab.table_name, '^FA_ARCHIVE_SUMMARY_.+$', 'c')
      and not regexp_like(tab.table_name, '^GL_DAILY_POST_INT_.+$', 'c')
      and not regexp_like(tab.table_name, '^GL_INTERCO_BSV_INT_[0-9]+$', 'c')
      and not regexp_like(tab.table_name, '^GL_MOVEMERGE_BAL_[0-9]+$', 'c')
      and not regexp_like(tab.table_name, '^GL_MOVEMERGE_INTERIM_[0-9]+$', 'c')
      and not regexp_like(tab.table_name, '^XLA_GLT_[0-9]+$', 'c')
      and not regexp_like(tab.table_name, '^ICX_POR_C[0-9]+.*$', 'c')
      and not regexp_like(tab.table_name, '^ICX_POR_UPLOAD_[0-9]+.*$', 'c')
      and not regexp_like(tab.table_name, '^IGI_SLS_[0-9]+$', 'c')
      and not regexp_like(tab.table_name, '^JTF_TAE_[0-9]+.*$', 'c')
      and not regexp_like(tab.table_name, '^JTY_[0-9]+_.*$', 'c')
      and not regexp_like(tab.table_name, '^ZPBDATA[0-9]+_EXCPT_T$', 'c')
      and not regexp_like(tab.table_name, '^ZX_DATA_UPLOAD_.*$', 'c')
        /* not an AD infrastructure table table */
      and tab.table_name not in
            ( 'AD_DEFERRED_JOBS',
              'AD_TABLE_INDEX_INFO',
              'FND_INSTALL_PROCESSES',
              'AD_UTIL_PARAMS',
              'AD_PATCHED_TABLES',
              'AD_ZD_DDL_HANDLER',
              'AD_OBSOLETE_OBJECTS',
              'FND_PRODUCT_INSTALLATIONS' )
      and not exists /* not a queue table */
            ( select qt.owner, qt.queue_table
              from   dba_queue_tables qt
              where  qt.owner       = tab.owner
              and    qt.queue_table = tab.table_name )
      and not exists /* not an MV container table */
            ( select mv.owner, mv.container_name
              from   dba_mviews mv
              where  mv.owner          = tab.owner
              and    mv.container_name = tab.table_name )
      and exists /* has apps synonym to base table */
            ( select syn.table_owner, syn.table_name
              from   dba_synonyms syn
              where  syn.table_owner = tab.owner
              and    syn.table_name  = tab.table_name
              and    syn.owner       = ad_zd.apps_schema )
      and not exists /* not an obsolete table */
            ( select
                  fou.oracle_username owner
                , aoo.object_name   object_name
              from
                  ebs_system.fnd_oracle_userid fou
                , fnd_product_installations fpi
                , ad_obsolete_objects aoo
              where fpi.application_id  = aoo.application_id
                and fou.oracle_id       = fpi.oracle_id
                and fou.oracle_username = tab.owner
                and aoo.object_name     = tab.table_name
                and aoo.object_type = 'TABLE' )
    order by tab.owner, tab.table_name;

  -- EV Tables that are not fully upgraded
  --   - synonyms that point to base table
  --   - triggers on base table
  --   - TODO: vpd policies on base table
  cursor C_REUPGRADE_TABLES is
    select ev.owner table_owner, ev.table_name
    from   dba_editioning_views ev
    where ev.owner in
            ( select oracle_username from   ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A','E','B') )
      and ( exists /* uncoverted synonyms */
              ( select syn.synonym_name
                from   dba_synonyms syn
                where syn.owner in
                        ( select oracle_username from   ebs_system.fnd_oracle_userid
                          where  read_only_flag in ('A', 'B', 'C', 'E', 'U') )
                  and syn.table_owner = ev.owner
                  and syn.table_name  = ev.table_name ) or
            exists /* unmoved triggers */
              ( select trg.trigger_name
                from   dba_triggers trg
                where  trg.owner in
                        ( select oracle_username from   ebs_system.fnd_oracle_userid
                          where  read_only_flag in ('A', 'B', 'C', 'E', 'U') )
                  and  trg.trigger_name not like '%$%' /* system trigger */
                  and  trg.crossedition = 'NO'
                  and  trg.table_owner = ev.owner
                  and  trg.table_name  = ev.table_name )
          )
    order by table_owner, table_name;

 begin
   log(c_module, 'PROCEDURE', 'begin: no parameter(s)' );


   -- Process tables that need upgrade
   for tab_rec in c_upgrade_tables loop
     log(c_module, 'STATEMENT', 'Store Upgrade action for table '||tab_rec.table_name );
     ad_zd_parallel_exec.load(
       x_phase  => ad_zd_parallel_exec.c_phase_upgrade_table,
       x_sql    => 'begin ad_zd_table.upgrade('''||tab_rec.table_owner ||''', '''|| tab_rec.table_name || '''); end;' ,
       x_unique => false );
   end loop;

   -- Process tables that need re-upgrade.
   for tab_rec in c_reupgrade_tables loop
     log(c_module, 'STATEMENT', 'Store Re-Upgrade action for table '||tab_rec.table_name );
     ad_zd_parallel_exec.load(
       x_phase  => ad_zd_parallel_exec.c_phase_upgrade_table,
       x_sql    => 'begin ad_zd_table.upgrade('''||tab_rec.table_owner ||''', '''|| tab_rec.table_name || '''); end;' ,
       x_unique => false);

   end loop;

   log(c_module, 'PROCEDURE', 'end' );

 end UPGRADE_DB;


/*
** Downgrade Table (remove EV layer)
**
**   X_TABLE_OWNER / X_TABLE_NAME - the table
** TODO: move triggers and VPD policies back to Table
*/
procedure DOWNGRADE(
  X_TABLE_OWNER in  varchar2,
  X_TABLE_NAME  in  varchar2)
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.downgrade';
  L_EV_NAME         varchar2(30);
  L_TABLE_OWNER     varchar2(30);
  L_TABLE_NAME      varchar2(30);

  cursor C_SYNONYMS(x_table_owner varchar2, x_table_name varchar2) is
    select syn.owner owner, syn.synonym_name name
    from   dba_synonyms syn
    where  syn.table_owner = x_table_owner
    and    syn.table_name  = ad_zd_table.ev_view(x_table_name)
    and    syn.owner         <> 'PUBLIC';

begin
  log( c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);

  -- Verify table exists
  begin
    select tab.owner, tab.table_name
    into   l_table_owner, l_table_name
    from   dba_tables tab
    where  tab.owner      = x_table_owner
    and    tab.table_name = x_table_name;
  exception
    when no_data_found then
      error(c_module, 'Table '||nvl(x_table_owner,'<null>')||'.'||nvl(x_table_name,'<null>')||' does not exist.');
  end;

  -- Change synonyms
  for synrec in c_synonyms(x_table_owner, x_table_name) loop
    log(c_module, 'STATEMENT',
        'Point Synonym back to Table: '||synrec.owner||'.'||synrec.name);
    exec('create or replace synonym "'||
         synrec.owner||'"."'||synrec.name||'" for "'||
         x_table_owner||'"."'||x_table_name||'"', c_module);
  end loop;

  -- Drop EV
  l_ev_name := ad_zd_table.ev_view(x_table_name);
  log(c_module, 'STATEMENT', 'Drop EV '||x_table_owner||'.'||l_ev_name);
  exec('drop view "'||x_table_owner||'"."'||l_ev_name ||'"', c_module, true);

  log( c_module, 'PROCEDURE', 'end');
end DOWNGRADE;


/*
** --------------------------------------------------------------------
**    Forward Crossedition Trigger Tools
** --------------------------------------------------------------------
*/

/*
** Choose a parallel_level that is the least of the three limiting factors:
** 1) job_queue_processes/2: half of the available parallel workers for the DB, no less than 2.
** 2) parallel level cap: set at 8 (some systems have very high job_queue_processes capacity).
** 3) chunk count: Do not request more workers than there are chunks of work to be done.
*/

function CALCULATE_PARALLEL_LEVEL(X_CHUNK_COUNT in number) return number
is
  C_MODULE       varchar2(80) := 'ad.plsql.ad_zd_table.calculate_parallel_level';
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

--
-- Update table (fake update) in order to apply Crossedition Trigger.
--
procedure UPDATE_4FCET(
  X_TABLE_OWNER    varchar2,
  X_TABLE_NAME     varchar2,
  X_TRIGGER_NAME   varchar2,
  X_COLUMN_NAME    varchar2,
  X_WHERE          varchar2)
is
  C_MODULE         varchar2(80) := 'ad.plsql.ad_zd_table.update_4fcet';
  L_STMT           varchar2(5000);
  L_STATUS         number;
  L_TASK_NAME      varchar2(64);
  L_CHUNK_COUNT    number;
  L_ERROR          VARCHAR2(3000);
  L_PARALLEL_LEVEL number;

  DUPLICATE_TASK_ERROR exception;
    pragma exception_init(duplicate_task_error, -29497);

  -- Conflict Triggers will block the apply of a forward crossedition trigger
  --   - directly on the table (or on EV, if EV is getting updated)
  --   - owned by user other than the current user
  cursor C_CONFLICT_TRIGGERS(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
    select
        trg.owner         owner
      , trg.trigger_name  trigger_name
      , trg.status        status
    from
        dba_triggers trg
    where trg.owner       <> user
      and trg.table_owner = x_table_owner
      and trg.table_name = x_table_name
    order by 1, 2;
begin
  l_task_name := x_trigger_name;

  -- disable any conflict triggers (workaround for DB Bug 13951889)
  -- TODO: remember explicit list of disabled triggers, only reenable those
  for crec in c_conflict_triggers(x_table_owner, x_table_name) loop
    if (crec.status = 'ENABLED') then
      log(c_module, 'STATEMENT',
          '['||l_task_name||'] Disable conflict trigger '||crec.owner||'.'||crec.trigger_name);
      exec('alter trigger "'||crec.owner||'"."'||crec.trigger_name||'" disable', c_module);
    end if;
  end loop;

  -- create parallel update statement
  l_stmt :=
      'update /*+ rowid (tbl) */ '||x_table_owner||'.'||x_table_name||' tbl '||
      'set '||x_column_name||'='||x_column_name||' '||
      'where rowid between :start_id and :end_id ';
  if x_where is not null then
    l_stmt := l_stmt||'  and ('||x_where||')';
  end if;

  log(c_module, 'STATEMENT', '['||l_task_name||'] Parallel Update for '||x_trigger_name);
  log(c_module, 'STATEMENT', '['||l_task_name||'] SQL: '||l_stmt);

  -- create task, handle possible conflicting task
  begin
    log(c_module, 'STATEMENT', '['||l_task_name||'] Create task');
    dbms_parallel_execute.create_task(l_task_name);
  exception
    when duplicate_task_error then
      log(c_module, 'STATEMENT', '['||l_task_name||'] Drop duplicate task');
      dbms_parallel_execute.drop_task(l_task_name);
      log(c_module, 'STATEMENT', '['||l_task_name||'] Create task (retry)');
      dbms_parallel_execute.create_task(l_task_name);
  end;

  -- create task chunks
  dbms_parallel_execute.create_chunks_by_rowid(
      l_task_name, x_table_owner, x_table_name, true, 10000);

  select count(chunk_id) into l_chunk_count
  from   user_parallel_execute_chunks
  where  task_name = l_task_name;

  -- if no chunks, then table was empty
  if (l_chunk_count = 0) then
    log(c_module, 'STATEMENT', '['||l_task_name||'] Table was empty');
    l_status := dbms_parallel_execute.finished;
  else
    -- apply crossedition trigger
    log(c_module, 'STATEMENT',
        '['||l_task_name||'] Executing parallel update task, chunks: '||to_char(l_chunk_count));

    -- get parallel_level
    l_parallel_level := calculate_parallel_level(l_chunk_count);

    dbms_parallel_execute.run_task(
        l_task_name, l_stmt, dbms_sql.native,
        apply_crossedition_trigger=>'"'||x_trigger_name ||'"', parallel_level=>l_parallel_level);
    l_status := dbms_parallel_execute.task_status(l_task_name);

    -- confirm task has finished
    if (l_status = dbms_parallel_execute.chunked) then
      -- Task did not execute, possible syntax error
      log(c_module, 'ERROR', '['||l_task_name||'] Parallel update task did not execute, internal error');
    elsif (l_status <> dbms_parallel_execute.finished) then
      -- Task did not finish, retry
      log(c_module, 'WARNING',
          '['||l_task_name||'] Parallel update task did not finish, status='||to_char(l_status)||', retrying...');
      dbms_parallel_execute.resume_task(l_task_name);
      l_status := dbms_parallel_execute.task_status(l_task_name);
    end if;
  end if;

  -- re-enable conflict triggers
  -- TODO: Enable only those triggers which were DISABLED by this API.
  for crec in c_conflict_triggers(x_table_owner, x_table_name) loop
    if (crec.status = 'DISABLED') then
      log(c_module, 'STATEMENT',
          '['||l_task_name||'] Re-enable conflict trigger '||crec.owner||'.'||crec.trigger_name);
      exec('alter trigger "'||crec.owner||'"."'||crec.trigger_name||'" enable', c_module, true);
    end if;
  end loop;

  -- If task did not finish properly, report error
  if (l_status <> dbms_parallel_execute.finished) then
    -- If Parallel chunks fails because of some reason then fetching errors from
    -- dba_parallel_execute_chunks table
    select substr(listagg(error_message, '# ') within group (order by error_message), 1, 3000) into l_error
    from (select distinct(substr(error_message,1,500)) as error_message
          from dba_parallel_execute_chunks
          where task_name=l_task_name
          and   status = 'PROCESSED_WITH_ERROR');

    error(c_module, '['||l_task_name||'] Parallel update task failed, status='||to_char(l_status)||
                       ' Error: '||l_error);
  end if;

  -- drop task
  log(c_module, 'STATEMENT',
      '['||l_task_name||'] Successful Parallel Update, dropping task');
  dbms_parallel_execute.drop_task(l_task_name);

  -- note: in case of exception, the task is not dropped,
  --       so that the error info is available for diagnostics.
end update_4fcet;


-- Create STUB Crossedition Trigger
--   A Stub trigger is created to satisfy a FOLLOWS dependency
--   or to replace an obsolete trigger
procedure STUB_CET(
  X_CET_OWNER    in varchar2,
  X_CET_NAME     in varchar2,
  X_TABLE_OWNER  in varchar2,
  X_TABLE_NAME   in varchar2,
  X_CROSSEDITION in varchar2,
  X_FOLLOWS      in varchar2 default '')
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.stub_cet';
  L_STMT            varchar2(1000);
  L_COLUMN          varchar2(30);
begin
  log(c_module, 'STATEMENT', 'Creating Stub CET: '||x_cet_owner||'.'||x_cet_name);

  -- use first column of base table as triggering column for stub trigger
  -- this is to minimize unnecessary firing of the stub
  select col.column_name into l_column
  from   dba_tab_columns col
  where  col.owner      = x_table_owner
    and  col.table_name = x_table_name
    and  col.column_id  = 1;

  -- create stub trigger, enabled
  l_stmt :=
    'create or replace trigger "'||x_cet_owner||'"."'||x_cet_name||
    '"  before insert or update of '||l_column||' on "'||
    x_table_owner||'"."'||x_table_name||
    '" for each row '||x_crossedition||' crossedition '||x_follows||
    ' begin null; end; ';
  exec(l_stmt, c_module);
end;


-- Determine the where clause required to apply this CET
--   Returns where clause expression to use in update_4fcet
--     '1<>1' no update required
--     '1=1' full update required
--     'source is not null' for simple column copy
function FCET_WHERE(X_CET_OWNER varchar2, X_CET_NAME varchar2) return varchar2
is
  C_MODULE varchar2(80) := 'ad.plsql.ad_zd_table.fcet_where';
  L_BODY long;
  L_TEXT varchar2(4000);
  L_POS number;
  L_WHERE varchar2(4000);
  L_OR varchar2(8);
  L_MATCH varchar2(4000);
  L_SOURCE varchar2(30);
begin
  ad_zd.log(c_module, 'PROCEDURE', 'begin: '||x_cet_owner||'.'||x_cet_name);

  select trg.trigger_body into l_body
  from all_triggers trg
  where trg.owner = x_cet_owner
    and trg.trigger_name = x_cet_name;

  l_text := substr(l_body, 1, 4000);

  -- check if stub CET
  if regexp_instr(l_text, '^\s*BEGIN\s+NULL\s*;\s*END\s*;', 1, 1, 1, 'i') > 0 then
    ad_zd.log(c_module, 'PROCEDURE', 'end: stub CET');
    return '1<>1';
  end if;

  -- parse begin
  --   regexp_instr(text, pattern, start_pos, nth_match, return_option[0|1], match_option)
  l_pos := regexp_instr(l_text, '^(\s*DECLARE)?\s*BEGIN\s+', 1, 1, 1, 'i');
  if l_pos = 0 then
    ad_zd.log(c_module, 'WARNING', 'could not parse '||x_cet_owner||'.'||x_cet_name);
    return '1=1';
  end if;

  -- parse copy statements, build where clause, loop till done
  --   regexp_substr(text, pattern, start_pos, nth_match, match_option, sub_expr)
  l_where := '';
  l_or := '';
  loop
    -- ad_zd.log(c_module, 'STATEMENT', '(parse copy) text@pos: ['||substr(l_text,l_pos)||']');
    l_match := regexp_substr(substr(l_text, l_pos), '^:NEW\.[[:alnum:]_#]+\s*:=\s*:NEW\.[[:alnum:]_#]+\s*;\s*', 1, 1, 'i');
    -- ad_zd.log(c_module, 'STATEMENT', '(parse copy) match result: ['||l_match||']');
    exit when l_match is null;

    l_source := regexp_substr(l_match, ':NEW\.[[:alnum:]_#]+\s*:=\s*:NEW\.([[:alnum:]_#]+)', 1, 1, 'i', 1);
    l_where := l_where||l_or||l_source||' is not null';
    l_pos := l_pos + length(l_match);
    l_or := ' or ';
  end loop;

  -- parse end
  -- ad_zd.log(c_module, 'STATEMENT', '(parse end) text@pos: ['||substr(l_text,l_pos)||']');
  if regexp_instr(substr(l_text,l_pos), '^END\s*;', 1, 1, 1, 'i') > 0 then
    ad_zd.log(c_module, 'PROCEDURE', 'end: '||l_where);
    return l_where;
  end if;

  ad_zd.log(c_module, 'PROCEDURE', 'end: could not parse '||x_cet_owner||'.'||x_cet_name);
  return '1=1';

exception
  when others then
    ad_zd.log(c_module, 'ERROR', 'exception while processing '||x_cet_owner||'.'||x_cet_name);
    return '1=1';
end FCET_WHERE;


-- Enable a CrossEdition Trigger (chain) for APPLY
--   Recursively enables any triggers this one follows first
--   For each trigger, the following steps are performed
--     1) enable predecessor triggers, if any, or create stub if missing
--     2) compile trigger, stub out obsolete triggers
--     3) enable trigger
--     4) out: store first trigger in firing chain for use by update_4fcet
--     5) out: generate where clause for use by update_4fcet
procedure ENABLE_CET(
  X_CET_OWNER    in varchar2,
  X_CET_NAME     in varchar2,
  X_UPD_CET      in out NOCOPY /* file.sql.39 change */ varchar2,
  X_UPD_WHERE    in out NOCOPY /* file.sql.39 change */ varchar2)
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.enable_cet';
  L_TRIGGER_STATUS  varchar2(8) := '';
  L_OBJECT_STATUS   varchar2(8);
  L_CROSSEDITION    varchar2(8);
  L_TABLE_OWNER     varchar2(30);
  L_TABLE_NAME      varchar2(30);
  L_FOLLOWS         varchar2(1000) := '';
  L_COMPILE_ERRORS  number;
  L_BIND_ERRORS     number;
  L_ERROR           varchar2(2000);
  L_FCET_WHERE      varchar2(4000);

  -- predecessor triggers must be enabled before specified trigger
  cursor C_PREDECESSORS(X_OWNER varchar2, X_NAME varchar2) is
    select
        tord.referenced_trigger_owner ref_trg_owner
      , tord.referenced_trigger_name  ref_trg_name
      , rtrg.status                   trg_status
    from
        dba_trigger_ordering tord
      , dba_triggers rtrg
    where tord.trigger_owner    = x_owner
      and tord.trigger_name     = x_name
      and tord.ordering_type    = 'FOLLOWS'
      and rtrg.owner(+)         = tord.referenced_trigger_owner
      and rtrg.trigger_name(+)  = tord.referenced_trigger_name
    order by 1, 2;

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_cet_owner||'.'||x_cet_name);

  -- Get CET info
  begin
    select trg.status, trg.crossedition, trg.table_owner, trg.table_name
    into   l_trigger_status, l_crossedition, l_table_owner, l_table_name
    from   dba_triggers trg
    where  trg.crossedition in ('FORWARD', 'REVERSE')
    and    trg.owner        = x_cet_owner
    and    trg.trigger_name = x_cet_name;
  exception
    when no_data_found then
      error(c_module, 'Crossedition Trigger '||x_cet_owner||'.'||x_cet_name||' does not exist');
  end;

  -- Ensure that predeccesor CET is enabled first
  --   Note: EBS development standards only allow a single "follows" predecessor,
  --         but DB syntax allows multiple "follows" clauses so we loop just in case
  --   Construct "follows" clause for current trigger in case we need it for stub creation
  for prerec in c_predecessors(x_cet_owner, x_cet_name) loop
    l_follows := l_follows||' follows "'||prerec.ref_trg_owner||'"."'||prerec.ref_trg_name||'"';
    if prerec.trg_status is NULL then
      -- missing predecessor, create stub trigger to satisfy dependency
      log(c_module, 'STATEMENT', 'Missing predecessor for trigger: '||x_cet_owner||'.'||x_cet_name||', creating stub');
      stub_cet(prerec.ref_trg_owner, prerec.ref_trg_name, l_table_owner, l_table_name, l_crossedition);
    end if;

    -- enable predecessor (recurses to first trigger)
    enable_cet(prerec.ref_trg_owner, prerec.ref_trg_name, x_upd_cet, x_upd_where);
  end loop;

  -- Save first CET in trigger chain
  if x_upd_cet is null then
    log(c_module, 'STATEMENT', 'Crossedition trigger '||x_cet_name||' is first in chain');
    x_upd_cet := x_cet_name;
  end if;

  -- Enable CET if needed
  if l_trigger_status <> 'ENABLED' then

    -- Compile CET, Check object status
    exec('alter trigger "'||x_cet_owner||'"."'||x_cet_name||'" compile', c_module);

    select obj.status into l_object_status
    from dba_objects obj
    where obj.owner        = x_cet_owner
      and obj.object_name  = x_cet_name
      and obj.object_type  = 'TRIGGER';

    if l_object_status <> 'VALID' then
      -- Invalid CET, Get error info
      select count(1), count(decode(message_number, 49, 1, NULL))
      into l_compile_errors, l_bind_errors
      from dba_errors
      where owner = x_cet_owner
        and name  = x_cet_name
        and type  = 'TRIGGER';

      if l_bind_errors > 0 and l_bind_errors = l_compile_errors then
        -- If compile errors are all bind errors, this is an obsolete trigger, stub, ignore
        log(c_module, 'WARNING', 'Crossedition trigger '||x_cet_name||' is obsolete, replacing with stub');
        stub_cet(x_cet_owner, x_cet_name, l_table_owner, l_table_name, l_crossedition, l_follows);
      else
        -- Non-ignorable compile errors, fail
        select substr(listagg(text, ':: ') within group (order by text), 1, 2000) into l_error
        from (select substr(text,1,200) as text
              from dba_errors
              where owner = x_cet_owner
                and name  = x_cet_name
                and type  = 'TRIGGER');
        error(c_module, 'Could not enable invalid crossedition trigger "'||
                            x_cet_owner||'"."'||x_cet_name||'": '||l_error);
      end if;
    end if; -- Invalid CET

    -- Enable valid CET
    exec('alter trigger "'||x_cet_owner||'"."'||x_cet_name||'" enable', c_module);

  end if;

  -- FCET: add CET where clause to CET APPLY update statement
  if l_crossedition = 'FORWARD' then
    l_fcet_where := fcet_where(x_cet_owner, x_cet_name);
    if x_upd_where is null then
      x_upd_where := l_fcet_where;
    else
      x_upd_where := x_upd_where||' or '||l_fcet_where;
    end if;
  end if;

  log(c_module, 'PROCEDURE', 'end: '||x_cet_name||' - enabled');
end;


--
--  Apply Crossedition Trigger
--
-- Enables crossedition trigger, then updates table to apply
--
-- Multilple crossedition triggers may be applied on the same table. For
-- performance purposes, only the APPLY call for the final trigger will
-- will be executed, which will enable and apply all triggers on the table
-- in a single update.
--
-- If the specified trigger "follows" other triggers or non-existant
-- triggers, this procedure will recursively enable or create
-- the referenced triggers first, as needed.
--
procedure APPLY(X_CET_NAME  in varchar2)
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.apply';
  C_CET_OWNER       varchar2(30) := ad_zd.apps_schema;
  L_STATUS          varchar2(8);
  L_CROSSEDITION    varchar2(8);
  L_TABLE_OWNER     varchar2(30);
  L_TABLE_NAME      varchar2(30);
  L_EXISTS          varchar2(1);
  L_SCN             number := null;
  L_UPD_WHERE       varchar2(4000);
  L_UPD_CET         varchar2(30);
  L_UPD_COLUMN      varchar2(30);
  L_ERROR           varchar2(2000);

begin
  log(c_module, 'PROCEDURE', 'begin: '||x_cet_name);

  -- Get CET info
  begin
    select trg.status, trg.crossedition, trg.table_owner, trg.table_name
    into   l_status, l_crossedition, l_table_owner, l_table_name
    from   dba_triggers trg
    where  trg.crossedition in ('FORWARD', 'REVERSE')
    and    trg.owner        = c_cet_owner
    and    trg.trigger_name = x_cet_name;
  exception
    when no_data_found then
      error(c_module, 'Crossedition Trigger '||c_cet_owner||'.'||x_cet_name||' does not exist');
  end;

  -- Apply not supported on seed data synchronization trigger
  if (x_cet_name = ad_zd_seed.eds_fcet(l_table_name)) then
    error(c_module, 'Improper call to "apply" seed data synchronization trigger: '||x_cet_name);
  end if;

  log(c_module, 'EVENT', 'Apply crossedition trigger: '||c_cet_owner||'.'||x_cet_name);

  -- Only the final trigger in FCET FOLLOWS chain will do apply processing
  -- Ignore any apply calls to predecessor triggers
  begin
    select 'Y' into l_exists from dual
    where exists
      ( select tord.trigger_name
        from   dba_trigger_ordering tord
        where  tord.referenced_trigger_owner = c_cet_owner
          and  tord.referenced_trigger_name  = x_cet_name
          and  tord.ordering_type            = 'FOLLOWS' );

    log(c_module, 'PROCEDURE', 'end: '||x_cet_name||' - forward predecessor');
    return;
  exception
    when no_data_found then null;
  end;

  -- Enable CET (and its predecessors)
  l_upd_cet := null;
  l_upd_where := null;
  enable_cet(c_cet_owner, x_cet_name, l_upd_cet, l_upd_where);

  -- If this is a reverse crossedition trigger, no need to update table
  if l_crossedition = 'REVERSE' then
    log(c_module, 'PROCEDURE', 'end: '||x_cet_name||' - reverse');
    return;
  end if;

  -- At this point we are applying the final trigger of the FCET trigger chain
  -- Execute the table update to apply all FCET triggers in the trigger chain

  -- Wait on pending DML so that update will not be overwritten by stale data
  -- Note: if timeout error occurs while waiting, we raise error, but there is
  --       no need to disable the triggers.  Call apply again at a later time.
  log(c_module, 'STATEMENT', 'Waiting on pending DML for '||l_table_owner||'.'||l_table_name);
  if not dbms_utility.wait_on_pending_dml(l_table_owner||'.'||l_table_name, null, l_scn) then
    error(c_module, 'Pending transactions block apply of '||x_cet_name);
  end if;

  -- Get Update Column
  --   Any column will do, but should be least-indexed and smallest column for best performance
  select x.column_name into l_upd_column from
    ( select col.column_name, count(idc.index_name), col.data_length
      from   dba_tab_columns col, dba_ind_columns idc
      where  col.owner      = l_table_owner
        and  col.table_name = l_table_name
        and  idc.table_owner(+) = col.owner
        and  idc.table_name(+)  = col.table_name
        and  idc.column_name(+) = col.column_name
      group by col.column_name, col.data_length
      order by count(idc.index_name), col.data_length ) x
  where rownum = 1;

  -- update table
  begin
    ad_zd_table.update_4fcet(l_table_owner, l_table_name, l_upd_cet, l_upd_column, l_upd_where);
  exception
    when others then
      l_error := substrb(sqlerrm, 1, 2000);
      -- TODO: Disable entire predecessor chain?
      -- exec('alter trigger "'||c_cet_owner||'"."'||x_cet_name||'" disable', c_module);
      error(c_module, 'Could not apply crossedition trigger "'||x_cet_name||'": '||l_error);
  end;

  log(c_module, 'PROCEDURE', 'end: '||x_cet_name||' - forward final');
end APPLY;




/*===================================================================================
**
**    Index Tools
**
** ===================================================================================
*/

-- Revised Index Name from Original Index Name
function REVISED_INDEX_NAME(X_ORIGINAL_INDEX_NAME in varchar2) return varchar2 is
begin
  return translate(x_original_index_name, '_', '~');
end REVISED_INDEX_NAME;

-- Regular expression for Revised Index Names
function REVISED_INDEX_REGEXP return varchar2 is
begin
  return '^[A-Z][0-9A-Z~$]*~[0-9A-Z$]*$';
end REVISED_INDEX_REGEXP;

-- Original Index Name from Revised Index Name
function ORIGINAL_INDEX_NAME(X_REVISED_INDEX_NAME in varchar2) return varchar2 is
begin
  return translate(x_revised_index_name, '~', '_');
end ORIGINAL_INDEX_NAME;

-- Regular expression for Original Index Names
function ORIGINAL_INDEX_REGEXP return varchar2 is
begin
  return '^[A-Z][0-9A-Z_$]*_[0-9A-Z$]*$';
end ORIGINAL_INDEX_REGEXP;


/*
** Revise Index
**
** Generates a revised index using the latest revised columns:
**   1) query the columns for the original index
**   2) use editioning view to map logical columns to new columns
**   3) create new index using new columns
*/
procedure REVISE_INDEX(
  X_TABLE_OWNER       in varchar2,
  X_TABLE_NAME        in varchar2,
  X_INDEX_OWNER       in varchar2,
  X_INDEX_NAME        in varchar2,
  X_INDEX_TYPE        in varchar2,
  X_INDEX_PARTITIONED in varchar2)
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.revise_index';
  L_REVISED_NAME    varchar2(30);
  L_TABLE_OWNER     varchar2(30);
  L_TABLE_NAME      varchar2(30);
  L_PRE_STMT        varchar2(1000);
  L_COL_STMT        varchar2(30000);
  L_POST_STMT       varchar2(1000);
  L_STMT            varchar2(32000);
  L_NEW_COLUMN      varchar2(4000);
  L_FIRST           boolean;

  L_PIDX_DDL_CLOB     clob;
  L_OBJECT_TYPE       varchar2(5) :='INDEX';
  L_PIDX_REV_COL_NAME varchar2(30);

  cursor C_INDEX_COLUMNS(x_owner varchar2, x_name varchar2) is
    select idc.column_name
    from   dba_ind_columns idc
    where  idc.index_owner = x_owner
    and  idc.index_name  = x_name
    order by column_position;
begin
  log(c_module, 'PROCEDURE', 'Revising index: '||x_index_owner||'.'||x_index_name);
  log(c_module, 'PROCEDURE', 'Index type: '||x_index_type||' and partitioned flag: '||x_index_partitioned);

  -- AD Bug#31249933:NZDT AUTOMATIC REVISION OF PARTITION INDEX
  -- Data Model Changes on the indexed(partitioned) columns of the
  -- partitioned table will trigger this automatic revision flow
  if(x_index_partitioned ='YES') then
    l_pidx_ddl_clob := dbms_metadata.get_ddl(l_object_type,x_index_name,x_index_owner);

    --Replace the index name with revised index name
    l_pidx_ddl_clob := regexp_replace(l_pidx_ddl_clob,'(^|\W)'||x_index_name||'($|\W)','"'||ad_zd_table.revised_index_name(x_index_name)||'"',1,1,'i');

    log(c_module, 'STATEMENT', 'Modified partitioned ddl with revised index name '||substr(l_pidx_ddl_clob,1,3900));

    for icolrec in c_index_columns(x_index_owner, x_index_name) loop
      if icolrec.column_name = 'ZD_EDITION_NAME' then
        l_pidx_rev_col_name := icolrec.column_name;
      else
        l_pidx_rev_col_name :=  ev_table_column(x_table_owner, ev_view(x_table_name), ev_view_column(icolrec.column_name));
      end if;

      --Replace column name with revised column name
      l_pidx_ddl_clob := regexp_replace(l_pidx_ddl_clob,'(^|\W)'||icolrec.column_name||'($|\W)','"'||l_pidx_rev_col_name||'"',1,1,'i');
    end loop;

    log(c_module, 'STATEMENT', 'Modified partitioned ddl with revised columns is '||substr(l_pidx_ddl_clob,1,3900));
  else
    -- generate pre/post statement
    -- TODO:
    -- 1- use DBMS_METADATA
    -- 2- table_owner, table_name already available as input, use them
    --  -----------------------
    select table_owner, table_name,
    'create '||
      decode(index_type,
     'NORMAL', decode(uniqueness, 'UNIQUE', 'UNIQUE', ''),
     index_type)||
      ' index "'||owner||'"."'||ad_zd_table.revised_index_name(index_name)||'"'||
      ' on "'||table_owner||'"."'||table_name||'"' I_HEADER,
      decode(nvl(tablespace_name,'???'),'???','','tablespace '||tablespace_name)||
      ' storage (initial '||nvl(initial_extent, 128*1024)/1024||'K '||
       'next '||nvl(next_extent, 128*1024)/1024||'K)'
    into   l_table_owner, l_table_name, l_pre_stmt, l_post_stmt
    from   dba_indexes
    where  owner      = x_index_owner
    and    index_name = x_index_name;

    -- prepare column clause
    l_col_stmt  := ' (';
    l_first     := TRUE;
    -- for each old index column...
    for icolrec in c_index_columns(x_index_owner, x_index_name) loop
      -- get new revised column name
      if icolrec.column_name = 'ZD_EDITION_NAME' then
        l_new_column := icolrec.column_name;
      else
        l_new_column := ev_table_column(l_table_owner, ev_view(l_table_name), ev_view_column(icolrec.column_name));
      end if;
      -- add new column to index creation statement
      if l_first then
        l_first := FALSE;
      else
        l_col_stmt := l_col_stmt||', ';
      end if;
        l_col_stmt := l_col_stmt||l_new_column;
    end loop;
    l_col_stmt := l_col_stmt||') ';
  end if;

  -- drop existing revised index, if any
  begin
    select idx.index_name
    into   l_revised_name
    from   dba_indexes idx
    where  idx.owner      = x_index_owner
    and    idx.index_name = ad_zd_table.revised_index_name(x_index_name);

    exec('drop index "'||x_index_owner||'"."'||l_revised_name||'"', c_module);
  exception
    when no_data_found then
      null;
  end;

  -- AD Bug#31249933:NZDT AUTOMATIC REVISION OF PARTITION INDEX
  -- Data Model Changes on the indexed(partitioned) columns of the
  -- partitioned table will trigger this automatic revision flow
  if(x_index_partitioned ='YES') then
    begin
      -- try ONLINE PARALLEL NOLOGGING first, then regular mode.
      log(c_module, 'STATEMENT', 'SQL: '||substr(l_pidx_ddl_clob,1,3900));
      exec(l_pidx_ddl_clob||' online parallel nologging', c_module);
    exception
      when others then
        if sqlcode = -1450 then
          -- maximum key length exceeded
          -- try to build the index without the ONLINE keyword
           log(c_module, 'WARNING', 'Maximum keylength exceeded, trying blocking DDL: '||x_index_name);
           log(c_module, 'STATEMENT', 'SQL: '||substr(l_pidx_ddl_clob,1,3900));
           exec(l_pidx_ddl_clob||' parallel nologging', c_module);
        elsif sqlcode = -1408 then
          -- such column list already indexed
          -- okay to ignore this as replacement index created under different name
          log(c_module, 'STATEMENT',
            'Index not revised, replacement already exists: '||x_index_name);
        else
          error(c_module, 'ERROR: '||SQLERRM|| ', SQL: '||substr(l_pidx_ddl_clob,1,3900));
        end if;
    end;
  else
    -- Create Revised Non partitioned Index
    begin
      -- try ONLINE first, then regular mode.
      l_stmt := l_pre_stmt||l_col_stmt||l_post_stmt||' online';
      log(c_module, 'STATEMENT', 'SQL: '||l_stmt);
      execute immediate l_stmt;
    exception
      when others then
        if sqlcode = -1450 then
          -- maximum key length exceeded
          -- try to build the index without the ONLINE keyword
          log(c_module, 'WARNING', 'Maximum keylength exceeded, trying blocking DDL: '||x_index_name);
          l_stmt := l_pre_stmt||l_col_stmt||l_post_stmt;
          log(c_module, 'STATEMENT', 'SQL: '||l_stmt);
          execute immediate l_stmt;
        elsif sqlcode = -1408 then
          -- such column list already indexed
          -- okay to ignore this as replacement index created under different name
          log(c_module, 'STATEMENT',
            'Index not revised, replacement already exists: '||x_index_name);
        else
          error(c_module, 'ERROR: '||SQLERRM|| ', SQL: '||l_stmt);
        end if;
    end;
  end if;

  log(c_module, 'PROCEDURE', 'end');
end REVISE_INDEX;


/*
** Revise Indexes for Table
**
**   Locates each out-of-date index for a table, and revises that index
**
** Note: Index organized tables are not supported
*/
procedure REVISE_INDEXES(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2)
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.revise_indexes';
  L_INDEX_OWNER     varchar2(30);
  L_INDEX_NAME      varchar2(30);

  -- Out Of Date indexes for a table
  --   A) Original Index with out of date columns and no Revised Index
  --   B) Revised Index with out of date columns
  cursor c_ood_indexes(x_table_owner varchar2, x_table_name varchar2) is
    select idx.owner, idx.index_name, idx.index_type, idx.partitioned
    from  dba_indexes idx
    where idx.owner in
            ( select oracle_username from ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A', 'B', 'E', 'U') )
      and idx.owner       = idx.table_owner
      and idx.table_owner = x_table_owner
      and idx.table_name  = x_table_name
      and exists /* index is out of date */
            ( select col.column_name
              from   dba_tab_columns col, dba_ind_columns idc
              where  col.owner       = idx.table_owner
                and  col.table_name  = idx.table_name
                and  idc.index_owner = idx.owner
                and  idc.index_name  = idx.index_name
                and  ad_zd_table.ev_view_column(idc.column_name)=ad_zd_table.ev_view_column(col.column_name)
                and  col.column_name > idc.column_name )
      and ( /* original index with no revsied index */
            regexp_like(idx.index_name, ad_zd_table.original_index_regexp, 'c')
            and not exists
                ( select idt.index_name
                  from   dba_indexes idt
                  where  idt.owner = idx.owner
                    and  idt.index_name = ad_zd_table.revised_index_name(idx.index_name) )
          or
            /* Revised Index */
            regexp_like(idx.index_name, ad_zd_table.revised_index_regexp, 'c')
          )
    order by 1, 2;

begin
  log(c_module, 'PROCEDURE',
      'begin: '||nvl(x_table_owner, 'NULL')||'.'||nvl(x_table_name, 'NULL'));

  -- revise each out-of-date index for the table
  for idxrec in c_ood_indexes(x_table_owner, x_table_name) loop
    if idxrec.index_type = 'IOT - TOP' then
      error(c_module, 'Automatic Revision of Index Organized Table not yet implemented: '||idxrec.owner||'.'||idxrec.index_name);
    elsif idxrec.index_type = 'FUNCTION-BASED NORMAL' then
      error(c_module, 'Automatic Revision of Function-based Index not yet implemented: '||idxrec.owner||'.'||idxrec.index_name);
    elsif idxrec.index_type = 'DOMAIN' then
      error(c_module, 'Automatic Revision of Domain Index not yet implemented: '||idxrec.owner||'.'||idxrec.index_name);
    else
      revise_index(x_table_owner, x_table_name,idxrec.owner, idxrec.index_name, idxrec.index_type, NVL(idxrec.partitioned,'NO'));
    end if;
  end loop;

  log(c_module, 'PROCEDURE', 'end');
end REVISE_INDEXES;


/*
** Cutover to revised Indexes for given table
**
** X_TABLE_OWNER - table owner filter (match any owner if NULL)
** X_TABLE_NAME  - table name filter (match any table if NULL)
*/
procedure CUTOVER_INDEXES(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2)
is
  C_MODULE    varchar2(80) := 'ad.plsql.ad_zd_table.cutover_indexes';

  -- Cutover Indexes are
  --   New or Revised indexes
  --   Obsolete indexes
  cursor C_CUTOVER_INDEXES(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
    select /* revised indexes */
        ridx.owner          owner
      , ridx.index_name     revised_index
      , ridx.table_owner    table_owner
      , ridx.table_name     table_name
      , oidx.index_name     original_index
      , con.constraint_name constraint_name
    from
        dba_indexes ridx
      , dba_indexes oidx
      , dba_constraints con
    where ridx.owner in
            ( select oracle_username from ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A', 'B', 'E', 'U') )
      and ridx.table_owner = x_table_owner
      and ridx.table_name  = x_table_name
      and regexp_like(ridx.index_name, ad_zd_table.revised_index_regexp, 'c')
      and oidx.owner(+)      = ridx.owner
      and oidx.index_name(+) = ad_zd_table.original_index_name(ridx.index_name)
      and con.owner(+)       = x_table_owner
      and con.table_name(+)  = x_table_name
      and con.index_owner(+) = oidx.owner
      and con.index_name(+)  = oidx.index_name
    union
    select /* obsolete indexes */
        oidx.owner          owner
      , null                revised_index
      , oidx.table_owner    table_owner
      , oidx.table_name     table_name
      , oidx.index_name     original_index
      , con.constraint_name constraint_name
    from
        dba_indexes oidx
      , dba_constraints con
    where oidx.owner in
            ( select oracle_username from ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A', 'B', 'E', 'U') )
      and oidx.owner       = oidx.table_owner
      and oidx.table_owner = x_table_owner
      and oidx.table_name  = x_table_name
      and regexp_like(oidx.index_name, ad_zd_table.original_index_regexp, 'c')
      /* Revised Index does not exist */
      /*Added the hint below because of Bug 21908492*/
      and not exists
            ( select /*+ push_subq no_unnest*/ idt.index_name
              from   dba_indexes idt
              where  idt.owner       = oidx.owner
                and  idt.table_owner = x_table_owner
                and  idt.table_name  = x_table_name
                and  idt.index_name  = ad_zd_table.revised_index_name(oidx.index_name) )
      /* Original Index is out of date */
      /*Added the hint below because of Bug 21908492*/
      and exists
            ( select /*+ push_subq no_unnest*/ col.column_name
              from   dba_tab_columns col, dba_ind_columns idc
              where  col.owner       = x_table_owner
                and  col.table_name  = x_table_name
                and  idc.index_owner = oidx.owner
                and  idc.index_name  = oidx.index_name
                and  idc.table_owner = x_table_owner
                and  idc.table_name  = x_table_name
                and  ad_zd_table.ev_view_column(idc.column_name)=ad_zd_table.ev_view_column(col.column_name)
                and  col.column_name > idc.column_name )
      and con.owner(+)       = x_table_owner
      and con.table_name(+)  = x_table_name
      and con.index_owner(+) = oidx.owner
      and con.index_name(+)  = oidx.index_name
    order by 1, 2;

begin
  log(c_module, 'PROCEDURE',
      'begin: '||nvl(x_table_owner,'NULL')||'.'||nvl(x_table_name,'NULL'));

   -- for each cutover index
  for idxrec in c_cutover_indexes(x_table_owner, x_table_name) loop
    log(c_module, 'STATEMENT',
        'Cutover index: '||idxrec.owner||'.'||nvl(idxrec.revised_index, idxrec.original_index));

    -- drop constraint, if it exists
    if idxrec.constraint_name is not null then
  begin
   exec('alter table "'||idxrec.table_owner||'"."'||idxrec.table_name||
           '" drop constraint "'||idxrec.constraint_name||'" cascade keep index', c_module);
   exception
        when others then
    if (SQLCODE = -02443) then
    null;
    else
    log(c_module, 'ERROR', 'Error while dropping constraint '
        ||idxrec.constraint_name|| ': ' || substr(sqlerrm, 1, 2000));
    end if;
      end;
    end if;
    -- drop original index, if it exists
    if idxrec.original_index is not null then
      exec('drop index "'||idxrec.owner||'"."'||idxrec.original_index||'"', c_module);
    end if;

    -- rename the revised index to the original name, if it exists
    if idxrec.revised_index is not null then
      exec('alter index "'||idxrec.owner||'"."'||idxrec.revised_index||'" '||
           'rename to "'||original_index_name(idxrec.revised_index)||'"', c_module);
    end if;
  end loop;

  log(c_module, 'PROCEDURE', 'end');
end CUTOVER_INDEXES;




/*
** --------------------------------------------------------------------
**    Event Interfaces
** --------------------------------------------------------------------
*/


/*
** Patch Table
**
** X_TABLE_OWNER - table owner
** X_TABLE_NAME  - table name
**
** This procedure must be called after an existing table is patched with
**   - Add column
**   - Create index
*/
procedure PATCH(
  X_TABLE_OWNER in varchar2,
  X_TABLE_NAME  in varchar2)
is
  C_MODULE         varchar2(80) := 'ad.plsql.ad_zd_table.patch';
  L_TABLE_EXISTS     varchar2(10);
begin
  log(c_module,'EVENT',  'Patch table: '||x_table_owner||'.'||x_table_name);

  begin
  select null
    into l_table_exists
    from dba_tables
    where  owner = x_table_owner
    and table_name = x_table_name;
  exception when no_data_found then
    error(c_module, x_table_owner ||'.'|| x_table_name || ' does not exist');
  end;

  -- If there is an EV then do related processing
  if ad_zd_table.ev_exists(x_table_owner, x_table_name) = 'Y' then

    -- Cannot regenerate EV from RUN edition if PATCH edition exists
    if ad_zd.get_edition_type = 'RUN' and ad_zd.get_edition('PATCH') is not null then
      error(c_module, 'Cannot PATCH table from Run Edition while Patch Edition exists');
   end if;

    -- Generate revised editioning view
    generate_ev(x_table_owner, x_table_name);

    -- For seed data tables, call patch processing in seed data manager
    if is_seed(x_table_owner, x_table_name) = 'Y' then
      ad_zd_seed.patch(x_table_owner, x_table_name);
    end if;

  end if;

  -- Store table for Finalize/Cutover processing
  store(x_table_owner, x_table_name);

end PATCH;


/*
** Finalize Tables (get ready for cutover)
**
** Process tables that have been marked as Patched
**   Check for un-applied Forward Crossedition Triggers
**   Revise Out-of-date Indexes
*/
procedure FINALIZE is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.finalize';

  cursor C_PATCHED_TABLES is
    select owner, name, status
    from   ad_patched_tables
    where  status in ('N', 'U');

  -- TODO: Find out a way to detect patched tables when there is
  --       a single database-edition.
  cursor C_NO_FCET is
    select /*+ leading ( adp ) cardinality ( adp 10 ) */
           tabcol.owner table_owner,
           tabcol.table_name,
           runcol.view_column_name,
           tabcol.column_name table_column_name
    from  ad_patched_tables adp
        , dba_editioning_view_cols_ae runcol  /* columns used by run edition EV */
        , dba_tab_columns tabcol             /* table columns */
    where tabcol.owner        = adp.owner
      and tabcol.table_name   = adp.name
      and tabcol.column_name like '%#%'
      and runcol.owner        = tabcol.owner
      and runcol.view_name    = ad_zd_table.ev_view(ADP.NAME)
      and runcol.edition_name = (select max(runev.edition_name) run_ev_edition
                                 from dba_editioning_views_ae runev
                                 where runev.owner     = runcol.owner
                                   and runev.view_name = runcol.view_name
                                   and edition_name    <  ad_zd.get_edition )
      and ad_zd_table.ev_view_column(tabcol.column_name) = runcol.view_column_name
      and tabcol.column_name > runcol.table_column_name
      and not exists                                /* is FCET missing or not applied? */
            (select /*+ push_pred(trgc) no_push_subq no_unnest */ null
             from dba_triggers trg, dba_trigger_cols trgc
             where trg.table_owner     = tabcol.owner
               and trg.table_name      = tabcol.table_name
               and trg.crossedition    = 'FORWARD'
               and trg.status          = 'ENABLED'
               and trgc.trigger_owner  = ad_zd.apps_schema
               and trgc.table_owner    = tabcol.owner
               and trgc.table_name     = tabcol.table_name
               and trgc.trigger_owner  = trg.owner
               and trgc.trigger_name   = trg.trigger_name
               and trgc.column_name    = tabcol.column_name
               and trgc.column_usage like 'NEW %OUT%' );
begin
  log(c_module,'PROCEDURE', 'begin: no parameter(s)');

  -- Gather stats before  C_NO_FCET cursor
  dbms_stats.gather_table_stats (ad_zd.applsys_schema, 'AD_PATCHED_TABLES');

  for l_col_rec in c_no_fcet loop
    log(c_module,  'ERROR', 'Revised column '|| l_col_rec.table_owner||'.'||l_col_rec.table_name ||
      '.' || l_col_rec.table_column_name || ' is not populated by a crossedition trigger. '||
      'To avoid data loss, apply a corrective patch in the same online patching cycle or abort the online patching cycle');
  end loop;

  for l_tab_rec in c_patched_tables loop
    log(c_module,  'STATEMENT', 'Process table '|| l_tab_rec.owner||'.'||l_tab_rec.name);

    -- Revise Out-of-date Indexs
    revise_indexes(l_tab_rec.owner, l_tab_rec.name);

    -- Store cutover action
    if (l_tab_rec.status = 'N') then
      ad_zd_parallel_exec.load(
        x_phase  => ad_zd_parallel_exec.c_phase_cutover,
        x_sql     => 'begin ad_zd_table.cutover('||
                     ''''||l_tab_rec.owner||''', '||
                     ''''||l_tab_rec.name||'''); end;',
        x_unique => true);
    end if;

    -- Mark as Complete
    update ad_patched_tables
    set status = 'C'
    where owner = l_tab_rec.owner
    and   name  = l_tab_rec.name;
    commit;

  end loop;

  log(c_module,'PROCEDURE', 'end');
end FINALIZE;



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
procedure CUTOVER(
  X_TABLE_OWNER  varchar2,
  X_TABLE_NAME   varchar2,
  X_EXECUTE      boolean default true)
is
  C_MODULE   varchar2(80) := 'ad.plsql.ad_zd_table.cutover';

  -- Obsolete columns for the specified table:
  --   columns which are not shown in the editioning view
  cursor C_OBSOLETE_COLUMNS(X_OWNER varchar2, X_TABLE_NAME varchar2) is
    select col.owner, col.table_name, col.column_name, col.nullable, col.data_default
    from  dba_tab_columns col
        , dba_editioning_views ev
    where col.owner       = x_owner
      and col.table_name  = x_table_name
      and col.column_name <> 'ZD_EDITION_NAME'
      and ev.owner      = x_owner
      and ev.view_name  = substrb(x_table_name, 1, 29)||'#'
      and not exists
            ( select evc.table_column_name
              from  dba_editioning_view_cols evc
              where evc.owner     = ev.owner
                and evc.view_name = ev.view_name
                and evc.table_column_name = col.column_name )
    order by col.owner, col.table_name, col.column_name;

  -- Multi-Column constraints on obsolete column
  cursor C_COLUMN_CONSTRAINTS(X_OWNER varchar2, X_TABLE_NAME varchar2, X_COLUMN_NAME varchar2) is
    select cc.constraint_name
    from  dba_cons_columns cc
    where cc.owner       = x_owner
      and cc.table_name  = x_table_name
      and cc.column_name = x_column_name;
begin
  log(c_module, 'PROCEDURE', 'begin: '||x_table_owner||'.'||x_table_name);
  log(c_module,'EVENT', 'Cutover table: '||x_table_owner||'.'||x_table_name);

  -- Cutover Indexes
  cutover_indexes(x_table_owner, x_table_name);

  -- Remove constraints from obsolete columns
  --   - Not Null Constraints
  --   - Multi-column constraints
  for colrec in  c_obsolete_columns(x_table_owner, x_table_name) loop

    -- remove Not Null constraint if column has no default value
    if (colrec.nullable = 'N' and
        (colrec.data_default is null or upper(colrec.data_default) = 'NULL')) then
      log(c_module, 'STATEMENT',
          'Alter obsolete column to be nullable: '||
           colrec.owner||'.'||colrec.table_name||'.'||colrec.column_name);

      exec('alter table "'||colrec.owner||'"."'||colrec.table_name||'"'||
           '  modify ("'||colrec.column_name||'" null)', c_module);
    end if;

    -- remove multi-column constraints involving this column, if any
    for conrec in c_column_constraints(colrec.owner, colrec.table_name, colrec.column_name) loop
      log(c_module, 'STATEMENT',
          'Drop Obsolete column constraint: '||
           colrec.owner||'.'||colrec.table_name||'.'||conrec.constraint_name);

      exec('alter table "'||colrec.owner||'"."'||colrec.table_name||'"'||
           '  drop constraint "'||conrec.constraint_name||'"', c_module);
    end loop;

  end loop;

  begin
    delete from ad_patched_tables
    where owner = x_table_owner
    and   name  = x_table_name;
  exception
    when no_data_found then
      null;
  end;

  log(c_module, 'PROCEDURE', 'end');
end CUTOVER;


/*
** Cleanup Table
**
** X_TABLE_OWNER - filter for tables to clean (match any owner if NULL)
** X_TABLE_NAME  - filter for tables to clean (match any table if NULL)
** X_CLEAN_MODE - how to clean
**   'QUICK'  - standard post-patch cleanup, drops indexes, triggers
**   'FULL'   - include obsolete columns (danger, should be fully actualized)
**
** Drop CETS
** Mark obsolete columns as unused (FULL)
*/
procedure CLEANUP(
  X_TABLE_OWNER in varchar2 default NULL,
  X_TABLE_NAME  in varchar2 default NULL,
  X_CLEAN_MODE  in varchar2 default 'QUICK')
is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.cleanup';
  L_INDEX_OWNER     varchar2(30);
  L_INDEX_NAME      varchar2(30);
  L_TABLE_OWNER     varchar2(30);
  L_TABLE_NAME      varchar2(30);
  L_COLUMN_NAME     varchar2(30);

  -- Crossedition Triggers
  cursor C_CETS(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
    select trg.owner, trg.trigger_name
    from   dba_triggers trg
    where  trg.crossedition in ('FORWARD', 'REVERSE')
      and  trg.table_owner = nvl(x_table_owner, trg.table_owner)
      and  trg.table_name  = nvl(x_table_name,  trg.table_name)
    order by trg.owner, trg.trigger_name;

  -- Obsolete Columns
  cursor C_OBSOLETE_COLUMNS(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
    select col.owner, col.table_name, col.column_name
    from   dba_tab_columns col
         , dba_editioning_views ev
    where ev.owner in
            ( select oracle_username
              from   ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A','E','B') )
      and ev.owner        = nvl(x_table_owner, col.owner)
      and ev.table_name   = nvl(x_table_name,  col.table_name)
      and col.column_name <> 'ZD_EDITION_NAME'
      and ev.owner        = col.owner
      and ev.table_name   = col.table_name
      and not exists
           ( select evc.table_column_name
              from  dba_editioning_view_cols evc
              where evc.owner     = ev.owner
              and   evc.view_name = ev.view_name
              and   evc.table_column_name = col.column_name )
      order by col.owner, col.table_name, col.column_name;

  -- EV Tables with unused columns
  -- Currently not used, but in future, use this to find tables that need online redef
  cursor C_UNUSED_COL_TABS(X_TABLE_OWNER varchar2, X_TABLE_NAME varchar2) is
    select ev.owner, ev.table_name
    from   dba_unused_col_tabs uct, dba_editioning_views ev
    where  uct.owner in
            ( select oracle_username
              from   ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A','E','B') )
      and  uct.owner       = nvl(x_table_owner, uct.owner)
      and  uct.table_name  = nvl(x_table_name,  uct.table_name)
      and  ev.owner      = uct.owner
      and  ev.table_name = uct.table_name
    order by 1, 2;

begin
  log(c_module, 'PROCEDURE',
      'begin: '||nvl(x_table_owner,'ALL')||'.'||nvl(x_table_name,'ALL')||', '||x_clean_mode);

  -- Cleanup CETs
  log(c_module, 'EVENT', 'Cleanup crossedition triggers');
  for cetrec in c_cets(x_table_owner, x_table_name) loop
    exec('alter trigger "'||cetrec.owner||'"."'||cetrec.trigger_name||'" DISABLE', c_module, true);
  end loop;
  for cetrec in c_cets(x_table_owner, x_table_name) loop
    exec('drop trigger "'||cetrec.owner||'"."'||cetrec.trigger_name||'"', c_module, true);
  end loop;

  -- Additional actions for FULL cleanup
  if x_clean_mode = 'FULL' then
    -- Mark unused columns
    log(c_module, 'EVENT', 'Cleanup unused columns');
    for colrec in c_obsolete_columns(x_table_owner, x_table_name) loop

      -- note: if this fails we really do want the error
      exec('alter table "'||colrec.owner||'"."'||colrec.table_name||'"'||
           '  set unused ('||colrec.column_name||')', c_module);
    end loop;
  end if;

  log(c_module, 'PROCEDURE', 'end');
end CLEANUP;


/*
** Abort patch edition
**
**   Drop new or revised indexes
**   Remove unused column not null constratints
**   Note: CETS are dropped when the Patch Edition is dropped
**   Note: Unused columns are handled during FULL cleanup
*/
procedure ABORT is
  C_MODULE          varchar2(80) := 'ad.plsql.ad_zd_table.abort';

  -- Patched Indexes: created since the patch edition
  cursor C_PATCHED_INDEXES is
    select idx.owner, idx.index_name,
           con.owner table_owner, con.table_name, con.constraint_name
    from
        dba_indexes idx
      , dba_constraints con
    where idx.owner in
            ( select oracle_username from ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A', 'B', 'E', 'U') )
      and regexp_like(idx.index_name, ad_zd_table.revised_index_regexp, 'c')
      and con.owner(+)      = idx.table_owner
      and con.table_name(+) = idx.table_name
      and con.index_name(+) = idx.index_name
    order by 1, 2;

  -- Unused Not-Null columns with no default
  cursor C_UNUSED_NN_COLUMNS is
    select col.owner, col.table_name, col.column_name, col.data_default
    from  dba_tab_columns col
        , dba_editioning_views ev
    where col.owner in
            ( select oracle_username
              from   ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A','E','B') )
      and col.nullable = 'N'
      and col.table_name not like '%#'
      and (col.default_length is null or col.default_length = 4)
      and ev.owner     = col.owner
      and ev.view_name = substrb(col.table_name, 1, 29)||'#'
      and not exists
             ( select evc.table_column_name
               from  dba_editioning_view_cols evc
               where evc.owner     = ev.owner
                 and evc.view_name = ev.view_name
                 and evc.table_column_name = col.column_name )
    order by col.owner, col.table_name, col.column_name;

begin
  log(c_module, 'PROCEDURE', 'begin: no parameter(s)');

  -- Drop patched indexes
  for idxrec in c_patched_indexes loop
    if idxrec.constraint_name is not null then
      log(c_module, 'STATEMENT', 'Drop patched constraint: '||
            idxrec.table_owner||'.'||idxrec.table_name||'/'||idxrec.constraint_name);
      exec('alter table '||idxrec.table_owner||'."'||idxrec.table_name||'" '||
              'drop constraint "'||idxrec.constraint_name||'" cascade', c_module, true);
    end if;
    log(c_module, 'STATEMENT', 'Drop patched index: '||idxrec.owner||'.'||idxrec.index_name);
    exec('drop index "'||idxrec.owner||'"."'||idxrec.index_name||'"', c_module, true);
  end loop;

  -- Alter unused not-null columns with no default value to be nullable
  for colrec in c_unused_nn_columns loop
    if colrec.data_default is null or upper(colrec.data_default) = 'NULL' then
      log(c_module, 'STATEMENT', 'Alter unused column to be nullable: '||
          colrec.owner||'.'||colrec.table_name || '.' || colrec.column_name );
      exec('alter table "'||colrec.owner||'"."'||colrec.table_name||'"'||
           '  modify ('||colrec.column_name||' null)', c_module, true);
    end if;
  end loop;

  -- Clear patched table list
  delete from ad_patched_tables;
  commit;

  log(c_module, 'PROCEDURE', 'end');
end ABORT;

procedure REVOKE_INVALID_GRANTS (
               X_OBJ_OWNER            in varchar2,
               X_OBJ_NAME             in varchar2,
               X_BASE_OBJ_OWNER       in varchar2 default NULL,
               X_BASE_OBJ_NAME        in varchar2 default NULL,
               X_EXCEPTION_LIST       in varchar2 default NULL)
is
  C_MODULE      varchar2(127) := 'ad.plsql.ad_zd_table.revoke_invalid_grants';
  L_APPS_SCHEMA varchar2(255) := ad_zd.apps_schema;
  STATEMENT     varchar2(10000);
  REVOKE_STMT   varchar2(1000);
  L_EXISTS      varchar2(1);

  cursor REVOKE_GRANTS is
    select vdtp.grantee, vdtp.privilege
    from   dba_tab_privs vdtp                                             /* Privileges on view */
    where  vdtp.owner      = X_OBJ_OWNER                                  /* Owner of view */
    and    vdtp.table_name = X_OBJ_NAME                                   /* View name */
    and    vdtp.grantor    = X_OBJ_OWNER                                  /* Revoke only those granted by owner */
    and    ( X_BASE_OBJ_OWNER is NULL OR
             X_BASE_OBJ_NAME is NULL OR
             privilege NOT IN ( select bdtp.privilege                       /* Grant not given on base */
                              from dba_tab_privs bdtp                     /*  object to view owner */
                              where  bdtp.owner      = X_BASE_OBJ_OWNER   /* Base object owner */
                              and    bdtp.table_name = X_BASE_OBJ_NAME    /* Base object name */
                              and    bdtp.grantee    = X_OBJ_OWNER        /* View owner */
                              and    bdtp.grantable  = 'YES'));            /* Should be grantable to other schemas */

 BEGIN

   IF (X_BASE_OBJ_OWNER is NOT NULL AND
       X_OBJ_OWNER = X_BASE_OBJ_OWNER)
   THEN
     log(c_module, 'WARNING', 'Nothing to do since both object and base object have same owner:'||X_OBJ_OWNER);
     return;
   END IF;

   IF ( (X_BASE_OBJ_OWNER is NULL AND X_BASE_OBJ_NAME is NOT NULL) OR
        (X_BASE_OBJ_OWNER is NOT NULL AND X_BASE_OBJ_NAME is NULL))
   THEN
       log(c_module, 'ERROR', 'Either both base object owner and name should be null or both should be not null');
       RAISE_APPLICATION_ERROR(-20002,'Either both base object owner and name should be null or both should be not null');
   END IF;

   IF (X_BASE_OBJ_OWNER iS NOT NULL)
   THEN
     BEGIN
       select 'X' into l_exists
       from dba_objects
       where owner       = X_BASE_OBJ_OWNER
       and   object_name = X_BASE_OBJ_NAME;
     EXCEPTION
       when no_data_found then
         log(c_module, 'ERROR', 'Base object "'||X_BASE_OBJ_OWNER||'"."'||X_BASE_OBJ_NAME||'" does not exist in database');
         RAISE_APPLICATION_ERROR(-20001,'Base object "'||X_BASE_OBJ_OWNER||'"."'||X_BASE_OBJ_NAME||'" does not exist in database');
     END;
   END IF;

   FOR grants in revoke_grants
   LOOP
     revoke_stmt:='revoke '||grants.privilege||' on "'||X_OBJ_OWNER||'"."'||X_OBJ_NAME||'" from '||grants.grantee;
     log(c_module, 'WARNING', 'Revoking '||grants.privilege||' on '||X_OBJ_OWNER||'.'||X_OBJ_NAME||' from '||grants.grantee);
     if (X_OBJ_OWNER = l_apps_schema)
     then
       EXECUTE IMMEDIATE revoke_stmt;
     else
       statement:='begin '||X_OBJ_OWNER||'.apps_ddl.apps_ddl(:revoke_stmt); end;';
       EXECUTE IMMEDIATE statement using revoke_stmt;
     end if;
   END LOOP;

   commit;
 EXCEPTION
 WHEN OTHERS THEN
   raise ;
end REVOKE_INVALID_GRANTS;

/*
 * Drop an editioned table
 *
 *   TODO: Drop Synonyms pointing to Editioning View
 *   Drop VPD policies on Editioning View
 *   Drop Editioning View
 *   If Running in PATCH edition
 *          Store deferred DDL to drop table in CLEANUP
 *   If running in RUN edition
 *          Drop table immediately
 *
 */
procedure DROP_TABLE (
              X_TABLE_OWNER    in  varchar2,
              X_TABLE_NAME     in  varchar2,
              X_DROP_STMT      in  varchar2,
              X_UPD_STMT       in  varchar2,
              X_DROPPED        out nocopy varchar2 )
is
  C_MODULE      varchar2(80) := 'ad.plsql.ad_zd_table.drop_table';
  L_TABLE_OWNER varchar2(30);
  L_EV_NAME     varchar2(30);
  L_COUNT       varchar2(30);
  L_APPSNAME    varchar2(30);
  L_DEFER_STMT  varchar2(2000);

  cursor C_SYNONYMS(x_table_owner varchar2, x_ev_name varchar2) is
    select syn.owner owner, syn.synonym_name name
    from   dba_synonyms syn
    where  syn.table_owner = x_table_owner
    and    syn.table_name  = x_ev_name
    and    syn.owner         <> 'PUBLIC';

begin
  l_appsname := ad_zd.apps_schema;
  l_table_owner := trim(nvl(x_table_owner, l_appsname));
  log(C_MODULE, 'PROCEDURE', 'begin: '|| l_table_owner ||'.'||x_table_name);

  -- Verify table exists
  select  count(1)
      into   l_count
      from   dba_tables tab
      where  tab.owner      = l_table_owner
      and    tab.table_name = x_table_name;

  if (l_count = 0) then
    -- Table doesn't exist.
    if (x_upd_stmt is not null) then
      exec(x_upd_stmt, c_module, true);
    end if;
    X_DROPPED := 'Y';
  else
    l_ev_name := ad_zd_table.ev_view(x_table_name);

    -- Drop synonyms pointing to EV
    for synrec in c_synonyms(l_table_owner, l_ev_name) loop
      log(c_module, 'STATEMENT', 'Dropping synonym '||synrec.owner||'.'||synrec.name);
      exec ('drop synonym "' || synrec.owner||'"."'||synrec.name||'"', c_module, true);
    end loop;

    -- Drop Edition view
    log(c_module, 'STATEMENT', 'Drop EV '||l_table_owner||'.'||l_ev_name);
    exec('drop view "'||l_table_owner||'"."'||l_ev_name ||'"', c_module, true);

    -- (Deferred) drop table logic
    if ad_zd.get_edition_type = 'RUN' then
      -- Drop table
      log(c_module, 'STATEMENT', 'Drop table '||l_table_owner||'.'||x_table_name);
      begin
        exec(x_drop_stmt, c_module);

        -- Update dropped status
        if (x_upd_stmt is not null) then
          exec(x_upd_stmt, c_module, true);
        end if;

        X_DROPPED := 'Y';

      exception
        when others then
          if (sqlcode <> -942) then
            log(c_module, 'ERROR', 'Error while dropping table '
            ||l_table_owner||'.'||x_table_name || ': ' || substr(sqlerrm, 1, 2000));
            X_DROPPED := 'N';
          else
            -- Update dropped status
            if (x_upd_stmt is not null) then
              exec(x_upd_stmt, c_module, true);
            end if;

            X_DROPPED := 'Y';
          end if;
      end;

    else  -- If running from PATCH edition

      -- Defer drop table to next cleanup
      log (c_module, 'STATEMENT', 'Defer drop table ' ||
           l_table_owner||'.'||x_table_name|| ' to next cleanup');

      if (x_upd_stmt is not null) then
         l_defer_stmt := 'begin execute immediate '''|| regexp_replace(x_drop_stmt, '''', '''''')  || '''; ' ||
                           'execute immediate ''' || regexp_replace(x_upd_stmt, '''', '''''') ||
                         '''; exception when others then null; end;';

        ad_zd.load_ddl('CLEANUP', l_defer_stmt);
      else
        ad_zd.load_ddl('CLEANUP', x_drop_stmt);
      end if;

      -- Return 'N' as the table object is not deleted yet.
      X_DROPPED := 'N';
    end if;
  end if;

  log(c_module, 'PROCEDURE', 'end');
  commit;
end DROP_TABLE;

/*
 ** Obsolete Column
 **
 ** Mark a table column as obsolete. The obsolete column is
 ** immediately removed from the editioning view, and will be
 ** removed from the table during full cleanup.
 **
 ** X_TABLE_OWNER - table owner
 ** X_TABLE_NAME  - table name
 ** X_COLUMN_NAME - logical column name to mark as OBSOLETE
 */

procedure OBSOLETE_COLUMN(
  X_TABLE_OWNER varchar2,
  X_TABLE_NAME varchar2,
  X_COLUMN_NAME varchar2)
is
  C_MODULE            varchar2(127) := 'ad.plsql.ad_zd_table.obsolete_column';
  L_MAX_COL_NAME  varchar2(30);
begin
  select max(column_name) into l_max_col_name
  from   dba_tab_columns
    where  owner = upper(x_table_owner)
    and  table_name = upper(x_table_name)
    and (column_name=upper(x_column_name) or
             column_name like upper(x_column_name)||'#%');

  if (l_max_col_name is not null) then
    exec('comment on column "' ||x_table_owner||'"."' ||x_table_name||
         '"."' || l_max_col_name || '" is ''AD_OBSOLETE''', c_module);

    ad_zd_table.patch(x_table_owner, x_table_name);
  end if;
end OBSOLETE_COLUMN;

end AD_ZD_TABLE;
