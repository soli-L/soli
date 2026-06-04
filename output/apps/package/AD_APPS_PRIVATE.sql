
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_APPS_PRIVATE" AUTHID CURRENT_USER as
/* $Header: adaprs.pls 120.0.12020000.4 2023/01/11 08:15:32 rsatyava noship $ */

--
-- Declare type for tables of objects given special treatment
-- These are usually the result of patches after the release goes
-- out.  In general, we don't want any of these at the start of a release
--

type TableNameType is table of varchar2(30)
  index by binary_integer;

--
-- Global variables and common sql statements used multiple times
--

error_buf varchar2(32760);
is_mls boolean;
is_mc  boolean;

ign_select_part1 constant varchar2(100) :=
   'select distinct decode(install_group_num,0,1,install_group_num) from ';
ign_select_part2 constant varchar2(200) :=
   '.fnd_product_installations '||
   'where db_status in ( ''I'' , ''S'' ) '||
   'and not (install_group_num != 0 '||
   'and exists ( '||
   'select null from ';
ign_select_part3 constant varchar2(200) :=
   '.fnd_product_installations '||
   'where install_group_num > 0)) '||
   'order by decode(install_group_num,0,1,install_group_num)';

ign_schema_select_part1 constant varchar2(100) :=
   'select distinct ou.oracle_username from ';
ign_schema_select_part2 constant varchar2(100) :=
   '.fnd_oracle_userid ou, ';
-- note the final where condition is missing.  This differs and is added later
ign_schema_select_part3 constant varchar2(200) :=
   '.fnd_product_installations pi '||
   'where ou.oracle_id = pi.oracle_id '||
   'and pi.db_status in ( ''I'' , ''S'' ) '||
   'and pi.install_group_num ';

--
-- These PL/SQL tables together logically implement a PL/SQL
-- table of records that tracks information on objects we need to treat
-- specially.  So far, we only refer to this information in the
-- create_grants_and_synonyms() procedure, and in advrfapp.sql
--
-- I probably should really implement this as a table of records...
--

-- The logical columns for the exception objects list

prod_short_name    TableNameType;
base_name          TableNameType;
base_type          TableNameType;
exception_type     TableNameType;
trigger_obj_schema TableNameType;
trigger_obj_type   TableNameType;
trigger_obj_name   TableNameType;
apps_name          TableNameType;
apps_type          TableNameType;
points_to_schema   TableNameType;
points_to_name     TableNameType;

-- The number of elements in the exception objects list

list_count number;

--
-- Array used to check to see if we have already done the following check:
-- Some programs that use ad_ddl call it hundreds of times and we don't need to
-- do the check if we've already done it. The check will be done in
-- check_for_apps_ddl
--
type schema_check_table is table of sys.dba_objects.owner%type index by binary_integer;
schema_check schema_check_table;
--

--
-- Procedures dealing with APPS_DDL and APPS_ARRAY_DDL
--

function is_edition_enabled(p_username varchar2 default null)
return varchar2;

procedure do_apps_ddl (schema_name in varchar2,
		       ddl_text    in varchar2);

procedure do_apps_ddl (schema_name in varchar2,
		       ddl_text    in varchar2,
                       abbrev_stmt in varchar2);
  --
  -- Purpose
  --   Execute the SQL statement  in the schema <username>
  --   This is done by creating the following pl/sql block:
  --		begin <username>.apps_ddl.apps_ddl(:<ddl_text>); end;
  -- Arguments
  --   schema_name	The schema in which to run the statement
  --   ddl_text		The SQL statement to run
  --   abbrev_stmt	Replace ddl_text with '$statement$' in stack trace?
  -- Example
  --   none

procedure do_apps_array_ddl (schema_name in varchar2,
                             lb          in integer,
                             ub          in integer);

procedure do_apps_array_ddl (schema_name in varchar2,
                             lb          in integer,
                             ub          in integer,
                             add_newline in varchar2);
  -- Purpose
  --   Execute a array of sql statement in the schema <username>
  --   This array should be already built in do_array_assignment
  -- Arguments
  --   schema_name	The schema in which to run the statement
  --   ddl_text		dummy variable, for future use
  --   lb, ub           the upper and lower bound of the array
  --   add_newline      Should we add a newline after each line of input
  --                      text?  Don't want this for long views, but
  --                      probably do want this for packages.
  -- Example
  --   none
  -- Notes
  --   1. Requires that create_apps_ddl, and do_array_assignment,
  --   2. This procedure requires that execute on sys.dbms_sys_sql be
  --      granted to username before calling.
  --   3. Before calling this function, one should call
  --      do_array_assignment to build the array.

procedure do_array_assignment (schema_name in varchar2,
                               ddl_text    in varchar2,
                               rowcount    in integer);

procedure do_array_assignment_patch_edn (schema_name in varchar2,
                                            ddl_text    in varchar2,
                                            rowcount    in integer);

  -- Build an array of sqlcode in a global variable glprogtext
  -- in package APPS_ARRAY_DDL in schema username
  -- Argument
  --   username, schema
  --   ddl_text, one line of plsql code.
  --   rowcount, the line number

procedure check_for_apps_ddl (schema_name in varchar2);

  -- Verify that APPS_DDL and APPS_ARRAY_DDL exist and are valid
  --   in "schema_name"
  -- Fail if not there or not valid

--
-- Procedures dealing with Oracle Schemas
--

function check_if_schema_exists (schema_name in varchar2)
         return boolean;
  --
  -- Purpose
  --   Check for existance of username in dba_users
  -- Arguments
  --   username	The oracle user name to check
  -- Output
  --   boolean		- TRUE if user exists, else FALSE
  -- Example
  --   none
  -- Notes
  --   1. none
  --

procedure validate_aol_or_apps_schema
           (aol_or_apps_schema in         varchar2);

  -- Purpose
  --   Check whether the user supplied schema name is a valid
  --   AOL or APPS schema
  -- Arguments
  --   aol or apps schema which user enters
  -- Output
  --   raises exception if the given schema is not a valid
  --   AOL or APPS user
  -- Example
  --   none
  -- Notes
  --   1. none

--
-- Utility functions
--

procedure create_grants_and_synonyms
           (install_group_num in number,
            from_schema       in varchar2,
            aol_schema        in varchar2,
            apps_schema       in varchar2);

procedure create_grants_and_synonyms
           (install_group_num in number,
            from_schema       in varchar2,
            aol_schema        in varchar2,
            apps_schema       in varchar2,
            force             in varchar2);

   --
   -- Purpose
   --   Create grants from base schema sequences and tables to the
   --   APPS schema(s), and create synonyms in the APPS schema(s)
   --   corresponding to the base schema objects.
   -- Arguments
   --   install_group_num  Install Group Number
   --   from_schema     Schema that contains the sequences and tables
   --	aol_schema	Schema that contains AOL tables
   --   apps_schema	Name of the regular APPS schema
   --   force           Drop and re-create synonyms in this APPS schema
   --                    for objects in this base schema?
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure get_apps_schema_name (ign                in  number,
				aol_or_apps_schema in  varchar2,
				apps_schema        out nocopy varchar2,
				apps_mls_schema    out nocopy varchar2);
   --
   -- Purpose
   --   Create name for appsuser accounts (regular and MLS versions)
   -- Arguments
   --   ign		Install Group Number
   --	aol_schema	Schema that contains AOL tables
   --   apps_schema	Name of the regular schema
   --   apps_mls_schema Name of the MLS schema
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure drop_object (target_schema in varchar2,
 		       object_name   in varchar2,
		       object_type   in varchar2);
  --   Drop the object_name from the target_schema handling most
  --   OK Oracle Errors (i.e. object does not exist)
  -- Arguments
  --   target_schema	The schema which owns the object
  --   object_name	The name of the object to drop
  --   object_type	The type of object to drop
  -- Example
  --   none
  -- Notes
  --   none
  --

procedure copy_view (view_name   in varchar2,
		     from_schema in varchar2,
		     to_schema   in varchar2);
   --
   -- Purpose
   --   The procedure copies a view from one schema to another.
   -- Arguments
   --   view_name	View to be copied
   --   from_schema	Schema to copy from
   --   to_schema	Schema to copy to
   -- Example
   --   none
   -- Notes
   --   This is actually a wrapper routine that calls copy_view_internal
   --   and handles "deadlock when recompiling dependent object" errors
   --   that can occur when creating a view.
   --

procedure copy_huge_view(view_name  in varchar2,
                         fromschema in varchar2,
                         toschema   in varchar2);
   --
   -- Purpose
   --   Copy a view with source text > 32 K
   --   Can also copy smaller views, but is probably slower than
   --    the normal copy_view routine
   -- Arguments
   --   view_name               The name of the view to copy
   --   fromschema		The source schema
   --	toschema		The destination schema
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure compare_view_text(view_name  in  varchar2,
                            fromschema in  varchar2,
                            toschema   in  varchar2,
                            from_len   in  number,
                            to_len     in  number,
                            equal      out nocopy varchar2);
   --
   -- Purpose
   --   Compare the text of two views, and determine whether
   --   they are identical
   -- Arguments
   --   view_name               The name of the view to copy
   --   fromschema		The source schema
   --	toschema		The destination schema
   --   from_len                View length in the source schema
   --   to_len                  View length in the destination schema
   --   equal                   Are the views equal?
   -- Example
   --   none
   -- Notes
   --   If the views are equal, the equal parameter is set to 'TRUE'
   --   Otherwise, the equal parameter is set to 'FALSE'
   --

procedure copy_code (object_name in varchar2,
		     object_type in varchar2,
		     from_schema in varchar2,
		     to_schema   in varchar2);
   --
   -- Purpose
   --   The procedure copies a code object (package spec, package body,
   --   procedure, function) from one schema to another
   -- Arguments
   --   object_name	code object to be copied
   --   object_type	type of object to be copied
   --		one of ak_org _private.g_package_spec
   --		       ak_org _private.g_package_body
   --		       ak_org _private.g_procedure
   --		       ak_org _private.g_function
   --   from_schema	Schema to copy from
   --   to_schema	Schema to copy to
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure compare_code (object_name in  varchar2,
		        object_type in  varchar2,
		        from_schema in  varchar2,
		        to_schema   in  varchar2,
                        comp_level  in  varchar2,
                        equal       out nocopy varchar2);
   --
   -- Purpose
   --   The procedure compares a code object (package spec, package body,
   --   procedure, function) from one schema with the same object
   --   in a different schema.
   -- Arguments
   --   object_name	code object to be copied
   --   object_type	type of object to be copied
   --   from_schema	Schema to copy from
   --   to_schema	Schema to copy to
   --   comp_level      Level of comparison (see notes)
   --   equal           are the two objects equal?
   -- Example
   --   none
   -- Notes
   --   sets equal to TRUE if the two objects are identical
   --   sets equal to FALSE if the objects are not identical
   --
   --   comp_level valid values, and what they mean:
   --
   --     none   : return "equal" without comparing objects
   --
   --     lines  : compare number of source lines in each object
   --              return "equal" if same number of source lines
   --
   --     chars  : compare number of source lines and number of
   --              source chars in each object
   --              return "equal" if same number of source lines and chars
   --
   --     full   : compare number of source lines in each object,
   --              then compare actual source text
   --              return "equal" only if exactly equal
   --

procedure create_base_gs (base_schema in varchar2,
                          apps_schema in varchar2);

procedure create_base_gs (base_schema in varchar2,
			  apps_schema in varchar2,
                          force       in varchar2);
   --
   -- Purpose
   --   The procedure creates grants from all base schema tables and
   --   sequences to the APPS schema; and also (re-)creates all missing
   --   or incorrect synonyms in APPS.
   --
   -- Arguments
   --   base_schema     the base applications schema
   --   apps_schema     the APPS schema
   --   force           drop, then recreate all synonyms in APPS
   --                     corresponding to objects in this base schema
   --
   -- Example
   --   none
   -- Notes
   --   1. uses apps_ddl
   --

procedure create_gs (object_owner_schema in varchar2,
                     to_schema           in varchar2,
                     object_name         in varchar2,
                     with_option         in boolean,
                     privs               in varchar2,
                     grant_from_schema   in varchar2 default null,
                     to_ev               in varchar2 default 'N');
   --
   -- Purpose
   --   Create a grant/synonym for object in <fromuser> to object in
   --   <touser> with 'all' privileges on object <object_name>, optionally
   --   'with grant option'
   -- Arguments
   --   fromuser	Schema in which object exists
   --   touser		Schema in which to create synonym and grant to
   --	object_name	Name of object to create synonym for
   --	with_option	TRUE - grant is created 'with grant option'
   --			FALSE - grant is created without grant option
   -- Example
   --   none
   -- Notes
   --   1. This implementation uses 'apps_ddl'.  So 'apps_ddl' must exist.
   --


--
-- Procedures used to create an APPS/MLS schema
--

procedure create_synonyms (from_schema       in varchar2,
                           to_schema         in varchar2,
                           grant_from_schema in varchar2 default null);
   --
   -- Purpose
   --   Copy synonyms from one schema to another
   -- Arguments
   --   from_schema	Schema to copy from
   --	to_schema	Schema to copy to
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure copy_odd_synonyms (fromschema in varchar2,
                             toschema   in varchar2);
   --
   -- Purpose
   --   Copy odd synonyms (those that have a different name than base table)
   -- Arguments
   --   fromschema	Schema to copy from
   --	toschema	Schema to copy to
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure create_special_views (install_group_num in number,
                                aol_schema        in varchar2,
                                apps_schema       in varchar2,
                                create_mls_views  in boolean);
   --
   -- Purpose
   --   Create mls views in the appsuser account.
   --   For each table listed in <aoluser>.ak_translated_columns an
   --   mls view is created in the <appsuser> account.
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure copy_views (aoluser    in varchar2,
                      fromschema in varchar2,
                      toschema   in varchar2);
   --
   -- Purpose
   --   Copy views from schema <fromschema> to schema <toschema>
   -- Arguments
   --   aoluser		Schema for AOL objects
   --   fromschema	Schema to copy views from
   --	toschema	Schema to copy views to
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure copy_stored_progs
           (fromschema    in varchar2,
            toschema      in varchar2,
            p_object_type in varchar2,
            p_subset      in varchar2,
            compare_level in varchar2);
   --
   -- Purpose
   --   Copy stored programs from schema <fromschema> to schema <toschema>
   -- Arguments
   --   fromschema	Schema to copy from
   --	toschema	Schema to copy to
   --   p_object_type   'A' - All, 'B' Bodies, 'S' Specs, ...
   --	p_subset	Only copy objects like 'subset%'
   --   compare_level   How precisely we compare objects
   --                   (to determine whether to copy from src to dst)
   -- Example
   --   none
   -- Notes
   --
   -- In general, we want to only re-copy from src to dest if the object
   -- in src is different from the object in dest.
   --
   -- Comparison algorithm:
   --
   -- We use the following logic to compare code objects in src schema
   -- with code objects in destination schema.
   --
   -- First check: if object not in dest schema, copy to dest schema
   --  If object in dest schema, go to next check.
   --
   -- Second check: if object in src schema does not have revision
   --  information, do a full text comparison between the object in src
   --  and the object in dest schemas.  This full compare always happens
   --  for objects without revision information (ie, the compare_level
   --  argument is ignored here).  If objects different,
   --  copy from src to dest.  If objects same, don't copy.
   --  If object in src schema has revision information, go to next check.
   --
   -- Third check: if object in dest schema does not have revision
   --  information, copy src to dest.  If dest schema object has revision
   --  info, go to next check.
   --
   -- Fourth check: compare revisions between src and dest object.
   --  If different, copy src to dest.  If same, continue to next check.
   --  Note: we compare the whole header string, not just the revision number
   --
   -- Fifth check: we know that src and dest object have same revisions.
   --  Do object comparison according to the compare_level argument to
   --  see if the objects are identical.  If identical (as far as we checked)
   --  do not copy src to dest.  If not identical, copy src to dest.
   --
   --  compare_level possible values and meanings:
   --
   --    none: identical revisions means identical objects.
   --
   --    lines: verify that objects have same number of source lines
   --
   --    chars: verify that objects have same number of source lines
   --           and same number of source characters
   --
   --    full: verify that objects have same number of source lines,
   --          then compare actual source text.
   --

procedure exact_synonym_match (syn_own_schema  in  varchar2,
                               syn_name        in  varchar2,
                               tab_owner       in  varchar2,
                               tab_name        in  varchar2,
                               exact_match     out nocopy boolean,
                               is_obj_w_name   out nocopy boolean,
                               typ_exist_obj   out nocopy varchar2);
   --
   -- Purpose
   --   Check to see if the specified schema contains a synonym that is
   --   defined exactly as would be created with the statement:
   --   'CREATE SYNONYM syn_own_schema.syn_name FOR tab_owner.tab_name;'
   --
   --   If finds exact match, returns exact_match = TRUE
   --
   --   If does not find exact match, checks to see if syn_own_schema contains
   --   any object named syn_name.  If it finds such an object, it returns
   --   is_obj_w_name = TRUE and typ_exist_obj = <type of object found>
   --
   --   Types returned are standard object types (as found in dba_objects),
   --   except for the case where there is both a PACKAGE and a PACKAGE BODY
   --   named syn_name in the schema.  In this case, we return
   --   typ_exist_obj = 'PKG_S_AND_B'.
   --
   -- Arguments
   --   syn_own_schema  The schema in which we look for the specified synonym
   --   syn_name        The name of the synonym
   --   tab_owner       The schema containing the object that the synonym
   --                     points to
   --   tab_name        The name of the object that the synonym points to
   --   exact_match     Did we find an exact match for the specified synonym?
   --   is_obj_w_name   Is there any object in the schema named syn_name?
   --   typ_exist_obj   The type of the existing object (if any object exists)
   -- Example
   --   none
   -- Notes
   --   see comments above
   --

procedure recomp_referenced_objs (object_name      in varchar2,
                                  object_type      in varchar2,
                                  obj_list_schema  in varchar2,
                                  recompile_schema in varchar2);
   --
   -- Purpose
   --   Recompile all objects referenced by a given object.
   --   Used mainly in case where we get a deadlock trying to create a view.
   --   (See RDBMS bugs 547700 and 481974; fixed in RDBMS v8.1.4)
   --   This can occur when copying a view from the APPS schema to the MRC
   --   schema.  The algorithm is:
   --    - get list of objects the view depends on from the APPS schema
   --    - recompile this set of objects in the MRC schema if they exist
   --      and are not already valid in the MRC schema.
   --      (ignore all errors during recompile)
   --
   -- Arguments
   --   object_name       Name of the object for which we compile dependent
   --                       objects
   --   object_type       Type of the object <object name>
   --   obj_list_schema   Schema we search to find all of the dependent
   --                       objects
   --   recompile_schema  Schema in which we do the actual object recompile
   --
   -- Example
   --   none
   -- Notes
   --   Making this a public procedure in case it's useful elsewhere
   --

--
-- Other Misc procedures
--

procedure build_view_columns (from_schema     in  varchar2,
                              view_name       in  varchar2,
                              out_column_text out nocopy varchar2);
   --
   -- Purpose
   --   The procedure builds the column name list for a view
   -- Arguments
   --   from_schema	Schema view exists in
   --   view_name	Name of the view
   --   out_column_text output
   -- Example
   --   none
   -- Notes
   --   1. none
   --

procedure show_exception_list;
   --
   -- Purpose
   --   Displays list of exception objects
   --   Must 'set serverout on' in Sql*Plus in order to see the output
   -- Arguments
   --   None

procedure load_exception_list;
   --
   -- Purpose
   --   Loads the global list of exception objects
   --
   -- Arguments
   --   none
   --
   -- Example
   --   none
   --

function matching_exception_object (base_schema_name in  varchar2,
                                    base_object_name in  varchar2,
                                    base_object_type in  varchar2,
                                    except_type      in  varchar2,
                                    apps_schema_name in  varchar2,
                                    found_cust_obj   out nocopy varchar2,
                                    cust_obj_correct out nocopy varchar2,
                                    index_to_object  out nocopy number)
return boolean;
   --
   -- Purpose
   --   Determine if the specified object is one of the exception objects
   --   AND we need to treat it as an exception (ie, the patch which creates
   --   the exception has been applied).
   --
   -- Arguments
   --   base_schema_name   Name of the base schema
   --   base_object_name   Name of object in base schema
   --   base_object_type   Type of object in base schema
   --   except_type        Type of exception
   --   apps_schema_name   Name of the APPS schema
   --   found_cust_obj     Did we find the customized object?
   --                        Valid values are: 'TRUE' or 'FALSE'.
   --   cust_obj_correct   Was the customized object correct?
   --                        Valid values are: 'TRUE' or 'FALSE'.
   --                        If we found the customized object, this will
   --                          always be TRUE, except maybe for synonyms.
   --   index_to_object    The index to this object on the exception objects
   --                        list.  Useful if customized object not correct
   --                        or missing.
   --
   -- Example
   --   none
   --
   -- Notes
   --   correct_in_apps and index_to_object should not be used if the
   --   function returns FALSE, as their values will not be meaningful.
   --

procedure initialize (aol_schema in varchar2);
   --
   -- Purpose
   --   Initialize variables is_mc and is_mls
   --   This cannot be done in the initialization section of the package
   --   because it requires the aol_schema.  Therefore this procedure
   --   must be called by every public procedure.
   -- Argument
   --   aol_schema, AOL schema name
   --


function compare_releases(release_1 in varchar2, release_2 in varchar2)
return boolean;
  --
  --
  -- Purpose
  --
  -- Bug 3258312 : Check if we are on a release >= 11.5.10.
  -- If we are, then, mrc is obsoleted. This function helps
  -- us do the comparison.
  --
  --


procedure do_apps_array_ddl_on_patch_edn
            (schema_name in varchar2,
             lb          in integer,
             ub          in integer,
             add_newline in varchar2,
             object_name in varchar2,
             object_type in varchar2);


procedure do_apps_ddl_on_patch_edn
            (schema_name in varchar2,
             object_name in varchar2,
             object_type in varchar2,
             ddl_text in varchar2,
             abbrev_stmt in varchar2);

function get_evname(p_obj_name varchar2,
                    p_obj_owner varchar2 default null)
return varchar2;

function  validate_definer(in_schema in varchar2, in_package in varchar2) return varchar2;

  -- Bug25445659
  -- Purpose
  --   This procedure vlidates the in_schema parameter that is later used to
  --   dynamically build the cursor for execution by the APPS_DDL package.
  -- Arguments
  --   in_schema      The schema in which to run the statement
  -- Example
  --   none
  -- Notes
  --
  --

function  validate_type(in_type in varchar2) return varchar2;

  -- Bug25445659
  -- Purpose
  --   This procedure vlidates the in_type parameter
  -- Arguments
  --   in_type
  -- Example
  --   none
  -- Notes
  --
  --

--Bug 34578266 - FORWARD-PORT: BUG 34454278: AD_DDL AND AD_APPS_PRIVATE PERFORMANCE
--ISSUES POST AD/TXK DELTA13

function  GET_EDITION(x_edition_type in varchar2 default NULL) return varchar2;
procedure DO_APPS_ARRAY_DDL_EDN
          (P_SCHEMA_NAME     in varchar2,
           DDL_TEXT          in varchar2,
           ROWCOUNT          in integer,
           P_EDITION_NAME    in varchar2 DEFAULT NULL);

--procedure generate_ev(owner varchar2, name varchar2);
end ad_apps_private;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_APPS_PRIVATE" as
/* $Header: adaprb.pls 120.0.12020000.5 2023/01/11 08:20:08 rsatyava noship $ */

  --
  -- PRIVATE GLOBAL VARIABLES
  --
  --Collection type to cache results
  -- Added the folling for bug# 4583342
  -- UserName_Cache_Table_TYpe
  TYPE Un_Cache_Tbl_Type IS TABLE OF VARCHAR2(40) INDEX BY VARCHAR2(10);

  --Collection variable to cache results
  g_Un_Cache_Tbl Un_Cache_Tbl_Type;

  --
  -- PRIVATE PROCEDURES/FUNCTIONS SPECIFICATIONS
  --

/*
** log debug message, jwsmith, sql injection bug 25248691
** Debugging routine. You must create the table apps.log_debug_message
*/
procedure log_debug_message(text in varchar2)
is
begin
  --insert into apps.log_debug_message(message) values(text);
  -- commit;
   null;
end log_debug_message;

function GET_EDITION(x_edition_type in varchar2 default NULL) return varchar2
is
  l_edition         varchar2(30);
  v_edition_type    varchar2(30);
begin
  -- Sql Injection Bug 25248691
  log_debug_message('Begin procedure get_edition ');

  v_edition_type := sys.dbms_assert.enquote_literal(x_edition_type);

  execute immediate 'select ad_zd.get_edition(' || v_edition_type || ') from dual' into  l_edition;

  log_debug_message('End procedure get_edition ');

  return l_edition;
exception
  when others then
    log_debug_message('Exception - procedure get_edition ');
    raise;

END GET_EDITION;

function is_edition_enabled (p_username varchar2 default null)
return varchar2
is
 l_enabled varchar2(1);
begin
 if p_username is null
 then
    select u.editions_enabled
    into   l_enabled
    from   fnd_oracle_userid f,
           sys.dba_users u
    where  f.read_only_flag='U'
    and    u.username=f.oracle_username;
 else
    select editions_enabled
    into   l_enabled
    from   sys.dba_users
    where  username=p_username;
 end if;
 return l_enabled;
end;

/* This is for getting evname. Cannot call apps.ad_Zd_Table as
   it is editioned object
   If non editioned db then returns p_obj_name
   IF editioned db then
       - if p_obj_owner is null then return evname
       - if p_obj_owner is not null then
              if ev exist then return evname
              else  return p_obj_name
*/
function GET_EVNAME(p_obj_name varchar2,
                    p_obj_owner varchar2 default null)
return varchar2
is
   CUR integer;
   stmt varchar2(250);
   l_evname varchar2(30);
   ign integer;
   l_exist number;
   v_obj_name varchar2(30);
begin

   log_debug_message('Begin procedure get_evname ');

   if (is_edition_enabled = 'N') then
     l_evname := p_obj_name;
     return l_evname;
   end if;

   v_obj_name := sys.dbms_assert.enquote_literal(v_obj_name);

   CUR := DBMS_SQL.OPEN_CURSOR;

   stmt := 'select AD_ZD_TABLE.EV_VIEW('
   ||v_obj_name||') from DUAL';
   DBMS_SQL.PARSE(CUR, STMT, DBMS_SQL.native);
   DBMS_SQL.DEFINE_COLUMN (CUR, 1, l_evname, 30);
   IGN :=  DBMS_SQL.execute(CUR);
   LOOP
      if DBMS_SQL.FETCH_ROWS(CUR)>0 then
         DBMS_SQL.column_value(CUR, 1, l_evname);
      else
         exit;
      end if;
   end LOOP;
   DBMS_SQL.CLOSE_CURSOR(CUR);

   if (p_obj_owner is not null)
   then
      SELECT count(1)
      INTO  l_exist
      FROM  sys.dba_editioning_views
      WHERE view_name=l_evname
      AND   owner=p_obj_owner;

      IF (l_exist = 0)
      THEN
         l_evname := p_obj_name;
         return l_evname;
      END IF;
   end if;

   log_debug_message('End procedure get_evname ');
   return l_evname;
exception WHEN OTHERS THEN
   -- log_debug_message('Exception - procedure get_evname ');
   raise;

end get_evname;

procedure log_message(text in varchar2)
is
begin
--  insert into apps.log_message_venu(message) values(text);
--  commit;
    null;
end log_message;

procedure copy_view_internal
           (view_name   in varchar2,
            from_schema in varchar2,
            to_schema   in varchar2);
--
-- Purpose
--   The procedure copies a view from one schema to another.
-- Arguments
--   view_name View to be copied
--   from_schema Schema to copy from
--   to_schema Schema to copy to
-- Example
--   none
-- Notes
--
-- This is the old copy_view routine.
-- Renamed it and created a new copy_view that is a wrapper
-- It calls this one and tries to handle deadlock errors
--

  --
  -- PROCEDURES/FUNCTIONS
  --

--
-- Procedures dealing with APPS_DDL and APPS_ARRAY_DDL
--

procedure do_apps_ddl
           (schema_name in varchar2,
            ddl_text    in varchar2,
            abbrev_stmt in varchar2)
--
--   schema_name The schema in which to run the statement
--   ddl_text  The SQL statement to run
--   abbrev_stmt Replace ddl_text with '$statement$' in stack trace?
--
is
  statement      varchar2(500);
  c              integer;
  rows_processed integer;
  v_schema_name  varchar2(30);

begin


-- Sql Injection Bug 25248691
   log_debug_message('Begin procedure do_apps_ddl');
   v_schema_name := sys.dbms_assert.schema_name(schema_name);

    c := dbms_sql.open_cursor;
    statement:='begin '||v_schema_name||'.apps_ddl.apps_ddl(:ddl_text); end;';

    dbms_sql.parse(c, statement, dbms_sql.native);
    dbms_sql.bind_variable(c,'ddl_text',ddl_text);
    rows_processed := dbms_sql.execute(c);
    dbms_sql.close_cursor(c);
    log_debug_message('End procedure do_apps_ddl');

exception
  when others then
   if (dbms_sql.is_open(c)) then
       dbms_sql.close_cursor(c);
   end if;
    if abbrev_stmt = 'FALSE' then
      ad_apps_private.error_buf := 'do_apps_ddl('||schema_name||
        ','||ddl_text|| '): '||ad_apps_private.error_buf;
    else
      ad_apps_private.error_buf := 'do_apps_ddl('||schema_name||
        ', $statement$): '||ad_apps_private.error_buf;
    end if;

    log_debug_message('Exception - procedure do_apps_ddl');
    raise;

end do_apps_ddl;


procedure do_apps_ddl
           (schema_name in varchar2,
            ddl_text    in varchar2)
is
begin
  do_apps_ddl (schema_name => schema_name,
               ddl_text    => ddl_text,
               abbrev_stmt => 'FALSE');
end;


procedure do_apps_array_ddl
            (schema_name in varchar2,
             lb          in integer,
             ub          in integer,
             add_newline in varchar2)
is
  statement             varchar2(500);
  c              integer;
  rows_processed integer;
  package_name varchar2(128) := 'APPS_ARRAY_DDL';
  v_schema_name  varchar2(30);


begin
  -- call the package procedure created earlier in schema username
  -- Sql Injection Bug 25248691
  log_debug_message('Begin procedure do_apps_array_ddl ');
  v_schema_name := sys.dbms_assert.schema_name(schema_name);

  c := dbms_sql.open_cursor;
  statement:='begin '||v_schema_name||'.apps_array_ddl.apps_array_ddl(:lb, :ub, :nlf); end;';

  dbms_sql.parse(c, statement, dbms_sql.native);
  dbms_sql.bind_variable(c,'lb',lb);
  dbms_sql.bind_variable(c,'ub',ub);
  dbms_sql.bind_variable(c,'nlf',add_newline);
  rows_processed := dbms_sql.execute(c);
  dbms_sql.close_cursor(c);
  log_debug_message('End procedure do_apps_array_ddl ');

exception
  when others then
    ad_apps_private.error_buf := 'do_apps_array_ddl('||schema_name||', '||
                lb||', '||ub||', '||add_newline||'): '||
                ad_apps_private.error_buf;
    log_debug_message('Exception - procedure do_apps_array_ddl ');
    raise;
end do_apps_array_ddl;

procedure do_apps_array_ddl
            (schema_name in varchar2,
             lb          in integer,
             ub          in integer)
is
begin
  do_apps_array_ddl (schema_name => schema_name,
                     lb          => lb,
                     ub          => ub,
                     add_newline => 'FALSE');
end;


procedure do_array_assignment
           (schema_name in varchar2,
            ddl_text    in varchar2,
            rowcount    in integer)
is
  statement             varchar2(500);
  c              integer;
  rows_processed integer;
  v_schema_name  varchar2(30);

begin
  -- Do the array assignment to the global variable in schema username
  -- Sql Injection Bug 25248691
  log_debug_message('Begin procedure do_array_assignment ');
  v_schema_name := sys.dbms_assert.schema_name(schema_name);

  c := dbms_sql.open_cursor;
  statement:='begin '||v_schema_name||'.apps_array_ddl.glprogtext(:i) := :ddl_text; end;';

  dbms_sql.parse(c, statement, dbms_sql.native);
  dbms_sql.bind_variable(c,'i',rowcount);
  dbms_sql.bind_variable(c,'ddl_text',ddl_text);
  rows_processed := dbms_sql.execute(c);
  dbms_sql.close_cursor(c);
  log_debug_message('End procedure do_array_assignment ');

exception
  when others then
    ad_apps_private.error_buf := 'do_array_assignment('||schema_name||','||
        ddl_text||','||rowcount||'): '||ad_apps_private.error_buf;
    log_debug_message('Exception - procedure do_array_assignment ');
    raise;
end do_array_assignment;


procedure do_array_assignment_patch_edn
           (schema_name in varchar2,
            ddl_text    in varchar2,
            rowcount    in integer)
is
  statement             varchar2(500);
  l_cur                 integer;
  l_patch_edition       varchar2(500);
  status                number;
  v_schema_name         varchar2(30);

begin
  -- Do the array assignment to the global variable in schema username

  -- Not edition enabled? Return.
  -- jwsmith Bug 28373908 - no need to call this for every line of a package, only first time
  -- This is called from ad_ddl in a loop to create the pl/sql package in patch edition
  log_debug_message('Begin procedure do_array_assignment_patch_edn ');
  if (rowcount = 1) then
     if ( is_edition_enabled = 'N') then
       return;
     end if;
  end if;

  l_patch_edition:=GET_EDITION('PATCH');
  if l_patch_edition is NULL then
     return;
  end if;

-- Sql Injection Bug 25248691
   v_schema_name := sys.dbms_assert.schema_name(schema_name);

    statement:='begin '||v_schema_name||'.apps_array_ddl.glprogtext(:i) := :ddl_text; end;';

   l_cur := dbms_sql.open_cursor;
   dbms_sql.parse (c => l_cur, language_flag => dbms_sql.native,
            statement => statement, edition => l_patch_edition);
   dbms_sql.bind_variable(l_cur,'i',rowcount);
   dbms_sql.bind_variable(l_cur,'ddl_text',ddl_text);
   status := dbms_sql.execute(l_cur);
   dbms_sql.close_cursor(l_cur);
   log_debug_message('End procedure do_array_assignment_patch_edn ');

   exception
     when others then
       ad_apps_private.error_buf := 'do_array_assignment_patch_edn('||schema_name||','||
          ddl_text||','||rowcount||'): '||ad_apps_private.error_buf;
    log_debug_message('Exception - procedure do_array_assignment_patch_edn ');
    raise;
end do_array_assignment_patch_edn;

procedure check_for_apps_ddl (schema_name in varchar2)
is
  dummy            number;
  i                number;
  found_session    boolean := False;
  pack_stmt        varchar2(1000);
  v_schema_name    varchar2(30);
  l_rows_processed integer;
begin
  -- Sql Injection Bug 25248691
  log_debug_message('Begin procedure check_for_apps_ddl');
  v_schema_name := sys.dbms_assert.schema_name(schema_name);

  -- Check to see if apps_ddl and apps_array_ddl exist and are valid
  -- but only once per session. Not necessary to continue to check
  for i in 1..schema_check.count loop
   if upper(v_schema_name) = schema_check(i)
   then
    found_session := True;
    exit; -- no reason to check further, exit the loop
   end if;
  end loop;

  if NOT found_session
  then

    select count(*)
    into dummy
    from dba_objects
    where object_type in ('PACKAGE', 'PACKAGE BODY')
    and object_name in ('APPS_DDL', 'APPS_ARRAY_DDL')
    and status = 'VALID'
    and owner = upper(v_schema_name);

    if dummy <> 4 then
      begin

-- Sql Injection Bug 25248691

        v_schema_name := sys.dbms_assert.enquote_name(schema_name,FALSE);

        pack_stmt:='alter package '||upper(v_schema_name)||'.APPS_DDL compile';

        execute immediate pack_stmt;

        pack_stmt:='alter package '||upper(v_schema_name)||
                   '.APPS_ARRAY_DDL compile';

        execute immediate pack_stmt;

      exception
        when others then
        log_debug_message('Exception - procedure check_for_apps_ddl');
        raise_application_error(-20000,
        'APPS_DDL/APPS_ARRAY_DDL package(s) missing or invalid in schema '||
        upper(v_schema_name));

      end;

    else
      if upper(v_schema_name) <> 'CTXSYS' then
        -- Verify packages APPS_DDL and APPS_ARRAY_DDL have
        -- definer rights and schema is EBS schema
        select count(1) into l_rows_processed
        from all_users u,
        all_procedures p,
        fnd_oracle_userid au
        where upper(v_schema_name) = u.username
        and u.username             = au.oracle_username
        and p.owner                = u.username
        and p.object_name          in ('APPS_DDL','APPS_ARRAY_DDL')
        and p.authid               = 'DEFINER'
        and p.subprogram_id        = 0
        and p.object_type          = 'PACKAGE'
        and au.read_only_flag      not in('C','X');

        if l_rows_processed <> 2 then
          raise_application_error(-20001,'Validation of parameters failed security.
                                          APPS_DDL/APPS_ARRAY_DDL package(s) are not definer rights in
                                          '||upper(v_schema_name));
        end if;

        schema_check(schema_check.count+1) := upper(v_schema_name);
      end if;
    end if;
  end if;

  log_debug_message('End procedure check_for_apps_ddl');
  exception
    when others then
      ad_apps_private.error_buf := 'check_for_apps_ddl('||v_schema_name||
                                   '): '||ad_apps_private.error_buf;
      log_debug_message('Exception - procedure check_for_apps_ddl');
      raise;
end check_for_apps_ddl;

--
-- Procedures dealing with Oracle Schemas
--

function check_if_schema_exists (schema_name in varchar2)
return boolean is
  cursor c1 is
    select USERNAME from DBA_USERS
    where username = upper(check_if_schema_exists.schema_name);
begin
  for c1rec in c1 loop
    -- at least one row was returned so the user exists.
    return TRUE;
  end loop;
  -- no rows returned then return false
  return FALSE;
exception
  when others then
    ad_apps_private.error_buf := 'check_if_schema_exists('||schema_name||
                                '): '||ad_apps_private.error_buf;
    raise;
end check_if_schema_exists;

procedure validate_aol_or_apps_schema
           (aol_or_apps_schema in         varchar2)
is
  c_statement   varchar2(500);
begin
  c_statement := 'select ''x'' from fnd_oracle_userid where'||
               ' oracle_username=:aol_or_apps_schema and read_only_flag in (''E'', ''U'')';
  execute immediate c_statement using upper(aol_or_apps_schema);
EXCEPTION
  WHEN no_data_found THEN
    ad_apps_private.error_buf := 'validate_aol_or_apps_schema: ' ||
                    'not a valid APPS or APPLSYS schema ' ||
                                     ad_apps_private.error_buf;
    RAISE;
  WHEN OTHERS THEN
    RAISE;
end;


--
-- Utility functions
--
PROCEDURE create_grant
           (p_grantor_schema_name IN VARCHAR2,
            p_grantee_schema_name IN VARCHAR2,
            p_object_name         IN VARCHAR2,
            p_privileges          IN VARCHAR2,
            p_with_grant_option   IN BOOLEAN DEFAULT TRUE,
            p_recursion_depth     IN NUMBER DEFAULT NULL)
  IS
     l_statement           VARCHAR2(500);
     l_owner_schema_name   sys.dba_objects.owner%TYPE;
     l_object_type         sys.dba_objects.object_type%TYPE;
     l_recursion_depth     NUMBER;
     l_exists              NUMBER;
     l_queue_owner         VARCHAR2(30);
     v_grantee_schema_name VARCHAR2(30);
     v_object_name         VARCHAR2(128);

     no_privileges_to_grant EXCEPTION;
     PRAGMA EXCEPTION_INIT(no_privileges_to_grant, -1929);

    no_grant_exist EXCEPTION;
    PRAGMA EXCEPTION_INIT(no_grant_exist, -1720);

BEGIN
   BEGIN

 -- Sql Injection Bug 25248691

   v_grantee_schema_name := sys.dbms_assert.enquote_name(p_grantee_schema_name,FALSE);
   v_object_name:= sys.dbms_assert.enquote_name(p_object_name, FALSE);

      l_statement := ('GRANT ' || p_privileges || ' ON ' ||
        v_object_name || ' TO ' || v_grantee_schema_name);

      IF (p_with_grant_option) THEN
  l_statement := l_statement || ' WITH GRANT OPTION';
      END IF;
      ad_apps_private.do_apps_ddl(p_grantor_schema_name, l_statement);
   EXCEPTION
      WHEN no_privileges_to_grant THEN
  --
  -- In case of APPS1 to APPS2 granting this can happen
  -- and we need to get grantable grant from the base schema.
  --
  --
  -- Get the object type.
  --
  BEGIN
     SELECT object_type
       INTO l_object_type
       FROM dba_objects
       WHERE owner = p_grantor_schema_name
       AND object_name = p_object_name;
  EXCEPTION
   WHEN OTHERS THEN
   ad_apps_private.error_buf :=
   p_object_name || ' does not exist in ' ||
   p_grantor_schema_name || ad_apps_private.error_buf;
  RAISE;
   END;
IF (l_object_type = 'SYNONYM') THEN
     BEGIN
   SELECT table_owner
   INTO l_owner_schema_name
   FROM dba_synonyms
   WHERE owner = p_grantor_schema_name
   AND synonym_name = p_object_name;
     EXCEPTION
      WHEN OTHERS THEN
      ad_apps_private.error_buf :=
      'Synonym ' || p_object_name || ' does not exist in ' ||
      p_grantor_schema_name || ad_apps_private.error_buf;
    RAISE;
     END;
     --
     -- Check to recursion depth in case of circular synonyms.
     --
     l_recursion_depth := Nvl(p_recursion_depth, 0) + 1;
     IF (l_recursion_depth < 0 OR
  l_recursion_depth > 20) THEN
        ad_apps_private.error_buf :=
   'Recursion depth exceeded the limit (0-20) : ' ||
   l_recursion_depth || ad_apps_private.error_buf;
        RAISE;
     END IF;
     --
     -- Recursively call to get grantable grant.
     --
     create_grant(p_grantor_schema_name => l_owner_schema_name,
    p_grantee_schema_name => p_grantor_schema_name,
    p_object_name         => p_object_name,
    p_privileges          => p_privileges,
    p_with_grant_option   => TRUE,
    p_recursion_depth     => l_recursion_depth);
     --
     -- Now we have the grant from previous owner schema.
     --
     ad_apps_private.do_apps_ddl(p_grantor_schema_name, l_statement);
   ELSE
      ad_apps_private.error_buf :=
      'No priv to grant for a non-synonym object. ' ||
      ad_apps_private.error_buf;
      RAISE;
  END IF;
   END;

EXCEPTION
/* Added for bug2765486 to trap ORA -1720 */
/* BUG 2892989, Since APPLSYS owns WF queues, we don't use the owner condition
   and use dba_queues that is faster than using dba_objects  */

 WHEN no_grant_exist THEN
  BEGIN
	SELECT 1, owner into l_exists, l_queue_owner
        FROM sys.dba_queues where name = p_object_name;

  EXCEPTION
     WHEN OTHERS THEN
      ad_apps_private.error_buf := 'create_grant('||
      p_object_name || ' does not exist in ' ||
      l_queue_owner ||'): ' || ad_apps_private.error_buf;
      RAISE;
  END;

  IF l_exists = 1 THEN
      dbms_aqadm.grant_queue_privilege(privilege  =>'ALL',
      queue_name =>l_queue_owner||'.'||p_object_name,
      grantee =>p_grantee_schema_name,grant_option=>TRUE);
  END IF;

 WHEN no_privileges_to_grant THEN
  ad_apps_private.error_buf := null;

 WHEN OTHERS THEN
      DECLARE
  l_with_grant_option_text VARCHAR2(10) := 'FALSE';
      BEGIN
  IF (p_with_grant_option) THEN
     l_with_grant_option_text := 'TRUE';
  END IF;
  ad_apps_private.error_buf := 'create_grant('||
    p_grantor_schema_name || ',' || p_grantee_schema_name || ',' ||
    p_object_name || ',' || p_privileges || ',' ||
    l_with_grant_option_text || ',' || p_recursion_depth || '): ' ||
    ad_apps_private.error_buf;
      END;
    RAISE;
END create_grant;

PROCEDURE create_synonym (p_from_schema_name IN VARCHAR2,
                          p_from_object_name IN VARCHAR2,
                          p_to_schema_name   IN VARCHAR2,
                          p_to_object_name   IN VARCHAR2,
                          p_replace_existing IN BOOLEAN)
  IS
     l_statement           VARCHAR2(500);
     l_object_type         sys.dba_objects.object_type%TYPE;

     name_is_already_used  EXCEPTION;
     v_from_schema_name    VARCHAR2(30);
     v_to_object_name      VARCHAR2(128);
     v_from_object_name    VARCHAR2(128);

     PRAGMA EXCEPTION_INIT(name_is_already_used, -955);
BEGIN
   BEGIN

 -- Sql Injection Bug 25248691

     v_from_schema_name := sys.dbms_assert.schema_name(p_from_schema_name);
     v_to_object_name:= sys.dbms_assert.enquote_name(p_to_object_name,FALSE);
     v_from_object_name:= sys.dbms_assert.enquote_name(p_from_object_name,FALSE);

      l_statement := ('CREATE SYNONYM ' || v_to_object_name || ' FOR ' ||
        v_from_schema_name || '.' ||
        v_from_object_name );
      ad_apps_private.do_apps_ddl(p_to_schema_name, l_statement);
  EXCEPTION
      WHEN name_is_already_used THEN

      if (p_replace_existing = TRUE) then
        BEGIN
          SELECT object_type
            INTO l_object_type
            FROM sys.dba_objects
            WHERE owner = p_to_schema_name
            AND object_name = p_to_object_name;
        EXCEPTION
        WHEN OTHERS THEN
          ad_apps_private.error_buf :=
             p_to_object_name || ' does not exist in ' ||
             p_to_schema_name || ad_apps_private.error_buf;
          RAISE;
        END;
        IF (l_object_type = 'SYNONYM') THEN
        --
        -- Drop the synonym and then re-create.
        --
          ad_apps_private.drop_object(p_to_schema_name, p_to_object_name,
                                      'SYNONYM');
          ad_apps_private.do_apps_ddl(p_to_schema_name, l_statement);
       ELSE
         RAISE;
       END IF;
     ELSE
       null;
     END IF;
   END;
EXCEPTION
   WHEN OTHERS THEN
      ad_apps_private.error_buf := 'create_synonym('||
 p_from_schema_name || ',' || p_from_object_name || ',' ||
 p_to_schema_name || ',' || p_to_object_name || '): ' ||
 ad_apps_private.error_buf;
   RAISE;

END create_synonym;

procedure create_grants_and_synonyms
           (install_group_num in number,
            from_schema       in varchar2,
            aol_schema        in varchar2,
            apps_schema       in varchar2,
            force             in varchar2)
is
begin
  -- initialize variables; call init functions

  ad_apps_private.error_buf := null;

  ad_apps_private.initialize(aol_schema);

  ad_apps_private.load_exception_list;

  -- first make sure that the apps_ddl packages exist
  -- in all relevent schemas

  ad_apps_private.check_for_apps_ddl(from_schema);
  ad_apps_private.check_for_apps_ddl(apps_schema);

-- create grants and synonyms from base to apps
--
-- if force=TRUE, will drop all synonyms in apps schema corresponding
-- to objects in this base schema before creating synonyms
--
-- This is handy for re-synchronizing the MLS schema with the APPS schema
-- in the case where the base object grant is manually removed from the
-- APPS schema.  Then the MLS grant would be removed via cascade, and we have
-- no automated way of fixing the MLS grant (re-running this without FORCE
-- will not re-create the MLS grant, because the synonym in APPS will not
-- have changed)

  create_base_gs(from_schema, apps_schema, force);

exception
  when others then
    ad_apps_private.error_buf := 'create_grants_and_synonyms('||
      install_group_num||','||from_schema||','||aol_schema||','||
      apps_schema||'): '||ad_apps_private.error_buf;
    raise;

end create_grants_and_synonyms;

procedure create_grants_and_synonyms
           (install_group_num in number,
            from_schema       in varchar2,
            aol_schema        in varchar2,
            apps_schema       in varchar2)
is
begin

create_grants_and_synonyms
           (install_group_num => install_group_num,
            from_schema       => from_schema,
            aol_schema        => aol_schema,
            apps_schema       => apps_schema,
            force             => 'FALSE');
end;


procedure get_apps_schema_name
           (ign                in         number,
            aol_or_apps_schema in         varchar2,
            apps_schema        out nocopy varchar2,
            apps_mls_schema    out nocopy varchar2)
is
  c                     integer;
  rows_processed        integer;
  l_apps_schema         varchar2(30);
  l_mls_apps_schema     varchar2(30);
  c_statement           varchar2(500);
  v_aol_or_apps_schema  varchar2(30);
  v_apps_schema         varchar2(30);
  v_mls_apps_schema     varchar2(30);


begin

-- Sql Injection Bug 25248691
  log_debug_message('Begin procedure get_apps_schema_name ');
  v_aol_or_apps_schema := sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(aol_or_apps_schema),FALSE);

  -- from the IGN get the APPS schema
  IF ( g_Un_Cache_Tbl.COUNT <> 0 AND g_Un_Cache_Tbl.EXISTS(ign||'_aol') ) THEN
    l_apps_schema := g_Un_Cache_Tbl(ign||'_aol') ;
  ELSE -- if cache check
   BEGIN --Block 1

    validate_aol_or_apps_schema(aol_or_apps_schema);

    c := dbms_sql.open_cursor;
    -- select APPS account for given IGN, or if IGN is 0 then the min
    c_statement:= 'select oracle_username from '||v_aol_or_apps_schema
                  ||'.fnd_oracle_userid '||
                  'where (install_group_num = :install_group_num '||
                  '      or install_group_num = '||
                  '           (select min(install_group_num) from '||
                  v_aol_or_apps_schema
                  ||'.fnd_oracle_userid '||
                  '     where 1 = decode (:install_group_num,0,1,2) '||
                  '     and read_only_flag = ''U'')) '||
                  'and read_only_flag = ''U'' ';
    dbms_sql.parse(c, c_statement, dbms_sql.native);
    dbms_sql.bind_variable(c,'install_group_num',ign);
    dbms_sql.define_column(c,1,l_apps_schema,30);
    rows_processed := dbms_sql.execute(c);
    if dbms_sql.fetch_rows(c) > 0 then
      dbms_sql.column_value(c,1,l_apps_schema);
    else
      raise no_data_found;
    end if;
    dbms_sql.close_cursor(c);
    --
    -- Cache the result to the global collection
    g_Un_Cache_Tbl(ign||'_aol') := l_apps_schema;
   EXCEPTION
    when others then
      if (dbms_sql.is_open(c)) then
        dbms_sql.close_cursor(c);
      end if;
      ad_apps_private.error_buf := 'c_statement='||c_statement||': '||
                                   ad_apps_private.error_buf;
      raise;
   END ; -- Block 1
  END IF ; -- Cache check


  -- from the IGN get the MLS_APPS schema if it exists, otherwise default it
  -- Only do this if MLS is enabled.
  if ad_apps_private.is_mls is null then
    ad_apps_private.initialize(aol_or_apps_schema);
  end if;

  if is_mls then
   IF ( g_Un_Cache_Tbl.COUNT <> 0 AND g_Un_Cache_Tbl.EXISTS (ign||'_mls') ) THEN
     l_mls_apps_schema := g_Un_Cache_Tbl(ign||'_mls') ;
   ELSE -- if cache check 2
    BEGIN --BLock 2

      validate_aol_or_apps_schema(aol_or_apps_schema);

      c := dbms_sql.open_cursor;
      c_statement:= 'select oracle_username from '||
                  v_aol_or_apps_schema||'.fnd_oracle_userid '||
                  'where (install_group_num = :install_group_num '||
                  '      or install_group_num = '||
                  '           (select min(install_group_num) from '||
                  v_aol_or_apps_schema||'.fnd_oracle_userid '||
                  '     where 1 = decode (:install_group_num,0,1,2) '||
                  '     and read_only_flag = ''M'')) '||
                  'and read_only_flag = ''M'' ';
      dbms_sql.parse(c, c_statement, dbms_sql.native);
      dbms_sql.bind_variable(c,'install_group_num',ign);
      dbms_sql.define_column(c,1,l_mls_apps_schema,30);
      rows_processed := dbms_sql.execute(c);
      if dbms_sql.fetch_rows(c) > 0 then
        dbms_sql.column_value(c,1,l_mls_apps_schema);
      else
        raise no_data_found;
      end if;
      dbms_sql.close_cursor(c);
      g_Un_Cache_Tbl(ign||'_mls') := l_mls_apps_schema ;
    EXCEPTION
      when others then
        if (dbms_sql.is_open(c)) then
          dbms_sql.close_cursor(c);
        end if;
        ad_apps_private.error_buf := 'c_statement='||c_statement||': '||
                                     ad_apps_private.error_buf;
        raise;
    END ; -- Block 2
   END IF ; -- if cache check 2
  END IF ;

-- Sql Injection Bug 25248691 - Validating values from the database before returning the value.

 v_apps_schema := sys.dbms_assert.schema_name(l_apps_schema);
 if v_mls_apps_schema is not null then
    v_mls_apps_schema := sys.dbms_assert.schema_name(l_mls_apps_schema);
 end if;

apps_schema := l_apps_schema;
apps_mls_schema := l_mls_apps_schema;
log_debug_message('End procedure get_apps_schema_name ');

exception
  when others then
    ad_apps_private.error_buf := 'get_apps_schema_name('||ign||
                ','||v_aol_or_apps_schema||'): '||ad_apps_private.error_buf;
    log_debug_message('Exception - procedure get_apps_schema_name ');
    raise;
END get_apps_schema_name;

procedure drop_object
           (target_schema in varchar2,
            object_name   in varchar2,
            object_type   in varchar2)
IS
  c                     integer;
  rows_processed        integer;
  statement             varchar2(1000);
  object_not_exist      exception;
  pragma exception_init(object_not_exist, -4043);
  table_view_not_exist  exception;
  pragma exception_init(table_view_not_exist, -942);
  trigger_not_exist     exception;
  pragma exception_init(trigger_not_exist, -4080);
  synonym_not_exist     exception;
  pragma exception_init(synonym_not_exist, -1434);
  sequence_not_exist     exception;
  pragma exception_init(sequence_not_exist, -2289);
  l_evname varchar2(30);
  l_evexist number;
  v_target_schema varchar2(30);
  v_object_name varchar2(128);
  v_object_type varchar2(23);

begin
  -- sql injection bug 25248691
  log_debug_message('Begin procedure drop_object ');
  v_target_schema := sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(target_schema),FALSE);
  v_object_name := sys.dbms_assert.enquote_name(object_name,FALSE);
  v_object_type := validate_type(object_type);

  -- don't use apps_ddl here because this is called in the
  -- procedure that creates the apps_ddl code, so apps_ddl cannot be
  -- called before it is created
  c := dbms_sql.open_cursor;
  statement :='drop '||v_object_type||' '
               ||upper(v_target_schema)
               ||'.'||v_object_name||' ';
  dbms_sql.parse(c, statement, dbms_sql.native);
  rows_processed := dbms_sql.execute(c);
  dbms_sql.close_cursor(c);

  if (v_object_type='TABLE' and
      is_edition_enabled = 'Y')
  then
     l_evname := get_evname(object_name);
     SELECT count(1)
     into   l_evexist
     FROM   sys.dba_editioning_views
     WHERE  view_name=upper(l_evname)
     AND    table_name=upper(object_name)
     AND    owner=upper(target_schema);

     if (l_evexist > 0)
     then
        c := dbms_sql.open_cursor;
        statement :='drop view '||v_target_schema||'."'||l_evname||'"';
        dbms_sql.parse(c, statement, dbms_sql.native);
        rows_processed := dbms_sql.execute(c);
        dbms_sql.close_cursor(c);
     end if;
  end if;

  if (upper(object_type) = 'PROCEDURE' or
     upper(object_type) = 'PACKAGE' or
     upper(object_type) = 'PACKAGE BODY' or
     upper(object_type) = 'FUNCTION' or
     upper(object_type) = 'VIEW' or
     upper(object_type) = 'TRIGGER' or
     upper(object_type) = 'SYNONYM') then
      ad_apps_private.do_apps_ddl_on_patch_edn(target_schema,object_name,object_type,statement,'TRUE');    ---- added by vpalakur for ZD
  end if;
  log_debug_message('End procedure drop_object ');

exception
  -- trap ora -4043 (Object xxx does not exist)
  when object_not_exist then
    -- Bug 13940203
    if (dbms_sql.is_open(c)) then
      dbms_sql.close_cursor(c);
    end if;
    if upper(object_type) = 'PROCEDURE' or
       upper(object_type) = 'PACKAGE' or
       upper(object_type) = 'PACKAGE BODY' then
      null;
    else
      ad_apps_private.error_buf := 'drop_object('||target_schema||','||
                v_object_name||
                ','||object_type||'): '||ad_apps_private.error_buf;
      log_debug_message('Exception - procedure drop_object ');
      raise;
    end if;
  -- trap ora -942 (Table or view xxx does not exist)
  when table_view_not_exist then
    -- Bug 13940203
    if (dbms_sql.is_open(c)) then
      dbms_sql.close_cursor(c);
    end if;
    null;
  -- trap ora -4080 (Trigger does not exist)
  when trigger_not_exist then
    -- Bug 13940203
    if (dbms_sql.is_open(c)) then
      dbms_sql.close_cursor(c);
    end if;
    if upper(object_type) = 'TRIGGER' then
      null;
    else
      ad_apps_private.error_buf := 'drop_object('||target_schema||','||
                object_name||
                ','||object_type||'): '||ad_apps_private.error_buf;
      log_debug_message('Exception - procedure drop_object ');
      raise;
    end if;
  -- trap ora -1434 (Synonym does not exist)
  when synonym_not_exist then
    -- Bug 13940203
    if (dbms_sql.is_open(c)) then
      dbms_sql.close_cursor(c);
    end if;
    if upper(object_type) = 'SYNONYM' then
      null;
    else
      ad_apps_private.error_buf := 'drop_object('||target_schema||','||
                object_name||','||object_type||'): '||
                ad_apps_private.error_buf;
      log_debug_message('Exception - procedure drop_object ');
      raise;
    end if;
  -- trap ora -2289 (Sequence does not exist)
  when sequence_not_exist then
    -- Bug 13940203
    if (dbms_sql.is_open(c)) then
      dbms_sql.close_cursor(c);
    end if;
    if upper(object_type) = 'SEQUENCE' then
      null;
    else
      ad_apps_private.error_buf := 'drop_object('||target_schema||','||
                object_name||','||object_type||'): '||
                ad_apps_private.error_buf;
      log_debug_message('Exception - procedure drop_object ');
      raise;
    end if;
  when others then
    -- Bug 13940203
    if (dbms_sql.is_open(c)) then
      dbms_sql.close_cursor(c);
    end if;
    ad_apps_private.error_buf := 'drop_object('||target_schema||','||
                object_name||
                ','||object_type||'): '||ad_apps_private.error_buf;
    log_debug_message('Exception - procedure drop_object ');
    raise;
end drop_object;


procedure copy_view
           (view_name   in varchar2,
            from_schema in varchar2,
            to_schema   in varchar2)
is
  error_comp_or_validate_object exception;
  PRAGMA EXCEPTION_INIT(error_comp_or_validate_object, -4045);
  extra_buf varchar2(200);
begin
  log_debug_message('Begin procedure copy_view ');

  extra_buf := null;
--
-- wrap call to copy_view_internal in a begin/end block to handle
-- the exception.  Only try to remedy the exception once, then call
-- copy_view_internal again.  If the second call fails, just fail.
--
  begin
    ad_apps_private.copy_view_internal(view_name, from_schema, to_schema);
  exception
    when others then
      --
      --
      -- Put the "Stack Trace" info in the extra_buf string

      extra_buf := extra_buf ||
                   ' +++<drop_object('||to_schema||','||view_name||', VIEW)+++';
      --
      -- Try dropping the view
      begin
         -- dbms_output.put_line('Dropping view '||to_schema||'.'||view_name);
         drop_object(to_schema, view_name, 'VIEW');
       exception
         when others then
           log_debug_message('Exception - procedure copy_view ');
           raise;
      end;

      -- try to recompile dependent objects
      -- Put the "Stack Trace" info in the extra_buf string

      extra_buf := ' +++(ad_apps_private.recomp_referenced_objs('||view_name||
                   ',VIEW,'||from_schema||','||to_schema||'))+++ ';

      begin
        ad_apps_private.recomp_referenced_objs(view_name, 'VIEW',
                                               from_schema, to_schema);

        extra_buf := '+++(ad_apps_private.copy_view_internal('||
                     view_name||','||from_schema||','||to_schema||')+++';

        -- try creating the view again
        ad_apps_private.copy_view_internal(view_name, from_schema, to_schema);

      exception
        when others then
          -- Ignore any compilation errors. If a dependent view is invalid,
          -- the hope is that by the time we have finished all of the views,
          -- the dependent view will be valid again. (Bug 2361208)
          null;
      end; -- end of second try at copying views.
      -- in all cases, clear the buffer. We will report any views that didn't
      -- compile in the calling routine

      extra_buf := null;

    end; -- end of first attempt at copying views.
    log_debug_message('End procedure copy_view ');
exception
  when others then
    ad_apps_private.error_buf := 'ad_apps_private.copy_view('||view_name||','
      ||from_schema||','||to_schema||'): '|| extra_buf ||
      ad_apps_private.error_buf;
    log_debug_message('Exception - procedure copy_view ');
    raise;
end copy_view;


procedure copy_view_internal
           (view_name   in varchar2,
            from_schema in varchar2,
            to_schema   in varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  view_text             varchar2(32760);
  statement             varchar2(32760);
  view_columns          varchar2(32760);
  temp_len              pls_integer;
  v_view_name           varchar2(30);
begin
--
-- Outer block to handle huge views
--
  declare
    numeric_or_value_error exception;
    pragma exception_init(numeric_or_value_error, -6502);
    view_size number;
  begin

    temp_len := 0;

    select text into view_text from sys.dba_views
    where owner = upper(copy_view_internal.from_schema)
    and   view_name = copy_view_internal.view_name;

    if view_text is null then
      raise numeric_or_value_error;
    end if;

    ad_apps_private.build_view_columns(copy_view_internal.from_schema,
                        copy_view_internal.view_name, view_columns);

    temp_len := length(view_columns) + length(view_text)
                + length(copy_view_internal.view_name) + 36;

    if temp_len > 30000 then
      raise numeric_or_value_error;
    end if;

   v_view_name:= sys.dbms_assert.enquote_name(copy_view_internal.view_name,FALSE);

    statement := 'create or replace force view '||
                     v_view_name||' ' ||
                     view_columns || ' as '|| view_text;

--
-- Inner block for normal logic
--
    declare
      invalid_num_columns     exception;
      pragma exception_init(invalid_num_columns, -1730);
      name_already_used exception;
      pragma exception_init(name_already_used, -955);
    begin

      ad_apps_private.do_apps_ddl(copy_view_internal.to_schema,statement);

    exception
      when invalid_num_columns then
        -- trap the error ora-1730 invalid number of columns
        -- this happens when trying to copy an invalid view that
        -- was created on an oracle6 database using select *
        -- syntax.  Now if the underlying table has changed shape
        -- the number of columns in the view will not match the
        -- number being selected, thus causing this error.
        -- We will skip this view as it is inherently invalid,
        -- and cannot be created even with the force option.
        -- This happens for some R9 views after an upgrade, and
        -- may happen for custom views as well.  This is not
        -- a problem for any views created on oracle7 because
        -- Oracle7 will convert the select * into the column list.
        null;
      when name_already_used then
        -- first reset error buf
        ad_apps_private.error_buf := null;
        -- drop any synonym that may exist by the same name
        ad_apps_private.drop_object(copy_view_internal.to_schema,
                view_name, 'SYNONYM');
        ad_apps_private.do_apps_ddl(copy_view_internal.to_schema,statement);
      when others then
        raise;
    end;
--
-- End inner block
--
  exception
    when numeric_or_value_error then
      if temp_len > 30000 then
   -- reset main error buffer
   ad_apps_private.error_buf := null;

   -- Call copy_huge_view

   ad_apps_private.copy_huge_view(copy_view_internal.view_name,
      copy_view_internal.from_schema, copy_view_internal.to_schema);
      else
 --
 -- handle case where view text > 32 K
 --
 select dv.text_length
 into view_size
 from sys.dba_views dv
 where dv.view_name= copy_view_internal.view_name
 and   dv.owner= upper(copy_view_internal.from_schema);

 -- Compare against 24000, since the actual 'create view'
 -- statement will have some column names, etc. added on

 if view_size < 24000 then
   raise;
 else
   -- reset main error buffer
   ad_apps_private.error_buf := null;

   -- Call copy_huge_view

   ad_apps_private.copy_huge_view(copy_view_internal.view_name,
      copy_view_internal.from_schema, copy_view_internal.to_schema);

 end if;
      end if;
    when others then
      raise;
  end;
--
-- End outer block
--
exception
  when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
    -- reset main error buffer
    ad_apps_private.error_buf := null;
  when others then
    ad_apps_private.error_buf := 'ad_apps_private.copy_view_internal('||
      view_name||','||from_schema||','||to_schema||'): '||
      ad_apps_private.error_buf;
    raise;

end copy_view_internal;


procedure copy_huge_view
           (view_name  in varchar2,
            fromschema in varchar2,
            toschema   in varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  statement             varchar2(256);
  view_columns          varchar2(32760);
  row_count             integer;
  position              number;
  curr_value            varchar2(256);
  val_length            number;
  value_max_size        number;
  c                     integer;
  rows_processed        integer;
  v_view_name varchar2(128);
  v_fromschema varchar2(30);
  v_toschema varchar2(30);

begin
--
-- We count on the size of each element of a varchar2s table being
--   of size 256 per this declaration taken from RDBMS v7.1 pvtsql.sql
--
-- type varchar2s is table of varchar2(256) index by binary_integer;
--
-- Sql Injection Bug 25248691 Verify schema

  log_debug_message('Begin procedure copy_huge_view ');
  v_fromschema := sys.dbms_assert.schema_name(copy_huge_view.fromschema);
  v_toschema := sys.dbms_assert.schema_name(copy_huge_view.toschema);

-- SQL Injection Bug 25248691 enquote view_name

  v_view_name := sys.dbms_assert.enquote_name(copy_huge_view.view_name,FALSE);

  value_max_size := 256;

--  statement := 'create or replace force view "'||
--                   copy_huge_view.view_name||'" ' ||
--                     view_columns || ' as '|| view_text;

--
-- create first line of 'create view' statement
--

  row_count := 1;

  statement := 'create or replace force view '||v_view_name||' ';

  ad_apps_private.do_array_assignment(copy_huge_view.toschema,statement,row_count);

--
-- Add in view columns
--

  ad_apps_private.build_view_columns(copy_huge_view.fromschema,copy_huge_view.view_name, view_columns);

-- for substr, position 1 is first character

  position := 1;
  val_length := value_max_size;

  while val_length = value_max_size loop
    curr_value := substr(view_columns, position, value_max_size);
    val_length := length(curr_value);

    row_count := row_count + 1;

    ad_apps_private.do_array_assignment(copy_huge_view.toschema,curr_value, row_count);

    position := position + val_length;
  end loop;

--
-- Add in ' as '
--

  statement := ' as ';
  row_count := row_count + 1;

  ad_apps_private.do_array_assignment(copy_huge_view.toschema,statement, row_count);

--
-- Add in view select text
--

-- for long column, position zero is first character

  position := 0;
  val_length := value_max_size;

-- create select statement to get value from dba_views
-- SQL Injection Bug 25248691 convert to use bind variables

  c := sys.dbms_sql.open_cursor;

  statement := 'select text into :view_text from sys.dba_views '||
               'where owner=upper(:b_fromschema) '||
               'and view_name=upper(:b_view_name)';

  sys.dbms_sql.parse(c, statement, dbms_sql.native);
  dbms_sql.bind_variable(c,'b_fromschema',copy_huge_view.fromschema);
  dbms_sql.bind_variable(c,'b_view_name',copy_huge_view.view_name);
  sys.dbms_sql.define_column_long(c,1);
  rows_processed := sys.dbms_sql.execute(c);

  if sys.dbms_sql.fetch_rows(c) > 0 then
    while val_length = value_max_size loop
      sys.dbms_sql.column_value_long(c,1,value_max_size,position,
           curr_value,val_length);

      row_count := row_count + 1;

      ad_apps_private.do_array_assignment(copy_huge_view.toschema,curr_value, row_count);

      position := position + val_length;
    end loop;
  else
    sys.dbms_sql.close_cursor(c);
    ad_apps_private.error_buf := 'statement='||statement||
       ':'||ad_apps_private.error_buf;
    raise no_data_found;
    log_debug_message('Exception procedure copy_huge_view ');
  end if;

  sys.dbms_sql.close_cursor(c);

--
-- Execute create view statement using apps_array_ddl
--

  declare
    invalid_num_columns     exception;
    pragma exception_init(invalid_num_columns, -1730);
    name_already_used exception;
    pragma exception_init(name_already_used, -955);
  begin
    -- execute the array of statement.
    ad_apps_private.do_apps_array_ddl(copy_huge_view.toschema, 1, row_count);
  exception
    when invalid_num_columns then
      -- trap the error ora-1730 invalid number of columns
      -- this happens when trying to copy an invalid view that
      -- was created on an oracle6 database using select *
      -- syntax.  Now if the underlying table has changed shape
      -- the number of columns in the view will not match the
      -- number being selected, thus causing this error.
      -- We will skip this view as it is inherently invalid,
      -- and cannot be created even with the force option.
      -- This happens for some R9 views after an upgrade, and
      -- may happen for custom views as well.  This is not
      -- a problem for any views created on oracle7 because
      -- Oracle7 will convert the select * into the column list.
      null;
    when name_already_used then
      -- first reset error buf
      ad_apps_private.error_buf := null;
      -- drop any synonym that may exist by the same name
      ad_apps_private.drop_object(copy_huge_view.toschema,view_name, 'SYNONYM');
      ad_apps_private.do_apps_array_ddl(copy_huge_view.toschema, 1, row_count);
    when others then
      log_debug_message('Exception procedure copy_huge_view ');
      raise;
    end;

  log_debug_message('End procedure copy_huge_view ');
exception
  when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
    -- reset main error buffer
    ad_apps_private.error_buf := null;
  when others then
    ad_apps_private.error_buf := 'copy_huge_view('||
        view_name||','||fromschema||','||toschema||'): '||
         ad_apps_private.error_buf;
    log_debug_message('Exception procedure copy_huge_view ');
    raise;

end copy_huge_view;


procedure compare_view_text
           (view_name  in         varchar2,
            fromschema in         varchar2,
            toschema   in         varchar2,
            from_len   in         number,
            to_len     in         number,
            equal      out nocopy varchar2)
is
  max_easy_len   number;
  local_equal    varchar2(10);
  extra_err_info varchar2(100);
  src_vw_text    varchar2(32760);
  dst_vw_text    varchar2(32760);
  c1             integer;
  statement1     varchar2(256);
  position1       number;
  val_length1     number;
  c2             integer;
  statement2     varchar2(256);
  position2       number;
  val_length2     number;
  rows_processed integer;
  v_fromschema varchar2(30);
  v_toschema varchar2(30);

begin

-- Sql Injection Bug 25248691 verify schemas

  log_debug_message('Begin procedure compare_view_text ');
   v_fromschema := sys.dbms_assert.schema_name(fromschema);
   v_toschema := sys.dbms_assert.schema_name(toschema);

  -- Initialize variables

  local_equal := 'FALSE';
  equal := local_equal;
  max_easy_len := 32760; -- must match declarations of (src|dst)_vw_text

  -- Return FALSE if view lengths not equal

  if from_len <> to_len then
    return;
  end if;

  -- Do a piecewise select from the long column into the
  -- local variables in a loop, and keep comparing them until
  -- we find a difference or run out of text to compare

  -- Setup select for source view

  -- for long column, position zero is first character

  position1 := 0;
  val_length1 := max_easy_len;

  -- create select statement

-- Sql Injection Bug 25248691: Using bind variables instead of concatenation.

  c1 := sys.dbms_sql.open_cursor;
  statement1 := 'select text into :view_text from sys.dba_views '||
  'where owner=upper(:b_fromschema) '||
  'and view_name=upper(:b_view_name) '||
  ' and text_length= :b_from_len';

  sys.dbms_sql.parse(c1, statement1, dbms_sql.native);
  dbms_sql.bind_variable(c1,'b_fromschema',fromschema);
  dbms_sql.bind_variable(c1,'b_view_name',view_name);
  dbms_sql.bind_variable(c1,'b_from_len',from_len);
  sys.dbms_sql.define_column_long(c1,1);
  rows_processed := sys.dbms_sql.execute(c1);

  if sys.dbms_sql.fetch_rows(c1) <= 0 then
    sys.dbms_sql.close_cursor(c1);
    extra_err_info := ' <L SRC> ';
    raise no_data_found;
  end if;

  -- Setup select for dest view

  position2 := 0;
  val_length2 := max_easy_len;

  -- create select statement

-- Sql Injection Bug 25248691: Using bind variables instead of concatenation.

  c2 := sys.dbms_sql.open_cursor;
  statement2 := 'select text into :view_text from sys.dba_views '||
                'where owner=upper(:b_toschema) '||
                'and view_name=upper(:b_view_name) '||
                'and text_length= :b_to_len';

  sys.dbms_sql.parse(c2, statement2, dbms_sql.native);
  dbms_sql.bind_variable(c2,'b_toschema',toschema);
  dbms_sql.bind_variable(c2,'b_view_name',view_name);
  dbms_sql.bind_variable(c2,'b_to_len',to_len);
  sys.dbms_sql.define_column_long(c2,1);
  rows_processed := sys.dbms_sql.execute(c2);

  if sys.dbms_sql.fetch_rows(c2) <= 0 then
    sys.dbms_sql.close_cursor(c2);
    extra_err_info := ' <L DST> ';
    raise no_data_found;
  end if;

  -- loop through chunks of view text and compare them

  while val_length1 = max_easy_len loop

    -- Get chunk of source view text

    sys.dbms_sql.column_value_long(c1, 1, max_easy_len, position1,
         src_vw_text, val_length1);

    position1 := position1 + val_length1;

    -- Get chunk of destination view text

    sys.dbms_sql.column_value_long(c2, 1, max_easy_len, position2,
         dst_vw_text, val_length2);

    position2 := position2 + val_length2;

    -- compare chunks

    if src_vw_text <> dst_vw_text then

      -- views not equal

      sys.dbms_sql.close_cursor(c1);
      sys.dbms_sql.close_cursor(c2);
      return;
    end if;

  end loop;

  -- If we got this far, the views are equal

  sys.dbms_sql.close_cursor(c1);
  sys.dbms_sql.close_cursor(c2);

  local_equal := 'TRUE';
  equal := local_equal;
  log_debug_message('End procedure compare_view_text ');
  return;

exception
  when others then
    ad_apps_private.error_buf := 'compare_view_text('||
        view_name||','||fromschema||','||toschema||
        ','||from_len||','||to_len||','||local_equal||')'||
        extra_err_info||': '||
         ad_apps_private.error_buf;
    log_debug_message('Exception - procedure compare_view_text ');
    raise;

end compare_view_text;


procedure copy_code
           (object_name in varchar2,
            object_type in varchar2,
            from_schema in varchar2,
            to_schema   in varchar2)
is
  success_with_comp_error exception;
  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
  source_text           varchar2(2000);
  row_count             integer;
  prog_text             varchar2(32760);
  v_object_name varchar2(128);
  v_object_type varchar2(128);
  v_from_schema varchar2(128);
  v_to_schema varchar2(128);

  cursor c1 is
    select text from sys.dba_source
    where owner = upper(copy_code.from_schema)
    and name = copy_code.object_name
    and type = copy_code.object_type
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
  header_string         varchar2(500);
begin
  -- sql injection bug 25248691 Validating input values

  log_debug_message('Begin procedure copy_code ');
  v_from_schema := sys.dbms_assert.schema_name(from_schema);
  v_to_schema := sys.dbms_assert.schema_name(to_schema);
  v_object_name := sys.dbms_assert.enquote_name(object_name,FALSE);
  v_object_type := validate_type(object_type);

  -- first get the source text
  -- purposely starting counter at 1 as later we add the
  -- create or replace at line 1
  row_count:=1;
  for c1rec in c1 loop
    row_count:=row_count+1;

    -- check line length
    --
    -- If longer than 255 characters, check to see if package contains
    --  a Header string.
    --   If so, fail
    --   If not, skip copying package and return successfully
    -- The assumption here is that a package without a Header string is
    --   not an Oracle E-Business Suite package, so we can safely skip copying
    --   the package.

    if length(c1rec.text) > 255 then

      open PKG_HEADER(from_schema, object_name, object_type);

      fetch PKG_HEADER
      into header_string;

      if PKG_HEADER%NOTFOUND then
        -- no header, so just return without copying PKG

        close PKG_HEADER;
        return;

      else
        -- has header, so fail

        close PKG_HEADER;
        raise_application_error(-20000,
          object_type||' '||from_schema||'.'||object_name||
          ': Line '||to_char(row_count-1)||' longer than 255 characters.');
      end if;

    end if;

    -- build one line of sql statement in the global variable in
    -- the global array variable in to schema.

  ad_apps_private.do_array_assignment(copy_code.to_schema,c1rec.text, row_count);
  end loop;
  -- once we have fetched all source
  -- then create the object
  declare
    statement           varchar2(256);
    name_already_used   exception;
    pragma exception_init(name_already_used, -955);
  begin
    statement := 'create or replace ';
    -- build the first line of the array of sql statement
    ad_apps_private.do_array_assignment(copy_code.to_schema, statement, 1);
    -- execute the array of statement.
    ad_apps_private.do_apps_array_ddl(copy_code.to_schema, 1, row_count);
  exception
    when name_already_used then
      -- first reset error buf
      ad_apps_private.error_buf := null;
      -- drop any synonym by such name and retry
      ad_apps_private.drop_object(copy_code.to_schema,object_name, 'SYNONYM');
      ad_apps_private.do_apps_array_ddl(copy_code.to_schema, 1, row_count);
  end;
  log_debug_message('End procedure copy_code ');
exception
  when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
    -- reset main error buffer
    ad_apps_private.error_buf := null;
  when others then
   ad_apps_private.error_buf :='ad_apps_private.copy_code('||object_name||','
       ||object_type||','||from_schema||','||to_schema||'): '
        || ad_apps_private.error_buf;
    log_debug_message('Exception - procedure copy_code ');
    raise;

  log_debug_message('End procedure copy_code ');
end copy_code;


procedure compare_code
           (object_name in         varchar2,
            object_type in         varchar2,
            from_schema in         varchar2,
            to_schema   in         varchar2,
            comp_level  in         varchar2,
            equal       out nocopy varchar2)
is
  cursor LINE_COUNT (c_owner in varchar2,
                     c_name  in varchar2,
                     c_type  in varchar2) is
    select count(*)
    from sys.dba_source
    where owner = upper(c_owner)
    and   name  = upper(c_name)
    and   type  = upper(c_type);
  cursor LINE_AND_CHAR_COUNT (c_owner in varchar2,
                           c_name  in varchar2,
                           c_type  in varchar2) is
    select count(*), sum(length(text))
    from sys.dba_source
    where owner = upper(c_owner)
    and   name  = upper(c_name)
    and   type  = upper(c_type);
  cursor SET_DIFFERENCE (s_owner in varchar2,
                         d_owner in varchar2,
                         c_name  in varchar2,
                         c_type  in varchar2) is
     SELECT /*+FIRST_ROWS */
         'X'
     FROM
        sys.dba_source ds1,
        sys.dba_source ds2
     WHERE
           ds1.owner = UPPER(s_owner)
     AND   ds1.name  = UPPER(c_name )
     AND   ds1.type  = UPPER(c_type )
     AND   ds2.owner = UPPER(d_owner)
     AND   ds2.name  = UPPER(c_name )
     AND   ds2.type  = UPPER(c_type )
     AND  (ds1.line <> ds2.line
     OR    ds1.text <> ds2.text     )
     AND   rownum =1;
  local_equal    varchar2(10);
  dummy_text     varchar2(100);
  extra_err_info varchar2(100);
  source_num_lines   number;
  dest_num_lines     number;
  source_num_chars   number;
  dest_num_chars     number;
  v_object_name varchar2(128);
  v_object_type varchar2(128);
  v_from_schema varchar2(30);
  v_to_schema varchar2(30);

begin
  -- sql injection bug 25248691 Verify schemas

  log_debug_message('Begin procedure compare_code ');
  v_from_schema := sys.dbms_assert.schema_name(from_schema);
  v_to_schema := sys.dbms_assert.schema_name(to_schema);

  -- sql injection bug 25248691 enquote object_name and validate type

  v_object_name := sys.dbms_assert.enquote_name(object_name,FALSE);
  v_object_type := validate_type(object_type);

  -- Exit immediately if comp_level = 'none'

  if lower(comp_level) = 'none' then
    local_equal := 'TRUE';
    equal := local_equal;
    return;
  end if; -- caller doesn't really want comparison

  -- Initialize variables

  local_equal := 'FALSE';
  equal := local_equal;

  --
  --   comp_level valid values, and what they mean:
  --
  --     none   : return "equal" without comparing objects
  --
  --     lines  : compare number of source lines in each object
  --              return "equal" if same number of source lines
  --
  --     chars  : compare number of source lines and number of
  --              source chars in each object
  --              return "equal" if same number of source lines and chars
  --
  --     full   : compare number of source lines in each object,
  --              then compare actual source text
  --              return "equal" only if exactly equal
  --

  -- Validate comparison level

  dummy_text := lower(comp_level);

  if dummy_text <> 'none' and
     dummy_text <> 'lines' and
     dummy_text <> 'chars' and
     dummy_text <> 'full' then

    extra_err_info := ' <Invalid comp_level: '''||comp_level||'''> ';
    raise no_data_found;
  end if; -- validation

  -- If 'lines' or 'full' specified, get number of source lines

  if lower(comp_level) = 'lines' or
     lower(comp_level) = 'full' then

    -- Get number of source lines for source object

    open LINE_COUNT(from_schema, object_name, object_type);

    fetch LINE_COUNT
    into source_num_lines;

    close LINE_COUNT;

    -- Get number of source lines for destination object

    open LINE_COUNT(to_schema, object_name, object_type);

    fetch LINE_COUNT
    into dest_num_lines;

    close LINE_COUNT;

    -- return not equal if number of lines is not the same

    if source_num_lines <> dest_num_lines then
      return;
    end if;

    -- Exit and claim objects equal if comp_level = 'lines'

    if lower(comp_level) = 'lines' then
      local_equal := 'TRUE';
      equal := local_equal;
      return;
    end if; -- comp_level is lines

  end if; -- comp_level is 'lines' or 'full'

  -- compute number of lines and chars at same time if
  -- comp_level is chars

  if lower(comp_level) = 'chars' then

    -- Get number of source lines and chars for source object

    open LINE_AND_CHAR_COUNT(from_schema, object_name, object_type);

    fetch LINE_AND_CHAR_COUNT
    into source_num_lines, source_num_chars;

    close LINE_AND_CHAR_COUNT;

    -- Get number of source lines and chars for destination object

    open LINE_AND_CHAR_COUNT(to_schema, object_name, object_type);

    fetch LINE_AND_CHAR_COUNT
    into dest_num_lines, dest_num_chars;

    close LINE_AND_CHAR_COUNT;

    -- return not equal if number of lines is not the same

    if source_num_lines <> dest_num_lines then
      log_debug_message('End procedure compare_code ');
      return;
    end if;

    -- return not equal if number of chars is not the same

    if source_num_chars <> dest_num_chars then
      log_debug_message('End procedure compare_code ');
      return;
    end if;

    -- Exit success because comp_level = 'chars'

    local_equal := 'TRUE';
    equal := local_equal;
    log_debug_message('End procedure compare_code ');
    return;

  end if; -- comp_level is chars

  -- Do full text compare using set difference

  if lower(comp_level) = 'full' then
    -- Open set difference cursor, select from it, and see if
    -- any rows are returned

    open SET_DIFFERENCE (from_schema, to_schema, object_name, object_type);

    fetch SET_DIFFERENCE
    into dummy_text;

    if SET_DIFFERENCE%NOTFOUND then
      -- no rows returned: objects are equal

      close SET_DIFFERENCE;
      local_equal := 'TRUE';
      equal := local_equal;
      log_debug_message('End procedure compare_code ');
      return;
    else
      -- a row was returned: objects not equal

      close SET_DIFFERENCE;
      log_debug_message('End procedure compare_code ');
      return;
    end if;

  end if; -- user specified full compare

  -- If we got this far, we had a logic error somewhere above

  extra_err_info := ' <internal logic error> ';
  raise no_data_found;

exception
  when others then
    ad_apps_private.error_buf := 'ad_apps_private.compare_code('||
      object_name||','||object_type||','||from_schema||','||to_schema||
      ','||comp_level||','||local_equal||')'||extra_err_info||': '||
      ad_apps_private.error_buf;
    log_debug_message('Exception -  procedure compare_code ');
    raise;

end compare_code;


procedure create_base_gs
           (base_schema in varchar2,
            apps_schema in varchar2,
            force       in varchar2)
is
  name_already_used     exception;
  pragma exception_init(name_already_used, -955);

  --
  -- In 'union all' statements corresponding columns must have
  -- the same data type. PL/SQL uses first select to determine the
  -- column type. If the other select statements return a different
  -- (or in this case longer varchar2) data type it raises
  -- 'ORA-06502: PL/SQL: numeric or value' error.
  -- Because of that we need to rpad 'TABLE' with extra 3 spaces.
  -- Code uses rtrim() to remove them.
  -- bug1301043.
  --
  cursor grants_cursor is
    (select table_name object_name, 'TABLE   ' object_type
     from sys.dba_tables
     where owner= upper(base_schema)
     and   iot_name is null
     and   table_name not like '%$%'
     minus
     select queue_table object_name, 'TABLE   ' object_type
     from sys.dba_queue_tables
     where owner= upper(base_schema)
     and   queue_table not like '%$%')
    union all
    select sequence_name object_name, 'SEQUENCE' object_type
    from sys.dba_sequences
    where sequence_owner= upper(base_schema)
    and sequence_name not like '%$%';

  cursor synonyms_cursor is
    Select Nvl(Ev.View_Name,Tab.Table_Name) Target_name, Tab.table_name object_name, 'TABLE   ' object_type
    From sys.Dba_Tables Tab
    Left Outer Join
    sys.Dba_Editioning_Views Ev
    On (Tab.Table_Name=Ev.table_Name)
    Where Tab.Owner=Nvl(Ev.Owner, Tab.Owner)
    And   Tab.Owner=upper(base_schema)
    And   Tab.Iot_Name Is Null
    And   Tab.Table_Name Not Like '%$%'
    And Not Exists (Select 'x'
                    From  sys.Dba_Queue_Tables Q
                    Where Owner=Tab.Owner
                    And   Queue_Table=Tab.Table_Name
                    And   Queue_table not like '%$%')
    And Not Exists (Select 'x'
                    From  sys.Dba_Synonyms Syn
                    Where Syn.Owner=upper(apps_schema)
                    And   Syn.Table_Name=Nvl(Ev.View_Name,Tab.Table_Name)
                    And   Syn.Table_Owner=Tab.Owner)
    union all

    select sequence_name Target_name, sequence_name object_name, 'SEQUENCE' object_type
    from   sys.dba_sequences seq
    where  sequence_owner= upper(base_schema)
    and    sequence_name not like '%$%'
    Minus
    select ds.synonym_name Target_name, ds.synonym_name object_name, 'SEQUENCE' object_type
    from   sys.dba_synonyms ds
    where  ds.owner = upper(apps_schema)
    and    ds.table_owner  = upper(base_schema)
    and    ds.synonym_name = ds.table_name
    and    ds.table_name not like '%$%';

  statement varchar2(500);
  what_part varchar2(30);
  found_cust varchar2(10);
  cust_correct varchar2(10);
  cust_row_index number;
  l_fnd_schema varchar2(30);
  replace_existing_syn_tmp varchar2(20);
  replace_existing_syn BOOLEAN;
  syn_name varchar2(40);
  v_base_schema varchar2(30);
  v_apps_schema varchar2(30);
  v_fnd_schema  varchar2(30);

begin

-- Sql Injection Bug 25248691 Validating the schemas

  log_debug_message('Begin procedure create_base_gs ');
  v_base_schema := sys.dbms_assert.schema_name(base_schema);
  v_apps_schema := sys.dbms_assert.schema_name(apps_schema);

  -- Create grants (whether they exist already or not)

  SELECT oracle_username
  INTO   l_fnd_schema
  FROM   fnd_oracle_userid
  WHERE  read_only_flag='E';

  v_fnd_schema := sys.dbms_assert.schema_name(l_fnd_schema);

  what_part := 'In Grants Loop:';

  for grant_rec in grants_cursor loop
     create_grant(p_grantor_schema_name =>base_schema,
    p_grantee_schema_name => apps_schema,
    p_object_name         => rtrim(grant_rec.object_name),
    p_privileges          => 'ALL',
    p_with_grant_option   => TRUE);
  end loop;

  -- Drop synonyms (if force='TRUE')

  what_part := 'In Drop Synonyms Loop:';

  if force = 'TRUE' then
    for drop_rec in grants_cursor loop

      -- Check to see if this is an active exception object

      if matching_exception_object(base_schema, rtrim(drop_rec.object_name),
                                   rtrim(drop_rec.object_type),
                                   'STANDARD_EXCEPTION',
                                   apps_schema, found_cust, cust_correct,
                                   cust_row_index) then
        --
        -- Active 'STANDARD_EXCEPTION' exception object
        --
        -- If customized object in APPS exists and is a synonym, drop it.
        -- Otherwise, don't do anything
        --
        if     found_cust = 'TRUE'
           and apps_type(cust_row_index) = 'SYNONYM' then

          ad_apps_private.drop_object(apps_schema, apps_name(cust_row_index),
                                      'SYNONYM');
        end if;
        -- end if customized object exists and is synonym
      else
        -- Existing object in APPS should be a synonym.  Just drop it.

        ad_apps_private.drop_object(apps_schema, rtrim(drop_rec.object_name),
                                    'SYNONYM');
      end if;
      -- end if active exception object
    end loop;
  end if;
  -- end if force=TRUE

  -- Create synonyms (if not there, or if incorrect)

  what_part := 'In Synonyms Loop:';

  --
  -- Note that the query for this loop returns all base schema tables
  -- and synonyms for which there is not a synonym with the same name
  -- in APPS pointing to the table/synonym.  Because it is possible for
  -- the trigger object for an exception to exist and the actual exception
  -- object in APPS to not exist, we just skip all active exception objects
  -- in this loop, and handle them in another loop after this one.
  --
  for syn_rec in synonyms_cursor loop

    -- (re)create synonym if not an active exception object

	if not matching_exception_object(base_schema, rtrim(syn_rec.object_name),
                                     rtrim(syn_rec.object_type),
                                     'STANDARD_EXCEPTION',
                                     apps_schema, found_cust, cust_correct,
                                     cust_row_index) then
    -- not an active exception object.  Calculate the replace_existing_syn flag.

    -- Bug 30355167, jwsmith - added Ds.Owner chk in following sql
	Select decode (Computed_Value.Val,1,'TRUE','FALSE') into replace_existing_syn_tmp
    From (Select Count(1) as val
          From   sys.Dba_Synonyms Ds
	      where  Ds.Table_Owner = upper(base_schema)
                     and ds.owner= upper(apps_schema)
          And    Ds.Table_Name = rtrim(Syn_Rec.object_Name)) Computed_Value;

    if (replace_existing_syn_tmp = 'TRUE') then
	   replace_existing_syn := TRUE;
	else
	   replace_existing_syn := FALSE;
	end if;

    -- finding the synonym name for each object_name

    IF replace_existing_syn= TRUE THEN
        Select ds.synonym_name into syn_name
        From   sys.dba_synonyms ds
        Where  ds.table_owner= upper(base_schema)
		And    ds.table_name = rtrim(Syn_Rec.object_Name);
    ELSE
        Select rtrim(Syn_Rec.object_Name) into syn_name
        From dual;
    END IF;
    -- End finding the synonym name for each object_name
    -- create the synonyms
	create_synonym(p_from_schema_name => base_schema,
    p_from_object_name => rtrim(syn_rec.Target_Name),
    p_to_schema_name   => apps_schema,
    p_to_object_name   => rtrim(syn_name),
    p_replace_existing => replace_existing_syn);
    end if;
    -- end if not an active exception object
  end loop;

-- Handle active exception objects

  what_part := 'In Exception Objects Loop:';

  for excpt_rec in grants_cursor loop

    -- Check to see if this is an active exception object

    if matching_exception_object(base_schema, rtrim(excpt_rec.object_name),
                                 rtrim(excpt_rec.object_type),
                                 'STANDARD_EXCEPTION',
                                 apps_schema, found_cust, cust_correct,
                                 cust_row_index) then
      --
      -- Active 'STANDARD_EXCEPTION' exception object
      --
      -- if customized object does not exist
      --   if not synonym, fatal error
      --   if synonym, create it
      --
      -- if customized object exists and is not correct
      --   if not synonym, fatal error
      --   if synonym drop and recreate
      --
      -- if customized object exists and is correct, don't do anything
      --
      if found_cust = 'FALSE' then
        if apps_type(cust_row_index) <> 'SYNONYM' then

          -- customized object not a synonym and not there.  No way
          -- we can repair it in this procedure.  fatal error

          raise_application_error(-20001,
            apps_type(cust_row_index)||' '||
            apps_schema||'.'||apps_name(cust_row_index)||
            ' is missing exception object.');
        else

    -- customized object is not there, but it is a synonym
    -- create it
    DECLARE
       l_from_schema_name sys.dba_objects.owner%TYPE;
    BEGIN
       IF (points_to_schema(cust_row_index) = 'BASE') THEN
   l_from_schema_name := base_schema;
        ELSE
   l_from_schema_name := apps_schema;
       END IF;
       create_synonym(p_from_schema_name => l_from_schema_name,
        p_from_object_name => get_evname(points_to_name(cust_row_index), l_from_schema_name),
        p_to_schema_name   => apps_schema,
        p_to_object_name   => apps_name(cust_row_index),
        p_replace_existing => FALSE);
    END;
        end if;
        -- end if missing customized object is not a synonym
      else
        -- customized object exists
        -- if not correct and not synonym, fatal error
        -- if not correct and is synonym, drop and recreate it

        if cust_correct = 'FALSE' then
          if apps_type(cust_row_index) <> 'SYNONYM' then

            -- customized object not a synonym and not correct.  No way
            -- we can repair it in this procedure.  fatal error

            raise_application_error(-20001,
              apps_type(cust_row_index)||' '||
              apps_schema||'.'||apps_name(cust_row_index)||
              ' is incorrect exception object.');
          else

            -- customized object is an existing but incorrect synonym
            -- drop it and then recreate it

            -- Drop synonym

            ad_apps_private.drop_object(apps_schema,
              apps_name(cust_row_index), 'SYNONYM');

            -- Recreate synonym
     DECLARE
        l_from_schema_name sys.dba_objects.owner%TYPE;
     BEGIN
        IF (points_to_schema(cust_row_index) = 'BASE') THEN
    l_from_schema_name := base_schema;
  ELSE
    l_from_schema_name := apps_schema;
        END IF;
        create_synonym(p_from_schema_name => l_from_schema_name,
         p_from_object_name => get_evname(points_to_name(cust_row_index), l_from_schema_name),
         p_to_schema_name   => apps_schema,
         p_to_object_name   => apps_name(cust_row_index),
         p_replace_existing => FALSE);
     END;
          end if;
          -- end if incorrect customized object is not a synonym
        end if;
        -- end if customized object exists, but is not correct
      end if;
      -- end if active customization, but customized object not there
    end if;
    -- end if active exception object
  end loop;
  -- end loop to handle exception objects
  log_debug_message('End procedure create_base_gs ');

exception
  when others then
    ad_apps_private.error_buf := 'create_base_gs('||base_schema||','||
        apps_schema||'): '||what_part||ad_apps_private.error_buf;
    log_debug_message('Exception - procedure create_base_gs ');
    raise;
  log_debug_message('End procedure create_base_gs ');
end create_base_gs;

procedure create_base_gs
           (base_schema in varchar2,
            apps_schema in varchar2)
is
begin
create_base_gs (base_schema => base_schema,
                apps_schema => apps_schema,
                force       => 'FALSE');
end;


procedure create_gs
           (object_owner_schema in varchar2,
            to_schema           in varchar2,
            object_name         in varchar2,
            with_option         in boolean,
            privs               in varchar2,
            grant_from_schema   in varchar2 default null,
            to_ev               in varchar2 default 'N'
)
is
  with_option_print varchar2(10);
  l_evname varchar2(30);
  v_object_owner_schema varchar2(128);
  v_to_schema varchar2(30);

begin
  -- Sql Injection Bug 25248691 Validate schema name
  log_debug_message('Begin procedure create_gs ');
  v_to_schema := sys.dbms_assert.schema_name(to_schema);
  v_object_owner_schema := sys.dbms_assert.schema_name(object_owner_schema);

   -- Perform the grant first so that the last_ddl_time on the base
   -- object is less than the synonym.  This facilitates the restart better
   -- grant all for each table/sequence

   if (to_ev = 'Y')
   then
      l_evname  := get_evname(object_name, object_owner_schema);
   end if;

   create_grant(p_grantor_schema_name => object_owner_schema,
  p_grantee_schema_name => to_schema,
  p_object_name         => object_name,
  p_privileges          => privs,
  p_with_grant_option   => with_option);

  if (to_ev = 'Y')
  then
      create_grant(p_grantor_schema_name => object_owner_schema,
     p_grantee_schema_name => to_schema,
     p_object_name         => l_evname,
     p_privileges          => privs,
     p_with_grant_option   => with_option);
  end if;

  if (to_ev = 'Y')
  then
     create_synonym(p_from_schema_name => object_owner_schema,
      p_from_object_name => l_evname,
      p_to_schema_name   => to_schema,
      p_to_object_name   => object_name,
      p_replace_existing => TRUE);
  else
     create_synonym(p_from_schema_name => object_owner_schema,
      p_from_object_name => object_name,
      p_to_schema_name   => to_schema,
      p_to_object_name   => object_name,
      p_replace_existing => TRUE);
  end if;
exception
  when others then
     if with_option then
 with_option_print := 'TRUE';
      else
 with_option_print := 'FALSE';
     end if;

    ad_apps_private.error_buf := 'ad_apps_private.create_gs('||
        object_owner_schema||','||to_schema||','||object_name||
        ', '||with_option_print||','||privs||','||
        grant_from_schema||'): '||ad_apps_private.error_buf;
    raise;
  log_debug_message('End procedure create_gs ');
end create_gs;


--
-- Procedures used to create an APPS/MLS schema
--

procedure create_synonyms
           (from_schema       in varchar2,
            to_schema         in varchar2,
            grant_from_schema in varchar2 default null)
is
  cursor c1 is
    select ds.synonym_name
    from sys.dba_synonyms ds
    where ds.owner = upper(from_schema)
    and   ds.synonym_name = ds.table_name -- regular synonyms only
    and   ds.synonym_name not like '%$%';
  exact_syn_match       boolean;
  any_obj_w_this_name   boolean;
  type_of_obj           varchar2(200);
  extra_err_info        varchar2(100);
  name_already_used     exception;
  pragma exception_init(name_already_used, -955);
begin
  for c1rec in c1 loop
    --
    -- Check for exact synonym match.  Drop and recreate synonym
    -- if not exact synonym match
    --
    ad_apps_private.exact_synonym_match(to_schema, c1rec.synonym_name,
      from_schema, c1rec.synonym_name, exact_syn_match,
      any_obj_w_this_name, type_of_obj);

    if not exact_syn_match then

      -- Drop existing object, if any

      if any_obj_w_this_name then

        -- Fail if table
        if type_of_obj = 'TABLE' then
          extra_err_info := ' <'||to_schema||'.'||c1rec.synonym_name||
            ' is a table.> ';
          raise name_already_used;
        end if; -- fail if existing object is a table

        -- just drop object if not a table

        if    type_of_obj = 'PKG_S_AND_B'
           or type_of_obj = 'PACKAGE'
           or type_of_obj = 'PACKAGE BODY' then
          -- existing object is package
          ad_apps_private.drop_object(to_schema, c1rec.synonym_name,
                                      'PACKAGE');
        else
          -- existing object not package
          ad_apps_private.drop_object(to_schema, c1rec.synonym_name,
                                      type_of_obj);
        end if; -- end if existing object is package
      end if;  -- end if any existing object with this name in toschema

      -- create grant/synonym
      begin
        if grant_from_schema is not null then
          ad_apps_private.create_gs(from_schema,to_schema,
              c1rec.synonym_name,FALSE,'ALL',grant_from_schema);
        else
          ad_apps_private.create_gs(from_schema,to_schema,
              c1rec.synonym_name,TRUE,'ALL');
        end if;
      exception
        when name_already_used then
          -- first reset error buf
          ad_apps_private.error_buf := null;
          -- first drop synonym
          ad_apps_private.drop_object(to_schema,c1rec.synonym_name,
                                      'SYNONYM');
          -- then create the synonym
          if grant_from_schema is not null then
            ad_apps_private.create_gs(from_schema,to_schema,
                c1rec.synonym_name,FALSE,'ALL',grant_from_schema);
          else
            ad_apps_private.create_gs(from_schema,to_schema,
                c1rec.synonym_name,TRUE,'ALL');
          end if;
      end; -- block for creating the grant/synonym
    end if; -- not exact synonym match: (re-)create synonym
  end loop; -- through all normal synonyms in APPS

exception
  when others then
    ad_apps_private.error_buf := 'create_synonyms('||
      from_schema||','||to_schema||','||grant_from_schema||')'||
      extra_err_info||': '||
      ad_apps_private.error_buf;
    raise;
end create_synonyms;


procedure copy_odd_synonyms
           (fromschema in varchar2,
            toschema   in varchar2)
is
  cursor c1 is
    select ds.synonym_name
    from sys.dba_synonyms ds
    where ds.owner = upper(fromschema)
    and   ds.synonym_name <> ds.table_name; -- odd synonyms only
  exact_syn_match       boolean;
  any_obj_w_this_name   boolean;
  type_of_obj           varchar2(200);
  extra_err_info        varchar2(100);
  name_already_used     exception;
  pragma exception_init(name_already_used, -955);
begin
  for c1rec in c1 loop
    --
    -- Check for exact synonym match.  Drop and recreate synonym
    -- if not exact synonym match
    --
    ad_apps_private.exact_synonym_match(toschema, c1rec.synonym_name,
      fromschema, c1rec.synonym_name, exact_syn_match,
      any_obj_w_this_name, type_of_obj);

    if not exact_syn_match then

      -- Drop existing object, if any

      if any_obj_w_this_name then

        -- Fail if table
        if type_of_obj = 'TABLE' then
          extra_err_info := ' <'||toschema||'.'||c1rec.synonym_name||
            ' is a table.> ';
          raise name_already_used;
        end if; -- fail if existing object is a table

        -- just drop object if not a table

        if    type_of_obj = 'PKG_S_AND_B'
           or type_of_obj = 'PACKAGE'
           or type_of_obj = 'PACKAGE BODY' then
          -- existing object is package
          ad_apps_private.drop_object(toschema, c1rec.synonym_name,
                                      'PACKAGE');
        else
          -- existing object not package
          ad_apps_private.drop_object(toschema, c1rec.synonym_name,
                                      type_of_obj);
        end if; -- end if existing object is package
      end if;  -- end if any existing object with this name in toschema

      -- create grant/synonym
      begin
        ad_apps_private.create_gs(fromschema,toschema,
          c1rec.synonym_name,TRUE,'ALL');
      exception
        when name_already_used then
          -- first reset error buf
          ad_apps_private.error_buf := null;
          -- first drop synonym
          ad_apps_private.drop_object(toschema, c1rec.synonym_name,
                                      'SYNONYM');
          -- then create the synonym
          ad_apps_private.create_gs(fromschema,toschema,
            c1rec.synonym_name,TRUE,'ALL');
      end; -- block for creating the grant/synonym
    end if; -- not exact synonym match: (re-)create synonym
  end loop; -- through all normal synonyms in APPS

exception
  when others then
    ad_apps_private.error_buf := 'copy_odd_synonyms('||
      fromschema||','||toschema||')'||extra_err_info||': '||
      ad_apps_private.error_buf;
    raise;
end copy_odd_synonyms;


procedure create_special_views
           (install_group_num in number,
            aol_schema        in varchar2,
            apps_schema       in varchar2,
            create_mls_views  in boolean)
is
  oracle_id_cursor      integer;
  rows_processed        integer;
  table_schema          varchar2(30);
  v_aol_schema          varchar2(30);
  v_apps_schema         varchar2(30);

  -- select distinct as multiple products can share the same oracleid
  -- select only those oracle_ids that belong to the current data
  -- group or the 0 datagroup (0 meaning a single install product)
  oracle_id_sql constant varchar2(2000) := ign_schema_select_part1||
          sys.dbms_assert.schema_name(upper(aol_schema))
          ||ign_schema_select_part2||aol_schema||
          ign_schema_select_part3||' in (to_char(:install_g_num), 0 )';
begin
  -- sql injection bug 25248691
  log_debug_message('Begin procedure create_special_views');
  v_aol_schema := sys.dbms_assert.schema_name(aol_schema);
  v_apps_schema := sys.dbms_assert.schema_name(apps_schema);

  oracle_id_cursor := dbms_sql.open_cursor;
  dbms_sql.parse(oracle_id_cursor, oracle_id_sql, dbms_sql.native);
  dbms_sql.bind_variable(oracle_id_cursor,'install_g_num',
                create_special_views.install_group_num);
  dbms_sql.define_column(oracle_id_cursor,1,table_schema,30);
  rows_processed := dbms_sql.execute(oracle_id_cursor);
  loop
      if dbms_sql.fetch_rows(oracle_id_cursor) > 0 then
        dbms_sql.column_value(oracle_id_cursor,1,table_schema);
        -- for each schema see if any of the listed tables exist in
        -- that schema and create the view in the apps schema
        declare
          c                     integer;
          rows_processed        integer;
          l_table_name          varchar2(30);
          table_mls             varchar2(1);
          statement             varchar2(32000);
          view_column_list      varchar2(20000);
          select_list           varchar2(20000);
          max_trans_date        date;
          max_xref_date         date;
          trans_record_date     date;
          view_date             date;
          table_date            date;
          view_is_old           boolean;
        begin

                -- Get value for max_trans_date
                declare
                  c                     integer;
                  rows_processed        integer;
                  statement             varchar2(500);
                begin
                  c := dbms_sql.open_cursor;

-- Sql Injection Bug 25248691

                  v_aol_schema := sys.dbms_assert.enquote_name(aol_schema,FALSE);

                  statement :=
                        'select nvl(max(last_update_date),              '||
                        '    to_date(''01/01/1970'',''DD/MM/YYYY''))    '||
                        '    from '||v_aol_schema||'.ak_translated_columns';
                  dbms_sql.parse(c, statement, dbms_sql.native);
                  dbms_sql.define_column(c,1,max_trans_date);
                  rows_processed := dbms_sql.execute(c);
                  loop
                    if dbms_sql.fetch_rows(c) > 0 then
                      dbms_sql.column_value(c,1,max_trans_date);
                    end if;
                    dbms_sql.close_cursor(c);
                    exit;
                  end loop;
                exception
                  when others then
                    dbms_sql.close_cursor(c);
                    ad_apps_private.error_buf := 'statement='||
                                                 statement||':'||
                                                 ad_apps_private.error_buf;
                    raise;
                end;


                -- Get value for max_xref_date
                declare
                  c                     integer;
                  rows_processed        integer;
                  statement             varchar2(500);
                begin
                  c := dbms_sql.open_cursor;

-- Sql Injection Bug 25248691

                  v_aol_schema := sys.dbms_assert.enquote_name(aol_schema,FALSE);

                  statement :=
                      'select nvl(max(last_update_date),              '||
                      '   to_date(''01/01/1970'',''DD/MM/YYYY''))     '||
                      '   from '||v_aol_schema||'.ak_language_attribute_xrefs';
                  dbms_sql.parse(c, statement, dbms_sql.native);
                  dbms_sql.define_column(c,1,max_xref_date);
                  rows_processed := dbms_sql.execute(c);
                  loop
                    if dbms_sql.fetch_rows(c) > 0 then
                      dbms_sql.column_value(c,1,max_xref_date);
                    end if;
                    dbms_sql.close_cursor(c);
                    exit;
                  end loop;
                exception
                  when others then
                    dbms_sql.close_cursor(c);
                    ad_apps_private.error_buf := 'statement='||
                                                 statement||':'||
                                                 ad_apps_private.error_buf;
                    raise;
                end;


            c := dbms_sql.open_cursor;

            if create_mls_views then
              -- work on tables that are multilingual

-- Sql Injection Bug 25248691

              v_aol_schema := sys.dbms_assert.enquote_name(aol_schema,FALSE);

              statement := 'select distinct upper(atc.table_name)           '||
                           'from '||v_aol_schema||
                           '.ak_translated_columns atc,'||
                           '     sys.dba_tables dt                              '||
                           'where dt.table_name = upper(atc.table_name)     '||
                           'and nvl(atc.enabled_flag,''Y'') = ''Y''         '||
                           'and dt.owner = :table_schema                    ';
            else
              -- therefore there are no special views to be created
              statement := 'select null from sys.dual where 1 = 2   '||
                           'and :table_schema = ''X''                       ';
            end if;


            dbms_sql.parse(c, statement, dbms_sql.native);
            dbms_sql.bind_variable(c,'table_schema',table_schema);
            dbms_sql.define_column(c,1,l_table_name,30);
            rows_processed := dbms_sql.execute(c);
            loop
              if dbms_sql.fetch_rows(c) > 0 then
                dbms_sql.column_value(c,1,l_table_name);

                -- initialize all comparison variables
                view_is_old := FALSE;
                view_date := to_date('01/01/1970','DD/MM/YYYY');
                table_date := to_date('01/01/1970','DD/MM/YYYY');
                trans_record_date := to_date('01/01/1970','DD/MM/YYYY');

                -- Get view_date
                select nvl(min(last_ddl_time),
                        to_date('01/01/1970','DD/MM/YYYY'))
                into view_date
                from sys.dba_objects
                where object_name = upper(l_table_name)
                and object_type = 'VIEW'
                and owner = upper(apps_schema);

                -- Get table_date
                select nvl(min(decode(last_ddl_time,sysdate,
                        to_date('31/12/2199','DD/MM/YYYY'),last_ddl_time)),
                        to_date('01/01/1970','DD/MM/YYYY'))
                into table_date
                from sys.dba_objects
                where object_name = upper(l_table_name)
                and object_type = 'TABLE'
                and owner = upper(table_schema);

                -- Get trans_record_date
                declare
                  c                     integer;
                  rows_processed        integer;
                  statement             varchar2(500);
                begin
                  c := dbms_sql.open_cursor;

-- Sql Injection Bug 25248691

                 v_aol_schema := sys.dbms_assert.enquote_name(aol_schema,FALSE);

                  statement :=
                          'select last_update_date                          '||
                          ' from '||v_aol_schema||
                          '.ak_translated_columns     '||
                          ' where upper(table_name) = upper(:table_name)    ';
                  dbms_sql.parse(c, statement, dbms_sql.native);
                  dbms_sql.bind_variable(c,'table_name',l_table_name);
                  dbms_sql.define_column(c,1,trans_record_date);
                  rows_processed := dbms_sql.execute(c);
                  loop
                    if dbms_sql.fetch_rows(c) > 0 then
                        dbms_sql.column_value(c,1,trans_record_date);
                    end if;
                    dbms_sql.close_cursor(c);
                    exit;
                  end loop;
                exception
                  when others then
                    dbms_sql.close_cursor(c);
                    ad_apps_private.error_buf := 'statement='||
                                                 statement||':'||
                                                 ad_apps_private.error_buf;
                    raise;
                end;

                -- Only recreate the view if:
                --   last_ddl_time on view is less than the underlying table
                if view_date < table_date then
                   view_is_old := TRUE;
                end if;
                --   last_ddl_time on view is less than the record in
                --      ak_translated_columns
                if view_date < trans_record_date then
                   view_is_old := TRUE;
                end if;
                --   last_ddl_time on view is less than the max_trans_date
                if view_date < max_trans_date then
                   view_is_old := TRUE;
                end if;
                --   last_ddl_time on view is less than the max_xref_date
                if view_date < max_xref_date then
                   view_is_old := TRUE;
                end if;
                --   View doesn't exist (i.e. last_update_date
                --      was null '01-JAN-70')
                if view_date = to_date('01/01/1970','DD/MM/YYYY') then
                   view_is_old := TRUE;
                end if;


                -- Only recreate the view if the existing view is old
                -- otherwise nothing has changed that would require the view to
                -- be recreated.
                if view_is_old = TRUE then
     -- for each table create grant
     create_grant(p_grantor_schema_name => table_schema,
    p_grantee_schema_name => apps_schema,
    p_object_name         => l_table_name,
    p_privileges          => 'ALL',
    p_with_grant_option   => TRUE);

                -- then build column list
                ad_mls.build_mls_column_list(l_table_name,
                                        table_schema,aol_schema,
                                        view_column_list,select_list);

                -- Create the view
                declare
                  success_with_comp_error exception;
                  PRAGMA EXCEPTION_INIT(success_with_comp_error, -24344);
                  statement             varchar2(32000);
                begin
                  statement := 'create or replace view "'||l_table_name||
                               '" '||view_column_list||
                               ' as select ' || select_list || ' from '||
                               table_schema||'."'||l_table_name||'"';

                  declare
                    name_already_used exception;
                    pragma exception_init(name_already_used, -955);
                  begin
                    ad_apps_private.do_apps_ddl(apps_schema,statement);
                  exception
                    when name_already_used then
                      -- first reset error buf
                      ad_apps_private.error_buf := null;
                      -- drop synonym and try view create again
                        ad_apps_private.drop_object(apps_schema,
                                l_table_name, 'SYNONYM');
                        ad_apps_private.do_apps_ddl(apps_schema,statement);
                  end;

                exception
                  when success_with_comp_error then
--
-- Trap and ignore ORA-24344: success with compilation error
-- This only happens on ORACLE 8
--
                    -- reset main error buffer
                    ad_apps_private.error_buf := null;
                end;
                end if;  -- view_is_old
              else
                -- no more oracle views to process for this schema
                if (dbms_sql.is_open(c)) then
                    dbms_sql.close_cursor(c);
                end if;
                exit;
              end if;
            end loop;  -- loop over all views

        exception
          when others then
            if (dbms_sql.is_open(c)) then
               dbms_sql.close_cursor(c);
            end if;
            ad_apps_private.error_buf := 'statement='||statement||': '||
                                         ad_apps_private.error_buf;
            raise;
        end;

      else
        -- no more rows to process
        if (dbms_sql.is_open(oracle_id_cursor)) then
            dbms_sql.close_cursor(oracle_id_cursor);
        end if;
        exit;
      end if;
  end loop;
  log_debug_message('End procedure create_special_views ');
exception
  when others then
    if (dbms_sql.is_open(oracle_id_cursor)) then
        dbms_sql.close_cursor(oracle_id_cursor);
    end if;
    ad_apps_private.error_buf := 'create_special_views('||install_group_num||
                ','||aol_schema||
                ','||apps_schema||',create_mls_views): '||
                ad_apps_private.error_buf;
    log_debug_message('Exception procedure create_special_views ');
    raise;
end create_special_views;


procedure copy_views
           (aoluser    in varchar2,
            fromschema in varchar2,
            toschema   in varchar2)
is
  -- Do not copy obsolete views left over by AutoInstall( 'AI9%' or 'AI1%')
  cursor view_cur is
    select v1.view_name, v1.text_length source_len,
           v2.text_length dest_len
    from sys.dba_views v1, sys.dba_views v2
    where v1.owner = upper(fromschema)
    and   v1.view_name not like 'AI9%'
    and   v1.view_name not like 'AI1%'
    and   v2.owner (+) = upper(toschema)
    and   v2.view_name (+) = v1.view_name;
  comp_result  varchar2(10);
begin
  for v_rec in view_cur loop
    --
    -- Check if view exists in destination schema,
    -- and create it if it's not already there
    --
    if v_rec.dest_len is null then
      ad_apps_private.copy_view(v_rec.view_name, fromschema, toschema);
    else
      --
      -- View exists in both schemas
      --
      -- Compare view lengths.  Re-create view in dest schema if the
      -- two views have different lengths.
      --
      if v_rec.source_len <> v_rec.dest_len then
        ad_apps_private.copy_view(v_rec.view_name, fromschema, toschema);
      else
        --
        -- View lengths equal.  Compare actual view text.
        --

        ad_apps_private.compare_view_text(v_rec.view_name, fromschema,
          toschema, v_rec.source_len, v_rec.dest_len, comp_result);

        -- Only copy view to destination schema if text not equal

        if comp_result = 'FALSE' then
          ad_apps_private.copy_view(v_rec.view_name, fromschema, toschema);
        end if;

      end if; -- view lengths equal
    end if; -- view exists in dest schema
  end loop;
exception
  when others then
    ad_apps_private.error_buf := 'copy_views('||aoluser||','||fromschema||','||
                        toschema||'): '||ad_apps_private.error_buf;
    raise;
end copy_views;


procedure copy_stored_progs
           (fromschema    in varchar2,
            toschema      in varchar2,
            p_object_type in varchar2,
            p_subset      in varchar2,
            compare_level in varchar2)
is
  -- don't do the apps_ddl procedure, because using it to drop
  -- and recreate itself is problematic
  cursor src_pls_obj is
    select do.object_name, do.object_type, do2.object_name name2
    from sys.dba_objects do, sys.dba_objects do2
    where do.owner = upper(copy_stored_progs.fromschema)
    and   do.object_type in (
     decode(copy_stored_progs.p_object_type,
                        'B',null,          'P',null,          'F',null,
                        'C',null,          'A','PACKAGE',     'S','PACKAGE',
                        'PACKAGE'),
     decode(copy_stored_progs.p_object_type,
                        'B','PACKAGE BODY','P',null,          'F',null,
                        'C','PACKAGE BODY','A','PACKAGE BODY','S',null,
                        'PACKAGE BODY'),
     decode(copy_stored_progs.p_object_type,
                        'B',null,          'P',null,          'F','FUNCTION',
                        'C','FUNCTION',    'A','FUNCTION',    'S',null,
                        'FUNCTION'),
     decode(copy_stored_progs.p_object_type,
                        'B',null,          'P','PROCEDURE',   'F',null,
                        'C','PROCEDURE',   'A','PROCEDURE',   'S',null,
                        'PROCEDURE'))
    and   do.object_name not in ('APPS_DDL', 'APPS_ARRAY_DDL')
    and   do.object_name not like 'FFP%'
    and   do.object_name like copy_stored_progs.p_subset || '%'
    and   do2.owner (+) = upper(copy_stored_progs.toschema)
    and   do2.object_name (+) = do.object_name
    and   do2.object_type (+) = do.object_type
    order by decode(do.object_type,'PACKAGE',1,2);
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
  src_header    varchar2(500);
  dst_header    varchar2(500);
  objs_equal    varchar2(10);
  object_number number;
begin
  -- loop through all package/function/procedure/pkg body in source schema

  for src_rec in src_pls_obj loop

    if src_rec.name2 is null then

      -- object not in destination schema, so copy it to destination schema

      ad_apps_private.copy_code(src_rec.object_name, src_rec.object_type,
        fromschema, toschema);

    else
      -- get header information for object in source schema

      open PKG_HEADER(fromschema, src_rec.object_name, src_rec.object_type);

      fetch PKG_HEADER
      into src_header;

      if PKG_HEADER%NOTFOUND then
        src_header := null;
      end if;

      close PKG_HEADER;

      -- If object in source schema had header information,
      -- compare headers (if possible).  Otherwise, have to do full
      -- comparison of source and destination objects

      if src_header is not null then

        -- get header information for object in destination schema

        open PKG_HEADER(toschema, src_rec.object_name, src_rec.object_type);

        fetch PKG_HEADER
        into dst_header;

        if PKG_HEADER%NOTFOUND then
          dst_header := null;
        end if;

        close PKG_HEADER;

        -- if no header information in destination object,
        -- copy source to destination

        if dst_header is null then

          ad_apps_private.copy_code(src_rec.object_name, src_rec.object_type,
            fromschema, toschema);

        else

          -- compare header strings
          -- copy source to destination if header strings different
          -- possibly do more extensive comparison if header lines same

          if src_header <> dst_header then

            ad_apps_private.copy_code(src_rec.object_name,
              src_rec.object_type, fromschema, toschema);

          else

            -- header strings are identical
            -- do object comparison according to compare_level

            ad_apps_private.compare_code(src_rec.object_name,
              src_rec.object_type, fromschema, toschema,
              compare_level, objs_equal);

            -- copy source to dest if not equal

            if objs_equal = 'FALSE' then

              ad_apps_private.copy_code(src_rec.object_name,
                src_rec.object_type, fromschema, toschema);

            end if; -- source and destination objects not identical

          end if; -- source and destination header not identical

        end if; -- destination has header information

      else

        -- no header information in source schema object
        -- do full object comparison
        -- (even if compare_level <> 'full')

        ad_apps_private.compare_code(src_rec.object_name,
          src_rec.object_type, fromschema, toschema,
          'full', objs_equal);

        -- copy source to dest if not equal

        if objs_equal = 'FALSE' then

          ad_apps_private.copy_code(src_rec.object_name,
            src_rec.object_type, fromschema, toschema);

        end if; -- source and destination objects not identical

      end if; -- source schema object has header information

    end if; -- object not in destination schema
  end loop;  -- loop over all stored progs in source schema

exception
  when others then
    ad_apps_private.error_buf := 'copy_stored_progs('||fromschema||','||
        toschema||','||p_object_type||','||p_subset||','||
        compare_level||'): '||ad_apps_private.error_buf;
    raise;
end copy_stored_progs;


procedure exact_synonym_match
           (syn_own_schema  in         varchar2,
            syn_name        in         varchar2,
            tab_owner       in         varchar2,
            tab_name        in         varchar2,
            exact_match     out nocopy boolean,
            is_obj_w_name   out nocopy boolean,
            typ_exist_obj   out nocopy varchar2)
is
  found_exact_match boolean;
  found_object_with_same_name boolean;

  cursor SYN_MATCH (c_owner          in varchar2,
                    c_synonym_name   in varchar2,
                    c_table_owner    in varchar2,
                    c_table_name     in varchar2) is
    select 'X'
    from sys.dba_synonyms
    where owner = c_owner
    and   synonym_name = c_synonym_name
    and   table_owner = c_table_owner
    and   table_name = c_table_name
    and   db_link is null;

  cursor FIND_OBJ (c_owner       in varchar2,
                   c_object_name in varchar2) is
    select object_type
    from sys.dba_objects
    where owner = c_owner
    and   object_name = c_object_name
    order by decode(object_type, 'PACKAGE', 1, 2);

  dummy1 varchar2(10);
  obj_type_found varchar2(30);
begin
  exact_match := FALSE;
  is_obj_w_name := FALSE;
  typ_exist_obj := null;

-- Sql Injection Bug 25248691
  log_debug_message('Begin procedure exact_synonym_match ');

  open SYN_MATCH(syn_own_schema, syn_name, tab_owner, tab_name);

  fetch SYN_MATCH
  into dummy1;

  if SYN_MATCH%NOTFOUND then
  -- no exact synonym match
    close SYN_MATCH;

    open FIND_OBJ(syn_own_schema, syn_name);

    fetch FIND_OBJ
    into obj_type_found;

    if FIND_OBJ%NOTFOUND then
    -- no object in schema with given name
      close FIND_OBJ;

      -- No need to set return variables, since they are already
      -- set to indicate "no matching object in schema"
    else
    -- at least one object in schema with given name

      if obj_type_found = 'PACKAGE' then
      -- found existing 'PACKAGE'.  Check for 'PACKAGE BODY' as well
        fetch FIND_OBJ
        into obj_type_found;

        if FIND_OBJ%NOTFOUND then
        -- only 'PACKAGE' found
          close FIND_OBJ;

          is_obj_w_name := TRUE;
          typ_exist_obj := 'PACKAGE';
        else
        -- found something besides 'PACKAGE'
          close FIND_OBJ;

          if obj_type_found = 'PACKAGE BODY' then
          -- end if found package body too
            is_obj_w_name := TRUE;
            typ_exist_obj := 'PKG_S_AND_B';
          else
          -- found other object w same name, but not package body
          -- this should never happen
            raise_application_error(-20000, 'Object '||syn_name||
              ' in schema '||syn_own_schema||
              ' has type PACKAGE and also type '||obj_type_found);
          end if;
          -- end if found package body too
        end if;
        -- end if only 'PACKAGE' found
      else
      -- found something other than 'PACKAGE'
        close FIND_OBJ;

        is_obj_w_name := TRUE;
        typ_exist_obj := obj_type_found;
      end if;
      -- end if found existing 'PACKAGE'

    end if;
    -- end if no object in schema with given name
  else
  -- found exact synonym match
    close SYN_MATCH;

    exact_match := TRUE;
    is_obj_w_name := TRUE;
    typ_exist_obj := 'SYNONYM';
  end if;
  -- end if no exact synonym match
  log_debug_message('End procedure exact_synonym_match ');

exception
  when others then
    ad_apps_private.error_buf := 'exact_synonym_match('||syn_own_schema||
      ','||syn_name||','||tab_owner||','||tab_name||'): '||
      ad_apps_private.error_buf;
    log_debug_message('Exception - procedure exact_synonym_match ');
    raise;
end exact_synonym_match;


procedure recomp_referenced_objs
           (object_name      in varchar2,
            object_type      in varchar2,
            obj_list_schema  in varchar2,
            recompile_schema in varchar2)
is
  v_object_name varchar2(128);
  v_object_type varchar2(128);
  v_obj_list_schema varchar2(128);
  v_recompile_schema varchar2(128);

  type NameType is table of varchar2(30)
    index by binary_integer;
  type NumType is table of binary_integer
    index by binary_integer;

  obj_names  NameType;
  obj_types  NameType;
  obj_levels NumType;
  obj_processed NumType;

  num_objs   number;

  cursor GET_DEPS (c_owner in varchar2,
                   c_type  in varchar2,
                   c_name  in varchar2,
                   c_level in number) is
    select distinct c_level, referenced_name, referenced_type
    from sys.dba_dependencies
    where owner = c_owner
    and   name  = c_name
    and   type  = c_type
    and   referenced_owner = owner
    and   referenced_type in
            ('VIEW', 'PACKAGE', 'PROCDEDURE', 'FUNCTION', 'PACKAGE BODY');

  sel_level  number;
  sel_name   varchar2(30);
  sel_type   varchar2(30);
  done_sel   boolean;
  done_sel2  boolean;
  add_object boolean;
  any_added  boolean;
  idx        number;
  i          number;
  j          number;
  start_val  number;
  end_val    number;
  max_level  number;
  dummy      varchar2(30);
  statement  varchar2(100);
begin

-- Sql Injection Bug 25248691
  log_debug_message('Begin procedure recomp_referenced_objs ');
  v_obj_list_schema := sys.dbms_assert.schema_name(obj_list_schema);
  v_recompile_schema := sys.dbms_assert.schema_name(recompile_schema);
  v_object_name := sys.dbms_assert.enquote_name(object_name,FALSE);
  v_object_type := validate_type(object_type);

  num_objs := 0;
  done_sel := FALSE;
  max_level := 0;

  -- open cursor for initial select

  open GET_DEPS(obj_list_schema, object_type, object_name, 1);

  while not done_sel loop

    fetch GET_DEPS
    into sel_level, sel_name, sel_type;

    if GET_DEPS%NOTFOUND then
      done_sel := TRUE;
    else
      -- process dependent object

      num_objs := num_objs + 1;

      obj_names(num_objs) := sel_name;
      obj_types(num_objs) := sel_type;
      obj_levels(num_objs) := sel_level;
      obj_processed(num_objs) := 0;

      if sel_level > max_level then
        max_level := sel_level;
      end if;

--    dbms_output.put_line('Add: '||sel_level||' '||sel_type||' '||sel_name);
    end if;

  end loop;
-- end loop to get first-level dependencies

  close GET_DEPS;
  done_sel := FALSE;

  while not done_sel loop
    any_added := FALSE;
    start_val:= 1;
    end_val:= num_objs;

    for i in start_val..end_val loop

      if (obj_processed(i) = 0) then

        open GET_DEPS(obj_list_schema, obj_types(i), obj_names(i),
                      obj_levels(i)+1);

        obj_processed(i) := 1;

        done_sel2:= FALSE;

        while not done_sel2 loop

          fetch GET_DEPS
          into sel_level, sel_name, sel_type;

          if GET_DEPS%NOTFOUND then
            done_sel2:= TRUE;
          else
            -- check to see if this object is already on the list

            add_object:= TRUE;

            for j in obj_names.first..obj_names.last loop
              if sel_name = obj_names(j) and
                 sel_type = obj_types(j) then
                add_object := FALSE;

-- If object is already on list, but listed at a lower level,
-- update object level to the current level.  This way we will list
-- all objects at the level corresponding to the deepest point in the
-- hierarchy at which they are required by another object.

                if sel_level > obj_levels(j) then
                  obj_levels(j) := sel_level;

                 if sel_level > max_level then
                   max_level := sel_level;
                 end if;

                end if;

                exit;
              end if;
            end loop;
-- end loop to see if object already in list

            if add_object then
              num_objs := num_objs + 1;

              obj_names(num_objs) := sel_name;
              obj_types(num_objs) := sel_type;
              obj_levels(num_objs) := sel_level;
              obj_processed(num_objs) := 0;

              if sel_level > max_level then
                max_level := sel_level;
              end if;
              any_added := TRUE;

--   dbms_output.put_line('Add: '||sel_level||' '||sel_type||' '||sel_name);

            end if;
-- end if added object

--  dbms_output.put_line('FYI: '||sel_level||' '||sel_type||' '||sel_name);
          end if;

        end loop;
-- end loop to fetch dependent objects for one object at this level

        close GET_DEPS;

      end if;
-- end if didn't already fetch dependent objs for this object
    end loop;
-- end loop to fetch dependent objects for this level

    if not any_added then
      done_sel := TRUE;
    end if;

  end loop;
-- end loop to get all dependent objects

-- Debugging output: list all dependent objects and their dependency levels

--  for i in 1..num_objs loop
--    dbms_output.put_line('Fin: '||obj_levels(i)||' '||
--      obj_types(i)||' '||obj_names(i));
--  end loop;

-- compile objects by dependency order in dest schema
-- go backwards on same dependency level in the hopes that this makes it less
-- likely we'll encounter the same deadlock the RDBMS did earlier

  for idx in reverse 1..max_level loop
    for i in reverse 1..num_objs loop
      if obj_levels(i) = idx then

        -- check to see if object exists in dest schema

        select object_name
        into dummy
        from sys.dba_objects
        where owner = recompile_schema
        and   object_name = obj_names(i)
        and   object_type = obj_types(i);

        if not SQL%NOTFOUND then

          -- build compilation statement

          if    obj_types(i) = 'PACKAGE' then
            statement := 'ALTER PACKAGE "'|| obj_names(i) ||
                         '" COMPILE SPECIFICATION';
          elsif obj_types(i) = 'PACKAGE BODY' then
            statement := 'ALTER PACKAGE "'|| obj_names(i) ||
                         '" COMPILE BODY';
          else
            statement := 'ALTER '|| obj_types(i) ||' "'||
                         obj_names(i) || '" COMPILE';
          end if;

          -- execute compilation statement

--          dbms_output.put_line('('||obj_levels(i)||') '||statement);

          begin
            ad_apps_private.do_apps_ddl(recompile_schema, statement);
          exception
            when others then
              ad_apps_private.error_buf := null;
          end;

        end if;
-- end if object exists in desc schema

      end if;
-- end if this object is at the current dependency level
    end loop;
-- end loop to compile invalid objecs for current level
  end loop;
-- end loop to compile invalid objects for all levels
  log_debug_message('End procedure recomp_referenced_objs ');

exception
  when others then
    ad_apps_private.error_buf := 'recomp_referenced_objs('||object_name||
      ','||obj_list_schema||','||recompile_schema||'): '||
      ad_apps_private.error_buf;
    log_debug_message('Exception - procedure recomp_referenced_objs ');
    raise;
end recomp_referenced_objs;


--
-- Other Misc procedures
--


procedure build_view_columns
           (from_schema     in         varchar2,
            view_name       in         varchar2,
            out_column_text out nocopy varchar2)
is
  counter               number := 0;
  column_text           varchar2(32760);
  cursor c1 is
    select column_name from sys.dba_tab_columns
    where table_name = build_view_columns.view_name
    and   owner = upper(build_view_columns.from_schema)
    order by column_id;
begin
  for c1rec in c1 loop
    if counter = 0 then
        column_text := '("' || c1rec.column_name;
    else
      column_text := column_text || '","' || c1rec.column_name;
    end if;
    counter := counter + 1;
  end loop;
  if counter > 0 then
    -- at least one column so add closing paren
    column_text := column_text || '")';
  end if;
  out_column_text := column_text;

exception
  when others then
  ad_apps_private.error_buf := 'ad_apps_private.build_view_columns('||
        from_schema||','||view_name||',out_column_text): '||
        ad_apps_private.error_buf;
  raise;
end build_view_columns;


procedure show_exception_list
is
  i number;
begin
  -- initialize dbms_output with large buffer size (200,000)
  --  default is 20,000   min is 2,000  max is 1,000,000

  dbms_output.enable(200000);

  -- load exception list, if not already loaded

  load_exception_list;

  -- display settings

  dbms_output.put_line('-');
  dbms_output.put_line(list_count ||' entries in exception list.');
  dbms_output.put_line('-');

  i := 1;
  while i <= list_count loop
    dbms_output.put_line('['||i||'] Product Short Name: '||
      prod_short_name(i));
    dbms_output.put_line('['||i||'] Base Schema Name  : '||
      base_name(i));
    dbms_output.put_line('['||i||'] Base Schema Type  : '||
      base_type(i));
    dbms_output.put_line('['||i||'] Exception Type    : '||
      exception_type(i));
    dbms_output.put_line('['||i||'] Trigger Obj Schema: '||
      trigger_obj_schema(i));
    dbms_output.put_line('['||i||'] Trigger Obj Type  : '||
      trigger_obj_type(i));
    dbms_output.put_line('['||i||'] Trigger Obj Name  : '||
      trigger_obj_name(i));
    dbms_output.put_line('['||i||'] APPS Schema Name  : '||
      apps_name(i));
    dbms_output.put_line('['||i||'] APPS Schema Type  : '||
      apps_type(i));
    dbms_output.put_line('['||i||'] Points to Schema  : '||
      points_to_schema(i));
    dbms_output.put_line('['||i||'] Points to Obj Name: '||
      points_to_name(i));
    dbms_output.put_line('['||i||']');
    i := i + 1;
  end loop;

  dbms_output.put_line('-');

exception
  when others then
    ad_apps_private.error_buf := 'show_exception_list: '||
      ad_apps_private.error_buf;
    raise;
end show_exception_list;


procedure load_exception_list
is
  i number;
begin
  --
  -- The "exception objects" list:
  --
  -- Lists objects in the base schema which are known to not be
  -- represented in the APPS schema by a synonym that points to
  -- the base object in some cases.
  --
  -- We determine whether the exception case should be activated by
  -- the presence of another object in either the base or APPS schema
  -- (called the "trigger object").
  --
  -- If the trigger object is present, we expect the synonym for the
  -- base object in the APPS schema to be replaced by a "customized object"
  -- with a specified name and type.  If the "customized object" is a
  -- synonym, we list the schema and name of the object it should point to.
  --
  -- No column in the exception objects list can be null except
  -- for the points_to_schema and points_to_name columns
  --
  -- Here is what each column means:
  --
  -- prod_short_name
  --
  --   The product short name for the product that owns the object in
  --   the base schema.
  --
  -- base_name
  --
  --   The name of the object in the base schema.
  --
  -- base_type
  --
  --   The type of the object in the base schema.
  --
  -- exception_type
  --
  --   Type of exception.  One of the following:
  --
  --     STANDARD_EXCEPTION
  --
  --       Possibly this is the only exception type we will ever support,
  --         but I wanted to leave it open for future expansion
  --
  --       Right now, only tables that were converted to MultiOrg in
  --         a patch will have any exceptions at all.
  --
  -- trigger_obj_schema
  --
  --   The schema in which the "trigger object" is located.
  --   If trigger object does not exist in trigger schema with the specified
  --     name and type, the exception logic will not execute.
  --   Valid values are: BASE and APPS
  --
  -- trigger_obj_type
  --
  --   The type of the "trigger object"
  --   The trigger object cannot be a synonym.
  --
  -- trigger_obj_name
  --
  --   The name of the "trigger object"
  --   The trigger object cannot have the same schema and name as the
  --     customized object in APPS, unless they are identical
  --     (same schema, type, and name).
  --
  -- apps_name
  --
  --   Name of the "customized object" in the APPS schema.
  --   Usually the same name as in the base schema.
  --
  -- apps_type
  --
  --   Type of the "customized object" in the APPS schema.
  --
  -- points_to_schema
  --
  --   This should be null unless customized object is a synonym.
  --   If object in the APPS schema is a synonym, this is the schema in
  --     which the object that the synonym should point to is located.
  --   Valid values are: BASE and APPS (and null, of course)
  --
  -- points_to_name
  --
  --   This should be null unless customized object is a synonym.
  --   If object in the APPS schema is a synonym, this is the name of
  --     the object that the synonym should point to.
  --

  --
  -- If counter variable is null, initialize list
  -- If counter variable is not null, assume list already initialized
  --

  if list_count is null then

    list_count := 0;

    -- Commented-out entries from Rel 11.0
    -- Keep them here so we can use them for reference

--    -- For PER_ASSIGNMENT_BUDGET_VALUES

--    list_count := list_count + 1;
--    prod_short_name(list_count)     := 'PER';
--    base_name(list_count)           := 'PER_ASSIGNMENT_BUDGET_VALUES';
--    base_type(list_count)           := 'TABLE';
--    exception_type(list_count)      := 'STANDARD_EXCEPTION';
--    trigger_obj_schema(list_count ) := 'APPS';
--    trigger_obj_type(list_count)    := 'VIEW';
--    trigger_obj_name(list_count)    := 'PER_ASG_BUDGET_VALS_INTNL';
--    apps_name(list_count)           := 'PER_ASSIGNMENT_BUDGET_VALUES';
--    apps_type(list_count)           := 'SYNONYM';
--    points_to_schema(list_count)    := 'APPS';
--    points_to_name(list_count)      := 'PER_ASG_BUDGET_VALS_INTNL';

--    -- For JG_ZZ_VEND_SITE_INFO

--    list_count := list_count + 1;
--    prod_short_name(list_count)     := 'SQLAP';
--    base_name(list_count)           := 'JG_ZZ_VEND_SITE_INFO';
--    base_type(list_count)           := 'TABLE';
--    exception_type(list_count)      := 'STANDARD_EXCEPTION';
--    trigger_obj_schema(list_count ) := 'APPS';
--    trigger_obj_type(list_count)    := 'VIEW';
--    trigger_obj_name(list_count)    := 'JG_ZZ_VEND_SITE_INFO_V';
--    apps_name(list_count)           := 'JG_ZZ_VEND_SITE_INFO';
--    apps_type(list_count)           := 'SYNONYM';
--    points_to_schema(list_count)    := 'APPS';
--    points_to_name(list_count)      := 'JG_ZZ_VEND_SITE_INFO_V';

    --
    -- Entries for Rel 11.5.x
    --

    -- For RA_CONTACTS

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'RA_CONTACTS';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'RA_HCONTACTS';
    apps_name(list_count)           := 'RA_CONTACTS';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'RA_HCONTACTS';

    -- For AR_CUST_PROF_CLASS_AMOUNTS

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'AR_CUST_PROF_CLASS_AMOUNTS';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'AR_HCUST_PROF_CLASS_AMOUNTS';
    apps_name(list_count)           := 'AR_CUST_PROF_CLASS_AMOUNTS';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'AR_HCUST_PROF_CLASS_AMOUNTS';

    -- For AR_CUSTOMER_PROFILES

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'AR_CUSTOMER_PROFILES';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'AR_HCUSTOMER_PROFILES';
    apps_name(list_count)           := 'AR_CUSTOMER_PROFILES';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'AR_HCUSTOMER_PROFILES';

    -- For RA_CONTACT_ROLES

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'RA_CONTACT_ROLES';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'RA_HCONTACT_ROLES';
    apps_name(list_count)           := 'RA_CONTACT_ROLES';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'RA_HCONTACT_ROLES';

    -- For AR_CUSTOMER_PROFILE_AMOUNTS

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'AR_CUSTOMER_PROFILE_AMOUNTS';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'AR_HCUSTOMER_PROFILE_AMOUNTS';
    apps_name(list_count)           := 'AR_CUSTOMER_PROFILE_AMOUNTS';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'AR_HCUSTOMER_PROFILE_AMOUNTS';

    -- For AR_CUSTOMER_PROFILE_CLASSES

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'AR_CUSTOMER_PROFILE_CLASSES';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'AR_HCUSTOMER_PROFILE_CLASSES';
    apps_name(list_count)           := 'AR_CUSTOMER_PROFILE_CLASSES';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'AR_HCUSTOMER_PROFILE_CLASSES';

   -- For CZ_LOCALIZED_TEXTS

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'CZ';
    base_name(list_count)           := 'CZ_INTL_TEXTS';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'CZ_LOCALIZED_TEXTS_VL';
    apps_name(list_count)           := 'CZ_INTL_TEXTS';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'CZ_LOCALIZED_TEXTS_VL';


    -- for HZ_CONTACT_RESTRICTIONS

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'HZ_CONTACT_RESTRICTIONS';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'HZ_CONTACT_RESTRICTIONS';
    apps_name(list_count)           := 'HZ_CONTACT_RESTRICTIONS';
    apps_type(list_count)           := 'VIEW';
    points_to_schema(list_count)    := null;
    points_to_name(list_count)      := null;


    -- for HZ_PARTY_RELATIONSHIPS

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'HZ_PARTY_RELATIONSHIPS';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'HZ_PARTY_RELATIONSHIPS';
    apps_name(list_count)           := 'HZ_PARTY_RELATIONSHIPS';
    apps_type(list_count)           := 'VIEW';
    points_to_schema(list_count)    := null;
    points_to_name(list_count)      := null;


    -- For JTF_TASK_ALL_ASSIGNMENTS

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'JTF';
    base_name(list_count)           := 'JTF_TASK_ASSIGNMENTS';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'JTF_TASK_ASSIGNMENTS_V';
    apps_name(list_count)           := 'JTF_TASK_ASSIGNMENTS';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'JTF_TASK_ASSIGNMENTS_V';


    -- For JTF_RS_SRP_TERRITORIES

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'JTF';
    base_name(list_count)           := 'JTF_RS_SRP_TERRITORIES';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'TABLE';
    trigger_obj_name(list_count)    := 'JTF_RS_SRP_TERRITORIES';
    apps_name(list_count)           := 'RA_SALESREP_TERRITORIES';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'RA_SALESREP_TERRITORIES';

    -- Bug 5877306 - stangutu - 13 Feb, 2007
    -- ADD EXCEPTION FOR SYNONYMS IN LOAD_EXCEPTION_LIST
    -- For OE_SYSTEM_PARAMETERS_ALL

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'ONT';
    base_name(list_count)           := 'OE_SYSTEM_PARAMETERS_ALL';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'OE_SYS_PARAMS_ALL_UPG';
    apps_name(list_count)           := 'OE_SYSTEM_PARAMETERS_ALL';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'OE_SYS_PARAMS_ALL_UPG';

    -- For RA_CUSTOMERS

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'RA_CUSTOMERS';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'RA_HCUSTOMERS';
    apps_name(list_count)           := 'RA_CUSTOMERS';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'RA_HCUSTOMERS';

    -- For RA_PHONES

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'RA_PHONES';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'RA_HPHONES';
    apps_name(list_count)           := 'RA_PHONES';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'RA_HPHONES';

    -- For RA_ADDRESSES_ALL

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'RA_ADDRESSES_ALL';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'RA_ADDRESSES_MORG';
    apps_name(list_count)           := 'RA_ADDRESSES_ALL';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'RA_ADDRESSES_MORG';

    -- For RA_CUSTOMER_RELATIONSHIPS_ALL

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'RA_CUSTOMER_RELATIONSHIPS_ALL';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'RA_CUSTOMER_RELATIONSHIPS_MORG';
    apps_name(list_count)           := 'RA_CUSTOMER_RELATIONSHIPS_ALL';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'RA_CUSTOMER_RELATIONSHIPS_MORG';

    -- For RA_SITE_USES_ALL

    list_count := list_count + 1;
    prod_short_name(list_count)     := 'AR';
    base_name(list_count)           := 'RA_SITE_USES_ALL';
    base_type(list_count)           := 'TABLE';
    exception_type(list_count)      := 'STANDARD_EXCEPTION';
    trigger_obj_schema(list_count ) := 'APPS';
    trigger_obj_type(list_count)    := 'VIEW';
    trigger_obj_name(list_count)    := 'RA_SITE_USES_MORG';
    apps_name(list_count)           := 'RA_SITE_USES_ALL';
    apps_type(list_count)           := 'SYNONYM';
    points_to_schema(list_count)    := 'APPS';
    points_to_name(list_count)      := 'RA_SITE_USES_MORG';

    --
    -- Validate list entries
    --

    for i in 1..list_count loop

      if    prod_short_name(i) is null
         or base_name(i) is null
         or base_type(i) is null
         or exception_type(i) is null
         or trigger_obj_schema(i) is null
         or trigger_obj_type(i) is null
         or trigger_obj_name(i) is null
         or apps_name(i) is null
         or apps_type(i) is null then
        raise_application_error(-20001,
          'Exception objects list row '||i||' has an invalid null value.');
      end if;
      -- end if any mandatory not-null field in the row was null

      if     trigger_obj_schema(i) <> 'BASE'
         and trigger_obj_schema(i) <> 'APPS' then
        raise_application_error(-20001,
          'Invalid trigger_obj_schema value: "'||trigger_obj_schema(i)||
          '". ('||i||')');
      end if;
      -- end if trigger object schema not valid

      if trigger_obj_type(i) = 'SYNONYM' then
        raise_application_error(-20001,
          'Trigger Object "'||trigger_obj_name(i)||'" cannot be a synonym'||
          '. ('||i||')');
      end if;
      -- end if trigger object is synonym

      if     apps_type(i) = 'SYNONYM'
         and (   points_to_schema(i) is null
              or points_to_name(i) is null) then
        raise_application_error(-20001,
          'Synonym "'||apps_name(i)||'" missing schema and/or object name'||
          '. ('||i||')');
      end if;
      -- end if customized object in APPS is a synonym, but either
      -- the schema or object name that the synonym is supposed to
      -- point to was not specified

      if     points_to_schema(i) <> 'BASE'
         and points_to_schema(i) <> 'APPS'
         and points_to_schema(i) is not null then
        raise_application_error(-20001,
          'Invalid points_to_schema value: "'||points_to_schema(i)||
          '". ('||i||')');
      end if;
      -- end if points_to_schema not valid

      if     trigger_obj_schema(i) = 'APPS'
         and trigger_obj_name(i) = apps_name(i)
         and trigger_obj_type(i) <> apps_type(i) then
        raise_application_error(-20001,
          'Trigger and customized objs have same name, but not same'||
          ' type. ('||i||')');
      end if;
      -- end check for trigger and customized object same name,
      -- but different types

    end loop;
    -- end loop to validate list entries

  end if;
  -- end if initialize list

exception
  when others then
    ad_apps_private.error_buf := 'load_exception_list: '||
      ad_apps_private.error_buf;
    raise;
end load_exception_list;


function matching_exception_object (base_schema_name in  varchar2,
                                    base_object_name in  varchar2,
                                    base_object_type in  varchar2,
                                    except_type      in  varchar2,
                                    apps_schema_name in  varchar2,
                                    found_cust_obj   out nocopy varchar2,
                                    cust_obj_correct out nocopy varchar2,
                                    index_to_object  out nocopy number)
return boolean
is
  i number;
  obj_index number;
  found_trigger_obj boolean;
  found_customized_object boolean;
  custom_object_correct boolean;
  matches_exactly boolean;
  any_obj_w_this_name boolean;
  type_of_existing_obj varchar2(100);
  trigger_is_base boolean;
  points_to_base boolean;
  whereami varchar2(100);
begin
  -- set default return value for 'out' variables

  whereami := null;

  found_cust_obj := null;
  cust_obj_correct := null;
  index_to_object := null;

  -- look for matching object on list

  found_trigger_obj := FALSE;
  found_customized_object := FALSE;
  custom_object_correct := FALSE;
  obj_index := 0;

  whereami := ' Before Loop ';

  if list_count is null then
    raise_application_error(-20001,
      'Exception Objects list has not been initialized');
  end if;

  for i in 1..list_count loop

    whereami := ' Loop Top ';

    if     base_name(i) = base_object_name
       and base_type(i) = base_object_type
       and exception_type(i) = except_type then

      -- decode data in row for this exception object

      whereami := ' A ';

      if    trigger_obj_schema(i) = 'BASE' then
        trigger_is_base := TRUE;
      elsif trigger_obj_schema(i) = 'APPS' then
        trigger_is_base := FALSE;
      else
        raise_application_error(-20001,
          'Invalid trigger_obj_schema value: "'||trigger_obj_schema(i)||
          '". ('||i||')');
      end if;
      -- end if trigger object schema is base schema

      whereami := ' B ';

      if points_to_schema(i) = 'BASE' then
        points_to_base := TRUE;
      elsif  points_to_schema(i) = 'APPS' then
        points_to_base := FALSE;
      elsif points_to_schema(i) is null then
        points_to_base := null;
      else
        raise_application_error(-20001,
          'Invalid points_to_schema value: "'||points_to_schema(i)||
          '". ('||i||')');
      end if;
      -- end if points_to schema is base schema

      -- check to see if trigger object exists

      whereami := ' C ';

      if trigger_is_base then
        ad_apps_private.exact_synonym_match(base_schema_name,
          trigger_obj_name(i), null, null,
          matches_exactly, any_obj_w_this_name, type_of_existing_obj);
      else
        ad_apps_private.exact_synonym_match(apps_schema_name,
          trigger_obj_name(i), null, null,
          matches_exactly, any_obj_w_this_name, type_of_existing_obj);
      end if;

      whereami := ' D ';

      if     any_obj_w_this_name
         and type_of_existing_obj = trigger_obj_type(i) then

        -- Trigger object exists.
        -- Say "this is an exception object" and set row number,
        --   then check to see if object is correct

 found_trigger_obj := TRUE;
 obj_index := i;

 -- Now check to see if the customized object exists and is correct

        whereami := ' E ';

 if apps_type(i) = 'SYNONYM' then
   if points_to_base then
     ad_apps_private.exact_synonym_match(apps_schema_name,apps_name(i),
       base_schema_name, points_to_name(i), matches_exactly,
       any_obj_w_this_name, type_of_existing_obj);
   else
     ad_apps_private.exact_synonym_match(apps_schema_name,apps_name(i),
       apps_schema_name, points_to_name(i), matches_exactly,
       any_obj_w_this_name, type_of_existing_obj);
   end if;
 else
   ad_apps_private.exact_synonym_match(apps_schema_name,apps_name(i),
     null, null, matches_exactly, any_obj_w_this_name,
     type_of_existing_obj);
 end if;

        whereami := ' F ';

        if     any_obj_w_this_name
           and type_of_existing_obj = apps_type(i) then

          found_customized_object := TRUE;

          -- decide if object was correct

          if apps_type(i) = 'SYNONYM' then
            if matches_exactly then
              custom_object_correct := TRUE;
            end if;
            -- end if synonym that matches exactly
          else
            -- If we got here for a non-synonym, we say the object is
            -- correct, as we really have no farther tests we can apply
            custom_object_correct := TRUE;
          end if;
          -- end if object in APPS is a synonym
        end if;
        -- end if exists object in APPS with same name
        -- and type as customized object

      end if;
      -- end if trigger object exists and is correct type

      -- break out of loop

      exit;

    end if;
    -- end if object name, object type, and exception type match
    -- the current object on the exception objects list
  end loop;
  -- end loop through exception objects list

  whereami := ' After Loop ';

  -- Set return values and exit

  if found_trigger_obj then

    if found_customized_object then
      found_cust_obj := 'TRUE';
    else
      found_cust_obj := 'FALSE';
    end if;
    -- end if found customized object

    if custom_object_correct then
      cust_obj_correct := 'TRUE';
    else
      cust_obj_correct := 'FALSE';
    end if;
    -- end if customized object correct

    index_to_object := obj_index;

    return(TRUE);
  else
    return(FALSE);
  end if;
  -- end if base object is active exception object

exception
  when others then
    ad_apps_private.error_buf := 'matching_exception_object('||
     base_schema_name||','||base_object_name||','||
     base_object_type||','||except_type||','||
     apps_schema_name||')<'||whereami||'> : '||
     ad_apps_private.error_buf;
    raise;
end matching_exception_object;


procedure initialize
           (aol_schema in varchar2)
is
  l_mrc_schema_name      varchar2(30);
  l_release_name         varchar2(30);
  l_statement            varchar2(500);
  l_first_space_in_rl    number;
  l_rel_comp_result      boolean;
  v_aol_schema          varchar2(30);

  cursor GET_MRC_SCHEMA_NAME is
    select oracle_username
    from fnd_oracle_userid
    where read_only_flag = 'K';
begin

-- Sql Injection Bug 25248691
  log_debug_message('Begin procedure initialize ');
  v_aol_schema := sys.dbms_assert.enquote_name(sys.dbms_assert.schema_name(aol_schema),FALSE);
  validate_aol_or_apps_schema(aol_schema);

  -- only perform the work if the variables are null, meaning that
  -- this routine has not been called before
  if ad_apps_private.is_mls is null
    or ad_apps_private.is_mc is null then
    -- get values for is_mc and is_mls
    declare
      x                 varchar2(30);
      y                 varchar2(30);
      c                 integer;
      rows_processed    integer;
      statement         varchar2(500);
    begin
      c := dbms_sql.open_cursor;
      statement := 'select nvl(min(multi_currency_flag),''N''), '||
                'nvl(min(multi_lingual_flag),''N'') '||
                'from '||v_aol_schema||'.fnd_product_groups';
      dbms_sql.parse(c, statement, dbms_sql.native);
      dbms_sql.define_column(c,1,x,30);
      dbms_sql.define_column(c,2,y,30);
      rows_processed := dbms_sql.execute(c);
      if dbms_sql.fetch_rows(c) > 0 then
        dbms_sql.column_value(c,1,x);
        dbms_sql.column_value(c,2,y);

      if x = 'Y' then
        -- Fixed bug 3258312 : Although MRC flag is at 'Y', someone
        -- may have dropped it or the release might be 11.5.10 or more.
        -- In both these cases, we have to set "ad_apps_private.is_mc"
        -- to 'FALSE'.

        -- get mrc schema name from FND_ORACLE_USERID

        open GET_MRC_SCHEMA_NAME;

        fetch GET_MRC_SCHEMA_NAME
        into l_mrc_schema_name;

        if GET_MRC_SCHEMA_NAME%NOTFOUND then

          -- MRC schema not registered in FND_ORACLE_USERID.
          -- Reset MRC flag to FALSE.

          close GET_MRC_SCHEMA_NAME;

          ad_apps_private.is_mc := FALSE;
        else

        -- MRC schema registered in FND_ORACLE_USERID, Check in DBA_USERS.

          close GET_MRC_SCHEMA_NAME;

          if ad_apps_private.check_if_schema_exists(l_mrc_schema_name) then

             -- Fixed bug 3353468 to resolve a runtime issue for
             -- 11.5.10. Check if the release>=11.5.10. if yes, MRC
             -- is not enabled

             -- Get the release name from FND_PRODUCT_GROUPS table.

             begin
                l_statement := 'select release_name from ' || v_aol_schema ||
                               '.fnd_product_groups';
                execute immediate l_statement into l_release_name;

             exception
                when others then
                  log_debug_message('Exception - procedure initialize ');
                  raise_application_error(-20000,
                  'Unable to get the RELEASE_NAME from FND_PRODUCT_GROUPS.');
             end;

             -- Trimming copied from FND_RELEASE.get_release()
             l_release_name      := rtrim(ltrim(l_release_name, ' '),' ');
             l_first_space_in_rl := instr(l_release_name,' ');
             if not l_first_space_in_rl = 0 then
                -- There is extra info, remove it
                l_release_name := substr(l_release_name, 1,
                                         l_first_space_in_rl - 1);
             end if;
             -- End of trimming.

             -- Now check for release information,
             -- set is_mc flag to TRUE if release is
             -- 11.5.9 or lower and FALSE if otherwise

             l_rel_comp_result :=  compare_releases(l_release_name ,
                                                    '11.5.9');

             if (l_rel_comp_result = TRUE) then
                ad_apps_private.is_mc := TRUE;
             else
                ad_apps_private.is_mc := FALSE;
             end if;

            else
              -- no MRC schema in DBA_USERS!
              ad_apps_private.is_mc := FALSE;
           end if;

          end if;
          -- end if block for MRC schema registered in FND_ORACLE_USERID

        else -- if not fnd_product_groups.multi_currency_flag

          ad_apps_private.is_mc := FALSE;

        end if;

        if y = 'Y' then
          ad_apps_private.is_mls := TRUE;
        else
          ad_apps_private.is_mls := FALSE;
        end if;
        dbms_sql.close_cursor(c);
      else
        log_debug_message('Exception - procedure initialize ');
        raise no_data_found;
      end if;
    exception
      when others then
        dbms_sql.close_cursor(c);
        ad_apps_private.error_buf := 'statement='||
                                     statement||':'||
                                     ad_apps_private.error_buf;
        log_debug_message('Exception - procedure initialize ');
        raise;
    end;

  end if;
  log_debug_message('End procedure initialize ');

exception
  when others then
    ad_apps_private.error_buf := 'initialize('||aol_schema||'): '||
                ad_apps_private.error_buf;
    log_debug_message('Exception - procedure initialize ');
    raise;
end initialize;


--
--
-- Function compare releases. Copied from AD_PATCH.compare_versions()
-- Compare passed release_levels. Returns TRUE if release_1 <= release_2.
--
--

function compare_releases(release_1 in varchar2,
                          release_2 in varchar2)
return boolean
is

  release_1_str  varchar2(132);
  release_2_str  varchar2(132);
  release_1_ver number;
  release_2_ver number;
  ret_status boolean           := TRUE;

begin

  release_1_str   := release_1 || '.';
  release_2_str  := release_2 || '.';

  while release_1_str is not null or release_2_str is not null loop

      -- Parse out a version from release_1
      if (release_1_str is null) then
         release_1_ver := 0;
      else
         release_1_ver := nvl(to_number(substr(release_1_str,1,
                             instr(release_1_str,'.')-1)),-1);
         release_1_str := substr(release_1_str,instr(release_1_str,'.')+1);
      end if;

      -- Next parse out a version from release_2

      if (release_2_str is null)
      then
        release_2_ver := 0;
      else
        release_2_ver := nvl(to_number(substr(release_2_str,1,
                             instr(release_2_str,'.')-1)),-1);
        release_2_str := substr(release_2_str,instr(release_2_str,'.')+1);
      end if;

      if (release_1_ver > release_2_ver)
      then
        ret_status := FALSE;
        exit;
      elsif (release_1_ver < release_2_ver)
      then
        exit;
      end if;

      -- Otherwise continue to loop.

  end loop;

  return(ret_status);

end compare_releases;

procedure is_object_actualised(
    p_object_name in varchar2,
    p_edition_name in varchar2,
    object_type in varchar2,
    schema_name in varchar2,
    p_status out nocopy number)
is
 l_cnt number;
 c integer;
 rows_processed number;
 c_statement varchar2(2000);
 l_edition_name varchar2(100);
begin
  p_status:=0;
  l_cnt:=0;
  l_edition_name:=p_edition_name;
  c := dbms_sql.open_cursor;
  log_message('inside is_object_actualised ..');

  c_statement:='select count(1) ' ||
               'from sys.dba_objects ' ||
               'where edition_name=:edition_name ' ||
               '  and owner=:schema_name ' ||
               '  and object_type=:object_type ' ||
               '  and object_name=:object_name';

  log_message('statement '||c_statement||'..');

  dbms_sql.parse(c => c, language_flag=>dbms_sql.native,
                 statement=> c_statement, edition => l_edition_name);
  log_message('done with parse');
  dbms_sql.bind_variable(c,'edition_name',p_edition_name,30);
  dbms_sql.bind_variable(c,'schema_name',schema_name,30);
  dbms_sql.bind_variable(c,'object_type',object_type,30);
  dbms_sql.bind_variable(c,'object_name',p_object_name,30);
--  dbms_output.put_line('statement : <'||c_statement||'>');
  log_message('done with binding');
  dbms_sql.define_column(c,1,l_cnt);
  rows_processed := dbms_sql.execute(c);
  log_message('done with execute');

  if dbms_sql.fetch_rows(c) > 0 then
    dbms_sql.column_value(c,1,l_cnt);
  end if;
  p_status:=l_cnt;
  dbms_sql.close_cursor(c);
  exception
    when others then
      dbms_sql.close_cursor(c);
      ad_apps_private.error_buf := 'c_statement='||
                                   c_statement||':'||
                                   ad_apps_private.error_buf;
      raise;
end is_object_actualised;

procedure do_apps_ddl_on_patch_edn(
     schema_name in varchar2,
     object_name in varchar2,
     object_type in varchar2,
     ddl_text in varchar2,
     abbrev_stmt in varchar2)
is

  object_already_exists exception;
  PRAGMA EXCEPTION_INIT(object_already_exists, -955);
  trigger_already_exists exception;
  PRAGMA EXCEPTION_INIT(trigger_already_exists, -4081);
  object_does_not_exist exception;
  PRAGMA EXCEPTION_INIT(object_does_not_exist, -4043);
  synonym_does_not_exist exception;
  PRAGMA EXCEPTION_INIT(synonym_does_not_exist, -1434);
  trigger_does_not_exist exception;
  PRAGMA EXCEPTION_INIT(trigger_does_not_exist, -4080);


--
--   schema_name The schema in which to run the statement
--   ddl_text  The SQL statement to run
--   abbrev_stmt Replace ddl_text with '$statement$' in stack trace?
--
  status           number;
  l_cur            integer;
  c                integer;
  statement        varchar2(500);
  l_patch_edition  varchar2(500);
  l_run_edition    varchar2(500);
  l_edition_name   varchar2(500);
  l_edition_type   varchar2(500);
  v_schema_name    varchar2(30);
begin

  log_debug_message('Begin procedure do_apps_ddl_on_patch_edn ');

-- Sql Injection Bug 25248691
  v_schema_name := sys.dbms_assert.enquote_name(schema_name,FALSE);

  -- Not edition enabled? Return.
  if ( is_edition_enabled = 'N')
  then
    return;
  end if;
  status:=0;
  log_message('before get_edition ..');
  l_patch_edition:=GET_EDITION('PATCH');
  log_message('patch_edition_name:<'||l_patch_edition||'>');
  if l_patch_edition is NULL then
    -- No Patch Edition. Do nothing, just return;
    return;
  end if;

  log_message('done get_edition ..');
  log_message('get_edition ..');
  l_run_edition:=GET_EDITION('RUN');
  log_message('run_edition_name:<'||l_run_edition||'>');

  execute immediate 'select ad_zd.get_edition_type from dual'into l_edition_type;

  if l_edition_type = 'PATCH' then
     --Action on patch edition performed by calling function. Return
     return;
  end if;
  if l_patch_edition = l_run_edition then
    return;
  end if;
  log_message('done get_edition ..');
  log_message('before creating the steatement');
  log_message(statement);

-- Sql Injection Bug 25248691
  v_schema_name := sys.dbms_assert.schema_name(schema_name);

   statement:='begin '||v_schema_name||'.apps_ddl.apps_ddl(:ddl_text); end;';

  log_message('statement <'||statement||'>');
  log_message('done creating the statement');
  l_cur := dbms_sql.open_cursor;
  log_message('calling parse ');
  dbms_sql.parse (
          c => l_cur, language_flag => dbms_sql.native,
          statement => statement, edition => l_patch_edition);
  log_message('done with parse ..');
  dbms_sql.bind_variable(l_cur,'ddl_text',ddl_text);
  log_message('done with bind ..');
  status := dbms_sql.execute(l_cur);
  log_message('done with execute ..');
  dbms_sql.close_cursor(l_cur);
  log_debug_message('End procedure do_apps_ddl_on_patch_edn ');
exception
  -- Fix to bug 13509922 - by asutrala 17-Dec-2011
  -- When there is an exception ORA-00955, while creating an
  -- object on patch edition, eat it. It is because the object
  -- is not actualized.
  when object_already_exists then
    if (dbms_sql.is_open(l_cur)) then
      dbms_sql.close_cursor(l_cur);
    end if;
  when trigger_already_exists then
    if (dbms_sql.is_open(l_cur)) then
      dbms_sql.close_cursor(l_cur);
    end if;

    ad_apps_private.error_buf := null;
  when trigger_does_not_exist then
    if (dbms_sql.is_open(l_cur)) then
      dbms_sql.close_cursor(l_cur);
    end if;
    if instr(upper(ddl_text),'DROP') = 0 then
	   raise;
	end if;
  when object_does_not_exist then
    if (dbms_sql.is_open(l_cur)) then
      dbms_sql.close_cursor(l_cur);
    end if;
    if instr(upper(ddl_text),'DROP') = 0 then
	   raise;
	end if;
  when synonym_does_not_exist then
    if (dbms_sql.is_open(l_cur)) then
      dbms_sql.close_cursor(l_cur);
    end if;
    if instr(upper(ddl_text),'DROP') = 0 then
	   raise;
	end if;

  when others then
    if (dbms_sql.is_open(l_cur)) then
      dbms_sql.close_cursor(l_cur);
    end if;

    if abbrev_stmt = 'FALSE' then
      ad_apps_private.error_buf := 'do_apps_ddl_on_patch_edn('||schema_name||
        ','||ddl_text|| '): '||ad_apps_private.error_buf;
      log_message('exception occurred...1');
      log_message('err:<'||ad_apps_private.error_buf||'>');
    else
      ad_apps_private.error_buf := 'do_apps_ddl_on_patch_edn('||schema_name||
        ', $statement$): '||ad_apps_private.error_buf;
      log_message('exception occurred...2');
      log_message('err:<'||ad_apps_private.error_buf||'>');
    end if;
    log_debug_message('Exception - procedure do_apps_ddl_on_patch_edn ');
    raise;
end do_apps_ddl_on_patch_edn;

procedure do_apps_array_ddl_on_patch_edn
            (schema_name in varchar2,
             lb          in integer,
             ub          in integer,
             add_newline in varchar2,
             object_name in varchar2,
             object_type in varchar2)
is

  object_already_exists exception;
  PRAGMA EXCEPTION_INIT(object_already_exists, -955);

  status                number;
  l_cur                 integer;
  c                     integer;
  statement             varchar2(500);
  l_patch_edition       varchar2(500);
  l_run_edition         varchar2(500);
  v_schema_name         varchar2(30);

begin

  log_debug_message('Begin procedure do_apps_array_ddl_on_patch_edn ');
  -- jwsmith Bug 28373908 - commented out call to is_edition_enabled. Already checked is_edition_enabled
  -- in routine do_apps_ddl_on_patch_edn. This is only called after that routine.
  -- Not edition enabled? Return.
  -- if ( is_edition_enabled = 'N')
  -- then
  --   return;
  -- end if;

  status:=0;
  l_patch_edition:=GET_EDITION('PATCH');
  if l_patch_edition is NULL then
    -- No Patch edition. Nothing to do.
    return;
  end if;

  l_run_edition:=GET_EDITION('RUN');
  if l_patch_edition = l_run_edition then
    return;
  end if;

  -- call the package procedure created earlier in schema username


  -- Sql Injection Bug 25248691
  v_schema_name := sys.dbms_assert.schema_name(schema_name);

    statement:='begin '||v_schema_name||'.apps_array_ddl.apps_array_ddl(:lb, :ub, :nlf); end;';

  l_cur := dbms_sql.open_cursor;
  dbms_sql.parse (
          c => l_cur, language_flag => dbms_sql.native,
          statement => statement, edition => l_patch_edition);
  dbms_sql.bind_variable(l_cur,'lb',lb);
  dbms_sql.bind_variable(l_cur,'ub',ub);
  dbms_sql.bind_variable(l_cur,'nlf',add_newline,500);
  status := dbms_sql.execute(l_cur);
  dbms_sql.close_cursor(l_cur);
  log_debug_message('End procedure do_apps_array_ddl_on_patch_edn ');

exception
  -- Fix to bug 13509922 - by asutrala 17-Dec-2011
  -- When there is an exception ORA-00955, while creating an
  -- object on patch edition, eat it. It is because the object
  -- is not actualized.
  when object_already_exists then
    ad_apps_private.error_buf := null;

  when others then
    if (dbms_sql.is_open(l_cur)) then
       dbms_sql.close_cursor(l_cur);
    end if;
    ad_apps_private.error_buf := 'do_apps_array_ddl_on_patch_edn('||schema_name||', '||
                lb||', '||ub||', '||add_newline||'): '||
                ad_apps_private.error_buf;
    log_debug_message('Exception - procedure do_apps_array_ddl_on_patch_edn ');
    raise;
end do_apps_array_ddl_on_patch_edn;


procedure DO_APPS_ARRAY_DDL_EDN
          (P_SCHEMA_NAME     in varchar2,
           DDL_TEXT          in varchar2,
           ROWCOUNT          in integer,
           P_EDITION_NAME    in varchar2 DEFAULT NULL) is
  L_STATEMENT             varchar2(500);
  L_CUR                   integer;
  L_STATUS                number;
  L_SCHEMA_NAME           varchar2(30);
begin
  log_debug_message('Start procedure do_apps_array_ddl_edn ');

  -- Sql Injection Bug 25248691
  l_schema_name := sys.dbms_assert.schema_name(p_schema_name);

  l_statement:=
    'begin '||l_schema_name||'.apps_array_ddl.glprogtext(:i) := :ddl_text; end;';

  l_cur := dbms_sql.open_cursor;
  dbms_sql.parse(c => l_cur, language_flag => dbms_sql.native,
                 statement => l_statement);
  dbms_sql.bind_variable(l_cur,'i',rowcount);
  dbms_sql.bind_variable(l_cur,'ddl_text',ddl_text);
  l_status := dbms_sql.execute(l_cur);
  dbms_sql.close_cursor(l_cur);

  if(p_edition_name is not null) then
    l_cur := dbms_sql.open_cursor;
    dbms_sql.parse (c => l_cur, language_flag => dbms_sql.native,
                    statement => l_statement, edition => p_edition_name);
    dbms_sql.bind_variable(l_cur,'i',rowcount);
    dbms_sql.bind_variable(l_cur,'ddl_text',ddl_text);
    l_status := dbms_sql.execute(l_cur);
    dbms_sql.close_cursor(l_cur);
  end if;

  log_debug_message('End procedure do_apps_array_ddl_edn ');
exception
  when others then
    ad_apps_private.error_buf := 'do_apps_array_ddl_edn('||l_schema_name||','||
      ddl_text||','||rowcount||'): '||ad_apps_private.error_buf;
    log_debug_message('Exception - procedure do_apps_array_ddl_edn ');
    raise;
end DO_APPS_ARRAY_DDL_EDN;



-- Bug25445659 - New routine to verify that the schema is a valid EBS
-- schema and that the package being called with that schema has
-- definers rights.

function validate_definer(in_schema in varchar2, in_package in varchar2) return varchar2
is
  rows_processed integer;
  v_in_schema varchar2(30);
begin
  log_debug_message('Begin procedure validate_definer ');

if upper(in_schema) <> 'CTXSYS'
then

  select count(1) into rows_processed
  from all_users u,
       all_procedures p,
       fnd_oracle_userid au
    where upper(in_schema) = u.username
    and u.username       = au.oracle_username
    and p.owner          = u.username
    and p.object_name    = upper(in_package)
    and p.authid         = 'DEFINER'
    and p.subprogram_id  = 0
    and p.object_type    = 'PACKAGE'
    and au.read_only_flag  not in('C','X');

  if rows_processed = 0 then
      raise_application_error(-20001,'Validation of parameters failed security');
  else return in_schema;
  end if;
elsif upper(in_schema) = 'CTXSYS' then
    return in_schema;
end if;
  log_debug_message('End procedure validate_definer ');
end validate_definer;

 -- Sql Injection Bug 25248691 new routine to check object_type

function validate_type(in_type in varchar2) return varchar2
is
begin
  log_debug_message('Begin procedure validate_type ');

 if (upper(in_type) = 'PROCEDURE' or
     upper(in_type) = 'PACKAGE' or
     upper(in_type) = 'PACKAGE BODY' or
     upper(in_type) = 'FUNCTION' or
     upper(in_type) = 'VIEW' or
     upper(in_type) = 'TRIGGER' or
     upper(in_type) = 'SYNONYM' or
     upper(in_type) = 'SEQUENCE' or
     upper(in_type) = 'TABLE' or
     upper(in_type) = 'JAVA CLASS') then
     return in_type;
   else
     raise_application_error(-20001,'Validation of parameters failed security');
   end if;
  log_debug_message('End procedure validate_type ');
end validate_type;

end ad_apps_private;
