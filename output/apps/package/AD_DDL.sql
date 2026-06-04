
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_DDL" AUTHID CURRENT_USER as
/* $Header: adddls.pls 120.0.12020000.3 2021/01/24 19:58:42 mkumandu noship $ */
   --
   -- Package
   --   AD_DDL
   -- Purpose
   --   Support for runtime DDL operations with functionality to
   --   handle multiorg and distributed applications
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
   --
   -- History
   --   15-May-95 B Lind Created
   --

-- Global variables

error_buf varchar2(32760);
gbl_statement varchar2(32760);

-- global array to store array DDL text

glprogtext dbms_sql.varchar2s;

-- constants

create_table    constant integer := 1;
create_view     constant integer := 2;
create_sequence constant integer := 3;
-- Note we do not support packages until dbms_sys_sql.parse
-- is available that supports arrays publically
-- This has now been implemented as a separate procedure create_package
-- create_package  constant integer := 4;
create_trigger  constant integer := 5;
create_index    constant integer := 6;
alter_trigger   constant integer := 7;
drop_trigger    constant integer := 8;
create_synonym  constant integer := 9;
-- Note these are not supported as it is uncertain what to do in
-- a R10.7 database with these types of statements
-- grant_privilege    constant integer := 10;
-- revoke_privilege   constant integer := 11;
drop_table      constant integer := 12;
drop_view       constant integer := 13;
drop_sequence   constant integer := 14;
drop_index      constant integer := 15;
drop_synonym    constant integer := 16;
alter_table     constant integer := 17;
alter_view      constant integer := 18;
alter_sequence  constant integer := 19;
truncate_table  constant integer := 20;
alter_package   constant integer := 21;
drop_package    constant integer := 22;
create_grants   constant integer := 23;

-- fix bug 2804640 by adding these types for base schema,
-- because the synonyms were not droped or created in base schemas, but
-- in APPS and APPS_MRC
create_base_synonym constant integer := 24;
drop_base_synonym   constant integer := 25;

-- public procedures and functions

procedure do_ddl (applsys_schema          in varchar2,
                  application_short_name  in varchar2,
                  statement_type          in integer,
                  statement               in varchar2,
                  object_name             in varchar2);
   --
   -- Procedure
   --   do_ddl
   -- Purpose
   --   Perform the DDL statement in the correct account(s) for the
   --   application indicated by application_id
   -- Arguments
   --   applsys_schema  The oracle username for the applsys account
   --   application_short_name The application_id that the statement is for
   --   statement_type  One of the macros defined in this file
   -- statement  The sql statement
   -- Example
   --   none
   -- Notes
   --   1. Which schema to perform the ddl operation in is:
   --    Use current user to determine which product_group_num
   --    is being accessed and find the associated schema for
   --    application_id in that product_group.
   --

procedure create_package (applsys_schema          in varchar2,
                          application_short_name  in varchar2,
                          package_name            in varchar2,
                          is_package_body         in varchar2,
                          lb                      in integer,
                          ub                      in integer);
   --
   -- Procedure
   --   create_package
   -- Purpose
   --   Perform the DDL statement to create a package or package body in the
   --   correct account(s) for the application indicated by application_id
   --
   -- Arguments and usage identical to create_plsql_object() except:
   --
   --
   --   package_name            Corresponds to object_name
   --
   --   is_package_body  TRUE if this is a package body, else FALSE
   --
   --       not used internally, keep for backwards compatibility
   --
   -- Calls create_plsql_object()
   --
   -- Always inserts a newline after each line of package source text
   --

procedure create_plsql_object
           (applsys_schema         in  varchar2,
            application_short_name in  varchar2,
            object_name            in  varchar2,
            lb                     in  integer,
            ub                     in  integer,
            insert_newlines        in  varchar2,
            comp_error             out nocopy varchar2);
   --
   -- Procedure
   --   create_plsql_object
   -- Purpose
   --   Perform the DDL statement to create a PL/SQL object in the
   --   correct account(s) for the application indicated by application_id
   -- Arguments
   --   applsys_schema  The oracle username for the applsys account
   --   application_short_name The application_id that the statement is for
   --   object_name  The name of the object being created
   --   lb   line number of first line of loaded text
   --   ub   line number of last line of loaded text
   --   insert_newlines         Add newlines between each line of PL/SQL
   --                             source text ('TRUE' or 'FALSE')
   --   comp_error              'TRUE' if the object created with
   --                             compilation errors
   --                           'FALSE' if the object created
   --                             without compilation errors
   -- Example
   --   none
   -- Notes
   --
   --   1. The object creation statement must have already been loaded
   --      by calls to build_package.  This call executes the statement
   --      built by build_package.
   --
   --   2. lb should generally be 1 with ub being the last line of text.
   --      all values between lb and ub should have been assigned via
   --      build_package
   --
   --   3. Which schema to perform the ddl operation in is:
   --      Use current user to determine which product_group_num
   --      is being accessed and find the associated schema for
   --      application_id in that product_group.
   --
   --   4. The current logic assumes Invoker's Rights by default
   --      Objects without an AUTHID clause are automatically converted
   --        to AUTHID CURRENT_USER.
   --      To create a Definer's Rights PL/SQL object, you
   --        must specify AUTHID DEFINER in the create line
   --      See ad_invoker package for use of the /*nosync*/ keyword
   --        with Definer's Rights PL/SQL objects
   --

procedure build_package (ddl_text in varchar2,
                         row_num  in integer);
   --
   -- Procedure
   --   build_package
   -- Purpose
   --   Build the DDL statement create a package or package body
   --   The resultant DDL statement is executed by create_package
   -- Arguments
   --   ddl_text  One line of the package creation statement,
   --    it can be upto 256 characters
   --   rownum   The line number that is being loaded
   -- Example
   --   none
   -- Notes
   --   none

procedure build_statement (ddl_text in varchar2,
                           row_num  in integer);
   --
   -- Procedure
   --   build_statement
   -- Purpose
   --   Build a DDL statement in 256-byte chunks
   --   The resultant DDL statement is executed by do_array_ddl
   -- Arguments
   --   ddl_text  One line of the DDL statement
   --      It can be up to 256 characters
   --   rownum   The line number that is being loaded
   -- Example
   --   none
   -- Notes
   --   none

procedure do_array_ddl
            (applsys_schema         in varchar2,
             application_short_name in varchar2,
             statement_type         in integer,
             lb                     in integer,
             ub                     in integer,
             object_name            in varchar2);
   --
   -- Procedure
   --   do_array_ddl
   -- Purpose
   --   Perform the DDL statement in the correct account(s) for the
   --   application indicated by application_id
   --
   --   The DDL statement must have been loaded into the glprogtext array
   --   using build_statement
   --
   -- Arguments
   --   applsys_schema  The oracle username for the applsys account
   --   application_short_name The application_id that the statement is for
   --   statement_type  One of the macros defined in this file
   --   lb                      First line of DDL text in glprogtext array
   --   ub                      Last line of DDL text in glprogtext array
   -- object_name             Name of the object on which to perform DDL
   -- Example
   --   none
   -- Notes
   --   1. Which schema to perform the ddl operation in is:
   --    Use current user to determine which product_group_num
   --    is being accessed and find the associated schema for
   --    application_id in that product_group.
   --   2. We currently only support the create view statement from this
   --       function.  Later we may support other statements.
   --

procedure extract_object_name(statement in varchar2,
                              uc_schema out nocopy varchar2,
                              object_name out nocopy varchar2);

procedure create_trigger_in_schema (schema_name in varchar2,
                                    ddl_text    in varchar2);
   --
   -- Procedure
   --   create_trigger_in_schema
   -- Purpose
   --   Create a trigger in the specified schema
   -- Arguments
   --   schema_name     The name of the schema in which to create the trigger
   --                   Must contain a copy of the APPS_DDL package
   --   ddl_text        The "create trigger" statement
   -- Example
   --   none
   -- Notes
   --   none

end ad_ddl;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_DDL" as
/* $Header: adddlb.pls 120.0.12020000.4 2023/01/11 08:26:58 rsatyava noship $ */

  --
  -- Global variables
  -- Added the folling for bug# 4583342
  -- InstallGroupNumber_Cache_Table_Type
  TYPE Ign_Cache_Tbl_Type IS TABLE OF NUMBER INDEX BY VARCHAR2 (40);

  g_Ign_Cache_Tbl Ign_Cache_Tbl_Type;

  --
  --
  -- PRIVATE PROCEDURES/FUNCTIONS
  --

/*
** log debug message
** Debugging routine. You must create the table apps.log_debug_message
*/
procedure log_debug_message(text in varchar2)
is
begin
--  insert into apps.log_debug_message(message) values(text);
--  commit;
    null;
end log_debug_message;

procedure private_do_ddl
           (p_apps_schema    in varchar2,
            p_applsys_schema in varchar2,
            oracle_schema    in varchar2,
            statement_type   in number,
            statement        in varchar2,
            object_name      in varchar2);

procedure private_do_array_ddl
           (p_apps_schema    in varchar2,
            p_applsys_schema in varchar2,
            oracle_schema    in varchar2,
            statement_type   in number,
            lb               in integer,
            ub               in integer,
            object_name      in varchar2);

procedure do_at_tab_a_seq_acd_ind
           (datasai_apps_schema    in varchar2,
            datasai_oracle_schema  in varchar2,
            datasai_statement      in varchar2,
            datasai_statement_type in number,
            datasai_object_name    in varchar2);

procedure do_acd_trigger
           (dat_install_group_num in number,
            dat_apps_schema       in varchar2,
            dat_statement         in varchar2);

procedure do_acd_trigger
           (dat_install_group_num in number,
            dat_apps_schema       in varchar2,
            dat_statement         in varchar2,
            object_name           in varchar2);

procedure do_a_view_cd_syn_ad_pack
           (davcsap_install_group_num in number,
            davcsap_apps_schema       in varchar2,
            davcsap_statement         in varchar2,
            object_name               in varchar2);

procedure do_cd_tab_cd_seq
           (dctcs_install_group_num in number,
            dctcs_apps_schema       in varchar2,
            dctcs_oracle_schema     in varchar2,
            dctcs_statement_type    in integer,
            dctcs_object_name       in varchar2,
            dctcs_statement         in varchar2);

procedure do_cd_view
            (dcv_install_group_num in number,
             dcv_apps_schema       in varchar2,
             dcv_statement_type    in integer,
             dcv_object_name       in varchar2,
             dcv_statement         in varchar2);

procedure do_array_c_view
           (dcv_install_group_num in number,
            dcv_apps_schema       in varchar2,
            dcv_object_name       in varchar2,
            dcv_lb                in integer,
            dcv_ub                in integer);

procedure array_assign_and_execute
           (p_schema_name in varchar2,
            p_lb          in integer,
            p_ub          in integer,
            add_newline   in varchar2,
            object_name   in varchar2,
			object_type   in varchar2);

procedure array_assign_and_execute
           (p_schema_name in varchar2,
            p_lb          in integer,
            p_ub          in integer,
            object_name   in varchar2,
			object_type   in varchar2);


procedure get_array_statement
           (p_lb in integer,
            p_ub in integer);

  --
  -- PUBLIC PROCEDURES/FUNCTIONS
  --

procedure do_ddl
           (applsys_schema          in varchar2,
            application_short_name  in varchar2,
            statement_type          in integer,
            statement               in varchar2,
            object_name             in varchar2)
is
  c_statement        varchar2(10000);
  dummy_boolean        varchar2(30);
  status        varchar2(1);
  industry        varchar2(1);
  oracle_schema        varchar2(30);
  apps_schema        varchar2(30);
  apps_mls_schema    varchar2(30);
  v_oracle_schema varchar2(30);
  v_apps_schema   varchar2(30);
  v_applsys_schema varchar2(30);

begin

  log_debug_message('Begin procedure do_ddl ');

  -- Sql Injection Bug 2524869 Validating APPLSYS schema

  v_applsys_schema := sys.dbms_assert.schema_name(applsys_schema);

  ad_ddl.error_buf := null;
  ad_apps_private.error_buf := null;
  gbl_statement := statement;

  -- from the APPLSYS schema get an APPS schema so that we can access
  -- the procedure FND_INSTALLATION that exists there
  ad_apps_private.get_apps_schema_name( 0, applsys_schema,apps_schema, apps_mls_schema);

  v_apps_schema := sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(apps_schema),FALSE);

  if upper(application_short_name) not in ('INTERMEDIA',upper(apps_schema))   then
    begin
      c_statement:='declare x boolean; '||
        'begin x := '||upper(v_apps_schema)||'.fnd_installation.'||
        'get_app_info_other(:application_short_name, :apps_schema, ' ||
        ':status, :industry, :oracle_schema); '||
        'if x = TRUE then :dummy_boolean := ''TRUE''; '||
        'elsif x = FALSE then :dummy_boolean := ''FALSE''; '||
        'else :dummy_boolean := null; end if; end;';

      EXECUTE IMMEDIATE c_statement
      using IN upper(application_short_name), IN upper(apps_schema),
            OUT status, OUT industry,
            OUT oracle_schema, OUT dummy_boolean;

    exception
      when others then
        ad_ddl.error_buf := 'c_statement='||c_statement||': '||
              ad_ddl.error_buf;
      log_debug_message('Exception - procedure do_ddl ');
      raise;
    end;

    if dummy_boolean <> 'TRUE' then
      raise_application_error(-20000,'Call to GET_APP_INFO_OTHER() failed: '||
        'USER='||user||', Status='||status||', Industry='||industry||
        ', Schema='|| oracle_schema||', STMT='||c_statement);
    end if;
  else
    if upper(application_short_name) = 'INTERMEDIA' then
      oracle_schema :='CTXSYS';
    else
      select ORACLE_USERNAME
      into
      oracle_schema
      from fnd_oracle_userid where read_only_flag='U';
    end if;
  end if;

-- Sql Injection Bug 25248691 - Verify value retrieved from the database

  v_oracle_schema := sys.dbms_assert.schema_name(oracle_schema);

  log_debug_message('calling private_do_ddl..');
  private_do_ddl(apps_schema, applsys_schema, oracle_schema,
                 statement_type, statement, upper(object_name));
  log_debug_message('End procedure do_ddl ');

exception
  when others then
    ad_ddl.error_buf := 'do_ddl('||applsys_schema||', '||
            application_short_name||
            ', '||statement_type||', $statement$, '||
            object_name||'): '||
            ad_ddl.error_buf||': '||ad_apps_private.error_buf||
                        ': substr($statement$,1,255)='''||
                        substr(gbl_statement,1,255)||'''';
    raise;
end do_ddl;


--
-- Private functions/procedures
--

procedure private_do_ddl
           (p_apps_schema    in varchar2,
            p_applsys_schema in varchar2,
            oracle_schema    in varchar2,
            statement_type   in number,
            statement        in varchar2,
            object_name      in varchar2)
is
  install_group_num number;
  l_apps_schema varchar2(30);
  l_mls_apps_schema varchar2(30);
  l_mrc_schema_name varchar2(30);
  rows_processed integer;
  v_apps_schema varchar2(30);
  v_applsys_schema varchar2(30);
  v_oracle_schema varchar2(30);
  c integer;
begin

-- Sql Injection Bug 25248691

  v_apps_schema := sys.dbms_assert.schema_name(p_apps_schema);
  v_applsys_schema := sys.dbms_assert.schema_name(p_applsys_schema);
  v_oracle_schema := sys.dbms_assert.schema_name(oracle_schema);


    if ad_apps_private.is_mls is null
       or ad_apps_private.is_mc is null then
      ad_apps_private.initialize(p_apps_schema);
    end if;

    -- get the install_group_num from the oracle_schema that the object
    -- is to be created in.
    if upper(oracle_schema)  not in ('CTXSYS') then
     IF ( g_Ign_Cache_Tbl.COUNT <> 0 AND g_Ign_Cache_Tbl.EXISTS (oracle_schema) ) THEN
       install_group_num := g_Ign_Cache_Tbl(oracle_schema);
     ELSE
      DECLARE -- Block Find Ign
        c integer;
        rows_processed number;
        c_statement varchar2(2000);
      begin

-- Sql Injection Bug 25248691

        v_apps_schema := sys.dbms_assert.enquote_name(p_apps_schema,FALSE);

        c := dbms_sql.open_cursor;
        c_statement:='select install_group_num from '||
               v_apps_schema||'.fnd_oracle_userid '||
           'where oracle_username = upper(:oracle_schema) '||
           'and install_group_num is not null';
        dbms_sql.parse(c, c_statement, dbms_sql.native);
        dbms_sql.bind_variable(c,'oracle_schema',oracle_schema,30);
        dbms_sql.define_column(c,1,install_group_num);
        rows_processed := dbms_sql.execute(c);
        if dbms_sql.fetch_rows(c) > 0 then
          dbms_sql.column_value(c,1,install_group_num);

        else
          raise no_data_found;
        end if;
        dbms_sql.close_cursor(c);
	g_Ign_Cache_Tbl(oracle_schema) := install_group_num;
      exception
        when others then
          dbms_sql.close_cursor(c);
          ad_ddl.error_buf := 'c_statement='||c_statement||': '||
                ad_ddl.error_buf;
        raise;
      END ; -- Block Find Ign
     END IF ;
    else
      install_group_num:=-99;
    end if;



-- Check for APPS*DDL packages

    ad_apps_private.check_for_apps_ddl(p_apps_schema);
    ad_apps_private.check_for_apps_ddl(oracle_schema);


    if install_group_num <> -99 then
    --
    --
      if ad_apps_private.is_mls then
    -- Get name of mls schema
        ad_apps_private.get_apps_schema_name(install_group_num, p_applsys_schema,
                                           l_apps_schema, l_mls_apps_schema);
    -- check for APPS*DDL in mls schema
        ad_apps_private.check_for_apps_ddl(l_mls_apps_schema);
      end if;

    end if;

    --
    -- Based on type of action determine what to do
    --
    --
    if statement_type = ad_ddl.alter_sequence
      then do_at_tab_a_seq_acd_ind(p_apps_schema, oracle_schema, statement,
                                                statement_type, object_name);
    elsif statement_type = ad_ddl.alter_table
      then do_at_tab_a_seq_acd_ind(p_apps_schema, oracle_schema, statement,
                                                statement_type, object_name);
    elsif statement_type = ad_ddl.alter_trigger
      then do_acd_trigger(install_group_num, p_apps_schema, statement, object_name);
    elsif statement_type = ad_ddl.alter_view
      then do_a_view_cd_syn_ad_pack(install_group_num, p_apps_schema,
                                      statement,object_name);
    elsif statement_type = ad_ddl.create_index
      then do_at_tab_a_seq_acd_ind(p_apps_schema, oracle_schema, statement,
                                                statement_type, object_name);
    elsif statement_type = ad_ddl.create_sequence
      then do_cd_tab_cd_seq(install_group_num, p_apps_schema, oracle_schema,
                              statement_type, object_name, statement);
    elsif statement_type = ad_ddl.create_synonym
      then do_a_view_cd_syn_ad_pack(install_group_num, p_apps_schema,
                                      statement,object_name);
    elsif statement_type = ad_ddl.create_table
      then do_cd_tab_cd_seq(install_group_num, p_apps_schema, oracle_schema,
                              statement_type, object_name, statement);
    elsif statement_type = ad_ddl.create_trigger
      then do_acd_trigger(install_group_num, p_apps_schema, statement, object_name);
    elsif statement_type = ad_ddl.create_view
      then
        log_debug_message('calling do_cd_view...');
        do_cd_view(install_group_num, p_apps_schema, statement_type,
                                      object_name, statement);
        log_debug_message('donecalling do_cd_view...');
    elsif statement_type = ad_ddl.drop_index
      then do_at_tab_a_seq_acd_ind(p_apps_schema, oracle_schema, statement,
                                                statement_type, object_name);
    elsif statement_type = ad_ddl.drop_sequence
        then do_cd_tab_cd_seq(install_group_num, p_apps_schema, oracle_schema,
                              statement_type, object_name, statement);
    elsif statement_type = ad_ddl.drop_synonym
        then do_a_view_cd_syn_ad_pack(install_group_num, p_apps_schema,
                                      statement,object_name);
    elsif statement_type = ad_ddl.drop_table
        then do_cd_tab_cd_seq(install_group_num, p_apps_schema, oracle_schema,
                              statement_type, object_name, statement);
    elsif statement_type = ad_ddl.drop_trigger
      then do_acd_trigger(install_group_num, p_apps_schema, statement, object_name);
    elsif statement_type = ad_ddl.drop_view
      then do_cd_view(install_group_num, p_apps_schema, statement_type,
                                              object_name, statement);
    elsif statement_type = ad_ddl.truncate_table
      then do_at_tab_a_seq_acd_ind(p_apps_schema, oracle_schema, statement,
                                              statement_type, object_name);
    elsif statement_type = ad_ddl.alter_package
      then do_a_view_cd_syn_ad_pack(install_group_num, p_apps_schema,
                                                    statement,object_name);
    elsif statement_type = ad_ddl.drop_package
      then do_a_view_cd_syn_ad_pack(install_group_num, p_apps_schema,
                                                    statement,object_name);
    elsif statement_type = ad_ddl.create_grants
      then do_at_tab_a_seq_acd_ind(p_apps_schema, oracle_schema, statement,
                                              statement_type, object_name);

    -- fix bug 2804640, it returns base schema
    -- The issue in do_ddl() was that synonyms were not created in
    -- base schemas, but in APPS and APPS_MRC

    elsif statement_type = ad_ddl.create_base_synonym
      then do_at_tab_a_seq_acd_ind(p_apps_schema, oracle_schema, statement,
                                              statement_type, object_name);
        ad_apps_private.do_apps_ddl_on_patch_edn(oracle_schema,object_name,
                                           'SYNONYM',statement,'TRUE');
    elsif statement_type = ad_ddl.drop_base_synonym
      then do_at_tab_a_seq_acd_ind(p_apps_schema, oracle_schema, statement,
                                              statement_type, object_name);
      ad_apps_private.do_apps_ddl_on_patch_edn(oracle_schema, object_name,
                                              'SYNONYM', statement, 'TRUE');

    end if;
exception
  when others then
    ad_ddl.error_buf := 'private_do_ddl('||p_apps_schema||', '||
            p_applsys_schema||', '||oracle_schema||
            ', '||statement_type||', $statement$, '||
            object_name||'): '||ad_ddl.error_buf;
    raise;
end;



procedure do_at_tab_a_seq_acd_ind
           (datasai_apps_schema    in varchar2,
            datasai_oracle_schema  in varchar2,
            datasai_statement      in varchar2,
            datasai_statement_type in number,
            datasai_object_name    in varchar2)
is
  l_ev_stmt varchar2(300);
begin

  ad_apps_private.do_apps_ddl(datasai_oracle_schema,datasai_statement, 'TRUE');

 if (datasai_statement_type = ad_ddl.alter_table and
           ad_apps_private.is_edition_enabled = 'Y')
  then
    -- Bug 14471759 Only generate editioned view with the following commands.

    if ((regexp_instr(datasai_statement,'ADD',1,1,0,'i')>0) or
        (regexp_instr(datasai_statement,'DROP',1,1,0,'i')>0) or
        (regexp_instr(datasai_statement,'SET UNUSED COLUMN',1,1,0,'i')>0) or
        (regexp_instr(datasai_statement,'RENAME COLUMN',1,1,0,'i')>0) or
        (regexp_instr(datasai_statement,'RENAME TABLE',1,1,0,'i')>0))
     then
     -- Bug 14471759 Do not need to generate the editioned view for the following command combinations.

       if ((regexp_instr(datasai_statement,'ADD SUPPLEMENTAL',1,1,0,'i')=0) and
          (regexp_instr(datasai_statement,'DROP SUPPLEMENTAL',1,1,0,'i')=0) and
          (regexp_instr(datasai_statement,'ADD OVERFLOW',1,1,0,'i')=0) and
          (regexp_instr(datasai_statement,'DROP PARTITION',1,1,0,'i')=0) and
          (regexp_instr(datasai_statement,'ADD PARTITION',1,1,0,'i')=0))
       then
         -- Table altered, Re-generate EV.
          l_ev_stmt := 'begin '||'ad_zd_table.patch('''|| datasai_oracle_schema ||''','||''''|| datasai_object_name || '''); end;';
          ad_apps_private.do_apps_ddl(datasai_apps_schema, l_ev_stmt, 'TRUE');
        end if;
      end if;
  end if;

exception
  when others then
    ad_ddl.error_buf := 'do_at_tab_a_seq_acd_ind('||datasai_oracle_schema||
        ', $statement$): '||ad_ddl.error_buf;
    raise;
end;


procedure do_acd_trigger
           (dat_install_group_num in number,
            dat_apps_schema       in varchar2,
            dat_statement         in varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  l_apps_schema varchar2(30);
  l_mls_apps_schema varchar2(30);
begin
        -- get the apps_schema_names for this install group
        ad_apps_private.get_apps_schema_name(dat_install_group_num,
        dat_apps_schema, l_apps_schema, l_mls_apps_schema);


    -- execute the trigger code in the apps schema
        ad_apps_private.do_apps_ddl(l_apps_schema,dat_statement, 'TRUE');

exception
  when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
    -- reset main error buffer
    ad_apps_private.error_buf := null;
  when others then
    ad_ddl.error_buf := 'do_acd_trigger('||dat_install_group_num||',  '||
    dat_apps_schema||', $statement$): '||ad_ddl.error_buf;
    raise;
end;

procedure do_acd_trigger
           (dat_install_group_num in number,
            dat_apps_schema       in varchar2,
            dat_statement         in varchar2,
            object_name           in varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  l_apps_schema varchar2(30);
  l_mls_apps_schema varchar2(30);
begin
        -- get the apps_schema_names for this install group
        ad_apps_private.get_apps_schema_name(dat_install_group_num,
        dat_apps_schema, l_apps_schema, l_mls_apps_schema);


    -- execute the trigger code in the apps schema
        ad_apps_private.do_apps_ddl(l_apps_schema,dat_statement, 'TRUE');
        ad_apps_private.do_apps_ddl_on_patch_edn(l_apps_schema,object_name,'TRIGGER',dat_statement,'TRUE');


exception
  when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
    -- reset main error buffer
    ad_apps_private.error_buf := null;
  when others then
    ad_ddl.error_buf := 'do_acd_trigger('||dat_install_group_num||',  '||
    dat_apps_schema||', $statement$): '||ad_ddl.error_buf;
    raise;
end;



procedure do_a_view_cd_syn_ad_pack
           (davcsap_install_group_num in number,
            davcsap_apps_schema       in varchar2,
            davcsap_statement         in varchar2,
            object_name               in varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);

--
-- rkagrawa: Fixed bug 2823541. When dropping synonyms, trap and ignore
-- ORA-01434 error, so that even if the synonym does not exist in apps schema,
-- apps_mls_schema or apps_mrc_schema, the procedure call is successful in
-- dropping the synonym in other schemas
--

  synonym_does_not_exist exception;
  PRAGMA EXCEPTION_INIT(synonym_does_not_exist, -1434);

  l_apps_schema varchar2(30);
  l_mls_apps_schema varchar2(30);
  l_mrc_schema_name varchar2(30);
  print_local_sql boolean;
  v_davcsap_apps_schema varchar2(30);
begin


  if ad_apps_private.is_mls is null
     or ad_apps_private.is_mc is null then
    ad_apps_private.initialize(davcsap_apps_schema);
  end if;

          if davcsap_install_group_num <> 0  then
            -- if this is a non 0 install group then perform this only
            -- for that apps account

            -- get the apps_schema_names for this install group
          if davcsap_install_group_num <> -99 then
            ad_apps_private.get_apps_schema_name(davcsap_install_group_num,
        davcsap_apps_schema, l_apps_schema, l_mls_apps_schema);
          else
            l_apps_schema:='CTXSYS';
          end if;


        -- execute the alter view in the apps schema
            begin
              ad_apps_private.do_apps_ddl(l_apps_schema, davcsap_statement,
                'TRUE');
              ad_apps_private.do_apps_ddl_on_patch_edn(l_apps_schema,object_name,'VIEW',davcsap_statement,'TRUE');

            exception
              when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
              -- reset main error buffer
              ad_apps_private.error_buf := null;

--
-- rkagrawa: Fixed bug 2823541. When dropping synonyms, trap and ignore
-- ORA-01434 error, so that even if the synonym does not exist in apps schema,
-- apps_mls_schema or apps_mrc_schema, the procedure call is successful in
-- dropping the synonym in other schemas
--
              when synonym_does_not_exist then
                ad_apps_private.error_buf := null;

            end;

        if davcsap_install_group_num <> -99 then

          if ad_apps_private.is_mls then
            -- execute the alter view in the apps_mls schema
              begin
                ad_apps_private.do_apps_ddl(l_mls_apps_schema,
                                            davcsap_statement, 'TRUE');
                ad_apps_private.do_apps_ddl_on_patch_edn(l_mls_apps_schema,object_name,'VIEW',davcsap_statement,'TRUE');

              exception
                when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
                -- reset main error buffer
                ad_apps_private.error_buf := null;

--
-- rkagrawa: Fixed bug 2823541. When dropping synonyms, trap and ignore
-- ORA-01434 error, so that even if the synonym does not exist in apps schema,
-- apps_mls_schema or apps_mrc_schema, the procedure call is successful in
-- dropping the synonym in other schemas
--
              when synonym_does_not_exist then
                ad_apps_private.error_buf := null;

              end;
          end if;

        end if;

          else
            -- if this is a 0 install group then perform this for all
            -- apps accounts (all install groups)
            declare
              l_apps_schema varchar2(30);
              l_mls_apps_schema varchar2(30);
              c integer;
              rows_processed number;
              c_statement varchar2(2000);
          l_install_group_num number;
            begin

-- Sql Injection Bug 25248691

             v_davcsap_apps_schema :=  sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(davcsap_apps_schema),FALSE);

              print_local_sql := TRUE;
              c := dbms_sql.open_cursor;
              c_statement:='select install_group_num from '||
                     v_davcsap_apps_schema||'.fnd_oracle_userid '||
                     'where read_only_flag = ''U'' '||
                 'order by install_group_num';
              dbms_sql.parse(c, c_statement, dbms_sql.native);
              dbms_sql.define_column(c,1,l_install_group_num);
              rows_processed := dbms_sql.execute(c);
              print_local_sql := FALSE;
              loop
                if dbms_sql.fetch_rows(c) > 0 then
                  dbms_sql.column_value(c,1,l_install_group_num);
                  ad_apps_private.get_apps_schema_name(l_install_group_num,
            davcsap_apps_schema, l_apps_schema, l_mls_apps_schema);
          -- execute the alter view in the apps schema
                  begin
                ad_apps_private.do_apps_ddl(l_apps_schema,
                                                davcsap_statement, 'TRUE');
              ad_apps_private.do_apps_ddl_on_patch_edn(l_apps_schema,object_name,'VIEW',davcsap_statement,'TRUE');

                  exception
                    when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
                    -- reset main error buffer
                    ad_apps_private.error_buf := null;

--
-- rkagrawa: Fixed bug 2823541. When dropping synonyms, trap and ignore
-- ORA-01434 error, so that even if the synonym does not exist in apps schema,
-- apps_mls_schema or apps_mrc_schema, the procedure call is successful in
-- dropping the synonym in other schemas
--
              when synonym_does_not_exist then
                ad_apps_private.error_buf := null;

                  end;

          if ad_apps_private.is_mls then
              -- execute the alter view in the apps_mls schema
                    begin
                  ad_apps_private.do_apps_ddl(l_mls_apps_schema,
                                  davcsap_statement, 'TRUE');
                  ad_apps_private.do_apps_ddl_on_patch_edn(l_mls_apps_schema,object_name,'VIEW',davcsap_statement,'TRUE');

                    exception
                      when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
                      -- reset main error buffer
                      ad_apps_private.error_buf := null;

--
-- rkagrawa: Fixed bug 2823541. When dropping synonyms, trap and ignore
-- ORA-01434 error, so that even if the synonym does not exist in apps schema,
-- apps_mls_schema or apps_mrc_schema, the procedure call is successful in
-- dropping the synonym in other schemas
--
              when synonym_does_not_exist then
                ad_apps_private.error_buf := null;

                    end;
          end if;

                else
                  dbms_sql.close_cursor(c);
                  exit;
                end if;
              end loop;
            exception
              when others then
                dbms_sql.close_cursor(c);
                if print_local_sql then
                  ad_ddl.error_buf := 'c_statement='||c_statement||': '||
                      ad_ddl.error_buf;
                end if;
                raise;
            end;
          end if;

exception
  when others then
    ad_ddl.error_buf := 'do_a_view_cd_syn_ad_pack('||
    davcsap_install_group_num||', '
    ||davcsap_apps_schema||', $statement$): '||
    ad_ddl.error_buf;
    raise;
end;


procedure do_cd_tab_cd_seq
           (dctcs_install_group_num in number,
            dctcs_apps_schema       in varchar2,
            dctcs_oracle_schema     in varchar2,
            dctcs_statement_type    in integer,
            dctcs_object_name       in varchar2,
            dctcs_statement         in varchar2)
is
  l_apps_schema varchar2(30);
  l_mls_apps_schema varchar2(30);
  l_mrc_apps_schema varchar2(30);
  print_local_sql boolean;
  l_ev_stmt varchar2(300);
  l_exist number;
  l_evname varchar2(30);
  v_dctcs_apps_schema varchar2(30);
begin

  if ad_apps_private.is_mls is null
     or ad_apps_private.is_mc is null then
    ad_apps_private.initialize(dctcs_apps_schema);
  end if;
      -- do statement in base schema
      if dctcs_statement_type = ad_ddl.drop_sequence then
            ad_apps_private.drop_object(dctcs_oracle_schema, dctcs_object_name,
                    'SEQUENCE');
          elsif dctcs_statement_type = ad_ddl.drop_table then
            ad_apps_private.drop_object(dctcs_oracle_schema, dctcs_object_name,
                    'TABLE');
            if (ad_apps_private.is_edition_enabled = 'Y')
            then
               l_evname := ad_apps_private.get_evname(dctcs_object_name);
               SELECT count(1)
               INTO   l_exist
               FROM   sys.dba_editioning_views
               where  owner=dctcs_oracle_schema
               and    view_name=l_evname
               and    table_name=dctcs_object_name;

               if (l_exist > 0)
               then
                  ad_apps_private.drop_object(dctcs_oracle_schema,
                                              l_evname,
                                              'VIEW');
               end if;
            end if;
            -- If ev exist, then drop ev too
      else -- it is a create
         ad_apps_private.do_apps_ddl(dctcs_oracle_schema, dctcs_statement,
              'TRUE');
      end if;
      -- now do the correct action in the apps schemas
          if dctcs_install_group_num <> 0 then
            -- if this is a non 0 install group then perform this only
            -- for that apps account

            -- get the apps_schema_names for this install group
            ad_apps_private.get_apps_schema_name(dctcs_install_group_num,
        dctcs_apps_schema, l_apps_schema, l_mls_apps_schema);

        -- create/drop grant/synonym in apps schema
        if dctcs_statement_type = ad_ddl.create_sequence then
              ad_apps_private.create_gs(dctcs_oracle_schema, l_apps_schema,
                    dctcs_object_name, TRUE, 'ALL');
        elsif dctcs_statement_type = ad_ddl.create_table then
              ad_apps_private.create_gs(dctcs_oracle_schema, l_apps_schema,
                    dctcs_object_name, TRUE, 'ALL', to_ev=>ad_apps_private.is_edition_enabled);
        else  -- this is a drop table/sequence
          ad_apps_private.drop_object(l_apps_schema,
            dctcs_object_name,'SYNONYM');
        end if;

        if ad_apps_private.is_mls then
          -- create/drop grant/synonym in apps_mls schema
          if dctcs_statement_type = ad_ddl.create_sequence then
                ad_apps_private.create_gs(dctcs_oracle_schema,
            l_mls_apps_schema,
              dctcs_object_name, TRUE, 'ALL');
          elsif dctcs_statement_type = ad_ddl.create_table
          then
              ad_apps_private.create_gs(dctcs_oracle_schema,
                 l_mls_apps_schema,
                 dctcs_object_name, TRUE, 'ALL', to_ev=>ad_apps_private.is_edition_enabled);
          else  -- this is a drop table/sequence
            ad_apps_private.drop_object(l_mls_apps_schema,
            dctcs_object_name,'SYNONYM');
          end if;
        end if;

          else

            -- if this is a 0 install group then perform this for all
            -- apps accounts (all install groups)
            declare
              l_apps_schema varchar2(30);
              l_mls_apps_schema varchar2(30);
              l_mrc_apps_schema varchar2(30);
              c integer;
              rows_processed number;
              c_statement varchar2(2000);
          l_install_group_num number;
            begin
-- Sql Injection Bug 25248691

             v_dctcs_apps_schema :=  sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(dctcs_apps_schema),FALSE);

              print_local_sql := TRUE;
              c := dbms_sql.open_cursor;
              c_statement:='select distinct install_group_num from '||
                     v_dctcs_apps_schema||'.fnd_oracle_userid '||
                     'where read_only_flag = ''U'' '||
                 'order by install_group_num';
              dbms_sql.parse(c, c_statement, dbms_sql.native);
              dbms_sql.define_column(c,1,l_install_group_num);
              rows_processed := dbms_sql.execute(c);
              print_local_sql := FALSE;
              loop

                if dbms_sql.fetch_rows(c) > 0 then
                  dbms_sql.column_value(c,1,l_install_group_num);

                  -- get the apps_schema_names for this install group
                  ad_apps_private.get_apps_schema_name(l_install_group_num,
            dctcs_apps_schema, l_apps_schema, l_mls_apps_schema);

              -- create/drop grant/synonym in apps schema
              if dctcs_statement_type = ad_ddl.create_sequence then

                    ad_apps_private.create_gs(dctcs_oracle_schema,
                                              l_apps_schema,
                                              dctcs_object_name, TRUE, 'ALL');
              elsif dctcs_statement_type = ad_ddl.create_table
              then
                    ad_apps_private.create_gs(dctcs_oracle_schema,
                                              l_apps_schema,
                                              dctcs_object_name, TRUE, 'ALL', to_ev=>ad_apps_private.is_edition_enabled);

              else  -- this is a drop table/sequence
                    ad_apps_private.drop_object(l_apps_schema,
                                            dctcs_object_name,'SYNONYM');
              end if;

              if ad_apps_private.is_mls then
                -- create/drop grant/synonym in apps_mls schema
                if dctcs_statement_type = ad_ddl.create_sequence then
                      ad_apps_private.create_gs(dctcs_oracle_schema,
                         l_mls_apps_schema, dctcs_object_name, TRUE, 'ALL');
                elsif dctcs_statement_type = ad_ddl.create_table
                then
                      ad_apps_private.create_gs(dctcs_oracle_schema,
                         l_mls_apps_schema, dctcs_object_name, TRUE, 'ALL', to_ev=>ad_apps_private.is_edition_enabled);
                else  -- this is a drop table/sequence
                  ad_apps_private.drop_object(l_mls_apps_schema,
            dctcs_object_name,'SYNONYM');
                end if;
              end if;

                else
                  dbms_sql.close_cursor(c);
                  exit;
                end if;
              end loop;
            exception
              when others then
                dbms_sql.close_cursor(c);
                if print_local_sql then
                  ad_ddl.error_buf := 'c_statement='||c_statement||': '||
                      ad_ddl.error_buf;
                end if;
                raise;
            end;
          end if;
exception
  when others then
    ad_ddl.error_buf := 'do_cd_tab_cd_seq('||dctcs_install_group_num||', '||
        dctcs_apps_schema||', '||dctcs_oracle_schema||', '||
        dctcs_statement_type||', '||dctcs_object_name||
        ', $statement$): '||ad_ddl.error_buf;
    raise;
end;


procedure do_cd_view
           (dcv_install_group_num in number,
            dcv_apps_schema       in varchar2,
            dcv_statement_type    in integer,
            dcv_object_name       in varchar2,
            dcv_statement         in varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  l_apps_schema varchar2(30);
  l_mls_apps_schema varchar2(30);
  l_mrc_apps_schema varchar2(30);
  print_local_sql boolean;
  v_dcv_apps_schema varchar2(30);
begin

  if ad_apps_private.is_mls is null
     or ad_apps_private.is_mc is null then
    ad_apps_private.initialize(dcv_apps_schema);
  end if;
      -- now do the correct action in the apps schemas
          if dcv_install_group_num <> 0 then
            -- if this is a non 0 install group then perform this only
            -- for that apps account

            -- get the apps_schema_names for this install group
            ad_apps_private.get_apps_schema_name(dcv_install_group_num,
        dcv_apps_schema, l_apps_schema, l_mls_apps_schema);

        -- create/drop view in apps schema
        if dcv_statement_type = ad_ddl.drop_view then
           log_debug_message('1calling ad_apps_private.drop_object...');
          ad_apps_private.drop_object(l_apps_schema,dcv_object_name,
                                          'VIEW');
           log_debug_message('1done calling ad_apps_private.drop_object...');
        else -- create_view
              begin
           log_debug_message('2calling do_apps_ddl...');
            ad_apps_private.do_apps_ddl(l_apps_schema, dcv_statement,
                  'TRUE');
           log_debug_message('2done calling do_apps_ddl...');
           log_debug_message('3calling do_apps_ddl_on_patch_edn...');
            ad_apps_private.do_apps_ddl_on_patch_edn(l_apps_schema,dcv_object_name,'VIEW',dcv_statement,'TRUE');
           log_debug_message('3done calling do_apps_ddl_on_patch_edn...');

              exception
                when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
                -- reset main error buffer
                ad_apps_private.error_buf := null;
              end;

        end if;

        if ad_apps_private.is_mls then
          -- create/drop view in apps_mls schema
          if dcv_statement_type = ad_ddl.drop_view then
           log_debug_message('4calling ad_apps_private.drop_object...');
            ad_apps_private.drop_object(l_mls_apps_schema,
            dcv_object_name,'VIEW');
           log_debug_message('4done calling ad_apps_private.drop_object...');

          else -- create_view
                begin
           log_debug_message('5calling ad_apps_private.do_apps_ddl...');
              ad_apps_private.do_apps_ddl(l_mls_apps_schema,
                                              dcv_statement, 'TRUE');
           log_debug_message('5done calling ad_apps_private.do_apps_ddl...');
           log_debug_message('6calling ad_apps_private.do_apps_ddl_on_patch_edn...');
              ad_apps_private.do_apps_ddl_on_patch_edn(l_mls_apps_schema,dcv_object_name,'VIEW',dcv_statement,'TRUE');

           log_debug_message('6done calling ad_apps_private.do_apps_ddl_on_patch_edn...');
                exception
                  when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
                  -- reset main error buffer
                  ad_apps_private.error_buf := null;
                end;
          end if;
        end if;

          else
            -- if this is a 0 install group then perform this for all
            -- apps accounts (all install groups)
            declare
              l_apps_schema varchar2(30);
              l_mls_apps_schema varchar2(30);
              l_mrc_apps_schema varchar2(30);
              c integer;
              rows_processed number;
              c_statement varchar2(2000);
          l_install_group_num number;
            begin

-- Sql Injection Bug 25248691

             v_dcv_apps_schema :=  sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(dcv_apps_schema),FALSE);

              print_local_sql := TRUE;
              c := dbms_sql.open_cursor;
              c_statement:='select distinct install_group_num from '||
                     v_dcv_apps_schema||'.fnd_oracle_userid '||
                     'where read_only_flag = ''U'' '||
                 'order by install_group_num';
              dbms_sql.parse(c, c_statement, dbms_sql.native);
              dbms_sql.define_column(c,1,l_install_group_num);
              rows_processed := dbms_sql.execute(c);
              print_local_sql := FALSE;
              loop
                if dbms_sql.fetch_rows(c) > 0 then
                  dbms_sql.column_value(c,1,l_install_group_num);

                  -- get the apps_schema_names for this install group
                  ad_apps_private.get_apps_schema_name(l_install_group_num,
            dcv_apps_schema, l_apps_schema, l_mls_apps_schema);

              -- create/drop view in apps schema
              if dcv_statement_type = ad_ddl.drop_view then
             log_debug_message('7calling ad_apps_private.drop_object...');
                ad_apps_private.drop_object(l_apps_schema,
            dcv_object_name,'VIEW');
             log_debug_message('7done calling ad_apps_private.drop_object...');
              else -- create_view
                    begin
             log_debug_message('8calling ad_apps_private.do_apps_ddl...');
                  ad_apps_private.do_apps_ddl(l_apps_schema,
                                                  dcv_statement, 'TRUE');
             log_debug_message('8done calling ad_apps_private.do_apps_ddl...');
             log_debug_message('9calling ad_apps_private.do_apps_ddl_on_patch_edn...');
                  ad_apps_private.do_apps_ddl_on_patch_edn(l_apps_schema,dcv_object_name,'VIEW',dcv_statement,'TRUE');

             log_debug_message('9done calling ad_apps_private.do_apps_ddl_on_patch_edn...');
                    exception
                      when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
                      -- reset main error buffer
                      ad_apps_private.error_buf := null;
                    end;
              end if;

              if ad_apps_private.is_mls then
                -- create/drop view in apps_mls schema
                if dcv_statement_type = ad_ddl.drop_view then
             log_debug_message('10calling ad_apps_private.drop_object...');
                  ad_apps_private.drop_object(l_mls_apps_schema,
             dcv_object_name,'VIEW');
             log_debug_message('10done calling ad_apps_private.drop_object...');
                else -- create_view
                      begin
             log_debug_message('11calling ad_apps_private.do_apps_ddl...');
                    ad_apps_private.do_apps_ddl(l_mls_apps_schema,
                                        dcv_statement, 'TRUE');
             log_debug_message('11done calling ad_apps_private.do_apps_ddl...');
             log_debug_message('12calling ad_apps_private.do_apps_ddl_on_patch_edn...');
                    ad_apps_private.do_apps_ddl_on_patch_edn(l_mls_apps_schema,dcv_object_name,'VIEW',dcv_statement,'TRUE');

             log_debug_message('12done calling ad_apps_private.do_apps_ddl_on_patch_edn...');
                      exception
                        when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
                        -- reset main error buffer
                        ad_apps_private.error_buf := null;
                      end;
                end if;
              end if;

                else
                  dbms_sql.close_cursor(c);
                  exit;
                end if;
              end loop;
            exception
              when others then
                dbms_sql.close_cursor(c);
                if print_local_sql then
                  ad_ddl.error_buf := 'c_statement='||c_statement||': '||
                      ad_ddl.error_buf;
                end if;
                raise;
            end;
          end if;
exception
  when others then
    ad_ddl.error_buf := 'do_cd_view('||dcv_install_group_num||', '||
        dcv_apps_schema||', '||
        dcv_statement_type||', '||dcv_object_name||
        ', $statement$): '||ad_ddl.error_buf;
    raise;
end do_cd_view;


procedure create_package
           (applsys_schema          in varchar2,
            application_short_name  in varchar2,
            package_name            in varchar2,
            is_package_body         in varchar2,
            lb                      in integer,
            ub                      in integer)
is
  dummy varchar2(20);
begin
--
-- just call more robust create_plsql_object procedure
--
  create_plsql_object(create_package.applsys_schema,
                      create_package.application_short_name,
                      create_package.package_name,
                      create_package.lb,
                      create_package.ub,
                      'TRUE',
                      dummy);
exception
  when others then
    ad_ddl.error_buf := 'create_package('||applsys_schema||', '||
                        application_short_name||
                        ', '||package_name||', '||is_package_body||', '||
                        lb||', '||ub||'): '||
                        ad_ddl.error_buf||': '||ad_apps_private.error_buf||
                        ': substr($statement$,1,255)='''||
                        substr(gbl_statement,1,255)||'''';
    raise;
end create_package;


procedure create_plsql_object
           (applsys_schema         in  varchar2,
            application_short_name in  varchar2,
            object_name            in  varchar2,
            lb                     in  integer,
            ub                     in  integer,
            insert_newlines        in  varchar2,
            comp_error             out nocopy varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  c_statement            varchar2(10000);
  dummy_boolean          varchar2(30);
  status                 varchar2(1);
  industry               varchar2(1);
  oracle_schema          varchar2(30);
  apps_schema            varchar2(30);
  apps_mls_schema        varchar2(30);
  first_apps_schema      varchar2(30);
  current_apps_schema    varchar2(30);
  install_group_num      number;
  print_local_sql        boolean;
  object_type            varchar2(30);
  obj_has_authid         varchar2(10);
  obj_invoker_flag       varchar2(10);
  is_invoker_object      boolean;
  invoker_flag_for_obj   varchar2(10);
  obj_is_correct_synonym boolean;
  obj_exists_in_schema   boolean;
  obj_type_in_schema     varchar2(30);
  tmp_ign                number;
  tmp_apps_schema        varchar2(30);
  tmp_mls_schema         varchar2(30);
  tmp_mrc_schema         varchar2(30);
  effective_schema       varchar2(30);
  object_status          varchar2(10);
  invalid_count          number;
  upper_obj_name         varchar2(30);
  v_applsys_schema       varchar2(128);
  v_apps_schema          varchar2(30);
  v_first_apps_schema    varchar2(30);

begin
  --
  -- Architecture:
  --
  -- Invoker's Rights objects have both spec and body in first APPS schema
  -- Other APPS schemas and MRC schemas have grants/synonyms to spec
  --   in first APPS schema
  --
  -- Definer's Rights objects have both spec and body in all APPS and MRC
  --   schemas
  --
  -- Definer's Rights nosync objects have both spec and body ONLY
  --   in the current APPS schema and its corresponding MRC schema.
  -- These objects only make sense for MOA products.  If an SOA product
  --   tries to create a Definer's Rights nosync object, we treat it as
  --   a normal Definer's Rights object.
  --
  -- Standalone procedures or functions are treated like package specs
  -- Our standard prohibit them, but people sometimes use them anyway...
  --

  -- Sql Injection Bug 25248691
  log_debug_message('Begin procedure create_plsql_object ');
  v_applsys_schema := sys.dbms_assert.schema_name(applsys_schema);

  -- initialize variables

  ad_ddl.error_buf := null;
  ad_apps_private.error_buf := null;
  gbl_statement := null;

  comp_error := 'FALSE';
  upper_obj_name := upper(object_name);

  -- Determine object type

  if    upper(ad_ddl.glprogtext(lb)) like 'CREATE%PACKAGE%' then
    if upper(ad_ddl.glprogtext(lb)) like 'CREATE%PACKAGE BODY%' then
      object_type := 'PACKAGE BODY';
    else
      object_type := 'PACKAGE';
    end if;
  elsif upper(ad_ddl.glprogtext(lb)) like 'CREATE%PROCEDURE%' then
    object_type := 'PROCEDURE';
  elsif upper(ad_ddl.glprogtext(lb)) like 'CREATE%FUNCTION%' then
    object_type := 'FUNCTION';
  else
    object_type := 'UNKNOWN';
  end if;

  if object_type = 'UNKNOWN' then
    raise_application_error(-20000,
      'Unknown or unsupported object type in create_plsql_object()');
  end if;

  -- from the APPLSYS schema get an APPS schema so that we can access
  -- the procedure FND_INSTALLATION that exists there

  ad_apps_private.get_apps_schema_name( 0, applsys_schema,
                apps_schema, apps_mls_schema);

  --
  -- compute effective user
  --
  -- If current user is a registered Oracle E-Business Suite schema,
  --  use current user.  Otherwise, use the APPS schema returned above
  --

-- Sql Injection Bug 25248691

   v_apps_schema := sys.dbms_assert.enquote_name(apps_schema,FALSE);

  c_statement := 'select oracle_username from '||upper(v_apps_schema)||
    '.fnd_oracle_userid where oracle_username = USER';

  begin
    EXECUTE IMMEDIATE c_statement
    into effective_schema;
  exception
    when no_data_found then
      effective_schema := apps_schema;
  end;

  if upper(application_short_name) not in ('INTERMEDIA',upper(apps_schema))  then
  -- dbms_output.put_line('effective_schema='||effective_schema);

  -- Get product information based on effective schema

    begin

-- Sql Injection Bug 25248691

   v_apps_schema := sys.dbms_assert.enquote_name(apps_schema,FALSE);

      c_statement:='declare x boolean; '||
        'begin x := '||upper(v_apps_schema)||'.fnd_installation.'||
        'get_app_info_other(:application_short_name, :effective_schema, ' ||
        ':status, :industry, :oracle_schema); '||
        'if x = TRUE then :dummy_boolean := ''TRUE''; '||
        'elsif x = FALSE then :dummy_boolean := ''FALSE''; '||
        'else :dummy_boolean := null; end if; end;';

      EXECUTE IMMEDIATE c_statement
      using IN upper(application_short_name), IN upper(effective_schema),
            OUT status, OUT industry,
            OUT oracle_schema, OUT dummy_boolean;
    --
    exception
      when others then
        ad_ddl.error_buf := 'c_statement='||c_statement||':'||
                          ad_ddl.error_buf;
      raise;
    end;
    --
    if dummy_boolean <> 'TRUE' then
      raise_application_error(-20000,'Call to GET_APP_INFO_OTHER() failed: '||
        'USER='||user||', Status='||status||', Industry='||industry||
        ', Schema='|| oracle_schema||', STMT='||c_statement);
    end if;
    --
  else
     if upper(application_short_name) = 'INTERMEDIA' then
       oracle_schema :='CTXSYS';
     else
       select ORACLE_USERNAME
       into
       oracle_schema
       from
       fnd_oracle_userid where
       read_only_flag='U';
     end if;
  end if;


  -- initialize global flags if required

  if   ad_apps_private.is_mls is null
    or ad_apps_private.is_mc  is null then
    ad_apps_private.initialize(apps_schema);
  end if;

  -- Get the name of the first apps schema

  begin

-- Sql Injection Bug 25248691

   v_apps_schema := sys.dbms_assert.enquote_name(apps_schema,FALSE);

    c_statement := 'select oracle_username from '||
      v_apps_schema||'.fnd_oracle_userid '||
      'where install_group_num = 1 and read_only_flag = ''U''';

    EXECUTE IMMEDIATE c_statement
    into first_apps_schema;

  exception
    when others then
      ad_ddl.error_buf := 'c_statement='||c_statement||':'||
                        ad_ddl.error_buf;
    raise;
  end;

  -- Get the install_group_num for the oracle_schema that owns the object
  -- If non-zero, it is also the install_group_num for the current
  --   APPS schema.

  if upper(oracle_schema) not in ('CTXSYS') then

    declare
      c integer;
      rows_processed number;
      c_statement varchar2(2000);
    begin

-- Sql Injection Bug 25248691

      v_apps_schema := sys.dbms_assert.enquote_name(apps_schema,FALSE);

      c := dbms_sql.open_cursor;
      c_statement:='select install_group_num from '||
             v_apps_schema||'.fnd_oracle_userid '||
             'where oracle_username = upper(:oracle_schema) '||
             'and install_group_num is not null';
      dbms_sql.parse(c, c_statement, dbms_sql.native);
      dbms_sql.bind_variable(c,'oracle_schema',oracle_schema,30);
      dbms_sql.define_column(c,1,install_group_num);
      rows_processed := dbms_sql.execute(c);
      if dbms_sql.fetch_rows(c) > 0 then
        dbms_sql.column_value(c,1,install_group_num);

      else
        raise no_data_found;
      end if;
      dbms_sql.close_cursor(c);
    exception
      when others then
        dbms_sql.close_cursor(c);
        ad_ddl.error_buf := 'c_statement='||c_statement||': '||
                            ad_ddl.error_buf;
      raise;
    end;
  else

    install_group_num:=-99;

  end if;


  -- Get the name of the APPS schema corresponding to the current
  -- install group num.
  -- Use the first APPS schema if the install group num is zero.

  if install_group_num = -99 then
     current_apps_schema :='CTXSYS';
  else

    if install_group_num <> 0 then

      begin

-- Sql Injection Bug 25248691

   v_apps_schema := sys.dbms_assert.enquote_name(apps_schema,FALSE);

        c_statement := 'select oracle_username from '||
          v_apps_schema||'.fnd_oracle_userid '||
          'where install_group_num = '||install_group_num||
          ' and read_only_flag = ''U''';

        EXECUTE IMMEDIATE c_statement
        into current_apps_schema;

      exception
        when others then
          ad_ddl.error_buf := 'c_statement='||c_statement||':'||
                            ad_ddl.error_buf;
        raise;
      end;

    else

      current_apps_schema := first_apps_schema;

    end if;
  end if;
  -- end get the current APPS schema name

  -- classify the PL/SQL object

  if object_type <> 'PACKAGE BODY' then
    -- not package body

    ad_invoker.classify_plsql_array(ad_ddl.glprogtext, lb, ub,
       object_type, obj_has_authid, obj_invoker_flag);

    if obj_has_authid = 'FALSE' then

      ad_invoker.rewrite_plsql_array(ad_ddl.glprogtext, lb, ub,
       object_type);

      is_invoker_object := TRUE;
      invoker_flag_for_obj := 'I';

    else

      if obj_invoker_flag = 'I' then
        is_invoker_object := TRUE;
      else
        is_invoker_object := FALSE;

        if obj_invoker_flag = 'S' and install_group_num = 0 then

          -- If an SOA product tries to create a Definer's Rights
          -- nosync object the results would be unsupportable, so
          -- do not allow this.  Instead, if nosync requested for
          -- an SOA product's PL/SQL object, ignore the nosync keyword
          -- and copy it to all APPS schemas anyway

          obj_invoker_flag := 'D';
        end if;

      end if;

      invoker_flag_for_obj := obj_invoker_flag;

    end if;

  else
    -- package body

    -- complicated, as we must first look at the package spec
    -- to determine where to create the package body
    --
    -- check to see if the package spec exists in the current APPS
    -- schema.  This will be the right place for Definer's Rights
    -- nosync packages.
    --
    -- If don't find in current APPS schema, look in the first APPS
    -- schema.  This will be the right place for Invoker's Rights
    -- packages
    --
    -- For regular Definer's Rights packages, it shouldn't matter
    -- which APPS schema we look in, as the spec should be in both
    --
    -- Use exact_synonym_match procedure even though we are not
    -- looking for a synonym because it gives us the required
    -- information easily
    --

    ad_apps_private.exact_synonym_match(current_apps_schema, upper_obj_name,
      current_apps_schema, upper_obj_name, obj_is_correct_synonym,
      obj_exists_in_schema, obj_type_in_schema);

    if     obj_exists_in_schema
       and obj_type_in_schema <> 'SYNONYM' then
      -- found the object in the current APPS schema
      -- if either package spec or both spec and body, parse the
      -- package spec to figure out what to do with the package body
      -- If neither, this is an error condition
      --
      -- Note that we would expect the object in the current APPS schema
      -- to be a synonym for Invoker's Rights, so we just roll over to
      -- the check in the first APPS schema in this case

      if    obj_type_in_schema = 'PACKAGE'
         or obj_type_in_schema = 'PKG_S_AND_B' then

        -- found package spec in current APPS schema
        -- parse it to see what type it is

        ad_invoker.classify_plsql_object(current_apps_schema, upper_obj_name,
          'PACKAGE', obj_has_authid, obj_invoker_flag);

        -- If no authid clause, convert the package spec to Invoker's
        -- Rights.

        if obj_has_authid = 'FALSE' then
          -- rewrite spec for Invoker's Rights
          -- put rewritten spec in first APPS schema
          -- and run grant logic for it

          ad_invoker.rewrite_a_package(current_apps_schema, upper_obj_name,
            'PACKAGE', first_apps_schema, 'FALSE');

          -- create/fix grants for package spec

          tmp_ign := 1;

          loop
            if tmp_ign <> 1 then

              -- Get name for this APPS schema

              -- exit loop if no data found
              -- barring data integrity issues, this means we've processed
              -- all of the APPS schemas (and corresponding MRC schemas)

              begin
                ad_apps_private.get_apps_schema_name(tmp_ign,
                  first_apps_schema, tmp_apps_schema, tmp_mls_schema);
              exception
                when no_data_found then
                  exit;
              end;

              -- Check for APPS*DDL

              ad_apps_private.check_for_apps_ddl(tmp_apps_schema);

              -- create grants

              ad_invoker.grant_a_package(first_apps_schema, upper_obj_name,
                'PACKAGE', tmp_apps_schema, 'Y', 'I', 'FALSE');

            end if;
            -- end if not first APPS schema

            tmp_ign := tmp_ign + 1;
          end loop;
          -- end create/fix grants for package spec

          is_invoker_object := TRUE;
          invoker_flag_for_obj := 'I';

        else
          -- package spec has authid.  set flags according to the value

          if obj_invoker_flag = 'I' then
            is_invoker_object := TRUE;
          else
            is_invoker_object := FALSE;

            if obj_invoker_flag = 'S' and install_group_num = 0 then

              -- If an SOA product tries to create a Definer's Rights
              -- nosync object the results would be unsupportable, so
              -- do not allow this.  Instead, if nosync requested for
              -- an SOA product's PL/SQL object, ignore the nosync keyword
              -- and copy it to all APPS schemas anyway

              obj_invoker_flag := 'D';
            end if;

          end if;

          invoker_flag_for_obj := obj_invoker_flag;

        end if;
        -- end if package spec contains authid keyword

      else
        -- object found, but not a package spec or both spec and body

        raise_application_error(-20000, '"'||upper_obj_name||
          '" in current APPS schema "'||current_apps_schema||
          '" is not a package specification.  Cannot create package '||
          'body "'||upper_obj_name||'"');

      end if;
    else
      if  upper(current_apps_schema) ='CTXSYS'  then
         first_apps_schema:=current_apps_schema;
      end if;
      -- didn't find object in current APPS schema.
      -- This probably an Invoker's Rights package or a normal
      -- Definer's Rights package.  It's also possible that
      -- the package spec doesn't exist

      -- Look for package spec in first APPS schema

      ad_apps_private.exact_synonym_match(first_apps_schema, upper_obj_name,
        first_apps_schema, upper_obj_name, obj_is_correct_synonym,
        obj_exists_in_schema, obj_type_in_schema);

      if obj_exists_in_schema then
        -- found the object in the first APPS schema
        -- if either package spec or both spec and body, parse the
        -- package spec to figure out what to do with the package body
        -- If neither, this is an error condition

        if    obj_type_in_schema = 'PACKAGE'
           or obj_type_in_schema = 'PKG_S_AND_B' then

          -- found package spec in first APPS schema
          -- parse it to see what type it is

          ad_invoker.classify_plsql_object(first_apps_schema,
            upper_obj_name, 'PACKAGE', obj_has_authid, obj_invoker_flag);

          -- If no authid clause, convert the package spec to Invoker's
          -- Rights.

          if obj_has_authid = 'FALSE' then
            -- rewrite spec for Invoker's Rights
            -- and run grant logic for it

            ad_invoker.rewrite_a_package(first_apps_schema, upper_obj_name,
              'PACKAGE', first_apps_schema, 'FALSE');

            -- create/fix grants for package spec

            tmp_ign := 1;

            loop
              if tmp_ign <> 1 then

                -- Get name for this APPS schema

                -- exit loop if no data found
                -- barring data integrity issues, this means we've processed
                -- all of the APPS schemas (and corresponding MRC schemas)

                begin
                  ad_apps_private.get_apps_schema_name(tmp_ign,
                    first_apps_schema, tmp_apps_schema, tmp_mls_schema);
                exception
                  when no_data_found then
                    exit;
                end;

                -- Check for APPS*DDL

                ad_apps_private.check_for_apps_ddl(tmp_apps_schema);

                -- create grants

                ad_invoker.grant_a_package(first_apps_schema, upper_obj_name,
                  'PACKAGE', tmp_apps_schema, 'Y', 'I', 'FALSE');

              end if;
              -- end if not first APPS schema

              tmp_ign := tmp_ign + 1;
            end loop;
            -- end create/fix grants for package spec

            is_invoker_object := TRUE;
            invoker_flag_for_obj := 'I';

          else
            -- package spec has authid.  set flags according to the value

            if obj_invoker_flag = 'I' then
              is_invoker_object := TRUE;
            else
              is_invoker_object := FALSE;

              if obj_invoker_flag = 'S' and install_group_num = 0 then

                -- If an SOA product tries to create a Definer's Rights
                -- nosync object the results would be unsupportable, so
                -- do not allow this.  Instead, if nosync requested for
                -- an SOA product's PL/SQL object, ignore the nosync keyword
                -- and copy it to all APPS schemas anyway

                obj_invoker_flag := 'D';
              end if;

            end if;

            invoker_flag_for_obj := obj_invoker_flag;

          end if;
          -- end if package spec contains authid keyword

        else
          -- object found, but not a package spec or both spec and body

          raise_application_error(-20000, '"'||upper_obj_name||
            '" in first APPS schema "'||first_apps_schema||
            '" is not a package specification.  Cannot create package '||
            'body "'||upper_obj_name||'"');

        end if;

      else
        -- package spec not found in either current or first APPS schemas

        raise_application_error(-20000, 'No package specification '
          ||'found for package body "'||upper_obj_name||'"');

      end if;
      -- end if package spec not found in first APPS schema

    end if;
    -- end if package spec not in current APPS schema

  end if;
  -- end if creating a package body

  --
  -- Between object_type, is_invoker_object, and invoker_flag_for_obj
  -- we now have enough informaton to know what to do
  --
  -- If object is not a package body and we needed to rewrite the
  -- source text, we already did this.
  --
  -- If object is a package body, we already found and classified
  -- the spec (and possibly also rewrote it), so we know where to
  -- put the body
  --
  -- first_apps_schema, current_apps_schema, and install_group_num
  -- are also key information
  --

  -- dbms_output.put_line('object_type='||object_type);
  -- if is_invoker_object then
  --  dbms_output.put_line('is_invoker_object=TRUE');
  -- else
  --   dbms_output.put_line('is_invoker_object=FALSE');
  -- end if;
  -- dbms_output.put_line('invoker_flag_for_obj='||invoker_flag_for_obj);
  -- dbms_output.put_line('first_apps_schema='||first_apps_schema);
  -- dbms_output.put_line('current_apps_schema='||current_apps_schema);
  -- dbms_output.put_line('install_group_num='||install_group_num);

  if object_type <> 'PACKAGE BODY' then
    -- not package body

    if upper(current_apps_schema) = 'CTXSYS' then
       first_apps_schema:=current_apps_schema;
    end if;

    if is_invoker_object then
      -- Create in first APPS schema
      -- Create grants to other APPS schemas

      -- Check for APPS*DDL

      ad_apps_private.check_for_apps_ddl(first_apps_schema);

      -- Create package in first APPS schema

      begin

        --dbms_output.put_line('creating package spec...');

        array_assign_and_execute(first_apps_schema, lb, ub,
          insert_newlines,object_name,'PACKAGE');

        -- dbms_output.put_line('successful');

      exception
        when success_with_comp_error then

        -- dbms_output.put_line('success w comp error');

        -- reset main error buffer

        ad_apps_private.error_buf := null;

        -- record compilation error

        comp_error := 'TRUE';

      end;

      -- create grants/synonyms to other APPS schemas

      tmp_ign := 1;

      if  upper(first_apps_schema) <> 'CTXSYS' then

        loop
          if tmp_ign <> 1 then

            -- Get name for this APPS schema

            -- exit loop if no data found
            -- barring data integrity issues, this means we've processed
            -- all of the APPS schemas (and corresponding MRC schemas)

            begin
              ad_apps_private.get_apps_schema_name(tmp_ign,
                first_apps_schema, tmp_apps_schema, tmp_mls_schema);
            exception
              when no_data_found then
                exit;
            end;

            -- Check for APPS*DDL

            ad_apps_private.check_for_apps_ddl(tmp_apps_schema);

            -- create grants

            ad_invoker.grant_a_package(first_apps_schema, upper_obj_name,
              'PACKAGE', tmp_apps_schema, 'Y', 'I', 'FALSE');

          end if;
          -- end if not first APPS schema

          tmp_ign := tmp_ign + 1;
        end loop;
        -- end create grants to other APPS schemas
      end if;

    else

      if invoker_flag_for_obj = 'S' then
        -- Definer's Rights nosync object
        -- Create in current APPS schema
        -- no grants required

        -- Check for APPS*DDL


        ad_apps_private.check_for_apps_ddl(current_apps_schema);

        -- Drop existing synonym, if any

        ad_apps_private.exact_synonym_match(current_apps_schema,
          upper_obj_name, current_apps_schema, upper_obj_name,
          obj_is_correct_synonym, obj_exists_in_schema, obj_type_in_schema);

        if     obj_exists_in_schema
           and obj_type_in_schema = 'SYNONYM' then

           ad_apps_private.drop_object(current_apps_schema, upper_obj_name,
             'SYNONYM');

        end if;

        -- Create package in current APPS schema

        begin
          array_assign_and_execute(current_apps_schema, lb, ub,
            insert_newlines,object_name,'PACKAGE');
        exception
          when success_with_comp_error then
          -- reset main error buffer

          ad_apps_private.error_buf := null;

          -- record compilation error

          comp_error := 'TRUE';

        end;

        -- Do the same for corresponding MRC schema, if any

        -- no grants required

      else
        -- normal Definer's Rights object
        -- Create in all APPS schemas
        -- no grants required

        -- because ad_invoker.grant_a_package synchronizes normal
        -- Definer's Rights packages in the first APPS schema with
        -- the corresponding packages in all other APPS schemas by
        -- comparing the source text and recreating in the other
        -- APPS schemas if required, this logic looks a lot like
        -- the Invoker's Rights logic above

        -- Check for APPS*DDL



        ad_apps_private.check_for_apps_ddl(first_apps_schema);



        -- Create package in first APPS schema

        begin
          array_assign_and_execute(first_apps_schema, lb, ub,
            insert_newlines,object_name,'PACKAGE');

        exception
          when success_with_comp_error then
          -- reset main error buffer

          ad_apps_private.error_buf := null;

          -- record compilation error

          comp_error := 'TRUE';

        end;

        -- create grants/synonyms to other APPS schemas

        if (upper(first_apps_schema) <> 'CTXSYS') then

          tmp_ign := 1;
          loop
            if tmp_ign <> 1 then

              -- Get name for this APPS schema

              -- exit loop if no data found
              -- barring data integrity issues, this means we've processed
              -- all of the APPS schemas (and corresponding MRC schemas)

              begin

                ad_apps_private.get_apps_schema_name(tmp_ign,
                  first_apps_schema, tmp_apps_schema, tmp_mls_schema);

              exception
                when no_data_found then
                  exit;
              end;

              -- Check for APPS*DDL

              ad_apps_private.check_for_apps_ddl(tmp_apps_schema);

              -- compare source text in this APPS schema with text in
              -- first APPS schema, and (re)create if not identical

              ad_invoker.grant_a_package(first_apps_schema, upper_obj_name,
                'PACKAGE', tmp_apps_schema, 'Y', 'D', 'FALSE');

            end if;
            -- end if not first APPS schema

            tmp_ign := tmp_ign + 1;
          end loop;

        end if;
        -- end copy package spec to other APPS schemas

        -- no grants required

      end if;
      -- end Definer's Rights nosync object

    end if;
    -- end if Invoker's Rights object
  else
    -- package body

    if is_invoker_object then
      -- Create in first APPS schema
      -- No grants required

      -- Check for APPS*DDL

      if upper(current_apps_schema) = 'CTXSYS' then
         first_apps_schema:=current_apps_schema;
      end if;

      ad_apps_private.check_for_apps_ddl(first_apps_schema);

      -- Create package body in first APPS schema


      begin
        array_assign_and_execute(first_apps_schema, lb, ub,
          insert_newlines,object_name,'PACKAGE BODY');
      exception
        when success_with_comp_error then
        -- reset main error buffer

        ad_apps_private.error_buf := null;

        -- record compilation error

        comp_error := 'TRUE';

      end;

      -- No grants required

    else

      if invoker_flag_for_obj = 'S' then
        -- Definer's Rights nosync object
        -- Create in current APPS schema
        -- no grants required

        -- Check for APPS*DDL

        ad_apps_private.check_for_apps_ddl(current_apps_schema);

        -- Create package body in current APPS schema

        begin
          array_assign_and_execute(current_apps_schema, lb, ub,
            insert_newlines,object_name,'PACKAGE BODY');
        exception
          when success_with_comp_error then
          -- reset main error buffer

          ad_apps_private.error_buf := null;

          -- record compilation error

          comp_error := 'TRUE';

        end;

        -- Do the same for corresponding MRC schema, if any

        -- No grants required

      else
        -- normal Definer's Rights object
        -- Create in all APPS schemas
        -- no grants required

        tmp_ign := 1;

        if upper(current_apps_schema) = 'CTXSYS' then
           array_assign_and_execute(current_apps_schema, lb, ub,
                insert_newlines,object_name,'PACKAGE BODY');
        else
          loop
            -- Get name for this APPS schema

            -- exit loop if no data found
            -- barring data integrity issues, this means we've processed
            -- all of the APPS schemas (and corresponding MRC schemas)

            begin
              ad_apps_private.get_apps_schema_name(tmp_ign,
                first_apps_schema, tmp_apps_schema, tmp_mls_schema);
            exception
              when no_data_found then
                exit;
            end;

            -- Check for APPS*DDL

            ad_apps_private.check_for_apps_ddl(tmp_apps_schema);

            -- Create package body in this APPS schema

            begin
              array_assign_and_execute(tmp_apps_schema, lb, ub,
                insert_newlines,object_name,'PACKAGE BODY');
            exception
              when success_with_comp_error then
              -- reset main error buffer

              ad_apps_private.error_buf := null;

              -- record compilation error

              comp_error := 'TRUE';

            end;

            -- also create package body in corresponding MRC schema

            tmp_ign := tmp_ign + 1;
          end loop;
        end if;
        -- end create package body in all APPS schemas

        -- no grants required

      end if;
      -- end if Definer's Rights nosync object

    end if;
    -- end if Invoker's Rights object

  end if;
  -- end if not package body

  -- We used to get success_with_comp_error if a PL/SQL object
  -- was create with compilation errors, but that doesn't appear
  -- to be working now.
  --
  -- To workaround this, if comp_error is 'FALSE', check to see if
  -- it looks like the object created with 'VALID' status.
  --
  -- The exact query depends on whether the object is Invoker,
  -- Definer, or Definer nosync
  --


  if comp_error = 'FALSE' then
    if is_invoker_object then

      -- Invoker's Rights object
      -- Check in first APPS schema
      begin

-- Sql Injection Bug 25248691 Modify to use bind variables.

        c_statement := 'select status from sys.dba_objects '||
          'where owner= :first_apps_schema '||
          'and object_name= :upper_obj_name '||
          'and object_type= :object_type';

        EXECUTE IMMEDIATE c_statement
        into object_status using upper(first_apps_schema), upper(upper_obj_name), upper(object_type);



      exception
        when others then
          ad_ddl.error_buf := 'c_statement='||c_statement||':'||
                            ad_ddl.error_buf;
        raise;
      end;

      if object_status = 'INVALID' then
        comp_error := 'TRUE';
      end if;

    else
      if invoker_flag_for_obj = 'S' then
        -- Definer's Rights nosync object
        -- Check in current APPS and MRC schemas

        begin

-- Sql Injection Bug 25248691 Modify to use bind variables.

        c_statement := 'select count(*) from sys.dba_objects '||
          'where owner= :current_apps_schema '||
          'and object_name= :upper_obj_name '||
          'and object_type= :object_type'||
          'and status= ''INVALID''';

          EXECUTE IMMEDIATE c_statement
          into invalid_count using upper(current_apps_schema), upper(upper_obj_name), upper(object_type);

        exception
          when others then
            ad_ddl.error_buf := 'c_statement='||c_statement||':'||
                              ad_ddl.error_buf;
          raise;
        end;

        if invalid_count <> 0 then
          comp_error := 'TRUE';
        end if;

      else
        -- Definer's Rights object
        -- Check in all APPS and MRC schemas
        if (upper(first_apps_schema)  <> 'CTXSYS') then
          begin

-- Sql Injection Bug 25248691 Modify to use bind variable and enquote_name

           v_first_apps_schema := sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(first_apps_schema),FALSE);

            c_statement := 'select count(*) from sys.dba_objects '||
              'where object_name= :upper_obj_name'||
              'and object_type=:object_type'||
              ' and owner in (select oracle_username '||
              'from '||upper(v_first_apps_schema)||'.fnd_oracle_userid '||
              'where read_only_flag in (''U'',''K'')) '||
              'and status=''INVALID''';

            EXECUTE IMMEDIATE c_statement into invalid_count using upper(upper_obj_name), upper(object_type);

          exception
            when others then
              ad_ddl.error_buf := 'c_statement='||c_statement||':'||
                                ad_ddl.error_buf;
            raise;
          end;

          if invalid_count <> 0 then
            comp_error := 'TRUE';
          end if;
        else
           comp_error :='FALSE';
        end if;


      end if;
      -- end if Definer's Rights nosync object

    end if;
    -- end if Invoker's Rights object

  end if;
  -- end if comp_error is 'FALSE'
  log_debug_message('End procedure create_plsql_object ');
exception
  when others then
    ad_ddl.error_buf := 'create_plsql_object('||applsys_schema||', '||
                        application_short_name||
                        ', '||object_name||', '||
                        lb||', '||ub||', '||insert_newlines||'): '||
                        ad_ddl.error_buf||': '||ad_apps_private.error_buf||
                        ': substr($statement$,1,255)='''||
                        substr(gbl_statement,1,255)||'''';
    raise;
end create_plsql_object;


procedure build_package
           (ddl_text in varchar2,
            row_num  in integer)
is
begin
  ad_ddl.error_buf := null;

  ad_ddl.glprogtext(row_num) := ddl_text;

exception
  when others then
    ad_ddl.error_buf := 'build_package('||
    ddl_text||', '||row_num||'): '||ad_ddl.error_buf;
    raise;
end build_package;


procedure build_statement
           (ddl_text in varchar2,
            row_num  in integer)
is
begin
  ad_ddl.error_buf := null;

  ad_ddl.glprogtext(row_num) := ddl_text;

exception
  when others then
    ad_ddl.error_buf := 'build_statement('||
    ddl_text||', '||row_num||'): '||ad_ddl.error_buf;
    raise;
end build_statement;


procedure do_array_ddl
           (applsys_schema         in varchar2,
            application_short_name in varchar2,
            statement_type         in integer,
            lb                     in integer,
            ub                     in integer,
            object_name            in varchar2)
is
  c_statement        varchar2(10000);
  dummy_boolean        varchar2(30);
  status        varchar2(1);
  industry        varchar2(1);
  oracle_schema        varchar2(30);
  apps_schema varchar2(30);
  apps_mls_schema    varchar2(30);
  v_apps_schema  varchar2(30);
  v_applsys_schema        varchar2(30);

begin

  -- Sql Injection Bug 25248691
  log_debug_message('Begin procedure do_array_ddl ');
  v_applsys_schema := sys.dbms_assert.schema_name(applsys_schema);

  ad_ddl.error_buf := null;
  ad_apps_private.error_buf := null;
  gbl_statement := null;

  -- from the APPLSYS schema get an APPS schema so that we can access
  -- the procedure FND_INSTALLATION that exists there
  ad_apps_private.get_apps_schema_name( 0, applsys_schema,
        apps_schema, apps_mls_schema);

  if upper(application_short_name) not in ('INTERMEDIA',upper(apps_schema))  then

    begin

  -- Sql Injection Bug 25248691

      v_apps_schema := sys.dbms_assert.enquote_name(apps_schema,FALSE);

      c_statement:='declare x boolean; '||
        'begin x := '||upper(v_apps_schema)||'.fnd_installation.'||
        'get_app_info_other(:application_short_name, :apps_schema, ' ||
        ':status, :industry, :oracle_schema); ' ||
        'if x = TRUE then :dummy_boolean := ''TRUE''; '||
        'elsif x = FALSE then :dummy_boolean := ''FALSE''; '||
        'else :dummy_boolean := null; end if; end;';

      EXECUTE IMMEDIATE c_statement
      using IN upper(application_short_name), IN upper(apps_schema),
            OUT status, OUT industry,
            OUT oracle_schema, OUT dummy_boolean;

    exception
      when others then
        ad_ddl.error_buf := 'c_statement='||c_statement||': '||
              ad_ddl.error_buf;
      raise;
    end;

    if dummy_boolean <> 'TRUE' then
      raise_application_error(-20000,'Call to GET_APP_INFO_OTHER() failed: '||
        'USER='||user||', Status='||status||', Industry='||industry||
        ', Schema='|| oracle_schema||', STMT='||c_statement);
    end if;
  else
    if upper(application_short_name) = 'INTERMEDIA' then
      oracle_schema:='CTXSYS';
    else
      select ORACLE_USERNAME
      into
      oracle_schema
      from
      fnd_oracle_userid where
      read_only_flag='U';
    end if;
  end if;


  private_do_array_ddl(apps_schema, applsys_schema, oracle_schema,
                       statement_type, lb, ub, upper(object_name));
  log_debug_message('End procedure do_array_ddl ');

exception
  when others then
    ad_ddl.error_buf := 'do_array_ddl('||applsys_schema||', '||
            application_short_name||
            ', '||statement_type||', '||lb||', '||ub||', '||
            object_name||'): '||
            ad_ddl.error_buf||': '||ad_apps_private.error_buf||
                        ': substr($statement$,1,255)='''||
                        substr(gbl_statement,1,255)||'''';
    raise;
end do_array_ddl;


procedure private_do_array_ddl
           (p_apps_schema    in varchar2,
            p_applsys_schema in varchar2,
            oracle_schema    in varchar2,
            statement_type   in number,
            lb               in integer,
            ub               in integer,
            object_name      in varchar2)
is
  install_group_num number;
  l_apps_schema varchar2(30);
  l_mls_apps_schema varchar2(30);
  l_mrc_apps_schema varchar2(30);
  rows_processed integer;
  c integer;
  v_apps_schema varchar2(30);
begin

    v_apps_schema:= sys.dbms_assert.schema_name(p_apps_schema);

    if ad_apps_private.is_mls is null
        or ad_apps_private.is_mc is null then
      ad_apps_private.initialize(p_apps_schema);
    end if;

    -- get the install_group_num from the oracle_schema that the object
    -- is to be created in.
    declare
      c integer;
      rows_processed number;
      c_statement varchar2(2000);
    begin

-- Sql Injection Bug 25248691

    v_apps_schema:= sys.dbms_assert.enquote_name(p_apps_schema,FALSE);

      c := dbms_sql.open_cursor;
      c_statement:='select install_group_num from '||
             v_apps_schema||'.fnd_oracle_userid '||
         'where oracle_username = upper(:oracle_schema) '||
         'and install_group_num is not null';
      dbms_sql.parse(c, c_statement, dbms_sql.native);
      dbms_sql.bind_variable(c,'oracle_schema',oracle_schema,30);
      dbms_sql.define_column(c,1,install_group_num);
      rows_processed := dbms_sql.execute(c);
      if dbms_sql.fetch_rows(c) > 0 then
        dbms_sql.column_value(c,1,install_group_num);

      else
        raise no_data_found;
      end if;
      dbms_sql.close_cursor(c);
    exception
      when others then
        dbms_sql.close_cursor(c);
        ad_ddl.error_buf := 'c_statement='||c_statement||': '||
              ad_ddl.error_buf;
      raise;
    end;

-- Check for APPS*DDL packages

    ad_apps_private.check_for_apps_ddl(p_apps_schema);
    ad_apps_private.check_for_apps_ddl(oracle_schema);

    if ad_apps_private.is_mls then
    -- Get name of mls schema
      ad_apps_private.get_apps_schema_name(install_group_num, p_applsys_schema,
                                           l_apps_schema, l_mls_apps_schema);
    -- check for APPS*DDL in mls schema
      ad_apps_private.check_for_apps_ddl(l_mls_apps_schema);
    end if;

    --
    -- Based on type of action determine what to do
    --
    if statement_type = ad_ddl.create_view then
      do_array_c_view(install_group_num, p_apps_schema,
              object_name, lb, ub);
    else
      raise_application_error(-20000,'Unsupported statement type '||
    statement_type);
    end if;

exception
  when others then
    ad_ddl.error_buf := 'private_do_array_ddl('||p_apps_schema||', '||
            p_applsys_schema||', '||oracle_schema||
            ', '||statement_type||', '||lb||', '||ub||', '||
            object_name||'): '||ad_ddl.error_buf;
    raise;
end private_do_array_ddl;


procedure do_array_c_view
           (dcv_install_group_num in number,
            dcv_apps_schema       in varchar2,
            dcv_object_name       in varchar2,
            dcv_lb                in integer,
            dcv_ub                in integer)
is
  l_apps_schema varchar2(30);
  l_mls_apps_schema varchar2(30);
  l_mrc_apps_schema varchar2(30);
  print_local_sql boolean;
  v_dcv_apps_schema varchar2(30);
begin

  if ad_apps_private.is_mls is null
    or ad_apps_private.is_mc is null then
    ad_apps_private.initialize(dcv_apps_schema);
  end if;
      -- now do the correct action in the apps schemas
          if dcv_install_group_num <> 0 then
            -- if this is a non 0 install group then perform this only
            -- for that apps account

            -- get the apps_schema_names for this install group
            ad_apps_private.get_apps_schema_name(dcv_install_group_num,
        dcv_apps_schema, l_apps_schema, l_mls_apps_schema);

        -- create view in apps schema
        array_assign_and_execute(l_apps_schema, dcv_lb, dcv_ub,dcv_object_name,'VIEW');

        if ad_apps_private.is_mls then
          -- create view in apps_mls schema
          array_assign_and_execute(l_mls_apps_schema, dcv_lb, dcv_ub,dcv_object_name,'VIEW');
        end if;

          else
            -- if this is a 0 install group then perform this for all
            -- apps accounts (all install groups)
            declare
              l_apps_schema varchar2(30);
              l_mls_apps_schema varchar2(30);
              l_mrc_apps_schema varchar2(30);
              c integer;
              rows_processed number;
              c_statement varchar2(2000);
          l_install_group_num number;
            begin

-- Sql Injection Bug 25248691

             v_dcv_apps_schema :=  sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(dcv_apps_schema),FALSE);

              print_local_sql := TRUE;
              c := dbms_sql.open_cursor;
              c_statement:='select distinct install_group_num from '||
                     v_dcv_apps_schema||'.fnd_oracle_userid '||
                     'where read_only_flag = ''U'' '||
                 'order by install_group_num';
              dbms_sql.parse(c, c_statement, dbms_sql.native);
              dbms_sql.define_column(c,1,l_install_group_num);
              rows_processed := dbms_sql.execute(c);
              print_local_sql := FALSE;
              loop
                if dbms_sql.fetch_rows(c) > 0 then
                  dbms_sql.column_value(c,1,l_install_group_num);

                  -- get the apps_schema_names for this install group
                  ad_apps_private.get_apps_schema_name(l_install_group_num,
            dcv_apps_schema, l_apps_schema, l_mls_apps_schema);

              -- create view in apps schema
              array_assign_and_execute(l_apps_schema, dcv_lb, dcv_ub,dcv_object_name,'VIEW');

              if ad_apps_private.is_mls then
                -- create view in apps_mls schema
                array_assign_and_execute(l_mls_apps_schema,
                                             dcv_lb, dcv_ub,dcv_object_name,'VIEW');
              end if;

                else
                  dbms_sql.close_cursor(c);
                  exit;
                end if;
              end loop;
            exception
              when others then
                dbms_sql.close_cursor(c);
                if print_local_sql then
                  ad_ddl.error_buf := 'c_statement='||c_statement||': '||
                      ad_ddl.error_buf;
                end if;
                raise;
            end;
          end if;
exception
  when others then
    ad_ddl.error_buf := 'do_array_c_view('||dcv_install_group_num||', '||
                        dcv_apps_schema||', '||dcv_object_name||', '||
                        dcv_lb||', '||dcv_ub||'): '||ad_ddl.error_buf;
    raise;
end do_array_c_view;




-- Bug 3611969 : FIXED FILE.SQL.35 GSCC WARNINGS
-- sraghuve (07/05/2004)


procedure array_assign_and_execute
          (p_schema_name in varchar2,
           p_lb          in integer,
           p_ub          in integer,
           object_name   in varchar2,
		   object_type   in varchar2)
is
begin

  array_assign_and_execute
           (p_schema_name => p_schema_name,
            p_lb          => p_lb,
            p_ub          => p_ub,
            add_newline   => 'FALSE',
            object_name   => object_name,
			object_type   => object_type);

end;


procedure array_assign_and_execute
           (p_schema_name in varchar2,
            p_lb          in integer,
            p_ub          in integer,
            add_newline   in varchar2,
            object_name   in varchar2,
			object_type   in varchar2)
is
  l_patch_edition       varchar2(500);
  l_schema_name         varchar2(30);
begin

  l_schema_name  :=  sys.dbms_assert.schema_name(p_schema_name);
  l_patch_edition:=  ad_apps_private.get_edition('PATCH');

  --
  -- Copy DDL text to p_schema_name.apps_array_ddl.glprogtext
  --

  for counter in p_lb..p_ub loop
    begin
      ad_apps_private.do_apps_array_ddl_edn(l_schema_name,ad_ddl.glprogtext(counter), counter,l_patch_edition);
    exception
      when others then
        ad_ddl.error_buf := ' At line '||counter||' of array DDL text '||
          ad_ddl.error_buf;
        raise;
    end;
  end loop;

  --
  -- Execute array DDL statement
  --

  ad_apps_private.do_apps_array_ddl(p_schema_name, p_lb, p_ub, add_newline);       -----VENU chk this
  ad_apps_private.do_apps_array_ddl_on_patch_edn(p_schema_name, p_lb, p_ub, add_newline, object_name,object_type);


exception
  when others then
    ad_ddl.error_buf := 'array_assign_and_execute('||
    p_schema_name||', '||p_lb||', '||p_ub||', '||add_newline||
    '): '||ad_ddl.error_buf;
--
-- load statement array into gbl_statement
--
    get_array_statement(p_lb, p_ub);

    raise;
end array_assign_and_execute;


procedure get_array_statement
           (p_lb in integer,
            p_ub in integer)
is
  statement_length number;
  chunk_length number;
  array_index number;
begin
  gbl_statement := null;
  statement_length := 0;
  array_index := p_lb;

  loop
    if array_index > p_ub then
      exit;
    end if;

    chunk_length := lengthb(ad_ddl.glprogtext(array_index));

    if (statement_length + chunk_length) > 32760 then
      exit;
    end if;

    if chunk_length > 0 then
      gbl_statement := gbl_statement || ad_ddl.glprogtext(array_index);
      statement_length := statement_length + chunk_length;
    end if;

    array_index := array_index + 1;
  end loop;

exception
  when others then
    ad_ddl.error_buf := ad_ddl.error_buf||
      'get_array_statement('||p_lb||', '||p_ub||'): ';
    raise;
end get_array_statement;


procedure extract_object_name(statement in varchar2,
                              uc_schema out nocopy varchar2,
                              object_name out nocopy varchar2) is
  pos2 number;
  pos3 number;
  pos4 number;
begin
  if (upper(statement) like '%CREATE%TRIGGER %' ) then
    pos2:=instr(upper(statement),' TRIGGER ',1,1)+9;
    pos3:=instr(upper(statement),' ',pos2,1);
    pos4:=instr(substr(upper(statement),pos2,pos3-pos2),'.',1,1);

    if(pos4 = 0) then
      uc_schema:=null;
      object_name:=substr(upper(statement),pos2,pos3-pos2);
    else
      uc_schema:=substr(upper(statement),pos2,pos4-1);
      object_name:=substr(upper(statement),pos2+pos4,pos3-pos4-pos2);
    end if;

--    dbms_output.put_line('String found <' || object_name || '>');
--  else
--    dbms_output.put_line('String not found.');
  end if;
end extract_object_name;


procedure create_trigger_in_schema
           (schema_name in varchar2,
            ddl_text    in varchar2) is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  uc_schema varchar2(30);
  object_name varchar2(30);
begin
  -- Initialize global variables

  ad_ddl.error_buf := null;
  ad_apps_private.error_buf := null;
  gbl_statement := ddl_text;


  uc_schema := null;

  extract_object_name(ddl_text,uc_schema,object_name);

  -- If user specified schema name in ddl_text
  -- take that as schema name instead of taking
  -- the schema name argument.
  if uc_schema is null then
    -- Upper-case schema name
    uc_schema := substr(upper(schema_name),1,30);
  end if;

  -- Check for APPS*DDL in the schema
  ad_apps_private.check_for_apps_ddl(uc_schema);

  -- Execute create trigger statement using APPS_DDL

  begin
    ad_apps_private.do_apps_ddl(uc_schema, ddl_text, 'TRUE');

    ad_apps_private.do_apps_ddl_on_patch_edn(uc_schema,object_name,'TRIGGER',ddl_text,'TRUE');

  exception
    when success_with_comp_error then
      ad_apps_private.error_buf := null;
  end;

exception
  when others then
    ad_ddl.error_buf := 'create_trigger_in_schema('||schema_name||
      ', $statement$): '||ad_ddl.error_buf||': '||ad_apps_private.error_buf||
      ': substr($statement$,1,255)='''||
      substr(gbl_statement,1,255)||'''';
    raise;
end create_trigger_in_schema;


end ad_ddl;
