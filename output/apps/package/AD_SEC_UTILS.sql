
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_SEC_UTILS" authid current_user as
  /* $Header: ADSECUTILSS.pls 120.0.12020000.8 2022/06/13 04:40:18 rsatyava noship $ */
$IF (ad_db_info.is_adb) $THEN

  /*
	** GRANT_ON_APPS_NE_TYPE_TO_EBS
	** X_TYPE_NAME  - Type name owned by APPS_NE
  ** Grants execute privileges on apps_ne type to ebs schemas.
	*/
  procedure GRANT_PRIV_ON_APPS_NE_TYPE(X_TYPE_NAME  in varchar2);
$ELSE
  /*
	** GRANT_ON_APPS_NE_TYPE_TO_EBS
	** X_TYPE_NAME  - Type name owned by APPS_NE
  ** Grants execute privileges on apps_ne type to ebs schemas.
	*/
  procedure GRANT_PRIV_ON_APPS_NE_TYPE(X_TYPE_NAME  in varchar2);

 /*
 ** FIX_SYSTEM_OWNED_NE_TYPE
 ** X_TYPE_NAME - type name
 ** This procedure must be invoked as cutover ddl
 ** to fix system owned non editionable type references
 ** in tables and/or in advanced queues
 */
  procedure FIX_SYSTEM_OWNED_NE_TYPE(X_TYPE_NAME in varchar2);

  /*
	** REMOVE_XML_SCHEMA
	** X_SCHEMA_URL - URL identifying the XML schema to be deleted
	** This api is invoked as cleanup ddl to remove XML schema
	**
 	*/
  procedure REMOVE_XML_SCHEMA(X_SCHEMA_URL in varchar2);
$end

end AD_SEC_UTILS;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_SEC_UTILS" as
/* $Header: ADSECUTILSB.pls 120.0.12020000.16 2023/02/28 06:00:07 rsatyava noship $ */
$if (ad_db_info.is_adb) $then
  /*
  ** log message
  */
  procedure LOG (X_MODULE in varchar2,X_LOG_TYPE in varchar2,X_MESSAGE in varchar2)
  is
    begin
      ad_zd_log.message(x_module => x_module,x_log_type => x_log_type,x_message => x_message);
  end;

  /*
  ** IS_TYPE_EXISTS
  ** X_OWNER
  ** X_NAME
  ** X_TYPE_LIST
  ** Utility function to check whether a given type exists or not in a schema
  */
  function IS_TYPE_EXISTS (X_OWNER varchar2, X_NAME varchar2 ) return boolean
  is
    L_OBJ_CNT pls_integer :=0;
  begin

    select count(*) into l_obj_cnt
    from   dba_types o
    where  owner=x_owner
    and    type_name=x_name;

    if(l_obj_cnt > 0 ) then
      return true;
    else
      return false;
    end if;

  end IS_TYPE_EXISTS;

  /*
  ** EXEC
  ** X_SQL     - statement to execute
  ** X_LOG_MOD - calling module (for logging)
  ** X_IGNORE  - ignore errors
  ** This procedure executes dynamic sql statement
  */
  procedure EXEC(X_SQL       IN CLOB,
                 X_LOG_MOD   IN VARCHAR2,
                 X_IGNORE    IN BOOLEAN DEFAULT FALSE
                )
  is

    SUCCESS_WITH_COMPILATION_ERROR exception;
    pragma exception_init(success_with_compilation_error, -24344);

    DEADLOCK_DETECTED_ERROR exception;
    pragma exception_init(deadlock_detected_error, -00060);

    L_CUR integer;
    L_RET integer;
    C_MODULE   varchar2(80) := 'ad.plsql.ad_sec_utils.exec';

  begin
    log(x_log_mod, 'STATEMENT', 'SQL(CLOB): '||substrb(dbms_lob.substr(x_sql, 3900),1,3900));

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
      log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM||', SQL: '||substrb(dbms_lob.substr(x_sql, 3900),1,3900));
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
     -- ignore or raise other errors as requested
    if x_ignore then
      log(x_log_mod, 'STATEMENT', 'Ignored: '||SQLERRM);
    else
      log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM||', SQL(CLOB): '||substrb(dbms_lob.substr(x_sql, 3900),1,3900));
      raise;
    end if;
  end EXEC;

  /*
   ** GRANT_PRIV_ON_APPS_NE_TYPE
   ** X_TYPE_NAME  - Type name owned by APPS_NE
   ** Grants execute privileges on APPS_NE type to ebs schemas.
  */
  procedure GRANT_PRIV_ON_APPS_NE_TYPE (X_TYPE_NAME in varchar2)
  is
    C_MODULE          varchar2(80) := 'ad.plsql.ad_sec_utils.grant_execute_on_type_to_ebs';
    L_GRANT_STMT      varchar2(1000);
    L_APPS_DDL_STMT   varchar2(10000);
    L_EXISTS          varchar2(1);
    L_APPS_NE_SCHEMA  varchar2(30) := 'APPS_NE';
    L_TYPE_NAME       varchar2(30)  ;
    --cursor to retrieve ebs schemas
    cursor C_EBS_SCHEMA is
    select trim(oracle_username) oracle_username
    from   fnd_oracle_userid
    where  read_only_flag in ('A','B','C','E','U')
    and oracle_username in (select username from dba_users)
    order  by 1;
  begin
    log(c_module,'PROCEDURE','begin x_type_name is '||x_type_name);
    --Convert Type name to Upper case
    l_type_name :=upper(x_type_name);
    --l_type_name validation checks
    if(l_type_name is null) then
      log(c_module,'ERROR','type name cannot be null');
      raise_application_error(-20002,'type name cannot be null');
      --Check if x_type_name exists in APPS_NE schema or not
    elsif(NOT(is_type_exists(l_apps_ne_schema,l_type_name))) then
      log(c_module,'ERROR','type "'||  l_apps_ne_schema|| '"."'|| l_type_name|| '" does not exist in database');
      raise_application_error(-20001,'type "'||  l_apps_ne_schema|| '"."'|| l_type_name|| '" does not exist in database');
    end if;

    -- grant execute privilege on apps_ne type to ebs schema
    for ebs_schema_list in c_ebs_schema loop
      l_grant_stmt := 'grant execute on "'|| l_apps_ne_schema|| '"."'|| l_type_name|| '" to '|| ebs_schema_list.oracle_username;
      log(c_module,'STATEMENT','granting execute on  '|| l_apps_ne_schema|| '"."'|| l_type_name|| '" to '|| ebs_schema_list.oracle_username);
      l_apps_ddl_stmt := 'begin '|| l_apps_ne_schema|| '.apps_ddl.apps_ddl(:l_grant_stmt); end;';
      execute immediate l_apps_ddl_stmt using l_grant_stmt;
    end loop;

    log(c_module,'PROCEDURE','end');
  end GRANT_PRIV_ON_APPS_NE_TYPE;


$else
  /*
  ** log message
  */
  procedure LOG (X_MODULE in varchar2,X_LOG_TYPE in varchar2,X_MESSAGE in varchar2)
  is
    begin
      ad_zd_log.message(x_module => x_module,x_log_type => x_log_type,x_message => x_message);
  end;

  /*
   ** SERVER_OUTPUT
   ** Enable or disable the dbms_output
  */
  procedure SERVER_OUTPUT (X_STATUS in varchar2)
  is
  begin
    if ( x_status = 'ENABLE' ) then
      dbms_output.enable(buffer_size => null);
    else
      dbms_output.disable;
    end if;
  end;

  /*
  ** log_server_output
  ** This is being used to capture dbms_output messages coming from
  ** st apis, like sys.dbms_objects_apps_utils.recompile_types
  */
  procedure LOG_SERVER_OUTPUT (X_MODULE in varchar2,X_LOG_TYPE in varchar2)
  is
    L_LINESARRAY   dbmsoutput_linesarray;
    L_NUMLINES     integer;
  begin
    dbms_output.get_lines(l_linesarray,l_numlines);
    for i in 1..l_linesarray.count loop
      if ( l_linesarray(i) is not null ) then
        log(x_module,x_log_type,l_linesarray(i) );
      end if;
    end loop;
  exception
    when others then
      null;
  end;

  /*
  ** IS_TYPE_EXISTS
  ** X_OWNER
  ** X_NAME
  ** X_TYPE_LIST
  ** Utility function to check whether a given type exists or not in a schema
  */
  function IS_TYPE_EXISTS (X_OWNER varchar2, X_NAME varchar2 ) return boolean
  is
    L_OBJ_CNT pls_integer :=0;
  begin

    select count(obj#) into l_obj_cnt
    from   sys.obj$ o
    where  owner# =(select user# from sys.user$ where name = x_owner)
    and    o.NAME = x_name
    and    o.type# = 13;

    if(l_obj_cnt > 0 ) then
      return true;
    else
      return false;
    end if;

  end IS_TYPE_EXISTS;

  /*
  ** EXEC
  ** X_SQL     - statement to execute
  ** X_LOG_MOD - calling module (for logging)
  ** X_IGNORE  - ignore errors
  ** This procedure executes dynamic sql statement
  */
  procedure EXEC(X_SQL       IN CLOB,
                 X_LOG_MOD   IN VARCHAR2,
                 X_IGNORE    IN BOOLEAN DEFAULT FALSE
                )
  is

    SUCCESS_WITH_COMPILATION_ERROR exception;
    pragma exception_init(success_with_compilation_error, -24344);

    DEADLOCK_DETECTED_ERROR exception;
    pragma exception_init(deadlock_detected_error, -00060);

    L_CUR integer;
    L_RET integer;
    C_MODULE   varchar2(80) := 'ad.plsql.ad_sec_utils.exec';

  begin
    log(x_log_mod, 'STATEMENT', 'SQL(CLOB): '||substrb(dbms_lob.substr(x_sql, 3900),1,3900));

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
      log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM||', SQL: '||substrb(dbms_lob.substr(x_sql, 3900),1,3900));
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
     -- ignore or raise other errors as requested
    if x_ignore then
      log(x_log_mod, 'STATEMENT', 'Ignored: '||SQLERRM);
    else
      log(x_log_mod, 'ERROR', 'ERROR: '||SQLERRM||', SQL(CLOB): '||substrb(dbms_lob.substr(x_sql, 3900),1,3900));
      raise;
    end if;
  end EXEC;

  /*
   ** GRANT_PRIV_ON_APPS_NE_TYPE
   ** X_TYPE_NAME  - Type name owned by APPS_NE
   ** Grants execute privileges on APPS_NE type to ebs schemas.
  */
  procedure GRANT_PRIV_ON_APPS_NE_TYPE (X_TYPE_NAME in varchar2)
  is
    C_MODULE          varchar2(80) := 'ad.plsql.ad_sec_utils.grant_execute_on_type_to_ebs';
    L_GRANT_STMT      varchar2(1000);
    L_APPS_DDL_STMT   varchar2(10000);
    L_EXISTS          varchar2(1);
    L_APPS_NE_SCHEMA  varchar2(30) := 'APPS_NE';
    L_TYPE_NAME       varchar2(30)  ;
    --cursor to retrieve ebs schemas
    cursor C_EBS_SCHEMA is
    select trim(oracle_username) oracle_username
    from   fnd_oracle_userid
    where  read_only_flag in ('A','B','C','E','U')
    and oracle_username in (select username from dba_users)
    order  by 1;
  begin
    log(c_module,'PROCEDURE','begin x_type_name is '||x_type_name);
    --Convert Type name to Upper case
    l_type_name :=upper(x_type_name);
    --l_type_name validation checks
    if(l_type_name is null) then
      log(c_module,'ERROR','type name cannot be null');
      raise_application_error(-20002,'type name cannot be null');
      --Check if x_type_name exists in APPS_NE schema or not
    elsif(NOT(is_type_exists(l_apps_ne_schema,l_type_name))) then
      log(c_module,'ERROR','type "'||  l_apps_ne_schema|| '"."'|| l_type_name|| '" does not exist in database');
      raise_application_error(-20001,'type "'||  l_apps_ne_schema|| '"."'|| l_type_name|| '" does not exist in database');
    end if;

    -- grant execute privilege on apps_ne type to ebs schema
    for ebs_schema_list in c_ebs_schema loop
      l_grant_stmt := 'grant execute on "'|| l_apps_ne_schema|| '"."'|| l_type_name|| '" to '|| ebs_schema_list.oracle_username;
      log(c_module,'STATEMENT','granting execute on  '|| l_apps_ne_schema|| '"."'|| l_type_name|| '" to '|| ebs_schema_list.oracle_username);
      l_apps_ddl_stmt := 'begin '|| l_apps_ne_schema|| '.apps_ddl.apps_ddl(:l_grant_stmt); end;';
      execute immediate l_apps_ddl_stmt using l_grant_stmt;
    end loop;

    log(c_module,'PROCEDURE','end');
  end GRANT_PRIV_ON_APPS_NE_TYPE;

  /*
  ** STOP_QUEUE
  ** X_QUEUE_NAME
  ** Procedure to stop an advanced queue
  */
  procedure STOP_QUEUE (X_QUEUE_NAME in varchar2)
  is
    C_MODULE          varchar2(80) := 'ad.plsql.ad_sec_utils.stop_queue';
  begin
    log(c_module,'PROCEDURE','begin: ' || x_queue_name);
    exec('begin dbms_aqadm.stop_queue('''|| x_queue_name|| '''); end;', c_module);
    log(c_module,'PROCEDURE','end');
  end STOP_QUEUE;

  /*
  ** START_QUEUE
  ** X_QUEUE_NAME
  ** Procedure to start an advanced queue
  */
  procedure START_QUEUE (x_queue_name in varchar2)
  is
    C_MODULE          varchar2(80) := 'ad.plsql.ad_sec_utils.start_queue';
  begin
    log(c_module,'PROCEDURE','begin: ' || x_queue_name);
    exec('begin dbms_aqadm.start_queue('''|| x_queue_name||'''); end;', c_module);
    log(c_module,'PROCEDURE','end');
  end START_QUEUE;

  /*
  ** RECREATE_AQ_OBJECT
  ** X_OWNER
  ** X_TABLE
  ** Procedure to recreate recreate associated objects of an advanced queue
  ** after fixing the type references
  */
  procedure RECREATE_AQ_OBJECT (X_OWNER in varchar2,X_TABLE in varchar2)
  is
    C_MODULE        varchar2(80) := 'ad.plsql.ad_sec_utils.recreate_aq_object';
    L_QT_FLAGS      number;
    L_SORT_COLS     number;
    L_SORT_BY_EQT   boolean;
    l_flags         number;

    cursor C_QUEUES is
    select aq.name,aq.queue_type
    from   dba_queues aq
    where  aq.owner = x_owner
    and    aq.queue_table = x_table;

  begin
    log(c_module,'PROCEDURE','begin: '|| x_owner|| '.'|| x_table);

    begin
      $IF (DBMS_DB_VERSION.VERSION >= 23) $THEN
         -- RDBMS BUG 34886366 - DB23C: PLS-00904: INSUFFICIENT PRIVILEGE TO ACCESS OBJECT CREATE_BASE_VIEW
        log(c_module, 'EVENT',
               'Call dbms_aqadm.migrate_queue_table('|| x_owner||'.'||x_table||', '|| l_qt_flags||')');
        l_flags := DBMS_AQADM.CREATE_QT_BASE_VIEW;
        dbms_aqadm.migrate_queue_table('x_owner'||'.'||'x_table',l_flags);
      $ELSE
        -- Regenerate derived objects
        select  flags,sort_cols
        into    l_qt_flags,l_sort_cols
        from    system.aq$_queue_tables
        where   schema = x_owner
        and     name = x_table;

        if l_sort_cols = 2 or l_sort_cols = 3 or l_sort_cols = 7 then
        l_sort_by_eqt := true;
        else
          l_sort_by_eqt := false;
        end if;

        sys.dbms_aqadm_sys.patch_queue_table(x_owner,x_table,l_qt_flags,l_sort_by_eqt,true);

        if ( sys.dbms_aqadm_sys.mcq_8_1(l_qt_flags) ) then
          -- for new multiconsumer queue (8.1 style and above)
          sys.dbms_aqadm_sys.create_buffer_view(x_owner,x_table,true);
          log(c_module,'EVENT','call sys.dbms_prvtaqim.create_base_view('|| x_owner|| ', '|| x_table|| ', '|| l_qt_flags|| ')');
          sys.dbms_prvtaqim.create_base_view(x_owner,x_table,l_qt_flags);
        else
          --  only for 8.0 style queues
          log(c_module,'EVENT','call sys.dbms_aqadm_sys.create_base_view('|| x_owner|| ', '|| x_table|| ', '|| l_qt_flags|| ')');
          sys.dbms_aqadm_sys.create_base_view(x_owner,x_table,l_qt_flags);
        end if;

      $END
    exception
      when others then
        log(c_module,'ERROR','error: '|| x_owner|| '.'|| x_table|| ' '|| substr(sqlerrm,1,2000) );
    end;
    for queue in c_queues loop
      if ( queue.queue_type = 'NORMAL_QUEUE' ) then
        start_queue('"'|| x_owner ||'"."'|| queue.name || '"');
      end if;
    end loop;

    log(c_module,'PROCEDURE','end');
  exception
    when no_data_found then
      null;
  end RECREATE_AQ_OBJECT;

  /*
  ** FIX_TYPE
  **
  ** X_TYPE_OWNER - Type owner
  ** X_TYPE_NAME  - Type name
  ** This procedure will fix system owned non editionable type references
  ** in tables and/or in advanced queues.
  ** Update table references to non editioned type if needed
  ** Convert dependant types, if needed
  ** Drop type, replace with synonym to non editioned type
  */
  procedure FIX_TYPE (X_TYPE_OWNER varchar2,X_TYPE_NAME varchar2)
  is
    C_MODULE           varchar2(80) := 'ad.plsql.ad_sec_utils.fix_type';
    L_REF_OWNER        varchar2(30);
    L_REF_NAME         varchar2(30);
    L_FOUND            boolean;
    L_APPS_DDL_STMT    varchar2(10000);
    L_APPS_NE_SCHEMA   varchar2(30) := 'APPS_NE';

    -- tables that reference the specified type
    cursor C_TABLE_REFS (TYPE_OWNER varchar2,TYPE_NAME varchar2)
    is
    select dep.owner,
           dep.name
    from   dba_dependencies dep
    where  dep.type = 'TABLE'
    and    dep.referenced_owner = type_owner
    and    dep.referenced_name = type_name
    and    dep.referenced_type = 'TYPE';

    -- types that reference the specified type and have a replacement in apps_ne
    cursor C_TYPE_REFS (XX_TYPE_OWNER varchar2,XX_TYPE_NAME varchar2) is
    select ot.owner,
       ot.name
    from   dba_dependencies ot,
           dba_types nt
    where  ot.type = 'TYPE'
    and    ot.referenced_owner = xx_type_owner
    and    ot.referenced_name = xx_type_name
    and    ot.referenced_type = 'TYPE'
    and    nt.owner = l_apps_ne_schema
    and    nt.type_name = ot.name;
    -- tables that references the specific type or its dependent type
    cursor C_TABLE_REFS2 (TYPE_OWNER varchar2,TYPE_NAME varchar2) is
    select dep.owner,
           dep.name
    from   dba_dependencies dep
    where  dep.type = 'TABLE'
    and    dep.referenced_owner <> l_apps_ne_schema
    start with dep.referenced_owner = type_owner
    and    dep.referenced_name = type_name
    and    dep.referenced_type = 'TYPE'
    connect by nocycle prior dep.owner = dep.referenced_owner
    and prior dep.name = dep.referenced_name
    and prior dep.type = dep.referenced_type;

  begin
    log(c_module,'PROCEDURE','begin: '|| x_type_owner|| '.'|| x_type_name);
    -- check for table references to type
    open c_table_refs(x_type_owner,x_type_name);
      fetch c_table_refs into l_ref_owner,
                              l_ref_name;
      l_found := c_table_refs%found;
    close c_table_refs;
    --If any table references to type are found,they need to be fixed
    if l_found then
      -- update column types to new owner
      -- note: "check_update" paremeter must be false for single type update
      log(c_module,'EVENT','fixing table references to '|| x_type_owner|| '.'|| x_type_name);
      server_output('enable');
      sys.dbms_objects_apps_utils.update_types(schema1      => x_type_owner,
                                               schema2      => l_apps_ne_schema,
                                               typename     => x_type_name,
                                               check_update => false ) ;
     log_server_output('sys.dbms_objects_apps_utils.update_types','statement');
     execute immediate 'alter system flush shared_pool';
     commit;
     -- re-check for table references to type
     open c_table_refs(x_type_owner,x_type_name);
       fetch c_table_refs into    l_ref_owner,l_ref_name;
         l_found := c_table_refs%found;
     close c_table_refs;
     -- if there are still references to the type, then we have failed
     if l_found then
        log(c_module,'ERROR','could not fix table references to '|| x_type_owner|| '.'|| x_type_name);
        raise_application_error(-20978, 'could not fix table references to '||x_type_owner||'.'||x_type_name);
     end if;
    end if;
    -- recursively drop any types that depend on this type and have ne replacements
    for l_types in c_type_refs(x_type_owner,x_type_name) loop
      log(c_module,'STATEMENT','fixing type reference: '|| l_types.owner|| '.'|| l_types.name);
      fix_type(l_types.owner,l_types.name);
    end loop;
    -- verify type still exists (could be missing now due to concurrent threads)
    if is_type_exists(x_type_owner,x_type_name) then
      -- make sure no table references to type or its dependent types
      open c_table_refs2(x_type_owner,x_type_name);
        fetch c_table_refs2 into l_ref_owner,l_ref_name;
        l_found := c_table_refs2%found;
      close c_table_refs2;
      -- if there are still references to the type or its dependent types, then we have failed
      if l_found then
         log(c_module,'ERROR','could not fix table references to '|| x_type_owner|| '.'|| x_type_name);
         raise_application_error(-20978, 'could not fix table references to '||x_type_owner||'.'||x_type_name);
      end if;
    end if;
    log(c_module,'PROCEDURE','end');
  end FIX_TYPE;

   /*
   ** FIX_SYSTEM_OWNED_NE_TYPE
   **
   ** X_TYPE_NAME - type name
   ** This procedure must be invoked as cutover ddl
   ** to fix system owned non editionable type references
   ** in tables and/or in advanced queues
   */
  procedure FIX_SYSTEM_OWNED_NE_TYPE (X_TYPE_NAME in varchar2)
  is
    C_MODULE                varchar2(80) := 'ad.plsql.ad_sec_utils.fix_system_owned_ne_type';
    L_TYPE_OWNER            varchar2(30) := 'SYSTEM';
    L_TYPE_NAME             varchar2(30);
    L_QTBL_OBJ_TYPE         varchar2(50);
    L_QUEUE_COUNT           number;
    L_QUEUE_NAME            varchar2(80);
    type UDT_QNAME_REC      is record  (queue_name  varchar2(80));
    type UDT_QNAME_TBL      is table of udt_qname_rec index by binary_integer;
    type UDT_QTBL_REC       is record (qtbl_owner varchar2(30),
                                       qtbl_name  varchar2(30),
                                       qname_tbl udt_qname_tbl);
    type UDT_QTBL_TBL       is table of udt_qtbl_rec index by binary_integer;
    L_UDT_QNAME_TBL         udt_qname_tbl;
    L_UDT_TEMP_QNAME_TBL    udt_qname_tbl;
    L_UDT_QNAME_TBL_EMPTY   udt_qname_tbl;
    L_UDT_QTBL_TBL          udt_qtbl_tbl;
    L_UDT_QTBL_TBL_INDX     pls_integer := 0;
    L_UDT_QNAME_TBL_INDX    pls_integer := 0;
    L_OBJ_LIST_TO_RECOMPILE sys.dbms_objects_utils_tnamearr := sys.dbms_objects_utils_tnamearr();

    --Cursor to identify all the queue tables referencing system owned type
    cursor C_QTBLS_REF_SYSTEM_OWNED_TYPE (L_QTBL_OBJ_TYPE varchar2) is
    select qt.owner table_owner,
           qt.queue_table table_name
    from   dba_queue_tables qt
    where  qt.owner in (select oracle_username
                        from fnd_oracle_userid fu
                        where fu.read_only_flag in ('A','B', 'E', 'U', 'C')
                       )
    and    qt.type  = 'OBJECT'
    and    qt.object_type = l_qtbl_obj_type;

    --Retrieves the advanced queue details
    cursor C_QUEUES (X_OWNER varchar2,X_TABLE varchar2) is
    select '"'|| aq.owner|| '"."'|| aq.name|| '"'
    from   dba_queues aq
    where  aq.owner = x_owner
    and    aq.queue_table = x_table;

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

  begin
    log(c_module,'PROCEDURE','begin: '|| l_type_owner|| '.'|| x_type_name);

    --Convert Type name to Upper case
    l_type_name := upper(x_type_name);
    --x_type_name validation checks
    if(l_type_name is null) then
      log(c_module,'ERROR','type name cannot be null');
      raise_application_error(-20002,'type name cannot be null');
    elsif(NOT(is_type_exists(l_type_owner,l_type_name))) then
      log(c_module,'ERROR','type "'|| l_type_owner|| '"."'|| l_type_name|| '" does not exist in database');
      raise_application_error(-20001,'type "'|| l_type_owner|| '"."'|| l_type_name|| '" does not exist in database');
    end if;
    --initialize the queue table object type
    l_qtbl_obj_type :=l_type_owner||'.'||l_type_name;

    --Populate the system owned non editionable type in the obj list to compile
    l_obj_list_to_recompile.extend;
    l_obj_list_to_recompile(l_obj_list_to_recompile.last):= sys.dbms_objects_utils_tname( l_type_owner,l_type_name);
    -- Populate obj list to compile with types that reference the system owned non editionable udt and have a replacement in APPS_NE
    for l_ref_types in c_type_refs(l_type_owner,l_type_name) loop
      l_obj_list_to_recompile.extend;
      l_obj_list_to_recompile(l_obj_list_to_recompile.last):= sys.dbms_objects_utils_tname( l_ref_types.owner, l_ref_types.name);
    end loop;

    --we need to re compile the system owned non editionable type and all the referenced types in system schema
    --to avoid structural sanity check failed error
    if(l_obj_list_to_recompile is not null and l_obj_list_to_recompile.count > 0 ) then
      log(c_module, 'EVENT', 'Recompiling User-Defined-Types from source schema to get'||' 11g database compatible hash-code ');
      server_output('ENABLE');
      sys.dbms_objects_apps_utils.recompile_types(names=> l_obj_list_to_recompile);
      log_server_output('sys.dbms_objects_apps_utils.recompile_types', 'STATEMENT');
      server_output('DISABLE');
    end if;
    --Loop through all the tables referencing system owned type and populate the advanced queue details (if there any)
    for l_tbl_rec in c_qtbls_ref_system_owned_type(l_qtbl_obj_type) loop
      --Set the l_udt_qname_tbl to empty collection and index to 0
      l_udt_qname_tbl_indx := 0;
      l_udt_qname_tbl      := l_udt_qname_tbl_empty;
      --For the Advanced queues referencing the UDTS,populate l_udt_qname_tbl
      open c_queues(l_tbl_rec.table_owner,l_tbl_rec.table_name);
        fetch c_queues into l_queue_name;
          while ( c_queues%found )
          loop
            log(c_module,'EVENT','loading queue details for the type '||l_tbl_rec.table_owner||'.'||l_tbl_rec.table_name);
            l_udt_qname_tbl_indx :=l_udt_qname_tbl_indx+1;
            l_udt_qname_tbl(l_udt_qname_tbl_indx).queue_name := l_queue_name;
            fetch c_queues into l_queue_name;
          end loop;
      close c_queues;
      --populate the advanced queue tbl details (if there any)
      if(l_udt_qname_tbl is not null and l_udt_qname_tbl.count > 0) then
        l_udt_qtbl_tbl_indx := l_udt_qtbl_tbl_indx + 1;
        l_udt_qtbl_tbl(l_udt_qtbl_tbl_indx).qtbl_owner := l_tbl_rec.table_owner;
        l_udt_qtbl_tbl(l_udt_qtbl_tbl_indx).qtbl_name := l_tbl_rec.table_name;
        l_udt_qtbl_tbl(l_udt_qtbl_tbl_indx).qname_tbl := l_udt_qname_tbl;
      end if;
    end loop;

    --Looping through the advanced queue tbls referencing system owned udts
    for qtblidx in 1..l_udt_qtbl_tbl.count loop
      l_udt_temp_qname_tbl := l_udt_qtbl_tbl(qtblidx).qname_tbl ;
      --looping through the associated queues to stop the queues
      if( l_udt_temp_qname_tbl is not null) then
        for qnameidx in 1..l_udt_temp_qname_tbl.count loop
        log(c_module,'EVENT','stopping queue ' || l_udt_temp_qname_tbl(qnameidx).queue_name);
        stop_queue(l_udt_temp_qname_tbl(qnameidx).queue_name);
        end loop;
      end if;
    end loop;

    --fix type references
    log(c_module,'EVENT','fixing table references for '|| l_type_owner|| '.'|| l_type_name);
    fix_type(l_type_owner,l_type_name);
    --recreate associated objects of an advanced queue after fixing the type references
    for idx in 1..l_udt_qtbl_tbl.count loop
     log(c_module,'EVENT','Recreating AQ Object for  '|| l_udt_qtbl_tbl(idx).qtbl_owner|| '.'|| l_udt_qtbl_tbl(idx).qtbl_name);
     recreate_aq_object(l_udt_qtbl_tbl(idx).qtbl_owner,l_udt_qtbl_tbl(idx).qtbl_name);
    end loop;

    log(c_module,'PROCEDURE','end');
  end FIX_SYSTEM_OWNED_NE_TYPE;


  /*
  ** REMOVE_XML_SCHEMA
  ** X_SCHEMA_URL - URL identifying the XML schema to be deleted
  ** This api is invoked as xml_schema_cleanup ddl to remove XML schema
  **
  */
  procedure REMOVE_XML_SCHEMA (X_SCHEMA_URL in varchar2)
  is
    C_MODULE           varchar2(80) := 'ad.plsql.ad_sec_utils.remove_xml_schema';
    TYPE C_XML_COL_CUR is ref cursor;
    C_OBSOLETE_COLUMNS c_xml_col_cur;
    L_XML_COL_STMT     varchar2(4000);
    L_COL_OWNER        varchar2(128);
    L_COL_TBL_NAME     varchar2(128);
    L_COL_NAME         varchar2(4000);
  begin
    log(c_module,'PROCEDURE','begin schema url is '||x_schema_url);

    if(x_schema_url is null) then
      log(c_module,'ERROR','xml schema url cannot be null');
      raise_application_error(-20002,'xml schema url cannot be null');
    end if;

    -- To avoid shipping of additional grant for APPS wrt dba_xml_tab_cols via slim patch created dynamic sql
    -- In AD delta13,we will be granting select on SYS.DBA_XML_TAB_COLS to ebs_system with grant option via adgrants.sql
    -- ebs_system will inturn grant select on SYS.DBA_XML_TAB_COLS to APPS via apps_adgrants.sql
    -- As this api will be run by AD finalize patch (post AD delta13,ensures that grant is available) during xml_schema_cleanup
    -- as system user
    l_xml_col_stmt := 'select xmltabcol.owner,
                              xmltabcol.table_name,
                              xmltabcol.column_name
                       from   sys.dba_xml_tab_cols  xmltabcol
                       where  xmltabcol.xmlschema = :x_schema_url
                       and    xmltabcol.owner in (select oracle_username
                                                  from fnd_oracle_userid
                                                  where  read_only_flag in (''A'', ''B'', ''C'', ''E'', ''U'', ''Z''))
                       --for any base columns which are already set as unused
                       --or dropped the column name will start with SYS
                       --we need not retrieve such columns
                       and    xmltabcol.column_name not like ''SYS%''
                       --ensure that base column is not part of ev
                       and    not exists(select evc.table_column_name
                                         from   dba_editioning_view_cols evc
                                         where  evc.owner     = xmltabcol.owner
                                         and    evc.view_name = substrb(xmltabcol.table_name, 1,29)||''#''
                                         and    evc.table_column_name = xmltabcol.column_name )
                       order by owner,table_name,column_name ';
    open  c_obsolete_columns for l_xml_col_stmt using x_schema_url;
    loop
      --Retrieve table columns associated with xmlschema
      --which have been revised successfully i.e they are not part of
      --editioning view and set base columns as unused
      --This is a precursor for xml schema deletion step
      fetch c_obsolete_columns into l_col_owner,
                                    l_col_tbl_name,
                                    l_col_name;
      exit when c_obsolete_columns%notfound;

      begin
        log(c_module,'PROCEDURE','xml schema dep col is'||l_col_owner||'.'||l_col_tbl_name||'.'||l_col_name);
        execute immediate 'alter table "'||l_col_owner||'"."'||l_col_tbl_name||'"'||
                          '  set unused ('||l_col_name||')';
      exception
        when others then
        raise_application_error(-20002,'error during setting column'||l_col_owner||'.'||l_col_tbl_name||'.'||l_col_name||' as unused '||sqlerrm);
      end;
    end loop;
    close c_obsolete_columns;

    begin
      --This procedure deletes the XML Schema specified by the schemaurl
      --with dbms_xmlschema.delete_cascade_force option
      --Schema deletion will also drop all default SQL types and default tables.
      dbms_xmlschema.deleteschema(schemaurl => x_schema_url,delete_option => dbms_xmlschema.delete_cascade_force);
    exception
      when others then
        --Invalid resource handle or path name
        if(sqlcode=-31001) then
          log(c_module,'ERROR','error: ->['|| substr(sqlerrm,1,400)|| ' ] ');
          raise;
        else
          log(c_module,'ERROR','error: ->['|| substr(sqlerrm,1,400)|| ' ] ');
          raise_application_error(-20010,sqlerrm);
        end if;
    end;

    log(c_module,'PROCEDURE','end');
  end REMOVE_XML_SCHEMA;

$end



end AD_SEC_UTILS;
