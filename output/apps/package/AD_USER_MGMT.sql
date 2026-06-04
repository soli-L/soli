
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_USER_MGMT" AUTHID CURRENT_USER AS
/* $Header: ADUSRMGMTS.pls 120.0.12020000.2 2021/06/09 16:41:29 rsatyava noship $ */

procedure ENABLE_CUSTOM_USER(X_USER in varchar2);

end AD_USER_MGMT;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_USER_MGMT" AS
/* $Header: ADUSRMGMTB.pls 120.0.12020000.5 2023/03/23 11:52:45 rsatyava noship $ */


-- log shortcut
procedure log(x_module    varchar2,
              x_log_type  varchar2,
              x_message   varchar2 ) is
begin
  ad_zd_log.Message( x_module=>x_module, x_log_type => x_log_type, x_message => x_message );
end;


--
--
-- INTERNAL Function to remove hardcoded schema names from the input string
--
-- it looks for pattern matching "<schema name>.<something>" and if found it removes
-- the hard coded schema name from the input string.
--
function REMOVE_SCHEMA_QUALIFIERS(X_DDL in clob) return clob
as
  L_OUT clob;
  L_INDEX number;
  cursor C_EBS_SCHEMA is
    select trim(oracle_username) oracle_username
    from ebs_system.fnd_oracle_userid
    where read_only_flag in ('A','B', 'E', 'U', 'C')
    order by 1;

begin

  l_out := x_ddl;
  for list in c_ebs_schema loop
    -- Get the first index of ["Schema".] or [Schema.], for example: "APPS".UDT or APPS.UDT
    -- in the given DDL.
    l_index := REGEXP_INSTR(l_out,
                            '[[:space:]]+("?' || list.oracle_username || '"?)[.]', 1,1,0, 'i' );

    -- Replace all such occurrences with space ' '
    if(l_index > 0 ) then
     l_out := REGEXP_REPLACE(l_out,
                             '[[:space:]]+("?' || list.oracle_username || '"?)[.]',
                              ' ',
                              l_index, 0, 'i' );
    end if;
  end loop;

  return l_out;
end REMOVE_SCHEMA_QUALIFIERS;



--
-- Enable or disable the dbms_output
procedure server_output(x_status in varchar2)
is
begin
  if(x_status='ENABLE') then
    dbms_output.enable(buffer_size => null);
  else
    dbms_output.disable;
  end if;
end server_output;

-- log_server_output
--   This is being used to capture dbms_output messages coming from
--   ST APIs, like dbms_utility.compile_schema.
procedure log_server_output
  (x_module    in varchar2,
   x_log_type  in varchar2)
is
  l_linesarray dbmsoutput_linesarray;
  l_numlines integer ;
begin

  dbms_output.get_lines (l_linesarray,  l_numlines);
  for i in 1..l_linesarray.count loop
    if(l_linesarray(i) is not null) then
      log(x_module, x_log_type, l_linesarray(i));
    end if;
  end loop;
exception
  when others then
    null;
end log_server_output;


--
-- **********************************************************
-- Utility function to check whether a given type exists or not in a schema?
--
--
function IS_TYPE_EXISTS(X_OWNER varchar2, X_NAME varchar2 ) return boolean
is
 L_OBJ_CNT pls_integer :=0;
begin

   begin
     select 1 into l_obj_cnt
		 from  dba_objects o
		 where o.owner       =x_owner
		 and   o.object_NAME =x_name
		 and   o.object_type ='TYPE';
	 exception
   when others then
        l_obj_cnt:=0;
	 end;

   if(l_obj_cnt > 0 ) then
    return true;
   else
    return false;
   end if;

end IS_TYPE_EXISTS;

--
-- **********************************************************
-- Utility function to check whether a given type BODY exists or not ?
--
--
function IS_TYPE_BODY_EXISTS(X_OWNER varchar2, X_NAME varchar2 ) return boolean
is
 l_obj_cnt pls_integer :=0;
begin

   begin
     select 1 into l_obj_cnt
		 from   dba_objects o
		 where  o.owner        =x_owner
		 and    o.object_NAME  =x_name
		 and    o.object_type  ='TYPE BODY';
	 exception
   when others then
        l_obj_cnt:=0;
	 end;

  if(l_obj_cnt > 0 ) then
    return true;
  else
    return false;
  end if;

end IS_TYPE_BODY_EXISTS;


--
-- execute dynamic SQL statement
--   x_sql     - statement to execute
--   x_log_mod - calling module (for logging)
--   x_ignore  - ignore errors
procedure exec(X_SQL in clob, X_LOG_MOD in varchar2, X_IGNORE in boolean default false)
 IS SUCCESS_WITH_COMPILATION_ERROR exception;
  pragma exception_init(success_with_compilation_error, -24344);

  DEADLOCK_DETECTED_ERROR exception;
  pragma exception_init(deadlock_detected_error, -00060);

  L_CUR integer;
  L_RET integer;
 l_module varchar2(80) := 'ad.plsql.ad_user_mgmt.exec';
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
  -- Ignore DROP TYPE error but log error at STATEMENT level.
  -- -02303: cannot drop or replace a type with type or table dependents
  if(sqlcode= -04043 or sqlcode = -02303) then
    log(l_module, 'STATEMENT', 'ERROR: ->[' || substr(sqlerrm,1,400) || ' ] ');
  elsif(sqlcode = -02306) then
    log(l_module, 'Warning', 'ERROR: ->[' || substr(sqlerrm,1,400) || ' ] ');
    log(l_module, 'STATEMENT', 'Will Create the type using force keyword');
    exec(regexp_replace(x_sql,'(^|\W)'||'AS'||'($|\W)',' FORCE AS ',1,1,'i'),x_log_mod, x_ignore);
  -- Raise "Deadlock detected" error irrespective of x_ignore parameter
  -- Bug 21670164
  elsif(sqlcode= -00060) then
    log(l_module, 'ERROR', 'ERROR: ->[' || substr(sqlerrm,1,400) || ' ] ');
    raise;
  elsif (not x_ignore ) then
    log(l_module, 'ERROR', 'ERROR: ->['|| substr(sqlerrm,1,400)  || ' ] '  );
    raise;
  else
    log(l_module, 'ERROR', 'ERROR: ->['|| substr(sqlerrm,1,400)  || ' ] '  );
  end if;
end exec;


 --
 -- Drops public synonym
 -- and recreate private synonym if not exist.
 --
 procedure FIX_PUBLIC_SYNONYM(
   X_SYNONYM_NAME  in varchar2,
   X_TABLE_OWNER   in varchar2,
   X_TABLE_NAME    in varchar2,
   X_DB_LINK       in VARCHAR2 )
 is
   L_MODULE      varchar2(80) := 'ad.plsql.ad_user_mgmt.fix_public_synonym';
   L_EXIST       pls_integer;
   L_OBJECT_TYPE varchar2(30);

   cursor C_DEPNDENT_USERS is
     select distinct owner
     from  dba_dependencies
     where referenced_owner = 'PUBLIC'
     and   referenced_type  = 'SYNONYM'
     and   referenced_name  = x_synonym_name
     and   owner in ( select oracle_username
                      from  ebs_system.fnd_oracle_userid
                      where read_only_flag in ('A','B', 'E', 'C', 'U'));


 begin
   log(l_module, 'PROCEDURE', 'begin: ' || x_synonym_name||', ' || x_table_owner||', '
                                        || x_table_name || ', '|| x_db_link);

   for l_users in c_depndent_users loop
     begin
       -- Check if private synonym exists?
       select 1 into l_exist
       from  dba_synonyms
       where owner        = l_users.owner
       and   synonym_name = x_synonym_name
       and   table_owner  = x_table_owner
       and   table_name   = x_table_name
       and   ((db_link is null
                 and x_db_link is null
                 )
                OR
                (db_link is not null
                 and x_db_link is not null
                 and db_link =  x_db_link
                )
               ) ;

       log(l_module, 'STATEMENT', 'Synonym with same name: ' ||
                                  l_users.owner  ||'.' || x_synonym_name ||' already exists.');
     exception
       when no_data_found then
         -- check if another object with same <owner, name, object-namespace > exists?
         begin
           select object_type into l_object_type
           from  dba_objects
           where owner       = l_users.owner
           and   object_name = x_synonym_name
           and   namespace in   /* not hard-coding namespace=1 */
                  ( select namespace
                    from   dba_objects
                    where  object_type = 'SYNONYM'
                    and    owner       = 'PUBLIC'
                    and    object_name = x_synonym_name
                   );
           log(l_module, 'ERROR',
                         'Object name conflict: There is an object with same name as '
                         ||l_users.owner||'.'||x_synonym_name||' of type ' || l_object_type ||
                         ' in the same object namespace.');
         exception
           when no_data_found then
              log(l_module, 'EVENT', 'Creating private synonym: ' || l_users.owner  ||'.' || x_synonym_name);
              exec('create or replace synonym "'||
                    l_users.owner  ||'"."' || x_synonym_name || '" for "'||
                    x_table_owner || '"."' || x_table_name ||'"', l_module);
         end;
     end;
   end loop;

   log(l_module, 'EVENT', 'Dropping PUBLIC synonym: ' || x_synonym_name);
   exec('drop public synonym "'|| x_synonym_name ||'"' ,  l_module, true);
   log(l_module, 'PROCEDURE', 'end');

 end FIX_PUBLIC_SYNONYM;


--  Evolved TYPES which are not being used as a COLUMN-TYPE (of a table)
--  needs to be RESET to avoid: "ORA-38820: user has evolved object type"
--  before enabling a user for editions.
--
--  NOTE: Restriction on RESET: cannot specify RESET if the type has any
--        table dependents (direct or indirect).
--
procedure RESET_NOCOLUMN_EVOLVED_TYPES(X_OWNER in varchar2 )
as
   l_module varchar2(80) := 'ad.plsql.ad_user_mgmt.reset_nocolumn_evolved_types';

	cursor l_evolved_types is
     with l_tab(type_owner, type_name)
     as(
        select owner type_owner, type_name
        from dba_type_versions tver
        where tver.typecode in ('OBJECT', 'COLLECTION')
        and tver.version# > 1
        and ((x_owner is not null and  tver.owner = x_owner)
             or
              (x_owner is null
               and tver.owner in (select oracle_username
                                  from ebs_system.fnd_oracle_userid
                                  where read_only_flag in ('A', 'B', 'U', 'E'))
               )
            )
        and not exists (
               select null
               from dba_dependencies d
               where d.type = 'TABLE'
               and   d.referenced_type = 'TYPE'
               and   d.referenced_owner = tver.owner
               and   d.referenced_name  = tver.type_name )
      union all
        select d.referenced_owner type_owner,
               d.referenced_name type_name
        from  dba_dependencies d,
              l_tab
        where d.referenced_type = 'TYPE'
        and   d.name = l_tab.type_name
        and   d.owner = l_tab.type_owner
        and   d.type = 'TYPE'
        and not exists (
               select null
               from dba_dependencies d2
               where d2.type = 'TABLE'
               and   d2.referenced_type = 'TYPE'
               and   d2.referenced_owner = d.referenced_owner
               and   d2.referenced_name  = d.referenced_name )
     )
     cycle type_owner, type_name set cyclemarker to 'Y' default 'N'
     select distinct type_owner, type_name
     from l_tab where cyclemarker = 'N'
     order by 1,2;

begin
  log(l_module, 'PROCEDURE', 'begin');

  for r_type in l_evolved_types loop
    exec('alter type "'||r_type.type_owner||'"."'|| r_type.type_name ||'" reset', l_module, true);
  end loop;

  log(l_module, 'PROCEDURE', 'end');
end RESET_NOCOLUMN_EVOLVED_TYPES;



 --
 -- The procedure works as follows:
 --  Gets the DDL by using dbms_metadata and creates in APPS_NE schema
 --
 --
 procedure COPY_TYPE(X_OWNER       in varchar2,
                     X_NAME        in varchar2,
                     X_NEW_OWNER   in varchar2)
 is
   L_MODULE varchar2(80) := 'ad.plsql.ad_user_mgmt.copy_type';
   DM_H          number;
   DM_T          number;
   L_DDL         clob;
   L_EXIST       pls_integer;
 begin

   log(l_module, 'PROCEDURE', 'begin: '||x_owner||'.'||x_name ||', '|| x_new_owner);

   begin
     select 1 into l_exist
     from  dba_types
     where owner     = x_owner
     and   type_name = x_name;
   exception
     when no_data_found then
       log(l_module, 'STATEMENT', 'Type: '||x_owner||'.'||x_name || ' does not exist - noop');
       return;
   end;

   dm_h := dbms_metadata.open('TYPE');
   dbms_metadata.set_filter(dm_h, 'SCHEMA', X_OWNER);
   dbms_metadata.set_filter(dm_h, 'NAME', X_NAME);
   dbms_metadata.set_filter(dm_h, 'SPECIFICATION', true);
   dbms_metadata.set_filter(dm_h, 'BODY', false);
   dm_t  := dbms_metadata.add_transform(dm_h, 'MODIFY');
   dbms_metadata.set_remap_param(dm_t, 'REMAP_SCHEMA', X_OWNER, X_NEW_OWNER);
   dm_t  := dbms_metadata.add_transform(dm_h, 'DDL');
   dbms_metadata.set_transform_param(dm_t, 'SQLTERMINATOR', false);

   l_ddl := dbms_metadata.fetch_clob(dm_h);
   -- replace occurrence of ";" ALTER with ALTER, ST bug 17801303
   l_ddl := regexp_replace(l_ddl,';.[[:space:]]*.ALTER', ' ALTER', 1, 0, 'in' );

   dbms_metadata.close(dm_h);

   if (l_ddl is not null ) then
     l_ddl := remove_schema_qualifiers(l_ddl );
     if(is_type_exists(x_new_owner, x_name) = false ) then
       log(l_module, 'EVENT', 'Creating TYPE: '||x_new_owner||'.'||x_name);
       exec(x_sql => l_ddl, x_log_mod => l_module, x_ignore=>true);
     end if;
   else
     log(l_module, 'ERROR', 'dbms_metadata returned null for User-Defined-Type Specification: '||x_owner||'.'||x_name );
     -- Shall we raise an error from here?
     raise_application_error(-20996,
        'dbms_metadata returned null for User-Defined-Type Specification: ' ||x_owner||'.'||x_name);
   end if;
   if(dbms_lob.istemporary(l_ddl) =1 ) then
     dbms_lob.freetemporary(l_ddl);
   end if;

   -- STEP#2 Follow same steps for OBJECT Body
   dm_h := dbms_metadata.open('TYPE');
   dbms_metadata.set_filter(dm_h, 'SCHEMA', X_OWNER);
   dbms_metadata.set_filter(dm_h, 'NAME', X_NAME);
   dbms_metadata.set_filter(dm_h, 'SPECIFICATION', FALSE);
   dbms_metadata.set_filter(dm_h, 'BODY', TRUE);

   dm_t  := dbms_metadata.add_transform(dm_h, 'MODIFY');
   dbms_metadata.set_remap_param(dm_t, 'REMAP_SCHEMA', X_OWNER, X_NEW_OWNER);
   dm_t  := dbms_metadata.add_transform(dm_h, 'DDL');
   dbms_metadata.set_transform_param(dm_t, 'SQLTERMINATOR', false);
   l_ddl := dbms_metadata.fetch_clob(dm_h);
   -- replace occurrence of ";" ALTER with ALTER, ST bug 17801303
   l_ddl := regexp_replace(l_ddl,';.[[:space:]]*.ALTER', ' ALTER', 1, 0, 'in' );
   dbms_metadata.close(dm_h);

   if (l_ddl is not null ) then
     l_ddl := remove_schema_qualifiers(l_ddl);
     if(is_type_body_exists(x_new_owner, x_name) = false ) then
       log(l_module, 'EVENT', 'Creating TYPE BODY: '||x_new_owner||'.'||x_name);
       exec(x_sql => l_ddl, x_log_mod => l_module, x_ignore=>true);
     end if;
   else
    log(l_module, 'STATEMENT', 'dbms_metadata returned null for User-Defined-Type Body: '||x_owner||'.'||x_name );
   end if;

   if(dbms_lob.istemporary(l_ddl) =1 ) then
     dbms_lob.freetemporary(l_ddl);
   end if;

   -- Grant execute priviledge to
   exec(x_sql => 'GRANT EXECUTE ON "'||x_new_owner||'"."'||x_name||'" to PUBLIC', x_log_mod => l_module,  x_ignore=>true);
   log(l_module, 'PROCEDURE', 'end');
 end COPY_TYPE;

-- Convert Editioned Type to equivalent Non-Editioned Type synonym
 --   Update table references to NE type if needed
 --   Convert dependant types, if needed
 --   Drop type, replace with synonym to NE type
procedure FIX_TYPE(X_TYPE_OWNER varchar2, X_TYPE_NAME varchar2)
 is
  L_MODULE     varchar2(80) := 'ad.plsql.ad_user_mgmt.fix_type';
  L_REF_OWNER  varchar2(30);
  L_REF_NAME   varchar2(30);
  L_FOUND      boolean;
	L_UPDT_TYPES_STMT VARCHAR2(1000);

  -- tables that reference the specified type
  cursor C_TABLE_REFS(TYPE_OWNER varchar2, TYPE_NAME varchar2) is
    select dep.owner, dep.name
    from   dba_dependencies dep
    where  dep.type            = 'TABLE'
    and    dep.referenced_owner= type_owner
    and    dep.referenced_name = type_name
    and    dep.referenced_type = 'TYPE';

  -- types that reference the specified type and have a replacement in APPS_NE
  cursor C_TYPE_REFS(XX_TYPE_OWNER varchar2, XX_TYPE_NAME varchar2) is
    select ot.owner, ot.name
    from   dba_dependencies ot,
           dba_types nt
    where  ot.type            = 'TYPE'
    and    ot.referenced_owner= xx_type_owner
    and    ot.referenced_name = xx_type_name
    and    ot.referenced_type = 'TYPE'
    and    nt.owner     = 'APPS_NE'
    and    nt.type_name = ot.name;

  -- tables that references the specific type or its dependent type
  cursor C_TABLE_REFS2(TYPE_OWNER varchar2, TYPE_NAME varchar2) is
    select dep.owner, dep.name
    from  dba_dependencies dep
    where dep.type  = 'TABLE'
    and   dep.referenced_owner <> 'APPS_NE'
    start with
          dep.referenced_owner = type_owner
      and dep.referenced_name  = type_name
      and dep.referenced_type  = 'TYPE'
    connect by nocycle
          prior dep.owner = dep.referenced_owner
      and prior dep.name  = dep.referenced_name
      and prior dep.type  = dep.referenced_type;

 begin

   log(l_module, 'PROCEDURE', 'begin: '||x_type_owner||'.'||x_type_name);

   -- check for table references to type
   open c_table_refs(x_type_owner, x_type_name);
   fetch c_table_refs into l_ref_owner, l_ref_name;
   l_found := c_table_refs%found;
   close c_table_refs;

   -- fix table references if any
   if l_found then
     -- update column types to new owner
     -- Note: "check_update" paremeter must be false for single type update
     log(l_module, 'EVENT', 'Fixing table references to '||x_type_owner||'.'||x_type_name);
     server_output('ENABLE');

		 --Making this call dynamic to avoid compile time issues with ADB

		 l_updt_types_stmt := 'begin
													   sys.dbms_objects_apps_utils.update_types
														 ( schema1      => :x_type_owner,
															 schema2      => ''APPS_NE'',
															 typename     => :x_type_name,
															 check_update => false ) ;
													end; ';
		 execute immediate l_updt_types_stmt using x_type_owner,x_type_name;

     log_server_output('sys.dbms_objects_apps_utils.update_types', 'STATEMENT');
     execute immediate 'alter system flush shared_pool';
     commit;

     -- re-check for table references to type
     open c_table_refs(x_type_owner, x_type_name);
     fetch c_table_refs into l_ref_owner, l_ref_name;
     l_found := c_table_refs%found;
     close c_table_refs;

     -- if there are still references to the type, then we have failed
     if l_found then
       log(l_module, 'ERROR', 'Could not fix table references to '||x_type_owner||'.'||x_type_name);
       raise_application_error(-20978, 'Could not fix table references to '||x_type_owner||'.'||x_type_name);
     end if;
   end if;

   -- recursively drop any types that depend on this type and have NE replacements
   for l_types in c_type_refs(x_type_owner, x_type_name) loop
     log(l_module, 'STATEMENT', 'Fixing type reference: ' || l_types.owner||'.'||l_types.name);
     fix_type(l_types.owner, l_types.name);
   end loop;

   -- verify type still exists (could be missing now due to concurrent threads)
   if is_type_exists(x_type_owner, x_type_name) then

      -- Make sure no table references to type or its dependent types
      open c_table_refs2(x_type_owner, x_type_name);
      fetch c_table_refs2 into l_ref_owner, l_ref_name;
      l_found := c_table_refs2%found;
      close c_table_refs2;

      -- if there are still references to the type or its dependent types, then we have failed
      if l_found then
        log(l_module, 'ERROR', 'Could not fix table references to '||x_type_owner||'.'||x_type_name);
        raise_application_error(-20978, 'Could not fix table references to '||x_type_owner||'.'||x_type_name);
      end if;

     -- drop the type, replace with synonym
		 -- Via AD Bug#32836605, apps has been given the privilege to drop any type system privilege
		 log(l_module, 'EVENT', 'Converting Type to Synonym: '||x_type_owner||'.'||x_type_name);
		 exec('drop type "'||x_type_owner||'"."'||x_type_name||'" force', l_module, true);
		 exec('create or replace synonym "'||x_type_owner||'"."'||x_type_name||'" for '
          ||'"APPS_NE"."'||x_type_name||'"', l_module, true);
   end if;

   log(l_module, 'PROCEDURE', 'end');
end FIX_TYPE;

--
-- This is used to fix EBR violations for custom users
--
procedure FIX_CUSTOM_OBJECTS(x_user varchar2)
is
  L_MODULE varchar2(80) :=  'ad.plsql.ad_user_mgmt.fix_custom_objects';
	L_XML_SCHEMA_PROC_BLOCK VARCHAR2(32767);

  -- Objects which would become INVALID when specified user is enabled for
  -- editions.
  cursor C_INVALIDATED_OBJECTS(P_USER varchar2) is
   select    dep.owner              d_owner
						, dep.name              d_name
            , dep.type              d_type
            , dep.referenced_owner  p_owner
            , dep.referenced_name   p_name
            , dep.referenced_type   p_type
   from     dba_dependencies dep
	  -- Only Non-Editionable objects, 55:XML SCHEMA-> is a Non-Editioned object
   where   (dep.type not in ('TYPE','SYNONYM','PACKAGE','VIEW','TYPE BODY',
	                           'PACKAGE BODY','FUNCTION','PROCEDURE','TRIGGER')
            or (dep.type = 'SYNONYM' AND dep.OWNER = 'PUBLIC'))
   and     (dep.referenced_owner, dep.referenced_name) not in (('SYS', 'STANDARD'))
   start with
       dep.referenced_owner   = p_user
	 and dep.referenced_type in ('TYPE','SYNONYM','PACKAGE','VIEW','TYPE BODY',
			                         'PACKAGE BODY','FUNCTION','PROCEDURE','TRIGGER')
   connect by
            prior     dep.referenced_owner = dep.owner
            and prior dep.referenced_name  = dep.name
            and prior dep.referenced_type  = dep.type;



  cursor C_COLUMNS is
    select
        tab.owner            table_owner
      , tab.table_name       table_name
      , col.column_name      column_name
      , col.data_type        type_name
      , col.data_type_owner  type_owner
    from
        dba_tables      tab
      , dba_tab_columns col
    where tab.owner = x_user
      and col.owner = tab.owner
      and col.table_name = tab.table_name
      and col.data_type_owner in   -- User defined data type (UDT)
          ( select oracle_username
            from   ebs_system.fnd_oracle_userid
            where  read_only_flag in ('A','B', 'E', 'U', 'C')
          )
    order by 1, 2, 3;

  -- Fix public synonyms
  cursor C_PUBLIC_SYNONYMS is
    select syn.synonym_name ,
           syn.table_owner  ,
           syn.table_name   ,
           syn.db_link
    from  dba_synonyms syn
    where syn.owner='PUBLIC'
    and   syn.table_owner = x_user
    and   (syn.table_owner, syn.table_name) in
            (select obj.owner, obj.object_name
             from   dba_objects obj
             where  obj.owner = syn.table_owner   -- To avoid GSCC error
             and    obj.object_type in ('TYPE',   'PACKAGE', 'VIEW' ,
                                        'SYNONYM','PROCEDURE',
                                        'TRIGGER','FUNCTION'));
  -- MVs
  cursor C_MVS is
    select m.owner owner,
           m.mview_name name
    from   dba_mviews m
    where m.owner =x_user
      and not exists
            ( select 'X'
              from dba_views v
              where v.owner = m.owner
              and   v.view_name = ad_zd_mview.get_mvq_name(m.mview_name) )
    union
    select v.owner owner,
           ad_zd_mview.get_mv_name(v.view_name) name
    from   dba_views v
    where v.view_name like '%'||'#'
      and v.editioning_view = 'N'
      and v.owner =x_user
      and not exists
            ( select 'X' from dba_objects m
              where m.owner      = v.owner
                and m.object_name = ad_zd_mview.get_mv_name(v.view_name)
                and m.object_type = 'MATERIALIZED VIEW'
                and m.status      = 'VALID' );


begin
  log(l_module, 'PROCEDURE', 'begin: '|| x_user );

  reset_nocolumn_evolved_types(x_user);

  for l_invalidated_object in c_invalidated_objects(x_user) loop
    log(l_module, 'STATEMENT', 'Non-Editionable Object ('|| l_invalidated_object.d_name ||
                               ',' || l_invalidated_object.d_type || '), dependent on (' ||
                               l_invalidated_object.p_name || ',' || l_invalidated_object.p_type || ')');
    case
      --CASE#1: Table is dependent on TYPE
      --        This condition is also true when table is dependet on a TYPE descended
      --        from an XML schema
      when (l_invalidated_object.d_type = 'TABLE' and
            l_invalidated_object.p_type = 'TYPE') then

        -- Fix each UDT column
        for l_tab_column in c_columns loop
          log(l_module, 'STATEMENT', 'Fix Table: which is dependent on ' ||
                                     l_tab_column.type_owner || '.' ||
                                     l_tab_column.type_name );

          copy_type(l_tab_column.type_owner, l_tab_column.type_name, 'APPS_NE');
          fix_type(l_tab_column.type_owner, l_tab_column.type_name);
        end loop;

        --(SSTOMAR)
        -- TODO: Fix the tables created directly by using a UDT.
        --       such tables will not show up in dba_tab_columns
        --       e.g. > create table sh_table of sh_type;

      --CASE#2: XML Schema dependency
      --       (and TYPES descended from XML schema will also be covered)
      when (l_invalidated_object.d_type = 'XML SCHEMA' and
            l_invalidated_object.p_type = 'TYPE') then

        log(l_module, 'STATEMENT', 'Fix XML schema: ');

        -- This is fine to run XML schema mover for all users as it will pick-up those
        -- users which are registered in fnd_oracle_userid (Only cost here is performance)
        -- TODO: Wait for DB fix 16286729, otherwise locking issue might occur.

        --Moved move_xml_schemas to ad_zd_sys package in ebs_system
        begin
				   ebs_system.ad_zd_sys.move_xml_schemas;
				exception
           when others then
        			raise_application_error(-20005,'Error during move_xml_schemas '||sqlerrm);
           end;

      -- CASE#3: MV is dependent on function, throw error as this can be fixed automatically.
      when (l_invalidated_object.d_type = 'MATERIALIZED VIEW' and
            l_invalidated_object.p_type = 'FUNCTION') then
        -- throw error
        log(l_module, 'ERROR', 'MV:' || l_invalidated_object.d_name ||
                               ',  dependent on: ' || l_invalidated_object.p_name);
        raise_application_error(-20005, 'Materialized view(s) which is/are dependent on a function, ' ||
                                        'can not be fixed automatically. Run Readiness Report from Note 1531121.1 ' ||
                                        'and fix them manually.');

      -- CASE#4: MV is dependent any other type of object i.e. other than a function.
      when (l_invalidated_object.d_type = 'MATERIALIZED VIEW' and
            l_invalidated_object.p_type <> 'FUNCTION' ) then

        -- Expand MVs
        -- TODO: This ideally should be done after upgrading Tables of this user
        for l_mv in C_MVS loop
          log(l_module, 'STATEMENT', 'Fix MV: ' || l_mv.owner || '.' || l_mv.name);
					begin
            ad_zd_mview.upgrade(l_mv.owner, l_mv.name);
					exception
					  when others then
						  raise_application_error(-20005,'Error during mv upgrade'||sqlerrm);
					end;
        end loop;
			else
        	 log(l_module, 'ERROR', 'In else block' || l_invalidated_object.d_name ||
                               ',  dependent on: ' || l_invalidated_object.p_name);
    end case;
  end loop;

  -- Fix public synonyms.
  -- NOTE: Public synonyms will NOT have any record in sys.dependencies$ table
  for l_rec in c_public_synonyms loop
    log(l_module, 'STATEMENT', 'Fix PUBLIC synonym: ' || l_rec.synonym_name);
    fix_public_synonym(l_rec.synonym_name, l_rec.table_owner, l_rec.table_name, l_rec.db_link);
  end loop;

  -- If still have noneditioned objects dependent on editioned objects?
  for l_invalidated_object in c_invalidated_objects(x_user) loop
     log(l_module, 'ERROR', 'ORA-20005: One or more noneditioned objects dependent on objects whose type is editionable.' ||
                            'Run and review Readiness Report: Note 1531121.1 and then fix noneditioned objects' );
     raise_application_error(-20005, 'One or more noneditioned objects dependent on objects whose type is editionable.' ||
                                     'Run and review Readiness Report: Note 1531121.1 and then fix noneditioned objects' );
  end loop;

  log(l_module, 'PROCEDURE', 'end');
end FIX_CUSTOM_OBJECTS;



--
-- Enables a custom schema for editions.
--  - If schema is not registered with E-biz, it will register it.
--  - Fixes custom objects owned by custom schema
--  - Upgrade tables for EV, owned by custom schema
--
procedure ENABLE_CUSTOM_USER(X_USER varchar2)
is
  L_MODULE                varchar2(80) :=  'ad.plsql.ad_user_mgmt.enable_custom_user';
  L_ENABLE_EDITIONS_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(l_enable_editions_error, -38819);
  L_STMT                  varchar2(250);
  L_EXISTS                number :=0;
  L_APPS_SCHEMA           varchar2(30) := ad_zd.apps_schema;

  cursor C_TABLES is
    select
        tab.owner        table_owner
      , tab.table_name   table_name
    from  dba_tables tab
    where tab.owner = x_user
      and tab.temporary = 'N'
      and tab.secondary = 'N'
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
      order by tab.owner, tab.table_name;

begin

  log(l_module, 'PROCEDURE', 'begin: '|| x_user || ' user enabling for editions');

  -- As the password is being set as INVALID not calling
  -- Register (Bug 16492268).
  -- register_custom_user(x_user);
  begin
     select 1 into l_exists from dual
     where
     ( upper(x_user) ='APPS_NE'
      or
      exists
				 ( select r.schema
	         from   sys.dba_registry r, sys.dba_users u
	         where  r.status    in ('VALID','LOADED','UPGRADED')
	         and    r.namespace ='SERVER'
	         and    r.control   =u.username
					 and    u.username  = upper(x_user)
					 union
					 SELECT
								 trim(COLUMN_VALUE) schema
					 FROM (select other_schemas schema
								 from   sys.dba_registry r, sys.dba_users u
								 where  r.status   in ('VALID','LOADED','UPGRADED')
								 and    r.namespace ='SERVER'
								 and    r.control   =u.username
								 and    u.username  = upper(x_user))schema_list,
							   xmltable(('"'
												|| replace(schema, ',', '","')
												|| '"')))
			   );
    exception
    when others then
			log(l_module, 'STATEMENT', 'Schema ' ||  x_user || ' does not exist in registered schemas '||sqlerrm);
			l_exists :=0;
  end;

   if ( l_exists > 0) then
     log(l_module, 'ERROR', 'Schema' ||  x_user || 'is Non Editionable');
     raise_application_error(-20006, 'Can not enable user for editions. ' || sqlerrm);
   end if;

  begin
	  log(l_module, 'STATEMENT', 'Enable '|| x_user || ' user for editions');
	  ebs_system.ad_zd_sys.enable_editions(x_user);
  exception
    when l_enable_editions_error then
		   log(l_module, 'ERROR', 'User '|| x_user || 'has objects which violate Edition-Based-Redefinition rules');
 			 if ad_db_utils.is_adb = 'N' then
			    fix_custom_objects(x_user);
					-- retry without force mode
					begin
						log(l_module, 'STATEMENT', 'Retry: Enable '|| x_user || ' user for editions');
						ebs_system.ad_zd_sys.enable_editions(x_user);
						log(l_module, 'STATEMENT', 'User '|| x_user || ' has been enabled for editions');
					exception
						when l_enable_editions_error then
							log(l_module, 'ERROR', 'User '|| x_user || 'Can not enable user for editions. ' || sqlerrm);
							raise_application_error(-20006, 'Can not enable user for editions. ' || sqlerrm);
					end;
		   else
			   --ST bug#32203372-REPLACEMENT FOR SYS.DBMS_OBJECTS_APPS_UTILS.UPDATE_TYPES
				 --As there is no replacement available for SYS.DBMS_OBJECTS_APPS_UTILS.UPDATE_TYPES api in ADB
		     log(l_module, 'ERROR', 'User '|| x_user || 'Can not enable user for editions in ADB environment');
			   raise_application_error(-20006, 'Can not enable user for editions. ' || sqlerrm);
		   end if;

  end;

  --Enh 33947773 - AD TO HANDLE NEW SCHEMA LEVEL PRIVILEGE IMPROVEMENT IN DB 23C
  --Grant Schema Privileges to APPS user on the custom schema
    $IF (DBMS_DB_VERSION.VERSION >= 23) $THEN
      ebs_system.ad_zd_sys.grant_schema_privs(l_apps_schema,x_user,'ADMIN') ;
    $END

  log(l_module, 'STATEMENT', 'Upgrade custom tables owned by: '|| x_user || ' user');
  for l_rec in c_tables loop
    ad_zd_table.upgrade(l_rec.table_owner, l_rec.table_name);
  end loop;

  commit;
  log(l_module, 'STATEMENT', 'end');

end ENABLE_CUSTOM_USER;


end AD_USER_MGMT;
