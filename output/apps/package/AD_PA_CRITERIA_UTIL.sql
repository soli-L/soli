
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PA_CRITERIA_UTIL" AUTHID CURRENT_USER as
/* $Header: adpaseds.pls 115.2 2003/11/21 03:08:43 kksingh ship $ */

  procedure update_rp;
  procedure update_nc;
  procedure update_rpandnc;
  procedure update_all;
end;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PA_CRITERIA_UTIL" as
/* $Header: adpasedb.pls 120.2.12020000.2 2014/05/08 20:18:39 tshort ship $ */
-- This procedure is to seed data for Recommended Patches in ad_pa_criteria and ad_pa_criteria_prod_fams table
 procedure update_rp
is
  l_advisor_criteria_id          ad_pa_criteria.ADVISOR_CRITERIA_ID%TYPE;
  l_pre_seeded                   ad_pa_criteria.pre_seeded_flag%TYPE;
  l_last_update_date             date;
  l_created_by                   number;
begin
  l_last_update_date             := sysdate;
  -- This package is called by Autopatch program when AD-OAM Module is being installed
  -- Check if this criteria set (criteria_id and pre_seeded flag) exists
  -- in ad_pa_advisor_criteria (create if not exists)
  --
  -- Then delete rows from ad_pa_criteria_prod_fams.
  --
  -- For all products in FND_PRODUCT_INSTALLATIONS with status='I' and 'S'
  --   create row in ad_pa_criteria_prod_fams for this
  --   criteria set and product Family with Recommended Patches flag and licensed flag set Y and other flags N
  --
  -- For all products in FND_PRODUCT_INSTALLATIONS with status != 'I' and 'S'
  --   create row in ad_pa_criteria_prod_fams for this
  --   criteria set and product Family with Recommended Patches flag set Y and other flags N including licensed flag
  --
  -- Change last_update_date for this criteria set in ad_pa_advisor_criteria
  --
  begin
    select advisor_criteria_id, pre_seeded_flag, created_by  into l_advisor_criteria_id,
     l_pre_seeded, l_created_by
      from AD_PA_CRITERIA
       where advisor_criteria_id ='Recommended Maintenance Patches'
        and pre_seeded_flag = 'Y';
    --dbms_output.put_line('before exception');

    if (l_created_by <> 2) then
      update AD_PA_CRITERIA
      set created_by = 2, last_updated_by = 2
      where advisor_criteria_id ='Recommended Maintenance Patches'
      and pre_seeded_flag = 'Y';
    end if;
  exception
   when no_data_found then

    insert into AD_PA_CRITERIA
      (advisor_criteria_id, advisor_criteria_description,pre_seeded_flag,
      creation_date,last_update_date,last_updated_by,created_by)
    values('Recommended Maintenance Patches','Recommended patches for current release','Y',sysdate,sysdate,2,2);

  end;


  begin
   delete from ad_pa_criteria_prod_fams
    where advisor_criteria_id = 'Recommended Maintenance Patches';

	 insert into ad_pa_criteria_prod_fams
    (PRODUCT_FAMILY_ABBREVIATION,ADVISOR_CRITERIA_ID,RECOMMENDED_PATCH_FLAG,NEW_CODE_LEVEL_FLAG,LICENSED_FLAG,
	  CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY)
   select distinct pfm.product_family_abbreviation,'Recommended Maintenance Patches','Y','N','Y',sysdate,1,sysdate,1
	  from fnd_product_installations fpi, fnd_application a,
			ad_pm_product_info pi, ad_pm_prod_family_map pfm
		where fpi.status in ('S', 'I')
     and fpi.application_id = a.application_id
     and a.application_short_name= pi.application_short_name
     and pi.PSEUDO_PRODUCT_FLAG='N'
     and pi.product_abbreviation = pfm.product_abbreviation ;


     begin
     insert into ad_pa_criteria_prod_fams
    (PRODUCT_FAMILY_ABBREVIATION,ADVISOR_CRITERIA_ID,RECOMMENDED_PATCH_FLAG,NEW_CODE_LEVEL_FLAG,LICENSED_FLAG,
	  CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY)
   select distinct pi.product_abbreviation,'Recommended Maintenance Patches', 'Y', 'N', 'N',sysdate, 1, sysdate, 1
    from ad_pm_product_info pi
     where pi.pseudo_product_flag='Y'
      and pi.product_family_flag='Y'
      and not exists
       (select 'X' from ad_pa_criteria_prod_fams adf
        where adf.product_family_abbreviation= pi.product_abbreviation
         and adf.advisor_criteria_id='Recommended Maintenance Patches');
	   end;

      BEGIN
      DECLARE
      	cursor prod_family is
		     select pi.PRODUCT_FAMILY_ABBREVIATION adi_prod_abbr, pfm.product_family_abbreviation adp_prod_abbr  from ad_pm_product_info pi, ad_pa_criteria_prod_fams pfm
		      where  pfm.PRODUCT_FAMILY_ABBREVIATION = pi.PRODUCT_FAMILY_ABBREVIATION
            and  pfm.ADVISOR_CRITERIA_ID ='Recommended Maintenance Patches' for update of pfm.product_family_abbreviation;
		          prod_abb prod_family%ROWTYPE;
	            begin
	            for prod_abb in prod_family
	              loop
		             update ad_pa_criteria_prod_fams
	               	set product_family_abbreviation = prod_abb.adi_prod_abbr
                   where current of prod_family;
                end loop;
              end;
          end;

	exception
   when dup_val_on_index then
    raise_application_error(-20001,
     'Attempting to insert a duplicate record '||
       'into AD_PA_CRITERIA_PROD_FAMS advisor_criteria_id =  '
         || l_advisor_criteria_id || ' and pre_seeded_flag '||
           l_pre_seeded);
  end;

  update ad_pa_criteria
   set last_update_date = l_last_update_date
    where advisor_criteria_id ='Recommended Maintenance Patches';
end update_rp;

-- This procedure is to seed data for New Code Levels in ad_pa_criteria and ad_pa_criteria_prod_fams table
procedure update_nc
is
  l_advisor_criteria_id          ad_pa_criteria.ADVISOR_CRITERIA_ID%TYPE;
  l_pre_seeded                   ad_pa_criteria.pre_seeded_flag%TYPE;
  l_last_update_date             date;
  l_created_by                   number;
 begin
  l_last_update_date             := sysdate;
  --
  -- This package is called by Autopatch program when AD-OAM Module is being installed
  -- Check if this criteria set (criteria_id and pre_seeded flag) exists
  -- in ad_pa_advisor_criteria (create if not exists)
  --
  -- Then delete rows from ad_pa_criteria_prod_fams.
  --
  -- For all products in FND_PRODUCT_INSTALLATIONS with status='I' and 'S'
  --   create row in ad_pa_criteria_prod_fams for this
  --   criteria set and product Family with New Code Levels flag and licensed flag set Y and other flags N
  --
  -- For all products in FND_PRODUCT_INSTALLATIONS with status != 'I' and 'S'
  --   create row in ad_pa_criteria_prod_fams for this
  --   criteria set and product Family with New Code Levels flag set Y and other flags N including licensed flag
  --
  -- Change last_update_date for this criteria set in ad_pa_advisor_criteria
  --
   begin
    select advisor_criteria_id, pre_seeded_flag, created_by  into l_advisor_criteria_id,
     l_pre_seeded, l_created_by
      from AD_PA_CRITERIA
      where advisor_criteria_id ='Consolidated Maintenance Patches'
       and pre_seeded_flag = 'Y';

    if (l_created_by <> 2) then
      update AD_PA_CRITERIA
      set created_by = 2, last_updated_by = 2
      where advisor_criteria_id ='Consolidated Maintenance Patches'
       and pre_seeded_flag = 'Y';
    end if;

   exception
    when no_data_found then
      insert into AD_PA_CRITERIA
       (advisor_criteria_id, advisor_criteria_description,pre_seeded_flag,
       creation_date,last_update_date,last_updated_by,created_by)
     values('Consolidated Maintenance Patches','Consolidated patches and new features for current release','Y',sysdate,sysdate,2,2);
   end;

   begin
    delete from ad_pa_criteria_prod_fams
     where advisor_criteria_id = 'Consolidated Maintenance Patches';

     insert into ad_pa_criteria_prod_fams
    (PRODUCT_FAMILY_ABBREVIATION,ADVISOR_CRITERIA_ID,RECOMMENDED_PATCH_FLAG,NEW_CODE_LEVEL_FLAG,LICENSED_FLAG,
	  CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY)
    select distinct pfm.product_family_abbreviation,'Consolidated Maintenance Patches','N','Y','Y',sysdate,1,sysdate,1
	   from fnd_product_installations fpi, fnd_application a,
			ad_pm_product_info pi, ad_pm_prod_family_map pfm
		   where fpi.status in ('S', 'I')
        and fpi.application_id = a.application_id
        and a.application_short_name= pi.application_short_name
        and  pi.PSEUDO_PRODUCT_FLAG='N'
        and pi.product_abbreviation = pfm.product_abbreviation ;
    begin
     insert into ad_pa_criteria_prod_fams
     (PRODUCT_FAMILY_ABBREVIATION,ADVISOR_CRITERIA_ID,RECOMMENDED_PATCH_FLAG,NEW_CODE_LEVEL_FLAG,LICENSED_FLAG,
	   CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY)
      select distinct pi.product_abbreviation,'Consolidated Maintenance Patches', 'N', 'Y', 'N',sysdate, 1, sysdate, 1
      from ad_pm_product_info pi
       where pi.pseudo_product_flag='Y'
        and pi.product_family_flag='Y'
        and not exists
        (select 'X' from ad_pa_criteria_prod_fams adf
         where adf.product_family_abbreviation= pi.product_abbreviation
          and adf.advisor_criteria_id='Consolidated Maintenance Patches');
	   end;

      BEGIN
      DECLARE
      	cursor prod_family is
		   select adi.PRODUCT_FAMILY_ABBREVIATION adi_prod_abbr, adp.product_family_abbreviation adp_prod_abbr  from ad_pm_product_info adi, ad_pa_criteria_prod_fams adp
		   where  adp.PRODUCT_FAMILY_ABBREVIATION = adi.PRODUCT_FAMILY_ABBREVIATION
        and  adp.ADVISOR_CRITERIA_ID ='Consolidated Maintenance Patches' for update of adp.product_family_abbreviation;
		     prod_abb prod_family%ROWTYPE;
	      begin
	      for prod_abb in prod_family
	       loop
		      update ad_pa_criteria_prod_fams
		       set product_family_abbreviation = prod_abb.adi_prod_abbr
          where current of prod_family;
  		   end loop;
     end;
    end;

  exception
   when dup_val_on_index then
    raise_application_error(-20001,
     'Attempting to insert a duplicate record '||
       'into AD_PA_CRITERIA_PROD_FAMS advisor_criteria_id =  '||
          l_advisor_criteria_id || ' and pre_seeded_flag '||
           l_pre_seeded);
  end;

  update ad_pa_criteria
   set last_update_date = l_last_update_date
    where advisor_criteria_id ='Consolidated Maintenance Patches';
end update_nc;
-- This procedure is to seed data for Recommended Patches Plus New Code Levels in ad_pa_criteria and ad_pa_criteria_prod_fams table
procedure update_rpandnc
is
  l_advisor_criteria_id          ad_pa_criteria.ADVISOR_CRITERIA_ID%TYPE;
  l_pre_seeded                   ad_pa_criteria.pre_seeded_flag%TYPE;
  l_last_update_date             date;
  l_created_by                   number;
 begin
  l_last_update_date             := sysdate;
  --
  -- This package is called by Autopatch program when AD-OAM Module is being installed
  -- Check if this criteria set (criteria_id and pre_seeded flag) exists
  -- in ad_pa_advisor_criteria (create if not exists)
  --
  -- Then delete rows from ad_pa_criteria_prod_fams.
  --
  -- For all products in FND_PRODUCT_INSTALLATIONS with status='I' and 'S'
  --   create row in ad_pa_criteria_prod_fams for this
  --   criteria set and product Family with Recommended Patches plus New Code Levels flag and licensed flag set Y and other flags N
  --
  -- For all products in FND_PRODUCT_INSTALLATIONS with status != 'I' and 'S'
  --   create row in ad_pa_criteria_prod_fams for this
  --   criteria set and product Family with Recommended Patches plus New Code Levels flag set Y and other flags N including licensed flag
  --
  -- Change last_update_date for this criteria set in ad_pa_advisor_criteria
  --
   begin
    select advisor_criteria_id, pre_seeded_flag, created_by  into l_advisor_criteria_id,
     l_pre_seeded, l_created_by
      from AD_PA_CRITERIA
      where advisor_criteria_id ='Recommended and Consolidated Maintenance Patches'
       and pre_seeded_flag = 'Y';

    if (l_created_by <> 2) then
      update AD_PA_CRITERIA
      set created_by = 2, last_updated_by = 2
      where advisor_criteria_id ='Recommended and Consolidated Maintenance Patches'
       and pre_seeded_flag = 'Y';
    end if;

   exception
    when no_data_found then
     insert into AD_PA_CRITERIA
       (advisor_criteria_id, advisor_criteria_description,pre_seeded_flag,
       creation_date,last_update_date,last_updated_by,created_by)
     values('Recommended and Consolidated Maintenance Patches','Recommended and consolidated patches, and new features. Suitable for upgrades. ','Y',sysdate,sysdate,2,2);
  end;

   begin
    delete from ad_pa_criteria_prod_fams
     where advisor_criteria_id = 'Recommended and Consolidated Maintenance Patches';

     insert into ad_pa_criteria_prod_fams
    (PRODUCT_FAMILY_ABBREVIATION,ADVISOR_CRITERIA_ID,RECOMMENDED_PATCH_FLAG,NEW_CODE_LEVEL_FLAG,LICENSED_FLAG,
	  CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY)
    select distinct pfm.product_family_abbreviation,'Recommended and Consolidated Maintenance Patches','Y','Y','Y',sysdate,1,sysdate,1
	   from fnd_product_installations fpi, fnd_application a,
			ad_pm_product_info pi, ad_pm_prod_family_map pfm
		   where fpi.status in ('S', 'I')
        and fpi.application_id = a.application_id
        and a.application_short_name= pi.application_short_name
        and  pi.PSEUDO_PRODUCT_FLAG='N'
        and pi.product_abbreviation = pfm.product_abbreviation ;
    begin
     insert into ad_pa_criteria_prod_fams
    (PRODUCT_FAMILY_ABBREVIATION,ADVISOR_CRITERIA_ID,RECOMMENDED_PATCH_FLAG,NEW_CODE_LEVEL_FLAG,LICENSED_FLAG,
	  CREATION_DATE, CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY)
     select distinct pi.product_abbreviation,'Recommended and Consolidated Maintenance Patches', 'Y', 'Y', 'N',sysdate, 1, sysdate, 1
      from ad_pm_product_info pi
       where pi.pseudo_product_flag='Y'
        and pi.product_family_flag='Y'
        and not exists
        (select 'X' from ad_pa_criteria_prod_fams adf
         where adf.product_family_abbreviation= pi.product_abbreviation
          and adf.advisor_criteria_id='Recommended and Consolidated Maintenance Patches');
	  end;

      BEGIN
      DECLARE
      	cursor prod_family is
		   select adi.PRODUCT_FAMILY_ABBREVIATION adi_prod_abbr, adp.product_family_abbreviation adp_prod_abbr  from ad_pm_product_info adi, ad_pa_criteria_prod_fams adp
		   where  adp.PRODUCT_FAMILY_ABBREVIATION = adi.PRODUCT_FAMILY_ABBREVIATION
        and  adp.ADVISOR_CRITERIA_ID ='Recommended and Consolidated Maintenance Patches' for update of adp.product_family_abbreviation;
		     prod_abb prod_family%ROWTYPE;
	      begin
	      for prod_abb in prod_family
	       loop
		      update ad_pa_criteria_prod_fams
		       set product_family_abbreviation = prod_abb.adi_prod_abbr
          where current of prod_family;
  		   end loop;
     end;
    end;

  exception
   when dup_val_on_index then
    raise_application_error(-20001,
     'Attempting to insert a duplicate record '||
       'into AD_PA_CRITERIA_PROD_FAMS advisor_criteria_id =  '||
          l_advisor_criteria_id || ' and pre_seeded_flag '||
           l_pre_seeded);
  end;

  update ad_pa_criteria
   set last_update_date = l_last_update_date
    where advisor_criteria_id ='Recommended and Consolidated Maintenance Patches';
end update_rpandnc;


procedure update_all
is

  --
  -- Create/update all three of the pre-seeded Criteria Sets
  -- Delete rows from ad_pa_criteria and ad_pa_criteria_products for 11.5.9
 x_statement varchar2(100);
 G_UN_FND varchar2(30) := null;
 l_stat   varchar2(1)  := null;
 l_ind    varchar2(1)  := null;
 l_ign    boolean;

  begin

    x_statement := 'n';
        begin

         --Bug # 3407988 -This is to delete existing old advisor_criteria_id from the database
	 delete from ad_pa_criteria
         where advisor_criteria_id = 'New Codelevels';
         delete from ad_pa_criteria
         where advisor_criteria_id = 'Recommended Patches';
        delete from ad_pa_criteria
         where advisor_criteria_id = 'Recommended Patches and New Codelevels';
         delete from ad_pa_criteria
         where advisor_criteria_id = 'RecPatches and New Codelevels';
         delete from ad_pa_criteria_prod_fams
         where advisor_criteria_id = 'New Codelevels';
         delete from ad_pa_criteria_prod_fams
         where advisor_criteria_id = 'Recommended Patches';
         delete from ad_pa_criteria_prod_fams
         where advisor_criteria_id = 'Recommended Patches and New Codelevels';
         delete from ad_pa_criteria_prod_fams
         where advisor_criteria_id = 'RecPatches and New Codelevels';
         -- end of  --Bug # 3407988

	 --vsigamal 10-Oct-2006 Bug # 5575432 - This is to delete existing old advisor_criteria_id from the database
	 delete from ad_pa_criteria_prod_fams
	 where advisor_criteria_id in ( select advisor_criteria_id
                                        from ad_pa_criteria
				        where pre_seeded_flag='Y');
	 delete from ad_pa_criteria
	 where pre_seeded_flag='Y';

         -- Get APPLSYS schema name (Bug 3871565).
         l_ign := fnd_installation.get_app_info('FND', l_stat,
                                             l_ind, G_UN_FND);

         --DBMS_OUTPUT.PUT_LINE('Username -> [' || G_UN_FND || ']');

         select 'y' into x_statement
         from dba_tables
         where table_name = 'AD_PA_CRITERIA_PRODUCTS'
         and owner = G_UN_FND;

         if  x_statement = 'y' then
            begin
              delete from ad_pa_criteria ac
              where advisor_criteria_id in ( select advisor_criteria_id
                                             from ad_pa_criteria_products acp
                                             where acp.advisor_criteria_id = ac.advisor_criteria_id);
	      DELETE from AD_PA_CRITERIA_products;
            exception
              when no_data_found then
                   null;
            end;
         end if;

   exception
    when others then
    null;
  end;

  update_rp;
  update_nc;
  update_rpandnc;
end update_all;

end ad_pa_criteria_util;
