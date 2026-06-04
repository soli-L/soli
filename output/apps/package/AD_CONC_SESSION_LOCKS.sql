
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_CONC_SESSION_LOCKS" AUTHID CURRENT_USER as
/* $Header: adcslcks.pls 115.2 2004/02/05 15:17:06 pzanwar ship $ */
--
-- Procedure
--   get_admin_lock
--
-- Purpose
--   Lock the DB admin objects used in ad_concurrent_sessions
-- Usage
--
--
--
procedure get_admin_lock(status out nocopy number);


--
-- Procedure
--   get_admin_lock
--
-- Purpose
--   Lock the DB admin objects used in ad_concurrent_sessions with timeout
-- Usage
--
--
--
procedure get_admin_lock_with_timeout(status out nocopy number,
                                      timeout_period in integer);
--
--
--
--
-- Procedure
--   release_admin_lock
--
-- Purpose
--   Release the DB admin objects used in ad_concurrent_sessions
-- Usage
--
--
--
procedure release_admin_lock(status out nocopy number);

--
--
--
procedure  reset_session_info(sess_id in number,
                              process_id number ,
                              appltop_path in varchar2,
                              node_name in varchar2,
                              inactive_flag out nocopy varchar2,
                              p_invokdir in varchar2);
--
--
--
procedure  set_session_info(sess_id    in number  ,process_id    in number,
                            utility_nm in varchar2,appltop_id    in number,
                            priority_value in number,osuser_name in varchar2,
                            invokedir in varchar2, appltop_path in varchar2,
                            node_name in varchar2, p_topdir in varchar2);
--
--
procedure  deactivate_session_row(sess_id in number,
                                  get_lock_with_timeout in number,
                                  row_count out nocopy number);
--
--


type conflict_sessions_t is table of number index by binary_integer;


-- Procedure
--     check_compatibility_with_fifo
-- Arguments
--     1) session_id
--     2) x_conflict_session_ids - Out parameter
--                                 List of conflict session ids.
--     3) error_code             - Out parameter
--            0                  --> Success
--            BASE_ERROR + 1     --> Invalid Argument
--            BASE_ERROR + 2     --> Unhandled exception
-- Purpose
--     This procedures does compatibility checks in DB. It checks set
--     of locks requested can be acquired (together) or not. It also
--     forces FIFO algorithm amoung same priority sessions
-- Notes

procedure check_compatibility_with_fifo (session_id in number,
                                         x_conflict_session_ids out
                                         nocopy conflict_sessions_t,
                                         error_code out nocopy number);

-- Procedure
--     check_compatibility
-- Arguments
--     1) session_id
--     2) x_conflict_session_ids - Out parameter
--                                 List of conflict session ids.
--     3) error_code             - Out parameter
--            0                  --> Success
--            BASE_ERROR + 1     --> Invalid Argument
--            BASE_ERROR + 2     --> Unhandled exception
-- Purpose
--     This procedures does compatibility checks in DB. It checks set
--     of locks requested can be acquired (together) or not.
-- Notes

procedure check_compatibility  (session_id in number,
                                x_conflict_session_ids out
                                nocopy conflict_sessions_t,
                                error_code out nocopy number);

-- Procedure
--     do_deadlock_detection
-- Arguments
--     1) root_session_id
--     2) error_code          -   Out parameter
--             0              --> Success
--             BASE_ERROR + 1 --> Deadlock detected, abort (caller is
--                                the least priority process in the list
--                                of process that caused the deadlock)
--             BASE_ERROR + 2 --> Deadlock detected, continue (caller is
--                                not the least priority process)
--             BASE_ERROR + 3 --> No conflicting sessions found for root
--                                session id.
--             BASE_ERROR + 4 --> Invalid Argument
--             BASE_ERROR + 5 --> check_compatibility  failed
--             BASE_ERROR + 6 --> Reading ad_sessions failed
--             BASE_ERROR + 7 --> Unhandled exception
--             BASE_ERROR + 8 --> Logic error,tree nodes are not proper
-- Purpose
--     Deadlocks are detected in this procedure. See the various return
--     values (above) for exact functionality.
-- Notes

procedure do_deadlock_detection(root_session_id in number,
                                error_code out nocopy number);

-- Procedure
--     acquire_promote_db_locks
-- Arguments
--     1) session_id
--     2) stage_code
--     3) acquire_admin_flag  -   If this flag is set to 1,ADMIN lock is
--                                acquired at the beginning.
--                                Otherwise, it is assumed that caller
--                                has already acquired the lock.
--     4) release_admin_flag  -   If this flag is set to 1,ADMIN lock is
--                                released at the end.
--                                Otherwise, it is assumed that caller
--                                will release the lock later. (this
--                                procedure retains ADMIN lock, only if
--                                the return status is success)
--     5) error_code          -   Out parameter
--            0               --> Success
--            BASE_ERROR + 1  --> This stage is already done.
--            BASE_ERROR + 2  --> Deadlock detected, abort (caller is
--                                the least priority process in the list
--                                of processes that caused the deadlock)
--            BASE_ERROR + 3  --> Invalid argument.
--            BASE_ERROR + 4  --> Lock rows are not prestaged.
--            BASE_ERROR + 5  --> Inconsistency state (some of the lock
--                                rows have done_flag='Y' and others
--                                have done_flag='N')
--                                It shouldn't happen.
--            BASE_ERROR + 6  --> Exception,reading ad_planned_res_lock
--            BASE_ERROR + 7  --> Exception, reading ad_sessions.
--            BASE_ERROR + 8  --> Exception, inserting row in
--                                ad_working_res_locks.
--            BASE_ERROR + 9  --> Exception updating ad_sessions.
--            BASE_ERROR + 10 --> Error, do_compatibility check failed
--            BASE_ERROR + 11 --> Stage_code = 'ACQUIRE_HELD' and
--                                compatibility check -> incompatibility
--            BASE_ERROR + 12 --> Exception, updating ad_sessions,
--                                ad_working_res_locks
--            BASE_ERROR + 13 --> Exception, reading ad_sessions
--            BASE_ERROR + 14 --> Adctrl says to quit
--            BASE_ERROR + 15 --> Exception, updating ad_sessions,
--                                ad_working_res_locks
--            BASE_ERROR + 16 --> Error calling do_deadlock_detection.
--            BASE_ERROR + 17 --> Exception, updating ad_sessions.
--            BASE_ERROR + 18 --> Exception, updating ad_sessions,
--                                ad_working_res_locks
--            BASE_ERROR + 19 --> Exception, updating ad_sessions,
--                                ad_working_res_locks
--            BASE_ERROR + 20 --> Unhandled exception
--            BASE_ERROR + 21 --> Error, Current Mode = X and Requested
--                                mode = S in Promotion
--            BASE_ERROR + 22 --> Error, Locks need to be promoted is
--                                not at all held.
--            BASE_ERROR + 23 --> Error, reading ad_essions
--            BASE_ERROR + 24 --> Special return value, Acquire lock
--                                loop exhausted
--     6) warning_code        -   Out parameter
--             0              --> No warning
--             1              --> ADMIN db lock is held already by this
--                                connection. But an attempt is made to
--                                acquire once again.
--             2              --> ADMIN db lock is not at all held. But
--                                an attempt is made to release it.
--     7) error_message       -   Out parameter
--                            -   SQL errors are returned to the caller
--                                using this variable.
-- Purpose
--     This procedures acquires and promotes locks for a stage (of a
--     session_id). This API also handles a special stage "ACQUIRE_HELD"
--     differently. In this special stage, this API simply tries to
--     reacquire all already held locks.
-- Notes


procedure acquire_promote_db_locks (session_id in number,
                                    stage_code in varchar2,
                                    acquire_admin_flag in number,
                                    release_admin_flag in number,
                                    sleep_duration_in_ms in number,
                                    try_again_flag in number,
                                    error_code out nocopy number,
                                    warning_code out nocopy number,
                                    error_message out nocopy varchar2);
-- Procedure
--     release_demote_db_locks
-- Arguments
--     1) session_id
--     2) stage_code
--     3) acquire_admin_flag  -   If this flag is set to 1,ADMIN lock is
--                                acquired at the beginning.
--                                Otherwise, it is assumed that caller
--                                has already acquired the lock.
--     4) release_admin_flag  -   If this flag is set to 1,ADMIN lock is
--                                released at the end.
--                                Otherwise, it is assumed that caller
--                                will release the lock later. (this
--                                procedure retains ADMIN lock, only if
--                                the return status is success)
--     4) error_code          -   Out parameter
--            0               --> Success
--            BASE_ERROR + 1  --> This stage is already done.
--            BASE_ERROR + 2  --> Invalid argument.
--            BASE_ERROR + 3  --> Exception,reading ad_planned_res_locks
--            BASE_ERROR + 4  --> Inconsistency state (some of the lock
--                                rows have done_flag='Y' and others
--                                have done_flag='N')
--                                It shouldn't happen.
--            BASE_ERROR + 5  --> Exception,reading ad_planned_res_locks
--            BASE_ERROR + 6  --> Unhandled exception
--            BASE_ERROR + 7  --> Lock rows are not prestaged.
--            BASE_ERROR + 8  --> Data error.Demote to 'X' is not valid
--            BASE_ERROR + 9  --> Error, Locks need to be promoted is
--                                not at all held.
--     5) warning_code        -   Out parameter
--             0              --> No warning
--             1              --> ADMIN db lock is held already by this
--                                connection. But an attempt is made to
--                                acquire once again.
--             2              --> ADMIN db lock is not at all held. But
--                                an attempt is made to release it.
--     6) error_message       -   Out parameter
--                            -   SQL errors are returned to the caller
--                                using this variable.
-- Purpose
--     This procedure releases and demotes locks for a stage.
-- Notes

procedure release_demote_db_locks (session_id in number,
                                   stage_code in varchar2,
                                   acquire_admin_flag in number,
                                   release_admin_flag in number,
                                   error_code out nocopy number,
                                   warning_code out nocopy number,
                                   error_message out nocopy varchar2);


procedure set_task_completed(p_session_id        in number ,
                             p_task_id           in number ,
                             p_completion_status in varchar2,
                             p_end_stage_cd      in varchar2,
                             p_begin_stage_cd    in varchar2);


procedure mv_sessinfo_to_history(p_sess_id in number,
                                 p_complete_status in varchar2,
                                 p_error_code out nocopy number);


end ad_conc_session_locks;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_CONC_SESSION_LOCKS" as
/* $Header: adcslckb.pls 115.3 2004/02/05 15:16:18 pzanwar ship $ */

--
-- Procedure
--   get_admin_lock
--
-- Purpose
--   Lock the DB admin objects used in ad_concurrent_sessions
-- Usage
--
--
--
procedure get_admin_lock(status out nocopy number)
is
  l_lockhandle varchar2(128);
  l_status number := 100;
  l_exit_loop boolean := FALSE;
begin
  dbms_lock.allocate_unique('ORA_APPS_AD_LOCKMGR', l_lockhandle);
--
  l_exit_loop := FALSE;
--
  loop
    exit when l_exit_loop;
--
    l_status := dbms_lock.request(l_lockhandle);
--
    if l_status in (0, 4) then
      -- 0 => success
      -- 1 => already held. deem as success.
--
      l_exit_loop := TRUE;
--
    elsif l_status <> 1 then
--
      -- 1 => Timeout, in which case we want to keep trying (ie. stay in the
      -- loop). Any value other than 1 is a fatal error.
--
      raise_application_error(-20000, 'Fatal error in get_admin_lock() - '||
                                      to_char(l_status));
    end if;
--
  end loop;
--
  status := l_status;
--
return;
--
end get_admin_lock;


procedure get_admin_lock_with_timeout(status out nocopy number,
                                      timeout_period in integer)
is
  l_lockhandle varchar2(128);
  l_status number := 100;
  l_exit_loop boolean := FALSE;
begin
  dbms_lock.allocate_unique('ORA_APPS_AD_LOCKMGR', l_lockhandle);
--
  l_exit_loop := FALSE;
--
  loop
    exit when l_exit_loop;
--
    l_status := dbms_lock.request(l_lockhandle, 6, timeout_period, FALSE);
--
    if l_status in (0, 1, 4) then
      -- 0 => success
      -- 1 => already held. deem as success.
--
      l_exit_loop := TRUE;
--
      elsif l_status <> 1 then
--
      -- 1 => Timeout, in which case we want to keep trying (ie. stay in the
      -- loop). Any value other than 1 is a fatal error.

       raise_application_error(-20000, 'Fatal error in get_admin_lock() - '||
                                        to_char(l_status) || timeout_period);
    end if;
--
  end loop;
--
  status := l_status;
--
return;
--
end get_admin_lock_with_timeout;


--
-- Procedure
--   release_admin_lock
--
-- Purpose
--   Release the DB admin objects used in ad_concurrent_sessions
-- Usage
--
--
--
procedure release_admin_lock(status out nocopy number)
is
  l_lockhandle varchar2(128);
  l_status number := 100;
  l_exit_loop boolean := FALSE;
begin
  dbms_lock.allocate_unique('ORA_APPS_AD_LOCKMGR',l_lockhandle);
--
  l_exit_loop := FALSE;
--
  loop
--
    exit when l_exit_loop;
--
    l_status:=dbms_lock.release(l_lockhandle);
--
    if l_status in (0, 4) then
      -- 0 => success
      -- 1 => already held. deem as success.
--
      l_exit_loop := TRUE;
    else
       raise_application_error(-20000,
           'Fatal error in release_admin_lock() - '|| to_char(l_status));
    end if;
--
  end loop;
--
--
  status:=l_status;
--
--
  return;
end release_admin_lock;
--
--
procedure  reset_session_info(sess_id in number, process_id in number ,
                              appltop_path in varchar2,
                              node_name in varchar2,
                              inactive_flag out nocopy varchar2,
                              p_invokdir in varchar2)
is
 dummy_number number;
begin
--
 /*Get the Admin lock */
    get_admin_lock(dummy_number);
--
--
 /* Update the process_id and set the STATUS to 'ACTIVE' */
 update  ad_sessions set
 OS_PROCESS_ID=process_id,
 STATUS='ACTIVE',
 LAST_UPDATE_DATE=sysdate,
 APPL_TOP_PATH=appltop_path,
 INVOKDIR=p_invokdir,
 RUN_ON_NODE=node_name
 where
 session_id=sess_id;
--
--
 update  AD_WORKING_RES_LOCKS set
 SESSION_STATUS='ACTIVE'
 where
 SESSION_ID=sess_id;
--
--
 /* Get the ANY_CHANGE_WHILE_INACTIVE_FLAG  for this session from ad_sessions */
 select nvl(ANY_CHANGE_WHILE_INACTIVE_FLAG,'N')
 into inactive_flag
 from ad_sessions
 where  session_id=sess_id;
--
--
--
  commit;
 /* release the Admin lock */
 release_admin_lock(dummy_number);
--
end reset_session_info;
--
--
procedure  set_session_info(sess_id    in number  ,process_id    in number,
                            utility_nm in varchar2,appltop_id    in number,
                            priority_value in number,osuser_name in varchar2,
                            invokedir in varchar2, appltop_path in varchar2,
                            node_name in varchar2, p_topdir in varchar2)
is
  lock_status number;
  session_status  varchar2(30);
  session_exists  number:=0;

  exst_session_id         number;
  exst_utility_name       varchar2(8);
  exst_appl_top_id        number;
  exst_topdir           varchar2(256);
  exst_status             varchar2(30);
  exst_priority           number;
  exst_os_user_name       varchar2(30);
  exst_appltop_path       varchar2(256);
  exst_node_name          varchar2(31);
begin
--
--  Get db admin lock
--
  if utility_nm = 'adctrl' then
    get_admin_lock_with_timeout(lock_status, 3);
  else
    get_admin_lock(lock_status);
  end if;

--
--
 SELECT  count(*)  INTO session_exists  from ad_sessions
 where session_id=sess_id;
--
 if session_exists > 1  then
  -- should not happen but in case the primary key index is dropped
       raise_application_error(-20000,
       'Fatal error Duplicate session_id in AD_SESSIONS: set_session_info()');
 end if;


 if session_exists = 1  then
   -- if  a row exists with the same session_id then
   -- check if it is the  same  utility, APPL_TOP and start_date
   -- as the one we are trying to insert
   -- if they  same then need not insert the record again. This situation
   -- can occur when a row was created in ad_sessions table and failed before
   -- updating the session_info_file.
   -- In the restart case we need to just update the STATUS column and
   -- process_id column for that row in the ad_sessions
   select
    SESSION_ID,UTILITY_NAME,APPL_TOP_ID,
    TOPDIR,STATUS,PRIORITY,
    OS_USER_NAME
   into
    exst_session_id,exst_utility_name,exst_appl_top_id,
    exst_topdir,exst_status,exst_priority,
    exst_os_user_name
   from ad_sessions
   where
   session_id=sess_id;
--
   if exst_session_id    = sess_id         and
      exst_utility_name  = utility_nm      and
      exst_appl_top_id   = appltop_id      and
      exst_topdir        = p_topdir          and
      exst_priority      = priority_value  and
      exst_os_user_name  = osuser_name     then
     -- if exists then just update the sttus to ACTIVE
       update AD_SESSIONS set status='ACTIVE'
       where session_id=sess_id;
   else
     raise_application_error(-20000,
     'Fatal error Duplicate session_id in AD_SESSIONS: set_session_info()');
   end if;
 else
     -- if here this means that a new row has to be inserted
      INSERT INTO AD_SESSIONS
       (
        SESSION_ID,UTILITY_NAME,APPL_TOP_ID,
        INVOKDIR,STATUS,PRIORITY,
        OS_PROCESS_ID,OS_USER_NAME,
        START_DATE,CREATION_DATE,LAST_UPDATE_DATE,
        APPL_TOP_PATH, RUN_ON_NODE, TOPDIR
      )
      VALUES
      (
        sess_id,
        utility_nm,
        appltop_id,
        invokedir,
        'ACTIVE',
        priority_value,
        process_id,
        osuser_name,
        SYSDATE,
        SYSDATE,SYSDATE,
        appltop_path, node_name, p_topdir
      );
 end if;
--
--   Release db admin lock
--
 release_admin_lock(lock_status);
--
--
--   commit;
  commit;
--
--
return;
--
--
end set_session_info;
--
--
procedure  deactivate_session_row(sess_id in number,
                                  get_lock_with_timeout in number,
                                  row_count out nocopy number)
is
 dummy_number number;
begin
--
 /*Get the Admin lock */
 if get_lock_with_timeout = 0 then
   get_admin_lock(dummy_number);
 else
   get_admin_lock_with_timeout(dummy_number, 3);
 end if;
--
--
 /* Update the STATUS to 'INACTIVE' */
--
 update  AD_SESSIONS set
 STATUS='INACTIVE',
 LAST_UPDATE_DATE=SYSDATE
 where
 SESSION_ID=sess_id;
--
 update  AD_WORKING_RES_LOCKS set
 SESSION_STATUS='INACTIVE'
 where
 SESSION_ID=sess_id;
--
 row_count := sql%rowcount;
 /* commit */
--
 commit;
--
 /* release the Admin lock */
 release_admin_lock(dummy_number);
--
--
exception
when no_data_found then
  row_count := 0;
end deactivate_session_row;


-- Procedure
--     check_compatibility_with_fifo
-- Arguments
--     1) session_id
--     2) x_conflict_session_ids - Out parameter
--                                 List of conflict session ids.
--     3) error_code             - Out parameter
--            0                  --> Success
--            BASE_ERROR + 1     --> Invalid Argument
--            BASE_ERROR + 2     --> Unhandled exception
-- Purpose
--     This procedures does compatibility checks in DB. It checks set
--     of locks requested can be acquired (together) or not. It also
--     forces FIFO algorithm amoung same priority sessions
-- Notes

procedure check_compatibility_with_fifo (session_id in number,
                                         x_conflict_session_ids out
                                         nocopy conflict_sessions_t,
                                         error_code out nocopy number)
is
  BASE_ERROR              number; /* This will be used, if we want to
                                   * propogate error number to the main
                                   * (for generating unique error number
                                   * - in future)
                                   */
  x_session_id            number;
begin

  BASE_ERROR := 0;
  x_session_id := session_id;
  error_code := 0; /* No error */

  /* Validate the arguments passed */
  if (session_id <= 0) then
    error_code := BASE_ERROR + 1; /* Invalid argument */
    raise_application_error(-20000,
         'Fatal error in check_compatibility_with_fifo() - '||
         to_char(error_code));
  end if;

  select distinct wl.session_id
    bulk collect into x_conflict_session_ids
  from ad_working_res_locks wr,    /* Requested */
       ad_working_res_locks wl     /* Locked */
  where wr.session_id = x_session_id and
        wl.session_id <> x_session_id and  /* Look at other sessions */
        wl.resource_code = wr.resource_code and
        ( wl.appl_top_id = -5 or
          wr.appl_top_id = -5 or
          wl.appl_top_id = wr.appl_top_id ) and
        ( wl.context = 'ALL' or
          wr.context = 'ALL' or
          wl.context = wr.context ) and
        ( wl.language = 'ALL' or
          wr.language = 'ALL' or
          wl.language = wr.language ) and
        ( wl.extra_context1 = 'ALL' or
          wr.extra_context1 = 'ALL' or
          wl.extra_context1 = wr.extra_context1 ) and
        ( wl.extra_context2 = 'ALL' or
          wr.extra_context2 = 'ALL' or
          wl.extra_context2 = wr.extra_context2 ) and
        ( wl.extra_context3 = 'ALL' or
          wr.extra_context3 = 'ALL' or
          wl.extra_context3 = wr.extra_context3 ) and
          wl.lock_mode = decode(wr.lock_mode,
                                'S', 'X',
                                'X', wl.lock_mode,
                                wl.lock_mode) and
        wl.session_status = 'ACTIVE' and
        ( wl.date_acquired is not null or
          wl.session_priority > wr.session_priority or
          (
            wl.session_priority = wr.session_priority and
            wl.date_requested < wr.date_requested
          )
        );

exception
  when others then
    error_code := BASE_ERROR + 2; /* Error, unhandled exception */
    raise_application_error(-20000,
            'Fatal error in check_compatibility_with_fifo() - '||
            to_char(error_code) ||
            substr(sqlerrm, 1, 100));

end check_compatibility_with_fifo;

-- Procedure
--     check_compatibility
-- Arguments
--     1) session_id
--     2) x_conflict_session_ids - Out parameter
--                                 List of conflict session ids.
--     3) error_code             - Out parameter
--            0                  --> Success
--            BASE_ERROR + 1     --> Invalid Argument
--            BASE_ERROR + 2     --> Unhandled exception
-- Purpose
--     This procedures does compatibility checks in DB. It checks set
--     of locks requested can be acquired (together) or not.
-- Notes

procedure check_compatibility (session_id in number,
                               x_conflict_session_ids out
                               nocopy conflict_sessions_t,
                               error_code out nocopy number)
is
  BASE_ERROR              number; /* This will be used, if we want to
                                   * propogate error number to the main
                                   * (for generating unique error number
                                   * - in future)
                                   */
  x_session_id            number;
begin

  BASE_ERROR := 0;
  x_session_id := session_id;
  error_code := 0; /* No error */

  /* Validate the arguments passed */
  if (session_id <= 0) then
    error_code := BASE_ERROR + 1; /* Invalid argument */
    raise_application_error(-20000,
            'Fatal error in check_compatibility() - '||
            to_char(error_code));
  end if;

  select distinct wl.session_id
    bulk collect into x_conflict_session_ids
  from ad_working_res_locks wr,    /* Requested */
       ad_working_res_locks wl     /* Locked */
  where wr.session_id = x_session_id and
        wl.session_id <> x_session_id and  /* Look at other sessions */
        wl.resource_code = wr.resource_code and
        ( wl.appl_top_id = -5 or
          wr.appl_top_id = -5 or
          wl.appl_top_id = wr.appl_top_id ) and
        ( wl.context = 'ALL' or
          wr.context = 'ALL' or
          wl.context = wr.context ) and
        ( wl.language = 'ALL' or
          wr.language = 'ALL' or
          wl.language = wr.language ) and
        ( wl.extra_context1 = 'ALL' or
          wr.extra_context1 = 'ALL' or
          wl.extra_context1 = wr.extra_context1 ) and
        ( wl.extra_context2 = 'ALL' or
          wr.extra_context2 = 'ALL' or
          wl.extra_context2 = wr.extra_context2 ) and
        ( wl.extra_context3 = 'ALL' or
          wr.extra_context3 = 'ALL' or
          wl.extra_context3 = wr.extra_context3 ) and
          wl.lock_mode = decode(wr.lock_mode,
                                'S', 'X',
                                'X', wl.lock_mode,
                                wl.lock_mode) and
        wl.session_status = 'ACTIVE' and
        ( wl.date_acquired is not null or
          wl.session_priority > wr.session_priority
        );

exception
  when others then
    error_code := BASE_ERROR + 2; /* Error, unhandled exception */
    raise_application_error(-20000,
            'Fatal error in check_compatibility() - '||
            to_char(error_code) ||
            substr(sqlerrm, 1, 100));

end check_compatibility;

-- Procedure
--     do_deadlock_detection
-- Arguments
--     1) root_session_id
--     2) error_code          -   Out parameter
--             0              --> Success
--             BASE_ERROR + 1 --> Deadlock detected, abort (caller is
--                                the least priority process in the list
--                                of process that caused the deadlock)
--             BASE_ERROR + 2 --> Deadlock detected, continue (caller is
--                                not the least priority process)
--             BASE_ERROR + 3 --> No conflicting sessions found for root
--                                session id.
--             BASE_ERROR + 4 --> Invalid Argument
--             BASE_ERROR + 5 --> check_compatibility  failed
--             BASE_ERROR + 6 --> Reading ad_sessions failed
--             BASE_ERROR + 7 --> Unhandled exception
--             BASE_ERROR + 8 --> Logic error,tree nodes are not proper
-- Purpose
--     Deadlocks are detected in this procedure. See the various return
--     values (above) for exact functionality.
-- Notes

procedure do_deadlock_detection(root_session_id in number,
                                error_code out nocopy number)
is
  BASE_ERROR            number; /* This will be used, if we want to
                                 * propogate error number to the main
                                 * (for generating unique error number
                                 * - in future)
                                 */
  session_list          conflict_sessions_t; /* To store tree node
                                              * values */
  session_tree          conflict_sessions_t; /* To store tree */
  conflict_session_ids  conflict_sessions_t;
  session_max           number;
  loop_count            number;
  temp_session_count    number;
  num                   number;
  dup_flag              number;
  deadlock_node_index   number;
  parent_node           number;
  child_node            number;
  parent_priority       number;
  child_priority        number;
  least_priority_node   number;
begin

  BASE_ERROR := 0;
  error_code := 0; /* No error */

  if (root_session_id <= 0) then
    error_code := BASE_ERROR + 4; /* Invalid Argument */
    raise_application_error(-20000,
            'Fatal error in do_deadlock_detection() - '||
            to_char(error_code));
    return;
  end if;

  /* Do compatibility check for root session id */
  check_compatibility_with_fifo(root_session_id, session_list,
                       error_code);

  /* session_list is used as tree node values list, the actual tree
   * structure is stored in session_tree
   *
   * Example
   *     session_tree     0    0    0    1    1    2    4
   *     session_list     101  103  105  107  108  110  113
   *
   * This is the BFS tree. root_node is not in the tree. The root
   * node is nothing but root_session_id. It is not stored in the
   * above shown data structures.
   *
   * Using session_tree, we can construct the tree. The tree node
   * values are stored in session_list.
   *
   * In other words, session_list has the list of session_ids and
   * corresponding session_tree element has the index of the parent
   * element. If the session_tree element has value 0, the parent
   * node is root node.
   */
  if (session_list.count = 0) then
    error_code := BASE_ERROR + 3; /* No conflicting sessions */
    return;
  end if;

  session_max := session_list.count;

  /* Initialize session tree */
  num := 1;
  while (num <= session_max) loop
    session_tree(num) := 0; /* parent node is root_session_id */
    num := num + 1;
  end loop;

  loop_count := 1;

  /* Do compatibility check - for all the elements in the
   * list of session ids (conflicting with root session id, either
   * directly or indirectly)
   */
  deadlock_node_index := 0;
  while (loop_count <= session_max) loop

    check_compatibility_with_fifo(session_list(loop_count),
                        conflict_session_ids,
                        error_code);

    /* One or more conflicting sessions found */
    if (conflict_session_ids.count > 0) then

      temp_session_count := session_list.count;
      /* Check whether newly found conflicting sessions (not
       * necessarily directly conflicting with root session id)
       * are already in the list of conflicting sessions. If it is
       * not so, add them to the list. Also, check for deadlock.
       */
      for var in conflict_session_ids.first..conflict_session_ids.last loop
        /* Check for deadlock */
        if (conflict_session_ids(var) = root_session_id) then
          deadlock_node_index := loop_count; /* Deadlock detected */
          session_max := 0; /* Terminate the outer loop */
          exit;
        else
          /* Add this session id to the list of conflicting sessions.
           * If it is not available (list of sessions for which
           * do_compatibility check need to be run).
           * (Search is not optimized because, the number of sessions
           * are always very less)
           */

          /** A small optimization here. restricting loop to
            * "temp_session_count", instead of
            * "session_list.count"
            */
          dup_flag := 0;
          num := 1;
          while (num <= temp_session_count) loop
            if (conflict_session_ids(var) = session_list(num)) then
              dup_flag := 1;
            end if;
            num := num + 1;
          end loop;

          if (dup_flag = 0) then
            session_max := session_max + 1;
            session_list(session_max) := conflict_session_ids(var);
            session_tree(session_max) := loop_count; /* Parent node */
          end if;
        end if;
      end loop;
    end if;
    loop_count := loop_count + 1;
  end loop;

  /* Deadlock detected. Check for the lowest priority process in
   * the deadlock loop. If the current process is the lowest priority
   * return a special value (the deadlock detected and forced
   * to abort the session)
   */
  if (deadlock_node_index <> 0) then
    child_node := session_list(deadlock_node_index);
    begin
      select priority into child_priority from ad_sessions
      where session_id = child_node; /* Child node */
    exception
      when others then
        error_code := BASE_ERROR + 6; /* Error, reading ad_sessions */
        raise_application_error(-20000,
            'Fatal error in do_deadlock_detection() - '||
            to_char(error_code) ||
            substr(sqlerrm, 1, 100));
    end;

    /* Traverse back from the leaf node where deadlock is detected and
     * find the lowest priority process(node)
     */
    least_priority_node := 0;
    while (deadlock_node_index <> 0) loop
      if (session_tree(deadlock_node_index) = 0) then
        parent_node := root_session_id;
      else
        parent_node := session_list(session_tree(deadlock_node_index));
      end if;

      begin
        select priority into parent_priority from ad_sessions
        where session_id = parent_node;
      exception
        when others then
          error_code := BASE_ERROR + 6; /* Error, reading ad_sessions */
          raise_application_error(-20000,
              'Fatal error in do_deadlock_detection() - '||
              to_char(error_code) ||
              substr(sqlerrm, 1, 100));
      end;

      if (child_priority < parent_priority) then
        least_priority_node := child_node;
      else
        least_priority_node := parent_node;
      end if;
      child_node := parent_node;
      child_priority := parent_priority;
      if (session_tree(deadlock_node_index) = 0) then
        if (child_node = root_session_id) then
          exit;
        else
          error_code := BASE_ERROR + 8; /* Error, tree construction */
          raise_application_error(-20000,
              'Fatal error in do_deadlock_detection() - '||
              to_char(error_code));
        end if;
      end if;
      deadlock_node_index := session_tree(deadlock_node_index);
    end loop;

    if (least_priority_node = root_session_id) then
      error_code := BASE_ERROR + 1; /* Deadlock, current session is the
                                     * least priority session, abort */
    else
      error_code := BASE_ERROR + 2; /* Deadlock, current session is not
                                     * the least priority session */
    end if;
  end if;
  return;
exception
  when others then
    error_code := BASE_ERROR + 7; /* Unhandled exception */
    raise_application_error(-20000,
         'Fatal error in do_deadlock_detection() - '||
         to_char(error_code) ||
         substr(sqlerrm, 1, 100));

end do_deadlock_detection;


-- Procedure
--     acquire_promote_db_locks
-- Arguments
--     1) session_id
--     2) stage_code
--     3) acquire_admin_flag  -   If this flag is set to 1,ADMIN lock is
--                                acquired at the beginning.
--                                Otherwise, it is assumed that caller
--                                has already acquired the lock.
--     4) release_admin_flag  -   If this flag is set to 1,ADMIN lock is
--                                released at the end.
--                                Otherwise, it is assumed that caller
--                                will release the lock later. (this
--                                procedure retains ADMIN lock, only if
--                                the return status is success)
--     5) error_code          -   Out parameter
--            0               --> Success
--            BASE_ERROR + 1  --> This stage is already done.
--            BASE_ERROR + 2  --> Deadlock detected, abort (caller is
--                                the least priority process in the list
--                                of processes that caused the deadlock)
--            BASE_ERROR + 3  --> Invalid argument.
--            BASE_ERROR + 4  --> Lock rows are not prestaged.
--            BASE_ERROR + 5  --> Inconsistency state (some of the lock
--                                rows have done_flag='Y' and others
--                                have done_flag='N')
--                                It shouldn't happen.
--            BASE_ERROR + 6  --> Exception,reading ad_planned_res_lock
--            BASE_ERROR + 7  --> Exception, reading ad_sessions.
--            BASE_ERROR + 8  --> Exception, inserting row in
--                                ad_working_res_locks.
--            BASE_ERROR + 9  --> Exception updating ad_sessions.
--            BASE_ERROR + 10 --> Error, do_compatibility check failed
--            BASE_ERROR + 11 --> Stage_code = 'ACQUIRE_HELD' and
--                                compatibility check -> incompatibility
--            BASE_ERROR + 12 --> Exception, updating ad_sessions,
--                                ad_working_res_locks
--            BASE_ERROR + 13 --> Exception, reading ad_sessions
--            BASE_ERROR + 14 --> Adctrl says to quit
--            BASE_ERROR + 15 --> Exception, updating ad_sessions,
--                                ad_working_res_locks
--            BASE_ERROR + 16 --> Error calling do_deadlock_detection.
--            BASE_ERROR + 17 --> Exception, updating ad_sessions.
--            BASE_ERROR + 18 --> Exception, updating ad_sessions,
--                                ad_working_res_locks
--            BASE_ERROR + 19 --> Exception, updating ad_sessions,
--                                ad_working_res_locks
--            BASE_ERROR + 20 --> Unhandled exception
--            BASE_ERROR + 21 --> Error, Current Mode = X and Requested
--                                mode = S in Promotion
--            BASE_ERROR + 22 --> Error, Locks need to be promoted is
--                                not at all held.
--            BASE_ERROR + 23 --> Error, reading ad_essions
--            BASE_ERROR + 24 --> Special return value, Acquire lock
--                                loop exhausted
--     6) warning_code        -   Out parameter
--             0              --> No warning
--             1              --> ADMIN db lock is held already by this
--                                connection. But an attempt is made to
--                                acquire once again.
--             2              --> ADMIN db lock is not at all held. But
--                                an attempt is made to release it.
--     7) error_message       -   Out parameter
--                            -   SQL errors are returned to the caller
--                                using this variable.
-- Purpose
--     This procedures acquires and promotes locks for a stage (of a
--     session_id). This API also handles a special stage "ACQUIRE_HELD"
--     differently. In this special stage, this API simply tries to
--     reacquire all already held locks.
-- Notes


procedure acquire_promote_db_locks (session_id in number,
                                    stage_code in varchar2,
                                    acquire_admin_flag in number,
                                    release_admin_flag in number,
                                    sleep_duration_in_ms in number,
                                    try_again_flag in number,
                                    error_code out nocopy number,
                                    warning_code out nocopy number,
                                    error_message out nocopy varchar2)
is
  type done_flag_t is table of varchar2(1) index by binary_integer;

  BASE_ERROR            number; /* This will be used, if we want to
                                 * propogate error number to the main
                                 * (for generating unique error number
                                 * - in future)
                                 */
  x_done_flag             done_flag_t;
  x_stage_code            varchar2(30);
  x_session_id            number;
  x_priority              number;
  x_status                varchar2(30);
  x_wait_loop_time        number;
  x_control_code          varchar2(1);
  x_mode_count            number;
  held_lock               number;
  sleep_duration          number;
  lock_status             number;
  conflict_session_ids    conflict_sessions_t;
  conflict_session_count  number;
  loop_max_count          number;
  x_lock_count            number;
  loop_count              number;
begin

  BASE_ERROR := 0;
  error_code := 0;   /* No error */
  warning_code := 0; /* No warning */
  held_lock := 0;
  sleep_duration := sleep_duration_in_ms/1000;

  x_session_id := session_id;
  x_stage_code := stage_code;
  loop_max_count := 10;

  /* Validate the arguments passed */
  if (session_id <= 0 or stage_code = null) then
    error_code := BASE_ERROR + 3; /* Error, invalid argument */
    return;
  end if;

  /* If stage code is ACQUIRE_HELD, it is an attempt to
   * re-acquire all acquired locks
   */

  if (x_stage_code <> 'ACQUIRE_HELD') then
    /* Check whether this stage locks have been acquired and
     * released earlier or not. (done_flag -> restart purpose)
     *
     * Are all the prestaged rows for this stage marked as
     * Done (done_flag = 'Y') ?
     */
    begin

      select distinct  nvl(done_flag,'N') bulk collect into x_done_flag
        from ad_planned_res_locks
        where session_id = x_session_id and
              stage_code = x_stage_code;

      if (x_done_flag.count = 0) then
        error_code := BASE_ERROR + 4;  /* Error, no lock rows
                                        * are prestaged */
        goto acquire_error;
      end if;

      if (x_done_flag.count <> 1) then
        error_code := BASE_ERROR + 5; /* Error, inconsistancy state,
                                       * it shouldn't happend */
        goto acquire_error;

      end if;

      if (x_done_flag(1) = 'Y') then
        error_code := BASE_ERROR + 1; /* Special return status, this
                                       * stage is done already */
        goto acquire_error;
      end if;
    exception
      when others then
        error_message := substr(sqlerrm, 1, 100);
        error_code :=  BASE_ERROR + 6; /* Error, reading
                                        * ad_planned_res_locks */
        goto acquire_error;
    end;
  end if;

  /* Read priority and status from ad_sessions table */
  begin
    select priority, status into x_priority, x_status
      from ad_sessions where session_id = x_session_id;
  exception
    when others then
      error_message := substr(sqlerrm, 1, 100);
      error_code := BASE_ERROR + 7; /* Error, reading
                                     * ad_sessions */
      goto acquire_error;
  end;

  if (acquire_admin_flag = 1) then
    /* Acquire ADMIN lock */
    get_admin_lock(lock_status);
    if (lock_status <> 0) then
      warning_code := 1; /* Warning, this connection
                          * holds the lock already */
    end if;
  end if;

  held_lock := 1; /* Lock is held */

  if (try_again_flag = 0) then
    /* Request locks -> insert lock rows in ad_working_res_locks */
    begin
      if (x_stage_code <> 'ACQUIRE_HELD') then
        insert into ad_working_res_locks
        (
          session_id,
          resource_code,
          context,
          appl_top_id,
          language,
          extra_context1,
          extra_context2,
          extra_context3,
          in_process_flag,
          lock_mode,
          date_requested,
          date_acquired,
          session_status,
          session_priority
        )
          select x_session_id, p.resource_code, p.context, p.appl_top_id,
                 p.language,
                 p.extra_context1,
                 p.extra_context2,
                 p.extra_context3,
                 'Y',
                 p.lock_mode,
                 sysdate,
                 null,
                 x_status,
                 x_priority
          from ad_planned_res_locks p
          where p.session_id = x_session_id and
                p.stage_code = x_stage_code and
                p.action_flag in ('A', 'P', 'B') and
                not exists (
                  /* It may be a restart and rows may already exist.
                   * (If the failure occurred in this procedure in
                   * the prior run)
                   */
                  select 'Already inserted'
                  from ad_working_res_locks w
                  where w.session_id = x_session_id and
                        w.resource_code = p.resource_code and
                        w.context = p.context and
                        w.appl_top_id = p.appl_top_id and
                        w.language = p.language and
                        w.extra_context1 = p.extra_context1 and
                        w.extra_context2 = p.extra_context2 and
                        w.extra_context3 = p.extra_context3 and
                        w.in_process_flag = 'Y');
      end if;
    exception
      when others then
        rollback;
        error_message := substr(sqlerrm, 1, 100);
        error_code := BASE_ERROR + 8; /* Error, inserting row in
                                       * ad_working_res_locks */
        goto acquire_error;
    end;

    /* Reset wait loop time */
    begin
      update ad_sessions set wait_loop_time = 0
        where session_id = x_session_id;
      commit work;
      x_wait_loop_time := 0;
    exception
      when others then
        rollback;
        error_message := substr(sqlerrm, 1, 100);
        error_code := BASE_ERROR + 9; /* Error, updating
                                       * ad_sessions */
        goto acquire_error;
    end;
  else
    begin
      select wait_loop_time into x_wait_loop_time from ad_sessions
        where session_id = x_session_id;
    exception
      when others then
        rollback;
        error_message := substr(sqlerrm, 1, 100);
        error_code := BASE_ERROR + 23; /* Error, reading
                                        * ad_sessions */
        goto acquire_error;
    end;
  end if;

  loop_count := 0;

  /* Loop for acquiring locks */
  loop
    if (loop_count > loop_max_count) then
      error_code := BASE_ERROR + 24; /* Special return value,
                                      * loop exhausted */
      goto acquire_error;
    end if;

    loop_count := loop_count + 1;

    /* Do compatibility checks in DB against "acquired" resource
     * locks (only ACTIVE sessions) and also "requested"
     * locks of higher priority ACTIVE sessions
     */
    check_compatibility_with_fifo(x_session_id, conflict_session_ids,
                                  error_code);
    if (error_code <> 0) then
      error_code := BASE_ERROR + 10; /* Error, doing compatibility_check */
      goto acquire_error;
    end if;

    /* There are no conflicting sessions */
    if (conflict_session_ids.count = 0) then
      exit; /* Break out of the main loop */

    /* There are conflicting sessions */
    else
      /* Check the stage_code for ACQUIRE_HELD stage  */
      if (x_stage_code = 'ACQUIRE_HELD') then
        /* de-activate session-row in DB */
        begin
          update ad_sessions set status = 'INACTIVE'
            where session_id = x_session_id;
          update ad_working_res_locks set session_status = 'INACTIVE'
            where session_id = x_session_id;
          commit work;
          error_code := BASE_ERROR + 11; /* Exit point */
          goto acquire_error;
        exception
          when others then
            rollback;
            error_message := substr(sqlerrm, 1, 100);
            error_code := BASE_ERROR + 12; /* Error, updating rows in
                                            * ad_working_res_locks */
            goto acquire_error;
        end;

      /* stage_code <> ACQUIRE_HELD  */
      else
        /* Read control_code from ad_sessions */
        begin
          select control_code into x_control_code from ad_sessions
            where session_id = x_session_id;
        exception
          when others then
            error_message := substr(sqlerrm, 1, 100);
            error_code := BASE_ERROR + 13;/* Error,reading ad_sessions*/
            goto acquire_error;
        end;

        /* Adctrl says to abort -> control_code is 'Q' ? */
        if (x_control_code = 'Q') then

          /* Wipe out ad_sessions.control_code and
           * de-activate session-row in DB
           */
          begin
            update ad_sessions set control_code = null,
                                   status = 'INACTIVE'
              where session_id = x_session_id;
            update ad_working_res_locks set session_status = 'INACTIVE'
              where session_id = x_session_id;
            commit work;
            error_code := BASE_ERROR + 14;
            goto acquire_error;
          exception
            when others then
              rollback;
              error_message := substr(sqlerrm, 1, 100);
              error_code := BASE_ERROR + 15; /* Error, updating
                                * ad_sessions, ad_working_res_locks */
              goto acquire_error;
          end;

        /* control_code is not set to 'Q' */
        else

          /* Detect dead lock */
          do_deadlock_detection(x_session_id, error_code);

          if (error_code not in (0,1,2,3)) then
            error_code := BASE_ERROR + 16;
            goto acquire_error;
          end if;

          /* Deadlock is detected and caller is the lowest
           * priority process, so abort
           */
          if (error_code = 1) then
            /* De-activate session-row in DB */
            begin
              update ad_sessions set status = 'INACTIVE'
                where session_id = x_session_id;
              update ad_working_res_locks set session_status = 'INACTIVE'
                where session_id = x_session_id;
              commit work;
              error_code := BASE_ERROR + 2;
              goto acquire_error;
            exception
              when others then
                rollback;
                error_message := substr(sqlerrm, 1, 100);
                error_code := BASE_ERROR + 17; /* Error, updating
                                  * ad_sessions, ad_working_res_locks */
                goto acquire_error;
            end;
          end if;

          /* Release DB admin lock */
          release_admin_lock(lock_status);
          if (lock_status <> 0) then
            warning_code := 2; /* Warning, not at all held the lock */
          end if;

          held_lock := 0;  /* Lock is not held at present */

          /* Delay or sleep here */
          dbms_lock.sleep(sleep_duration);

          /* Get DB admin lock */
          get_admin_lock(lock_status);
          if (lock_status <> 0) then
            warning_code := 1; /* Warning, not at all held the lock */
          end if;

          held_lock := 1;  /* Lock is held at present */

          /* Increment wait loop time */
          x_wait_loop_time := x_wait_loop_time + sleep_duration;
          begin
            update ad_sessions set wait_loop_time = x_wait_loop_time
              where session_id = x_session_id;
            commit work;
          exception
            when others then
              error_message := substr(sqlerrm, 1, 100);
              error_code := BASE_ERROR + 18; /* Error, updating
                                              * ad_sessions */
              goto acquire_error;
          end;
        end if;
      end if;
    end if;
  end loop;

  if (stage_code <> 'ACQUIRE_HELD') then
    begin
      select count(*) into x_mode_count from ad_working_res_locks
        where session_id = x_session_id and
              lock_mode = 'X';

      if (x_mode_count > 0) then
        update ad_sessions
	set any_change_while_inactive_flag = 'Y',
	    locks_overridden_by = x_session_id
          where
	  nvl(any_change_while_inactive_flag,'N') <> 'Y' and
	  session_id in (
            select distinct wl.session_id
            from ad_working_res_locks wr,    -- Requested
                 ad_working_res_locks wl     -- Locked
            where wr.session_id = x_session_id and
                  wl.session_id <> x_session_id and
                  wl.resource_code = wr.resource_code and
                  ( wl.appl_top_id = -5 or
                    wr.appl_top_id = -5 or
                    wl.appl_top_id = wr.appl_top_id ) and
                  ( wl.context = 'ALL' or
                    wr.context = 'ALL' or
                    wl.context = wr.context ) and
                  ( wl.language = 'ALL' or
                    wr.language = 'ALL' or
                    wl.language = wr.language ) and
                  ( wl.extra_context1 = 'ALL' or
                    wr.extra_context1 = 'ALL' or
                    wl.extra_context1 = wr.extra_context1 ) and
                  ( wl.extra_context2 = 'ALL' or
                    wr.extra_context2 = 'ALL' or
                    wl.extra_context2 = wr.extra_context2 ) and
                  ( wl.extra_context3 = 'ALL' or
                    wr.extra_context3 = 'ALL' or
                    wl.extra_context3 = wr.extra_context3 ) and
                  wl.session_status = 'INACTIVE');
      end if;

      select count(*) into x_lock_count from ad_working_res_locks
        where (
          resource_code || ':' || context || ':' || appl_top_id || ':' ||
          language || ':' || extra_context1 || ':' ||
          extra_context2 || ':' || extra_context3 || ':' ||
          decode (lock_mode, 'X', 'M', lock_mode)
          in
          (select  wl.resource_code || ':' || wl.context || ':' ||
                   wl.appl_top_id || ':' || wl.language || ':' ||
                   wl.extra_context1 || ':' || wl.extra_context2 || ':' ||
                   wl.extra_context3 || ':' || decode (lock_mode, 'S', 'M',
                                                       lock_mode)
          from ad_planned_res_locks wl
          where session_id = x_session_id and
                stage_code = x_stage_code and
                action_flag = 'P') and
          session_id = x_session_id and
          in_process_flag = 'N' and
          date_acquired is not null);

      if (x_lock_count <> 0) then
        rollback;
        error_code := BASE_ERROR + 21;
        goto acquire_error;
      end if;

      select count(*) into x_lock_count from (
        select resource_code, context, appl_top_id,
               language,
               extra_context1,
               extra_context2,
               extra_context3
        from ad_planned_res_locks wl
        where session_id = x_session_id and
              stage_code = x_stage_code and
              action_flag = 'P'
        minus
        select resource_code, context, appl_top_id,
               language,
               extra_context1,
               extra_context2,
               extra_context3
        from ad_working_res_locks where (
          resource_code || ':' || context || ':' ||
          appl_top_id || ':' || language || ':' ||
          extra_context1 || ':' || extra_context2 || ':' ||
          extra_context3
          in
          (select  wl.resource_code || ':' || wl.context || ':' ||
                   wl.appl_top_id || ':' || wl.language || ':' ||
                   wl.extra_context1 || ':' || wl.extra_context2 || ':' ||
                   wl.extra_context3
          from ad_planned_res_locks wl
          where session_id = x_session_id and
                stage_code = x_stage_code and
                action_flag = 'P') and
          session_id = x_session_id and
          in_process_flag = 'N' and
          date_acquired is not null));

      if (x_lock_count <> 0) then
        rollback;
        error_code := BASE_ERROR + 22;
        goto acquire_error;
      end if;

      /* Acquire resource locks here */
      update ad_working_res_locks set date_acquired = sysdate
        where session_id = x_session_id and in_process_flag = 'Y';

      /* Delete duplicate rows */
      delete from ad_working_res_locks where rowid in
             (select w.rowid from ad_working_res_locks w,
                ad_working_res_locks p
              where w.session_id = x_session_id and
                w.session_id = p.session_id and
                   w.resource_code = p.resource_code and
                  w.context = p.context and
                  w.appl_top_id = p.appl_top_id and
                  w.language = p.language and
                  w.extra_context1 = p.extra_context1 and
                  w.extra_context2 = p.extra_context2 and
                  w.extra_context3 = p.extra_context3 and
                  w.rowid <> p.rowid and
                  w.in_process_flag = 'N');

      update ad_working_res_locks set in_process_flag = 'N'
        where session_id = x_session_id and in_process_flag = 'Y';

      update ad_planned_res_locks set done_flag = 'N' where
         session_id = x_session_id and stage_code = x_stage_code;

      update ad_sessions set wait_loop_time = 0
        where session_id = x_session_id;

      commit work;
    exception
      when others then
        rollback;
        error_message := substr(sqlerrm, 1, 100);
        error_code := BASE_ERROR + 19;
        goto acquire_error;
    end;
  end if;

  if (release_admin_flag = 1) then
    /* Release DB admin lock */
    release_admin_lock(lock_status);
    if (lock_status <> 0) then
      warning_code := 2; /* Warning, not at all held the lock */
    end if;
  end if;

  return;

<<acquire_error>>

  if (held_lock = 1) then
    /* Release DB admin lock */
    release_admin_lock(lock_status);
    if (lock_status <> 0) then
      warning_code := 2; /* Warning, not at all held the lock */
    end if;
  end if;

  return;

exception
  when others then
    rollback;
    error_message := substr(sqlerrm, 1, 100);
    error_code := BASE_ERROR + 20; /* Error, unhandled exception */

end acquire_promote_db_locks;


-- Procedure
--     release_demote_db_locks
-- Arguments
--     1) session_id
--     2) stage_code
--     3) acquire_admin_flag  -   If this flag is set to 1,ADMIN lock is
--                                acquired at the beginning.
--                                Otherwise, it is assumed that caller
--                                has already acquired the lock.
--     4) release_admin_flag  -   If this flag is set to 1,ADMIN lock is
--                                released at the end.
--                                Otherwise, it is assumed that caller
--                                will release the lock later. (this
--                                procedure retains ADMIN lock, only if
--                                the return status is success)
--     4) error_code          -   Out parameter
--            0               --> Success
--            BASE_ERROR + 1  --> This stage is already done.
--            BASE_ERROR + 2  --> Invalid argument.
--            BASE_ERROR + 3  --> Exception,reading ad_planned_res_locks
--            BASE_ERROR + 4  --> Inconsistency state (some of the lock
--                                rows have done_flag='Y' and others
--                                have done_flag='N')
--                                It shouldn't happen.
--            BASE_ERROR + 5  --> Exception,reading ad_planned_res_locks
--            BASE_ERROR + 6  --> Unhandled exception
--            BASE_ERROR + 7  --> Lock rows are not prestaged.
--            BASE_ERROR + 8  --> Data error.Demote to 'X' is not valid
--            BASE_ERROR + 9  --> Error, Locks need to be promoted is
--                                not at all held.
--     5) warning_code        -   Out parameter
--             0              --> No warning
--             1              --> ADMIN db lock is held already by this
--                                connection. But an attempt is made to
--                                acquire once again.
--             2              --> ADMIN db lock is not at all held. But
--                                an attempt is made to release it.
--     6) error_message       -   Out parameter
--                            -   SQL errors are returned to the caller
--                                using this variable.
-- Purpose
--     This procedure releases and demotes locks for a stage.
-- Notes

procedure release_demote_db_locks (session_id in number,
                                   stage_code in varchar2,
                                   acquire_admin_flag in number,
                                   release_admin_flag in number,
                                   error_code out nocopy number,
                                   warning_code out nocopy number,
                                   error_message out nocopy varchar2)
is
  type done_flag_t is table of varchar2(1) index by binary_integer;
  x_done_flag             done_flag_t;
  x_stage_code            varchar2(31);
  x_session_id            number;
  held_lock               number;
  x_lock_count            number;
  lock_status             number;
  BASE_ERROR              number;
begin

  BASE_ERROR := 0;
  error_code := 0;   /* No error */
  warning_code := 0; /* No warning */

  held_lock := 0;

  x_session_id := session_id;
  x_stage_code := stage_code;

  /* Validate the arguments passed */
  if (session_id <= 0) then
    error_code := BASE_ERROR + 2; /* Argument error */
    return;
  end if;

  /* Check whether this stage locks have been acquired and
   * released earlier or not. (done_flag -> restart purpose)
   *
   * Are all the prestaged rows for this stage marked as
   * Done (done_flag = 'Y')
   */
  begin
    select distinct  nvl(done_flag,'N') bulk collect into x_done_flag
      from ad_planned_res_locks
      where session_id = x_session_id and
            stage_code = x_stage_code;

    if (x_done_flag.count = 0) then
      error_code := BASE_ERROR + 7;  /* Error, no lock rows
                                      * are prestaged */
      goto release_error;
    end if;

    if (x_done_flag.count <> 1) then
      error_code := BASE_ERROR + 4; /* Error, inconsistancy state,
                                     * it shouldn't happend */
      goto release_error;
    end if;

    if (x_done_flag(1) = 'Y') then
      error_code := BASE_ERROR + 1; /* Special return status, this
                                     * stage is done already */
      goto release_error;
    end if;

  exception
    when others then
      error_message := substr(sqlerrm, 1, 100);
      error_code :=  BASE_ERROR + 5; /* Error, reading
                                      * ad_planned_res_locks */
      goto release_error;
  end;


  if (acquire_admin_flag = 1) then
    /* Acquire ADMIN lock */
    get_admin_lock(lock_status);
    if (lock_status <> 0) then
      warning_code := 1; /* Warning, this connection
                          * holds the lock already */
    end if;
  end if;

  held_lock := 1; /* Lock is held */

  /* Release or Demote locks */
  begin
    if (x_stage_code is not null) then

      delete from ad_working_res_locks where (
        resource_code || ':' || context || ':' || appl_top_id || ':' ||
        language || ':' || extra_context1 || ':' ||
        extra_context2 || ':' || extra_context3
        in
        (select  wl.resource_code || ':' || wl.context || ':' ||
                 wl.appl_top_id || ':' || wl.language || ':' ||
                 wl.extra_context1 || ':' || wl.extra_context2 || ':' ||
                 wl.extra_context3
        from ad_planned_res_locks wl
        where session_id = x_session_id and
              stage_code = x_stage_code and
              action_flag in ('B', 'R')) and
        session_id = x_session_id
        );

      select count(*) into x_lock_count from ad_planned_res_locks
        where session_id = x_session_id and
              stage_code = x_stage_code and
              action_flag = 'D' and
              lock_mode = 'X';

      if (x_lock_count <> 0) then
        rollback;
        error_code :=  BASE_ERROR + 8; /* Error, Data Error
                                        * check prestage rows */
        goto release_error;
      end if;

      select count(*) into x_lock_count from ad_planned_res_locks
        where session_id = x_session_id and
              stage_code = x_stage_code and
              action_flag = 'D';

      update ad_working_res_locks set lock_mode = 'S' where (
        resource_code || ':' || context || ':' || appl_top_id || ':' ||
        language || ':' || extra_context1 || ':' ||
        extra_context2 || ':' || extra_context3
        in
        (select  wl.resource_code || ':' || wl.context || ':' ||
                 wl.appl_top_id || ':' || wl.language || ':' ||
                 wl.extra_context1 || ':' || wl.extra_context2 || ':' ||
                 wl.extra_context3
        from ad_planned_res_locks wl
        where session_id = x_session_id and
              stage_code = x_stage_code and
              action_flag = 'D') and
        session_id = x_session_id);

      if (sql%rowcount <> x_lock_count) then
        rollback;
        error_code :=  BASE_ERROR + 9; /* Error, Data Error
                                        * check prestage rows */
        goto release_error;
      end if;

      update ad_planned_res_locks set done_flag = 'Y' where
             session_id = x_session_id and stage_code = x_stage_code;
    else
      delete from ad_working_res_locks where session_id = x_session_id;
    end if;
    commit;
  exception
    when others then
      rollback;
      error_message := substr(sqlerrm, 1, 100);
      error_code := BASE_ERROR + 3; /* Error, reading
                                     * ad_planned_res_locks */
      goto release_error;
  end;

  if (release_admin_flag = 1) then
    /* Release DB admin lock */
    release_admin_lock(lock_status);
    if (lock_status <> 0) then
      warning_code := 2; /* Warning, not at all held the lock */
    end if;
  end if;

  commit;
  return;

<<release_error>>

  if (held_lock = 1) then
    /* Release DB admin lock */
    release_admin_lock(lock_status);
    if (lock_status <> 0) then
      warning_code := 2; /* Warning, not at all held the lock */
    end if;
  end if;

  return;

exception
  when others then
    rollback;
    error_message := substr(sqlerrm, 1, 100);
    error_code := BASE_ERROR + 6; /* Error, unhandled exception */

end release_demote_db_locks;
--
--
procedure set_task_completed(p_session_id        in number ,
                             p_task_id           in number ,
                             p_completion_status in varchar2,
                             p_end_stage_cd      in varchar2,
                             p_begin_stage_cd    in varchar2)
is
begin
--
--
  DELETE FROM AD_PLANNED_RES_LOCKS
  WHERE SESSION_ID =  p_session_id  AND
        STAGE_CODE <> p_end_stage_cd AND
        STAGE_CODE <> p_begin_stage_cd;
--
--
  UPDATE AD_SESSION_TASKS
  SET COMPLETION_STATUS = p_completion_status,
      END_DATE          = sysdate ,
      LAST_UPDATE_DATE  = sysdate
  where   session_id  = p_session_id  and
          task_number = p_task_id;
--
--
  commit;
--
--
 return;
--
--
end  set_task_completed;
--
--
procedure mv_sessinfo_to_history(p_sess_id in number,
                                 p_complete_status in varchar2,
                                 p_error_code out nocopy number)
is
  row_count number;
begin
--
--
 p_error_code := 0;

 INSERT INTO AD_SESSIONS_HISTORY
 ( SESSION_ID, UTILITY_NAME, APPL_TOP_PATH,
   RUN_ON_NODE, INVOKDIR, STATUS, PRIORITY,
   CONTEXT_INFO, ANY_CHANGE_WHILE_INACTIVE_FLAG, LOCKS_OVERRIDDEN_BY,
   JS_TOTAL_JOBS, JS_COMPLETED_JOBS, JS_REMAINING_JOBS,
   COMPLETION_STATUS,
   START_DATE, END_DATE, CREATION_DATE, LAST_UPDATE_DATE, TOPDIR
  )
  SELECT
    SESSION_ID,UTILITY_NAME, APPL_TOP_PATH,
    RUN_ON_NODE, INVOKDIR, STATUS, PRIORITY,
    CONTEXT_INFO, ANY_CHANGE_WHILE_INACTIVE_FLAG, LOCKS_OVERRIDDEN_BY,
    JS_TOTAL_JOBS, JS_COMPLETED_JOBS,JS_REMAINING_JOBS,
    p_complete_status,
    START_DATE,SYSDATE, CREATION_DATE, LAST_UPDATE_DATE, TOPDIR
 FROM
    AD_SESSIONS
 WHERE
    SESSION_ID=p_sess_id;

 row_count := sql%rowcount;
 if row_count = 0  then
    p_error_code := 1;
  end if;
--
--
 DELETE FROM AD_SESSIONS
 WHERE session_id = p_sess_id;
--
--
 INSERT INTO AD_SESSION_TASKS_HISTORY
 (SESSION_ID,TASK_NUMBER,COMPLETION_STATUS,
  CONTEXT   ,START_DATE ,END_DATE,CREATION_DATE,
  LAST_UPDATE_DATE)
  SELECT
    SESSION_ID,TASK_NUMBER,COMPLETION_STATUS,
    CONTEXT   ,START_DATE , nvl(END_DATE,SYSDATE),SYSDATE,
    SYSDATE
  from
    AD_SESSION_TASKS
  where
    SESSION_ID=p_sess_id;
--
--
 DELETE FROM AD_SESSION_TASKS
 WHERE session_id = p_sess_id;
--
--
 commit;
--
--
 return;
--
end mv_sessinfo_to_history;
--
--
end ad_conc_session_locks;
