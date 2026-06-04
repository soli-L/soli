
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_INST" AUTHID CURRENT_USER as
/* $Header: adinsts.pls 120.0.12020000.3 2021/01/24 19:59:39 mkumandu noship $ */
   --
   -- Package
   --   AD_INST
   -- Purpose
   --   Support for R10.7 and higher server side code.
   -- Notes
   --   1. This package is created in a priviledged account.
   --      It is recommended that this package be created in 'system'
   --   2. The priviledged account requires the following explicit
   --      priviledges to run (i.e. these priviledges cannot be obtained
   --      from a role, like 'dba'):
   --            grant create user to system;
   --            grant select any table to system;
   --            grant create any procedure to system;
   --            grant create any trigger to system;
   --            grant create any view to system;
   --            grant execute any procedure to system;
   --            grant drop any procedure to system;
   --            grant drop any trigger to system;
   --            grant drop any view to system;
   --            grant drop any synonym to system;
   --            grant unlimited tablespace to system with admin option;
   --         These privledges should be granted to system in addbXXX.sql
   --
   -- History
   --   15-NOV-94      B Lind      Created
   --
error_buf varchar2(32760);

procedure compile_schema
           (in_schema in varchar2);
   --
   -- Purpose
   --   Compile all 'invalid' objects in a schema
   -- Arguments
   --   compile_schema      The oracle user name to compile
   -- Example
   --   none
   -- Notes
   --   1. This is used over the DBMS compile_schema procedure because
   --      for performance reasons it is only desirable to recompile
   --      objects that are invalid
   --      2. Any compilation errors are ignored.
   --

procedure do_apps_ddl
           (in_schema in varchar2,
            ddl_text  in varchar2);
  --
  -- Purpose
  --   Execute the SQL statement  in the schema <username>
  --   This is done by creating the following pl/sql block:
  --            begin <username>.apps_ddl.apps_ddl(:<ddl_text>); end;
  -- Arguments
  --   in_schema      The schema in which to run the statement
  --   ddl_text            SQL statement to execute
  -- Example
  --   none
  -- Notes
  --   1. Requires that the APPS_DDL has been created in the target schema
  --
  --
end ad_inst;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_INST" as
/* $Header: adinstb.pls 120.0.12020000.3 2021/01/24 20:02:27 mkumandu noship $ */

  --
  -- PRIVATE VARIABLES
  --

  --
  -- PRIVATE PROCEDURES/FUNCTIONS
  --
  /*
  ** log debug message, jwsmith, sql injection bug 25248691
  ** Debugging routine. You must create the table apps.log_debug_message
  */
  procedure log_debug_message(text in varchar2)
  is
  begin
    --  insert into apps.log_debug_message(message) values(text);
    --  commit;
    null;
  end log_debug_message;


  --
  -- PUBLIC PROCEDURES/FUNCTIONS
  --

procedure compile_schema
           (in_schema in varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  -- compile packages first, then views, then bodies
  -- this is because a view could reference a package header

  cursor c1 is
    select object_name, object_type from sys.dba_objects
    where owner = upper(compile_schema.in_schema)
    and   status = 'INVALID'
    and   object_type = 'PACKAGE';
  cursor c2 is
    select object_name, object_type from sys.dba_objects
    where owner = upper(compile_schema.in_schema)
    and   status = 'INVALID'
    and   object_type = 'VIEW';
  cursor c3 is
    select object_name, object_type from sys.dba_objects
    where owner = upper(compile_schema.in_schema)
    and   status = 'INVALID'
    order by decode(object_type,'PACKAGE',1,'VIEW',2,'PACKAGE BODY',4,3);

begin
-- initialize error buffers
  ad_inst.error_buf := null;
  ad_apps_private.error_buf := null;

-- Check for APPS*DDL packages
  ad_apps_private.check_for_apps_ddl(in_schema);

  -- first compile all invalid packages specifications
  for c1rec in c1 loop
    -- for each invalid object compile
    declare
      statement                  varchar2(100);
      v_object_name              varchar2(30);
    begin

 -- Sql Injection Bug 25248691
      v_object_name := sys.dbms_assert.enquote_name(c1rec.object_name,FALSE);

      statement := 'ALTER PACKAGE '||v_object_name||
                   ' COMPILE SPECIFICATION';

      do_apps_ddl(in_schema, statement);

    exception
      when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
        -- reset error buffer
        ad_inst.error_buf := null;
    end;
  end loop;  -- loop over all invalid packages
  -- next compile all invalid views
  for c2rec in c2 loop
    -- for each invalid object compile
    declare
      v_object_name              varchar2(30);
      statement                  varchar2(100);
    begin

 -- Sql Injection Bug 25248691
      v_object_name := sys.dbms_assert.enquote_name(c2rec.object_name,FALSE);

      statement := 'ALTER VIEW '||v_object_name||' COMPILE';

      do_apps_ddl(in_schema,statement);

    exception
      when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
        -- reset error buffer
        ad_inst.error_buf := null;
    end;
  end loop;  -- loop over all invalid views
  -- last, get all remaining invalid objects, which could be package bodies
  -- unpackaged procedures or functions
  for c3rec in c3 loop
    -- for each invalid object compile
    declare
      statement                  varchar2(100);
      v_object_name              varchar2(30);
    begin

 -- Sql Injection Bug 25248691
      v_object_name := sys.dbms_assert.enquote_name(c3rec.object_name,FALSE);

      if    c3rec.object_type = 'PACKAGE' then
        statement := 'ALTER PACKAGE '|| v_object_name ||
                     ' COMPILE SPECIFICATION';
      elsif c3rec.object_type = 'PACKAGE BODY' then
        statement := 'ALTER PACKAGE '|| v_object_name ||
                     ' COMPILE BODY';
      else
        statement := 'ALTER '|| c3rec.object_type ||' '||
                     v_object_name || ' COMPILE';
      end if;

      do_apps_ddl(in_schema,statement);

    exception
      when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
        -- reset error buffer
        ad_inst.error_buf := null;
    end;
  end loop;  -- loop over all remaining invalid objects

exception
  when others then
    ad_inst.error_buf := 'compile_schema('||in_schema||
            '):'||ad_inst.error_buf||':'||ad_apps_private.error_buf;
    raise;
end compile_schema;


-- Bug25578590 Modified the procedure to call ad_apps_private.validate_definer
-- to verify package has DEFINERS rights and schema is EBS schema.

procedure do_apps_ddl
           (in_schema in varchar2,
            ddl_text  in varchar2)
is
  c              integer;
  rows_processed integer;
  statement      varchar2(500);
  package_name   varchar2(128):='APPS_DDL';

  v_in_schema    varchar2(30);

begin
     -- Sql Injection Bug 25248691
     log_debug_message('Begin procedure do_apps_ddl ');
     v_in_schema := sys.dbms_assert.schema_name(in_schema);

     c := dbms_sql.open_cursor;
     statement:='begin '||
                  ad_apps_private.validate_definer(in_schema,package_name)||
                  '.apps_ddl.apps_ddl(:ddl_text); end;';
     dbms_sql.parse(c, statement, dbms_sql.native);
     dbms_sql.bind_variable(c,'ddl_text',ddl_text);
     rows_processed := dbms_sql.execute(c);
     dbms_sql.close_cursor(c);
     log_debug_message('End procedure do_apps_ddl ');

exception
  when others then
    if (dbms_sql.is_open(c)) then
       dbms_sql.close_cursor(c);
    end if;
    ad_inst.error_buf := 'do_apps_ddl('||in_schema||','||ddl_text||
                         '):'||ad_inst.error_buf;
    raise;
end do_apps_ddl;

end ad_inst;
