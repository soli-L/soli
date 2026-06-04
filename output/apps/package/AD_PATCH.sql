
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PATCH" AUTHID CURRENT_USER as
/* $Header: adphpchs.pls 120.5 2007/12/14 13:09:13 diverma ship $ */

/* Public constants for AOL or any caller to use, as well */

NOT_APPLIED   CONSTANT varchar2(30) := 'NOT_APPLIED';
IMPLICITLY_APPLIED   CONSTANT varchar2(30) := 'IMPLICIT';
EXPLICITLY_APPLIED   CONSTANT varchar2(30) := 'EXPLICIT';
MANUALLY_APPLIED   CONSTANT varchar2(30) := 'MANUAL';
AD_UNKNOWN   CONSTANT varchar2(30) := 'UNKNOWN';
AD_FILES_ONLY   CONSTANT varchar2(30) := 'FILES_ONLY';

function  is_patch_applied (p_release_name  in varchar2,
                            p_appl_top_id   in number,
                            p_bug_number    in varchar2,
                            p_bug_language  in varchar2)
                            return varchar2;

function  is_patch_applied (p_release_name  in varchar2,
                            p_appl_top_id   in number,
                            p_bug_number    in varchar2)
                            return varchar2;

function  is_codeline_patch_applied (p_release_name in varchar2,
                                p_baseline_name in varchar2,
                                p_appl_top_id in number,
                                p_bug_number in varchar2 )
                                return varchar2;

function is_codeline_patch_applied ( p_release_name in varchar2,
                                     p_baseline_name  in varchar2,
                                     p_appl_top_id   in number,
                                     p_bug_number    in varchar2,
                                     p_language     in varchar2)
                                    return varchar2;

function is_file_copied (p_application_short_name in varchar2,
                         p_appl_top_id in number,
                         p_object_location in varchar2,
                         p_object_name in varchar2,
                         p_object_version in varchar2)
                         return varchar2;

procedure mark_patch_succ(p_patch_run_id in NUMBER ,
                          p_appl_top_id in number,
                          p_release_name in varchar2,
                          p_flag in varchar2,
                          p_reason_text in varchar2);

procedure mark_bug_succ(p_patch_run_id in NUMBER ,
                        p_appl_top_id in number,
                        p_release_name in varchar2,
                        p_bug_number in varchar2,
                        p_flag in varchar2,
                        p_reason_text in varchar2);

procedure set_patch_status(p_release_name in varchar2,
                           p_appl_top_id in number,
                           p_bug_number in varchar2,
                           p_bug_status in varchar2);

function getAppltopID(p_appl_top_name in varchar2,
                      p_app_sys_name in varchar2,
                      p_appl_top_type in varchar2)
                      return number;

/*****************************************************************************
  Compare passed versions of files to determine which is greater,
  the one requested by caller or the one in database.

  Returns:
    Returns TRUE if p_version_indb >= p_version.
*****************************************************************************/
function compare_versions(p_version      in varchar2,
                          p_version_indb in varchar2)
         return boolean;

end ad_patch;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PATCH" as
/* $Header: adphpchb.pls 120.12.12020000.5 2014/10/14 09:49:03 seetsing ship $ */

  VER_SEPARATOR           CONSTANT varchar2(1)  := '.';
  CURRENT_VIEW_SNP_NAME   CONSTANT varchar2(12) := 'CURRENT_VIEW';
  GLOBAL_VIEW_SNP_NAME	  CONSTANT varchar2(11) := 'GLOBAL_VIEW';
  g_errm                    varchar2(132);

/**************************************************************************
      Returns whether or not the patch has been applied.

      release_name - the aru release name (e.g., '11i')
      bug_number - the bug number (e.g., '1234567')

      returns
      NOT_APPLIED, IMPLICITLY_APPLIED, or EXPLICITLY_APPLIED
**************************************************************************/

/**************************************************************************
    New version to go with new proposed data model changes (11.5.6 maybe),
    resulting in simpler joins. This function queries on AD_SNAPSHOT_BUGFIXES
    bug_status column to report the status of a bug.
    With the snapshot project, and changes to the patch history data
    model, the bug_status column is moved to ad_snapshot_bugfixes and hence
    the query has to join on ad_snapshots,ad_snapshot_bugfixes and ad_bugs
    tables.
    2/15/02 : app_short_name is moved from AD_BUGS to AD_PATCH_RUN_BUGS
              due to AOL's requirement, since  AOL doesn't always know
              app_short_name to pass.
**************************************************************************/
function  is_patch_applied (p_release_name  in varchar2,
                            p_appl_top_id   in number,
                            p_bug_number    in varchar2)
          return varchar2
is
begin

  return is_patch_applied(p_release_name, p_appl_top_id,
                          p_bug_number, 'US');
end is_patch_applied;

function  is_patch_applied (p_release_name  in varchar2,
                            p_appl_top_id   in number,
                            p_bug_number    in varchar2,
                            p_bug_language  in varchar2)
          return varchar2
is
  cursor FIND_BUG_ID_CURSOR is
    select b.bug_id
      from AD_BUGS b, AD_TRACKABLE_ENTITIES adte
     where b.bug_number = p_bug_number
       and upper(b.trackable_entity_abbr) =
               DECODE(UPPER(adte.abbreviation(+)),'SO', 'SQLSO',
                                                  'FA', 'OFA',
                                                  'AP', 'SQLAP',
                                                  'GL', 'SQLGL',
                                                  UPPER(adte.abbreviation(+)))
       and b.language = p_bug_language
       and ( b.baseline_name = adte.baseline
            or b.generic_patch = 'y'
           );

  l_bugst       ad_snapshot_bugfixes.bug_status%type;
  l_bugid       ad_bugs.bug_id%type;
  l_snapshot_id ad_snapshots.snapshot_id%type;

  l_row_found   boolean := TRUE;
begin

  if (p_bug_number in ('13839836', '13839844', '14100919', '16399723'))
  then
      return(NOT_APPLIED);
  end if;

  if (p_appl_top_id = -1)
  then
    begin
      select s.snapshot_id into l_snapshot_id
      from AD_SNAPSHOTS s, AD_APPL_TOPS a,
           FND_PRODUCT_GROUPS fpg
      where s.snapshot_name = GLOBAL_VIEW_SNP_NAME
      and s.snapshot_type =
           ad_file_sys_snapshots_pkg.get_snapshot_type(GLOBAL_VIEW_SNP_NAME)
      and s.appl_top_id = a.appl_top_id
      and a.name = 'GLOBAL'
      and a.appl_top_type = 'G'
      and a.applications_system_name = fpg.applications_system_name
      and fpg.product_group_id=1;
      exception
        when no_data_found then
          return(NOT_APPLIED);
    end;
  else
    begin
      select snapshot_id into l_snapshot_id
      from AD_SNAPSHOTS
      where appl_top_id = p_appl_top_id
      and snapshot_name = CURRENT_VIEW_SNP_NAME
      and snapshot_type =
         ad_file_sys_snapshots_pkg.get_snapshot_type(CURRENT_VIEW_SNP_NAME);
      exception
        when no_data_found then
          return(NOT_APPLIED);
    end;
  end if;

  begin
    for cur_bugid in FIND_BUG_ID_CURSOR loop
      l_row_found := TRUE;
      begin
        select bug_status into l_bugst
          from ad_snapshot_bugfixes
         where bugfix_id = cur_bugid.bug_id
           and snapshot_id = l_snapshot_id;
      exception
        when no_data_found then
          l_row_found := FALSE;
      end;
      if (l_row_found) then
        if (not l_bugst = NOT_APPLIED) then
          -- if a row was found and the
          -- bug_status is other than 'NOT_APPLIED'
          -- return this status
          return(l_bugst);
        end if;
      end if;
    end loop;

    -- either no row was found or bug_status = 'NOT_APPLIED'
    -- for all the rows that were found when we reach this point
    return (NOT_APPLIED);
  end;
end is_patch_applied;
/**************************************************************************
      Analyuzes  whether or not the codeline patch has been applied.

      release_name - the aru release name - 'R12'
      baseline_name - baseline value -   (eg., 'A',B',R12')
      appl_top_id  - id of appl top.( eg., -1, 123 )
      bug_number - the bug number (e.g., '1234567')
      langauage - the language of the patch (e.g. 'D', 'US' )

      returns
      NOT_APPLIED, IMPLICITLY_APPLIED, or EXPLICITLY_APPLIED
**************************************************************************/


function is_codeline_patch_applied ( p_release_name in varchar2,
                                     p_baseline_name  in varchar2,
                                     p_appl_top_id   in number,
                                     p_bug_number    in varchar2)
          return varchar2
is
begin

  return is_codeline_patch_applied ( p_release_name, p_baseline_name,
                                     p_appl_top_id, p_bug_number,
                                     'US');
end is_codeline_patch_applied;


function is_codeline_patch_applied ( p_release_name in varchar2,
                                     p_baseline_name  in varchar2,
                                     p_appl_top_id   in number,
                                     p_bug_number    in varchar2,
                                     p_language     in varchar2)
          return varchar2
is
    l_snapshot_id ad_snapshots.snapshot_id%type;
    l_bug_id ad_bugs.bug_id%type;
    l_bugst ad_snapshot_bugfixes.bug_status%type;
BEGIN

  if (p_appl_top_id = -1)
  then
    begin
      select s.snapshot_id into l_snapshot_id
      from AD_SNAPSHOTS s, AD_APPL_TOPS a,
           FND_PRODUCT_GROUPS fpg
      where s.snapshot_name = GLOBAL_VIEW_SNP_NAME
      and s.snapshot_type =
           ad_file_sys_snapshots_pkg.get_snapshot_type(GLOBAL_VIEW_SNP_NAME)
      and s.appl_top_id = a.appl_top_id
      and a.name = 'GLOBAL'
      and a.appl_top_type = 'G'
      and a.applications_system_name = fpg.applications_system_name
      and fpg.product_group_id=1;
      exception
        when no_data_found then
          return(NOT_APPLIED);
    end;
  else
    begin
      select snapshot_id into l_snapshot_id
      from AD_SNAPSHOTS
      where appl_top_id = p_appl_top_id
      and snapshot_name = CURRENT_VIEW_SNP_NAME
      and snapshot_type =
         ad_file_sys_snapshots_pkg.get_snapshot_type(CURRENT_VIEW_SNP_NAME);
      exception
        when no_data_found then
          return(NOT_APPLIED);
    end;
  end if;

  begin
    select b.bug_id into l_bug_id
      from AD_BUGS b
      where b.bug_number = p_bug_number
      and   b.baseline_name = p_baseline_name
      and   b.aru_release_name = p_release_name
      and   b.language   = p_language;
   exception
      when no_data_found then
          return(NOT_APPLIED);
  end;


  begin
    select bug_status into l_bugst
       from ad_snapshot_bugfixes
       where bugfix_id = l_bug_id
       and snapshot_id = l_snapshot_id;
     exception
        when no_data_found then
        return (NOT_APPLIED);
  end;

  return l_bugst;

END is_codeline_patch_applied ;


/*****************************************************************************
  Compare passed versions of files to determine which is greater,
  the one requested by caller or the one in database.
*****************************************************************************/
function compare_versions(p_version      in varchar2,
                          p_version_indb in varchar2)
         return boolean
is
  db_ver     number;
  passed_ver number;
  passed_len number;
  db_ver_len number;
  l_ver_str  varchar2(132) ;
  db_ver_str varchar2(132) ;
  ret_status boolean       := TRUE;
begin
  l_ver_str   := p_version||'.';
  db_ver_str  := p_version_indb||'.';

-- Version format is  a.b.c.e...x
-- parse out a version from the passed in version (p_version)

  while l_ver_str is not null or db_ver_str is not null loop
    if (l_ver_str is null)
    then
      passed_ver := 0;
    else
      passed_ver  := nvl(to_number(substr(l_ver_str,1,instr(l_ver_str,'.')-1)),
                        -1);
      l_ver_str := substr(l_ver_str,instr(l_ver_str,'.')+1);
    end if;

    -- Next parse out a version from the db_version (p_version_indb)

    if (db_ver_str is null)
    then
      db_ver := 0;
    else
       db_ver := nvl(to_number(substr(db_ver_str,1,instr(db_ver_str,'.')-1)),
                     -1);
       db_ver_str := substr(db_ver_str,instr(db_ver_str,'.')+1);
    end if;

    -- If passed file ver is greater than version in DB, then ret FALSE

    if (passed_ver > db_ver)
    then
      ret_status := FALSE;
      exit; /* get out of the loop, we're done. */

    -- If passed file ver is less than version in DB, then ret TRUE

    elsif (passed_ver < db_ver)
    then
      exit; /* get out of the loop, we're done. */
    end if;

-- Continue looping only if sub string versions are equal, i.e
-- compraing 115.2.1151.2 - 115.42, second time thru the loop should
-- exit with a ret_status, since 2 and 42 are not equal.

  end loop;

  return(ret_status);

end compare_versions;

/***********************************************************************
  Find max version of the passed file that was applied to the
  system. Not just any max version of the passed file in patch hist tables.
  For is_file_copied, the relevant question is "does the file with a
  specific version or higher, exists on the file system" ?
  Not whether it was explicitly copied or not by a patch.
  And for that, just a file with a exact or higher version in
  ad_snapshot_files is sufficient.
***********************************************************************/

function find_max_applied_version_indb(p_file_id     in number,
                                       p_snapshot_id in number)
         return varchar2
is
  cursor MAX_VER_CUR(p_file_id in ad_files.file_id%TYPE) is
  select v.version
  from ad_file_versions v, ad_snapshot_files s
  where s.file_id = v.file_id
  and s.file_id = p_file_id
  and s.snapshot_id = p_snapshot_id
  and v.file_version_id = s.file_version_id;

  max_ver ad_file_versions.version%TYPE ;
  old_ver ad_file_versions.version%TYPE ;
  ret     boolean                       := FALSE;
begin
  max_ver  := '0';
  old_ver  := '0';

  for max_ver_cur_rec in MAX_VER_CUR(p_file_id) loop
    ret := compare_versions(max_ver_cur_rec.version,old_ver);
    if (ret = FALSE) then
      max_ver := max_ver_cur_rec.version;
    end if;
    old_ver := max_ver_cur_rec.version;
  end loop;

  return(max_ver);

end find_max_applied_version_indb;


/*************************************************************************
  is_file_copied()
  This function returns whether a given file with a subdir and version
  passed, was already applied to an appl_top. The return value is either
  NOT_APPLIED or EXPLICITLY_APPLIED.
*************************************************************************/
function is_file_copied (p_application_short_name in varchar2,
                         p_appl_top_id            in number,
                         p_object_location        in varchar2,
                         p_object_name            in varchar2,
                         p_object_version         in varchar2)
         return varchar2
is
  l_file_id     ad_files.file_id%TYPE;
  l_snapshot_id ad_snapshots.snapshot_id%TYPE;
  l_ver         ad_file_versions.version%TYPE;
  l_dbver       ad_file_versions.version%TYPE;
  max_ver_indb  ad_file_versions.version%TYPE;
  ret           boolean := FALSE;

  cursor FILE_VER_CUR(p_file_id in ad_files.file_id%TYPE) is
  select executed_flag
  from ad_patch_run_bug_actions
  where file_id = p_file_id
  and patch_file_version_id in (select file_version_id
                                from ad_file_versions
                                where file_id = p_file_id
                                and version = max_ver_indb);
begin

  l_ver := rtrim(p_object_version);

  -- First get the snapshot_id, from the given appl_top_id to work on.
  if (p_appl_top_id = -1)
  then
    begin
      select s.snapshot_id into l_snapshot_id
      from AD_SNAPSHOTS s, AD_APPL_TOPS a,
           FND_PRODUCT_GROUPS fpg
      where s.snapshot_name = GLOBAL_VIEW_SNP_NAME
      and s.snapshot_type =
           ad_file_sys_snapshots_pkg.get_snapshot_type(GLOBAL_VIEW_SNP_NAME)
      and s.appl_top_id = a.appl_top_id
      and a.name = 'GLOBAL'
      and a.appl_top_type = 'G'
      and a.applications_system_name = fpg.applications_system_name
      and fpg.product_group_id=1;
      exception
        /*bug 2770858 Do not rollback and do not raise exception*/
        when no_data_found then
          return(NOT_APPLIED);
    end;
  else
    begin
      select snapshot_id into l_snapshot_id
      from AD_SNAPSHOTS
      where appl_top_id = p_appl_top_id
      and snapshot_name = CURRENT_VIEW_SNP_NAME
      and snapshot_type =
        ad_file_sys_snapshots_pkg.get_snapshot_type(CURRENT_VIEW_SNP_NAME);
      exception
        /*bug 2770858 Do not rollback and do not raise exception*/
        when no_data_found then
          return(NOT_APPLIED);
    end;
   end if;

  begin
    select file_id into l_file_id
    from ad_files
    where app_short_name = p_application_short_name
    and subdir = p_object_location
    and filename = p_object_name;
    exception
      when no_data_found then
        return(NOT_APPLIED);
  end;

  -- Find the max applied version of the passed file in db.
  max_ver_indb := find_max_applied_version_indb(l_file_id,l_snapshot_id);

  -- Compare the version of the passed file and the version of the file
  -- that exists in the database to return if file is copied explicitly or
  -- not

  ret := compare_versions(l_ver,max_ver_indb);

  if (ret = TRUE) then
    return(EXPLICITLY_APPLIED);
  end if;

  -- If you are here means the file with the specific version was not
  -- applied, and hence return not applied.

  return(NOT_APPLIED);

end is_file_copied;



/*************************************************************************
  cascade update AD_SNAPSHOT_BUGFIXES based on the values in AD_PATCH_RUN_BUGS.
    - Don't update AD_SNAPSHOT_BUGFIXES at all if already set to the value
      being updated.
    - When updating to successful, just mark row in AD_SNAPSHOT_BUGFIXES
      as successful.
    - When updating to unsuccessful, only mark row in AD_SNAPSHOT_BUGFIXES
      as not successful if there are no rows in AD_PATCH_RUN_BUGS marked as
      successful for the bug, product, and aru_release.
      This routine updates AD_SNAPSHOT_BUGFIXES for given a patch_run_id and
      a flag.
*************************************************************************/
procedure mark_patch_bug_in_snpbgfix(p_appl_top_id  in number,
                                     p_patch_run_id in number,
                                     p_flag         in varchar2)
is
  l_snapshot_id AD_SNAPSHOTS.snapshot_id%type;

  cursor BUG_ID_CUR is
  select bug_id
  from AD_PATCH_RUN_BUGS
  where patch_run_id = p_patch_run_id;

  cursor FIND_SUCC_CUR(p_bug_id in ad_bugs.bug_id%type) is
  select success_flag
  from AD_PATCH_RUN_BUGS
  where patch_run_id <> p_patch_run_id
  and bug_id = p_bug_id;

  no_update boolean := FALSE;

begin

  begin
    select snapshot_id into l_snapshot_id
    from AD_SNAPSHOTS
    where appl_top_id = p_appl_top_id
    and snapshot_name = CURRENT_VIEW_SNP_NAME
    and snapshot_type =
        ad_file_sys_snapshots_pkg.get_snapshot_type(CURRENT_VIEW_SNP_NAME);
    exception
      when no_data_found then
 /* bug 2770858 Do not rollback */
        return;
  end;


  if (p_flag = 'Y') then
    begin
      update AD_SNAPSHOT_BUGFIXES
      set success_flag = p_flag
      where snapshot_id = l_snapshot_id
      and bugfix_id in (select bug_id from AD_PATCH_RUN_BUGS
                        where patch_run_id = p_patch_run_id);
      exception when others then
        g_errm := sqlerrm;
        raise_application_error(-20001, g_errm ||
              'Error occurred in mark_patch_bug_in_snpbgfix() '||
              'while trying to update success_flag to Y '||
              ' in AD_SNAPSHOT_BUGFIXES '||
              'for patch_run_id =  ' || p_patch_run_id);
    end;
  elsif (p_flag = 'N') then
    for mybugid in BUG_ID_CUR loop
      for succ_rec in FIND_SUCC_CUR(mybugid.bug_id) loop
          if (succ_rec.success_flag = 'Y') then
            no_update := TRUE;
            exit;
          end if;
      end loop;
      if (no_update = FALSE) then
        begin
          update AD_SNAPSHOT_BUGFIXES
          set success_flag = p_flag
          where bugfix_id = mybugid.bug_id
          and snapshot_id = l_snapshot_id;
          exception when others then
            g_errm := sqlerrm;
            raise_application_error(-20001, g_errm ||
                  'Error occurred in mark_patch_bug_in_snpbgfix() '||
                  'while trying to update success_flag to N '||
                  ' in AD_SNAPSHOT_BUGFIXES '||
                  'for patch_run_id =  ' || p_patch_run_id);
        end;
      end if;
    no_update := FALSE;
    end loop;
  else
    raise_application_error(-20000,'Value for success_flag passed "'||
                                p_flag ||'" is invalid');
  end if;
end mark_patch_bug_in_snpbgfix;

/*************************************************************************
  cascade update AD_SNAPSHOT_BUGFIXES based on the values in AD_PATCH_RUN_BUGS.
    - Don't update AD_SNAPSHOT_BUGFIXES at all if already set to the value
      being updated.
    - When updating to successful, just mark row in AD_SNAPSHOT_BUGFIXES
      as successful.
    - When updating to unsuccessful, only mark row in AD_SNAPSHOT_BUGFIXES
      as not successful if there are no rows in AD_PATCH_RUN_BUGS marked as
      successful for the bug, product, and aru_release.
      This routine updates AD_SNAPSHOT_BUGFIXES, given a patch_run, bug id.
*************************************************************************/
procedure mark_bug_in_snpbgfix(p_patch_run_id in number,
                               p_appl_top_id  in number,
                               p_bug_id       in number,
                               p_flag         in varchar2)
is
  l_bug_id      ad_bugs.bug_id%TYPE;
  l_snapshot_id AD_SNAPSHOTS.snapshot_id%type;

  cursor FIND_SUCC_CUR(p_bug_id in ad_bugs.bug_id%type) is
  select success_flag
  from AD_PATCH_RUN_BUGS
  where patch_run_id <> p_patch_run_id
  and bug_id = p_bug_id;

  no_update boolean := FALSE;

begin

  begin
    select snapshot_id into l_snapshot_id
    from AD_SNAPSHOTS
    where appl_top_id = p_appl_top_id
    and snapshot_name = CURRENT_VIEW_SNP_NAME
    and snapshot_type =
      ad_file_sys_snapshots_pkg.get_snapshot_type(CURRENT_VIEW_SNP_NAME);
    exception
      when no_data_found then
    /* bug 2770858 Do not rollback */
      return;
  end;

  if (p_flag = 'Y') then
    begin
      update AD_SNAPSHOT_BUGFIXES
      set success_flag = p_flag
      where bugfix_id = p_bug_id
      and snapshot_id = l_snapshot_id;
      exception when others then
        g_errm := sqlerrm;
        raise_application_error(-20001, g_errm ||
              'Error occurred in mark_bug_in_snpbgfix() '||
              'while trying to update success_flag to Y '||
              ' in AD_SNAPSHOT_BUGFIXES '||
              'for patch_run_id =  ' || p_patch_run_id);
    end;
  elsif (p_flag = 'N') then
    for succ_rec in FIND_SUCC_CUR(p_bug_id) loop
      if (succ_rec.success_flag = 'Y') then
        no_update := TRUE;
        exit;
      end if;
    end loop;
    if (no_update = FALSE) then
      begin
        update AD_SNAPSHOT_BUGFIXES
        set success_flag = p_flag
        where bugfix_id = p_bug_id
        and snapshot_id = l_snapshot_id;
        exception when others then
          g_errm := sqlerrm;
          raise_application_error(-20001, g_errm ||
                'Error occurred in mark_bug_in_snpbgfix() '||
                'while trying to update success_flag to N '||
                ' in AD_SNAPSHOT_BUGFIXES '||
                'for patch_run_id =  ' || p_patch_run_id);
      end;
    end if;
    no_update := FALSE;
  else
    raise_application_error(-20000,'Value for success_flag passed "'||
                                p_flag ||'" is invalid');
  end if;
end mark_bug_in_snpbgfix;

/*****************************************************************************
  Mark patch runs as successful or unsuccessful, in a given appl_top_id,
  cascading to ad_patch_run_bugs and ad_bugs. This procedure will use
  patch_run_id, which would be selected via another layer of sql report that
  the user would run to list all patch_run_ids for a given patch_name,
  appl_top_id and a date.
*****************************************************************************/

procedure mark_patch_succ(p_patch_run_id in NUMBER ,
                          p_appl_top_id  in number,
                          p_release_name in varchar2,
                          p_flag         in varchar2,
                          p_reason_text  in varchar2)
is

begin

  begin
    update AD_PATCH_RUNS
    set success_flag = p_flag, failure_comments = p_reason_text
    where patch_run_id = p_patch_run_id;
    exception when others then
      g_errm := sqlerrm;
      raise_application_error(-20001, g_errm ||
            'Error occurred in mark_patch_succ() '||
            'while trying to update success_flag '||
            'in AD_PATCH_RUNS '||
            'for patch_run_id =  ' || p_patch_run_id);
  end;

  begin
    update AD_PATCH_RUN_BUGS
    set success_flag = p_flag, failure_comments = p_reason_text
    where patch_run_id = p_patch_run_id;
    exception when others then
      g_errm := sqlerrm;
      raise_application_error(-20001, g_errm ||
            'Error occurred in mark_patch_succ() '||
            'while trying to update success_flag '||
            'in AD_PATCH_RUN_BUGS '||
            'for patch_run_id =  ' || p_patch_run_id);
  end;

  mark_patch_bug_in_snpbgfix(p_appl_top_id,p_patch_run_id,p_flag);

end mark_patch_succ;


/*************************************************************************
  are_all_bugs_for_patch_succ(p_patch_run_id);
  Go thru all the bug_id's for the given patch_run_id in ad_patch_run_bugs
  to get all the bugs for a given patch and check if all the bugs have
  success_flag set to 'Y' or 'N' and return true or false accordingly.
*************************************************************************/
function are_all_bugs_for_patch_succ(p_patch_run_id in
                                      ad_patch_runs.patch_run_id%TYPE)
         return boolean
is
  l_flag varchar2(1);
begin

  begin
    select success_flag into l_flag
    from AD_PATCH_RUN_BUGS
    where patch_run_id = p_patch_run_id
    and success_flag = 'N';
    exception
      when no_data_found then
        return(TRUE);
  end;

  -- If you are here means one or more records had success_flag = 'N' and
  -- hence need to return a FALSE.

  return(FALSE);

end are_all_bugs_for_patch_succ;

/*************************************************************************
  Given a patch_run_id and a bug number, mark the bug as successful or
  unsuccessful and cascade to ad_patch_runs and ad_bugs in the following
  manner:
    - update AD_PATCH_RUN_BUGS for the specified patch run and bug
    - Also update AD_PATCH_RUNS in the following cases:
        - if updating bug to successful and all other bugs for this patch run
          are successful and patch run marked as unsuccessful, update patch run
          to successful.
        - if updating bug to unsuccessful and patch run marked
          as successful, update patch run to unsuccessful.
    -  cascade update AD_BUGS as described above based on values in
      AD_PATCH_RUN_BUGS.
*************************************************************************/

procedure mark_bug_succ(p_patch_run_id in NUMBER ,
                        p_appl_top_id  in number,
                        p_release_name in varchar2,
                        p_bug_number   in varchar2,
                        p_flag         in varchar2,
                        p_reason_text  in varchar2)
is
  l_bug_id     ad_bugs.bug_id%TYPE;
  l_patch_succ ad_snapshot_bugfixes.success_flag%TYPE;

begin

  -- get bug id from ad_bugs for the passed bug number and aru_release_name.

  begin
    select bug_id into l_bug_id
    from AD_BUGS
    where bug_number = p_bug_number
    and aru_release_name = p_release_name;
    exception
      when no_data_found then
        raise_application_error(-20000,'Bug number '||p_bug_number||
                          ' does not exist'||' in patch history tables!!');
        return;
      when too_many_rows then
        raise_application_error(-20001,
                              'Too many rows returned for bug '|| p_bug_number);
        return;
  end;


  /* Case I:
     update ad_patch_runs for the specified patch run and bug.
  */

  begin
    update AD_PATCH_RUN_BUGS
    set success_flag = p_flag, failure_comments = p_reason_text
    where patch_run_id = p_patch_run_id and
    bug_id = l_bug_id;
    exception when others then
      g_errm := sqlerrm;
      raise_application_error(-20001, g_errm ||
            'Error occurred in mark_bug_succ() '||
            'while trying to update case I success_flag '||
            'in AD_PATCH_RUNS '||
            'for patch_run_id =  ' || p_patch_run_id);
    end;

  /* Case II:
     update ad_patch_runs in the following manner.
      1.if updating bug to successful and all other bugs for this patch run
        are successful and patch run marked as unsuccessful, update patch run
        to successful.
  */

  begin
    select success_flag into l_patch_succ
    from AD_PATCH_RUNS
    where patch_run_id = p_patch_run_id;
  exception
    when no_data_found then
    /* bug 2770858 Do not rollback */
      return;
  end;

  if (p_flag = 'Y' and
      are_all_bugs_for_patch_succ(p_patch_run_id) = TRUE and
      l_patch_succ = 'N') then

    begin
      update AD_PATCH_RUNS
      set success_flag = p_flag, failure_comments = p_reason_text
      where patch_run_id = p_patch_run_id;
      exception when others then
        g_errm := sqlerrm;
        raise_application_error(-20001, g_errm ||
              'Error occurred in mark_bug_succ() '||
              'while trying to update case II success_flag '||
              'in AD_PATCH_RUNS '||
              'for patch_run_id =  ' || p_patch_run_id);
    end;

 -- case III. if updating bug to unsuccessful and patch run marked
 -- as successful, update patch run to unsuccessful.

  elsif (p_flag = 'N' and l_patch_succ = 'Y')  then

    begin
      update AD_PATCH_RUNS
      set success_flag = p_flag, failure_comments = p_reason_text
      where patch_run_id = p_patch_run_id;
      exception when others then
        g_errm := sqlerrm;
        raise_application_error(-20001, g_errm ||
              'Error occurred in mark_bug_succ() '||
              'while trying to update case III success_flag '||
              'in AD_PATCH_RUNS '||
              'for patch_run_id =  ' || p_patch_run_id);
    end;

  end if;

  -- Case IV:
  -- cascade update AD_SNAPSHOT_BUGFIXES just like in mark_patch_succ
  -- above based on values in AD_PATCH_RUN_BUGS.

  mark_bug_in_snpbgfix(p_patch_run_id,p_appl_top_id,l_bug_id,p_flag);

end mark_bug_succ;


/*******************************************************************************
  - set patch application status.
  - arguments include:
    - aru_release_name (e.g., 11i)
    - bug_number (eg., '1234567')
    - application_status, the patch application status (e.g.,IMPLICITLY_APPLIED)
    - appl_top_id, to know which appl_top, user is requesting patch status for.

    2/15/02 : app_short_name is moved from AD_BUGS to AD_PATCH_RUN_BUGS
              due to AOL's requirement, since  AOL doesn't always know
              app_short_name to pass.
*******************************************************************************/
procedure set_patch_status(p_release_name in varchar2,
                           p_appl_top_id     number,
                           p_bug_number   in varchar2,
                           p_bug_status   in varchar2)
is
  l_bug_id          ad_bugs.bug_id%TYPE;
  l_snapshot_id     ad_snapshots.snapshot_id%TYPE;
  l_snapshot_bug_id ad_snapshot_bugfixes.snapshot_bug_id%TYPE;

begin

  -- CASE I: On create, when there are no entries in AD_BUGS for the
  -- passed bug_number, aru_release_name. create a row in AD_BUGS and
  -- AD_SNAPSHOT_BUGFIXES.

  -- First get the snapshot_id, from the given appl_top_id to work on.

  if (p_appl_top_id = -1)
  then
    begin
      select s.snapshot_id into l_snapshot_id
      from AD_SNAPSHOTS s, AD_APPL_TOPS a,
           FND_PRODUCT_GROUPS fpg
      where s.snapshot_name = GLOBAL_VIEW_SNP_NAME
      and s.snapshot_type =
           ad_file_sys_snapshots_pkg.get_snapshot_type(GLOBAL_VIEW_SNP_NAME)
      and s.appl_top_id = a.appl_top_id
      and a.name = 'GLOBAL'
      and a.appl_top_type = 'G'
      and a.applications_system_name = fpg.applications_system_name
      and fpg.product_group_id=1;
      exception
        /* bug 2770858 Do not rollback */
        when no_data_found then
          return;
    end;
  else
    begin
      select snapshot_id into l_snapshot_id
      from AD_SNAPSHOTS
      where appl_top_id = p_appl_top_id
      and snapshot_name = CURRENT_VIEW_SNP_NAME
      and snapshot_type =
           ad_file_sys_snapshots_pkg.get_snapshot_type(CURRENT_VIEW_SNP_NAME);
      exception
        when no_data_found then
        /* bug 2770858 Do not rollback */
          return;
    end;
  end if;

  begin
    select bug_id into l_bug_id
    from AD_BUGS
    where bug_number = p_bug_number
    and aru_release_name = p_release_name;
    exception
      when no_data_found then

      -- Insert a new record

        select ad_bugs_s.nextval into l_bug_id from dual;

        begin
          insert into AD_BUGS
          (bug_id, bug_number,
          creation_date, aru_release_name,
          last_update_date, last_updated_by,created_by)
          values(l_bug_id,
                 p_bug_number,
                 sysdate,
                 p_release_name,
                 sysdate,
                 -1,
                 -1);
          exception
            when dup_val_on_index then
              raise_application_error(-20001,
                   'Attempting to insert a duplicate record '||
                   'into AD_BUGS for bug_number =  '||
                   p_bug_number || ' and release '||
                   p_release_name);

            when others then
              g_errm := sqlerrm;
              raise_application_error(-20001, g_errm ||
                    'Error occurred in set_patch_status() '||
                    'while trying to insert new record '||
                    'into AD_BUGS for bug_number =  '||
                    p_bug_number || ' and release '||
                    p_release_name);
        end;
  end;

  begin
    select snapshot_bug_id into l_snapshot_bug_id
    from AD_SNAPSHOT_BUGFIXES
    where bugfix_id = l_bug_id
    and snapshot_id = l_snapshot_id;
    exception
      when no_data_found then
        -- create an entry in AD_SNAPSHOT_BUGFIXES
        begin
          insert into AD_SNAPSHOT_BUGFIXES
          (snapshot_bug_id,
           snapshot_id,
           bugfix_id,
           bug_status,
           success_flag,
           creation_date,
           last_update_date,
           last_updated_by,
           created_by)
           values (ad_snapshot_bugfixes_s.nextval,
                   l_snapshot_id,
                   l_bug_id,
                   p_bug_status,
                   'Y',
                   sysdate,
                   sysdate,
                   -1,
                   -1);
           exception
             when dup_val_on_index then
               raise_application_error(-20001,
                    'Attempting to insert a duplicate record '||
                    'into AD_SNAPSHOT_BUGFIXES for bug_number =  '||
                    p_bug_number || ' and release '||
                    p_release_name);

             when others then
               g_errm := sqlerrm;
               raise_application_error(-20001, g_errm ||
                     'Error occurred in set_patch_status() '||
                     'while trying to insert new record '||
                     'into AD_SNAPSHOT_BUGFIXES for bug_number =  '||
                     p_bug_number || ' and release '||
                     p_release_name);
        end;

      when too_many_rows then
      /* bug 2770858 Do not rollback */
        raise_application_error(-20001,
                'Too many rows in AD_SNAPSHOT_BUGFIXES '||
                'table for '||p_bug_number||
                ' '||p_release_name);
  end;

  -- If you are here means there was a record in AD_BUGS and
  -- AD_SNAPSHOT_BUGFIXES.
  -- So just update the existing record.

  begin
    update AD_SNAPSHOT_BUGFIXES
    set BUG_STATUS = p_bug_status, success_flag = 'Y', last_updated_by = -1,
    last_update_date = sysdate
    where bugfix_id = l_bug_id and
    snapshot_id = l_snapshot_id;
    exception when others then
      g_errm := sqlerrm;
      raise_application_error(-20001, g_errm ||
            'Error occurred in set_patch_status() '||
            'while trying to update bug_status '||
            'in AD_SNAPSHOT_BUGFIXES '||
            'for bug_id =  ' || l_bug_id);
  end;

end set_patch_status;

/*******************************************************************************
  getAppltopID()

  This function returns an appl_top_id to the caller given the appl_top name,
  and optionally an Applications System name and/or APPL_TOP type.
  1. If APPL_TOP type not specified, it defaults to a normal APPL_TOP
     i.e 'R'
  2. If Applications Sytem name not specified, it defaults to the value in
     FND_PRODUCT_GROUPS.

*******************************************************************************/

function getAppltopID(p_appl_top_name in varchar2,
                      p_app_sys_name  in varchar2,
                      p_appl_top_type in varchar2)
         return number
is
  l_app_sys_name  ad_appl_tops.applications_system_name%TYPE;
  l_appl_top_type ad_appl_tops.appl_top_type%TYPE;
  l_appl_top_id   ad_appl_tops.appl_top_id%TYPE;
begin

  select decode(upper(p_appl_top_type),'','R',
                upper(p_appl_top_type))
  into l_appl_top_type
  from dual;

  if ((upper(p_app_sys_name)) is null) then
    select applications_system_name into l_app_sys_name
    from FND_PRODUCT_GROUPS;
  else
    l_app_sys_name := p_app_sys_name;
  end if;

  begin
    select appl_top_id into l_appl_top_id
    from AD_APPL_TOPS
    where name = p_appl_top_name
    and appl_top_type = l_appl_top_type
    and applications_system_name = l_app_sys_name;
    exception
      when no_data_found then
        raise_application_error(-20001,
                'No rows in AD_APPL_TOPS table for appl_top_name '||
                 '''' || p_appl_top_name || ''''||
                 'and applications system name '||
                 '''' || l_app_sys_name || ''''||
                 ' and appl_top type '||
                 '''' || l_appl_top_type || '''');
        return(0);
      when too_many_rows then
        raise_application_error(-20001,
                'Too many rows in AD_APPL_TOPS table for appl_top_name '||
                 '''' || p_appl_top_name || ''''||
                 'and applications system name '||
                 '''' || l_app_sys_name || '''');
        return(0);
  end;

  return(l_appl_top_id);

end getAppltopID;

end ad_patch;
