
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PM_ADMIN" AUTHID DEFINER AS
/* $Header: ADPMADMINS.pls 120.0.12020000.2.1221500.2 2023/04/03 07:16:01 rsatyava noship $ */

/* functions and procedures */

procedure set_lead_time(p_lead_time in varchar2);
procedure set_lead_time(p_lead_time in interval day to second);
function  get_lead_time return interval day to second;
procedure set_patch_method(p_patch_method in varchar2);
function  get_patch_method return varchar2;
procedure set_drain_time(p_drain_time in binary_integer);
function  get_drain_time return number;

end AD_PM_ADMIN;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PM_ADMIN" AS
/* $Header: ADPMADMINB.pls 120.0.12020000.2.1221500.3 2023/04/04 14:37:01 rsatyava noship $ */

/* functions and procedures */

procedure set_lead_time(p_lead_time in varchar2) is
begin
  null;
end;

procedure set_lead_time(p_lead_time in interval day to second) is
begin
   null;
end;

function get_lead_time return interval day to second is
begin
  return null;
end;

procedure set_patch_method(p_patch_method in varchar2) is
begin
  null;
end;

function get_patch_method return varchar2 is
begin
  return null;
end;

procedure set_drain_time(p_drain_time in binary_integer) is
begin
  null;
end;

function get_drain_time return number is
begin
  return null;
end;

end AD_PM_ADMIN;
