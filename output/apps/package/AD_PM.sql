
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PM" AUTHID DEFINER AS
/* $Header: ADPMS.pls 120.0.12020000.4.1221400.3 2022/10/05 05:04:45 vpalakur noship $ */

/* functions and procedures */
function is_pm_enabled return boolean result_cache;
function show_pm_enabled return varchar2;
function patch_status return varchar2;
function start_time return TIMESTAMP WITH TIME ZONE;
function drain_time return interval day to second;
function batch_status return varchar2;
function is_draining_session return boolean;
function show_draining_session return varchar2;
function is_patched return boolean;
function show_patched return varchar2;
function patch_method return varchar2;

end AD_PM;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PM" AS
/* $Header: ADPMB.pls 120.0.12020000.3.1221400.3 2022/10/05 05:06:10 vpalakur noship $ */

/* functions and procedures */
function is_pm_enabled return boolean result_cache is
  l_ret_value boolean := FALSE;
begin
  return l_ret_value;
end;

function show_pm_enabled return varchar2 is
begin
  if (is_pm_enabled) then
    return 'true';
  else
    return 'false';
  end if;
end;

function patch_status return varchar2 is
begin
  return 'NORMAL';
end;

function start_time return TIMESTAMP WITH TIME ZONE is
begin
  return NULL;
end;

function drain_time return interval day to second is
begin
  return NULL;
end;

function batch_status return varchar2 is
begin
  return NULL;
end;

function is_draining_session return boolean is
begin
  return NULL;
end;

function show_draining_session return varchar2 is
begin
  return NULL;
end;

function is_patched return boolean is
begin
  return NULL;
end;

function show_patched return varchar2 is
begin
  return NULL;
end;

function patch_method return varchar2 is
begin
  return NULL;
end;

end AD_PM;
