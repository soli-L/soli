
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_MORG" AUTHID CURRENT_USER as
/* $Header: admorgs.pls 120.3.12020000.2 2013/02/20 09:21:24 rahulshr ship $ */
--
-- Declare table for Multi-Org table list
--
type TableNameType is table of varchar2(30)
  index by binary_integer;

type FlagValueType is table of varchar2(1)
  index by binary_integer;

table_list      TableNameType;
view_list       TableNameType;
appl_list       TableNameType;
seed_data       TableNameType;
conv_method     FlagValueType;
owner_list      TableNameType;

--
-- Procedure
--   load_table_list
--
-- Purpose
--   Loads the hard-coded list of partitioned tables into PL/SQL tables.
--   These PL/SQL tables should replace AK_PARTITIONED_TABLES in 10.7.
--
-- Arguments
--   X_load_table_stats   indicates whether the tables' row count should
--                        be used to determine the conversion method
--                        (default Y)
--
-- Example
--   none
--
procedure load_table_list(x_load_table_stats in varchar2);


procedure load_table_list;

--
-- Procedure
--   replicate_table_data
--
-- Purpose
--   Perform seed data replication from the template to the specified
--   org for the specified table
--
-- Arguments
--   X_table_name       Name of table
--   X_source_org_id    org_id of the source organization_id
--   X_target_org_id    org_id of the target organization_id
--
-- Example
--   none
--
-- Notes
--   1. Templates for partitioned seed data have a source org_id of -3113.
--   2. Templates for shared seed data have a source org_id of -3114.
--   3. Custom data have a source org_id of NULL.
--
procedure replicate_table_data
           (X_table_name in varchar2,
            X_source_org_id in number,
            X_target_org_id in number);

--
-- Procedure
--   replicate_table_data_bulk
--
-- Purpose
--   Perform seed data replication from the template to
--   a group of orgs for the specified table
--
--   This procedure was adapted from replicate_table_data()
--
--   This was written to improve performance as described
--   in bug 5409325.
--
--   Instead of calling replicate_table_data() for each
--   value fetched from the cursor, the cursor is combined
--   with the dynamic INSERT statement to process all orgs
--   in one shot per table.
--
-- Arguments
--   X_table_name       Name of table
--   X_source_org_id    org_id of the source organization_id
--
-- Example
--   none
--
-- Notes
--   1. Templates for partitioned seed data have a source org_id of -3113.
--   2. Templates for shared seed data have a source org_id of -3114.
--   3. Custom data have a source org_id of NULL.
--
procedure replicate_table_data_bulk
           (X_table_name in varchar2,
            X_source_org_id in number);

--
-- Procedure
--   replicate_seed_data
--
-- Purpose
--   Perform seed data replication from the template to the specified
--   org or all orgs for the specified table or all tables from one
--   product or all tables
--
-- Arguments
--   X_org_id           org_id of the target organization_id (NULL if all)
--   X_appl_short_name  application (NULL if all)
--   X_table_name       Name of table (NULL if all)
--
-- Example
--   none
--
-- Notes
--   none
--
procedure replicate_seed_data
           (X_org_id          in number,
            X_appl_short_name in varchar2,
            X_table_name      in varchar2);

procedure get_next_table
           (X_number      in out nocopy number,
            X_table_name  out    nocopy varchar2,
            X_conv_method out    nocopy varchar2);

procedure initialize(X_number out nocopy number);

procedure verify_seed_data
           (X_appl_short_name IN varchar2,
            X_table           IN varchar2,
            X_debug_level     IN number default 1);

procedure update_book_id
            (X_org_id          in number,
             X_table_name      in varchar2);

end ad_morg;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_MORG" as
/* $Header: admorgb.pls 120.25.12020000.8 2015/01/21 17:01:14 sstomar ship $ */

--
-- Private Cursors
--
-- This cursor had been combined with the dynamic INSERT statement
-- in replicate_table_data_bulk() to improve a performance issue
-- described in bug 5409325.  Any changes to this cursor would
-- require corresponding changes to the value of "in_line_view"
-- in replicate_table_data_bulk().
--
cursor org_cursor is
  select organization_id
  from   hr_operating_units
  ,      fnd_product_groups
  where  product_group_id = 1
  and    multi_org_flag = 'Y'
  union
  select to_number(null)
  from   dual
  where not exists (
         select null
         from   fnd_product_groups
         where  multi_org_flag = 'Y')
  order by 1;

MSG_LEVEL_WARN          CONSTANT BINARY_INTEGER := 1;
MSG_LEVEL_BASIC         CONSTANT BINARY_INTEGER := 2;
MSG_LEVEL_DATA          CONSTANT BINARY_INTEGER := 3;
MSG_LEVEL_SQL           CONSTANT BINARY_INTEGER := 4;


--
-- Private variables
--
g_prod_status     varchar2(10);
g_industry        varchar2(10);
g_prev_product    varchar2(30);
g_oracle_schema    varchar2(30);
g_load_table_data boolean := FALSE;
g_load_table_stats varchar2(1);
g_debug_level     number := 0;

function is_edition_enabled(p_username varchar2 default null)
return varchar2
is
 l_enabled varchar2(1);
begin
 if p_username is null
 then
    select u.editions_enabled
    into   l_enabled
    from   fnd_oracle_userid f,
           dba_users u
    where  f.read_only_flag='U'
    and    u.username=f.oracle_username;
 else
    select editions_enabled
    into   l_enabled
    from   dba_users
    where  username=p_username;
 end if;
 return l_enabled;
end;

--
-- Private Functions and Procedures
--

--
-- Function
--   check_object
--
-- Purpose
--   Checks if the object exists in the database
--
-- Arguments
--   X_table_name       name of partitioned table
--   X_appl_short_name  application owner of table
--
-- Returns
--   TRUE if the object exists, FALSE if it does not
--
-- Example
--   none
--
-- Notes
--   none
--
function check_table
          (X_table_name       in         varchar2,
           X_appl_short_name  in         varchar2,
           O_table_owner      out nocopy varchar2) return boolean
is
  l_dummy  varchar2(30);
  l_edition_enabled varchar2(1);
  l_appsname varchar2(30);
begin

  if (is_edition_enabled = 'N')
  then
     select 'table exists',t.owner
     into   l_dummy,
            O_table_owner
     from   user_synonyms s,
            dba_tables    t
     where  s.synonym_name = upper(X_table_name)
       and  t.owner        = s.table_owner
       and  t.table_name   = s.table_name
       and  rownum = 1;
   else
     select 'table exists',t.owner
     into   l_dummy,
            O_table_owner
     from   user_synonyms s,
            dba_editioning_views t
     where  s.synonym_name = upper(X_table_name)
       and  t.owner        = s.table_owner
       and  t.view_name    = s.table_name
       and  rownum = 1;
   end if;

   return(TRUE);

exception
   when NO_DATA_FOUND then
     return(FALSE);
end;

--
-- Procedure
--   add_list
--
-- Purpose
--   Add a partitioned table to the register
--
-- Arguments
--   X_table_name       name of partitioned table
--   X_view_name        name of corresponding partitioned view
--   X_appl_short_name  application owner of table
--   X_seed_data_flag   table containing seed data?
--   X_chk_licensed     add to list only if the product is licensed (default N)
--   X_chk_industry     add to list only if specific industry (default NULL)
--   X_alt_short_name   alternative application owner of table (default NULL)
--                      (see notes)
--   X_conv_method      table conversion method (S or P, default NULL)
--
-- Example
--   none
--
-- Notes
--   Some tables (mostly localization tables) are not created in their
--   own schema but rather in some other product's schema. For instance,
--   JG_ZZ_INT_INV_LINES_ALL is created in the AR schema and not in JG.
--   For such tables, an additional application short name needs to be
--   specified. The first application name will be stored in the
--   application names list while the second application name will be
--   used to determine the name of the oracle schema that owns the table.
--
--   Determining the name of the oracle schema that corresponds to an
--   apps product is a bit trickier than expected. This is because some
--   apps instances once implemented the Multiple Set Of Books
--   Architecture. Under the MSOBA, some products define a separate
--   oracle schema for each implemented set of books.
--
--   For example, an instance may define 3 payables schemas named
--   'AP', 'AP1' and 'AP2' in order to support 3 sets of books.
--   At some point the instance was converted to a single schema instance
--   which eliminated two of the Payables schemas. The remaining schema
--   however is not necessarily 'AP', but may as well be 'AP1' or 'AP2'.
--
--   Performance issue:
--     The check_exists parameter has been removed from the parameter
--     list because we always want to verify the existance of the table
--     before we try to load the parameters into the respective tables.
--     Testing indicates that at most there is a half-second difference
--     between checking all of the tables for existance and only checking
--     some of the tables for existance when loading the entire list.
--     (Yes, we mean the entire list, not each entry.)
--
procedure add_list
           (X_table_name      in varchar2,
            X_view_name       in varchar2,
            X_appl_short_name in varchar2,
            X_seed_data_flag  in varchar2,
            X_chk_licensed    in varchar2,
            X_chk_industry    in varchar2 default null,
            X_alt_short_name  in varchar2 default null,
            X_conv_method     in varchar2 default null)
is
  l_status          varchar2(30);
  l_industry        varchar2(30);
  l_oracle_schema   varchar2(30) := null;
  l_ign             boolean;
  l_conv_method     varchar2(1);
  l_num_rows        number;
  l_table_owner     dba_tables.owner%type;
begin

  l_conv_method     := 'S';
   --
   -- First, we need to retrieve the product status, industry and name of
   -- the oracle schema associated to the specified application.
   --

   if ( x_appl_short_name <> g_prev_product) then

      -- We need to call fnd_installation.get_app_info() every time we
      -- are passed a new application short name.

      -- The x_appl_short_name <> g_prev_product comparison evaluates to
      -- false when x_appl_short_name is null.

      l_ign := fnd_installation.get_app_info(x_appl_short_name, l_status,
                                             l_industry, l_oracle_schema);

      -- Cache the values so we can use them the next time add_list() is
      -- called (if the same application name is passed):

      g_prod_status   := l_status;
      g_industry      := l_industry;
      g_oracle_schema := l_oracle_schema;

      g_prev_product  := x_appl_short_name;

   else
      -- The value of x_appl_short_name is the same as last time
      -- add_list() was called, so we can use the cached values:

      l_status        := g_prod_status;
      l_industry      := g_industry;
      l_oracle_schema := g_oracle_schema;

   end if;


  --
  -- Localization tables are created only when they are licenced. Ignore
  -- these tables where localizations are not installed.
  --
  if (X_chk_licensed = 'Y' or X_chk_industry is not null)
  then
      if (X_chk_licensed = 'Y' and l_status <> 'I') then
          return;
      end if;

      if (X_chk_industry is not null and
          l_industry <> upper(X_chk_industry))
      then
        return;
      end if;
  end if;

  -- We need to put the check in for the last entry in the table and then
  -- go ahead and process it. Other routines may use this as a table terminator.
  -- This should be changed in the next revision so that we can use a more
  -- elegant solution.

    -- check_table() doesn't use the x_appl_short_name parameter
  if ( (X_table_name is not null) and
       (NOT check_table(X_table_name, X_appl_short_name, l_table_owner) ) )
  then
    return;
  end if;

  -- If the x_alt_short_name parameter is not null, we're dealing with
  -- a licensed localization table. This is an exceptional and hopefully
  -- rare case. We cannot use the schema value associated with
  -- x_appl_short_schema (see notes section) but we must call
  -- fnd_installation.get_app_info() once again:

  if (g_load_table_stats = 'Y' and x_alt_short_name is not null) then

     l_ign := fnd_installation.get_app_info(x_alt_short_name, l_status,
                                            l_industry, l_oracle_schema);

     -- We won't cache anything this time because it won't buy us much.

     -- Note: after this point, l_status and l_industry correspond to
     -- l_alt_short_name, not l_appl_short_name! Use them with care, or
     -- better yet, don't use them at all!

  end if;

  --
  -- We now need to determine how the table will be converted. If the
  -- caller has specified a valid conversion method, we'll accept it,
  -- otherwise we'll look at the table's statistics. If the table
  -- contains more than 1 million rows we'll convert it in parallel;
  -- otherwise serially. Retrieving the table's statistics is an
  -- expensive operation which we want to avoid if not needed. Hence,
  -- when the g_load_table_stats flag is not 'Y', we'll just set the
  -- conversion method to 'S'.
  --

  if ((x_table_name is null) or (x_conv_method in ('S', 'P'))) then
     l_conv_method := x_conv_method;
  else

     l_conv_method := 'S'; -- default conversion method is 'S'

     if (g_load_table_stats = 'Y') then

        begin
           select num_rows
             into l_num_rows
             from dba_tables
            where table_name = x_table_name
              and owner= l_table_owner;
        exception
           when no_data_found then
             raise_application_error(-20001,
                 'Unable to get statistics for table : '||
                 l_oracle_schema||'.'||x_table_name);
        end;

        if (l_num_rows > 1000000) then
           l_conv_method := 'P';
        end if;

     end if;

  end if;

  table_list (table_list.count+1)  := X_table_name;
  owner_list (owner_list.count+1)  := l_oracle_schema;
  view_list  (view_list.count+1)   := X_view_name;
  appl_list  (appl_list.count+1)   := X_appl_short_name;
  seed_data  (seed_data.count+1)   := X_seed_data_flag;
  conv_method(conv_method.count+1) := l_conv_method;

end;

--
-- Procedure
--   create_sequences
--
-- Purpose
--   Perform seed data replication from the template to the specified
--   org for the specified table
--
-- Arguments
--   X_sequence_name    name of sequence to create
--   X_seq_start_num    sequence's starting number
--   X_appl_short_name  Application owner of sequence
--
-- Example
--   none
--
-- Notes
--   none
--
procedure create_sequence
           (X_sequence_name   in varchar2,
            X_seq_start_num   in number,
            X_appl_short_name in varchar2)
is
  statement       varchar2(2000);
  sequence_exists exception;
  inst_stat varchar2(30);
  ind       varchar2(30);
  schema_nm varchar2(30);

  pragma exception_init(sequence_exists, -955);

begin
  -- Get the schema name to use for the ad_ddl call below. Note that this
  -- used to be passed as parameter 1, but due to GSCC requirements, it is
  -- deemed a much safer way to do it this way instead.
  begin
    if (NOT (FND_INSTALLATION.get_app_info('FND', inst_stat, ind, schema_nm)))
    then
      -- Check the status from the call.
      if (inst_stat <> 'I') then
        raise_application_error(-20001,'FND_INSTALLATION.GET_APP_INFO()'||
                                ' installation status of FND = '||inst_stat||
                                ' '|| X_sequence_name||' not created.');
      end if;
    end if;
    exception
     when others then
       raise_application_error(-20000, sqlerrm || ' during '||
                               'FND_INSTALLATION.GET_APP_INFO()');
  end;


  statement := 'create sequence ' || X_sequence_name ||
               ' start with ' || to_char(X_seq_start_num) ||
               ' increment by 1';

  ad_ddl.do_ddl(schema_nm, X_appl_short_name,
                ad_ddl.create_sequence, statement, X_sequence_name);
exception
    when sequence_exists then
      null;
    when others then
      raise_application_error(-20002,sqlerrm||' in CREATE_SEQUENCE for '||
                              X_sequence_name);
end;


--
-- Procedure
--   replicate_table_data
--
-- Purpose
--   Perform seed data replication from the template to the specified
--   org for the specified table
--
-- Arguments
--   X_table_name       Name of table
--   X_source_org_id    org_id of the source organization_id
--   X_target_org_id    org_id of the target organization_id
--
-- Example
--   none
--
-- Notes
--   1. Templates for partitioned seed data have a source org_id of -3113.
--   2. Templates for shared seed data have a source org_id of -3114.
--   3. Custom data have a source org_id of NULL.
--
procedure replicate_table_data
           (X_table_name    in varchar2,
            X_source_org_id in number,
            X_target_org_id in number)
is
  where_clause     varchar2(32767);
  column_list      varchar2(32767);
  statement        varchar2(32767);
  c                integer;

  table_not_found  exception;

-- No need to modify the below cursor to use ev.
-- because we are not checking here with us.table_name
  cursor c_column is
    select col.column_name, col.column_id
    from  (select table_owner, table_name
           from user_synonyms
           where synonym_name = x_table_name)
         syn,
         dba_tab_columns col
    where col.owner = syn.table_owner
      and col.table_name = syn.table_name
      and col.column_name <> 'ORG_ID'
      and col.data_type not like 'LONG%'
    order by col.column_id;

  cursor c_primary_key is
    select c.column_name, pkc.primary_key_sequence
    from   fnd_columns             c
    ,      fnd_primary_key_columns pkc
    ,      fnd_primary_keys        pk
    ,      fnd_tables              t
    where  t.application_id   >= 0
    and    t.table_name        = X_table_name
    and    pk.application_id   = t.application_id
    and    pk.table_id         = t.table_id
    and    pk.primary_key_type = 'D'
    and    pkc.application_id  = pk.application_id
    and    pkc.table_id        = pk.table_id
    and    pkc.primary_key_id  = pk.primary_key_id
    and    c.application_id    = pkc.application_id
    and    c.table_id          = pkc.table_id
    and    c.column_id         = pkc.column_id
    and    c.column_name      <> 'ORG_ID'
    order by pkc.primary_key_sequence;

begin

  if (X_source_org_id is null and X_target_org_id is null) then
    return;
  end if;

  column_list := NULL;
  c := 0;
  for c_col in c_column loop
    c := c + 1;
    column_list := column_list || c_col.column_name || ', ';
  end loop;
  if c = 0 then
    raise table_not_found;
  end if;

  where_clause := ' WHERE NVL(ORG_ID, -99) = nvl(:X_source_org_id, -99)' ||
                  ' AND NOT (ORG_ID = -3114 AND :X_target_org_id IS NOT NULL)' ||
                  ' AND NOT EXISTS (' ||
                  ' SELECT NULL FROM ' || X_table_name ||
                  ' WHERE NVL(ORG_ID, -99) = NVL(:X_target_org_id, -99)';
  for c_pk in c_primary_key loop
    where_clause := where_clause || ' AND ' ||
                c_pk.column_name || ' = A.' || c_pk.column_name;
  end loop;
  where_clause := where_clause || ')';

  statement := 'INSERT INTO ' || X_table_name || ' (' ||
               column_list || 'ORG_ID) SELECT ' ||
               column_list || ':X_target_org_id FROM ' || X_table_name || ' A' ||
               where_clause;

  EXECUTE IMMEDIATE statement USING X_target_org_id, X_source_org_id,
          X_target_org_id, X_target_org_id;

exception
  when table_not_found then
    null;
  when others then
    raise_application_error(-20000, sqlerrm || ':ad_morg.replicate_table_data(' ||
         X_table_name || ',' || X_target_org_id || '):' || statement);

end replicate_table_data;


--
-- Procedure
--   replicate_table_data_bulk
--
-- Purpose
--   Perform seed data replication from the template to
--   a group of orgs for the specified table
--
--   This procedure was adapted from replicate_table_data()
--
--   This was written to improve performance as described
--   in bug 5409325.
--
--   Instead of calling replicate_table_data() for each
--   value fetched from the cursor, the cursor is combined
--   with the dynamic INSERT statement to process all orgs
--   in one shot per table.
--
-- Arguments
--   X_table_name       Name of table
--   X_source_org_id    org_id of the source organization_id
--
-- Example
--   none
--
-- Notes
--   1. Templates for partitioned seed data have a source org_id of -3113.
--   2. Templates for shared seed data have a source org_id of -3114.
--   3. Custom data have a source org_id of NULL.
--
procedure replicate_table_data_bulk
           (X_table_name    in varchar2,
            X_source_org_id in number)
is
  where_clause     varchar2(32767);
  in_line_view     varchar2(32767);
  column_list      varchar2(32767);
  statement        varchar2(32767);
  c                integer;

  table_not_found  exception;

-- No need to modify the below cursor to use ev.
-- because we are not checking here with us.table_name
  cursor c_column is
    select distinct col.column_name, col.column_id
    from  user_synonyms syn, dba_tab_columns col
    where syn.synonym_name = X_table_name
    and col.owner      =  syn.table_owner
    and col.table_name = syn.table_name
    and col.column_name <>'ORG_ID'
    and col.data_type not in ('LONG', 'LONG RAW')
    order by col.column_id;

  cursor c_primary_key is
    select c.column_name, pkc.primary_key_sequence
    from   fnd_columns             c
    ,      fnd_primary_key_columns pkc
    ,      fnd_primary_keys        pk
    ,      fnd_tables              t
    where  t.application_id   >= 0
    and    t.table_name        = X_table_name
    and    pk.application_id   = t.application_id
    and    pk.table_id         = t.table_id
    and    pk.primary_key_type = 'D'
    and    pkc.application_id  = pk.application_id
    and    pkc.table_id        = pk.table_id
    and    pkc.primary_key_id  = pk.primary_key_id
    and    c.application_id    = pkc.application_id
    and    c.table_id          = pkc.table_id
    and    c.column_id         = pkc.column_id
    and    c.column_name      <> 'ORG_ID'
    order by pkc.primary_key_sequence;

begin

  if (X_source_org_id is null) then
    return;
  end if;

  column_list := NULL;
  c := 0;
  for c_col in c_column loop
    c := c + 1;
    column_list := column_list || c_col.column_name || ', ';
  end loop;
  if c = 0 then
    raise table_not_found;
  end if;

  in_line_view := ' (SELECT /*+ no_merge */ ORGANIZATION_ID FROM' ||
                  ' fnd_product_groups, hr_operating_units' ||
                  ' WHERE product_group_id = 1' ||
                  ' AND multi_org_flag = ''Y'' UNION' ||
                  ' SELECT TO_NUMBER(NULL) FROM DUAL WHERE NOT EXISTS' ||
                  ' (SELECT NULL FROM fnd_product_groups WHERE' ||
                  ' multi_org_flag = ''Y'')) V';

  statement:= 'MERGE INTO ' ||X_table_name||' targ'||
              ' USING (SELECT '||column_list||' V.ORGANIZATION_ID '||
              ' FROM '||X_table_name||' A, '||in_line_view||
              ' where  NVL(A.ORG_ID, -99) = nvl(:X_source_org_id, -99) '||
              ' AND NOT (ORG_ID = -3114 AND V.ORGANIZATION_ID IS NOT NULL) '||
              ' )src on '||
              ' (NVL(src.ORGANIZATION_ID,-99) = NVL(targ.ORG_ID, -99) ';

  for c_pk in c_primary_key loop
     statement:= statement || ' AND src.'||c_pk.column_name||
                              ' = targ.'||c_pk.column_name;
  end loop;

  statement:= statement || ' ) WHEN NOT MATCHED THEN INSERT ( '||column_list||
                         ' ORG_ID) VALUES(';

  FOR c_col in c_column loop
      statement:= statement ||' src.'||c_col.column_name||' ,';
  end loop;

  statement:= statement || ' src.ORGANIZATION_ID)';

  EXECUTE IMMEDIATE statement USING X_source_org_id;

exception
  when table_not_found then
    null;
  when others then
    raise_application_error(-20000, sqlerrm ||
         ':ad_morg.replicate_table_data_bulk(' ||
         X_table_name || ',' || X_source_org_id || '):' || statement);

end replicate_table_data_bulk;

procedure replicate_ar_org_data
           (X_org_id in number)
is
begin
  --
  -- Now create seeded batch source sequences
  --
  if X_org_id is not null then
    create_sequence('RA_TRX_NUMBER_N1_'||to_char(X_org_id)||'_S', 10000, 'AR');
    create_sequence('RA_TRX_NUMBER_8_'||to_char(X_org_id)||'_S',  10000, 'AR');
    create_sequence('RA_TRX_NUMBER_11_'||to_char(X_org_id)||'_S', 200000, 'AR');
    create_sequence('RA_TRX_NUMBER_12_'||to_char(X_org_id)||'_S', 100000, 'AR');
    create_sequence('RA_TRX_NUMBER_13_'||to_char(X_org_id)||'_S', 10000, 'AR');
    create_sequence('RA_TRX_NUMBER_22_'||to_char(X_org_id)||'_S', 10000, 'AR');
    create_sequence('RA_TRX_NUMBER_24_'||to_char(X_org_id)||'_S', 10000, 'AR');
    create_sequence('RA_TRX_NUMBER_25_'||to_char(X_org_id)||'_S', 10000, 'AR');
    create_sequence('RA_TRX_NUMBER_26_'||to_char(X_org_id)||'_S', 10000, 'AR');
    create_sequence('RA_TRX_NUMBER_27_'||to_char(X_org_id)||'_S', 10000, 'AR');
    create_sequence('RA_TRX_NUMBER_29_'||to_char(X_org_id)||'_S', 10000, 'AR');
    create_sequence('RA_TRX_NUMBER_30_'||to_char(X_org_id)||'_S', 10000, 'AR');
  end if;

exception
  when others then
    raise;
end replicate_ar_org_data;

--
-- Public Functions and Procedures
--

--
-- Procedure
--   replicate_seed_data
--
-- Purpose
--   Perform seed data replication from the template to the specified
--   org or all orgs for the specified table or all tables from one
--   product or all tables
--
-- Arguments
--   X_org_id           org_id of the target organization_id (NULL if all)
--   X_appl_short_name  application (NULL if all)
--   X_table_name       Name of table (NULL if all)
--
-- Example
--   none
--
-- Notes
--   1. Template rows have a special org_id of -3113.
--
procedure replicate_seed_data
           (X_org_id          in number,
            X_appl_short_name in varchar2,
            x_table_name      in varchar2)
is
  is_org   varchar2(1);
  i        number;
begin
  --
  -- If org_id is not null and multi_org_flag is not 'Y', exit
  -- use min() to return a value even if no rows (fresh install case)
  --
  select nvl(min(multi_org_flag),'N')
  into   is_org
  from   fnd_product_groups
  where  product_group_id = 1;

  if X_org_id is not null and is_org <> 'Y' then
    return;
  end if;
  --
  -- Check to see if single table replication
  --
  if X_table_name is not null then
    --
    -- Check to see if single org replication
    --
    if X_org_id is not null then
      replicate_table_data(X_table_name, -3113, X_org_id);
      update_book_id(X_org_id, X_table_name);
    else
      replicate_table_data(X_table_name, -3114, null);
      replicate_table_data_bulk(X_table_name, -3113);
      commit;
    end if;
  else
    load_table_list('N');
    --
    -- Check to see if single org replication
    --
    if X_org_id is not null then
      i := 1;
      while table_list(i) is not null loop
        if  ((appl_list(i) = X_appl_short_name or X_appl_short_name is null)
        and seed_data(i) = 'Y') then
          replicate_table_data(table_list(i), -3113, X_org_id);
	  update_book_id(X_org_id, table_list(i));
        end if;
        -- increment counter to go to next table/view
        i := i + 1;
      end loop;
      if (X_appl_short_name is null or X_appl_short_name = 'AR') then
        replicate_ar_org_data(X_org_id);
      end if;
    else
      i := 1;
      while table_list(i) is not null loop
        if  ((appl_list(i) = X_appl_short_name or X_appl_short_name is null)
        and seed_data(i) = 'Y') then
          replicate_table_data_bulk(table_list(i), -3113);
          replicate_table_data(table_list(i), -3114, null);
          commit;
        end if;
        -- increment counter to go to next table/view
        i := i + 1;
      end loop;
      if (X_appl_short_name is null or X_appl_short_name = 'AR') then
        for c_org in org_cursor loop
          replicate_ar_org_data(c_org.organization_id);
        end loop;
        commit;
      end if;
    end if;
  end if;
  --
  -- Comments out following codes based on request from table owner
  -- Bug 4557238
  --
  -- Exception cases: we need to unstamp certain rows
  -- This is added as a cleanup step.
  --
  -- update ar_payment_schedules_all
  -- set org_id = null
  -- where payment_schedule_id < 0;

exception
  when others then
    raise;
end replicate_seed_data;


--
-- Procedure
--   load_table_list
--
-- Purpose
--   Loads the hard-coded list of partitioned tables into PL/SQL tables.
--   These PL/SQL tables should replace AK_PARTITIONED_TABLES in 10.7.
--
-- Arguments
--   X_load_table_stats   indicates whether the tables' row count should
--                        be used to determine the conversion method
--                        (default Y)
--
-- Example
--   none
--
procedure load_table_list
           (x_load_table_stats in varchar2)
is
begin

  g_load_table_stats := x_load_table_stats;

  -- If someone calls this routine multiple times within the same database
  -- session, we need to make sure that we don't add to the table entries.
  -- So, truncate all of the tables before we add to them.
  if (table_list.count > 0)
  then
    table_list.DELETE;
    owner_list.DELETE;
    view_list.DELETE;
    appl_list.DELETE;
    seed_data.DELETE;
    conv_method.DELETE;
  end if;
  --
  -- get licence status for localization products
  --

  /*
  -- IMPORTANT: performance is best when the add_list() calls for the
  -- same application are grouped together!
  */

  add_list('AP_1096_DATA_ALL'               , 'AP_1096_DATA'                   , 'SQLAP' ,'Y','N');
  add_list('AP_1099_TAPE_DATA_ALL'          , 'AP_1099_TAPE_DATA'              , 'SQLAP' ,'N','N');
  add_list('AP_ACCOUNTING_EVENTS_ALL'       , 'AP_ACCOUNTING_EVENTS'           , 'SQLAP' ,'N','N');
  add_list('AP_AE_HEADERS_ALL'              , 'AP_AE_HEADERS'                  , 'SQLAP' ,'N','N');
  add_list('AP_AE_LINES_ALL'                , 'AP_AE_LINES'                    , 'SQLAP' ,'N','N');
  add_list('AP_AUD_RULE_ASSIGNMENTS_ALL'    , 'AP_AUD_RULE_ASSIGNMENTS'        , 'SQLAP' ,'N','N');
  add_list('AP_AWT_BUCKETS_ALL'             , 'AP_AWT_BUCKETS'                 , 'SQLAP' ,'N','N');
  add_list('AP_AWT_GROUP_TAXES_ALL'         , 'AP_AWT_GROUP_TAXES'             , 'SQLAP' ,'N','N');
  add_list('AP_AWT_TAX_RATES_ALL'           , 'AP_AWT_TAX_RATES'               , 'SQLAP' ,'N','N');
  add_list('AP_AWT_TEMP_DISTRIBUTIONS_ALL'  , 'AP_AWT_TEMP_DISTRIBUTIONS'      , 'SQLAP' ,'N','N');
  add_list('AP_BANK_ACCOUNTS_ALL'           , 'AP_BANK_ACCOUNTS'               , 'SQLAP' ,'N','N');
  add_list('AP_BANK_ACCOUNT_USES_ALL'       , 'AP_BANK_ACCOUNT_USES'           , 'SQLAP' ,'N','N');
  add_list('AP_BATCHES_ALL'                 , 'AP_BATCHES'                     , 'SQLAP' ,'N','N');
  add_list('AP_CARDS_ALL'                   , 'AP_CARDS'                       , 'SQLAP' ,'N','N');
  add_list('AP_CARD_CODES_ALL'              , 'AP_CARD_CODES'                  , 'SQLAP' ,'N','N');
  add_list('AP_CARD_CODE_SETS_ALL'          , 'AP_CARD_CODE_SETS'              , 'SQLAP' ,'N','N');
  add_list('AP_CARD_GL_ACCTS_ALL'           , 'AP_CARD_GL_ACCTS'               , 'SQLAP' ,'N','N');
  add_list('AP_CARD_GL_SETS_ALL'            , 'AP_CARD_GL_SETS'                , 'SQLAP' ,'N','N');
  add_list('AP_CARD_PROFILES_ALL'           , 'AP_CARD_PROFILES'               , 'SQLAP' ,'N','N');
  add_list('AP_CARD_PROFILE_LIMITS_ALL'     , 'AP_CARD_PROFILE_LIMITS'         , 'SQLAP' ,'N','N');
  add_list('AP_CARD_PROGRAMS_ALL'           , 'AP_CARD_PROGRAMS'               , 'SQLAP' ,'N','N');
  add_list('AP_CARD_REQUESTS_ALL'           , 'AP_CARD_REQUESTS'               , 'SQLAP' ,'N','N');
  add_list('AP_CARD_SUPPLIERS_ALL'          , 'AP_CARD_SUPPLIERS'              , 'SQLAP' ,'N','N');
  add_list('AP_CHRG_ALLOCATIONS_ALL'        , 'AP_CHRG_ALLOCATIONS'            , 'SQLAP' ,'N','N');
  add_list('AP_CHECKRUN_CONC_PROCESSES_ALL' , 'AP_CHECKRUN_CONC_PROCESSES'     , 'SQLAP' ,'N','N');
  add_list('AP_CHECKRUN_CONFIRMATIONS_ALL'  , 'AP_CHECKRUN_CONFIRMATIONS'      , 'SQLAP' ,'N','N');
  add_list('AP_CHECKS_ALL'                  , 'AP_CHECKS'                      , 'SQLAP' ,'N','N');
  add_list('AP_CHECK_STOCKS_ALL'            , 'AP_CHECK_STOCKS'                , 'SQLAP' ,'N','N');
  add_list('AP_CREDIT_CARD_TRXNS_ALL'       , 'AP_CREDIT_CARD_TRXNS'           , 'SQLAP' ,'N','N');
  add_list('AP_DISTRIBUTION_SETS_ALL'       , 'AP_DISTRIBUTION_SETS'           , 'SQLAP' ,'N','N');
  add_list('AP_DISTRIBUTION_SET_LINES_ALL'  , 'AP_DISTRIBUTION_SET_LINES'      , 'SQLAP' ,'N','N');
  add_list('AP_DUPLICATE_VENDORS_ALL'       , 'AP_DUPLICATE_VENDORS'           , 'SQLAP' ,'N','N');
  add_list('AP_ENCUMBRANCE_LINES_ALL'       , 'AP_ENCUMBRANCE_LINES'           , 'SQLAP' ,'N','N');
  add_list('AP_EXP_REPORT_DISTS_ALL'        , 'AP_EXP_REPORT_DISTS'            , 'SQLAP' ,'N','N');
  add_list('AP_EXPENSE_FEED_DISTS_ALL'      , 'AP_EXPENSE_FEED_DISTS'          , 'SQLAP' ,'N','N');
  add_list('AP_EXPENSE_FEED_LINES_ALL'      , 'AP_EXPENSE_FEED_LINES'          , 'SQLAP' ,'N','N');
  add_list('AP_EXPENSE_PARAMS_ALL'          , 'AP_EXPENSE_PARAMS'              , 'SQLAP' ,'N','N');
  add_list('AP_EXPENSE_REPORT_HEADERS_ALL'  , 'AP_EXPENSE_REPORT_HEADERS'      , 'SQLAP' ,'N','N');
  add_list('AP_EXPENSE_REPORT_LINES_ALL'    , 'AP_EXPENSE_REPORT_LINES'        , 'SQLAP' ,'N','N');
  add_list('AP_EXPENSE_REPORT_PARAMS_ALL'   , 'AP_EXPENSE_REPORT_PARAMS'       , 'SQLAP' ,'N','N');
  add_list('AP_EXPENSE_REPORTS_ALL'         , 'AP_EXPENSE_REPORTS'             , 'SQLAP' ,'N','N');
  add_list('AP_FLEX_SEGMENT_MAPPINGS_ALL'   , 'AP_FLEX_SEGMENT_MAPPINGS'       , 'SQLAP' ,'Y','N');
  add_list('AP_HISTORY_CHECKS_ALL'          , 'AP_HISTORY_CHECKS'              , 'SQLAP' ,'N','N');
  add_list('AP_HISTORY_INVOICES_ALL'        , 'AP_HISTORY_INVOICES'            , 'SQLAP' ,'N','N');
  add_list('AP_HISTORY_INV_PAYMENTS_ALL'    , 'AP_HISTORY_INVOICE_PAYMENTS'    , 'SQLAP' ,'N','N');
  add_list('AP_HOLDS_ALL'                   , 'AP_HOLDS'                       , 'SQLAP' ,'N','N');
  add_list('AP_INVOICES_ALL'                , 'AP_INVOICES'                    , 'SQLAP' ,'N','N');
  add_list('AP_INVOICE_DISTRIBUTIONS_ALL'   , 'AP_INVOICE_DISTRIBUTIONS'       , 'SQLAP' ,'N','N');
  add_list('AP_INVOICE_KEY_IND_ALL'         , 'AP_INVOICE_KEY_IND'             , 'SQLAP' ,'N','N');
  add_list('AP_INVOICE_PAYMENTS_ALL'        , 'AP_INVOICE_PAYMENTS'            , 'SQLAP' ,'N','N');
  add_list('AP_INVOICE_PREPAYS_ALL'         , 'AP_INVOICE_PREPAYS'             , 'SQLAP' ,'N','N');
  add_list('AP_INV_SELECTION_CRITERIA_ALL'  , 'AP_INVOICE_SELECTION_CRITERIA'  , 'SQLAP' ,'N','N');
  add_list('AP_INV_APRVL_HIST_ALL'          , 'AP_INV_APRVL_HIST'              , 'SQLAP' ,'N','N');
  add_list('AP_MATCHED_RECT_ADJ_ALL'        , 'AP_MATCHED_RECT_ADJ'            , 'SQLAP' ,'N','N');
  add_list('AP_PAYMENT_HISTORY_ALL'         , 'AP_PAYMENT_HISTORY'             , 'SQLAP' ,'N','N');
  add_list('AP_PAYMENT_KEY_IND_ALL'         , 'AP_PAYMENT_KEY_IND'             , 'SQLAP' ,'N','N');
  add_list('AP_PAYMENT_SCHEDULES_ALL'       , 'AP_PAYMENT_SCHEDULES'           , 'SQLAP' ,'N','N');
  add_list('AP_PBATCH_SETS_ALL'             , 'AP_PBATCH_SETS'                 , 'SQLAP' ,'N','N');
  add_list('AP_PBATCH_SET_LINES_ALL'        , 'AP_PBATCH_SET_LINES'            , 'SQLAP' ,'N','N');
  add_list('AP_POL_CAT_OPTIONS_ALL'         , 'AP_POL_CAT_OPTIONS'             , 'SQLAP' ,'N','N');
  add_list('AP_POL_EXRATE_OPTIONS_ALL'      , 'AP_POL_EXRATE_OPTIONS'          , 'SQLAP' ,'N','N');
  add_list('AP_POL_VIOLATIONS_ALL'          , 'AP_POL_VIOLATIONS'              , 'SQLAP' ,'N','N');
  add_list('AP_RECURRING_PAYMENTS_ALL'      , 'AP_RECURRING_PAYMENTS'          , 'SQLAP' ,'N','N');
  add_list('AP_REPORTING_ENTITIES_ALL'      , 'AP_REPORTING_ENTITIES'          , 'SQLAP' ,'N','N');
  add_list('AP_REPORTING_ENTITY_LINES_ALL'  , 'AP_REPORTING_ENTITY_LINES'      , 'SQLAP' ,'N','N');
  add_list('AP_SELECTED_INVOICES_ALL'       , 'AP_SELECTED_INVOICES'           , 'SQLAP' ,'N','N');
  add_list('AP_SELECTED_INVOICE_CHECKS_ALL' , 'AP_SELECTED_INVOICE_CHECKS'     , 'SQLAP' ,'N','N');
  add_list('AP_SYSTEM_PARAMETERS_ALL'       , 'AP_SYSTEM_PARAMETERS'           , 'SQLAP' ,'N','N');
  add_list('AP_TAX_RECVRY_RATES_ALL'        , 'AP_TAX_RECVRY_RATES'            , 'SQLAP' ,'N','N');
  add_list('AP_TAX_RECVRY_RULES_ALL'        , 'AP_TAX_RECVRY_RULES'            , 'SQLAP' ,'N','N');
  add_list('AP_TEMP_APPROVAL_ALL'           , 'AP_TEMP_APPROVAL'               , 'SQLAP' ,'N','N');
  add_list('AP_TOLERANCES_ALL'              , 'AP_TOLERANCES'                  , 'SQLAP' ,'Y','N');
  add_list('AP_VENDOR_KEY_IND_ALL'          , 'AP_VENDOR_KEY_IND'              , 'SQLAP' ,'N','N');
  add_list('AP_WEB_SIGNING_LIMITS_ALL'      , 'AP_WEB_SIGNING_LIMITS'          , 'SQLAP' ,'N','N');
  add_list('AP_WEB_VAT_SETUP_ALL'           , 'AP_WEB_VAT_SETUP'               , 'SQLAP' ,'N','N');
  add_list('AP_WEB_EMPLOYEE_INFO_ALL'       , 'AP_WEB_EMPLOYEE_INFO'           , 'SQLAP' ,'N','N');
  add_list('FINANCIALS_SYSTEM_PARAMS_ALL'   , 'FINANCIALS_SYSTEM_PARAMETERS'   , 'SQLAP' ,'N','N');
  add_list('OIE_ATTENDEES_ALL'              , 'OIE_ATTENDEES'                  ,  'SQLAP' ,'N','N');
  add_list('AR_ADJUSTMENTS_ALL'             , 'AR_ADJUSTMENTS'                 , 'AR'    ,'N','N');
  add_list('AR_BATCHES_ALL'                 , 'AR_BATCHES'                     , 'AR'    ,'N','N');
  add_list('AR_BATCH_SOURCES_ALL'           , 'AR_BATCH_SOURCES'               , 'AR'    ,'Y','N');
  add_list('AR_BR_STAMP_VALUES_ALL'         , 'AR_BR_STAMP_VALUES'             , 'AR'    ,'N','N');
  add_list('AR_CASH_BASIS_DISTS_ALL'        , 'AR_CASH_BASIS_DISTRIBUTIONS'    , 'AR'    ,'N','N');
  add_list('AR_CASH_RECEIPTS_ALL'           , 'AR_CASH_RECEIPTS'               , 'AR'    ,'N','N');
  add_list('AR_CASH_RECEIPT_HISTORY_ALL'    , 'AR_CASH_RECEIPT_HISTORY'        , 'AR'    ,'N','N');
  add_list ('AR_CCID_CORRECTIONS_ALL'       , 'AR_CCID_CORRECTIONS'            , 'AR'    ,'N','N');
  add_list('RA_CM_REQUESTS_ALL'             , 'RA_CM_REQUESTS'                 , 'AR'    ,'N','N');
  add_list('RA_CM_REQUEST_LINES_ALL'        , 'RA_CM_REQUEST_LINES'            , 'AR'    ,'N','N');
  add_list('AR_COLLECTION_INDICATORS_ALL'   , 'AR_COLLECTION_INDICATORS'       , 'AR'    ,'N','N');
  add_list('AR_CONS_INV_ALL'                , 'AR_CONS_INV'                    , 'AR'    ,'N','N');
  add_list('AR_CONS_INV_TRX_ALL'            , 'AR_CONS_INV_TRX'                , 'AR'    ,'N','N');
  add_list('AR_CONS_INV_TRX_LINES_ALL'      , 'AR_CONS_INV_TRX_LINES'          , 'AR'    ,'N','N');
  add_list('AR_CONT_ACTIONS_ALL'            , 'AR_CONT_ACTIONS'                , 'AR'    ,'Y','N');
  add_list('AR_CORRESPONDENCES_ALL'         , 'AR_CORRESPONDENCES'             , 'AR'    ,'N','N');
  add_list('AR_CORR_PAY_SCHED_ALL'          , 'AR_CORRESPONDENCE_PAY_SCHED'    , 'AR'    ,'N','N');
  add_list('AR_CUSTOMER_CALLS_ALL'          , 'AR_CUSTOMER_CALLS'              , 'AR'    ,'N','N');
  add_list('AR_CUSTOMER_CALL_TOPICS_ALL'    , 'AR_CUSTOMER_CALL_TOPICS'        , 'AR'    ,'N','N');
  add_list('AR_DEFERRED_LINES_ALL'          , 'AR_DEFERRED_LINES'              , 'AR'    ,'N','N');
  add_list('AR_DISTRIBUTIONS_ALL'           , 'AR_DISTRIBUTIONS'               , 'AR'    ,'N','N');
  add_list('AR_DISTRIBUTION_SETS_ALL'       , 'AR_DISTRIBUTION_SETS'           , 'AR'    ,'N','N');
  add_list('AR_DISTRIBUTION_SET_LINES_ALL'  , 'AR_DISTRIBUTION_SET_LINES'      , 'AR'    ,'N','N');
  add_list('AR_INTERFACE_CONTS_ALL'         , 'AR_INTERFACE_CONTS'             , 'AR'    ,'N','N');
  add_list('AR_INTERIM_CASH_RCPT_LINES_ALL' , 'AR_INTERIM_CASH_RECEIPT_LINES'  , 'AR'    ,'N','N');
  add_list('AR_INTERIM_CASH_RECEIPTS_ALL'   , 'AR_INTERIM_CASH_RECEIPTS'       , 'AR'    ,'N','N');
  add_list('AR_JOURNAL_INTERIM_ALL'         , 'AR_JOURNAL_INTERIM'             , 'AR'    ,'N','N');
  add_list('AR_LINE_CONTS_ALL'              , 'AR_LINE_CONTS'                  , 'AR'    ,'N','N');
  add_list('AR_LOCATION_ACCOUNTS_ALL'       , 'AR_LOCATION_ACCOUNTS'           , 'AR'    ,'N','N');
  add_list('AR_LOCKBOXES_ALL'               , 'AR_LOCKBOXES'                   , 'AR'    ,'N','N');

  --
  -- AR_MC_DISTRIBUTIONS_ALL is MRC related and does not have corresponding
  -- view. Setting it to AR_MC_DISTRIBUTIONS_ALL
  --
  add_list('AR_MC_DISTRIBUTIONS_ALL'        , 'AR_MC_DISTRIBUTIONS_ALL'        , 'AR'    ,'N','N');
  add_list('AR_MC_CASH_BASIS_DISTS_ALL'     , 'AR_CASH_BASIS_DISTS_MRC_V'      , 'AR'    ,'N','N');
  add_list('AR_MEMO_LINES_ALL_B'            , 'AR_MEMO_LINES_B'                , 'AR'    ,'Y','N');
  add_list('AR_MEMO_LINES_ALL_TL'           , 'AR_MEMO_LINES_TL'               , 'AR'    ,'Y','N');
  add_list('AR_MISC_CASH_DISTRIBUTIONS_ALL' , 'AR_MISC_CASH_DISTRIBUTIONS'     , 'AR'    ,'N','N');
  add_list('AR_PAYMENTS_INTERFACE_ALL'      , 'AR_PAYMENTS_INTERFACE'          , 'AR'    ,'N','N');
  add_list('AR_PAYMENT_SCHEDULES_ALL'       , 'AR_PAYMENT_SCHEDULES'           , 'AR'    ,'N','N');
  add_list('AR_RATE_ADJUSTMENTS_ALL'        , 'AR_RATE_ADJUSTMENTS'            , 'AR'    ,'N','N');
  add_list('AR_RECEIPT_METHOD_ACCOUNTS_ALL' , 'AR_RECEIPT_METHOD_ACCOUNTS'     , 'AR'    ,'N','N');
  add_list('AR_RECEIVABLES_TRX_ALL'         , 'AR_RECEIVABLES_TRX'             , 'AR'    ,'Y','N');
  add_list('AR_RECEIVABLE_APPLICATIONS_ALL' , 'AR_RECEIVABLE_APPLICATIONS'     , 'AR'    ,'N','N');
  add_list('AR_REVENUE_ADJUSTMENTS_ALL'     , 'AR_REVENUE_ADJUSTMENTS'         , 'AR'    ,'N','N');
  add_list('AR_STATEMENTS_HISTORY_ALL'      , 'AR_STATEMENTS_HISTORY'          , 'AR'    ,'N','N');
  add_list('AR_STATEMENT_CYCLE_DATES_ALL'   , 'AR_STATEMENT_CYCLE_DATES'       , 'AR'    ,'N','N');
  add_list('AR_SYSTEM_PARAMETERS_ALL'       , 'AR_SYSTEM_PARAMETERS'           , 'AR'    ,'Y','N');
  add_list('AR_TAX_CONDITIONS_ALL'          , 'AR_TAX_CONDITIONS'              , 'AR'    ,'N','N');
  add_list('AR_TAX_CONDITION_ACTIONS_ALL'   , 'AR_TAX_CONDITION_ACTIONS'       , 'AR'    ,'N','N');
  add_list('AR_TAX_CONDITION_LINES_ALL'     , 'AR_TAX_CONDITION_LINES'         , 'AR'    ,'N','N');
  add_list('AR_TRANSACTION_HISTORY_ALL'     , 'AR_TRANSACTION_HISTORY'         , 'AR'    ,'N','N');
  add_list('AR_TRANSMISSIONS_ALL'           , 'AR_TRANSMISSIONS'               , 'AR'    ,'N','N');
  add_list('HZ_CUST_ACCT_RELATE_ALL'        , 'HZ_CUST_ACCT_RELATE'            , 'AR'    ,'N','N');
  add_list('HZ_CUST_ACCT_SITES_ALL'         , 'HZ_CUST_ACCT_SITES'             , 'AR'    ,'N','N');
  add_list('HZ_CUST_SITE_USES_ALL'          , 'HZ_CUST_SITE_USES'              , 'AR'    ,'N','N');
  add_list('RA_ACCOUNT_DEFAULTS_ALL'        , 'RA_ACCOUNT_DEFAULTS'            , 'AR'    ,'N','N');
  add_list('RA_BATCHES_ALL'                 , 'RA_BATCHES'                     , 'AR'    ,'N','N');
  add_list('RA_BATCH_SOURCES_ALL'           , 'RA_BATCH_SOURCES'               , 'AR'    ,'Y','N');
  add_list('RA_CONTACT_PHONES_INT_ALL'      , 'RA_CONTACT_PHONES_INTERFACE'    , 'AR'    ,'N','N');
  add_list('RA_CUSTOMERS_INTERFACE_ALL'     , 'RA_CUSTOMERS_INTERFACE'         , 'AR'    ,'N','N');
  add_list('RA_CUSTOMER_BANKS_INT_ALL'      , 'RA_CUSTOMER_BANKS_INTERFACE'    , 'AR'    ,'N','N');
  add_list('RA_CUSTOMER_PROFILES_INT_ALL'   , 'RA_CUSTOMER_PROFILES_INTERFACE' , 'AR'    ,'N','N');
  add_list('RA_CUSTOMER_RELATIONSHIPS_ALL'  , 'RA_CUSTOMER_RELATIONSHIPS'      , 'AR'    ,'N','N');
  add_list('RA_CUSTOMER_TRX_ALL'            , 'RA_CUSTOMER_TRX'                , 'AR'    ,'N','N');
  add_list('RA_CUSTOMER_TRX_LINES_ALL'      , 'RA_CUSTOMER_TRX_LINES'          , 'AR'    ,'N','N');
  add_list('RA_CUST_PAY_METHOD_INT_ALL'     , 'RA_CUST_PAY_METHOD_INTERFACE'   , 'AR'    ,'N','N');
  add_list('RA_CUST_TRX_LINE_GL_DIST_ALL'   , 'RA_CUST_TRX_LINE_GL_DIST'       , 'AR'    ,'N','N');
  add_list('RA_CUST_TRX_LINE_SALESREPS_ALL' , 'RA_CUST_TRX_LINE_SALESREPS'     , 'AR'    ,'N','N');
  add_list('RA_CUST_TRX_TYPES_ALL'          , 'RA_CUST_TRX_TYPES'              , 'AR'    ,'Y','N');
  add_list('RA_INTERFACE_DISTRIBUTIONS_ALL' , 'RA_INTERFACE_DISTRIBUTIONS'     , 'AR'    ,'N','N');
  add_list('RA_INTERFACE_ERRORS_ALL'        , 'RA_INTERFACE_ERRORS'            , 'AR'    ,'N','N');
  add_list('RA_INTERFACE_LINES_ALL'         , 'RA_INTERFACE_LINES'             , 'AR'    ,'N','N');
  add_list('RA_INTERFACE_SALESCREDITS_ALL'  , 'RA_INTERFACE_SALESCREDITS'      , 'AR'    ,'N','N');
  add_list('RA_REMIT_TOS_ALL'               , 'RA_REMIT_TOS'                   , 'AR'    ,'N','N');
  add_list('RA_SALESREPS_ALL'               , 'RA_SALESREPS'                   , 'AR'    ,'Y','N');
  add_list('RA_SITE_USES_ALL'               , 'RA_SITE_USES'                   , 'AR'    ,'N','N');
  add_list('ASO_QUOTE_HEADERS_ALL'          ,'ASO_QUOTE_HEADERS'               , 'ASO'   ,'N','N');
  add_list('ASO_QUOTE_LINES_ALL'            ,'ASO_QUOTE_LINES'                 , 'ASO'   ,'N','N');
  -- for bug 4208651
  add_list('BLC_SYSTEM_OPTIONS_ALL'         , 'BLC_SYSTEM_OPTIONS'             , 'BLC'   ,'N','N');
  add_list('BLC_CHARGE_CATS_ALL_B'          , 'BLC_CHARGE_CATS_VL'             , 'BLC'   ,'N','N');
  --
  add_list('CE_ARCH_HEADERS_ALL'            , 'CE_ARCH_HEADERS'                , 'CE'    ,'N','N');
  add_list('CE_ARCH_INTERFACE_HEADERS_ALL'  , 'CE_ARCH_INTERFACE_HEADERS'      , 'CE'    ,'N','N');
  add_list('CE_ARCH_INTRA_HEADERS_ALL'      , 'CE_ARCH_INTRA_HEADERS'          , 'CE'    ,'N','N');
  add_list('CE_ARCH_RECONCILIATIONS_ALL'    , 'CE_ARCH_RECONCILIATIONS'        , 'CE'    ,'N','N');
  add_list('CE_BANK_ACCT_USES_ALL'          , 'CE_BANK_ACCT_USES'              , 'CE'    ,'N','N');
  add_list('CE_INTRA_STMT_HEADERS_ALL'      , 'CE_INTRA_STMT_HEADERS'          , 'CE'    ,'N','N');
  add_list('CE_STATEMENT_HEADERS_ALL'       , 'CE_STATEMENT_HEADERS'           , 'CE'    ,'N','N');
  add_list('CE_STATEMENT_HEADERS_INT_ALL'   , 'CE_STATEMENT_HEADERS_INTERFACE' , 'CE'    ,'N','N');
  add_list('CE_STATEMENT_RECONCILS_ALL'     , 'CE_STATEMENT_RECONCILIATIONS'   , 'CE'    ,'N','N');
  add_list('CE_SYSTEM_PARAMETERS_ALL'       , 'CE_SYSTEM_PARAMETERS'           , 'CE'    ,'N','N');
  add_list('CE_UPG_BA_USES_ALL'           , 'CE_UPG_BA_USES'                 , 'CE'    ,'N','N');
  add_list('CE_UPGA_BA_USES_ALL'          , 'CE_UPGA_BA_USES'                , 'CE'    ,'N','N');
  --
  add_list('CN_ATTRIBUTE_RULES_ALL'         , 'CN_ATTRIBUTE_RULES'             , 'CN'    ,'N','N');
  add_list('CN_CAL_PER_INT_TYPES_ALL'       , 'CN_CAL_PER_INT_TYPES'           , 'CN'    ,'N','N');
  add_list('CN_CALC_EDGES_ALL'              , 'CN_CALC_EDGES'                  , 'CN'    ,'N','N');
  add_list('CN_CALC_EXT_TABLES_ALL'         , 'CN_CALC_EXT_TABLES'             , 'CN'    ,'N','N');
  add_list('CN_CALC_EXT_TBL_DTLS_ALL'       , 'CN_CALC_EXT_TBL_DTLS'           , 'CN'    ,'N','N');
  add_list('CN_CALC_FORMULAS_ALL'           , 'CN_CALC_FORMULAS'               , 'CN'    ,'N','N');
  add_list('CN_CALC_SUBMISSION_BATCHES_ALL' , 'CN_CALC_SUBMISSION_BATCHES'     , 'CN'    ,'N','N');
  add_list('CN_CALC_SUBMISSION_ENTRIES_ALL' , 'CN_CALC_SUBMISSION_ENTRIES'     , 'CN'    ,'N','N');
  add_list('CN_CALC_SUB_QUOTAS_ALL'         , 'CN_CALC_SUB_QUOTAS'             , 'CN'    ,'N','N');
  add_list('CN_CLRL_API_ALL'                , 'CN_CLRL_API'                    , 'CN'    ,'N','N');
  add_list('CN_COLUMN_MAPS_ALL'             , 'CN_COLUMN_MAPS'                 , 'CN'    ,'Y','N');
  add_list('CN_COMMISSION_HEADERS_ALL'      , 'CN_COMMISSION_HEADERS'          , 'CN'    ,'N','N');
  add_list('CN_COMMISSION_LINES_ALL'        , 'CN_COMMISSION_LINES'            , 'CN'    ,'N','N');
  add_list('CN_COMM_LINES_API_ALL'          , 'CN_COMM_LINES_API'              , 'CN'    ,'N','N');
  add_list('CN_COMP_PLANS_ALL'              , 'CN_COMP_PLANS'                  , 'CN'    ,'N','N');
  add_list('CN_CREDIT_CONV_FCTS_ALL'        , 'CN_CREDIT_CONV_FCTS'            , 'CN'    ,'N','N');
  add_list('CN_CREDIT_TYPES_ALL_B'          , 'CN_CREDIT_TYPES_ALL_VL'         , 'CN'    ,'Y','N');
  add_list('CN_CREDIT_TYPES_ALL_TL'         , 'CN_CREDIT_TYPES_ALL_VL'         , 'CN'    ,'Y','N');
  add_list('CN_DIMENSIONS_ALL_B'            , 'CN_DIMENSIONS_ALL_VL'           , 'CN'    ,'Y','N');
  add_list('CN_DIMENSIONS_ALL_TL'           , 'CN_DIMENSIONS_ALL_VL'           , 'CN'    ,'Y','N');
  add_list('CN_DIM_EXPLOSION_ALL'           , 'CN_DIM_EXPLOSION'               , 'CN'    ,'N','N');
  add_list('CN_DIM_HIERARCHIES_ALL'         , 'CN_DIM_HIERARCHIES'             , 'CN'    ,'N','N');
  add_list('CN_EVENTS_ALL_B'                , 'CN_EVENTS_ALL_VL'               , 'CN'    ,'Y','N');
  add_list('CN_EVENTS_ALL_TL'               , 'CN_EVENTS_ALL_VL'               , 'CN'    ,'Y','N');
  add_list('CN_EVENT_LOG_ALL'               , 'CN_EVENT_LOG'                   , 'CN'    ,'N','N');
  add_list('CN_FORMULA_INPUTS_ALL'          , 'CN_FORMULA_INPUTS'              , 'CN'    ,'N','N');
  add_list('CN_HEAD_HIERARCHIES_ALL_B'      , 'CN_HEAD_HIERARCHIES_ALL_VL'     , 'CN'    ,'Y','N');
  add_list('CN_HEAD_HIERARCHIES_ALL_TL'     , 'CN_HEAD_HIERARCHIES_ALL_VL'     , 'CN'    ,'Y','N');
  add_list('CN_HIERARCHIES_API_ALL'         , 'CN_HIERARCHIES_API'             , 'CN'    ,'N','N');
  add_list('CN_HIERARCHY_EDGES_ALL'         , 'CN_HIERARCHY_EDGES'             , 'CN'    ,'N','N');
  add_list('CN_HIERARCHY_NODES_ALL'         , 'CN_HIERARCHY_NODES'             , 'CN'    ,'N','N');
  add_list('CN_INTERVAL_TYPES_ALL_B'        , 'CN_INTERVAL_TYPES_ALL_VL'       , 'CN'    ,'Y','N');
  add_list('CN_INTERVAL_TYPES_ALL_TL'       , 'CN_INTERVAL_TYPES_ALL_VL'       , 'CN'    ,'Y','N');
  add_list('CN_LEDGER_JE_BATCHES_ALL'       , 'CN_LEDGER_JE_BATCHES'           , 'CN'    ,'N','N');
  add_list('CN_LEDGER_JOURNAL_ENTRIES_ALL'  , 'CN_LEDGER_JOURNAL_ENTRIES'      , 'CN'    ,'N','N');
  add_list('CN_LINE_ROLLUP_PATHS_ALL'       , 'CN_LINE_ROLLUP_PATHS'           , 'CN'    ,'N','N');
  add_list('CN_MODULES_ALL_B'               , 'CN_MODULES_ALL_VL'              , 'CN'    ,'Y','N');
  add_list('CN_MODULES_ALL_TL'              , 'CN_MODULES_ALL_VL'              , 'CN'    ,'Y','N');
  add_list('CN_MOD_OBJ_DEPENDS_ALL'         , 'CN_MOD_OBJ_DEPENDS'             , 'CN'    ,'N','N');
  add_list('CN_NOTIFY_LOG_ALL'              , 'CN_NOTIFY_LOG'                  , 'CN'    ,'N','N');
  add_list('CN_NOT_TRX_ALL'                 , 'CN_NOT_TRX'                     , 'CN'    ,'N','N');
  add_list('CN_OBJECTS_ALL'                 , 'CN_OBJECTS'                     , 'CN'    ,'Y','N');
  add_list('CN_PAY_GROUPS_ALL'              , 'CN_PAY_GROUPS'                  , 'CN'    ,'N','N');
  add_list('CN_PAYMENT_API_ALL'             , 'CN_PAYMENT_API'                 , 'CN'    ,'N','N');
  add_list('CN_PAYMENT_WORKSHEETS_ALL'      , 'CN_PAYMENT_WORKSHEETS'          , 'CN'    ,'N','N');
  add_list('CN_PAYRUNS_ALL'                 , 'CN_PAYRUNS'                     , 'CN'    ,'N','N');
  add_list('CN_PERIOD_QUOTAS_ALL'           , 'CN_PERIOD_QUOTAS'               , 'CN'    ,'N','N');
  add_list('CN_PERIOD_SETS_ALL'             , 'CN_PERIOD_SETS'                 , 'CN'    ,'N','N');
  add_list('CN_PERIOD_STATUSES_ALL'         , 'CN_PERIOD_STATUSES'             , 'CN'    ,'N','N');
  add_list('CN_PERIOD_TYPES_ALL'            , 'CN_PERIOD_TYPES'                , 'CN'    ,'Y','N');
  add_list('CN_PERF_MEASURES_ALL'           , 'CN_PERF_MEASURES'               , 'CN'    ,'N','N');
  add_list('CN_PMT_PLANS_ALL'               , 'CN_PMT_PLANS'                   , 'CN'    ,'N','N');
  add_list('CN_POSTING_BATCHES_ALL'         , 'CN_POSTING_BATCHES'             , 'CN'    ,'N','N');
  add_list('CN_POSTING_DETAILS_ALL'         , 'CN_POSTING_DETAILS'             , 'CN'    ,'N','N');
  add_list('CN_PROCESS_AUDITS_ALL'          , 'CN_PROCESS_AUDITS'              , 'CN'    ,'N','N');
  add_list('CN_PROCESS_AUDIT_LINES_ALL'     , 'CN_PROCESS_AUDIT_LINES'         , 'CN'    ,'N','N');
  add_list('CN_PROCESS_BATCHES_ALL'         , 'CN_PROCESS_BATCHES'             , 'CN'    ,'N','N');
  add_list('CN_QUOTAS_ALL'                  , 'CN_QUOTAS'                      , 'CN'    ,'N','N');
  add_list('CN_QUOTA_ASSIGNS_ALL'           , 'CN_QUOTA_ASSIGNS'               , 'CN'    ,'N','N');
  add_list('CN_QUOTA_RULE_UPLIFTS_ALL'      , 'CN_QUOTA_RULE_UPLIFTS'          , 'CN'    ,'N','N');
  add_list('CN_QUOTA_RULES_ALL'             , 'CN_QUOTA_RULES'                 , 'CN'    ,'N','N');
  add_list('CN_RATE_DIM_TIERS_ALL'          , 'CN_RATE_DIM_TIERS'              , 'CN'    ,'N','N');
  add_list('CN_RATE_DIMENSIONS_ALL'         , 'CN_RATE_DIMENSIONS'             , 'CN'    ,'N','N');
  add_list('CN_RATE_SCH_DIMS_ALL'           , 'CN_RATE_SCH_DIMS'               , 'CN'    ,'N','N');
  add_list('CN_RATE_SCHEDULES_ALL'          , 'CN_RATE_SCHEDULES'              , 'CN'    ,'N','N');
  add_list('CN_RATE_TIERS_ALL'              , 'CN_RATE_TIERS'                  , 'CN'    ,'N','N');
  add_list('CN_REASONS_ALL'                 , 'CN_REASONS'                     , 'CN'    ,'N','N');
  add_list('CN_REPOSITORIES_ALL'            , 'CN_REPOSITORIES'                , 'CN'    ,'Y','N');
  add_list('CN_REVENUE_CLASSES_ALL'         , 'CN_REVENUE_CLASSES'             , 'CN'    ,'N','N');
  add_list('CN_ROLE_PLANS_ALL'              , 'CN_ROLE_PLANS'                  , 'CN'    ,'N','N');
  add_list('CN_RT_FORMULA_ASGNS_ALL'        , 'CN_RT_FORMULA_ASGNS'            , 'CN'    ,'N','N');
  add_list('CN_RT_QUOTA_ASGNS_ALL'          , 'CN_RT_QUOTA_ASGNS'              , 'CN'    ,'N','N');
  add_list('CN_RULE_ATTR_EXPRESSION_ALL'    , 'CN_RULE_ATTR_EXPRESSION'        , 'CN'    ,'N','N');
  add_list('CN_RULESETS_ALL_B'              , 'CN_RULESETS_ALL_VL'             , 'CN'    ,'Y','N');
  add_list('CN_RULESETS_ALL_TL'             , 'CN_RULESETS_ALL_VL'             , 'CN'    ,'Y','N');
  add_list('CN_RULES_ALL_B'                 , 'CN_RULES_ALL_VL'                , 'CN'    ,'Y','N');
  add_list('CN_RULES_ALL_TL'                , 'CN_RULES_ALL_VL'                , 'CN'    ,'Y','N');
  add_list('CN_RULES_HIERARCHY_ALL'         , 'CN_RULES_HIERARCHY'             , 'CN'    ,'N','N');
  add_list('CN_SALESREPS_API_ALL'           , 'CN_SALESREPS_API'               , 'CN'    ,'N','N');
  add_list('CN_SCH_DIM_TIERS_ALL'           , 'CN_SCH_DIM_TIERS'               , 'CN'    ,'N','N');
  add_list('CN_SCA_RULE_ATTRIBUTES_ALL_B'   , 'CN_SCA_RULE_ATTRIBUTES_ALL_VL'  , 'CN'    ,'Y','N');
  add_list('CN_SCA_RULE_ATTRIBUTES_ALL_TL'  , 'CN_SCA_RULE_ATTRIBUTES_ALL_VL'  , 'CN'    ,'Y','N');
  add_list('CN_SEC_PROF_ASSIGNS_ALL'        , 'CN_SEC_PROF_ASSIGNS'            , 'CN'    ,'N','N');
  add_list('CN_SECURITY_PROFILES_ALL'       , 'CN_SECURITY_PROFILES'           , 'CN'    ,'N','N');
  add_list('CN_SOURCE_ALL'                  , 'CN_SOURCE'                      , 'CN'    ,'N','N');
  add_list('CN_SRP_INTEL_PERIODS_ALL'       , 'CN_SRP_INTEL_PERIODS'           , 'CN'    ,'N','N');
  add_list('CN_SRP_PAY_GROUPS_ALL'          , 'CN_SRP_PAY_GROUPS'              , 'CN'    ,'N','N');
  add_list('CN_SRP_PAYEE_ASSIGNS_ALL'       , 'CN_SRP_PAYEE_ASSIGNS'           , 'CN'    ,'N','N');
  add_list('CN_SRP_PERIODS_ALL'             , 'CN_SRP_PERIODS'                 , 'CN'    ,'N','N');
  add_list('CN_SRP_PERIOD_PAYEES_ALL'       , 'CN_SRP_PERIOD_PAYEES'           , 'CN'    ,'N','N');
  add_list('CN_SRP_PERIOD_QUOTAS_ALL'       , 'CN_SRP_PERIOD_QUOTAS'           , 'CN'    ,'N','N');
  add_list('CN_SRP_PER_QUOTA_RC_ALL'        , 'CN_SRP_PER_QUOTA_RC'            , 'CN'    ,'N','N');
  add_list('CN_SRP_PLAN_ASSIGNS_ALL'        , 'CN_SRP_PLAN_ASSIGNS'            , 'CN'    ,'N','N');
  add_list('CN_SRP_PMT_PLANS_ALL'           , 'CN_SRP_PMT_PLANS'               , 'CN'    ,'N','N');
  add_list('CN_SRP_QUOTA_ASSIGNS_ALL'       , 'CN_SRP_QUOTA_ASSIGNS'           , 'CN'    ,'N','N');
  add_list('CN_SRP_QUOTA_RULES_ALL'         , 'CN_SRP_QUOTA_RULES'             , 'CN'    ,'N','N');
  add_list('CN_SRP_RATE_ASSIGNS_ALL'        , 'CN_SRP_RATE_ASSIGNS'            , 'CN'    ,'N','N');
  add_list('CN_SRP_RULE_UPLIFTS_ALL'        , 'CN_SRP_RULE_UPLIFTS'            , 'CN'    ,'N','N');
  add_list('CN_LEDGER_BAL_TYPES_ALL_B'      , 'CN_LEDGER_BAL_TYPES_ALL_VL'     , 'CN'    ,'Y','N');
  add_list('CN_LEDGER_BAL_TYPES_ALL_TL'     , 'CN_LEDGER_BAL_TYPES_ALL_VL'     , 'CN'    ,'Y','N');
  add_list('CN_TABLE_MAPS_ALL'              , 'CN_TABLE_MAPS'                  , 'CN'    ,'Y','N');
  add_list('CN_TABLE_MAP_OBJECTS_ALL'       , 'CN_TABLE_MAP_OBJECTS'           , 'CN'    ,'Y','N');
  add_list('CN_TRX_ALL'                     , 'CN_TRX'                         , 'CN'    ,'N','N');
  add_list('CN_TRX_BATCHES_ALL'             , 'CN_TRX_BATCHES'                 , 'CN'    ,'N','N');
  add_list('CN_TRX_FACTORS_ALL'             , 'CN_TRX_FACTORS'                 , 'CN'    ,'N','N');
  add_list('CN_TRX_LINES_ALL'               , 'CN_TRX_LINES'                   , 'CN'    ,'N','N');
  add_list('CN_TRX_SALES_LINES_ALL'         , 'CN_TRX_SALES_LINES'             , 'CN'    ,'N','N');
  add_list('CN_WORKSHEET_BONUSES_ALL'       , 'CN_WORKSHEET_BONUSES'           , 'CN'    ,'N','N');
  --
  add_list('CS_ACCESS_CONTROL_TEMPLATE_ALL' , 'CS_ACCESS_CONTROL_TEMPLATES'    , 'CS'    ,'N','N');
  add_list('CS_CP_SERVICES_ALL'             , 'CS_CP_SERVICES'                 , 'CS'    ,'N','N');
  add_list('CS_ESTIMATE_HEADERS_ALL'        , 'CS_ESTIMATE_HEADERS'            , 'CS'    ,'N','N');
  add_list('CS_INCIDENTS_ALL'               , 'CS_INCIDENTS'                   , 'CS'    ,'N','N');
  add_list('CS_ORDERS_INTERFACE_ALL'        , 'CS_ORDERS_INTERFACE'            , 'CS'    ,'N','N');
  add_list('CS_REPAIRS_ALL'                 , 'CS_REPAIRS'                     , 'CS'    ,'N','N');
  add_list('CS_SYSTEMS_ALL_B'               , 'CS_SYSTEMS_VL'                  , 'CS'    ,'N','N');
  add_list('CS_SYSTEM_PARAMETERS_ALL'       , 'CS_SYSTEM_PARAMETERS'           , 'CS'    ,'N','N');
  add_list('CS_TERMINATION_INTERFACE_ALL'   , 'CS_TERMINATION_INTERFACE'       , 'CS'    ,'N','N');
  --
  add_list('CSR_WIN_PROMIS_ALL_B'           , 'CSR_WIN_PROMIS_VL'              , 'CSR'   ,'Y','N');
  add_list('CSR_COSTS_ALL_B'                , 'CSR_COSTS_VL'                   , 'CSR'   ,'Y','N');
  --
  add_list('FPT_AP_HEADERS_ALL'             , 'FPT_AP_HEADERS_V'               , 'FPT'   ,'N','N');
  add_list('FPT_BK_ACCOUNTS_ALL'            , 'FPT_ACCOUNTS_V'                 , 'FPT'   ,'N','N');
  add_list('FPT_BK_TRANSACTIONS_ALL'        , 'FPT_BK_TRANSACTIONS_V'          , 'FPT'   ,'N','N');
  add_list('FPT_FN_HEADERS_ALL'             , 'FPT_FN_HEADERS_ALL_V'           , 'FPT'   ,'N','N');
  --
  add_list('GMS_AWARDS_ALL'                 , 'GMS_AWARDS'                     , 'GMS'   ,'N','N');
  add_list('GMS_FUNDING_PATTERNS_ALL'       , 'GMS_FUNDING_PATTERNS'           , 'GMS'   ,'N','N');
  add_list('GMS_IMPLEMENTATIONS_ALL'        , 'GMS_IMPLEMENTATIONS'            , 'GMS'   ,'N','N');
  add_list('GMS_TRANSACTION_INTERFACE_ALL'  , 'GMS_TRANSACTION_INTERFACE'      , 'GMS'   ,'N','N');
  add_list('GMS_ENCUMBRANCES_ALL'           , 'GMS_ENCUMBRANCES'               , 'GMS'   ,'N','N');
  add_list('GMS_ENCUMBRANCE_GROUPS_ALL'     , 'GMS_ENCUMBRANCE_GROUPS'         , 'GMS'   ,'N','N');
  add_list('GMS_ENCUMBRANCE_ITEMS_ALL'      , 'GMS_ENCUMBRANCE_ITEMS'          , 'GMS'   ,'N','N');

  --

  add_list('IBE_SH_SHP_LISTS_ALL'           , 'IBE_SH_SHP_LISTS'               , 'IBE'   ,'N','N');
  add_list('IBE_SHP_LIST_ITEMS_ALL'         , 'IBE_SH_SHP_LIST_ITEMS'          , 'IBE'   ,'N','N');

 --
  add_list('IGW_IMPLEMENTATIONS_ALL'        , 'IGW_IMPLEMENTATIONS'            , 'IGW'  ,'N','N');
  add_list('IGW_PROPOSALS_ALL'              , 'IGW_PROPOSALS'                  , 'IGW'  ,'N','N');
  add_list('IGW_BUSINESS_RULES_ALL'         , 'IGW_BUSINESS_RULES'             , 'IGW'  ,'N','N');
  add_list('IGW_ORG_MAPS_ALL'               , 'IGW_ORG_MAPS_V'                 , 'IGW'  ,'N','N');

  add_list('IPA_ASSET_NAMING_CONVENTS_ALL'  , 'IPA_ASSET_NAMING_CONVENTIONS'   , 'IPA'  ,'N','N');

 --
  add_list('FV_1099C_ALL'                    , 'FV_1099C'                      , 'FV'    ,'N','N');
  add_list('FV_AAN_SETUP_DETAILS_ALL'        , 'FV_AAN_SETUP_DETAILS'          , 'FV'    ,'N','N');
  add_list('FV_AAN_SETUP_HDRS_ALL'           , 'FV_AAN_SETUP_HDRS'             , 'FV'    ,'N','N');
  add_list('FV_AR_BATCHES_ALL'               , 'FV_AR_BATCHES'                 , 'FV'    ,'N','N');
  add_list('FV_AR_CONTROLS_ALL'              , 'FV_AR_CONTROLS'                , 'FV'    ,'N','N');
  add_list('FV_ASSIGN_REASON_CODES_ALL'      , 'FV_ASSIGN_REASON_CODES'        , 'FV'    ,'N','N');
  add_list('FV_CUST_FINANCE_CHRGS_ALL'       , 'FV_CUST_FINANCE_CHRGS'         , 'FV'    ,'N','N');
  add_list('FV_FINANCE_CHARGE_CONTROLS_ALL'  , 'FV_FINANCE_CHARGE_CONTROLS'    , 'FV'    ,'N','N');
  add_list('FV_INTERAGENCY_FUNDS_ALL'        , 'FV_INTERAGENCY_FUNDS'          , 'FV'    ,'N','N');
  add_list('FV_INTERIM_CASH_RECEIPTS_ALL'    , 'FV_INTERIM_CASH_RECEIPTS'      , 'FV'    ,'N','N');
  add_list('FV_INVOICE_FINANCE_CHRGS_ALL'    , 'FV_INVOICE_FINANCE_CHRGS'      , 'FV'    ,'N','N');
  add_list('FV_INVOICE_RETURNS_ALL'          , 'FV_INVOICE_RETURNS'            , 'FV'    ,'N','N');
  add_list('FV_INVOICE_RETURN_DATES_ALL'     , 'FV_INVOICE_RETURN_DATES'       , 'FV'    ,'N','N');
  add_list('FV_INVOICE_STATUSES_ALL'         , 'FV_INVOICE_STATUSES'           , 'FV'    ,'N','N');
  add_list('FV_INVOICE_STATUSES_HIST_ALL'    , 'FV_INVOICE_STATUSES_HIST'      , 'FV'    ,'N','N');
  add_list('FV_OPAC_AUDIT_ALL'               , 'FV_OPAC_AUDIT'                 , 'FV'    ,'N','N');
  add_list('FV_OPAC_BILLING_ALL'             , 'FV_OPAC_BILLING'               , 'FV'    ,'N','N');
  add_list('FV_OPERATING_UNITS_ALL'          , 'FV_OPERATING_UNITS'            , 'FV'    ,'N','N');
  add_list('FV_RECEIVABLE_TYPES_ALL'         , 'FV_RECEIVABLE_TYPES'           , 'FV'    ,'N','N');
  add_list('FV_REC_CUST_TRX_TYPES_ALL'       , 'FV_REC_CUST_TRX_TYPES'         , 'FV'    ,'N','N');
  add_list('FV_REFUNDS_VOIDS_ALL'            , 'FV_REFUNDS_VOIDS'              , 'FV'    ,'N','N');
  add_list('FV_TREASURY_CONFIRMATIONS_ALL'   , 'FV_TREASURY_CONFIRMATIONS'     , 'FV'    ,'N','N');
 --
  add_list('JE_ES_MESSAGES_ALL'             , 'JE_ES_MESSAGES'                 , 'JE'    ,'N','N');
  add_list('JE_ES_MODELO_190_ALL'           , 'JE_ES_MODELO_190'               , 'JE'    ,'N','N');
  add_list('JE_ES_MODELO_347_ALL'           , 'JE_ES_MODELO_347'               , 'JE'    ,'N','N');
  add_list('JE_ES_MODELO_349_ALL'           , 'JE_ES_MODELO_349'               , 'JE'    ,'N','N');
  add_list('JE_ES_MODELO_415_ALL'           , 'JE_ES_MODELO_415'               , 'JE'    ,'N','N');
  add_list('JE_CZ_EFT_CONTRACTS_ALL'        , 'JE_CZ_EFT_CONTRACTS'            , 'JE'    ,'N' ,'N' , null, 'SQLAP');
  add_list('JE_CZ_CONT_ALLOC_ALL'           , 'JE_CZ_CONT_ALLOC'               , 'JE'    ,'N' ,'N', null, 'SQLAP');
 --
  add_list('JG_ZZ_AR_SRC_TRX_TY_ALL'        , 'JG_ZZ_AR_SRC_TRX_TY'            , 'JG'    ,'Y','N');
  add_list('JG_ZZ_SYS_FORMATS_ALL_B'        , 'JG_ZZ_SYS_FORMATS'              , 'JG'    ,'N' ,'N', null, 'SQLAP');
  add_list('JG_ZZ_SYS_FORMATS_ALL_TL'       , 'JG_ZZ_SYS_FORMATS_VL'           , 'JG'    ,'N' ,'N', null, 'SQLAP');
  --
  add_list('JE_CZ_EFT_CONTRACTS_ALL'        , 'JE_CZ_EFT_CONTRACTS'            , 'JE'    ,'N' ,'N' , null, 'SQLAP');
  add_list('JE_CZ_CONT_ALLOC_ALL'           , 'JE_CZ_CONT_ALLOC'               , 'JE'    ,'N' ,'N', null, 'SQLAP');
  --
  add_list('JL_AR_AP_AWT_CERTIF_ALL'        , 'JL_AR_AP_AWT_CERTIF'            , 'JL'    ,'N','N');
  add_list('JL_AR_AR_DOC_LETTER_ALL'        , 'JL_AR_AR_DOC_LETTER'            , 'JL'    ,'N','N');

  add_list('JL_BR_AP_COLLECTION_DOCS_ALL'   , 'JL_BR_AP_COLLECTION_DOCS'       , 'JL'    ,'N','N');
  add_list('JL_BR_AP_CONSOLID_INVOICES_ALL' , 'JL_BR_AP_CONSOLID_INVOICES'     , 'JL'    ,'N','N');
  --
  -- JL_BR_AP_EXP_REP_HEAD_EXT_ALL is MRC related and does not have
  -- corresponding view. Setting it to JL_BR_AP_EXP_REP_HEAD_EXT_ALL
  --
  add_list('JL_BR_AP_INT_COLLECT_ALL'       , 'JL_BR_AP_INT_COLLECT'           , 'JL'    ,'N','N');
  add_list('JL_BR_AP_INT_COLLECT_EXT_ALL'   , 'JL_BR_AP_INT_COLLECT_EXT'       , 'JL'    ,'N','N');
  add_list('JL_BR_AR_BANK_RETURNS_ALL'      , 'JL_BR_AR_BANK_RETURNS'          , 'JL'    ,'N','N');
  add_list('JL_BR_AR_BORDEROS_ALL'          , 'JL_BR_AR_BORDEROS'              , 'JL'    ,'N','N');
  add_list('JL_BR_AR_COLLECTION_DOCS_ALL'   , 'JL_BR_AR_COLLECTION_DOCS'       , 'JL'    ,'N','N');
  add_list('JL_BR_AR_COMP_INV_ALL'          , 'JL_BR_AR_COMP_INV'              , 'JL'    ,'N','N');
  add_list('JL_BR_AR_OCCURRENCE_DOCS_ALL'   , 'JL_BR_AR_OCCURRENCE_DOCS'       , 'JL'    ,'N','N');
  add_list('JL_BR_AR_REC_MET_ACCTS_EXT_ALL' , 'JL_BR_AR_REC_MET_ACCTS_EXT'     , 'JL'    ,'N','N');
  add_list('JL_BR_AR_REMIT_BORDEROS_ALL'    , 'JL_BR_AR_REMIT_BORDEROS'        , 'JL'    ,'N','N');
  add_list('JL_BR_AR_RET_INTERFACE_ALL'     , 'JL_BR_AR_RET_INTERFACE'         , 'JL'    ,'N','N');
  add_list('JL_BR_AR_RET_INTERFACE_EXT_ALL' , 'JL_BR_AR_RET_INTERFACE_EXT'     , 'JL'    ,'N','N');
  add_list('JL_BR_AR_SELECT_ACCOUNTS_ALL'   , 'JL_BR_AR_SELECT_ACCOUNTS'       , 'JL'    ,'N','N');
  add_list('JL_BR_AR_SELECT_CONTROLS_ALL'   , 'JL_BR_AR_SELECT_CONTROLS'       , 'JL'    ,'N','N');
  add_list('JL_BR_AR_TX_CATEG_ALL'          , 'JL_BR_AR_TX_CATEG'              , 'JL'    ,'Y','N');
  add_list('JL_BR_AR_TX_EXC_ITM_ALL'        , 'JL_BR_AR_TX_EXC_ITM'            , 'JL'    ,'N','N');
  add_list('JL_BR_AR_TX_FSC_CLS_ALL'        , 'JL_BR_AR_TX_FSC_CLS'            , 'JL'    ,'N','N');
  add_list('JL_BR_AR_TX_GROUP_ALL'          , 'JL_BR_AR_TX_GROUP'              , 'JL'    ,'N','N');
  add_list('JL_BR_AR_TX_LOCN_ALL'           , 'JL_BR_AR_TX_LOCN'               , 'JL'    ,'N','N');
  add_list('JL_BR_AR_TX_RULES_ALL'          , 'JL_BR_AR_TX_RULES'              , 'JL'    ,'N','N');
  add_list('JL_BR_BALANCES_ALL'             , 'JL_BR_BALANCES'                 , 'JL'    ,'N','N');
  add_list('JL_BR_JOURNALS_ALL'             , 'JL_BR_JOURNALS'                 , 'JL'    ,'N','N');
  add_list('JL_BR_PO_FISC_CLASSIF_ALL'      , 'JL_BR_PO_FISC_CLASSIF'          , 'JL'    ,'N','N');
  add_list('JL_BR_PO_TAX_EXCEPTIONS_ALL'    , 'JL_BR_PO_TAX_EXCEPTIONS'        , 'JL'    ,'N','N');
  add_list('JL_BR_PO_TAX_EXC_ITEMS_ALL'     , 'JL_BR_PO_TAX_EXC_ITEMS'         , 'JL'    ,'N','N');
  add_list('JL_BR_PO_TAX_LOCATIONS_ALL'     , 'JL_BR_PO_TAX_LOCATIONS'         , 'JL'    ,'N','N');
  add_list('JL_BR_TAX_LMSG_ALL'             , 'JL_BR_TAX_LMSG'                 , 'JL'    ,'N','N');
  add_list('JL_ZZ_AP_INV_DIS_WH_ALL'        , 'JL_ZZ_AP_INV_DIS_WH'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AP_SUP_AWT_CD_ALL'        , 'JL_ZZ_AP_SUP_AWT_CD'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_ATT_CLS_ALL'        , 'JL_ZZ_AR_TX_ATT_CLS'            , 'JL'    ,'Y','N');
  add_list('JL_ZZ_AR_TX_ATT_VAL_ALL'        , 'JL_ZZ_AR_TX_ATT_VAL'            , 'JL'    ,'Y','N');
  add_list('JL_ZZ_AR_TX_CAT_ATT_ALL'        , 'JL_ZZ_AR_TX_CAT_ATT'            , 'JL'    ,'Y','N');
  add_list('JL_ZZ_AR_TX_CAT_DTL_ALL'        , 'JL_ZZ_AR_TX_CAT_DTL'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_CATEG_ALL'          , 'JL_ZZ_AR_TX_CATEG'              , 'JL'    ,'Y','N');
  add_list('JL_ZZ_AR_TX_CUS_CLS_ALL'        , 'JL_ZZ_AR_TX_CUS_CLS'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_EXC_CUS_ALL'        , 'JL_ZZ_AR_TX_EXC_CUS'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_EXC_FSC_ALL'        , 'JL_ZZ_AR_TX_EXC_FSC'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_EXC_ITM_ALL'        , 'JL_ZZ_AR_TX_EXC_ITM'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_FSC_CLS_ALL'        , 'JL_ZZ_AR_TX_FSC_CLS'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_GROUPS_ALL'         , 'JL_ZZ_AR_TX_GROUPS'             , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_LGL_MSG_ALL'        , 'JL_ZZ_AR_TX_LGL_MSG'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_LOCN_ALL'           , 'JL_ZZ_AR_TX_LOCN'               , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_NAT_RAT_ALL'        , 'JL_ZZ_AR_TX_NAT_RAT'            , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_RULES_ALL'          , 'JL_ZZ_AR_TX_RULES'              , 'JL'    ,'N','N');
  add_list('JL_ZZ_AR_TX_SCHEDULES_ALL'      , 'JL_ZZ_AR_TX_SCHEDULES'          , 'JL'    ,'N','N');
  --
  add_list('JTF_TERR_ALL'                   , 'JTF_TERR'                       , 'JTF'   ,'Y','N');
  --add_list('JTF_QUAL_TYPE_USGS_ALL'         , 'JTF_QUAL_TYPE_USGS'             , 'JTF'   ,'Y','N');
  --add_list('JTF_QUAL_TYPES_ALL'             , 'JTF_QUAL_TYPES'                 , 'JTF'   ,'Y','N');
  add_list('JTF_QUAL_USGS_ALL'              , 'JTF_QUAL_USGS'                  , 'JTF'   ,'Y','N');
  --add_list('JTF_SEEDED_QUAL_ALL_B'          , 'JTF_SEEDED_QUAL'                , 'JTF'   ,'Y','N');
  --add_list('JTF_SEEDED_QUAL_ALL_TL'         , 'JTF_SEEDED_QUAL'                , 'JTF'   ,'Y','N');
  --add_list('JTF_SOURCES_ALL'                , 'JTF_SOURCES'                    , 'JTF'   ,'Y','N');
  add_list('JTF_FM_GROUPS_ALL'              , 'JTF_FM_GROUP'                   , 'JTF'   ,'N','N');
  add_list('JTF_FM_QUERIES_ALL'             , 'JTF_FM_QUERY'                   , 'JTF'   ,'Y','N');
  add_list('JTF_FM_SERVICE_ALL'             , 'JTF_FM_SERVICE'                 , 'JTF'   ,'N','N');
  add_list('JTF_FM_TEMPLATE_ALL'            , 'JTF_FM_TEMPLATE'                , 'JTF'   ,'Y','N');
  add_list('JTF_FM_STATUS_ALL'              , 'JTF_FM_STATUS'                  , 'JTF'   ,'N','N');
  add_list('JTF_FM_REQUEST_HISTORY_ALL'     , 'JTF_FM_REQUEST_HISTORY'         , 'JTF'   ,'N','N');
  add_list('JTF_CHANGED_TERR_ALL'           , 'JTF_CHANGED_TERR'               , 'JTF'   ,'N','N');
  add_list('JTF_TERR_QTYPE_USGS_ALL'        , 'JTF_TERR_QTYPE_USGS'            , 'JTF'   ,'N','N');
  add_list('JTF_TERR_QUAL_ALL'              , 'JTF_TERR_QUAL'                  , 'JTF'   ,'N','N');
  add_list('JTF_TERR_USGS_ALL'              , 'JTF_TERR_USGS'                  , 'JTF'   ,'N','N');
  add_list('JTF_TERR_VALUES_ALL'            , 'JTF_TERR_VALUES'                , 'JTF'   ,'N','N');
  add_list('JTF_TERR_RSC_ACCESS_ALL'        , 'JTF_TERR_RSC_ACCESS'            , 'JTF'   ,'N','N');
  add_list('JTF_TERR_RSC_ALL'               , 'JTF_TERR_RSC'                   , 'JTF'   ,'N','N');
  add_list('JTF_TERR_TYPE_QUAL_ALL'         , 'JTF_TERR_TYPE_QUAL'             , 'JTF'   ,'Y','N');
  add_list('JTF_TERR_TYPE_USGS_ALL'         , 'JTF_TERR_TYPE_USGS'             , 'JTF'   ,'Y','N');
  add_list('JTF_TERR_TYPES_ALL'             , 'JTF_TERR_TYPES'                 , 'JTF'   ,'Y','N');
  add_list('JTF_TYPE_QTYPE_USGS_ALL'        , 'JTF_TYPE_QTYPE_USGS'            , 'JTF'   ,'Y','N');
  add_list('JTF_RS_SALESREPS'               , 'JTF_RS_SALESREPS_MO_V'          , 'JTF'   ,'Y','N');
  --
  add_list('SO_HEADERS_ALL'                 , 'SO_HEADERS'                     , 'OE'    ,'N','N');
  add_list('SO_HEADERS_INTERFACE_ALL'       , 'SO_HEADERS_INTERFACE'           , 'OE'    ,'N','N');
  add_list('SO_HOLD_SOURCES_ALL'            , 'SO_HOLD_SOURCES'                , 'OE'    ,'N','N');
  add_list('SO_LINES_ALL'                   , 'SO_LINES'                       , 'OE'    ,'N','N');
  add_list('SO_LINES_INTERFACE_ALL'         , 'SO_LINES_INTERFACE'             , 'OE'    ,'N','N');
  add_list('SO_ORDER_HOLDS_ALL'             , 'SO_ORDER_HOLDS_115'             , 'OE'    ,'N','N');
  add_list('SO_ORDER_TYPES_115_ALL'         , 'SO_ORDER_TYPES_115'             , 'OE'    ,'N','N');
  add_list('SO_PICKING_BATCHES_ALL'         , 'SO_PICKING_BATCHES'             , 'OE'    ,'N','N');
  add_list('SO_PICKING_HEADERS_ALL'         , 'SO_PICKING_HEADERS'             , 'OE'    ,'N','N');
  add_list('SO_PICKING_LINES_ALL'           , 'SO_PICKING_LINES'               , 'OE'    ,'N','N');
  --
  add_list('OE_ACTIONS_IFACE_ALL'           , 'OE_ACTIONS_INTERFACE'           , 'ONT'   ,'N','N');
  add_list('OE_BLANKET_HEADERS_ALL'         , 'OE_BLANKET_HEADERS'             , 'ONT'   ,'N', 'N');
  add_list('OE_BLANKET_LINES_ALL'           , 'OE_BLANKET_LINES'               , 'ONT'   ,'N', 'N');
  add_list('OE_CREDIT_BALANCES_ALL'         , 'OE_CREDIT_BALANCES'             , 'ONT'  ,'N', 'N');
  add_list('OE_CUST_TOTAL_AMTS_ALL'         , 'OE_CUST_TOTAL_AMTS'             , 'ONT'   ,'N', 'N');
  add_list('OE_CREDITS_IFACE_ALL'           , 'OE_CREDITS_INTERFACE'           , 'ONT'   ,'N','N');
  add_list('OE_EM_INFORMATION_ALL'          , 'OE_EM_INFORMATION'              , 'ONT'   ,'N','N');
  add_list('OE_HEADERS_IFACE_ALL'           , 'OE_HEADERS_INTERFACE'           , 'ONT'   ,'N','N');
  add_list('OE_ITEM_CUST_VOLS_ALL'          , 'OE_ITEM_CUST_VOLS'              , 'ONT'   ,'N', 'N');
  add_list('OE_LINES_IFACE_ALL'             , 'OE_LINES_INTERFACE'             , 'ONT'   ,'N','N');
  add_list('OE_LOTSERIALS_IFACE_ALL'        , 'OE_LOTSERIALS_INTERFACE'        , 'ONT'   ,'N','N');
  add_list('OE_RESERVTNS_IFACE_ALL'         , 'OE_RESERVTNS_INTERFACE'         , 'ONT'   ,'N','N');
  add_list('OE_HOLD_SOURCES_ALL'            , 'OE_HOLD_SOURCES'                , 'ONT'   ,'N','N');
  add_list('OE_ORDER_HEADERS_ALL'           , 'OE_ORDER_HEADERS'               , 'ONT'   ,'N','N');
  add_list('OE_ORDER_HOLDS_ALL'             , 'OE_ORDER_HOLDS'                 , 'ONT'   ,'N','N');
  add_list('OE_ORDER_LINES_ALL'             , 'OE_ORDER_LINES'                 , 'ONT'   ,'N','N');
  add_list('OE_PAYMENTS_IFACE_ALL'          , 'OE_PAYMENTS_INTERFACE'          , 'ONT'   ,'N', 'N');
  add_list('OE_PAYMENT_TYPES_ALL'           , 'OE_PAYMENT_TYPES_VL'            , 'ONT'   ,'Y','N');
  add_list('OE_PAYMENT_TYPES_TL'            , 'OE_PAYMENT_TYPES_VL'            , 'ONT'   ,'Y','N');
  add_list('OE_PRICE_ADJS_IFACE_ALL'        , 'OE_PRICE_ADJS_INTERFACE'        , 'ONT'   ,'N','N');
  add_list('OE_PRICE_ATTS_IFACE_ALL'        , 'OE_PRICE_ATTS_INTERFACE'        , 'ONT'   ,'N','N');
  add_list('OE_SYS_PARAMETERS_ALL'          , 'OE_SYS_PARAMETERS_V'            ,  'ONT'  ,'N','N');
  add_list('OE_SYSTEM_PARAMETERS_ALL'       , 'OE_SYSTEM_PARAMETERS'           , 'ONT'   ,'N','N');
  add_list('OE_TRANSACTION_TYPES_ALL'       , 'OE_TRANSACTION_TYPES_VL'        , 'ONT'   ,'N','N');
  --
  add_list('PA_ALL_ORGANIZATIONS'           , 'PA_ALL_ORGANIZATIONS'           , 'PA'    ,'N','N');
  add_list('PA_BC_COMMITMENTS_ALL'          , 'PA_BC_COMMITMENTS'              , 'PA'    ,'N','N');
  --
  add_list('AS_ACCESSES_ALL'                , 'AS_ACCESSES'                    , 'AS'    ,'N','N');
  add_list('AS_ACCESSES_ALL_ALL'            , 'AS_ACCESSES'                    , 'AS'    ,'N','N');
  add_list('AS_ACCESSES_ALL_ALL'            , 'AS_ACCESSES_ALL'                , 'AS'    ,'N','N');
  add_list('AS_CHANGED_ACCOUNTS_ALL'        , 'AS_CHANGED_ACCOUNTS'            , 'AS'    ,'N','N');
  add_list('AS_DEFAULT_PURCHASES_ALL'       , 'AS_DEFAULT_PURCHASES'           , 'AS'    ,'N','N');
  add_list('AS_FORECAST_PROB_ALL_B'         , 'AS_FORECAST_PROB'               , 'AS'    ,'N','N');
  add_list('AS_INTERESTS_ALL'               , 'AS_INTERESTS'                   , 'AS'    ,'N','N');
  add_list('AS_INTEREST_CATEGORY_SETS_ALL'  , 'AS_INTEREST_CATEGORY_SETS'      , 'AS'    ,'N','N');
  add_list('AS_INTEREST_TYPES_ALL'          , 'AS_INTEREST_TYPES'              , 'AS'    ,'N','N');
  add_list('AS_LEADS_ALL'                   , 'AS_LEADS'                       , 'AS'    ,'N','N');
  add_list('AS_LEAD_CONTACTS_ALL'           , 'AS_LEAD_CONTACTS'               , 'AS'    ,'N','N');
  add_list('AS_LEAD_LINES_ALL'              , 'AS_LEAD_LINES'                  , 'AS'    ,'N','N');
  add_list('AS_MERGE_FILES_ALL'             , 'AS_MERGE_FILES'                 , 'AS'    ,'N','N');
  add_list('AS_SALES_STAGES_ALL_B'          , 'AS_SALES_STAGES'                , 'AS'    ,'N','N');
  --
  add_list('PA_AGREEMENTS_ALL'              , 'PA_AGREEMENTS'                  , 'PA'    ,'N','N');
  add_list('PA_ALLOC_RULES_ALL'             , 'PA_ALLOC_RULES'                 , 'PA'    ,'N','N');
  add_list('PA_ALLOC_RUNS_ALL'              , 'PA_ALLOC_RUNS'                  , 'PA'    ,'N','N');
  add_list('PA_BILLING_ASSIGNMENTS_ALL'     , 'PA_BILLING_ASSIGNMENTS'         , 'PA'    ,'Y','N');
  add_list('PA_BILL_RATES_ALL'              , 'PA_BILL_RATES'                  , 'PA'    ,'N','N');
  add_list('PA_BIS_TOTALS_TO_DATE_ALL'      , 'PA_BIS_TOTALS_TO_DATE'          , 'PA'    ,'N','N');
  add_list('PA_BIS_TOTALS_BY_PRD_ALL'       , 'PA_BIS_TOTALS_BY_PRD'           , 'PA'    ,'N','N');
  add_list('PA_BIS_TO_DATE_DRILLS_ALL'      , 'PA_BIS_TO_DATE_DRILLS'          , 'PA'    ,'N','N');
  add_list('PA_BIS_PRJ_TO_DATE_DRILLS_ALL'  , 'PA_BIS_PRJ_TO_DATE_DRILLS'      , 'PA'    ,'N','N');
  add_list('PA_BIS_PRJ_BY_PRD_DRILLS_ALL'   , 'PA_BIS_PRJ_BY_PRD_DRILLS'       , 'PA'    ,'N','N');
  add_list('PA_CC_DIST_LINES_ALL'           , 'PA_CC_DIST_LINES'               , 'PA'    ,'N','N');
  add_list('PA_CINT_RATE_INFO_ALL'          , 'PA_CINT_RATE_INFO'              , 'PA'    ,'N','N');
  add_list('PA_CINT_EXP_TYPE_EXCL_ALL'      , 'PA_CINT_EXP_TYPE_EXCL'          , 'PA'    ,'N','N');
  add_list('PA_COMPENSATION_DETAILS_ALL'    , 'PA_COMPENSATION_DETAILS'        , 'PA'    ,'N','N');
  add_list('PA_COMP_RULE_OT_DEFAULTS_ALL'   , 'PA_COMP_RULE_OT_DEFAULTS'       , 'PA'    ,'N','N');
  add_list('PA_COST_DISTRIBUTION_LINES_ALL' , 'PA_COST_DISTRIBUTION_LINES'     , 'PA'    ,'N','N');
  add_list('PA_CUST_EVENT_RDL_ALL'          , 'PA_CUST_EVENT_REV_DIST_LINES'   , 'PA'    ,'N','N');
  add_list('PA_CUST_REV_DIST_LINES_ALL'     , 'PA_CUST_REV_DIST_LINES'         , 'PA'    ,'N','N');
  add_list('PA_DRAFT_INVOICES_ALL'          , 'PA_DRAFT_INVOICES'              , 'PA'    ,'N','N');
  add_list('PA_DRAFT_INVOICE_DETAILS_ALL'   , 'PA_DRAFT_INVOICE_DETAILS'       , 'PA'    ,'N','N');
  add_list('PA_DRAFT_REVENUES_ALL'          , 'PA_DRAFT_REVENUES'              , 'PA'    ,'N','N');
  add_list('PA_EMPLOYEE_ACCUM_ALL'          , 'PA_EMPLOYEE_ACCUM'              , 'PA'    ,'N','N');
  add_list('PA_EMPLOYEE_ORG_ACCUM_ALL'      , 'PA_EMPLOYEE_ORG_ACCUM'          , 'PA'    ,'N','N');
  add_list('PA_EVENT_TYPE_OUS_ALL'          , 'PA_EVENT_TYPE_OUS'              , 'PA'    ,'N','N');
  add_list('PA_EXPENDITURES_ALL'            , 'PA_EXPENDITURES'                , 'PA'    ,'N','N');
  add_list('PA_EXPENDITURE_BATCHES_ALL'     , 'PA_EXPENDITURE_BATCHES'         , 'PA'    ,'N','N');
  add_list('PA_EXPENDITURE_COST_RATES_ALL'  , 'PA_EXPENDITURE_COST_RATES'      , 'PA'    ,'N','N');
  add_list('PA_EXPENDITURE_GROUPS_ALL'      , 'PA_EXPENDITURE_GROUPS'          , 'PA'    ,'N','N');
  add_list('PA_EXPENDITURE_ITEMS_ALL'       , 'PA_EXPENDITURE_ITEMS'           , 'PA'    ,'N','N');
  add_list('PA_EXPENDITURE_TYPE_OUS_ALL'    , 'PA_EXPENDITURE_TYPE_OUS'        , 'PA'    ,'N','N');
  add_list('PA_FUNCTION_TRANSACTIONS_ALL'   , 'PA_FUNCTION_TRANSACTIONS'       , 'PA'    ,'Y','N');
  add_list('PA_IMPLEMENTATIONS_ALL'         , 'PA_IMPLEMENTATIONS'             , 'PA'    ,'N','N');
  add_list('PA_MASS_UPDATE_BATCHES_ALL'     , 'PA_MASS_UPDATE_BATCHES'         , 'PA'    ,'N','N');
  add_list('PA_PERIODS_ALL'                 , 'PA_PERIODS'                     , 'PA'    ,'N','N');
  add_list('PA_PRJ_ACT_CMT_IT_ALL'          , 'PA_PRJ_ACT_CMT_IT'              , 'PA'    ,'N','N');
  add_list('PA_PRJ_BGT_LINES_IT_ALL'        , 'PA_PRJ_BGT_LINES_IT'            , 'PA'    ,'N','N');
  add_list('PA_PRJ_TYPES_IT_ALL'            , 'PA_PRJ_TYPES_IT'                , 'PA'    ,'N','N');
  add_list('PA_PROJECTS_ALL'                , 'PA_PROJECTS'                    , 'PA'    ,'N','N');
  add_list('PA_PROJECTS_IT_ALL'             , 'PA_PROJECTS_IT'                 , 'PA'    ,'N','N');
  add_list('PA_PROJECT_ASSETS_ALL'          , 'PA_PROJECT_ASSETS'              , 'PA'    ,'N','N');
  add_list('PA_PROJECT_ASSET_LINES_ALL'     , 'PA_PROJECT_ASSET_LINES'         , 'PA'    ,'N','N');
  add_list('PA_PROJECT_TYPES_ALL'           , 'PA_PROJECT_TYPES'               , 'PA'    ,'N','N');
  add_list('PA_PROJ_TYPE_DISTRIBUTIONS_ALL' , 'PA_PROJECT_TYPE_DISTRIBUTIONS'  , 'PA'    ,'N','N');
  add_list('PA_PROJ_TYPE_VERIFICATIONS_ALL' , 'PA_PROJECT_TYPE_VERIFICATIONS'  , 'PA'    ,'N','N');
  add_list('PA_SEGMENT_RULE_PAIRINGS_ALL'   , 'PA_SEGMENT_RULE_PAIRINGS'       , 'PA'    ,'N','N');
  add_list('PA_STD_BILL_RATE_SCHEDULES_ALL' , 'PA_STD_BILL_RATE_SCHEDULES'     , 'PA'    ,'N','N');
  add_list('PA_TRANSACTION_INTERFACE_ALL'   , 'PA_TRANSACTION_INTERFACE'       , 'PA'    ,'N','N');
  add_list('PA_TRANSACTION_XFACE_CTRL_ALL'  , 'PA_TRANSACTION_XFACE_CONTROL'   , 'PA'    ,'N','N');
  add_list('PA_TSK_ACT_CMT_IT_ALL'          , 'PA_TSK_ACT_CMT_IT'              , 'PA'    ,'N','N');
  add_list('PA_TSK_BGT_LINES_IT_ALL'        , 'PA_TSK_BGT_LINES_IT'            , 'PA'    ,'N','N');
  add_list('PA_TXN_INTERFACE_AUDIT_ALL'     , 'PA_TXN_INTERFACE_AUDIT'         , 'PA'    ,'N','N');
  add_list('PA_USAGE_COST_RATE_OVR_ALL'     , 'PA_USAGE_COST_RATE_OVERRIDES'   , 'PA'    ,'N','N');
  add_list('PA_FORECASTING_OPTIONS_ALL'     , 'PA_FORECASTING_OPTIONS'         , 'PA'    ,'N','N');
  add_list('PA_UTILIZATION_OPTIONS_ALL'     , 'PA_UTILIZATION_OPTIONS'         , 'PA'    ,'N','N');

 --------

  add_list('PN_ACCOUNTING_EVENTS_ALL'       , 'PN_ACCOUNTING_EVENTS'           , 'PN'    ,'N','N');
  add_list('PN_ADDRESSES_ALL'               , 'PN_ADDRESSES'                   , 'PN'    ,'N','N');
  add_list('PN_AE_HEADERS_ALL'              , 'PN_AE_HEADERS'                  , 'PN'    ,'N','N');
  add_list('PN_AE_LINES_ALL'                , 'PN_AE_LINES'                    , 'PN'    ,'N','N');
  add_list('PN_COMPANIES_ALL'               , 'PN_COMPANIES'                   , 'PN'    ,'N','N');
  add_list('PN_COMPANY_SITES_ALL'           , 'PN_COMPANY_SITES'               , 'PN'    ,'N','N');
  add_list('PN_CONTACTS_ALL'                , 'PN_CONTACTS'                    , 'PN'    ,'N','N');
  add_list('PN_CONTACT_ASSIGNMENTS_ALL'     , 'PN_CONTACT_ASSIGNMENTS'         , 'PN'    ,'N','N');
  add_list('PN_DISTRIBUTIONS_ALL'           , 'PN_DISTRIBUTIONS'               , 'PN'    ,'N','N');
  add_list('PN_INDEX_EXCLUDE_TERM_ALL'      , 'PN_INDEX_EXCLUDE_TERM'          , 'PN'    ,'N','N');
  add_list('PN_INDEX_LEASES_ALL'            , 'PN_INDEX_LEASES'                , 'PN'    ,'N','N');
  add_list('PN_INDEX_LEASE_CONSTRAINTS_ALL' , 'PN_INDEX_LEASE_CONSTRAINTS'     , 'PN'    ,'N','N');
  add_list('PN_INDEX_LEASE_PERIODS_ALL'     , 'PN_INDEX_LEASE_PERIODS'         , 'PN'    ,'N','N');
  add_list('PN_INDEX_LEASE_TERMS_ALL'       , 'PN_INDEX_LEASE_TERMS'           , 'PN'    ,'N','N');
  add_list('PN_INSURANCE_REQUIREMENTS_ALL'  , 'PN_INSURANCE_REQUIREMENTS'      , 'PN'    ,'N','N');
  add_list('PN_LANDLORD_SERVICES_ALL'       , 'PN_LANDLORD_SERVICES'           , 'PN'    ,'N','N');
  add_list('PN_LEASES_ALL'                  , 'PN_LEASES'                      , 'PN'    ,'N','N');
  add_list('PN_LEASE_CHANGES_ALL'           , 'PN_LEASE_CHANGES'               , 'PN'    ,'N','N');
  add_list('PN_LEASE_DETAILS_ALL'           , 'PN_LEASE_DETAILS'               , 'PN'    ,'N','N');
  add_list('PN_LEASE_MILESTONES_ALL'        , 'PN_LEASE_MILESTONES'            , 'PN'    ,'N','N');
  add_list('PN_LEASE_TRANSACTIONS_ALL'      , 'PN_LEASE_TRANSACTIONS'          , 'PN'    ,'N','N');
  add_list('PN_LOC_ACC_MAP_HDR_ALL'         , 'PN_LOC_ACC_MAP_HDR'             , 'PN'    ,'N','N');
  add_list('PN_LOC_ACC_MAP_ALL'             , 'PN_LOC_ACC_MAP'                 , 'PN'    ,'N','N');
  add_list('PN_LOCATIONS_ALL'               , 'PN_LOCATIONS'                   , 'PN'    ,'N','N');
  add_list('PN_LOCATION_FEATURES_ALL'       , 'PN_LOCATION_FEATURES'           , 'PN'    ,'N','N');
  add_list('PN_OPTIONS_ALL'                 , 'PN_OPTIONS'                     , 'PN'    ,'N','N');
  add_list('PN_PAYMENT_ITEMS_ALL'           , 'PN_PAYMENT_ITEMS'               , 'PN'    ,'N','N');
  add_list('PN_PAYMENT_SCHEDULES_ALL'       , 'PN_PAYMENT_SCHEDULES'           , 'PN'    ,'N','N');
  add_list('PN_PAYMENT_TERMS_ALL'           , 'PN_PAYMENT_TERMS'               , 'PN'    ,'N','N');
  add_list('PN_PHONES_ALL'                  , 'PN_PHONES'                      , 'PN'    ,'N','N');
  add_list('PN_PROPERTIES_ALL'              , 'PN_PROPERTIES'                  , 'PN'    ,'N','N');

  add_list('PN_REC_AGR_LINABAT_ALL'         , 'PN_REC_AGR_LINABAT'             , 'PN'    ,'N','N');
  add_list('PN_REC_AGR_LINAREA_ALL'         , 'PN_REC_AGR_LINAREA'             , 'PN'    ,'N','N');
  add_list('PN_REC_AGR_LINCONST_ALL'        , 'PN_REC_AGR_LINCONST'            , 'PN'    ,'N','N');
  add_list('PN_REC_AGR_LINES_ALL'           , 'PN_REC_AGR_LINES'               , 'PN'    ,'N','N');
  add_list('PN_REC_AGR_LINEXP_ALL'          , 'PN_REC_AGR_LINEXP'              , 'PN'    ,'N','N');
  add_list('PN_REC_AGREEMENTS_ALL'          , 'PN_REC_AGREEMENTS'              , 'PN'    ,'N','N');
  add_list('PN_REC_ARCL_ALL'                , 'PN_REC_ARCL'                    , 'PN'    ,'N','N');
  add_list('PN_REC_ARCL_DTL_ALL'            , 'PN_REC_ARCL_DTL'                , 'PN'    ,'N','N');
  add_list('PN_REC_ARCL_DTLLN_ALL'          , 'PN_REC_ARCL_DTLLN'              , 'PN'    ,'N','N');
  add_list('PN_REC_ARCL_EXC_ALL'            , 'PN_REC_ARCL_EXC'                , 'PN'    ,'N','N');
  add_list('PN_REC_CALC_PERIODS_ALL'        , 'PN_REC_CALC_PERIODS'            , 'PN'    ,'N','N');
  add_list('PN_REC_EXP_LINE_ALL'            , 'PN_REC_EXP_LINE'                , 'PN'    ,'N','N');
  add_list('PN_REC_EXP_LINE_DTL_ALL'        , 'PN_REC_EXP_LINE_DTL'            , 'PN'    ,'N','N');
  add_list('PN_REC_EXPCL_ALL'               , 'PN_REC_EXPCL'                   , 'PN'    ,'N','N');
  add_list('PN_REC_EXPCL_DTL_ALL'           , 'PN_REC_EXPCL_DTL'               , 'PN'    ,'N','N');
  add_list('PN_REC_EXPCL_DTLACC_ALL'        , 'PN_REC_EXPCL_DTLACC'            , 'PN'    ,'N','N');
  add_list('PN_REC_EXPCL_DTLLN_ALL'         , 'PN_REC_EXPCL_DTLLN'             , 'PN'    ,'N','N');
  add_list('PN_REC_EXPCL_INC_ALL'           , 'PN_REC_EXPCL_INC'               , 'PN'    ,'N','N');
  add_list('PN_REC_EXPCL_TYPE_ALL'          , 'PN_REC_EXPCL_TYPE'              , 'PN'    ,'N','N');
  add_list('PN_REC_LINBILL_ALL'             , 'PN_REC_LINBILL'                 , 'PN'    ,'N','N');
  add_list('PN_REC_PERIOD_BILLREC_ALL'      , 'PN_REC_PERIOD_BILLREC'          , 'PN'    ,'N','N');
  add_list('PN_REC_PERIOD_LINES_ALL'        , 'PN_REC_PERIOD_LINES'            , 'PN'    ,'N','N');

  add_list('PN_SPACE_ALLOCATIONS_ALL'       , 'PN_SPACE_ALLOCATIONS'           , 'PN'    ,'N','N');
  add_list('PN_SPACE_ASSIGN_CUST_ALL'       , 'PN_SPACE_ASSIGN_CUST'           , 'PN'    ,'N','N');
  add_list('PN_SPACE_ASSIGN_EMP_ALL'        , 'PN_SPACE_ASSIGN_EMP'            , 'PN'    ,'N','N');
  add_list('PN_TENANCIES_ALL'               , 'PN_TENANCIES'                   , 'PN'    ,'N','N');
  add_list('PN_TERM_TEMPLATES_ALL'          , 'PN_TERM_TEMPLATES'              , 'PN'    ,'N','N');
  add_list('PN_VAR_ABATEMENTS_ALL'          , 'PN_VAR_ABATEMENTS'              , 'PN'    ,'N','N');
  add_list('PN_VAR_BKPTS_DET_ALL'           , 'PN_VAR_BKPTS_DET'               , 'PN'    ,'N','N');
  add_list('PN_VAR_BKPTS_HEAD_ALL'          , 'PN_VAR_BKPTS_HEAD'              , 'PN'    ,'Y','N');
  add_list('PN_VAR_CONSTRAINTS_ALL'         , 'PN_VAR_CONSTRAINTS'             , 'PN'    ,'Y','N');
  add_list('PN_VAR_DEDUCTIONS_ALL'          , 'PN_VAR_DEDUCTIONS'              , 'PN'    ,'Y','N');
  add_list('PN_VAR_GRP_DATES_ALL'           , 'PN_VAR_GRP_DATES'               , 'PN'    ,'N','N');
  add_list('PN_VAR_LINES_ALL'               , 'PN_VAR_LINES'                   , 'PN'    ,'Y','N');
  add_list('PN_VAR_PERIODS_ALL'             , 'PN_VAR_PERIODS'                 , 'PN'    ,'N','N');
  add_list('PN_VAR_RENTS_ALL'               , 'PN_VAR_RENTS'                   , 'PN'    ,'Y','N');
  add_list('PN_VAR_RENT_DATES_ALL'          , 'PN_VAR_RENT_DATES'              , 'PN'    ,'Y','N');
  add_list('PN_VAR_RENT_INV_ALL'            , 'PN_VAR_RENT_INV'                , 'PN'    ,'N','N');
  add_list('PN_VAR_RENT_SUMM_ALL'           , 'PN_VAR_RENT_SUMM'               , 'PN'    ,'N','N');
  add_list('PN_VAR_VOL_HIST_ALL'            , 'PN_VAR_VOL_HIST'                , 'PN'    ,'N','N');

--
  add_list('PO_ACCRUAL_ACCOUNTS_TEMP_ALL'   , 'PO_ACCRUAL_ACCOUNTS_TEMP'       , 'PO'    ,'N','N');
  add_list('PO_ACCRUAL_RECONCILE_TEMP_ALL'  , 'PO_ACCRUAL_RECONCILE_TEMP'      , 'PO'    ,'N','N');
  add_list('PO_ACCRUAL_WRITE_OFFS_ALL'      , 'PO_ACCRUAL_WRITE_OFFS'          , 'PO'    ,'N','N');
  add_list('PO_AUTOSOURCE_DOCUMENTS_ALL'    , 'PO_AUTOSOURCE_DOCUMENTS'        , 'PO'    ,'N','N');
  add_list('PO_CONTROL_GROUPS_ALL'          , 'PO_CONTROL_GROUPS'              , 'PO'    ,'N','N');
  add_list('PO_DISTRIBUTIONS_ALL'           , 'PO_DISTRIBUTIONS'               , 'PO'    ,'N','N');
  add_list('PO_DISTRIBUTIONS_ARCHIVE_ALL'   , 'PO_DISTRIBUTIONS_ARCHIVE'       , 'PO'    ,'N','N');
  add_list('PO_DOCUMENT_TYPES_ALL_B'        , 'PO_DOCUMENT_TYPES_B'            , 'PO'    ,'Y','N');
  add_list('PO_DOCUMENT_TYPES_ALL_TL'       , 'PO_DOCUMENT_TYPES_TL'           , 'PO'    ,'Y','N');
  add_list('PO_HEADERS_ALL'                 , 'PO_HEADERS'                     , 'PO'    ,'N','N');
  add_list('PO_HEADERS_ARCHIVE_ALL'         , 'PO_HEADERS_ARCHIVE'             , 'PO'    ,'N','N');
  add_list('PO_HISTORY_POS_ALL'             , 'PO_HISTORY_POS'                 , 'PO'    ,'N','N');
  add_list('PO_HISTORY_REQUISITIONS_ALL'    , 'PO_HISTORY_REQUISITIONS'        , 'PO'    ,'N','N');
  add_list('PO_LINES_ALL'                   , 'PO_LINES'                       , 'PO'    ,'N','N');
  add_list('PO_LINES_ARCHIVE_ALL'           , 'PO_LINES_ARCHIVE'               , 'PO'    ,'N','N');
  add_list('PO_LINE_LOCATIONS_ALL'          , 'PO_LINE_LOCATIONS'              , 'PO'    ,'N','N');
  add_list('PO_LINE_LOCATIONS_ARCHIVE_ALL'  , 'PO_LINE_LOCATIONS_ARCHIVE'      , 'PO'    ,'N','N');
  add_list('PO_LOCATION_ASSOCIATIONS_ALL'  ,  'PO_LOCATION_ASSOCIATIONS'       , 'PO'    ,'N','N');
  add_list('PO_MASSCANCEL_INCLUDES_ALL'     , 'PO_MASSCANCEL_INCLUDES'         , 'PO'    ,'N','N');
  add_list('PO_NOTIFICATIONS_ALL'           , 'PO_NOTIFICATIONS'               , 'PO'    ,'N','N');
  add_list('PO_POSITION_CONTROLS_ALL'       , 'PO_POSITION_CONTROLS'           , 'PO'    ,'N','N');
  add_list('PO_QUOTATION_APPROVALS_ALL'     , 'PO_QUOTATION_APPROVALS'         , 'PO'    ,'N','N');
  add_list('PO_RELEASES_ALL'                , 'PO_RELEASES'                    , 'PO'    ,'N','N');
  add_list('PO_RELEASES_ARCHIVE_ALL'        , 'PO_RELEASES_ARCHIVE'            , 'PO'    ,'N','N');
  add_list('PO_REQEXPRESS_HEADERS_ALL'      , 'PO_REQEXPRESS_HEADERS'          , 'PO'    ,'N','N');
  add_list('PO_REQEXPRESS_LINES_ALL'        , 'PO_REQEXPRESS_LINES'            , 'PO'    ,'N','N');
  add_list('PO_REQUISITIONS_INTERFACE_ALL'  , 'PO_REQUISITIONS_INTERFACE'      , 'PO'    ,'N','N');
  add_list('PO_REQUISITION_HEADERS_ALL'     , 'PO_REQUISITION_HEADERS'         , 'PO'    ,'N','N');
  add_list('PO_REQUISITION_LINES_ALL'       , 'PO_REQUISITION_LINES'           , 'PO'    ,'N','N');
  add_list('PO_REQ_DISTRIBUTIONS_ALL'       , 'PO_REQ_DISTRIBUTIONS'           , 'PO'    ,'N','N');
  add_list('PO_REQ_DIST_INTERFACE_ALL'      , 'PO_REQ_DIST_INTERFACE'          , 'PO'    ,'N','N');
  add_list('PO_RULE_EXPENSE_ACCOUNTS'       , 'PO_RULE_EXPENSE_ACCOUNTS'       , 'PO'    ,'N','N');
  add_list('PO_SYSTEM_PARAMETERS_ALL'       , 'PO_SYSTEM_PARAMETERS'           , 'PO'    ,'N','N');
  add_list('PO_UNIQUE_IDENTIFIER_CONT_ALL'  , 'PO_UNIQUE_IDENTIFIER_CONTROL'   , 'PO'    ,'Y','N');
  add_list('PO_VENDOR_SITES_ALL'            , 'PO_VENDOR_SITES'                , 'PO'    ,'N','N');
  --
  add_list('PON_AUCTION_HEADERS_ALL'        , 'PON_AUCTION_HEADERS'            , 'PN'    ,'N','N');
  add_list('PON_AUCTION_ITEM_PRICES_ALL'    , 'PON_AUCTION_ITEM_PRICES'        , 'PN'    ,'N','N');
  --
  -- bug 7654852
  add_list('PON_EMD_PAYMENT_TYPES_ALL'      , 'PON_EMD_PAYMENT_TYPES_VL'       , 'PON'   ,'Y','N');
  add_list('PON_EMD_PAYMENT_TYPES_TL'       , 'PON_EMD_PAYMENT_TYPES_VL'       , 'PON'   ,'Y','N');
  --
  add_list('RLA_DEMAND_HEADERS_ALL'         , 'RLA_DEMAND_HEADERS'             , 'RLA'   ,'N','N');
  add_list('RLA_DEMAND_HEADERS_ARCHIVE_ALL' , 'RLA_DEMAND_HEADERS_ARCHIVE'     , 'RLA'   ,'N','N');
  add_list('RLA_DEMAND_INTERFACE_ALL'       , 'RLA_DEMAND_INTERFACE'           , 'RLA'   ,'N','N');
  add_list('RLA_DEMAND_LINES_ALL'           , 'RLA_DEMAND_LINES'               , 'RLA'   ,'N','N');
  add_list('RLA_DEMAND_LINES_ARCHIVE_ALL'   , 'RLA_DEMAND_LINES_ARCHIVE'       , 'RLA'   ,'N','N');
  --
  add_list('RLM_CUST_ITEM_CUM_ADJ_ALL'      , 'RLM_CUST_ITEM_CUM_ADJ'          , 'RLM'   ,'N','N');
  add_list('RLM_CUST_ITEM_CUM_KEYS_ALL'     , 'RLM_CUST_ITEM_CUM_KEYS'         , 'RLM'   ,'N','N');
  add_list('RLM_CUST_ITEM_TERMS_ALL'        , 'RLM_CUST_ITEM_TERMS'            , 'RLM'   ,'N','N');
  add_list('RLM_CUST_SHIPTO_TERMS_ALL'      , 'RLM_CUST_SHIPTO_TERMS'          , 'RLM'   ,'N','N');
  add_list('RLM_INTERFACE_HEADERS_ALL'      , 'RLM_INTERFACE_HEADERS'          , 'RLM'   ,'N','N');
  add_list('RLM_INTERFACE_LINES_ALL'        , 'RLM_INTERFACE_LINES'            , 'RLM'   ,'N','N');
  add_list('RLM_SCHEDULE_HEADERS_ALL'       , 'RLM_SCHEDULE_HEADERS'           , 'RLM'   ,'N','N');
  add_list('RLM_SCHEDULE_LINES_ALL'         , 'RLM_SCHEDULE_LINES'             , 'RLM'   ,'N','N');

  add_list('OZF_CLAIM_TYPES_ALL_B'          , 'OZF_CLAIM_TYPES_VL'             , 'OZF'   ,'Y','N');
  add_list('OZF_CLAIM_TYPES_ALL_TL'         , 'OZF_CLAIM_TYPES_ALL_VL'         , 'OZF'   ,'Y','N');


  -- Bug: 4623852
  add_list('OZF_CLAIM_DEF_RULES_ALL'         , 'OZF_CLAIM_DEF_RULES_ALL'         , 'OZF'   ,'Y','N');
  add_list('OZF_CLAIM_STTLMNT_METHODS_ALL'   , 'OZF_CLAIM_STTLMNT_METHODS_ALL'   , 'OZF'   ,'Y','N');

  --
  -- for bug 3513992, table WSH_DELIVERY_DETAILS does not have corresponding
  -- view. Setting it to WSH_DELIVERY_DETAILS
  add_list('WSH_DELIVERY_DETAILS'           , 'WSH_DELIVERY_DETAILS'           , 'WSH'   , 'N','N');

  --
  -- for bug 4407367, table PO_CHANGE_ORDER_TOLERANCES_ALL does not have corresponding
  -- view. Setting it to PO_CHANGE_ORDER_TOLERANCES_ALL
  add_list('PO_CHANGE_ORDER_TOLERANCES_ALL'           , 'PO_CHANGE_ORDER_TOLERANCES_ALL'           , 'PO'   , 'Y','N');

  -- for bug 4592660, adding the following seed tables

  add_list('CN_CW_WORKBENCH_ITEMS_ALL_B'     , 'CN_CW_WORKBENCH_ITEMS_ALL_VL'       , 'CN'   , 'Y','N');
  add_list('CN_CW_WORKBENCH_ITEMS_ALL_TL'    , 'CN_CW_WORKBENCH_ITEMS_ALL_VL'       , 'CN'   , 'Y','N');
  add_list('CN_CW_SETUP_TASKS_ALL_B'         , 'CN_CW_SETUP_TASKS_ALL_VL'           , 'CN'   , 'Y','N');
  add_list('CN_CW_SETUP_TASKS_ALL_TL'        , 'CN_CW_SETUP_TASKS_ALL_VL'           , 'CN'   , 'Y','N');

  --
  -- all NULL end of list
  --
  add_list(null, null, null, null,'N');

  g_load_table_data := TRUE;
end load_table_list;


-- Bug 3611969 : FIXED FILE.SQL.35 GSCC WARNINGS
-- sraghuve (07/05/2004)

procedure load_table_list
is
begin
  load_table_list('N');
end;

--
-- Procedure to initialize the table list and return the count of
-- multi-org partitioned tables
--

procedure initialize
           (X_number out nocopy number)
is
begin
  load_table_list;

  X_number := 0;

  if (table_list.count > 0) then
     X_number := table_list.count - 1;
  end if;
end;

--
-- procedure to return the next partitioned table given the index to the
-- current table. It also returns the conversion method for the table and
-- increments the index variable to point to the new table.
--

procedure get_next_table
           (X_number      in out nocopy number,
            X_table_name  out    nocopy varchar2,
            X_conv_method out    nocopy varchar2)
is
  i number;
begin
   if (NOT g_load_table_data) then
      load_table_list;
   end if;

   i := X_number + 1;

   X_table_name := table_list(i);
   X_conv_method := conv_method(i);

   X_number := i;

   return;
end;

function get_org_count return number is
  l_num_org     number;
begin

  select count(*)
  into   l_num_org
  from   hr_operating_units
  ,      fnd_product_groups
  where  product_group_id = 1
  and    multi_org_flag = 'Y';

  return(l_num_org);
end;

procedure enable_debug
           (p_debug_level in number)
is
begin
  g_debug_level := p_debug_level;
end;

procedure debug
           (p_txt          in varchar2,
            p_debug_level  in number default 0,
            p_indent_level in number default 0)
is
  l_len       number;
  l_total_len number;
  l_max_len   number := 80 - (p_indent_level * 4);
begin

   return;

   if (g_debug_level >= p_debug_level) then
      l_len := 1;

      l_total_len := length(p_txt);

      while (l_len < l_total_len)
      loop
          l_len := l_len + l_max_len;
      end loop;
   end if;
end;

procedure debugln
           (p_txt          in varchar2,
            p_debug_level  in number default 0,
            p_indent_level in number default 0)
is
begin
   debug(p_txt, p_debug_level, p_indent_level);
   debug('       ', p_debug_level);
end;


procedure verify_table_seed_data
           (X_table       IN varchar2,
            X_num_org     IN number,
            X_debug_level IN number default 0)
is
  where_clause     varchar2(32767);
  group_clause     varchar2(32767);
  column_list      varchar2(32767);
  statement        varchar2(32767);
  c                integer;
  row_processed    integer;
  l_count          integer;
  pk_list          varchar2(200);
  pk_list_simple   varchar2(200);
  pk_value         varchar2(600);

  table_not_found  exception;

  cursor c_primary_key(p_table varchar2) is
    select c.column_name, pkc.primary_key_sequence
    from   fnd_columns             c
    ,      fnd_primary_key_columns pkc
    ,      fnd_primary_keys        pk
    ,      fnd_tables              t
    where  t.application_id   >= 0
    and    t.table_name        = p_table
    and    pk.application_id   = t.application_id
    and    pk.table_id         = t.table_id
    and    pk.primary_key_type = 'D'
    and    pkc.application_id  = pk.application_id
    and    pkc.table_id        = pk.table_id
    and    pkc.primary_key_id  = pk.primary_key_id
    and    c.application_id    = pkc.application_id
    and    c.table_id          = pkc.table_id
    and    c.column_id         = pkc.column_id
    and    c.column_name      <> 'ORG_ID'
    order by pkc.primary_key_sequence;

begin

  enable_debug(X_debug_level);
  debugln('Process table : '||X_table, MSG_LEVEL_BASIC);

  for c_pk in c_primary_key(X_table) loop
    if (pk_list is null) then
       pk_list := c_pk.column_name;
       pk_list_simple := initcap(c_pk.column_name);
    else
       pk_list := pk_list||'||'||''''||'-'||''''||'||'||c_pk.column_name;
       pk_list_simple := pk_list_simple||'-'||initcap(c_pk.column_name);
    end if;

    if (where_clause is null) then
       where_clause := 'b.'||c_pk.column_name || ' = A.' || c_pk.column_name;
    else
       where_clause := where_clause || ' AND b.' ||
                   c_pk.column_name || ' = A.' || c_pk.column_name;
    end if;

    if (group_clause is null) then
       group_clause := ' group by '||c_pk.column_name;
    else
       group_clause := group_clause||', '||c_pk.column_name;
    end if;
  end loop;

  if (pk_list is null) then
     debugln('Warning : '||X_table||' does not have primary key',
             MSG_LEVEL_WARN);
  end if;

  statement := ' select '||''' '||''''||'||'||
                       nvl(pk_list, ''''||'no primary key'||'''')
                       ||' pk_value '||
               ' from  '||X_table||' a'||
               ' where org_id in (-3113, -3114)'||
               ' and decode(org_id, -3114, 1, '||X_num_org||') <> ( '||
               ' select count(*)'||
               ' from  '||X_table||' b'||
               ' where '||nvl(where_clause, '1=1 ')||
               ' and nvl(b.org_id, -99) not in (-3113, -3114)'||
               ') order by 1';

  debugln(statement, MSG_LEVEL_SQL, 1);

  c := dbms_sql.open_cursor;
  dbms_sql.parse(c, statement, dbms_sql.native);
  dbms_sql.define_column(c, 1, pk_value, 600);
  row_processed := dbms_sql.execute(c);

  l_count   := 0;

  loop
      if dbms_sql.fetch_rows(c) > 0 then
        if (l_count = 0) then
           debug('There are seed data row(s) missing from the table. '||
                 'The primary key values   for these rows are as follows ',
                 MSG_LEVEL_DATA, 1);
           debug(pk_list_simple,
                 MSG_LEVEL_DATA, 2);
           debugln(rpad('-', length(pk_list_simple), '-'),
                   MSG_LEVEL_DATA, 2);
        end if;
        dbms_sql.column_value(c, 1, pk_value);
        l_count := l_count + 1;
        if (pk_value is null) then
            debug('Primary key is null', MSG_LEVEL_DATA, 2);
        else
            debug(pk_value, MSG_LEVEL_DATA, 2);
        end if;
      else
        dbms_sql.close_cursor(c);
        exit;
      end if;
  end loop;

  if (l_count > 0) then
     debugln(rpad(X_table, 30)||' : '||lpad(to_char(l_count), 6)||
             ' row(s) missing ', MSG_LEVEL_WARN);
  end if;

end;

procedure verify_seed_data
           (X_appl_short_name IN varchar2,
            X_table           IN varchar2,
            X_debug_level     IN number) is

  l_num_org     number;
  l_multi_org   boolean := TRUE;
  i             number;
begin

  l_num_org := get_org_count();

  if (l_num_org = 0) then
     l_num_org   := 1;
     l_multi_org := FALSE;
  end if;

  ad_morg.load_table_list('N');

  if (X_table is null) then

     i := 1;

     loop
        if (ad_morg.table_list(i) is not null
            and
            ad_morg.seed_data(i) = 'Y'
            and
            ad_morg.appl_list(i) = nvl(upper(X_appl_short_name),
                                       ad_morg.appl_list(i))
           )
        then

            verify_table_seed_data(ad_morg.table_list(i), l_num_org,
                                   X_debug_level);

        end if;

        if (ad_morg.table_list(i) is null) then
            exit;
        end if;

        i := i + 1;

     end loop;

  elsif (X_table is not null) then
     verify_table_seed_data(X_table, l_num_org, X_debug_level);
  end if;


end verify_seed_data;

procedure update_book_id
                (X_org_id          in number,
                 X_table_name      in varchar2)
is
        book_id varchar2(20);
        stmt    varchar2(400);
        st      varchar2(400);
        cnt     number :=0;
	id	number :=0;
begin
  select count(*) into cnt
        from dba_tab_columns
        where table_name= X_table_name and
	column_name='SET_OF_BOOKS_ID' and
	nvl(owner, 'null') = nvl(owner, 'null');
  if (cnt > 0)
  then
        select SET_OF_BOOKS_ID into book_id
		from HR_OPERATING_UNITS where
		ORGANIZATION_ID=X_org_id;
	id := to_number(book_id);
	if (id > 1) then
        	stmt:= 'update ' || X_table_name || ' set SET_OF_BOOKS_ID='||book_id||
' where ORG_ID='||X_org_id;
        	EXECUTE IMMEDIATE stmt;
	end if;
  end if;

exception
  when NO_DATA_FOUND then
	cnt := 0;
	id := 0;

end update_book_id;

begin
  g_prod_status     := '$#';
  g_industry        := '$#';
  g_prev_product    := '$#$#';
  g_oracle_schema    := '$#$#';
  g_load_table_stats  := 'Y';

end ad_morg;
