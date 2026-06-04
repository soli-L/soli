
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_ZD_LOG" AUTHID CURRENT_USER AS
/* $Header: ADZDLOGS.pls 120.6.12020000.2 2015/04/16 09:35:06 rraam ship $ */


-- Log's the actual message into ad_zd_log table
-- x_log_type should be one of the following:
--   STATEMENT: useful/detail
--   PROCEDURE: begin/end
--   EVENT:     something normal happened
--   ERROR:     something bad happened
-- For more detailed information, see comments in ADZDLOGB.pls
procedure message( X_MODULE     in varchar2,
                   X_LOG_TYPE   in VARCHAR2,
                   X_MESSAGE    in VARCHAR2,
                   X_NODE_NAME  in VARCHAR2 default NULL) ;


-- Truncate's AD_ZD_LOG
procedure clear;

END ad_zd_log;
CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_ZD_LOG" AS
/* $Header: ADZDLOGB.pls 120.11.12020000.8 2021/01/24 18:47:17 mkumandu ship $ */

--  create table APPLSYS.AD_ZD_LOG (
--          LOG_SEQUENCE NOT NULL NUMBER,
--          MODULE       NOT NULL VARCHAR2(255),
--          MESSAGE_TEXT NOT NULL VARCHAR2(4000),
--          SESSION_ID   NUMBER,
--          TYPE         VARCHAR2(10),
--          TIMESTAMP    TIMESTAMP  )'
--
--
--


-- procedure:
--   message()
-- parameters:
--   x_module - varchar2 - calling code identifier (calling module)
--   x_log_type - varchar2 - the type of message being logged (see below)
--   x_message - varchar2 - the message being logged into the table
--   x_node_name - varchar2 - the node name of the client from which the
--                              API is called.
-- purpose:
--   Insert record into ad_zd_logs table
-- more on x_log_type:
--   This specifies the "level" of the log message. This is used to clarify
--   log messages by level of detail so that extraneous information can be
--   filtered from summary reports. ALL log messages are logged ALL the time
--   and there is no filtering of any kind, so please be careful to not
--   overlog. Although everything gets logged regardless of what is passed in
--   for this parameter, you SHOULD use one of the below defined level codes.
-- level codes:
--   STATEMENT: Detailed information that might be helpful. Message should
--     show some detail that will be useful in debugging.
--   PROCEDURE: Used to mark beginning and ending of high level procedures.
--     Should be: "begin: <key arguments>' or 'end'
--   EVENT: Used to record a significant state change - ie. dropping an index.
--     Use English (not SQL) - example: 'Dropping unused column: <name>'
--   WARNING: Internal warning. DO NOT USE THIS!!!
--   ERROR: Some action failed. Message should state the problem, identify
--     the specific object that was being changed (if applicable). Be careful
--     using this as this message will be shown to system operators.
--   UNEXPECTED: Something terrible happened. DO NOT USE THIS!!!
--
-- more on x_node_name:
--   This is used tot rack the node from which the statement is logged.
--   It is obtained as follows:
--     The value passed as parameter to the API
--     If not check the value set as HOSTNAME in context AD_ZD_CTX
--     If not get it from SYS_CONTEXT and fetch the HOST value and remove domain information from it.
 procedure message( x_module    varchar2,
                    x_log_type  varchar2,
                    x_message   varchar2,
                    x_node_name varchar2 default NULL ) is
   pragma autonomous_transaction;
   l_applsys   varchar2(30);
   l_message   varchar2(4000);
   l_module    varchar2(255);
   l_type      varchar2(10);
   l_node_name varchar2(256);
   l_ddl_id    number;
  BEGIN

   l_message   := SUBSTR(x_message,1, 3999);
   l_module    := SUBSTR(x_module,1, 254);
   l_type      := SUBSTR(x_log_type, 1, 10);
   l_node_name := SUBSTR(x_node_name,1, 256);

   if(l_node_name is NULL)
   then
     l_node_name:=sys_context('AD_ZD_CTX','HOSTNAME');
     if(l_node_name is NULL)
     then
       -- Reading the HOST variable from SYS_CONTEXT
       SELECT SYS_CONTEXT('USERENV','HOST') into l_node_name from dual;
       -- Removing the domain information from hostname
       SELECT  substr(l_node_name, 1, decode(instr(l_node_name,'.',1,1),
                                                   0, length(l_node_name),
                                                   instr(l_node_name,'.',1,1)-1))
       into l_node_name from dual;
     end if;
   end if;

   l_ddl_id:=sys_context('AD_ZD_CTX','DDL_ID');

   insert into ad_zd_logs
        ( log_sequence,
          module,
          message_text,
          session_id,
          type ,
          timestamp,
          node_name,
          ddl_id)
   values (AD_ZD_LOGS_S.NEXTVAL,
           l_module,
           l_message,
           SYS_CONTEXT('USERENV', 'SESSIONID'),
           l_type,
           current_timestamp,
           l_node_name,
           l_ddl_id);
   commit;
 END message;

-- procedure:
--   clear()
-- parameters:
--   none
-- purpose:
--   to truncate the log file.
-- notes:
--   will delete EVERYTHING - so be careful
 procedure clear is
  pragma autonomous_transaction;
  l_applsys varchar2(30);
 BEGIN

  select oracle_username into l_applsys
    from ebs_system.fnd_oracle_userid
    where  read_only_flag in ('E')
      and rownum < 2 ;

  execute immediate 'truncate table ' || l_applsys || '.ad_zd_logs';
  commit;

 end clear;

end ad_zd_log;