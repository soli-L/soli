
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_FEATURE_VERS_PKG" AUTHID CURRENT_USER as
/* $Header: adufeats.pls 115.0 2003/03/01 19:07:52 vharihar ship $ */

procedure load_row
(
  p_feature_name       varchar2,
  p_db_version         number,
  p_enabled_flag       varchar2,
  p_rcs_file_keyword   varchar2,
  p_rcs_vers_keyword   varchar2
);


end ad_feature_vers_pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_FEATURE_VERS_PKG" as
/* $Header: adufeatb.pls 115.3 2003/04/10 21:19:38 vharihar ship $ */


--
-- Public program units
--

procedure load_row
(
  p_feature_name       varchar2,
  p_db_version         number,
  p_enabled_flag       varchar2,
  p_rcs_file_keyword   varchar2,
  p_rcs_vers_keyword   varchar2
)
is
  l_actual_filename varchar2(80) := null;      -- after stripping out RCS stuff
  l_actual_rcs_version varchar2(161) := null;  -- after stripping out RCS stuff

  l_curr_rcs_version varchar2(150) := null;    -- as recorded in DB

  l_colon_pos number := 0;
  l_len number := 0;
  l_num number := 0;
begin

  begin
    -- get the RCS filename
    -- eg. adufeatb.pls is embedded as '$RCSfile: adufeatb.pls,v $'
    --     (without the quotes)

    l_colon_pos := instr(p_rcs_file_keyword, ':');
    l_len := length(p_rcs_file_keyword);
    l_actual_filename := substr(p_rcs_file_keyword,
                                l_colon_pos+2, l_len - l_colon_pos - 5);

    -- get the RCS version
    -- eg. 115.1 is embedded as '$Revision: 115.3 $' (without the quotes)

    l_colon_pos := instr(p_rcs_vers_keyword, ':');
    l_len := length(p_rcs_vers_keyword);
    l_actual_rcs_version := substr(p_rcs_vers_keyword,
                                   l_colon_pos+2, l_len - l_colon_pos - 3);

    -- validate that its all numeric (strip out the dot (.))

    l_num := to_number(translate(l_actual_rcs_version,
                                 '0123456789.',
                                 '0123456789'));

    if nvl(l_num, 0) = 0 then
      raise VALUE_ERROR ;
    end if;

  exception when others then
    raise_application_error(-20000, 'Invalid RCS entry '||
                                 p_rcs_file_keyword||', '||p_rcs_vers_keyword);
  end;

  select rcs_version
  into l_curr_rcs_version
  from ad_feature_versions
  where feature_name = p_feature_name
  for update;

  if l_curr_rcs_version = '0' then
    -- Bootstrap code.

    -- These columns were just added, we need to populate them (ODF defaults
    -- the value of the FEATURE_NAME column into FILENAME, and '0' into
    -- RCS_VERSION)

    update ad_feature_versions
    set filename = l_actual_filename,
        rcs_version = l_actual_rcs_version
    where filename = p_feature_name;

    -- Bug 2890523: Also update feature version if needed.
    -- That is, if p_db_version is also greater than the one in the database,
    -- then update it.

    -- Note: Dont touch ENABLED_FLAG.

    update ad_feature_versions
    set current_db_version = p_db_version,
        last_update_date = sysdate
    where feature_name = p_feature_name
    and p_db_version > current_db_version;

    commit;

    return;

  end if;

  if not ad_patch.compare_versions(l_actual_rcs_version, l_curr_rcs_version)
  then

    -- l_actual_rcs_version is newer. Lets update.

    -- Note: (1) Dont touch ENABLED_FLAG.
    --       (2) Intentionally keep these as 2 separate UPDATE's, bcoz their
    --           WHERE clauses are a bit different. (Intentionally keeping
    --           the WHERE clause of the first update stmt (the RCS_VERSION
    --           one) as just a simple one on FEATURE_NAME, bcoz this column
    --           serves as just a parallel "checkfile" infrastructure. See
    --           bug 2899475 for details)
    --       (3) Leapfrogging not supported (ie. if a lower file version has
    --           a higher feature version, the feature version wouldn't get
    --           updated)

    update ad_feature_versions
    set rcs_version = l_actual_rcs_version,
        last_update_date = sysdate
    where feature_name = p_feature_name;


    -- Next, update the feature version if thats also newer.

    update ad_feature_versions
    set current_db_version = p_db_version,
        last_update_date = sysdate
    where feature_name = p_feature_name
    and p_db_version > current_db_version;

  end if;

  commit;

exception when no_data_found then
  insert into ad_feature_versions
  (
    feature_name, current_db_version, enabled_flag,
    filename, rcs_version,
    creation_date,last_update_date
  )
  values
  (
    p_feature_name, p_db_version, p_enabled_flag,
    l_actual_filename, l_actual_rcs_version,
    sysdate, sysdate
  );

  commit;

end load_row;


end ad_feature_vers_pkg;
