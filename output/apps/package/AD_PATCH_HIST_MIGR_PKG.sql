
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PATCH_HIST_MIGR_PKG" AUTHID CURRENT_USER as
/* $Header: adphmigs.pls 115.6 2002/02/26 17:12:54 pkm ship      $ */

procedure load_patch_driver
(
  p_src_ptch_drvr_id        number,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_cd                  varchar2,
  p_drv_typ_cflag           varchar2,
  p_drv_typ_dflag           varchar2,
  p_drv_typ_gflag           varchar2,
  p_plat                    varchar2,
  p_platver                 varchar2,
  p_orig_ptch_nm            varchar2,
  p_merged_driver_flag      varchar2,
  p_merge_date              date,
  p_src_ap_app_ptch_id      number,
  p_ap_ptch_nm              varchar2,
  p_ap_ptch_typ             varchar2,
  p_ap_mtpk_lvl             varchar2,
  p_ap_src_cd               varchar2,
  p_exported_from_db        varchar2,
  p_ap_rapid_installed_flag varchar2
);

procedure load_patch_driver_minipk
(
  p_src_cd                  varchar2,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_ptch_drvr_id        number,
  p_exported_from_db        varchar2,
  p_app_short_name          varchar2,
  p_patch_level             varchar2
);

procedure load_patch_driver_lang
(
  p_src_cd                  varchar2,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_ptch_drvr_id        number,
  p_exported_from_db        varchar2,
  p_language                varchar2
);

procedure load_comprising_patch
(
  p_src_cd                  varchar2,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_ptch_drvr_id        number,
  p_exported_from_db        varchar2,
  p_bug_number              varchar2,
  p_aru_release_name        varchar2
);

procedure load_patch_run
(
  p_start_date              date,
  p_at_nm                   varchar,
  p_apps_sys_nm             varchar,
  p_cache_appl_top_id       boolean,
  p_chksum                  number,
  p_filsiz                  number,
  p_filnm                   varchar,
  p_pd_src_cd               varchar,
  p_pr_patch_driver_id      number,
  p_exported_from_db        varchar,
  p_maj_v                   number,
  p_min_v                   number,
  p_tap_v                   number,
  p_rapid_install_flag      varchar,
  p_upd_to_maj_v            number,
  p_upd_to_min_v            number,
  p_upd_to_tap_v            number,
  p_patch_top               varchar,
  p_end_date                date,
  p_src_patch_run_id        number,
  p_patch_action_options    varchar,
  p_server_type_admin_flag  varchar,
  p_server_type_forms_flag  varchar,
  p_server_type_node_flag   varchar,
  p_server_type_web_flag    varchar,
  p_source_code             varchar,
  p_success_flag            varchar,
  p_failure_comments        varchar,
  p_record_against_rlse     varchar
);

procedure update_current_view_snapshot
(
  p_use_cache               boolean,
  p_start_date              date,
  p_at_nm                   varchar,
  p_apps_sys_nm             varchar,
  p_chksum                  number,
  p_filsiz                  number,
  p_filnm                   varchar,
  p_pd_src_cd               varchar,
  p_pr_patch_driver_id      number,
  p_exported_from_db        varchar
);

end ad_patch_hist_migr_pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PATCH_HIST_MIGR_PKG" as
/* $Header: adphmigb.pls 120.0 2005/05/25 11:58:23 appldev noship $ */

--
-- Private package globals
--
G_WHO_USER_ID constant number := 3;      -- 3 == Feeder system
G_CURRENT_RELEASE varchar2(30);
G_CURRENT_RELEASE_ID number;
G_REC_ALL_PTCHS_ON_RLSE_ID number;
G_IMPORT_SESSION_ID number;
G_APPL_TOP_ID number;
G_PATCH_RUN_ID number;
G_SNAPSHOT_MAINT_ALLOWED boolean;

--
-- Private program units
--
procedure init_rlse_info is
begin
  G_CURRENT_RELEASE := null;
  G_CURRENT_RELEASE_ID := null;
  G_REC_ALL_PTCHS_ON_RLSE_ID := null;
end init_rlse_info;

procedure initialize is
begin
  init_rlse_info;

  G_APPL_TOP_ID := null;
  G_PATCH_RUN_ID := null;
  G_SNAPSHOT_MAINT_ALLOWED := AD_FILE_SYS_SNAPSHOTS_PKG.Snapshot_Maint_Allowed;

  select fnd_concurrent_requests_s.currval
  into G_IMPORT_SESSION_ID
  from dual;
end initialize;

procedure bootstrap_release is
  l_rlse_id number;
  l1 number;
  l2 number;
  l3 number;
  l4 number;
begin
  -- Attempt to identify release only once

  if G_CURRENT_RELEASE is not null then
    return;
  end if;

  select release_name
  into G_CURRENT_RELEASE
  from fnd_product_groups;

  l1 := instr(G_CURRENT_RELEASE, '.');
  l2 := instr(G_CURRENT_RELEASE, '.', l1+1);
  l3 := instr(G_CURRENT_RELEASE, '.', l2+1);
  l4 := instr(G_CURRENT_RELEASE, '.', l3+1);

  -- Check that there are necessarily (and at most) 2 dots, and that too at
  -- valid places.
  if (l1 > 1 and l2>l1+1 and l3=0) OR
     (l1 > 1 and l2>l1+1 and l3>l2+1 and l4=0) then
    -- this is a good format. Re-compute l3 as length(p_release_name)
    l3 := length(G_CURRENT_RELEASE);
  else
    -- this is an invalid format. Error out
    raise_application_error(-20000, 'Invalid release - '||
                                    G_CURRENT_RELEASE);
  end if;

  AD_RELEASES_PVT.CreateRelease
  (
    p_major_version => to_number(substr(G_CURRENT_RELEASE, 1, l1-1)),
    p_minor_version => to_number(substr(G_CURRENT_RELEASE, l1+1, l2-l1-1)),
    p_tape_version => to_number(substr(G_CURRENT_RELEASE, l2+1, l3-l2)),
    p_row_src_comments => 'Created while migrating patch-history info',
    p_release_id => G_CURRENT_RELEASE_ID,
    p_base_rel_flag   =>  'N',
    p_start_dt        => sysdate,
    p_created_by_user_id => -1
  );

end bootstrap_release;

function identify_patch_driver_only
(
  p_src_cd                  varchar2,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_ptch_drvr_id        number,
  p_exported_from_db        varchar2
) return number is
  l_patch_driver_id number;
begin
  if p_src_cd = 'DRV' then

    -- An actual driver (as opposed to a dummy one uploaded from applptch.txt.
    -- In this case, we check on checksum, etc

    select patch_driver_id
    into l_patch_driver_id
    from ad_patch_drivers
    where file_contents_checksum = p_chksum
    and file_size = p_fil_size
    and driver_file_name = p_drv_fil_nm;

    return l_patch_driver_id;

  else

    -- uploaded info (from applptch.txt)
    -- In this case, we check if its ever been export-imported before

    select patch_driver_id
    into l_patch_driver_id
    from ad_patch_drivers
    where imported_from_db = p_exported_from_db
    and imported_id = p_src_ptch_drvr_id;

  end if;   -- end if src-cd = DRV/TXT

  return l_patch_driver_id;

exception when no_data_found then
  return null;
end identify_patch_driver_only;


--
-- Public program units
--
procedure load_patch_driver
(
  p_src_ptch_drvr_id        number,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_cd                  varchar2,
  p_drv_typ_cflag           varchar2,
  p_drv_typ_dflag           varchar2,
  p_drv_typ_gflag           varchar2,
  p_plat                    varchar2,
  p_platver                 varchar2,
  p_orig_ptch_nm            varchar2,
  p_merged_driver_flag      varchar2,
  p_merge_date              date,
  p_src_ap_app_ptch_id      number,
  p_ap_ptch_nm              varchar2,
  p_ap_ptch_typ             varchar2,
  p_ap_mtpk_lvl             varchar2,
  p_ap_src_cd               varchar2,
  p_exported_from_db        varchar2,
  p_ap_rapid_installed_flag varchar2
) is
  l_applied_patch_id number;
  l_patch_driver_id number;
begin
  l_patch_driver_id := identify_patch_driver_only(p_src_cd,
                                     p_chksum, p_fil_size, p_drv_fil_nm,
                                     p_src_ptch_drvr_id, p_exported_from_db);

  if l_patch_driver_id is not null then
    -- Bingo! Found a patch-driver. Simply return.

    return;
  end if;


  -- Got here => absolutely no record of the patch-driver

  begin
    select applied_patch_id
    into l_applied_patch_id
    from ad_applied_patches
    where imported_from_db = p_exported_from_db
    and imported_id = p_src_ap_app_ptch_id;

    -- Found an APP-PTCH => only need to create a PTCH-DRVR for that APP-PTCH

    insert into ad_patch_drivers
    (
      patch_driver_id,
      applied_patch_id, driver_file_name,
      driver_type_c_flag, driver_type_d_flag, driver_type_g_flag,
      platform, platform_version,
      file_size, file_contents_checksum,
      source_code, orig_patch_name,
      merged_driver_flag, merge_date,
      creation_date, last_update_date, last_updated_by, created_by,
      imported_flag, imported_from_db, imported_id
    ) values
    (
      ad_patch_drivers_s.nextval,
      l_applied_patch_id, p_drv_fil_nm,
      p_drv_typ_cflag, p_drv_typ_dflag, p_drv_typ_gflag,
      p_plat, p_platver,
      p_fil_size, p_chksum,
      p_src_cd, p_orig_ptch_nm,
      p_merged_driver_flag, p_merge_date,
      sysdate, sysdate, G_WHO_USER_ID, G_WHO_USER_ID,
      'Y', p_exported_from_db, p_src_ptch_drvr_id
    );

    return;

  exception when no_data_found then

    -- Need to create an APP-PTCH as well as a PTCH-DRVR row

    insert into ad_applied_patches
    (
      applied_patch_id,
      rapid_installed_flag, patch_name,
      patch_type, maint_pack_level, source_code,
      creation_date, last_update_date, last_updated_by, created_by,
      imported_flag, imported_from_db,
      imported_id
    ) values
    (
      ad_applied_patches_s.nextval,
      p_ap_rapid_installed_flag, p_ap_ptch_nm,
      p_ap_ptch_typ, p_ap_mtpk_lvl, p_ap_src_cd,
      sysdate, sysdate, G_WHO_USER_ID, G_WHO_USER_ID,
      'Y', p_exported_from_db, p_src_ap_app_ptch_id
    ) returning applied_patch_id into l_applied_patch_id;

    insert into ad_patch_drivers
    (
      patch_driver_id,
      applied_patch_id, driver_file_name,
      driver_type_c_flag, driver_type_d_flag, driver_type_g_flag,
      platform, platform_version,
      file_size, file_contents_checksum,
      source_code, orig_patch_name,
      merged_driver_flag, merge_date,
      creation_date, last_update_date, last_updated_by, created_by,
      imported_flag, imported_from_db, imported_id
    ) values
    (
      ad_patch_drivers_s.nextval,
      l_applied_patch_id, p_drv_fil_nm,
      p_drv_typ_cflag, p_drv_typ_dflag, p_drv_typ_gflag,
      p_plat, p_platver,
      p_fil_size, p_chksum,
      p_src_cd, p_orig_ptch_nm,
      p_merged_driver_flag, p_merge_date,
      sysdate, sysdate, G_WHO_USER_ID, G_WHO_USER_ID,
      'Y', p_exported_from_db, p_src_ptch_drvr_id
    );

  end;
end load_patch_driver;

procedure load_patch_driver_minipk
(
  p_src_cd                  varchar2,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_ptch_drvr_id        number,
  p_exported_from_db        varchar2,
  p_app_short_name          varchar2,
  p_patch_level             varchar2
) is
  l_patch_driver_id number;
  l_dummy varchar2(1);
  l_true_app_short_name varchar2(50);
begin
  -- identify the PTCH-DRVR row

  l_patch_driver_id := identify_patch_driver_only(p_src_cd,
                                     p_chksum, p_fil_size, p_drv_fil_nm,
                                     p_src_ptch_drvr_id, p_exported_from_db);

  if l_patch_driver_id is null then
    raise_application_error(-20000, 'PTCH-DRVR not yet identified!');
  end if;

  -- Then, insert a MINIPK row if it doesnt already exist

  begin
    -- make it tolerant to prod-abbrevs too
    if p_app_short_name = 'gl' then
      l_true_app_short_name := 'SQLGL';
    elsif p_app_short_name = 'ap' then
      l_true_app_short_name := 'SQLAP';
    elsif p_app_short_name = 'fa' then
      l_true_app_short_name := 'OFA';
    elsif p_app_short_name = 'so' then
      l_true_app_short_name := 'SQLSO';
    else
      l_true_app_short_name := upper(p_app_short_name);
    end if;

    select 'x'
    into l_dummy
    from ad_patch_driver_minipks
    where patch_driver_id = l_patch_driver_id
    and app_short_name = l_true_app_short_name;

    return;

  exception when no_data_found then

    insert into ad_patch_driver_minipks
    (
      minipk_id, patch_driver_id,
      app_short_name, patch_level,
      creation_date, last_update_date, last_updated_by, created_by
    ) values
    (
      ad_patch_driver_minipks_s.nextval, l_patch_driver_id,
      l_true_app_short_name, p_patch_level,
      sysdate, sysdate, G_WHO_USER_ID, G_WHO_USER_ID
    );

  end;

end load_patch_driver_minipk;

procedure load_patch_driver_lang
(
  p_src_cd                  varchar2,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_ptch_drvr_id        number,
  p_exported_from_db        varchar2,
  p_language                varchar2
) is
  l_patch_driver_id number;
  l_dummy varchar2(1);
begin
  -- identify the PTCH-DRVR row

  l_patch_driver_id := identify_patch_driver_only(p_src_cd,
                                     p_chksum, p_fil_size, p_drv_fil_nm,
                                     p_src_ptch_drvr_id, p_exported_from_db);

  if l_patch_driver_id is null then
    raise_application_error(-20000, 'PTCH-DRVR not yet identified!');
  end if;

  -- Then, insert a LANG row if it doesnt already exist

  begin
    select 'x'
    into l_dummy
    from ad_patch_driver_langs
    where patch_driver_id = l_patch_driver_id
    and language = p_language;

    return;

  exception when no_data_found then

    insert into ad_patch_driver_langs
    (
      lang_id, patch_driver_id, language,
      creation_date, last_update_date, last_updated_by, created_by
    ) values
    (
      ad_patch_driver_langs_s.nextval, l_patch_driver_id, p_language,
      sysdate, sysdate, G_WHO_USER_ID, G_WHO_USER_ID
    );

  end;

end load_patch_driver_lang;

procedure load_comprising_patch
(
  p_src_cd                  varchar2,
  p_chksum                  number,
  p_fil_size                number,
  p_drv_fil_nm              varchar2,
  p_src_ptch_drvr_id        number,
  p_exported_from_db        varchar2,
  p_bug_number              varchar2,
  p_aru_release_name        varchar2
) is
  l_patch_driver_id number;
  l_bug_id number;
  l_dummy varchar2(1);
begin
  if p_bug_number is null then
    return;
  end if;

  -- identify the PTCH-DRVR row

  l_patch_driver_id := identify_patch_driver_only(p_src_cd,
                                     p_chksum, p_fil_size, p_drv_fil_nm,
                                     p_src_ptch_drvr_id, p_exported_from_db);

  if l_patch_driver_id is null then
    raise_application_error(-20000, 'PTCH-DRVR not yet identified!');
  end if;

  select bug_id
  into l_bug_id
  from ad_bugs
  where bug_number = p_bug_number
  and aru_release_name = p_aru_release_name;

  -- Then, insert a COMPRSNG-PTCH row if it doesnt already exist

  begin
    select 'x'
    into l_dummy
    from ad_comprising_patches
    where patch_driver_id = l_patch_driver_id
    and bug_id = l_bug_id;

    return;

  exception when no_data_found then

    insert into ad_comprising_patches
    (
      comprising_patch_id, patch_driver_id, bug_id,
      creation_date, last_update_date, last_updated_by, created_by
    ) values
    (
      ad_comprising_patches_s.nextval, l_patch_driver_id, l_bug_id,
      sysdate, sysdate, G_WHO_USER_ID, G_WHO_USER_ID
    );

  end;

end load_comprising_patch;


procedure load_patch_run
(
  p_start_date              date,
  p_at_nm                   varchar,
  p_apps_sys_nm             varchar,
  p_cache_appl_top_id       boolean,
  p_chksum                  number,
  p_filsiz                  number,
  p_filnm                   varchar,
  p_pd_src_cd               varchar,
  p_pr_patch_driver_id      number,
  p_exported_from_db        varchar,
  p_maj_v                   number,
  p_min_v                   number,
  p_tap_v                   number,
  p_rapid_install_flag      varchar,
  p_upd_to_maj_v            number,
  p_upd_to_min_v            number,
  p_upd_to_tap_v            number,
  p_patch_top               varchar,
  p_end_date                date,
  p_src_patch_run_id        number,
  p_patch_action_options    varchar,
  p_server_type_admin_flag  varchar,
  p_server_type_forms_flag  varchar,
  p_server_type_node_flag   varchar,
  p_server_type_web_flag    varchar,
  p_source_code             varchar,
  p_success_flag            varchar,
  p_failure_comments        varchar,
  p_record_against_rlse     varchar
) is
  l_at_id number;
  l_upd_to_rlse_id number;
  l_patch_run_id number;
  l_patch_driver_id number;
  l_rec_this_ptch_on_rlse_id number;
begin

  -- code that should run upon the upload of the 1st PATCH_RUN *only*

  if G_CURRENT_RELEASE_ID is null then
    begin
      bootstrap_release;

      if p_record_against_rlse is not null then
        begin
          select release_id
          into G_REC_ALL_PTCHS_ON_RLSE_ID
          from ad_releases
          where major_version = p_maj_v
          and minor_version = p_min_v
          and to_char(major_version)||'.'||to_char(minor_version)||'.'||
              to_char(tape_version) = p_record_against_rlse;
        exception when no_data_found then
          raise_application_error(-20000,
'Invalid release. Illegal to request loader to record patches against '''||
                                  p_record_against_rlse||'''');
        end;
      end if;

    exception when others then
      -- Reset the pkg globals, else if some are set but others aren't, then
      -- uploads of subsequent entities is unreliable. Resetting to null
      -- ensures that this piece of code is re-attempted for the next
      -- entity, and if it fails there, then it may well keep failing for
      -- all entities, but thats still better than silently proceeding and
      -- creating bad data.

      init_rlse_info;

      raise;
    end;
  end if;

  if p_cache_appl_top_id and G_APPL_TOP_ID is not null then
    l_at_id := G_APPL_TOP_ID;
  else
    begin
      select appl_top_id
      into l_at_id
      from ad_appl_tops
      where name = p_at_nm
      and appl_top_type = 'R'    -- only REAL appl-top's
      and applications_system_name = p_apps_sys_nm;

      if p_cache_appl_top_id then
        G_APPL_TOP_ID := l_at_id;
      end if;

    exception when no_data_found then
      raise_application_error(-20000, 'APPL-TOP not yet identified!');
    end;
  end if;

  -- identify the PTCH-DRVR row

  l_patch_driver_id := identify_patch_driver_only(p_pd_src_cd,
                                    p_chksum, p_filsiz, p_filnm,
                                    p_pr_patch_driver_id, p_exported_from_db);

  if l_patch_driver_id is null then
    raise_application_error(-20000, 'PTCH-DRVR not yet identified!');
  end if;

  begin
    select patch_run_id
    into l_patch_run_id
    from ad_patch_runs
    where start_date = p_start_date
    and appl_top_id = l_at_id
    and patch_driver_id = l_patch_driver_id;

    G_PATCH_RUN_ID := l_patch_run_id;

    return;

  exception when no_data_found then

    -- Need to insert a patch-run

    -- Determine the release against which we will record this patch
    if p_record_against_rlse is null then
      begin
        select release_id
        into l_rec_this_ptch_on_rlse_id
        from ad_releases
        where major_version = p_maj_v
        and minor_version = p_min_v
        and tape_version = p_tap_v;
      exception when no_data_found then
        l_rec_this_ptch_on_rlse_id := G_CURRENT_RELEASE_ID;
      end;
    else
      l_rec_this_ptch_on_rlse_id := G_REC_ALL_PTCHS_ON_RLSE_ID;
    end if;

    if p_upd_to_maj_v is null then
      l_upd_to_rlse_id := null;
    else
      begin
        select release_id
        into l_upd_to_rlse_id
        from ad_releases
        where major_version = p_upd_to_maj_v
        and minor_version = p_upd_to_min_v
        and tape_version = p_upd_to_tap_v;

        -- Make sure that no other patch already exists that has this value
        -- in UPDTD-TO-RLSE-ID (there is a unique index). If one exists, then
        -- that probably is the right one, in which case we wipe out
        -- l_upd_to_rlse_id. If it doesn't exist, then its safe to continue
        -- using l_upd_to_rlse_id to populate UPDTD-TO-RLSE-ID for this patch.
        begin
          select null
          into l_upd_to_rlse_id
          from ad_patch_runs
          where updated_to_release_id = l_upd_to_rlse_id;
        exception when no_data_found then
          null;
        end;
      exception when no_data_found then
        -- It doesn't exist. Wipe it out. (Premise 1: we aren't in the business
        -- of creating rlse recs here (other than base-rlse and cur-rlse))
        l_upd_to_rlse_id := null;
      end;
    end if;

    insert into ad_patch_runs
    (
      patch_run_id,
      release_id,
      session_id,
      rapid_install_flag,
      updated_to_release_id,
      patch_top,
      start_date, end_date,
      patch_driver_id,
      patch_action_options,
      appl_top_id,
      server_type_admin_flag, server_type_forms_flag,
      server_type_node_flag, server_type_web_flag,
      source_code,
      success_flag, failure_comments,
      imported_flag, imported_from_db, imported_id, import_session_id,
      creation_date, last_update_date, last_updated_by, created_by
    )
    values
    (
      ad_patch_runs_s.nextval,
      l_rec_this_ptch_on_rlse_id,
      ad_sessions_s.nextval,
      p_rapid_install_flag,
      l_upd_to_rlse_id,
      p_patch_top,
      p_start_date, p_end_date,
      l_patch_driver_id,
      p_patch_action_options,
      l_at_id,
      p_server_type_admin_flag, p_server_type_forms_flag,
      p_server_type_node_flag, p_server_type_web_flag,
      p_source_code,
      p_success_flag, p_failure_comments,
      'Y', p_exported_from_db, p_src_patch_run_id, G_IMPORT_SESSION_ID,
      sysdate, sysdate, G_WHO_USER_ID, G_WHO_USER_ID
    ) returning patch_run_id into G_PATCH_RUN_ID;

  end;

end load_patch_run;


procedure update_current_view_snapshot
(
  p_use_cache               boolean,
  p_start_date              date,
  p_at_nm                   varchar,
  p_apps_sys_nm             varchar,
  p_chksum                  number,
  p_filsiz                  number,
  p_filnm                   varchar,
  p_pd_src_cd               varchar,
  p_pr_patch_driver_id      number,
  p_exported_from_db        varchar
) is
  l_at_id number;
  l_pr_id number;
  l_pd_id number;
begin

  if not G_SNAPSHOT_MAINT_ALLOWED then
    return;
  end if;

  if p_use_cache and G_APPL_TOP_ID is not null and
                     G_PATCH_RUN_ID is not null then
    l_at_id := G_APPL_TOP_ID;
    l_pr_id := G_PATCH_RUN_ID;
  else

    select appl_top_id
    into l_at_id
    from ad_appl_tops
    where name = p_at_nm
    and appl_top_type = 'R'    -- only REAL appl-top's
    and applications_system_name = p_apps_sys_nm;

    -- identify the PTCH-DRVR row

    l_pd_id := identify_patch_driver_only(p_pd_src_cd,
                                     p_chksum, p_filsiz, p_filnm,
                                     p_pr_patch_driver_id, p_exported_from_db);

    if l_pd_id is null then
      raise_application_error(-20000, 'PTCH-DRVR not yet identified!');
    end if;

    select patch_run_id
    into l_pr_id
    from ad_patch_runs
    where start_date = p_start_date
    and appl_top_id = l_at_id
    and patch_driver_id = l_pd_id;

  end if;

  -- call the updt-curr-vw-snapshot API

  delete from ad_ptch_hst_exe_cop_tmp;    -- to clear prev ptch-run's info

  AD_FILE_SYS_SNAPSHOTS_PKG.Update_Current_View(l_pr_id, l_at_id);

end update_current_view_snapshot;


-- package initializer
begin
  initialize;
end ad_patch_hist_migr_pkg;
