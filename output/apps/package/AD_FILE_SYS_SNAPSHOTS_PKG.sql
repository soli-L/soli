
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_FILE_SYS_SNAPSHOTS_PKG" AUTHID CURRENT_USER as
/* $Header: adfssnps.pls 120.0.12020000.2 2012/07/09 17:54:54 mkumandu ship $ */

-- ACTION code to use when inserting into the temp table for use with
-- update_current_view() with p_patch_runs_spec = 'IN_TEMP_TAB'

G_PR_ID_ACT_CD constant number := 20;


-- return codes when instantiating a current-view snapshot

G_SNAPSHOT_MAINT_DISALLOWED  constant varchar2(2) := 'NA';
G_ALREADY_INSTANTIATED       constant varchar2(2) := 'AI';
G_NO_PRESEEDED_BASELINE      constant varchar2(3) := 'NPB';
G_INSTANTIATED_SNAPSHOT      constant varchar2(2) := 'IS';
G_INSTANTIATED_SNAPSHOT_BUGS constant varchar2(3) := 'ISB';


function  get_snapshot_type (p_snapshot_name in varchar2)
                             return varchar2;

-- Returns TRUE if we are allowed to maintain snapshots (using a temporary
-- strategy)
function snapshot_maint_allowed return boolean;

-- Update curr-vw snapshot using info from a single patch run
--   Pre-req: Temp table AD_PTCH_HST_EXE_COP_TMP must be empty
procedure update_current_view
           (p_patch_run_id number,
            p_appl_top_id  number default null);

-- Update curr-vw snapshot using info from a set of patch runs
--   Pre-req: Temp table AD_PTCH_HST_EXE_COP_TMP must be populated with
--            (only) the patch-run-id's (if called in IN_TEMP_TAB mode)


-- patch-runs specifier: 'IN_TEMP_TAB' or 'ALL'
procedure update_current_view
           (p_patch_runs_spec          varchar2,
            p_appl_top_id              number,
            p_caller_is_managing_locks boolean);

-- Instantiate a current-view
-- Note: See return-code "constants" above.
-- Note2: This procedure ALWAYS commits.
procedure instantiate_current_view
           (p_release_id                           number,
            p_appl_top_id                          number,
            p_fail_if_no_preseeded_rows            boolean default TRUE,
            p_caller_is_managing_locks             boolean default FALSE,
            p_return_code               out nocopy varchar2);

-- BUG 3402506  - sallamse , 02-03-04
-- Backfill the current-view snapshot if necessary.
-- Note: See return-code "constants" above.
-- Note2: This procedure ALWAYS commits.
procedure backfill_bugs_from_patch_hist
           (p_snapshot_id number);

procedure update_rel_name(rel_name varchar2);

end ad_file_sys_snapshots_pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_FILE_SYS_SNAPSHOTS_PKG" as
/* $Header: adfssnpb.pls 120.3.12020000.5 2021/01/24 18:42:07 mkumandu ship $ */


--
-- Private types
--
type NUM_TAB is table of number;
type VC1_TAB is table of varchar2(1);

--
-- Private program units
--

-- APPLSYS schema name

G_UN_FND varchar2(30) := null;

-- ACTION code for internal use only

G_PR_ID_ACT_CD2 constant number := 200;

g_current_snapshot_type varchar2(1);
g_global_snapshot_type varchar2(1);

--
--
-- Debug utils START
--
G_DEBUG constant boolean := FALSE;  --%%set to FALSE in production code

procedure put_line
           (msg varchar2, len number default 80)
is
  n number := 1;
  nmax number;
begin
  nmax := nvl(length(msg), 0);
  if not G_DEBUG then
    return;
  end if;

  loop
--  dbms_output.put_line(substr(msg, n, len)); --%%comment out in prodn code
    n := n + len;
    exit when n > nmax;
  end loop;
end put_line;
--
-- Debug utils END
--
--
function  get_snapshot_type (p_snapshot_name in varchar2)
                             return varchar2
is
flag boolean;
begin
  if (ad_zd.is_editions_enabled = 'N' or
      sys_context('userenv', 'current_edition_name') = ad_zd.get_edition('RUN'))
  then
    g_current_snapshot_type := 'C';
    g_global_snapshot_type := 'G';
  else
    g_current_snapshot_type := 'P';
    g_global_snapshot_type := 'Q';
  end if;

 if (p_snapshot_name = 'CURRENT_VIEW')
 then
    return g_current_snapshot_type;
 elsif (p_snapshot_name = 'GLOBAL_VIEW')
 then
    return g_global_snapshot_type;
 else
    raise_application_error(-20001, 'Invalid Snapshot Name <'
                                   ||p_snapshot_name||'>');
 end if;
end get_snapshot_type;

procedure handle_bugs
           (p_action_code         varchar2,
            p_update_global_view  boolean,
            p_snapshot_id         number,
            p_global_snapshot_id  number,
            p_delete_junk_created boolean)
 is
  L_BUGSTAT_EXPL_ACT_CD constant number := 15;  -- bug fix row: EXPLICIT status
  L_ADPBNAAS constant varchar2(20) := 'No active actions';

  l_snapshot_bugs_inserted number := 0;
  l_gathered_stats_flag    boolean := FALSE;
  l_snapshot_count         number;
  l_global_snapshot_count  number;
  l_global_snapshot_id     number;
begin
  -- Gather stats on the temp table at the start (it may have stats from its
  -- prior use. For that, first commit.

  commit;

  fnd_stats.gather_table_stats(G_UN_FND, 'ad_patch_hist_snaps_temp');

  if G_DEBUG then
    put_line('Inserting candidate bugs into temp table');
  end if;

  --bug3537094. The following insert should be used instead
  --Also removed 2 delete stmt which deletes unknown and duplicate
  --rows from ad_patch_hist_snaps_temp

  insert into ad_patch_hist_snaps_temp (action_code, bug_id)
  select distinct L_BUGSTAT_EXPL_ACT_CD, prb.bug_id
  from ad_patch_run_bugs prb, ad_patch_hist_snaps_temp t
  where prb.patch_run_id = t.patch_run_id
  and t.action_code = p_action_code
  and (prb.applied_flag = 'Y' or prb.reason_not_applied = L_ADPBNAAS);

  if G_DEBUG then
    put_line('Inserted '||to_char(sql%rowcount)||
             ' candidate bugs into temp table');
  end if;

  commit;

  -- Now gather stats.

  if G_DEBUG then
    put_line('Gathering stats');
  end if;

  FND_STATS.Gather_Table_Stats(G_UN_FND, 'ad_patch_hist_snaps_temp');

  if G_DEBUG then
    put_line('Inserting new bugfixes in the curr-vw snapshot');
  end if;

  -- Insert new ones
  insert into ad_snapshot_bugfixes
  (
    snapshot_bug_id,
    snapshot_id,
    bugfix_id,
    bug_status,
    success_flag,
    creation_date, last_update_date, last_updated_by, created_by
  )
  select
    ad_snapshot_bugfixes_s.nextval,
    p_snapshot_id,
    t.bug_id,
    'EXPLICIT',
    'Y',
    sysdate, sysdate, 5, 5
  from ad_patch_hist_snaps_temp t
  where t.action_code = L_BUGSTAT_EXPL_ACT_CD
  and not exists (select 'Bug not yet recorded in the curr-vw'
                  from ad_snapshot_bugfixes sb2
                  where sb2.snapshot_id = p_snapshot_id
                  and sb2.bugfix_id = t.bug_id);

  l_snapshot_bugs_inserted := sql%rowcount;

  if G_DEBUG then
    put_line('Inserted '||to_char(l_snapshot_bugs_inserted)||
             ' new bugfixes in the CV');
  end if;

  commit;

  if G_DEBUG then
    put_line('Updating existing bugfix statuses in the curr-vw snapshot');
  end if;

  -- update the status of existing ones, if they dont already say EXPLICIT, Y

  update ad_snapshot_bugfixes sb
  set sb.bug_status = 'EXPLICIT',
      sb.success_flag = 'Y',
      sb.last_update_date = sysdate,
      sb.last_updated_by = 5
  where sb.snapshot_id = p_snapshot_id
  and sb.bugfix_id in (select t.bug_id
                       from ad_patch_hist_snaps_temp t
                       where t.action_code = L_BUGSTAT_EXPL_ACT_CD)
  and (sb.bug_status <> 'EXPLICIT' or
       sb.success_flag <> 'Y');

  if G_DEBUG then
    put_line('Updated '||to_char(sql%rowcount)|| ' bugfix rows in the CV');

  end if;

  commit;

  -- GLOBAL_VIEW snapshot processing

  if p_update_global_view then

    if G_DEBUG then
      put_line('Inserting new bugfixes in the GV');
    end if;

    -- Insert new ones
    insert into ad_snapshot_bugfixes
    (
      snapshot_bug_id,
      snapshot_id, bugfix_id,
      bug_status, success_flag,
      creation_date, last_update_date, last_updated_by, created_by
    )
    select
      ad_snapshot_bugfixes_s.nextval,
      p_global_snapshot_id, t.bug_id,
      'EXPLICIT', 'Y',
      sysdate, sysdate, 5, 5
    from ad_patch_hist_snaps_temp t
    where t.action_code = L_BUGSTAT_EXPL_ACT_CD
    and not exists (select 'Bug not yet recorded in the curr-vw'
                    from ad_snapshot_bugfixes sb2
                    where sb2.snapshot_id = p_global_snapshot_id
                    and sb2.bugfix_id = t.bug_id);

    l_snapshot_bugs_inserted := l_snapshot_bugs_inserted + sql%rowcount;

    if G_DEBUG then
      put_line('Inserted '||to_char(sql%rowcount)|| ' new bugfixes in the GV');
    end if;

    commit;

    if G_DEBUG then
      put_line('Updating existing bugfix statuses in the GV');
    end if;

    -- update the status of existing ones, if they dont already say EXPLICIT, Y

    update ad_snapshot_bugfixes sb
    set sb.bug_status = 'EXPLICIT',
        sb.success_flag = 'Y',
        sb.last_update_date = sysdate,
        sb.last_updated_by = 5,
        sb.inconsistent_flag = null
    where sb.snapshot_id = p_global_snapshot_id
    and sb.bugfix_id in (select t.bug_id
                         from ad_patch_hist_snaps_temp t
                         where t.action_code = L_BUGSTAT_EXPL_ACT_CD)
    and (sb.bug_status <> 'EXPLICIT' or
         sb.success_flag <> 'Y');

    if G_DEBUG then
      put_line('Updated '||to_char(sql%rowcount)|| ' bugfix rows in the GV');
    end if;

    commit;

  end if;  -- End If p_update_global_view


  -- gather stats if necessary

  ad_stats_util_pkg.gather_stats_if_necessary('SNAPSHOT',
                                              l_snapshot_bugs_inserted,
                                              TRUE,
                                              TRUE,
                                              l_gathered_stats_flag);


  if p_delete_junk_created then

    delete from ad_patch_hist_snaps_temp
    where action_code = L_BUGSTAT_EXPL_ACT_CD;

  end if;

--Bug 7255366 nissubra---
    update ad_snapshots set snapshot_update_date = sysdate
    where  snapshot_id in (p_snapshot_id, p_global_snapshot_id);

  commit;

end handle_bugs;


procedure backfill_bugs_from_patch_hist
           (p_snapshot_id number)
is
  l_appl_top_id number;
  l_apps_sys_nm varchar2(30);
  l_at_name varchar2(256);
  l_dummy varchar2(1);
begin
  if G_DEBUG then
    put_line('just entered backfill_bugs_from_patch_hist');
  end if;

  select s.appl_top_id, aat.applications_system_name, aat.name
  into l_appl_top_id, l_apps_sys_nm, l_at_name
  from ad_snapshots s, ad_appl_tops aat
  where s.appl_top_id = aat.appl_top_id
  and s.snapshot_id = p_snapshot_id;

  begin
    select 'x'
    into l_dummy
    from ad_timestamps
    where type = 'BACKFILLED_BUGS_IN_CURRENT_VIEW_SNAPSHOT'
    and attribute = l_apps_sys_nm||'*'||l_at_name;

    return;

  exception when no_data_found then

    -- insert ALL patch-runs in this appltop into temp table that dont
    -- already doesnt exist. While inserting, insert with special action
    -- code G_PR_ID_ACT_CD2 (so that we can delete them later on)

    if G_DEBUG then
      put_line('About to insert PR-IDs into temp table - 2');
    end if;

    insert into ad_patch_hist_snaps_temp
    (
      patch_run_id, action_code
    )
    select
      patch_run_id, G_PR_ID_ACT_CD2
    from ad_patch_runs
    where appl_top_id = l_appl_top_id
    and patch_run_id not in (select patch_run_id
                             from ad_patch_hist_snaps_temp
                             where action_code in (G_PR_ID_ACT_CD,
                                                   G_PR_ID_ACT_CD2));

    if G_DEBUG then
      put_line('Inserted '||to_char(sql%rowcount)||' PR-ID rows - 2');
    end if;


    -- Backfill bugs ONLY if above INSERT inserted anything

    if sql%rowcount > 0 then

      if G_DEBUG then
        put_line('calling handle_bugs - 2');
      end if;

      -- Backfill the bugs. Do it only if processing an actual patch-run,
      -- not when backfilling from prior patch-hist. Hence we pass in
      -- p_update_global_view as FALSE. Reason: Backfilling bugs into GV
      -- has already been taken care of when instantiating the GV (albeit
      -- indirectly, viz. by creating it from constituent CV's which must
      -- have already been backfilled).

      handle_bugs(p_snapshot_id => p_snapshot_id,
                  p_action_code => G_PR_ID_ACT_CD2,
                  p_update_global_view => FALSE,
                  p_global_snapshot_id => -1,
                  p_delete_junk_created => TRUE);

      -- Now delete all G_PR_ID_ACT_CD2 rows from temp table

      delete from ad_patch_hist_snaps_temp
      where action_code = G_PR_ID_ACT_CD2;

    end if;

    -- mark as having done this backfill

    ad_file_util.update_timestamp('BACKFILLED_BUGS_IN_CURRENT_VIEW_SNAPSHOT',
                                  l_apps_sys_nm||'*'||l_at_name);

    commit;
  end;

end backfill_bugs_from_patch_hist;


-- Creates just the top level info (ad_appl_tops and ad_snapshots)
procedure get_create_global_view_header
(
  p_apps_system_name                 varchar2,
  p_is_run_flow                      boolean,
  p_global_appl_top_id    out nocopy number,
  p_global_snapshot_id    out nocopy number,
  p_count_appltops        out nocopy number
) is
l_release_id number;
l_snapshot_type varchar2(1);
begin

  if (p_is_run_flow = TRUE)
  then
     l_snapshot_type := 'G';
  else
     l_snapshot_type := 'Q';
  end if;

  select nvl(count(*), 0)
  into p_count_appltops
  from ad_appl_tops
  where applications_system_name = p_apps_system_name
  and active_flag = 'Y';

  /* Create a dummy appl_top called 'GLOBAL' (inactive) */

  insert into ad_appl_tops
  (
    appl_top_id, name, applications_system_name, appl_top_type,
    description,
    server_type_admin_flag, server_type_forms_flag,
    server_type_node_flag, server_type_web_flag,
    creation_date, created_by, last_update_date, last_updated_by,
    active_flag
  )
  select
    ad_appl_tops_s.nextval, 'GLOBAL', p_apps_system_name, 'G',
    'Created for Global View Snapshot',
    null, null,
    null, null,
    sysdate, 5, sysdate, 5,
    'N'
  from dual
  where not exists (select 'Already exists'
                    from ad_appl_tops t
                    where t.name = 'GLOBAL'
                    and t.appl_top_type ='G'
                    and t.applications_system_name = p_apps_system_name);

  /* Get ID of above GLOBAL appl_top */

  select appl_top_id
  into p_global_appl_top_id
  from ad_appl_tops
  where appl_top_type ='G'
  and name = 'GLOBAL'
  and applications_system_name = p_apps_system_name;

  /* Get the release id */
  select release_id into l_release_id from ad_releases
  where  to_char(major_version) || '.' ||
         to_char(minor_version) || '.' ||
         to_char(tape_version) = (select release_name
                                  from   fnd_product_groups
                                  where  applications_system_name =
                                         p_apps_system_name);
  insert into ad_snapshots
  (
    snapshot_id, release_id,
    appl_top_id, snapshot_name,
    snapshot_creation_date, snapshot_update_date,
    snapshot_type, comments,
    ran_snapshot_flag,
    creation_date, last_updated_by, created_by, last_update_date
  )
  select
    ad_snapshots_s.nextval, l_release_id,
    p_global_appl_top_id, 'GLOBAL_VIEW',
    sysdate, sysdate,
    l_snapshot_type, 'Created from Current View Snapshots',
    'N',
    sysdate, 5, 5, sysdate
  from dual
  where not exists (select 'Already exists'
                    from ad_snapshots
                    where appl_top_id = p_global_appl_top_id
                    and snapshot_type = l_snapshot_type
                    and snapshot_name = 'GLOBAL_VIEW');

  /* Get above created Global snapshot ID */

  select snapshot_id
  into p_global_snapshot_id
  from ad_snapshots
  where snapshot_type = l_snapshot_type
  and snapshot_name = 'GLOBAL_VIEW'
  and appl_top_id   = p_global_appl_top_id;

end get_create_global_view_header;


-- procedure get_max_fil_vers_over_appltops : Identify highest file versions
-- across APPL_TOPs, and inserts them into a temp table.
procedure get_max_fil_vers_over_appltops
(
  p_apps_system_name varchar2,
  p_limit_to_candidate_files boolean,
  p_wipe_out_temp_table_at_start boolean,
  p_commit boolean,
  p_gather_stats boolean,
  p_is_run_flow boolean
)
is
  l_cv_ids NUM_TAB;  -- curr-vw snapshot-id's
  l_cv_ids_str varchar2(4000);  -- comma-separated CV-ID's

  l_str1 varchar2(1024) := null;
  l_str2 varchar2(256) := null;
  l_str3 varchar2(512) := null;

  L_ARCH_NONE_ACT_CD constant number := 10;
  L_ARCH_CLIB_ACT_CD constant number := 11;
  L_ARCH_AZIP_ACT_CD constant number := 12;
  i number;
  l_snapshot_type varchar2(1);

begin

  if p_wipe_out_temp_table_at_start then
    execute immediate
                   'truncate table ' || G_UN_FND || '.ad_snapshot_files_temp';
  end if;

  if (p_is_run_flow = TRUE)
  then
    l_snapshot_type := 'C';
  else
    l_snapshot_type := 'P';
  end if;

  select snapshot_id
  bulk collect into l_cv_ids
  from ad_snapshots s, ad_appl_tops at1
  where s.appl_top_id = at1.appl_top_id
  and at1.applications_system_name = p_apps_system_name
  and at1.appl_top_type = 'R'
  and at1.active_flag = 'Y'
  and s.snapshot_type = l_snapshot_type
  and s.snapshot_name = 'CURRENT_VIEW';

  l_cv_ids_str := null;

  -- Bug 4207329 : The condition must be if count >=1 and not
  -- if count > 1. Otherwise, if there is only one appltop and
  -- only one current_view for that appl_top, the global_view
  -- for that appl_top will never be updated through adpatch!.
  --
  -- sgadag - 02-MAR-2005


  if l_cv_ids.count >= 1 then

    -- Build a string of CV-IDs

    for i in l_cv_ids.first .. l_cv_ids.last loop
      if l_cv_ids_str is null then
        l_cv_ids_str := to_char(l_cv_ids(i));  -- Dont prepend "," on 1st iter.
      else
        -- @@TODO: Add safeguard to ensure that l_cv_ids_str length is not
        -- exceeded (very unlikely, but need a check anyway). Err msg should
        -- say something like "Developer error: ..."

        l_cv_ids_str := l_cv_ids_str || ', ' || to_char(l_cv_ids(i));
      end if;
    end loop;

  end if;  -- End If l_cv_ids.count >= 1

  if l_cv_ids_str is null then

    return;  -- No curr-vws. Just return

  end if;


  l_str1 :=
    'insert into ad_snapshot_files_temp '||
    '( '||
      'snapshot_file_id, file_id, update_source_id, update_type, '||
      'inconsistent_flag, containing_file_id, file_version_id, '||
      'dest_file_id, file_type_flag '||
    ') '||
    'select '||
    'snapshot_file_id, file_id, -1, ''P'', ''Y'', containing_file_id, '||
    'file_version_id, '||
    'dest_file_id, file_type_flag '||
    'from (select '||
     'sf.snapshot_file_id snapshot_file_id, sf.file_id file_id, '||
          'sf.containing_file_id containing_file_id, '||
          'sf.file_version_id file_version_id, '||
          'sf.dest_file_id dest_file_id, sf.file_type_flag file_type_flag, '||
          'row_number() over '||
            '(partition by afv.file_id, sf.containing_file_id '||
             'order by afv.version_segment1 desc, afv.version_segment2 desc, '||
                      'afv.version_segment3 desc, afv.version_segment4 desc, '||
                      'afv.version_segment5 desc, afv.version_segment6 desc, '||
                      'afv.version_segment7 desc, afv.version_segment8 desc, '||
                      'afv.version_segment9 desc, afv.version_segment10 desc, '||
                      'afv.translation_level desc nulls last) as r '||
        'from ad_snapshot_files sf, ad_file_versions afv ';

  if p_limit_to_candidate_files then
    l_str2 :=
      ', ad_patch_hist_snaps_temp t ' ||
      'where t.file_id = sf.file_id '||
      'and t.action_code in (:1, :2, :3) and ';
  else
    l_str2 := ' where ';
  end if;

  l_str3 :=
      'sf.snapshot_id in (' || l_cv_ids_str || ')' ||
      'and sf.file_version_id = afv.file_version_id (+) ' ||
    ') r_sf ' ||
    'where r_sf.r = 1';

  if G_DEBUG then

    put_line('@@INDIV VC2 VARS');

    put_line('l_str1 (len='||to_char(length(l_str1))||'): ');
      put_line(l_str1);

    put_line('l_str2 (len='||to_char(length(l_str2))||'): ');
      put_line(l_str2);

    put_line('l_str3 (len='||to_char(length(l_str3))||'): ');
      put_line(l_str3);

  end if;

  if p_limit_to_candidate_files then

    execute immediate l_str1 || l_str2 || l_str3 using
      L_ARCH_NONE_ACT_CD, L_ARCH_CLIB_ACT_CD, L_ARCH_AZIP_ACT_CD;

  else

    execute immediate l_str1 || l_str2 || l_str3;

  end if;

  if p_commit then
    commit;
  end if;

  if p_gather_stats then
    fnd_stats.gather_table_stats(G_UN_FND, 'ad_snapshot_files_temp');
  end if;

end get_max_fil_vers_over_appltops;



--
-- procedure instantiate_global_view
--
procedure instantiate_global_view
(
  p_apps_system_name varchar2,
  p_instantiate_from_preseed boolean,
  p_cur_appl_top_id varchar2,
  p_release_name  varchar2,
  p_is_run_flow boolean
) is
  l_dummy                 varchar2(1);
  l_preseeded_snapshot_id number;
  l_global_appl_top_id    number;
  l_global_snapshot_id    number;
  l_count_appltops        number;
  l_is_curr_rel_gv        boolean;
  l_release_id            number;
  l_global_snapshot_type  varchar2(1);
  l_current_snapshot_type  varchar2(1);

begin

  select release_id into l_release_id
	from ad_releases
 	where major_version||'.'||minor_version||'.'||tape_version = p_release_name;


  if (p_is_run_flow = TRUE)
  then
     l_global_snapshot_type := 'G';
     l_current_snapshot_type := 'C';
  else
     l_global_snapshot_type := 'Q';
     l_current_snapshot_type := 'P';
  end if;

  begin
    select snapshot_id into l_global_snapshot_id
    from ad_snapshots
    where snapshot_name ='GLOBAL_VIEW'
    and snapshot_type= l_global_snapshot_type
    and appl_top_id = (
      select appl_top_id
      from ad_appl_tops
      where appl_top_type = 'G'
      and name = 'GLOBAL'
      and applications_system_name = p_apps_system_name
    );

  exception when no_data_found then
    l_global_snapshot_id := -1;
  end;

  if p_instantiate_from_preseed then
    if l_global_snapshot_id <> -1 then
      begin
        select 'x' into l_dummy
        from ad_snapshots ads
        where ads.release_id = l_release_id
        and ads.snapshot_id = l_global_snapshot_id;
      exception when no_data_found then
        l_dummy := null;
      end;

      if l_dummy is null then
        update ad_snapshots
        set snapshot_type = 'O',
        snapshot_name = snapshot_name||'-'||snapshot_id,
        last_update_date = sysdate
        where snapshot_id = l_global_snapshot_id;

        l_global_snapshot_id := -1;

      end if;
    end if;

    if l_global_snapshot_id = -1 then

      -- Caller ensures that preseeded info is present

      -- Bug 4143940: Earlier this query used to use the
      -- release_name from FND_PRODUCT_GROUPS. This caused
      -- a few problems because instantiate_current_view()
      -- ended up using a different release_name (l_rlse_nm)
      -- and this function was using another one (like
      -- 11.5.10 in instantiate_current_view() and 11.5.10.1
      -- in this.
      --
      -- To solve this, instantiate_current_view now passes
      -- l_rlse_nm to this function as a parameter.
      --

      select ss.snapshot_id
      into l_preseeded_snapshot_id
      from ad_snapshots ss,             -- seeded
           ad_appl_tops ats             -- seeded
      where ss.appl_top_id = ats.appl_top_id
      and ss.snapshot_type = 'B'
      and ss.snapshot_name like '*PRESEEDED*'||p_release_name||'%'
      and ats.name = '*PRESEEDED*'
      and ats.applications_system_name = '*PRESEEDED*'
      and ats.appl_top_type = 'S';

      get_create_global_view_header(p_apps_system_name, p_is_run_flow,
                                    l_global_appl_top_id,
                                    l_global_snapshot_id, l_count_appltops);


      /* Instantiate preseeded bugfixes information to GLOBAL_VIEW */

      insert into ad_snapshot_bugfixes
      (
        snapshot_bug_id, snapshot_id, bugfix_id, bug_status, success_flag,
        creation_date, last_update_date, last_updated_by, created_by,
        inconsistent_flag
      )
      select
        ad_snapshot_bugfixes_s.nextval,
        l_global_snapshot_id,
        sbs.bugfix_id,
        sbs.bug_status,
        sbs.success_flag,
        sysdate, sysdate, 5, 5,
        'N'  /* inconsistent_flag: set to 'N' */
      from ad_snapshot_bugfixes sbs     -- seeded
      where sbs.snapshot_id = l_preseeded_snapshot_id
      and not exists (select /*+ INDEX(SB2 AD_SNAPSHOT_BUGFIXES_U2) */
                        'Already exists'
                      from ad_snapshot_bugfixes sb2
                      where sb2.snapshot_id = l_global_snapshot_id
                      and sb2.bugfix_id = sbs.bugfix_id);


      /* Instantiate preseeded files information to GLOBAL_VIEW */

      insert into ad_snapshot_files
      (
        snapshot_file_id,
        snapshot_id, file_id, containing_file_id,
        file_version_id,
        update_source_id, update_type,
        creation_date, last_update_date, last_updated_by, created_by,
        appl_top_id, inconsistent_flag,
        server_type_admin_flag, server_type_forms_flag,
        server_type_node_flag, server_type_web_flag,
        dest_file_id, file_type_flag
      )
      select
        ad_snapshot_files_s.nextval,
        l_global_snapshot_id, file_id, containing_file_id,
        file_version_id,
        update_source_id, update_type,
        sysdate, sysdate, 5, 5,
        p_cur_appl_top_id, 'N',
        server_type_admin_flag, server_type_forms_flag,
        server_type_node_flag, server_type_web_flag,
        dest_file_id, file_type_flag
      from  ad_snapshot_files sf
      where snapshot_id = l_preseeded_snapshot_id
      and not exists (select  /*+ INDEX(SF2 AD_SNAPSHOT_FILES_U2) */
                          'Already exists'
                      from ad_snapshot_files sf2
                      where sf2.snapshot_id = l_global_snapshot_id
                      and sf2.file_id = sf.file_id
                      and nvl(sf2.containing_file_id, -1) =
                                                nvl(sf.containing_file_id, -1));


    end if;

  else --  p_instantiate_from_preseed is false

    if l_global_snapshot_id <> -1 then

      begin
      select 'x' into l_dummy
      from ad_snapshots ads, ad_releases adr
      where ads.release_id = adr.release_id
      and ads.snapshot_id = l_global_snapshot_id
      and adr.major_version = ( select distinct major_version from ad_releases
                                where release_id = l_release_id );

      exception when no_data_found then
        l_dummy := null;
      end;

      if l_dummy is null then
        update ad_snapshots
        set snapshot_type = 'O',
        snapshot_name = snapshot_name||'-'||snapshot_id,
        last_update_date = sysdate
        where snapshot_id = l_global_snapshot_id;
        l_global_snapshot_id := -1;

      else
        update ad_snapshots
        set release_id = l_release_id,
        last_update_date = sysdate
        where snapshot_id = l_global_snapshot_id
        and release_id <> l_release_id;
      end if;

    end if;

    if l_global_snapshot_id = -1 then

      -- In this case, instantiate from existing curr-vws.

      -- Wipe out temp table

      execute immediate
                   'truncate table ' || G_UN_FND || '.ad_snapshot_bugfixes_temp';

      --
      -- Insert candidate bugs into temp table.
      -- Rules:
      --  If explicit in any appltop, insert it as explicit
      --  If success-flag=N in any appltop, insert it as N
      --

      insert into ad_snapshot_bugfixes_temp
      (
        bugfix_id,
        bug_status,
        success_flag
      )
      select
        bugfix_id,
        decode(min(decode(bug_status, 'EXPLICIT', 1, 2)), 1,
               'EXPLICIT', 'IMPLICIT'),
        decode(min(decode(success_flag, 'N', 1, 2)), 1, 'N', 'Y')
      from ad_snapshot_bugfixes
      where snapshot_id in (select snapshot_id
                            from ad_snapshots s, ad_appl_tops at1
                            where s.appl_top_id = at1.appl_top_id
                            and at1.applications_system_name = p_apps_system_name
                            and at1.appl_top_type = 'R'
                            and s.snapshot_type = l_current_snapshot_type
                            and s.snapshot_name = 'CURRENT_VIEW')
      group by bugfix_id;

      --
      -- Now insert files into temp table, picking highest version from across
      -- APPL_TOPs
      --

      get_max_fil_vers_over_appltops(p_apps_system_name => p_apps_system_name,
                                     p_limit_to_candidate_files => FALSE,
                                     p_wipe_out_temp_table_at_start => TRUE,
                                     p_commit => TRUE,
                                     p_gather_stats => TRUE,
                                     p_is_run_flow => p_is_run_flow
                                   );


      get_create_global_view_header(p_apps_system_name, p_is_run_flow,
                                    l_global_appl_top_id,
                                    l_global_snapshot_id, l_count_appltops);


      -- Now insert bugs into actual table (mark them all as inconsistent)

      insert into ad_snapshot_bugfixes
      (
        snapshot_bug_id, snapshot_id,
        bugfix_id, bug_status, success_flag,
        inconsistent_flag,
        creation_date, last_update_date, last_updated_by, created_by
      )
      select
        ad_snapshot_bugfixes_s.nextval, l_global_snapshot_id,
        t.bugfix_id, t.bug_status, t.success_flag,
        decode(l_count_appltops, 1, 'N', null),
        sysdate, sysdate, 5, 5
      from ad_snapshot_bugfixes_temp t
      where not exists (select 'Already exists'
                        from ad_snapshot_bugfixes sb2
                        where sb2.snapshot_id = l_global_snapshot_id
                        and sb2.bugfix_id = t.bugfix_id);

      -- Now insert files into actual table
      -- Bug 3863707, changed the query not to select duplicate rows. 09/01/2004, cbhati.

      insert into ad_snapshot_files
      (
        snapshot_file_id, snapshot_id,
        file_id, containing_file_id, file_version_id,
        dest_file_id, file_type_flag,
        appl_top_id,
        inconsistent_flag,
        update_source_id, update_type,
        creation_date, last_update_date, created_by, last_updated_by
      )
      select
        ad_snapshot_files_s.nextval, l_global_snapshot_id,
        t.file_id, t.containing_file_id, t.file_version_id,
        t.dest_file_id, t.file_type_flag,
        decode(l_count_appltops, 1, p_cur_appl_top_id, null),
        decode(l_count_appltops, 1, 'N', null),
        -1, 'P',
        sysdate, sysdate, 5, 5
      from
        (
          select
            file_id,
            max(containing_file_id) containing_file_id,
            max(file_version_id) file_version_id,
            max(dest_file_id) dest_file_id,
            decode(max(decode(file_type_flag,'M',1,'N',0,2)),
                                 1,'M',0,'N',null) file_type_flag
          from
            ad_snapshot_files_temp
          group by file_id) t
       where not exists (select 'Already exists'
                        from ad_snapshot_files sf2
                        where sf2.snapshot_id = l_global_snapshot_id
                        and sf2.file_id = t.file_id
                        and nvl(sf2.containing_file_id, -1) =
                                                   nvl(t.containing_file_id, -1)
                       );
    end if;
  end if;

  commit;

end instantiate_global_view;



--
-- Public program units
--
-- Returns TRUE if we are allowed to maintain snapshots (using a temporary
-- strategy of a "wierd" row in AD_TIMESTAMPS)
--
-- CORRECTION: Starting 4/25/02 bug# 2345215, will always return TRUE.

function snapshot_maint_allowed return boolean is
begin
  return TRUE;
end;

procedure update_current_view
           (p_patch_run_id number,
            p_appl_top_id  number)
is
  l_at_id number;
begin
  -- obtain a lock, to ensure serialized access to temp table infrastructure
  ad_file_util.lock_infrastructure;

  if not snapshot_maint_allowed then
    goto return_success;
  end if;

  if p_appl_top_id is null then
    select pr.appl_top_id
    into l_at_id
    from ad_patch_runs pr
    where pr.patch_run_id = p_patch_run_id;
  else
    -- make sure the 2 are consistent
    select pr.appl_top_id
    into l_at_id
    from ad_patch_runs pr
    where pr.patch_run_id = p_patch_run_id
    and pr.appl_top_id = p_appl_top_id;
  end if;

  delete from ad_patch_hist_snaps_temp;

  if G_DEBUG then
    put_line('About to insert PR-ID into temp table');
  end if;

  insert into ad_patch_hist_snaps_temp
  (
    action_code, patch_run_id
  )
  select G_PR_ID_ACT_CD, pr.patch_run_id
  from ad_patch_runs pr
  where pr.patch_run_id = p_patch_run_id;

  if G_DEBUG then
    put_line('Inserted '||to_char(sql%rowcount)||' PR-ID rows');
    put_line('About to call update_current_view() (the one '||
             'that works on many)');
  end if;

  update_current_view('IN_TEMP_TAB', l_at_id, TRUE);


  -- release the lock upon successful completion

  <<return_success>>

  ad_file_util.unlock_infrastructure;

exception when others then
  -- release the lock upon errors
  ad_file_util.unlock_infrastructure;

  -- and allow the exception (that made us land here) to propogate
  raise;
end update_current_view;

procedure update_current_view
           (p_patch_runs_spec          varchar2,
            p_appl_top_id              number,
            p_caller_is_managing_locks boolean)
is
  l_snapshot_id number;
  l_curr_rlse_nm varchar2(50);
  l_curr_rlse_id number;
  l_apps_zip_f_id number;  -- file-id of apps.zip (using the AU one)

  L_ARCH_NONE_ACT_CD constant number := 10;  -- file is never archived (eg.fmbs)
  L_ARCH_CLIB_ACT_CD constant number := 11;  -- file is archived in a C archive
                                             -- library (eg .o's)
  L_ARCH_AZIP_ACT_CD constant number := 12;  -- file is archived in apps.zip
                                             -- (eg .class files)

  l_return_code varchar2(3);

  l_ins_stmt1 varchar2(400);
  l_ins_stmt1_contd varchar2(400);
  l_hint varchar2(10);
  l_sel_list varchar2(1000);
  l_from_where varchar2(700);
  l_trailer varchar2(100);

  l_count number := 0;
  l_src_dest_info_exists boolean := FALSE;
  l_copy_actions_exist boolean;
  l_only_one_driver_row boolean;

  l_snapshot_files_inserted number := 0;
  l_gathered_stats_flag boolean := FALSE;

  l_inconsistent_flag varchar2(1);
  l_global_snapshot_id number;
  l_snapshot_count     number;
  l_gsnapshot_count     number;
  l_apps_system_name   varchar2(30);

  l_is_run_flow boolean;
  l_current_snapshot_type varchar2(1);
  l_global_snapshot_type  varchar2(1);

  l_deleted_ru_file_ids NUM_TAB;

  i number;
  l_dummy varchar2(1);
begin
  l_inconsistent_flag  := 'Y';

  if (ad_zd.is_editions_enabled = 'N' or
      sys_context('userenv', 'current_edition_name') = ad_zd.get_edition('RUN'))
  then
     l_is_run_flow := TRUE;
     l_current_snapshot_type := 'C';
     l_global_snapshot_type := 'G';
  else
     l_is_run_flow := FALSE;
     l_current_snapshot_type := 'P';
     l_global_snapshot_type := 'Q';
  end if;

  if not p_caller_is_managing_locks then
    -- obtain a lock, to ensure serialized access to temp table infrastructure
    ad_file_util.lock_infrastructure;
  end if;

  if G_DEBUG then
    put_line('In update_current_view(). (the one that '||
             'works on many ptch-runs)');
  end if;

  if p_patch_runs_spec not in ('IN_TEMP_TAB', 'ALL') then
    raise_application_error(-20000,
'Invalid parameters: p_patch_runs_spec MUST be IN_TEMP_TAB or ALL.');
  end if;

  if not snapshot_maint_allowed then
    goto return_success;
  end if;

  if p_patch_runs_spec = 'ALL' then
    -- insert all patch-runs for this appl-top into temp table

    if G_DEBUG then
      put_line('About to insert PR-IDs into temp table');
    end if;

    insert into ad_patch_hist_snaps_temp
    (
      patch_run_id, action_code
    )
    select
      patch_run_id, G_PR_ID_ACT_CD
    from ad_patch_runs
    where appl_top_id = p_appl_top_id
    and patch_run_id not in (select patch_run_id
                             from ad_patch_hist_snaps_temp
                             where action_code = G_PR_ID_ACT_CD);

    if G_DEBUG then
      put_line('Inserted '||to_char(sql%rowcount)||' PR-ID rows');
    end if;
  end if;


  -- Gather stats on the temp table at the start (it may have stats from its
  -- prior use. For that, first commit.

  commit;

  fnd_stats.gather_table_stats(G_UN_FND, 'ad_patch_hist_snaps_temp');

  -- set some flags, that help us fine-tune SQL's down the line

  l_only_one_driver_row := FALSE;
  l_copy_actions_exist := TRUE;

  select nvl(count(*), 0)
  into l_count
  from ad_patch_hist_snaps_temp;

  if l_count = 0 then
    goto return_success;
  elsif l_count = 1 then
    l_only_one_driver_row := TRUE;
  else
    l_only_one_driver_row := FALSE;
  end if;

  l_count := 0;

  begin
    select 1
    into l_count
    from ad_patch_hist_snaps_temp t,
         ad_patch_runs pr,
         ad_patch_drivers pd
    where t.patch_run_id = pr.patch_run_id
    and pr.patch_driver_id = pd.patch_driver_id
    and pd.driver_type_c_flag = 'Y'
    and rownum < 2;

    l_copy_actions_exist := TRUE;

  exception when no_data_found then
    l_copy_actions_exist := FALSE;
  end;


  -- Instantiate current-view snapshot for the current on-site rlse. For
  -- that, first get the onsite rlse.

  select release_name
  into l_curr_rlse_nm
  from fnd_product_groups;

  -- Then get its rlse-id

  declare
    l1 number;
    l2 number;
    l3 number;
    l4 number;
  begin
    l1 := instr(l_curr_rlse_nm, '.');
    l2 := instr(l_curr_rlse_nm, '.', l1+1);
    l3 := instr(l_curr_rlse_nm, '.', l2+1);
    l4 := instr(l_curr_rlse_nm, '.', l3+1);

    -- Check that there are necessarily (and at most) 2 dots, and that too at
    -- valid places.
    if (l1 > 1 and l2>l1+1 and l3=0 ) OR
       (l1 > 1 and l2>l1+1 and l3>l2+1 and l4=0) then
      -- this is a good format. Re-compute l3 as length(p_release_name)
      l3 := length(l_curr_rlse_nm);
    else
       -- this is an invalid format. Error out
       raise_application_error(-20000, 'Invalid release - '||
                                      l_curr_rlse_nm);
    end if;

    AD_RELEASES_PVT.CreateRelease
    (
      p_major_version => to_number(substr(l_curr_rlse_nm, 1, l1-1)),
      p_minor_version => to_number(substr(l_curr_rlse_nm, l1+1, l2-l1-1)),
      p_tape_version => to_number(substr(l_curr_rlse_nm, l2+1, l3-l2)),
      p_row_src_comments => 'Created while updating current-view snapshot '||
                            'using patch-history info',
      p_release_id => l_curr_rlse_id,
      p_base_rel_flag   =>  'N',
      p_start_dt        => sysdate,
      p_created_by_user_id => -1
    );
  end;

  -- Finally, instantiate the current-view snapshot

  instantiate_current_view
  (
    l_curr_rlse_id, p_appl_top_id,
    FALSE, p_caller_is_managing_locks,
    l_return_code
  );

  select snapshot_id
  into l_snapshot_id
  from ad_snapshots
  where appl_top_id = p_appl_top_id
  and snapshot_name = 'CURRENT_VIEW'
  and snapshot_type = l_current_snapshot_type;

  if G_DEBUG then
    put_line('Curr-vw snapshotid is '||to_char(l_snapshot_id));
  end if;

  select applications_system_name into l_apps_system_name
  from   ad_appl_tops where appl_top_id = p_appl_top_id;


  /* Get Global snapshot ID for this Applications System */

  select snapshot_id into l_global_snapshot_id
  from   ad_snapshots s, ad_appl_tops t
  where  s.snapshot_type            = l_global_snapshot_type and
         s.snapshot_name            = 'GLOBAL_VIEW' and
         s.appl_top_id              = t.appl_top_id and
         t.applications_system_name = l_apps_system_name;

  if G_DEBUG then
    put_line('Global-vw snapshot id is '||to_char(l_global_snapshot_id));
  end if;

  -- identify the apps.zip:
  --  (assumed to be in lower case, even on NT. It is *suspected* that our
  --   OSD's for ALL platforms (when the Snapshot Utility C code is run) will
  --   return apps.zip filename in lower case, so we can rest assured that
  --   we won't end up with a slew of records (atleast so long as our
  --   *suspicion* is true. %% Need NT testing to really verify)
  begin
    select f.file_id
    into l_apps_zip_f_id
    from ad_files f
    where f.filename = 'apps.zip'
    and f.app_short_name = 'AU'
    and f.subdir = 'java';
  exception when no_data_found then
    insert into ad_files
    (
      file_id,
      app_short_name, subdir, filename,
      creation_date, last_update_date, last_updated_by, created_by
    )
    values
    (
      ad_files_s.nextval,
      'AU', 'java', 'apps.zip',
      sysdate, sysdate, 5, 5
    ) returning file_id into l_apps_zip_f_id;
  end;

  if G_DEBUG then
    put_line('apps.zip file-id is '||to_char(l_apps_zip_f_id));
    put_line('Ensuring that lib<prod>.a files exist in AD_FILES...');
  end if;

  -- Note: assumes that app-short-names are indeed APP-SHORT-NAMES, and not
  -- prod-abbrs, as they used to be some time back.

  -- for all the various Unix's
  insert into ad_files
  (
    file_id,
    app_short_name,
    subdir,
    filename,
    creation_date, last_update_date, last_updated_by, created_by
  )
  select    -- for all the various Unix's
    ad_files_s.nextval,
    a.application_short_name,
    'lib',
    'lib'||decode(a.application_short_name, 'SQLGL', 'gl',
                                            'SQLAP', 'ap',
                                            'OFA', 'fa',
                                            'SQLSO', 'so',
                                            lower(a.application_short_name))||
           '.a',
    sysdate, sysdate, 5, 5
  from fnd_application a
  where not exists (select
                      'lib<prod>.a already exists'
                    from ad_files f2
                    where f2.filename =  'lib'||
                                           decode(a.application_short_name,
                                             'SQLGL', 'gl',
                                             'SQLAP', 'ap',
                                             'OFA', 'fa',
                                             'SQLSO', 'so',
                                             lower(a.application_short_name))||
                                           '.a'
                    and f2.subdir = 'lib'
                    and f2.app_short_name = a.application_short_name);

  if G_DEBUG then
    put_line('Done ensuring that lib<prod>.a files exist in AD_FILES...');
    put_line('>>(had to insert '||to_char(sql%rowcount)||' rows)');
    put_line('Ensuring that <prod>st.lib files exist in AD_FILES...');
  end if;

  -- for NT
  insert into ad_files
  (
    file_id,
    app_short_name,
    subdir,
    filename,
    creation_date, last_update_date, last_updated_by, created_by
  )
  select
    ad_files_s.nextval,
    a.application_short_name,
    'lib',
    decode(a.application_short_name, 'SQLGL', 'gl',
                                     'SQLAP', 'ap',
                                     'OFA', 'fa',
                                     'SQLSO', 'so',
                                     lower(a.application_short_name))||
           'st.lib',
    sysdate, sysdate, 5, 5
  from fnd_application a
  where not exists (select
                      '<prod>st.lib already exists'
                    from ad_files f2
                    where f2.filename =  decode(a.application_short_name,
                                           'SQLGL', 'gl',
                                           'SQLAP', 'ap',
                                           'OFA', 'fa',
                                           'SQLSO', 'so',
                                           lower(a.application_short_name))||
                                         'st.lib'
                    and f2.subdir = 'lib'
                    and f2.app_short_name = a.application_short_name);

  if G_DEBUG then
    put_line('Done ensuring that <prod>st.lib files exist in AD_FILES...');
    put_line('>>(had to insert '||to_char(sql%rowcount)||' rows)');
  end if;


  -- Process snapshot_files *only* if there were copy-actions in the patch

  if l_copy_actions_exist then

    if G_DEBUG then
      put_line('About to insert candidate FILES info into temp table');
    end if;

    /*
    Using the set of starter patch-run rows in the temp table, we first
    build the list of candidate files in the temp table.

    To help populate the CONTAINING_FILE_ID correctly for C code, we need to
    be able to distinguish bween C code that have a main() and those that dont.
    The reason is that the former do NOT get into the archive
    library (lib<prod>.a on Unix), while the latter do. Hence, the containing
    file should be left NULL for C code that have a main(). To achieve this, we
    need to set ACTION_CODE (in temp tab) for "main()" C code to
    L_ARCH_NONE_ACT_CD.

    This is done in a 2-step process, viz. an INSERT SQL followed by an UPDATE
    SQL. The first SQL inserts candidate rows into the temp table, and the
    second one flags (updates) C object files that are not archived (main()'s),
    that got mistaken as non-main() files in the first SQL.

    Moreover, when there is only 1 row in the temp table, then the analytic
    function can be done away with and replaced with a grp by instead (since
    each FILE_ID partition will have only 1 row, or worst case, multiple
    rows with same version). Note that in the vast majority of the cases,
    we will have only 1 starter row in the temp table (multiple rows
    occur only in the applptch.txt upload case)

    The 2nd SQL (the UPDATE) is however the same regardless of whether its
    a big/small patch, or whether there are 1/many rows in the temp tables
    to start with.

    The first SQL (INSERT stmt) is explained below:

    Case 1: 1 patch-run
    ------
      The SQL to use is:

      insert into ad_patch_hist_snaps_temp
        (patch_run_id, action_code, file_id, file_version_id,
         app_short_name, filename,
         version_segment1, version_segment2,
         version_segment3, version_segment4,
         version_segment5, version_segment6,
         version_segment7, version_segment8,
         version_segment9, version_segment10,
         translation_level, dest_file_id, file_type_flag)
      select
        max(pr.patch_run_id),
        decode(max(pca.action_code),
               'copy',
                 decode(max(f.subdir),
                        'lib',
                          case when (max(f.filename) like '%.o' or
                                     max(f.filename) like '%.obj') then
                            :clib_cd else
                            :none_cd end,
                          :none_cd),
               'RU_Insert', :azip_cd,
               'RU_Update', :azip_cd,
               'RU_Delete', :azip_cd,
                 :none_cd) act_cd,
        f.file_id, max(afv.file_version_id),
        max(f.app_short_name), max(f.filename),
        max(afv.version_segment1), max(afv.version_segment2),
        max(afv.version_segment3), max(afv.version_segment4),
        max(afv.version_segment5), max(afv.version_segment6),
        max(afv.version_segment7), max(afv.version_segment8),
        max(afv.version_segment9), max(afv.version_segment10),
        max(afv.translation_level), max(prba.dest_file_id),
        max(prba.file_type_flag)
      from ad_patch_hist_snaps_temp t, ad_patch_runs pr,
           ad_patch_run_bugs prb, ad_patch_run_bug_actions prba,
           ad_patch_common_actions pca, ad_file_versions afv, ad_files f
      where pr.patch_run_id = t.patch_run_id
      and pr.appl_top_id = :at_id
      and t.action_code = :pr_id_act_cd
      and pr.patch_run_id = prb.patch_run_id
      and prb.patch_run_bug_id = prba.patch_run_bug_id
      and prba.common_action_id = pca.common_action_id
      and prba.file_id = f.file_id
      and prba.patch_file_version_id = afv.file_version_id (+)
      and prba.executed_flag = 'Y'
      and pca.action_code in ('copy', 'forcecopy', 'RU_Update',
          'RU_Insert', 'RU_Delete')
      group by f.file_id;

    Case 2: Many patch-runs
    ------
      Here, we may have different versions of the same file copied in
      different patches (eg. adpvov v115.10 in patch 1, v115.11 in patch 2,
      etc). And what we'd like is to form groups, each group containing
      the various copied versions of 1 file, and then pick the highest
      version for a file in that file's group). To achieve this, we use the
      analytic function ROW_NUMBER.

      The SQL to use is:

      insert into ad_patch_hist_snaps_temp
        (patch_run_id, action_code, file_id, file_version_id,
         app_short_name, filename,
         version_segment1, version_segment2,
         version_segment3, version_segment4,
         version_segment5, version_segment6,
         version_segment7, version_segment8,
         version_segment9, version_segment10,
         translation_level, dest_file_id, file_type_flag)
      select
        m.patch_run_id, m.act_cd, m.file_id, m.file_version_id,
        m.app_short_name, m.filename,
        m.version_segment1, m.version_segment2,
        m.version_segment3, m.version_segment4,
        m.version_segment5, m.version_segment6,
        m.version_segment7, m.version_segment8,
        m.version_segment9, m.version_segment10,
        m.translation_level, prba.dest_file_id, prba.file_type_flag
      from
        (
        select
          pr.patch_run_id, afv.file_version_id,
          f.file_id, f.app_short_name, f.filename,
          afv.version_segment1, afv.version_segment2,
          afv.version_segment3, afv.version_segment4,
          afv.version_segment5, afv.version_segment6,
          afv.version_segment7, afv.version_segment8,
          afv.version_segment9, afv.version_segment10,
          afv.translation_level,
          decode(pca.action_code, 'copy',
            decode(f.subdir, 'lib',
              case when (f.filename like '%.o' or f.filename like '%.obj')
                     then :clib_cd
                   else :none_cd
              end,
              :none_cd),
            'RU_Insert', :azip_cd,
            'RU_Update', :azip_cd,
            'RU_Delete', :azip_cd,
            :none_cd) act_cd,
          row_number() over  (partition by f.file_id
                  order by afv.version_segment1 desc, afv.version_segment2 desc,
                           afv.version_segment3 desc, afv.version_segment4 desc,
                           afv.version_segment5 desc, afv.version_segment6 desc,
                           afv.version_segment7 desc, afv.version_segment8 desc,
                           afv.version_segment9 desc, afv.version_segment10 desc,
                           afv.translation_level desc nulls last) as r1
        from ad_patch_hist_snaps_temp t, ad_patch_runs pr,
             ad_patch_run_bugs prb, ad_patch_run_bug_actions prba,
             ad_patch_common_actions pca, ad_file_versions afv, ad_files f
        where pr.patch_run_id = t.patch_run_id
        and pr.appl_top_id = :at_id
        and t.action_code = :pr_id_act_cd
        and pr.patch_run_id = prb.patch_run_id
        and prb.patch_run_bug_id = prba.patch_run_bug_id
        and prba.common_action_id = pca.common_action_id
        and prba.file_id = f.file_id
        and prba.patch_file_version_id = afv.file_version_id (+)
        and prba.executed_flag = 'Y'
        and pca.action_code in ('copy', 'forcecopy', 'RU_Update',
            'RU_Insert', 'RU_Delete')
        ) m
      where m.r1 = 1


    Next, the second SQL (UPDATE stmt) is explained below:

    update
      ad_patch_hist_snaps_temp t
    set t.action_code = :none_cd
    where t.action_code = :clib_cd
    and not exists (select
                        'libin action exists for this .o (ie. its archived)'
                    from ad_patch_run_bug_actions prba,
                         ad_patch_run_bugs prb,
                         ad_patch_common_actions pca
                    where prba.file_id = t.file_id
                    and prba.patch_run_bug_id = prb.patch_run_bug_id
                    and prb.patch_run_id = t.patch_run_id
                    and pca.common_action_id = prba.common_action_id
                    and pca.action_code = 'libin')

    */

    l_ins_stmt1 :=
      'insert into ad_patch_hist_snaps_temp '||
        '(patch_run_id, action_code, file_id, file_version_id, '||
        'app_short_name, filename, '||
        'version_segment1, version_segment2, '||
        'version_segment3, version_segment4, '||
        'version_segment5, version_segment6, '||
        'version_segment7, version_segment8, '||
        'version_segment9, version_segment10, '||
        'translation_level,  dest_file_id, file_type_flag) '||
      'select ';

    l_hint := ' ';

    l_from_where :=
        'from ad_patch_hist_snaps_temp t, ad_patch_runs pr, '||
             'ad_patch_run_bugs prb, ad_patch_run_bug_actions prba, '||
             'ad_patch_common_actions pca, ad_file_versions afv, ad_files f '||
        'where pr.patch_run_id = t.patch_run_id '||
        'and pr.appl_top_id = :at_id '||
        'and t.action_code = :pr_id_act_cd '||
        'and pr.patch_run_id = prb.patch_run_id '||
        'and prb.patch_run_bug_id = prba.patch_run_bug_id '||
        'and prba.common_action_id = pca.common_action_id '||
        'and prba.file_id = f.file_id '||
        'and prba.patch_file_version_id = afv.file_version_id (+) '||
        'and prba.executed_flag = ''Y'' '||
        'and pca.action_code in (''copy'', ''forcecopy'', ''RU_Update'', '||
        '''RU_Insert'', ''RU_Delete'') ';

    if l_only_one_driver_row then

      l_ins_stmt1_contd := null;

      l_sel_list :=
        'max(pr.patch_run_id), '||
        'decode(max(pca.action_code), '||
               '''copy'', '||
                 'decode(max(f.subdir), '||
                        '''lib'', '||
                          'case when (max(f.filename) like ''%.o'' or '||
                                     'max(f.filename) like ''%.obj'') then '||
                            ':clib_cd else '||
                            ':none_cd end, '||
                          ':none_cd), '||
               '''RU_Insert'', '||
                 ':azip_cd, '||
               '''RU_Update'', '||
                 ':azip_cd, '||
               '''RU_Delete'', '||
                 ':azip_cd, '||
                 ':none_cd) act_cd, '||
        'f.file_id, max(afv.file_version_id), '||
        'max(f.app_short_name), max(f.filename), '||
        'max(afv.version_segment1), max(afv.version_segment2), '||
        'max(afv.version_segment3), max(afv.version_segment4), '||
        'max(afv.version_segment5), max(afv.version_segment6), '||
        'max(afv.version_segment7), max(afv.version_segment8), '||
        'max(afv.version_segment9), max(afv.version_segment10), '||
        'max(afv.translation_level), max(prba.dest_file_id), '||
        'max(prba.file_type_flag) ';

     l_trailer := 'group by f.file_id ';

    else
      -- Multiple starter patch-runs in temp table

      l_ins_stmt1_contd :=
          'm.patch_run_id, m.act_cd, m.file_id, m.file_version_id, '||
          'm.app_short_name, m.filename, '||
          'm.version_segment1, m.version_segment2, '||
          'm.version_segment3, m.version_segment4, '||
          'm.version_segment5, m.version_segment6, '||
          'm.version_segment7, m.version_segment8, '||
          'm.version_segment9, m.version_segment10, '||
          'm.translation_level, m.dest_file_id, m.file_type_flag '||
        'from '||
          '( '||
          'select ';

      l_sel_list :=
        'pr.patch_run_id, afv.file_version_id, '||
        'f.file_id, f.app_short_name, f.filename, '||
        'afv.version_segment1, afv.version_segment2, '||
        'afv.version_segment3, afv.version_segment4, '||
        'afv.version_segment5, afv.version_segment6, '||
        'afv.version_segment7, afv.version_segment8, '||
        'afv.version_segment9, afv.version_segment10, '||
        'afv.translation_level, '||
        'decode(pca.action_code, ''copy'', '||
          'decode(f.subdir, ''lib'', '||
            'case when (f.filename like ''%.o'' or '||
                       'f.filename like ''%.obj'') '||
                   'then :clib_cd '||
                 'else :none_cd '||
            'end, '||
            ':none_cd), '||
          '''RU_Insert'', :azip_cd, '||
          '''RU_Update'', :azip_cd, '||
          '''RU_Delete'', :azip_cd, '||
          ':none_cd) act_cd, '||
        'row_number() over  (partition by f.file_id '||
              'order by afv.version_segment1 desc, afv.version_segment2 desc, '||
                       'afv.version_segment3 desc, afv.version_segment4 desc, '||
                       'afv.version_segment5 desc, afv.version_segment6 desc, '||
                       'afv.version_segment7 desc, afv.version_segment8 desc, '||
                       'afv.version_segment9 desc, afv.version_segment10 desc, '||
                       'afv.translation_level desc nulls last) as r1, '||
                       'prba.dest_file_id, prba.file_type_flag ';
      l_trailer := ') m where m.r1 = 1';

    end if;  -- End If Multiple starter patch-runs in temp table

    /* Debugging code. Helps in validating the built SQL, as well as in
       sizing the vars appropriately.

    if G_DEBUG then
      put_line('@@INDIVIDUAL VC2 VARS:');
      put_line('l_ins_stmt1 (len='||to_char(length(l_ins_stmt1))||'): ');
        put_line(l_ins_stmt1);
      put_line('l_ins_stmt1_contd (len='||
                             to_char(length(l_ins_stmt1_contd))||'): ');
        put_line(l_ins_stmt1_contd);
      put_line('l_hint (len='||to_char(length(l_hint))||'): ');
        put_line(l_hint);
      put_line('l_sel_list (len='||to_char(length(l_sel_list))||'): ');
        put_line(l_sel_list);
      put_line('l_from_where (len='||to_char(length(l_from_where))||'): ');
        put_line(l_from_where);
      put_line('l_trailer (len='||to_char(length(l_trailer))||'): ');
        put_line(l_trailer);

      put_line('@@FULL INSERT STMT:@@');
      put_line(l_ins_stmt1||l_ins_stmt1_contd||l_hint||
               l_sel_list||l_from_where||l_trailer);
    end if;
    */

    execute immediate l_ins_stmt1 || l_ins_stmt1_contd || l_hint ||
                      l_sel_list || l_from_where || l_trailer
      using L_ARCH_CLIB_ACT_CD, L_ARCH_NONE_ACT_CD, L_ARCH_NONE_ACT_CD,
            L_ARCH_AZIP_ACT_CD, L_ARCH_AZIP_ACT_CD,
            L_ARCH_AZIP_ACT_CD, L_ARCH_NONE_ACT_CD,
            p_appl_top_id, G_PR_ID_ACT_CD;

    if G_DEBUG then
      put_line('Inserted '||to_char(sql%rowcount)||
               ' candidate FILES rows into temp table');
    end if;


    -- Gather stats regardless of # of rows inserted. For that first commit.

    commit;

    FND_STATS.Gather_Table_Stats(G_UN_FND, 'ad_patch_hist_snaps_temp');

    -- Now issue the 2nd SQL (the UPDATE stmt, to flag the unarchived C object
    -- libraries as such)

    update
      ad_patch_hist_snaps_temp t
    set t.action_code = L_ARCH_NONE_ACT_CD
    where t.action_code = L_ARCH_CLIB_ACT_CD
    and not exists (select
                        'libin action exists for this .o (ie. its archived)'
                    from ad_patch_run_bug_actions prba,
                         ad_patch_run_bugs prb,
                         ad_patch_common_actions pca
                    where prba.file_id = t.file_id
                    and prba.patch_run_bug_id = prb.patch_run_bug_id
                    and prb.patch_run_id = t.patch_run_id
                    and pca.common_action_id = prba.common_action_id
                    and pca.action_code = 'libin');


    -- Next, update the CLIB_ARCH_FILE_ID column in the temp table.

    update
      ad_patch_hist_snaps_temp t
    set t.clib_arch_file_id =
      (
        select f.file_id
        from ad_files f
        where f.app_short_name = translate(t.app_short_name, 'A#', 'A')
        and f.subdir = 'lib'
        and f.filename = decode(
                           lower(substr(t.filename, instr(t.filename,'.',-1),
                                        length(t.filename) -
                                          instr(t.filename,'.',-1) + 1)),
                           '.o', 'lib', null) ||
                         decode(translate(t.app_short_name, 'A#', 'A'),
                                'SQLGL', 'gl',
                                'SQLAP', 'ap',
                                'OFA', 'fa',
                                'SQLSO', 'so',
                              lower(translate(t.app_short_name, 'A#', 'A'))) ||
                         decode(
                           lower(substr(t.filename, instr(t.filename,'.',-1),
                                        length(t.filename) -
                                          instr(t.filename,'.',-1) + 1)),
                           '.o', '.a', 'st.lib')
      )
    where t.action_code = L_ARCH_CLIB_ACT_CD;

    -- Update information in ad_patch_hist_snaps_temp about the
    -- irep_gathered_flag. Since ad_patch_hist_snaps_temp table
    -- has information about files which were patched (or newly
    -- introduced), set/reset the irep_gathered_flag to 'N' and
    -- the last_patched_date to sysdate. The irep_gathered_flag
    -- signifies that these files (with the flag set to 'N') have
    -- not been processed yet. Once they are processed, this flag
    -- will be set to 'Y'. Then again when they get patched, we set
    -- the flag to 'N' making them ready for processing .... and the
    -- cycle continues...
    --
    -- Bug 3807737 - sgadag.

    if G_DEBUG then
      put_line('Updating irep_gathered_flag data in ad_patch_hist_snaps_temp');
    end if;


    update ad_patch_hist_snaps_temp t
    set t.irep_gathered_flag = 'N';


    -- Rupsingh Bug 3675019. 06/07/2004


    -- Now, incrementally INSERT new files and UPDATE existing files
    -- in the snapshot.

    if G_DEBUG then
      put_line('Inserting new files in the curr-vw snapshot');
    end if;

    -- insert new files
    insert into ad_snapshot_files
    (
      snapshot_file_id,
      snapshot_id,
      file_id,
      containing_file_id,
      file_version_id,
      dest_file_id,
      file_type_flag,
      update_source_id,
      update_type,
      creation_date, last_update_date,
      last_updated_by, created_by,
      appl_top_id,
      irep_gathered_flag,
      last_patched_date
    )
    select
      ad_snapshot_files_s.nextval,
      l_snapshot_id,
      t.file_id,
      decode(t.action_code, L_ARCH_CLIB_ACT_CD, t.clib_arch_file_id,
                            L_ARCH_AZIP_ACT_CD, l_apps_zip_f_id,
                            null),
      t.file_version_id,
      t.dest_file_id,
      t.file_type_flag,
      t.patch_run_id,
      'P',
      sysdate, sysdate,
      5, 5, p_appl_top_id,
      t.irep_gathered_flag,
      sysdate
    from ad_patch_hist_snaps_temp t
    where t.action_code in (L_ARCH_NONE_ACT_CD, L_ARCH_CLIB_ACT_CD,
                            L_ARCH_AZIP_ACT_CD)
    and not exists (select 'Already exists'
                    from ad_snapshot_files sf
                    where sf.snapshot_id = l_snapshot_id
                    and sf.file_id = t.file_id
                    and ((sf.containing_file_id is null and
                          t.action_code = L_ARCH_NONE_ACT_CD)
                             or
                         (sf.containing_file_id = decode(t.action_code,
                                    L_ARCH_CLIB_ACT_CD, t.clib_arch_file_id,
                                    L_ARCH_AZIP_ACT_CD, l_apps_zip_f_id))
                        )
                    );

    l_snapshot_files_inserted := sql%rowcount;

    if G_DEBUG then
      put_line('Inserted '||to_char(l_snapshot_files_inserted)||
               ' new files in the curr-vw snapshot');
    end if;

    select count(*) into l_snapshot_count
    from   ad_snapshots s, ad_appl_tops t
    where  s.snapshot_type = l_current_snapshot_type and
           s.appl_top_id = t.appl_top_id and
           t.applications_system_name = l_apps_system_name;

    /* At least one current view snapshot should be there at this point */

    if l_snapshot_count = 1 then
      l_inconsistent_flag := 'N';
    elsif l_snapshot_count = 0 then
      raise_application_error(-20000, 'Error: update_current_view: ' ||
                              'Currrent view snapshot doesn''t exist.');
    end if;

    /* insert new files into Global current view snapshot */

    insert into ad_snapshot_files
    (
      snapshot_file_id, snapshot_id, file_id, containing_file_id,
      file_version_id, dest_file_id, file_type_flag,
      update_source_id, update_type,
      creation_date, last_update_date, last_updated_by,
      created_by, appl_top_id, inconsistent_flag
    )
    select
      ad_snapshot_files_s.nextval,
      l_global_snapshot_id,          -- Global Snapshot ID here
      t.file_id,
      decode(t.action_code, L_ARCH_CLIB_ACT_CD, t.clib_arch_file_id,
                            L_ARCH_AZIP_ACT_CD, l_apps_zip_f_id,
                            null),
      t.file_version_id,
      t.dest_file_id,
      t.file_type_flag,
      t.patch_run_id,
      'P',
      sysdate, sysdate,
      5, 5, p_appl_top_id,
      l_inconsistent_flag
    from ad_patch_hist_snaps_temp t
    where
    t.action_code in (L_ARCH_NONE_ACT_CD, L_ARCH_CLIB_ACT_CD,
                                          L_ARCH_AZIP_ACT_CD)
    and not exists (select 'Already exists'
                    from ad_snapshot_files sf
                    where sf.snapshot_id = l_global_snapshot_id
                    and sf.file_id = t.file_id
                    and ((sf.containing_file_id is null and
                          t.action_code = L_ARCH_NONE_ACT_CD)
                             or
                         (sf.containing_file_id = decode(t.action_code,
                                    L_ARCH_CLIB_ACT_CD, t.clib_arch_file_id,
                                    L_ARCH_AZIP_ACT_CD, l_apps_zip_f_id))
                        )
                    );

    l_snapshot_files_inserted := l_snapshot_files_inserted + sql%rowcount;

    if G_DEBUG then
      put_line('Inserted '||to_char(sql%rowcount)||
               ' new files in the Global View snapshot');
    end if;

    commit;

    -- gather stats if necessary

    ad_stats_util_pkg.gather_stats_if_necessary('SNAPSHOT',
                                                l_snapshot_files_inserted,
                                                TRUE,
                                                TRUE,
                                                l_gathered_stats_flag);

    if G_DEBUG then
      put_line('Updating existing files in the curr-vw snapshot');
    end if;

    -- update existing files if higher version, or if dest_file_id
    -- or file_type_flag is different (Current View)

    update ad_snapshot_files sf
    set
      (sf.file_version_id, sf.update_source_id,
       sf.dest_file_id, sf.file_type_flag, sf.irep_gathered_flag) =
         (select t.file_version_id, t.patch_run_id,
                 t.dest_file_id, t.file_type_flag, t.irep_gathered_flag
          from ad_patch_hist_snaps_temp t
          where t.file_id = sf.file_id),
      sf.update_type = 'P',
      sf.last_update_date = sysdate,
      sf.last_updated_by = 5,
      sf.last_patched_date = sysdate
    where sf.snapshot_id = l_snapshot_id
    and sf.file_id in (select t2.file_id
                       from ad_patch_hist_snaps_temp t2
                       where t2.action_code in (L_ARCH_NONE_ACT_CD,
                                       L_ARCH_CLIB_ACT_CD, L_ARCH_AZIP_ACT_CD))
    and exists
     (
      select 'File exists in curr-vw with lower version'
      from ad_patch_hist_snaps_temp t, ad_file_versions fv_old
      where sf.file_id = t.file_id
      and    t.file_version_id = fv_old.file_version_id (+)
      and sf.file_version_id = fv_old.file_version_id (+)
           -- Update only if patch version is higher (code copied from adfilutb.pls)
      and (((fv_old.file_version_id is null)
                or
               ('Y' = decode(
                sign(nvl(t.version_segment1,0) - nvl(fv_old.version_segment1,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment2,0) - nvl(fv_old.version_segment2,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment3,0) - nvl(fv_old.version_segment3,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment4,0) - nvl(fv_old.version_segment4,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment5,0) - nvl(fv_old.version_segment5,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment6,0) - nvl(fv_old.version_segment6,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment7,0) - nvl(fv_old.version_segment7,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment8,0) - nvl(fv_old.version_segment8,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment9,0) - nvl(fv_old.version_segment9,0)),
                -1, null, 1, 'Y', decode(
                sign(nvl(t.version_segment10,0) - nvl(fv_old.version_segment10,0)),
                -1, null, 1, 'Y',  decode(
                sign(t.translation_level - fv_old.translation_level),
                -1, null, 1, 'Y', null)))))))))))
              )
             )
          or (nvl(sf.dest_file_id, -1) <> nvl(t.dest_file_id, -1))
          or (nvl(sf.file_type_flag, 'X') <> nvl(t.file_type_flag, 'X'))
          )
      and ((sf.containing_file_id is null and
            t.action_code = L_ARCH_NONE_ACT_CD)
               or
           (sf.containing_file_id = decode(t.action_code,
                      L_ARCH_CLIB_ACT_CD, t.clib_arch_file_id,
                      L_ARCH_AZIP_ACT_CD, l_apps_zip_f_id))
          )
      );

    if G_DEBUG then
      put_line('Updated '||to_char(sql%rowcount)||
               ' files in the curr-vw snapshot');
    end if;

    commit;


    /* Now Deleting the class files that are not part of apps.zip
       ie. All the entries in ad_patch_run_bug_actions for which
       action_code is RU_Delete */

    /* Bug#3483080/3419891:
         We KNOW that RU_Delete actions will be very, very few.
         Therefore our approach is:
           - Hold these temporarily in a collection type
             - While fetching the data, give the hints exactly as given
               below (no more, no less) worked great in volume testing
               db (gsiappkm).
           - Issue a bulk-bind DELETE using the collection type
    */

    select /*+ ordered use_nl(prba, prb, pr, t)
               index(pca ad_patch_common_actions_n1) */
      distinct prba.file_id
    bulk collect into l_deleted_ru_file_ids
    from ad_patch_common_actions pca,
         ad_patch_run_bug_actions prba,
         ad_patch_run_bugs prb,
         ad_patch_runs pr,
         ad_patch_hist_snaps_temp t
    where pr.patch_run_id       = t.patch_run_id and
          pr.appl_top_id        = p_appl_top_id and
          t.action_code         = G_PR_ID_ACT_CD and
          pr.patch_run_id       = prb.patch_run_id and
          prba.patch_run_bug_id = prb.patch_run_bug_id and
          prba.common_action_id = pca.common_action_id and
          pca.action_code       = 'RU_Delete';

    if nvl(l_deleted_ru_file_ids.last, 0) > 0 then

      forall i in l_deleted_ru_file_ids.first..l_deleted_ru_file_ids.last
        delete from ad_snapshot_files
        where snapshot_id = l_snapshot_id and
              file_id = l_deleted_ru_file_ids(i);

      if G_DEBUG then
        put_line('Deleted '||to_char(sql%rowcount)||
                 ' class files which are removed from apps.zip');
      end if;

    end if;

    commit;


    -- Now update the files into the global view (GV). For this, first insert
    -- relevant rows into the temp table, picking highest version from across
    -- APPL_TOPs, considering just the files delivered by this patch (ie. just
    -- the candidate files)
    --

    get_max_fil_vers_over_appltops(p_apps_system_name => l_apps_system_name,
                                   p_limit_to_candidate_files => TRUE,
                                   p_wipe_out_temp_table_at_start => TRUE,
                                   p_commit => TRUE,
                                   p_gather_stats => TRUE,
                                   p_is_run_flow => l_is_run_flow
                                 );

    declare
      file_id_list             NUM_TAB;
      dest_file_id_list        NUM_TAB;
      file_type_flag_list      VC1_TAB;
      file_version_id_list     NUM_TAB;
      containing_file_id_list  NUM_TAB;
      inconsistent_flag_list   VC1_TAB;

      rows NATURAL := 1000;

      cursor crec is
         select file_id, dest_file_id, file_type_flag,
                file_version_id, containing_file_id,
                inconsistent_flag
         from ad_snapshot_files_temp;
    begin

      open crec;

      loop
        fetch crec bulk collect into
          file_id_list,
          dest_file_id_list,
          file_type_flag_list,
          file_version_id_list,
          containing_file_id_list,
          inconsistent_flag_list
        limit rows;

        if file_id_list.count > 0 then
          forall j in file_id_list.first.. file_id_list.last
            update /*+ INDEX(SF AD_SNAPSHOT_FILES_U2) */
              ad_snapshot_files sf
            set sf.last_update_date  = sysdate,
              sf.last_updated_by   = 5,
              sf.file_version_id   = file_version_id_list(j),
              sf.update_source_id  = -1,
              sf.update_type       = 'P',
              sf.appl_top_id       = null,
              sf.inconsistent_flag = null,
              sf.dest_file_id      = dest_file_id_list(j),
              sf.file_type_flag    = file_type_flag_list(j)
            where
              sf.snapshot_id                  =  l_global_snapshot_id and
              sf.file_id                      =  file_id_list(j) and
              nvl(sf.containing_file_id, -1)  =
              nvl(containing_file_id_list(j), -1) and
              -- rkagrawa: deliberately putting -2 here since for versionless
              -- files, we want the update_type, update_source_id, etc to be
              -- updated each time the file is patched
              (nvl(sf.file_version_id, -1)    <> nvl(file_version_id_list(j), -2) or
              sf.inconsistent_flag            <> inconsistent_flag_list(j) or
              nvl(sf.dest_file_id, -1)        <> nvl(dest_file_id_list(j), -1) or
              nvl(sf.file_type_flag, -1)      <> nvl(file_type_flag_list(j), -1))
          ;
        end if;

        commit;
        exit when crec%NOTFOUND;
      end loop;

      close crec;

      if G_DEBUG then
        put_line('Updated ' || to_char(sql%rowcount) ||
                 ' in Global view snapshot');
      end if;

    end;


    /* Delete files from Global view snapshot */

    if nvl(l_deleted_ru_file_ids.last, 0) > 0 then

      forall i in l_deleted_ru_file_ids.first..l_deleted_ru_file_ids.last
        delete from ad_snapshot_files sf
        where sf.snapshot_id = l_global_snapshot_id and
              sf.file_id = l_deleted_ru_file_ids(i)
        and not exists
        (
         select 'Exists in the curr vw of some appltop'
         from ad_snapshot_files sf1
         where sf1.file_id                   = l_deleted_ru_file_ids(i)
         and nvl(sf1.containing_file_id, -1) = nvl(sf.containing_file_id, -1)
         and sf1.snapshot_id in (
                          select s.snapshot_id
                          from ad_snapshots s, ad_appl_tops a
                          where s.snapshot_type          = l_current_snapshot_type
                          and s.appl_top_id              = a.appl_top_id
                          and a.applications_system_name = l_apps_system_name
                          and nvl(a.active_flag,'Y')     = 'Y'
                                )
        );

      if G_DEBUG then
        put_line('Deleted '||to_char(sql%rowcount)||
                 ' files from Global View snapshot');
      end if;

    end if;

--Bug 7255366 nissubra---
    update ad_snapshots set last_update_date = sysdate,
    snapshot_update_date = sysdate
    where  snapshot_id in (l_snapshot_id, l_global_snapshot_id);

    commit;

  end if;  -- End If l_copy_actions_exist



  --
  -- Maintain bugfixes
  --

  -- First, delete unwanted rows from the temp table.

  delete from ad_patch_hist_snaps_temp
  where action_code <> G_PR_ID_ACT_CD;

  commit;

  handle_bugs(p_action_code => G_PR_ID_ACT_CD,
              p_snapshot_id => l_snapshot_id,
              p_update_global_view => TRUE,
              p_global_snapshot_id => l_global_snapshot_id,
              p_delete_junk_created => FALSE);  -- let it be, can help debug.

  commit;


  -- release the lock upon successful completion

  <<return_success>>

  if not p_caller_is_managing_locks then
    ad_file_util.unlock_infrastructure;
  end if;

exception when others then
  if not p_caller_is_managing_locks then
    -- release the lock upon errors
    ad_file_util.unlock_infrastructure;
  end if;

  -- and allow the exception (that made us land here) to propogate
  raise;
end update_current_view;

-- instantiate_current_view:
-- instantiates snapshot and snapshot-bugfixes (not snapshot-files)
procedure instantiate_current_view
           (p_release_id                           number,
            p_appl_top_id                          number,
            p_fail_if_no_preseeded_rows            boolean,
            p_caller_is_managing_locks             boolean,
            p_return_code               out nocopy varchar2)
is
  l_dummy varchar2(1);
  l_apps_sys_nm varchar2(30);
  l_prim_apps_sys_nm varchar2(30);
  l_at_name varchar2(256);
  l_preseeded_rlse_id number;
  l_rlse_nm varchar2(50);
  l_preseeded_snapshot_id number := -1;
  l_curr_vw_snapshot_id number := -1;
  l_snapshot_bugs_inserted number := 0;
  l_snapshot_files_inserted number := 0;
  l_gathered_stats_flag boolean := FALSE;
  l_inst_gv_snap_from_pseed boolean := FALSE;
  l_global_snapshot_id     number;
  l_global_appl_top_id     number;
--  l_server_type_admin_flag varchar2(1);
--  l_server_type_forms_flag varchar2(1);
--  l_server_type_node_flag  varchar2(1);
--  l_server_type_web_flag   varchar2(1);
  l_snapshot_type varchar2(1);
  l_is_run_flow   boolean;
begin

  l_preseeded_snapshot_id := -1;

  if not p_caller_is_managing_locks then
    -- obtain a lock, to ensure serialized access to temp table infrastructure
    ad_file_util.lock_infrastructure;
  end if;

  if not snapshot_maint_allowed then
    p_return_code := G_SNAPSHOT_MAINT_DISALLOWED; -- snapshot maint not allowed
    goto return_success;
  else
    p_return_code := null;
  end if;

  -- First, abort if PRIMARY apps-sys-nm has not been set by bootstrap code

  select nvl(applications_system_name, '1 UNKNOWN 1')
  into l_prim_apps_sys_nm
  from fnd_product_groups;

  if l_prim_apps_sys_nm = '1 UNKNOWN 1' then
    raise_application_error(-20000,
'Primary Applications System has not been initialized yet.');
  end if;

  select to_char(major_version)||'.'||
         to_char(minor_version)||'.'||
         to_char(tape_version)
  into l_rlse_nm
  from ad_releases
  where release_id = p_release_id;

  -- Fail if appl-top in question is invalid

  begin
    select nvl(applications_system_name, '1 UNKNOWN 1'), name
    into l_apps_sys_nm, l_at_name
    from ad_appl_tops
    where appl_top_id = p_appl_top_id
    and appl_top_type = 'R';
  exception when no_data_found then
    raise_application_error(-20000,
'APPL-TOP ID "'||to_char(p_appl_top_id)||'" is not a valid APPL-TOP.');
  end;

  -- Fail if p_appl_top_id belongs to some other apps-system (refer talk with
  -- Rick on 1/11/02)

  if l_apps_sys_nm <> l_prim_apps_sys_nm then
    raise_application_error(-20000,
'Applications System name for APPL-TOP ID "'||to_char(p_appl_top_id)||
'" is not a primary one. Instantiation not allowed.');
  end if;

  -- Fail if that apps-sys-nm has not been initialized.

  if nvl(l_apps_sys_nm, '1 UNKNOWN 1') = '1 UNKNOWN 1' then
    raise_application_error(-20000,
'Applications System name for APPL-TOP ID "'||to_char(p_appl_top_id)||
'" has not been initialized yet.');
  end if;

  if (ad_zd.is_editions_enabled = 'N' or
      sys_context('userenv', 'current_edition_name') = ad_zd.get_edition('RUN'))
  then
     l_is_run_flow := TRUE;
     l_snapshot_type := 'C';
  else
     l_is_run_flow := FALSE;
     l_snapshot_type := 'P';
  end if;

  begin
    select snapshot_id
    into l_curr_vw_snapshot_id
    from ad_snapshots
    where appl_top_id = p_appl_top_id
    and snapshot_name = 'CURRENT_VIEW'
    and snapshot_type = l_snapshot_type;
  exception when no_data_found then
    null;
  end;


  begin
    select ss.snapshot_id, ss.release_id
    into l_preseeded_snapshot_id, l_preseeded_rlse_id
    from ad_snapshots ss,             -- seeded
         ad_appl_tops ats             -- seeded
    where ss.appl_top_id = ats.appl_top_id
    and ss.snapshot_type = 'B'
    and ss.snapshot_name like '*PRESEEDED*'||l_rlse_nm||'%'
    and ats.name = '*PRESEEDED*'
    and ats.applications_system_name = '*PRESEEDED*'
    and ats.appl_top_type = 'S'
    and ss.release_id = p_release_id;

  exception when no_data_found then
    null;
  end;

  if l_preseeded_snapshot_id <> -1 then
    if l_curr_vw_snapshot_id <> -1 then
      begin
        select 'x' into l_dummy
        from ad_snapshots ads
        where nvl(ran_snapshot_flag, 'N') = 'Y'
        and ads.release_id = p_release_id
        and ads.snapshot_id = l_curr_vw_snapshot_id;
      exception when no_data_found then
        l_dummy := null;
      end;

      if l_dummy is null then
        update ad_snapshots
        set snapshot_type = 'O',
        snapshot_name = snapshot_name||'-'||snapshot_id,
        last_update_date = sysdate
        where snapshot_id = l_curr_vw_snapshot_id;

        l_curr_vw_snapshot_id := -1;

      end if;
    end if;

    if l_curr_vw_snapshot_id = -1 then

      -- create new CV through pressed.

      select ad_snapshots_s.nextval into l_curr_vw_snapshot_id from dual;

      insert into ad_snapshots
      (
        snapshot_id,
        release_id, appl_top_id,
        snapshot_name, comments,
        snapshot_creation_date, snapshot_update_date,
        snapshot_type, ran_snapshot_flag,
        creation_date, last_update_date, last_updated_by, created_by
      )
      select
        l_curr_vw_snapshot_id,
        p_release_id, p_appl_top_id,
        'CURRENT_VIEW', 'Current View',
        sysdate, sysdate,
        l_snapshot_type, 'N',
        sysdate, sysdate, 5, 5
      from dual;


--      select
--        nvl(at1.server_type_admin_flag, 'N'), nvl(at1.server_type_forms_flag, 'N'),
--        nvl(at1.server_type_node_flag,  'N'), nvl(at1.server_type_web_flag,   'N')
--      into
--        l_server_type_admin_flag, l_server_type_forms_flag,
--        l_server_type_node_flag,  l_server_type_web_flag
--      from  ad_appl_tops at1
--      where at1.appl_top_id = p_appl_top_id;

      -- Bugs

      insert into ad_snapshot_bugfixes
      (
        snapshot_bug_id,
        snapshot_id, bugfix_id,
        bug_status, success_flag,
        creation_date, last_update_date, last_updated_by, created_by
      )
      select
        ad_snapshot_bugfixes_s.nextval,
        l_curr_vw_snapshot_id, sbs.bugfix_id,
        sbs.bug_status, sbs.success_flag,
      sysdate, sysdate, 5, 5
      from ad_snapshot_bugfixes sbs     -- seeded
      where sbs.snapshot_id = l_preseeded_snapshot_id
      and not exists (select /*+ INDEX(SB2 AD_SNAPSHOT_BUGFIXES_U2) */
                        'Already exists'
                      from ad_snapshot_bugfixes sb2
                      where sb2.snapshot_id = l_curr_vw_snapshot_id
                      and sb2.bugfix_id = sbs.bugfix_id);

      l_snapshot_bugs_inserted := sql%rowcount;

      insert into ad_snapshot_files
      (
        snapshot_file_id,
        snapshot_id, file_id, containing_file_id,
        file_version_id,
        update_source_id, update_type,
        creation_date, last_update_date, last_updated_by, created_by,
        dest_file_id, file_type_flag
      )
      select
        ad_snapshot_files_s.nextval,
        l_curr_vw_snapshot_id, file_id, containing_file_id,
        file_version_id,
        update_source_id, update_type,
        sysdate, sysdate, 5, 5,
        dest_file_id, file_type_flag
      from ad_snapshot_files sf
      where sf.snapshot_id = l_preseeded_snapshot_id

       -- Added for bug 3947949
--   and ((sf.server_type_admin_flag  = l_server_type_admin_flag
--         and l_server_type_admin_flag = 'Y') or
--           (sf.server_type_forms_flag  = l_server_type_forms_flag
--            and l_server_type_forms_flag = 'Y') or
--           (sf.server_type_node_flag   = l_server_type_node_flag
--            and l_server_type_node_flag = 'Y') or
--           (sf.server_type_web_flag    = l_server_type_web_flag
--            and l_server_type_web_flag = 'Y')
--         )

      and not exists (select  /*+ INDEX(SF2 AD_SNAPSHOT_FILES_U2) */
                        'Already exists' from ad_snapshot_files sf2
                      where sf2.snapshot_id = l_curr_vw_snapshot_id
                      and sf2.file_id       = sf.file_id
                      and nvl(sf2.containing_file_id, -1) =
                                                nvl(sf.containing_file_id, -1));
      l_snapshot_files_inserted := sql%rowcount;

      if l_snapshot_files_inserted > 0 then

        /* set ran_snapshot_flag only incase the *PRESEEDED* snapshot
         * has files information.
         */

        update ad_snapshots
        set ran_snapshot_flag = 'Y',
        last_update_date = sysdate
        where snapshot_id = l_curr_vw_snapshot_id;

        l_inst_gv_snap_from_pseed := TRUE;

      end if;

      p_return_code := G_INSTANTIATED_SNAPSHOT_BUGS;  -- Instantiated snpsht-bugs

    else
      p_return_code := G_ALREADY_INSTANTIATED;   -- Already Instantiated
    end if;

  else --  l_preseeded_snapshot_id is null

    if l_curr_vw_snapshot_id <> -1 then

      begin
        select 'x' into l_dummy
        from ad_snapshots ads, ad_releases adr
        where ads.release_id = adr.release_id
        and ads.snapshot_id = l_curr_vw_snapshot_id
        and adr.major_version = ( select distinct major_version from ad_releases
                                  where release_id = p_release_id );

      exception when no_data_found then
        l_dummy := null;
      end;

      if l_dummy is null then

        update ad_snapshots
        set snapshot_type = 'O',
        last_update_date = sysdate,
        snapshot_name = snapshot_name||'-'||snapshot_id
        where snapshot_id = l_curr_vw_snapshot_id;

        l_curr_vw_snapshot_id := -1;

      end if;
    end if;

    if l_curr_vw_snapshot_id = -1 then

      if p_fail_if_no_preseeded_rows then
        raise_application_error(-20000,
          'No preseeded snapshots to instantiate from.');
      else
        p_return_code := G_NO_PRESEEDED_BASELINE;  -- No Preseeded Baseline rows
        l_preseeded_snapshot_id := -1;
      end if;

      p_return_code := G_INSTANTIATED_SNAPSHOT;   -- Instantiated Snapshot

      select ad_snapshots_s.nextval into l_curr_vw_snapshot_id from dual;

      insert into ad_snapshots
      (
        snapshot_id,
        release_id, appl_top_id,
        snapshot_name, comments,
        snapshot_creation_date, snapshot_update_date,
        snapshot_type, ran_snapshot_flag,
        creation_date, last_update_date, last_updated_by, created_by
      )
      select
        l_curr_vw_snapshot_id,
        p_release_id, p_appl_top_id,
        'CURRENT_VIEW', 'Current View',
        sysdate, sysdate,
        l_snapshot_type, 'N',
        sysdate, sysdate, 5, 5
      from dual;

    else

      update ad_snapshots
      set release_id = p_release_id,
      last_update_date = sysdate
      where snapshot_id = l_curr_vw_snapshot_id
      and release_id <> p_release_id;

      p_return_code := G_ALREADY_INSTANTIATED;   -- Already Instantiated

    end if;

  end if;

  commit;

  -- gather stats if necessary

  ad_stats_util_pkg.gather_stats_if_necessary
  (
    'SNAPSHOT',
    l_snapshot_bugs_inserted + l_snapshot_files_inserted,
    TRUE,
    TRUE,
    l_gathered_stats_flag
  );

  backfill_bugs_from_patch_hist(l_curr_vw_snapshot_id);

  commit;


    -- The cust likely already has curr-vw snapshots of all APPLTOPs. Just
    -- instantiate global view using those CV's (as opposed to considering
    -- creating from preseeded info)

  instantiate_global_view(p_apps_system_name         => l_apps_sys_nm,
                            p_instantiate_from_preseed => l_inst_gv_snap_from_pseed,
                            p_cur_appl_top_id          => p_appl_top_id,
                            p_release_name             => l_rlse_nm,
                            p_is_run_flow              => l_is_run_flow
                           );
  <<return_success>>

  if not p_caller_is_managing_locks then
    ad_file_util.unlock_infrastructure;
  end if;

exception when others then
  if not p_caller_is_managing_locks then
    -- release the lock upon errors
    ad_file_util.unlock_infrastructure;
  end if;

  -- and allow the exception (that made us land here) to propogate
  raise;
end instantiate_current_view;


procedure update_rel_name(rel_name varchar2) is

G_CURRENT_RELEASE varchar2(50);
ret_status boolean;
begin
   select release_name
     into G_CURRENT_RELEASE
    from fnd_product_groups;

 ret_status:=ad_apps_private.compare_releases(G_CURRENT_RELEASE, rel_name);
--Compare and update ONLY if the rel_name is greater than the value in db.
       if ret_status = TRUE then
            update fnd_product_groups
               set    release_name = rel_name,
                      last_update_date = sysdate,
                      last_updated_by = 1
               where  product_group_id = 1;
   --dbms_output.put_line('major versions are different');
       else
           null; -- release_name is > the extension mimipack info for MP driver
   --dbms_output.put_line('no update needed.');
      end if;
end update_rel_name;

begin
  -- initialization code

  declare
    l_stat varchar2(1);
    l_ind varchar2(1);
  begin
    if not FND_INSTALLATION.Get_App_Info('FND', l_stat, l_ind, G_UN_FND) then
      raise_application_error(-20000, 'Error calling Get_App_Info().');
    end if;
  end;

end ad_file_sys_snapshots_pkg;
