
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_POST_PATCH" AUTHID CURRENT_USER as
/* $Header: adpostps.pls 120.1 2005/10/17 05:15:48 rahkumar noship $ */

procedure get_patched_files
(
  p_appltop_id          number,
  p_file_extension_list varchar2 default NULL,
  p_applsys_user_name   varchar2
);

procedure get_files
(
  p_appltop_id          number,
  p_start_date          varchar2
);

procedure get_all_files
(
  p_appltop_id          number
);

procedure get_all_files
(
  p_appltop_id          number,
  p_start_date          varchar2,
  p_end_date            varchar2,
  p_file_extension_list varchar2 default NULL
);

procedure set_gathered_flag
(
  p_appltop_id          number
);


end ad_post_patch;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_POST_PATCH" as
/* $Header: adpostpb.pls 120.2 2005/10/17 05:45:59 rahkumar noship $ */


-- This procedure populates the table ad_processed_files_temp with
-- the list of files in the current_view for which the irep_gathered_flag
-- is set to 'N' and their extension matches with the list of extensions
-- provided to this procedure.

procedure get_patched_files
(p_appltop_id          number,
 p_file_extension_list varchar2 default NULL,
 p_applsys_user_name   varchar2)
is
  v_snapshot_id number;
  v_sql_stmt    varchar2(4000);
begin


  -- Truncate table applsys.ad_processed_files_temp.
  v_sql_stmt := 'truncate table ' || p_applsys_user_name || '.ad_processed_files_temp';
  execute immediate v_sql_stmt;

  -- Get the snapshot_id for use later.

  select snapshot_id
  into v_snapshot_id
  from ad_snapshots
  where appl_top_id = p_appltop_id
  and snapshot_name = 'CURRENT_VIEW'
  and snapshot_type = 'C';

  -- dbms_output.put_line('->SNAPSHOT_ID : [' || v_snapshot_id || ']');

  -- Insert into ad_processed_files_temp all the files in ad_snapshot_files
  -- whose extension matches the given list of extension, whose irep_gathered_flag
  -- is set to 'N' and thet belong to the current view snapshot for this appltop.

  v_sql_stmt := 'insert into ad_processed_files_temp' ||
                '(' ||
                'product_short_name,' ||
                'subdir,' ||
                'file_base,' ||
                'file_extension,' ||
                'file_id,' ||
                'file_version_id,' ||
                'version,' ||
                'date_applied,' ||
                'adpatch_flag' ||
  ')' ||
  ' select f.app_short_name,' ||
  '       f.subdir,' ||
  '       substr(f.filename,0,instr(f.filename,''.'')-1),' ||
  '       substr(f.filename,instr(f.filename,''.'')+1),' ||
  '       sf.file_id, ' ||
  '       sf.file_version_id, ' ||
  '       adfv.version, ' ||
  '       sf.last_patched_date, ' ||
  '       ''Y'' ' ||
  ' from ad_files f, ' ||
  '     ad_file_versions adfv, ' ||
  '     ad_snapshot_files sf ' ||
  ' where f.file_id = adfv.file_id ' ||
  ' and   sf.file_id = f.file_id ' ||
  ' and   sf.file_version_id = adfv.file_version_id ' ||
  ' and   substr(f.filename,instr(f.filename,''.'')+1) in ' || p_file_extension_list ||
  ' and   sf.snapshot_id = ' || v_snapshot_id ||
  ' and   sf.irep_gathered_flag = ''N''';

  execute immediate v_sql_stmt;

  -- Commit.

  v_sql_stmt := 'commit';
  execute immediate v_sql_stmt;

exception
 when others
 then
  raise;
end get_patched_files;



-- This procedure populates the table ad_processed_files_temp with
-- the list of files in the current_view having extension as 'ildt'
-- and patched since the given date.

procedure get_files
(p_appltop_id          number,
  p_start_date          varchar2)
is
  v_snapshot_id number;
  v_sql_stmt    varchar2(4000);
begin


  -- Truncate table applsys.ad_processed_files_temp.
  --v_sql_stmt := 'truncate table ' || p_applsys_user_name || '.ad_processed_files_temp';
  --execute immediate v_sql_stmt;

  -- Get the snapshot_id for use later.

  select snapshot_id
  into v_snapshot_id
  from ad_snapshots
  where appl_top_id = p_appltop_id
  and snapshot_name = 'CURRENT_VIEW'
  and snapshot_type = 'C';

  -- dbms_output.put_line('->SNAPSHOT_ID : [' || v_snapshot_id || ']');

  -- Insert into ad_processed_files_temp all the files in ad_snapshot_files
  -- whose extension matches the given list of extension, whose irep_gathered_flag
  -- is set to 'N' and thet belong to the current view snapshot for this appltop.

  v_sql_stmt := 'MERGE INTO ad_processed_files_temp apft' ||
                ' USING (' ||
  ' select f.app_short_name,' ||
  '       f.subdir,' ||
  '       substr(f.filename,0,instr(f.filename,''.'')-1) file_base,' ||
  '       substr(f.filename,instr(f.filename,''.'')+1) file_extension,' ||
  '       sf.file_id, ' ||
  '       sf.file_version_id, ' ||
  '       adfv.version, ' ||
  '       sf.last_patched_date ' ||
  ' from ad_files f, ' ||
  '     ad_file_versions adfv, ' ||
  '     ad_snapshot_files sf ' ||
  ' where f.file_id = adfv.file_id ' ||
  ' and   sf.file_id = f.file_id ' ||
  ' and   sf.file_version_id = adfv.file_version_id ' ||
  ' and   substr(f.filename,instr(f.filename,''.'')+1) = ''ildt''' ||
  ' and   sf.snapshot_id = ' || v_snapshot_id ||
  ' and   sf.last_patched_date >= ''' || to_date(p_start_date,'DD-MM-YYYY') || '''' ||
  ' ) S' ||
  ' ON ( apft.product_short_name=S.app_short_name and' ||
  '     apft.subdir=S.subdir and' ||
  '     apft.file_base=S.file_base and' ||
  '     apft.file_extension=S.file_extension )' ||
  ' WHEN MATCHED THEN UPDATE SET ' ||
  '     apft.file_version_id=S.file_version_id,' ||
  '     apft.version=S.version,' ||
  '     apft.date_applied=S.last_patched_date,' ||
  '     apft.adpatch_flag=''Y''' ||
  ' WHEN NOT MATCHED THEN INSERT ' ||
  ' (product_short_name,subdir,file_base,' ||
  ' file_extension,file_id,file_version_id,' ||
  ' version,date_applied,adpatch_flag)' ||
  ' VALUES ' ||
  '    (S.app_short_name ,S.subdir ,S.file_base,' ||
  '     S.file_extension, S.file_id, S.file_version_id,' ||
  '     S.version, S.last_patched_date,''Y'')';

  execute immediate v_sql_stmt;

  -- Commit.

  v_sql_stmt := 'commit';
  execute immediate v_sql_stmt;

exception
 when no_data_found then
   return;
 when others
 then
  raise;
end get_files;


-- Populates the table ad_processed_files_temp with the details
-- of all ildt files in the current view of the given appltop.

procedure get_all_files
(p_appltop_id          number)
is
  v_snapshot_id number;
  v_sql_stmt    varchar2(4000);
begin

  -- Truncate table applsys.ad_processed_files_temp.
  --v_sql_stmt := 'truncate table ' || p_applsys_user_name || '.ad_processed_files_temp';
  --execute immediate v_sql_stmt;

  select snapshot_id
  into v_snapshot_id
  from ad_snapshots
  where appl_top_id = p_appltop_id
  and snapshot_name = 'CURRENT_VIEW'
  and snapshot_type = 'C';

  -- dbms_output.put_line('->SNAPSHOT_ID : [' || v_snapshot_id || ']');

  -- Insert into ad_processed_files_temp all the files in ad_snapshot_files
  -- whose last_patched_date is between the start_date and end_date passed
  -- and the extension of the file matches the list of extensions passed.
  -- Do NOT consider the irep_gathered_flag here.

  v_sql_stmt := 'MERGE INTO ad_processed_files_temp apft' ||
                ' USING (' ||
  ' select f.app_short_name,' ||
  '       f.subdir,' ||
  '       substr(f.filename,0,instr(f.filename,''.'')-1) file_base,' ||
  '       substr(f.filename,instr(f.filename,''.'')+1) file_extension,' ||
  '       sf.file_id, ' ||
  '       sf.file_version_id, ' ||
  '       adfv.version, ' ||
  '       sf.last_patched_date ' ||
  ' from ad_files f, ' ||
  '     ad_file_versions adfv, ' ||
  '     ad_snapshot_files sf ' ||
  ' where f.file_id = adfv.file_id ' ||
  ' and   sf.file_id = f.file_id ' ||
  ' and   sf.file_version_id = adfv.file_version_id ' ||
  ' and   substr(f.filename,instr(f.filename,''.'')+1) = ''ildt''' ||
  ' and   sf.snapshot_id = ' || v_snapshot_id ||
  ' ) S' ||
  ' ON ( apft.product_short_name=S.app_short_name and' ||
  '     apft.subdir=S.subdir and' ||
  '     apft.file_base=S.file_base and' ||
  '     apft.file_extension=S.file_extension )' ||
  ' WHEN MATCHED THEN UPDATE SET ' ||
  '     apft.file_version_id=S.file_version_id,' ||
  '     apft.version=S.version,' ||
  '     apft.date_applied=S.last_patched_date,' ||
  '     apft.adpatch_flag=''Y''' ||
  ' WHEN NOT MATCHED THEN INSERT ' ||
  ' (product_short_name,subdir,file_base,' ||
  ' file_extension,file_id,file_version_id,' ||
  ' version,date_applied,adpatch_flag)' ||
  ' VALUES ' ||
  '    (S.app_short_name ,S.subdir ,S.file_base,' ||
  '     S.file_extension, S.file_id, S.file_version_id,' ||
  '     S.version, S.last_patched_date,''Y'')';

  execute immediate v_sql_stmt;

  -- Commit.

  v_sql_stmt := 'commit';
  execute immediate v_sql_stmt;


exception
 when no_data_found then
   return;
 when others
 then
  raise;
end get_all_files;


-- Gets the list of files in the current view who have been patched between the two
-- dates (given in DD-MM-YYYY format) and whose extension matches the list of
-- extensions passed.

procedure get_all_files
(p_appltop_id          number,
 p_start_date          varchar2,
 p_end_date            varchar2,
 p_file_extension_list varchar2 default NULL)

is
  v_snapshot_id number;
  v_sql_stmt    varchar2(4000);
begin

  -- Truncate table applsys.ad_processed_files_temp.
  -- v_sql_stmt := 'truncate table ' || p_applsys_user_name || '.ad_processed_files_temp';
  -- execute immediate v_sql_stmt;

  select snapshot_id
  into v_snapshot_id
  from ad_snapshots
  where appl_top_id = p_appltop_id
  and snapshot_name = 'CURRENT_VIEW'
  and snapshot_type = 'C';

  -- dbms_output.put_line('->SNAPSHOT_ID : [' || v_snapshot_id || ']');

  -- Insert into ad_processed_files_temp all the files in ad_snapshot_files
  -- whose last_patched_date is between the start_date and end_date passed
  -- and the extension of the file matches the list of extensions passed.
  -- Do NOT consider the irep_gathered_flag here.

  v_sql_stmt := 'MERGE INTO ad_processed_files_temp apft' ||
                ' USING (' ||
  ' select f.app_short_name,' ||
  '       f.subdir,' ||
  '       substr(f.filename,0,instr(f.filename,''.'')-1) file_base,' ||
  '       substr(f.filename,instr(f.filename,''.'')+1) file_extension,' ||
  '       sf.file_id, ' ||
  '       sf.file_version_id, ' ||
  '       adfv.version, ' ||
  '       sf.last_patched_date ' ||
  ' from ad_files f, ' ||
  '     ad_file_versions adfv, ' ||
  '     ad_snapshot_files sf ' ||
  ' where f.file_id = adfv.file_id ' ||
  ' and   sf.file_id = f.file_id ' ||
  ' and   sf.file_version_id = adfv.file_version_id ' ||
  ' and   substr(f.filename,instr(f.filename,''.'')+1) in '||
  p_file_extension_list||
  ' and   sf.snapshot_id = ' || v_snapshot_id ||
  ' and   sf.last_patched_date >= ''' || to_date(p_start_date,'DD-MM-YYYY') ||'''' ||
  ' ) S' ||
  ' ON ( apft.product_short_name=S.app_short_name and' ||
  '     apft.subdir=S.subdir and' ||
  '     apft.file_base=S.file_base and' ||
  '     apft.file_extension=S.file_extension )' ||
  ' WHEN MATCHED THEN UPDATE SET ' ||
  '     apft.file_version_id=S.file_version_id,' ||
  '     apft.version=S.version,' ||
  '     apft.date_applied=S.last_patched_date,' ||
  '     apft.adpatch_flag=''Y''' ||
  ' WHEN NOT MATCHED THEN INSERT ' ||
  ' (product_short_name,subdir,file_base,' ||
  ' file_extension,file_id,file_version_id,' ||
  ' version,date_applied,adpatch_flag)' ||
  ' VALUES ' ||
  '    (S.app_short_name ,S.subdir ,S.file_base,' ||
  '     S.file_extension, S.file_id, S.file_version_id,' ||
  '     S.version, S.last_patched_date,''Y'')';

  execute immediate v_sql_stmt;

  -- Commit.

  v_sql_stmt := 'commit';
  execute immediate v_sql_stmt;


exception
 when no_data_found then
   return;
 when others
 then
  raise;
end get_all_files;


-- This procedure sets the ad_snapshot_files.irep_gathered_flag to 'Y'
-- for all files present in ad_processed_files_temp (its assumed that
-- whoever calls this function would have made sure the files have
-- really been processed and are ready to be marked as processed).
-- The flag will remain at 'Y' until the next time when the file gets
-- patched and the flag gets reset to 'N" meaning "I have been patched
-- and I need to be processed again".

procedure set_gathered_flag
(p_appltop_id          number)
is
  v_snapshot_id number;
  v_sql_stmt    varchar2(4000);
begin

  -- Dont truncate the table ad_processed_files_temp!!!

  select snapshot_id
  into v_snapshot_id
  from ad_snapshots
  where appl_top_id = p_appltop_id
  and snapshot_name = 'CURRENT_VIEW'
  and snapshot_type = 'C';

  -- dbms_output.put_line('->SNAPSHOT_ID : [' || v_snapshot_id || ']');

  -- Taking the file_id and the file_version_id from ad_processed_files_temp,
  -- update the row in ad_snapshot_files to make its column irep_gathered_flag
  -- set to 'Y'. This marks the file saying "We have processed this version of
  -- this file.". The next time this file is patched, this flag will get reset
  -- to 'N' and will be again ready for processing and the cycle continues...


  v_sql_stmt := 'update ad_snapshot_files sf' ||
  ' set sf.irep_gathered_flag=''Y''' ||
  ' where sf.snapshot_id = ' || v_snapshot_id ||
  ' and sf.irep_gathered_flag = ''N''' ||
  ' and sf.file_id in ' ||
  '         (select t.file_id from ad_processed_files_temp t ' ||
  '          where  sf.file_version_id   = t.file_version_id ' ||
  '          and    sf.file_id           = t.file_id ' ||
  '          and    sf.last_patched_date = t.date_applied ' ||
  '          and    t.file_extension = ''ildt''' || ') ';

  --DBMS_OUTPUT.PUT_LINE('->[' || v_sql_stmt || ']');

  execute immediate v_sql_stmt;

  -- Commit.

  v_sql_stmt := 'commit';
  execute immediate v_sql_stmt;



exception
 when others
 then
  raise;
end set_gathered_flag;




--
--
--
end ad_post_patch;
