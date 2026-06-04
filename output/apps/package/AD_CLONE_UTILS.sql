
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_CLONE_UTILS" AUTHID CURRENT_USER as
-- $Header: adclutls.pls 120.0.12020000.2 2021/01/24 19:58:16 mkumandu ship $

  --
  -- package constants for CLONE, SYNC, SWAP statuses
  --
  SOURCE_SCHEMA_TYPE CONSTANT varchar2(30) := 'SOURCE';
  CLONE_SCHEMA_TYPE  CONSTANT varchar2(30) := 'CLONE';
  SPEC_SCHEMA_TYPE   CONSTANT varchar2(30) := 'SPEC';

  CLONE_PHASE     CONSTANT varchar2(30) := 'CLONE';
  MERGE_PHASE     CONSTANT varchar2(30) := 'MERGE';
  SYNC_PHASE      CONSTANT varchar2(30) := 'SYNC';
  UNKNOWN_PHASE   CONSTANT varchar2(30) := 'UNKNOWN';

  STATUS_UNKNOWN    CONSTANT varchar2(30)  := 'UNKNOWN';
  STATUS_COMPLETED  CONSTANT varchar2(30)  := 'COMPLETED';
  STATUS_INCOMPLETE CONSTANT varchar2(30)  := 'INCOMPLETE';
  STATUS_FAILED     CONSTANT varchar2(30)  := 'FAILED';
  STATUS_INPROGRESS CONSTANT varchar2(30)  := 'INPROGRESS';

  function get_db_version return varchar2;

  procedure println(X_msg          in varchar2);

  procedure clone_table(X_table_name            in varchar2,
                        X_from_schema           in varchar2,
                        X_to_schema             in varchar2,
                        X_from_APPS_schema      in varchar2,
                        X_to_APPS_schema        in varchar2,
                        X_copy_pk_cons          in boolean default TRUE,
                        X_preserve_partitions   in boolean default TRUE,
                        X_data_tablespace       in varchar2 default NULL,
                        X_index_tablespace      in varchar2 default NULL,
                        X_overwrite             in boolean default FALSE);

  procedure clone_schema(X_source_schema        in varchar2,
                         X_clone_schema         in varchar2,
                         X_degree               in number);

  procedure sync_schema(X_source_schema         in varchar2,
                        X_clone_schema          in varchar2,
                        X_degree                in number);

  procedure merge_schema(X_source_schema        in varchar2,
                         X_clone_schema         in varchar2,
                         X_degree               in number);

  procedure clean_up(X_source_schema        in varchar2,
                     X_clone_schema         in varchar2,
                     X_spec_schema          in varchar2,
                     X_degree               in number  default null,
                     X_cleanup_clone        in boolean default FALSE,
                     X_cleanup_spec         in boolean default FALSE);

  procedure get_status(X_source_schema       in varchar2,
                       X_clone_schema        in varchar2,
                       X_clone_phase        out NOCOPY varchar2,
                       X_clone_status       out NOCOPY varchar2);

  procedure is_phase_complete(X_source_schema in  varchar2,
                              X_clone_schema  in  varchar2,
                              X_phase_name    in  varchar2,
                              X_complete_flag out NOCOPY varchar2);

  procedure validate_schemas(X_source_schema in varchar2,
                             X_clone_schema  in varchar2,
                             X_spec_schema   in varchar2);

  procedure create_schema(X_schema_un   in varchar2,
                          X_schema_pw   in varchar2,
                          X_tablespace  in varchar2);

  procedure repoint_synonyms(X_source_schema  in varchar2,
                             X_clone_schema   in varchar2,
                             X_spec_schema    in varchar2);

  procedure cleanup_chkfile_info(X_apps_schema  in varchar2);

  procedure cleanup_spec_schema(X_spec_schema in varchar2);

  procedure cleanup_clone_schema(X_source_schema in varchar2,
                                 X_clone_schema  in varchar2,
                                 X_force_flag    in boolean,
                                 X_threads       in number);


end;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_CLONE_UTILS" as
-- $Header: adclutlb.pls 120.0.12020000.2 2021/01/24 20:00:05 mkumandu ship $

  g_db_version            varchar2(40) := NULL;
  native_clone_supported  boolean      := FALSE;
  dbms_metadata_supported boolean      := FALSE;
  g_seq_no                number       := 0;


  MAX_LOGSTR_SIZE CONSTANT number      := 80;    -- maximum size of log message
                                                 -- line
  DQT             CONSTANT varchar2(5) := '"';   -- double quotes
  QT              CONSTANT varchar2(5) := '''';  -- quotes
  CCT             CONSTANT varchar2(5) := '||';

  G_CLONE_SCHEMA_NAME CONSTANT varchar2(30) := 'APPSCLONE';
  G_SPEC_SCHEMA_NAME  CONSTANT varchar2(30) := 'APPSSPEC';

  /*
  ** log debug message, jwsmith, sql injection bug 25248691
  ** Debugging routine. You must create the table appslog_debug_message
  */
  procedure log_debug_message(text in varchar2)
  is
  begin
    --  insert into apps.log_debug_message(message) values(text);
    --  commit;
    null;
  end log_debug_message;

  function get_db_version return varchar2 is
    l_version  varchar2(40);
  begin

    if (g_db_version is null) then
      select version
      into   g_db_version
      from   v$instance
      where  rownum = 1;
    end if;

    return(g_db_version);
  end;

  function get_schema_info(X_schema_name in varchar2) return varchar2
  is
    l_read_only_flag  varchar2(10);
  begin

    EXECUTE IMMEDIATE
       ' SELECT read_only_flag'||
       ' FROM FND_ORACLE_USERID u'||
       ' WHERE oracle_username = upper(:b)'
    INTO l_read_only_flag USING X_schema_name;

    return(l_read_only_flag);

  exception
    when no_data_found then
       return(null);
  end;

  procedure println(X_msg          in varchar2)
  is
    i      integer := 1;
    maxlen integer;
  begin
    maxlen := length(X_msg);
    while (i < maxlen+1) loop
      g_seq_no := g_seq_no + 1;

      INSERT INTO AD_GENERIC_TEMP(line_sequence, contents)
      VALUES (g_seq_no, substr(X_msg, i, MAX_LOGSTR_SIZE));

      i := i + MAX_LOGSTR_SIZE;
    end loop;

  end;

  procedure print_timestamp(X_msg          in varchar2)
  is
  begin
       println(X_msg||' '||to_char(sysdate, 'YYYY/MM/DD HH24:MI:SS'));
  end;

  procedure validate_schema(X_schema_name in varchar2,
                            X_schema_type in varchar2)
  is
    l_schema_info varchar2(10);
  begin

     if (X_schema_type not in (SOURCE_SCHEMA_TYPE,
                               CLONE_SCHEMA_TYPE,
                               SPEC_SCHEMA_TYPE)) then
         raise_application_error(-20001,
           'Invalid schema type : '||X_schema_type);
     end if;

     l_schema_info := get_schema_info(X_schema_name);

     --
     -- clone snd spec chema should not be a registered schema
     --
     if (X_schema_type in (CLONE_SCHEMA_TYPE, SPEC_SCHEMA_TYPE)) then
        if (l_schema_info is not null) then
           raise_application_error(-20001,
               'Schema "'||X_schema_name||'" is a registered schema '||
               'and cannot be used for Clone operations.');
        end if;

        --
        -- In 11i, the clone schema and spec schema are hard-coded to APPSCLONE
        -- Make sure no other schema is specified
        --
        if (X_schema_type in (CLONE_SCHEMA_TYPE) and
            X_schema_name <> G_CLONE_SCHEMA_NAME)
        then
           raise_application_error(-20001,
               'Invalid name for clone schema : '||X_schema_name);
        end if;

        if (X_schema_type in (SPEC_SCHEMA_TYPE) and
            X_schema_name <> G_SPEC_SCHEMA_NAME)
        then
           raise_application_error(-20001,
               'Invalid name for specifications schema : '||X_schema_name);
        end if;

     end if;

     --
     -- the source schema must be a universal schema
     --
     if (X_schema_type in (SOURCE_SCHEMA_TYPE)) then
        if (nvl(l_schema_info, '~') <> 'U') then
           raise_application_error(-20001,
             'Schema "'||X_schema_name||'" is not a registered APPS schema '||
             'and cannot be used as the source for Clone operations.');
        end if;
     end if;

  end;

  procedure validate_schemas(X_source_schema in varchar2,
                             X_clone_schema  in varchar2,
                             X_spec_schema   in varchar2)
  is
      -- Sql Injection Bug 25248691
      v_source_schema varchar2(30);
      v_clone_schema varchar2(30);
      v_spec_schema varchar2(30);
  begin

      log_debug_message('Begin procedure validate_schemas ');
      v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
      v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));
      v_spec_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_spec_schema));

      validate_schema(v_source_schema, SOURCE_SCHEMA_TYPE);
      validate_schema(v_clone_schema,  CLONE_SCHEMA_TYPE);
      validate_schema(v_spec_schema,   SPEC_SCHEMA_TYPE);
      log_debug_message('End procedure validate_schemas ');
  end;

  procedure get_column_list(X_table_owner         in varchar2,
                            X_table_name          in varchar2,
                            X_from_APPS_schema    in varchar2,
                            X_col_list           out nocopy varchar2,
                            X_long_column_exists out nocopy boolean,
                            X_type_column_exists out nocopy boolean,
                            X_APPS_type_column_exists out nocopy boolean)
  is
    cursor c_col is
       select column_name, data_type, data_type_owner
       from  sys.dba_tab_columns
       where owner = X_table_owner
       and   table_name = X_table_name;
  begin

    X_col_list := null;
    X_long_column_exists := FALSE;
    X_type_column_exists := FALSE;
    X_APPS_type_column_exists := FALSE;

    for crec in c_col loop

      if (crec.data_type like 'LONG%') then
         X_long_column_exists := TRUE;
      elsif ((crec.data_type_owner is not null) and
            (crec.data_type_owner = X_from_APPS_schema)) then
         X_type_column_exists := TRUE;
         X_APPS_type_column_exists := TRUE;
      else

         if (crec.data_type_owner is not null) then
           X_type_column_exists := TRUE;
         end if;

         if (X_col_list is not null) then
            X_col_list := X_col_list ||', '||crec.column_name;
         else
            X_col_list := crec.column_name;
         end if;
       end if;
    end loop;

  end;

  procedure check_for_special_columns(X_table_name            in varchar2,
                                      X_from_schema           in varchar2,
                                      X_long_column_exists    out NOCOPY boolean,
                                      X_type_column_exists    out NOCOPY boolean)
  is

    cursor c_col is
       select column_name, data_type, data_type_owner
       from  sys.dba_tab_columns
       where owner = X_from_schema
       and   table_name = X_table_name
       and (data_type  in ('LONG', 'LONG RAW')
            or
            (data_type_owner is not null
             and
             data_type_owner not in ('SYSTEM', 'MDSYS', X_from_schema)));

  begin
    for crec in c_col loop

      if (crec.data_type like 'LONG%') then
         X_long_column_exists := TRUE;
      end if;

      if (crec.data_type_owner is not null) then
         X_type_column_exists := TRUE;
      end if;

    end loop;
  end;

  procedure grant_on_type(X_type_name           in varchar2,
                          X_type_owner          in varchar2,
                          X_grant_to_schema     in varchar2,
                          X_type_exists         out NOCOPY boolean)
  is
    l_type_exists varchar2(1);
  begin

    begin
      select 'x'
      into   l_type_exists
      from   sys.dba_types
      where type_name = X_type_name
      and   owner = X_type_owner;

      X_type_exists := TRUE;
    exception
     when NO_DATA_FOUND then
       X_type_exists := FALSE;
       return;
    end;

    ad_inst.do_apps_ddl(X_type_owner,
                        'GRANT ALL ON '||
                        X_type_owner||'.'||X_type_name||
                        ' TO '|| X_grant_to_schema|| ' WITH GRANT OPTION');
  end;

  procedure copy_table_definition(
                        X_table_name               in varchar2,
                        X_base_schema              in varchar2,
                        X_spec_schema              in varchar2,
                        X_copy_pk_cons             in boolean  default FALSE,
                        X_preserve_partitions      in boolean  default FALSE,
                        X_data_tablespace          in varchar2 default NULL,
                        X_index_tablespace         in varchar2 default NULL,
                        X_from_objtyp_schema       in varchar2,
                        X_to_objtyp_schema         in varchar2,
                        X_overwrite                in boolean  default FALSE)
  is
    l_overwrite varchar2(1);
  begin

    if (X_overwrite = TRUE) then
      l_overwrite := 'Y';
    else
      l_overwrite := 'N';
    end if;

    EXECUTE IMMEDIATE
       'declare '||
       '  ddl_stmt CLOB; '||
       '  c1       integer; '||
       '  lb       number; '||
       '  ub       number; '||
       '  offset   integer := 1; '||
       '  ddllen   integer; '||
       '  MAXSIZE  integer := 32000; '||
       '  ddl_tab  dbms_sql.varchar2a; '||
       ''||
       'begin '||
       '  dbms_metadata.set_transform_param( '||
       '     dbms_metadata.SESSION_TRANSFORM, '||
       '     ''PRETTY'', FALSE); '||
       ''||
       '  dbms_metadata.set_transform_param( '||
       '      dbms_metadata.SESSION_TRANSFORM, '||
       '      ''SEGMENT_ATTRIBUTES'', FALSE); '||

       '  dbms_metadata.set_transform_param( '||
       '      dbms_metadata.SESSION_TRANSFORM, '||
       '      ''REF_CONSTRAINTS'', FALSE); '||
       ''||
       'ddl_stmt := dbms_metadata.get_ddl('||QT||'TABLE'||QT||', '||
                                             QT||X_table_name||QT||', '||
                                             QT||X_base_schema||QT||'); '||
       ''||
       'ddl_stmt := replace(ddl_stmt, '||
                       QT||' TABLE '||DQT||X_base_schema||DQT||'.'||QT||
                  ','||QT||' TABLE '||DQT||X_spec_schema||DQT||'.'||QT||
                                    '); '||
       ''||
       'ddl_stmt := replace(ddl_stmt, '||
                       QT||DQT||X_from_objtyp_schema||DQT||'.'||QT||
                  ','||QT||DQT||X_to_objtyp_schema||DQT||'.'||QT||
                                    '); '||
       ''||
       'ddl_stmt := replace(ddl_stmt, '||QT||'USAGE_QUEUE'||QT||
                                    ','||QT||' '||QT||
                                    '); '||
       ''||
       'offset := 1; '||
       'lb := 1; '||
       'ub := 0; '||
       'ddllen := dbms_lob.getlength(ddl_stmt); '||
       ''||
       'while (offset <= ddllen) '||
       'loop '||
       '  ub := ub + 1; '||
       '  ddl_tab(ub) := dbms_lob.substr(ddl_stmt, MAXSIZE, offset); '||
       '  offset := offset + length(ddl_tab(ub)); '||
       'end loop; '||
       ''||
       'c1 := dbms_sql.open_cursor; '||
       ''||
       'begin'||
       '   dbms_sql.parse(c1, ddl_tab, lb, ub, FALSE, dbms_sql.native); '||
       'exception '||
       '  when others then '||
       '    if (sqlcode = -955) then '||
       '      if (:l_overwrite = ''Y'') then '||
       ''||
       '        EXECUTE IMMEDIATE ''DROP TABLE '||X_spec_schema||'.'||
                                              '"'||X_table_name||'"''; '||
       '        dbms_sql.parse(c1, ddl_tab, lb, ub, FALSE, dbms_sql.native); '||
       '      end if;'||
       '    else '||
       '       raise; '||
       '    end if;'||
       'end;'||
       ''||
       'dbms_sql.close_cursor(c1); '||
       ''||
       'end; ' USING l_overwrite;
  end;

  procedure copy_special_table(
                        X_table_name               in varchar2,
                        X_from_schema              in varchar2,
                        X_to_schema                in varchar2,
                        X_copy_pk_cons             in boolean  default FALSE,
                        X_preserve_partitions      in boolean  default FALSE,
                        X_data_tablespace          in varchar2 default NULL,
                        X_index_tablespace         in varchar2 default NULL,
                        X_from_objtyp_schema in varchar2,
                        X_to_objtyp_schema   in varchar2,
                        X_overwrite                in boolean  default FALSE)

  is
    l_stmt      varchar2(32000);
    l_col_stmt  varchar2(512);
    l_data_type_owner varchar2(512);
    l_type_exists  boolean;

    cursor c_col is
      select column_name, data_type, data_type_owner, data_length,
             data_precision, data_scale, nullable
      from   sys.dba_tab_columns
      where  owner = X_from_schema
      and    table_name = X_table_name
      order by column_id;
  begin

     l_stmt := 'CREATE TABLE '||X_to_schema||'.'||X_table_name||' ( ';

     for c_rec in c_col loop

        if (l_col_stmt is not null) then
          l_stmt := l_stmt||', ';
        end if;

        l_col_stmt := c_rec.column_name;
        l_data_type_owner := c_rec.data_type_owner;

        if (X_to_objtyp_schema is not null
            and
            c_rec.data_type_owner not in ('SYSTEM', 'MDSYS', X_from_schema))
        then
            grant_on_type(c_rec.data_type,
                          X_to_objtyp_schema,
                          X_to_schema,
                          l_type_exists);

            if (l_type_exists = TRUE) then
               l_data_type_owner := X_to_objtyp_schema;
            end if;

        end if;

        if (l_data_type_owner is not null) then
           l_col_stmt := l_col_stmt||' '||
                             l_data_type_owner||'.'||c_rec.data_type;
        else
           l_col_stmt := l_col_stmt||' '||
                             c_rec.data_type;

           if (c_rec.data_type = 'NUMBER')
           then
              if (c_rec.data_precision is not null) then
                 l_col_stmt := l_col_stmt || '('||c_rec.data_precision;

                 if (c_rec.data_scale > 0) then
                    l_col_stmt := l_col_stmt || ','||c_rec.data_scale||')';
                 else
                    l_col_stmt := l_col_stmt || ')';
                 end if;

              end if;

           elsif (c_rec.data_type in ('VARCHAR2', 'CHAR', 'RAW')) then
              l_col_stmt := l_col_stmt || '('||c_rec.data_length||')';
           end if;

           if (c_rec.nullable = 'N') then
             l_col_stmt := l_col_stmt || ' NOT NULL';
           end if;

        end if;

        l_stmt := l_stmt || l_col_stmt;
     end loop;

     l_stmt := l_stmt||')';

     -- println(l_stmt);

     EXECUTE IMMEDIATE l_stmt;


  exception
    when others then

       if (sqlcode = -955) then
         --
         -- table already exists. drop table and recreate it
         --

         if (X_overwrite = TRUE) then
           EXECUTE IMMEDIATE 'DROP TABLE '||X_to_schema||'.'||X_table_name;

           EXECUTE IMMEDIATE l_stmt;

         else
           raise;
         end if;
       else
         raise;
       end if;
  end;

  --
  -- create a copy of table in the spec schema
  -- Any type references in X_from_APPS_schema are changed to
  -- X_to_APPS_schema
  --
  procedure clone_table(X_table_name            in varchar2,
                        X_from_schema           in varchar2,
                        X_to_schema             in varchar2,
                        X_from_APPS_schema      in varchar2,
                        X_to_APPS_schema        in varchar2,
                        X_copy_pk_cons          in boolean  default TRUE,
                        X_preserve_partitions   in boolean  default TRUE,
                        X_data_tablespace       in varchar2 default NULL,
                        X_index_tablespace      in varchar2 default NULL,
                        X_overwrite             in boolean  default FALSE)
  is

    l_stmt                   varchar2(32000);
    l_col_list               varchar2(15000);
    l_long_column_exist      boolean := FALSE;
    l_type_column_exist      boolean := FALSE;
    l_APPS_type_column_exist boolean := FALSE;

    l_spec_table_timestamp   varchar2(30);
    l_source_table_timestamp varchar2(30);
    l_spec_table_exists      boolean;
    l_overwrite_spec_table   boolean;

    l_dummy                  varchar2(1);
    l_temporary              varchar2(1);

-- Sql Injection Bug 25248691

    v_table_name             varchar2(30);
    v_from_schema            varchar2(30);
    v_to_schema              varchar2(30);
    v_from_APPS_schema       varchar2(30);
    v_to_APPS_schema         varchar2(30);

  begin
    log_debug_message('Begin procedure clone_table ');
    v_table_name := sys.dbms_assert.simple_sql_name(X_table_name);
    v_from_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_from_schema));
    v_to_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_to_schema));
    v_from_APPS_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_from_APPS_schema));
    v_to_APPS_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_to_APPS_schema));


    if (X_overwrite = TRUE) then
       l_overwrite_spec_table := TRUE;
    else
       --
       -- fisrt get timestamp for spec table. If table exists, then compare
       -- timestamps
       --

       --
       -- find if table is a temporary table. You cannot perform a transaction
       -- against a temporary table and then perform a DDL against that table
       --
       l_overwrite_spec_table := FALSE;

       begin
          SELECT spec.timestamp, temporary
          INTO   l_spec_table_timestamp, l_temporary
          FROM   sys.DBA_OBJECTS spec
          WHERE  spec.OWNER = v_to_schema
          AND    spec.OBJECT_NAME = v_table_name
          AND    spec.OBJECT_TYPE = 'TABLE';

       exception
          when NO_DATA_FOUND then
             l_overwrite_spec_table := TRUE;
             l_temporary := NULL;
       end;

       --
       -- now that spec table exists, compare timestamp with source table
       --
       if (l_overwrite_spec_table = FALSE) then

         begin
            SELECT src.timestamp, nvl(l_temporary, temporary)
            INTO   l_source_table_timestamp, l_temporary
            FROM   sys.DBA_OBJECTS src
            WHERE  src.OWNER = v_from_schema
            AND    src.OBJECT_NAME = v_table_name
            AND    src.OBJECT_TYPE = 'TABLE';

            if (l_source_table_timestamp > l_spec_table_timestamp) then
               l_overwrite_spec_table := TRUE;
            end if;
         end;
       end if;
    end if;

    if (l_overwrite_spec_table = FALSE) then
       return;
    end if;

    get_column_list(v_from_schema,
                    v_table_name,
                    v_from_APPS_schema,
                    l_col_list,
                    l_long_column_exist, l_type_column_exist,
                    l_APPS_type_column_exist);

    --
    -- grant on the table to ensure that the destination schema has proper
    -- privileges on type referenced, if any, by the table
    --
    if (l_type_column_exist = TRUE) then

      ad_inst.do_apps_ddl(v_from_schema,
                          'GRANT SELECT ON '||
                          v_from_schema
                          ||'.'||v_table_name
                          ||' TO '|| v_to_schema
                          || ' WITH GRANT OPTION');
    end if;

    if ((dbms_metadata_supported = TRUE) or
        ( l_long_column_exist = FALSE and l_APPS_type_column_exist = FALSE))
    then

       copy_table_definition(
                  X_table_name=>v_table_name,
                  X_base_schema=>v_from_schema,
                  X_spec_schema=>v_to_schema,
                  X_copy_pk_cons=>X_copy_pk_cons,
                  X_preserve_partitions=>X_preserve_partitions,
                  X_data_tablespace=>X_data_tablespace,
                  X_index_tablespace=>X_index_tablespace,
                  X_from_objtyp_schema=>v_from_APPS_schema,
                  X_to_objtyp_schema=>v_to_APPS_schema,
                  X_overwrite=>l_overwrite_spec_table);
    else

      copy_special_table(
           X_table_name=>v_table_name,
           X_from_schema=>v_from_schema,
           X_to_schema=>v_to_schema,
           X_copy_pk_cons=>X_copy_pk_cons,
           X_preserve_partitions=>X_preserve_partitions,
           X_data_tablespace=>X_data_tablespace,
           X_index_tablespace=>X_index_tablespace,
           X_from_objtyp_schema=>v_from_APPS_schema,
           X_to_objtyp_schema=>v_to_APPS_schema,
           X_overwrite=>l_overwrite_spec_table);

    end if;

    if (l_temporary = 'N') then
      --
      -- insert at least one row of data
      --

      l_stmt := ' INSERT INTO '||v_to_schema
              ||'.'||v_table_name
              ||'('|| l_col_list||') '
              ||' SELECT '||l_col_list||
                ' FROM '||v_from_schema
              ||'.'||v_table_name||
                ' WHERE rownum = 1 '||
                ' AND NOT EXISTS ( '||
                       ' SELECT null'||
                       ' FROM '||v_to_schema||'.'||v_table_name||
                       ' WHERE rownum = 1)';

      EXECUTE IMMEDIATE l_stmt;

      commit;
    end if;

   log_debug_message('End procedure clone_table ');
  end;

  procedure copy_ddl_package(X_name   in varchar2,
                             X_type   in varchar2,
                             X_source_schema in varchar2,
                             X_clone_schema  in varchar2)
  is
    source_text  varchar2(10000):= NULL;

    cursor c1 is
      select text
      from   sys.dba_source
      where owner = X_source_schema
      and name = X_name
      and type = X_type
      order by line;

  begin

     for crec in c1 loop
       if (source_text is null) then
          source_text := 'CREATE OR REPLACE '||X_type||' '||
                         X_clone_schema||'.'||X_name||' AS ';
       else
          source_text := source_text||' '||crec.text;
       end if;
     end loop;

     EXECUTE IMMEDIATE source_text;

  end;

  procedure clone_schema(X_source_schema        in varchar2,
                         X_clone_schema         in varchar2,
                         X_degree               in number)
  is
    l_clone_phase varchar2(30);
    l_clone_status varchar2(30);
    v_source_schema varchar2(30);
    v_clone_schema varchar2(30);

  begin

    -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure clone_schema ');
    v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
    v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));

    validate_schema(v_source_schema, SOURCE_SCHEMA_TYPE);
    validate_schema(v_clone_schema, CLONE_SCHEMA_TYPE);

    if (native_clone_supported = TRUE) then

       get_status(v_source_schema, v_clone_schema,
                  l_clone_phase, l_clone_status);

       --
       -- clone is allowed only if current status is one of
       --    UNKNOWN phase and UNKNOWN status
       --    CLONE   phase and INPROGRESS status
       --    CLONE   phase and FAILED status
       --    MERGE   phase and COMPLETED status

       if (not((l_clone_phase = UNKNOWN_PHASE and
                l_clone_status = STATUS_UNKNOWN)
               or
               (l_clone_phase = CLONE_PHASE and
                l_clone_status in (STATUS_INPROGRESS, STATUS_FAILED))
               or
               (l_clone_phase = MERGE_PHASE and
                l_clone_status = STATUS_COMPLETED)))
       then
          raise_application_error(-20001,
                 'CLONE operation invalid for the current state '||
                 'of the clone schema. '||
                 '[ Current Phase : '||l_clone_phase||
                 '  Status : '||l_clone_status||' ]');

       end if;

       --
       -- recover from a prior clone if necessary
       --
       if (l_clone_phase = CLONE_PHASE AND
           l_clone_status in (STATUS_INPROGRESS, STATUS_FAILED)) then

          println('The previous CLONE operation did not succeed '||
                  'and requires recovery.');

          print_timestamp('Recovery operation started at :');

          EXECUTE IMMEDIATE
             'begin '||
             '  sys.dbms_schema_copy.clone_recovery('||
                            'src_sch=>:a, ' ||
                            'dst_sch=>:b, ' ||
                            'threads=>:c); ' ||
             'end;'
             USING IN v_source_schema, v_clone_schema, X_degree;

          print_timestamp('Recovery operation completed at :');
       else

          print_timestamp('CLONE operation started   at : ');

          EXECUTE IMMEDIATE
             'begin '||
             '  sys.dbms_schema_copy.clone('||
                            'src_sch=>:a, ' ||
                            'dst_sch=>:b, ' ||
                            'threads=>:c); ' ||
             'end;'
             USING IN v_source_schema, v_clone_schema, X_degree;

          print_timestamp('CLONE operation completed at : ');
       end if;

    else

       --
       -- native clone is not specified, just copy DDL package to the
       -- clone schema
       --
       copy_ddl_package( 'APPS_DDL',
                         'PACKAGE',
                         v_source_schema,
                         v_clone_schema);

       copy_ddl_package( 'APPS_ARRAY_DDL',
                         'PACKAGE',
                         v_source_schema,
                         v_clone_schema);

       copy_ddl_package( 'APPS_DDL',
                         'PACKAGE BODY',
                         v_source_schema,
                         v_clone_schema);

       copy_ddl_package( 'APPS_ARRAY_DDL',
                         'PACKAGE BODY',
                         v_source_schema,
                         v_clone_schema);
    end if;
    log_debug_message('End procedure clone_schema ');
  end;

  procedure sync_schema(X_source_schema         in varchar2,
                        X_clone_schema          in varchar2,
                        X_degree                in number)
  is
    l_clone_phase varchar2(30);
    l_clone_status varchar2(30);
    v_source_schema varchar2(30);
    v_clone_schema varchar2(30);

  begin

  -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure sync_schema ');
    v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
    v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));

    validate_schema(v_source_schema, SOURCE_SCHEMA_TYPE);
    validate_schema(v_clone_schema, CLONE_SCHEMA_TYPE);

    if (native_clone_supported = TRUE) then

       get_status(v_source_schema, v_clone_schema,
                  l_clone_phase, l_clone_status);

       --
       -- SYNC is allowed only if current status is one of
       --    CLONE   phase and COMPLETED status

       if (not((l_clone_phase = CLONE_PHASE and
                l_clone_status = STATUS_COMPLETED)))
       then
          raise_application_error(-20001,
               'SYNC operation invalid for the current state of '||
               'the clone schema. '||
               '[ Current Phase : '||l_clone_phase||
               '  Status : '||l_clone_status||' ]');
       end if;

       print_timestamp('SYNC operation started at   : ');

       EXECUTE IMMEDIATE
          'begin '||
          '  sys.dbms_schema_copy.sync_code('||
                         'src_sch=>:a,'||
                         'dst_sch=>:b,'||
                         'ignore_conflict=>TRUE); '||
          'end;'
          USING IN v_source_schema, v_clone_schema;

       print_timestamp('SYNC operation completed at : ');
    end if;
    log_debug_message('End procedure sync_schema ');
  end;

  procedure merge_schema(X_source_schema        in varchar2,
                         X_clone_schema         in varchar2,
                         X_degree               in number)
  is
    l_clone_phase varchar2(30);
    l_clone_status varchar2(30);
    v_source_schema varchar2(30);
    v_clone_schema varchar2(30);

  begin

  -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure merge_schema ');
    v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
    v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));

    validate_schema(v_source_schema, SOURCE_SCHEMA_TYPE);
    validate_schema(v_clone_schema, CLONE_SCHEMA_TYPE);

    if (native_clone_supported = TRUE) then

       get_status(v_source_schema, v_clone_schema,
                  l_clone_phase, l_clone_status);

       --
       -- MERGE is allowed only if current status is one of
       --    CLONE   phase and COMPLETED status

       if (not((l_clone_phase = CLONE_PHASE and
                l_clone_status = STATUS_COMPLETED)
               or
               (l_clone_phase = MERGE_PHASE and
                l_clone_status <> STATUS_COMPLETED)))
       then
          raise_application_error(-20001,
               'MERGE operation invalid for the current state of '||
               'the clone schema. '||
               '[ Current Phase : '||l_clone_phase||
               '  Status : '||l_clone_status||' ]');
       end if;

       print_timestamp('MERGE operation started   at : ');

       EXECUTE IMMEDIATE
          'begin '||
          '  sys.dbms_schema_copy.swap('||
                         'src_sch=>:a,'||
                         'dst_sch=>:b,'||
                         'ignore_conflict=>TRUE); '||
          'end;'
          USING IN v_source_schema, v_clone_schema;

       print_timestamp('MERGE operation completed at : ');

    end if;

    log_debug_message('End procedure merge_schema ');
  end;

  procedure cleanup_chkfile_info(X_apps_schema  in varchar2) is

    v_apps_schema varchar2(30);

    cursor c_syn is
      select synonym_name, table_name, table_owner
      from   sys.dba_synonyms
      where owner = v_apps_schema
      and    synonym_name = 'AD_PREPMODE_CHECK_FILES';

  begin

  -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure cleanup_chkfile_info');
    v_apps_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_apps_schema));

    for c_rec in c_syn loop

       EXECUTE IMMEDIATE 'TRUNCATE TABLE '||
                         c_rec.table_owner||'.'||c_rec.table_name;
    end loop;

    log_debug_message('End procedure cleanup_chkfile_info');
  end;

  procedure cleanup_spec_schema(X_spec_schema in varchar2) is

      v_spec_schema varchar2(30);

      TYPE spec_obj_type IS TABLE OF varchar2(128);
      TYPE spec_obj_name IS TABLE OF varchar2(30);
      spec_obj_type_tab   spec_obj_type;
      spec_obj_name_tab   spec_obj_name;

      i            binary_integer;
      l_sql_stmt   varchar2(2000);

  begin

  -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure cleanup_spec_schema ');
    v_spec_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_spec_schema));

     validate_schema(v_spec_schema, SPEC_SCHEMA_TYPE);

     print_timestamp('CLEANUP of Spec schema ('||
                     v_spec_schema||') started at   : ');


     begin

       select object_type, object_name
       bulk collect into spec_obj_type_tab, spec_obj_name_tab
       from sys.dba_objects
       where owner = v_spec_schema
       and object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL')
       and object_type not in ('INDEX', 'LOB INDEX', 'LOB');

     exception
       when NO_DATA_FOUND then
          null;
     end;

     --
     -- drop individual objects
     --
     for i in 1..spec_obj_name_tab.count
     loop
        begin

          l_sql_stmt := 'DROP '||spec_obj_type_tab(i)||
                       ' '||v_spec_schema||'."'||spec_obj_name_tab(i)||'"';
          EXECUTE IMMEDIATE l_sql_stmt;
        exception
          when others then
             println(l_sql_stmt);
             if (SQLCODE in (-950, -942, -1434, -4043)) then
                null;
             else
                raise;
             end if;
        end;
     end loop;

     print_timestamp('CLEANUP of Spec schema ('||
                     v_spec_schema||') completed at : ');
    log_debug_message('End procedure cleanup_spec_schema ');
  end;

  procedure cleanup_clone_schema(X_source_schema in varchar2,
                                 X_clone_schema  in varchar2,
                                 X_force_flag    in boolean,
                                 X_threads       in number) is
    l_force_str varchar2(10);
    TYPE clone_obj_type IS TABLE OF varchar2(128);
    TYPE clone_obj_name IS TABLE OF varchar2(30);
    clone_obj_type_tab   clone_obj_type;
    clone_obj_name_tab   clone_obj_name;

    i            binary_integer;
    l_sql_stmt   varchar2(2000);
    l_obj_count  number;
    v_source_schema varchar2(30);
    v_clone_schema varchar2(30);


  begin

     -- Sql Injection Bug 25248691
     log_debug_message('Begin procedure cleanup_clone_schema ');
     v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
     v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));

     l_force_str := 'FALSE';
     validate_schema(v_clone_schema, CLONE_SCHEMA_TYPE);

     print_timestamp('CLEANUP of Clone schema ('||
                     v_clone_schema||') started at   : ');

     if (X_force_flag = TRUE) then
       l_force_str := 'TRUE';
     end if;

     begin

       EXECUTE IMMEDIATE
          'begin '||
            '  sys.dbms_schema_copy.clean_target('||
                           ' dst_sch=>:a,'||
                           ' force=>'||l_force_str||','||
                           ' threads=>:c);'||
          'end;'
          USING IN v_clone_schema, X_threads;
     exception
        --
        -- handle case where the clone operation may have failed
        --
        when others then
           if (sqlcode = -39312) then
             EXECUTE IMMEDIATE
                'begin '||
                  '  sys.dbms_schema_copy.clean_failed_clone('||
                                 ' src_sch=>:a,'||
                                 ' dst_sch=>:b,'||
                           ' threads=>:c);'||
                'end;'
                USING IN v_source_schema, v_clone_schema, X_threads;
           else
              raise;
           end if;
     end;

     begin
        EXECUTE IMMEDIATE
                'begin '||
                  '  sys.dbms_schema_copy.clean_up('||
                                 ' src_sch=>:a,'||
                                 ' dst_sch=>:b);'||
                'end;'
                USING IN v_source_schema, v_clone_schema;
     exception
        when others then
          null;
     end;

     begin

       select object_type, object_name
       bulk collect into clone_obj_type_tab, clone_obj_name_tab
       from sys.dba_objects
       where owner = v_clone_schema
       and object_type not in ('INDEX', 'LOB INDEX', 'LOB')
       and object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL')
       order by decode(object_type, 'PACKAGE', 1, 'VIEW', 2,
                                    3);

     exception
       when NO_DATA_FOUND then
          null;
     end;

     println('Number of objects before the cleanup operation : '||
             clone_obj_name_tab.count);

     --
     -- drop individual objects
     --
     for i in 1..clone_obj_name_tab.count
     loop
        begin

          l_sql_stmt := 'DROP '||clone_obj_type_tab(i)||
                       ' '||v_clone_schema||'."'||clone_obj_name_tab(i)||'"';

          if (clone_obj_type_tab(i) in ('TYPE')) then
              l_sql_stmt := l_sql_stmt|| ' FORCE ';
          end if;

          if (clone_obj_type_tab(i) in ('DATABASE LINK')) then
             l_sql_stmt := 'DROP '||clone_obj_type_tab(i)||' "'||
                                    clone_obj_name_tab(i)||'"';

             EXECUTE IMMEDIATE
                   'BEGIN '||
                     v_clone_schema||'.'||'APPS_DDL.apps_ddl(:ddl_txt); '||
                   ' END; '
                   USING l_sql_stmt;

          else
             EXECUTE IMMEDIATE l_sql_stmt;
          end if;
        exception
          when others then
             dbms_output.put_Line(l_sql_stmt);
             println(l_sql_stmt);
             if (SQLCODE in (-950, -942, -1434, -4043)) then
                null;
             else
                raise;
             end if;
        end;
     end loop;

     select count(*)
     into   l_obj_count
     from   sys.dba_objects
     where  owner = X_clone_schema
     and    object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL');

     println('Number of objects remaining after the cleanup operation : '||
             l_obj_count);

     print_timestamp('CLEANUP of Clone schema ('||
                      v_clone_schema||') completed at : ');
     log_debug_message('End procedure cleanup_clone_schema ');
  end;

  procedure clean_up(X_source_schema        in varchar2,
                     X_clone_schema         in varchar2,
                     X_spec_schema          in varchar2,
                     X_degree               in number  default null,
                     X_cleanup_clone        in boolean default FALSE,
                     X_cleanup_spec         in boolean default FALSE)
  is
     l_status varchar2(30);
     l_phase  varchar2(30);
     v_source_schema varchar2(30);
     v_clone_schema varchar2(30);
     v_spec_schema varchar2(30);

  begin

    -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure clean_up ');
    v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
    v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));
    v_spec_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_spec_schema));

    validate_schema(v_clone_schema, CLONE_SCHEMA_TYPE);
    validate_schema(v_spec_schema,  SPEC_SCHEMA_TYPE);

    if (native_clone_supported = TRUE) then

       get_status(v_source_schema, v_clone_schema,
                  l_phase, l_status);

       print_timestamp('CLEANUP operation started   at : ');

       --
       -- cleanup spec, if required
       --
       if (X_cleanup_spec = TRUE) then
          cleanup_spec_schema(X_spec_schema);
       end if;

       --
       -- cleanup the target, if required
       --
       if (X_cleanup_clone = TRUE) then
          cleanup_clone_schema(v_source_schema, v_clone_schema, TRUE, X_degree);
       end if;

       begin
          EXECUTE IMMEDIATE
             'begin '||
             '  sys.dbms_schema_copy.clean_up('||
                            'src_sch=>:a,  '||
                            'dst_sch=>:b); '||
             'end;'
             USING IN v_source_schema, v_clone_schema;
       exception
         when others then
           -- 39307 : operation illegal with initial clone
           if (SQLCODE = -39307) then
              null;
           else
              raise;
           end if;
       end;

       print_timestamp('CLEANUP operation completed at : ');

    end if;
    log_debug_message('End procedure clean_up ');
  end;

  procedure get_status(X_source_schema       in varchar2,
                       X_clone_schema        in varchar2,
                       X_clone_phase        out NOCOPY varchar2,
                       X_clone_status       out NOCOPY varchar2)
  is
    type t_status     is table of varchar2(30)  index by binary_integer;
    type t_status_msg is table of varchar2(100) index by binary_integer;
    type StatusCurTyp is ref cursor;

    stat_c  StatusCurTyp;
    l_stmt  varchar2(300);
    l_status  t_status;
    l_message t_status_msg;
    v_source_schema varchar2(30);
    v_clone_schema varchar2(30);


  begin

   -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure get_status ');
    v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
    v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));

    if (native_clone_supported = FALSE) then
      begin
         ad_apps_private.check_for_apps_ddl(v_clone_schema);

         X_clone_phase  := 'CLONE';
         X_clone_status := 'COMPLETE';
      exception
         when others then
            X_clone_phase  := UNKNOWN_PHASE;
            X_clone_status := STATUS_UNKNOWN;
      end;

      return;
    end if;

    l_stmt := 'select status, message '||
              'from sys.dbms_upg_status$ s '||
              'where source_schema = :v_source_schema '||
              'and   target_schema = :x_target_schema '||
              'and ( status like ''CLONE%'' or '||
              '      status like ''SWAP%'') '||
              'order by sequence# desc';

    open stat_c for l_stmt using v_source_schema, v_clone_schema;

    X_clone_phase  := UNKNOWN_PHASE;
    X_clone_status := STATUS_UNKNOWN;

    loop

      fetch stat_c bulk collect into l_status, l_message limit 100;
      exit when l_status.count = 0;

      for i IN l_status.FIRST..l_status.LAST loop
        --
        -- exit the loop on first occurrence of CLONE or SWAP (COMPLETED)
        --
        if (l_status(i) like 'CLONE%')
        then
           X_clone_phase := CLONE_PHASE;

           if (l_message(i) = 'CLONE COMPLETED')
           then
              X_clone_status := STATUS_COMPLETED;
           elsif (l_message(i) = 'CLONE IN PROGRESS') then
              X_clone_status := STATUS_INPROGRESS;
           elsif (l_message(i) = 'CLONE FAILED') then
              X_clone_status := STATUS_FAILED;
           else
              X_clone_status := STATUS_INCOMPLETE;
           end if;
           exit;
        end if;

        if (l_status(i) like 'SWAP%')
        then
           X_clone_phase := MERGE_PHASE;

           if (l_message(i) = 'SWAP COMPLETED')
           then
              X_clone_status := STATUS_COMPLETED;
           else
              X_clone_status := STATUS_INCOMPLETE;
           end if;
           exit;
        end if;
      end loop;
    end loop;

    close stat_c;

    log_debug_message('End procedure get_status ');
  end;

  procedure is_phase_complete(X_source_schema in  varchar2,
                              X_clone_schema  in  varchar2,
                              X_phase_name    in  varchar2,
                              X_complete_flag out NOCOPY varchar2)
  is
    l_phase   varchar2(30);
    l_status  varchar2(30);
    v_source_schema varchar2(30);
    v_clone_schema varchar2(30);

  begin

   -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure is_phase_complete ');
    v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
    v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));

     if (X_phase_name not in (CLONE_PHASE, MERGE_PHASE)) then
        raise_application_error(-20001, 'Unknown phase : '||X_phase_name);
     end if;

     X_complete_flag := 'N';

     get_status(v_source_schema,
                v_clone_schema,
                l_phase, l_status);

     if (l_phase = X_phase_name) then
       if (l_status = STATUS_COMPLETED) then
          X_complete_flag := 'Y';
       else
          X_complete_flag := 'N';
       end if;
     end if;
    log_debug_message('End procedure is_phase_complete ');

  end;

  procedure create_schema(X_schema_un   in varchar2,
                          X_schema_pw   in varchar2,
                          X_tablespace  in varchar2)
  is
    v_schema_un varchar2(30);
    v_schema_pw varchar2(30);

  begin

   -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure create_schema ');
    v_schema_un := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_schema_un));
    v_schema_pw := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_schema_pw));

     EXECUTE IMMEDIATE ' create user '||v_schema_un||
                       ' identified by '||v_schema_pw||
                       ' default tablespace '||X_tablespace;

     EXECUTE IMMEDIATE 'grant connect, resource to '||v_schema_un;

  exception
    when others then
      if (sqlcode = -1920) then
         --
         -- make sure that CLONE schema has the correct password
         --
         EXECUTE IMMEDIATE 'alter user '||v_schema_un||' identified by '||
                                          v_schema_pw||
                           ' default tablespace '||X_tablespace;
      else
         raise;
      end if;
    log_debug_message('End procedure create_schema ');
  end;

  procedure repoint_synonyms(X_source_schema  in varchar2,
                             X_clone_schema   in varchar2,
                             X_spec_schema    in varchar2)
  is
    type t_objname  is table of varchar2(30)  index by binary_integer;

    l_syntab   t_objname;
    l_tabtab   t_objname;
    l_owntab   t_objname;
    v_source_schema varchar2(30);
    v_clone_schema varchar2(30);
    v_spec_schema varchar2(30);

    cursor c_syn is
      select synonym_name, table_name, table_owner
      from   sys.dba_synonyms src
      where  src.owner = v_source_schema
      and    src.synonym_name in (
        select cl.synonym_name
        from   sys.dba_synonyms cl
        where  cl.owner = v_clone_schema
        and    cl.table_owner = v_spec_schema);

  begin

   -- Sql Injection Bug 25248691
    log_debug_message('Begin procedure repoint_synonyms ');
    v_source_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_source_schema));
    v_clone_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_clone_schema));
    v_spec_schema := sys.dbms_assert.simple_sql_name(sys.dbms_assert.schema_name(X_spec_schema));

    open c_syn;

    loop
      fetch c_syn bulk collect into l_syntab, l_tabtab, l_owntab limit 1000;

       exit when l_syntab.count = 0;

       for i in 1..l_syntab.last loop

          EXECUTE IMMEDIATE 'CREATE OR REPLACE SYNONYM '||
                            v_clone_schema||'.'||l_syntab(i)||
                            ' FOR '||l_owntab(i)||'.'||l_tabtab(i);
       end loop;

    end loop;
    log_debug_message('End procedure repoint_synonyms ');
  end;


begin
  g_db_version := get_db_version;

  if (g_db_version like '10%') then
    native_clone_supported := TRUE;
  end if;

  if (to_number(substr(g_db_version,
                       1, instr(g_db_version, '.', 1, 2) -1)) > 9.2) then
    dbms_metadata_supported := TRUE;
  end if;
end;
