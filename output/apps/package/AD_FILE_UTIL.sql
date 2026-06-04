
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_FILE_UTIL" AUTHID CURRENT_USER as
/* $Header: adfiluts.pls 120.1.12020000.3 2012/08/07 14:14:11 mkumandu ship $ */

error_buf varchar2(32760);

procedure lock_infrastructure;

procedure unlock_infrastructure;


--
-- Procedure
--   lock_and_empty_temp_table
--
-- Purpose
--   Serializes access to the AD_CHECK_FILE_TEMP table using a User Lock
--   (created using DBMS_LOCK mgmt services), and also empties the table.
--   This lock would be a session-level lock, and is intended to be released
--   when the calling script is totally done with its use of the temp table.
--
--   This is especially necessary when we have multiple scripts that use
--   the infrastructure built around AD_CHECK_FILE_TEMP, that perhaps could
--   be running in parallel. As of 2/25/02, we already a case for
--   this, viz. the snapshot preseeding scripts and the checkfile preseeding
--   scripts use the same temp table. In the absence of such a serializing
--   facility, they could end up stamping on each others feet (eg. creating
--   bugs as files and files as bugs!!)
--
-- Usage
--   Any script that uses the AD_CHECK_FILE_TEMP infrastructure must do the
--   following:
--   a) Call lock_and_empty_temp_table
--   b) Insert rows into AD_CHECK_FILE_TEMP
--   c) Gather statistics on AD_CHECK_FILE_TEMP
--   d) Call the relevant packaged-procedure that reads the temp table and
--      loads whatever is necessary.
--   e) Commit.
--
--   Then repeat steps (a) thru (e) for other rows. When all batches have
--   finished processing, then unlock_infrastructure() should be called to
--   release the User Lock at the very end.
--
-- Arguments
--   APPLSYS schema name
--
procedure lock_and_empty_temp_table
           (p_un_fnd varchar2);

--
-- Procedure
--   load_file_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to ad_files
--
--   Only creates rows that don't already exist.
--
--   Processes all rows in ad_check_file_temp with active_flag='Y'.
--
--   To handle batch sizes:
--
--   1) - fill up whole table with null active_flag
--      - In a loop:
--        - update a batch to have active_flag='Y'
--        - process the batch
--        - delete the batch
--      - using 'where rownum < batch+1' is handy here
--
--   2) perform (truncate, load, process) cycles in an outer loop where
--      only <batch size> rows are loaded and processed at a time.
--
--   Updates the file_id column of ad_check_file_temp so that all
--   rows point to the file_id of the file referenced in the row.
--
-- Arguments
--   none
--
procedure load_file_info;

--
-- Procedure
--   load_file_version_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to ad_files and
--   ad_file_versions.
--
--   Only creates rows that don't already exist.
--
--   Processes all rows in ad_check_file_temp with active_flag='Y'.
--
--   To handle batch sizes:
--
--   1) - fill up whole table with null active_flag
--      - In a loop:
--        - update a batch to have active_flag='Y'
--        - process the batch
--        - delete the batch
--      - using 'where rownum < batch+1' is handy here
--
--   2) perform (truncate, load, process) cycles in an outer loop where
--      only <batch size> rows are loaded and processed at a time.
--
--   Calls load_file_info
--
--   Updates the file_version_id column of ad_check_file_temp so that all
--   rows point to the file_version_id of the file version referenced
--   in the row.
--
-- Arguments
--   none
--
procedure load_file_version_info;

--
-- Procedure
--   load_checkfile_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to ad_files,
--   ad_file_versions, and ad_check_files.
--
--   Only creates rows in ad_files and ad_file_versions that don't
--   already exist. In ad_check_files, it creates rows that don't already
--   exist and also updates existing rows if the version to load is higher
--   than the current version in ad_check_files.
--
--   Processes all rows in ad_check_file_temp with active_flag='Y'.
--
--   To handle batch sizes:
--
--   1) - fill up whole table with null active_flag
--      - In a loop:
--        - update a batch to have active_flag='Y'
--        - process the batch
--        - delete the batch
--      - using 'where rownum < batch+1' is handy here
--
--   2) perform (truncate, load, process) cycles in an outer loop where
--      only <batch size> rows are loaded and processed at a time.
--
--   Calls load_file_version_info
--
--   Updates the check_file_id column of ad_check_file_temp so that any
--   rows that were already in ad_check_files point to the check_file_id
--   of the (file, distinguisher) referenced in the row.  Rows in
--   ad_check_file_temp that did not already have corresponding rows in
--   ad_check_files still have null values for check_file_id
--   (assuming they started out as null)
--
-- Arguments
--   p_ebr_flow => true populate ad_check_file_history table
--              => false doesn't populate ad_check_file_history table
--
procedure load_checkfile_info(p_ebr_flow boolean default false);

--
-- Procedure
--   update_timestamp
--
-- Purpose
--   Inserts/updates a row in AD_TIMESTAMPS corresponding to the
--   specified row type and attribute.
--
-- Arguments
--   in_type         The row type
--   in_attribute    The row attribute
--   in_timestamp    A timestamp.  Defaults to sysdate.
--
-- Notes
--   This is essentially the same as ad_invoker.update_timestamp
--   Added it here to make it easier to call from APPS.
--
procedure update_timestamp
           (in_type      in varchar2,
            in_attribute in varchar2,
            in_timestamp in date);

procedure update_timestamp
           (in_type      in varchar2,
            in_attribute in varchar2);
--
--
--
-- Procedure
--   load_patch_onsite_vers_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to ad_files and
--   ad_file_versions.
--
--   Only creates rows that don't already exist.
--
--   Processes all rows in ad_check_file_temp with active_flag='Y'.
--
--   To handle batch sizes:
--
--   1) - fill up whole table with null active_flag
--      - In a loop:
--        - update a batch to have active_flag='Y'
--        - process the batch
--        - delete the batch
--      - using 'where rownum < batch+1' is handy here
--
--   2) perform (truncate, load, process) cycles in an outer loop where
--      only <batch size> rows are loaded and processed at a time.
--
--   Calls load_file_info
--
--   Updates the file_version_id and file_version_id_2 columns of
--   ad_check_file_temp so that all rows point to the file_version_id
--   of the file versions referenced in the row.
--
--   Doesn't try to update ad_file_versions for rows in ad_check_file_temp
--   with manifest_vers='NA' or manifest_vers_2='NA'.  These values mean
--   "no version for this file", so no corresponding record should be
--   created in ad_file_versions.
--
-- Arguments
--   none
--
procedure load_patch_onsite_vers_info;
--
--
--
-- Procedure
--   load_snapshot_file_info
--
-- Purpose
--  Create Snapshot data by
--  1.Calls  ad_file_versions  and loads the file versions
--    into the ad_check_file_temp table .
--  2.Updates rows in AD_SNAPSHOT_FILES from  ad_check_file_temp
--    which have the same file_id, snapshot_id and containing_file_id
--  3.Inserts those  rows from ad_check_file_temp  into AD_SNAPSHOT_FILES
--    which exists in ad_check_file_temp but are not in AD_SNAPSHOT_FILES.
--    for the  given snapshot_id
--  4.Delete those rows from AD_SNAPSHOT_FILES which exists
--    in AD_SNAPSHOT_FILES  but do not exist in ad_check_file_temp
--    for the  given snapshot_id
--
-- Arguments
-- is_upload pass TRUE if it is an upload otherwise FALSE
--
--
procedure load_snapshot_file_info
           (snp_id number,
            preserve_irep_flag number);
--
--
--
-- Procedure
--   load_preseeded_bugfixes
--
-- Purpose
--   Gets the bug_id from AD_BUGS for the bugnumbers in
--   in ad_check_file_temp table .
--   Creates new rows in the AD_BUGS for the new bugnumbers
--   and gets the bug_id for those bugnumbers and stores them
--   ad_check_file_temp table .
--
--   Inserts those BUG_IDs into AD_SNAPSHOT_BUGFIXES
--
--
-- Arguments
-- None
--
procedure load_preseeded_bugfixes;
--
--
procedure load_patch_hist_action
           (bugs_processed    out NOCOPY number,
            actions_processed out NOCOPY number);

-- Procedure
--     create_global_view
-- Arguments
--     p_apps_system_name - Applications system name
-- Purpose
--     Procedure to create Global View snapshot using exisiting
--     current view snapshots for an applications system.
-- Notes

procedure create_global_view(p_apps_system_name varchar2,
                             p_is_run_flow boolean default true);
--
--
-- Procedure
--     populate_snapshot_files_temp
-- Arguments
--     p_apps_system_name   - Applications System Name
--
--     p_min_file_id        - lower limit file_id in the range of file_ids
--
--     p_max_file_id        - upper limit file_id in the range of file_ids
--
--     p_global_snapshot_id - Global snapshot_id
--
--     p_un_fnd             - applsys username
--
--     p_iteration          - which iteration  (1,2,etc)
-- Purpose
--     This procedure populates temp table with a range of file_ids
--     processes the data and updates the ad_snapshot_files  with negative
--     global snapshot_id
-- Notes
--

procedure populate_snapshot_files_temp(p_applications_sys_name varchar2,p_min_file_id number,
                                       p_max_file_id number,p_global_snapshot_id number,
                                       p_un_fnd varchar2,p_iteration number,
                                       p_is_run_flow boolean default true);

--
--
-- Procedure
--     populate_snapshot_bugs_temp
-- Arguments
--     p_apps_system_name   - Applications System Name
--
--     p_min_bug_id        - lower limit bugfix_id in the range of bugfix_id
--
--     p_max_bug_id        - upper limit bugfix_id in the range of bugfix_id
--
--     p_global_snapshot_id - Global snapshot_id
--
--     p_un_fnd             - applsys username
--
--     p_iteration          - which iteration  (1,2,etc)
-- Purpose
--     This procedure populates temp table  with a range of file_ids
--     processes the data and updates the ad_snapshot_bugfixes  with negative
--     global snapshot_id
-- Notes
--
procedure populate_snapshot_bugs_temp(p_applications_sys_name varchar2,p_min_bug_id number,
                                      p_max_bug_id number,p_global_snapshot_id number,
                                      p_un_fnd varchar2,p_iteration number,
                                      p_is_run_flow boolean default true);


-- Procedure
--   load_prepmode_checkfile_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to
--   ad_premode_check_files table, when applying a patch in "prepare" mode.
--
-- Arguments
--   none
--
procedure load_prepmode_checkfile_info;


--
-- Procedure
--   cleanup_prepmode_checkfile_info
--
-- Purpose
--   deletes rows from ad_premode_check_files (called after the merge)
--
-- Arguments
--   none
--
procedure cln_prepmode_checkfile_info;
--
--
procedure load_snpst_file_server_info
           (snp_id number);
--
--
end ad_file_util;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_FILE_UTIL" as
/* $Header: adfilutb.pls 120.17.12020000.6 2013/06/10 07:37:57 mkumandu ship $ */

procedure lock_infrastructure is
  l_lockhandle varchar2(128);
  l_status number := 100;
  l_exit_loop boolean := FALSE;
begin
  ad_file_util.error_buf := 'lock_infrastructure()';

  dbms_lock.allocate_unique('ORA_APPS_AD_CHKFILTMP', l_lockhandle);

  l_exit_loop := FALSE;

  loop
    exit when l_exit_loop;

    l_status := dbms_lock.request(l_lockhandle);

    if l_status in (0, 4) then
      -- 0 => success
      -- 4 => already held, deem as success.

      l_exit_loop := TRUE;

    elsif l_status <> 1 then
      -- 1 => Timeout, in which case we want to keep trying (ie. stay in the
      -- loop). Any value other than 1 is a fatal error.

      raise_application_error(-20000,
                              'Fatal error in lock_infrastructure() - '||
                              to_char(l_status));
    end if;

  end loop;

end lock_infrastructure;

procedure unlock_infrastructure is
  l_lockhandle varchar2(128);
  l_status number := 100;
begin
  ad_file_util.error_buf := 'unlock_infrastructure()';

  dbms_lock.allocate_unique('ORA_APPS_AD_CHKFILTMP', l_lockhandle);

  l_status := dbms_lock.release(l_lockhandle);

  if l_status not in (0, 4) then
    -- 0 => success.  4 => never held, so deem as success. Any other value is
    -- an error.

    raise_application_error(-20000,
                            'Fatal error in unlock_infrastructure() - '||
                            to_char(l_status));
  end if;

end unlock_infrastructure;

--
-- Procedure
--   lock_and_empty_temp_table
--
-- Purpose
--   Serializes access to the AD_CHECK_FILE_TEMP table using a User Lock
--   (created using DBMS_LOCK mgmt services), and also empties the table.
--   This lock would be a session-level lock, and is intended to be released
--   when the calling script is totally done with its use of the temp table.
--
--   This is especially necessary when we have multiple scripts that use
--   the infrastructure built around AD_CHECK_FILE_TEMP, that perhaps could
--   be running in parallel. As of 2/25/02, we already a case for
--   this, viz. the snapshot preseeding scripts and the checkfile preseeding
--   scripts use the same temp table. In the absence of such a serializing
--   facility, they could end up stamping on each others feet (eg. creating
--   bugs as files and files as bugs!!)
--
-- Usage
--   Any script that uses the AD_CHECK_FILE_TEMP infrastructure must do the
--   following:
--   a) Call lock_and_empty_temp_table
--   b) Insert rows into AD_CHECK_FILE_TEMP
--   c) Gather statistics on AD_CHECK_FILE_TEMP
--   d) Call the relevant packaged-procedure that reads the temp table and
--      loads whatever is necessary.
--   e) Commit.
--
--   Then repeat steps (a) thru (e) for other rows. When all batches have
--   finished processing, then unlock_infrastructure() should be called to
--   release the User Lock at the very end.
--
-- Arguments
--   none
--
procedure lock_and_empty_temp_table
           (p_un_fnd varchar2) is
begin
  lock_infrastructure;

  ad_file_util.error_buf := 'truncate ad_check_file_temp';

  execute immediate 'truncate table '||p_un_fnd||'.ad_check_file_temp';

exception when others then
  ad_file_util.error_buf := 'lock_and_empty_temp_table('||
                            ad_file_util.error_buf||
                            ')';

  raise;
end lock_and_empty_temp_table;

--
-- Procedure
--   load_file_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to ad_files
--
--   Only creates rows that don't already exist.
--
--   Processes all rows in ad_check_file_temp with active_flag='Y'.
--
--   To handle batch sizes:
--
--   1) - fill up whole table with null active_flag
--      - In a loop:
--        - update a batch to have active_flag='Y'
--        - process the batch
--        - delete the batch
--      - using 'where rownum < batch+1' is handy here
--
--   2) perform (truncate, load, process) cycles in an outer loop where
--      only <batch size> rows are loaded and processed at a time.
--
--   Updates the file_id column of ad_check_file_temp so that all
--   rows point to the file_id of the file referenced in the row.
--
-- Arguments
--   none
--
procedure load_file_info
is
begin
--
-- process ad_files
--

--
-- get file_id from ad_files
--
-- set junk to null to free up space in row and avoid row chaining
--
  ad_file_util.error_buf := 'load_file_info('||
                            ' update ad_check_file_temp t '||
                            'set t.file_id = (select f.file_id '||
                            'from ad_files f '||
                            'where f.app_short_name = t.app_short_name '||
                            'and   f.subdir = t.subdir '||
                            'and   f.filename = t.filename), '||
                            't.junk = null '||
                            'where nvl(t.active_flag,''N'') = ''Y'';):(';
  begin
    update ad_check_file_temp t
    set t.file_id =
     (select /*+ INDEX(F AD_FILES_U2) */ f.file_id
      from ad_files f
      where f.app_short_name = t.app_short_name
      and   f.subdir = t.subdir
      and   f.filename = t.filename),
    t.junk = null
    where nvl(t.active_flag,'N') = 'Y';

  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
-- add new entries in ad_files
--
  ad_file_util.error_buf := 'load_file_info('||
                            'insert into ad_files '||
                            '(file_id, app_short_name, subdir, filename, '||
                            'creation_date, created_by, last_update_date, '||
                            'last_updated_by) select ad_files_s.nextval, '||
                            'temp.asn, temp.dir, temp.fname, temp.edate, 5, '||
                            'temp.edate, 5  '||
                            'from (select distinct t.app_short_name asn, '||
                            't.subdir dir, t.filename fname, '||
                            't.effective_date edate from '||
                            'ad_check_file_temp t where t.file_id is null '||
                            ' and   nvl(t.active_flag,''N'') = ''Y'') temp;):(';

  begin
    insert into ad_files
     (file_id, app_short_name, subdir, filename,
      creation_date, created_by, last_update_date, last_updated_by)
    select ad_files_s.nextval,
      temp.asn, temp.dir, temp.fname,
      temp.edate, 5, temp.edate, 5
    from
     (select distinct
      t.app_short_name asn,
      t.subdir dir,
      t.filename fname,
      t.effective_date edate
      from ad_check_file_temp t
      where t.file_id is null
      and   nvl(t.active_flag,'N') = 'Y') temp;
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;

--
-- add file_id for new entries
--
   ad_file_util.error_buf := 'load_file_info('||
                             'update ad_check_file_temp t set t.file_id = '||
                             '(select f.file_id from ad_files f '||
                             'where f.app_short_name = t.app_short_name '||
                             'and   f.subdir = t.subdir '||
                             'and f.filename = t.filename) '||
                             'where t.file_id is null '||
                             'and nvl(t.active_flag,''N'') = ''Y'';):(';

   begin
     update ad_check_file_temp t
     set t.file_id =
      (select /*+ INDEX(F AD_FILES_U2) */ f.file_id
       from ad_files f
       where f.app_short_name = t.app_short_name
       and   f.subdir = t.subdir
       and   f.filename = t.filename)
     where t.file_id is null
     and   nvl(t.active_flag,'N') = 'Y';
   exception
     when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
   end;

--
-- rkagrawa: Fixed bug3354978
-- Process the dest_file_id entries in a separate chunk, on lines similar
-- to file_id entries (i.e., first update, then insert and finally update)
--

--
-- get dest_file_id from ad_files
--

  ad_file_util.error_buf := 'load_file_info('||
                            ' update ad_check_file_temp t '||
                            'set t.dest_file_id = (select f.file_id '||
                            'from ad_files f '||
                            'where f.app_short_name = t.dest_apps_short_name '||
                            'and   f.subdir = t.dest_subdir '||
                            'and   f.filename = t.dest_filename) '||
                            'where nvl(t.active_flag,''N'') = ''Y'';):(';
  begin
    update ad_check_file_temp t
    set t.dest_file_id =
     (select /*+ INDEX(F AD_FILES_U2) */ f.file_id
      from ad_files f
      where f.app_short_name = t.dest_apps_short_name
      and   f.subdir = t.dest_subdir
      and   f.filename = t.dest_filename)
    where nvl(t.active_flag,'N') = 'Y';
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;

--
-- add new entries in ad_files
--

  ad_file_util.error_buf := 'load_file_info('||
                            'insert into ad_files '||
                            '(file_id, app_short_name, subdir, filename, '||
                            'creation_date, created_by, last_update_date, '||
                            'last_updated_by) select ad_files_s.nextval, '||
                            'temp.asn, temp.dir, temp.fname, temp.edate, 5, '||
                            'temp.edate, 5  '||
                            'from (select distinct t.dest_apps_short_name asn, '||
                            't.dest_subdir dir, t.dest_filename fname, '||
                            't.effective_date edate from '||
                            'ad_check_file_temp t where t.dest_file_id is null '||
                            ' and t.dest_filename is not null '||
                            ' and   nvl(t.active_flag,''N'') = ''Y'') temp;):(';

  begin
    insert into ad_files
     (file_id, app_short_name, subdir, filename,
      creation_date, created_by, last_update_date, last_updated_by)
    select ad_files_s.nextval,
      temp.asn, temp.dir, temp.fname,
      temp.edate, 5, temp.edate, 5
    from
     (select distinct
      t.dest_apps_short_name asn,
      t.dest_subdir dir,
      t.dest_filename fname,
      t.effective_date edate
      from ad_check_file_temp t
      where t.dest_file_id is null
      and t.dest_filename is not null
      and t.dest_filename <> 'none'
      and nvl(t.active_flag,'N') = 'Y') temp;
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;

--
-- add dest_file_id for new entries
--

   ad_file_util.error_buf := 'load_file_info('||
                          'update ad_check_file_temp t set t.dest_file_id ='||
                             '(select f.file_id from ad_files f '||
                          'where f.app_short_name = t.dest_apps_short_name'||
                             'and   f.subdir = t.dest_subdir '||
                             'and f.filename = t.dest_filename) '||
                             'where t.dest_file_id is null '||
                             'and t.dest_filename is not null '||
                             'and nvl(t.active_flag,''N'') = ''Y'';):(';

   begin
     update ad_check_file_temp t
     set t.dest_file_id =
      (select /*+ INDEX(F AD_FILES_U2) */ f.file_id
       from ad_files f
       where f.app_short_name = t.dest_apps_short_name
       and   f.subdir = t.dest_subdir
       and   f.filename = t.dest_filename)
     where t.dest_file_id is null
     and t.dest_filename is not null
     and t.dest_filename <> 'none'
     and   nvl(t.active_flag,'N') = 'Y';
   exception
     when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
   end;

--
-- done processing ad_files
--

end load_file_info;

--
-- Procedure
--   load_file_version_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to ad_files and
--   ad_file_versions.
--
--   Only creates rows that don't already exist.
--
--   Processes all rows in ad_check_file_temp with active_flag='Y'.
--
--   To handle batch sizes:
--
--   1) - fill up whole table with null active_flag
--      - In a loop:
--        - update a batch to have active_flag='Y'
--        - process the batch
--        - delete the batch
--      - using 'where rownum < batch+1' is handy here
--
--   2) perform (truncate, load, process) cycles in an outer loop where
--      only <batch size> rows are loaded and processed at a time.
--
--   Calls load_file_info
--
--   Updates the file_version_id column of ad_check_file_temp so that all
--   rows point to the file_version_id of the file version referenced
--   in the row.
--
-- Arguments
--   none
--
procedure load_file_version_info
is
begin
--
-- process ad_files
--
   begin
     ad_file_util.load_file_info;
   exception
     when others then
      ad_file_util.error_buf := 'load_file_version_info('||
                                ad_file_util.error_buf||
                                ')';
      raise;
   end;
--
-- process ad_file_versons
--

--
-- get file_version_id from ad_file_versions
--
   ad_file_util.error_buf := 'load_file_version_info('||
                             'update ad_check_file_temp t '||
                             'set t.file_version_id = '||
                             '(select fv.file_version_id '||
                             'from ad_file_versions fv '||
                             'where fv.file_id = t.file_id '||
                             'and fv.version = t.manifest_vers '||
                             'and fv.translation_level = '||
                             't.translation_level) '||
                             'where nvl(t.active_flag,''N'') = ''Y'' '||
                             'and lower(t.manifest_vers)<>''none'';):(';
   begin
     update ad_check_file_temp t
     set t.file_version_id =
      (select /*+ INDEX(FV AD_FILE_VERSIONS_U2) */ fv.file_version_id
       from ad_file_versions fv
       where fv.file_id = t.file_id
       and   fv.version = t.manifest_vers
       and   fv.translation_level = t.translation_level)
     where nvl(t.active_flag,'N') = 'Y'
     and   lower(t.manifest_vers)<>'none';
   exception
     when others then
       ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
       raise;
   end;

--
-- add new entries to ad_file_versions
--
   ad_file_util.error_buf := 'load_file_version_info('||
                             'insert into ad_file_versions '||
                             '(file_version_id, file_id, version, '||
                             'translation_level, '||
                             'version_segment1, version_segment2, '||
                             'version_segment3, version_segment4, '||
                             'version_segment5, version_segment6, '||
                             'version_segment7, version_segment8,  '||
                             'version_segment9, version_segment10, '||
                             'creation_date, created_by, last_update_date, '||
                             'last_updated_by) select '||
                             'ad_file_versions_s.nextval, '||
                             'temp.f_id, temp.vers, temp.trans_level, '||
                             'temp.vs1, temp.vs2, temp.vs3, temp.vs4, '||
                             'temp.vs5, temp.vs6, temp.vs7, temp.vs8, '||
                             'temp.vs9, temp.vs10, temp.edate, 5, '||
                             'temp.edate, 5 from (select distinct '||
                             't.file_id f_id, t.manifest_vers vers, '||
                             't.translation_level trans_level,....);):(';

   begin
     insert into ad_file_versions
      (file_version_id, file_id, version, translation_level,
       version_segment1, version_segment2, version_segment3,
       version_segment4, version_segment5, version_segment6,
       version_segment7, version_segment8, version_segment9,
       version_segment10,
       creation_date, created_by, last_update_date, last_updated_by)
     select ad_file_versions_s.nextval,
       temp.f_id, temp.vers, temp.trans_level,
       temp.vs1, temp.vs2, temp.vs3, temp.vs4, temp.vs5,
       temp.vs6, temp.vs7, temp.vs8, temp.vs9, temp.vs10,
       temp.edate, 5, temp.edate, 5
     from
      (select distinct
       t.file_id f_id,
       t.manifest_vers vers,
       t.translation_level trans_level,
       decode(  instr(t.manifest_vers||'.','.',1,1), 0, 0,
         to_number(substr(t.manifest_vers||'.',
           1,
           (    instr(t.manifest_vers||'.','.',1,1)-1)))) vs1,
       decode(  instr(t.manifest_vers||'.','.',1,2), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,1)+1),
           (   (instr(t.manifest_vers||'.','.',1,2))
             - (instr(t.manifest_vers||'.','.',1,1)+1)) ))) vs2,
       decode(  instr(t.manifest_vers||'.','.',1,3), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,2)+1),
           (   (instr(t.manifest_vers||'.','.',1,3))
             - (instr(t.manifest_vers||'.','.',1,2)+1)) ))) vs3,
       decode(  instr(t.manifest_vers||'.','.',1,4), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,3)+1),
           (   (instr(t.manifest_vers||'.','.',1,4))
             - (instr(t.manifest_vers||'.','.',1,3)+1)) ))) vs4,
       decode(  instr(t.manifest_vers||'.','.',1,5), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,4)+1),
           (   (instr(t.manifest_vers||'.','.',1,5))
             - (instr(t.manifest_vers||'.','.',1,4)+1)) ))) vs5,
       decode(  instr(t.manifest_vers||'.','.',1,6), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,5)+1),
           (   (instr(t.manifest_vers||'.','.',1,6))
             - (instr(t.manifest_vers||'.','.',1,5)+1)) ))) vs6,
       decode(  instr(t.manifest_vers||'.','.',1,7), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,6)+1),
           (   (instr(t.manifest_vers||'.','.',1,7))
             - (instr(t.manifest_vers||'.','.',1,6)+1)) ))) vs7,
       decode(  instr(t.manifest_vers||'.','.',1,8), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,7)+1),
           (   (instr(t.manifest_vers||'.','.',1,8))
             - (instr(t.manifest_vers||'.','.',1,7)+1)) ))) vs8,
       decode(  instr(t.manifest_vers||'.','.',1,9), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,8)+1),
           (   (instr(t.manifest_vers||'.','.',1,9))
             - (instr(t.manifest_vers||'.','.',1,8)+1)) ))) vs9,
       decode(  instr(t.manifest_vers||'.','.',1,10), 0, 0,
         to_number(substr(t.manifest_vers||'.',
               (instr(t.manifest_vers||'.','.',1,9)+1),
           (   (instr(t.manifest_vers||'.','.',1,10))
             - (instr(t.manifest_vers||'.','.',1,9)+1)) ))) vs10,
       t.effective_date edate
     from ad_check_file_temp t
     where t.file_version_id is null
     and   lower(t.manifest_vers) <> 'none'
     and   nvl(t.active_flag,'N') = 'Y'
     ) temp;
   exception
     when others then
       ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
       raise;
   end;


--
-- get file_version_id for new entries
--
   ad_file_util.error_buf :='load_file_version_info('||
                            'update ad_check_file_temp t '||
                            'set t.file_version_id = '||
                            '(select fv.file_version_id '||
                            'from ad_file_versions fv '||
                            'where fv.file_id = t.file_id '||
                            'and fv.version = t.manifest_vers '||
                            'and fv.translation_level = t.translation_level)'||
                            'where t.file_version_id is null '||
                            'and nvl(t.active_flag,''N'') = ''Y'' '||
                            'and lower(t.manifest_vers)<>''none'';):(';


   begin
     update ad_check_file_temp t
     set t.file_version_id =
      (select /*+ INDEX(FV AD_FILE_VERSIONS_U2) */ fv.file_version_id
       from ad_file_versions fv
       where fv.file_id = t.file_id
       and   fv.version = t.manifest_vers
       and   fv.translation_level = t.translation_level)
     where t.file_version_id is null
     and   nvl(t.active_flag,'N') = 'Y'
     and   lower(t.manifest_vers)<>'none';
   exception
     when others then
       ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
       raise;
   end;

--
-- done processing ad_file_versons
--

end load_file_version_info;

--
-- Procedure
--   load_checkfile_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to ad_files,
--   ad_file_versions, and ad_check_files.
--
--   Only creates rows in ad_files and ad_file_versions that don't
--   already exist. In ad_check_files, it creates rows that don't already
--   exist and also updates existing rows if the version to load is higher
--   than the current version in ad_check_files.
--
--   Processes all rows in ad_check_file_temp with active_flag='Y'.
--
--   To handle batch sizes:
--
--   1) - fill up whole table with null active_flag
--      - In a loop:
--        - update a batch to have active_flag='Y'
--        - process the batch
--        - delete the batch
--      - using 'where rownum < batch+1' is handy here
--
--   2) perform (truncate, load, process) cycles in an outer loop where
--      only <batch size> rows are loaded and processed at a time.
--
--   Calls load_file_version_info
--
--   Updates the check_file_id column of ad_check_file_temp so that any
--   rows that were already in ad_check_files point to the check_file_id
--   of the (file, distinguisher) referenced in the row.  Rows in
--   ad_check_file_temp that did not already have corresponding rows in
--   ad_check_files still have null values for check_file_id
--   (assuming they started out as null)
--
-- Arguments
--   none
--
procedure load_checkfile_info(p_ebr_flow boolean default false)
is
begin
--
-- process ad_files and ad_file_versions
--
   ad_file_util.error_buf := 'load_checkfile_info(';
   begin
     ad_file_util.load_file_version_info;
   exception
     when others then
       ad_file_util.error_buf := 'load_checkfile_info('||
                                 ad_file_util.error_buf||sqlerrm||')';
       raise;
   end;
--
-- process ad_check_files
--

--
-- get check_file_id and manifest_vers_higher
--
   ad_file_util.error_buf := 'load_checkfile_info('||
                             'update ad_check_file_temp t '||
                             'set t.check_file_id = '||
                             '(select cf.check_file_id '||
                             'from ad_check_files cf '||
                             'where cf.file_id = t.file_id '||
                             'and nvl(cf.distinguisher,''*null*'') ='||
                             ' nvl(t.distinguisher,''*null*'')), '||
                             't.manifest_vers_higher =.....);):(';

   begin
     update ad_check_file_temp t
     set t.check_file_id =
      (select /*+ INDEX(CF AD_CHECK_FILES_U2) */ cf.check_file_id
       from ad_check_files cf
       where cf.file_id = t.file_id
       and   nvl(cf.distinguisher,'*null*') = nvl(t.distinguisher,'*null*')),
     t.manifest_vers_higher =
      (select /*+ ORDERED INDEX(FV1 AD_FILE_VERSIONS_U1)
                  INDEX(CF AD_CHECK_FILES_U2) INDEX(FV2 AD_FILE_VERSIONS_U1)
                  USE_NL(FV1 CF FV2) */
              decode(
         sign(nvl(fv1.version_segment1,0) - nvl(fv2.version_segment1,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment2,0) - nvl(fv2.version_segment2,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment3,0) - nvl(fv2.version_segment3,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment4,0) - nvl(fv2.version_segment4,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment5,0) - nvl(fv2.version_segment5,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment6,0) - nvl(fv2.version_segment6,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment7,0) - nvl(fv2.version_segment7,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment8,0) - nvl(fv2.version_segment8,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment9,0) - nvl(fv2.version_segment9,0)),
           -1, null, 1, 'Y', decode(
         sign(nvl(fv1.version_segment10,0) - nvl(fv2.version_segment10,0)),
           -1, null, 1, 'Y',  decode(
         sign(fv1.translation_level - fv2.translation_level),
           -1, null, 1, 'Y', null)))))))))))
       from ad_file_versions fv1, ad_check_files cf, ad_file_versions fv2
       where t.file_version_id = fv1.file_version_id
       and   t.file_id = cf.file_id
       and   nvl(t.distinguisher,'*null*') = nvl(cf.distinguisher,'*null*')
       and   cf.file_version_id = fv2.file_version_id)
      where nvl(t.active_flag,'N') = 'Y';
   exception
     when others then
       ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
       raise;
   end;
--
-- add new entries into ad_check_files
--
      ad_file_util.error_buf := 'load_checkfile_info('||
                                'insert into ad_check_files '||
                                '(check_file_id, file_id, distinguisher, '||
                                'file_version_id, creation_date) '||
                                'select ad_check_files_s.nextval, '||
                                'temp.f_id, temp.dist, temp.fv_id, '||
                                'temp.edate from (select distinct '||
                                't.file_id f_id, t.distinguisher dist, '||
                                't.file_version_id fv_id, '||
                                't.effective_date edate from '||
                                'ad_check_file_temp t where t.check_file_id '||
                                'is null and nvl(t.active_flag,''N'') = '||
                                '''Y'') temp;):(';

   begin
     insert into ad_check_files
      (check_file_id, file_id, distinguisher,
       file_version_id, creation_date)
     select ad_check_files_s.nextval,
       temp.f_id, temp.dist, temp.fv_id, temp.edate
     from
      (select distinct
       t.file_id f_id,
       t.distinguisher dist,
       t.file_version_id fv_id,
       t.effective_date edate
     from ad_check_file_temp t
     where t.check_file_id is null
     and   nvl(t.active_flag,'N') = 'Y') temp;

   exception
     when others then
       ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
       raise;
   end;

   if (p_ebr_flow = true)
   then

-- Insert new records. Insert all the records with patch_run_id -1
-- Later while updating patch history update patch_run_id

   ad_file_util.error_buf := 'load_checkfile_info('||
    'insert into ad_check_file_history ' ||
    '(CHECK_FILE_ID, FILE_VERSION_ID, PATCH_RUN_ID, CREATION_DATE) ' ||
    'select distinct acf.check_file_id, acf.file_version_id, -1, sysdate ' ||
    'from ad_check_files acf, ad_check_file_temp acft ' ||
    ' where acft.check_file_id is null ' ||
    ' and nvl(acft.active_flag,''N'') = ''Y'' ' ||
    ' and acf.file_id=acft.file_id ' ||
    ' and nvl(acf.distinguisher, ''x'')=nvl(acft.distinguisher, ''x''))';

   begin
    insert into ad_check_file_history
     (CHECK_FILE_ID, FILE_VERSION_ID, PATCH_RUN_ID, CREATION_DATE)
    select distinct acf.check_file_id, acf.file_version_id, -1, sysdate
     from ad_check_files acf, ad_check_file_temp acft
     where acft.check_file_id is null
     and nvl(acft.active_flag,'N') = 'Y'
     and acf.file_id=acft.file_id
     and nvl(acf.distinguisher, 'x')=nvl(acft.distinguisher, 'x');

   exception
     when others then
       ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
       raise;
   end;
   end if;
--
--
-- delete from ad_check_files where versions lower than manifest
--
  ad_file_util.error_buf := 'load_checkfile_info('||
                            'delete from ad_check_files kf '||
                            'where cf.check_file_id in '||
                            '(select t.check_file_id '||
                            'from ad_check_file_temp t '||
                            'where t.manifest_vers_higher = ''Y'' '||
                            'and nvl(t.active_flag,''N'') = ''Y'');):(';

  begin
    delete /*+ INDEX(CF AD_CHECK_FILES_U1) */ from ad_check_files cf
    where cf.check_file_id in
     (select t.check_file_id
      from ad_check_file_temp t
      where t.manifest_vers_higher = 'Y'
      and   nvl(t.active_flag,'N') = 'Y');
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
-- insert into ad_check_files where versions lower than manifest
--
  ad_file_util.error_buf := 'load_checkfile_info('||
                            ' insert into ad_check_files '||
                            '(check_file_id, file_id, distinguisher, '||
                            'file_version_id, creation_date) '||
                            'select temp.cf_id, '||
                            'temp.f_id, temp.dist, temp.fv_id, temp.edate '||
                            'from (select distinct '||
                            't.check_file_id cf_id, '||
                            't.file_id f_id, '||
                            't.distinguisher dist, '||
                            't.file_version_id fv_id, '||
                            't.effective_date edate '||
                            'from ad_check_file_temp t '||
                            'where t.manifest_vers_higher = ''Y'' '||
                            'and nvl(t.active_flag,''N'') = ''Y'') temp;):(';

  begin
    insert into ad_check_files
     (check_file_id, file_id, distinguisher,
      file_version_id, creation_date)
    select temp.cf_id,
      temp.f_id, temp.dist, temp.fv_id, temp.edate
    from
     (select distinct
      t.check_file_id cf_id,
      t.file_id f_id,
      t.distinguisher dist,
      t.file_version_id fv_id,
      t.effective_date edate
    from ad_check_file_temp t
    where t.manifest_vers_higher = 'Y'
    and   nvl(t.active_flag,'N') = 'Y') temp;

  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;

  if (p_ebr_flow = true)
  then
-- Insert new records. Insert all the records with patch_run_id -1
-- Later while updating patch history update patch_run_id

  ad_file_util.error_buf := 'load_checkfile_info('||
    'insert into ad_check_file_history ' ||
    ' (CHECK_FILE_ID, FILE_VERSION_ID, PATCH_RUN_ID, CREATION_DATE) ' ||
    'select distinct acf.check_file_id, acf.file_version_id, -1, sysdate ' ||
    ' from ad_check_files acf, ad_check_file_temp acft ' ||
    ' where acft.manifest_vers_higher = ''Y'' ' ||
    ' and nvl(acft.active_flag,''N'') = ''Y'' ' ||
    ' and acf.file_id=acft.file_id ' ||
    ' and acf.distinguisher=acft.distinguisher)';

  begin
    insert into ad_check_file_history
     (CHECK_FILE_ID, FILE_VERSION_ID, PATCH_RUN_ID, CREATION_DATE)
    select distinct acf.check_file_id, acf.file_version_id, -1, sysdate
     from ad_check_files acf, ad_check_file_temp acft
     where acft.manifest_vers_higher = 'Y'
     and nvl(acft.active_flag,'N') = 'Y'
     and acf.file_id=acft.file_id
     and nvl(acf.distinguisher, 'x')=nvl(acft.distinguisher, 'x');

  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
  end if;
--
-- done processing ad_check_files
--

end load_checkfile_info;

--
-- Procedure
--   update_timestamp
--
-- Purpose
--   Inserts/updates a row in AD_TIMESTAMPS corresponding to the
--   specified row type and attribute.
--
-- Arguments
--   in_type         The row type
--   in_attribute    The row attribute
--   in_timestamp    A timestamp.  Defaults to sysdate.
--
-- Notes
--   This is essentially the same as ad_invoker.update_timestamp
--   Added it here to make it easier to call from APPS.
--
procedure update_timestamp
           (in_type      in varchar2,
            in_attribute in varchar2,
            in_timestamp in date)
--
-- Updates/Inserts the row in AD_TIMESTAMPS for the specified
--  type and attribute
--
is
begin
--
-- First try to update
--
  ad_file_util.error_buf := 'update_timestamp(update ad_timestamps '||
                            'set timestamp = '||in_timestamp||
                            'where type = '||in_type||
                            'and attribute = '||in_attribute||'):(';
  begin
    update ad_timestamps
    set timestamp = in_timestamp
    where type = in_type
    and attribute = in_attribute;
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;

  if SQL%ROWCOUNT = 1 then
    return;
  end if;
--
-- Insert if no rows updated
--
   ad_file_util.error_buf := 'update_timestamp('||
                             'insert into ad_timestamps'||
                             '(type, attribute, timestamp)'||
                             'values ('||in_type||', '||in_attribute||
                             ', '||in_timestamp||'):(';

  begin
    insert into ad_timestamps
    (type, attribute, timestamp)
    values (in_type, in_attribute, in_timestamp);
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;

end update_timestamp;
--
--
procedure update_timestamp
           (in_type      in varchar2,
            in_attribute in varchar2)
is
begin
 update_timestamp
           (in_type      => in_type,
            in_attribute => in_attribute,
            in_timestamp => sysdate);
end;

--
--
--
-- Procedure
--   load_patch_onsite_vers_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to ad_files and
--   ad_file_versions.
--
--   Only creates rows that don't already exist.
--
--   Processes all rows in ad_check_file_temp with active_flag='Y'.
--
--   To handle batch sizes:
--
--   1) - fill up whole table with null active_flag
--      - In a loop:
--        - update a batch to have active_flag='Y'
--        - process the batch
--        - delete the batch
--      - using 'where rownum < batch+1' is handy here
--
--   2) perform (truncate, load, process) cycles in an outer loop where
--      only <batch size> rows are loaded and processed at a time.
--
--   Calls load_file_info
--
--   Updates the file_version_id and file_version_id_2 columns of
--   ad_check_file_temp so that all rows point to the file_version_id
--   of the file versions referenced in the row.
--
--   Doesn't try to update ad_file_versions for rows in ad_check_file_temp
--   with manifest_vers='NA' or manifest_vers_2='NA'.  These values mean
--   "no version for this file", so no corresponding record should be
--   created in ad_file_versions.
--
-- Arguments
--   none
--
procedure load_patch_onsite_vers_info
is
begin
--
-- process ad_files
--

  ad_file_util.load_file_info;

--
-- process ad_file_versons
--
  ad_file_util.error_buf := 'load_patch_onsite_vers_info('||
                            'update ad_check_file_temp t '||
                            'set t.file_version_id = '||
                            '(select fv.file_version_id '||
                            'from ad_file_versions fv '||
                            'where fv.file_id = t.file_id '||
                            'and fv.version = t.manifest_vers '||
                            'and fv.translation_level = t.translation_level) '||
                            'where nvl(t.active_flag,''N'') = ''Y'' '||
                            'and nvl(t.manifest_vers,''NA'')<>''NA''):(';

  begin
    update ad_check_file_temp t
    set t.file_version_id =
     (select /*+ INDEX(FV AD_FILE_VERSIONS_U2) */ fv.file_version_id
      from ad_file_versions fv
      where fv.file_id = t.file_id
      and   fv.version = t.manifest_vers
      and   fv.translation_level = t.translation_level)
    where nvl(t.active_flag,'N') = 'Y'
          and nvl(t.manifest_vers,'NA')<>'NA';
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
-- add new entries to ad_file_versions
--
  ad_file_util.error_buf := 'load_patch_onsite_vers_info('||
                            'insert into ad_file_versions '||
                            '(file_version_id, file_id, version, '||
                            'translation_level, version_segment1,'||
                            'version_segment2, version_segment3, '||
                            'version_segment4, version_segment5, '||
                            'version_segment6, version_segment7, '||
                            'version_segment8, version_segment9, '||
                            'version_segment10, creation_date, created_by, '||
                            'last_update_date, last_updated_by) '||
                            '.....):(';
  begin
    insert into ad_file_versions
     (file_version_id, file_id, version, translation_level,
      version_segment1, version_segment2, version_segment3,
      version_segment4, version_segment5, version_segment6,
      version_segment7, version_segment8, version_segment9,
      version_segment10,
      creation_date, created_by, last_update_date, last_updated_by)
    select ad_file_versions_s.nextval,
      temp.f_id, temp.vers, temp.trans_level,
      temp.vs1, temp.vs2, temp.vs3, temp.vs4, temp.vs5,
      temp.vs6, temp.vs7, temp.vs8, temp.vs9, temp.vs10,
      temp.edate, 5, temp.edate, 5
    from
     (select distinct
      t.file_id f_id,
      t.manifest_vers vers,
      t.translation_level trans_level,
      decode(  instr(t.manifest_vers||'.','.',1,1), 0, null,
        to_number(substr(t.manifest_vers||'.',
          1,
          (    instr(t.manifest_vers||'.','.',1,1)-1)))) vs1,
      decode(  instr(t.manifest_vers||'.','.',1,2), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,1)+1),
          (   (instr(t.manifest_vers||'.','.',1,2))
            - (instr(t.manifest_vers||'.','.',1,1)+1)) ))) vs2,
      decode(  instr(t.manifest_vers||'.','.',1,3), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,2)+1),
          (   (instr(t.manifest_vers||'.','.',1,3))
            - (instr(t.manifest_vers||'.','.',1,2)+1)) ))) vs3,
      decode(  instr(t.manifest_vers||'.','.',1,4), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,3)+1),
          (   (instr(t.manifest_vers||'.','.',1,4))
            - (instr(t.manifest_vers||'.','.',1,3)+1)) ))) vs4,
      decode(  instr(t.manifest_vers||'.','.',1,5), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,4)+1),
          (   (instr(t.manifest_vers||'.','.',1,5))
            - (instr(t.manifest_vers||'.','.',1,4)+1)) ))) vs5,
      decode(  instr(t.manifest_vers||'.','.',1,6), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,5)+1),
          (   (instr(t.manifest_vers||'.','.',1,6))
            - (instr(t.manifest_vers||'.','.',1,5)+1)) ))) vs6,
      decode(  instr(t.manifest_vers||'.','.',1,7), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,6)+1),
          (   (instr(t.manifest_vers||'.','.',1,7))
            - (instr(t.manifest_vers||'.','.',1,6)+1)) ))) vs7,
      decode(  instr(t.manifest_vers||'.','.',1,8), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,7)+1),
          (   (instr(t.manifest_vers||'.','.',1,8))
            - (instr(t.manifest_vers||'.','.',1,7)+1)) ))) vs8,
      decode(  instr(t.manifest_vers||'.','.',1,9), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,8)+1),
          (   (instr(t.manifest_vers||'.','.',1,9))
            - (instr(t.manifest_vers||'.','.',1,8)+1)) ))) vs9,
      decode(  instr(t.manifest_vers||'.','.',1,10), 0, 0,
        to_number(substr(t.manifest_vers||'.',
              (instr(t.manifest_vers||'.','.',1,9)+1),
          (   (instr(t.manifest_vers||'.','.',1,10))
            - (instr(t.manifest_vers||'.','.',1,9)+1)) ))) vs10,
      t.effective_date edate
    from ad_check_file_temp t
    where t.file_version_id is null
    and   nvl(t.active_flag,'N') = 'Y'
    and   nvl(t.manifest_vers,'NA')<>'NA') temp;
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
--
  ad_file_util.error_buf := 'load_patch_onsite_vers_info('||
                            'update ad_check_file_temp t '||
                            'set t.file_version_id = '||
                            '(select fv.file_version_id '||
                            'from ad_file_versions fv '||
                            'where fv.file_id = t.file_id '||
                            'and fv.version = t.manifest_vers '||
                            'and fv.translation_level = t.translation_level) '||
                            'where nvl(t.active_flag,''N'') = ''Y'' '||
                            'and nvl(t.manifest_vers,''NA'')<>''NA''):(';
--
--
  begin
    update ad_check_file_temp t
    set t.file_version_id =
     (select /*+ INDEX(FV AD_FILE_VERSIONS_U2) */ fv.file_version_id
      from ad_file_versions fv
      where fv.file_id = t.file_id
      and   fv.version = t.manifest_vers
      and   fv.translation_level = t.translation_level)
    where nvl(t.active_flag,'N') = 'Y'
          and nvl(t.manifest_vers,'NA')<>'NA';
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
-- get file_version_id_2 from ad_file_versions
--
   ad_file_util.error_buf := 'load_patch_onsite_vers_info('||
                             'update ad_check_file_temp t '||
                             'set t.file_version_id_2 = '||
                             '(select fv.file_version_id '||
                             'from ad_file_versions fv '||
                             'where fv.file_id = t.file_id '||
                             'and fv.version = t.manifest_vers_2 '||
                             'nvl(t.manifest_vers_2,''NA'')<>''NA''):(';
--
--
   begin
     update ad_check_file_temp t
     set t.file_version_id_2 =
      (select /*+ INDEX(FV AD_FILE_VERSIONS_U2) */ fv.file_version_id
       from ad_file_versions fv
       where fv.file_id = t.file_id
       and   fv.version = t.manifest_vers_2
       and   fv.translation_level = t.translation_level)
     where nvl(t.active_flag,'N') = 'Y' AND
           nvl(t.manifest_vers_2,'NA')<>'NA';
   exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
   end;

--
-- add new entries to ad_file_versions
--
  ad_file_util.error_buf := 'load_patch_onsite_vers_info('||
                            'insert into ad_file_versions '||
                            '(file_version_id, file_id, version, '||
                            'translation_level, version_segment1,'||
                            'version_segment2, version_segment3, '||
                            'version_segment4, version_segment5, '||
                            'version_segment6, version_segment7, '||
                            'version_segment8, version_segment9, '||
                            'version_segment10, creation_date, created_by, '||
                            'last_update_date, last_updated_by) '||
                            '.....):(';
--
  begin
    insert into ad_file_versions
     (file_version_id, file_id, version, translation_level,
      version_segment1, version_segment2, version_segment3,
      version_segment4, version_segment5, version_segment6,
      version_segment7, version_segment8, version_segment9,
      version_segment10,
      creation_date, created_by, last_update_date, last_updated_by)
    select ad_file_versions_s.nextval,
      temp.f_id, temp.vers, temp.trans_level,
      temp.vs1, temp.vs2, temp.vs3, temp.vs4, temp.vs5,
      temp.vs6, temp.vs7, temp.vs8, temp.vs9, temp.vs10,
      temp.edate, 5, temp.edate, 5
    from
     (select distinct
      t.file_id f_id,
      t.manifest_vers_2 vers,
      t.translation_level trans_level,
      decode(  instr(t.manifest_vers_2||'.','.',1,1), 0, null,
        to_number(substr(t.manifest_vers_2||'.',
          1,
          (    instr(t.manifest_vers_2||'.','.',1,1)-1)))) vs1,
      decode(  instr(t.manifest_vers_2||'.','.',1,2), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,1)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,2))
            - (instr(t.manifest_vers_2||'.','.',1,1)+1)) ))) vs2,
      decode(  instr(t.manifest_vers_2||'.','.',1,3), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,2)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,3))
            - (instr(t.manifest_vers_2||'.','.',1,2)+1)) ))) vs3,
      decode(  instr(t.manifest_vers_2||'.','.',1,4), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,3)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,4))
            - (instr(t.manifest_vers_2||'.','.',1,3)+1)) ))) vs4,
      decode(  instr(t.manifest_vers_2||'.','.',1,5), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,4)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,5))
            - (instr(t.manifest_vers_2||'.','.',1,4)+1)) ))) vs5,
      decode(  instr(t.manifest_vers_2||'.','.',1,6), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,5)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,6))
            - (instr(t.manifest_vers_2||'.','.',1,5)+1)) ))) vs6,
      decode(  instr(t.manifest_vers_2||'.','.',1,7), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,6)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,7))
            - (instr(t.manifest_vers_2||'.','.',1,6)+1)) ))) vs7,
      decode(  instr(t.manifest_vers_2||'.','.',1,8), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,7)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,8))
            - (instr(t.manifest_vers_2||'.','.',1,7)+1)) ))) vs8,
      decode(  instr(t.manifest_vers_2||'.','.',1,9), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,8)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,9))
            - (instr(t.manifest_vers_2||'.','.',1,8)+1)) ))) vs9,
      decode(  instr(t.manifest_vers_2||'.','.',1,10), 0, 0,
        to_number(substr(t.manifest_vers_2||'.',
              (instr(t.manifest_vers_2||'.','.',1,9)+1),
          (   (instr(t.manifest_vers_2||'.','.',1,10))
            - (instr(t.manifest_vers_2||'.','.',1,9)+1)) ))) vs10,
      t.effective_date edate
    from ad_check_file_temp t
    where t.file_version_id_2 is null
    and   nvl(t.active_flag,'N') = 'Y'
    and   nvl(t.manifest_vers_2,'NA')<>'NA') temp;
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
-- get file_version_id_2 from ad_file_versions
--
   ad_file_util.error_buf := 'load_patch_onsite_vers_info('||
                             'update ad_check_file_temp t '||
                             'set t.file_version_id_2 = '||
                             '(select fv.file_version_id '||
                             'from ad_file_versions fv '||
                             'where fv.file_id = t.file_id '||
                             'and fv.version = t.manifest_vers_2 '||
                             'nvl(t.manifest_vers_2,''NA'')<>''NA''):(';
   begin
     update ad_check_file_temp t
     set t.file_version_id_2 =
      (select /*+ INDEX(FV AD_FILE_VERSIONS_U2) */ fv.file_version_id
       from ad_file_versions fv
       where fv.file_id = t.file_id
       and   fv.version = t.manifest_vers_2
       and   fv.translation_level = t.translation_level)
     where nvl(t.active_flag,'N') = 'Y' AND
           nvl(t.manifest_vers_2,'NA')<>'NA';
   exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
   end;
--
-- done processing ad_file_versions
--
end load_patch_onsite_vers_info;

--
--
--
-- Procedure
--   load_snapshot_file_info
--
-- Purpose
--  Create Snapshot data by
--  1.Calls  ad_file_versions  and loads the file versions
--    into the ad_check_file_temp table .
--  2.Updates rows in AD_SNAPSHOT_FILES from  ad_check_file_temp
--    which have the same file_id, snapshot_id and containing_file_id
--  3.Inserts those  rows from ad_check_file_temp  into AD_SNAPSHOT_FILES
--    which exists in ad_check_file_temp but are not in AD_SNAPSHOT_FILES.
--    for the  given snapshot_id
--  4.Delete those rows from AD_SNAPSHOT_FILES which exists
--    in AD_SNAPSHOT_FILES  but do not exist in ad_check_file_temp
--    for the  given snapshot_id
--
-- Arguments
-- is_upload pass TRUE if it is an upload otherwise FALSE
--
--
procedure load_snapshot_file_info
           (snp_id number,
            preserve_irep_flag number)
is
TYPE t_version_id  IS TABLE OF ad_check_file_temp.file_version_id%TYPE;
TYPE t_check_sum   IS TABLE OF ad_check_file_temp.check_sum%TYPE;
TYPE t_file_size   IS TABLE OF ad_check_file_temp.file_size%TYPE;
TYPE t_file_id     IS TABLE OF ad_check_file_temp.file_id%TYPE;
TYPE t_containing_file_id IS TABLE OF ad_check_file_temp.check_file_id%TYPE;
TYPE t_dest_file_id IS TABLE OF ad_check_file_temp.dest_file_id%TYPE;
TYPE t_file_type_flag IS TABLE OF ad_check_file_temp.file_type_flag%TYPE;
TYPE t_irep_gathered_flag IS TABLE OF ad_check_file_temp.manifest_vers_higher%TYPE;
TYPE t_effective_date IS TABLE OF ad_check_file_temp.effective_date%TYPE;

--
vers_id_list       t_version_id;
chk_sum_list       t_check_sum;
fl_size_list       t_file_size;
fl_id_list         t_file_id;
con_file_id_list   t_containing_file_id;
dest_file_id_list  t_dest_file_id;
file_type_flag_list t_file_type_flag;
irep_gathered_flag_list t_irep_gathered_flag;
effective_date_list t_effective_date;

--
--
--
cursor  c1 is
select
file_version_id,check_sum,file_size,
file_id,check_file_id,dest_file_id,
file_type_flag, manifest_vers_higher,
effective_date
from  ad_check_file_temp;
--
--
--
--
cur_rec c1%ROWTYPE;
rows   NATURAL := 2000;
--
--
--
begin
--
-- process ad_files and ad_file_versions
--
   begin
     ad_file_util.load_file_version_info;
   exception
     when others then
      ad_file_util.error_buf := 'load_snapshot_file_info('||snp_id||'):('||
                                ad_file_util.error_buf||sqlerrm||')';
      raise;
   end;
--
-- get contain_file_id from ad_files
--
-- The containing files are already inserted into ad_files
-- by the procedure load_file_version_info  so we are
-- guaranteed to get the file_id from ad_files.
--
-- done processing ad_files
--
--
   ad_file_util.error_buf := 'load_snapshot_file_info(cursor: '||
                             'select file_version_id,check_sum,file_size, '||
                             'file_id,check_file_id,dest_file_id, '||
                             'file_type_flag from '||
                             'ad_check_file_temp):(';

   begin
     OPEN c1;
   exception
     when others then
       ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
     raise;
   end;
--
--
  LOOP
--
--
--
    FETCH c1 BULK COLLECT INTO
    vers_id_list ,chk_sum_list ,fl_size_list ,
    fl_id_list ,con_file_id_list,
    dest_file_id_list, file_type_flag_list,
    irep_gathered_flag_list,
    effective_date_list
    LIMIT rows;
--
--
    if   fl_id_list.COUNT > 0 then
--
--
--
      FORALL j IN fl_id_list.FIRST.. fl_id_list.LAST
        update /*+ INDEX(SNAP AD_SNAPSHOT_FILES_U2) */
           ad_snapshot_files snap
        set
          snap.file_version_id  = vers_id_list(j),
          snap.file_size        = fl_size_list(j),
          snap.checksum         = chk_sum_list(j),
          snap.dest_file_id     = dest_file_id_list(j),
          snap.file_type_flag   = file_type_flag_list(j),
          snap.update_source_id = snp_id,
-- Intentionally storing 'U' so that these rows will be marked
-- so that we can know which rows were updated
          snap.update_type      ='U',
          snap.last_update_date = sysdate,
          snap.last_patched_date = decode(preserve_irep_flag,1,
                                          snap.last_patched_date,
                  decode ((effective_date_list(j) - snap.last_patched_date) -
                          abs(effective_date_list(j) - snap.last_patched_date),
                          0, effective_date_list(j), snap.last_patched_date)),
          snap.irep_gathered_flag = decode(preserve_irep_flag,1,
                                           snap.irep_gathered_flag,
                                           irep_gathered_flag_list(j))
        where
          snap.snapshot_id=snp_id   and
          snap.file_id    =fl_id_list(j)         and
          nvl(snap.containing_file_id,-1)=nvl(con_file_id_list(j),-1);
--
--
     end if;
--
--

    EXIT WHEN c1%NOTFOUND;
--
--
--
  END LOOP;
--
--
--
   begin
     close c1;
   exception
     when others then
     ad_file_util.error_buf := 'load_snapshot_file_info(Close cursor):('||
                               sqlerrm||')';
   end;
--
--
--
   ad_file_util.error_buf := 'load_snapshot_file_info('||
                             'INSERT INTO ad_snapshot_files '||
                             '(snapshot_file_id,snapshot_id,file_id, '||
                             'containing_file_id,file_size,checksum,'||
                             'file_version_id, update_source_id, '||
                             'update_type,creation_date,last_update_date,' ||
                             'last_updated_by,created_by,' ||
                             'appl_top_id, inconsistent_flag, '||
                             'dest_file_id, file_type_flag) '||
                             'select ad_snapshot_files_s.nextval,'||
                             'snp_id,t.file_id, t.check_file_id,'||
                             't.file_size,t.check_sum, t.file_version_id,'||
                             'snp_id,''U'',sysdate,sysdate, 5,5,' ||
                             't.appl_top_id, t.inconsistent_flag, '||
                             't.dest_file_id, t.file_type_flag '||
                             'from ad_check_file_temp t where not exists '||
                             '(select ''already present'' '||
                             'from ad_snapshot_files sf2 '||
                             'where sf2.snapshot_id = snp_id '||
                             'and sf2.file_id = t.file_id '||
                             'and nvl(sf2.containing_file_id,-1) = '||
                             'nvl(t.check_file_id,-1)):(';

  begin

    INSERT INTO ad_snapshot_files
      (snapshot_file_id,snapshot_id,file_id,
      containing_file_id,file_size,checksum,file_version_id,
      update_source_id, update_type,creation_date,last_update_date,
      last_updated_by,created_by, appl_top_id, inconsistent_flag,
      dest_file_id, file_type_flag, irep_gathered_flag,last_patched_date)
      select
      ad_snapshot_files_s.nextval,snp_id,t.file_id,
      t.check_file_id,t.file_size,t.check_sum,
      t.file_version_id,snp_id,'U',sysdate,sysdate,
      5,5, t.appl_top_id, t.inconsistent_flag,
      t.dest_file_id, t.file_type_flag,
      t.manifest_vers_higher, t.effective_date
      from ad_check_file_temp t
      where not exists
      (select /*+ INDEX(SF2 AD_SNAPSHOT_FILES_U2) */ 'already present'
      from ad_snapshot_files sf2
      where sf2.snapshot_id        = snp_id
      and   sf2.file_id            = t.file_id
      and   nvl(sf2.containing_file_id,-1) = nvl(t.check_file_id,-1)
      );
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;

  update ad_snapshots set last_update_date = sysdate
  where  snapshot_id = snp_id;

--
--
--
--
end load_snapshot_file_info;
--
--
--
-- Procedure
--   load_preseeded_bugfixes
--
-- Purpose
--   Gets the bug_id from AD_BUGS for the bugnumbers in
--   in ad_check_file_temp table .
--   Creates new rows in the AD_BUGS for the new bugnumbers
--   and gets the bug_id for those bugnumbers and stores them
--   ad_check_file_temp table .
--
--   Inserts those BUG_IDs into AD_SNAPSHOT_BUGFIXES
--
--
-- Arguments
-- None
procedure load_preseeded_bugfixes
is
begin
--
-- Get the bug_id from ad_bugs
--
-- Bug 5758908 - stangutu - 14 June, 2007
  ad_file_util.error_buf := 'load_preseeded_bugfixes('||
                            'SET t.file_id = (SELECT b.bug_id '||
                            'FROM ad_bugs b WHERE b.bug_number = t.filename '||
                            'AND b.aru_release_name = t.subdir '||
                            'AND b.trackable_entity_abbr=t.app_short_name '||
                            'AND b.language           = t.language  '||
                            'AND b.baseline_name = t.manifest_vers_2), '||
                            't.junk = NULL '||
                            'WHERE NVL(t.active_flag,''N'') = ''Y''):(';
  begin
-- Bug 5579901- stangutu - 9 Oct, 2006
    UPDATE ad_check_file_temp t
    SET t.file_id = (SELECT /*+ INDEX(B AD_BUGS_U2) */ b.bug_id
                     FROM   ad_bugs b
                     WHERE  b.bug_number         = t.filename
                     AND    b.aru_release_name   = t.subdir
-- bug 6317065 diverma Thu Aug  2 04:10:21 PDT 2007
                     AND    b.trackable_entity_abbr  = t.app_short_name
-- bug 5615204 diverma Tuesday, August 07, 2007
                     AND    b.language           = t.language
-- Bug 5596989 - stangutu - 17 Oct, 2006
-- Bug 5758908 - stangutu - 14 June, 2007
                     AND    b.baseline_name = t.manifest_vers_2),
-- If the above condition does not work, we need to include below line.
--                   AND    b.generic_patch = t.manifest_vers_higher),
        t.junk = NULL
    WHERE NVL(t.active_flag,'N') = 'Y';
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
-- add new entries in  ad_bugs
--
-- Bug 5758908 - stangutu - 14 Jun, 2007 */
  ad_file_util.error_buf := 'load_preseeded_bugfixes('||
                            'INSERT INTO ad_bugs '||
                            '(bug_id, bug_number,aru_release_name, '||
                            'creation_date, created_by, last_update_date, '||
                            'last_updated_by, baseline_name, generic_patch, '||
                            ' trackable_entity_abbr ) SELECT '||
                            'ad_bugs_s.nextval, temp.bugfix, temp.rel, '||
                            'temp.edate, 5, temp.edate, 5, '||
                            'temp.baseline_name, temp.generic_patch, '||
                            'temp.trackable_entity_abbr, language)' ||
                            'FROM (SELECT DISTINCT t.filename bugfix, '||
                            't.subdir rel, t.effective_date edate '||
                            't.manifest_vers_2  baseline_name, '||
                            't.manifest_vers_higher, generic_patch, '||
                            't.app_short_name trackable_entity_abbr, ' ||
                            't.language language '||
                            'FROM ad_check_file_temp t '||
                            'WHERE t.file_id is null '||
                            'AND NVL(t.active_flag,''N'') = ''Y'') temp):(';
  begin
    INSERT INTO ad_bugs
     (bug_id, bug_number,aru_release_name,
      creation_date, created_by, last_update_date, last_updated_by,
-- Bug 5758908 - stangutu - 14 June, 2007
      baseline_name, generic_patch, trackable_entity_abbr,
-- bug 5615204 diverma Tuesday, August 07, 2007
      language)
    SELECT
      ad_bugs_s.nextval, temp.bugfix, temp.rel,
      temp.edate, 5, temp.edate, 5,
-- Bug 5758908 - stangutu - 14 June, 2007
      temp.baseline_name, temp.generic_patch, temp.trackable_entity_abbr,
-- bug 5615204 diverma Tuesday, August 07, 2007
      temp.language
    FROM
     (SELECT DISTINCT
      t.filename              bugfix,
      t.subdir                rel   ,
      t.effective_date        edate,
-- Bug 5758908 - stangutu - 14 June, 2007
      t.manifest_vers_2       baseline_name,
      t.manifest_vers_higher  generic_patch,
      t.app_short_name trackable_entity_abbr,
-- bug 5615204 diverma Tuesday, August 07, 2007
      t.language language
      FROM  ad_check_file_temp t
      WHERE t.file_id is null
      AND   NVL(t.active_flag,'N') = 'Y') temp;
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
-- add bug_id for new entries
--
-- Bug 5758908 - stangutu - 14 June, 2007
  ad_file_util.error_buf := 'load_preseeded_bugfixes('||
                            'UPDATE ad_check_file_temp t '||
                            'SET t.file_id = (SELECT b.bug_id '||
                            'FROM ad_bugs b WHERE b.bug_number = t.filename '||
                            'AND b.aru_release_name = t.subdir, '||
                            'AND b.trackable_entity_abbr = t.app_short_name' ||
                            'AND b.language = t.language '||
                            'AND b.baseline_name = t.manifest_vers_2), '||
                            't.junk = NULL '||
                            'WHERE NVL(t.active_flag,''N'') = ''Y''):(';
  begin
-- Bug 5579901- stangutu - 9 Oct, 2006
    UPDATE ad_check_file_temp t
     SET t.file_id = (SELECT /*+ INDEX(B AD_BUGS_U2) */ b.bug_id
                      FROM   ad_bugs b
                      WHERE  b.bug_number         = t.filename
                      AND    b.aru_release_name   = t.subdir
-- bug 6317065 diverma Thu Aug  2 04:10:21 PDT 2007
                      AND    b.trackable_entity_abbr  = t.app_short_name
-- bug 5615204 diverma Tuesday, August 07, 2007
                      AND    b.language           = t.language
-- Bug 5596989 - stangutu -17Oct, 2006
-- Bug 5758908 - stangutu - 14 June, 2007
                      AND   b.baseline_name = t.manifest_vers_2),
-- If the above condition does not work, we need to include below line.
--                    AND   b.generic_patch = t.manifest_vers_higher),
         t.junk = NULL
     WHERE NVL(t.active_flag,'N') = 'Y';
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
--
-- store the pre-seed the list of bug fixes included
-- in that Maintenance Pack.
--
  ad_file_util.error_buf := 'load_preseeded_bugfixes('||
                            'INSERT into ad_snapshot_bugfixes( '||
                            'snapshot_bug_id,snapshot_id, '||
                            'bugfix_id,bug_status,success_flag, '||
                            'creation_date,last_update_date, '||
                            'last_updated_by,created_by) '||
                            'SELECT ad_snapshot_bugfixes_s.nextval,'||
                            'file_version_id_2, file_id,''EXPLICIT'',''Y'','||
                            'sysdate, sysdate,5,5 FROM ad_check_file_temp t '||
                            'where not exists (select ''already present'' '||
                            'from ad_snapshot_bugfixes b '||
                            'where b.BUGFIX_ID=t.file_id and '||
                            'b.SNAPSHOT_ID=t.file_version_id_2):(';


  begin
    INSERT into ad_snapshot_bugfixes(
    snapshot_bug_id,snapshot_id,
    bugfix_id,bug_status,success_flag,creation_date,
    last_update_date,last_updated_by,created_by)
    SELECT ad_snapshot_bugfixes_s.nextval,file_version_id_2,
    file_id,'EXPLICIT','Y',sysdate,
    sysdate,5,5
    FROM
    ad_check_file_temp t
    where not exists
    (select /*+ INDEX(B AD_SNAPSHOT_BUGFIXES_U2) */ 'already present'
      from ad_snapshot_bugfixes b
      where  b.BUGFIX_ID=t.file_id and
             b.SNAPSHOT_ID=t.file_version_id_2);
  exception
    when others then
      ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
      raise;
  end;
end load_preseeded_bugfixes;
--
--
--
--
procedure load_patch_hist_action
           (bugs_processed    out NOCOPY number,
            actions_processed out NOCOPY number)
is
  l_bugs_processed    number := 0;
  l_actions_processed number := 0;
--
-- for deleting duplicate actions
--
  cursor del_cursor is
    select patch_run_bug_id, common_action_id, file_id, rowid row_id
    from ad_patch_hist_temp
    where (patch_run_bug_id, common_action_id, file_id) in
      (select patch_run_bug_id, common_action_id, file_id
       from AD_PATCH_HIST_TEMP
       group by patch_run_bug_id, common_action_id, file_id
       having count(*) > 1)
    order by 1, 2, 3;
  prb_id number;
  ca_id number;
  f_id number;
  statement varchar2(200);
--
-- end for deleting duplicate actions
--
begin

-- bug 6343734 diverma 16 August 2007
--
-- update AD_PATCH_HIST_TEMP.TRACKABLE_ENTITY_ABBR with
-- AD_PATCH_HIST_TEMP.BUG_APP_SHORT_NAME if it is null.
--

  update AD_PATCH_HIST_TEMP
  set TRACKABLE_ENTITY_NAME = BUG_APP_SHORT_NAME
  where TRACKABLE_ENTITY_NAME is null;

  update AD_PATCH_HIST_TEMP
  set LANGUAGE = 'US'
  where LANGUAGE is null;

--
-- Add new entries in AD_BUGS
--
  insert  into ad_bugs
  (
    BUG_ID, BUG_NUMBER, ARU_RELEASE_NAME, CREATION_DATE,
    CREATED_BY, LAST_UPDATE_DATE, LAST_UPDATED_BY,
-- bug 5615204 diverma Tuesday, August 07, 2007
    TRACKABLE_ENTITY_ABBR, BASELINE_NAME, GENERIC_PATCH, LANGUAGE
  )
  -- bug 6332450 diverma Thu Aug  9 06:25:06 PDT 2007
  select
    ad_bugs_s.nextval, BUG_NUMBER, ARU_RELEASE_NAME, sysdate,
    5, sysdate, 5, TRACKABLE_ENTITY_NAME  , BASELINE_NAME,
    GENERIC_PATCH, LANGUAGE
  from
  (
    select
      distinct BUG_NUMBER, ARU_RELEASE_NAME,
-- bug 6332450 diverma Thu Aug  9 06:25:06 PDT 2007
-- bug 5615204 diverma Tuesday, August 07, 2007
      TRACKABLE_ENTITY_NAME, BASELINE_NAME, GENERIC_PATCH, LANGUAGE
    from
      AD_PATCH_HIST_TEMP where BUG_NUMBER is not null) tmp
    where
    not exists (
      select
        'x'
      from
        ad_bugs b
      where
        b.bug_number                  = tmp.BUG_NUMBER
-- bug 6332450 diverma Thu Aug  9 06:25:06 PDT 2007
    and b.trackable_entity_abbr = tmp.TRACKABLE_ENTITY_NAME
    and b.baseline_name         = tmp.baseline_name
    and b.aru_release_name = tmp.aru_release_name
-- bug 5615204 diverma Tuesday, August 07, 2007
    and b.language                  = tmp.LANGUAGE
           );
-- schinni bug 5612532 25th Oct 2006
-- ----------------------------------------------------------
-- Changed the condition in the subquery .
-- Earlier condition " b.generic_patch=y " was returning multiple
-- rows for a single row return subquery.
-- Using the generic_patch column present in the ad_patch_hist_temp
-- for refining the search condition in subquery
-- and to return a single row
-- -----------------------------------------------------------
--
--  Get the Bug_id into the Staging Table
--
  update AD_PATCH_HIST_TEMP t
  set t.bug_id = (
    select
    b.bug_id from ad_bugs b
    where
        b.bug_number       = t.BUG_NUMBER
-- bug 6332450 diverma Thu Aug  9 06:25:06 PDT 2007
    and b.trackable_entity_abbr = t.TRACKABLE_ENTITY_NAME
    and nvl(b.baseline_name,'NULL') = nvl(t.baseline_name,'NULL')
    and b.aru_release_name = t.aru_release_name
-- bug 5615204 diverma Tuesday, August 07, 2007
    and b.language                  = t.LANGUAGE
            );
--
--
commit;
--
-- Add new entries in the AD_PATCH_RUN_BUGS
--
  insert    into ad_patch_run_bugs
  (
    PATCH_RUN_BUG_ID,
    PATCH_RUN_ID, BUG_ID, ORIG_BUG_NUMBER, APPLICATION_SHORT_NAME,
    SUCCESS_FLAG, APPLIED_FLAG, REASON_NOT_APPLIED,
    CREATION_DATE, LAST_UPDATE_DATE, CREATED_BY, LAST_UPDATED_BY
  )
  select
    ad_patch_run_bugs_s.nextval,
    patch_run_id, bug_id, orig_bug_number,bug_app_short_name,
    success_flag, applied_flag, reason_not_applied,
    sysdate, sysdate, 5, 5
  from (
    select
      distinct patch_run_id,bug_id,
      orig_bug_number, bug_app_short_name,
      success_flag, applied_flag, reason_not_applied
    from
      AD_PATCH_HIST_TEMP  ) t
    where
    not exists (
      select
      'x'
      from ad_patch_run_bugs b
      where
       b.PATCH_RUN_ID           = t.patch_run_id
   and b.BUG_ID                 = t.bug_id
   and b.ORIG_BUG_NUMBER        = t.orig_bug_number
   and b.APPLICATION_SHORT_NAME = t.bug_app_short_name);

l_bugs_processed := sql%rowcount;
bugs_processed := l_bugs_processed;
--
--  Get the patch_run_bug_id into staging table
--
    update AD_PATCH_HIST_TEMP  t
    set PATCH_RUN_BUG_ID
    =(select
        b.PATCH_RUN_BUG_ID
      from
        ad_patch_run_bugs b
      where
          b.PATCH_RUN_ID           = t.patch_run_id
      and b.BUG_ID                 = t.bug_id
      and b.ORIG_BUG_NUMBER        = t.orig_bug_number
      and b.APPLICATION_SHORT_NAME = t.bug_app_short_name);
--
--
commit;
--
-- Add new entries in ad_files
--
   insert  into ad_files
   (file_id,
    app_short_name,
    subdir, filename,
    creation_date, created_by, last_update_date, last_updated_by)
    select ad_files_s.nextval,
      temp.FILE_APPS_SHORT_NAME asn,
      temp.file_subdir dir, temp.filename fname,
      sysdate,5,sysdate,5
   from
   (select    distinct
      t.file_apps_short_name ,
      t.file_subdir          ,
      t.filename
    from
      AD_PATCH_HIST_TEMP t
    ) temp
    where not exists (
    select
      'x'  from ad_files fl
    where
            fl.filename       = temp.filename
      and   fl.subdir         = temp.file_subdir
      and   fl.app_short_name = temp.file_apps_short_name
      )
     and temp.filename is not null;
--
-- Get the file_id into the staging table
--
  update AD_PATCH_HIST_TEMP t
  set t.file_id =
   (select  f.file_id
    from ad_files f
    where
            f.filename       = t.filename
      and   f.subdir         = t.file_subdir
      and   f.app_short_name = t.file_apps_short_name);
--
--
commit;
--
-- Add new entries in ad_files for Loader files
--
   insert  into ad_files
   (file_id, app_short_name, subdir, filename,
    creation_date, created_by, last_update_date, last_updated_by)
    select ad_files_s.nextval,
      temp.ldr_app_short_name asn,
      temp.ldr_subdir dir, temp.ldr_filename fname,
      sysdate, 5, sysdate, 5
   from
   (select    distinct
      t.ldr_app_short_name ,
      t.ldr_subdir          ,
      t.ldr_filename
    from
      AD_PATCH_HIST_TEMP t
    ) temp
    where not exists (
    select
      'x'  from ad_files fl
    where
            fl.filename       = temp.ldr_filename
      and   fl.subdir         = temp.ldr_subdir
      and   fl.app_short_name = temp.ldr_app_short_name
      )
     and temp.ldr_filename is not null;
--
-- Get the Loader file_id into the staging table
--
  update AD_PATCH_HIST_TEMP t
  set t.loader_data_file_id =
   (select  f.file_id
    from ad_files f
    where
            f.filename       = t.ldr_filename
      and   f.subdir         = t.ldr_subdir
      and   f.app_short_name = t.ldr_app_short_name)
      where t.ldr_filename is not null;
--
--
commit;

--
-- Add new entries in ad_files for the destination files
--
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
    temp.dest_apps_short_name,
    temp.dest_subdir,
    temp.dest_filename,
    sysdate, sysdate, 5, 5
  from
  (select    distinct
   t.dest_apps_short_name ,
   t.dest_subdir          ,
   t.dest_filename
   from
   AD_PATCH_HIST_TEMP t
   where t.dest_apps_short_name is not null
   and   t.dest_subdir is not null
   and 	 t.dest_filename is not null
  ) temp
  where not exists (
  select
    'dest file already exists' from ad_files f
  where
       f.filename = temp.dest_filename
  and  f.subdir   = temp.dest_subdir
  and  f.app_short_name = temp.dest_apps_short_name);

--
-- Get the Destination file_id into the staging table
--
   update AD_PATCH_HIST_TEMP t
   set t.dest_file_id =
    (select /*+ INDEX(F AD_FILES_U2) */ f.file_id
     from ad_files f
     where f.app_short_name = t.dest_apps_short_name
     and   f.subdir = t.dest_subdir
     and   f.filename = t.dest_filename);
--
--
commit;

--
--  Add new entries in the ad_file_versions
--
  INSERT   into ad_file_versions
  (file_version_id, file_id, version, translation_level,
   version_segment1, version_segment2, version_segment3,
   version_segment4, version_segment5, version_segment6,
   version_segment7, version_segment8, version_segment9,
   version_segment10,
   creation_date, created_by, last_update_date, last_updated_by)
   select
     ad_file_versions_s.nextval,
     temp.f_id, temp.vers, temp.trans_level,
     temp.vs1, temp.vs2, temp.vs3, temp.vs4, temp.vs5,
     temp.vs6, temp.vs7, temp.vs8, temp.vs9, temp.vs10,
     sysdate, 5, sysdate, 5
   from
   (
    select
      distinct
      t.file_id f_id,
      t.PATCH_FILE_VERS vers,
      t.PATCH_TRANS_LEVEL trans_level,
      t.PATCH_VERSION_SEGMENT1  vs1,
      t.PATCH_VERSION_SEGMENT2  vs2,
      t.PATCH_VERSION_SEGMENT3  vs3,
      t.PATCH_VERSION_SEGMENT4  vs4,
      t.PATCH_VERSION_SEGMENT5  vs5,
      t.PATCH_VERSION_SEGMENT6  vs6,
      t.PATCH_VERSION_SEGMENT7  vs7,
      t.PATCH_VERSION_SEGMENT8  vs8,
      t.PATCH_VERSION_SEGMENT9  vs9,
      t.PATCH_VERSION_SEGMENT10 vs10
    from
      AD_PATCH_HIST_TEMP t
    where
      t.PATCH_FILE_VERS is not null
  ) temp
   where not exists (
   select
     'x'
   from
     ad_file_versions vers
   where
       vers.file_id           = temp.f_id
   and vers.version           = temp.vers
   and vers.translation_level = temp.trans_level);
--
--  Add new entries in the ad_file_versions
--
  INSERT   into ad_file_versions
  (file_version_id, file_id, version, translation_level,
   version_segment1, version_segment2, version_segment3,
   version_segment4, version_segment5, version_segment6,
   version_segment7, version_segment8, version_segment9,
   version_segment10,
   creation_date, created_by, last_update_date, last_updated_by)
   select
     ad_file_versions_s.nextval,
     temp.f_id, temp.vers, temp.trans_level,
     temp.vs1, temp.vs2, temp.vs3, temp.vs4, temp.vs5,
     temp.vs6, temp.vs7, temp.vs8, temp.vs9, temp.vs10,
     sysdate, 5, sysdate, 5
   from
   (
    select
      distinct t.file_id f_id,
      t.ONSITE_FILE_VERS vers,
      t.ONSITE_TRANS_LEVEL trans_level,
      t.ONSITE_VERSION_SEGMENT1   vs1,
      t.ONSITE_VERSION_SEGMENT2   vs2,
      t.ONSITE_VERSION_SEGMENT3   vs3,
      t.ONSITE_VERSION_SEGMENT4   vs4,
      t.ONSITE_VERSION_SEGMENT5   vs5,
      t.ONSITE_VERSION_SEGMENT6   vs6,
      t.ONSITE_VERSION_SEGMENT7   vs7,
      t.ONSITE_VERSION_SEGMENT8   vs8,
      t.ONSITE_VERSION_SEGMENT9   vs9,
      t.ONSITE_VERSION_SEGMENT10  vs10
    from
      AD_PATCH_HIST_TEMP t
    where
      t.ONSITE_FILE_VERS is not NULL
    ) temp
   where not exists (
   select
     'x'
   from
     ad_file_versions vers
   where
       vers.file_id           = temp.f_id
   and vers.version           = temp.vers
   and vers.translation_level = temp.trans_level);
--
--  Add new entries in the ad_file_versions
--
  INSERT   into ad_file_versions
  (file_version_id, file_id, version, translation_level,
   version_segment1, version_segment2, version_segment3,
   version_segment4, version_segment5, version_segment6,
   version_segment7, version_segment8, version_segment9,
   version_segment10,
   creation_date, created_by, last_update_date, last_updated_by)
   select
     ad_file_versions_s.nextval,
     tmp.f_id,tmp.vers, tmp.trans_level,
     tmp.vs1, tmp.vs2, tmp.vs3, tmp.vs4,
     tmp.vs5, tmp.vs6, tmp.vs7, tmp.vs8,
     tmp.vs9, tmp.vs10,sysdate, 5, sysdate, 5
   from
   (
    select
      distinct
      t.file_id f_id,
      t.DB_FILE_VERS vers,
      t.DB_TRANS_LEVEL trans_level,
      t.DB_VERSION_SEGMENT1  vs1 ,
      t.DB_VERSION_SEGMENT2  vs2 ,
      t.DB_VERSION_SEGMENT3  vs3 ,
      t.DB_VERSION_SEGMENT4  vs4 ,
      t.DB_VERSION_SEGMENT5  vs5 ,
      t.DB_VERSION_SEGMENT6  vs6 ,
      t.DB_VERSION_SEGMENT7  vs7 ,
      t.DB_VERSION_SEGMENT8  vs8 ,
      t.DB_VERSION_SEGMENT9  vs9 ,
      t.DB_VERSION_SEGMENT10 vs10
    from
      AD_PATCH_HIST_TEMP t
    where
      t.DB_FILE_VERS is not null
   ) tmp
   where not exists (
   select
     'x'
   from
     ad_file_versions vers
   where
       vers.file_id           = tmp.f_id
   and vers.version           = tmp.vers
   and vers.translation_level = tmp.trans_level);
--
--
commit;
--
--
-- Process the PatchFile Versions
--
-- Get the file_version_id into the staging table
--
  update AD_PATCH_HIST_TEMP t
  set t.PATCH_FILE_VERS_ID =
    (select
      fv.file_version_id
    from
      ad_file_versions fv
    where
      fv.file_id           = t.file_id
  and fv.version           = t.PATCH_FILE_VERS
  and fv.translation_level = t.PATCH_TRANS_LEVEL)
  where
    t.PATCH_FILE_VERS is not NULL;
--
--
--  Process the OnSiteFile Versions
--
--
--  Get the file_version_id into the staging table
--
--
  update AD_PATCH_HIST_TEMP t
  set t.ONSITE_FILE_VERS_ID =
   (select
      fv.file_version_id
    from
      ad_file_versions fv
    where
      fv.file_id = t.file_id
  and fv.version = t.ONSITE_FILE_VERS
  and fv.translation_level = t.ONSITE_TRANS_LEVEL
    )
  where
    t.ONSITE_FILE_VERS is not NULL;
--
--
-- Process the Db FileVersions
--
-- Get the file_version_id into the staging table
--
  update AD_PATCH_HIST_TEMP t
  set t.DB_FILE_VERS_ID =
    (select
      fv.file_version_id
    from
      ad_file_versions fv
    where
          fv.file_id           = t.file_id
    and   fv.version           = t.DB_FILE_VERS
    and   fv.translation_level = t.DB_TRANS_LEVEL)
    where
      t.DB_FILE_VERS is not NULL;
--
--
commit;
--
--  Add new entries in the ad_patch_common_actions
--
  INSERT  INTO AD_PATCH_COMMON_ACTIONS
  (
    COMMON_ACTION_ID, ACTION_CODE, ACTION_PHASE, NUMERIC_PHASE,
    NUMERIC_SUB_PHASE, ACTION_ARGUMENTS, CHECKFILE_ARGS,
    ACTION_CHECK_OBJ, ACTION_CHECK_OBJ_USERNAME, ACTION_CHECK_OBJ_PASSWD,
    ACTION_WHAT_SQL_EXEC, ACTION_TIERLIST_IN_DRIVER, ACTION_LANG_CODE,
    CONCAT_ATTRIBS, LOADER_DATA_FILE_ID, CREATION_DATE,
    LAST_UPDATE_DATE, CREATED_BY, LAST_UPDATED_BY
  )
  select AD_PATCH_COMMON_ACTIONS_S.NEXTVAL,
    t.action_code, t.action_phase, t.major_phase, t.minor_phase,
    t.action_arguments, t.checkfile_args, t.checkobj , t.checkobj_un  ,
    t.checkobj_pw, t.action_modifier , t.action_tierlist       ,
    t.action_lang_code , t.concat_attribs, t.loader_data_file_id,
    sysdate, sysdate, 5, 5
  from
  (
    select distinct
      action_code, action_phase, major_phase, minor_phase,
      action_arguments, checkfile_args, checkobj , checkobj_un  ,
      checkobj_pw, action_modifier, action_tierlist ,
      action_lang_code, concat_attribs, loader_data_file_id
    from
      AD_PATCH_HIST_TEMP )t
  where not exists (
    select
      'x'
    FROM
      AD_PATCH_COMMON_ACTIONS PCA
    WHERE
       PCA.CONCAT_ATTRIBS   = t.CONCAT_ATTRIBS)
    and t.concat_attribs is not null;
--
--   Get the COMMON_ACTION_ID into the staging table
--
  update AD_PATCH_HIST_TEMP t
  set t.COMMON_ACTION_ID =
    (select
      PCA.COMMON_ACTION_ID
    from
      AD_PATCH_COMMON_ACTIONS PCA
    WHERE
      PCA.CONCAT_ATTRIBS   = t.concat_attribs   )
    where  t.concat_attribs is not null;
--
--
  commit;
--
-- Fix bug 2757813:
-- remove any duplicate actions in same bug fix from temp table
-- These will cause logic below to fail
--
-- Later we should set allow_duplicate_actions= FALSE; in adpdrv.lc
-- so that we don't get any duplicate actions in the action list
-- and also stop calling adptod().
--
  begin

    prb_id := -1;
    ca_id := -1;
    f_id := -1;

    for c1 in del_cursor loop

  --    dbms_output.put_line(c1.patch_run_bug_id||','||c1.common_action_id||
  --      ','||c1.file_id||','||c1.row_id);
  --    dbms_output.put_line(prb_id||','||ca_id||','||f_id);

      if c1.patch_run_bug_id <> prb_id
	 or c1.common_action_id <> ca_id
	 or c1.file_id <> f_id then

	prb_id := c1.patch_run_bug_id;
	ca_id := c1.common_action_id;
	f_id := c1.file_id;

	statement := 'delete from ad_patch_hist_temp'||
	  ' where patch_run_bug_id = '||c1.patch_run_bug_id||
	  ' and common_action_id = '||c1.common_action_id||
	  ' and file_id = '||c1.file_id||
	  ' and rowid <> '''||c1.row_id||'''';

  --      dbms_output.put_line(statement);

	execute immediate statement;
      end if;

    end loop;
  end;
--
--  Add new entries in the ad_patch_run_bug_actions
--
  insert    into AD_PATCH_RUN_BUG_ACTIONS
  (
    ACTION_ID,
    PATCH_RUN_BUG_ID,
    COMMON_ACTION_ID,
    FILE_ID,
    PATCH_FILE_VERSION_ID,
    ONSITE_FILE_VERSION_ID,
    ONSITE_PKG_VERSION_IN_DB_ID,
    EXECUTED_FLAG,
    DEST_FILE_ID, FILE_TYPE_FLAG,
    CREATION_DATE, LAST_UPDATE_DATE, CREATED_BY, LAST_UPDATED_BY
  )
  select
    AD_PATCH_RUN_BUG_ACTIONS_S.NEXTVAL,
    t.patch_run_bug_id,
    t.common_action_id,
    t.file_id,
    t.patch_file_vers_id,
    t.onsite_file_vers_id,
    t.db_file_vers_id,
    t.action_executed_flag,
    t.dest_file_id, t.file_type_flag,
    SYSDATE, SYSDATE, 5, 5 from AD_PATCH_HIST_TEMP t
    where not exists
    (select
       'x'
     from
       AD_PATCH_RUN_BUG_ACTIONS aprba
     where
         aprba.PATCH_RUN_BUG_ID = t.patch_run_bug_id
     and aprba.FILE_ID          = t.file_id
     and aprba.COMMON_ACTION_ID = t.common_action_id)
    and t.common_action_id is not null and t.ldr_filename is null;
--
--
l_actions_processed := sql%rowcount;
actions_processed := l_actions_processed;
--
--
commit;
--
--  Add new entries in the ad_patch_run_bug_actions with loader files.
--  bug 3486202, cbhati
--
  insert    into AD_PATCH_RUN_BUG_ACTIONS
  (
    ACTION_ID,
    PATCH_RUN_BUG_ID,
    COMMON_ACTION_ID,
    FILE_ID,
    PATCH_FILE_VERSION_ID,
    ONSITE_FILE_VERSION_ID,
    ONSITE_PKG_VERSION_IN_DB_ID,
    EXECUTED_FLAG,
    DEST_FILE_ID, FILE_TYPE_FLAG,
    CREATION_DATE, LAST_UPDATE_DATE, CREATED_BY, LAST_UPDATED_BY
  )
  select
    AD_PATCH_RUN_BUG_ACTIONS_S.NEXTVAL,
    t.patch_run_bug_id,
    t.common_action_id,
    t.loader_data_file_id,
    t.patch_file_vers_id,
    t.onsite_file_vers_id,
    t.db_file_vers_id,
    t.action_executed_flag,
    t.dest_file_id, t.file_type_flag,
    SYSDATE, SYSDATE, 5, 5 from AD_PATCH_HIST_TEMP t
    where not exists
    (select
       'x'
     from
       AD_PATCH_RUN_BUG_ACTIONS aprba
     where
         aprba.PATCH_RUN_BUG_ID = t.patch_run_bug_id
     and aprba.FILE_ID          = t.loader_data_file_id
     and aprba.COMMON_ACTION_ID = t.common_action_id)
    and t.common_action_id is not null and t.loader_data_file_id is not null;
--
--
l_actions_processed := sql%rowcount;
actions_processed := l_actions_processed;
--
--
commit;

--
--
end load_patch_hist_action;


-- Procedure
--     create_global_view
-- Arguments
--     p_apps_system_name - Applications system name
-- Purpose
--     Procedure to create Global View snapshot using exisiting
--     current view snapshots for an applications system.
-- Notes
--     Pre-requiste: ad_snapshot_files_temp sholud have been populated
--                   before calling this API.

procedure create_global_view(p_apps_system_name varchar2,
                             p_is_run_flow boolean default true)
is
  l_release_id         number;
  l_snapshot_count     number;
  l_global_snapshot_id number;
  l_appl_top_id        number;
  l_appl_top_count     number;
  l_global_snapshot_type  varchar2(1);
  l_current_snapshot_type  varchar2(1);
begin

  if (p_is_run_flow = TRUE)
  then
     l_global_snapshot_type := 'G';
     l_current_snapshot_type := 'C';
  else
     l_global_snapshot_type := 'Q';
     l_current_snapshot_type := 'P';
  end if;

  /* Compute total number of current view snapshots available */
  select count(*) into l_snapshot_count
  from   ad_snapshots s, ad_appl_tops t
  where  s.snapshot_type            = l_current_snapshot_type and
         s.snapshot_name            = 'CURRENT_VIEW' and
         s.appl_top_id              = t.appl_top_id and
         t.applications_system_name = p_apps_system_name;

  /* Get the release id */
  select release_id into l_release_id from ad_releases
  where  to_char(major_version) || '.' ||
         to_char(minor_version) || '.' ||
         to_char(tape_version) = (select release_name
                                  from   fnd_product_groups
                                  where  applications_system_name =
                                         p_apps_system_name);

  /* Create a dummy Appl_top called  'GLOBAL' */
  insert into ad_appl_tops
  (
    appl_top_id, name, applications_system_name, appl_top_type,
    description,
    server_type_admin_flag,
    server_type_forms_flag,
    server_type_node_flag,
    server_type_web_flag,
    creation_date,
    created_by,
    last_update_date,
    last_updated_by,
    active_flag
  )
  select
    ad_appl_tops_s.nextval,
    'GLOBAL',    /* APPL_TOP type is 'G' */
    p_apps_system_name,
    'G',
    'Created for Global View Snapshot',
    null,
    null,
    null,
    null,
    sysdate,
    5,
    sysdate,
    5,
    'N'  /* ACTIVE_FLAG is set to 'N'. (Refer CONCURRENT_SESSIONS) */
  from dual where not exists(select 'Already exists'
                  from  ad_appl_tops t
                  where t.name                     = 'GLOBAL' and
                        t.appl_top_type            = 'G' and
                        t.applications_system_name = p_apps_system_name);

  /* Get 'GLOBAL' APPL_TOP_ID */
  select appl_top_id into l_appl_top_id
  from   ad_appl_tops
  where  appl_top_type            = 'G' and
         name                     = 'GLOBAL' and
         applications_system_name = p_apps_system_name;

  insert into ad_snapshots
  (
    snapshot_id, release_id, appl_top_id, snapshot_name,
    snapshot_creation_date,
    snapshot_update_date,
    snapshot_type,
    comments,
    ran_snapshot_flag,
    creation_date,
    last_updated_by,
    created_by,
    last_update_date
  )
  select ad_snapshots_s.nextval, l_release_id,
         l_appl_top_id,
         'GLOBAL_VIEW',
         sysdate,
         sysdate,
         l_global_snapshot_type,      /* snapshot type is 'G' */
         'Created from Current View Snapshots',
         'Y',      /* Setting RAN_SNAPSHOT_FLAG to 'Y'. Because, it doesn't */
         sysdate,  /* have any significance for GLOBAL_VIEW  */
         5,
         5,
         sysdate
  from dual where not exists(select 'Already exists'
                  from ad_snapshots s
                  where s.appl_top_id = l_appl_top_id
                  and s.snapshot_type = l_global_snapshot_type
                  and s.snapshot_name = 'GLOBAL_VIEW');

  /* Get Global snapshot ID for this Applications Sytem Name */
  select s.snapshot_id into l_global_snapshot_id
  from   ad_snapshots s
  where  s.snapshot_type = l_global_snapshot_type and
         s.snapshot_name = 'GLOBAL_VIEW' and
         s.appl_top_id   = l_appl_top_id;

  commit;
exception
  when others then
    rollback;
    raise;
end create_global_view;
-- Procedure
--     populate_snapshot_files_temp
-- Arguments
--     p_apps_system_name   - Applications System Name
--
--     p_min_file_id        - lower file_id in the range of file_ids
--
--     p_max_file_id        - upper file_id in the range of file_ids
--
--     p_global_snapshot_id - Global snapshot_id
--
--     p_un_fnd             - applsys username
--
--     p_iteration          - which iteration  (1,2,etc)
-- Purpose
--     This procedure populates temp table  with a range of file_ids
--     processes the data and updates the ad_snapshot_files  with negative
--     global snapshot_id
-- Notes

procedure populate_snapshot_files_temp(p_applications_sys_name varchar2,p_min_file_id number,
                                       p_max_file_id number,p_global_snapshot_id number,
                                       p_un_fnd varchar2,p_iteration number,
                                       p_is_run_flow boolean default true)
is
  v_global_snapshot_count number;
  v_global_snapshot_id number;
  v_global_appl_top_id number;
  v_current_snapshot_type varchar2(1);
begin
--
--
  execute immediate 'truncate table '|| p_un_fnd ||'.ad_snapshot_files_temp';
  execute immediate 'truncate table '|| p_un_fnd ||'.ad_patch_hist_temp';
--
--
  if (p_is_run_flow = TRUE)
  then
     v_current_snapshot_type := 'C';
  else
     v_current_snapshot_type := 'P';
  end if;

  if (p_iteration = 1) then
    execute immediate 'truncate table '|| p_un_fnd ||'.ad_check_file_temp';
--
--
    insert into ad_check_file_temp
    (TRANSLATION_LEVEL,APP_SHORT_NAME,
     SUBDIR,FILENAME, MANIFEST_VERS,
     EFFECTIVE_DATE)
     select
       snapshot_id, ' ',
       ' ',' ',' ',
       sysdate
     from
       ad_snapshots  snap,
       ad_appl_tops atp,
       ad_releases ar,
       fnd_product_groups fpg
     where
       atp.appl_top_id=snap.appl_top_id                     and
       atp.appl_top_type='R'                                and
       atp.applications_system_name=p_applications_sys_name and
       nvl(atp.active_flag,'Y') = 'Y'                       and
       snap.snapshot_type       = v_current_snapshot_type   and
       snap.snapshot_name       = 'CURRENT_VIEW'            and
       snap.release_id          = ar.release_id             and
       fpg.release_name         = ar.major_version||'.'||ar.minor_version||'.'||ar.tape_version and
       fpg.applications_system_name=atp.applications_system_name and
       fpg.product_group_id=1;
--
--
  end if;
--
--
  commit;
--
--
   v_global_snapshot_id:=(-1*p_global_snapshot_id);
--
--
    insert into ad_snapshot_files
    (
      snapshot_file_id,snapshot_id,
      file_id, file_version_id, containing_file_id,
      file_size, checksum, update_source_id,  update_type,
      appl_top_id, inconsistent_flag, dest_file_id,file_type_flag,
      creation_date,last_update_date,last_updated_by,created_by
    )
    select
      ad_snapshot_files_s.nextval,v_global_snapshot_id,
      file_id,file_version_id,containing_file_id,
      file_size,checksum,update_source_id,'S',
      appl_top_id, 'N', dest_file_id,file_type_flag,
      sysdate,sysdate,5,5
    from
    (
       select
         file_id,
         max(file_version_id)    file_version_id,
         max(containing_file_id) containing_file_id,
         max(file_size)          file_size,
         max(checksum)           checksum,
         max(snapshot_id)        snapshot_id,
         max(dest_file_id)       dest_file_id,
         max(appl_top_id)        appl_top_id,
         decode(max(decode(update_type, 'P', 2, 1)), 2, 'P', 'S')    update_type,
         decode(max(decode(file_type_flag, 'M', 2, 1)), 2, 'M', 'N') file_type_flag,
         replace(max(decode(update_type, 'P', 'a', null)||
         to_char(update_source_id)), 'a', null)                      update_source_id
        from
          ad_snapshot_files
        where
          file_id >= p_min_file_id  and
          file_id <  p_max_file_id  and
          snapshot_id in (select TRANSLATION_LEVEL from ad_check_file_temp)
        group by
            file_id
        having
            count(distinct nvl(file_version_id,0))=1
    );
--
--
   commit;
--
--
  insert into ad_patch_hist_temp
  (
     file_id, patch_file_vers_id , onsite_file_vers_id,
     bug_id, patch_run_bug_id ,
     db_file_vers_id, applied_flag,common_action_id,
     success_flag, major_phase,action_executed_flag,
     concat_attribs
  )
  select /*+ opt_param('_gby_hash_aggregation_enabled','false') */
   file_id,
   nvl(file_version_id,0),
   containing_file_id,
   file_size,
   checksum,
   update_source_id,
   update_type,
   appl_top_id ,
   'Y',
   dest_file_id,
   file_type_flag,
    '1234567890123456789012345678901234567890123456789012345678901234567890'
  from
    ad_snapshot_files
  where
    file_id in
    ( select
       file_id from ad_snapshot_files
      where
        file_id >= p_min_file_id  and
        file_id <  p_max_file_id  and
        snapshot_id in (select TRANSLATION_LEVEL from ad_check_file_temp)
      group by
        file_id
      having
        count(distinct nvl(file_version_id,0)) >1
    )  and
    snapshot_id in (select TRANSLATION_LEVEL from ad_check_file_temp);
--
--
  commit;
--
--
  update ad_patch_hist_temp tmp set
   (tmp.PATCH_VERSION_SEGMENT1, tmp.PATCH_VERSION_SEGMENT2,
    tmp.PATCH_VERSION_SEGMENT3, tmp.PATCH_VERSION_SEGMENT4,
    tmp.PATCH_VERSION_SEGMENT5, tmp.PATCH_VERSION_SEGMENT6,
    tmp.PATCH_VERSION_SEGMENT7, tmp.PATCH_VERSION_SEGMENT8,
    tmp.PATCH_VERSION_SEGMENT9, tmp.PATCH_VERSION_SEGMENT10,
    tmp.PATCH_FILE_VERS, tmp.PATCH_TRANS_LEVEL) =
    (select
      v.VERSION_SEGMENT1, v.VERSION_SEGMENT2,
      v.VERSION_SEGMENT3, v.VERSION_SEGMENT4,
      v.VERSION_SEGMENT5, v.VERSION_SEGMENT6,
      v.VERSION_SEGMENT7, v.VERSION_SEGMENT8,
      v.VERSION_SEGMENT9, v.VERSION_SEGMENT10,
      v.VERSION, v.TRANSLATION_LEVEL
    from
      ad_file_versions v
    where
      v.file_version_id = tmp.PATCH_FILE_VERS_ID),
      tmp.concat_attribs=null;
--
--
  update ad_patch_hist_temp tmp set
   tmp.PATCH_VERSION_SEGMENT1=0, tmp.PATCH_VERSION_SEGMENT2=0,
    tmp.PATCH_VERSION_SEGMENT3=0, tmp.PATCH_VERSION_SEGMENT4=0,
    tmp.PATCH_VERSION_SEGMENT5=0, tmp.PATCH_VERSION_SEGMENT6=0,
    tmp.PATCH_VERSION_SEGMENT7=0, tmp.PATCH_VERSION_SEGMENT8=0,
    tmp.PATCH_VERSION_SEGMENT9=0, tmp.PATCH_VERSION_SEGMENT10=0,
    tmp.PATCH_FILE_VERS=null, tmp.PATCH_TRANS_LEVEL=null
   where tmp.PATCH_FILE_VERS_ID=0;
--
   execute immediate 'insert into ad_snapshot_files
    (
      snapshot_file_id,snapshot_id,
      file_id, file_version_id, containing_file_id,
      file_size, checksum, update_source_id,  update_type,
      appl_top_id, inconsistent_flag, dest_file_id,file_type_flag,
      creation_date,last_update_date,last_updated_by,
      created_by
    )
    select
      ad_snapshot_files_s.nextval,:v_global_snapshot_id,
      file_id, patch_file_vers_id , onsite_file_vers_id,
      bug_id, patch_run_bug_id,db_file_vers_id,applied_flag,
      common_action_id, ''Y'', major_phase,action_executed_flag,
      sysdate,sysdate,5,5
    from
   (
     select
       file_id, patch_file_vers_id , onsite_file_vers_id,
       bug_id, patch_run_bug_id ,
       db_file_vers_id, applied_flag,common_action_id,
       success_flag, major_phase ,action_executed_flag,row_number() over
     (
        PARTITION BY file_id order by
        PATCH_VERSION_SEGMENT1 desc, PATCH_VERSION_SEGMENT2 desc,
        PATCH_VERSION_SEGMENT3 desc, PATCH_VERSION_SEGMENT4 desc,
        PATCH_VERSION_SEGMENT5 desc, PATCH_VERSION_SEGMENT6 desc,
        PATCH_VERSION_SEGMENT7 desc, PATCH_VERSION_SEGMENT8 desc,
        PATCH_VERSION_SEGMENT9 desc, PATCH_VERSION_SEGMENT10 desc,
        PATCH_TRANS_LEVEL desc NULLS LAST
     ) rnk
    from
      ad_patch_hist_temp)   where  rnk=1'  using v_global_snapshot_id;
--
--
   commit;
--
--
  if (p_iteration = 1) then
    FND_STATS.Gather_Table_Stats(p_un_fnd, 'AD_SNAPSHOT_FILES_TEMP');
    FND_STATS.Gather_Table_Stats(p_un_fnd, 'AD_CHECK_FILE_TEMP');
    FND_STATS.Gather_Table_Stats(p_un_fnd, 'AD_PATCH_HIST_TEMP');
  end if;
--
--
end populate_snapshot_files_temp;
--
--
-- Procedure
--     populate_snapshot_bugs_temp
-- Arguments
--     p_apps_system_name   - Applications System Name
--
--     p_min_bug_id        - lower bugfix_id in the range of bugfix_id
--
--     p_max_bug_id        - upper bugfix_id in the range of bugfix_id
--
--     p_global_snapshot_id - Global snapshot_id
--
--     p_un_fnd             - applsys username
--
--     p_iteration          - which iteration  (1,2,etc)
-- Purpose
--     This procedure populates temp table with a range of bugfix_id
--     processes the data and updates the ad_snapshot_bugfixes  with negative
--     global snapshot_id
-- Notes
--
procedure populate_snapshot_bugs_temp(p_applications_sys_name varchar2,p_min_bug_id number,
                                      p_max_bug_id number,p_global_snapshot_id number,
                                      p_un_fnd varchar2,p_iteration number,
                                      p_is_run_flow boolean default true)
is
  v_global_snapshot_id  number;
  v_current_snapshot_type varchar2(1);
begin
--
--
  execute immediate 'truncate table '||p_un_fnd||'.ad_check_file_temp';
--
--
  if (p_is_run_flow = TRUE)
  then
     v_current_snapshot_type := 'C';
  else
     v_current_snapshot_type := 'P';
  end if;

 if (p_iteration = 1) then
--
--
   execute immediate 'truncate table '||p_un_fnd||'.ad_patch_hist_temp';
--
--
  insert into ad_patch_hist_temp
  (patch_run_id)
   select
     snapshot_id
   from
     ad_snapshots  snap,
       ad_appl_tops atp,
       ad_releases ar,
       fnd_product_groups fpg
     where
       atp.appl_top_id=snap.appl_top_id                     and
       atp.appl_top_type='R'                                and
       atp.applications_system_name=p_applications_sys_name and
       nvl(atp.active_flag,'Y') = 'Y'                       and
       snap.snapshot_type       = v_current_snapshot_type   and
       snap.snapshot_name       = 'CURRENT_VIEW'            and
       snap.release_id          = ar.release_id             and
       fpg.release_name         = ar.major_version||'.'||ar.minor_version||'.'||ar.tape_version and
       fpg.applications_system_name=atp.applications_system_name and
       fpg.product_group_id=1;
--
--
 end if;
  v_global_snapshot_id:=(-1 *p_global_snapshot_id);
--
--
 insert into ad_snapshot_bugfixes
(
    SNAPSHOT_BUG_ID,
    snapshot_id, bugfix_id,
    inconsistent_flag,
    bug_status, success_flag,
    creation_date,last_update_date,last_updated_by,
    created_by
)
select
   ad_snapshot_bugfixes_s.nextval,v_global_snapshot_id,
   bugfix_id,
   'N',
   bug_status,success_flag,
   sysdate,sysdate,5,5
from
(
   select
    bugfix_id,
    decode(max(decode(success_flag, 'Y', 2, 1)),
           2, 'Y', 'N') success_flag,
    decode(max(decode(bug_status, 'EXPLICIT', 2, 1)),
           2, 'EXPLICIT', 'IMPLICIT') bug_status
  from
    ad_snapshot_bugfixes
  where
    bugfix_id >=  p_min_bug_id  and
    bugfix_id <   p_max_bug_id  and
    snapshot_id in (select patch_run_id from ad_patch_hist_temp)
   group by
     bugfix_id
   having
     count(distinct decode(success_flag, 'Y', 2, 1)) = 1);
--
--
  insert into ad_check_file_temp (
                 file_version_id,
                app_short_name , active_flag,
                check_file_id,subdir,filename,
                manifest_vers,translation_level,effective_date)
  select
    bugfix_id,
    bug_status, success_flag,
    (decode(success_flag,'Y',1,2) * 3 +
      decode(bug_status,'EXPLICIT',1,'IMPLICIT',2,3))  bug_rank ,
    'NA','NA','NA',0,sysdate
  from
  (
    select
    bugfix_id,
    decode(max(decode(success_flag, 'Y', 2, 1)),
                       2, 'Y', 'N') success_flag,
    decode(max(decode(bug_status, 'EXPLICIT', 2, 1)),
                       2, 'EXPLICIT', 'IMPLICIT') bug_status
   from
    ad_snapshot_bugfixes
   where
      bugfix_id >=  p_min_bug_id  and
      bugfix_id <   p_max_bug_id  and
      snapshot_id in (select patch_run_id from ad_patch_hist_temp)
   group by bugfix_id
   having count(distinct decode(success_flag, 'Y', 2, 1)) >1);
--
--
  execute immediate 'insert into ad_snapshot_bugfixes
  (
    SNAPSHOT_BUG_ID,
    snapshot_id, bugfix_id,
    inconsistent_flag,
    bug_status, success_flag,
    creation_date,last_update_date,last_updated_by,
    created_by
  )
  select
   ad_snapshot_bugfixes_s.nextval,:snp_id,
   file_version_id,
   ''Y'',
   app_short_name , active_flag,
   sysdate,sysdate,5,5
  from
  (
   select
     file_version_id,
     app_short_name , active_flag,rnk
   from
   (
     select
       file_version_id,
       app_short_name , active_flag,
       ROW_NUMBER() over
      (
        PARTITION BY file_version_id order by
        check_file_id
      ) rnk
     from
       ad_check_file_temp
    )
  ) where rnk=1 ' using v_global_snapshot_id;
--
--
  commit;
--
--
  if (p_iteration = 1) then
    FND_STATS.Gather_Table_Stats(p_un_fnd, 'AD_SNAPSHOT_FILES_TEMP');
    FND_STATS.Gather_Table_Stats(p_un_fnd, 'AD_CHECK_FILE_TEMP');
    FND_STATS.Gather_Table_Stats(p_un_fnd, 'AD_PATCH_HIST_TEMP');
  end if;
--
--
end populate_snapshot_bugs_temp;
--
--
--
-- Procedure
--   load_prepmode_checkfile_info
--
-- Purpose
--   Imports file information from ad_check_file_temp to
--   ad_prepmode_check_files, when applying a patch is "prepare" mode.
--
-- Arguments
--   none
--
procedure load_prepmode_checkfile_info is
begin

   --
   -- first update versions for existing rows
   --  (assume that the versions in temporary table are higher)
   --

   update ad_prepmode_check_files cf
   set version = (select t.manifest_vers
                  from   ad_check_file_temp t
                  where  t.app_short_name = cf.app_short_name
                  and    t.subdir = cf.subdir
                  and    t.filename = cf.filename
                  and    nvl(t.distinguisher, '~') = cf.distinguisher)
   where (app_short_name, subdir, filename, distinguisher) in
     (select app_short_name, subdir, filename, nvl(distinguisher, '~')
      from   ad_check_file_temp
      where  manifest_vers is not null);

   --
   -- insert rows for new files
   --
   insert into ad_prepmode_check_files cf
   (
      app_short_name, subdir, filename, distinguisher,
      version
   )
   select distinct app_short_name, subdir, filename, nvl(distinguisher, '~'),

          manifest_vers
   from ad_check_file_temp t
   where t.manifest_vers is not null
   and not exists (
     select null
     from   ad_prepmode_check_files cf2
     where  cf2.app_short_name = t.app_short_name
     and    cf2.subdir = t.subdir
     and    cf2.filename = t.filename
     and    cf2.distinguisher = nvl(t.distinguisher, '~'));


end load_prepmode_checkfile_info;

--
-- Procedure
--   cln_prepmode_checkfile_info
--
-- Purpose
--   deletes rows from ad_premode_check_files (called after the merge)
--
-- Arguments
--   none
--
procedure cln_prepmode_checkfile_info
is
begin
  delete from ad_prepmode_check_files;
end cln_prepmode_checkfile_info;

--
-- Bug 4488796 - rahkumar
-- Procedure
--   load_snpst_file_server_info
--
-- Purpose
--   updates the values of the server flags of the table ad_snapshot_files
--   as obtained from the temporary table ad_check_file_temp
--
-- Arguments
--   snp_id - snapshot_id for which the rows are to be updated
--
procedure load_snpst_file_server_info
           (snp_id number)
is
  TYPE t_file_id     IS TABLE OF ad_check_file_temp.file_id%TYPE;
  TYPE t_containing_file_id IS TABLE OF ad_check_file_temp.check_file_id%TYPE;
  TYPE t_admin_server_flag IS TABLE OF ad_check_file_temp.server_type_admin_flag%TYPE;
  TYPE t_forms_server_flag IS TABLE OF ad_check_file_temp.server_type_forms_flag%TYPE;
  TYPE t_node_server_flag IS TABLE OF ad_check_file_temp.server_type_node_flag%TYPE;
  TYPE t_web_server_flag IS TABLE OF ad_check_file_temp.server_type_web_flag%TYPE;
--
  fl_id_list         t_file_id;
  con_file_id_list   t_containing_file_id;
  admin_server_flag_list t_admin_server_flag;
  forms_server_flag_list t_forms_server_flag;
  node_server_flag_list t_node_server_flag;
  web_server_flag_list t_web_server_flag;
--
--
--
  CURSOR  c1 IS
  SELECT
  file_id,check_file_id,
  server_type_admin_flag,
  server_type_forms_flag,
  server_type_node_flag,
  server_type_web_flag
  FROM  ad_check_file_temp;
--
--
--
--
cur_rec c1%ROWTYPE;
rows   NATURAL := 2000;
--
--
begin

   ad_file_util.error_buf := 'load_snpst_file_server_info(cursor: '||
                             'select file_id,check_file_id,server_type_admin_flag, '||
                             'server_type_forms_flag, server_type_node_flag, '||
                             'server_type_web_flag from '||
                             'ad_check_file_temp):(';
--
   begin
     OPEN c1;
   exception
     when others then
       ad_file_util.error_buf := ad_file_util.error_buf||sqlerrm||')';
     raise;
   end;
--
--
  LOOP
--
--
--
  FETCH c1 BULK COLLECT INTO
  fl_id_list ,con_file_id_list,
  admin_server_flag_list, forms_server_flag_list,
  node_server_flag_list, web_server_flag_list
  LIMIT rows;
--
--
    if   fl_id_list.COUNT > 0 then
--
--
--
  FORALL j IN fl_id_list.FIRST.. fl_id_list.LAST
    update
       ad_snapshot_files snap
    set
           snap.server_type_admin_flag = admin_server_flag_list(j),
           snap.server_type_forms_flag = forms_server_flag_list(j),
           snap.server_type_node_flag = node_server_flag_list(j),
           snap.server_type_web_flag = web_server_flag_list(j)
    where
          snap.snapshot_id=snp_id   and
          snap.file_id    =fl_id_list(j)         and
          nvl(snap.containing_file_id,-1)=nvl(con_file_id_list(j),-1);
--
--
     end if;
--
--

    EXIT WHEN c1%NOTFOUND;
--
--
--
  END LOOP;
--
--
--
   begin
     close c1;
   exception
     when others then
     ad_file_util.error_buf := 'load_snpst_file_server_info(Close cursor):('||
                               sqlerrm||')';
   end;

--
--
--
end load_snpst_file_server_info;
--
--

end ad_file_util;
