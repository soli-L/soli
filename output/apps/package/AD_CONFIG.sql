
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_CONFIG" AUTHID CURRENT_USER as
/* $Header: adconfgs.pls 115.0 99/07/17 04:30:04 porting ship $ */

FUNCTION release_name(
    p_release_type IN varchar2 default null)  RETURN varchar2;

FUNCTION is_multi_org        RETURN varchar2;
FUNCTION is_multi_lingual    RETURN varchar2;
FUNCTION is_multi_currency   RETURN varchar2;
FUNCTION get_default_org_id  RETURN number;

end AD_CONFIG;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_CONFIG" as
/* $Header: adconfgb.pls 115.0 99/07/17 04:29:59 porting ship $ */

FUNCTION release_name(p_release_type IN varchar2 default null) RETURN varchar2
IS
  l_release_name varchar2(50) := '';
BEGIN

   SELECT decode(p_release_type,
             'B', substr(release_name, 1,
                     decode(sign(instr(release_name, ' ')), 1,
                              instr(release_name, ' ')-1,
                              length(release_name))),
              release_name)
   INTO   l_release_name
   FROM fnd_product_groups;

   return(l_release_name);
END;

FUNCTION is_multi_org        RETURN varchar2
IS
  l_flag  varchar2(1);
BEGIN
   SELECT nvl(multi_org_flag, 'N')
   INTO   l_flag
   FROM   fnd_product_groups;

   return(l_flag);
END;

FUNCTION is_multi_lingual    RETURN varchar2
IS
  l_flag  varchar2(1);
BEGIN
   SELECT nvl(multi_lingual_flag, 'N')
   INTO   l_flag
   FROM   fnd_product_groups;

   return(l_flag);
END;

FUNCTION is_multi_currency   RETURN varchar2
IS
  l_flag  varchar2(1);
BEGIN
   SELECT nvl(multi_currency_flag, 'N')
   INTO   l_flag
   FROM   fnd_product_groups;

   return(l_flag);
END;

FUNCTION get_default_org_id  RETURN number
IS
  l_org_id number;
BEGIN

  if (is_multi_org() = 'N')
  then return NULL;
  end if;

  SELECT to_number(profile_option_value)
  INTO   l_org_id
  FROM   fnd_profile_option_values pov
       , fnd_profile_options po
  WHERE  po.profile_option_name = 'ORG_ID'
  AND    pov.profile_option_id = po.profile_option_id
  AND    pov.level_id = 10001;

  return(l_org_id);

EXCEPTION
  WHEN NO_DATA_FOUND THEN
     return(null);
END;

end AD_CONFIG;
