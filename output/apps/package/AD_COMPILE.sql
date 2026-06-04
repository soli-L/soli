
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_COMPILE" AUTHID CURRENT_USER as
/* $Header: adcmps.pls 120.0.12020000.3 2021/01/24 20:01:40 mkumandu noship $ */

  procedure compile_apps_ddl;

end ad_compile;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_COMPILE" as
/* $Header: adcmpb.pls 120.0.12020000.3 2021/01/24 19:57:52 mkumandu noship $ */

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
-- PL/SQL procedure to find and recompile all invalid APPS_DDL and
--   APPS_ARRAY_DDL packages in the database
--

procedure compile_apps_ddl is
  cursor c1 is
  select owner, object_type, object_name
  from sys.dba_objects
  where object_type in ('PACKAGE', 'PACKAGE BODY')
  and object_name in ('APPS_DDL', 'APPS_ARRAY_DDL')
  and status = 'INVALID'
  order by object_type, object_name desc;

  success_with_comp_error     exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);

  c			integer;
  rows_processed	integer;
  statement		varchar2(500);
  error_buf             varchar2(31744);
begin
  log_debug_message('Begin procedure compile_apps_ddl ');
  for c1rec in c1 loop

   -- build statement

   if    c1rec.object_type = 'PACKAGE' then

    -- Sql Injection Bug 25248691
     statement := 'alter package '|| sys.dbms_assert.enquote_name(c1rec.owner,FALSE)||
'.'||sys.dbms_assert.enquote_name(c1rec.object_name,FALSE)||
       ' compile specification';

   elsif c1rec.object_type = 'PACKAGE BODY' then

     statement := 'alter package '||sys.dbms_assert.enquote_name(c1rec.owner,FALSE)||'.'||sys.dbms_assert.enquote_name(c1rec.object_name,FALSE)||
       ' compile body';

   else

     statement := 'Why does '||c1rec.object_type||' '||c1rec.owner||'.'||
       c1rec.object_name||' fail?';


   end if;

--
-- Execute compile command in a sub-block so we can trap and handle errors
--
    begin
      c := dbms_sql.open_cursor;

      dbms_sql.parse(c, statement, dbms_sql.native);
      rows_processed := dbms_sql.execute(c);
      dbms_sql.close_cursor(c);

    exception
      when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
        dbms_sql.close_cursor(c);
      when others then
        dbms_sql.close_cursor(c);
        raise_application_error(-20000, SQLERRM || ' [Statement is: '||
          statement||']');
    end;

  end loop;

--
-- We should not have any invalid packages left
-- Look for them again, and fail if we find any
--

  error_buf := null;

  for c1rec in c1 loop

    error_buf := error_buf || ' "' || c1rec.object_type ||' '||
      c1rec.owner||'.'||c1rec.object_name||'"';

  end loop;

  if error_buf is not null then
    raise_application_error(-20000,
      'Please manually fix the following invalid packages:' || error_buf);
  end if;

  log_debug_message('End procedure compile_apps_ddl ');
end compile_apps_ddl;

end ad_compile;
