
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."ADX_PRF_PKG" AUTHID CURRENT_USER AS
 /* $Header: ADXPRFS.pls 120.0.12000000.2 2007/10/01 11:47:38 rdamodar ship $ */

--
-- PRINTLN (Internal)
--   Print messages as needed
-- IN
--    msg
--
procedure PRINTLN(msg in varchar2);

--
-- set_profile
--   Set Profile options via AutoConfig
-- IN
--   p_application_id
--   p_profile_option_name
--   p_level_id
--   p_level_value
--   p_profile_value
--   p_level_value_app_id
--   p_context_name
--   p_update_only
--   p_insert_only
--   p_level_value2
--
PROCEDURE set_profile(p_application_id      in number,
                        p_profile_option_name in varchar2,
                        p_level_id            in number,
                        p_level_value         in number,
                        p_profile_value       in varchar2,
                        p_level_value_app_id  in number,
                        p_context_name        in varchar2,
                        p_update_only         in boolean default FALSE,
                        p_insert_only         in boolean default FALSE,
                        p_level_value2        in varchar2 default NULL);

END  adx_prf_pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."ADX_PRF_PKG" AS
 /* $Header: ADXPRFB.pls 120.7.12020000.2 2013/07/25 16:17:42 srveerar ship $ */


--
-- PRINTLN (Internal)
--   Print messages as needed
-- IN
--    msg
--
procedure PRINTLN(msg in varchar2) is
begin
     dbms_output.put_line(msg);
end;

--
-- set_profile
--   Set Profile options via AutoConfig
-- IN
--   p_application_id
--   p_profile_option_name
--   p_level_id
--   p_level_value
--   p_profile_value
--   p_level_value_app_id
--   p_context_name
--   p_update_only
--   p_insert_only
--   p_level_value2
--
PROCEDURE set_profile(p_application_id      in number,
                      p_profile_option_name in varchar2,
                      p_level_id            in number,
                      p_level_value         in number,
                      p_profile_value       in varchar2,
                      p_level_value_app_id  in number,
                      p_context_name        in varchar2,
                      p_update_only         in boolean default FALSE,
                      p_insert_only         in boolean default FALSE,
                      p_level_value2        in varchar2 default NULL)
IS
    old_pv_rec fnd_profile_option_values%rowtype;
    level_value_app_id_temp number;
    level_name varchar2(30);
    update_flag varchar2(1);
    insert_flag varchar2(1);
    ret_value boolean;

BEGIN
     begin
      if (p_level_value2 is NULL) then
        select *
        into   old_pv_rec
        from   fnd_profile_option_values
        where  (application_id, profile_option_id) in (
          select application_id, profile_option_id
          from   fnd_profile_options
          where  application_id = p_application_id
          and    profile_option_name = p_profile_option_name)
          and    level_id = p_level_id;
      else
        select *
        into   old_pv_rec
        from   fnd_profile_option_values
        where  (application_id, profile_option_id) in (
          select application_id, profile_option_id
          from   fnd_profile_options
          where  application_id = p_application_id
          and    profile_option_name = p_profile_option_name)
          and    level_id = p_level_id
          and    level_value = p_level_value
          and    level_value2 = p_level_value2;
      end if;
     exception
        when no_data_found then null;
     end;

     declare
         tablename varchar2(100);
     begin
         select tname into tablename from tab where tname ='ADX_PRE_AUTOCONFIG' and tabtype in ('TABLE', 'SYNONYM');
     exception WHEN NO_DATA_FOUND THEN
          execute immediate 'create table APPLSYS.ADX_PRE_AUTOCONFIG (
             application_id           number,
             profile_option_name      varchar2(100),
             level_id                 number,
             level_value              number,
             profile_value            varchar2(300),
             level_value_app_id       number,
             context_name             varchar2(100),
             update_only              varchar2(1),
             insert_only              varchar2(1),
             level_value2             varchar2(100)
          )';

          execute immediate 'create synonym ADX_PRE_AUTOCONFIG for APPLSYS.ADX_PRE_AUTOCONFIG';
     end;

     level_value_app_id_temp := p_level_value_app_id;
     if level_value_app_id_temp = '' then
        level_value_app_id_temp := NULL;
     end if;

     -- convert parameters to type expected by FND API
     if (p_level_id  = 10001) then
         level_name := 'SITE';
     elsif (p_level_id = 10002) then
         level_name := 'APPL';
     elsif (p_level_id = 10003) then
         level_name := 'RESP';
     elsif (p_level_id = 10004) then
         level_name := 'USER';
     elsif (p_level_id = 10005) then
         level_name := 'SERVER';
     elsif (p_level_id = 10006) then
         level_name := 'ORG';
     elsif (p_level_id = 10007) then
         level_name := 'SERVRESP';
     end if;

     -- Setting update_only and insert_only based on the values passed
     if (p_insert_only = FALSE) then
       insert_flag := 'F';
       if (p_update_only = FALSE)then
         update_flag := 'F';
       else
         update_flag := 'T';
       end if;
     else
       insert_flag := 'T';
       if (p_update_only = FALSE) then
         update_flag := 'F';
       else
         update_flag := 'T';
       end if;
     end if;

     --
     -- Update the ADX_PRE_AUTOCONFIG table for rollback
     -- purposes.
     --
     declare
       str varchar2(700);
       countrow number;
     begin
       -- If the value is to be set at the SITE level
       if (p_level_value2 is NULL) then
         str := 'select count(*)
                 from ADX_PRE_AUTOCONFIG where
                 application_id=:1 and
                 profile_option_name=:2 and
                 level_id=:3  and
                 level_value=:4 and
                 context_name=:5 and
                 update_only= :6 and
                 insert_only= :7';
         execute immediate str INTO countrow
               using p_application_id, p_profile_option_name, p_level_id,
                     p_level_value, p_context_name,update_flag,insert_flag;

         if (countrow>0) then -- update table since row already exist
            str := 'update ADX_PRE_AUTOCONFIG set
                    profile_value=:1 where
                    application_id=:2 and profile_option_name=:3 and
                    level_id=:4 and level_value=:5 and
                    context_name=:6 and update_only=:7 and
                    insert_only=:8';
            execute immediate str
                  using old_pv_rec.profile_option_value, p_application_id,
                        p_profile_option_name, p_level_id, p_level_value,
                        p_context_name, update_flag, insert_flag;

         else  -- insert new row into table since one does not exist yet
            str:='insert into ADX_PRE_AUTOCONFIG
                  (application_id, profile_option_name,
                   level_id,level_value,profile_value,
                   level_value_app_id,context_name,
                   update_only,insert_only)
                  values(:1, :2, :3, :4, :5, :6, :7, :8, :9)';
            execute immediate str
                  using p_application_id, p_profile_option_name, p_level_id,
                        p_level_value, old_pv_rec.profile_option_value,
                        level_value_app_id_temp, p_context_name, update_flag,
                        insert_flag;
         end if;

         -- Call FND API to update/insert the profile option value in the
         -- fnd_profile_option_values table
         -- Note that for setting profiles at the SITE level
         -- the last 3 parameters defined in the SAVE api are not required.

         ret_value := FND_PROFILE.SAVE(p_profile_option_name,
                                       p_profile_value,
                                       level_name);
       else
         str:= 'select count(*)
                from ADX_PRE_AUTOCONFIG where
                application_id=:1 and
                profile_option_name=:2 and
                level_id=:3  and
                level_value=:4 and
                level_value_app_id=:5 and
                context_name=:6 and
                update_only= :7 and
                insert_only= :8 and
                level_value2= :9';
         execute immediate str INTO countrow
               using p_application_id, p_profile_option_name, p_level_id,
                     p_level_value, level_value_app_id_temp, p_context_name,
                     update_flag,insert_flag, p_level_value2;

         if (countrow>0) then -- update table since row already exist
            str := 'update ADX_PRE_AUTOCONFIG set
                    profile_value=:1 where
                    application_id=:2 and profile_option_name=:3 and
                    level_id=:4 and level_value=:5 and
                    level_value_app_id=:6 and
                    context_name=:7 and update_only=:8 and
                    insert_only=:9 and  level_value2=:10';
            execute immediate str
                  using old_pv_rec.profile_option_value, p_application_id,
                        p_profile_option_name, p_level_id, p_level_value,
                        level_value_app_id_temp, p_context_name, update_flag,
                        insert_flag, p_level_value2;

         else -- insert new row into table since one does not exist yet
           str:='insert into ADX_PRE_AUTOCONFIG
                 values(:1, :2, :3, :4, :5, :6, :7, :8, :9, :10)';
           execute immediate str
                 using p_application_id, p_profile_option_name, p_level_id,
                       p_level_value, old_pv_rec.profile_option_value,
                       level_value_app_id_temp, p_context_name, update_flag,
                       insert_flag, p_level_value2;
         end if;

         -- Call FND API to update/insert the profile option value in the
         -- fnd_profile_option_values table
         if (p_level_id = 10005)  then
                ret_value := FND_PROFILE.SAVE(p_profile_option_name,
                                             p_profile_value,
                                             level_name,
                                             p_level_value2);
         else
         	ret_value := FND_PROFILE.SAVE(p_profile_option_name,
                                       p_profile_value,
                                       level_name,
                                       p_level_value,
                                       p_level_value_app_id,
                                       p_level_value2);
	 end if;
       end if;

     end; -- of begin block

     if ret_value = TRUE then
        println('       ');
        println('[ ' || p_profile_option_name || ' ]');
        println(' Application Id : '||p_application_id);
        println(' Profile Value  : '||p_profile_value);
        println(' Level Name: '||level_name);
        println(' INFO           : Updated/created profile option value.');
        println('.       ');
     else
        println('       ');
        println('[ ' || p_profile_option_name || ' ]');
        println(' Application Id : '||p_application_id);
        println(' Profile Value  : '||p_profile_value);
        println(' Level Name  : '||level_name);
        println(' INFO           : Error updating/creating profile option value.');
           println('.       ');
     end if;

END; -- set_profile()


END adx_prf_pkg;