
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PA_CREATE_ADVISOR_CRITERIA" AUTHID CURRENT_USER as
/* $Header: adpaincs.pls 115.2 2004/06/02 12:07:33 sallamse ship $*/

Procedure insert_criteria(p_advisor_criteria_id           varchar2,
                p_advisor_criteria_description            varchar2,
                p_pre_seeded_flag                         varchar2,
                p_last_updated_by                         number default 1,
                p_created_by                              number default 1);

Procedure insert_criteria_prod(p_advisor_criteria_id      varchar2,
                p_product_abbreviation                    varchar2,
                p_product_family_abbreviation             varchar2,
                p_require_family_pack                     varchar2,
                p_require_mini_pack                       varchar2,
                p_require_high_priority                   varchar2,
                p_last_updated_by                         number default 1,
                p_created_by                              number default 1);

end ad_pa_create_advisor_criteria;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PA_CREATE_ADVISOR_CRITERIA" as
/* $Header: adpaincb.pls 115.3 2002/10/14 22:25:23 kksingh ship $*/

Procedure insert_criteria(p_advisor_criteria_id           varchar2,
                p_advisor_criteria_description            varchar2,
                p_pre_seeded_flag                         varchar2,
                p_last_updated_by                         number,
                p_created_by                              number)
IS
  l_uid number;
BEGIN
  l_uid := p_last_updated_by;

  if l_uid is null then
    l_uid := 1;
  end if;

  begin
    insert into AD_PA_CRITERIA
      (ADVISOR_CRITERIA_ID,ADVISOR_CRITERIA_DESCRIPTION,PRE_SEEDED_FLAG,
       CREATION_DATE,LAST_UPDATED_BY,CREATED_BY,LAST_UPDATE_DATE)
    values (p_advisor_criteria_id,p_advisor_criteria_description,
            p_pre_seeded_flag,sysdate,p_last_updated_by,p_created_by,sysdate);

  exception
    when dup_val_on_index then
      raise_application_error(-20001,
                   'Attempting to insert a duplicate record '||
                   'into AD_PA_ADVISOR_CRITERIA advisor_criteria_id =  '||
                   p_advisor_criteria_id || ' and pre_seeded_flag '||
                   p_pre_seeded_flag);
  end;

END insert_criteria;


Procedure insert_criteria_prod(p_advisor_criteria_id       varchar2,
                p_product_abbreviation                     varchar2,
                p_product_family_abbreviation              varchar2,
                p_require_family_pack                      varchar2,
                p_require_mini_pack                        varchar2,
                p_require_high_priority                    varchar2,
                p_last_updated_by                          number,
                p_created_by                               number)
IS
  l_uid number;
BEGIN
  l_uid := p_last_updated_by;

  if l_uid is null then
    l_uid := 1;
  end if;

  begin
    insert into AD_PA_CRITERIA_PRODUCTS
      (ADVISOR_CRITERIA_ID,PRODUCT_ABBREVIATION,PRODUCT_FAMILY_ABBREVIATION,
       REQUIRE_FAMILY_PACK,REQUIRE_MINI_PACK,REQUIRE_HIGH_PRIORITY,
       CREATION_DATE,LAST_UPDATED_BY,CREATED_BY,LAST_UPDATE_DATE)
     values (p_advisor_criteria_id,p_product_abbreviation,
             p_product_family_abbreviation,p_require_family_pack,
             p_require_mini_pack,p_require_high_priority,sysdate,
             p_last_updated_by,p_created_by,sysdate);

  exception
    when dup_val_on_index then
      raise_application_error(-20001,
        'Attempting to insert a duplicate record '||
        'into AD_PA_ADVISOR_CRITERIA advisor_criteria_id =  '||
        p_advisor_criteria_id || ' and product_abbreviation '||
        p_product_abbreviation);
  END;
END insert_criteria_prod;

End ad_pa_create_advisor_criteria;
