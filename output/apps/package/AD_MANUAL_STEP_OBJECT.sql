
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_MANUAL_STEP_OBJECT" AUTHID CURRENT_USER as
/* $Header: admsis.pls 120.4 2006/09/13 22:28:52 hxue noship $ */

   --
   -- Checks whether the manual step exists in history with the given
   -- version and status.
   --
   function manual_step_hist_exists(p_step_key varchar2,
                                    p_step_version varchar2,
                                    p_status char)
      return number;

   --
   -- Function that checks whether the manual steps is already applied in
   -- this instance.
   --
   function is_step_already_done(p_step_key varchar2,
                                 p_step_version varchar2)
      return number;

   --
   -- Procedure that adds manual steps in to ad_manual_step_history table
   -- with the given parameters.
   --
   procedure add_manual_step_history(p_patch_number varchar2,
                                     p_step_key varchar2,
                                     p_step_version varchar2,
                                     p_step_text varchar2,
                                     p_cond_code varchar2,
                                     p_username varchar2,
                                     p_status char);

   --
   -- Procedure that updates given manual steps as completed.
   --
   procedure update_step_as_completed(p_patch_number varchar2);

   --
   -- Function that checks whether the customer instance is on a
   -- codelevel passed.
   -- returns : 0, if the customer is not in that codelevel.
   --           1, if the customer is on or above the given codelevel
   --
   function is_on_codelevel (p_entity varchar2,
                             p_level varchar2)
      return number;

   --
   -- Function that checks whether the customer instance is on a
   -- baseline.
   -- returns : 0, if the customer is not in that baseline
   --           1, if the customer is on or above the given baseline.
   --
   function is_on_baseline (p_entity varchar2,
                            p_baseline varchar2)
      return number;

end ad_manual_step_object;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_MANUAL_STEP_OBJECT" as
/* $Header: admsib.pls 120.4.12000000.2 2007/03/16 13:43:38 nshahi ship $ */

   --
   -- Checks whether the manual step exists in history with the given
   -- version and status.
   --
   function manual_step_hist_exists(p_step_key varchar2,
                                    p_step_version varchar2,
                                    p_status char)
      return number is
         hist_count number :=0;
   begin
      select count(0) into hist_count
         from ad_manual_step_history
         where step_key = p_step_key and
         step_version = p_step_version and
         status = p_status;

      if hist_count > 0 then
         return 1;
       else
         return 0;
      end if;
   end manual_step_hist_exists;

   --
   -- Function that checks whether the manual steps is already applied in
   -- this instance.
   --
   function is_step_already_done(p_step_key varchar2,
                                 p_step_version varchar2)
      return number is
   begin
      return manual_step_hist_exists(p_step_key,
                                     p_step_version,
                                     'Y');
   end is_step_already_done;


   --
   -- Procedure that adds manual steps in to ad_manual_step_history table
   -- with the given parameters.
   --
   procedure add_manual_step_history(p_patch_number varchar2,
                                     p_step_key varchar2,
                                     p_step_version varchar2,
                                     p_step_text varchar2,
                                     p_cond_code varchar2,
                                     p_username varchar2,
                                     p_status char)
      is
         l_step_key varchar2(100);
      begin
         select step_key
            into l_step_key
            from ad_manual_step_history
            where step_key = p_step_key and
            step_version = p_step_version;

         update ad_manual_step_history
            set status = p_status,
            patch_number = p_patch_number
            where step_key = p_step_key and
            step_version = p_step_version;

      exception
         when NO_DATA_FOUND then
            insert into ad_manual_step_history
               (history_id, step_key, step_version,step_text, cond_code,
                patch_number, status, updated_by)
               values
               (ad_manual_step_history_s.nextval, p_step_key, p_step_version,
                p_step_text, p_cond_code, p_patch_number,
                p_status, p_username);
      end;

      --
      -- Procedure that updates given manual steps as completed.
      --
      procedure update_step_as_completed(p_patch_number varchar2) is
      begin
         update ad_manual_step_history
            set status = 'Y'
            where
            status='D' and patch_number=p_patch_number;
      end;

      --
      -- Function that checks whether the customer instance is on a
      -- codelevel passed.
      -- returns : 1, if the customer is not in that codelevel.
      --           0, if the customer is on or above the given codelevel
      --
      function is_on_codelevel (p_entity varchar2,
                                p_level varchar2)
         return number
         is
            l_level ad_trackable_entities.codelevel%type;
            l_baseline ad_trackable_entities.baseline%type;
            l_status varchar2(10);
      begin

         ad_trackable_entities_pkg.get_code_level(p_entity,
                                                  l_level,
                                                  l_baseline,
                                                  l_status);
         if (l_status = 'TRUE' and
             ad_patch_analysis_engine.compareLevel(p_level, l_level)=1) then
            return 1;
         end if;

         return 0;

      end;

      --
      -- Function that checks whether the customer instance is on a
      -- baseline.
      -- returns : 0, if the customer is not in that baseline
      --           1, if the customer is on or above the given baseline.
      --
      function is_on_baseline (p_entity varchar2,
                               p_baseline varchar2)
         return number
         is
            l_level ad_trackable_entities.codelevel%type;
            l_baseline ad_trackable_entities.baseline%type;
            l_status varchar2(10);
      begin

         ad_trackable_entities_pkg.get_code_level(p_entity,
                                                  l_level,
                                                  l_baseline,
                                                  l_status);
         if (l_status = 'TRUE' and
             ad_patch_analysis_engine.compareLevel(p_baseline,
                                                   l_baseline)=1) then
            return 0;
         end if;

         return 1;

      end;

end ad_manual_step_object;
