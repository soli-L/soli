
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PATCH_LEVEL" AUTHID CURRENT_USER as
/*$Header: adplvls.pls 115.0 2004/04/07 13:10:40 sshivara noship $ */

-- Procedure GET_PATCH_LEVEL (apps_short_name (IN), FP_LEVEL (out))
-- This procedure takes an application_short_name (case insensitive)
-- and passes back the level.

procedure get_patch_level(apps_short_name in         varchar2,
                          fp_level        out nocopy varchar2);



-- Procedure GET_RELEASELEVEL (apps_release_level (out))
-- This procedure passes back the release level.

procedure get_release_level(apps_release_level out nocopy varchar2);


-- Procedure compare releases. Copied from AD_PATCH.compare_versions()
-- Compare passed release_levels.
--
-- Result:
--
-- -1 release_1 < release_2
--  0 release_1 = release_2
--  1 release_1 > release_2
--

procedure compare_release_levels(release_1 in  varchar2,
                                 release_2 in  varchar2,
                                 result    out nocopy number);



-- Procedure compare patch_levels.
--
-- Result:
--
-- -1 patchlevel_1 < patchlevel_2
--  0 patchlevel_1 = patchlevel_2
--  1 patchlevel_1 > patchlevel_2
--


procedure compare_patch_levels(patchlevel_1 in  varchar2,
                                 patchlevel_2 in  varchar2,
                                 result    out nocopy number);

end ad_patch_level;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PATCH_LEVEL" as
/*$Header: adplvlb.pls 115.1 2004/06/01 10:51:13 sallamse noship $ */

-- Procedure GET_PATCH_LEVEL (apps_short_name (IN), FP_LEVEL (out))
-- This procedure takes an application_short_name (case insensitive)
-- and passes back the level.


procedure get_patch_level(apps_short_name in  varchar2,
                          fp_level        out nocopy varchar2)
is
  c                     integer;
  rows_processed        integer;
  c_statement           varchar2(500);
  l_patch_level         varchar2(30);

begin

  c := dbms_sql.open_cursor;

  c_statement:= 'SELECT PI.PATCH_LEVEL FROM ' ||
                'FND_PRODUCT_INSTALLATIONS PI, FND_APPLICATION FA ' ||
                'WHERE FA.APPLICATION_ID = PI.APPLICATION_ID AND ' ||
                'UPPER(APPLICATION_SHORT_NAME)=' ||
                'UPPER(:short_name)';

  dbms_sql.parse(c, c_statement, dbms_sql.native);
  dbms_sql.bind_variable(c,'short_name',apps_short_name);
  dbms_sql.define_column(c,1,l_patch_level,30);

  rows_processed := dbms_sql.execute(c);

  if dbms_sql.fetch_rows(c) > 0 then
      dbms_sql.column_value(c,1,l_patch_level);
  else
      raise no_data_found;
  end if;

  dbms_sql.close_cursor(c);

  fp_level := l_patch_level;

exception
    when others then
      dbms_sql.close_cursor(c);
      raise;
end;



-- Procedure GET_RELEASELEVEL (apps_release_level (out))
-- This procedure passes back the release level.


procedure get_release_level(apps_release_level out nocopy varchar2)
is
  c                     integer;
  rows_processed        integer;
  c_statement           varchar2(500);
  l_release_name        varchar2(50);

begin

  c := dbms_sql.open_cursor;

  c_statement:= 'SELECT RELEASE_NAME FROM ' ||
                'FND_PRODUCT_GROUPS WHERE PRODUCT_GROUP_ID=1';

  dbms_sql.parse(c, c_statement, dbms_sql.native);
  dbms_sql.define_column(c,1,l_release_name,30);

  rows_processed := dbms_sql.execute(c);

  if dbms_sql.fetch_rows(c) > 0 then
      dbms_sql.column_value(c,1,l_release_name);
  else
      raise no_data_found;
  end if;

  dbms_sql.close_cursor(c);

  apps_release_level := l_release_name;

exception
    when others then
      dbms_sql.close_cursor(c);
      raise;
end;




-- Procedure compare releases. Copied from AD_PATCH.compare_versions()
-- Compare passed release_levels.
--
-- Result:
--
-- -1 release_1 < release_2
--  0 release_1 = release_2
--  1 release_1 > release_2
--


procedure compare_release_levels(release_1 in  varchar2,
                                release_2 in  varchar2,
                                result    out nocopy number)
is

  release_1_str  varchar2(132);
  release_2_str  varchar2(132);
  release_1_ver number;
  release_2_ver number;
  ret_status number            :=0;

begin
  release_1_str   := release_1 || '.';
  release_2_str   := release_2 || '.';

  while release_1_str is not null or release_2_str is not null loop

      -- Parse out a version from release_1

      if (release_1_str is null) then
         release_1_ver := 0;
      else
         release_1_ver := nvl(to_number(substr(release_1_str,1,
                             instr(release_1_str,'.')-1)),-1);
         release_1_str := substr(release_1_str,instr(release_1_str,'.')+1);
      end if;

      -- Next parse out a version from release_2

      if (release_2_str is null)
      then
        release_2_ver := 0;
      else
        release_2_ver := nvl(to_number(substr(release_2_str,1,
                             instr(release_2_str,'.')-1)),-1);
        release_2_str := substr(release_2_str,instr(release_2_str,'.')+1);
      end if;


      if (release_1_ver > release_2_ver)
      then
        ret_status := 1;
        result     := ret_status;
        exit;
      elsif (release_1_ver < release_2_ver)
      then
        ret_status := -1;
        result     := ret_status;
        exit;
      end if;

      -- Otherwise continue to loop.

  end loop;

  result := ret_status;

end compare_release_levels;

-- Procedure compare patch levels.
--
-- Result:
--
-- -1 patchlevel_1 < patchlevel_2
--  0 patchlevel_1 = patchlevel_2
--  1 patchlevel_1 > patchlevel_2
--


procedure compare_patch_levels(patchlevel_1 in  varchar2,
                               patchlevel_2 in  varchar2,
                               result       out nocopy number)
is

  ret_status number            :=0;

begin

  if (UPPER(TRIM(patchlevel_1)) < UPPER(TRIM(patchlevel_2 )))
  then
    ret_status := -1;
    result     := ret_status;
  elsif (UPPER(TRIM(patchlevel_1)) > UPPER(TRIM(patchlevel_2 )))
  then
    ret_status := 1;
    result     := ret_status;
  else
    ret_status := 0;
    result     := ret_status;
  end if;

end compare_patch_levels;

end ad_patch_level;
