
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PA_INSERT_PACKAGE" AUTHID CURRENT_USER as
/* $Header: adpaips.pls 120.1 2006/03/24 03:25:44 msailoz noship $ */

--
-- Procedure to insert/update in table ad_pm_patches
--

procedure insert_ad_pm_patches
(
   bug_number_value            number,
   aru_update_date_value       varchar2,
   product_abbreviation_value  varchar2,
   product_family_abbv_value  varchar2,
   patch_name_value            varchar2,
   conc_request_id             number,
   bug_description_value       varchar2,
   is_family_pack_flag 	       varchar2,
   is_mini_pack_flag	       varchar2,
   is_high_priority_flag       varchar2,
   is_maint_pack_flag          varchar2,
   X_in_reference_family_pack  varchar2,
   X_reference_family_pack     varchar2,
   X_in_reference_mini_pack    varchar2,
   X_reference_mini_pack       varchar2,
   X_in_reference_maint_pack   varchar2,
   X_reference_maint_pack      varchar2,
   X_infobundle_upload_date    varchar2,
   X_creation_date             varchar2,
   X_last_updated_by           number,
   X_created_by                number,
   X_last_update_date          varchar2
);

-- msailoz bug#4956568 Set release name to R12
-- Procedure to insert/update in table ad_pm_patches for R12
--

procedure insert_ad_pm_patches
(
   bug_number_value            number,
   aru_update_date_value       varchar2,
   product_abbreviation_value  varchar2,
   product_family_abbv_value  varchar2,
   patch_name_value            varchar2,
   conc_request_id             number,
   bug_description_value       varchar2,
   is_high_priority_flag       varchar2,
   X_infobundle_upload_date    varchar2,
   X_creation_date             varchar2,
   X_last_updated_by           number,
   X_created_by                number,
   X_last_update_date          varchar2,
   is_code_level_flag           varchar2,
   p_patch_type                varchar2,
   p_entity_abbr                varchar2,
   p_entity_baseline            varchar2
);

--
-- Procedure to insert/update in ad_pm_product_info
--

procedure insert_ad_pm_product_info
 (
  X_product_abbreviation        varchar2,
  X_pseudo_product_flag         varchar2,
  X_product_family_flag         varchar2,
  X_application_short_name      varchar2,
  X_product_name                varchar2,
  X_product_family_abbreviation varchar2,
  X_product_family_name         varchar2,
  X_aru_update_date             varchar2,
  X_currDate                    varchar2 ,
  X_last_updated_by             number,
  X_created_by                  number
 );


--
-- Procedure to insert/update in ad_pm_prod_family_map
--  Added for Bug# 2814295 to update the new AD Patch Advisor
--  table ad_pm_prod_family_map

procedure insert_ad_pm_prod_family_map
 (
  X_product_abbreviation        varchar2,
  X_product_family_abbreviation varchar2,
  X_aru_update_date             varchar2,
  X_currDate                    varchar2,
  X_last_updated_by             number,
  X_created_by                  number
 );


end ad_pa_insert_package;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PA_INSERT_PACKAGE" as
/* $Header: adpaipb.pls 120.2 2006/03/27 08:07:14 msailoz noship $ */

--
-- Procedure to insert/update in table ad_pm_patches
--

procedure insert_ad_pm_patches
(
   bug_number_value	       number,
   aru_update_date_value       varchar2,
   product_abbreviation_value  varchar2,
   product_family_abbv_value   varchar2,
   patch_name_value            varchar2,
   conc_request_id             number,
   bug_description_value       varchar2,
   is_family_pack_flag         varchar2,
   is_mini_pack_flag	       varchar2,
   is_high_priority_flag       varchar2,
   is_maint_pack_flag          varchar2,
   X_in_reference_family_pack  varchar2,
   X_reference_family_pack     varchar2,
   X_in_reference_mini_pack    varchar2,
   X_reference_mini_pack       varchar2,
   X_in_reference_maint_pack   varchar2,
   X_reference_maint_pack      varchar2,
   X_infobundle_upload_date    varchar2,
   X_creation_date             varchar2,
   X_last_updated_by           number,
   X_created_by                number,
   X_last_update_date          varchar2
)
is
begin
  insert into ad_pm_patches
                       (
                        patch_metadata_key ,
                        bug_number ,
                        product_abbreviation,
                        product_family_abbreviation,
                        patch_name,
                        upload_run_id ,
                        bug_description ,
                        is_family_pack ,
                        is_mini_pack ,
                        is_high_priority ,
                        is_maint_pack ,
                        in_reference_family_pack ,
                        reference_family_pack ,
                        in_reference_mini_pack ,
                        reference_mini_pack ,
                        in_reference_maint_pack ,
                        reference_maint_pack,
                        creation_date  ,
                        last_updated_by ,
                        created_by ,
                        last_update_date
                        )
                  values
                       (
                       'DEFAULT' ,
                       bug_number_value ,
                       product_abbreviation_value,
                       nvl(product_family_abbv_value,'Not Found'),
                       patch_name_value,
                       conc_request_id ,
                       bug_description_value,
                       is_family_pack_flag,
                       is_mini_pack_flag,
                       is_high_priority_flag,
                       is_maint_pack_flag,
                       X_in_reference_family_pack  ,
                       X_reference_family_pack,
                       X_in_reference_mini_pack  ,
                       X_reference_mini_pack,
                       X_in_reference_maint_pack,
                       X_reference_maint_pack ,
                       to_date(X_last_update_date,'yyyy-mm-dd hh24:mi:ss'),
                       X_last_updated_by,
                       X_created_by ,
                       to_date(X_last_update_date,'yyyy-mm-dd hh24:mi:ss')
                       );

exception
 when dup_val_on_index then
   update ad_pm_patches
             set
               product_abbreviation     = product_abbreviation_value ,
               product_family_abbreviation =  nvl(product_family_abbv_value,'Not Found'),
               patch_name               = patch_name_value ,
               upload_run_id            = conc_request_id ,
               bug_description          = bug_description_value ,
               is_family_pack           = is_family_pack_flag ,
               is_mini_pack             = is_mini_pack_flag,
               is_high_priority         = is_high_priority_flag ,
               is_maint_pack            = is_maint_pack_flag ,
               in_reference_family_pack = X_in_reference_family_pack ,
               reference_family_pack    = X_reference_family_pack ,
               in_reference_mini_pack   = X_in_reference_mini_pack ,
               reference_mini_pack      = X_reference_mini_pack,
               in_reference_maint_pack  = X_in_reference_maint_pack,
               reference_maint_pack     = X_reference_maint_pack,
               last_updated_by          = X_last_updated_by,
               last_update_date =
                           to_date(X_last_update_date,'yyyy-mm-dd hh24:mi:ss')

            where
               (      bug_number         =  bug_number_value
                  and patch_metadata_key = 'DEFAULT'   );

end insert_ad_pm_patches;

-- msailoz bug#4956568 Set release name to R12
-- Procedure to insert/update in table ad_pm_patches for R12
--

procedure insert_ad_pm_patches
(
   bug_number_value	            number,
   aru_update_date_value       varchar2,
   product_abbreviation_value  varchar2,
   product_family_abbv_value   varchar2,
   patch_name_value            varchar2,
   conc_request_id             number,
   bug_description_value       varchar2,
   is_high_priority_flag       varchar2,
   X_infobundle_upload_date    varchar2,
   X_creation_date             varchar2,
   X_last_updated_by           number,
   X_created_by                number,
   X_last_update_date          varchar2,
   is_code_level_flag          varchar2,
   p_patch_type                varchar2,
   p_entity_abbr	             varchar2,
   p_entity_baseline           varchar2
)
is
   err_msg              varchar2(200);
   l_entity_baseline    varchar2(50);

begin

  IF (p_entity_baseline = '' OR p_entity_baseline IS NULL) THEN
    l_entity_baseline := 'R12';
  ELSE
    l_entity_baseline := p_entity_baseline;
  END IF;

  INSERT INTO ad_pm_patches
                       (
                        patch_metadata_key ,
                        bug_number ,
                        product_abbreviation,
                        product_family_abbreviation,
                        patch_name,
                        upload_run_id ,
                        bug_description ,
                        is_high_priority ,
                        creation_date  ,
                        last_updated_by ,
                        created_by ,
                        last_update_date,
                        is_code_level,
                        patch_type ,
                        entity_abbr,
                        baseline,
                        patch_id
                        )
  SELECT
                       'DEFAULT' ,
                       bug_number_value ,
                       product_abbreviation_value,
                       nvl(product_family_abbv_value,'Not Found'),
                       patch_name_value,
                       conc_request_id ,
                       bug_description_value,
                       is_high_priority_flag,
                       to_date(X_last_update_date,'yyyy-mm-dd hh24:mi:ss'),
                       X_last_updated_by,
                       X_created_by ,
                       to_date(X_last_update_date,'yyyy-mm-dd hh24:mi:ss'),
                       is_code_level_flag,
                       p_patch_type ,
                       p_entity_abbr ,
                       l_entity_baseline,
                       ad_patch_id_s.NEXTVAL
  FROM DUAL;

exception
 when dup_val_on_index then
   update ad_pm_patches
             set
               product_abbreviation     = product_abbreviation_value ,
               product_family_abbreviation =  nvl(product_family_abbv_value,'Not Found'),
               patch_name               = patch_name_value ,
               upload_run_id            = conc_request_id ,
               bug_description          = nvl(bug_description,bug_description_value) ,
               is_high_priority         = decode(is_high_priority,'N',is_high_priority_flag,null, is_high_priority_flag, is_high_priority),
               is_code_level            = decode(is_code_level,'N',is_code_level_flag,null, is_code_level_flag, is_code_level),
               patch_type               = decode(patch_type, null, p_patch_type, patch_type),
               last_updated_by          = X_last_updated_by,
               last_update_date =
                           to_date(X_last_update_date,'yyyy-mm-dd hh24:mi:ss')
            where
               (      bug_number         = bug_number_value
                  and baseline           = l_entity_baseline
                  and patch_metadata_key = 'DEFAULT'   );

end insert_ad_pm_patches;


--
-- Procedure to insert/update in ad_pm_product_info
--

procedure insert_ad_pm_product_info
 (
  X_product_abbreviation        varchar2,
  X_pseudo_product_flag         varchar2,
  X_product_family_flag         varchar2,
  X_application_short_name      varchar2,
  X_product_name                varchar2,
  X_product_family_abbreviation varchar2,
  X_product_family_name         varchar2,
  X_aru_update_date             varchar2,
  X_currDate                    varchar2 ,
  X_last_updated_by             number,
  X_created_by                  number
 )
is
 begin
  insert into ad_pm_product_info
                             (
                             product_abbreviation ,
                             pseudo_product_flag ,
                             product_family_flag ,
                             application_short_name ,
                             product_name,
                             aru_update_date ,
                             creation_date ,
                             last_updated_by,
                             created_by,
                             last_update_date
                             )
                             values
                             (
                             X_product_abbreviation ,
                             X_pseudo_product_flag ,
                             X_product_family_flag ,
                             X_application_short_name ,
                             X_product_name,
                             to_date(X_aru_update_date,'yyyy-mm-dd hh24:mi:ss')
                             ,to_date(X_currdate,'yyyy-mm-dd hh24:mi:ss'),
                             X_last_updated_by,
                             X_created_by,
                             to_date(X_currdate,'yyyy-mm-dd hh24:mi:ss')
                              );
  exception
    when dup_val_on_index then
           update ad_pm_product_info
             set pseudo_product_flag           = X_pseudo_product_flag  ,
                  product_family_flag          = X_product_family_flag ,
                  application_short_name       = X_application_short_name ,
                  product_name                 = X_product_name ,
                  aru_update_date
                     = to_date(X_aru_update_date,'yyyy-mm-dd hh24:mi:ss'),
                  last_update_date
                     = to_date(X_currdate,'yyyy-mm-dd hh24:mi:ss'),
                  last_updated_by =  X_last_updated_by
             where product_abbreviation = X_product_abbreviation;

end insert_ad_pm_product_info ;


--
-- Procedure to insert/update in ad_pm_prod_family_map
--  Added for Bug# 2814295 to update the new AD Patch Advisor
--  table ad_pm_prod_family_map

procedure insert_ad_pm_prod_family_map
 (
  X_product_abbreviation        varchar2,
  X_product_family_abbreviation varchar2,
  X_aru_update_date             varchar2,
  X_currDate                    varchar2,
  X_last_updated_by             number,
  X_created_by                  number
 )
is
 begin
  insert into ad_pm_prod_family_map
                             (
                             product_abbreviation ,
                             product_family_abbreviation,
                             creation_date ,
                             last_updated_by,
                             created_by,
                             last_update_date
                             )
                             values
                             (
                             X_product_abbreviation ,
                             X_product_family_abbreviation,
                             to_date(X_currdate,'yyyy-mm-dd hh24:mi:ss'),
                             X_last_updated_by,
                             X_created_by,
                             to_date(X_currdate,'yyyy-mm-dd hh24:mi:ss')
                              );

  -- do nothing if the info already exists in table
  -- Combination of PRODUCT_ABBREVIATION AND PRODUCT_FAMILY_ABBREVIATION
  --  is the primary key for the table  AD_PM_PROD_FAMILY_MAP
  exception
    when dup_val_on_index then
     update  ad_pm_prod_family_map
	     set
	        last_updated_by =  X_last_updated_by ,
	        last_update_date =  to_date(X_currdate,'yyyy-mm-dd hh24:mi:ss')
		where
		      product_abbreviation =  X_product_abbreviation
		 and  product_family_abbreviation = X_product_family_abbreviation;

end insert_ad_pm_prod_family_map;

end ad_pa_insert_package;
