
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_PREP" authid current_user as
/* $Header: ADZDPRPS.pls 120.14.12020000.10 2022/06/13 04:39:28 rsatyava ship $ */
$if (ad_db_info.is_adb) $then

  c_package        constant varchar2(80) := 'ad.plsql.ad_zd_prep.';

$else

  /*---------------------------------------------------------------

                 Utility / Internal APIs
  ---------------------------------------------------------------*/

  function IS_TYPE_EVOLVED(
    X_OWNER in varchar2,
    X_NAME  in varchar2 ) return varchar2 ;

  function IS_TYPE_EXISTS(
    X_OWNER in varchar2,
    X_NAME in varchar2) return boolean ;


  /*---------------------------------------------------------------

                 Public APIs

  ---------------------------------------------------------------*/

  -- Creates EBS_PATCH service
  procedure CREATE_PATCH_SERVICE;

  -- Moves XML schema referenced by E-business Suite tables
  -- to Non_Editioned APPS schema.
  procedure MOVE_XML_SCHEMAS;


  -- Public API which is an entry point to
  -- generate DDLs for Online-Enablement process.
  procedure DO_PREP;

  -- This procedure recompiles TYPES from source schema.
  -- uses a global list of TYPES and calls ST API during DDL generation.
  --
  -- DEPENDENT ON:
  --     COPY_TYPE
  --     COPY_EVOLVED_TYPE
  procedure RECOMPILE_TYPES;



  --  Drop not-used queues
  procedure DROP_TEMP_QUEUES;
  procedure DROP_QUEUES(
    X_OWNER      in varchar2,
    X_QUEUE_NAME in varchar2);
  procedure STOP_QUEUE(X_QUEUE_NAME in varchar2);


  procedure ENABLE_EDITIONS;
  procedure ENABLE_USER_4EDITION(X_USERNAME in varchar2);

  --
  -- Produre to fix all the public and private synonyms in the system.
  --
  -- Desc :
  --   PUBLIC Synonyms point to editioned EBS objects must be dropped,
  --   PUBLIC Synonyms cannot be editioned so they should be replaced by
  --   equivalent private synonyms.
  --
  --
  -- 1.	Query PUBLIC synonyms that point at "to be editioned" objects.
  -- 2.	For each PUBLIC synonym in step 1, query the oracle users that have code dependencies on that PUBLIC synonym.
  -- 3.	For each affected oracle user in step 2, create the equivalent private synonym.
  -- 4.	After all private replacement synonyms have been created, drop all PUBLIC synonyms from step 1.
  PROCEDURE FIX_PUBLIC_SYNONYMS;
  procedure FIX_PUBLIC_SYNONYM(
    X_SYNONYM_NAME in varchar2,
    X_TABLE_OWNER  in varchar2,
    X_TABLE_NAME   in varchar2,
    X_DB_LINK      in varchar2);

  -- COPY User-Defined-Types to APPS_NE schema
  procedure COPY_TYPES;
  procedure COPY_TYPE(
    X_OWNER       in varchar2,
    X_NAME        in varchar2,
    X_NEW_OWNER   in varchar2);

  -- COPY User-Defined-Evolved-Types to APPS_NE schema
  procedure COPY_EVOLVED_TYPES;
  procedure COPY_EVOLVED_TYPE(
    X_OWNER       in varchar2,
    X_NAME        in varchar2,
    X_NEW_OWNER   in varchar2 );

  --  Evolved TYPES which are not being used as a COLUMN-TYPE (of a table)
  --  needs to be RESET to avoid: "ORA-38820: user has evolved object type"
  --  before enabling a user for editions.
  procedure RESET_NOCOLUMN_EVOLVED_TYPES(
    X_OWNER in varchar2 default null);

  -- Public API to change UDT reference at table-column level
  --, this internally calls sys.dbms_objects_utils.update_types without
  -- any specific TYPE name.
  procedure FIX_TYPES(
    X_SOURCE_SCHEMA in varchar2,
    X_TARGET_SCHEMA in varchar2);

  -- This internally calls sys.dbms_objects_utils.update_types with
  -- specific TYPE name.
  procedure FIX_TYPE (
    X_TYPE_OWNER in varchar2,
    X_TYPE_NAME  in varchar2);

  -- Re-create AQ objects like DEQUEUE view etc. after changing UDT reference
  -- at table-column level
  procedure RECREATE_AQ_OBJECT (
    X_OWNER in varchar2,
    X_TABLE  in varchar2);


  --
  -- Problematic cases.
  -- User Datastore procedures pre-process data to be indexed.  Pre-10g, this code
  -- had to be defined in the CTXSYS schema, and much of it is still there.
  -- Post 10g, these procedures can and should be migrated back to the APPS schema.  (Easy Fix)
  --
  PROCEDURE FIX_CTXSYS ;
  PROCEDURE DROP_CTXSYS_PKG(X_PACKAGE_NAME in varchar2);
  PROCEDURE DROP_CTXSYS_SYNONYM(X_SYNONYM_NAME in varchar2);

  -- Internal APIs
  procedure FIX_COLUMNS;
  procedure FIX_QUEUE(
    X_OWNER       in varchar2,
    X_TABLE       in varchar2,
    X_COLUMN      in varchar2);
  procedure FIX_COLUMN(
    X_OWNER       in varchar2,
    X_TABLE       in varchar2,
    X_COLUMN      in varchar2);



  procedure REGISTER_CUSTOM_USER(X_USER in varchar2);
  procedure ENABLE_CUSTOM_USER(X_USER in varchar2);
  procedure FIX_CUSTOM_OBJECTS(X_USER in varchar2);

  function GET_EBS_PATCH_SERVICE RETURN VARCHAR2;
$end

end AD_ZD_PREP;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_PREP" as
/* $Header: ADZDPRPB.pls 120.46.12020000.39 2023/02/28 06:02:04 rsatyava ship $ */
$if (ad_db_info.is_adb) $then
  g_apps_ne_schema constant varchar2(30) :='APPS_NE';
$else

   c_package        constant varchar2(80) := 'ad.plsql.ad_zd_prep.';
   g_apps_ne_schema constant varchar2(30) :='APPS_NE';
   g_xla_schema     constant varchar2(10) :='XLA';

   type col_owners is table of number index by varchar2(150);
   type udt_obj is record (owner  varchar2(30),
                           type_name varchar2(30) );
   type evolved_type_src_rec is record
        ( owner  varchar2(30),
          type_name varchar2(30),
          objid  number ,
          source varchar2(4000)
        );

   -- store udt and source udt owner
   type udt_obj_t is table of udt_obj index by binary_integer;
   type evolved_type_src_tab is table of evolved_type_src_rec index by binary_integer;

   -- Package level global variables
   -- ***********************************************************************
   g_udt_obj_list udt_obj_t;
   g_udt_obj_indx pls_integer := 0;
   -- List of source obj of evolved-types
   g_evolved_types_src_list evolved_type_src_tab;
   g_evolved_type_index pls_integer :=0;

   g_obj_list_to_recompile sys.dbms_objects_utils_tnamearr := sys.dbms_objects_utils_tnamearr();

  --  ************************************************************************
  --
  --   Private: Utility or Validation APIs
  --
  -- **************************************************************************

  -- log shortcut
  procedure log(x_module    varchar2,
                x_log_type  varchar2,
                x_message   varchar2 ) is
  begin
    ad_zd_log.Message( x_module=>x_module, x_log_type => x_log_type, x_message => x_message );
  end;


  /*
  ** log error message and raise exception
  */
  procedure ERROR(X_MODULE varchar2, X_MESSAGE varchar2) is
  begin
    ad_zd_log.message(x_module, 'ERROR', x_message);
    raise_application_error(-20001, x_message);
  end;

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
  -- execute dynamic SQL statement
  --   x_sql     - statement to execute
  --   x_log_mod - calling module (for logging)
  --   x_ignore  - ignore errors
  --
  procedure exec(X_SQL in clob, X_LOG_MOD in varchar2, X_IGNORE in boolean default false)
   IS SUCCESS_WITH_COMPILATION_ERROR exception;
    pragma exception_init(success_with_compilation_error, -24344);

    DEADLOCK_DETECTED_ERROR exception;
    pragma exception_init(deadlock_detected_error, -00060);

    L_CUR integer;
    L_RET integer;
   l_module varchar2(80) := c_package || 'exec';
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

  -- Calls ad_zd_parallel_exec.load with same parameters.
  procedure LOAD(
    X_PHASE   varchar2,
    X_SQL     clob)
  is
  begin
    -- SQLs from DB Prep flow can NOT be duplicate, so
    -- should not be checked for duplicity i.e. x_unique => false.
    ad_zd_parallel_exec.load(x_phase, x_sql, false);
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
  --
  -- Utility function to check whether a given type is an EVOLVED type in an schema or not.
  --
  function IS_TYPE_EVOLVED(X_OWNER in varchar2, X_NAME in varchar2 )
     return varchar2
  is
   l_obj_cnt pls_integer :=0;
  begin

     select count(obj#) into l_obj_cnt
     from sys.obj$ o
     where owner# =(select user# from sys.user$ where name = x_owner)
     and o.NAME = x_name
     and o.type# = 13            --13 =  TYPE,
     and o.subname is not null;  --only for evloved type

     if(l_obj_cnt > 0 ) then
      return 'Y';
     else
      return 'N';
     end if;

  end IS_TYPE_EVOLVED;


  --
  -- This function checks if TYPE and OWNER exist in the specified collection
  --
  function IS_TYPE_EXISTS_IN_LIST(X_OWNER varchar2,
                                  X_NAME varchar2 ,
                                  X_TYPE_LIST in udt_obj_t )
    return boolean
  is
   is_exists boolean := false;
  begin
    for idx in 1..x_type_list.count loop
      if( x_type_list(idx).owner = x_owner and
          x_type_list(idx).type_name = x_name ) then
        is_exists := true;
      end if;
    end loop;
    return is_exists;
  end IS_TYPE_EXISTS_IN_LIST;

  --
  -- **********************************************************
  -- Utility function to check whether a given type exists or not in a schema?
  --
  --
  function IS_TYPE_EXISTS(X_OWNER varchar2, X_NAME varchar2 ) return boolean
  is
   l_obj_cnt pls_integer :=0;
  begin

     select count(obj#) into l_obj_cnt
     from sys.obj$ o
     where owner# =(select user# from sys.user$ where name = x_owner)
     and o.NAME = x_name
     and o.type# = 13;

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

     select count(obj#) into l_obj_cnt
     from sys.obj$ o
     where owner# =(select user# from sys.user$ where name = x_owner)
     and o.NAME = x_name
     and o.type# = 14;    -- 14: TYPE BODY

     if(l_obj_cnt > 0 ) then
      return true;
     else
      return false;
     end if;

  end IS_TYPE_BODY_EXISTS;

   --
   -- Procedure to compile Non editionable apps ( apps_ne ) schema
   --
   --
   procedure compile_ne_schema(x_exec boolean) as
     l_module varchar2(80) := c_package || 'compile_ne_schema';
   begin
    log(l_module, 'PROCEDURE', 'begin');
    if(x_exec) then
      exec('begin dbms_utility.compile_schema(schema=>'''||g_apps_ne_schema||'''); end;',  l_module);
    else
      load(x_phase=> ad_zd_parallel_exec.c_phase_compile_type,
           x_sql  => 'begin dbms_utility.compile_schema(schema=>'''|| g_apps_ne_schema||'''); end;');
    end if;
    log(l_module, 'PROCEDURE', 'end');
   end compile_ne_schema;

   --
   -- This procedure recompiles TYPES from source schema so that new db version compatible
   -- hash-code is generated. This is specifically for TYPEs compiled in Pre-11G DB.
   --
   -- This API uses the type list prepared from:
   --     COPY_TYPE
   --     COPY_EVOLVED_TYPE APIs.
   --
   -- Usage:
   --    Should be called after call of dependent (COPY_TYPE, COPY_EVOLVED_TYPE ) are being
   --    called.
   --
   procedure recompile_types as
    l_module varchar2(80) := c_package || 'recompile_types';
   begin
     log(l_module, 'PROCEDURE', 'begin');
     --
     -- Bug 12747238 : If hash-code conforming to 10g db
     --                then sys.dbms_objects_apps_utils.update_types will not work.
     -- Solution is: recompile all such UDTs then it will have 11g db compatible hash-code.
     --
     if(g_obj_list_to_recompile is not null and
        g_obj_list_to_recompile.count > 0 ) then

       log(l_module, 'STATEMENT', 'Recompiling User-Defined-Types from source schema to get'||
                                  ' 11g database compatible hash-code ');
       server_output('ENABLE');
       sys.dbms_objects_apps_utils.recompile_types(names=> g_obj_list_to_recompile);
       log_server_output('sys.dbms_objects_apps_utils.recompile_types', 'STATEMENT');
       server_output('DISABLE');

     end if;
     log(l_module, 'PROCEDURE', 'end');
   end recompile_types;


   --
   -- This procedure populates g_obj_list_to_recompile
   --
   procedure put_obj_to_recompile(x_owner varchar2, x_type_name varchar2 )
   is
    l_type_names  sys.dbms_objects_utils_tname;
   begin

     l_type_names := sys.dbms_objects_utils_tname(x_owner, x_type_name);
     g_obj_list_to_recompile.extend;
     g_obj_list_to_recompile(g_obj_list_to_recompile.last):= l_type_names;

   end put_obj_to_recompile;

  --  **********************************************************************************
  --
  --            E-business Suite Database Preparation APIs for Editionning .
  --
  --
  -- ***********************************************************************************
  --
  function GET_EBS_PATCH_SERVICE return varchar2
  is
    l_patch_service varchar2(255);
    l_dbdomain      varchar2(128) := sys_context('userenv', 'db_domain');
  begin
    -- - Get "<db-name>_ebs_patch" service name from context file.
    --
    -- - If "<db-name>_ebs_patch" exists in context file (either RUN or PATCH)
    --     then "<db-name>_ebs_patch" is either already came into existence (OR)
    --     about to come into existence (AD/TXK patches are being-applied).
    --
    -- - If "<db-name>_ebs_patch" does not exist in context file then we are
    --     still in "ebs_patch" mode and all validations should be for "ebs_patch".
    --
    begin
      select distinct(extractvalue(xmltype(text),'//patch_service_name[@oa_var="s_patch_service_name"]'))
             into l_patch_service
      from fnd_oam_context_files
      where (status is null or status <> 'H')
        --and extractvalue(xmltype(text),'//file_edition_type')='run' /* check accross-editions */
        and name not in ('TEMPLATE','METADATA')
        and existsnode(xmltype(text),'//patch_service_name[@oa_var="s_patch_service_name"]') = 1
        and ctx_type = 'A';
    exception
      when no_data_found then
        -- "<db-name>_ebs_patch" does not come into existence, so OLD style
        --  until AD/TXK patch-application's adop:cutover is done (OR) for EBR flow
        --  control will come here.
        l_patch_service := 'ebs_patch';
    end;

    if(l_dbdomain is not null) then
      l_patch_service := l_patch_service||'.'||l_dbdomain;
    end if;
    return l_patch_service;
  end GET_EBS_PATCH_SERVICE;

  -- Create patch service
  --  Usage:
  --    - During EBR (ADZDPREP.sql)
  --    - adop: database validations (ad_zd_adop.adop_database_validations)
  --
  procedure CREATE_PATCH_SERVICE
  is
    l_module        varchar2(80) := c_package || 'create_patch_service';
    l_exists        number;
    l_dbdomain      varchar2(128) := sys_context('userenv', 'db_domain');
    l_patch_service varchar2(255);

  begin
    log(l_module, 'PROCEDURE', 'begin');
    l_patch_service := get_ebs_patch_service;

    -- Since service name is case-insensitive, even sqlplus accepts that.
    begin
      select 1 into l_exists
      from  dba_services
      where upper(name)=upper(l_patch_service);
    exception
      when no_data_found then
        log(l_module, 'EVENT', 'Creating ' || l_patch_service || ' database service');
        dbms_service.create_service(l_patch_service, l_patch_service);
    end;

    -- start patch service if needed
    begin
      select 1 into l_exists
      from   sys.v_$active_services
      where upper(name)=upper(l_patch_service);
    exception
      when no_data_found then
        log(l_module, 'EVENT', 'Starting ' || l_patch_service || ' database service');
        dbms_service.start_service(l_patch_service);
    end;

    log(l_module, 'PROCEDURE', 'end');
  end CREATE_PATCH_SERVICE;


  --
  --
  -- After ST fix 16819180, XML SCHEMA is not being migrated to target database user,
  -- instead underlying TYPES are being moved to target db user.
  --
  procedure MOVE_XML_SCHEMAS
  is
    L_MODULE varchar2(80) := c_package|| 'move_xml_schemas';
    L_SCHEMA_OWNER varchar2(30);
    L_SCHEMA_URL   varchar2(700);
    L_FOUND        boolean := false;
    L_COUNT_PRE    number;
    L_COUNT_POST   number;

    cursor C_XML_SCHEMAS is
      -- NOTE:
      -- -- Following SQL should only be used where ST fix 16819180
      -- -- (v3 bug 16162444: migrate types) has been applied.
      -- -- Also, pick up  all the E-biz XML schema, not only those on which a table is dependent on
      -- -- as XML schema is a non-editionable object, per EBR rule, which can not dependent on a TYPE.
      --
      select distinct xmls.owner, xmls.schema_url
      from  dba_xml_schemas  xmls
      where ( -- oracle seeded xml schemas in SYSTEM user, let move TYPES to apps_ne
              -- though XML schema in SYSTEM does not violate any EBR rule.
             (xmls.schema_url in (
                 'http://isetup.oracle.com/2006/diffresultdata.xsd',
                 'http://isetup.oracle.com/2006/selectionsets.xsd',
                 'http://isetup.oracle.com/2006/reporterdata.xsd')
              and xmls.owner='SYSTEM')
            or
             xmls.owner in
              (select oracle_username
               from fnd_oracle_userid fu
               where fu.read_only_flag in ('A','B', 'E', 'U', 'C')
              )
            )
        and exists
              (select null
               from  dba_dependencies dep,
                     xdb.xdb$element e
               where dep.name = xmls.int_objname
                 and dep.type = 'XML SCHEMA'
                 and dep.owner = 'XDB'
                 and (dep.referenced_owner in
                       (select oracle_username
                        from  fnd_oracle_userid fu
                        where fu.read_only_flag in ('A','B', 'E', 'U', 'C')
                        )
                      or
                      dep.referenced_owner='SYSTEM' ) -- for seeded xml schemas
                 and e.xmldata.property.sqltype = dep.referenced_name
                 and e.xmldata.property.SQLSchema = dep.referenced_owner
               );
  begin
    log(l_module, 'PROCEDURE', 'begin');
    -- Clear off rows from xdb table
    delete from sys.xdb$moveSchemaTab;
    log(l_module, 'EVENT',  sql%rowcount || ' rows have been deleted from sys.xdb$moveSchemaTab');

    for xml_schema in c_xml_schemas loop
      insert into sys.xdb$moveSchemaTab(schema_url, schemaownerfrom, schemaownerto, schema)
        values(xml_schema.schema_url, xml_schema.owner, g_apps_ne_schema, null);

      log(l_module, 'STATEMENT', 'Inserted XML schema into sys.xdb$moveSchemaTab ('||
                                  xml_schema.schema_url || ',' || xml_schema.owner ||
                                  ',' || g_apps_ne_schema ||', null)' );
      l_found := true;
    end loop;

    commit;

    if( l_found ) then
      l_found := false;

      -- Pre-migration invalid count only in current edition
      select count(1) into l_count_pre
      from dba_invalid_objects;

      log(l_module, 'EVENT', 'Move xml schema: Invoke sys.xdb_migrateschema.moveSchemas ');
      server_output('ENABLE');
      sys.xdb_migrateschema.moveSchemas;
      log_server_output('sys.xdb_migrateschema.moveSchemas', 'STATEMENT');
      log(l_module, 'STATEMENT', 'Done with sys.xdb_migrateschema.moveSchemas call');

      -- Post migration invalid count only in current edition
      select count(1) into l_count_post
      from dba_invalid_objects;

      if(l_count_post > l_count_pre ) then
        error(l_module, 'XML SCHEMAS not migrated to target user successfully ' ||
                              'or migration process introduced some new Invalid-objects');
      end if;

      -- Clean up DB table; in case of error, we want to preserve it for debugging.
      delete from sys.xdb$moveSchemaTab;
      commit;
    else
      log(l_module, 'STATEMENT', 'No XML Schema found to be migrated to target user');
    end if;
    log(l_module, 'PROCEDURE', 'end');
  exception
    when others then
      log_server_output('sys.xdb_migrateschema.moveSchemas', 'ERROR');
      error(l_module, substr(sqlerrm, 1, 255));
  end MOVE_XML_SCHEMAS;


   --
   -- procedure to stop an AQ.
   --
   procedure STOP_QUEUE(X_QUEUE_NAME varchar2) as
     l_module varchar2(80) := c_package || 'stop_queue';
   begin
     log(l_module, 'PROCEDURE', 'begin: '|| x_queue_name);
     exec('begin dbms_aqadm.stop_queue('''|| x_queue_name|| '''); end;', l_module);
     log(l_module, 'PROCEDURE', 'end');
   end stop_queue;


   -- procedure to start an AQ.
   procedure START_QUEUE(X_QUEUE_NAME in varchar2) as
    l_module varchar2(80) := c_package || 'start_queue';
   begin
     log(l_module, 'PROCEDURE', 'begin: ' || x_queue_name);
     exec('begin dbms_aqadm.start_queue('''|| x_queue_name||'''); end;', l_module);
     log(l_module, 'PROCEDURE', 'end');
   end start_queue;


   -- procedure to drop an AQ.
   procedure DROP_QUEUE (X_QUEUE_NAME in varchar2) as
    l_module varchar2(80) := c_package || 'drop_queue';
   begin
     log(l_module, 'PROCEDURE', 'begin: ' || x_queue_name);
     exec('begin dbms_aqadm.drop_queue('''|| x_queue_name||'''); end;', l_module);
     log(l_module, 'PROCEDURE', 'end');
   end drop_queue;


   --
   -- Stops and then drops specified queue
   --
   procedure DROP_QUEUES(X_OWNER varchar2, X_QUEUE_NAME varchar2)
   as
     l_module varchar2(80) := c_package || 'drop_queues';
   begin
     log(l_module, 'PROCEDURE', 'begin: ' || x_owner || '.'||  x_queue_name);
     stop_queue('"'||x_owner ||'"."' || x_queue_name ||'"' );
     drop_queue('"'||x_owner ||'"."' || x_queue_name || '"');
     log(l_module, 'PROCEDURE', 'end');
   end DROP_QUEUES;

   --
   -- Drops all temporary queue which had been left over due to
   -- some bug which was fixed via patch: 8284764:R12.XLA.A or 9131790:R12.XLA.B
   -- The AQs still exist after the patch applied so dropping them.
   --
   procedure DROP_TEMP_QUEUES is

     cursor c_queues is
       select aq.owner ,  aq.name
       from   dba_queues aq
       where  aq.owner = g_xla_schema
       and    (aq.name  like 'XLA_%_DOC_Q' or aq.name  like 'XLA_%_COMP_Q');

   begin

     for queue in c_queues loop
       load(x_phase => ad_zd_parallel_exec.c_phase_drop_unused_object,
            x_sql   => 'begin ad_zd_prep.drop_queues('
                       || '''' || queue.owner || ''', '''
                       || queue.name || '''); end; ');
    end loop;
   end DROP_TEMP_QUEUES;


   --   Update table references to  APPS_NE type
   procedure FIX_TYPES(X_SOURCE_SCHEMA  varchar2,
                       X_TARGET_SCHEMA  varchar2)
   is
     L_MODULE     varchar2(80) := c_package || 'fix_types';

     cursor C_TYPES is
       with p(referenced_owner, referenced_name) as
       (
          select referenced_owner, referenced_name
          from dba_dependencies d
          where d.type = 'TABLE'
          and   d.name = upper (name)
          and   d.referenced_type = 'TYPE'
          and   d.referenced_name = upper(d.referenced_name)
          and   (
                 -- either referenced owner is registred ebs_system.fnd_oracle_userids owner
                 d.referenced_owner in
                 ( select oracle_username
                   from ebs_system.fnd_oracle_userid
                   where  read_only_flag in ('A','B', 'E', 'U', 'C')
                 )
                or
                 exists
                 ( select 1
                   from  dba_dependencies
                   where owner = d.referenced_owner
                   and   name = d.referenced_name
                   and   type = d.referenced_type
                   and   referenced_type = 'TYPE'
                   and   referenced_owner in
                         (
                           select oracle_username
                           from ebs_system.fnd_oracle_userid
                           where  read_only_flag in ('A','B', 'E', 'U', 'C')
                         )
                 )
               )
          /* filter out XDB types */
          and not exists ( select null
                           from  xdb.xdb$element e
                           where e.xmldata.property.sqltype = d.referenced_name )
          and not exists (select null
                          from  xdb.xdb$element e
                          where e.xmldata.property.sqlcolltype = d.referenced_name)
       union all
         select d.referenced_owner referenced_owner,
                d.referenced_name referenced_name
         from  dba_dependencies d,
               p
         where d.referenced_type = 'TYPE'
         and   d.referenced_name = upper (d.referenced_name )
         and   d.name = p.referenced_name
         and   d.owner = p.referenced_owner
         and   d.referenced_owner in
               ( select oracle_username
                 from ebs_system.fnd_oracle_userid
                 where  read_only_flag in ('A','B', 'E', 'U', 'C')
                )
       )
       cycle referenced_owner, referenced_name set cyclemarker to 'Y' default 'N'
       select distinct referenced_owner, referenced_name
       from p where cyclemarker = 'N';


   begin
     log(l_module, 'PROCEDURE', 'begin: '||x_source_schema||', '||x_target_schema);

     for l_type in c_types loop
       log(l_module, 'STATEMENT', 'User Defined Type: '||l_type.referenced_owner||'.'||l_type.referenced_name);
       if ((l_type.referenced_owner = x_source_schema ) and
           (is_type_exists(x_target_schema, l_type.referenced_name)= false)) then

         log(l_module, 'ERROR', 'User Defined Type ' || x_target_schema || '.' || l_type.referenced_name ||
                                ' does not exist');

         -- Raise critical error code 20978 from defined unexpected errors (in ADZDPEXS.pls ) instead
         -- of defining a new one: -20978 /* Cannot drop a type with table dependents */
         -- so that parallel worker won't execute subsequent jobs.
         raise_application_error(-20978, 'User Defined Type ' || x_target_schema || '.' || l_type.referenced_name ||
                                         ' does not exist');
       end if;
     end loop;

     log(l_module, 'EVENT', 'Update User Defined Type reference at TABLE level from '||
                            x_source_schema||' to '||x_target_schema);

     server_output('ENABLE');
     -- Without any specific TYPE
     sys.dbms_objects_apps_utils.update_types
         ( schema1      => x_source_schema,
           schema2      => x_target_schema,
           typename     => null,
           check_update => true ) ;

     log_server_output('sys.dbms_objects_apps_utils.update_types', 'STATEMENT');

     --NOTE: Not adding a CHECK here to make sure that none of the table are now dependent
     --      on x_source_schema types, reason being: since  sys.dbms_objects_apps_utils.update_types
     --      checkes if all TYPES from source schema are created in target scheam but if source
     --      schema is SYSTEM then it does not fall true, so data-dictionary updates still would be
     --      half-way, so let that validation be handled withih FIX_TYPE API.

     log(l_module, 'PROCEDURE', 'end');
   end FIX_TYPES;


   -- Convert Editioned Type to equivalent Non-Editioned Type synonym
   --   Update table references to NE type if needed
   --   Convert dependant types, if needed
   --   Drop type, replace with synonym to NE type
   procedure FIX_TYPE(X_TYPE_OWNER varchar2, X_TYPE_NAME varchar2)
   is
    L_MODULE     varchar2(80) := c_package || 'fix_type';
    L_REF_OWNER  varchar2(30);
    L_REF_NAME   varchar2(30);
    L_FOUND      boolean;

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
      and    nt.owner     = g_apps_ne_schema
      and    nt.type_name = ot.name;

    -- tables that references the specific type or its dependent type
    cursor C_TABLE_REFS2(TYPE_OWNER varchar2, TYPE_NAME varchar2) is
      select dep.owner, dep.name
      from  dba_dependencies dep
      where dep.type  = 'TABLE'
      and   dep.referenced_owner <> g_apps_ne_schema
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

       sys.dbms_objects_apps_utils.update_types
         ( schema1      => x_type_owner,
           schema2      => 'APPS_NE',
           typename     => x_type_name,
           check_update => false ) ;

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
       log(l_module, 'EVENT', 'Converting Type to Synonym: '||x_type_owner||'.'||x_type_name);

       exec('drop type "'||x_type_owner||'"."'||x_type_name||'" force', l_module, true);
       exec('create or replace synonym "'||x_type_owner||'"."'||x_type_name||'" for '
            ||'"APPS_NE"."'||x_type_name||'"', l_module, true);
     end if;

     log(l_module, 'PROCEDURE', 'end');
   end FIX_TYPE;

   --
   -- The procedure works as follows:
   --  Gets the DDL by using dbms_metadata and creates in APPS_NE schema
   --
   --
   procedure COPY_TYPE(X_OWNER       in varchar2,
                       X_NAME        in varchar2,
                       X_NEW_OWNER   in varchar2)
   is
     L_MODULE varchar2(80) := c_package || 'copy_type';
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

   --
   -- Copy UDT columns of tables to APPS_NE
   --
   -- procedure to find all UDTs which are referenced by table columns and calling
   -- procedure to copy them to APPSNE schema
   --
   procedure COPY_TYPES is
     l_module varchar2(80) := c_package || 'copy_types';
     l_flag boolean := false;

     cursor all_types is
       with p(referenced_owner, referenced_name) as
       (
          select referenced_owner, referenced_name
          from dba_dependencies d
          where d.type = 'TABLE'
          and   d.name = upper (name)
          and   d.referenced_type = 'TYPE'
          and   d.referenced_name = upper(d.referenced_name)
          and   (
                 -- either referenced owner is registred ebs_system.fnd_oracle_userids owner
                 d.referenced_owner in
                 ( select oracle_username
                   from ebs_system.fnd_oracle_userid
                   where  read_only_flag in ('A','B', 'E', 'U', 'C')
                 )
                OR
                 exists
                 ( select 1
                   from  dba_dependencies
                   where owner = d.referenced_owner
                   and   name = d.referenced_name
                   and   type = d.referenced_type
                   and   referenced_type = 'TYPE'
                   and   referenced_owner in
                         (
                           select oracle_username
                           from ebs_system.fnd_oracle_userid
                           where  read_only_flag in ('A','B', 'E', 'U', 'C')
                         )
                 )
               )
          -- /* filter out XDB types */
          and not exists ( select null
                           from  xdb.xdb$element e
                           where e.xmldata.property.sqltype = d.referenced_name )
          and not exists (select null
                          from  xdb.xdb$element e
                          where e.xmldata.property.sqlcolltype = d.referenced_name)

       union all
         select d.referenced_owner referenced_owner,
                d.referenced_name referenced_name
         from  dba_dependencies d,
               p
         where d.referenced_type = 'TYPE'
         and   d.referenced_name = upper (d.referenced_name )
         and   d.name = p.referenced_name
         and   d.owner = p.referenced_owner
         and   d.referenced_owner in
               ( select oracle_username
                 from ebs_system.fnd_oracle_userid
                 where  read_only_flag in ('A','B', 'E', 'U', 'C')
                )
       )
       cycle referenced_owner, referenced_name set cyclemarker to 'Y' default 'N'
       select distinct referenced_owner, referenced_name
       from p where cyclemarker = 'N';

      l_evolved_idx pls_integer := 0;

   begin
     log(l_module, 'PROCEDURE', 'begin');

     for t in all_types loop
       if( is_type_evolved(t.referenced_owner, t.referenced_name) <> 'Y')  then
         -- normal UDTs
         load(x_phase => ad_zd_parallel_exec.c_phase_copy_type,
              x_sql   => 'begin ad_zd_prep.copy_type('''
                                        || t.referenced_owner || ''', '''
                                        || t.referenced_name || ''','''
                                        || g_apps_ne_schema || '''); end;');

         -- BUG 12747238 :
         -- Source TYPES will recompiled during DDL generation time
         -- to make sure that they have 11g conforming hash-code
         -- before DDL execution starts.
         put_obj_to_recompile(t.referenced_owner, t.referenced_name);

         -- FIX_TYPE will check dependency, if exist, will try to fix before
         -- dropping a type.
         load(x_phase  => ad_zd_parallel_exec.c_phase_fix_type,
              x_sql    => 'begin ad_zd_prep.fix_type('''
                         || t.referenced_owner || ''', '''
                         || t.referenced_name || '''); end; ');

       end if;
       l_flag := true;
     end loop;

     if(l_flag) then
      -- Recompile source TYPES to make hash-code compatible if they were NOT before.
      -- This API should be called during ddl-population time.
      recompile_types;

      -- STEP#3 : Adding it here also so, all UDT become VALID before EVOLVED type creation
      log(l_module, 'STATEMENT', 'Populating compile_ne_schema(x_exec=>false) API.' );
      compile_ne_schema(false);
     end if;

     log(l_module, 'PROCEDURE', 'end');
   end COPY_TYPES;


   --
   -- Loads the DDLs into AD_ZD_DDL_HANDLER from the global evolved_type or
   -- from sorted global list.
   --
   procedure INSTALL_EVOLVED_TYPES
   as
    l_idx number;
    l_objid number;
    l_flag boolean := true;
    l_evolved_type_rec evolved_type_src_rec;
    l_owner varchar2(30);
    l_type_name varchar2(30);
    l_source varchar(32676);  -- max will be 4000 but
    l_evolve_type_list udt_obj_t ;
    l_evolve_type_index pls_integer;
    l_module varchar2(80) := c_package || 'install_evolved_types';
   begin

     log(l_module, 'PROCEDURE', 'begin');
     -- Generic algo.
     -- Sorting based on [objid]
     --
     -- **********************************************************
     while(l_flag) loop
       l_flag  := false;
       for i in 1..(g_evolved_types_src_list.count-1) loop
        if (g_evolved_types_src_list(i).objid  > g_evolved_types_src_list(i+1).objid ) then
          l_evolved_type_rec            := g_evolved_types_src_list(i+1);
          g_evolved_types_src_list(i+1) := g_evolved_types_src_list(i);
          g_evolved_types_src_list(i)   := l_evolved_type_rec;
          l_flag        := true;
        end if;
       end loop;
     end loop;

     -- **************************************************************

      l_idx := g_evolved_types_src_list.FIRST;
      l_evolve_type_index := 0;

      while ( l_idx is not null ) loop
        l_evolved_type_rec :=  g_evolved_types_src_list(l_idx);
        l_source := l_evolved_type_rec.source;
        --  It is possible that TYPE has been evolved / exists in APPS_NE schema but table referecne might
        --   not have changed?
        if(is_type_evolved(l_evolved_type_rec.type_name, g_apps_ne_schema ) ='Y') then
         continue;
        end if;
        exec(l_source, l_module, true);

        if(is_type_exists_in_list(l_evolved_type_rec.owner,
                                  l_evolved_type_rec.type_name  ,
                                  l_evolve_type_list  ) = false ) then

            l_evolve_type_index := l_evolve_type_index + 1;
            l_evolve_type_list(l_evolve_type_index).owner :=  l_evolved_type_rec.owner;
            l_evolve_type_list(l_evolve_type_index).type_name := l_evolved_type_rec.type_name;
        end if;

        l_idx := g_evolved_types_src_list.next(l_idx);

      end loop;

      -- not optimized but okay to re-iterate .
      for i in 1..(l_evolve_type_list.count ) loop
         l_owner := l_evolve_type_list(i).owner;
         l_type_name := l_evolve_type_list(i).type_name;

         exec('GRANT EXECUTE ON "'||g_apps_ne_schema||'"."' || l_type_name || '"  TO PUBLIC ', l_module, true);

         load(x_phase=> ad_zd_parallel_exec.c_phase_fix_type,
              x_sql  => 'begin ad_zd_prep.fix_type('
                        || '''' || l_owner || ''', '''
                        || l_type_name || '''); end; ');

      end loop;
      log(l_module, 'PROCEDURE', 'end');
   end INSTALL_EVOLVED_TYPES;

   --
   -- Gets the DDL of a given Evolved-Types by using
   -- sys.dbms_objects_apps_utils.split_source() and replaces
   -- source schemas with APPS_NE.
   --
   -- TODO: If an APPS.evolved type dependent on another E-biz schema
   --       e.g. ECX then we need to check how dbms_objects_apps_utils.split_source()
   --       returns and may be we have to replace them.
   --
   procedure COPY_EVOLVED_TYPE (X_OWNER varchar2,
                                X_NAME  varchar2,
                                X_NEW_OWNER varchar2 )
   as
     e_source sys.dbms_objects_utils_tsource;
     l_source varchar2(4000);
     l_objid  number;
     sql_count number; /* number of DDLs returned in e_source for an EVOLVED type */
     l_index number;
     l_module varchar2(80) := c_package || 'copy_evolved_type';
   begin

     log(l_module, 'PROCEDURE', 'begin: '||x_owner||'.'||x_name || ', '|| x_new_owner);
     sql_count := sys.dbms_objects_apps_utils.split_source(x_owner, x_name, e_source);

     -- For each evolved type
     for cntr in 1..sql_count  loop
        l_source :=  e_source(cntr).source;
        l_objid  :=  e_source(cntr).objid;
        l_index :=   REGEXP_INSTR(l_source,
                       '[[:space:]]*("?' || x_owner || '"?)[.]?"?'|| x_name ||'"?[[:space:]]',
                       1,1,0, 'i' ) ;

        if(l_index > 0 ) then
          l_source :=  REGEXP_REPLACE(l_source,
                         '[[:space:]]*("?' || x_owner || '"?)[.]?"?'|| x_name ||'"?[[:space:]]',
                         ' "' || x_new_owner || '"."' || x_name || '" ' ,
                         1,1,'i' ) ;
        else
          -- No <schema.type> exist, may be only TYPE name, replace with  "APPS_NE"."TYPE"
          --
          l_source :=  REGEXP_REPLACE(l_source,
                            '[[:space:]]*("?' || x_name ||'"?)[[:space:]]',
                           ' "' || x_new_owner || '"."' || x_name || '" ' ,
                           1,1,'i' ) ;

        end if;

        -- insert in GLOBAL LIST to be used by INSTALL_EVOLVED_TYPES
        g_evolved_type_index := g_evolved_type_index + 1;
        g_evolved_types_src_list(g_evolved_type_index).owner  := x_owner  ;
        g_evolved_types_src_list(g_evolved_type_index).type_name := x_name;
        g_evolved_types_src_list(g_evolved_type_index).objid := l_objid;
        g_evolved_types_src_list(g_evolved_type_index).source  := l_source ;
     end loop;
     log(l_module, 'PROCEDURE', 'end');
   end COPY_EVOLVED_TYPE;

   --
   --
   -- Get all evolved type referenced by tables as column type
   -- NOTE: Evolved-type can be created properly only when ALL DEPENDENT
   --       TYPES have been created and are VALID. Otherwise ALTER DDL
   --       statement on evolved type will fail.
   --
   procedure COPY_EVOLVED_TYPES
   as
    l_module varchar2(80) := c_package || 'copy_evolved_types';
    l_evolved_type_list     udt_obj_t;
    l_index pls_integer :=0;

    --    Since this SQL is very slow, so better to get the list of evolved types from
    --    COPY_TYPES API (owner, evolved_type_name) but this  API will have dependency on
    --    COPY_TYPES API i.e. COPY_TYPES should be run before this API.
    --
    cursor all_evolved_types is
       with p(referenced_owner, referenced_name) as
       (
         select referenced_owner, referenced_name
         from dba_dependencies d
         where type = 'TABLE'
         and   name = upper ( name )
         and   referenced_type = 'TYPE'
         and   referenced_name = upper (referenced_name)
         and   (
                -- either referenced owner is registred ebs_system.fnd_oracle_userids owner
                referenced_owner in
                ( select oracle_username
                  from ebs_system.fnd_oracle_userid
                  where  read_only_flag in ('A','B', 'E', 'U','C')
                )
               or
               exists
               ( select 1
                 from  dba_dependencies
                 where owner = d.referenced_owner
                 and   name = d.referenced_name
                 and   type = d.referenced_type
                 and   referenced_type = 'TYPE'
                 and   referenced_owner in
                       (
                        select oracle_username
                        from ebs_system.fnd_oracle_userid
                        where  read_only_flag in ('A','B', 'E', 'U', 'C')
                       )
               )
              )
         -- Only take care  evolved types i.e. exclude normal UDT
         --
         and exists
                 (  select 1
                    from sys.obj$ o
                    where owner# =(select user# from sys.user$ where name = referenced_owner)
                    and o.NAME = referenced_name
                    and o.type# = 13
                    and o.subname is not null
                   )
          /* filter out XDB types */
         and not exists ( select null
                          from  xdb.xdb$element e
                          where e.xmldata.property.sqltype = d.referenced_name )
         and not exists (select null
                          from  xdb.xdb$element e
                          where e.xmldata.property.sqlcolltype = d.referenced_name)

       union all
         select d.referenced_owner referenced_owner,
                d.referenced_name referenced_name
         from  dba_dependencies d,
               p
         where d.referenced_type = 'TYPE'
         and   d.referenced_name = upper(d.referenced_name )
         and   d.name = p.referenced_name
         and   d.owner = p.referenced_owner
         and   d.referenced_owner in
               ( select oracle_username
                 from ebs_system.fnd_oracle_userid
                 where  read_only_flag in ('A','B', 'E', 'U', 'C')
                )
        and exists
              (  select 1
                 from sys.obj$ o
                 where owner# =(select user# from sys.user$ where name = d.referenced_owner)
                 and o.name = d.referenced_name
                 and o.type# = 13             --13 =  TYPE,
                 and o.subname is not null    -- sstomar:
                                              -- This predicate is important becuase for evolved type more than
                                              -- one rows will be exist,
                                              -- one with "subname= null" and other one as "subname= <value>"
                )

       )
       cycle referenced_owner, referenced_name set cyclemarker to 'Y' default 'N'
       select distinct referenced_owner, referenced_name
       from p where cyclemarker = 'N';
   begin
     log(l_module, 'PROCEDURE', 'begin');
     -- reset in each call of this API
     g_evolved_type_index := 0;
     for et in all_evolved_types loop

       -- we will get only DISTINCT Evoled-type and dependent evolved-type
       -- So for a case where
       --    T2 -> ( dependes on) T1
       --    T3 ->                T1
       --
       --    T1 will come thru above cursor and no need to find dependent evolved-type
       --    for each ( T2 and T3) type then.
       --
       --
       copy_evolved_type(et.referenced_owner, et.referenced_name, g_apps_ne_schema);
       -- bug 12747238
       put_obj_to_recompile(et.referenced_owner, et.referenced_name);
     end loop; -- For ALL EVOLVED-TYPES

     -- Install DDLs from global list to AD_ZD_DDL_HANDLER table
     install_evolved_types;
     recompile_types;
     compile_ne_schema(true);
     log(l_module, 'PROCEDURE', 'end');
   end COPY_EVOLVED_TYPES;


   --
   -- Get all evolved type referenced by tables as column type
   -- TODO: Currently this API is being populated as single API, reason being
   --       evolved type should be created in a proper order otherwise
   --       ALTER DDL command will fail and we may NOT get required hash-code.
   --
   procedure COPY_EVOLVED_TYPES_WRAPPER
   as
    l_module varchar2(80) := c_package || 'copy_evolved_types_wrapper';
    l_count number;
   begin
     log(l_module, 'PROCEDURE', 'begin');

      select count(1) into l_count
      from  dba_dependencies d
      where d.type = 'TABLE'
      and   d.name = upper(name)
      and   d.referenced_type = 'TYPE'
      and   d.referenced_name = upper(d.referenced_name)
      and   (
            d.referenced_owner in
            ( select oracle_username
              from   ebs_system.fnd_oracle_userid
              where  read_only_flag in ('A','B', 'E', 'U','C')
            )
           OR
            exists
            ( select 1
              from  dba_dependencies
              where owner = d.referenced_owner
              and   name  = d.referenced_name
              and   type  = d.referenced_type
              and   referenced_type = 'TYPE'
              and   referenced_owner in
                    (
                     select oracle_username
                     from ebs_system.fnd_oracle_userid
                     where  read_only_flag in ('A','B', 'E', 'U', 'C')
                    )
            )
           )
      and exists
              (  select 1
                 from sys.obj$ o
                 where owner# =(select user# from sys.user$ where name = referenced_owner)
                 and o.NAME = referenced_name
                 and o.type# = 13
                 and o.subname is not null
                )
     and not exists ( select null
                      from  xdb.xdb$element e
                      where e.xmldata.property.sqltype = d.referenced_name )
     and not exists (select null
                     from  xdb.xdb$element e
                     where e.xmldata.property.sqlcolltype = d.referenced_name);

     if(l_count > 0 ) then
       -- Note: Evolved types should be created in a proper order and dependent TYPEs should be VALID.
       --       otherwise ALTER TYPE command will fail. So let it be run by a single worker.
       load(x_phase => ad_zd_parallel_exec.c_phase_copy_evolved_type,
            x_sql     => 'begin ad_zd_prep.copy_evolved_types; end; ');

     end if;

     log(l_module, 'PROCEDURE', 'end');
  end COPY_EVOLVED_TYPES_WRAPPER;


  --  Evolved TYPES which are not being used as a COLUMN-TYPE (of a table)
  --  needs to be RESET to avoid: "ORA-38820: user has evolved object type"
  --  before enabling a user for editions.
  --
  --  NOTE: Restriction on RESET: cannot specify RESET if the type has any
  --        table dependents (direct or indirect).
  --
  procedure RESET_NOCOLUMN_EVOLVED_TYPES(X_OWNER in varchar2 )
  as
     l_module varchar2(80) := c_package || 'reset_nocolumn_evolved_types';
     /*
     cursor l_evolved_types is
       select distinct owner type_owner, type_name
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
        and not exists (select null
                        from dba_dependencies dep
                         where dep.referenced_type ='TYPE'
                           and dep.referenced_name = tver.type_name
                           and dep.type not in ('VIEW' ,'SYNONYM', 'PROCEDURE',
                                                'FUNCTION', 'PACKAGE', 'NON-EXISTENT',
                                                'PACKAGE BODY', 'TRIGGER', 'TYPE',
                                                'TYPE BODY', 'LIBRARY', 'ASSEMBLY')

                        );
      */

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
   -- TODO: Rename or CLEANUP this API
   -- Populates column owner (of an UDT type column) of a table in a list,
   -- which will be used  by FIX_COL_SYS() API
   --
   -- Note: we assume that the equivalent non-editioned type has already been
   --       been created in the non-editioned schema via the copy_type procedure.

  procedure FIX_COLUMN(X_OWNER       in varchar2,
                       X_TABLE       in varchar2,
                       X_COLUMN      in varchar2)
  is
    l_type_owner   varchar2(30);
    l_type_name    varchar2(30);
    l_autofix      number :=0;
    l_module varchar2(80) := c_package || 'fix_column';
    l_comma  varchar2(2)  := ', ';
  begin
    log(l_module, 'PROCEDURE', 'begin: '|| x_owner || l_comma || x_table || l_comma
                                        || x_column);
    -- get old column type information
    select col.data_type_owner, col.data_type
    into   l_type_owner, l_type_name
    from   dba_tab_columns col
    where  col.owner = x_owner
    and    col.table_name = x_table
    and    col.column_name = x_column;
    --
    -- 02-jun-2011: sstomar:
    --   Currently, including: schema1 =>'SYSTEM', schema2 => 'APPS_NE', typename => 'CCT_QDE_RESPONSE'
    --
    -- Not exist in <owner, type> list then only insert it
     if (is_type_exists_in_list(l_type_owner, l_type_name, g_udt_obj_list)= false )then
       g_udt_obj_indx := g_udt_obj_indx + 1;
       g_udt_obj_list(g_udt_obj_indx).owner := l_type_owner;
       g_udt_obj_list(g_udt_obj_indx).type_name := l_type_name;
     end if;
     log(l_module, 'PROCEDURE', 'end');
  end FIX_COLUMN;

   --
   -- PRIVATE
   --   Fix data dictionary to use non-editioned data type
   --
   --   FIX_COLUMNS
   --      |
   --       -->FIX_COLUMN
   --      |
   --       --> FIX_COL_SYS

   procedure FIX_COL_SYS as
     l_sql varchar2(4000);
     l_type_owner col_owners ;
     l_flag boolean := false;
     l_module varchar2(80) := c_package || 'fix_col_sys';
   begin

    log(l_module, 'PROCEDURE', 'begin');

    for idx in 1..g_udt_obj_list.count loop
      begin
        if(l_type_owner.count > 0 ) then
          if(l_type_owner( g_udt_obj_list(idx).owner) = 1  ) then
           l_flag := false;
          end if;
        else
         l_flag := true; -- first time.
        end if;
      exception
        when no_data_found then
          l_flag := true;   -- not in already updated list
      end;
      -- ST (sundeep.abraham@oracle.com): Suggested to use
      -- sys.dbms_objects_apps_utils.update_types('APPS', APPS_NE', NULL, TRUE) , instead of
      -- calling for specific TYPE
      --
      if(l_flag) then
        l_sql := 'begin ad_zd_prep.fix_types(' ||
                    'x_source_schema =>''' || g_udt_obj_list(idx).owner || ''', ' ||
                    'x_target_schema => '''|| g_apps_ne_schema || ''') ; end;' ;

        load(x_phase => ad_zd_parallel_exec.c_phase_fix_column,
             x_sql    => l_sql);

        l_type_owner(g_udt_obj_list(idx).owner) := 1;
      end if;
    end loop;

    log(l_module, 'PROCEDURE', 'end');
   end FIX_COL_SYS;

   --
   -- Fix AQ to use Non-Editioned payload type
   --
   -- Process works as follows:
   --   1) Stop queue
   --   2) Fix up payload column
   --   3) Start queue
   --
   -- Note: multiple queues can be attached to the same queue table, we need to
   -- deal with all of them at once.
   --
   --
   procedure FIX_QUEUE(x_owner in varchar2, x_table in varchar2, x_column in varchar2)
   is
     l_module varchar2(80) := c_package || 'fix_queue';
     l_queue      varchar2(80);
     l_queue_type varchar2(30);

     cursor C_QUEUES(X_OWNER VARCHAR2, X_TABLE VARCHAR2) IS
       select '"'||aq.owner || '"."' || aq.name ||'"',
              aq.queue_type
       from   dba_queues aq
       where  aq.owner = x_owner
       and    aq.queue_table = x_table
       and    not ( aq.name like 'XLA_%_COMP_Q'
                    OR aq.name like 'XLA_%_DOC_Q' );

   begin
     log(l_module, 'PROCEDURE', 'begin: ' || x_owner || '.'|| x_table || ', ' || x_column);
     -- Stop related queues
     open c_queues(x_owner, x_table);
     fetch c_queues INTO l_queue, l_queue_type;
     --
     -- Merging with COPY_TYPE phase as both are independent.
     while (c_queues%found) loop
       load(x_phase => ad_zd_parallel_exec.c_phase_copy_type,
            x_sql   => 'begin ad_zd_prep.stop_queue(''' || l_queue ||'''); end;');

       fetch c_queues INTO l_queue, l_queue_type;
     end loop;
     -- close cursor
     CLOSE c_queues;
     -- Fix payload column
     fix_column(x_owner, x_table, x_column);

     -- This phase should be executed after DROP_OBJECT, so if still there is any UDT reference
     -- , can be fixed.
     load(x_phase => ad_zd_parallel_exec.c_phase_recreate_aq_object,
          x_sql   => 'begin ad_zd_prep.recreate_aq_object(''' || x_owner ||''', ''' || x_table ||'''); end;');

     log(l_module, 'PROCEDURE', 'end');
   end FIX_QUEUE;

   --
   -- Recreates associated objects of an AQ after UDT reference fix.
   --
   --
   procedure RECREATE_AQ_OBJECT(X_OWNER in varchar2, X_TABLE in varchar2)
   is
     l_module     varchar2(80) := c_package || 'recreate_aq_object';
     l_qt_flags   number;
     cursor c_queues is
       select aq.name,
              aq.queue_type
       from   dba_queues aq
       where  aq.owner = x_owner
       and    aq.queue_table = x_table;
     l_flags      number;

   begin

    log(l_module, 'PROCEDURE', 'begin: ' || x_owner || '.' || x_table);

    begin
      $IF (DBMS_DB_VERSION.VERSION >= 23) $THEN
         -- RDBMS BUG 34886366 - DB23C: PLS-00904: INSUFFICIENT PRIVILEGE TO ACCESS OBJECT CREATE_BASE_VIEW
         log(l_module, 'EVENT',
                'Call dbms_aqadm.migrate_queue_table('|| x_owner||'.'||x_table||', '|| l_qt_flags||')');
           l_flags := DBMS_AQADM.CREATE_QT_BASE_VIEW;
           dbms_aqadm.migrate_queue_table('x_owner'||'.'||'x_table',l_flags);
    exception
      when others then
        log(l_module, 'ERROR', 'Error: '|| x_owner ||'.'|| x_table || ' '|| substr(sqlerrm,1,2000));
    end;
    $ELSE

       -- Regenerate derived objects
       select flags into l_qt_flags
       from   system.aq$_queue_tables
       where  schema = x_owner
       and    name = x_table;
       -- RDBMS BUG 14206186: SHBOSE:
       -- Note that sys.dbms_prvtaqim.create_base_view internally calls
       -- sys.dbms_prvtaqim.create_deq_view. So you may not need to call another
       -- create_deq_view.
       --
       if (sys.dbms_aqadm_sys.mcq_8_1(l_qt_flags)) then
         -- For new multiconsumer queue (8.1 style and above)
         sys.dbms_aqadm_sys.create_buffer_view(x_owner, x_table, true);
         log(l_module, 'EVENT',
             'Call sys.dbms_prvtaqim.create_base_view('|| x_owner||', '||x_table ||', '|| l_qt_flags||')');
         sys.dbms_prvtaqim.create_base_view(x_owner, x_table, l_qt_flags);
       else
         --  only for 8.0 style queues
         log(l_module, 'EVENT',
             'Call sys.dbms_aqadm_sys.create_base_view('|| x_owner||', '||x_table||', '|| l_qt_flags||')');
         sys.dbms_aqadm_sys.create_base_view(x_owner, x_table, l_qt_flags);
       end if;
     exception
       when others then
        log(l_module, 'ERROR', 'Error: '|| x_owner ||'.'|| x_table || ' '|| substr(sqlerrm,1,2000));
     end;
    $END
     -- Start queue
     -- TODO: Start EXCEPTION AQ Also ?
     --
     for queue in c_queues loop
      if (queue.queue_type =  'NORMAL_QUEUE') then
       start_queue('"'|| x_owner ||'"."'|| queue.name || '"');
      end if;
     end loop;
     log(l_module, 'PROCEDURE', 'end');
   exception
     when no_data_found then
       null;
   end RECREATE_AQ_OBJECT;


   --
   -- Fix all columns that depend on editioned types
   --
   -- Note: we assume that the equivalent non-editioned types have already
   -- been created in the non-editioned schema via the copy_type procedure.
   --
   procedure FIX_COLUMNS
   is
     L_OWNER        varchar2(30);
     L_TABLE        varchar2(30);
     L_COLUMN       varchar2(30);
     L_QUEUE_COUNT  number;
     l_orig_util_id number;

     cursor C_EBS_SCHEMAS is
       select oracle_username
       from   ebs_system.fnd_oracle_userid
       where  read_only_flag in ('A','B', 'E', 'U', 'C');

     -- problem column query
     cursor C_COLUMNS (p_owner varchar2) is
       select
           atab.owner            table_owner
         , atab.table_name       table_name
         , acol.column_name      column_name
       from
           dba_tables      atab
         , dba_tab_columns acol
       where atab.owner = p_owner /* Due to performance issue, not using
                                     inner query with fnd_oracle_userid */
       and   acol.owner      = atab.owner
       and   acol.table_name = atab.table_name
       and   acol.data_type_owner in   -- User defined data type (UDT)
             ( select oracle_username
               from   ebs_system.fnd_oracle_userid
               where  read_only_flag in ('A','B', 'E', 'U', 'C')
             )
       order by 1, 2, 3;

       -- This cursor for columns of SYSTEM.<UDT> AND SYSTEM.<UDT> depends
       -- on <EBS schema>.UDT
       --
       cursor C_COLUMNS2(p_owner varchar2) is
         select
             atab.owner            table_owner
           , atab.table_name       table_name
           , acol.column_name      column_name
         from
             dba_tables      atab
           , dba_tab_columns acol
         where acol.owner      = atab.owner
         and   acol.table_name = atab.table_name
         and   atab.owner = p_owner
         and   acol.data_type_owner='SYSTEM'
         and  exists
              (
                select    1
                from   dba_dependencies dep
                where   dep.type = 'TYPE'
                start with  dep.owner   = acol.data_type_owner
                   and  dep.name        = acol.DATA_TYPE
                   and dep.type          = 'TYPE'
                   and dep.referenced_type= 'TYPE'
                   and dep.referenced_owner <> 'SYSTEM'
                connect by
                      prior dep.referenced_name  = dep.name
                  and prior dep.referenced_type  = dep.type
                  and prior dep.referenced_type  = 'TYPE'
                  and   dep.referenced_owner in (
                          select oracle_username
                          from   ebs_system.fnd_oracle_userid
                          where  read_only_flag in ('A','B', 'E', 'U', 'C')
                        )
              )
         order by 1,2,3;

     l_module varchar2(80) := c_package || 'fix_columns';

   begin
     log(l_module, 'PROCEDURE', 'begin');

     for l_schema_rec in c_ebs_schemas loop
       for l_udt_rec in c_columns(l_schema_rec.oracle_username) loop

         select count(name) into l_queue_count
         from   dba_queues
         where  owner       = l_udt_rec.table_owner
           and  queue_table = l_udt_rec.table_name;

         -- If it is a queue table, then fix the overall queue,
         -- otherwise, just fix the column
         if l_queue_count > 0 then
           fix_queue(l_udt_rec.table_owner, l_udt_rec.table_name, l_udt_rec.column_name);
         else
           fix_column(l_udt_rec.table_owner, l_udt_rec.table_name, l_udt_rec.column_name);
         end if;

       end loop;
     end loop;

     -- for SYSTEM.UDT columns
     -----------------------------------------------
     for l_schema_rec in c_ebs_schemas loop
       for l_udt_rec in c_columns2(l_schema_rec.oracle_username) loop

         select count(name) into l_queue_count
         from   dba_queues
         where  owner       = l_udt_rec.table_owner
           and  queue_table = l_udt_rec.table_name;

         -- If it is a queue table, then fix the overall queue,
         -- otherwise, just fix the column
         if l_queue_count > 0 then
           fix_queue(l_udt_rec.table_owner, l_udt_rec.table_name, l_udt_rec.column_name);
         else
           fix_column(l_udt_rec.table_owner, l_udt_rec.table_name, l_udt_rec.column_name);
         end if;

       end loop;
     end loop;

     -----------------------------------------------
     -- Special query to update SYS tables
     -- Reason: There would be other DATABASE objects like table which would be dependent
     --      on UTDs, now update their dependency to refer to APPS_NE UDT.
     --
     --
     fix_col_sys;
     log(l_module, 'PROCEDURE', 'end');
   end FIX_COLUMNS;

  --
  --  - PUBLIC Synonyms point to editioned EBS objects must be dropped,
  --  - PUBLIC Synonyms cannot be editioned so they should be replaced by
  --    an equivalent private synonyms.
  --
  procedure FIX_PUBLIC_SYNONYMS as
    L_MODULE varchar2(80) := c_package || 'fix_public_synonyms';

    cursor C_PUBLIC_SYNONYMS is
      select syn.synonym_name ,
             syn.table_owner  ,
             syn.table_name   ,
             syn.db_link
      from  dba_synonyms syn
      where syn.owner='PUBLIC'
      and   syn.table_owner in
              (select oracle_username
               from   ebs_system.fnd_oracle_userid
               where read_only_flag in ('A','B', 'E', 'C', 'U'))
      and   (syn.table_owner, syn.table_name) in
              (select obj.owner, obj.object_name
               from   dba_objects obj
               where  obj.owner = syn.table_owner   -- To avoid GSCC error
               and    obj.object_type in ('TYPE',   'PACKAGE', 'VIEW' ,
                                          'SYNONYM','PROCEDURE',
                                          'TRIGGER','FUNCTION'));
  begin
    log(l_module, 'PROCEDURE', 'begin');
    for rec in c_public_synonyms loop
      load(x_phase=> ad_zd_parallel_exec.c_phase_fix_public_synonym,
           x_sql  => 'begin ad_zd_prep.fix_public_synonym(''' || rec.synonym_name || ''', ''' ||
                     rec.table_owner || ''',''' || rec.table_name ||''','''|| rec.db_link || '''); end;');

    end loop;
    log(l_module, 'PROCEDURE', 'end');
  end FIX_PUBLIC_SYNONYMS;


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
     L_MODULE      varchar2(80) := c_package || 'fix_public_synonym';
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

   --
   -- Drop CTXSYS SYNONYMS
   --
   procedure DROP_CTXSYS_SYNONYM(X_SYNONYM_NAME varchar2) is
     l_module varchar2(80) := c_package || 'drop_ctxsys_synonym';
   begin
    log(l_module, 'PROCEDURE', 'begin: CTXSTS.' || X_SYNONYM_NAME);
    exec(X_SQL =>'drop synonym CTXSYS."'||X_SYNONYM_NAME ||'"' , X_LOG_MOD=>l_module, X_IGNORE=> true);
    log(l_module, 'PROCEDURE', 'end');
   end DROP_CTXSYS_SYNONYM;

   --
   -- Drop CTXSYS package
   --
   procedure DROP_CTXSYS_PKG(X_PACKAGE_NAME varchar2) is
    l_module varchar2(80) := c_package || 'drop_ctxsys_pkg';
   begin
    log(l_module, 'PROCEDURE', 'begin: CTXSYS.'|| X_PACKAGE_NAME);
    exec(X_SQL =>'drop package CTXSYS."'||X_PACKAGE_NAME ||'"', X_LOG_MOD=> l_module, X_IGNORE=> true);
    log(l_module, 'PROCEDURE', 'end');
   end DROP_CTXSYS_PKG;

   --
   -- Fix PLSQL packages installed in CTXSYS (context indexing)
   --
   -- TODO: migrate packages to APPS and repair CTXSYS definition.
   -- HACK: For now we just drop them.
   --
   -- NOTE: BUGS has already been filed against product teams to fix their objects.
   --       Here, we are just droping them from CTXSYS
   --
   procedure FIX_CTXSYS
   is
     l_module varchar2(80) := c_package || 'fix_ctxsys';
     cursor ctxpkg is
        select distinct name
        from  dba_dependencies
        where owner='CTXSYS'
        and   TYPE='PACKAGE BODY'
        and   referenced_owner in
              ( select oracle_username
                from   ebs_system.fnd_oracle_userid
                where  read_only_flag in ('A','B', 'E', 'U', 'C')
              )
       and referenced_type in
                  ( 'TYPE',
                    'PACKAGE',
                    'VIEW' ,
                    'SYNONYM',
                    'PROCEDURE',
                    'TRIGGER',
                    'FUNCTION'
                   );
     --
     -- Synonyms in CTXSYS for EBS objects.
     cursor C_SYNONYMS is
       select aps.synonym_name
       from   dba_synonyms aps
       where  aps.owner       = 'CTXSYS'
       and    aps.table_owner in
              ( select oracle_username
                from   ebs_system.fnd_oracle_userid
                where  read_only_flag in ('A','B', 'E', 'U','C')
               )
       order by 1;

   begin
     log(l_module, 'PROCEDURE', 'begin');
     for rec in ctxpkg loop
       load(x_phase => ad_zd_parallel_exec.c_phase_drop_object,
            x_sql  => 'begin ad_zd_prep.drop_ctxsys_pkg(''' || rec.name || '''); end;');

     end loop;

     -- drop problematic synonyms
     for rec in c_synonyms loop
       load(x_phase => ad_zd_parallel_exec.c_phase_drop_object,
            x_sql   => 'begin ad_zd_prep.drop_ctxsys_synonym(''' || rec.synonym_name || '''); end;');
     end loop;
     log(l_module, 'PROCEDURE', 'end');
   end FIX_CTXSYS;


  --
  -- This is used to fix EBR violations for custom users
  --
  procedure FIX_CUSTOM_OBJECTS(x_user varchar2)
  is
    L_MODULE varchar2(80) := c_package || 'fix_custom_objects';

    -- Objects which would become INVALID when specified user is enabled for
    -- editions.
    cursor C_INVALIDATED_OBJECTS(P_USER varchar2) is
     select dep.d_obj# d_obj, do.name d_name, do.type# d_type,
            dep.p_obj# p_obj, po.name p_name, po.type# p_type
      from  sys.dependency$ dep,
            sys.obj$ do,
            sys.obj$ po
      where do.obj# = dep.d_obj#
        and po.obj# = dep.p_obj#
        -- Only Non-Editionable objects, 55:XML SCHEMA-> is a Non-Editioned object
        and do.type# not in (4,5,7,8,9,10,11,12,13,14,22,87)
      start with dep.p_obj# in (select  o.obj#
                                from sys.obj$ o,
                                     sys.user$ u
                                where u.name  = P_USER
                                  and u.user# = o.owner#
                                  and o.type# in (4,5,7,8,9,10,11,12,13,14,22,87) )
      connect by nocycle prior dep.d_obj# = dep.p_obj#;

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


    -- XML schema owned by custom user
    cursor C_XML_SCHEMAS is
      select owner, schema_url
      from  dba_xml_schemas
      where owner =x_user;

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

    ad_zd_prep.reset_nocolumn_evolved_types(x_user);

    for l_invalidated_object in c_invalidated_objects(x_user) loop
      log(l_module, 'STATEMENT', 'Non-Editionable Object ('|| l_invalidated_object.d_name ||
                                 ',' || l_invalidated_object.d_type || '), dependent on (' ||
                                 l_invalidated_object.p_name || ',' || l_invalidated_object.p_type || ')');
      case
        --CASE#1: Table is dependent on TYPE
        --        This condition is also true when table is dependet on a TYPE descended
        --        from an XML schema
        when (l_invalidated_object.d_type = 2 and
              l_invalidated_object.p_type = 13) then

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

        --CASE#2: Table dependent on an XML schema
        --       (and TYPES descended from XML schema will also be covered)
        when (l_invalidated_object.d_type = 2 and
              l_invalidated_object.p_type = 55) then

          log(l_module, 'STATEMENT', 'Fix XML schema: ');

          -- This is fine to run XML schema mover for all users as it will pick-up those
          -- users which are registered in fnd_oracle_userid (Only cost here is performance)
          -- TODO: Wait for DB fix 16286729, otherwise locking issue might occur.
          ad_zd_prep.move_xml_schemas;

        -- CASE#3: MV is dependent on function, throw error as this can be fixed automatically.
        when (l_invalidated_object.d_type = 42 and
              l_invalidated_object.p_type = 8) then
          -- throw error
          log(l_module, 'ERROR', 'MV:' || l_invalidated_object.d_name ||
                                 ',  dependent on: ' || l_invalidated_object.p_name);
          raise_application_error(-20005, 'Materialized view(s) which is/are dependent on a function, ' ||
                                          'can not be fixed automatically. Run Readiness Report from Note 1531121.1 ' ||
                                          'and fix them manually.');

        -- CASE#4: MV is dependent any other type of object i.e. other than a function.
        when (l_invalidated_object.d_type = 42 and
              l_invalidated_object.p_type <> 8 ) then

          -- Expand MVs
          -- TODO: This ideally should be done after upgrading Tables of this user
          for l_mv in C_MVS loop
            log(l_module, 'STATEMENT', 'Fix MV: ' || l_mv.owner || '.' || l_mv.name);
            ad_zd_mview.upgrade(l_mv.owner, l_mv.name);
          end loop;
      end case;
    end loop;

    -- Fix public synonyms.
    -- NOTE: Public synonyms will NOT have any record in sys.dependencies$ table
    for l_rec in c_public_synonyms loop
      log(l_module, 'STATEMENT', 'Fix PUBLIC synonym: ' || l_rec.synonym_name);
      ad_zd_prep.fix_public_synonym(l_rec.synonym_name, l_rec.table_owner, l_rec.table_name, l_rec.db_link);
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
  -- Registers a schema with fnd_oracle_userid with READ_ONLY_FLAG='B'
  --
  procedure REGISTER_CUSTOM_USER(X_USER varchar2) is
    L_STMT          varchar2(1000);
  begin
    -- use execute immediate so that AD won't have any hard dependency on FND
    l_stmt := 'begin fnd_oracle_user_pkg.load_row (:1, ''CUSTOM'', ''INVALID'', NULL, ''N'', ''B''); end;';
    execute immediate l_stmt using X_USER;
    commit;

  end REGISTER_CUSTOM_USER;
  --
  -- Enables the user for EDITIONS.
  -- NOTE: This procedure uses "force" mode to enable users for editions.
  procedure ENABLE_USER_4EDITION(X_USERNAME varchar2) as
   L_MODULE varchar2(80) := c_package || 'enable_user_4edition';
  begin
    log(l_module, 'PROCEDURE', 'begin: '|| x_username || ' enabling for editions');
    exec('alter user "'||x_username||'" enable editions force', l_module);
    log(l_module, 'PROCEDURE', 'end');
    exception when others then
         raise_application_error(-20979, 'User : ' || x_username || ' is not enabled for editions.');
  end ENABLE_USER_4EDITION;


  --
  -- Enables a custom schema for editions.
  --  - If schema is not registered with E-biz, it will register it.
  --  - Fixes custom objects owned by custom schema
  --  - Upgrade tables for EV, owned by custom schema
  --
  procedure ENABLE_CUSTOM_USER(X_USER varchar2)
  is
    L_MODULE varchar2(80) := c_package || 'enable_custom_user';
    L_ENABLE_EDITIONS_ERROR EXCEPTION;
    PRAGMA EXCEPTION_INIT(l_enable_editions_error, -38819);
    L_STMT varchar2(250);
    l_exists number :=0;

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
       ( X_USER ='APPS_NE'
        or
        exists
       (select u.name
       from sys.registry$ r,
          sys.user$ u
       where r.status in (1,3,5)
       and   r.namespace = 'SERVER'
       and   r.schema#   = u.user#
       and   u.name      = X_USER
       union
       select u.name
       from  sys.registry$ r,
          sys.registry$schemas s,
          sys.user$ u
      where r.status in (1,3,5)
      and   r.namespace = 'SERVER'
      and   r.cid       = s.cid
      and   s.schema#   = u.user#
      and   u.name      = X_USER)
      );
      exception
      when no_data_found then
      null;
    end;

     if ( l_exists > 0) then
     log(l_module, 'ERROR', 'Schema' ||  X_USER || 'is Non Editionable');
     raise_application_error(-20006, 'Can not enable user for editions. ' || sqlerrm);
     end if;

    begin
      l_stmt := 'alter user "'||x_user||'" enable editions';
      log(l_module, 'STATEMENT', 'Enable '|| x_user || ' user for editions');
      execute immediate l_stmt;
    exception
      when l_enable_editions_error then
        log(l_module, 'STATEMENT', 'User '|| x_user || 'has objects which violate Edition-Based-Redefinition rules');
        /*
        ORA-38819: user SH_USER owns one or more objects whose type is editionable and
        that have noneditioned dependent objects
        */
        fix_custom_objects(x_user);

        -- retrye without force mode
        begin
          log(l_module, 'STATEMENT', 'Retry: Enable '|| x_user || ' user for editions');
          execute immediate l_stmt;
          log(l_module, 'STATEMENT', 'User '|| x_user || ' has been enabled for editions');
        exception
          when l_enable_editions_error then
            log(l_module, 'ERROR', 'User '|| x_user || 'Can not enable user for editions. ' || sqlerrm);
            raise_application_error(-20006, 'Can not enable user for editions. ' || sqlerrm);
        end;
    end;

    log(l_module, 'STATEMENT', 'Upgrade custom tables owned by: '|| x_user || ' user');
    for l_rec in c_tables loop
      ad_zd_table.upgrade(l_rec.table_owner, l_rec.table_name);
    end loop;

    commit;
    log(l_module, 'STATEMENT', 'end');

  end ENABLE_CUSTOM_USER;

   --
   --
   -- NOTE: This should be run after completing all the DDLs i.e.
   --       EBR violations has been removed from target database.
   --
   -- This API should be (SYS or SYSTEM) as SYSDBA
   --
   -- Enable Editions for ALL users
   --
   procedure ENABLE_EDITIONS as
     l_module varchar2(80) := c_package || 'enable_editions';
     cursor c_users is
       select fou.oracle_username username
       from  ebs_system.fnd_oracle_userid fou
            , dba_users du
       where fou.read_only_flag in ('A','B', 'E', 'U', 'C')
       and   du.editions_enabled = 'N'
       and   du.username = fou.oracle_username
       and   not exists
              (select u.name
               from sys.registry$ r,
                    sys.user$ u
               where r.status in (1,3,5)
               and   r.namespace = 'SERVER'
               and   r.schema#   = u.user#
               and   u.name      = du.username
              union
              select u.name
              from  sys.registry$ r,
                    sys.registry$schemas s,
                    sys.user$ u
              where r.status in (1,3,5)
              and   r.namespace = 'SERVER'
              and   r.cid       = s.cid
              and   s.schema#   = u.user#
              and   u.name      = du.username
             );
   begin
     log(l_module, 'PROCEDURE', 'begin');

     for rec in c_users loop
       load(x_phase => ad_zd_parallel_exec.c_phase_enable_editioning,
            x_sql  => 'begin ad_zd_prep.enable_user_4edition('''||rec.username||'''); end;');

     end loop;
     log(l_module, 'PROCEDURE', 'end');
   end ENABLE_EDITIONS;


   --
   -- This API generates DDLs or PL/SQL blocks for EBR violations as well
   -- as TABLE, MV upgrades.
   --
   --
   procedure DO_PREP
   as
    c_module varchar2(80) := c_package || 'DO_PREP';

   begin

     log(c_module, 'PROCEDURE', 'begin' );
     dbms_application_info.set_module('AD_ZD_PREP', 'DDL GENERATION');

     log(c_module, 'STATEMENT', 'Cleaning up AD_ZD_DDL_HANDLER table' );

     -- **** Clean ONLY DB PREP data, as SEED-UPGRADE data
     --      has already been populated *****.
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_drop_unused_object);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_copy_type);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_compile_type);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_copy_evolved_type);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_fix_column);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_fix_type);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_fix_public_synonym);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_recreate_aq_object);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_drop_object);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_enable_editioning);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_upgrade_table);
     ad_zd_parallel_exec.cleanup(ad_zd_parallel_exec.c_phase_upgrade_mview);

     -- STEP#1)
     log(c_module, 'STATEMENT', 'Invoking drop_temp_queues ' );
     drop_temp_queues;
     commit;

     ad_zd_prep.reset_nocolumn_evolved_types;

     --STEP#2 : copy_types also populates compile_ne_schema API.
     copy_types;
     commit;

     --step#3
     copy_evolved_types_wrapper;
     --step#5
     log(c_module, 'STATEMENT','Invoking fix_columns API.' );
     fix_columns;
     commit;

     -- STEP#6) Objects from CTXSYS as CTXSYS is Non-Editioned
     log(c_module, 'STATEMENT', 'Invoking fix_ctxsys API.' );
     fix_ctxsys;
     commit;

     -- STEP#7) : fix_synonyms;
     log(c_module, 'STATEMENT', 'Invoking fix_public_synonyms API.' );
     fix_public_synonyms;
     commit;
     --step#8
     log(c_module, 'STATEMENT', 'Invoking enable_editions API.' );
     enable_editions;
     commit;

     -- STEP#2) Materialized Views
     log(c_module, 'STATEMENT', 'Invoking ad_zd_mview.upgrade_db API.' );
     ad_zd_mview.upgrade_db(0);
     commit;    --

     log(c_module, 'STATEMENT', 'Invoking ad_zd_table.upgrade_db API.' );
     ad_zd_table.upgrade_db;
     commit;
     log(c_module, 'PROCEDURE','end' );
   exception
    when others then
      log(c_module, 'ERROR','E-Business Suite Database Preparation for Editions:'
               || sqlcode || ' ' || substr(sqlerrm, 1, 64) );
      raise_application_error(-20997,
               'E-Business Suite Database Preparation for Editions: '
               || sqlcode || ' ' || substr(sqlerrm, 1, 64));
   end do_prep;
$end

end AD_ZD_PREP;
