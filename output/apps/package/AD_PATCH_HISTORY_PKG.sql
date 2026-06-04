
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PATCH_HISTORY_PKG" AUTHID CURRENT_USER as
/* $Header: adphmnts.pls 115.4 2002/12/11 23:08:28 wjenkins ship $ */


-- PROCEDURE backfill_onsite_versions:
-- Walks back in time and fills the onsite-versions of certain actions.
--
-- If p_min_run_date is null, then it looks at the entire history, otherwise
-- only looks at patch runs since p_min_run_date (inclusive).
--
-- Commits?: Yes
--
procedure backfill_onsite_versions
           (p_min_run_date date);


-- PROCEDURE bld_cf_repos_using_upload_hist:
-- Inserts into AD_CHECK_FILES using information uploaded from applptch.txt.
-- Does something ONLY if the checkfile repository is empty AND is some patch
-- history information exists.
--
-- Commits?: Yes
--
procedure bld_cf_repos_using_upload_hist
           (anything_inserted out nocopy number);


end ad_patch_history_pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PATCH_HISTORY_PKG" as
/* $Header: adphmntb.pls 115.5 2002/12/11 23:10:57 wjenkins ship $ */

--
--
-- Private procedures
--

--
/*
NAME:
Procedure bld_execs_and_copy_acts_list():

DESCRIPTION:
Inserts into AD_PTCH_HST_EXE_COP_TMP records of 2 kinds (viz. executed
copy actions and all non-copy actions) in patches that have been uploaded
from applptch.txt

COLUMNS THAT MAY NEED EXPLANATION:
 - ACTION: 1 for "copy" actions, 2 otherwise
 - FILE_VERSION: Relevant only for "executed" "copy" actions . Holds the
   patch-file-version
 - MAX-COPY-DATE: Holds the run-date of the latest "copy" action on that
   file in that appl-top, prior to (attempting to) running the action
   in question.

LOGIC: For a particular action on a file in a specific appl-top (source),
we walk back in time starting from a some action, till we get a copy
action for that file on that appl-top (target). The version there (on
the target) can then be said to have been the "onsite" version when the
original action (the source) must have been attempted to be executed.

NOTE: The only reason dynamic sql is used is bcoz PL/SQL wouldn't let me use
analytic functions otherwise (an analytic windowing function is used
here, whose start point is fixed and the end point is the row just
prior to the current-row)

CAUTION: The windowing function has 2 implications related to MAX_COPY_DATE:
 1. If the FIRST (ie. when walked back all the way to the beginning) patch
had 2 executed "copy" actions for the same file, then the first one
would have a null MAX_COPY_DATE (bcoz there is no "prior" record to walk
back to), and the second one would have the RUN-DATE of the first stored
in its MAX_COPY_DATE. But the RUN-DATE of both are the same (since they
are part of the same patch) Truly, we need to skip such cases. Its difficult
if not impossible to do it as part the single SQL, hence we delegate the
task of skipping such records to the caller.

 2. On subsequent uploads of applptch.txt (ie. other than the first upload.
In other words, say if uploaded from an applptch.txt that was created bcoz
a patch was run in pre-install mode), the FIRST action in the temp table
is not truly the first. There could be prior executed "copy" actions for
that file in prior normal mode patches. But the walk-back logic would not
look at those. As a result, the on-site version during some actions in
patches applied in pre-install mode may not be known. This is a
limitation, and is hoped NOT to be a severe one.
*/
--
procedure bld_execs_and_copy_acts_list
           (p_min_run_date date)
is
   l_str varchar2(2000);
begin
   l_str := 'insert into ad_ptch_hst_exe_cop_tmp '||
   '( '||
      'row_id, action, appl_top_id, run_date, '||
      'file_id, file_version_id, max_copy_date '||
   ') '||
   'select '||
      'prba.rowid, '||
      'decode(pca.action_code, ''copy'', 1, 2), '||
      'pr.appl_top_id, '||
      'pr.end_date, '||
      'nvl(pca.loader_data_file_id, prba.file_id), '||
      'decode(pca.action_code, ''copy'', decode(prba.executed_flag, '||
            '''Y'', prba.patch_file_version_id, null),  '||
                  'null), '||
      'max(decode(pca.action_code, ''copy'', decode(prba.executed_flag, '||
         '''Y'', pr.end_date, to_date(''01/01/1990'',''MM/DD/YYYY'')), '||
               'to_date(''01/01/1990'',''MM/DD/YYYY''))) over '||
         '(partition by nvl(pca.loader_data_file_id, prba.file_id), '||
                  'pr.appl_top_id '||
         'order by pr.end_date, '||
               'decode(pca.action_code, ''copy'', 1, 2) '||
         'rows between unbounded preceding and 1 preceding) '||
   'from ad_patch_runs pr, '||
      'ad_patch_run_bugs prb, '||
      'ad_files f, '||
      'ad_patch_common_actions pca, '||
      'ad_patch_run_bug_actions prba '||
   'where prba.common_action_id = pca.common_action_id '||
   'and prba.file_id = f.file_id '||
   'and prba.patch_run_bug_id = prb.patch_run_bug_id '||
   'and prb.patch_run_id = pr.patch_run_id '||
   -- only look at rows uploaded from applptch.txt
   'and pr.source_code = ''TXT'' '||
   -- in sync with the actions considered in
   -- adpvovGetFSVerAndAddToHash() (but excl fcopy)
   'and pca.action_code in (''copy'', ''libin'', ''forcecopy'', '||
            '''genfpll'', ''genform'', ''genrpll'', '||
            '''genrep'', ''genmenu'', '||
            '''sql'', ''exec'', ''exectier'') '||
   -- If its a loader call but the parsing logic of
   -- adpfilExtractFileFromArgs() failed to identify the file-id, skip it
   'and not (pca.loader_data_file_id is null and f.filename in ( '||
            '''FNDLOAD'', ''WFLOAD'', ''akload.class'')) '||
   -- Only consider (1) exec(tier) calls of the ODF and loader
     -- kinds, and (2) actions other than exec(tier).
   'and ( '||
      '(pca.action_code in (''exec'', ''exectier'') and '||
         '(pca.loader_data_file_id is not null or '||
          'pca.action_what_sql_exec like ''odf%'') '||
      ') '||
      'or '||
      'pca.action_code not in (''exec'', ''exectier'') '||
      ') '||
   -- To allow multiple runs (incremental)
   'and prba.onsite_file_version_id is null';

   if p_min_run_date is not null then
      l_str := l_str || ' and pr.end_date >= :min_end_date';

      execute immediate l_str using p_min_run_date;
   else
      execute immediate l_str;
   end if;

end bld_execs_and_copy_acts_list;


--
--
-- Public procedures
--

procedure backfill_onsite_versions
           (p_min_run_date date)
is
   cursor c_actions is
      select rowidtochar(row_id)
      from ad_ptch_hst_exe_cop_tmp
      where max_copy_date is not null
      and (action <> 1 or max_copy_date <> run_date);

   type T_ROWID is varray(1000) of varchar2(18);
   l_arr_size constant number := 1000;

   l_rowid T_ROWID;

     l_cur_fetch number := 0;
   l_prev_fetch number := 0;
   l_row number;
   u number := 0;
begin
   -- First, build the temp area

   bld_execs_and_copy_acts_list(p_min_run_date);

   -- Commit, to free up rollback segs

   commit;

   -- Now do the actual update

   open c_actions;

   l_prev_fetch := 0;

   <<one_iter_per_limit_fetch>>
   loop
      fetch c_actions bulk collect into l_rowid limit l_arr_size;

      l_cur_fetch := c_actions%rowcount - l_prev_fetch;
      l_prev_fetch := c_actions%rowcount;

      forall l_row in 1..l_cur_fetch
      update ad_patch_run_bug_actions prba
      set prba.onsite_file_version_id =
      (
         select
         /*+ USE_NL(E)
            INDEX (AD_PTCH_HST_EXE_COP_TMP AD_PTCH_HST_EXE_COP_TMP_U1)
            INDEX(AD_PTCH_HST_EXE_COP_TMP AD_PTCH_HST_EXE_COP_TMP_N1)
         */
            distinct c.file_version_id
            -- The "distinct" isn't really necessary. The values should
            -- be the same. The distinct is just to throw up an error
            -- if they aren't the same.
         from ad_ptch_hst_exe_cop_tmp c, ad_ptch_hst_exe_cop_tmp e
         where e.row_id = chartorowid(l_rowid(l_row))
         and e.appl_top_id = c.appl_top_id
         and e.file_id = c.file_id
         and c.action = 1
         and e.max_copy_date = c.run_date
      )
      where prba.rowid = chartorowid(l_rowid(l_row))
      and prba.onsite_file_version_id is null;

      exit when c_actions%notfound;
   end loop one_iter_per_limit_fetch;

   close c_actions;

   --
   commit;
   --
end backfill_onsite_versions;


/*
NAME:
Procedure bld_cf_repos_using_upload_hist():

DESCRIPTION:
Inserts into AD_CHECK_FILES using information uploaded from applptch.txt.
Does something ONLY if the checkfile repository is empty AND is some patch
history information exists.

NOTE: The only reason dynamic sql is used is bcoz PL/SQL wouldn't let me use
analytic functions otherwise (an analytic ranking function is used here)
*/
--
procedure bld_cf_repos_using_upload_hist
           (anything_inserted out nocopy number)
is
   dummy varchar2(1);
begin
   anything_inserted := 0;

   select 'x'
   into dummy
   from dual
   where not exists (select 'x' from ad_check_files)
   and exists (select 'x' from ad_patch_runs);
   --
   --
   execute immediate 'insert into ad_check_files '||
   '( '||
      'check_file_id, file_id,  '||
      'file_version_id, distinguisher,  '||
      'creation_date '||
   ') '||
   'select  '||
      'ad_check_files_s.nextval, max_vers.file_id, '||
      'max_vers.file_version_id, max_vers.distinguisher, '||
      'sysdate '||
   'from '||
   '( '||
   'select '||
      'nvl(pca.loader_data_file_id, prba.file_id)   file_id, '||
      'fv.file_version_id                  file_version_id, '||
      'decode(pca.action_code, ''sql'', null, '||
         'decode(substr(pca.action_what_sql_exec, 1, 3), ''odf'', '||
            'decode(substr(pca.action_phase, 1,  '||
               'decode(instr(pca.action_phase, ''+''), 0,  '||
                  'length(pca.action_phase),  '||
                  'instr(pca.action_phase, ''+'')-1)), '||
               '''tab'', ''tab_tables'', '||
               '''seq'', ''seq_sequences'', '||
               '''vw'', ''vw_views'', '||
               'null), '||
            'null))                  distinguisher, '||
      'rank() over (partition by nvl(pca.loader_data_file_id,  '||
                        'prba.file_id), '||
         'decode(pca.action_code, ''sql'', null, '||
            'decode(substr(pca.action_what_sql_exec, 1, 3), ''odf'', '||
               'decode(substr(pca.action_phase, 1,  '||
                  'decode(instr(pca.action_phase, ''+''), 0,  '||
                     'length(pca.action_phase),  '||
                     'instr(pca.action_phase, ''+'')-1)), '||
                  '''tab'', ''tab_tables'', '||
                  '''seq'', ''seq_sequences'', '||
                  '''vw'', ''vw_views'', '||
                  'null), '||
               'null)) '||
         'order by fv.version_segment1 desc, '||
         'fv.version_segment2 desc, fv.version_segment3 desc, '||
         'fv.version_segment4 desc, fv.version_segment5 desc, '||
         'fv.version_segment6 desc, fv.version_segment7 desc, '||
         'fv.version_segment8 desc, fv.version_segment9 desc, '||
         'fv.version_segment10 desc,  '||
         'fv.translation_level desc) as rank1 '||
   'from '||
      'ad_file_versions fv, '||
      'ad_patch_runs pr, '||
      'ad_patch_run_bugs prb, '||
      'ad_patch_common_actions pca, '||
      'ad_patch_run_bug_actions prba '||
   'where prba.common_action_id = pca.common_action_id '||
   'and prba.patch_run_bug_id = prb.patch_run_bug_id '||
   'and prb.patch_run_id = pr.patch_run_id '||
   'and prba.onsite_file_version_id = fv.file_version_id '||
   'and pca.action_code in (''sql'', ''exec'', ''exectier'') '||
   'and prba.executed_flag = ''Y'' '||
   'and pr.source_code = ''TXT'' '||
   'group by '||
      -- The group-by is necessary to suppress repeated entries if the
      -- SAME version of the SAME file was (executed) in different
      -- patches (or in different bugs in the same patch)
      'nvl(pca.loader_data_file_id, prba.file_id), fv.file_version_id, '||
      'decode(pca.action_code, ''sql'', null, '||
         'decode(substr(pca.action_what_sql_exec, 1, 3), ''odf'', '||
            'decode(substr(pca.action_phase, 1,  '||
               'decode(instr(pca.action_phase, ''+''), 0,  '||
                  'length(pca.action_phase),  '||
                  'instr(pca.action_phase, ''+'')-1)), '||
               '''tab'', ''tab_tables'', '||
               '''seq'', ''seq_sequences'', '||
               '''vw'', ''vw_views'', '||
               'null), '||
            'null)), '||
      'fv.version_segment1, fv.version_segment2, fv.version_segment3, '||
      'fv.version_segment4, fv.version_segment5, fv.version_segment6, '||
      'fv.version_segment7, fv.version_segment8, fv.version_segment9, '||
      'fv.version_segment10, fv.translation_level '||
   ') max_vers '||
   'where max_vers.rank1 = 1';
   --
   anything_inserted := sql%rowcount;
   --
   commit;
   --
   --
exception when no_data_found then
   -- If ad_check_files already has data, or patch-hist is NOT
   -- populated, simply return.
   --
   null;
end bld_cf_repos_using_upload_hist;


end ad_patch_history_pkg;
