
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_INVOKER" AUTHID CURRENT_USER as
/* $Header: adinvsps.pls 120.0.12020000.3 2021/01/24 19:59:20 mkumandu noship $ */

--
-- Procedures and Functions
--
procedure get_rewrite_pkgs
           (is_incremental in varchar2);

--
-- Loads the AD_INVOKER_TASKS table with the list of packages,
--   procedures, and functions in the first APPS schema that need to
--   be re-written for Invoker's Rights
--
-- is_incremental can be either
--   'TRUE'  - only process PL/SQL objects that have changed since last run
--   'FALSE' - process all applicable PL/SQL objects
--
-- If for some reason the row for 'Invoker Maintenance', 'Last Run'
--   is missing from AD_TIMESTAMPS, get_rewrite_pkgs() will fail in
--   incremental mode.  This can be fixed by running the whole
--   Invoker's Rights processing logic in non-incremental mode
--   (via adadmin "Compile APPS Schema(s)")
--

procedure add_phase_boundary
           (num_workers in integer);

--
-- Loads the AD_INVOKER_TASKS table with a phase boundary,
--   which consists of one row per worker with the boundary_flag set
--

procedure get_grant_pkgs
           (is_incremental in varchar2);

--
-- Loads the AD_INVOKER_TASKS table with the list of packages,
--   procedures, functions, and Java objects in the first APPS schema
--   in a cross product with all of the other APPS schemas.
-- Will have to verify the grants/synonyms for each combination of
--   first and (2-N)th APPS schemas
--
-- is_incremental can be either
--   'TRUE'  - only process objects that have changed since last run
--   'FALSE' - process all applicable objects
--
-- If for some reason the row for 'Invoker Maintenance', 'Last Run'
--   is missing from AD_TIMESTAMPS, get_grant_pkgs() will fail in
--   incremental mode.  This can be fixed by running the whole
--   Invoker's Rights processing logic in non-incremental mode
--   (via adadmin "Compile APPS Schema(s)")
--

procedure invoker_maint_serial
           (is_incremental in varchar2);

--
-- Runs the whole Invoker's Rights maintenance logic in serial
--
-- Does not log errors to a table: just fails if encounters errors
--
-- The parallel version is strongly recommended over this version
--  (just use this from AutoPatch in serial mode)
--

procedure invoker_mrc_grants
           (apps_schema in varchar2,
            mrc_schema  in varchar2);

--
-- Runs the Invoker's Rights grants logic for MRC/MLS schemas
--
-- This replaces the non-invoker MRC logic that copies packages, procedures,
--   functions, and package bodies
--

procedure calculate_grant_types
           (worker_num in integer);

--
-- Sets the authid_flag and invoker_flag for the PL/SQL objects
--  that this worker will process.
--
-- Have to do this in the worker because the grant logic is different
--  depending on whether a given package is Invoker's Rights or
--  Definer's Rights, and any package that is re-written will change from
--  Definer's Rights to Invoker's Rights.
--

procedure assign_tasks
           (num_workers in integer);

--
-- Distribute the tasks evenly among the workers within each phase
-- Start each phase with worker 1.  Don't update any tasks in the
-- phase boundary rows.
--

procedure apps_ddl_check;

--
-- Doesn't do anything if no packages to process
-- If are packages to process:
--   Compiles any invalid APPS*DDL packages in the database
--   Checks for APPS_DDL and APPS_ARRAY_DDL packages in all APPS schemas
--

procedure update_done
           (what_row in rowid);

--
-- Sets AD_INVOKER_TASKS.DONE_FLAG to 'Y' for this particular row.
-- Commits the changes using an autonomous transaction
--

procedure rewrite_pkgs
           (worker_num in integer);

--
-- Re-writes the packages assigned to this worker to use
--   Invoker's Rights.
--

procedure rewrite_a_package
           (owner        in varchar2,
            name         in varchar2,
            type         in varchar2,
            new_owner    in varchar2,
            log_to_table in varchar2);

--
-- Rewrites a specific package to use Invoker's Rights.
--
-- if log_to_table is 'TRUE', writes errors to ad_parallel_compile_errors
--

procedure rewrite_plsql_array
           (the_array in out nocopy dbms_sql.varchar2s,
            lb        in     number,
            ub        in     number,
            type      in     varchar2);
--
-- Rewrites the PL/SQL object creation text stored in the array
--  to use Invoker's Rights.
--
-- DOES NOT CREATE THE OBJECT
--
-- Got most of the logic from rewrite_a_package
--

procedure grant_pkgs
           (worker_num in integer);

--
-- Creates/verifies the correct grants for all packages assigned
--   to this worker
--

procedure grant_a_package
           (owner        in varchar2,
            name         in varchar2,
            type         in varchar2,
            new_owner    in varchar2,
            authid_flag  in varchar2,
            invoker_flag in varchar2,
            log_to_table in varchar2);

--
-- Creates/verifies the correct grants for a specific package
--
-- if log_to_table is 'TRUE', writes errors to ad_parallel_compile_errors
--

procedure grant_a_java_object
           (owner        in varchar2,
            name         in varchar2,
            type         in varchar2,
            new_owner    in varchar2,
            log_to_table in varchar2);


--
-- Creates/verifies the correct grants for a specific Java object
--
-- if log_to_table is 'TRUE', writes errors to ad_parallel_compile_errors
--

procedure update_timestamp
           (in_type      in varchar2,
            in_attribute in varchar2);

procedure update_timestamp
           (in_type      in varchar2,
            in_attribute in varchar2,
            in_timestamp in date);

--
-- Updates/Inserts the row in AD_TIMESTAMPS for the specified
--  type and attribute
--

procedure verify_token_location
           (input_string   in  varchar2,
            input_token    in  varchar2,
            token_found    out nocopy varchar2,
            token_location out nocopy number);

--
-- Makes sure a given token does exist as a word in the input string
--   A word is delimited by white space on either side
--   (unless at the beginning or end of the string, in which case it is
--    only delimited by white space on one side)
--
-- token_found returns either 'TRUE' or 'FALSE'
--
-- token_location is the index of the token in the string (if found)
--   It's the same value that would be returned by the INSTR function
--
-- If the given token exists in multiple places in the string as a word,
--   we just return the first occurrence
--

procedure classify_plsql_object
           (owner        in  varchar2,
            name         in  varchar2,
            type         in  varchar2,
            has_authid   out nocopy varchar2,
            invoker_flag out nocopy varchar2);

--
-- Parses the source text for the given PL/SQL object
--
-- Sets has_authid to 'TRUE' if the object contains the AUTHID keyword
--   sets has_authid to 'FALSE' otherwise
--
-- Sets invoker_flag to 'I' (Invoker's Rights; AUTHID CURRENT_USER)
--  or 'D' (Definer's Rights; AUTHID DEFINER) if has_authid is 'TRUE'.
-- Sets invoker_flag to 'S' for Definer's Rights packages containing
--  the /*nosync*/ comment (exactly as written, and delimited by whitespace)
--  The /*nosync*/ comment must appear before the IS/AS keyword.
--
-- For wrapped package specs (procedures, functions), assumes definer's
--  rights, as we really have no way to parse them.  Not clear why anyone
--  would want to wrap these objects, though...
--

procedure classify_plsql_array
           (the_array    in  dbms_sql.varchar2s,
            lb           in  number,
            ub           in  number,
            type         in  varchar2,
            has_authid   out nocopy varchar2,
            invoker_flag out nocopy varchar2);

--
-- Parses the PL/SQL source text stored in the varchar2s array
--
-- Sets has_authid to 'TRUE' if the object contains the AUTHID keyword
--   sets has_authid to 'FALSE' otherwise
--
-- Sets invoker_flag to 'I' (Invoker's Rights; AUTHID CURRENT_USER)
--  or 'D' (Definer's Rights; AUTHID DEFINER) if has_authid is 'TRUE'
-- Sets invoker_flag to 'S' for Definer's Rights packages containing
--  the /*nosync*/ comment (exactly as written, and delimited by whitespace)
--  The /*nosync*/ comment must appear before the IS/AS keyword.
--
-- For wrapped package specs (procedures, functions), assumes definer's
--  rights, as we really have no way to parse them.  Not clear why anyone
--  would want to wrap these objects, though...
--

end ad_invoker;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_INVOKER" as
/* $Header: adinvspb.pls 120.0.12020000.4 2021/04/30 17:41:27 rsatyava noship $ */


--
-- Global private SQL cursors
--

cursor REWRITE_NOT_INCR is
  select do.owner,
				 do.object_name,
				 do.object_type
  from   sys.dba_objects do
  where  do.owner =(select o.oracle_username
                   from fnd_oracle_userid o
                   where o.read_only_flag = 'U'
                   and   o.install_group_num = 1)
  and    do.object_type in ('PROCEDURE', 'FUNCTION','PACKAGE')
  and    do.object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL')
	and    exists (SELECT 1
	               from  sys.dba_procedures dp
	               where dp.object_type in ('PROCEDURE', 'FUNCTION','PACKAGE')
								 and   dp.object_name = do.object_name
	               and   dp.object_type = do.object_type
                 and   dp.authid <> 'CURRENT_USER');

cursor REWRITE_INCR is
  select do.owner,
				 do.object_name,
				 do.object_type
  from   sys.dba_objects do, ad_timestamps t
  where  do.owner =(select o.oracle_username
                   from fnd_oracle_userid o
                   where o.read_only_flag = 'U'
                   and   o.install_group_num = 1)
	and    do.object_type in ('PROCEDURE', 'FUNCTION','PACKAGE')
  and    do.object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL')
	and    exists (SELECT 1
	               from  sys.dba_procedures dp
	               where dp.object_type in ('PROCEDURE', 'FUNCTION','PACKAGE')
								 and   dp.object_name = do.object_name
	               and   dp.object_type = do.object_type
                 and   dp.authid <> 'CURRENT_USER')
  and    t.type = 'Invoker Maintenance'
  and    t.attribute = 'Last Run'
  and    do.last_ddl_time >= t.timestamp;

cursor GRANTS_NOT_INCR is
  select do.owner, do.object_name, do.object_type, u.oracle_username
  from sys.dba_objects do, fnd_oracle_userid u
  where do.owner =
    (select o.oracle_username
     from fnd_oracle_userid o
     where o.read_only_flag = 'U'
     and   o.install_group_num = 1)
  and do.object_type in ('PACKAGE', 'PROCEDURE', 'FUNCTION',
                         'JAVA CLASS')
  and do.object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL')
  and u.read_only_flag = 'U'
  and u.install_group_num > 1;

cursor GRANTS_INCR is
  select do.owner, do.object_name, do.object_type, u.oracle_username
  from sys.dba_objects do, fnd_oracle_userid u, ad_timestamps t
  where do.owner =
    (select o.oracle_username
     from fnd_oracle_userid o
     where o.read_only_flag = 'U'
     and   o.install_group_num = 1)
  and do.object_type in ('PACKAGE', 'PROCEDURE', 'FUNCTION',
                         'JAVA CLASS')
  and do.object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL')
  and u.read_only_flag = 'U'
  and u.install_group_num > 1
  and t.type = 'Invoker Maintenance'
  and t.attribute = 'Last Run'
  and do.last_ddl_time >= t.timestamp;

cursor MRC_GRANTS_OBJ_ID (c_apps_schema in varchar2) is
  select do.owner, do.object_name, do.object_type
  from sys.dba_objects do
  where do.owner = upper(c_apps_schema)
  and do.object_type in ('PACKAGE', 'PROCEDURE', 'FUNCTION',
                         'JAVA CLASS')
  and do.object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL')
  and do.object_name not like 'FFP%';

-- Private data types

type rowid_list is table of rowid index by binary_integer;

type integer_list is table of integer index by binary_integer;

type owner_list_t is table of varchar2(30) index by binary_integer;

type object_name_list_t is table of varchar2(128) index by binary_integer;

type object_type_list_t is table of varchar2(18) index by binary_integer;

--
-- Procedures and Functions
--

/*
** log debug message, jwsmith, sql injection bug 25248691
** Debugging routine. You must create the table apps.log_debug_message
*/
procedure log_debug_message(text in varchar2)
is
begin
--  insert into apps.log_debug_message(message) values(text);
--  commit;
    null;
end log_debug_message;

procedure get_rewrite_pkgs
           (is_incremental in varchar2)
--
-- Loads the AD_INVOKER_TASKS table with the list of packages,
--   procedures, and functions in the first APPS schema that need to
--   be re-written for Invoker's Rights
--
-- is_incremental can be either
--   'TRUE'  - only process PL/SQL objects that have changed since last run
--   'FALSE' - process all applicable PL/SQL objects
--
-- If for some reason the row for 'Invoker Maintenance', 'Last Run'
--   is missing from AD_TIMESTAMPS, get_rewrite_pkgs() will fail in
--   incremental mode.  This can be fixed by running the whole
--   Invoker's Rights processing logic in non-incremental mode
--   (via adadmin "Compile APPS Schema(s)")
--
is
  found_authid  varchar2(10);
  invoker_flag  varchar2(10);
begin
  ad_apps_private.error_buf := null;
--
-- Insert rows into ad_invoker_tasks for all packages, procedures, and
--   functions that do not contain the 'AUTHID' keyword
--
-- Only look in the first APPS schema.
--

  if is_incremental = 'FALSE' then

    for c1 in REWRITE_NOT_INCR loop

       classify_plsql_object(c1.owner, c1.object_name, c1.object_type,
         found_authid, invoker_flag);

       if found_authid = 'FALSE' then

         insert into ad_invoker_tasks (
           phase, owner, name, type, other_schema,
           worker, done_flag, authid_flag, invoker_flag, boundary_flag)
         values (
           1, c1.owner, c1.object_name, c1.object_type, c1.owner,
           0, 'N', null, null, 'N');

       end if;
       -- end if no AUTHID keyword found -> needs rewrite

    end loop;
    -- end loop through PL/SQL specification objects in first APPS schema

  elsif is_incremental = 'TRUE' then

    for c1 in REWRITE_INCR loop

       classify_plsql_object(c1.owner, c1.object_name, c1.object_type,
         found_authid, invoker_flag);

       if found_authid = 'FALSE' then

         insert into ad_invoker_tasks (
           phase, owner, name, type, other_schema,
           worker, done_flag, authid_flag, invoker_flag, boundary_flag)
         values (
           1, c1.owner, c1.object_name, c1.object_type, c1.owner,
           0, 'N', null, null, 'N');

       end if;
       -- end if no AUTHID keyword found -> needs rewrite

    end loop;
    -- end loop through PL/SQL specification objects in first APPS schema
    -- that have changed since the last run

  else
    raise_application_error(-20000,
      'is_incremental must be either TRUE or FALSE');
  end if;

exception
  when others then
    ad_apps_private.error_buf := 'get_rewrite_pkgs(): '||
      ad_apps_private.error_buf;
    raise;
end get_rewrite_pkgs;


procedure add_phase_boundary
           (num_workers in integer)
--
-- Loads the AD_INVOKER_TASKS table with a phase boundary,
--   which consists of one row per worker with the boundary_flag set
--
is
  num_workers_local pls_integer;
  counter           pls_integer;
  statement         varchar2(300);
begin
  ad_apps_private.error_buf := null;
--
-- Insert a phase boundary
-- (actually a new phase with one row per worker)
--

-- Actual length: 225

  statement :=
    'insert into ad_invoker_tasks ('||
    'phase, owner, name, type, other_schema,'||
    'worker, done_flag, authid_flag, invoker_flag, boundary_flag)'||
    'values ('||
    '2, ''Boundary'', ''Boundary'', ''Boundary'', to_char(:wrk_num),'||
    ':wrk_num, ''N'', null, null, ''Y'')';

  for counter in 1..num_workers loop

    EXECUTE IMMEDIATE statement
    using counter, counter;

  end loop;

exception
  when others then
    ad_apps_private.error_buf := 'add_phase_boundary('||
      num_workers||'): '||
      ad_apps_private.error_buf;
    raise;
end add_phase_boundary;


procedure get_grant_pkgs
           (is_incremental in varchar2)
--
-- Loads the AD_INVOKER_TASKS table with the list of packages,
--   procedures, functions and Java objects in the first APPS schema
--   in a cross product with all of the other APPS schemas.
-- Will have to verify the grants/synonyms for each combination of
--   first and (2-N)th APPS schemas
--
-- is_incremental can be either
--   'TRUE'  - only process objects that have changed since last run
--   'FALSE' - process all applicable objects
--
-- If for some reason the row for 'Invoker Maintenance', 'Last Run'
--   is missing from AD_TIMESTAMPS, get_grant_pkgs() will fail in
--   incremental mode.  This can be fixed by running the whole
--   Invoker's Rights processing logic in non-incremental mode
--   (via adadmin "Compile APPS Schema(s)")
--
is
begin
  ad_apps_private.error_buf := null;
--
-- Create rows for each grant task.  Insert some data so later updates
--   can't cause row chaining.
--
-- If only one APPS schema, no rows are returned
--
-- Will update the rows later as follows:
--
--   authid_flag=N, invoker_flag=null
--     if no AUTHID keyword in PL/SQL object source
--
--   authid_flag=Y, invoker_flag=D
--     if AUTHID DEFINER in PL/SQL object source
--
--   authid_flag=Y, invoker_flag=I
--     if AUTHID CURRENT_USER in PL/SQL object source
--

  if is_incremental = 'FALSE' then

    for c1 in GRANTS_NOT_INCR loop

       insert into ad_invoker_tasks (
	 phase, owner, name, type, other_schema,
	 worker, done_flag, authid_flag, invoker_flag, boundary_flag)
       values (
	 3, c1.owner, c1.object_name, c1.object_type, c1.oracle_username,
	 0, 'N', 'X', 'X', 'N');

    end loop;
    -- end loop through PL/SQL specification objects in first APPS schema

  elsif is_incremental = 'TRUE' then

    for c1 in GRANTS_INCR loop

       insert into ad_invoker_tasks (
	 phase, owner, name, type, other_schema,
	 worker, done_flag, authid_flag, invoker_flag, boundary_flag)
       values (
	 3, c1.owner, c1.object_name, c1.object_type, c1.oracle_username,
	 0, 'N', 'X', 'X', 'N');

    end loop;
    -- end loop through PL/SQL specification objects in first APPS schema
    -- that have changed since the last run

  else
    raise_application_error(-20000,
      'is_incremental must be either TRUE or FALSE');
  end if;

exception
  when others then
    ad_apps_private.error_buf := 'get_grant_pkgs(): '||
      ad_apps_private.error_buf;
    raise;
end get_grant_pkgs;


procedure invoker_maint_serial
           (is_incremental in varchar2)
--
-- Runs the whole Invoker's Rights maintenance logic in serial
--
-- Does not log errors to a table: just fails if encounters errors
--
-- The parallel version is strongly recommended over this version
--  (just use this from AutoPatch in serial mode)
--
is
  found_authid  varchar2(10);
  invoker_flag  varchar2(10);
begin
  --
  -- Clear error buffer
  --

  ad_apps_private.error_buf := null;

  --
  -- Run rewrite logic
  --

  if is_incremental = 'FALSE' then

    for c1 in REWRITE_NOT_INCR loop

       classify_plsql_object(c1.owner, c1.object_name, c1.object_type,
         found_authid, invoker_flag);

       if found_authid = 'FALSE' then

	rewrite_a_package(c1.owner, c1.object_name, c1.object_type,
	  c1.owner, 'FALSE');

       end if;
       -- end if no AUTHID keyword found -> needs rewrite

    end loop;
    -- end loop through PL/SQL specification objects in first APPS schema

  elsif is_incremental = 'TRUE' then

    for c1 in REWRITE_INCR loop

       classify_plsql_object(c1.owner, c1.object_name, c1.object_type,
         found_authid, invoker_flag);

       if found_authid = 'FALSE' then

	rewrite_a_package(c1.owner, c1.object_name, c1.object_type,
	  c1.owner, 'FALSE');

       end if;
       -- end if no AUTHID keyword found -> needs rewrite

    end loop;
    -- end loop through PL/SQL specification objects in first APPS schema
    -- that have changed since the last run

  else
    raise_application_error(-20000,
      'is_incremental must be either TRUE or FALSE [1]');
  end if;

  --
  -- Run grant logic
  --

  if is_incremental = 'FALSE' then

    for c1 in GRANTS_NOT_INCR loop

       if (c1.object_type not like 'JAVA%') then

          classify_plsql_object(c1.owner, c1.object_name, c1.object_type,
   	     found_authid, invoker_flag);

           if found_authid = 'FALSE' then

	      grant_a_package(c1.owner, c1.object_name, c1.object_type,
	        c1.oracle_username, 'N', null, 'FALSE');

           else

	      grant_a_package(c1.owner, c1.object_name, c1.object_type,
	        c1.oracle_username, 'Y', invoker_flag, 'FALSE');

           end if;
           -- end if no AUTHID keyword found
       else
          grant_a_java_object(c1.owner, c1.object_name, c1.object_type,
                              c1.oracle_username, 'FALSE');
       end if;

    end loop;
    -- end loop through PL/SQL specification objects in first APPS schema

  elsif is_incremental = 'TRUE' then

    for c1 in GRANTS_INCR loop

       if (c1.object_type not like 'JAVA%') then

          classify_plsql_object(c1.owner, c1.object_name, c1.object_type,
	    found_authid, invoker_flag);

          if found_authid = 'FALSE' then

	     grant_a_package(c1.owner, c1.object_name, c1.object_type,
	       c1.oracle_username, 'N', null, 'FALSE');

          else

	     grant_a_package(c1.owner, c1.object_name, c1.object_type,
	       c1.oracle_username, 'Y', invoker_flag, 'FALSE');

          end if;
          -- end if no AUTHID keyword found
       else
          grant_a_java_object(c1.owner, c1.object_name, c1.object_type,
                              c1.oracle_username, 'FALSE');
       end if;
    end loop;
    -- end loop through PL/SQL specification objects in first APPS schema
    -- that have changed since the last run

  else
    raise_application_error(-20000,
      'is_incremental must be either TRUE or FALSE [2]');
  end if;

  --
  -- Update timestamp
  --

  update_timestamp('Invoker Maintenance','Last Run');

exception
  when others then
    ad_apps_private.error_buf := 'invoker_maint_serial('||
      is_incremental || '): '||
      ad_apps_private.error_buf;
    raise;
end invoker_maint_serial;


procedure invoker_mrc_grants
           (apps_schema in varchar2,
            mrc_schema  in varchar2)
--
-- Runs the Invoker's Rights grants logic for MRC/MLS schemas
--
-- This replaces the non-invoker MRC logic that copies packages, procedures,
--   functions, and package bodies
--
is
  found_authid           varchar2(10);
  invoker_flag           varchar2(10);
  owner_to_process       owner_list_t;
  object_name_to_process object_name_list_t;
  object_type_to_process object_type_list_t;
  row_index              binary_integer;
  row_count              binary_integer;
  the_owner              varchar2(30);
  the_obj_name           varchar2(128);
  the_obj_type           varchar2(30);
  the_mrc_schema         varchar2(30);

begin

   log_debug_message('Begin procedure invoke_mrc_grants ');

  --
  -- Clear error buffer
  --

  ad_apps_private.error_buf := null;

  -- set variables

  the_mrc_schema := upper(mrc_schema);

  --
  -- select row set to process into rows_to_process
  --

  row_index := 1;

  for c1 in MRC_GRANTS_OBJ_ID(apps_schema) loop

    owner_to_process(row_index) := c1.owner;
    object_name_to_process(row_index) := c1.object_name;
    object_type_to_process(row_index) := c1.object_type;

    row_index := row_index + 1;
  end loop;

  -- end loop through PL/SQL specification objects in APPS schema

  row_count := row_index - 1;

  --
  -- Run grant logic
  --

  for row_index in 1..row_count loop

    if (object_type_to_process(row_index) not like 'JAVA%') then
     classify_plsql_object(owner_to_process(row_index),
                           object_name_to_process(row_index),
                           object_type_to_process(row_index),
                           found_authid, invoker_flag);

     if found_authid = 'FALSE' then

       grant_a_package(owner_to_process(row_index),
                       object_name_to_process(row_index),
                       object_type_to_process(row_index),
	               the_mrc_schema, 'N', null, 'FALSE');

     else

       if invoker_flag = 'S' then

         --
         -- 'S' means this is a definer's rights package with the
         -- /*nosync*/ comment.  For regular APPS schemas, we do not
         -- copy it.  For MRC schemas, we want to treat it just like any
         -- other definer's rights package: copy it to MRC
         --

         grant_a_package(owner_to_process(row_index),
                         object_name_to_process(row_index),
                         object_type_to_process(row_index),
	                 the_mrc_schema, 'Y', 'D', 'FALSE');

       else

         grant_a_package(owner_to_process(row_index),
                         object_name_to_process(row_index),
                         object_type_to_process(row_index),
	                 the_mrc_schema, 'Y', invoker_flag, 'FALSE');

       end if;
       -- end if invoker_flag = 'S'

     end if;
     -- end if no AUTHID keyword found
    else
       grant_a_java_object(owner_to_process(row_index),
                           object_name_to_process(row_index),
                           object_type_to_process(row_index),
                           the_mrc_schema, 'FALSE');
    end if;

  end loop;
  -- end loop through PL/SQL specification objects in APPS schema

exception
  when others then
    ad_apps_private.error_buf := 'invoker_mrc_grants('||
      apps_schema ||', '|| mrc_schema || '): '||
      ad_apps_private.error_buf;
    raise;
   log_debug_message('End procedure invoke_mrc_grants ');
end invoker_mrc_grants;


procedure calculate_grant_types
           (worker_num in integer)
--
-- Sets the authid_flag and invoker_flag for the PL/SQL objects
--  that this worker will process.
--
-- Have to do this in the worker because the grant logic is different
--  depending on whether a given package is Invoker's Rights or
--  Definer's Rights, and any package that is re-written will change from
--  Definer's Rights to Invoker's Rights.
--
is
  cursor WORKER_GRANTS is
    select rowid, owner, name, type
    from ad_invoker_tasks
    where phase = 3
    and   type not like 'JAVA%'
    and   worker = calculate_grant_types.worker_num;
  found_authid  varchar2(10);
  invoker_flag  varchar2(10);
begin
  for c1 in WORKER_GRANTS loop

       classify_plsql_object(c1.owner, c1.name, c1.type,
         found_authid, invoker_flag);

       if found_authid = 'FALSE' then

         update ad_invoker_tasks
         set authid_flag = 'N',
             invoker_flag = null
         where rowid = c1.rowid;

       else

         update ad_invoker_tasks
         set authid_flag = 'Y',
             invoker_flag = calculate_grant_types.invoker_flag
         where rowid = c1.rowid;

       end if;
       -- end if no AUTHID keyword found

  end loop;
  -- end loop through grants that this worker will process

exception
  when others then
    ad_apps_private.error_buf := 'calculate_grant_types('||
      worker_num||'): '||
      ad_apps_private.error_buf;
    raise;
end calculate_grant_types;


procedure assign_tasks
           (num_workers in integer)
--
-- Distribute the tasks evenly among the workers within each phase
-- Start each phase with worker 1.  Don't update any tasks in the
-- phase boundary rows.
--
is
  cursor cs1 (phase_num in number) is
    select rowid
    from ad_invoker_tasks
    where phase = phase_num;
  counter           pls_integer;
  num_workers_local pls_integer;
begin
  ad_apps_private.error_buf := null;
  num_workers_local := num_workers;
--
-- Assign tasks for first phase (rewrite PL/SQL)
--
  counter := 1;

  for the_rec in cs1(1) loop

    if mod(counter, num_workers_local + 1) = 0 then
      counter := 1;
    end if;

    update ad_invoker_tasks
    set worker = counter
    where rowid = the_rec.rowid;

    counter := counter + 1;

  end loop;

--
-- Don't do anything to the second phase
-- (which actually serves as the phase boundary for the first phase)
--

--
-- Assign tasks for third phase (Do PL/SQL grants/synonyms)
--
  counter := 1;

  for the_rec in cs1(3) loop

    if mod(counter, num_workers_local + 1) = 0 then
      counter := 1;
    end if;

    update ad_invoker_tasks
    set worker = counter
    where rowid = the_rec.rowid;

    counter := counter + 1;

  end loop;

exception
  when others then
    ad_apps_private.error_buf := 'assign_tasks('||
      num_workers||'): '||
      ad_apps_private.error_buf;
    raise;
end assign_tasks;


procedure apps_ddl_check
--
-- Doesn't do anything if no packages to process
-- If are packages to process:
--   Compiles any invalid APPS*DDL packages in the database
--   Checks for APPS_DDL and APPS_ARRAY_DDL packages in all APPS schemas
--
is
  cursor ANY_INV_ROWS is
    select count(*)
    from ad_invoker_tasks
    where phase in (1, 3);
  cursor APPS_SCHEMAS is
    select oracle_username
    from fnd_oracle_userid
    where read_only_flag = 'U';
  num_rows number;
begin
--
-- Only run this check if we have anything to do
-- Otherwise, exit early
--
  open ANY_INV_ROWS;

  fetch ANY_INV_ROWS
  into num_rows;

  if ANY_INV_ROWS%NOTFOUND then
    close ANY_INV_ROWS;
    raise no_data_found;
  else
    close ANY_INV_ROWS;
  end if;

  if num_rows = 0 then
    return;
  end if;

--
-- If we got this far, there are rows to process, so we better make sure
-- that all of the APPS schemas have the proper APPS*DDL packages
--

-- First compile any invalid APPS*DDL packages in the whole database

  ad_compile.compile_apps_ddl;

-- Then verify that the APPS*DDL packages in the APPS schemas are OK

  for apps_rec in APPS_SCHEMAS loop

    ad_apps_private.check_for_apps_ddl(apps_rec.oracle_username);

  end loop;

exception
  when others then
    ad_apps_private.error_buf := 'apps_ddl_check(): '||
      ad_apps_private.error_buf;
    raise;
end apps_ddl_check;


procedure update_done
           (what_row in rowid)
--
-- Sets AD_INVOKER_TASKS.DONE_FLAG to 'Y' for this particular row.
-- Commits the changes using an autonomous transaction
--
is
  PRAGMA AUTONOMOUS_TRANSACTION;
begin

  update ad_invoker_tasks
  set done_flag = 'Y'
  where rowid = what_row;

  commit;

exception
  when others then
    ad_apps_private.error_buf := 'update_done('||
      what_row||'): '||
      ad_apps_private.error_buf;
    raise;
end update_done;


procedure rewrite_pkgs
           (worker_num in integer)
--
-- Re-writes the packages assigned to this worker to use
--   Invoker's Rights.
--
is
  rows_to_process rowid_list;
  row_index       binary_integer;
  row_count       binary_integer;
  the_owner       varchar2(30);
  obj_name        varchar2(128);
  obj_type        varchar2(30);
  other_schema    varchar2(30);
  is_done         varchar2(2);
  cursor c1 (worker_number in number) is
    select rowid the_row_id
    from ad_invoker_tasks
    where phase = 1
    and   worker = worker_number;
  cursor c2 (c_row_id in rowid) is
    select owner, name, type, other_schema, done_flag
    from ad_invoker_tasks
    where rowid = c_row_id;
begin
--
-- clear error buffer
--
  ad_apps_private.error_buf := null;

--
-- select row set to process into rows_to_process
--
  row_index := 1;
  for c1_rec in c1(worker_num) loop

    rows_to_process(row_index) := c1_rec.the_row_id;

    row_index := row_index + 1;
  end loop;

  row_count := row_index - 1;

--
-- actually process rows
--
  for row_index in 1..row_count loop

    open c2 (rows_to_process(row_index));

    fetch c2
    into the_owner, obj_name, obj_type, other_schema, is_done;

    if c2%NOTFOUND then
      close c2;
      raise no_data_found;
    end if;

    close c2;

    if nvl(is_done,'N') = 'N' then

      rewrite_a_package(the_owner, obj_name, obj_type, other_schema, 'TRUE');

      update_done(rows_to_process(row_index));

    end if;

  end loop;

exception
  when others then
    ad_apps_private.error_buf := 'rewrite_pkgs('||
      worker_num||'): '||
      ad_apps_private.error_buf;
    raise;
end rewrite_pkgs;


procedure rewrite_a_package
           (owner        in varchar2,
            name         in varchar2,
            type         in varchar2,
            new_owner    in varchar2,
            log_to_table in varchar2)
--
-- Rewrites a specific package to use Invoker's Rights.
--
-- if log_to_table is 'TRUE', writes errors to ad_parallel_compile_errors
--
-- Got most of the logic from ad_apps_private.copy_code
--
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  cursor c1 is
    select text from sys.dba_source
    where owner = upper(rewrite_a_package.owner)
    and name = upper(rewrite_a_package.name)
    and type = upper(rewrite_a_package.type)
    order by line;
  row_count        integer;
  source_line      varchar2(255);
  new_source_line  varchar2(300);
  found_authid     boolean;
  authid_line      number;
  found_is_as      boolean;
  is_as_line       number;
  word_location    number;
  is_as_position   number;
  we_found_it      varchar2(10);
  timestamp        varchar2(20);
  v_owner varchar2(128);
  v_name varchar2(128);
  v_type varchar2(128);
  v_new_owner varchar2(128);

begin

  log_debug_message('Begin procedure rewrite_a_package ');

--  dbms_output.put_line('rewrite_a_package('
--	  || owner ||', '|| name ||', '|| type ||', '
--          || v_new_owner || ', '|| log_to_table ||')');
--  return;

  -- Validate PL/SQL object type

  if     upper(type) <> 'PACKAGE'
     and upper(type) <> 'PROCEDURE'
     and upper(type) <> 'FUNCTION'  then

    if log_to_table = 'TRUE' then

      timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

      v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
      v_name  := sys.dbms_assert.enquote_name(name,FALSE);
      v_type  := sys.dbms_assert.enquote_name(type,FALSE);

      insert into ad_parallel_compile_errors (
	     owner, worker_number, timestamp, type, text)
      select upper(owner),
	     0,
	     timestamp,
	     '1 REWRITE ERROR',
             upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	       ': Object type "'||upper(v_type)||'" not supported.'
      from sys.dual;

    end if;
    -- end if log errors/messages to ad_parallel_compile_errors

    -- dbms_output.put_line('Do not know how to rewrite objects of type "'||
    --  upper(type)||'".');

    return;

  end if;
  -- end if not valid type

  -- Initialize variables

  found_authid := FALSE;
  found_is_as  := FALSE;

  authid_line  := 0;
  is_as_line   := 0;

  --
  -- get the source text
  -- purposely start counter at 1 as later we add the
  -- create or replace at line 1
  --
  -- parse the text while we're at it
  --
  row_count:=1;
  for c1rec in c1 loop
    row_count:=row_count+1;

    if not found_is_as then

      -- Check for AS

      word_location := instr(upper(c1rec.text),'AS');

      if word_location <> 0 then

        -- Do more strict checking

        verify_token_location(upper(c1rec.text), 'AS',
          we_found_it, word_location);

        if we_found_it = 'TRUE' then

	  found_is_as := TRUE;
	  is_as_line := row_count - 1;
	  is_as_position := word_location;
	  source_line := c1rec.text;

        end if;
        -- end if we really found AS

      end if;
      -- end if found AS using INSTR

      -- Check for IS

      word_location := instr(upper(c1rec.text),'IS');

      if word_location <> 0 then

        -- Do more strict checking

        verify_token_location(upper(c1rec.text), 'IS',
          we_found_it, word_location);

        if we_found_it = 'TRUE' then

	  found_is_as := TRUE;
	  is_as_line := row_count - 1;
	  is_as_position := word_location;
	  source_line := c1rec.text;

        end if;
        -- end if we really found IS

      end if;
      -- end if found IS using INSTR

      -- Check for AUTHID, and return if we find it

      word_location := instr(upper(c1rec.text),'AUTHID');

      if word_location <> 0 then

        -- Do more strict checking

        verify_token_location(upper(c1rec.text), 'AUTHID',
          we_found_it, word_location);

        if we_found_it = 'TRUE' then

	  -- If we found an AUTHID keyword, return

	  found_authid := TRUE;
	  authid_line := row_count - 1;

	  -- dbms_output.put_line('Found AUTHID at line '||authid_line);

          if log_to_table = 'TRUE' then

            timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

            v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
            v_name  := sys.dbms_assert.enquote_name(name,FALSE);
            v_type  := sys.dbms_assert.enquote_name(type,FALSE);

            insert into ad_parallel_compile_errors (
                   owner, worker_number, timestamp, type, text)
            select upper(owner),
                   0,
                   timestamp,
                   '1 REWRITE MESSAGE',
                   upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
                     ' contains AUTHID - Not rewritten'
            from sys.dual;

          end if;
          -- end if log errors/messages to ad_parallel_compile_errors

	  return;

        end if;
        -- end if we really found AUTHID

      end if;
      -- end if found AUTHID using INSTR

    end if;
    -- end parse lines until we find the IS/AS keyword

    -- build one line of sql statement in the global variable in
    -- the global array variable in to schema.

    if (length (c1rec.text) > 255) then

      -- text > 255 chars
      --
      -- log message to error table if requested
      -- ignore the error and return success
      --   (don't try to rewrite package)
      --

      if log_to_table = 'TRUE' then

	timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

        v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
        v_name  := sys.dbms_assert.enquote_name(name,FALSE);
        v_type  := sys.dbms_assert.enquote_name(type,FALSE);

	insert into ad_parallel_compile_errors (
	       owner, worker_number, timestamp, type, text)
	select upper(owner),
	       0,
	       timestamp,
	       '1 REWRITE MESSAGE',
	       upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
		 ' contains line(s) > 255 chars - Not rewritten'
	from sys.dual;

      end if;
      -- end if log errors/messages to ad_parallel_compile_errors

      return;

    else

      -- text <= 255 chars
      --
      -- just add to array of source text lines
      --
    ad_apps_private.do_array_assignment(rewrite_a_package.new_owner,
                c1rec.text, row_count);

    end if;
    -- end if text <= 255 chars

  end loop;
  -- end loop to get and parse source text

  --
  -- Alter the line on which we found the IS|AS
  --
  -- The parsing above is fairly good, but there are still a
  --   few failure cases I can think of (maybe more?):
  --
  --  1) it doesn't handle comments
  --
  --     We will ignore this for now
  --
  --  2) if the line is already pretty long, we will fail below if adding
  --     AUTHID CURRENT_USER pushes the length past 255
  --
  --     If the line would be too long, just exit the procedure without
  --     rewriting the PL/SQL object.  That's probably better than
  --     raising an exception.  If someone wonders why their PL/SQL
  --     object didn't get rewritten, we can always just explain
  --     that the rewrite routine doesn't work if the IS/AS keyword
  --     is on a long line.
  --

  if not found_is_as then
    --
    -- This should never happen
    -- If it does, just exit without editing the PL/SQL object
    --

    -- dbms_output.put_line('No IS/AS keyword found in '||upper(type)||' '||
    --   upper(owner)||'.'||upper(name));

    if log_to_table = 'TRUE' then

      timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

      v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
      v_name  := sys.dbms_assert.enquote_name(name,FALSE);
      v_type  := sys.dbms_assert.enquote_name(type,FALSE);

      insert into ad_parallel_compile_errors (
             owner, worker_number, timestamp, type, text)
      select upper(owner),
             0,
             timestamp,
             '1 REWRITE ERROR',
             upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
               ' has no IS/AS keyword - Not rewritten'
      from sys.dual;

    end if;
    -- end if log errors/messages to ad_parallel_compile_errors

    return;

  end if;
  -- end if didn't find IS/AS keyword

  --
  -- Rewrite PL/SQL object
  --

  new_source_line := substr(source_line,1,is_as_position-1)||
    'AUTHID CURRENT_USER '||substr(source_line,is_as_position);

  if length(new_source_line) > 255 then

    if log_to_table = 'TRUE' then

      timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

      v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
      v_name  := sys.dbms_assert.enquote_name(name,FALSE);
      v_type  := sys.dbms_assert.enquote_name(type,FALSE);

      insert into ad_parallel_compile_errors (
	     owner, worker_number, timestamp, type, text)
      select upper(owner),
	     0,
	     timestamp,
	     '1 REWRITE ERROR',
	     upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	       ' has IS/AS keyword on long line - Not rewritten'
      from sys.dual;

    end if;
    -- end if log errors/messages to ad_parallel_compile_errors

    return;
  end if;
  -- end if edited line is too long

  ad_apps_private.do_array_assignment(rewrite_a_package.new_owner,
	      new_source_line, is_as_line+1);

  --
  -- once we have fetched and processed all source
  -- then create the object
  --
  declare
    statement           varchar2(256);
    name_already_used   exception;
    pragma exception_init(name_already_used, -955);
  begin
    statement := 'create or replace ';
    -- build the first line of the array of sql statement
    ad_apps_private.do_array_assignment(rewrite_a_package.new_owner,
      statement, 1);
    -- execute the array of statement.
    ad_apps_private.do_apps_array_ddl(rewrite_a_package.new_owner,
     1, row_count);
  exception
    when name_already_used then
      --
      -- This should never happen, but it doesn't hurt to leave this
      --  code here
      --
      -- first reset error buf
      ad_apps_private.error_buf := null;
      -- drop any synonym by such name and retry
      ad_apps_private.drop_object(rewrite_a_package.new_owner,
                  upper(rewrite_a_package.name), 'SYNONYM');
      ad_apps_private.do_apps_array_ddl(rewrite_a_package.new_owner,
       1, row_count);
  end;

exception
  when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
    -- reset main error buffer
    ad_apps_private.error_buf := null;
  when others then
    declare
      sql_error varchar2(1996);
    begin
      if log_to_table = 'TRUE' then

	timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

        v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
        v_name  := sys.dbms_assert.enquote_name(name,FALSE);
        v_type  := sys.dbms_assert.enquote_name(type,FALSE);

	insert into ad_parallel_compile_errors (
	       owner, worker_number, timestamp, type, text)
	select upper(owner),
	       0,
	       timestamp,
	       '1 REWRITE ERROR - A',
               upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
		 ': Generic error occurred.'
	from sys.dual;

        sql_error := SQLERRM;

-- Sql Injection Bug 25248691

	insert into ad_parallel_compile_errors (
	       owner, worker_number, timestamp, type, text)
	select upper(owner),
	       0,
	       timestamp,
	       '1 REWRITE ERROR - B',
               substr(upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	       ': '||sql_error,1,1996)
	from sys.dual;

        if ad_apps_private.error_buf is not null then

-- Sql Injection Bug 25248691

	  insert into ad_parallel_compile_errors (
		 owner, worker_number, timestamp, type, text)
	  select upper(owner),
		 0,
		 timestamp,
 		 '1 REWRITE ERROR - C',
                 substr(upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	           ': '||ad_apps_private.error_buf,1,1996)
	  from sys.dual;

        end if;
        -- error buf contains information

        -- clear error buf
        ad_apps_private.error_buf := null;

      else
	raise;
      end if;
      -- end if log errors/messages to ad_parallel_compile_errors
    exception
      -- should only fire if we have errors writing to the log table
      -- Sql Injection Bug 25248691
      when others then
	ad_apps_private.error_buf := 'rewrite_a_package('
	  || owner ||', '|| name ||', '|| type ||', '
          || new_owner || ', '|| log_to_table ||'): '||
	  ad_apps_private.error_buf;
	raise;
    end;
  log_debug_message('End procedure rewrite_a_package ');
end rewrite_a_package;


procedure rewrite_plsql_array
           (the_array    in out nocopy dbms_sql.varchar2s,
            lb           in     number,
            ub           in     number,
            type         in     varchar2)
--
-- Rewrites the PL/SQL object creation text stored in the array
--  to use Invoker's Rights.
--
-- DOES NOT CREATE THE OBJECT
--
-- Got most of the logic from rewrite_a_package
--
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  source_line      varchar2(255);
  new_source_line  varchar2(300);
  found_authid     boolean;
  authid_line      number;
  found_is_as      boolean;
  is_as_line       number;
  word_location    number;
  is_as_position   number;
  we_found_it      varchar2(10);
  timestamp        varchar2(20);
begin
  -- Validate PL/SQL object type

  if     upper(type) <> 'PACKAGE'
     and upper(type) <> 'PROCEDURE'
     and upper(type) <> 'FUNCTION'  then

    raise_application_error(-20000,
    'Do not know how to rewrite objects of type "'|| upper(type)||'".');

  end if;
  -- end if not valid type

  -- Initialize variables

  found_authid := FALSE;
  found_is_as  := FALSE;

  authid_line  := 0;
  is_as_line   := 0;

  --
  -- loop through and parse source text
  --

  for counter in lb..ub loop

    if not found_is_as then

      -- Check for AS

      word_location := instr(upper(the_array(counter)),'AS');

      if word_location <> 0 then

        -- Do more strict checking

        verify_token_location(upper(the_array(counter)), 'AS',
          we_found_it, word_location);

        if we_found_it = 'TRUE' then

	  found_is_as := TRUE;
	  is_as_line := counter;
	  is_as_position := word_location;
	  source_line := the_array(counter);

        end if;
        -- end if we really found AS

      end if;
      -- end if found AS using INSTR

      -- Check for IS

      word_location := instr(upper(the_array(counter)),'IS');

      if word_location <> 0 then

        -- Do more strict checking

        verify_token_location(upper(the_array(counter)), 'IS',
          we_found_it, word_location);

        if we_found_it = 'TRUE' then

	  found_is_as := TRUE;
	  is_as_line := counter;
	  is_as_position := word_location;
	  source_line := the_array(counter);

        end if;
        -- end if we really found IS

      end if;
      -- end if found IS using INSTR

      -- Check for AUTHID

      word_location := instr(upper(the_array(counter)),'AUTHID');

      if word_location <> 0 then

        -- Do more strict checking

        verify_token_location(upper(the_array(counter)), 'AUTHID',
          we_found_it, word_location);

        if we_found_it = 'TRUE' then

	  -- We found an AUTHID keyword

	  found_authid := TRUE;
	  authid_line := counter;

	  -- dbms_output.put_line('Found AUTHID at line '||authid_line);

        end if;
        -- end if we really found AUTHID

      end if;
      -- end if found AUTHID using INSTR

    else
      -- if we already found the IS/AS keyword, break out of the loop

      exit;

    end if;
    -- end parse lines until we find the IS/AS keyword

  end loop;
  -- end loop to get and parse source text

  -- just exit if found authid keyword, as nothing needs to be rewritten

  if found_authid then
    return;
  end if;

  --
  -- Alter the line on which we found the IS|AS
  --
  -- The parsing above is fairly good, but there are still a
  --   few failure cases I can think of (maybe more?):
  --
  --  1) it doesn't handle comments
  --
  --     We will ignore this for now
  --
  --  2) if the line is already pretty long, we will fail below if adding
  --     AUTHID CURRENT_USER pushes the length past 255
  --
  --     If the line would be too long, just exit the procedure without
  --     rewriting the PL/SQL object.  That's probably better than
  --     raising an exception.  If someone wonders why their PL/SQL
  --     object didn't get rewritten, we can always just explain
  --     that the rewrite routine doesn't work if the IS/AS keyword
  --     is on a long line.
  --

  if not found_is_as then
    --
    -- This should never happen
    --
    -- If it does, exit without rewriting the source text
    --

    return;

  end if;
  -- end if didn't find IS/AS keyword

  --
  -- Rewrite PL/SQL object creation line
  --

  new_source_line := substr(source_line,1,is_as_position-1)||
    'AUTHID CURRENT_USER '||substr(source_line,is_as_position);

  if length(new_source_line) > 255 then

    raise_application_error(-20000,
    'Source text too long at line '||is_as_position);

  end if;
  -- end if edited line is too long

  the_array(is_as_line) := new_source_line;

exception
  when others then
    ad_apps_private.error_buf := 'rewrite_plsql_array('
      || ' <array>, '|| lb ||', ' || ub ||', '
      || type || ' ): '||
      ad_apps_private.error_buf;
    raise;
end rewrite_plsql_array;


procedure grant_pkgs
           (worker_num in integer)
--
-- Creates/verifies the correct grants for all packages and Java classes
--  assigned to this worker
--
is
  cursor c1 (worker_number in number) is
    select rowid, owner, name, type, other_schema,
      authid_flag, invoker_flag, done_flag
    from ad_invoker_tasks
    where phase = 3
    and   worker = worker_number;
begin
--
-- clear error buffer
--
  ad_apps_private.error_buf := null;

  for c1_rec in c1(worker_num) loop

    if nvl(c1_rec.done_flag,'N') = 'N' then

      if (c1_rec.type not like 'JAVA%') then
         grant_a_package(c1_rec.owner, c1_rec.name, c1_rec.type,
           c1_rec.other_schema, c1_rec.authid_flag, c1_rec.invoker_flag,
           'TRUE');
      else
         grant_a_java_object(c1_rec.owner, c1_rec.name, c1_rec.type,
           c1_rec.other_schema, 'TRUE');
      end if;

      update_done(c1_rec.rowid);

    end if;

  end loop;

exception
  when others then
    ad_apps_private.error_buf := 'grant_pkgs('||
      worker_num||'): '||
      ad_apps_private.error_buf;
    raise;
end grant_pkgs;


procedure grant_a_package
           (owner        in varchar2,
            name         in varchar2,
            type         in varchar2,
            new_owner    in varchar2,
            authid_flag  in varchar2,
            invoker_flag in varchar2,
            log_to_table in varchar2)
--
-- Creates/verifies the correct grants for a specific package
--
-- if log_to_table is 'TRUE', writes errors to ad_parallel_compile_errors
--
is
  invoker_plsql    boolean;
  definer_plsql    boolean;
  nosync_plsql     boolean;
  statement        varchar2(200);
  synonym_ok       boolean;
  any_obj_w_name   boolean;
  type_of_object   varchar2(30);
  obj_type_new     varchar2(30);
  timestamp        varchar2(20);
  exact_code_match varchar2(10);
  v_owner varchar2(128);
  v_name varchar2(128);
  v_type varchar2(128);
  v_new_owner varchar2(128);

begin
  log_debug_message('Begin procedure grant_a_package ');

--  dbms_output.put_line('grant_a_package('
--	  || owner ||', '|| name ||', '|| type ||', '|| new_owner
--	  || ', '|| authid_flag || ', '|| invoker_flag
--	  || ', '|| log_to_table ||')');
--  return;

  -- Validate PL/SQL object type

  if     upper(type) <> 'PACKAGE'
     and upper(type) <> 'PROCEDURE'
     and upper(type) <> 'FUNCTION'  then

    if log_to_table = 'TRUE' then

      timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

      v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
      v_name  := sys.dbms_assert.enquote_name(name,FALSE);
      v_type  := sys.dbms_assert.enquote_name(type,FALSE);

      insert into ad_parallel_compile_errors (
	     owner, worker_number, timestamp, type, text)
      select upper(owner),
	     0,
	     timestamp,
	     '3 GRANT ERROR',
             upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	       ': Object type '||upper(v_type)||' not supported.'
      from sys.dual;

      return;

    else

      raise_application_error(-20000,upper(type)||' '||upper(owner)||
        '.'||upper(name)||': Object type "'||upper(type)||
        '" not supported.');

    end if;
    -- end if log errors/messages to ad_parallel_compile_errors

  end if;
  -- end if not valid type

  -- Init variables

  invoker_plsql := FALSE;
  definer_plsql := FALSE;
  nosync_plsql  := FALSE;

  --
  -- Decide how to handle this PL/SQL object, based on
  --   authid_flag and invoker_flag

  if    authid_flag = 'N' then

    definer_plsql := TRUE;

  elsif authid_flag = 'Y' then

    if    invoker_flag = 'I' then

      invoker_plsql := TRUE;

    elsif invoker_flag = 'D' then

      definer_plsql := TRUE;

    elsif invoker_flag = 'S' then

      nosync_plsql  := TRUE;

    else

      if log_to_table = 'TRUE' then

	timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

      v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
      v_name  := sys.dbms_assert.enquote_name(name,FALSE);
      v_type  := sys.dbms_assert.enquote_name(type,FALSE);

	insert into ad_parallel_compile_errors (
	       owner, worker_number, timestamp, type, text)
	select upper(owner),
	       0,
	       timestamp,
	       '3 GRANT ERROR',
	       upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
               ': Invalid value for invoker_flag: "'||invoker_flag||'"'
	from sys.dual;

	return;

      else

	raise_application_error(-20000,upper(type)||' '||upper(owner)||
          '.'||upper(name)||': Invalid value for invoker_flag: "'||
	  invoker_flag||'"');

      end if;
      -- end if log errors to table

    end if;
    -- end if statement to handle/validate settings for invoker_flag

  else

    if log_to_table = 'TRUE' then

      timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

      v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
      v_name  := sys.dbms_assert.enquote_name(name,FALSE);
      v_type  := sys.dbms_assert.enquote_name(type,FALSE);

      insert into ad_parallel_compile_errors (
	     owner, worker_number, timestamp, type, text)
      select upper(owner),
	     0,
	     timestamp,
	     '3 GRANT ERROR',
	     upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	     ': Invalid value for authid_flag: "'||authid_flag||'"'
      from sys.dual;

      return;

    else

      raise_application_error(-20000,upper(type)||' '||upper(owner)||
	'.'||upper(name)||': Invalid value for authid_flag: "'||
	authid_flag||'"');

    end if;
    -- end if log errors to table

  end if;
  -- end if statement to figure out how to handle this PL/SQL object

  --
  -- Perform correct logic based on classification of this PL/SQL object
  --

  if    invoker_plsql then

    --
    -- Create grant
    --

-- Sql Injection Bug 25248691

    v_name :=sys.dbms_assert.enquote_name(name,FALSE);
    v_new_owner :=sys.dbms_assert.enquote_name(new_owner,FALSE);

    statement := 'grant all on '||upper(v_name)||' to '||upper(v_new_owner)||
      ' with grant option';

    ad_apps_private.do_apps_ddl(upper(owner), statement);

    --
    -- Check for correct synonym
    --

    ad_apps_private.exact_synonym_match(upper(new_owner), upper(name),
      upper(owner), upper(name), synonym_ok, any_obj_w_name,
      type_of_object);

    if not synonym_ok then

      --
      -- drop any existing object with this name
      --

      if any_obj_w_name then

	if    type_of_object = 'PKG_S_AND_B'
	   or type_of_object = 'PACKAGE'
	   or type_of_object = 'PACKAGE BODY' then
	  -- existing object is package

	  ad_apps_private.drop_object(upper(new_owner), upper(name),
				      'PACKAGE');
	else
	  -- existing object not package

	  ad_apps_private.drop_object(upper(new_owner), upper(name),
				      type_of_object);
	end if;
	-- end if existing object is package

      end if;
      -- end if any existing object with this name

      --
      -- then create correct synonym
      --

-- Sql Injection Bug 25248691

      v_name :=sys.dbms_assert.enquote_name(name,FALSE);
      v_new_owner :=sys.dbms_assert.enquote_name(new_owner,FALSE);
      v_owner := sys.dbms_assert.enquote_name(owner,FALSE);

      statement := 'create synonym '||upper(v_name)||' for '||upper(v_owner)||
        '.'||upper(v_name);

      ad_apps_private.do_apps_ddl(upper(new_owner), statement);

    end if;
    -- end if synonym was not exactly correct

  elsif definer_plsql then

    --
    -- Check to see if there is any object in the other schema
    --   with this name
    --

    ad_apps_private.exact_synonym_match(upper(new_owner), upper(name),
      upper(owner), upper(name), synonym_ok, any_obj_w_name,
      type_of_object);

    if any_obj_w_name then

      --
      -- if not the right type of object, drop it and recreate as
      --   a copy of the current object
      --

      if     type_of_object <> upper(type)
         and not (    upper(type) = 'PACKAGE'
                  and type_of_object = 'PKG_S_AND_B') then

        --
        -- Drop existing object from other schema
        --

	if    type_of_object = 'PKG_S_AND_B'
	   or type_of_object = 'PACKAGE'
	   or type_of_object = 'PACKAGE BODY' then
	  -- existing object is package

	  ad_apps_private.drop_object(upper(new_owner), upper(name),
				      'PACKAGE');
	else
	  -- existing object not package

	  ad_apps_private.drop_object(upper(new_owner), upper(name),
				      type_of_object);
	end if;
	-- end if existing object is package

        --
        -- Create a copy of this object in the other schema
        --

	ad_apps_private.copy_code(upper(name), upper(type), upper(owner),
	  upper(new_owner));

	--
	-- If object is a package and the package body exists
	--   in the source schema, also copy the package body
	--   to the other schema
	--

	ad_apps_private.exact_synonym_match(upper(owner), upper(name),
	  upper(owner), upper(name), synonym_ok, any_obj_w_name,
	  type_of_object);

	if any_obj_w_name and type_of_object = 'PKG_S_AND_B' then

	  ad_apps_private.copy_code(upper(name), 'PACKAGE BODY', upper(owner),
	    upper(new_owner));

	end if;
	-- end if object is package spec, and corresponding body exists

      else

        --
        -- Correct type in other schema
        --   Compare to validate that it exactly matches the object
        --   from the owner schema
        --

        ad_apps_private.compare_code(upper(name), upper(type), upper(owner),
          upper(new_owner), 'FULL', exact_code_match);

        --
        -- If code matches exactly, don't do anything
        -- If code doesn't match exactly, recopy code from owner schema
        --   to new schema
        --

        if exact_code_match <> 'TRUE' then

	  ad_apps_private.copy_code(upper(name), upper(type), upper(owner),
	    upper(new_owner));

        end if;
        -- end if code does not match exactly

	--
	-- If object is a package and the package body exists
	--   in the source schema, also compare the package body text
        --   with the package body in the other schema
	--

        -- save object type in other schema for use below

        obj_type_new := type_of_object;

        -- now find out if this is a package that also has a body

	ad_apps_private.exact_synonym_match(upper(owner), upper(name),
	  upper(owner), upper(name), synonym_ok, any_obj_w_name,
	  type_of_object);

	if any_obj_w_name and type_of_object = 'PKG_S_AND_B' then

          --
          -- if type in other schema is just 'PACKAGE', unconditionally
          --   copy the body over
          --
          -- if type is 'PKG_S_AND_B', then compare the bodies and then
          --   only copy the body over if not identical
          --

          if obj_type_new = 'PACKAGE' then

	    ad_apps_private.copy_code(upper(name), 'PACKAGE BODY',
              upper(owner), upper(new_owner));

          elsif obj_type_new = 'PKG_S_AND_B' then

            --
            -- Compare pkg bodies
            --

	    ad_apps_private.compare_code(upper(name), 'PACKAGE BODY',
              upper(owner), upper(new_owner), 'FULL', exact_code_match);

	    --
	    -- If code matches exactly, don't do anything
	    -- If code doesn't match exactly, recopy code from owner schema
	    --   to new schema
	    --

	    if exact_code_match <> 'TRUE' then

	      ad_apps_private.copy_code(upper(name), 'PACKAGE BODY',
                upper(owner), upper(new_owner));

	    end if;
	    -- end if code does not match exactly

          else

	    if log_to_table = 'TRUE' then

	      timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

              v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
              v_name  := sys.dbms_assert.enquote_name(name,FALSE);
              v_type  := sys.dbms_assert.enquote_name(type,FALSE);

	      insert into ad_parallel_compile_errors (
		     owner, worker_number, timestamp, type, text)
	      select upper(owner),
		     0,
		     timestamp,
		     '3 GRANT ERROR',
		     upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
		     ': Internal error [pkg]'
	      from sys.dual;

	      return;

	    else

	      raise_application_error(-20000,upper(type)||' '||upper(owner)||
		'.'||upper(name)||': Internal error [pkg]');

	    end if;
	    -- end if log errors to table

          end if;
          -- end if this is a package spec and body combination, but
          --  only the spec exists in the other schema

	end if;
	-- end if object is package spec, and corresponding body exists

      end if;
      -- end if object types differ

    else

      --
      -- No object with this name.  Copy object to other schema
      --

      ad_apps_private.copy_code(upper(name), upper(type), upper(owner),
        upper(new_owner));

      --
      -- If object is a package and the package body exists
      --   in the source schema, also copy the package body
      --   to the other schema
      --

      ad_apps_private.exact_synonym_match(upper(owner), upper(name),
	upper(owner), upper(name), synonym_ok, any_obj_w_name,
	type_of_object);

      if any_obj_w_name and type_of_object = 'PKG_S_AND_B' then

	ad_apps_private.copy_code(upper(name), 'PACKAGE BODY', upper(owner),
	  upper(new_owner));

      end if;
      -- end if object is package spec, and corresponding body exists

    end if;
    -- end if there is already an object in the dest schema with this name

  elsif nosync_plsql then

    -- Don't do anything for Definer's Rights PL/SQL that contains the
    --   /*nosync*/ comment

    return;

  else

    if log_to_table = 'TRUE' then

      timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

      v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
      v_name  := sys.dbms_assert.enquote_name(name,FALSE);
      v_type  := sys.dbms_assert.enquote_name(type,FALSE);

      insert into ad_parallel_compile_errors (
	     owner, worker_number, timestamp, type, text)
      select upper(owner),
	     0,
	     timestamp,
	     '3 GRANT ERROR',
	     upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	     ': Internal error [classification]'
      from sys.dual;

      return;

    else

      raise_application_error(-20000,upper(type)||' '||upper(owner)||
	'.'||upper(name)||': Internal error [classification]');

    end if;
    -- end if log errors to table

  end if;
  -- End process PL/SQL object based on its type

exception
  when others then
    declare
      sql_error varchar2(1996);
    begin
      if log_to_table = 'TRUE' then

	timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

        v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
        v_name  := sys.dbms_assert.enquote_name(name,FALSE);
        v_type  := sys.dbms_assert.enquote_name(type,FALSE);

	insert into ad_parallel_compile_errors (
	       owner, worker_number, timestamp, type, text)
	select upper(owner),
	       0,
	       timestamp,
	       '3 GRANT ERROR - A',
               upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
		 ': Generic error occurred.'
	from sys.dual;

        sql_error := SQLERRM;

	insert into ad_parallel_compile_errors (
	       owner, worker_number, timestamp, type, text)
	select upper(owner),
	       0,
	       timestamp,
	       '3 GRANT ERROR - B',
               substr(upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	       ': '||sql_error,1,1996)
	from sys.dual;

        if ad_apps_private.error_buf is not null then

	  insert into ad_parallel_compile_errors (
		 owner, worker_number, timestamp, type, text)
	  select upper(owner),
		 0,
		 timestamp,
 		 '3 GRANT ERROR - C',
                 substr(upper(v_type)||' '||upper(v_owner)||'.'||upper(v_name)||
	           ': '||ad_apps_private.error_buf,1,1996)
	  from sys.dual;

        end if;
        -- error buf contains information

        -- clear error buf
        ad_apps_private.error_buf := null;

      else
	raise;
      end if;
      -- end if log errors/messages to ad_parallel_compile_errors
    exception
      -- should only fire if we have errors writing to the log table
      when others then
	ad_apps_private.error_buf := 'grant_a_package('
	  || owner ||', '|| name ||', '|| type ||', '|| new_owner
	  || ', '|| authid_flag || ', '|| invoker_flag
	  || ', '|| log_to_table ||'): '||
	  ad_apps_private.error_buf;
	raise;
    end;
  log_debug_message('End procedure grant_a_package ');
end grant_a_package;

procedure grant_a_java_object
           (owner        in varchar2,
            name         in varchar2,
            type         in varchar2,
            new_owner    in varchar2,
            log_to_table in varchar2)
--
-- Creates/verifies the correct grants for a specific Java object
--
-- if log_to_table is 'TRUE', writes errors to ad_parallel_compile_errors
--
is
  statement        varchar2(200);
  synonym_ok       boolean;
  any_obj_w_name   boolean;
  type_of_object   varchar2(30);
  obj_type_new     varchar2(30);
  timestamp        varchar2(20);
  v_owner varchar2(128);
  v_name varchar2(128);
  v_type varchar2(128);
  v_new_owner varchar2(128);


begin
-- Sql Injection Bug 25248691
  log_debug_message('Begin procedure grant_a_java_object ');

  -- Validate Java  object type

  if (upper(type) not in ('JAVA CLASS')) then

    if log_to_table = 'TRUE' then

      timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

        v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
        v_name  := sys.dbms_assert.enquote_name(name,FALSE);
        v_type  := sys.dbms_assert.enquote_name(type,FALSE);

      insert into ad_parallel_compile_errors (
	     owner, worker_number, timestamp, type, text)
      select upper(owner),
	     0,
	     timestamp,
	     '3 GRANT ERROR',
             upper(v_type)||' '||upper(v_owner)||'.'||v_name||
	       ': Object type '||upper(v_type)||' not supported.'
      from sys.dual;

      return;

    else

      raise_application_error(-20000,upper(type)||' '||upper(owner)||
        '.'||name||': Object type "'||upper(type)||
        '" not supported.');

    end if;
    -- end if log errors/messages to ad_parallel_compile_errors

  end if;
  -- end if not valid type

  --
  -- Create grant
  --

-- Sql Injection Bug 25248691

        v_name  := sys.dbms_assert.enquote_name(name,FALSE);
        v_new_owner  := sys.dbms_assert.enquote_name(new_owner,FALSE);

  statement := 'grant all on '||v_name||' to '||upper(v_new_owner)||
    ' with grant option';

  ad_apps_private.do_apps_ddl(upper(owner), statement);

  --
  -- Check for correct synonym
  --

  ad_apps_private.exact_synonym_match(upper(new_owner), name,
    upper(owner), name, synonym_ok, any_obj_w_name,
    type_of_object);

  if not synonym_ok then

    --
    -- drop any existing object with this name
    --

    if any_obj_w_name then

	if    type_of_object = 'JAVA CLASS'
	   or type_of_object = 'JAVA RESOURCE' then
	  -- existing object is Java object

	  ad_apps_private.drop_object(upper(new_owner), name,
				      type_of_object);
	else
	  -- existing object not Java object


	  ad_apps_private.drop_object(upper(new_owner), name,
				      type_of_object);
	end if;
	-- end if existing object is Java object

    end if;
    -- end if any existing object with this name

    --
    -- then create correct synonym
    --

-- Sql Injection Bug 25248691

        v_name  := sys.dbms_assert.enquote_name(name,FALSE);
        v_new_owner  := sys.dbms_assert.enquote_name(name,FALSE);

    statement := 'create synonym '||v_name||' for '||upper(v_owner)||
      '.'||v_name||'';

    ad_apps_private.do_apps_ddl(upper(new_owner), statement);

  end if;
  -- end if synonym was not exactly correct

  -- End process Java object

exception
  when others then
    declare
      sql_error varchar2(1996);
    begin
      if log_to_table = 'TRUE' then

	timestamp := to_char(sysdate,'YYYY-MM-DD:HH24:MI:SS');

-- Sql Injection Bug 25248691

        v_owner := sys.dbms_assert.enquote_name(owner,FALSE);
        v_name  := sys.dbms_assert.enquote_name(name,FALSE);
        v_type  := sys.dbms_assert.enquote_name(type,FALSE);

	insert into ad_parallel_compile_errors (
	       owner, worker_number, timestamp, type, text)
	select upper(owner),
	       0,
	       timestamp,
	       '3 GRANT ERROR - A',
               upper(v_type)||' '||upper(v_owner)||'.'||v_name||
		 ': Generic error occurred.'
	from sys.dual;

        sql_error := SQLERRM;

	insert into ad_parallel_compile_errors (
	       owner, worker_number, timestamp, type, text)
	select upper(owner),
	       0,
	       timestamp,
	       '3 GRANT ERROR - B',
               substr(upper(v_type)||' '||upper(v_owner)||'.'||v_name||
	       ': '||sql_error,1,1996)
	from sys.dual;

        if ad_apps_private.error_buf is not null then

	  insert into ad_parallel_compile_errors (
		 owner, worker_number, timestamp, type, text)
	  select upper(owner),
		 0,
		 timestamp,
 		 '3 GRANT ERROR - C',
                 substr(upper(v_type)||' '||upper(v_owner)||'.'||v_name||
	           ': '||ad_apps_private.error_buf,1,1996)
	  from sys.dual;

        end if;
        -- error buf contains information

        -- clear error buf
        ad_apps_private.error_buf := null;

      else
	raise;
      end if;
      -- end if log errors/messages to ad_parallel_compile_errors
    exception
      -- should only fire if we have errors writing to the log table
      when others then
	ad_apps_private.error_buf := 'grant_a_java_object('
	  || owner ||', '|| name ||', '|| type ||', '|| new_owner
	  || ', '|| log_to_table ||'): '||
	  ad_apps_private.error_buf;
	raise;
    end;
  log_debug_message('End procedure grant_a_java_object ');
end grant_a_java_object;



-- Bug 3611969 : FIXED FILE.SQL.35 GSCC WARNINGS
-- sraghuve (07/05/2004)

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
  update ad_timestamps
  set timestamp = in_timestamp
  where type = in_type
  and attribute = in_attribute;

  if SQL%ROWCOUNT = 1 then
    return;
  end if;
--
-- Insert if no rows updated
--
  insert into ad_timestamps
  (type, attribute, timestamp)
  values (in_type, in_attribute, in_timestamp);

exception
  when others then
    ad_apps_private.error_buf := 'update_timestamp('
      || in_type ||', '|| in_attribute ||', '||
      to_char(in_timestamp,'YYYY-MM-DD:HH24:MI:SS') ||'): '||
      ad_apps_private.error_buf;
    raise;
end update_timestamp;


procedure verify_token_location
           (input_string   in  varchar2,
            input_token    in  varchar2,
            token_found    out nocopy varchar2,
            token_location out nocopy number)
--
-- Makes sure a given token does exist as a word in the input string
--   A word is delimited by white space on either side
--   (unless at the beginning or end of the string, in which case it is
--    only delimited by white space on one side)
--
-- token_found returns either 'TRUE' or 'FALSE'
--
-- token_location is the index of the token in the string (if found)
--   It's the same value that would be returned by the INSTR function
--
-- If the given token exists in multiple places in the string as a word,
--   we just return the first occurrence
--
-- Added (SYS_CONTEXT('USERENV','LANGUAGE') for MRC bug 3697501
--


is

  a_space       constant varchar2(10) :=
    CONVERT(CHR(32), substr(SYS_CONTEXT('USERENV','LANGUAGE'),
                            instr(SYS_CONTEXT('USERENV','LANGUAGE'),'.')+1),
                            'US7ASCII');

  a_tab         constant varchar2(10) :=
    CONVERT(CHR(9), substr(SYS_CONTEXT('USERENV','LANGUAGE'),
                           instr(SYS_CONTEXT('USERENV','LANGUAGE'),'.')+1),
                           'US7ASCII');

  a_newline     constant varchar2(10) :=
    CONVERT(CHR(10), substr(SYS_CONTEXT('USERENV','LANGUAGE'),
                            instr(SYS_CONTEXT('USERENV','LANGUAGE'),'.')+1),
                            'US7ASCII');

  a_carr_return constant varchar2(10) :=
    CONVERT(CHR(13), substr(SYS_CONTEXT('USERENV','LANGUAGE'),
                            instr(SYS_CONTEXT('USERENV','LANGUAGE'),'.')+1),
                            'US7ASCII');

  token_index   number;
  look_for_next number;
  string_length number;
  token_length  number;
begin
  string_length := length(input_string);
  token_length  := length(input_token);
  look_for_next := 1;

  --
  -- Find first occurrence of token in string that is
  --   delimited by white space.
  -- If find an occurrence that is not delimited by white space
  --   look for the next occurrence
  -- Break out of loop if found token delimited by white space
  --   or if couldn't find the token delmited by white space
  --
  loop
    token_index := instr(input_string,input_token,1,look_for_next);

    -- Exit if we didn't find the token

    if token_index = 0 then
      exit;
    end if;

    -- Check for white space before token

    if token_index > 1 then

      if     substr(input_string,token_index-1,1) <> a_space
         and substr(input_string,token_index-1,1) <> a_tab
         and substr(input_string,token_index-1,1) <> a_newline
         and substr(input_string,token_index-1,1) <> a_carr_return then

        goto try_next_occurrence;

      end if;
      -- end if no white space before token

    end if;
    -- end if token not at start of string

    -- Check for white space after token

    if token_index+token_length <= string_length then

      if     substr(input_string,token_index+token_length,1) <> a_space
         and substr(input_string,token_index+token_length,1) <> a_tab
         and substr(input_string,token_index+token_length,1) <> a_newline
         and substr(input_string,token_index+token_length,1) <> a_carr_return
                                                            then

        goto try_next_occurrence;

      else

        -- Found token delimited by white space

        exit;

      end if;
      -- end if no white space after token

    else

      -- Found token at end of string
      exit;

    end if;
    -- end if token not at end of string

  <<try_next_occurrence>>

    look_for_next := look_for_next + 1;

  end loop;

  -- Set return values

  token_location := token_index;

  if token_index = 0 then
    token_found := 'FALSE';
  else
    token_found := 'TRUE';
  end if;

exception
  when others then
    ad_apps_private.error_buf := 'verify_token_location('
      || input_string ||', '|| input_token ||'): '||
      ad_apps_private.error_buf;
    raise;
end verify_token_location;


procedure classify_plsql_object
           (owner        in  varchar2,
            name         in  varchar2,
            type         in  varchar2,
            has_authid   out nocopy varchar2,
            invoker_flag out nocopy varchar2)
--
-- Parses the source text for the given PL/SQL object
--
-- Sets has_authid to 'TRUE' if the object contains the AUTHID keyword
--   sets has_authid to 'FALSE' otherwise
--
-- Sets invoker_flag to 'I' (Invoker's Rights; AUTHID CURRENT_USER)
--  or 'D' (Definer's Rights; AUTHID DEFINER) if has_authid is 'TRUE'
-- Sets invoker_flag to 'S' for Definer's Rights packages containing
--  the /*nosync*/ comment (exactly as written, and delimited by whitespace)
--  The /*nosync*/ comment must appear before the IS/AS keyword.
--
-- For wrapped package specs (procedures, functions), assumes definer's
--  rights, as we really have no way to parse them.  Not clear why anyone
--  would want to wrap these objects, though...
--
-- 2/6/01 R Lotero
--
-- Add "customer hack" for Fidelity.  If package doesn't contain an AUTHID
-- clause, and package doesn't contain a valid Header string either, assume
-- it's not an Oracle Apps package and maintain the default behavior (no
-- AUTHID clause implies Definer Rights).  To do this, say we found an AUTHID
-- clause and that the package was explicitly declared as Definer Rights,
-- even though this is not true.
--
is
  cursor c1 is
    select text from sys.dba_source
    where owner = upper(classify_plsql_object.owner)
    and name = upper(classify_plsql_object.name)
    and type = upper(classify_plsql_object.type)
    order by line;

  cursor PKG_HEADER (c_owner in varchar2,
                     c_name  in varchar2,
                     c_type  in varchar2) is
    select
       substr(s.text, instr(s.text,'$Header'||': '),
              ((instr(s.text,' $', instr(s.text,'$Header'||': ')) + 2)
               - instr(s.text,'$Header'||': ')))
    from sys.dba_source s
    where s.owner= upper(c_owner)
    and   s.name = upper(c_name)
    and   s.type = upper(c_type)
    and   s.line between 2 and 5
    and   s.text like '%$Header'||': % $%';

  header_string    varchar2(500);
  row_count        number;
  found_authid     boolean;
  authid_line      number;
  found_is_as      boolean;
  found_wrapped    boolean;
  is_as_line       number;
  word_location    number;
  is_as_position   number;
  we_found_it      varchar2(10);
  found_aid_type   boolean;
  aid_type_line    number;
  authid_type      varchar2(10);
  found_nosync     boolean;
  nosync_line      number;
begin
  log_debug_message('Begin procedure classify_plsql_object ');

  -- Initialize return variables

  has_authid := 'FALSE';
  invoker_flag := 'X';

  -- Validate PL/SQL object type

  if     upper(type) <> 'PACKAGE'
     and upper(type) <> 'PROCEDURE'
     and upper(type) <> 'FUNCTION'  then

    raise_application_error(-20000,
      'Do not know how to classify objects of type "'||upper(type)||'".');

  end if;
  -- end if not valid type

  -- Initialize variables

  found_authid   := FALSE;
  found_is_as    := FALSE;
  found_aid_type := FALSE;
  found_nosync   := FALSE;
  found_wrapped  := FALSE;

  authid_line   := 0;
  is_as_line    := 0;
  aid_type_line := 0;
  nosync_line   := 0;

  --
  -- parse the source text
  --
  -- Exit loop when we find the IS/AS keyword
  --

  row_count := 0;

  for c1rec in c1 loop

    row_count:=row_count+1;

    -- Check for AUTHID

    word_location := instr(upper(c1rec.text),'AUTHID');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(c1rec.text), 'AUTHID',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_authid := TRUE;
	authid_line := row_count;

      end if;
      -- end if we really found AUTHID

    end if;
    -- end if found AUTHID using INSTR

    -- If found AUTHID, check for authid type

    if found_authid then

      -- Check for CURRENT_USER keyword

      word_location := instr(upper(c1rec.text),'CURRENT_USER');

      if word_location <> 0 then

	-- Do more strict checking

	verify_token_location(upper(c1rec.text), 'CURRENT_USER',
	  we_found_it, word_location);

	if we_found_it = 'TRUE' then

	  found_aid_type := TRUE;
	  aid_type_line := row_count;
	  authid_type := 'I';

	end if;
	-- end if we really found CURRENT_USER

      end if;
      -- end if found CURRENT_USER using INSTR

      -- Check for DEFINER keyword

      word_location := instr(upper(c1rec.text),'DEFINER');

      if word_location <> 0 then

	-- Do more strict checking

	verify_token_location(upper(c1rec.text), 'DEFINER',
	  we_found_it, word_location);

	if we_found_it = 'TRUE' then

	  found_aid_type := TRUE;
	  aid_type_line := row_count;
	  authid_type := 'D';

	end if;
	-- end if we really found DEFINER

      end if;
      -- end if found DEFINER using INSTR

    end if;
    -- end if check for AUTHID type

    -- Check for /*nosync*/ comment
    -- Must be specified exactly as above (case-insensitive) and be
    --   delimited by whitespace

    word_location := instr(upper(c1rec.text),'/*NOSYNC*/');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(c1rec.text), '/*NOSYNC*/',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_nosync := TRUE;
	nosync_line := row_count;

      end if;
      -- end if we really found /*NOSYNC*/

    end if;
    -- end if found /*NOSYNC*/ using INSTR

    -- Check for AS
    -- Break out of the loop if we find it

    word_location := instr(upper(c1rec.text),'AS');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(c1rec.text), 'AS',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_is_as := TRUE;
	is_as_line := row_count;
	exit;

      end if;
      -- end if we really found AS

    end if;
    -- end if found AS using INSTR

    -- Check for IS
    -- Break out of the loop if we find it

    word_location := instr(upper(c1rec.text),'IS');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(c1rec.text), 'IS',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_is_as := TRUE;
	is_as_line := row_count;
	exit;

      end if;
      -- end if we really found IS

    end if;
    -- end if found IS using INSTR

    -- Check for WRAPPED
    -- Just make a note of it if we find it

    word_location := instr(upper(c1rec.text),'WRAPPED');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(c1rec.text), 'WRAPPED',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then


	found_wrapped := TRUE;
        is_as_line := row_count;
        exit;

      end if;
      -- end if we really found WRAPPED

    end if;
    -- end if found WRAPPED using INSTR

  end loop;
  -- end loop to parse source text

  if not found_is_as then

    -- Should only happen for wrapped package specs,
    --   wrapped procedures, or wrapped functions

    if found_wrapped then

      -- It's wierd to wrap a package spec, procedure, or function
      -- It's also annoying, because then we can't parse it to find
      -- out if it's invoker's rights or definer's rights.
      --
      -- Treat all wrapped specs, procedures, or functions as
      -- definer's rights objects.  This is the safest strategy.
      --

      has_authid := 'TRUE';
      invoker_flag := 'D';
      return;

    else

      --
      -- This should never happen, but it happens on Dev115
      --  Use the "safe" strategy from above: say it's Definer's Rights
      --

      has_authid := 'TRUE';
      invoker_flag := 'D';
      return;

      -- raise_application_error(-20000,
      --   'No IS/AS keyword found in '||upper(type)||' '||
      --   upper(owner)||'.'||upper(name));

    end if;
    -- end if found WRAPPED keyword

  end if;
  -- end if didn't find IS/AS keyword

  -- Set return values

  if found_authid then

    has_authid := 'TRUE';

    if found_aid_type then

      if authid_type = 'D' or authid_type = 'I' then

        --
        -- Reset authid_type to 'S' for Definer's Rights objects
        --   that contain the /*nosync*/ comment
        --
        if authid_type = 'D' then
          if found_nosync then
            authid_type := 'S';
          end if;
        end if;

        invoker_flag := authid_type;
      else
        raise_application_error(-20000,
          'Found AUTHID keyword, but did not find authid type');
      end if;
      -- end if valid authid type

    end if;
    -- end if found authid type

  else

    -- Didn't find AUTHID keyword.

    -- Check for valid Header string in package.  If found, don't do anything.
    -- If not found, assume not an Oracle Apps package and treat it as if it
    -- had an explicit AUTHID DEFINER clause.

    open PKG_HEADER(owner, name, type);

    fetch PKG_HEADER
    into header_string;

    if PKG_HEADER%NOTFOUND then
      -- no header.  Assume not an Oracle Apps pkg

      close PKG_HEADER;

      has_authid := 'TRUE';
      invoker_flag := 'D';

    else
      -- has header.  Assume an Oracle Apps pkg

      close PKG_HEADER;

    end if;
    -- end if pkg has valid Header string

  end if;
  -- end if found AUTHID keyword

exception
  when others then
    ad_apps_private.error_buf := 'classify_plsql_object('
      || owner ||', '|| name ||', '|| type ||'): '||
      ad_apps_private.error_buf;
    raise;
  log_debug_message('End procedure classify_plsql_object ');
end classify_plsql_object;


procedure classify_plsql_array
           (the_array    in  dbms_sql.varchar2s,
            lb           in  number,
            ub           in  number,
            type         in  varchar2,
            has_authid   out nocopy varchar2,
            invoker_flag out nocopy varchar2)
--
-- Parses the PL/SQL source text stored in the varchar2s array
--
-- Sets has_authid to 'TRUE' if the object contains the AUTHID keyword
--   sets has_authid to 'FALSE' otherwise
--
-- Sets invoker_flag to 'I' (Invoker's Rights; AUTHID CURRENT_USER)
--  or 'D' (Definer's Rights; AUTHID DEFINER) if has_authid is 'TRUE'
-- Sets invoker_flag to 'S' for Definer's Rights packages containing
--  the /*nosync*/ comment (exactly as written, and delimited by whitespace)
--  The /*nosync*/ comment must appear before the IS/AS keyword.
--
-- For wrapped package specs (procedures, functions), assumes definer's
--  rights, as we really have no way to parse them.  Not clear why anyone
--  would want to wrap these objects, though...
--
-- 2/6/01 R Lotero
--
-- Deliberately don't add "customer hack" we added to classify_plsql_object.
--
-- This routine is only called from AD_DDL to create packages dynamically.
-- In most cases dynamically-created packages should not contain Header
-- strings because these are basically meaningless in a dynamically-created
-- object.  This means that even Oracle Apps dynamically-created packages
-- should not contain Header strings, so the header -vs- no header
-- distinction central to the "customer hack" is not useful for
-- deciding if a given dynamically-created package belongs to Oracle Apps
-- or to a customer.
--
is
  found_authid     boolean;
  authid_line      number;
  found_is_as      boolean;
  found_wrapped    boolean;
  is_as_line       number;
  word_location    number;
  is_as_position   number;
  we_found_it      varchar2(10);
  found_aid_type   boolean;
  aid_type_line    number;
  authid_type      varchar2(10);
  found_nosync     boolean;
  nosync_line      number;
begin
  -- Initialize return variables

  has_authid := 'FALSE';
  invoker_flag := 'X';

  -- Validate PL/SQL object type

  if     upper(type) <> 'PACKAGE'
     and upper(type) <> 'PROCEDURE'
     and upper(type) <> 'FUNCTION'  then

    raise_application_error(-20000,
      'Do not know how to classify objects of type "'||upper(type)||'".');

  end if;
  -- end if not valid type

  -- Initialize variables

  found_authid   := FALSE;
  found_is_as    := FALSE;
  found_aid_type := FALSE;
  found_nosync   := FALSE;
  found_wrapped  := FALSE;

  authid_line   := 0;
  is_as_line    := 0;
  aid_type_line := 0;
  nosync_line   := 0;

  --
  -- parse the source text
  --
  -- Exit loop when we find the IS/AS keyword
  --

  for counter in lb..ub loop

    -- Check for AUTHID

    word_location := instr(upper(the_array(counter)),'AUTHID');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(the_array(counter)), 'AUTHID',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_authid := TRUE;
	authid_line := counter;

      end if;
      -- end if we really found AUTHID

    end if;
    -- end if found AUTHID using INSTR

    -- If found AUTHID, check for authid type

    if found_authid then

      -- Check for CURRENT_USER keyword

      word_location := instr(upper(the_array(counter)),'CURRENT_USER');

      if word_location <> 0 then

	-- Do more strict checking

	verify_token_location(upper(the_array(counter)), 'CURRENT_USER',
	  we_found_it, word_location);

	if we_found_it = 'TRUE' then

	  found_aid_type := TRUE;
	  aid_type_line := counter;
	  authid_type := 'I';

	end if;
	-- end if we really found CURRENT_USER

      end if;
      -- end if found CURRENT_USER using INSTR

      -- Check for DEFINER keyword

      word_location := instr(upper(the_array(counter)),'DEFINER');

      if word_location <> 0 then

	-- Do more strict checking

	verify_token_location(upper(the_array(counter)), 'DEFINER',
	  we_found_it, word_location);

	if we_found_it = 'TRUE' then

	  found_aid_type := TRUE;
	  aid_type_line := counter;
	  authid_type := 'D';

	end if;
	-- end if we really found DEFINER

      end if;
      -- end if found DEFINER using INSTR

    end if;
    -- end if check for AUTHID type

    -- Check for /*nosync*/ comment
    -- Must be specified exactly as above (case-insensitive) and be
    --   delimited by whitespace

    word_location := instr(upper(the_array(counter)),'/*NOSYNC*/');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(the_array(counter)), '/*NOSYNC*/',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_nosync := TRUE;
	nosync_line := counter;

      end if;
      -- end if we really found /*NOSYNC*/

    end if;
    -- end if found /*NOSYNC*/ using INSTR

    -- Check for AS
    -- Break out of the loop if we find it

    word_location := instr(upper(the_array(counter)),'AS');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(the_array(counter)), 'AS',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_is_as := TRUE;
	is_as_line := counter;
	exit;

      end if;
      -- end if we really found AS

    end if;
    -- end if found AS using INSTR

    -- Check for IS
    -- Break out of the loop if we find it

    word_location := instr(upper(the_array(counter)),'IS');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(the_array(counter)), 'IS',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_is_as := TRUE;
	is_as_line := counter;
	exit;

      end if;
      -- end if we really found IS

    end if;
    -- end if found IS using INSTR

    -- Check for WRAPPED
    -- Just make a note of it if we find it

    word_location := instr(upper(the_array(counter)),'WRAPPED');

    if word_location <> 0 then

      -- Do more strict checking

      verify_token_location(upper(the_array(counter)), 'WRAPPED',
	we_found_it, word_location);

      if we_found_it = 'TRUE' then

	found_wrapped := TRUE;
        is_as_line := counter;
        exit;

      end if;
      -- end if we really found WRAPPED

    end if;
    -- end if found WRAPPED using INSTR

  end loop;
  -- end loop to parse source text

  if not found_is_as then

    -- Should only happen for wrapped package specs,
    --   wrapped procedures, or wrapped functions

    if found_wrapped then

      -- It's wierd to wrap a package spec, procedure, or function
      -- It's also annoying, because then we can't parse it to find
      -- out if it's invoker's rights or definer's rights.
      --
      -- Treat all wrapped specs, procedures, or functions as
      -- definer's rights objects.  This is the safest strategy.
      --

      has_authid := 'TRUE';
      invoker_flag := 'D';
      return;

    else

      --
      -- This should never happen, but it happens on Dev115
      --  Use the "safe" strategy from above: say it's Definer's Rights
      --

      has_authid := 'TRUE';
      invoker_flag := 'D';
      return;

    end if;
    -- end if found WRAPPED keyword

  end if;
  -- end if didn't find IS/AS keyword

  -- Set return values

  if found_authid then

    has_authid := 'TRUE';

    if found_aid_type then

      if authid_type = 'D' or authid_type = 'I' then

        --
        -- Reset authid_type to 'S' for Definer's Rights objects
        --   that contain the /*nosync*/ comment
        --
        if authid_type = 'D' then
          if found_nosync then
            authid_type := 'S';
          end if;
        end if;

        invoker_flag := authid_type;
      else
        raise_application_error(-20000,
          'Found AUTHID keyword, but did not find authid type');
      end if;
      -- end if valid authid type

    end if;
    -- end if found authid type

  end if;
  -- end if found AUTHID keyword

exception
  when others then
    ad_apps_private.error_buf := 'classify_plsql_array('
      || ' <array>, '|| lb ||', '|| ub ||', '|| type ||'): '||
      ad_apps_private.error_buf;
    raise;
end classify_plsql_array;


end ad_invoker;
