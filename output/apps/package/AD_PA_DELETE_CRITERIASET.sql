
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PA_DELETE_CRITERIASET" AUTHID CURRENT_USER as
/* $Header: adpadlcs.pls 115.0 2002/10/11 21:51:22 kksingh noship $*/

Procedure delete_criteriaset(p_advisor_criteria_id  varchar2);

end ad_pa_delete_criteriaset;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PA_DELETE_CRITERIASET" as
/* $Header: adpadlcb.pls 115.2 2002/10/11 21:52:31 kksingh ship $ */

Procedure delete_criteriaset(p_advisor_criteria_id  varchar2 )
IS

BEGIN

  begin
    DELETE from AD_PA_CRITERIA_PRODUCTS
      where advisor_criteria_id = p_advisor_criteria_id;

    DELETE from AD_PA_CRITERIA
      where advisor_criteria_id = p_advisor_criteria_id;

    exception
      when no_data_found then
       RETURN ;
  end ;
END delete_criteriaset;

END ad_pa_delete_criteriaset;
