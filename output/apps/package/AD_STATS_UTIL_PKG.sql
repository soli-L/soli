
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_STATS_UTIL_PKG" AUTHID CURRENT_USER as
/* $Header: adustats.pls 115.1 2002/12/10 23:35:06 wjenkins ship $ */

--
-- procedure gather_stats_if_necessary:
--
-- Gather stats if necessary for a given subsystem, based on the count
-- inserted in this run.
--
-- p_gather_stats_flag = FALSE => Maintain the counts as usual but dont
-- actually gather the stats.
--
-- If p_gather_stats_flag is TRUE, then p_commit_flag is ignored.
--
-- p_gathered_stats_flag is passed back indicating whether stats were actually
-- gathered or not.
--
procedure gather_stats_if_necessary
           (p_subsystem_code                    varchar2,
            p_rows_inserted_this_run            number,
            p_gather_stats_flag                 boolean,
            p_commit_flag                       boolean,
            p_gathered_stats_flag    out nocopy boolean);


end ad_stats_util_pkg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_STATS_UTIL_PKG" as
/* $Header: adustatb.pls 120.1 2005/11/17 03:11:29 sgaruday noship $ */


--
-- Private program units
--

-- APPLSYS schema name

G_UN_FND varchar2(30) := null;

-- Minimum # of actions in the combined candidate starter patch-runs, that
-- when exceeded, should be deemed as a "big patch" (primarily for purposes of
-- switching from NESTED-LOOP to HASH-JOIN's).

G_BIG_PATCH_THRESHOLD constant number := 10000;
-- G_BIG_PATCH_THRESHOLD constant number := 2;  --testing. %% comment out later


--
--
-- Debug utils START
--
G_DEBUG constant boolean := FALSE;  --%%set to FALSE in production code

procedure put_line
           (msg varchar2,
            len number default 80)
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


procedure gather_stats
           (p_subsystem_code varchar2)
is
exist_flag varchar2(6) :=null;
begin
  if G_DEBUG then
    put_line('Gathering stats on: '||p_subsystem_code);
  end if;

  if p_subsystem_code = 'PATCH_HIST' then
    begin
       select distinct('EXIST')
       into exist_flag
       from FND_HISTOGRAM_COLS
       where application_id = 50
       and table_name = 'AD_PATCH_COMMON_ACTIONS'
       and column_name = 'ACTION_CODE';

       exception
        when no_data_found then
          fnd_stats.load_histogram_cols('INSERT', 50, 'AD_PATCH_COMMON_ACTIONS',
                                  'ACTION_CODE',NULL, hsize=>250);
        when others then
          raise_application_error(-20000 ,sqlerrm||': Error getting hisotgram
                                column from FND_HISTOGRAM_COLS');
     end;

    -- Bug: 4661028. sgaruday
    begin
       select distinct('EXIST')
       into exist_flag
       from FND_HISTOGRAM_COLS
       where application_id = 50
       and table_name = 'AD_FILES'
       and column_name = 'IS_FLAGGED_FILE';

       exception
        when no_data_found then
          fnd_stats.load_histogram_cols('INSERT', 50,  'AD_FILES',
                                  'IS_FLAGGED_FILE', NULL, hsize=>250);
        when others then
          raise_application_error(-20000 ,sqlerrm||': Error getting hisotgram
                                column from FND_HISTOGRAM_COLS');
     end;
     --

    fnd_stats.gather_table_stats(G_UN_FND, 'AD_RELEASES');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_APPL_TOPS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_APPLIED_PATCHES');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PATCH_DRIVERS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_COMPRISING_PATCHES');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PATCH_DRIVER_MINIPKS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PATCH_DRIVER_LANGS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PATCH_RUNS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PATCH_RUN_BUGS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_BUGS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PATCH_COMMON_ACTIONS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PATCH_RUN_BUG_ACTIONS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_FILE_VERSIONS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_FILES');
  elsif p_subsystem_code = 'SNAPSHOT' then
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_SNAPSHOTS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_SNAPSHOT_BUGFIXES');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_SNAPSHOT_FILES');
  elsif p_subsystem_code = 'TASK_TIMING' then
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PROGRAM_RUN_TASKS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PROGRAM_RUN_TASK_JOBS');
    fnd_stats.gather_table_stats(G_UN_FND, 'AD_PATCH_RUN_SESS_ATTRIBS');
  else
    raise_application_error(-20000, 'Invalid p_subsystem_code: '||
                                    p_subsystem_code);
  end if;

end gather_stats;

procedure validate_subsystem
           (p_subsystem_code varchar2)
is
begin
  if p_subsystem_code not in ('PATCH_HIST', 'SNAPSHOT','TASK_TIMING') then
    raise_application_error(-20000, 'Invalid p_subsystem_code: '||
                                    p_subsystem_code);
  end if;
end validate_subsystem;

procedure validate_increment
           (p_increment number)
is
begin
  if (p_increment >= 0 and trunc(p_increment) = p_increment) then
    return;
  else
    raise_application_error(-20000, 'Invalid increment: '||
                                    to_char(p_increment));
  end if;
end validate_increment;


--
-- Public program units
--

procedure gather_stats_if_necessary
           (p_subsystem_code                    varchar2,
            p_rows_inserted_this_run            number,
            p_gather_stats_flag                 boolean,
            p_commit_flag                       boolean,
            p_gathered_stats_flag    out NOCOPY boolean)
is
  l_count_when_last_analyzed number := 0;
  l_count_till_last_run number := 0;
  l_newcount number := 0;
  l_found boolean := FALSE;
begin
  -- fail if p_gather_stats_flag is TRUE but p_commit_flag is FALSE.

  if p_gather_stats_flag and (not p_commit_flag) then
    raise_application_error(-20000,
'Invalid args. Cannot expect to gather stats and not commit.');
  end if;

  p_gathered_stats_flag := FALSE;

  validate_subsystem(p_subsystem_code);
  validate_increment(p_rows_inserted_this_run);

  begin
    select
      nvl(to_number(attribute1), 0),
      nvl(to_number(attribute2), 0)
    into
      l_count_when_last_analyzed,
      l_count_till_last_run
    from ad_timestamps
    where type = 'COUNTS_FOR_ANALYZE'
    and attribute = p_subsystem_code;

    l_found := TRUE;

  exception when no_data_found then
    l_count_till_last_run := 0;
    l_count_when_last_analyzed := 0;
  end;

  l_newcount := l_count_till_last_run + p_rows_inserted_this_run;

  if l_found then

    if G_DEBUG then
      put_line('bumping up count-till-date by '||
               to_char(p_rows_inserted_this_run));
    end if;

    if p_gather_stats_flag and
       (l_newcount - l_count_when_last_analyzed > G_BIG_PATCH_THRESHOLD) then

      gather_stats(p_subsystem_code);

      p_gathered_stats_flag := TRUE;

      -- save both counts (count-till-date and count-when-last-analyzed) in
      -- AD_TIMESTAMPS.

      update ad_timestamps
      set attribute1 = to_char(l_newcount),
          attribute2 = to_char(l_newcount),
          timestamp = sysdate
      where type = 'COUNTS_FOR_ANALYZE'
      and attribute = p_subsystem_code;

    else

      -- save (only) the count-till-date in AD_TIMESTAMPS.

      update ad_timestamps
      set attribute2 = to_char(l_newcount),
          timestamp = sysdate
      where type = 'COUNTS_FOR_ANALYZE'
      and attribute = p_subsystem_code;

    end if;

  else  -- if not found

    -- we could fail here. lets not do that. rather, lets insert an "initial"
    -- row. Why? well, its not a big deal. The next run onwards should be ok.

    if G_DEBUG then
      put_line('creating initial row');
    end if;

    if p_gather_stats_flag and
       (l_newcount - l_count_when_last_analyzed > G_BIG_PATCH_THRESHOLD) then

      gather_stats(p_subsystem_code);

      p_gathered_stats_flag := TRUE;

      l_count_when_last_analyzed := l_newcount;
    end if;

    begin
      insert into ad_timestamps
      (
        type, attribute, timestamp,
        attribute1, attribute2
      ) values
      (
        'COUNTS_FOR_ANALYZE', p_subsystem_code, sysdate,
        to_char(l_count_when_last_analyzed), to_char(l_newcount)
      );

    exception when dup_val_on_index then
      -- Handle the corner case where we didn't see a row when we "saw", but
      -- someone else inserted after that. We dont want to fail in such a
      -- case. Rather, we just ignore and continue on. It would seem like we
      -- could handle this with select-for-update, etc. But not really, bcoz
      -- we do a DDL in between (gather stats). QED.

      null;
    end;

  end if;  -- End If not found


  -- If p_gather_stats_flag is TRUE, then commit regardless of p_commit_flag.

  if p_gather_stats_flag or p_commit_flag then
    commit;
  end if;

end gather_stats_if_necessary;

--
--
--

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

end ad_stats_util_pkg;
