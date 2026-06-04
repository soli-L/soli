
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_DB_UTILS" AUTHID DEFINER AS
/* $Header: ADDBUTILSS.pls 120.0.12020000.4 2021/03/24 09:31:07 rsatyava noship $ */

function IS_ADB return varchar2;

function GET_EBS_PATCH_SERVICE return varchar2;

procedure CREATE_PATCH_SERVICE;

end AD_DB_UTILS;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_DB_UTILS" AS
/* $Header: ADDBUTILSB.pls 120.0.12020000.7 2021/07/01 03:01:23 rsatyava noship $ */


-- log shortcut
procedure log(x_module    varchar2,
              x_log_type  varchar2,
              x_message   varchar2 ) is
begin
  ad_zd_log.Message( x_module=>x_module, x_log_type => x_log_type, x_message => x_message );
end;


/*
** Is this Autonomous Database or not
** If sys_context ('userenv','cloud_service') returns paas then 'Y' else 'N'
** Waiting for ST bug#32113494 fix - API TO DETERMINE AUTONOMOUS DATABASE SERVICE AND ITS TYPE
**
** Bug 32633139 - Don't add logging to this as this is a utility routine
*/
function IS_ADB return varchar2
is
L_MODULE        							    varchar2(80) := 'ad.plsql.ad_db_utils.is_adb';
L_IS_ADB        							    varchar2(1)  := 'N';
INVALID_USERENV_PARAM_ERROR 			exception;
pragma exception_init(invalid_userenv_param_error, -2003);
begin
	begin

		case sys_context ('userenv','cloud_service')
		when 'paas' then l_is_adb := 'Y';
		else  l_is_adb :='N';
		end case;

  exception
	  when invalid_userenv_param_error then
		  return 'N';
		when others then
			raise_application_error(-20001, 'Unable to get userenv parameter cloud_service.');
	end;

	return l_is_adb;
end IS_ADB;



function GET_EBS_PATCH_SERVICE return varchar2
is
  L_PATCH_SERVICE varchar2(255);
  L_DBDOMAIN      varchar2(128) := sys_context('userenv', 'db_domain');
begin
  --- Get "<db-name>_ebs_patch" service name from context file.
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
--    - adop: database validations (ad_zd_adop.adop_database_validations)
--
procedure CREATE_PATCH_SERVICE
is
  L_MODULE        			varchar2(80) := 'ad.plsql.ad_db_utils.create_patch_service';
  L_EXISTS        			number;
  L_DBDOMAIN      			varchar2(128) := sys_context('userenv', 'db_domain');
  l_patch_service 			varchar2(255);
	L_IS_ADB        			varchar2(1);
	L_DBMS_SERVICE_STMT   varchar2(500);

begin
  log(l_module, 'PROCEDURE', 'begin');

	-- Only for Non ADB-D environments
	if(is_adb='N') then
		l_patch_service := get_ebs_patch_service;

		-- Since service name is case-insensitive, even sqlplus accepts that.
		begin
			select 1 into l_exists
			from  dba_services
			where upper(name)=upper(l_patch_service);
		exception
			when no_data_found then
				log(l_module, 'EVENT', 'Creating ' || l_patch_service || ' database service');
				l_dbms_service_stmt := 'begin dbms_service.create_service(:1, :2); end; ';
				execute immediate l_dbms_service_stmt using l_patch_service,l_patch_service;
		end;

		-- start patch service if needed
		begin
			select 1 into l_exists
			from   sys.v_$active_services
			where upper(name)=upper(l_patch_service);
		exception
			when no_data_found then
				log(l_module, 'EVENT', 'Starting ' || l_patch_service || ' database service');
				l_dbms_service_stmt := 'begin dbms_service.start_service(:1); end; ';
				execute immediate l_dbms_service_stmt using l_patch_service;
		end;
	else
    log(l_module, 'STATEMENT', 'This is ADB-D instance,so no action w.r.t patch service');
	end if;

  log(l_module, 'PROCEDURE', 'end');
end CREATE_PATCH_SERVICE;


end AD_DB_UTILS;
