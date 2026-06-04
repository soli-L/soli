
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PA_EDIT_ADVISOR_CRITERIA" AUTHID CURRENT_USER as
/* $Header: adpaedcs.pls 115.1 2002/10/10 20:10:31 rlotero ship $*/

Procedure edit_criteriaSet(p_advisor_criteria_id    varchar2,
                  p_product_abbreviation            varchar2,
                  p_require_family_pack             varchar2,
                  p_require_mini_pack               varchar2,
                  p_require_high_priority           varchar2);

end ad_pa_edit_advisor_criteria;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PA_EDIT_ADVISOR_CRITERIA" as
/* $Header: adpaedcb.pls 115.2 2004/06/01 10:40:37 sallamse ship $*/

Procedure  edit_criteriaSet(p_advisor_criteria_id      varchar2,
              p_product_abbreviation                   varchar2,
              p_require_family_pack                    varchar2,
              p_require_mini_pack                      varchar2,
              p_require_high_priority                  varchar2)

IS
  l_last_update_date date;
  l_lub number;
  cursor ad_pa_cri_prod is
    select product_abbreviation,product_family_abbreviation,
           require_family_pack,require_mini_pack,require_high_priority
    from ad_pa_criteria_products
    where advisor_criteria_id =p_advisor_criteria_id
    and   product_abbreviation = p_product_abbreviation;
BEGIN
  l_last_update_date  := sysdate;
  for PRODUCT_REC in ad_pa_cri_prod loop
    begin
      if PRODUCT_REC.require_family_pack <> p_require_family_pack or
         PRODUCT_REC.require_mini_pack  <> p_require_family_pack or
         PRODUCT_REC.require_high_priority <> p_require_high_priority then

	 update  AD_PA_CRITERIA_products
	 set
	   require_family_pack  =p_require_family_pack,
	   require_mini_pack    =p_require_mini_pack,
	   REQUIRE_HIGH_PRIORITY=p_require_high_priority,
	   last_update_date = l_last_update_date
	 where advisor_criteria_id = p_advisor_criteria_id
	 and   product_abbreviation = p_product_abbreviation;

      end if;

    exception
      when dup_val_on_index then
        raise_application_error(-20001,
          'Attempting to insert a duplicate record '||
          'into AD_PA_ADVISOR_CRITERIA_PRODUCT advisor_criteria_id =  '||
          p_advisor_criteria_id || ' and product_abbreviation '||
          p_product_abbreviation);
    end;
  end loop;

end edit_criteriaSet;

End ad_pa_edit_advisor_criteria;
