
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_MLS" AUTHID CURRENT_USER as
/* $Header: admlss.pls 120.0.12020000.3 2021/01/24 20:01:20 mkumandu noship $ */
   --
   -- Package
   --   AD_MLS
   -- Purpose
   --   Support for R10 multi-lingual view based solution.
   -- Notes
   --   1. This package is created in a priviledged account.
   --      It is recommended that this package be created in 'system'
   --   2. The priviledged account requires the following explicit
   --      priviledges to run (i.e. these priviledges cannot be obtained
   --      from a role, like 'dba'):
   --      grant create user to system;
   --      grant select any table to system;
   --      grant create any procedure to system;
   --      grant create any trigger to system;
   --      grant create any view to system;
   --      grant execute any procedure to system;
   --      grant drop any procedure to system;
   --      grant drop any trigger to system;
   --      grant drop any view to system;
   --      grant drop any synonym to system;
   --      grant unlimited tablespace to system with admin option;
   --      These privledges should be granted to system in addbXXX.sql.
   --
   -- History
   --   15-NOV-94   B Lind   Created
   --   10-APR-97       nvijayap  Split adorgs.pls into two
   --                             - admlss.pls, adaprs.pls -
   --                             - this is admlss.pls
   --

-- Bug 3611969 : FIXED FILE.SQL.35 GSCC WARNINGS
-- sraghuve (07/05/2004)

procedure create_mls_schema
           (aol_schema   in varchar2);

procedure create_mls_schema
           (aol_schema   in varchar2,
            invoker_mode in varchar2);
   --
   -- Procedure
   --   create_mls_schema
   -- Purpose
   --   Build/Create the 'mls appsuser' account.
   -- Arguments
   --   apps_schema   The oracle username for the apps account
   --   invoker_mode    Running in Invoker's Rights mode? 'TRUE' or 'FALSE'
   -- Example
   --   none
   -- Notes
   --   1. None
   --

procedure build_lang_decode
           (aol_schema in varchar2);
   --
   -- Purpose
   --   Build decode on language to attributex
   --   The format of the output is:
   --      decode(substr(userenv('LANGUAGE'),1,instr(userenv('LANGUAGE'),
   --      '_')-1),lang1,attributex,lang2,attributey,...
   --   Each output is of the same form, but maps different columns to the
   --   languages
   -- Arguments
   --   aoluser      The applsys oracle user name
   -- Example
   --   none
   -- Notes

procedure build_mls_column_list
           (table_name       in  varchar2,
            table_owner      in  varchar2,
            aol_schema       in  varchar2,
            view_column_list out nocopy varchar2,
            select_list      out nocopy varchar2);
   --
   -- Purpose
   --   Build the column lists:
   --     one for the view columns
   --     two for the select statement for the view
   -- Arguments
   --   mls_decode_1    output from build_lang_decode
   --   mls_decode_2    output from build_lang_decode
   --   table_name   Table for which the view is being created
   --   aoluser      Schema in which table ak_partitioned_tables exists
   -- Example
   --   none
   -- Notes
   --   1. none
   --


end ad_mls;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_MLS" as
/* $Header: admlsb.pls 120.0.12020000.3 2021/01/24 20:03:11 mkumandu noship $ */

mls_decode_1 varchar2(2000);
mls_decode_2 varchar2(2000);

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

procedure do_create_mls_schema
           (install_group_num in number,
            aol_schema        in varchar2,
            apps_schema       in varchar2,
            apps_mls_schema   in varchar2,
            invoker_mode      in varchar2);
   --
   -- Purpose
   --   The procedure does the work of creating an mls apps account.
   -- Arguments
   --   aol_schema   AOL Schema
   --   apps_schema    APPS schema to base this mls apps schema on
   -- Example
   --   none
   -- Notes
   --   1. none
   --


-- Bug 3611969 : FIXED FILE.SQL.35 GSCC WARNINGS
-- sraghuve (07/05/2004)


procedure create_mls_schema
           (aol_schema   in varchar2)

is
begin

  create_mls_schema
           (aol_schema   => aol_schema,
            invoker_mode => 'FALSE');

end;


procedure create_mls_schema (aol_schema in varchar2,
                             invoker_mode in varchar2)

is
  apps_schema		varchar2(30);
  apps_schema_mls	varchar2(30);
  v_aol_schema          varchar2(30);

begin

-- Sql Injection Bug 25248691
  log_debug_message('Begin procedure create_mls_schema ');
  v_aol_schema := sys.dbms_assert.schema_name(aol_schema);

  ad_apps_private.error_buf := null;  -- reset error buffer

  if ad_apps_private.is_mls is null then
    ad_apps_private.initialize(aol_schema);
  end if;

  if ad_apps_private.is_mls = TRUE then

  declare
    c         integer;
    rows_processed   integer;
    install_group_num   number;
    statement      varchar2(500);
  begin
    -- check existence of aol_schema account
    if not ad_apps_private.check_if_schema_exists(aol_schema) then
      raise_application_error(-20000,'The schema '||upper(aol_schema)||
          ' does not exist.');
    end if;

    c := dbms_sql.open_cursor;

-- Sql Injection Bug 25248691

    v_aol_schema := sys.dbms_assert.enquote_name(aol_schema,FALSE);

    statement := 'select install_group_num from '||upper(v_aol_schema)||
                 '.fnd_oracle_userid where read_only_flag = ''U'''||
                 ' order by install_group_num' ;

    dbms_sql.parse(c, statement, dbms_sql.native);
    dbms_sql.define_column(c,1,install_group_num);
    rows_processed := dbms_sql.execute(c);
    -- loop through all install groups and create the multiple APPS_MLS
    -- schemas as necessary
    loop
      if dbms_sql.fetch_rows(c) > 0 then
        dbms_sql.column_value(c,1,install_group_num);

   -- Process the install group

        -- get the APPS account name ( apps[<IGN>][_<aol_schema>] )
        ad_apps_private.get_apps_schema_name(install_group_num, aol_schema,
            apps_schema, apps_schema_mls);

        -- create the MLS APPS schema
        do_create_mls_schema(install_group_num, aol_schema,
         apps_schema, apps_schema_mls, invoker_mode);

      else
        -- no more product groups to process
        dbms_sql.close_cursor(c);
        exit;
      end if;
    end loop;  -- loop over all product groups
  exception
    when others then
      dbms_sql.close_cursor(c);
      ad_apps_private.error_buf := 'statement='||
                                   statement||':'||
                                   ad_apps_private.error_buf;
      raise;
  end;

  end if;

  log_debug_message('End procedure create_mls_schema ');

exception
  when others then
    ad_apps_private.error_buf := 'create_mls_schema('||aol_schema||
      ', '||invoker_mode||'):'||
   ad_apps_private.error_buf;
    raise;

end create_mls_schema;


procedure build_lang_decode
           (aol_schema in varchar2)
is
  c         integer;
  rows_processed   integer;
  statement      varchar2(500);
  language_name      varchar2(30);
  attribute_column_name varchar2(30);
  lset_number		number;
  ldecode_1		varchar2(2000);
  ldecode_2		varchar2(2000);
  v_aol_schema          varchar2(30);


begin

-- Sql Injection Bug 25248691
  log_debug_message('Begin procedure build_lang_decode ');
  v_aol_schema := sys.dbms_assert.schema_name(aol_schema);

  -- only do the work if it hasn't been done before
  if ad_mls.mls_decode_1 is null then

    c := dbms_sql.open_cursor;


  -- Bug 3611969 : FIXED FILE.SQL.35 GSCC WARNINGS
  -- sraghuve (07/05/2004)

    ldecode_1 :=  'nvl(decode(substr(userenv
		(''LANGUAGE''),1,instr(userenv
		(''LANGUAGE''),''_'')-1),';

    ldecode_2 :=  'nvl(decode(substr(userenv
		(''LANGUAGE''),1,instr(userenv
		(''LANGUAGE''),''_'')-1),';

    -- Only select languages that are not the base language
    -- Since the base language will be in the original column

-- Sql Injection Bug 25248691

   v_aol_schema := sys.dbms_assert.enquote_name(aol_schema,FALSE);

    statement := 'select language, attribute_column_name,    '||
       'translated_column_number from       '||
       v_aol_schema||
       '.ak_language_attribute_xrefs   '||
       'where language not in (select nls_language   '||
       'from '||v_aol_schema||
       '.fnd_languages      '||
       'where installed_flag = ''B'')         ';
    dbms_sql.parse(c, statement, dbms_sql.native);
    dbms_sql.define_column(c,1,language_name,30);
    dbms_sql.define_column(c,2,attribute_column_name,30);
    dbms_sql.define_column(c,3,lset_number);
    rows_processed := dbms_sql.execute(c);

    loop
      if dbms_sql.fetch_rows(c) > 0 then
        dbms_sql.column_value(c,1,language_name);
        dbms_sql.column_value(c,2,attribute_column_name);
        dbms_sql.column_value(c,3,lset_number);
        if lset_number = 1 then
     ldecode_1 := ldecode_1 || '''' || language_name ||
      ''', "' || attribute_column_name || '", ';
        else
     ldecode_2 := ldecode_2 || '''' || language_name ||
      ''', "' || attribute_column_name || '", ';
        end if;
      else
        -- no more records
        dbms_sql.close_cursor(c);
        exit;
      end if;
    end loop;

    ad_mls.mls_decode_1 := ldecode_1;
    ad_mls.mls_decode_2 := ldecode_2;
  else
    null;
  end if;

  log_debug_message('End procedure build_lang_decode ');

exception
  when others then
     if (dbms_sql.is_open(c)) then
        dbms_sql.close_cursor(c);
      end if;
    ad_apps_private.error_buf := 'build_lang_decode('||aol_schema||
      '):'||ad_apps_private.error_buf;
    raise;
end build_lang_decode;


procedure build_mls_column_list
           (table_name       in  varchar2,
            table_owner      in  varchar2,
            aol_schema       in  varchar2,
            view_column_list out nocopy varchar2,
            select_list      out nocopy varchar2)
is
  c         integer;
  rows_processed   integer;
  statement      varchar2(32000);
  column_name      varchar2(30);
  mlsized      varchar2(1);
  translated_column_number number;
  lview_column_list     varchar2(20000) := null;
  lselect_list          varchar2(20000) := null;
  counter      number := 1;
  v_aol_schema          varchar2(30);

begin

-- Sql Injection Bug 25248691
  log_debug_message('Begin procedure build_mls_column_list ');
  v_aol_schema := sys.dbms_assert.schema_name(aol_schema);

    -- get value for mls_decode's
    if ad_mls.mls_decode_1 is null then
      build_lang_decode (aol_schema);
    end if;

    c := dbms_sql.open_cursor;

-- Sql Injection Bug 25248691
  v_aol_schema := sys.dbms_assert.enquote_name(aol_schema,FALSE);

    statement :=
      'select dtc.column_name,                                          '||
      '  decode(atc.column_name,'''',''N'',''Y'') mlsized,              '||
      '  translated_column_number                                       '||
      'from all_tab_columns dtc,                                        '||
      v_aol_schema||
      '.ak_translated_columns atc                           '||
      'where dtc.table_name = upper(:table_name)                        '||
      'and   nvl(atc.enabled_flag,''Y'') = ''Y''         '||
      'and   dtc.owner = upper(:table_owner)                            '||
      'and   atc.table_name (+) = dtc.table_name                        '||
      'and   atc.column_name (+) = dtc.column_name                      '||
      'order by dtc.column_id                                           ';
    dbms_sql.parse(c, statement, dbms_sql.native);
    dbms_sql.define_column(c,1,column_name,30);
    dbms_sql.define_column(c,2,mlsized,1);
    dbms_sql.define_column(c,3,translated_column_number);
    dbms_sql.bind_variable(c,'table_name',table_name);
    dbms_sql.bind_variable(c,'table_owner',table_owner);
    rows_processed := dbms_sql.execute(c);
    loop
      if dbms_sql.fetch_rows(c) > 0 then

        -- only add commas between columns
        if counter > 1 then
          lview_column_list := lview_column_list || ', ';
          lselect_list := lselect_list || ', ';
        end if;
        counter := counter + 1;

        dbms_sql.column_value(c,1,column_name);
        dbms_sql.column_value(c,2,mlsized);
        dbms_sql.column_value(c,3,translated_column_number);
        if mlsized = 'Y' then
          if translated_column_number = 1 then
            lselect_list := lselect_list || ad_mls.mls_decode_1 ||
         '"'||column_name || '"), "' || column_name ||'")' ;
            lview_column_list := lview_column_list ||'"'|| column_name||'"';
          elsif translated_column_number = 2 then
            lselect_list := lselect_list || ad_mls.mls_decode_2 ||
         '"'||column_name || '"), "' || column_name ||'")' ;
            lview_column_list := lview_column_list ||'"'|| column_name||'"';
          else
            lselect_list := lselect_list||'"'|| column_name||'"';
            lview_column_list := lview_column_list ||'"'|| column_name||'"';
          end if;
        else
          lselect_list := lselect_list ||'"'|| column_name||'"';
          lview_column_list := lview_column_list ||'"'|| column_name||'"';
        end if;

      else
        -- no more records
        dbms_sql.close_cursor(c);
        exit;
      end if;
    end loop;
    view_column_list := '('|| lview_column_list ||')';
    select_list := lselect_list;
    log_debug_message('End procedure build_mls_column_list ');

exception
  when others then
     if (dbms_sql.is_open(c)) then
        dbms_sql.close_cursor(c);
      end if;
    ad_apps_private.error_buf := 'build_mls_column_list('||
      ','||table_name||','||table_owner||','||aol_schema||
      lview_column_list||','||lselect_list||
      '):'||ad_apps_private.error_buf;
  raise;
end;

procedure do_create_mls_schema
           (install_group_num in number,
            aol_schema        in varchar2,
            apps_schema       in varchar2,
            apps_mls_schema   in varchar2,
            invoker_mode      in varchar2)
is

begin
        -- Step 1) Check for existence of apps_mls_schema
        if not ad_apps_private.check_if_schema_exists(apps_mls_schema) then
          -- Error out if it doesn't exist
          raise_application_error(-20000,'The schema '||
      upper(apps_mls_schema)||' does not exist.');
        end if;

        -- Step 2) Check for existence of APPS*DDL in apps_schema and
        --         apps_mls_schema;
        ad_apps_private.check_for_apps_ddl(apps_schema);
        ad_apps_private.check_for_apps_ddl(apps_mls_schema);

        -- Step 4) Create grants/synonyms for tables and seqs to APPS
        ad_apps_private.create_synonyms(apps_schema, apps_mls_schema,
         apps_schema);

   -- Step 5) Create odd synonyms in MLS account
   ad_apps_private.copy_odd_synonyms(apps_schema, apps_mls_schema);

        -- Step 6) Create MLS views in MLS schema
--
-- This doesn't work, as ak_translated_columns is obsolete in Rel 11.5
-- Leave the call here, as it may need to be fixed if we will support
-- the consulting MLS solution in Rel 11.5.  Better to get an error here
-- and then know we need to fix something than just comment out the call
-- and get the wrong behavior silently.
--

        ad_apps_private.create_special_views(install_group_num,
                       aol_schema, apps_mls_schema, TRUE);


        -- Step 7)Copy views from APPS to MLS
        ad_apps_private.copy_views(aol_schema, apps_schema, apps_mls_schema);

        -- Step 8)Copy stored programs from APPS to MLS

        if invoker_mode = 'FALSE' then
          ad_apps_private.copy_stored_progs(apps_schema, apps_mls_schema,
                                            'A', null,'none');
        else
          ad_invoker.invoker_mrc_grants(apps_schema, apps_mls_schema);
        end if;
        -- end if Invoker's Rights mode

        -- Step 9 Compile invalid objects in appsuser schema
        -- ignoring all compilation failures
        ad_inst.compile_schema(apps_mls_schema);

exception
  when others then
    ad_apps_private.error_buf := 'do_create_mls_schema('||aol_schema||', '
                                 ||apps_schema||', '||apps_mls_schema||', '||
                                 invoker_mode||'):'||ad_apps_private.error_buf;
    raise;

end do_create_mls_schema;


end ad_mls;
