
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_FIXER" AUTHID CURRENT_USER as
/* $Header: ADZDFIXS.pls 120.0.12020000.3 2015/06/09 11:21:31 rraam noship $ */
procedure FIX_ADOP_REPO_TABLES(ORIGINAL_APPLTOP_ID in number,
                                  ORIGINAL_NODENAME in varchar2,
                                  NEW_APPLTOP_ID in number,
                                  NEW_NODENAME in varchar2);

procedure CLEAR_ADOP_REPO_TABLES(X_FULL in boolean default FALSE);

procedure CLEAR_VALID_NODES_INFO;

end AD_ZD_FIXER;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_FIXER" AS
/* $Header: ADZDFIXB.pls 120.0.12020000.5 2015/08/21 09:29:46 asutrala noship $ */
procedure FIX_ADOP_REPO_TABLES(ORIGINAL_APPLTOP_ID in number,
                                  ORIGINAL_NODENAME in varchar2,
                                  NEW_APPLTOP_ID in number,
                                  NEW_NODENAME in varchar2)
is
  L_UPDATE_SESSIONS_QUERY   varchar2(4999);
  L_UPDATE_SESS_PATCH_QUERY varchar2(1000);
  L_DELETE_LOCK_PATCH_QUERY varchar2(1000);
  L_DELETE_LOCK_SESS_QUERY  varchar2(1000);
  L_SESSION_INPUT_DATA      varchar2(4000);
  L_SESSION_INPUT_DATA_QRY  varchar2(1000);
  SESSION_ID                number;
begin
  -- validations for parameters
  if( original_appltop_id is null) then
    raise_application_error(-20001,'The parameter original_appltop_id must be defined');
  end if;
  if( original_nodename is null) then
    raise_application_error(-20002,'The parameter original_nodename must be defined');
  end if;
  if(new_appltop_id is null and new_nodename is null) then
    raise_application_error(-20003,'Either new_appltop_id or new_nodename parameter must be defined');
  end if;

  begin
    -- Get the current session id
    select max(adop_session_id) into session_id
    from ad_adop_sessions
    where node_name=original_nodename;
    -- Get the session input data of current session id
    select session_input_data into l_session_input_data
    from ad_adop_sessions
    where adop_session_id=session_id
    and node_name=original_nodename;
  exception
    when no_data_found then
      session_id:=0;
      l_session_input_data:='';
  end;

  --initialize the update queries
  l_update_sessions_query := 'UPDATE ad_adop_sessions set ';
  l_update_sess_patch_query := 'UPDATE ad_adop_session_patches set ';
  l_delete_lock_patch_query := 'DELETE from ad_adop_session_patches ' ||
             ' where node_name = '''||original_nodename||''' and adop_session_id=0';
  l_delete_lock_sess_query := 'DELETE from ad_adop_sessions ' ||
             ' where node_name = '''||original_nodename||''' and adop_session_id=0';

  if new_appltop_id is not null then
    l_update_sess_patch_query := l_update_sess_patch_query||'appltop_id ='||new_appltop_id||',';
    l_update_sessions_query := l_update_sessions_query||'appltop_id ='||new_appltop_id||',';
  end if;


  if new_nodename is not null then
    l_update_sess_patch_query := l_update_sess_patch_query||'node_name ='''||new_nodename||''',';
    l_update_sessions_query := l_update_sessions_query||'node_name ='''||new_nodename||''',';
    if regexp_like(l_session_input_data,original_nodename) then
      l_session_input_data_qry:='update ad_adop_sessions set session_input_data=regexp_replace(session_input_data,';
      l_session_input_data_qry:=l_session_input_data_qry||'''#'||original_nodename||';''';
      l_session_input_data_qry:=l_session_input_data_qry||',''#'||new_nodename||';'')';
      l_session_input_data_qry:=l_session_input_data_qry||' where node_name='''||original_nodename;
      l_session_input_data_qry:=l_session_input_data_qry||''' and appltop_id='||original_appltop_id||' and adop_session_id=';
      l_session_input_data_qry:=l_session_input_data_qry||session_id;
      execute immediate l_session_input_data_qry;
      commit;
    end if;

    -- update adop_valid_nodes table with new nodename
    declare
      table_does_not_exist exception;
      PRAGMA EXCEPTION_INIT(table_does_not_exist, -00942);
    begin
      execute immediate 'delete from adop_valid_nodes '||
                        'where node_name='''||original_nodename||'''';
    exception
      when table_does_not_exist
        then null;
    end;
  end if;

  --Add conditions to the update queries and complete it
  l_update_sessions_query := l_update_sessions_query||'pid=0 ';
  l_update_sessions_query := l_update_sessions_query||' where node_name='''||original_nodename||
                              ''' and appltop_id='||original_appltop_id;
  l_update_sessions_query := l_update_sessions_query ||' and adop_session_id='||session_id;

  l_update_sess_patch_query :=RTRIM(l_update_sess_patch_query,',');
  l_update_sess_patch_query := l_update_sess_patch_query||' where node_name ='''||original_nodename||
                              ''' and appltop_id='||original_appltop_id;

  -- Update rows for patches which are not yet synchronized
  -- or clone/config clone rows which are not yet complete
  l_update_sess_patch_query := l_update_sess_patch_query ||' and (patch_file_system_base is NULL'||
                      ' OR (bug_number in (''CLONE'',''CONFIG_CLONE'') AND status in (''N'',''R'',''F'')))';

  -- Execute the queries
  execute immediate l_delete_lock_sess_query;
  execute immediate l_delete_lock_patch_query;
  execute immediate l_update_sessions_query;
  execute immediate l_update_sess_patch_query;

  commit;
end FIX_ADOP_REPO_TABLES;


/*
 An API to clear data from adop repository tables. This is a standalone API
 which suer can run if there is a reuirement. It accepts a boolean parameter.

 X_FULL - FALSE(default)
    Removes entires of sessions which are already completed. Retains
    information which are not yet complete.
 X_FULL - TRUE
    Truncates the repository tables. Should be run only when user is sure
    all data can be safely removed.

*/

procedure CLEAR_ADOP_REPO_TABLES(X_FULL in boolean default FALSE)
is
begin
  if x_full then
    delete from ad_adop_sessions;
    delete from ad_adop_session_patches;
    commit;
    return;
  end if;

  delete from ad_adop_session_patches aasp
  where
    /* completed clone rows */
        (bug_number IN ('CLONE','CONFIG_CLONE')
         and status='Y')
    /* synchronized or aborted patches */
  or    (bug_number NOT IN ('CLONE','CONFIG_CLONE')
         and patch_file_system_base is NOT NULL)
     /* failed patches/clone actions from abandoned nodes */
  or    exists (select null
                from   ad_adop_sessions aas
                where  aas.node_name=aasp.node_name
                and    aas.adop_session_id=aasp.adop_session_id
                and    aas.abandon_flag is NOT NULL
                and    aas.adop_session_id<>(select max(aas2.adop_session_id)
                                             from ad_adop_sessions aas2)
                );

  delete from ad_adop_sessions aas
  /* delete rows for all nodes where cycle completed in master node*/
  where aas.adop_session_id IN (select adop_session_id
                                from   ad_adop_sessions
                                where node_type='master'
                                /* completed or aborted online patching cycle*/
                                and   (cutover_status='Y' or abort_status='Y'
                                /*hotpatch/downtime patching cycle*/
                                       or cutover_status='X')
                                and   cleanup_status='Y');
  commit;
end CLEAR_ADOP_REPO_TABLES;

/* Remove all entries from ADOP_VALID_NODES table.
  This is primarily used as for data guard switchover/failover
  scenario */
procedure CLEAR_VALID_NODES_INFO
is
begin
  delete from adop_valid_nodes;
  commit;
end CLEAR_VALID_NODES_INFO;

END AD_ZD_FIXER;