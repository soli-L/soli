
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_ADOP" AUTHID CURRENT_USER AS
/* $Header: ADZDADOPS.pls 120.18.12020000.48 2017/11/08 15:44:57 jvalenti ship $ */

/*
** Constants
*/
--C_NE_OWNER varchar2(30) := 'SYSTEM';

TYPE adrecord IS RECORD(BugNumber varchar2(30), File_edition varchar2(512),
Status varchar2(30), node varchar2(256));
TYPE adrecordtable IS TABLE OF adrecord
INDEX BY BINARY_INTEGER;
PROCEDURE ADOP_PATCH_APPLY_STATUS(adop_sessionID NUMBER, ADOP_tab out
adrecordtable, stat varchar2 default 'ALL', node varchar2 default 'ALL');

FUNCTION  GETPATCHNUMBERS RETURN VARCHAR2;

FUNCTION SUBMIT_REQUEST RETURN NUMBER;
FUNCTION WAIT_FOR_CP_TO_RUN (REQID IN NUMBER) RETURN NUMBER;

FUNCTION IS_PATCH_APPLIED_IN_MASTER(x_patch_no in varchar2,
                                    x_host IN VARCHAR2 default NULL
                                   ) RETURN NUMBER;

FUNCTION GET_ACTIVE_CP_REQUEST_ID RETURN NUMBER;

PROCEDURE GET_ACTIVE_CP_REQ_ID(p_req_id OUT NOCOPY NUMBER);

PROCEDURE KILL_OLD_SESSIONS(p_session_id IN NUMBER);

PROCEDURE INSERT_INTO_PATCHES_TABLE(
                                    p_session_id IN NUMBER,
                                    p_bug_number IN VARCHAR2,
                                    p_patch_run_id IN NUMBER,
                                    p_appltop_base IN VARCHAR2,
                                    p_adpatch_options IN VARCHAR2,
                                    p_autoconfig_status IN VARCHAR2,
                                    p_start_date IN DATE,
                                    p_end_date IN DATE,
                                    p_patch_top IN VARCHAR2,
                                    p_driverfile_name IN VARCHAR2,
                                    p_status IN VARCHAR2,
                                    p_utility IN VARCHAR2 default 'ADPATCH',
                                    p_host IN VARCHAR2 default NULL
                                  );

FUNCTION GET_CUTOVER_STATUS(p_appltop_id in number,p_node_name in varchar2,p_session_id in number) return varchar2;

PROCEDURE SET_CUTOVER_STATUS(
                             p_appltop_id in number,
                             p_node_name in varchar2,
                             p_status in varchar2
                            );

FUNCTION GET_ADZDPATCH_STATUS(REQID IN NUMBER) RETURN VARCHAR2;
PROCEDURE LOCK_SESSIONS_TABLE(p_node_name in varchar2,p_wait_interval in number,p_num_tries in number);
PROCEDURE UNLOCK_SESSIONS_TABLE(p_node_name in varchar2,p_wait_interval in number,p_num_tries in number);
PROCEDURE LOCK_PATCHES_TABLE(p_node_name in varchar2,p_lock_name in varchar2);
PROCEDURE UNLOCK_PATCHES_TABLE(p_node_name in varchar2,p_lock_name in varchar2);
PROCEDURE ABORT(x_mode in varchar2 default null, x_session_id in number);
PROCEDURE CUTOVER;
PROCEDURE FLIP_SNAPSHOTS;
PROCEDURE WAIT_FOR_DB_CUTOVER(p_session_id in number);
FUNCTION IS_ICM_ALIVE RETURN NUMBER;
FUNCTION EVAL_SRV_STATUS(avail_node_list in VARCHAR2) RETURN BOOLEAN;
FUNCTION IS_ABORTABLE RETURN BOOLEAN;
FUNCTION ADOP_HEALTH_CHECK(phase in VARCHAR2,node in VARCHAR2 default null) RETURN NUMBER;
FUNCTION IS_ABANDONED(node in varchar2) RETURN NUMBER;
FUNCTION GET_ABANDONED_NODES(p_mode in varchar2) RETURN VARCHAR2;
PROCEDURE CLEAR_ABANDON_FLAG(dest_node in varchar2);
PROCEDURE GET_ACTIV_PATCHING_SES_DETAILS(id out NOCOPY NUMBER);
PROCEDURE SYNC_SNAPSHOTS(p_appl_top_id in number default null);
FUNCTION GET_OUT_OF_SYNC_APPLY_NODES(p_session_id in number) return varchar2;
FUNCTION GET_OUT_OF_SYNC_PATCHES(p_session_id in number) return varchar2;
FUNCTION GET_APPLTOP_ID(p_node_name in varchar2) return number;
function CHECK_PENDING_CLONE(l_runbase in varchar2,l_patchbase in varchar2) return varchar2;
FUNCTION IS_PATCH_APPLIED_IN_S_MASTER(x_patch_no in varchar2,
                                      x_super_node in varchar2,
                                      x_host IN VARCHAR2 default NULL
                                     ) RETURN NUMBER;
FUNCTION GET_INVALID_NODES RETURN VARCHAR2;
FUNCTION CHECK_PRIVS(p_schema_to_check VARCHAR2,
                     p_privilege VARCHAR2,
                     p_owner VARCHAR2 default NULL,
                     p_object_name VARCHAR2 default NULL) RETURN VARCHAR2;

-- Bug26875995 Modifed output datatype to clob to handle larger message text
PROCEDURE ADOP_DATABASE_VALIDATIONS(L_MSG out NOCOPY CLOB,L_MODE in VARCHAR2 default NULL);

PROCEDURE INSTALL_APPS_DDLS( schema in varchar2);
PROCEDURE UPDATE_SESSIONS_TABLE (p_node_name IN VARCHAR2,
                                 p_status IN VARCHAR2 default 'F');
PROCEDURE INSERT_ADD_NODE_RECORDS;

FUNCTION GET_NODE_TYPE(p_node_name VARCHAR2) return NUMBER;
FUNCTION GET_MASTER_NODES RETURN VARCHAR2;
FUNCTION GET_SLAVE_NODES(p_node_name VARCHAR2) return VARCHAR2;
FUNCTION GET_NODES_WITH_SLAVES RETURN VARCHAR2;

---------------------------------------------------------------------------------
-- RESET_ADOP_SESSION_METADATA Procedure
--  The purpose of this procedure is to truncate the ADOP repository tables
--  (AD_ADOP_SESSIONS and AD_ADOP_SESSION_PATCHES) and conditionally reset the
--  adop_session_id counter (If user passes TRUE to this procedure).
---------------------------------------------------------------------------------
PROCEDURE RESET_ADOP_SESSION_METADATA(p_reset_seq  IN BOOLEAN default FALSE);

---------------------------------------------------------------------------------
-- GET_FAILED_PATCHES Function (Bug 22334672)
-- The purpose of this function is to return the list of patches for a node,
-- which has been failed or skipped in the last patching cycle.
--   Input Parameter: NODE_NAME  VARCHAR2
--                    SESSION_ID NUMBER
--   Return Value: PATCH1#STATUS1,PATCH2#STATUS2,PATCH3#STATUS3,
---------------------------------------------------------------------------------
FUNCTION GET_FAILED_PATCHES(p_node_name in VARCHAR2, p_session_id in number) return varchar2;
FUNCTION VALIDATE_SESSION_ID(session_id  number) RETURN NUMBER;
PROCEDURE UPDATE_SESSION_STATUS_FAILED(session_id NUMBER);
function is_clone_record_exist(p_adop_session_id in number,
                               p_action in varchar2,
                               p_appl_top_id in number,
                               p_hostname in varchar2,
                               p_runbase in varchar2) return number;
function is_codelevel_bumped(p_adop_session_id in number,
                              p_ad   in varchar2,
                              p_txk  in varchar2) return number;

/*----------------------------------------------------------------------+
 | Global Constant Variables                                            |
 +----------------------------------------------------------------------*/

pkg_name constant varchar2(25) := 'AD_ZD_ADOP';


end AD_ZD_ADOP;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_ADOP" AS
/* $Header: ADZDADOPB.pls 120.25.12020000.147 2023/03/03 05:54:12 rsatyava ship $ */

FUNCTION ADD_TO_LIST(p_list VARCHAR2, p_new_value VARCHAR2) RETURN VARCHAR2
IS
BEGIN
  if(p_list is NULL)
  then
    return p_new_value;
  else
    return p_list||','||p_new_value;
  end if;
END ADD_TO_LIST;

/*API to get the status of applied patch*/
PROCEDURE ADOP_PATCH_APPLY_STATUS(adop_sessionID NUMBER, ADOP_tab out
adrecordtable, stat varchar2 default 'ALL',node varchar2 default 'ALL')
AS
TYPE cur_typ IS REF CURSOR;
TYPE map_varchar_char IS TABLE OF CHAR INDEX BY VARCHAR2(30);
TYPE map_char_varchar IS TABLE OF VARCHAR2(30) INDEX BY VARCHAR2(1);
TYPE rec is RECORD
(
        bugnumber VARCHAR2(30),
        appliedfsb VARCHAR2(512),
        patchfsb VARCHAR2(512),
        st VARCHAR2(30),
        noden VARCHAR2(256)
);
srec rec;
c cur_typ;
status_map map_varchar_char;
reverse_map map_char_varchar;
nodeName varchar2(256);
fs varchar2(30);
v_counter number :=0;
v_str varchar2(400);
v_str_common varchar2(400);
BEGIN

        status_map('NOTAPPLIED') := 'N';
        status_map('RUNNING') := 'R';
        status_map('SKIP_FAILURE') := 'F';
        status_map('SKIPPED') := 'S';
        status_map('SUCCESS') := 'Y';
        status_map('HARD_FAILURE') := 'H';
        status_map('ALL') := 'A';
        status_map('NULL') := 'A';

        reverse_map('N') := 'NOTAPPLIED';
        reverse_map('R') := 'RUNNING';
        reverse_map('F') := 'SKIP_FAILURE';
        reverse_map('S') := 'SKIPPED';
        reverse_map('Y') := 'SUCCESS';
        reverse_map('H') := 'HARD_FAILURE';
       IF node = 'ALL' OR node IS NULL THEN
                nodeName := 'A';
        ELSE
                nodeName := node;
        END IF;
        v_str_common := 'Select BUG_NUMBER, APPLIED_FILE_SYSTEM_BASE,'||
'PATCH_FILE_SYSTEM_BASE,STATUS, NODE_NAME FROM  AD_ADOP_SESSION_PATCHES WHERE '||
'BUG_NUMBER <> '||''''||'CLONE'||''''||' AND BUG_NUMBER <>' ||
''''||'CONFIG_CLONE'||''''||' AND BUG_NUMBER NOT LIKE ''ADADMIN%'' '||
'AND BUG_NUMBER NOT LIKE ''ADSPLICE%'' AND ADOP_SESSION_ID ='||adop_sessionID;
       IF (stat = 'ALL' OR stat IS NULL) AND nodeName = 'A' THEN
                v_str := v_str_common;

        ELSIF (stat = 'ALL' OR stat IS NULL) AND nodeName <> 'A' THEN
                v_str := v_str_common||
' AND NODE_NAME = '||''''||node||'''';

        ELSIF stat <> 'ALL' AND nodeName = 'A' THEN
                v_str := v_str_common||
' AND STATUS = '||''''||status_map(stat)||'''';

        ELSIF stat <> 'ALL' AND nodeName <> 'A' THEN
                v_str := v_str_common||
' AND STATUS = '||''''||status_map(stat)||''''||' AND  NODE_NAME ='||
''''|| node ||'''';
        END IF;


        open c for v_str;
        LOOP
                fetch c into srec;
                exit when c%notfound;
                                ADOP_tab(v_counter).BugNumber:=srec.bugnumber;
                                ADOP_tab(v_counter).File_edition:=
srec.appliedfsb;
                                ADOP_tab(v_counter).Status:=reverse_map(srec.st);
                                ADOP_tab(v_counter).node:=srec.noden;
                v_counter:=v_counter+1;
        END LOOP;
        CLOSE c;

 end ADOP_PATCH_APPLY_STATUS;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  LOG                                                            |
 |     Logging api. This API calls AD_ZD_LOG.Message api.          |
 |                                                                 |
 |                                                                 |
 +-----------------------------------------------------------------*/

procedure LOG(p_module varchar2, p_log_type varchar2, p_message varchar2)
is
begin

   AD_ZD_LOG.Message(x_module => pkg_name||'.'||p_module,
                     x_log_type => p_log_type,
                     x_message => p_message);
end;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  getPatchNumbers                                                |
 |     This api gets the delta patches between Run and Patch FSs.  |
 |                                                                 |
 +-----------------------------------------------------------------*/

function getPatchNumbers return varchar2
is
 l_bug_numbers_list varchar2(32767);
 l_first boolean :=true;
begin
    for rec in
        (select distinct bug_number || ','  as bug_number
         from   ad_adop_session_patches
         where  PATCH_FILE_SYSTEM_BASE is NULL
         and    status = 'Y'
         order by bug_number )
    loop
      l_bug_numbers_list := l_bug_numbers_list || rec.bug_number;
    end loop;
   return l_bug_numbers_list;
end getPatchNumbers;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  GET_ACTIVE_CP_REQUEST_ID                                       |
 |     This api returns active ADZDPATCH CP request id, if any     |
 |                                                                 |
 |     Returns -1, if no such CP request found                     |
 |  Note: This function must not be used in a select statement as  |
 |        is is prone to ORA-14552. Please refer bug 21946060      |
 |        for more details.                                        |
 +-----------------------------------------------------------------*/
function GET_ACTIVE_CP_REQUEST_ID return number
is
  l_cp_req_number number;
  l_mod_name    varchar2(25) := 'GET_ACTIVE_CP_REQUEST_ID';
begin

  get_active_cp_req_id(l_cp_req_number);

  return l_cp_req_number;
end GET_ACTIVE_CP_REQUEST_ID;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  GET_ACTIVE_CP_REQ_ID                                       |
 |     This api fetches active ADZDPATCH CP request id, if any     |
 |                                                                 |
 |     Returns -1, if no such CP request found                     |
 |                                                                 |
 +-----------------------------------------------------------------*/

PROCEDURE GET_ACTIVE_CP_REQ_ID (p_req_id OUT NOCOPY NUMBER)
IS
  c_ret         boolean;
  l_phase       varchar2(30);
  l_dev_phase   varchar2(30);
  l_dev_status  varchar2(30);
  l_status      varchar2(30);
  l_message     varchar2(2000);
  l_mod_name    varchar2(30) := 'GET_ACTIVE_CP_REQ_ID';
BEGIN

--  This api would be called from adop which is outside of forms administration
-- Hence needs to call Apps_Initialize
  FND_GLOBAL.Apps_Initialize(0, 20420, 1);

  /*
   * Check is there any CP request already submitted
   */

  c_ret := FND_CONCURRENT.get_request_status(request_id => p_req_id,
                                              appl_shortname => 'AD',
                                              program    => 'ADZDPATCH',
                                              phase      => l_phase,
                                              status     => l_status,
                                              dev_phase  => l_dev_phase,
                                              dev_status => l_dev_status,
                                              message    => l_message);
  if (c_ret = TRUE)
  then
    if ((l_dev_phase = 'PENDING') OR (l_dev_phase = 'RUNNING'))
    then
      log(l_mod_name,'STATEMENT', 'An ADZDPATCH CP request '  || p_req_id ||
                                         ' is in progress');
    else
      p_req_id := 0;
    end if;
  else
    p_req_id := 0;
  end if;
END GET_ACTIVE_CP_REQ_ID;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  WAIT_FOR_CP_TO_RUN                                             |
 |     This api waits for the CP to run.                           |
 |     i.e. Waits until the CP request moves to RUNNING status     |
 |                                                                 |
 |     Returns 0, if CP manager is down                            |
 |     Returns 1, if the request started successfully.             |
 |                                                                 |
 +-----------------------------------------------------------------*/

FUNCTION WAIT_FOR_CP_TO_RUN (REQID IN NUMBER) RETURN NUMBER
IS
  c_ret         boolean;
  c_reqid       number;
  l_phase       varchar2(30);
  l_dev_phase   varchar2(30);
  l_dev_status  varchar2(30);
  l_status      varchar2(30);
  l_message     varchar2(2000);
  l_defined     boolean;
  l_active      boolean;
  l_workshift   boolean;
  l_mgr_running boolean;
  l_run_alone   boolean;
  l_mod_name    varchar2(25) := 'WAIT_FOR_CP_TO_RUN';
BEGIN

-- This api is called only when ICM is running

-- This api would be called from adop which is outside of forms administration
-- Hence needs to call Apps_Initialize
  FND_GLOBAL.Apps_Initialize(0, 20420, 1);

  log(l_mod_name, 'STATEMENT', 'Waiting for the ' ||
                                        'ADZDPATCH CP to start');

  c_reqid:=REQID;
  l_dev_phase := 'PENDING';

  while l_dev_phase = 'PENDING' loop

   /*
    * The conc managers are up if we get here.
    * Now check to make sure there is a manager defined
    * that can run the ADZDPATCH conc pgm.
    * If manager is not running then this is a failure situation
    * since we know other managers are currently running (see above).
    */
    l_mgr_running := TRUE;

    FND_CONC.manager_check(req_id        => c_reqid,
                           cd_id         => null,
                           mgr_defined   => l_defined,
                           mgr_active    => l_active,
                           mgr_workshift => l_workshift,
                           mgr_running   => l_mgr_running,
                           run_alone     => l_run_alone);

    if( l_defined = FALSE)
    then
      log(l_mod_name, 'ERROR', 'No Concurrent Manager is defined that can run ' ||
                               'concurrent program ADZDPATCH');
      raise_application_error (-20008, 'No Concurrent Manager is defined that ' ||
                                       'can run concurrent program ADZDPATCH');
    end if;

    if( l_mgr_running = FALSE)
    then
      log(l_mod_name, 'ERROR', 'No Concurrent Manager is running that can run ' ||
                               'concurrent program ADZDPATCH');
      raise_application_error (-20008, 'No Concurrent Manager is running that ' ||
                                       'can run concurrent program ADZDPATCH');
    end if;

   /*
    * If we get here, we know conc mgrs are up.
    * and we know there is one defined that can run ADZDPATCH conc pgm.
    * So now let's check the status of ADZDPATCH conc pgm.
    */
    l_dev_phase := null;

    c_ret := FND_CONCURRENT.get_request_status(request_id => c_reqid,
                                               appl_shortname => 'AD',
                                               program    => 'ADZDPATCH',
                                               phase      => l_phase,
                                               status     => l_status,
                                               dev_phase  => l_dev_phase,
                                               dev_status => l_dev_status,
                                               message    => l_message);

    if (c_ret = FALSE)
    then
      log(l_mod_name, 'ERROR', 'Failed to check the status of ' ||
                                           'concurrent program ADZDPATCH');
      raise_application_error (-20008, 'Failed to check the status of concurrent ' ||
                                      'program ADZDPATCH');
    end if;

    if (l_dev_phase = 'PENDING')
    then
      dbms_lock.sleep(30);
    end if;
  end loop;

  /*
   * If we come here we have exit the PENDING loop.
   * Now we must check that it went from PENDING to RUNNING.
   * Anything else is a failure situation.
   */

  if (l_dev_phase = 'RUNNING')
  then

     log (l_mod_name, 'STATEMENT', 'ADZDPATCH concurrent program ' ||
                                       'started successfully');
  else
      log(l_mod_name, 'ERROR', 'ADZDPATCH status is INVALID. ' ||
                                           ' Failed to submit ADZDPATCH');
      raise_application_error (-20008, 'Failed to submit concurrent ' ||
                                      'program ADZDPATCH');
  end if;

  return 1;

END WAIT_FOR_CP_TO_RUN;

/*-----------------------------------------------------------------+
 |                                                                 |
 |  SUBMIT_REQUEST                                                 |
 |     This api submits the CP request and returns the request id. |
 |                                                                 |
 |     If any active CP request found, no new request will be      |
 |     submitted. The current active CP request id gets returned.  |
 |                                                                 |
 +-----------------------------------------------------------------*/

FUNCTION SUBMIT_REQUEST RETURN NUMBER
IS
  c_error       varchar2(2000);
  c_reqid       number;
  l_mod_name    varchar2(25) := 'SUBMIT_REQUEST';
BEGIN

--  This api would be called from adop which is outside of forms administration
-- Hence needs to call Apps_Initialize
  FND_GLOBAL.Apps_Initialize(0, 20420, 1);

  /*
   * Check is there is any CP request already submitted
   */
  get_active_cp_req_id(c_reqid);
  if (c_reqid > 0)
  then
    /*
     * Since there is an active CP request error out
     */
    log(l_mod_name,'ERROR', 'Can not submit CP request, ' ||
              ' as there is an active ADZDPATCH concurrent program.');
    return -1;
  end if;

  /*
   * Submit a new CP request only in case of no ADZDPATCH CP requests
   * with PENDING or RUNNING status.
   */
  c_reqid := FND_REQUEST.SUBMIT_REQUEST(application=>'AD',
                                     program=>'ADZDPATCH');

  /*
   * the below commit is needed to commit the submitted request above
   */
  commit;

  if (c_reqid = 0)
  then
    c_error := fnd_message.GET_TOKEN('REASON');
    log(l_mod_name,'ERROR', 'Error occured whiile submitting ' ||
               'ADZDPATCH concurrent program. Error= '||c_error);
    raise_application_error(-20008, 'Error in submitting ADZDPATCH ' ||
                                          'concurrent request');
  else
    log(l_mod_name,'STATEMENT', 'Submitted concurrent program ' ||
                                         'ADZDPATCH successfully');
  end if;

  return c_reqid;

END SUBMIT_REQUEST;

PROCEDURE INSERT_INTO_PATCHES_TABLE(
                                    p_session_id IN NUMBER,
                                    p_bug_number IN VARCHAR2,
                                    p_patch_run_id IN NUMBER,
                                    p_appltop_base IN VARCHAR2,
                                    p_adpatch_options IN VARCHAR2,
                                    p_autoconfig_status IN VARCHAR2,
                                    p_start_date IN DATE,
                                    p_end_date IN DATE,
                                    p_patch_top IN VARCHAR2,
                                    p_driverfile_name IN VARCHAR2,
                                    p_status IN VARCHAR2,
                                    p_utility IN VARCHAR2 default 'ADPATCH',
                                    p_host IN VARCHAR2 default NULL
                                  )
IS
  l_mod_name          varchar2(25) := 'INSERT_INTO_PATCHES_TABLE';
  l_exists            number;
  l_status            varchar2(1) := 'N';
  l_ac_status         varchar2(1);
  l_invoking_node     varchar2(256);
  l_appl_top_id       number;
  l_current_status    varchar2(1);
  l_current_ac_status varchar2(1);
  TYPE status_order_t IS TABLE OF NUMBER INDEX BY VARCHAR2(1);
  status_order        status_order_t;
  ac_status_order     status_order_t;
  l_session_type      varchar2(20);
  l_utility           varchar2(30);
  l_invoker_atid      number;
  l_adpatch_options   varchar2(4000);
  l_session_id        number;
  cursor nodes is

        SELECT
                  fn.host node_name ,
                  aat.appl_top_id appl_top_id ,
                  EXTRACTVALUE(XMLType(TEXT),'//shared_file_system') is_shared
        FROM
                  fnd_nodes fn,
                  FND_OAM_CONTEXT_FILES focf,
                  fnd_product_groups fpg,
                  ad_appl_tops aat,
                  ad_releases ar
        WHERE     focf.NAME not in ('TEMPLATE','METADATA','config.txt') and focf.CTX_TYPE='A' and
                  (focf.status is null or upper(focf.status) in ('S','F')) and
                  EXTRACTVALUE(XMLType(focf.TEXT),'//file_edition_type') = 'run' and
                  focf.node_name=fn.host and
                  (fn.support_cp='Y' or fn.support_forms='Y' or
                   fn.support_web='Y' or fn.support_admin='Y') and
                  aat.appl_top_type='R' and aat.applications_system_name=fpg.applications_system_name and
                  aat.active_flag='Y' and
                  fpg.release_name=ar.major_version||'.'||ar.minor_version||'.'||ar.tape_version and
                  fpg.aru_release_name=ar.aru_release_name and
                  aat.name=EXTRACTVALUE(XMLType(focf.TEXT),'//APPL_TOP_NAME');

BEGIN
  log(l_mod_name,'STATEMENT','START -->');
  log(l_mod_name,'STATEMENT','Session Id       : '||p_session_id);
  log(l_mod_name,'STATEMENT','Bug Number       : '||p_bug_number );
  log(l_mod_name,'STATEMENT','Patch Run ID     : '||p_patch_run_id);
  log(l_mod_name,'STATEMENT','Autoconfig Status: '||p_autoconfig_status);
  log(l_mod_name,'STATEMENT','Patch Top        : '||p_patch_top );
  log(l_mod_name,'STATEMENT','Driver file name : '||p_driverfile_name );
  log(l_mod_name,'STATEMENT','Status           : '||p_status );
  log(l_mod_name,'STATEMENT','Host             : '||p_host );

  if p_utility like 'ADPATCH_%'
  then
     l_utility       := substr(p_utility,0,instr(p_utility,'_')-1);
     l_session_type  := substr(p_utility,instr(p_utility,'_')+1,length(p_utility)-1);
  else
     l_utility      := p_utility;
     l_session_type := p_utility;
  end if;

  if (p_host IS NOT NULL)
  then
    l_invoking_node := p_host;
  else
    SELECT  substr(sys_context ('userenv','HOST'),1,256) into l_invoking_node from dual;
    SELECT  substr(l_invoking_node, 1, decode(instr(l_invoking_node,'.',1,1),
                                                   0,length(l_invoking_node),
                                                   instr(l_invoking_node,'.',1,1)-1)
                  )
    into l_invoking_node from dual;
  end if;

  status_order('N'):=10;
  status_order('R'):=20;
  status_order('H'):=30;
  status_order('F'):=40;
  status_order('S'):=50;
  status_order('Y'):=60;

  ac_status_order('N'):=10;
  ac_status_order('P'):=20;
  ac_status_order('Y'):=30;

  for rec in nodes loop
    if(upper(rec.node_name) = upper(l_invoking_node)) then
      l_invoker_atid := rec.appl_top_id;
      exit;
    end if;
  end loop;

  if( l_utility = 'ADPATCH' ) then
    for rec in nodes loop

      if(upper(rec.node_name) = upper(l_invoking_node) OR (rec.is_shared='true' AND rec.appl_top_id=l_invoker_atid)) then
        l_status:=p_status;
      else
        l_status:='N';
      end if;

      if(upper(rec.node_name) = upper(l_invoking_node)) then
        l_ac_status:=p_autoconfig_status;
      else
        l_ac_status:='N';
      end if;

      l_session_id := p_session_id;
      if(p_session_id = 0) then
         select max(adop_session_id) into l_session_id from ad_adop_session_patches;
      end if;
      select count(1) into l_exists from ad_adop_session_patches
      where ADOP_SESSION_ID=l_session_id and BUG_NUMBER=p_bug_number and
          APPLIED_FILE_SYSTEM_BASE=p_appltop_base and APPLTOP_ID=rec.appl_top_id and
          NODE_NAME=rec.node_name and DRIVER_FILE_NAME=p_driverfile_name;

      if (l_exists > 0) then
        select STATUS,AUTOCONFIG_STATUS into l_current_status,l_current_ac_status
        from ad_adop_session_patches
        where ADOP_SESSION_ID=l_session_id and BUG_NUMBER=p_bug_number and
              APPLIED_FILE_SYSTEM_BASE=p_appltop_base and APPLTOP_ID=rec.appl_top_id and
              NODE_NAME=rec.node_name and DRIVER_FILE_NAME=p_driverfile_name;

        if ((status_order(l_current_status) < status_order(l_status)) or
             (ac_status_order(l_current_ac_status) < ac_status_order(l_ac_status)) or
              (l_current_status = 'F' and l_status = 'R')) then
          log(l_mod_name,'STATEMENT','Updating existing AD_ADOP_SESSION_PATCHES table entry for patch #' || p_bug_number);
          log(l_mod_name,'STATEMENT','- STATUS:  ' || l_current_status || ' -> ' || l_status);
          log(l_mod_name,'STATEMENT','- AC STATUS:  ' || l_current_ac_status || ' -> ' || l_ac_status);

          if(ac_status_order(l_current_ac_status) < ac_status_order(l_ac_status))
          then
            update ad_adop_session_patches
            set PATCHRUN_ID=p_patch_run_id, STATUS=l_status, AUTOCONFIG_STATUS=l_ac_status,
                START_DATE=p_start_date, END_DATE=p_end_date, PATCH_TOP=p_patch_top, SESSION_TYPE=l_session_type
            where ADOP_SESSION_ID=l_session_id and BUG_NUMBER=p_bug_number and APPLTOP_ID=rec.appl_top_id and
                NODE_NAME=rec.node_name and DRIVER_FILE_NAME=p_driverfile_name;
          else
            update ad_adop_session_patches
            set PATCHRUN_ID=p_patch_run_id, STATUS=l_status,
                START_DATE=p_start_date, END_DATE=p_end_date, PATCH_TOP=p_patch_top, SESSION_TYPE=l_session_type
            where ADOP_SESSION_ID=l_session_id and BUG_NUMBER=p_bug_number and APPLTOP_ID=rec.appl_top_id and
                NODE_NAME=rec.node_name and DRIVER_FILE_NAME=p_driverfile_name;
          end if;
        end if;
      else
        log(l_mod_name,'STATEMENT','Inserting new AD_ADOP_SESSION_PATCHES table entry for patch #' || p_bug_number);
        if(p_session_id = 0)  then
           select count(1) into l_exists
           from ad_adop_session_patches
           where adop_session_id = l_session_id
           and   SESSION_TYPE = 'BOOTSTRAP'
           and not exists ( select 1 from ad_adop_session_patches
                            where adop_session_id = l_session_id
                            and   SESSION_TYPE <> 'BOOTSTRAP');
           if (l_exists = 0) then
              -- insert a new bootstrap cycle
              select ad_adop_session_id_seq.nextval into l_session_id from dual;
           end if;
        end if;
        INSERT INTO ad_adop_session_patches
          (ADOP_SESSION_ID, BUG_NUMBER, PATCHRUN_ID, STATUS, APPLIED_FILE_SYSTEM_BASE, PATCH_FILE_SYSTEM_BASE,
           ADPATCH_OPTIONS, APPLTOP_ID, NODE_NAME, AUTOCONFIG_STATUS, START_DATE, END_DATE, PATCH_TOP, DRIVER_FILE_NAME,SESSION_TYPE)
        VALUES
        (l_session_id, p_bug_number, p_patch_run_id, l_status, p_appltop_base, NULL, p_adpatch_options,
         rec.appl_top_id, rec.node_name, l_ac_status, p_start_date, p_end_date, p_patch_top, p_driverfile_name,l_session_type);
      end if;
    end loop;
    commit;
    log(l_mod_name,'STATEMENT','<-- END');
  else
    l_status:=p_status;

    if( l_utility = 'ADSPLICE' ) then
      l_ac_status:=p_autoconfig_status;
    else
      l_ac_status:='N';
    end if;

    l_adpatch_options := regexp_replace(p_adpatch_options,' ','|');

    for rec in nodes loop
      continue when rec.appl_top_id <> l_invoker_atid;

      select count(1) into l_exists from ad_adop_session_patches
      where ADOP_SESSION_ID=p_session_id and BUG_NUMBER=p_bug_number and
            APPLIED_FILE_SYSTEM_BASE=p_appltop_base and APPLTOP_ID=rec.appl_top_id and
            NODE_NAME=rec.node_name and
           (ADPATCH_OPTIONS=l_adpatch_options OR (ADPATCH_OPTIONS IS NULL AND l_adpatch_options is NULL));

      if (l_exists > 0) then
        log(l_mod_name,'STATEMENT','Updating existing AD_ADOP_SESSION_PATCHES table entry for ADADMIN action' || p_bug_number);
        log(l_mod_name,'STATEMENT','- STATUS:  ' || l_current_status || ' -> ' || l_status);

        update ad_adop_session_patches
           set STATUS=l_status, END_DATE=p_end_date
        where ADOP_SESSION_ID=p_session_id and BUG_NUMBER=p_bug_number and APPLTOP_ID=rec.appl_top_id and
           NODE_NAME=rec.node_name and (ADPATCH_OPTIONS=l_adpatch_options OR
          (ADPATCH_OPTIONS IS NULL AND l_adpatch_options is NULL));
      else
        log(l_mod_name,'STATEMENT','Inserting new AD_ADOP_SESSION_PATCHES table entry for ADADMIN Action ' || p_bug_number);

        INSERT INTO ad_adop_session_patches
            (ADOP_SESSION_ID, BUG_NUMBER, PATCHRUN_ID, STATUS, APPLIED_FILE_SYSTEM_BASE, PATCH_FILE_SYSTEM_BASE,
             ADPATCH_OPTIONS, APPLTOP_ID, NODE_NAME, AUTOCONFIG_STATUS, START_DATE, END_DATE, PATCH_TOP, DRIVER_FILE_NAME,SESSION_TYPE)
        VALUES
        (p_session_id, p_bug_number, NULL, l_status, p_appltop_base, NULL, l_adpatch_options,
         rec.appl_top_id, rec.node_name, l_ac_status, p_start_date, p_end_date, p_patch_top, p_driverfile_name,l_session_type);
      end if;
      commit;
    end loop;
  end if;
EXCEPTION
  when others then
    log(l_mod_name, 'ERROR', 'ERROR: '||SQLERRM);
    RAISE_APPLICATION_ERROR(-20010,SQLERRM);
END INSERT_INTO_PATCHES_TABLE;

FUNCTION GET_CUTOVER_STATUS(p_appltop_id in number,p_node_name in varchar2,p_session_id in number) return varchar2 is
   l_cutover_status       varchar2(1);
   l_session_id       number;
begin
  if ( p_session_id is null) then
    select max(adop_session_id) into l_session_id from ad_adop_sessions
    where appltop_id=p_appltop_id and node_name=p_node_name;
  else
    l_session_id:=p_session_id;
  end if;
  select cutover_status into l_cutover_status
   from ad_adop_sessions
   where appltop_id=p_appltop_id
     and node_name=p_node_name
     and adop_session_id= l_session_id;
  return l_cutover_status;
end GET_CUTOVER_STATUS;

PROCEDURE LOCK_SESSIONS_TABLE(p_node_name in varchar2,p_wait_interval in number,p_num_tries in number) is
        l_mod_name         varchar2(25) := 'LOCK_SESSIONS_TABLE';
        resource_busy      exception;
        pragma exception_init(resource_busy,-54);
        l_is_locked        number:=0;
begin
   if ( p_num_tries = 0 ) then
      log(l_mod_name, 'ERROR', 'Number of attempts to lock table must be more than zero');
      RAISE_APPLICATION_ERROR(-20010,'Error: Attempted to lock AD_ADOP_SESSIONS table with 0 attempts');
   end if;
   for i in 1..p_num_tries loop
     begin
        lock table ad_adop_sessions in  exclusive mode nowait;
        select count(*) into l_is_locked from ad_adop_sessions where adop_session_id=0 and EDITION_NAME='LOCK';
        if (l_is_locked = 0) then
          insert into ad_adop_sessions
          (ADOP_SESSION_ID,PREPARE_STATUS,APPLY_STATUS,FINALIZE_STATUS,CUTOVER_STATUS,CLEANUP_STATUS,ABORT_STATUS,STATUS,EDITION_NAME,NODE_NAME)
          values (0,'X','X','X','X','X','X','Y','LOCK',p_node_name);
          commit;
          return;
        else
          commit;
          dbms_lock.sleep(p_wait_interval);
        end if;
     exception
         when resource_busy then
             dbms_lock.sleep(p_wait_interval);
     end;
   end loop;
   log(l_mod_name, 'ERROR', 'ERROR: Unable to acquire lock on ad_adop_sessions table.');
   if (l_is_locked <> 0) then
      log(l_mod_name, 'ERROR', 'LOCK row seems to have been inserted in AD_ADOP_SESSIONS by another session');
      RAISE_APPLICATION_ERROR(-20010,'ERROR: Unable to acquire lock on ad_adop_sessions table. LOCK row seems to have been inserted by another session');
   else
      log(l_mod_name, 'ERROR', 'AD_ADOP_SESSIONS table seems to have been locked in exclusive mode by another session');
      RAISE_APPLICATION_ERROR(-20010,'ERROR: Unable to acquire lock on ad_adop_sessions table. AD_ADOP_SESSIONS table seems to have been locked in exclusive mode by another session');
   end if;
end LOCK_SESSIONS_TABLE;

PROCEDURE UNLOCK_SESSIONS_TABLE(p_node_name in varchar2,p_wait_interval in number,p_num_tries in number) is
        l_mod_name         varchar2(25) := 'UNLOCK_SESSIONS_TABLE';
        resource_busy      exception;
        pragma exception_init(resource_busy,-54);
        l_is_locked        number:=0;
begin

   for i in 1..p_num_tries loop
     begin
        lock table ad_adop_sessions in  exclusive mode nowait;
        select count(*) into l_is_locked from ad_adop_sessions where adop_session_id=0 and EDITION_NAME='LOCK' and node_name=p_node_name;
        if (l_is_locked <> 0) then
          delete from ad_adop_sessions where adop_session_id=0 and EDITION_NAME='LOCK' and node_name=p_node_name;
          commit;
          return;
        else
          log(l_mod_name, 'WARN', 'WARN: Trying to unlock ad_adop_sessions table when no lock in place.');
          commit;
          return;
        end if;
     exception
         when resource_busy then
             dbms_lock.sleep(p_wait_interval);
     end;
   end loop;
   log(l_mod_name, 'ERROR', 'ERROR: Unable to acquire lock on ad_adop_sessions table.');
   RAISE_APPLICATION_ERROR(-20010,'ERROR: Unable to acquire lock on ad_adop_sessions table.');

end UNLOCK_SESSIONS_TABLE;

/*----------------------------------------------------------------+
|  CUTOVER_DONE                                                   |
|     This api updates the cutover phase for a patching cycle     |
|      of a multi node environment.                               |
+-----------------------------------------------------------------*/
procedure SET_CUTOVER_STATUS(p_appltop_id in number,p_node_name in varchar2,p_status in varchar2) is
   l_session_id       number;
begin
  select max(adop_session_id) into l_session_id from ad_adop_sessions
    where appltop_id=p_appltop_id and node_name=p_node_name
      and prepare_status='Y' and apply_status='Y';
  update ad_adop_sessions set cutover_status=p_status
   where adop_session_id= l_session_id
     and appltop_id=p_appltop_id
     and node_name=p_node_name;
  commit;
end SET_CUTOVER_STATUS;

PROCEDURE KILL_OLD_SESSIONS(p_session_id number)
IS
   l_message varchar2(250);
   l_statement varchar2(200);
   l_info varchar2(200);
   invalid_session EXCEPTION;
   PRAGMA EXCEPTION_INIT(invalid_session,-30);
   CURSOR c_sessions_to_kill is
      select
      '/* '||e.object_name||' '||s.osuser||' '||s.username||' */' info,
      'ALTER SYSTEM KILL SESSION '||''''||s.sid||','||s.serial#||'''' kill
      from
      v$session s, v$process p, database_properties run -- /* run edition name */
      , dba_objects_ae e
      where s.type <> 'BACKGROUND' and p.addr    = s.paddr
      and run.property_name = 'DEFAULT_EDITION'
      and e.object_id = s.session_edition_id
      and e.object_name < run.property_value
      and s.username in
      ( select oracle_username from  fnd_oracle_userid
        where  read_only_flag in ('A', 'B', 'C', 'E', 'U') );
begin
   OPEN c_sessions_to_kill;
   FETCH c_sessions_to_kill into l_info,l_statement;
   while (c_sessions_to_kill%found)
   loop
      begin
         AD_ZD.EXEC(l_statement,'STATEMENT');
      exception
         when invalid_session then
            l_message := 'Invalid user session <'||l_statement||'>';
            ad_zd_log.message('ADOP','WARNING',l_message);
         when others then
            l_message := 'Error: while killing session using <'||l_statement||'> '||sqlerrm;
            ad_zd_log.message('ADOP','ERROR',l_message);
            raise_application_error(-20001, l_message);
      end;
      FETCH c_sessions_to_kill into l_info,l_statement;
   end loop;
   CLOSE c_sessions_to_kill;
   exception
      when others then
         if c_sessions_to_kill%isopen then
             -- cursor was not already closed
            CLOSE c_sessions_to_kill;
         end if;
         update ad_adop_sessions set status='F'
         where adop_session_id=p_session_id;
         commit;
         raise_application_error(-20001,'Error: while killing old sessions.' || sqlerrm);
end KILL_OLD_SESSIONS;

FUNCTION GET_ADZDPATCH_STATUS(REQID IN NUMBER) RETURN VARCHAR2
IS
  c_error       varchar2(2000);
  c_reqid       number;
  l_mod_name    varchar2(25) := 'GET_ADZDPATCH_STATUS';
  l_phase       varchar2(80);
  l_status      varchar2(80);
  l_diag        varchar2(2000);

BEGIN

 -- This api would be called from adop which is outside of forms administration
 -- Hence needs to call Apps_Initialize
 FND_GLOBAL.Apps_Initialize(0, 20420, 1);

 c_reqid := REQID;
 FND_CONC.DIAGNOSE(c_reqid, l_phase, l_status, l_diag);

 return l_diag;

END GET_ADZDPATCH_STATUS;

PROCEDURE LOCK_PATCHES_TABLE(p_node_name in varchar2,p_lock_name in varchar2) is
        l_mod_name         varchar2(25) := 'LOCK_PATCHES_TABLE';
        resource_busy      exception;
        pragma exception_init(resource_busy,-54);
        l_is_locked        number:=0;
begin
   begin
        select count(*) into l_is_locked from ad_adop_session_patches where adop_session_id=0 and BUG_NUMBER=p_lock_name;
        if (l_is_locked = 0) then
          lock table ad_adop_session_patches in  exclusive mode nowait;
          insert into ad_adop_session_patches
          (ADOP_SESSION_ID,BUG_NUMBER,STATUS,NODE_NAME)
          values (0,p_lock_name,'N',p_node_name);
          commit;
          log(l_mod_name, 'STATEMENT', 'Able to acquire lock on ad_adop_session_patches table.');
          return;
        else
          log(l_mod_name, 'WARNING', 'Unable to acquire lock on ad_adop_session_patches table.');
          commit;
        end if;
     exception
         when resource_busy then
          log(l_mod_name, 'WARNING', 'Unable to acquire lock on ad_adop_session_patches table.');
   end;
end LOCK_PATCHES_TABLE;

PROCEDURE UNLOCK_PATCHES_TABLE(p_node_name in varchar2,p_lock_name in varchar2) is
        l_mod_name         varchar2(25) := 'UNLOCK_PATCHES_TABLE';
        resource_busy      exception;
        pragma exception_init(resource_busy,-54);
        l_is_locked        number:=0;
begin
   begin
     select count(1) into l_is_locked from ad_adop_session_patches
      where adop_session_id=0 and BUG_NUMBER=p_lock_name
            and node_name=p_node_name;
     if (l_is_locked <> 0) then
       lock table ad_adop_session_patches in  exclusive mode nowait;
       delete from ad_adop_session_patches
        where adop_session_id=0 and BUG_NUMBER=p_lock_name
              and node_name=p_node_name;
       commit;
         log(l_mod_name, 'STATEMENT', 'Able to acquire lock on ad_adop_session_patches table.');
       return;
     else
         log(l_mod_name, 'WARNING', 'Unable to acquire lock on ad_adop_session_patches table.');
       commit;
       return;
     end if;
  exception
       when resource_busy then
         log(l_mod_name, 'WARNING', 'Unable to acquire lock on ad_adop_session_patches table.');
  end;
end UNLOCK_PATCHES_TABLE;

PROCEDURE SYNC_SNAPSHOTS(p_appl_top_id in number default null)
is

cursor snapshot_ids(x_release_id number) is
select lp.appl_top_id, asn.snapshot_id
from (select ad_zd_adop.get_appltop_id(avn.node_name) as appl_top_id
from adop_valid_nodes avn
where upper(avn.node_name) in (select upper(ad_zd_adop.get_master_nodes)
                               from dual)
     ) lp, ad_snapshots asn
where asn.appl_top_id(+)=lp.appl_top_id
and   asn.release_id(+)=x_release_id
and   asn.snapshot_type(+)='P'
and asn.snapshot_id is null;

l_applications_system_name varchar2(30);
l_snapshot_creation_status varchar2(10);
l_release_id number;
l_patch_edition varchar2(30) := ad_zd.get_edition('PATCH');
l_setback boolean := false;
begin

  -- Get the latest release_id
  select rel.release_id, fpg.applications_system_name  into l_release_id, l_applications_system_name
  from ad_releases rel, fnd_product_groups fpg
  where fpg.release_name=rel.major_version||'.'||rel.minor_version||'.'||rel.tape_version
  and fpg.product_group_id=1;

  if l_patch_edition is not null
  then
    if (ad_zd.get_edition_type<>'PATCH')
    then
       ad_zd.set_edition('PATCH');
       l_setback := true;
    end if;
    for snapshotid in snapshot_ids(l_release_id)
    loop
      -- Instantiate the current view snapshot.
      -- You may ignore the l_snapshot_creation_status return code since prepare doesn't have to failed
      -- as I feel this is not a hard failure.
      AD_FILE_SYS_SNAPSHOTS_PKG.Instantiate_Current_View(l_release_id, snapshotid.appl_top_id,
      FALSE, TRUE, l_snapshot_creation_status);
    end loop;
    if (l_setback = true)
    then
       ad_zd.set_edition('RUN');
       l_setback := false;
    end if;
  end if;

-- Bug 23146424
-- Update patch release_ids as RUN release_ids

-- Cleaning ad_snapshot_files
-- Deleting new records inserted by patch
  delete AD_SNAPSHOT_FILES
  where (snapshot_id, file_id, nvl(containing_file_id, -2)) in
        (select ou.snapshot_id, ou.file_id, nvl(ou.containing_file_id, -2)
         from   AD_SNAPSHOT_FILES OU, AD_SNAPSHOTS OUASN,
                AD_APPL_TOPS ouaat
         where  OU.SNAPSHOT_ID=OUASN.SNAPSHOT_ID
         and    OUASN.SNAPSHOT_TYPE='P'
         and    ouasn.snapshot_name='CURRENT_VIEW'
         and    ouasn.appl_top_id=ouaat.appl_top_id
         and    ouaat.appl_top_id=nvl(p_appl_top_id, ouaat.appl_top_id)
         and    ouaat.appl_top_type='R'
         and    ouaat.applications_system_name=l_applications_system_name
         and    ouasn.release_id=l_release_id
         and    ouaat.active_flag='Y'
         and not exists (
           select 'x'
           from   AD_SNAPSHOT_FILES ASF, AD_SNAPSHOTS ASN
           where  ASF.SNAPSHOT_ID=ASN.SNAPSHOT_ID
           and    ASN.SNAPSHOT_TYPE='C'
           and    ASN.SNAPSHOT_NAME=OUASN.SNAPSHOT_NAME
           and    ASN.APPL_TOP_ID=OUASN.APPL_TOP_ID
           and    OU.FILE_ID=ASF.FILE_ID
           and    NVL(OU.CONTAINING_FILE_ID, -2)=NVL(ASF.CONTAINING_FILE_ID, -2)
           and    OUASN.APPL_TOP_ID=ASN.APPL_TOP_ID)
        );

  delete AD_SNAPSHOT_FILES
  where (snapshot_id, file_id, nvl(containing_file_id, -2)) in
        (select ou.snapshot_id, ou.file_id, nvl(ou.containing_file_id, -2)
         from   AD_SNAPSHOT_FILES OU, AD_SNAPSHOTS OUASN,
                AD_APPL_TOPS ouaat
         where  OU.SNAPSHOT_ID=OUASN.SNAPSHOT_ID
         and    OUASN.SNAPSHOT_TYPE='Q'
         and    ouasn.snapshot_name='GLOBAL_VIEW'
         and    ouasn.appl_top_id=ouaat.appl_top_id
         and    ouaat.appl_top_type='G'
         and    ouaat.applications_system_name=l_applications_system_name
         and    ouasn.release_id=l_release_id
         and    ouaat.active_flag='Y'
         and not exists (
           select 'x'
           from   AD_SNAPSHOT_FILES ASF, AD_SNAPSHOTS ASN
           where  ASF.SNAPSHOT_ID=ASN.SNAPSHOT_ID
           and    ASN.SNAPSHOT_TYPE='G'
           and    ASN.SNAPSHOT_NAME=OUASN.SNAPSHOT_NAME
           and    ASN.APPL_TOP_ID=OUASN.APPL_TOP_ID
           and    OU.FILE_ID=ASF.FILE_ID
           and    NVL(OU.CONTAINING_FILE_ID, -2)=NVL(ASF.CONTAINING_FILE_ID, -2)
           and    OUASN.APPL_TOP_ID=ASN.APPL_TOP_ID)
        );

-- Cleaning ad_snapshot_bugfixes
-- Deleting new records inserted by patch
  delete AD_SNAPSHOT_BUGFIXES
  where (SNAPSHOT_ID, BUGFIX_ID) in
        (select OU.SNAPSHOT_ID, OU.BUGFIX_ID
         from   AD_SNAPSHOT_BUGFIXES OU, AD_SNAPSHOTS OUASN,
                AD_APPL_TOPS ouaat
         where  OU.SNAPSHOT_ID=OUASN.SNAPSHOT_ID
         and    OUASN.SNAPSHOT_TYPE='P'
         and    ouasn.snapshot_name='CURRENT_VIEW'
         and    ouasn.appl_top_id=ouaat.appl_top_id
         and    ouaat.appl_top_id=nvl(p_appl_top_id, ouaat.appl_top_id)
         and    ouaat.appl_top_type='R'
         and    ouaat.applications_system_name=l_applications_system_name
         and    ouasn.release_id=l_release_id
         and    ouaat.active_flag='Y'
         and not exists (
           select 'x'
           from   AD_SNAPSHOT_BUGFIXES ASF, AD_SNAPSHOTS ASN
           where  ASF.SNAPSHOT_ID=ASN.SNAPSHOT_ID
           and    ASN.SNAPSHOT_TYPE='C'
           and    ASN.SNAPSHOT_NAME=OUASN.SNAPSHOT_NAME
           and    ASN.APPL_TOP_ID=OUASN.APPL_TOP_ID
           and    OU.BUGFIX_ID=ASF.BUGFIX_ID
           and    OUASN.APPL_TOP_ID=ASN.APPL_TOP_ID)
        );

  delete AD_SNAPSHOT_BUGFIXES
  where (SNAPSHOT_ID, BUGFIX_ID) in
        (select OU.SNAPSHOT_ID, OU.BUGFIX_ID
         from   AD_SNAPSHOT_BUGFIXES OU, AD_SNAPSHOTS OUASN,
                AD_APPL_TOPS ouaat
         where  OU.SNAPSHOT_ID=OUASN.SNAPSHOT_ID
         and    OUASN.SNAPSHOT_TYPE='Q'
         and    ouasn.snapshot_name='GLOBAL_VIEW'
         and    ouasn.appl_top_id=ouaat.appl_top_id
         and    ouaat.appl_top_type='G'
         and    ouaat.applications_system_name=l_applications_system_name
         and    ouasn.release_id=l_release_id
         and    ouaat.active_flag='Y'
         and not exists (
           select 'x'
           from   AD_SNAPSHOT_BUGFIXES ASF, AD_SNAPSHOTS ASN
           where  ASF.SNAPSHOT_ID=ASN.SNAPSHOT_ID
           and    ASN.SNAPSHOT_TYPE='G'
           and    ASN.SNAPSHOT_NAME=OUASN.SNAPSHOT_NAME
           and    ASN.APPL_TOP_ID=OUASN.APPL_TOP_ID
           and    OU.BUGFIX_ID=ASF.BUGFIX_ID)
        );

-- Update existing records
  declare
  cursor crs is
  select ASF1.SNAPSHOT_ID,
         ASF2.FILE_ID,
         ASF2.CONTAINING_FILE_ID,
         ASF2.FILE_VERSION_ID
  from   AD_SNAPSHOTS ASN1, AD_SNAPSHOT_FILES ASF1,
         AD_SNAPSHOTS ASN2, AD_SNAPSHOT_FILES ASF2,
         AD_APPL_TOPS AAT
  where  ASN1.SNAPSHOT_ID=ASF1.SNAPSHOT_ID
  and    ASN2.SNAPSHOT_ID=ASF2.SNAPSHOT_ID
  and    ASN1.SNAPSHOT_TYPE='P'
  and    ASN2.SNAPSHOT_TYPE='C'
  and    ASN1.SNAPSHOT_NAME='CURRENT_VIEW'
  and    ASN2.SNAPSHOT_NAME=ASN1.SNAPSHOT_NAME
  and    ASN1.APPL_TOP_ID=ASN2.APPL_TOP_ID
  and    ASF1.FILE_ID=ASF2.FILE_ID
  and    NVL(ASF1.CONTAINING_FILE_ID, -2)=NVL(ASF2.CONTAINING_FILE_ID, -2)
  and    NVL(ASF1.FILE_VERSION_ID, -2)<>NVL(ASF2.FILE_VERSION_ID, -2)
  and    ASN1.APPL_TOP_ID=AAT.APPL_TOP_ID
  and    AAT.APPL_TOP_ID=nvl(p_appl_top_id, AAT.APPL_TOP_ID)
  and    AAT.APPLICATIONS_SYSTEM_NAME=l_applications_system_name
  and    asn1.release_id=l_release_id
  and    asn2.release_id=asn1.release_id
  and    aat.active_flag='Y';

  cursor grs is
  select ASF1.SNAPSHOT_ID,
         ASF2.FILE_ID,
         ASF2.CONTAINING_FILE_ID,
         ASF2.FILE_VERSION_ID
  from   AD_SNAPSHOTS ASN1, AD_SNAPSHOT_FILES ASF1,
         AD_SNAPSHOTS ASN2, AD_SNAPSHOT_FILES ASF2,
         AD_APPL_TOPS AAT
  where  ASN1.SNAPSHOT_ID=ASF1.SNAPSHOT_ID
  and    ASN2.SNAPSHOT_ID=ASF2.SNAPSHOT_ID
  and    ASN1.SNAPSHOT_TYPE='Q'
  and    ASN2.SNAPSHOT_TYPE='G'
  and    ASN1.SNAPSHOT_NAME='GLOBAL_VIEW'
  and    ASN2.SNAPSHOT_NAME=ASN1.SNAPSHOT_NAME
  and    ASN1.APPL_TOP_ID=ASN2.APPL_TOP_ID
  and    ASF1.FILE_ID=ASF2.FILE_ID
  and    NVL(ASF1.CONTAINING_FILE_ID, -2)=NVL(ASF2.CONTAINING_FILE_ID, -2)
  and    NVL(ASF1.FILE_VERSION_ID, -2)<>NVL(ASF2.FILE_VERSION_ID, -2)
  and    ASN1.APPL_TOP_ID=AAT.APPL_TOP_ID
  and    AAT.APPLICATIONS_SYSTEM_NAME=l_applications_system_name
  and    asn1.release_id=l_release_id
  and    asn2.release_id=asn1.release_id
  and    aat.active_flag='Y';

  begin
     for cr in crs
     loop
        update AD_SNAPSHOT_FILES
        set    FILE_VERSION_ID=cr.FILE_VERSION_ID
        where SNAPSHOT_ID=cr.SNAPSHOT_ID
        and   file_id=cr.file_id
        and   nvl(containing_file_id, -2)=nvl(cr.containing_file_id, -2);
     end loop;

     for globalr in grs
     loop
        update AD_SNAPSHOT_FILES
        set    FILE_VERSION_ID=globalr.FILE_VERSION_ID
        where SNAPSHOT_ID=globalr.SNAPSHOT_ID
        and   file_id=globalr.file_id
        and   nvl(containing_file_id, -2)=nvl(globalr.containing_file_id, -2);
   end loop;
 end;

-- Insert the missing records;
  insert into ad_snapshot_files(SNAPSHOT_FILE_ID,          SNAPSHOT_ID,                FILE_ID,
                                CONTAINING_FILE_ID,        FILE_SIZE,                  CHECKSUM,
                                FILE_VERSION_ID,           UPDATE_SOURCE_ID,           UPDATE_TYPE,
                                CREATION_DATE,             LAST_UPDATE_DATE,           LAST_UPDATED_BY,
                                CREATED_BY,                APPL_TOP_ID,                INCONSISTENT_FLAG,
                                SERVER_TYPE_ADMIN_FLAG,    SERVER_TYPE_FORMS_FLAG,     SERVER_TYPE_NODE_FLAG,
                                SERVER_TYPE_WEB_FLAG,      DEST_FILE_ID,               FILE_TYPE_FLAG,
                                IREP_GATHERED_FLAG,        LAST_PATCHED_DATE)
        select AD_SNAPSHOT_FILES_S.NEXTVAL,    ouasnpat.SNAPSHOT_ID,            ouasf.FILE_ID,
               ouasf.CONTAINING_FILE_ID,       ouasf.FILE_SIZE,                 ouasf.CHECKSUM,
               ouasf.FILE_VERSION_ID,          ouasf.UPDATE_SOURCE_ID,          ouasf.UPDATE_TYPE,
               ouasf.CREATION_DATE,            ouasf.LAST_UPDATE_DATE,          ouasf.LAST_UPDATED_BY,
               ouasf.CREATED_BY,               ouasf.APPL_TOP_ID,               ouasf.INCONSISTENT_FLAG,
               ouasf.SERVER_TYPE_ADMIN_FLAG,   ouasf.SERVER_TYPE_FORMS_FLAG,    ouasf.SERVER_TYPE_NODE_FLAG,
               ouasf.SERVER_TYPE_WEB_FLAG,     ouasf.DEST_FILE_ID,              ouasf.FILE_TYPE_FLAG,
               ouasf.IREP_GATHERED_FLAG,       ouasf.LAST_PATCHED_DATE
        from   ad_snapshot_files ouasf, ad_snapshots ouasn, AD_APPL_TOPS ouaat, ad_snapshots ouasnpat
        where  ouasf.SNAPSHOT_ID=OUASN.SNAPSHOT_ID
        and    ouasn.appl_top_id=ouasnpat.appl_top_id
        and    ouasn.release_id=ouasnpat.release_id
        and    ouasnpat.snapshot_type='P'
        and    ouasn.snapshot_name=ouasnpat.snapshot_name
        and    OUASN.SNAPSHOT_TYPE='C'
        and    ouasn.snapshot_name='CURRENT_VIEW'
        and    OUASN.APPL_TOP_ID=OUAAT.APPL_TOP_ID
        and    ouaat.appl_top_id=nvl(p_appl_top_id, ouaat.appl_top_id)
        and    ouaat.appl_top_type='R'
        and    ouaat.applications_system_name=l_applications_system_name
        and    ouasn.release_id=l_release_id
        and    ouaat.active_flag='Y'
        and not exists (
           select 'x'
           from   AD_SNAPSHOT_FILES OUASFPAT
           where  OUASFPAT.SNAPSHOT_ID=OUASNPAT.SNAPSHOT_ID
           and    OUASF.FILE_ID=OUASFPAT.FILE_ID
           and    NVL(OUASF.CONTAINING_FILE_ID, -2)=NVL(OUASFPAT.CONTAINING_FILE_ID, -2));

  insert into ad_snapshot_files(SNAPSHOT_FILE_ID,          SNAPSHOT_ID,                FILE_ID,
                                CONTAINING_FILE_ID,        FILE_SIZE,                  CHECKSUM,
                                FILE_VERSION_ID,           UPDATE_SOURCE_ID,           UPDATE_TYPE,
                                CREATION_DATE,             LAST_UPDATE_DATE,           LAST_UPDATED_BY,
                                CREATED_BY,                APPL_TOP_ID,                INCONSISTENT_FLAG,
                                SERVER_TYPE_ADMIN_FLAG,    SERVER_TYPE_FORMS_FLAG,     SERVER_TYPE_NODE_FLAG,
                                SERVER_TYPE_WEB_FLAG,      DEST_FILE_ID,               FILE_TYPE_FLAG,
                                IREP_GATHERED_FLAG,        LAST_PATCHED_DATE)
        select AD_SNAPSHOT_FILES_S.NEXTVAL,    ouasnpat.SNAPSHOT_ID,            ouasf.FILE_ID,
               ouasf.CONTAINING_FILE_ID,       ouasf.FILE_SIZE,                 ouasf.CHECKSUM,
               ouasf.FILE_VERSION_ID,          ouasf.UPDATE_SOURCE_ID,          ouasf.UPDATE_TYPE,
               ouasf.CREATION_DATE,            ouasf.LAST_UPDATE_DATE,          ouasf.LAST_UPDATED_BY,
               ouasf.CREATED_BY,               ouasf.APPL_TOP_ID,               ouasf.INCONSISTENT_FLAG,
               ouasf.SERVER_TYPE_ADMIN_FLAG,   ouasf.SERVER_TYPE_FORMS_FLAG,    ouasf.SERVER_TYPE_NODE_FLAG,
               ouasf.SERVER_TYPE_WEB_FLAG,     ouasf.DEST_FILE_ID,              ouasf.FILE_TYPE_FLAG,
               ouasf.IREP_GATHERED_FLAG,       ouasf.LAST_PATCHED_DATE
        from   ad_snapshot_files ouasf, ad_snapshots ouasn, AD_APPL_TOPS ouaat, ad_snapshots ouasnpat
        where  ouasf.SNAPSHOT_ID=OUASN.SNAPSHOT_ID
        and    ouasn.appl_top_id=ouasnpat.appl_top_id
        and    ouasn.release_id=ouasnpat.release_id
        and    ouasnpat.snapshot_type='Q'
        and    ouasn.snapshot_name=ouasnpat.snapshot_name
        and    OUASN.SNAPSHOT_TYPE='G'
        and    ouasn.snapshot_name='GLOBAL_VIEW'
        and    OUASN.APPL_TOP_ID=OUAAT.APPL_TOP_ID
        and    ouaat.appl_top_type='G'
        and    ouaat.applications_system_name=l_applications_system_name
        and    ouasn.release_id=l_release_id
        and    ouaat.active_flag='Y'
        and not exists (
           select 'x'
           from   AD_SNAPSHOT_FILES OUASFPAT
           where  OUASFPAT.SNAPSHOT_ID=OUASNPAT.SNAPSHOT_ID
           and    OUASF.FILE_ID=OUASFPAT.FILE_ID
           and    NVL(OUASF.CONTAINING_FILE_ID, -2)=NVL(OUASFPAT.CONTAINING_FILE_ID, -2));

-- Insert Missing records in AD_SNAPSHOT_BUGFIXES Table
  insert into AD_SNAPSHOT_BUGFIXES(SNAPSHOT_BUG_ID, SNAPSHOT_ID, BUGFIX_ID, BUG_STATUS,
                                   SUCCESS_FLAG, CREATION_DATE, LAST_UPDATE_DATE, LAST_UPDATED_BY,
				   CREATED_BY, INCONSISTENT_FLAG)

         select      AD_SNAPSHOT_BUGFIXES_S.NEXTVAL, ouasnpat.SNAPSHOT_ID, OUASF.BUGFIX_ID, OUASF.BUG_STATUS,
                     OUASF.SUCCESS_FLAG, OUASF.CREATION_DATE, OUASF.LAST_UPDATE_DATE, OUASF.LAST_UPDATED_BY,
		     OUASF.CREATED_BY, OUASF.INCONSISTENT_FLAG

         from        AD_SNAPSHOT_BUGFIXES OUASF, AD_SNAPSHOTS OUASN, AD_APPL_TOPS ouaat,
                     AD_SNAPSHOTS ouasnpat

         where       ouasf.SNAPSHOT_ID = ouasn.SNAPSHOT_ID
         and         ouasn.appl_top_id = ouasnpat.appl_top_id
         and         ouasn.release_id = ouasnpat.release_id
         and         ouasnpat.snapshot_type = 'P'
         and         ouasn.snapshot_name=ouasnpat.snapshot_name
         and         ouasn.SNAPSHOT_TYPE = 'C'
         and         ouasn.snapshot_name = 'CURRENT_VIEW'
         and         ouasn.APPL_TOP_ID = ouaat.APPL_TOP_ID
         and         ouaat.appl_top_id=nvl(p_appl_top_id, ouaat.appl_top_id)
         and         ouaat.appl_top_type='R'
         and         ouaat.applications_system_name=l_applications_system_name
         and         ouasn.release_id=l_release_id
         and         ouaat.active_flag='Y'
         and         not exists (
                         select 'x'
                         from   AD_SNAPSHOT_BUGFIXES OUASFPAT
                         where  OUASFPAT.SNAPSHOT_ID=OUASNPAT.SNAPSHOT_ID
                         and    OUASF.BUGFIX_ID=OUASFPAT.BUGFIX_ID);


  insert into AD_SNAPSHOT_BUGFIXES(SNAPSHOT_BUG_ID, SNAPSHOT_ID, BUGFIX_ID, BUG_STATUS,
                                 SUCCESS_FLAG, CREATION_DATE, LAST_UPDATE_DATE, LAST_UPDATED_BY,
								 CREATED_BY, INCONSISTENT_FLAG)

        select      AD_SNAPSHOT_BUGFIXES_S.NEXTVAL, ouasnpat.SNAPSHOT_ID, OUASF.BUGFIX_ID, OUASF.BUG_STATUS,
                    OUASF.SUCCESS_FLAG, OUASF.CREATION_DATE, OUASF.LAST_UPDATE_DATE, OUASF.LAST_UPDATED_BY,
		    OUASF.CREATED_BY, OUASF.INCONSISTENT_FLAG

        from        AD_SNAPSHOT_BUGFIXES OUASF, AD_SNAPSHOTS OUASN, AD_APPL_TOPS ouaat, AD_SNAPSHOTS ouasnpat

        where       ouasf.SNAPSHOT_ID = ouasn.SNAPSHOT_ID
        and         ouasn.appl_top_id = ouasnpat.appl_top_id
        and         ouasn.release_id = ouasnpat.release_id
        and         ouasnpat.snapshot_type = 'Q'
        and         ouasn.snapshot_name=ouasnpat.snapshot_name
        and         ouasn.SNAPSHOT_TYPE = 'G'
        and         ouasn.snapshot_name = 'GLOBAL_VIEW'
        and         ouasn.APPL_TOP_ID = ouaat.APPL_TOP_ID
        and         ouaat.appl_top_type='G'
        and         ouaat.applications_system_name=l_applications_system_name
        and         ouasn.release_id=l_release_id
        and         ouaat.active_flag='Y'
        and         not exists (
                         select 'x'
                         from   AD_SNAPSHOT_BUGFIXES OUASFPAT
                         where  OUASFPAT.SNAPSHOT_ID=OUASNPAT.SNAPSHOT_ID
                         and    OUASF.BUGFIX_ID=OUASFPAT.BUGFIX_ID);

end SYNC_SNAPSHOTS;

/* If p_adop_session_id is provided, then it will return the max codelevel which would have before that session id is staged*/
function get_max_codelevel(p_abbreviation in varchar2, p_adop_session_id in number default -2, p_maxbaseline out nocopy varchar2)
return varchar2
is
maxbaseline varchar2(50);
maxversion varchar2(100) := '0';
result boolean := false;
cursor lvls is
  select baseline, nvl(substr(codelevel, length(baseline)+2, length(codelevel)), '0') lvl
  from ad_te_level_history
  where abbreviation=p_abbreviation
  and (patch_run_id NOT IN (SELECT patchrun_id
                           FROM ad_adop_session_patches pat
                           WHERE adop_session_id>=p_adop_session_id  and patchrun_id is not null)
       or p_adop_session_id = -2);
begin
  for levelrec in lvls
  loop
    if (maxbaseline is null or levelrec.baseline > maxbaseline) then
      maxbaseline := levelrec.baseline;
      maxversion  := levelrec.lvl;
      p_maxbaseline := maxbaseline;
    elsif(levelrec.baseline = maxbaseline) then
      result := ad_patch.compare_versions(maxversion, levelrec.lvl);
      if(result = true) then
        maxversion := levelrec.lvl;
      end if;
    end if;
  end loop;
  return maxversion;
end;

procedure abort_patch_info(x_patch_run_id in number)
is
v_blvl varchar2(150);
v_clvl varchar2(150);
v_query varchar2(4000);
t_or_v_not_exist exception;
PRAGMA EXCEPTION_INIT(t_or_v_not_exist, -942);
v_process_cfhistory boolean := true;

cursor bugs is
select PATCH_RUN_BUG_ID
from   ad_patch_run_bugs
where  PATCH_RUN_ID=x_patch_run_id;

cursor tes is
select distinct abbreviation
from   ad_te_level_history
where  patch_run_id=x_patch_run_id;

begin

-- Cleaning ad_patch_run_bug_actions
  for run_bug_id in bugs
  loop
     delete ad_patch_run_bug_actions
     where  PATCH_RUN_BUG_ID=run_bug_id.patch_run_bug_id;
  end loop;

-- Cleaning ad_patch_run_bug
  delete ad_patch_run_bugs where patch_run_id=x_patch_run_id;

-- Cleaning Codelevels
  for te in tes
  loop
     delete AD_TE_LEVEL_HISTORY
     where  patch_run_id=x_patch_run_id and abbreviation=te.abbreviation;

     begin
        v_clvl := get_max_codelevel(p_abbreviation => te.abbreviation, p_maxbaseline => v_blvl);

        update ad_trackable_entities
        set    baseline=v_blvl, codelevel=DECODE(nvl(v_clvl, 'XXX'), 'XXX', v_blvl,  v_blvl||'.'||v_clvl)
        where  abbreviation=te.abbreviation;
     exception
     when no_data_found
     then
         delete ad_trackable_entities
         where  abbreviation=te.abbreviation;
     when others then null;
     end;
  end loop;

-- Cleaning ad_patch_runs
  delete ad_patch_runs where patch_run_id=x_patch_run_id;

-- Cleaning Checkfile Repository
--  Delete new records created by patch
  v_query :=
    'delete ad_check_files acf                                    ' ||
    'where not exists                                             ' ||
    '      (select ''x''                                          ' ||
    '       from   ad_check_file_history acfh                     ' ||
    '       where  acfh.check_file_id=acf.check_file_id           ' ||
    '       and    acfh.patch_run_id not in (:1, :2)) ';

  begin
    execute immediate v_query using x_patch_run_id, -1;
    v_process_cfhistory := true;
  exception when t_or_v_not_exist then
    v_process_cfhistory := false;
  end;

  if (v_process_cfhistory = true)
  then
     declare
     TYPE cur_typ IS REF CURSOR;
     cs cur_typ;
     v_prid number;
     v_cfid number;
     v_qry varchar2(2000);
     --  Update existing records with older file_version_id
     begin

       v_query := 'select max(ACFH2.PATCH_RUN_ID) PRID,           ' ||
                  '       ACFH2.CHECK_FILE_ID CFID                ' ||
                  'from   AD_CHECK_FILE_HISTORY ACFH1,            ' ||
                  '       AD_CHECK_FILE_HISTORY ACFH2             ' ||
                  'where  ACFH1.CHECK_FILE_ID=ACFH2.CHECK_FILE_ID ' ||
                  'and    ACFH1.PATCH_RUN_ID in (:1, :2)          ' ||
                  'and    ACFH2.PATCH_RUN_ID not in (:3, :4)      ' ||
                  'group by ACFH2.CHECK_FILE_ID';

       open cs for v_query using x_patch_run_id, -1, x_patch_run_id, -1;
       loop
          fetch cs into v_prid, v_cfid;
          exit when cs%NOTFOUND;

          v_qry := 'update ad_check_files acf                     ' ||
                   'set    acf.file_version_id=(                  ' ||
                   '           select acfh.file_Version_id        ' ||
                   '           from   ad_check_file_history acfh  ' ||
                   '           where  acfh.patch_run_id=:1' ||
                   '           and    acfh.check_file_id=:2) ' ||
                   'where acf.check_file_id=:3';
          execute immediate v_qry using v_prid, v_cfid, v_cfid;
       end loop;

       v_qry := 'delete ad_check_file_history acfh ' ||
                'where  acfh.patch_run_id in (:1, :2)';

       execute immediate v_qry using x_patch_run_id, -1;
     end;
  end if;
  SYNC_SNAPSHOTS;
end abort_patch_info;

procedure ABORT(X_MODE in varchar2 default null, X_SESSION_ID in number) is
cursor prids is
SELECT AASP.PATCHRUN_ID
FROM   AD_ADOP_SESSION_PATCHES AASP
WHERE  AASP.ADOP_SESSION_ID=x_session_id
AND  AASP.PATCHRUN_ID IS NOT NULL
UNION
SELECT ACFH.PATCH_RUN_ID
FROM AD_CHECK_FILE_HISTORY ACFH,
     AD_ADOP_SESSION_PATCHES aasp
WHERE ACFH.PATCH_RUN_ID>AASP.PATCHRUN_ID
AND   AASP.ADOP_SESSION_ID=x_session_id
AND   AASP.PATCHRUN_ID<>-1
AND   AASP.PATCHRUN_ID IS NOT NULL;

begin

   ad_zd.abort(x_mode=>X_MODE);
   for prid in prids
   loop
      abort_patch_info(prid.patchrun_id);
   end loop;
end ABORT;

procedure CUTOVER is
begin
   ad_zd.cutover('QUICK');
end CUTOVER;

procedure  FLIP_SNAPSHOTS is
cursor snps is
select AAT.APPL_TOP_ID,
       ASN.SNAPSHOT_ID,
       ASN.SNAPSHOT_NAME,
       ASN.SNAPSHOT_TYPE,
       AR.RELEASE_ID
FROM   AD_APPL_TOPS AAT,
       AD_SNAPSHOTS ASN,
       AD_RELEASES AR,
       FND_PRODUCT_GROUPS FPG,
       FND_NODES FN
WHERE  AAT.APPL_TOP_TYPE='R'
and    aat.active_flag='Y'
AND    AAT.APPL_TOP_ID=ASN.APPL_TOP_ID
and    ASN.SNAPSHOT_TYPE  in ('C', 'P')
and    ASN.SNAPSHOT_NAME='CURRENT_VIEW'
and    AR.RELEASE_ID=ASN.RELEASE_ID
and    AR.MAJOR_VERSION||'.'||AR.MINOR_VERSION||'.'||AR.TAPE_VERSION=FPG.RELEASE_NAME
and    FPG.APPLICATIONS_SYSTEM_NAME = AAT.APPLICATIONS_SYSTEM_NAME
and    UPPER(FN.NODE_NAME)=UPPER(AAT.name)
and    ( FN.SUPPORT_CP='Y' or FN.SUPPORT_FORMS='Y' or FN.SUPPORT_WEB='Y' or FN.SUPPORT_ADMIN='Y')
and    fn.node_name is not null
union
select AAT.APPL_TOP_ID,
       ASN.SNAPSHOT_ID,
       ASN.SNAPSHOT_NAME,
       ASN.SNAPSHOT_TYPE,
       AR.RELEASE_ID
FROM   AD_APPL_TOPS AAT,
       AD_SNAPSHOTS ASN,
       AD_RELEASES AR,
       FND_PRODUCT_GROUPS FPG
WHERE  AAT.APPL_TOP_TYPE='G'
and    aat.active_flag='Y'
and    aat.name='GLOBAL'
AND    AAT.APPL_TOP_ID=ASN.APPL_TOP_ID
and    ASN.SNAPSHOT_TYPE in ('G', 'Q')
and    ASN.SNAPSHOT_NAME='GLOBAL_VIEW'
and    AR.RELEASE_ID=ASN.RELEASE_ID
and    AR.MAJOR_VERSION||'.'||AR.MINOR_VERSION||'.'||AR.TAPE_VERSION=FPG.RELEASE_NAME
and    FPG.APPLICATIONS_SYSTEM_NAME = AAT.APPLICATIONS_SYSTEM_NAME;

begin
  -- Update release_id if necessary
  for snp in snps
  loop
    update ad_snapshots
    set    release_id=snp.release_id
    where  appl_top_id=snp.appl_top_id
    and    snapshot_type=decode(snp.snapshot_type, 'P', 'C', 'Q', 'G')
    and    snapshot_name=snp.snapshot_name
    and    release_id<>snp.release_id;
  end loop;

  -- Flip snapshots
  update ad_snapshots
  set    snapshot_type=DECODE(snapshot_type, 'C', 'P', 'P', 'C',
                                            'G', 'Q', 'Q', 'G')
  where  snapshot_id in (
     select ASN.SNAPSHOT_ID
     FROM   AD_APPL_TOPS AAT,
            AD_SNAPSHOTS ASN,
            AD_RELEASES AR,
            FND_PRODUCT_GROUPS FPG,
            FND_NODES FN
     WHERE  AAT.APPL_TOP_TYPE='R'
     and    aat.active_flag='Y'
     AND    AAT.APPL_TOP_ID=ASN.APPL_TOP_ID
     and    ASN.SNAPSHOT_TYPE  in ('C', 'P')
     and    ASN.SNAPSHOT_NAME='CURRENT_VIEW'
     and    AR.RELEASE_ID=ASN.RELEASE_ID
     and    AR.MAJOR_VERSION||'.'||AR.MINOR_VERSION||'.'||AR.TAPE_VERSION=FPG.RELEASE_NAME
     and    FPG.APPLICATIONS_SYSTEM_NAME = AAT.APPLICATIONS_SYSTEM_NAME
     and    UPPER(FN.NODE_NAME)=UPPER(AAT.name)
     and    ( FN.SUPPORT_CP='Y' or FN.SUPPORT_FORMS='Y' or FN.SUPPORT_WEB='Y' or FN.SUPPORT_ADMIN='Y' )
     and    fn.node_name is not null
     union
     select ASN.SNAPSHOT_ID
     FROM   AD_APPL_TOPS AAT,
            AD_SNAPSHOTS ASN,
            AD_RELEASES AR,
            FND_PRODUCT_GROUPS FPG
     WHERE  AAT.APPL_TOP_TYPE='G'
     and    aat.active_flag='Y'
     AND    AAT.APPL_TOP_ID=ASN.APPL_TOP_ID
     and    ASN.SNAPSHOT_TYPE in ('G', 'Q')
     and    ASN.SNAPSHOT_NAME='GLOBAL_VIEW'
     and    AR.RELEASE_ID=ASN.RELEASE_ID
     and    AR.MAJOR_VERSION||'.'||AR.MINOR_VERSION||'.'||AR.TAPE_VERSION=FPG.RELEASE_NAME
     and    FPG.APPLICATIONS_SYSTEM_NAME = AAT.APPLICATIONS_SYSTEM_NAME);

end FLIP_SNAPSHOTS;

PROCEDURE WAIT_FOR_DB_CUTOVER(p_session_id in number) is
        l_mod_name         varchar2(25) := 'WAIT_FOR_DB_CUTOVER';
        l_cutover_status varchar2(1);
        l_node_name varchar2(256);
        l_appltop_id number;
        l_status varchar2(1);
        type array_t is varray(9) of varchar2(30);
        l_break boolean := false;
--  The sequence of the below array should match with the perl/ADOP/GlobalVars.pm
        cutover_statuses array_t := array_t('N',
                                           '0', --force_shutdown_begin
                                           '1', --force_shutdown
                                           '3', --db_cutover
                                           'D', --flip_snapshots
                                           '4', --fs_cutover
                                           '5', --admin_startup
                                           '6', --force_startup
                                           'Y');
begin
     select node_name,appltop_id into l_node_name,l_appltop_id
     from ad_adop_sessions
     where node_type='master' and adop_session_id=p_session_id;
     loop
       l_cutover_status :=
get_cutover_status(l_appltop_id,l_node_name,p_session_id);
       for i in 1..cutover_statuses.count
       loop
           if (cutover_statuses(i) = '3')
           then
              return;
           end if;
           if (l_cutover_status = cutover_statuses(i))
           then
              exit;
           end if;
       end loop;
       select status into l_status from ad_adop_sessions
       where node_type='master' and adop_session_id=p_session_id;
       if(l_status = 'F') then
          RAISE_APPLICATION_ERROR(-20010,'ERROR: Master in failure status');
       else
          dbms_lock.sleep(60);
       end if;
     end loop;
end WAIT_FOR_DB_CUTOVER;


FUNCTION IS_PATCH_APPLIED_IN_MASTER(
                                    x_patch_no in varchar2,
                                    x_host IN VARCHAR2 default NULL
                                   )
return NUMBER
is
l_mod_name         varchar2(30) := 'IS_PATCH_APPLIED_IN_MASTER';
l_adop_session_id  number:= 0;
l_patch_exists number;
l_invoking_node varchar2(256);
l_admin_node varchar2(256);
l_nodes varchar2(60);
l_ret number;

begin

  select count(1) into l_nodes from
  ( select distinct fn.host
    from fnd_nodes fn, adop_valid_nodes avn
    where fn.host is not null
    and   (fn.support_cp='Y' and fn.support_forms='Y' and
           fn.support_web='Y' and fn.support_admin='Y')
    and server_id is not NULL
    and upper(fn.node_name)=upper(avn.node_name)
  );

if ((l_nodes = 1)  OR (l_nodes < 1) )
then
  return 1;
end if;

  SELECT node_name
  INTO   l_admin_node
  FROM   FND_OAM_CONTEXT_FILES
  WHERE  NAME not in ('TEMPLATE','METADATA','config.txt')
  AND    CTX_TYPE='A' and (status is null or upper(status) in ('S','F'))
  AND    EXTRACTVALUE(XMLType(TEXT),'//file_edition_type') = 'run'
  AND    EXTRACTVALUE(XMLType(TEXT),'//oa_service_group_status[@oa_var=''s_web_admin_status'']')='enabled'
  AND    EXTRACTVALUE(XMLType(TEXT),'//oa_service_list/oa_service[@type=''admin_server'']/oa_service_status')='enabled';

  SELECT NVL(MAX(ADOP_SESSION_ID),0)
  INTO   l_adop_session_id
  FROM   AD_ADOP_SESSIONS
  WHERE  APPLY_STATUS IN ('P','N')
  AND    PREPARE_STATUS IN ('Y','X')
  AND    ABORT_STATUS <> 'Y'
  AND    CLEANUP_STATUS <> 'Y'
  AND    ADOP_SESSION_ID = (SELECT MAX(ADOP_SESSION_ID) FROM AD_ADOP_SESSIONS);
  if (l_adop_session_id =0) then
    -- if comes here then someone running adpatch directly
    -- such sitution INSERT_INTO_PATCHES_TABLE inserting
    -- latest session id so here also get the max session id
    select max(adop_session_id) into l_adop_session_id from ad_adop_session_patches;
  end if;
  if (x_host IS NOT NULL)
  then
    l_invoking_node := x_host;
  else
    SELECT  sys_context ('userenv','HOST') into l_invoking_node from dual;
  end if;

  if(upper(l_invoking_node) <> upper(l_admin_node)) then
          SELECT COUNT(1) INTO l_patch_exists
            FROM AD_ADOP_SESSION_PATCHES
            WHERE STATUS in ('S','Y')
            AND BUG_NUMBER = x_patch_no
            AND ADOP_SESSION_ID = l_adop_session_id
            AND NODE_NAME = l_admin_node;
            if (l_patch_exists >= 1)
	    then
	      return 1;
	    else
	      return 0;
	    end if;
  end if;
 return 1;
end IS_PATCH_APPLIED_IN_MASTER;

FUNCTION IS_ICM_ALIVE RETURN NUMBER
IS
BEGIN
 if(fnd_conc.icm_alive(false)) then
    return 1;
 else
    return 0;
 end if;
END IS_ICM_ALIVE;

FUNCTION EVAL_SRV_STATUS(avail_node_list in VARCHAR2) RETURN BOOLEAN IS

  l_mod_name         varchar2(25) := 'EVAL_SRV_STATUS';
  TYPE service_map_type IS TABLE OF NUMBER INDEX BY VARCHAR2(30);
  TYPE service_varray IS VARRAY(20) OF VARCHAR2(40);

  service_map service_map_type;
  group_service_map service_map_type;

  avail_service_map service_map_type;
  avail_group_service_map service_map_type;

  services service_varray := service_varray('s_nodemanagerstatus','s_adminserverstatus',
                                            's_opmnstatus','s_apcstatus','s_oacorestatus',
                                            's_formsstatus','s_oafmstatus','s_forms-c4wsstatus',
                                            's_tnsstatus','s_concstatus','s_icsmstatus',
                                            's_jtffsstatus','s_formsserver_status',
                                            's_metcstatus','s_metsstatus','s_mwastatus');

  group_services service_varray := service_varray('s_root_status','s_web_admin_status',
                                                  's_web_entry_status','s_web_applications_status',
                                                  's_batch_status','s_other_service_group_status');

  cursor service_status is
     select
      (XMLQuery(
      ' for $i in /oa_context/oa_services/oa_service_list/oa_service/oa_service_status
       where $i/text() eq "enabled"
       return fn:concat($i/@oa_var,",") '
       PASSING XMLType(TEXT) RETURNING CONTENT
      )).getStringVal() services, node_name node
     from FND_OAM_CONTEXT_FILES
     where NAME not in ('TEMPLATE','METADATA','config.txt') and
           CTX_TYPE='A' and (status is null or upper(status) in ('S','F'))
           and EXTRACTVALUE(XMLType(TEXT),'//file_edition_type') = 'patch';


  cursor group_service_status is
    select
     (XMLQuery(
     ' for $i in /oa_context/oa_services/oa_service_group_list/oa_service_group/oa_service_group_status
      where $i/text() eq "enabled"
      return fn:concat($i/@oa_var,",") '
      PASSING XMLType(TEXT) RETURNING CONTENT
     )).getStringVal() group_services, node_name node
    from FND_OAM_CONTEXT_FILES
    where NAME not in ('TEMPLATE','METADATA','config.txt') and
          CTX_TYPE='A' and (status is null or upper(status) in ('S','F'))
          and EXTRACTVALUE(XMLType(TEXT),'//file_edition_type')= 'patch';


BEGIN

  log(l_mod_name,'STATEMENT', 'Node List:'||avail_node_list);

  if(avail_node_list is NULL) then
    return FALSE;
  end if;

  for i IN services.FIRST..services.LAST loop
      service_map(services(i)) := 0;
      avail_service_map(services(i)) := 0;
  end loop;

  for i IN group_services.FIRST..group_services.LAST loop
      group_service_map(group_services(i)) := 0;
      avail_group_service_map(group_services(i)) := 0;
  end loop;

  for rec in service_status loop
      for i IN services.FIRST..services.LAST loop
        if (INSTR( rec.services, services(i) ) > 0) then
          service_map(services(i)) := service_map(services(i)) + 1;
          if (INSTR(avail_node_list, rec.node ) > 0) then
            avail_service_map(services(i)) := avail_service_map(services(i)) + 1;
          end if;
        end if;

      end loop;
  end loop;

  for rec in group_service_status loop
      for i IN group_services.FIRST..group_services.LAST loop
        if (INSTR( rec.group_services, group_services(i) ) > 0) then
          group_service_map(group_services(i)) := group_service_map(group_services(i)) + 1;

          if (INSTR(avail_node_list, rec.node ) > 0) then
            avail_group_service_map(group_services(i)) := avail_group_service_map(group_services(i)) + 1;
          end if;

        end if;
      end loop;
  end loop;

  for i IN services.FIRST..services.LAST loop
      if ( (service_map(services(i)) > 0) and (avail_service_map(services(i)) = 0) ) then
         return FALSE;
      end if;
  end loop;

  for i IN group_services.FIRST..group_services.LAST loop
      if ( (group_service_map(group_services(i)) = 1) and (avail_group_service_map(group_services(i)) = 0) ) then
         return FALSE;
      end if;
  end loop;

  return TRUE;
END EVAL_SRV_STATUS;

FUNCTION IS_ABORTABLE RETURN BOOLEAN IS
abort_status   VARCHAR2(1);
BEGIN

  begin
    select abort_status into abort_status from ad_adop_sessions
    where prepare_status <> 'X' and node_type='master' and
    adop_session_id = (select max(adop_session_id) from ad_adop_sessions where
    prepare_status <> 'X' and node_type='master');
  exception
    when no_data_found then
       return FALSE;
  end;

  if(abort_status <> 'X' and abort_status <> 'Y') then
     return TRUE;
  end if;
  return FALSE;
END IS_ABORTABLE;

FUNCTION ADOP_HEALTH_CHECK(phase in VARCHAR2,node in VARCHAR2) RETURN NUMBER IS

session_id NUMBER;
l_valid_prep_status VARCHAR2(30);
st NUMBER := 1;
ed NUMBER;
node_name VARCHAR2(256);
cnt NUMBER := 0;
cnt1 NUMBER := 0;
TYPE node_map_type IS TABLE OF NUMBER INDEX BY VARCHAR2(256);
node_map node_map_type;
node_list VARCHAR2(32767) := NULL;
succ_flag BOOLEAN := TRUE;
l_cutover_status varchar2(30);
l_abort_status   varchar2(30);
l_cleanup_status varchar2(30);

BEGIN
  --get the latest patching cycle session id
  begin
    select max(adop_session_id) into session_id from ad_adop_sessions
    where node_type='master';
    if (session_id is null) then
       return 0;
    end if;
  exception
    when no_data_found then
       return 0;
  end;

  for rec in (select node_name from ad_adop_sessions where adop_session_id = session_id) loop
    node_map(rec.node_name) := 1;
  end loop;

  if (phase = 'prepare') then
     select cutover_status, abort_status, cleanup_status
       into l_cutover_status, l_abort_status, l_cleanup_status
     from  ad_adop_sessions
     where adop_session_id=session_id and node_type='master';

     -- if any of below conditions are true then online patching cycle does
     -- not exist so means prepare if attempted had failed
     if( l_cutover_status = 'Y' or
         l_abort_status = 'Y' or
         l_cleanup_status = 'Y' or
         l_cutover_status = 'X')
     then
       return 1;
     end if;
     select count(1) into cnt from ad_adop_sessions where adop_session_id = session_id
     and prepare_status not in ('X','Y');

     if ( cnt > 0 ) then
       for rec in (select node_name from ad_adop_sessions where adop_session_id
       = session_id and prepare_status not in ('X','Y')) loop
         node_map(rec.node_name) := 0;
       end loop;
     end if;

  end if;

  if (phase = 'apply' or phase='hotpatch_apply') then
     if ( phase = 'apply') then
        l_valid_prep_status := 'Y';
     else
        l_valid_prep_status := 'X';
     end if;

     select count(1) into cnt from ad_adop_sessions where adop_session_id =
     session_id and ((apply_status = 'N') or (apply_status='P' and
     status in ('F','R')) or prepare_status<>l_valid_prep_status);

     if (cnt > 0 ) then
        for rec in (select node_name from ad_adop_sessions where adop_session_id=
           session_id and ( (apply_status = 'N') or(apply_status='P' and
           status in ('F','R')) or prepare_status<>l_valid_prep_status)) loop
         node_map(rec.node_name) := 0;
        end loop;
     end if;

     if (node is null) then
        node_list := get_out_of_sync_apply_nodes(session_id);
        if node_list is not NULL then
           loop
              ed := instr(node_list,',',st);
              if (ed = 0) then
                 node_name := substr(node_list,st);
                 node_map(node_name) := 0;
                 exit;
              end if;
              node_name := substr(node_list,st,ed-st);
              node_map(node_name) := 0;
              st := ed+1;
           end loop;
           node_list := NULL;
        end if;
     end if;
  end if;

  if (phase = 'cutover') then
     select count(1) into cnt from ad_adop_sessions where adop_session_id =
     session_id and cutover_status not in ('X','Y');

     if ( cnt > 0 ) then
       for rec in (select node_name from ad_adop_sessions where adop_session_id
       = session_id and cutover_status not in ('X','Y')) loop
         node_map(rec.node_name) := 0;
       end loop;
     end if;
  end if;

  if (phase = 'abort') then
     select count(1) into cnt from ad_adop_sessions where adop_session_id =
     session_id and abort_status not in ('X','Y');

     if ( cnt > 0 ) then
       for rec in (select node_name from ad_adop_sessions where adop_session_id
       = session_id and abort_status not in ('X','Y')) loop
         node_map(rec.node_name) := 0;
       end loop;
     end if;
  end if;

    if (phase = 'finalize') then
     select count(1) into cnt from ad_adop_sessions where adop_session_id = session_id
     and finalize_status not in ('X','Y');

     if ( cnt > 0 ) then
       for rec in (select node_name from ad_adop_sessions where adop_session_id
       = session_id and finalize_status not in ('X','Y')) loop
         node_map(rec.node_name) := 0;
       end loop;
     end if;
  end if;

  if (phase = 'cleanup') then
     select count(1) into cnt from ad_adop_sessions where adop_session_id = session_id
     and cleanup_status not in ('Y');

     if ( cnt > 0 ) then
       for rec in (select node_name from ad_adop_sessions where adop_session_id
       = session_id and cleanup_status not in ('Y')) loop
         node_map(rec.node_name) := 0;
       end loop;
     end if;
  end if;

  if (phase = 'fs_clone') then
    select count(1) into cnt from ad_adop_session_patches where bug_number in ('CLONE','CONFIG_CLONE');

     if ( cnt > 0 ) then
       for rec in (select node_name from ad_adop_session_patches where
         bug_number in ('CLONE','CONFIG_CLONE') and status in ('N', 'R', 'F')) loop
         node_map(rec.node_name) := 0;
       end loop;
     end if;

     if ( cnt = 0 ) then
      return 0;
    end if;
  end if;

  if(node is not NULL) then
    if(node_map(node) = 0) then
      return 1;
    else
      return 2;
    end if;
  end if;

  for rec in (select node_name from ad_adop_sessions where adop_session_id = session_id) loop
    if ((node_map(rec.node_name)) = 1) then
      node_list := node_list || ',' || rec.node_name;
    else
      succ_flag := FALSE;
    end if;
  end loop;

  if(succ_flag) then
    return 3;
  end if;

  if(EVAL_SRV_STATUS(node_list)) then
    return 2;
  else
    return 1;
  end if;

END ADOP_HEALTH_CHECK;


FUNCTION IS_ABANDONED(node in varchar2) RETURN NUMBER IS
  l_session_id number;
  l_abandon_flag number;
  l_cnt number;

BEGIN

  select max(adop_session_id) into l_session_id
  from ad_adop_sessions
  where node_type='master' and prepare_status <> 'X';

  select abandon_flag into l_abandon_flag
  from ad_adop_sessions
  where adop_session_id = l_session_id and node_name = node;

  if (l_abandon_flag <> l_session_id) then
     return 2;
  else
     select count(1) into l_cnt from ad_adop_sessions
     where node_type = 'master' and
     adop_session_id = l_session_id and
     cutover_status in ('4','5','6','Y');
     if l_cnt > 0 then
       select count(1) into l_cnt from ad_adop_sessions slave, ad_adop_sessions master
       where
         (((slave.prepare_status <> master.prepare_status) and
          (slave.prepare_status <> 'Y')) or
         ((slave.apply_status   <> master.apply_status) and
         (slave.apply_status <> 'Y')) or
         ((slave.cutover_status <> master.cutover_status) and
         (slave.cutover_status  not in ('4','5','6','Y'))) or
         ((slave.abort_status   <> master.abort_status) and
         (slave.abort_status <> 'Y'))) and
         master.adop_session_id = l_session_id and
         slave.adop_session_id  = l_session_id and
         master.node_type = 'master' and
         slave.node_name = node;

       if l_cnt > 0 then
         return 1;
       end if;
     end if;
  end if;
  return 0;
END IS_ABANDONED;

FUNCTION GET_ABANDONED_NODES(p_mode in varchar2) RETURN VARCHAR2 IS
  l_session_id number;
  l_node_list VARCHAR2(32767) := NULL;
  l_cnt number;

  TYPE cutover_status_map_type IS TABLE OF NUMBER INDEX BY VARCHAR2(1);
  cutover_status_map cutover_status_map_type;
BEGIN

  select max(adop_session_id) into l_session_id
  from ad_adop_sessions
  where node_type='master' and prepare_status <> 'X';

  cutover_status_map('N') := 10;
  cutover_status_map('0') := 20;
  cutover_status_map('1') := 30;
  cutover_status_map('3') := 40;
  cutover_status_map('D') := 50;
  cutover_status_map('4') := 60;
  cutover_status_map('5') := 65;
  cutover_status_map('6') := 70;
  cutover_status_map('Y') := 80;

  if (p_mode = 'ABANDONED') then
    for rec in (select node_name from ad_adop_sessions where
                adop_session_id=l_session_id and
                abandon_flag <> l_session_id)
    loop
       if l_node_list is NULL then
          l_node_list := rec.node_name;
       else
          l_node_list := l_node_list || ',' || rec.node_name;
       end if;
    end loop;
  else
     select count(1) into l_cnt from ad_adop_sessions
     where node_type = 'master' and
     adop_session_id = l_session_id and
     cutover_status in ('4','6','Y');
     if l_cnt > 0 then
       for rec in (
        select slave.node_name node_name, slave.cutover_status cutover_status
        from ad_adop_sessions slave,ad_adop_sessions master
        where
         (((slave.prepare_status <> master.prepare_status) and
          (slave.prepare_status <> 'Y')) or
         ((slave.apply_status   <> master.apply_status) and
         (slave.apply_status <> 'Y')) or
         ((slave.cutover_status <> master.cutover_status) and
         (slave.cutover_status  not in ('4','5','6','Y'))) or
         ((slave.abort_status   <> master.abort_status) and
         (slave.abort_status <> 'Y'))) and
         master.adop_session_id = l_session_id and
         slave.adop_session_id  = l_session_id and
         slave.abandon_flag = l_session_id and
         master.node_type = 'master' and
         slave.node_type = 'slave')
      loop
       if (cutover_status_map(rec.cutover_status) > cutover_status_map('D')) then
          if l_node_list is NULL then
             l_node_list := rec.node_name;
          else
             l_node_list := l_node_list || ',' || rec.node_name;
          end if;
       end if;
      end loop;
    end if;
  end if;
  return l_node_list;
END GET_ABANDONED_NODES;

PROCEDURE CLEAR_ABANDON_FLAG(dest_node in varchar2) IS
BEGIN

  update ad_adop_sessions set abandon_flag = NULL
  where node_name=dest_node  and abandon_flag is not null and
        adop_session_id = (select max(adop_session_id) from ad_adop_sessions where
                           ((prepare_status='Y' and apply_status='Y' and cutover_status='Y') or
                            (abort_status='Y')) and node_type='master');
  commit;

END CLEAR_ABANDON_FLAG;

--returns active patching Cycle ADOP Session ID
--we also can extend this api in future
PROCEDURE GET_ACTIV_PATCHING_SES_DETAILS(id out NOCOPY NUMBER) IS
begin
   select max(adop_session_id)
   into id
   from ad_adop_sessions
   where prepare_status <> 'X'
   and node_type='master'
   and cutover_status = 'N'
   and abort_status='N';
end GET_ACTIV_PATCHING_SES_DETAILS;

FUNCTION GET_OUT_OF_SYNC_APPLY_NODES(p_session_id in number) return varchar2 IS
  l_session_id number;
  l_node_list VARCHAR2(32767) := NULL;
  l_different_status number := 0;
  l_current_bug varchar2(30) := NULL;
  l_current_driver_file_name varchar2(50) := NULL;
  l_max_status varchar2(1):='0';

  TYPE node_map_type IS TABLE OF NUMBER INDEX BY VARCHAR2(256);
  node_map node_map_type;

  TYPE status_order_t IS TABLE OF NUMBER INDEX BY VARCHAR2(1);
  status_order        status_order_t;

  TYPE status_tractker_t IS TABLE OF VARCHAR2(1);
  status_tracker status_tractker_t := status_tractker_t();

  cursor bugs_list is
     select bug_number,driver_file_name,status from ad_adop_session_patches
     where adop_session_id = p_session_id and
     (adpatch_options is NULL or not (adpatch_options like '%nocopyportion%' and adpatch_options like '%nogenerateportion%')) and
     bug_number NOT IN ('CLONE','CONFIG_CLONE') and bug_number not like 'ADADMIN%' and bug_number not like 'ADSPLICE%'
     group by bug_number,driver_file_name,status
     order by bug_number,driver_file_name,status;

BEGIN
  for rec in (select node_name from ad_adop_sessions where adop_session_id = p_session_id) loop
    node_map(rec.node_name) := 1;
  end loop;

  status_order('N'):=1;
  status_order('R'):=2;
  status_order('H'):=3;
  status_order('F'):=4;
  status_order('S'):=5;
  status_order('Y'):=6;

  for i in 1..status_order.count() loop
    status_tracker.extend;
    status_tracker(i) := '0';
  end loop;

  for rec in bugs_list loop

     if ( (l_current_bug||'_'||l_current_driver_file_name) <> (rec.bug_number||'_'||rec.driver_file_name)) then

        if (l_different_status > 0) then
            for i in 1..status_order.count() loop
              if(status_tracker(i) <>  '0') then
                 l_max_status:=status_tracker(i);
              end if;
            end loop;
            if (l_max_status = 'Y' OR l_max_status = 'S') then
              for r in (select node_name from ad_adop_session_patches where
              bug_number = l_current_bug  and driver_file_name =
              l_current_driver_file_name and status not in ('Y','S')) loop
                node_map(r.node_name) := 0;
              end loop;
            else
              for r in (select node_name from ad_adop_session_patches where
              bug_number = l_current_bug  and driver_file_name =
              l_current_driver_file_name and status <> l_max_status) loop
                node_map(r.node_name) := 0;
              end loop;
            end if;
        end if;

        l_different_status := 0;
        for i in 1..status_order.count() loop
            status_tracker(i):='0';
        end loop;
        status_tracker(status_order(rec.status)) := rec.status;
        l_current_bug := rec.bug_number;
        l_current_driver_file_name := rec.driver_file_name;

     else
        if (status_tracker(status_order(rec.status)) = '0') then
           l_different_status := l_different_status +1;
           status_tracker(status_order(rec.status)) := rec.status;
        end if;
     end if;

  end loop;


  if (l_different_status > 0) then
     for i in 1..status_order.count() loop
       if(status_tracker(i) <>  '0') then
          l_max_status:=status_tracker(i);
       end if;
     end loop;

     if (l_max_status = 'Y' OR l_max_status = 'S') then
       for r in (select node_name from ad_adop_session_patches where
         bug_number = l_current_bug  and driver_file_name =
         l_current_driver_file_name and status not in ('Y','S')) loop
           node_map(r.node_name) := 0;
       end loop;
     else
       for r in (select node_name from ad_adop_session_patches where
         bug_number = l_current_bug  and driver_file_name =
         l_current_driver_file_name and status <> l_max_status) loop
         node_map(r.node_name) := 0;
       end loop;
     end if;

  end if;


  for rec in (select node_name from ad_adop_sessions where adop_session_id = p_session_id) loop
    if ((node_map(rec.node_name)) = 0) then
      if l_node_list is not NULL then
         l_node_list := l_node_list || ',';
      end if;
      l_node_list := l_node_list || rec.node_name;
    end if;
  end loop;

  return l_node_list;

END GET_OUT_OF_SYNC_APPLY_NODES;

FUNCTION GET_OUT_OF_SYNC_PATCHES(p_session_id in number) return varchar2 IS
  l_session_id number;
  l_node_patches_list VARCHAR2(32767) := NULL;
  l_different_status number := 0;
  l_current_bug varchar2(30) := NULL;
  l_current_driver_file_name varchar2(50) := NULL;
  l_max_status varchar2(1):='0';

  TYPE node_map_type IS TABLE OF NUMBER INDEX BY VARCHAR2(256);
  node_map node_map_type;

  TYPE status_order_t IS TABLE OF NUMBER INDEX BY VARCHAR2(1);
  status_order        status_order_t;

  TYPE status_tractker_t IS TABLE OF VARCHAR2(1);
  status_tracker status_tractker_t := status_tractker_t();

  TYPE out_of_sync_patch_map_type IS TABLE OF VARCHAR2(32767) INDEX BY VARCHAR2(30);
  out_of_sync_patch_map out_of_sync_patch_map_type;

  cursor bugs_list is
     select bug_number,driver_file_name,status from ad_adop_session_patches
     where adop_session_id = p_session_id and
     (adpatch_options is NULL or not (adpatch_options like '%nocopyportion%' and adpatch_options like '%nogenerateportion%')) and
     bug_number NOT IN ('CLONE','CONFIG_CLONE') and bug_number not like 'ADADMIN%' and bug_number not like 'ADSPLICE%'
     group by bug_number,driver_file_name,status
     order by bug_number,driver_file_name,status;

BEGIN
  for rec in (select node_name from ad_adop_sessions where adop_session_id = p_session_id) loop
    node_map(rec.node_name) := 1;
    out_of_sync_patch_map(rec.node_name) := NULL;
  end loop;

  status_order('N'):=1;
  status_order('R'):=2;
  status_order('H'):=3;
  status_order('F'):=4;
  status_order('S'):=5;
  status_order('Y'):=6;

  for i in 1..status_order.count() loop
    status_tracker.extend;
    status_tracker(i) := '0';
  end loop;

  for rec in bugs_list loop

     if ( (l_current_bug||'_'||l_current_driver_file_name) <> (rec.bug_number||'_'||rec.driver_file_name)) then

        if (l_different_status > 0) then
            for i in 1..status_order.count() loop
              if(status_tracker(i) <>  '0') then
                 l_max_status:=status_tracker(i);
              end if;
            end loop;
            if (l_max_status = 'Y' OR l_max_status = 'S') then
              for r in (select node_name from ad_adop_session_patches where
                        bug_number = l_current_bug  and driver_file_name =
                        l_current_driver_file_name and status not in ('Y','S')) loop
                 node_map(r.node_name) := 0;
                 if out_of_sync_patch_map(r.node_name) is not NULL then
                    out_of_sync_patch_map(r.node_name) := out_of_sync_patch_map(r.node_name) || ',';
                 end if;
                 out_of_sync_patch_map(r.node_name) := out_of_sync_patch_map(r.node_name) || l_current_bug;
              end loop;
            else
              for r in (select node_name from ad_adop_session_patches where
                        bug_number = l_current_bug  and driver_file_name =
                        l_current_driver_file_name and status <> l_max_status) loop
                 node_map(r.node_name) := 0;
                 if out_of_sync_patch_map(r.node_name) is not NULL then
                    out_of_sync_patch_map(r.node_name) := out_of_sync_patch_map(r.node_name) || ',';
                 end if;
                 out_of_sync_patch_map(r.node_name) := out_of_sync_patch_map(r.node_name) || l_current_bug;
              end loop;
            end if;
        end if;

        l_different_status := 0;
        for i in 1..status_order.count() loop
            status_tracker(i):='0';
        end loop;
        status_tracker(status_order(rec.status)) := rec.status;
        l_current_bug := rec.bug_number;
        l_current_driver_file_name := rec.driver_file_name;

     else
        if (status_tracker(status_order(rec.status)) = '0') then
           l_different_status := l_different_status +1;
           status_tracker(status_order(rec.status)) := rec.status;
        end if;
     end if;

  end loop;


  if (l_different_status > 0) then
     for i in 1..status_order.count() loop
       if(status_tracker(i) <>  '0') then
          l_max_status:=status_tracker(i);
       end if;
     end loop;

     if (l_max_status = 'Y' OR l_max_status = 'S') then
       for r in (select node_name from ad_adop_session_patches where
                 bug_number = l_current_bug  and driver_file_name =
                 l_current_driver_file_name and status not in ('Y','S')) loop
           node_map(r.node_name) := 0;
           if out_of_sync_patch_map(r.node_name) is not NULL then
              out_of_sync_patch_map(r.node_name) := out_of_sync_patch_map(r.node_name) || ',';
           end if;
           out_of_sync_patch_map(r.node_name) := out_of_sync_patch_map(r.node_name) || l_current_bug;
       end loop;
     else
       for r in (select node_name from ad_adop_session_patches where
                 bug_number = l_current_bug  and driver_file_name =
                 l_current_driver_file_name and status <> l_max_status) loop
           node_map(r.node_name) := 0;
           if out_of_sync_patch_map(r.node_name) is not NULL then
              out_of_sync_patch_map(r.node_name) := out_of_sync_patch_map(r.node_name) || ',';
           end if;
           out_of_sync_patch_map(r.node_name) := out_of_sync_patch_map(r.node_name) || l_current_bug;
       end loop;
     end if;

  end if;


  for rec in (select node_name from ad_adop_sessions where adop_session_id = p_session_id) loop
    if ((node_map(rec.node_name)) = 0) then
      if l_node_patches_list is not NULL then
         l_node_patches_list := l_node_patches_list || ';';
      end if;
      l_node_patches_list := l_node_patches_list || rec.node_name || '#' || out_of_sync_patch_map(rec.node_name);
    end if;
  end loop;

  return l_node_patches_list;

END GET_OUT_OF_SYNC_PATCHES;

function CHECK_PENDING_CLONE(l_runbase in varchar2,l_patchbase in varchar2) return varchar2 is
   C_MODULE          varchar2(80) := 'check_pending_clone';
   NODELIST          varchar2(2000) := '';
   L_COUNT_EXIST     number(3) :=0;
   L_SESSION_ID      number;

begin
      log (C_MODULE,'STATEMENT', 'run base: ' || l_runbase || ' patch base: '|| l_patchbase);

      -- Get current session id value bug21546094

      select max(adop_session_id) into l_session_id
             from ad_adop_session_patches;

      -- Check if any CLONE failure status and abort cycle for current
      -- sesion id bug21546094.

      select count(1) into l_count_exist
             from ad_adop_session_patches aasp, ad_adop_sessions aas
             where aasp.applied_file_system_base=l_runbase
             and aasp.patch_file_system_base=l_patchbase
             and aasp.bug_number='CLONE'
             and aasp.status in ('N','F')
             and aasp.adop_session_id = l_session_id
             and aas.adop_session_id = l_session_id
             and aas.node_name = aasp.node_name
             and aas.abort_status = 'Y';

     -- Return the list of nodes that are pending/failed and abort cycle
     -- executed for the current session id bug21546094

     if (l_count_exist > 0) then
         select listagg(node_name,',') within group (order by node_name)
           into nodelist
           from (select distinct node_name
                        from ad_adop_session_patches
                        where  applied_file_system_base=l_runbase
                        and patch_file_system_base=l_patchbase
                        and bug_number='CLONE'
                        and status in ('N','F')
                        and adop_session_id = l_session_id
                 intersect
                 select node_name
                        from ad_adop_sessions
                        where abort_status='Y'
                        and adop_session_id = l_session_id);
   else
     nodelist := 'none';
   end if;
   log (c_module,'STATEMENT','fs_clone pending at nodelist: ' || nodelist);
   return nodelist;
exception
     when no_data_found then
       null;
     when others then
	   log(C_MODULE, 'ERROR', 'ERROR: '||SQLERRM);
end CHECK_PENDING_CLONE;

FUNCTION IS_PATCH_APPLIED_IN_S_MASTER( x_patch_no in varchar2,
                                       x_super_node in varchar2,
                                       x_host IN VARCHAR2 default NULL
                                     ) return NUMBER
is
l_mod_name         varchar2(30) := 'IS_PATCH_APPLIED_IN_S_MASTER';
l_adop_session_id  number:= 0;
l_patch_exists number;
l_invoking_node varchar2(256);
l_nodes varchar2(60);
l_ret number;

begin
  select count(1) into l_nodes from
  ( select distinct fn.host
    from fnd_nodes fn, adop_valid_nodes avn
    where fn.host is not null
    and   (fn.support_cp='Y' and fn.support_forms='Y' and
           fn.support_web='Y' and fn.support_admin='Y')
    and server_id is not NULL
    and upper(fn.node_name)=upper(avn.node_name)
  );

if ((l_nodes = 1)  OR (l_nodes < 1) )
then
  return 1;
end if;

  SELECT NVL(MAX(ADOP_SESSION_ID),0)
  INTO   l_adop_session_id
  FROM   AD_ADOP_SESSIONS
  WHERE  APPLY_STATUS IN ('P','N')
  AND    PREPARE_STATUS IN ('Y','X')
  AND    ABORT_STATUS <> 'Y'
  AND    CLEANUP_STATUS <> 'Y'
  AND    ADOP_SESSION_ID = (SELECT MAX(ADOP_SESSION_ID) FROM AD_ADOP_SESSIONS);
  if (l_adop_session_id =0) then
    -- if comes here then someone running adpatch directly
    -- such sitution INSERT_INTO_PATCHES_TABLE inserting
    -- latest session id so here also get the max session id
    select max(adop_session_id) into l_adop_session_id from ad_adop_session_patches;
  end if;


  if (x_host IS NOT NULL)
  then
    l_invoking_node := x_host;
  else
    SELECT  sys_context ('userenv','HOST') into l_invoking_node from dual;
  end if;

  if(upper(l_invoking_node) <> upper(x_super_node)) then
          SELECT COUNT(1) INTO l_patch_exists
            FROM AD_ADOP_SESSION_PATCHES
            WHERE STATUS in ('S','Y')
            AND BUG_NUMBER = x_patch_no
            AND ADOP_SESSION_ID = l_adop_session_id
            AND NODE_NAME = x_super_node;
        if (l_patch_exists >= 1)
	    then
	      return 1;
	    else
	      return 0;
	    end if;
  end if;
 return 1;
end IS_PATCH_APPLIED_IN_S_MASTER;

FUNCTION GET_INVALID_NODES RETURN VARCHAR2 IS
  l_mod_name  varchar2(30) := 'GET_INVALID_NODES';
  l_node_list VARCHAR2(32767) := NULL;
BEGIN
for rec in (select node_name from adop_valid_nodes avn
            where not exists
           (select 1 from fnd_nodes fn
            where upper(fn.node_name)=upper(avn.node_name)))
 loop
    if l_node_list is NULL then
       l_node_list := rec.node_name;
    else
       l_node_list := l_node_list || ',' || rec.node_name;
    end if;
 end loop;

 log(l_mod_name,'STATEMENT', 'Invalid Node List:'||l_node_list);
 return l_node_list;
END GET_INVALID_NODES;

PROCEDURE INSTALL_APPS_DDLS( schema in varchar2) IS
  l_stmt clob;
  l_schema varchar2(32);
  c_module varchar2(80) := 'install_apps_ddls';
BEGIN
  l_schema := upper(trim(schema));
  l_stmt := dbms_metadata.get_ddl('PACKAGE_SPEC','APPS_DDL','APPS');
  l_stmt := regexp_replace(l_stmt,'"APPS"' || '.','"' || l_schema || '".');
  execute immediate l_stmt;

  l_stmt :=null;
  l_stmt := dbms_metadata.get_ddl('PACKAGE_BODY','APPS_DDL','APPS');
  l_stmt := regexp_replace(l_stmt,'"APPS"' || '.','"' || l_schema || '".');
  execute immediate l_stmt;

  l_stmt :=null;
  l_stmt := dbms_metadata.get_ddl('PACKAGE_SPEC','APPS_ARRAY_DDL','APPS');
  l_stmt := regexp_replace(l_stmt,'"APPS"' || '.','"' || l_schema || '".');
  execute immediate l_stmt;

  l_stmt :=null;
  l_stmt := dbms_metadata.get_ddl('PACKAGE_BODY','APPS_ARRAY_DDL','APPS');
  l_stmt := regexp_replace(l_stmt,'"APPS"' || '.','"' || l_schema || '".');
  execute immediate l_stmt;
  exception
     when no_data_found then
       null;
     when others then
	   log(c_module, 'ERROR', 'ERROR: '||SQLERRM);
END INSTALL_APPS_DDLS;

/*----------------------------------------------------------------------------|
| Function to check if a user has grants on an object or it has some
| privileges
|
| To check if user has grants on an object
| select ad_zd_adop.check_privs('APPS','SELECT',
|                                'SYS','OBJ$') from dual;
|
| To check if a user has some privilege
| select ad_zd_adop.check_privs('APPS','CREATE ANY EDITION')
|                            from dual;
| Output: TRUE  - If user has grants
|         FALSE - If user does not have grants
|
------------------------------------------------------------------------------|
*/
FUNCTION CHECK_PRIVS(p_schema_to_check VARCHAR2,
                     p_privilege VARCHAR2,
                     p_owner VARCHAR2 default NULL,
                     p_object_name VARCHAR2 default NULL) return VARCHAR2
as
  l_count INTEGER;
  l_select_query varchar2(300);
BEGIN
  l_select_query:='select count(*) from (';
  l_select_query:=l_select_query||'select grantee p1, null p2 from';
  if(p_object_name is NOT NULL and p_owner is NOT NULL) then
    l_select_query:=l_select_query||' dba_tab_privs where owner='''||p_owner||'''';
    l_select_query:=l_select_query||' and table_name='''||p_object_name||''' and';
  else
    l_select_query:=l_select_query||' dba_sys_privs where';
  end if;
  l_select_query:=l_select_query||' privilege='''||p_privilege||''' union';
  l_select_query:=l_select_query||' select grantee p1,granted_role p2';
  l_select_query:=l_select_query||' from dba_role_privs)';
  l_select_query:=l_select_query||' where p1 IN (''PUBLIC'','''||p_schema_to_check||''')';
  l_select_query:=l_select_query||' start with p2 is null';
  l_select_query:=l_select_query||' connect by p2 = prior p1';

  execute immediate l_select_query into l_count;

  if(l_count = 0) then
    return 'FALSE';
  end if;
  return 'TRUE';
END CHECK_PRIVS;

-- Bug26875995 Modifed output datatype to clob to handle larger message text

PROCEDURE ADOP_DATABASE_VALIDATIONS(L_MSG out NOCOPY CLOB,
                                    L_MODE in VARCHAR2 default NULL) is
	L_MODULE        varchar2(80) := 'ad.plsql.ad_zd_adop.adop_database_validations';
  L_STATUS         varchar2(30);
  L_COUNT          integer;
  L_APPS_SCHEMA    varchar2(30)   := ad_zd.apps_schema;
  L_APPLSYS_SCHEMA varchar2(30);
  L_EDITION_LIST   varchar2(300)  := '';
  L_CHECK_RESULT   varchar2(10);
  L_CHECK_MESSAGE  varchar2(4000);
  L_SYSTEM_TRIG_VALUE varchar2(10);
  L_SELECT_QUERY   varchar2(1000);
  L_RUN_EDITION    varchar2(30)   := ad_zd.get_edition('RUN');
  L_PATCH_EDITION  varchar2(30)   := '';
  L_PATCH_DATE     date;
  L_DB_DOMAIN       varchar2(128) := sys_context('userenv', 'db_domain');
  L_PATCH_SERVICE   varchar2(255);

  L_BUGFIX_XML_VERSION_DB varchar2(132);
  -- hard coded value of bug fix xml version
  -- which will change with each delta
  L_BUGFIX_XML_VERSION_CUR varchar2(132) := '120.0.12020000.31';
  L_MTCC_XML_VERSION_CUR   varchar2(132) := '120.0.12020000.24';
  L_MTCC_STATE     varchar2(900);
  TYPE rec_type    IS RECORD
  (
    check_result       varchar2(10),
    check_message      varchar2(4000),
    bugfix_xml_version varchar2(20),
    component_name     varchar2(10)
  );
  mtcc_rec        rec_type;
  TXK_COUNT        INTEGER;
  L_TXK_COUNT      varchar2(500);
  TYPE c_mtcc_type IS REF CURSOR;
  MTCC_CURSOR      c_mtcc_type;
  MTCC_COUNT       INTEGER;
	L_STYLESHEET_STMT varchar2(500);
	L_STYLE_SHEETS_LOADED integer;

  cursor DATABASE_NODES is
    select host from fnd_nodes
    where support_db='Y';

  cursor EDITION_LIST(X_EDITION_NAME varchar2) is
        select edition_name
          from dba_editions
          start with parent_edition_name=x_edition_name
          connect by prior edition_name=parent_edition_name
          order by level desc;

BEGIN
  l_mtcc_state := 'select check_result, check_message, bugfix_xml_version, component_name ';
  l_mtcc_state := l_mtcc_state||' from txk_tcc_results where upper(component_name) <> ''RDBMS''';

  l_msg := '';
  /* job_queue_process parameter check */
  select value into l_count
  from v$parameter
  where name='job_queue_processes';

  if (l_count < 2) then
    l_msg:=l_msg||'Parameter ''job_queue_process'' is set to incorrect value: '||l_count||';';
  end if;

  if ad_db_utils.is_adb = 'N' then
    /* Generic Database checks */
    begin
      select count(*) into l_count
        from dba_tab_privs
        where table_name ='DUAL'
        and owner        = 'SYS'
        and grantor      = 'SYS'
        and privilege    <> 'SELECT'
        and  grantee in (select oracle_username oracle_username
                         from    fnd_oracle_userid
                         where   read_only_flag  in ('A', 'B', 'C', 'E', 'S', 'U', 'Z')
                         and     oracle_username in (select username from dba_users));

     if (l_count <> 0) then
       l_msg:=l_msg||'EXCESSIVE PRIVILEGES granted on SYS.DUAL;';
     end if;

   end;

	 /* system_trig_enabled check */
	 begin
	  select value into l_system_trig_value
		from v$parameter
		where name='_system_trig_enabled';

		if (upper(l_system_trig_value) = 'FALSE' ) then
		  l_msg:=l_msg||'Parameter ''_system_trig_enabled'' is set to incorrect value: '||l_system_trig_value||';';
		end if;
	 exception
	 when no_data_found then
	   null;
	 end;
  end if;

  /* Generic Database checks */

  /* Administer database trigger checks */

  /* Bug21389740 removed the check for
     EXEMPT ACCESS POLICY privilege granted to SYSTEM schema
  */

  if(check_privs(l_apps_schema,'EXEMPT ACCESS POLICY')='TRUE') then
    l_msg:=l_msg||'EXEMPT ACCESS POLICY privilege granted to APPS schema;';
  end if;

	if ad_db_utils.is_adb = 'N' then
	  l_stylesheet_stmt := 'BEGIN  :1 := sys.diutil.bool_to_int( sys.dbms_metadata_util.are_stylesheets_loaded); END;';
		execute immediate l_stylesheet_stmt using out l_style_sheets_loaded;

		if (l_style_sheets_loaded=0) then
			l_msg:=l_msg||'Metadata stylesheets are not loaded in database;';
		end if;
	else
	  log(l_module, 'STATEMENT', 'This is ADB-D instance,action pending on how to invoke sys.dbms_metadata_util.are_stylesheets_loaded api ');
  end if;

  /* Database edition related checks */
  /* Check 1: Run edition should have 0 or 1 child */
  begin
    l_patch_edition := ad_zd.get_edition('PATCH');
  exception
    when TOO_MANY_ROWS then
      /* This scneario is not currently possible in database. We have
         added it just to be on the safer side per George's suggestion in bug 20384399*/
      l_msg:=l_msg||'Current run edition '||l_run_edition||' has more than one child edition;';
  end;

  /* Perform couple more checks if patch edition exists */
  if(l_patch_edition is NOT NULL)
  then
    /* Check 2 : Patch edition should not have child editions */
    for edition in edition_list(l_patch_edition) loop
      l_edition_list:=l_edition_list||edition.edition_name||',';
    end loop;

    if(l_edition_list is NOT NULL)
    then
      l_edition_list := regexp_replace(l_edition_list,',$','');
      l_msg:=l_msg||'Unexpected child edition ('||l_edition_list||
                    ') of patch edition exists in database;';
    end if;

    /* Check 3 : Check if patch edition has name in proper format */
    --name should sort
    if(l_patch_edition <= l_run_edition) then
      l_msg:=l_msg||'Patch edition ('||l_patch_edition||') does not match the expected edition name;';
    --name should be in proper alphanumeric format
    elsif (not regexp_like(l_patch_edition, '^V_\d{8}_\d{4}$'))  then
      l_msg:=l_msg||'Patch edition ('||l_patch_edition||') does not match the expected alphanumeric format;';
    --name should translate to a proper timestamp
    else
      begin
        l_patch_date:=to_date(substr(l_patch_edition,3),'YYYYMMDD_HH24MI');
      exception
        when others then
          l_msg:=l_msg||'Patch edition ('||l_patch_edition||') does not match the expected timestamp format;';
        end;
    end if;
  end if;

	/* EBS_LOGON related checks */
		begin
			select status into l_status
			from dba_triggers
			where owner='EBS_SYSTEM' and trigger_name='EBS_LOGON';

			if(l_status<>'ENABLED') then
				l_msg:=l_msg||'Trigger EBS_LOGON is disabled;';
			end if;
		exception
			when no_data_found then
				l_msg:=l_msg||'Trigger EBS_LOGON does not exist;';
		end;


	--Checking if adb or not
  if ad_db_utils.is_adb = 'N' then

		log(l_module, 'STATEMENT', 'This is non ADB-D instance,Check and create patch service');
		-- Check and create patch service {"ebs_patch" | "<db-name>_ebs_patch"}
		begin
			ad_db_utils.create_patch_service;
		exception
			when others then
				l_msg:=l_msg||'Patch service ' ||l_patch_service ||' is not exist or running;';
		end;
	else
	  log(l_module, 'STATEMENT', 'This is ADB-D instance,validation not required w.r.t patch service.');
	end if;

  --Checking if adb or not
  --Bug 33122201 - ADB-D :: ADOP DEPENDENCY ON ETCC TO BE RUN FOR ADB ENVIRONMENTS
  --Skipping the ETCC check for ADB
  --Until we get fix for Bug 32897384 - ETCC SUPPORT FOR ADB-D
  if ad_db_utils.is_adb = 'N' then
	 	log(l_module, 'STATEMENT', 'This is non ADB-D instance,Performing ETCC checks');
	/* ETCC checks */
    select distinct oracle_username into l_applsys_schema
      from ebs_system.fnd_oracle_userid
      where read_only_flag = 'E';

    l_txk_count := 'select count(table_name) from all_tables ' ||
                   'where table_name=''TXK_TCC_RESULTS'' and OWNER=''' ||
                   l_applsys_schema || ''' ' ;
    execute immediate l_txk_count into txk_count;
    if( txk_count = 0 ) then
      l_msg:=l_msg||'ETCC: The table '||l_applsys_schema||'.TXK_TCC_RESULTS does not exist;';
    else
      for node in database_nodes loop
        BEGIN
          l_select_query := 'select check_result, check_message, bugfix_xml_version';
          l_select_query := l_select_query||' from '||l_applsys_schema||'.TXK_TCC_RESULTS';
          l_select_query := l_select_query||' where UPPER(node_name)='''||UPPER(node.host)||'''';
          l_select_query := l_select_query||' AND UPPER(component_name) =''RDBMS''';
          execute immediate l_select_query into l_check_result, l_check_message, l_bugfix_xml_version_db;
          -- BUGFIX_XML_VERSION is less than current version
          if not ad_patch.compare_versions(l_bugfix_xml_version_cur, l_bugfix_xml_version_db)
          then
            l_msg:=l_msg||'BUGFIX_XML_VERSION,'||node.host||',';
            l_msg:=l_msg||l_bugfix_xml_version_cur||',';
            l_msg:=l_msg||l_bugfix_xml_version_db||';';
          end if;
          if (l_check_result='MISSING') then
            l_msg:=l_msg||'ETCC: The following required database fixes have not been applied';
            l_msg:=l_msg||' to node '||node.host||': -('||l_check_message||');';
          elsif (l_check_result='ROLLBACK') then
            l_msg:=l_msg||'ETCC: The following database fixes should be rolled back';
            l_msg:=l_msg||' in node '||node.host||' -('||l_check_message||');';
          end if;
        exception
          when no_data_found then
            l_msg:=l_msg||'ETCC not run in the database node '||node.host||';';
        END;
      end loop;
    end if;
  end if;

  /* Middle Tier Compliance Checker - bug 21162951 */
  if( txk_count > 0 ) then
    l_select_query := 'select count(*) from '||l_applsys_schema||'.TXK_TCC_RESULTS WHERE upper(component_name) <> ''RDBMS''';
    execute immediate l_select_query INTO mtcc_count;
    if(mtcc_count < 1 ) then
      l_msg:=l_msg||'MTCC not ran;';
    end if;
    open mtcc_cursor for l_mtcc_state;
    loop
      fetch mtcc_cursor into mtcc_rec;
      exit when mtcc_cursor%NOTFOUND;
      BEGIN
        if not ad_patch.compare_versions(l_mtcc_xml_version_cur, mtcc_rec.bugfix_xml_version)
        then
          l_msg:=l_msg||'MTCC_XML_VERSION,'||l_mtcc_xml_version_cur||','||mtcc_rec.bugfix_xml_version||','||mtcc_rec.component_name||';';
        end if;
        if( mtcc_rec.check_result='MISSING') then
          l_msg:=l_msg||'MTCC: The following middle tier fixes have not been applied: '||mtcc_rec.check_message;
          l_msg:=l_msg||' for component:'||mtcc_rec.component_name||';';
        end if;
      END;
    end loop;
    close mtcc_cursor;
  end if;

  l_msg := regexp_replace(l_msg,';$','');
END ADOP_DATABASE_VALIDATIONS;

PROCEDURE UPDATE_SESSIONS_TABLE (p_node_name IN VARCHAR2,
                                 p_status IN VARCHAR2 default 'F')
IS
BEGIN
update ad_adop_sessions set status=p_status
where adop_session_id=(select max(adop_session_id) from ad_adop_sessions)
  and node_name=p_node_name
  and status='R';
END UPDATE_SESSIONS_TABLE;

FUNCTION GET_APPLTOP_ID(p_node_name VARCHAR2) return NUMBER
IS
l_appltop_id NUMBER;
BEGIN
   SELECT aat.appl_top_id into l_appltop_id
   FROM
   FND_OAM_CONTEXT_FILES focf,
   fnd_product_groups fpg,
   ad_appl_tops aat,
   ad_releases ar
   WHERE focf.NAME not in ('TEMPLATE','METADATA','config.txt') and focf.CTX_TYPE='A' and
   (focf.status is null or upper(focf.status) in ('S','F')) and
   EXTRACTVALUE(XMLType(focf.TEXT),'//file_edition_type') = 'run' and
   upper(focf.node_name)=upper(p_node_name) and
   aat.appl_top_type='R' and
   aat.applications_system_name=fpg.applications_system_name and
   aat.active_flag='Y' and
   fpg.release_name=ar.major_version||'.'||ar.minor_version||'.'||ar.tape_version and
   fpg.aru_release_name=ar.aru_release_name and
   aat.name=EXTRACTVALUE(XMLType(focf.TEXT),'//APPL_TOP_NAME');

   return l_appltop_id;
EXCEPTION
  when no_data_found then
    RAISE_APPLICATION_ERROR(-20001,'Could not get appltop id for node '||p_node_name);
END GET_APPLTOP_ID;



PROCEDURE INSERT_ADD_NODE_RECORDS
IS
  l_appl_top_id number;
  l_node_list VARCHAR2(32767) := NULL;
  l_av_appl_top_id number;
  l_admin_atid number;
  l_shared number;
  l_super_node varchar2(256);
  l_admin_node varchar2(256);
  l_prepare_status varchar2(1);
  l_apply_status varchar2(1);
  l_session_id number;
  l_count number :=0;
  l_stmt varchar2(3000);
  l_avail_node_flag boolean := FALSE;
  no_admin_node    exception;
  pragma exception_init(no_admin_node,-20001);
  multiple_admin_nodes    exception;
  pragma exception_init(multiple_admin_nodes,-20002);
  cursor new_nodes is
        select node_name
          from adop_valid_nodes
         where node_name not in (select node_name from ad_adop_sessions
                                  where adop_session_id = (select max(adop_session_id) from
                                                           ad_adop_sessions));

  cursor available_nodes is
        select node_name from ad_adop_sessions
         where adop_session_id = (select max(adop_session_id) from
                                  ad_adop_sessions)
           and node_name in (select node_name from
                             adop_valid_nodes)
         order by node_name;

 cursor admin_nodes is
    SELECT node_name
      FROM   FND_OAM_CONTEXT_FILES
      WHERE  NAME not in ('TEMPLATE','METADATA','config.txt')
      AND    CTX_TYPE='A' and (status is null or upper(status) in ('S','F'))
      AND    EXTRACTVALUE(XMLType(TEXT),'//file_edition_type') = 'run'
      AND    EXTRACTVALUE(XMLType(TEXT),'//oa_service_group_status[@oa_var=''s_web_admin_status'']')='enabled'
      AND    EXTRACTVALUE(XMLType(TEXT),'//oa_service_list/oa_service[@type=''admin_server'']/oa_service_status')='enabled';
  BEGIN
    select max(adop_session_id) into l_session_id from ad_adop_sessions;

    --get admin node
    for rec in admin_nodes loop
      if l_node_list is NULL then
        l_node_list := rec.node_name;
        l_count := l_count +1;
      else
        l_node_list := l_node_list || ',' || rec.node_name;
        l_count := l_count +1;
      end if;
    end loop;

    if ( l_count = 0 ) then
       raise  no_admin_node;
    elsif ( l_count > 1 ) then
       raise multiple_admin_nodes;
    else
      l_admin_node := l_node_list;
      l_admin_atid:=get_appltop_id(l_admin_node);
    end if;

    --loop through the new added nodes
    for hostname in new_nodes loop
      l_shared:=0;
      l_super_node:=l_admin_node;

      --get appltop_id for new node
      l_appl_top_id:=get_appltop_id(hostname.node_name);

      if(l_appl_top_id = l_admin_atid) then
          l_shared := 1;
          l_super_node := l_admin_node;
      end if;
      --avaialable node cursor
      for av_node_name in available_nodes loop
        l_avail_node_flag :=TRUE;
        if(l_shared = 1) then
          exit;
        end if;
        l_av_appl_top_id:=get_appltop_id(av_node_name.node_name);

        if (l_appl_top_id = l_av_appl_top_id) then
          l_shared := 1;
          l_super_node := av_node_name.node_name;
        end if;
      end loop;

      if ( NOT l_avail_node_flag )
      then
        return;
      end if;

      -- bug26323604 modified the insert to avoid duplicates by comparing against entries that already
      -- exist for the same bug number and appltop_id.

      --insert the non sync row to patches table
      --bug 21058226: added a space at the end of each string to allow for proper spacing when the statement is
      --concatenated together.

      l_stmt := 'insert into ad_adop_session_patches (adop_session_id, bug_number, patchrun_id, status, ' ||
        'applied_file_system_base, patch_file_system_base,adpatch_options, appltop_id, node_name, ' ||
        'autoconfig_status, start_date, end_date, patch_top, driver_file_name, session_type) ' ||
        '(select adop_session_id, bug_number, patchrun_id, status, applied_file_system_base, ' ||
        'patch_file_system_base, adpatch_options, '||l_appl_top_id||', ''' || hostname.node_name ||''', '||
        'autoconfig_status, start_date, end_date, patch_top, driver_file_name, session_type ' ||
        'from ad_adop_session_patches ' ||
        'where node_name='''||l_super_node||''' and ' ||
        '(bug_number in (''CLONE'',''CONFIG_CLONE'') and status = ''N'') ' ||
        'or (patch_file_system_base is NULL and '||
        'bug_number not in (select bug_number from ad_adop_session_patches  ' ||
        'where node_name = '''||hostname.node_name||''' and appltop_id = '''||l_appl_top_id||''')))';

      EXECUTE IMMEDIATE l_stmt;

      if(l_shared = 1) then
        --bug 21058226: added a space at the end of each string to allow for proper spacing when the statement is
        --concatenated together.
        l_stmt := 'update ad_adop_session_patches set bug_number=''CONFIG_CLONE''' ||
        ' where node_name =''' || hostname.node_name||''' and status = ''N'' and bug_number = ''CLONE''';
        EXECUTE IMMEDIATE l_stmt;
      end if;

      --Bug 21518115 - Catching the NO_DATA_FOUND exception
      BEGIN
        select prepare_status,apply_status into l_prepare_status,l_apply_status
        from ad_adop_sessions
        where upper(node_name) = upper(l_admin_node) and adop_session_id = l_session_id;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          return;
      END;

      --during active hotpatch session, sessions table should be updated with adop data
      if (upper(l_prepare_status) = 'X' and upper(l_apply_status) = 'P') then

        --bug 21058226: added a space at the end of each string to allow for proper spacing when the statement is
        --concatenated together.
        l_stmt := 'insert into ad_adop_sessions (adop_session_id, prepare_status, apply_status, finalize_status, '||
        'cutover_status, cleanup_status, abort_status,status, node_name, node_type, appltop_id, edition_name, pid, '||
        'abandon_flag, session_input_data, prepare_start_date, prepare_end_date, finalize_start_date, '||
        'finalize_end_date, apply_start_date, apply_end_date, cutover_start_date, cutover_end_date, '||
        'cleanup_start_date, cleanup_end_date, abort_start_date, abort_end_date) '||
        '(select adop_session_id, prepare_status, apply_status, finalize_status, cutover_status, '||
        'cleanup_status, abort_status,status,'''||hostname.node_name|| ''',''slave'','|| l_appl_top_id||', '||
        'edition_name, pid, abandon_flag, session_input_data, prepare_start_date, prepare_end_date, '||
        'finalize_start_date, finalize_end_date, apply_start_date, apply_end_date, cutover_start_date, '||
        'cutover_end_date, cleanup_start_date, cleanup_end_date, abort_start_date, abort_end_date '||
        'from ad_adop_sessions '||
        'where adop_session_id = '||l_session_id||' and upper(node_name) = upper('''||l_super_node||'''))';

        EXECUTE IMMEDIATE l_stmt;
      end if;
      commit;
    end loop;
EXCEPTION
    when no_admin_node then
      RAISE_APPLICATION_ERROR(-20010,'No admin node found. Review and correct your configuration,
                               contacting Oracle Support as needed.');
    when  multiple_admin_nodes then
       RAISE_APPLICATION_ERROR(-20010,'More than one admin node found: '|| l_node_list
                               ||'. Review and correct your configuration, contacting Oracle Support as needed.');
    when others then
        RAISE_APPLICATION_ERROR(-20010,SQLERRM);
END INSERT_ADD_NODE_RECORDS;

/* This API accepts node name and returns a number
THe meaning of various return values are
 1 - Admin Node
 2 - Non-Shared master node
 3 - Admin Shared slave node
 4 - Shared slave node
*/
FUNCTION GET_NODE_TYPE(p_node_name VARCHAR2) return NUMBER
IS
  l_node_type number;
BEGIN
  SELECT node_type into l_node_type
  FROM
  (SELECT avn.node_name,
     DECODE(EXTRACTVALUE(XMLType(focf.text),'//APPL_TOP_NAME'),
            admin_node.appl_top, DECODE(avn.node_name,admin_node.node_name, 1,3),
            DECODE(ROW_NUMBER() OVER (PARTITION BY EXTRACTVALUE(XMLType(focf.text),'//APPL_TOP_NAME')
                                      ORDER BY avn.node_name),
                  1,2,4)) node_type
  FROM
     fnd_oam_context_files focf,
     adop_valid_nodes avn,
     (SELECT node_name,
             EXTRACTVALUE(XMLType(text),'//APPL_TOP_NAME') appl_top
      FROM fnd_oam_context_files
      WHERE name NOT IN ('TEMPLATE','METADATA','config.txt')
        AND CTX_TYPE='A'
        AND (status IS NULL or UPPER(status) IN ('S','F'))
        AND EXTRACTVALUE(XMLType(text),'//file_edition_type') = 'run'
        AND EXTRACTVALUE(XMLType(text),'//oa_service_group_status[@oa_var=''s_web_admin_status'']')='enabled'
        AND EXTRACTVALUE(XMLType(text),'//oa_service_list/oa_service[@type=''admin_server'']/oa_service_status')='enabled') admin_node
  WHERE focf.name not IN ('TEMPLATE','METADATA','config.txt')
    AND focf.CTX_TYPE='A'
    AND (focf.status is null
         or upper(focf.status) IN ('S','F'))
    AND EXTRACTVALUE(XMLType(focf.text),'//file_edition_type') = 'run'
    AND upper(focf.node_name)=upper(avn.node_name))
   WHERE upper(node_name)=upper(p_node_name);
  return l_node_type;
EXCEPTION
  when no_data_found then
    RAISE_APPLICATION_ERROR(-20001,'Node name '||p_node_name||' not found in adop repository tables');
END GET_NODE_TYPE;


/*
Returns nodes which is considered master node by adop for every appltop
in the configuration
*/
FUNCTION GET_MASTER_NODES RETURN VARCHAR2
IS
  l_node_list varchar2(32767) := NULL;
  l_node_type number;
  CURSOR node_list IS
    select node_name
    from adop_valid_nodes;
BEGIN
  for node in node_list
  loop
    l_node_type:=get_node_type(node.node_name);
    if(l_node_type = 1 or l_node_type = 2)
    then
      l_node_list := add_to_list(l_node_list,node.node_name);
    end if;
  end loop;
  return l_node_list;
END GET_MASTER_NODES;

/*
FOr a given node find the slave nodes with same appltop
*/
FUNCTION GET_SLAVE_NODES(p_node_name VARCHAR2) return VARCHAR2
IS
  l_node_list         varchar2(32767) := NULL;
  l_master_appltop_id number;
  l_appltop_id        number;
  l_node_type number;
  CURSOR node_list IS
    select node_name
    from adop_valid_nodes;
BEGIN
  l_node_type := get_node_type(p_node_name);
  if(l_node_type = 1 or l_node_type = 2)
  then
    l_master_appltop_id:=get_appltop_id(p_node_name);
    for node in node_list
    loop
      if(upper(p_node_name) = upper(node.node_name))
      then
        continue;
      end if;
      l_appltop_id:=get_appltop_id(node.node_name);
      if(l_master_appltop_id = l_appltop_id)
      then
        l_node_list := add_to_list(l_node_list,node.node_name);
      end if;
    end loop;
    return l_node_list;
  else
    RAISE_APPLICATION_ERROR(-20002,'Node '||p_node_name||' is not a master node');
  end if;
END GET_SLAVE_NODES;

/*
List master nodes which have slaves sharing same appltop
*/
FUNCTION GET_NODES_WITH_SLAVES RETURN VARCHAR2
IS
  l_master_nodes   VARCHAR2(32767);
  l_no_of_masters  NUMBER;
  l_start_position NUMBER;
  l_end_position   NUMBER;
  l_node_list      VARCHAR2(32767);
  l_master_name    VARCHAR2(256);
BEGIN
  l_master_nodes:=get_master_nodes;
  if(l_master_nodes is NULL)
  then
    return NULL;
  end if;
  l_no_of_masters:=REGEXP_COUNT(l_master_nodes,',')+1;
  l_start_position:=1;
  for i in 1..l_no_of_masters
  loop
    l_end_position:=instr(l_master_nodes,',',l_start_position+1)-1;
    if(l_end_position = -1)
    then
      l_end_position:=length(l_master_nodes);
    end if;
    l_master_name:=substr(l_master_nodes,l_start_position,
                          l_end_position-l_start_position+1);
    if( get_slave_nodes(l_master_name) is NOT NULL)
    then
      l_node_list:=add_to_list(l_node_list,l_master_name);
    end if;
    l_start_position:=l_end_position+2;
  end loop;
  return l_node_list;
END GET_NODES_WITH_SLAVES;

------------------------------------------------------------------------------
-- RESET_ADOP_SESSION_METADATA Procedure
--   This procedure truncates the ADOP repository tables (AD_ADOP_SESSION and
--   AD_ADOP_SESSION_PATCHES) and conditionally reset ad_adop_session_id_seq
--   sequence to 0.
--   It takes one boolean (true/false) arguments -
--     1. p_reset_seq:  If TRUE, it will reset ad_adop_session_id_seq to 0
------------------------------------------------------------------------------
PROCEDURE RESET_ADOP_SESSION_METADATA(p_reset_seq  IN BOOLEAN default FALSE)
IS
  l_val number;
  l_schema_name varchar2(30);
  l_seq_name varchar2(30);
BEGIN

  -- Deleting all the rows from ad_adop_sessions and ad_adop_session_patches tables
  delete from ad_adop_sessions;
  delete from ad_adop_session_patches;
  commit;

  -- Fetching schema name and actual seq name by using synonym in APPS schema
  select table_owner, table_name into l_schema_name, l_seq_name
  from dba_synonyms
  where synonym_name = 'AD_ADOP_SESSION_ID_SEQ'
        and owner = AD_ZD.APPS_SCHEMA;

  -- Resetting ad_adop_session_id_seq sequence to 0
  if p_reset_seq then
    execute immediate 'select ' || l_schema_name || '.' || l_seq_name ||'.nextval from dual' INTO l_val;
    execute immediate 'alter sequence ' || l_schema_name ||'.'|| l_seq_name ||' increment by -' || l_val || ' minvalue 0';
    execute immediate 'select ' || l_schema_name || '.' || l_seq_name ||'.nextval from dual' INTO l_val;
    execute immediate 'alter sequence ' || l_schema_name ||'.'|| l_seq_name ||' increment by 1 minvalue 0';
    commit;
  end if;

END RESET_ADOP_SESSION_METADATA;

---------------------------------------------------------------------------------
-- GET_FAILED_PATCHES Function (Bug 22334672)
-- The purpose of this function is to return the list of patches for a node,
-- which has been failed or skipped in the last patching cycle.
--   Input Parameter: NODE_NAME  VARCHAR2
--                    SESSION_ID NUMBER
--   Return Value: PATCH1#STATUS1,PATCH2#STATUS2,PATCH3#STATUS3,
---------------------------------------------------------------------------------
FUNCTION GET_FAILED_PATCHES(p_node_name IN varchar2, p_session_id IN number) return varchar2
IS
  l_node_patches_list VARCHAR2(32767) := NULL;
  cursor bug_list is
      select bug_number, status
      from ad_adop_session_patches
      where status not in ('N', 'Y')
      and adop_session_id = p_session_id
      and node_name = p_node_name
      and bug_number not in ('CLONE', 'CONFIG_CLONE')
      and bug_number not like 'ADADMIN%'
      and bug_number not like 'ADSPLICE%';
BEGIN

  -- Making the list of failed patches along with their status values
  for rec in bug_list loop
    l_node_patches_list := l_node_patches_list || rec.bug_number || '#' || rec.status || ',';
  end loop;

  -- Returning the list to caller
  return l_node_patches_list;

END GET_FAILED_PATCHES;

---------------------------------------------------------------------------------
-- This function will have session_id as input
  -- If no session id is given it will return maximum session_id either
  -- from sessions table or patches table

  -- Appends session_id with 0 if it is from sessions table and 1 if it is
  -- from patches table
---------------------------------------------------------------------------------
FUNCTION VALIDATE_SESSION_ID(session_id  number) RETURN NUMBER
IS
  l_session_id         number;
  l_session_id_patches number;
  l_bug_number         varchar2(30);
  g_clone_at_next_s    number :=0;
  report_session_id    number :=0;
BEGIN
  if( session_id is null  ) then
    begin
      select max(adop_session_id) into l_session_id from ad_adop_sessions;
    exception
      when others then
      return -1;
    end;

    select adop_session_id into l_session_id_patches from ad_adop_session_patches
      where
      adop_session_id = (select max(adop_session_id) from ad_adop_session_patches)
      and bug_number in ('CLONE','CONFIG_CLONE') and rownum = 1;

    if (l_session_id_patches > l_session_id) then
      g_clone_at_next_s := 1;
      report_session_id := l_session_id_patches;
    elsif (l_session_id_patches = l_session_id) then
      report_session_id := l_session_id_patches;
    else
      report_session_id := l_session_id;
    end if;
  else
    begin
      select bug_number into l_bug_number
        from (select ap.bug_number from ad_adop_session_patches ap
      where ap.adop_session_id =  session_id
      and not exists ( select ad.adop_session_id
                       from ad_adop_sessions ad
                       where ad.adop_session_id = session_id )) where rownum=1;

      if(l_bug_number = 'CLONE' or l_bug_number = 'CONFIG_CLONE') then
        g_clone_at_next_s := 1;
      else
        g_clone_at_next_s := 0;
      end if;
    exception
      when others then
      g_clone_at_next_s := 0;
    end;
    report_session_id := session_id;
  end if;
  return (report_session_id || g_clone_at_next_s);
exception
  when others then
   report_session_id := l_session_id;
   return (report_session_id || g_clone_at_next_s);

end VALIDATE_SESSION_ID;

PROCEDURE UPDATE_SESSION_STATUS_FAILED(session_id NUMBER)
IS
l_mod_name varchar2(30) := 'UPDATE_SESSION_STATUS_FAILED';
BEGIN
  update ad_adop_sessions set status='F' where adop_session_id=session_id;
EXCEPTION
  when others then
    log(l_mod_name, 'ERROR', 'ERROR: '||SQLERRM);
    RAISE_APPLICATION_ERROR(-20010,SQLERRM);
END UPDATE_SESSION_STATUS_FAILED;

function is_clone_record_exist(p_adop_session_id in number,
                               p_action in varchar2,
                               p_appl_top_id in number,
                               p_hostname in varchar2,
                               p_runbase in varchar2)
return number
is
  l_exist number := 0;
  l_old_adop_session_id number;
begin
  SELECT nvl(MAX(adop_session_id), 2) adop_session_id into l_old_adop_session_id
  FROM   ad_adop_sessions sess
  WHERE  adop_session_id<p_adop_session_id
  AND    apply_status='Y'
  AND    status='C'
  AND    abort_status='X'
  AND    cutover_status='Y'
  AND    node_type='master';

  if (l_old_adop_session_id is not null)
  then
      select count(1) into l_exist
      from   ad_adop_session_patches
      where  adop_session_id>=l_old_adop_session_id
      and    adop_session_id<=p_adop_session_id
      and    bug_number in (p_action)
      and    status not in ('X')
      and    applied_file_system_base=p_runbase
      and    appltop_id=p_appl_top_id and node_name=p_hostname;
  end if;
  return l_exist;
end is_clone_record_exist;

function is_codelevel_bumped(p_adop_session_id in number,
                              p_ad   in varchar2,
                              p_txk  in varchar2)
return number
is

  l_mod_name varchar2(30) := 'is_codelevel_bumped';
  -- C.9
  l_baseline varchar2(3) := 'C';
  l_codelevel varchar2(10) := '9';
  l_bumped number := 0;
  l_old_adop_session_id number;
  l_result1 boolean;
  l_result2 boolean;

  l_old_ad_codelevel varchar2(50);
  l_new_ad_codelevel varchar2(50);
  l_old_txk_codelevel varchar2(50);
  l_new_txk_codelevel varchar2(50);

  l_old_ad_baseline varchar2(50);
  l_new_ad_baseline varchar2(50);
  l_old_txk_baseline varchar2(50);
  l_new_txk_baseline varchar2(50);
begin
  SELECT nvl(MAX(adop_session_id), 2) adop_session_id into l_old_adop_session_id
  FROM   ad_adop_sessions sess
  WHERE  adop_session_id<p_adop_session_id
  AND    apply_status='Y'
  AND    status='C'
  AND    abort_status='X'
  AND    cutover_status='Y'
  AND    node_type='master';

  if (l_old_adop_session_id is not null)
  then
    l_new_ad_codelevel  := get_max_codelevel(p_ad,  p_adop_session_id,     l_new_ad_baseline);
    l_old_ad_codelevel  := get_max_codelevel(p_ad,  l_old_adop_session_id, l_old_ad_baseline);
    l_new_txk_codelevel := get_max_codelevel(p_txk, p_adop_session_id,     l_new_txk_baseline);
    l_old_txk_codelevel := get_max_codelevel(p_txk, l_old_adop_session_id, l_old_txk_baseline);

    --Bug 34057411:PREPARE IS NOT DETECTING AD-TXK LEVEL CHANGE
    --Resetting the default values for baseline and codelevel
    --based on the old ad code level.
    begin
      if((l_old_ad_baseline = l_baseline) and
         (to_number(l_old_ad_codelevel) > to_number(l_codelevel))) then
        l_baseline  :=l_old_ad_baseline;
        l_codelevel :=l_old_ad_codelevel;
      end if;
     exception
      when others then
        log(l_mod_name, 'ERROR', 'ERROR: '||sqlerrm);
        raise_application_error(-20010,sqlerrm);
    end;


    if ((l_new_ad_baseline||'.'||l_new_ad_codelevel = l_baseline||'.'||l_codelevel
        and l_new_ad_baseline||'.'||l_new_ad_codelevel <> l_old_ad_baseline||'.'||l_old_ad_codelevel) or
       (l_new_txk_baseline||'.'||l_new_txk_codelevel = l_baseline||'.'||l_codelevel
        and l_new_txk_baseline||'.'||l_new_txk_codelevel <> l_old_txk_baseline||'.'||l_old_txk_codelevel)) then
      l_bumped := 1;
    elsif (l_old_ad_baseline<>l_baseline or
        l_old_ad_baseline<>l_new_ad_baseline or
        l_old_txk_baseline<>l_baseline or
        l_old_txk_baseline<>l_new_txk_baseline) then
      l_bumped := 0;
    else
      -- ad
      l_result1 := ad_patch.compare_versions(l_old_ad_codelevel, l_codelevel);
      l_result2 := ad_patch.compare_versions(l_codelevel, l_new_ad_codelevel);
      if(l_result1 = true and l_old_ad_codelevel<>l_new_ad_codelevel and l_result2 = true) then
        l_bumped := 1;
      else
        -- txk
        l_result1 := ad_patch.compare_versions(l_old_txk_codelevel, l_codelevel);
        l_result2 := ad_patch.compare_versions(l_codelevel, l_new_txk_codelevel);
        if(l_result1 = true and l_old_txk_codelevel<> l_new_txk_codelevel and l_result2 = true) then
          l_bumped := 1;
        end if;
      end if;
    end if;
  end if;
  return l_bumped;
end is_codelevel_bumped;

END AD_ZD_ADOP;
