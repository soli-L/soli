
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_PARALLEL_UPDATES_PKG" AUTHID CURRENT_USER as
-- $Header: adprupds.pls 120.2.12020000.2 2015/11/16 13:39:38 asutrala ship $

  --
  -- update types
  --
  --        ROWID_RANGE : use range of rowids when updating
  --  ID_RANGE_BY_ROWID : use range of IDs and selectively update by rowids
  --           ID_RANGE : use range of IDs when updating

  ROWID_RANGE                CONSTANT INTEGER := 1;
  ID_RANGE_BY_ROWID          CONSTANT INTEGER := 2;
  ID_RANGE                   CONSTANT INTEGER := 3;
  ID_RANGE_SUB_RANGE         CONSTANT INTEGER := 4;
  ID_RANGE_SUB_RANGE_SQL     CONSTANT INTEGER := 5;
  ID_RANGE_SCAN_EQUI_ROWSETS CONSTANT INTEGER := 6;

  --
  -- mode for processed rows
  --   PRESERVE_PROCESSED_UNITS : do not delete processed rows, just mark them
  --                              as processed
  --   DELETE_PROCESSED_UNITS   : delete units that are processed
  --                              (applicable for ROWID_RANGE only)
  --
  PRESERVE_PROCESSED_UNITS  CONSTANT INTEGER := 1;
  DELETE_PROCESSED_UNITS    CONSTANT INTEGER := 2;

procedure initialize_rowid_range
           (X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2,
            X_worker_id    in number,
            X_num_workers  in number,
            X_batch_size   in number,
            X_debug_level  in number,
            X_processed_mode in number);

procedure initialize_rowid_range
           (X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2,
            X_worker_id    in number,
            X_num_workers  in number,
            X_batch_size   in number,
            X_debug_level  in number);

procedure initialize_id_range
           (X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2,
            X_ID_column    in varchar2,
            X_worker_id    in number,
            X_num_workers  in number,
            X_batch_size   in number,
            X_debug_level  in number,
            X_SQL_Stmt     in varchar2 default NULL,
            X_Begin_ID     in number   default NULL,
            X_End_ID       in number   default NULL);

procedure processed_rowid_range
           (X_rows_processed  in  number,
            X_last_rowid      in  rowid);

procedure processed_id_range
           (X_rows_processed   in  number,
            X_last_id          in  number);

procedure get_rowid_range_wrapper
           (X_start_rowid  out nocopy rowid,
            X_end_rowid    out nocopy rowid,
            X_any_rows     out nocopy integer,
            X_num_rows     in         number  default NULL,
            X_restart      in         integer default 0);

procedure get_rowid_range
           (X_start_rowid  out nocopy rowid,
            X_end_rowid    out nocopy rowid,
            X_any_rows     out nocopy boolean,
            X_num_rows     in         number  default NULL,
            X_restart      in         boolean default FALSE);

procedure get_id_range
           (X_start_id   out nocopy number,
            X_end_id     out nocopy number,
            X_any_rows   out nocopy boolean,
            X_num_rows   in         number  default NULL,
            X_restart    in         boolean default FALSE);

procedure purge_processed_units
           (X_owner        in varchar2 default NULL,
            X_table        in varchar2 default NULL,
            X_script       in varchar2 default NULL);

--
-- Procedure Delete_Update_Information
--
--   Deletes rows associated with an update from AD tables so that the update
--   is eligible for reprocessing
--
--   This procedure does an implicit commit of the transaction.
--
--   THIS API IS INTENDED TO BE USED ONLY IN CERTAIN SITUATIONS. DO NOT
--   ARBITRARILY CALL THIS API.
--

procedure delete_update_information(
            X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2);

--
-- ReInitialize_After_Table_Reorg
--
-- This procedure is only applicable for ROWID_RANGE processing.
--
-- It marks the update for reprocessing if it partially done and data in the
-- driving table has been reorganized
--
procedure ReInitialize_After_Table_Reorg(
            X_owner        in varchar2 default NULL,
            X_table        in varchar2 default NULL,
            X_script       in varchar2 default NULL);

end;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_PARALLEL_UPDATES_PKG" as
-- $Header: adprupdb.pls 120.8.12020000.5 2021/03/12 15:52:47 rsatyava ship $

SUBTYPE update_info_type IS ad_parallel_updates%ROWTYPE;

--
-- Global cache for the current Parallel Update Record and Options.
--

TYPE global_cache_type IS RECORD
  (
   ui_initialized    BOOLEAN       := FALSE,
   update_info       update_info_type,
   batch_size        NUMBER        := 0,
   debug_level       NUMBER        := 0,
   processed_mode    NUMBER        := NULL,
   lock_name         VARCHAR2(128),
   lock_handle       VARCHAR2(128) := NULL,
   worker_id         NUMBER        := NULL
   );

  g_cache     global_cache_type;


  type NumberTab is table of number index by binary_integer;
  type StatusTab is table of varchar2(1) index by binary_integer;

  G_MAX_ROWS_IN_BLOCK    number := 9999;
  DEFAULT_MIN_BLOCKS     CONSTANT number := 200;
  g_max_blocks_multiple  number := 5;


  UNASSIGNED_STATUS     CONSTANT VARCHAR2(1) := 'U';
  ASSIGNED_STATUS       CONSTANT VARCHAR2(1) := 'A';
  PROCESSED_STATUS      CONSTANT VARCHAR2(1) := 'P';

  --
  -- Function
  --   get_rowid
  --
  -- Purpose
  --   Creates a rowid given file, block and row information
  --
  -- Arguments
  --
  -- Returns
  --
  -- Example
  --   none
  --
  -- Notes
  --   none
  --

function get_rowid
          (X_object_no     in number,
           X_relative_fno  in number,
           X_block_no      in number,
           X_row_no        in number)
  return rowid
is
  begin

     return(dbms_rowid.rowid_create(1, X_object_no, X_relative_fno,
                                       X_block_no, X_row_no));
  END get_rowid;

PROCEDURE init_g_cache_update_info
           (p_owner        IN VARCHAR2,
            p_table_name   IN VARCHAR2,
            p_script_name  IN VARCHAR2)
IS
  BEGIN
     g_cache.ui_initialized := FALSE;
     SELECT *
       INTO g_cache.update_info
       FROM ad_parallel_updates
       WHERE owner = p_owner
       AND table_name = p_table_name
       AND script_name = p_script_name;
     g_cache.ui_initialized := TRUE;
  END init_g_cache_update_info;

PROCEDURE get_update_info
           (x_update_info OUT nocopy update_info_type)
IS
  BEGIN
     IF (g_cache.ui_initialized) THEN
   x_update_info := g_cache.update_info;
      ELSE
   raise_application_error(-20001,
            'Not initialized.');
     END IF;
  END get_update_info;

procedure debug_info
           (msg  varchar2)
is
  begin
     if (g_cache.debug_level > 0) then
         -- dbms_output.put_line(msg);
         null;
     end if;
  END debug_info;

procedure lock_table
           (X_owner         in varchar2,
            X_table         in varchar2,
            X_mode          in varchar2,
            X_CommitRelease in boolean default null)
IS
       l_reqid  number;
       l_lock_name VARCHAR2(128);
       l_CommitRelease boolean;
  BEGIN
     l_lock_name := x_owner || '.' || x_table;

     if (g_cache.lock_name <> l_lock_name OR
         g_cache.lock_handle is null) THEN

         dbms_lock.allocate_unique(l_lock_name, g_cache.lock_handle);
         g_cache.lock_name := l_lock_name;

     end if;

     l_CommitRelease := nvl(X_CommitRelease, TRUE);

     l_reqid := dbms_lock.request(g_cache.lock_handle,
                                  dbms_lock.x_mode, dbms_lock.maxwait,
                                  l_CommitRelease);

     IF (l_reqid <> 0) THEN
        raise_application_error(-20001,
            'dbms_lock.request('|| g_cache.lock_handle ||
            ', ' || dbms_lock.x_mode ||
            ', ' || dbms_lock.maxwait ||
            ', TRUE) returned : ' || l_reqid);
     END IF;
  END lock_table;


procedure unlock_table
           (X_owner     in varchar2,
            X_table     in varchar2)
is
    l_reqid  number;
    l_lock_name VARCHAR2(128);
begin
    l_lock_name := x_owner || '.' || x_table;

    if (g_cache.lock_name is null
        or
        g_cache.lock_name <> l_lock_name)
    then
       raise_application_error(-20001, 'Invalid lock name : '||
                                       l_lock_name);
    end if;

    l_reqid := dbms_lock.release(g_cache.lock_handle);

    IF (l_reqid <> 0) THEN
        raise_application_error(-20001,
            'dbms_lock.release('|| g_cache.lock_handle ||
            ') returned : ' || l_reqid);
    END IF;
  END unlock_table;

procedure create_update_record
           (X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2,
            X_id_column    in varchar2 default null,
            X_num_workers  in number default null)
is
    l_initialized varchar2(1);
  begin

     IF (X_update_type in (ID_RANGE_BY_ROWID, ID_RANGE,
                           ID_RANGE_SUB_RANGE,
                           ID_RANGE_SUB_RANGE_SQL,
                           ID_RANGE_SCAN_EQUI_ROWSETS))
     THEN
        if (X_id_column is null) then
           raise_application_error(-20001,
               'Cannot get name for the unique id column');
        end if;

        if (X_num_workers is null) then
           raise_application_error(-20001,
               'Cannot get number of workers for ID range updates');
        end if;
     ELSIF (x_update_type = ROWID_RANGE) THEN
        NULL;
     ELSE
        raise_application_error(-20001,
               'Unknown update type : ' || x_update_type);
     end if;

     begin
        select null
        into   l_initialized
        from   ad_parallel_updates
        where  owner = X_owner
        and    table_name = X_table
        and    script_name = X_script;

     exception
        when NO_DATA_FOUND then
          insert into ad_parallel_updates (
                        update_id,
                        update_type,
                        owner, script_name, table_name,
                        object_id,
                        id_column, num_workers, creation_date,
                        db_block_size, avg_row_len,
                        initialized_flag)
          select ad_parallel_updates_s.nextval,
                 X_update_type,
                 X_owner, X_script, X_table,
                 nvl(o.data_object_id, o.object_id),
                 X_id_column, X_num_workers, sysdate,
                 8192, t.avg_row_len, 'N' -- only 8k block sizes for 11i and above
          from   dba_objects o, dba_tables t
          where  o.owner=X_owner
          and    o.object_name=X_table
          and    o.object_type='TABLE'
          and    o.owner=t.owner
          and    o.object_name=t.table_name;

   --
   -- Initialize the Global Cache Update Record Info.
   --
     end;

     init_g_cache_update_info(x_owner, x_table, x_script);

  END create_update_record;

-- For bug 3447980, a view ad_extents is created via adgrants.sql,
-- using the huge select tested by APPS Performance team.
-- This is to replace the Rule optimization
-- in ad_parallel_updates_pkg() package.

procedure populate_extent_info
           (X_owner     in varchar2,
            X_table     in varchar2,
            X_script    in varchar2,
            X_batch_size in number)
is
    CURSOR c_ext IS
      SELECT segment_name,
             partition_name,
             segment_type,
             data_object_id,
             relative_fno, block_id, blocks
      from   ebs_system.ad_extents
      where  owner = X_owner
      and    segment_name = X_table
      and    segment_type in ('TABLE', 'TABLE PARTITION',
                                'TABLE SUBPARTITION')
      order by segment_name, partition_name, relative_fno, block_id;

    object_id_tab     NumberTab;
    unit_id_tab       NumberTab;
    relative_fno_tab  NumberTab;
    start_block_tab   NumberTab;
    end_block_tab     NumberTab;

    cur_block   number;
    max_block   number;
    num_units   number;
    l_unit_id   number;
    i           integer;
    j           integer;
    k           integer;

    l_minblocks      number;
    l_my_sid         number;
    l_my_serialid    number;

    l_update_info    update_info_type;
    l_statement         varchar2(500);
    l_instance_version   varchar2(30);
    l_first_space_in_version   number;
    l_version_compare_result boolean;

  begin

     debug_info('populate_extent_info()+');

    --Bug#32589074(AD IMPACT - SYS.DBMS% PACKAGE RELATED CHANGES W.R.T ADB)
    --Removed the call to set _push_join_union_view as FALSE via API DBMS_SYSTEM.SET_BOOL_PARAM_IN_SESSION
		--This call is not required for database versions greater than 10g.We can refer to bug 3189824 for complete details.

     create_update_record(ROWID_RANGE,
                          X_owner,
                          X_table,
                          X_script);

     get_update_info(l_update_info);

     if (nvl(l_update_info.avg_row_len, 0) = 0) then
        l_minblocks := DEFAULT_MIN_BLOCKS;
     else
        l_minblocks := round((X_batch_size*l_update_info.avg_row_len)/
                                 l_update_info.db_block_size, -1);

        if (l_minblocks = 0) then
           l_minblocks := DEFAULT_MIN_BLOCKS;
        end if;
     end if;

     select nvl(max(unit_id), 0)
     into   l_unit_id
     from   ad_parallel_update_units
     where  update_id = l_update_info.update_id;

     FOR erec IN c_ext
     LOOP

        cur_block := erec.block_id;

        IF (erec.blocks > 0)
        THEN
           max_block := erec.block_id + erec.blocks - 1;
        ELSE
           max_block := erec.block_id;
        END IF;

        num_units := round(erec.blocks/l_minblocks + 0.5);

        i := 1;
        j := 1;

        LOOP

           EXIT WHEN (i > num_units);

           unit_id_tab(j)      := l_unit_id + i;
           object_id_tab(j)    := erec.data_object_id;
           relative_fno_tab(j) := erec.relative_fno;
           start_block_tab(j)  := erec.block_id +
                                         ((i - 1) * l_minblocks);
           end_block_tab(j)    := least(max_block,
                                            erec.block_id +
                                                 (i) * l_minblocks - 1);

           if (j = 100 or
               i = num_units) then
              FORALL k IN 1..j
                 INSERT INTO ad_parallel_update_units(
                   unit_id, update_id,
                   data_object_id,
                   relative_fno, start_block, end_block,
                   status
                 )
                 values( unit_id_tab(k), l_update_info.update_id,
                         object_id_tab(k),
                         relative_fno_tab(k),
                         start_block_tab(k),
                         end_block_tab(k),
                         UNASSIGNED_STATUS);
              j := 0;
           end if;

           i := i + 1;
           j := j + 1;
        END LOOP;

        l_unit_id := l_unit_id + i - 1;

     END LOOP;

     debug_info('populate_extent_info()-');
  END populate_extent_info;

procedure get_min_max_id
           (X_owner     in         varchar2,
            X_table     in         varchar2,
            X_id_column in         varchar2,
            X_SQL_Stmt  in         varchar2,
            X_min_id    out nocopy number,
            X_max_id    out nocopy number)
is
    l_stmt      varchar2(500);
    l_start_id  number;
    l_end_id    number;
  begin
     debug_info('get_min_max_id()+');
     X_min_id := null;
     X_max_id := null;

     if (X_SQL_Stmt is null)
     then

        l_stmt := 'select min('||X_id_column||') min_val '||
                  'from '||X_owner||'.'||X_table;

        EXECUTE IMMEDIATE l_stmt INTO l_start_id;

        l_stmt := 'select max('||X_id_column||') max_val '||
                  'from '||X_owner||'.'||X_table;

        EXECUTE IMMEDIATE l_stmt INTO l_end_id;

     else

        debug_info('get_min_max_id : '||X_SQL_Stmt);
        EXECUTE IMMEDIATE X_SQL_Stmt INTO l_start_id, l_end_id;

     end if;

     X_min_id := l_start_id;
     X_max_id := l_end_id;

     debug_info('get_min_max_id()-');

  END get_min_max_id;

procedure populate_id_ranges(
            X_update_type in number,
            X_update_id   in number,
            X_num_workers in number,
            X_batch_size  in number,
            X_SQL_Stmt    in varchar2)
is
  l_status varchar2(1);
begin

  l_status := UNASSIGNED_STATUS;

  if ( instr(lower(X_SQL_Stmt), 'id_value', 1) = 0)
  then
     raise_application_error(-20001,
         'The mandatory column alias (ID_VALUE) is missing '||
         'from the supplied SQL statement. ');
  end if;

  EXECUTE IMMEDIATE
    ' INSERT INTO ad_parallel_update_units '||
    ' (update_id, unit_id, start_id, end_id, status) '||
    ' SELECT :update_id update_id, '||
    '        unit_id+1 unit_id, '||
    '        min(id_value) start_id_value, '||
    '        max(id_value) end_id_value, '||
    '        :status status '||
    ' from ('||
    '   select id_value, '||
    '          floor(rank() over (order by id_value)/:batchsize) unit_id '||
    '   from ( '||
             X_SQL_Stmt||
    '   ) '||
    ' ) '||
    ' group by unit_id '
  using X_Update_id, l_status, X_batch_size;

exception
  when others then
  raise_application_error(-20001,
    SQLERRM||'. SQL statement is : '||
    'INSERT INTO ad_parallel_update_units '||
    ' (update_id, unit_id, start_id, end_id, status) '||
    ' select :update_id, unit_id, start_id_value, end_id_value, :status '||
    ' from ( '||
             X_SQL_Stmt||
    ' ) ');
end;

procedure populate_id_info
           (X_update_type in number,
            X_owner       in varchar2,
            X_table       in varchar2,
            X_script      in varchar2,
            X_id_column   in varchar2,
            X_num_workers in number,
            X_batch_size  in number,
            X_SQL_Stmt    in varchar2,
            X_Begin_ID    in number,
            X_End_ID      in number)
is
    l_table_start_id  number;
    l_table_end_id    number;
    l_unit_start_id   number;
    l_unit_end_id     number;
    l_unit_id         number;
    l_num_units       number;

    unit_id_tab       NumberTab;
    start_id_tab      NumberTab;
    end_id_tab        NumberTab;


    i                 number;
    l_entire_range    boolean;

    l_update_info     update_info_type;
    l_num_workers_used  number;

  begin
      debug_info('populate_id_info()+');

      l_entire_range := (X_update_type = ID_RANGE_BY_ROWID);

      create_update_record(X_update_type,
                           X_owner, X_table, X_script,
                           X_id_column, X_num_workers);

      get_update_info(l_update_info);

      if (X_update_type = ID_RANGE_SCAN_EQUI_ROWSETS)
      then
         populate_id_ranges(
            X_update_type,
            l_update_info.update_id,
            X_num_workers, X_batch_size,
            X_SQL_Stmt);
      else
         if (X_update_type = ID_RANGE_SUB_RANGE)
         then
            l_table_start_id := X_Begin_ID;
            l_table_end_id   := X_End_ID;
         else
            get_min_max_id(X_owner, X_table, X_id_column,
                           X_SQL_Stmt,
                           l_table_start_id, l_table_end_id);
         end if;

         if (l_table_start_id is NOT NULL and l_table_end_id IS NOT NULL) then

            if (l_entire_range = TRUE) then

              FOR i IN 1..X_num_workers
              LOOP
                start_id_tab(i) := l_table_start_id;
                end_id_tab(i)   := l_table_end_id;
                unit_id_tab(i)  := i;
              END LOOP;

              FORALL i in 1..X_num_workers
                insert into ad_parallel_update_units(
                    unit_id, update_id,
                    start_id, end_id,
                    status
                 )
                values (unit_id_tab(i), l_update_info.update_id,
                         start_id_tab(i), end_id_tab(i),
                         UNASSIGNED_STATUS);
            else
               l_unit_start_id := l_table_start_id;
               l_unit_id       := 0;
               l_num_units     := 0;

               while (l_unit_start_id <= l_table_end_id)
               loop

                  l_unit_id     := l_unit_id + 1;
                  l_num_units   := l_num_units + 1;

                  l_unit_end_id := least((l_unit_start_id + X_batch_size - 1),
                                          l_table_end_id);

                  unit_id_tab(l_num_units)  := l_unit_id;
                  start_id_tab(l_num_units) := l_unit_start_id;
                  end_id_tab(l_num_units)   := l_unit_end_id;

                  l_unit_start_id := l_unit_start_id + X_batch_size;

                  if (l_num_units = 500
                      or
                      l_unit_start_id > l_table_end_id)
                  then

                    FORALL i in 1..l_num_units
                      insert into ad_parallel_update_units(
                        unit_id, update_id,
                        start_id, end_id,
                        status
                       )
                      values (unit_id_tab(i), l_update_info.update_id,
                              start_id_tab(i), end_id_tab(i),
                              UNASSIGNED_STATUS);

                      l_num_units := 0;

                  end if;

               end loop;

            end if; /* entire_range = FALSE */

         end if; /* l_table_start_id is not null */

      end if; /* if not X_Update_type = ID_RANGE_SCAN_EQUI_ROWSETS */

      debug_info('populate_id_info()-');

  END populate_id_info;

procedure initialize
           (X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2,
            X_ID_column    in varchar2,
            X_worker_id    in number,
            X_num_workers  in number,
            X_batch_size   in number,
            X_debug_level  in number,
            X_processed_mode in number,
            X_SQL_Stmt     in varchar2,
            X_Begin_ID     in number,
            X_End_ID       in number)
is
    l_initialized  varchar2(1);
    l_req_init     boolean := TRUE;
    l_update_id    number;
    l_num_workers  number;
    l_unproc_units_exist  number;
  begin
      debug_info('initialize()+');

      if (X_processed_mode not in (PRESERVE_PROCESSED_UNITS,
                                   DELETE_PROCESSED_UNITS))
      then
         raise_application_error(-20001,
           'Incorrect mode specified for processed units. '||
           'Must be either PRESERVE_PROCESSED_UNITS or '||
           'DELETE_PROCESSED_UNITS. ');
      end if;

      if (X_batch_size <= 0) then
        raise_application_error(-20001,
          'Invalid value for batch size ('||X_batch_size||'). '||
          'The batch size must be a positive number greater than 0.');
      end if;

      if (X_update_type = ID_RANGE_SCAN_EQUI_ROWSETS
          and
          X_SQL_Stmt is null)
      then
        raise_application_error(-20001,
          'You must specify a SQL statement to derive processing units.');
      end if;

      if (X_update_type = ID_RANGE_SUB_RANGE
          and
          X_SQL_Stmt is not null)
      then
        raise_application_error(-20001,
          'You cannot specify a SQL statement for specific ID range.');
      end if;

      if (X_update_type = ID_RANGE_SUB_RANGE_SQL
          and
          X_SQL_Stmt is null)
      then
          raise_application_error(-20001,
          'You must specify a SQL statement for this ID range method.');
      end if;

      --
      -- lock the table to ensure that other workers are not initializing
      --
      lock_table(X_owner, X_table, 'EXCLUSIVE', FALSE);

      l_req_init := TRUE;

      begin
        select update_id, initialized_flag, num_workers
        into   l_update_id, l_initialized, l_num_workers
        from   ad_parallel_updates
        where  owner = X_owner
          and  table_name = X_table
          and  script_name = X_script;

        if (l_initialized = 'Y') then
           --
           -- already initialized
           --
           l_req_init := FALSE;
        end if;

      exception
        when no_data_found then
          l_req_init := TRUE;
          l_update_id := null;
      end;

      if (l_req_init = TRUE) then

          --
          -- to be safe, delete any rows that may have been inserted
          --
          if (l_update_id is not null) then
             delete from ad_parallel_update_units
             where update_id = l_update_id;
          end if;

          debug_info('Populate information : ');

          if (X_update_type = ROWID_RANGE) then
             populate_extent_info(X_owner, X_table, X_script, X_batch_size);
          else
             populate_id_info(X_update_type,
                              X_owner, X_table, X_script, X_ID_column,
                              X_num_workers, X_batch_size,
                              X_SQL_Stmt, X_Begin_ID, X_End_ID);
          end if;

          --
          -- now set initialized_flag to Y
          --
          update ad_parallel_updates
          set    initialized_flag = 'Y',
                 num_workers = X_num_workers
          where  owner = X_owner
            and  table_name = X_table
            and  script_name = X_script;

      else

         --
         -- compare number of workers and recover unprocessed units
         --
         if (X_num_workers <> nvl(l_num_workers, -1)) then

           --
           -- check if the update is already processed. do not do anything
           -- if all units are processed.
           --

           begin
             select 1
             into   l_unproc_units_exist
             from   sys.dual
             where  exists (
                 select 1
                 from   ad_parallel_update_units
                 where  update_id = l_update_id
                 and status in (UNASSIGNED_STATUS, ASSIGNED_STATUS));
           exception
             when no_data_found then
                l_unproc_units_exist := 0;
           end;

           if (l_unproc_units_exist > 0) then

             if (X_update_type not in (ROWID_RANGE, ID_RANGE)) then
                --
                -- for ID over ROWID range methods, you cannot reduce the
                -- number of workers after initialization
                --
                if (X_num_workers <  l_num_workers) then

                   raise_application_error(-20001,
              'Cannot reduce the number of workers after initialization.');
                end if;

             else
               --
               -- recover all units in ASSIGNED_STATUS by returning them
               -- to the UNASSIGNED_STATUS pool
               --
               update ad_parallel_update_units
               set    status = UNASSIGNED_STATUS,
                      worker_id = null
               where  update_id = l_update_id
               and    status = ASSIGNED_STATUS
               and    worker_id > X_num_workers;

               update ad_parallel_workers
               set    start_unit_id = 0,
                      end_unit_id = 0,
                      start_rowid = null,
                      start_id    = null,
                      end_rowid   = null,
                      end_id      = null
               where update_id = l_update_id
               and    worker_id > X_num_workers;

               update ad_parallel_updates
               set    num_workers = X_num_workers
               where  update_id = l_update_id;

             end if; -- ID range method

           end if; -- incomplete update

         end if; -- worker count changed

      end if;  -- require initialization

      --
      -- g_cache might already be initialized by populate_* calls.
      --
      IF ((g_cache.ui_initialized = FALSE)
          OR
          (x_owner||'.'||x_owner||'.'||x_script <>
             g_cache.update_info.owner||'.'||
             g_cache.update_info.table_name||'.'||
             g_cache.update_info.script_name)) THEN
         init_g_cache_update_info(x_owner, x_table, x_script);
      END IF;

      g_cache.debug_level    := X_debug_level;
      g_cache.batch_size     := X_batch_size;
      g_cache.worker_id      := X_worker_id;
      g_cache.processed_mode := X_processed_mode;

      --
      -- Release the lock. First do the commit so that other workers
      -- would see the row.
      --
      COMMIT;
      unlock_table(X_owner, X_table);
      debug_info('initialize()-');
  exception
      when others then
        debug_info(sqlerrm);
        raise;
  END initialize;


-- Bug 3611969 : FIXED FILE.SQL.35 GSCC WARNINGS
-- sraghuve (07/05/2004)


procedure initialize_rowid_range
           (X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2,
            X_worker_id    in number,
            X_num_workers  in number,
            X_batch_size   in number,
            X_debug_level  in number)
is
begin
  initialize_rowid_range
             (X_update_type => X_update_type,
              X_owner       => X_owner,
              X_table       => X_table,
              X_script      => X_script,
              X_worker_id   => X_worker_id,
              X_num_workers => X_num_workers,
              X_batch_size  => X_batch_size,
              X_debug_level => X_debug_level,
              X_processed_mode => PRESERVE_PROCESSED_UNITS);

end;

procedure initialize_rowid_range
           (X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2,
            X_worker_id    in number,
            X_num_workers  in number,
            X_batch_size   in number,
            X_debug_level  in number,
            X_processed_mode in number)
is
  begin
     debug_info('initialize_rowid_range()+');
     initialize(X_update_type,
                X_owner, X_table, X_script, null,
                X_worker_id, X_num_workers,
                X_batch_size, X_debug_level,
                X_processed_mode,
                null, null, null);
     debug_info('initialize_rowid_range()-');
  END initialize_rowid_range;

procedure initialize_id_range
           (X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2,
            X_ID_column    in varchar2,
            X_worker_id    in number,
            X_num_workers  in number,
            X_batch_size   in number,
            X_debug_level  in number,
            X_SQL_Stmt     in varchar2 default NULL,
            X_Begin_ID     in number   default NULL,
            X_End_ID       in number   default NULL)
is
  begin
     initialize(X_update_type,
                X_owner, X_table, X_script, X_ID_column,
                X_worker_id, X_num_workers,
                X_batch_size, X_debug_level,
                ad_parallel_updates_pkg.PRESERVE_PROCESSED_UNITS,
                X_SQL_Stmt, X_Begin_ID, X_End_ID);
  END initialize_id_range;


procedure get_restart_range
           (X_worker_id        in         number,
            X_update_id        in         number,
            X_res_start_rowid  out nocopy rowid,
            X_res_end_rowid    out nocopy rowid,
            X_res_start_id     out nocopy number,
            X_res_end_id       out nocopy number,
            X_start_unit_id    out nocopy number,
            X_end_unit_id      out nocopy number)
  is
  begin

     select start_rowid, end_rowid,
            start_id, end_id,
            start_unit_id, end_unit_id
     into   X_res_start_rowid, X_res_end_rowid,
            X_res_start_id, X_res_end_id,
            X_start_unit_id, X_end_unit_id
     from   ad_parallel_workers
     where  worker_id = X_worker_id
     and    update_id = X_update_id;

  exception
     when no_data_found then
       X_res_start_rowid := null;
       X_res_end_rowid   := null;
       X_res_start_id    := null;
       X_res_end_id      := null;
       X_start_unit_id   := null;
       X_end_unit_id     := null;
  END get_restart_range;

  --
  -- updates worker record with processed information. If all
  -- rows for a range are processed, update the work unit to
  -- processed
  --
procedure processed_unit
           (X_rows_processed in  number,
            X_last_rowid     in  rowid,
            X_last_id        in  number)
is
    l_res_start_rowid   rowid;
    l_res_end_rowid     rowid;
    l_start_unit_id     number;
    l_end_unit_id       number;

    l_worker_id         NUMBER;
    l_update_info       update_info_type;
  begin

     get_update_info(l_update_info);
     l_worker_id := g_cache.worker_id;

     -- do not get the explicit lock
     -- lock_table(l_update_info.owner, l_update_info.table_name, 'EXCLUSIVE');

     select start_unit_id, end_unit_id
     into   l_start_unit_id, l_end_unit_id
     from   ad_parallel_workers
     where  worker_id = l_worker_id
     and    update_id = l_update_info.update_id;

     --
     -- set start_id to end_id+1 to handle cases where there is just one
     -- row per worker
     --
     update ad_parallel_workers
     set    start_rowid = nvl(X_last_rowid, start_rowid),
	    start_id    = least(nvl(X_last_id, start_id)+1, end_id+1),
            rows_processed = nvl(rows_processed, 0) + nvl(X_rows_processed, 0)
     where  worker_id = l_worker_id
     and    update_id = l_update_info.update_id;

     if (g_cache.processed_mode = DELETE_PROCESSED_UNITS) then
        delete from ad_parallel_update_units
        where  update_id = l_update_info.update_id
        and    unit_id  between l_start_unit_id and l_end_unit_id;
     else
        update ad_parallel_update_units
        set    status = decode(l_update_info.update_type,
                               ROWID_RANGE, PROCESSED_STATUS,
                               decode(X_last_id,
                                      end_id, PROCESSED_STATUS,
                                      status)),
               end_date = sysdate,
               rows_processed = nvl(rows_processed, 0) +
                                nvl(X_rows_processed, 0)
        where  update_id = l_update_info.update_id
        and    unit_id  between l_start_unit_id and l_end_unit_id;

     end if;

     --
     -- commit here to release lock
     --
     commit;

  END processed_unit;

  --
  -- procedure for processing by ROWID_RANGE
  --
procedure processed_rowid_range
           (X_rows_processed in number,
            X_last_rowid     in  rowid)
is
  begin
      processed_unit(X_rows_processed,
                     X_last_rowid,
                     null);
  END processed_rowid_range;

  --
  -- procedure for processing by ID_RANGE and ID_BY_ROWID_RANGE
  --
procedure processed_id_range
           (X_rows_processed in number,
            X_last_id        in  number)
is
  begin
      processed_unit(X_rows_processed,
                     null,
                     X_last_id);
  END processed_id_range;

procedure set_current_range
           (X_worker_id     in  number,
            X_start_unit_id in  number,
            X_end_unit_id   in  number,
            X_start_rowid   in  rowid,
            X_end_rowid     in  rowid,
            X_start_id      in  number,
            X_end_id        in  number)
is
    l_unit_id      number;
    l_update_info  update_info_type;
  begin

    debug_info('set_current_range()+');

    get_update_info(l_update_info);

    update ad_parallel_workers
    set    start_unit_id = X_start_unit_id,
           end_unit_id   = X_end_unit_id,
           start_rowid   = X_start_rowid,
           end_rowid     = X_end_rowid,
           start_id      = X_start_id,
           end_id        = X_end_id
    where  worker_id   = X_worker_id
    and    update_id   = l_update_info.update_id;

    --
    -- if no records updated, insert a new record
    --
    IF (SQL%ROWCOUNT = 0) THEN
       insert into ad_parallel_workers (
                      worker_id, update_id,
                      start_unit_id, end_unit_id,
                      start_rowid, end_rowid,
                      start_id, end_id
                   )
       values (X_worker_id, l_update_info.update_id,
               X_start_unit_id, X_end_unit_id,
               X_start_rowid, X_end_rowid,
               X_start_id, X_end_id
              );
    END IF;

    --
    -- Set status to ASSIGNED_STATUS
    --

    update ad_parallel_update_units
    set    status = ASSIGNED_STATUS,
           worker_id = X_worker_id,
           start_date = nvl(start_date, sysdate)
    where  update_id = l_update_info.update_id
    and    unit_id between X_start_unit_id and X_end_unit_id;

    debug_info('set_current_range()-');

  END set_current_range;

procedure set_rowid_range
           (X_worker_id     in  number,
            X_start_unit_id in  number,
            X_end_unit_id   in  number,
            X_start_rowid   in  rowid,
            X_end_rowid     in  rowid)
is
  begin
      set_current_range(X_worker_id,
                        X_start_unit_id, X_end_unit_id,
                        X_start_rowid, X_end_rowid,
                        null, null);
  end;

procedure set_id_range
           (X_worker_id     in  number,
            X_start_unit_id in  number,
            X_end_unit_id   in  number,
            X_start_id      in  number,
            X_end_id        in  number)
is
  begin
      set_current_range(X_worker_id,
                        X_start_unit_id, X_end_unit_id,
                        null, null,
                        X_start_id, X_end_id);
  end;

--
-- This is a wrapper around get_rowid_range() to enable
-- programs written in other languages that do not support
-- passing boolean parameters to PL/SQL stored procedures,
-- like Java, to call get_rowid_range().
--
procedure get_rowid_range_wrapper
           (X_start_rowid  out nocopy rowid,
            X_end_rowid    out nocopy rowid,
            X_any_rows     out nocopy integer,
            X_num_rows     in         number  default NULL,
            X_restart      in         integer default 0)
is
    l_any_rows  boolean;
    l_restart   boolean;
  begin

    debug_info('get_rowid_range_wrapper()+');

    -- Translate integer to boolean
    -- 1 = TRUE
    -- 0 = FALSE
    l_restart := x_restart > 0;

    get_rowid_range(X_START_ROWID,
                    X_END_ROWID,
                    l_any_rows,
                    X_NUM_ROWS,
                    l_restart);

    -- Translate boolean to integer for OUT variable
    if (l_any_rows) then
       X_ANY_ROWS := 1;
    else
       X_ANY_ROWS := 0;
    end if;

    debug_info('get_rowid_range_wrapper()-');
  END get_rowid_range_wrapper;

procedure get_rowid_range
           (X_start_rowid out nocopy rowid,
            X_end_rowid   out nocopy rowid,
            X_any_rows    out nocopy boolean,
            X_num_rows    in         number  default NULL,
            X_restart     in         boolean default FALSE)
is
    l_res_start_rowid      rowid;
    l_res_end_rowid        rowid;
    l_res_start_id         number;
    l_res_end_id           number;
    l_start_rowid          rowid;
    l_end_rowid            rowid;
    l_start_unit_id        number;
    l_end_unit_id          number;
    l_last_processed_unit  number;
    l_unit_rec             ad_parallel_update_units%rowtype;

    l_worker_id            NUMBER;
    l_update_info          update_info_type;

    cursor c_range(p_update_id number) is
      select /*+ FIRST_ROWS +*/ *
      from   ad_parallel_update_units
      where  update_id = p_update_id
      and status = UNASSIGNED_STATUS
      for update of status
      skip locked;
  begin

    debug_info('get_rowid_range()+');

    get_update_info(l_update_info);
    l_worker_id := g_cache.worker_id;

    get_restart_range(l_worker_id, l_update_info.update_id,
                      l_res_start_rowid, l_res_end_rowid,
                      l_res_start_id, l_res_end_id,
                      l_start_unit_id, l_end_unit_id);

    l_last_processed_unit := nvl(l_end_unit_id, 0);

    -- return the current range if there are still some rows to process

    X_any_rows := FALSE;

    if (l_res_start_rowid is not null
        and
        l_res_start_rowid <> l_res_end_rowid)
    then
        X_start_rowid  := l_res_start_rowid;
        X_end_rowid    := l_res_end_rowid;
        X_any_rows     := TRUE;

        debug_info('get_rowid_range()-');
        return;
    end if;

    l_start_rowid := null;
    l_end_rowid   := null;

    -- do not explicitly get the lock as we are now using the skip lock
    -- feature
    -- lock_table(l_update_info.owner, l_update_info.table_name, 'EXCLUSIVE');

    open c_range(l_update_info.update_id);

    fetch c_range into l_unit_rec;

    if (c_range%NOTFOUND) then
       debug_info('get_rowid_range() : no more rows found ');
    else
      debug_info('get_rowid_range() : getting from table');

      l_start_rowid := get_rowid(nvl(l_unit_rec.data_object_id,
                                     l_update_info.object_id),
                                 l_unit_rec.relative_fno,
                                 l_unit_rec.start_block,
                                 0);

      l_end_rowid   := get_rowid(nvl(l_unit_rec.data_object_id,
                                     l_update_info.object_id),
                                 l_unit_rec.relative_fno,
                                 l_unit_rec.end_block,
                                 G_MAX_ROWS_IN_BLOCK);

      debug_info('get_rowid_range() : rowids returned are '||
                           l_start_rowid||' and '||l_end_rowid);

    end if;

    X_start_rowid := l_start_rowid;
    X_end_rowid   := l_end_rowid;
    X_any_rows    := (l_start_rowid <> l_end_rowid);

    if (l_start_rowid is not null) then
       set_rowid_range(l_worker_id,
             l_unit_rec.unit_id, l_unit_rec.unit_id,
             l_start_rowid, l_end_rowid);
    end if;

    close c_range;

    commit;

    debug_info('get_rowid_range()-');
  END get_rowid_range;

procedure get_id_range
           (X_start_id   out nocopy number,
            X_end_id     out nocopy number,
            X_any_rows   out nocopy boolean,
            X_num_rows   in         number  default NULL,
            X_restart    in         boolean default FALSE)
is
    l_res_start_rowid    rowid;
    l_res_end_rowid      rowid;
    l_res_start_id       number;
    l_res_end_id         number;
    l_start_id           number;
    l_end_id             number;
    l_start_unit_id      number;
    l_end_unit_id        number;
    l_unit_rec           ad_parallel_update_units%rowtype;
    l_batch_size         number;

    l_status             varchar2(30);

    l_worker_id          NUMBER;
    l_update_info        update_info_type;

    cursor c_range(p_update_id in number) is
      select /*+ FIRST_ROWS +*/ *
      from   ad_parallel_update_units
      where  update_id = p_update_id
      and status = UNASSIGNED_STATUS
      for update of status
      skip locked;
  begin

    debug_info('get_id_range()+');

    get_update_info(l_update_info);
    l_worker_id := g_cache.worker_id;

    l_batch_size := nvl(X_num_rows, g_cache.batch_size);

    get_restart_range(l_worker_id, l_update_info.update_id,
                      l_res_start_rowid, l_res_end_rowid,
                      l_res_start_id, l_res_end_id,
                      l_start_unit_id, l_end_unit_id);

    -- return the current range if there are still some rows to process

    X_any_rows := FALSE;

    if (l_res_start_id is not null
        and
        l_res_start_id < l_res_end_id)
    then
        X_start_id  := l_res_start_id;

        --
        -- For Equi rowsets, return the entire range
        --
        if (l_update_info.update_type = ID_RANGE_SCAN_EQUI_ROWSETS) then
           X_end_id := l_res_end_id;
        else
           X_end_id    := least(l_res_start_id + l_batch_size-1, l_res_end_id);
        end if;

        X_any_rows  := TRUE;
        debug_info('get_id_range()-');
        return;
    end if;

    --
    -- to address the case where the start_id = end_id as used to be recorded
    -- earlier. The processing now stops when start_id > end_id
    --
    if (l_res_start_id is not null
        and
        l_res_start_id = l_res_end_id)
    then
       begin
          --
          -- check the actual unit to find out if it has already been processed
          --
          select status
          into   l_status
          from   ad_parallel_update_units
          where  update_id = l_update_info.update_id
          and    unit_id = l_start_unit_id;

          --
          -- return the same range if the unit is not yet marked as processed
          --

          if (l_status = ASSIGNED_STATUS) then
             X_start_id  := l_res_start_id;

             if (l_update_info.update_type = ID_RANGE_SCAN_EQUI_ROWSETS) then
               X_end_id := l_res_end_id;

             else
               X_end_id    := least(l_res_start_id + l_batch_size-1,
                                    l_res_end_id);
             end if;

             X_any_rows  := TRUE;
             debug_info('get_id_range()-');
             return;
          end if;

       exception
          when NO_DATA_FOUND then
            null;
       end;
    end if;


    l_start_id := null;
    l_end_id   := null;

    -- do not explicitly lock the update as we are now using the skip locked
    -- feature
    -- lock_table(l_update_info.owner, l_update_info.table_name, 'EXCLUSIVE');

    open c_range(l_update_info.update_id);

    while (TRUE)
    loop
      fetch c_range into l_unit_rec;

      if (c_range%NOTFOUND) then
         debug_info('get_id_range() : no more rows found ');
         X_start_id := null;
         X_end_id   := null;
         X_any_rows := FALSE;
         exit;
      else
        debug_info('get_id_range() : getting from table');

        l_start_id := l_unit_rec.start_id;
        l_end_id := l_unit_rec.end_id;

        debug_info('get_id_range() : ids returned are '||
                             l_start_id||' and '||l_end_id);


        X_start_id := l_start_id;

        if (l_update_info.update_type = ID_RANGE_SCAN_EQUI_ROWSETS) then
          X_end_id := l_end_id;
        else
          X_end_id   := least(l_start_id + l_batch_size-1, l_end_id);
        end if;

        X_any_rows := (X_start_id <= X_end_id);

        if (l_start_id is not null)
        then
          set_id_range(l_worker_id, l_unit_rec.unit_id, l_unit_rec.unit_id,
                       l_start_id, l_end_id);

          exit;
        else

          /* set unit as processed if ID values are null.  */

          update AD_PARALLEL_UPDATE_UNITS
          set STATUS = PROCESSED_STATUS
          where update_id = l_update_info.update_id
          and    unit_id = l_unit_rec.unit_id;

        end if;
      end if;
    end loop;

    close c_range;

    commit;

    debug_info('get_id_range()-');
  END get_id_range;

procedure purge_processed_units
           (X_owner  in varchar2 default NULL,
            X_table  in varchar2 default NULL,
            X_script in varchar2 default NULL)
is
    cursor c_purge is
       select update_id
       from   ad_parallel_updates p
       where  initialized_flag = 'Y'
       and    owner = nvl(upper(X_owner), owner)
       and    table_name = nvl(upper(X_table), table_name)
       and    script_name = nvl(X_script, script_name)
       and not exists (
           select update_id
           from   ad_parallel_update_units u
           where  u.update_id = p.update_id
           and    u.status in ('A', 'U'));
  begin
    for c_rec in c_purge loop
      --
      -- delete from ad_parallel_update_units
      --
      delete from ad_parallel_update_units
      where update_id = c_rec.update_id;

      --
      -- delete from ad_parallel_workers
      --
      delete from ad_parallel_workers
      where update_id = c_rec.update_id;

      commit;

    end loop;
  end;

--
-- Procedure Delete_Update_Information
--
--   Deletes rows associated with an update from AD tables so that the update
--   is eligible for reprocessing
--
--   This procedure does an implicit commit of the transaction
--

procedure delete_update_information(
            X_update_type  in number,
            X_owner        in varchar2,
            X_table        in varchar2,
            X_script       in varchar2)
is
  l_update_id  number;
begin

  begin

    select update_id
    into   l_update_id
    from   ad_parallel_updates
    where  owner = upper(X_owner)
    and    table_name = upper(X_table)
    and    script_name = X_script;

  exception
    --
    -- just return, if an update row is not found
    --
    when NO_DATA_FOUND then
      return;
  end;

  --
  -- get lock for the update
  --
  lock_table(X_owner, X_table, 'EXCLUSIVE');

  delete from ad_parallel_workers
  where  update_id = l_update_id;

  delete from ad_parallel_update_units
  where  update_id = l_update_id;

  delete from ad_parallel_updates
  where  update_id = l_update_id;

  --
  -- commit and release the lock
  --
  commit;

end;


--
-- ReInitialize_After_Table_Reorg
--
-- This procedure is only applicable for ROWID_RANGE processing.
--
-- It marks the update for reprocessing if it partially done and data in the
-- driving table has been reorganized
--
procedure ReInitialize_After_Table_Reorg(
            X_owner        in varchar2 default NULL,
            X_table        in varchar2 default NULL,
            X_script       in varchar2 default NULL)
is

  --
  -- updates that have pending units are candidates for reinitialization
  --
  cursor c_cur is
    select update_id, table_name, owner
    from   ad_parallel_updates pu
    where  owner = nvl(upper(X_owner), owner)
    and    table_name = nvl(upper(X_table), table_name)
    and    script_name = nvl(X_script, script_name)
    and    update_type = ROWID_RANGE
    and    initialized_flag = 'Y'
    and exists (
        select 'Unprocessed units exist'
        from   ad_parallel_update_units pun
        where  pun.update_id = pu.update_id
        and    pun.status in (UNASSIGNED_STATUS, ASSIGNED_STATUS));
begin

  for crec in c_cur loop

     --
     -- get lock for the update
     --
     lock_table(crec.owner, crec.table_name, 'EXCLUSIVE');

     --
     -- set the update to un-initialized
     --
     update ad_parallel_updates
     set initialized_flag = 'N'
     where update_id = crec.update_id;

     --
     -- delete from ad_parallel_update_units
     --
     delete from ad_parallel_update_units
     where update_id = crec.update_id;

     delete from ad_parallel_workers
     where update_id = crec.update_id;

     --
     -- release the lock
     --
     commit;

  end loop;

end ReInitialize_After_Table_Reorg;


begin
   g_cache.ui_initialized := FALSE;
   g_cache.lock_name := '$';
end;
