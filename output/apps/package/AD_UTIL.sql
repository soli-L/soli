
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_UTIL" AUTHID CURRENT_USER as
/* $Header: adutils.pls 115.5 2004/06/04 14:31:41 sallamse ship $ */
procedure update_column
           (p_old_oid  in number,
            p_new_oid  in number,
            p_tab_name in varchar2,
            p_col_name in varchar2,
            p_option   in varchar2);

procedure update_oracle_id
           (p_release in varchar2,     /* for future use */
            p_old_oid in number,
            p_option  in varchar2 );

procedure update_oracle_id
           (p_release in varchar2,     /* for future use */
            p_old_oid in number);

procedure update_oracle_id
           (p_release in varchar2,     /* for future use */
            p_old_oid in number,
            p_new_oid in number,
            p_option  in varchar2 );

procedure update_oracle_id
           (p_release in varchar2,     /* for future use */
            p_old_oid in number,
            p_new_oid in number);

procedure set_prod_to_shared
           (p_release         in varchar2,
            p_apps_short_name in varchar2);

end ad_util;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_UTIL" as
/* $Header: adutilb.pls 120.0.12020000.2 2012/12/05 12:59:48 mkumandu ship $ */
--------------------------------------------------
--
-- PUBLIC FUNCTION UPDATE_COLUMN
--
-- This is public in case the list in up_oid
-- is not complete.
--
-- update one number column for one table
--
--------------------------------------------------
procedure update_column
           (p_old_oid  in number,
            p_new_oid  in number,
            p_tab_name in varchar2,
            p_col_name in varchar2,
            p_option   in varchar2)
is
  p_cnt number;
  p_cursor integer;
  statement varchar2(500);
  rows_processed integer;
  p_tab_owner varchar2(30);
  p_apps_username varchar2(30);
begin

  begin
    select upper(oracle_username) into p_apps_username
      from fnd_oracle_userid
      where oracle_id between 900 and 999
        and read_only_flag = 'U';
  exception
    when others then
      dbms_output.put_line('-- Unable to get APPS username.');
      return;
  end;

  begin
    select upper(table_owner) into p_tab_owner
      from dba_synonyms
      where synonym_name = upper(p_tab_name)
        and table_name   = ad_zd_table.ev_view(upper(p_tab_name))
        and owner        = upper(p_apps_username);
  exception
    when others then
      dbms_output.put_line('-- Unable to determine owner for table ' ||
                           p_tab_name ||'.');
      return;
  end;

  begin
    select 1 into p_cnt
      from all_tables
      where table_name = upper(p_tab_name)
        and owner      = upper(p_tab_owner);

  exception
    when no_data_found then
      dbms_output.put_line('-- Table '||p_tab_name||' does not exist.');
      return;
  end;

  begin
    select 1 into p_cnt
      from all_tab_columns col, user_synonyms syn
      where syn.synonym_name = upper(p_tab_name)
        and col.column_name  = upper(p_col_name)
        and syn.table_owner  = upper(p_tab_owner)
        and syn.table_name   = col.table_name
        and syn.table_owner  = col.owner;
  exception
    when no_data_found then
      dbms_output.put_line('-- Column '||p_col_name||
                           ' is not a column of table '||
                           p_tab_name||'.');
      return;
  end;

  statement := 'update '||p_tab_name||' set '||p_col_name||' = '||
               p_new_oid||' where '||p_col_name||' = '||p_old_oid;
  dbms_output.put_line(statement||';');

  if upper(p_option) = 'N' then
    return;
  end if;

  p_cursor := dbms_sql.open_cursor;
  dbms_sql.parse(p_cursor, statement, dbms_sql.native);
  rows_processed := dbms_sql.execute(p_cursor);
  dbms_output.put_line('  '||rows_processed||' rows updated.');
  dbms_sql.close_cursor(p_cursor);

exception
  when others then
    dbms_sql.close_cursor(p_cursor);
    raise;

end update_column;

--------------------------------------------------
--
-- PRIVATE FUNCTION UP_OID
--
-- update all known tables related to oracle_id
--
-- This is a private function.  This is called by
-- update_oracle_id, which is overloaded.
--
--------------------------------------------------
procedure up_oid
           (p_release in varchar2, /* for future use */
            p_old_oid in number,
            p_new_oid in number,
            p_option  in varchar2)
is
begin

--
-- 03/12/98
-- The list below is currently in sync with the corresponding lists in
--   $ad/src/database/aidafo.lpc
-- If you change anything in the list below, you must also make the same
-- change in $ad/src/database/aidafo.lpc
--

  update_column(p_old_oid, p_new_oid, 'AD_MERGED_TABLES',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'ALR_ACTION_SET_CHECKS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'ALR_ALERT_INSTALLATIONS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'ALR_ORACLE_MAIL_ACCOUNTS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'ALR_RESPONSE_ACTION_HISTORY',
                        'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_AUDIT_SCHEMAS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_CONCURRENT_COMPLEX_LINES',
                       'TYPE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_CONCURRENT_QUEUE_CONTENT',
                       'TYPE_ID', p_option);
  -----------------------------------------
  -- for release 9 columns
  -- in release 9, type_id was oracle_id
  --------------------------------------------------------------------
  update_column(p_old_oid, p_new_oid, 'FND_CONCURRENT_COMPLEX_LINES',
                       'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_CONCURRENT_QUEUE_CONTENT',
                       'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_RESPONSIBILITY',
                       'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_RESPONSIBILITY',
                       'READ_ONLY_ORACLE_ID', p_option);
  ----------------- end of release 9 columns --------------------------

  update_column(p_old_oid, p_new_oid, 'FND_CONCURRENT_REQUESTS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_DATA_GROUP_UNITS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_DATA_GROUP_UNITS',
                                      'READ_ONLY_ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_DOC_SEQUENCE_ACCESS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_ORACLE_USERID',
                                      'READ_ONLY_ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_REGRESSION_SUITES',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_REGRESSION_TESTS',
                                      'ORACLE_ID', p_option);
  ----------------------------------------------------------------------------
  -- FND_PRODUCT% and FND_MODULE% tables are updated separately by AutoInstall
  -- but we update them here in the PL/SQL API plus we also need to update
  -- ORACLE_ID in FND_ORACLE_USERID itself.
  ----------------------------------------------------------------------------
  update_column(p_old_oid, p_new_oid, 'FND_MODULE_INSTALLATIONS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_PRODUCT_INSTALLATIONS',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_PRODUCT_DEPENDENCIES',
                                      'ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_PRODUCT_DEPENDENCIES',
                                      'REQUIRED_ORACLE_ID', p_option);
  update_column(p_old_oid, p_new_oid, 'FND_ORACLE_USERID',
                                      'ORACLE_ID', p_option);

end up_oid;

--------------------------------------------------
--
-- OVERLOADED PUBLIC FUNCTION UPDATE_ORACLE_ID
--
-- user can specify the new oracle_id he wants to
-- use in case he wants to consolidate schemas.
--
--------------------------------------------------
procedure update_oracle_id
           (p_release in varchar2,
            p_old_oid in number,
            p_new_oid in number,
            p_option  in varchar2)
is
begin

  up_oid(p_release, p_old_oid, p_new_oid, p_option);

end update_oracle_id;

procedure update_oracle_id
           (p_release in varchar2,
            p_old_oid in number,
            p_new_oid in number)
is
begin

  update_oracle_id(
      p_release => p_release,
      p_old_oid => p_old_oid,
      p_new_oid => p_new_oid,
      p_option => 'N');

end update_oracle_id;


--------------------------------------------------
--
-- OVERLOADED PUBLIC FUNCTION UPDATE_ORACLE_ID
--
-- here the new oracle_id is generated from the
-- sequence FND_ORACLE_USERID_S.nextval
--
--------------------------------------------------
procedure update_oracle_id
           (p_release in varchar2,
            p_old_oid in number,
            p_option  in varchar2)
is
  p_new_oid number;
begin

  dbms_output.put_line('-- select fnd_oracle_userid_s.nextval from dual;');

  select fnd_oracle_userid_s.nextval into p_new_oid
    from dual;

  up_oid(p_release, p_old_oid, p_new_oid, p_option);

end update_oracle_id;

procedure update_oracle_id
           (p_release in varchar2,
            p_old_oid in number)
is
begin

  update_oracle_id(
      p_release => p_release,
      p_old_oid => p_old_oid,
      p_option => 'N');

end update_oracle_id;

--------------------------------------------------
--
-- PRIVATE FUNCTION : IS_VALID_APPL_SHORT_NAME
--
--------------------------------------------------
procedure is_valid_appl_short_name
           (p_apps_short_name               varchar2,
            p_apps_id         in out nocopy number)
is
begin

  select application_id into p_apps_id
    from fnd_application
    where application_short_name = upper(p_apps_short_name);

exception
  when no_data_found then
    raise_application_error(-20000, 'Invalid application_short_name: "'||
                            p_apps_short_name||'"');

end is_valid_appl_short_name;

--------------------------------------------------
--
-- PUBLIC FUNCTION SET_PROD_TO_SHARED
--
-- This function changes a product's status in fnd_product_installations
-- to be 'S' if the db_status is 'I', and inserts a row into
-- fnd_data_group_units if it's not already there.
-- If product's status is already 'I' or 'S', doesn't do anything
--
--
--
--------------------------------------------------
procedure set_prod_to_shared
           (p_release          in varchar2,
            p_apps_short_name  in varchar2)
is
  x_oracle_id fnd_product_installations.oracle_id%TYPE;
  x_db_status fnd_product_installations.db_status%TYPE;
  x_status    fnd_product_installations.status%TYPE;
  x_ign       fnd_product_installations.install_group_num%TYPE;

  appid number;  /* application id for the product */
  errmsg varchar2(240);

  cursor x_cursor (appl_id in number) is
    select oracle_id, db_status, status, install_group_num
      from fnd_product_installations
      where application_id = appl_id;

begin
  --
  -- check the application short name and get application_id if valid
  --
  is_valid_appl_short_name(p_apps_short_name, appid);

  FOR c in x_cursor(appid) LOOP

    x_oracle_id := c.oracle_id;
    x_db_status := c.db_status;
    x_status := c.status;
    x_ign := c.install_group_num;

    -- dbms_output.put_line(x_oracle_id||x_db_status||x_ign);

    if x_db_status = 'I' then
      if x_status is null or (x_status <> 'I' and x_status <> 'S') then
        --
        -- set the status to be licensed
        --
        errmsg := 'update fnd_product_installations for oracle_id '||
                  x_oracle_id;
        dbms_output.put_line(errmsg);
        update fnd_product_installations
          set status = 'S',
              last_update_date = sysdate
          where application_id = appid
            and oracle_id = x_oracle_id;

          if SQL%ROWCOUNT = 1 then
            dbms_output.put_line(SQL%ROWCOUNT||
              ' row updated in fnd_product_installations.');
          else
            dbms_output.put_line(SQL%ROWCOUNT||
              ' rows updated in fnd_product_installations.');
          end if;

        --
        -- For application id (0, 1, 3, 50, 160) the application_id
        -- to use in 10.6 is 0.  For everything else is the oracle_id
        -- of the corresponding apps schema.
        --

        -- if x_ign = 0 ; then we need to insert into every set of books

        if x_ign = 0 then

            -- insert a row of this product for every apps schema
            -- decode is used to fulfill the requirement above.

            insert into fnd_data_group_units
             (application_id,
              data_group_id,
              last_update_date,
              last_updated_by,
              creation_date,
              created_by,
              last_update_login,
              oracle_id
             )
            select distinct appid,
                   dg.data_group_id,
                   sysdate,
                   1,
                   sysdate,
                   1,
                   0,
                   decode(substr(p_release, 1, 4), '10.6', decode(appid,
                                                           0,  0,
                                                           1,  0,
                                                           3,  0,
                                                           50, 0,
                                                           160,0,
                                                           u.oracle_id),
                          u.oracle_id)
            from fnd_data_groups dg,
                 fnd_data_group_units du,
                 fnd_oracle_userid u
            where du.data_group_id = dg.data_group_id
              and du.created_by = 1
              and dg.created_by = 1
              and du.oracle_id = u.oracle_id
              and u.oracle_id between 900 and 999
              and not exists
                ( select 'x'
                    from fnd_data_group_units u2
                    where u2.data_group_id = dg.data_group_id
                      and u2.application_id = appid
                );

          if SQL%ROWCOUNT = 1 then
            dbms_output.put_line(SQL%ROWCOUNT||
              ' row inserted into fnd_data_group_units.');
          else
            dbms_output.put_line(SQL%ROWCOUNT||
              ' rows inserted into fnd_data_group_units.');
          end if;

          exit;  -- exit the LOOP
        end if;

        --
        -- If here, we have an MOA product, and x_ign should > 0
        --
        --
        -- insert a row into fnd_data_group_units if not already exists.
        --
        errmsg := 'insert into fnd_data_group_units';

        insert into fnd_data_group_units
          (application_id, data_group_id, last_update_date, last_updated_by,
           creation_date, created_by, last_update_login, oracle_id)
            select distinct appid,
                   dg.data_group_id,
                   sysdate,
                   1,
                   sysdate,
                   1,
                   0,
                   u.oracle_id
            from fnd_data_groups dg,
                 fnd_data_group_units du,
                 fnd_oracle_userid u
            where du.data_group_id = dg.data_group_id
              and du.created_by = 1
              and dg.created_by = 1
              and du.oracle_id = u.oracle_id
              and u.install_group_num = x_ign
              and u.oracle_id between 900 and 999
              and not exists
                ( select 'x'
                    from fnd_data_group_units u2
                    where u2.data_group_id = dg.data_group_id
                      and u2.application_id = appid
                );

          if SQL%ROWCOUNT = 1 then
            dbms_output.put_line(SQL%ROWCOUNT||
              ' row inserted into fnd_data_group_units.');
          else
            dbms_output.put_line(SQL%ROWCOUNT||
              ' rows inserted into fnd_data_group_units.');
          end if;


      end if;
    end if;
  END LOOP;

end set_prod_to_shared;

end ad_util;
