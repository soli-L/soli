
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PA_VALIDATE_CRITERIASET" AUTHID CURRENT_USER as
/* $Header: adpavacs.pls 120.1 2005/08/12 03:23:50 appldev noship $*/

Procedure validate_criteriaset(p_advisor_criteria_id  varchar2);

/* This function returns comma separated patches in column Merged_patches in PatchSummary page . Bug # 2813894 -KKSINGH */
function get_concat_mergepatches(p_ptch_drvr_id number) return varchar2;

/* This function  detemines to enable or disable Details Image in Action Summary page. Bug # 2803063 -KKSINGH */
function get_jobtiming_details(p_action_id number, p_program_run_id number, p_session_id number)
         return number ;

/* This function returns comma separated MiniPacks in column MiniPacks in PatchDetails page . Bug # 2803063 -KKSINGH */

function get_concat_minipks(p_ptch_drvr_id number) return varchar2;

/* This function returns comma separated product family desc for a give product abbr */
function get_cs_prod_fam_name(p_product_abbr varchar2) return varchar2;

/* This function returns comma separated product family abbr for a give product abbr */
function get_cs_prod_fam_abbr(p_product_abbr varchar2) return varchar2;

pragma restrict_references(get_concat_minipks, WNDS, WNPS);

end ad_pa_validate_criteriaset;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PA_VALIDATE_CRITERIASET" as
/* $Header: adpavacb.pls 120.3 2005/10/06 05:31:19 tjohn ship $ */

Procedure validate_criteriaset(p_advisor_criteria_id  varchar2 )
IS

 l_count number :=0;

 BEGIN

  begin
   select count(1) into l_count from AD_PA_CRITERIA
     where advisor_criteria_id = LTRIM(RTRIM((p_advisor_criteria_id)));
     --where upper(advisor_criteria_id) = LTRIM(RTRIM(UPPER(p_advisor_criteria_id)));
    if l_count > 0 then
      -- FND_MESSAGE.CLEAR;
      -- FND_MESSAGE.SET_NAME(application=>'AD', name=>'AD_DUP_AC_MSG');
       raise_application_error(-20101, 'Duplicate Advisor Criteria Name. Please click on Browser Back arrow and enter a different name. ');

    end if;
  end;
end validate_criteriaSet;


/* This function returns comma separated patches in column Merged_patches in PatchSummary page . Bug # 2813894 -KKSINGH */

function get_concat_mergepatches(p_ptch_drvr_id number)
         return varchar2 is

  l_concat_bugNumber   varchar2(4096);
  l_first_iter         boolean;          -- first iteration flag
  l_rem_space          number :=0;       -- remaining space
  l_len_till_now       number :=0;       -- length of l_concat_bugid

  cursor c1(p_patch_driver_id number) is
  --tjohn - 14-SEP-2005 - Bug# 4574467  Changed cursor c1 to have join between two tables and avoid the IN caluse for improved performance.
	  SELECT
	      bug_number
	     FROM
	      ad_bugs ab,
	      ad_comprising_patches acp
	     WHERE
	      ab.bug_id   = acp.bug_id  and
	      acp.patch_driver_id = p_patch_driver_id;

  begin
  l_concat_bugNumber   := null;
  l_first_iter         := TRUE;


  for c1_rec in c1(p_ptch_drvr_id) loop
    if (l_first_iter)
    then
      l_concat_bugNumber   := c1_rec.bug_number;
      l_first_iter         := FALSE;
      l_len_till_now       :=length(l_concat_bugNumber);

    else
      l_rem_space :=(4096 - l_len_till_now);

      -- 2 spaces must ALWAYS be available whenever we are about
      -- to make this determination.

      if (l_rem_space > length(c1_rec.bug_number) + 2)
      then
        l_concat_bugNumber := l_concat_bugNumber || ', '||
                            c1_rec.bug_number;
        -- Maintain l_len_till_now (Note: 2 is for the comma and space)
        l_len_till_now := l_len_till_now + 2 +
                          length(c1_rec.bug_number);
      else
        -- not enough space, show error message
           raise_application_error(-20500,'The total of merged patches exceed the display limit. Contact Oracle Support group.');
        exit;
      end if;
    end if;
  end loop;
  return l_concat_bugNumber;
end get_concat_mergepatches;


function get_concat_minipks(p_ptch_drvr_id number)
         return varchar2 is

  l_concat_minipks varchar2(4096); /* intentionally having it 4K to handle
                                  the minipacks in Maintenance pack */
  l_first_iter     boolean;      -- first iteration flag

  l_rem_space        number :=0;  -- remaining space

  l_len_till_now       number :=0;  -- length of l_concat_minipks till now


cursor c1(p_patch_driver_id number) is
  select patch_level
  from   ad_patch_driver_minipks
  where  patch_driver_id = p_patch_driver_id;
begin
  l_concat_minipks := null;
  l_first_iter     := TRUE;

  for c1_rec in c1(p_ptch_drvr_id) loop
    if (l_first_iter)
    then
      l_concat_minipks := c1_rec.patch_level;
      l_first_iter     := FALSE;
      l_len_till_now   :=length(l_concat_minipks);
    else
      l_rem_space :=(4096 - l_len_till_now);

      -- if no space avail, we want to add ", ...". This means that
      -- 5 spaces must ALWAYS be available whenever we are about
      -- to make this determination. This implies that we
      -- always check for len(<patch-level>) + 5, even though we
      -- we only intend to append <patch-level>.

      if (l_rem_space > length(c1_rec.patch_level) + 5)
      then
        l_concat_minipks := l_concat_minipks || ', '||
                            c1_rec.patch_level;
        -- Maintain l_len_till_now (Note: 2 is for the comma and space)
        l_len_till_now := l_len_till_now + 2 +
                          length(c1_rec.patch_level);
      else
        -- not enough space, just append ", ..." and break the loop
        l_concat_minipks := l_concat_minipks || ', ...';
        exit;
      end if;
    end if;
  end loop;
  return l_concat_minipks;
end get_concat_minipks;


-- New function for ActionDetails
-- Based on the value returned from this function, the status of Details Image in ActionSummary page will be decided for enable or disable
function get_jobtiming_details(p_action_id number, p_program_run_id number, p_session_id number)
         return number is
   l_number   number := 0;

 BEGIN
  select count(*) into l_number from
  ad_program_run_task_jobs prtj,
  ad_files ldr_f,
  ad_files f,
  ad_patch_common_actions pca,
  ad_patch_run_bug_actions prba
where prba.action_id = p_action_id
and prba.common_action_id = pca.common_action_id
and prba.file_id = f.file_id
and pca.loader_data_file_id = ldr_f.file_id (+)
and nvl(ldr_f.filename, f.filename) = prtj.job_name
and UPPER(nvl(ldr_f.app_short_name, f.app_short_name)) = UPPER(prtj.product)
and nvl(prtj.arguments,'NA') = nvl(pca.action_arguments,'NA') -- Bug# (3443373)-KKS
and prtj.program_run_id = p_program_run_id
and prtj.session_id = p_session_id
and prtj.phase_name=pca.action_phase
and (pca.ACTION_ARGUMENTS is not null or
     pca.ACTION_WHAT_SQL_EXEC is not null or
     pca.ACTION_CHECK_OBJ_USERNAME is not null or
     pca.ACTION_CHECK_OBJ is not null or
     pca.ACTION_CHECK_OBJ_PASSWD is not null or
     prtj.start_time is not null or
     prtj.restart_time is not null or
     prtj.end_time is not null or
     prtj.restart_count is not null or
     prtj.elapsed_time  is not null ) ;

    if l_number = 0 then
      return  0;
    else
     return 1 ;
  end if;
end get_jobtiming_details;

function get_cs_prod_fam_name(p_product_abbr varchar2) return varchar2 is

  l_concat_prod_fam varchar2(200) := '';

  cursor c1(l_product_abbr varchar2) is
  select product_name
  from  ad_pm_prod_family_map appfm, ad_pm_product_info appi
  where appfm.product_family_abbreviation = appi.product_abbreviation
  and   appfm.product_abbreviation = l_product_abbr;

begin

  for c1_rec in c1(p_product_abbr) loop
    if(length(l_concat_prod_fam) > 0) then
      l_concat_prod_fam := l_concat_prod_fam || ', '||
                         c1_rec.product_name;
    else
      l_concat_prod_fam := c1_rec.product_name;
    end if;
  end loop;
  return l_concat_prod_fam;
end get_cs_prod_fam_name;

function get_cs_prod_fam_abbr(p_product_abbr varchar2) return varchar2 is

  l_concat_prod_fam varchar2(200) := '';

  cursor c1(l_product_abbr varchar2) is
  select product_family_abbreviation
  from  ad_pm_prod_family_map appfm
  where appfm.product_abbreviation = l_product_abbr;

begin

  for c1_rec in c1(p_product_abbr) loop
    if(length(l_concat_prod_fam) > 0) then
      l_concat_prod_fam := l_concat_prod_fam || ', '||
                         c1_rec.product_family_abbreviation;
    else
      l_concat_prod_fam := c1_rec.product_family_abbreviation;
    end if;
  end loop;
  return l_concat_prod_fam;
end get_cs_prod_fam_abbr;


END ad_pa_validate_criteriaset;
