
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_TRACKABLE_ENTITIES_PKG" AUTHID CURRENT_USER AS
-- $Header: adcodlins.pls 120.2.12020000.3 2021/07/21 11:02:46 rsatyava ship $

  C_AD_ENTITY     CONSTANT      ad_trackable_entities.abbreviation%type :='ad';
  C_TXK_ENTITY    CONSTANT      ad_trackable_entities.abbreviation%type :='txk';
  C_EBSSYS_ENTITY CONSTANT      ad_trackable_entities.abbreviation%type :='ebssys';
  C_AD_TXK        CONSTANT      ad_trackable_entities.abbreviation%type :='AD_TXK';
  C_EBS           CONSTANT      ad_trackable_entities.abbreviation%type :='EBS';
  C_SYS_MIG       CONSTANT      ad_trackable_entities.abbreviation%type :='SYS_MIG';


  -- Procedure declarations follows

  PROCEDURE validate_name(p_te IN VARCHAR2);
  PROCEDURE validate_level(p_level IN VARCHAR2);
  PROCEDURE create_te ( p_trackable_entity_name IN  VARCHAR2 ,
                        p_desc IN VARCHAR2,
                        p_type IN  VARCHAR2,
                        x_status  OUT NOCOPY /* file.sql.39 change */ VARCHAR2 );

  PROCEDURE get_code_level (
              p_trackable_entity_name IN  VARCHAR2,
              x_te_level            OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_baseline              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2);

  PROCEDURE set_code_level (
              p_trackable_entity_name IN  VARCHAR2,
              p_te_level            IN  VARCHAR2,
              p_baseline              IN  VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2);

  PROCEDURE get_used_status (
              p_trackable_entity_name IN  VARCHAR2,
              x_used_status           OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_te_level            OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_baseline              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2);


  PROCEDURE set_used_status (
              p_trackable_entity_name IN  VARCHAR2,
              p_used_status           IN  VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2);

  PROCEDURE reset_used_flag(x_status                OUT NOCOPY VARCHAR2);

  PROCEDURE get_load_status (
              p_trackable_entity_name IN  VARCHAR2,
              x_load_status           OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_te_level            OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_baseline              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2);

  PROCEDURE set_load_status (
              p_trackable_entity_name IN  VARCHAR2,
              p_load_status           IN  VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2);


  PROCEDURE get_te_info (
              p_trackable_entity_name IN  VARCHAR2,
              x_desc                  OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_type                  OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_te_level              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_baseline              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_used_status           OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_load_status           OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2);

  PROCEDURE set_te_info (
              p_trackable_entity_name IN  VARCHAR2,
              p_trackable_entity_desc IN VARCHAR2,
              p_type                  IN VARCHAR2,
              p_te_level              IN VARCHAR2,
              p_baseline              IN VARCHAR2,
              p_used_status           IN VARCHAR2,
              p_load_status           IN VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2);


  /*
  ** IS_AD_TXK_ON_EBSSYS
  ** This function checks if ad/txk code level is
  ** compatible with ebssys codelevel.
  ** If codelevel for ad >=C.13 and txk >=C.13 and ebssys >=C.0 returns Y
  ** else returns N
  */
  function IS_AD_TXK_ON_EBSSYS return varchar2;

  /*
  ** IS_EBS_ON_EBSSYS
  ** This function checks if ebs code level is
  ** compatible with ebssys codelevel.
  ** If codelevel for ebssys >=C.1 returns Y
  ** else returns N
  */
  function IS_EBS_ON_EBSSYS return varchar2;

  /*
  ** IS_EBS_SYS_MIG
  ** This function checks if ebs system schema migration is
  ** complete.
  ** If codelevel for ebssys >=C.2 returns Y
  ** else returns N
  */
  function IS_EBS_SYS_MIG return varchar2;

END AD_TRACKABLE_ENTITIES_PKG;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_TRACKABLE_ENTITIES_PKG" AS
-- $Header: adcodlinb.pls 120.3.12020000.3 2021/07/21 11:18:16 rsatyava ship $

  /*
  ** GET_CODELEVEL_NUM
  ** This function returns numeric value of the codelevel for
  ** a given trackable entity
  ** If the code level has no numeric value
  ** it returns 0
  */
  function GET_CODELEVEL_NUM(X_ENTITY IN VARCHAR2) return pls_integer
  is
    L_CODE_LVL_STR           ad_trackable_entities.codelevel%type;
    L_BASELINE               ad_trackable_entities.baseline%type;
    L_ENTITY_STATUS          varchar2(10);
    L_CODE_LVL_NUM           pls_integer :=0;
    L_CODE_LVL_NUM_START_POS pls_integer ;
  begin

    --Validate trackable entity
    if((x_entity is null) or (x_entity = '')) then
      raise_application_error(-20002,'Trackable entity cannot be null or empty string');
    end if;

    --Retrieve the trackable entities code level in string format
    begin
      get_code_level(x_entity,
                     l_code_lvl_str,
                     l_baseline,
                     l_entity_status);

      --If trackable entity does not exist
      if(l_entity_status = 'FALSE') then
        raise_application_error(-20002,'The code level for trackable entity '||x_entity||
                                       ' could not be found');
      end if;
    exception
      when others then
        raise_application_error(-20002,'The code level for trackable entity '||x_entity||
                                       ' could not be retrieved due to error '||sqlerrm);
    end;

    --retrive the start position of the first occurence of the digit in
    --the code level string
    l_code_lvl_num_start_pos := regexp_instr(l_code_lvl_str,'\d',1,1);

    -- If no match is found, the function regexp_instr returns 0.
    if(l_code_lvl_num_start_pos > 0) then
      l_code_lvl_num         := substr(l_code_lvl_str,l_code_lvl_num_start_pos);
    end if;

    return l_code_lvl_num;
  end GET_CODELEVEL_NUM;

  /*
  ** IS_ON_EBSSYS
  ** This function checks if the trackable entity code level
  ** is compatible with ebssys codelevel.
  */
  function IS_ON_EBSSYS(X_ENTITY_STR IN VARCHAR2) return varchar2
  is
    L_AD_CODE_LVL_NUM         ad_trackable_entities.codelevel%type;
    L_TXK_CODE_LVL_NUM        ad_trackable_entities.codelevel%type;
    L_EBSSYS_CODE_LVL_NUM     ad_trackable_entities.codelevel%type;
    L_IS_ON_EBSSYS            varchar2(1) :='N';
  begin

    --Retrieve the trackable entity ebssys code level
    l_ebssys_code_lvl_num  := get_codelevel_num(ad_trackable_entities_pkg.C_EBSSYS_ENTITY);

    --For 'AD_TXK' entity if codelevel for ad >=C.13 and txk >=C13 and ebssys >=C.0, is_on_ebssys returns Y
    if(x_entity_str = ad_trackable_entities_pkg.C_AD_TXK) then

      --Retrieve the trackable entities ad,txk code levels
      l_ad_code_lvl_num      := get_codelevel_num(ad_trackable_entities_pkg.C_AD_ENTITY);
      l_txk_code_lvl_num     := get_codelevel_num(ad_trackable_entities_pkg.C_TXK_ENTITY);

      if((l_ad_code_lvl_num >= 13)  and  (l_txk_code_lvl_num >= 13) and
         (l_ebssys_code_lvl_num >= 0)) then
        l_is_on_ebssys := 'Y';
      end if;

    --For 'EBS' entity if codelevel for ebssys >=C.1, is_on_ebssys returns 'Y'
    elsif(x_entity_str = ad_trackable_entities_pkg.C_EBS) then

      if(l_ebssys_code_lvl_num >= 1) then
        l_is_on_ebssys := 'Y';
      end if;

    --For 'SYS_MIG' entity if codelevel for ebssys >=C.2, is_on_ebssys returns 'Y'
    elsif(x_entity_str = ad_trackable_entities_pkg.C_SYS_MIG) then

      if(l_ebssys_code_lvl_num >= 2) then
        l_is_on_ebssys := 'Y';
      end if;

    else
      raise_application_error(-20002,'The entity '||x_entity_str||
                                       ' is not yet supported to verify the compatibility with ebssys');
    end if;

    return l_is_on_ebssys;
  end IS_ON_EBSSYS;


   PROCEDURE validate_name( p_te IN VARCHAR2) is
    l_te varchar2(30);
   BEGIN

    l_te := p_te;
   END validate_name;

   PROCEDURE validate_level( p_level IN VARCHAR2) is
    l_levl varchar2(30);
   BEGIN
    l_levl := p_level;
   END validate_level;

   PROCEDURE create_te ( p_trackable_entity_name IN  VARCHAR2 ,
                         P_desc IN VARCHAR2,
                         p_type IN  VARCHAR2,
                         x_status  OUT NOCOPY /* file.sql.39 change */ VARCHAR2 ) is
   BEGIN
     validate_name(p_trackable_entity_name);
     validate_name(p_type);

     insert into AD_TRACKABLE_ENTITIES (
                      abbreviation, name, type, baseline, codelevel,
                      used_flag, load_flag)
     values ( p_trackable_entity_name, p_desc, p_type, '0', '0',
                     'F' ,'F' );

     COMMIT;
     x_status := 'TRUE';

    EXCEPTION
      WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END create_te;

   PROCEDURE get_code_level (
              p_trackable_entity_name IN  VARCHAR2,
              x_te_level            OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_baseline              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2) is
   BEGIN
     validate_name(p_trackable_entity_name);
     -- Select the details of the event for the passed parameters.

       select baseline, codelevel
       into x_baseline, x_te_level
       from AD_TRACKABLE_ENTITIES
       where abbreviation = p_trackable_entity_name;

       x_status := 'TRUE';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        x_status := 'FALSE';
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END get_code_level;


  PROCEDURE set_code_level (
              p_trackable_entity_name IN  VARCHAR2,
              p_te_level            IN  VARCHAR2,
              p_baseline              IN  VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2) is
   BEGIN
     validate_name(p_trackable_entity_name);
     validate_level(p_te_level);
     validate_level(p_baseline);

     update AD_TRACKABLE_ENTITIES
     set codelevel =  p_te_level ,
         baseline =  p_baseline
     where abbreviation = p_trackable_entity_name;

    if(SQL%ROWCOUNT = 0) then
      x_status := 'FALSE';
    else
      x_status := 'TRUE';
    end if;

     COMMIT;
    EXCEPTION
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END set_code_level;


  PROCEDURE get_used_status (
              p_trackable_entity_name IN  VARCHAR2,
              x_used_status           OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_te_level            OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_baseline              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2) is
   BEGIN
     validate_name(p_trackable_entity_name);

       select baseline, codelevel, used_flag
       into x_baseline, x_te_level, x_used_status
       from AD_TRACKABLE_ENTITIES
       where abbreviation = p_trackable_entity_name;

       x_status := 'TRUE';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        x_status := 'FALSE';
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END get_used_status;


  PROCEDURE set_used_status (
              p_trackable_entity_name IN  VARCHAR2,
              p_used_status           IN  VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2) is
   BEGIN
     validate_name(p_trackable_entity_name);

     update AD_TRACKABLE_ENTITIES
     set used_flag = p_used_status
     where abbreviation = p_trackable_entity_name;

    if(SQL%ROWCOUNT = 0) then
      x_status := 'FALSE';
    else
      x_status := 'TRUE';
    end if;

     COMMIT;

    EXCEPTION
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END set_used_status;


  PROCEDURE reset_used_flag (x_status OUT NOCOPY VARCHAR2)
  IS
  BEGIN
	update ad_trackable_entities set used_flag = 'y';

	update ad_trackable_entities set used_flag = 'n' where
	type = 'product' and
	upper(abbreviation) in (select decode(upper(application_short_name),
	'SQLAP','AP','SQLGL','GL','OFA','FA',upper(application_short_name)) from
	fnd_product_installations fpi, fnd_application fa where
	fa.application_id = fpi.application_id
	and status = 'N');

	commit;

	update ad_trackable_entities ate set ate.used_flag = 'n' where
	ate.type = 'product_family' and

	/*don't want to mark as not in use if the product family doesn't exist
 	 * in ad_pm_prod_family_map for some reason */

	exists (select 1 from
	ad_pm_prod_family_map appfm where appfm.product_family_abbreviation
	= ate.abbreviation) and

	/*if no products in a product family are installed or shared
 	 * then mark as not in use*/

	abbreviation not in (select distinct product_family_abbreviation from
	ad_pm_prod_family_map appfm
	where upper(appfm.product_abbreviation) in
	(select upper(ate2.abbreviation) from
	ad_trackable_entities ate2 where
	used_flag = 'y'));

	commit;

    EXCEPTION
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

  END reset_used_flag;


  PROCEDURE get_load_status (
              p_trackable_entity_name IN  VARCHAR2,
              x_load_status           OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_te_level            OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_baseline              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2) is
   BEGIN
     validate_name(p_trackable_entity_name);

       select baseline, codelevel, load_flag
       into x_baseline, x_te_level, x_load_status
       from AD_TRACKABLE_ENTITIES
       where abbreviation = p_trackable_entity_name;

       x_status := 'TRUE';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        x_status := 'FALSE';
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END get_load_status;

  PROCEDURE set_load_status (
              p_trackable_entity_name IN  VARCHAR2,
              p_load_status           IN  VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2) is
   BEGIN
     validate_name(p_trackable_entity_name);

     update AD_TRACKABLE_ENTITIES
     set load_flag =  p_load_status
     where abbreviation = p_trackable_entity_name;

     COMMIT;

    if(SQL%ROWCOUNT = 0) then
      x_status := 'FALSE';
    else
      x_status := 'TRUE';
    end if;


    EXCEPTION
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END set_load_status;

 PROCEDURE get_te_info (
              p_trackable_entity_name IN  VARCHAR2,
              x_desc                  OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_type                  OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_te_level              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_baseline              OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_used_status           OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_load_status           OUT NOCOPY /* file.sql.39 change */ VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2) is
   BEGIN
     validate_name(p_trackable_entity_name);

       select name, type, baseline, codelevel, used_flag, load_flag
       into x_desc, x_type, x_baseline, x_te_level, x_used_status, x_load_status
       from AD_TRACKABLE_ENTITIES
       where abbreviation = p_trackable_entity_name;

       x_status := 'TRUE';

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        x_status := 'FALSE';
        RAISE;
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END get_te_info;

 PROCEDURE set_te_info (
              p_trackable_entity_name IN  VARCHAR2,
              p_trackable_entity_desc IN VARCHAR2,
              p_type                  IN VARCHAR2,
              p_te_level              IN VARCHAR2,
              p_baseline              IN VARCHAR2,
              p_used_status           IN VARCHAR2,
              p_load_status           IN VARCHAR2,
              x_status                OUT NOCOPY /* file.sql.39 change */ VARCHAR2) is
   BEGIN
     validate_name(p_trackable_entity_name);

     UPDATE AD_TRACKABLE_ENTITIES
     set name = p_trackable_entity_desc,
         type = p_type,
         baseline = p_baseline,
         codelevel = p_te_level,
         used_flag = p_used_status,
         load_flag = p_load_status
     where abbreviation = p_trackable_entity_name;

    if(SQL%ROWCOUNT = 0) then
     insert into AD_TRACKABLE_ENTITIES
         (abbreviation, name, type, baseline, codelevel, used_flag, load_flag)
     values (p_trackable_entity_name, p_trackable_entity_desc, p_type, p_te_level,
             p_baseline, p_used_status, p_load_status);
    end if;

    COMMIT;
    x_status := 'TRUE';

    EXCEPTION
     WHEN OTHERS THEN
        x_status := 'FALSE';
        RAISE;

   END set_te_info;

  /*
  ** IS_AD_TXK_ON_EBSSYS
  ** This function checks if ad/txk code level is
  ** compatible with ebssys codelevel.
  ** If codelevel for ad >=C.13 and txk >=C.13 and ebssys >=C.0 returns Y
  ** else returns N
  */
  function IS_AD_TXK_ON_EBSSYS return varchar2
  is
    L_IS_AD_TXK_ON_EBSSYS     varchar2(1) :='N';
  begin

    --Verifies if AD/TXK code level is compatible with ebssys codelevel
    --Invoke is_on_ebssys api with 'AD_TXK' as parameter
    l_is_ad_txk_on_ebssys := is_on_ebssys(ad_trackable_entities_pkg.C_AD_TXK);

    return l_is_ad_txk_on_ebssys;
  end IS_AD_TXK_ON_EBSSYS;

  /*
  ** IS_EBS_ON_EBSSYS
  ** This function checks if ebs code level is
  ** compatible with ebssys codelevel.
  ** If codelevel for ebssys >=C.1 returns Y
  ** else returns N
  */
  function IS_EBS_ON_EBSSYS  return varchar2
  is
    L_IS_EBS_ON_EBSYS  varchar2(1) :='N';
  begin

    --Verifies if ebs code level is compatible with ebssys codelevel.
    --Invoke is_on_ebssys with 'EBS' as parameter
    l_is_ebs_on_ebsys  := is_on_ebssys(ad_trackable_entities_pkg.C_EBS);

    return l_is_ebs_on_ebsys;
  end IS_EBS_ON_EBSSYS;

  /*
  ** IS_EBS_SYS_MIG
  ** This function checks if ebs system schema migration is
  ** complete.
  ** If codelevel for ebssys >=C.2 returns Y
  ** else returns N
  */
  function IS_EBS_SYS_MIG  return varchar2
  is
    L_IS_EBS_SYS_MIG   varchar2(1) :='N';
  begin

    --Verifies if ebs system schema migration is complete
    --Invoke is_on_ebssys with 'SYS_MIG' as parameter
    l_is_ebs_sys_mig  := is_on_ebssys(ad_trackable_entities_pkg.C_SYS_MIG);

    return l_is_ebs_sys_mig;
  end IS_EBS_SYS_MIG;

END AD_TRACKABLE_ENTITIES_PKG;
