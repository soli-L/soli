
  CREATE OR REPLACE EDITIONABLE PACKAGE "APPS"."AD_DD" AUTHID CURRENT_USER as
/* $Header: addds.pls 120.0.12020000.2 2016/02/11 05:06:18 sstomar ship $ */
procedure register_table
           (p_appl_short_name in varchar2,
            p_tab_name        in varchar2,
            p_tab_type        in varchar2,
            p_next_extent     in number default 512,
            p_pct_free        in number default 10,
            p_pct_used        in number default 70);

procedure register_column
           (p_appl_short_name in varchar2,
            p_tab_name        in varchar2,
            p_col_name        in varchar2,
            p_col_seq         in number,
            p_col_type        in varchar2,
            p_col_width       in number,
            p_nullable        in varchar2,
            p_translate       in varchar2,
            p_precision       in number default null,
            p_scale           in number default null);

procedure register_primary_key
           (p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_description     in varchar2,
            p_key_type        in varchar2,
            p_audit_flag      in varchar2,
            p_enabled_flag    in varchar2);

procedure update_primary_key
           (p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_description     in varchar2 default null,
            p_key_type        in varchar2 default null,
            p_audit_flag      in varchar2 default null,
            p_enabled_flag    in varchar2 default null);

procedure register_primary_key_column
           (p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_col_name        in varchar2,
            p_col_sequence    in number);

procedure delete_primary_key_column
           (p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_col_name        in varchar2 default null);


procedure delete_table
           (p_appl_short_name in varchar2,
            p_tab_name        in varchar2);

procedure delete_column
           (p_appl_short_name in varchar2,
            p_tab_name        in varchar2,
            p_col_name        in varchar2);

end ad_dd;

CREATE OR REPLACE EDITIONABLE PACKAGE BODY "APPS"."AD_DD" as
/* $Header: adddb.pls 120.0.12020000.3 2016/02/11 04:49:20 sstomar ship $ */
--
-- PRIVATE FUNCTION
--
procedure is_valid_appl_short_name
           (p_apps_short_name               varchar2,
            p_apps_id         in out nocopy number) is
  cnt integer;
begin
  select count(*), application_id into cnt, p_apps_id
    from fnd_application
    where application_short_name = upper(p_apps_short_name)
    group by application_id;

  if cnt <> 1 then
    raise_application_error(-20000, 'Invalid application_short_name: "'||
                            p_apps_short_name||'"');
  end if;

exception
  when no_data_found then
    raise_application_error(-20000, 'Invalid application_short_name: "'||
                            p_apps_short_name||'"');

end is_valid_appl_short_name;

function get_table_id(p_apps_id  in number,
                      p_tab_name in varchar2) return number is
  p_table_id number;
begin

  select table_id into p_table_id
    from  fnd_tables
    where application_id = p_apps_id
      and table_name = p_tab_name;

  return p_table_id;

exception
  when no_data_found then
    return null;

end get_table_id;

function get_column_id(p_appl_id  in number,
                      p_table_id  in number,
                      p_col_name  in varchar2) return number is
  l_col_id number;
begin

  select column_id into l_col_id
    from  fnd_columns
    where application_id = p_appl_id
      and table_id       = p_table_id
      and column_name    = p_col_name;

  return l_col_id;

exception
  when no_data_found then
    return null;

end get_column_id;

function check_multiple_developer_keys(
    p_appl_id       in number,
    p_table_id      in number,
    p_key_name      in varchar2) return boolean
is
  l_tmp  number;
begin

   select count(*)
   into   l_tmp
   from   fnd_primary_keys
   where  application_id = p_appl_id
   and    table_id       = p_table_id
   and    primary_key_name <> upper(p_key_name)
   and    primary_key_type = 'D';

   if (l_tmp > 0) then
      return(TRUE);
   else
      return(FALSE);
   end if;
end;

function get_primary_key_id(p_appl_id   in number,
                            p_table_id  in number,
                            p_key_name  in varchar2) return number
is
  l_key_id   number;
begin

  select primary_key_id
  into   l_key_id
  from   fnd_primary_keys
  where  application_id = p_appl_id
  and    table_id       = p_table_id
  and    primary_key_name = upper(p_key_name);

  return(l_key_id);

exception
  when no_data_found then
    return(null);
end;

procedure insert_update_primary_key
           (p_mode            in varchar2,
            p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_description     in varchar2,
            p_enabled_flag    in varchar2,
            p_key_type        in varchar2,
            p_audit_flag      in varchar2)
is
  l_table_id     number := null;
  l_appl_id      number := null;
  l_key_id       number;
begin

  --
  -- check to see if the application_id is valid
  --
  is_valid_appl_short_name(p_appl_short_name, l_appl_id);

  --
  -- check to see if the table exists
  --
  l_table_id := get_table_id(l_appl_id, upper(p_tab_name));

  if (l_table_id is null) then
     raise_application_error(-20000, 'Cannot find the table_id for table: "'||
                             p_tab_name||'" with application_short_name "'||
                             p_appl_short_name||'"');
  end if;

  --
  -- check if the key exists
  --
  l_key_id := get_primary_key_id(l_appl_id, l_table_id, p_key_name);

  if    (p_mode = 'INSERT' and l_key_id is not null) then
     return;
  elsif (p_mode = 'UPDATE' and l_key_id is null) then
     raise_application_error(-20000,
           'Cannot find the key_id for key: "'||p_key_name||'" for table "'||
           p_tab_name||'" with application_short_name "'||
           p_appl_short_name||'"');
  end if;

  --
  -- check for multiple developer primary keys
  --
  if (p_key_type = 'D') then
     if (check_multiple_developer_keys(l_appl_id, l_table_id, p_key_name)) then
        raise_application_error(-20000, 'You cannot define more than one '||
             'developer primary key on a table ('||p_tab_name||')');
     end if;
  end if;

  --
  -- perform other checks
  --
  if ((p_mode = 'INSERT' and     p_key_type       not in ('S', 'D')) or
      (p_mode = 'UPDATE' and nvl(p_key_type, 'S') not in ('S', 'D'))) then
     raise_application_error(-20000, 'Invalid value for primary key type : '||
                                     p_key_type);
  end if;

  if ((p_mode = 'INSERT' and     p_audit_flag       not in ('Y', 'N')) or
      (p_mode = 'UPDATE' and nvl(p_audit_flag, 'Y') not in ('Y', 'N'))) then
     raise_application_error(-20000, 'Invalid value for audit flag : '||
                                     p_audit_flag);
  end if;

  if ((p_enabled_flag = 'INSERT' and  p_enabled_flag       not in ('Y', 'N'))
       or
      (p_enabled_flag = 'UPDATE' and nvl(p_enabled_flag,'Y') not in ('Y','N')))
  then
     raise_application_error(-20000, 'Invalid value for enabled flag : '||
                                     p_enabled_flag);
  end if;

  -- If here, we are going to perform DML.
  ad_zd_seed.prepare('FND_PRIMARY_KEYS');

  if (p_mode = 'INSERT' and l_key_id is null) then

    insert into fnd_primary_keys (
       APPLICATION_ID,
       TABLE_ID,
       PRIMARY_KEY_ID,
       PRIMARY_KEY_NAME,
       LAST_UPDATE_DATE, LAST_UPDATED_BY,
       CREATION_DATE, CREATED_BY,
       LAST_UPDATE_LOGIN,
       PRIMARY_KEY_TYPE,
       AUDIT_KEY_FLAG,
       DESCRIPTION,
       ENABLED_FLAG)
    select l_appl_id,
           l_table_id,
           fnd_primary_keys_s.nextval,
           p_key_name,
           to_date('01/01/1990', 'DD/MM/YYYY'), 1,
           to_date('01/01/1990', 'DD/MM/YYYY'), 1,
           0,
           p_key_type,
           p_audit_flag,
           p_description,
           p_enabled_flag
    from  dual
    where not exists (
            select 'x'
            from   fnd_primary_keys
            where  application_id = l_appl_id
            and    table_id       = l_table_id
            and    primary_key_name = upper(p_key_name));

  elsif (p_mode = 'UPDATE' and l_key_id is not null) then

    update fnd_primary_keys
    set  primary_key_type = nvl(p_key_type, primary_key_type),
         audit_key_flag   = nvl(p_audit_flag, audit_key_flag),
         description      = nvl(p_description, description),
         enabled_flag     = nvl(p_enabled_flag, enabled_flag)
    where application_id = l_appl_id
      and table_id       = l_table_id
      and primary_key_id = l_key_id;

  end if;

end;


--
-- PUBLIC PROCEDURES/FUNCTIONS
--
procedure register_table
           (p_appl_short_name in varchar2,
            p_tab_name        in varchar2,
            p_tab_type        in varchar2,
            p_next_extent     in number,
            p_pct_free        in number,
            p_pct_used        in number)
is
  up_tab_name varchar2(40);
  p_table_id  number       := null;
  p_appl_id   number       := null;
begin
  up_tab_name := upper(p_tab_name);
  --
  -- check to see if the application_id is valid
  --
  is_valid_appl_short_name(p_appl_short_name, p_appl_id);
  --
  -- check to see if the table already exists
  --
  p_table_id := get_table_id(p_appl_id, up_tab_name);

  if p_table_id is null then
    --
    -- table does not exist yet; insert it
    --
    declare
      new_auto_size    char(1);
      new_next_extent  number;
      new_tab_type     char(1);
      factor           number;
    begin
      --
      -- need to auto size?
      --
      new_tab_type := upper(p_tab_type);

      if new_tab_type = 'S' then
        new_auto_size := 'N';
      elsif new_tab_type = 'T' then
        new_auto_size := 'Y';
      else
        raise_application_error(-20000, 'Unknown table type: "'||p_tab_type||
          '" for table "'||up_tab_name||'".');
      end if;

      --
      -- calculate the next_extent size
      --
      new_next_extent := round(p_next_extent, 0);

      ad_zd_seed.prepare('FND_TABLES');

      insert into fnd_tables (
        application_id       ,
        table_id      ,
        table_name      ,
        user_table_name      ,
        last_update_date   ,
        last_updated_by      ,
        creation_date      ,
        created_by      ,
        last_update_login   ,
        auto_size      ,
        table_type      ,
        initial_extent       ,
        next_extent      ,
        min_extents      ,
        max_extents      ,
        pct_increase      ,
        ini_trans      ,
        max_trans      ,
        pct_free      ,
        pct_used      )
      select p_appl_id,
             fnd_tables_s.nextval,
             up_tab_name,
             up_tab_name,
             to_date('01-01-1990', 'DD-MM-YYYY') ,
             1,
             to_date('01-01-1990', 'DD-MM-YYYY') ,
             1,
             0,
             new_auto_size,
             new_tab_type,
             4,
             new_next_extent,
             1,
             50,
             0,
             1,
             255,
             p_pct_free,
             p_pct_used
        from sys.dual
        where not exists ( select 'x'
          from fnd_tables
          where application_id = p_appl_id
            and table_name = up_tab_name);

    end;
  end if;
end register_table;


procedure register_column
           (p_appl_short_name in varchar2,
            p_tab_name        in varchar2,
            p_col_name        in varchar2,
            p_col_seq         in number,
            p_col_type        in varchar2,
            p_col_width       in number,
            p_nullable        in varchar2,
            p_translate       in varchar2,
            p_precision       in number default null,
            p_scale           in number default null)
is
  new_col_type char(1);
  up_col_type  varchar2(40);
  up_tab_name  varchar2(40);
  p_table_id   number       := null;
  p_appl_id    number       := null;
begin
  up_col_type := upper(p_col_type);
  up_tab_name := upper(p_tab_name);
  --
  -- check to see if the application_id is valid
  --
  is_valid_appl_short_name(p_appl_short_name, p_appl_id);
  --
  -- get table_id
  --
  p_table_id := get_table_id(p_appl_id, up_tab_name);

  if p_table_id is null then

      raise_application_error(-20000, 'Table '||up_tab_name||
      ' does not exist in FND_TABLES for application_short_name "'||
      p_appl_short_name||'" application_id "'||p_appl_id||'".');

  end if;
  --
  -- check input column type value
  --
  if up_col_type = 'NCLOB' then
    new_col_type := 'A';
  elsif up_col_type = 'BLOB' then
    new_col_type := 'B';
  elsif up_col_type = 'DATE' then
    new_col_type := 'D';
  elsif up_col_type = 'CLOB' then
    new_col_type := 'E';
  elsif up_col_type = 'BFILE' then
    new_col_type := 'F';
  elsif up_col_type = 'ROWID' then
    new_col_type := 'I';
  elsif up_col_type = 'LONG' then
    new_col_type := 'L';
  elsif up_col_type = 'MLSLABEL' then
    new_col_type := 'M';
  elsif up_col_type = 'NUMBER' then
    new_col_type := 'N';
  elsif up_col_type = 'RAW' then
    new_col_type := 'R';
  elsif up_col_type = 'CHAR' then
    new_col_type := 'V';
  elsif up_col_type = 'VARCHAR2' then
    new_col_type := 'V';
  elsif up_col_type = 'NCHAR' then
    new_col_type := 'W';
  elsif up_col_type = 'NVARCHAR2' then
    new_col_type := 'W';
  elsif up_col_type = 'LONG RAW' then
    new_col_type := 'X';
  elsif up_col_type = 'VARCHAR' then
    new_col_type := 'Y';
  elsif up_col_type = 'RAW MLSLABEL' then
    new_col_type := 'Z';
  else

    raise_application_error(-20000, 'Unknown column type: "'||up_col_type||
      '" provided for Application_short_name "'||p_appl_short_name||
      '" application_id "'||p_appl_id||'" Table_name='||up_tab_name||
            ' Column_name='||p_col_name);

  end if;

  ad_zd_seed.prepare('FND_COLUMNS');
  --
  -- insert into FND_COLUMNS
  --
  insert into fnd_columns
               (APPLICATION_ID,
                TABLE_ID,
                COLUMN_ID,
                COLUMN_NAME,
                USER_COLUMN_NAME,
                COLUMN_SEQUENCE,
                LAST_UPDATE_DATE,
                LAST_UPDATED_BY,
                CREATION_DATE,
                CREATED_BY,
                LAST_UPDATE_LOGIN,
                COLUMN_TYPE,
                WIDTH,
                NULL_ALLOWED_FLAG,
                TRANSLATE_FLAG,
                FLEXFIELD_USAGE_CODE,
                PRECISION,
                SCALE)
  select p_appl_id,
         p_table_id,
         fnd_columns_s.nextval,
         upper(p_col_name),
         upper(p_col_name),
         p_col_seq,
         to_date('01-01-1990', 'DD-MM-YYYY'),
         1,
         to_date('01-01-1990', 'DD-MM-YYYY'),
         1,
         0,
         new_col_type,
         p_col_width,
         upper(p_nullable),
         upper(p_translate),
         'N',
         p_precision,
         p_scale
    from sys.dual
    where not exists (select 'x' from fnd_columns
            where application_id = p_appl_id
              and table_id = p_table_id
              and column_name = upper(p_col_name));

end register_column;

procedure delete_table
            (p_appl_short_name in varchar2,
             p_tab_name        in varchar2)
is
  up_tab_name varchar2(40);
  p_table_id  number := null;
  p_appl_id   number := null;
begin
  up_tab_name := upper(p_tab_name);
  --
  -- check to see if the application_id is valid
  --
  is_valid_appl_short_name(p_appl_short_name, p_appl_id);

  --
  -- check to see if the table exists
  --
  p_table_id := get_table_id(p_appl_id, up_tab_name);

  if p_table_id is null then
    --
    -- either the table has been deleted or does not exist
    --
    return;
  end if;

  --
  -- delete all columns
  --
  ad_zd_seed.prepare('FND_COLUMNS');
  delete from fnd_columns
    where application_id = p_appl_id and table_id = p_table_id;

  ad_zd_seed.prepare('FND_TABLES');

  delete from fnd_tables
    where application_id = p_appl_id and table_id = p_table_id;

end delete_table;

procedure delete_column
           (p_appl_short_name in varchar2,
            p_tab_name        in varchar2,
            p_col_name        in varchar2)
is
  p_table_id     number := null;
  p_appl_id      number := null;
begin
  --
  -- check to see if the application_id is valid
  --
  is_valid_appl_short_name(p_appl_short_name, p_appl_id);

  --
  -- check to see if the table exists
  --
  p_table_id := get_table_id(p_appl_id, upper(p_tab_name));

  if p_table_id is null then
    --
    -- either the table has been deleted or does not exist
    --
    raise_application_error(-20000, 'Cannot find the table_id for table: "'||
      p_tab_name||'" with application_short_name "'||p_appl_short_name||
      '", application_id "'||p_appl_id||'" for column "'||
      p_col_name||'".');

  end if;

  ad_zd_seed.prepare('FND_COLUMNS');
  --
  -- delete the given column
  --
  delete from fnd_columns
    where application_id = p_appl_id
      and table_id = p_table_id
      and column_name = upper(p_col_name);

end delete_column;


procedure register_primary_key
           (p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_description     in varchar2,
            p_key_type        in varchar2,
            p_audit_flag      in varchar2,
            p_enabled_flag    in varchar2)
is
begin
   insert_update_primary_key('INSERT',
                             p_appl_short_name,
                             upper(p_key_name),
                             upper(p_tab_name),
                             p_description,
                             upper(p_enabled_flag),
                             upper(p_key_type),
                             upper(p_audit_flag));
end;

procedure update_primary_key
           (p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_description     in varchar2 default null,
            p_key_type        in varchar2 default null,
            p_audit_flag      in varchar2 default null,
            p_enabled_flag    in varchar2 default null)
is
begin
   insert_update_primary_key('UPDATE',
                             p_appl_short_name,
                             upper(p_key_name),
                             upper(p_tab_name),
                             p_description,
                             upper(p_enabled_flag),
                             upper(p_key_type),
                             upper(p_audit_flag));
end;

procedure register_primary_key_column
           (p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_col_name        in varchar2,
            p_col_sequence    in number)
is
  l_table_id     number := null;
  l_appl_id      number := null;
  l_col_id       number := null;
  l_key_id       number;
begin

  --
  -- check to see if the application_id is valid
  --
  is_valid_appl_short_name(p_appl_short_name, l_appl_id);

  --
  -- check to see if the table exists
  --
  l_table_id := get_table_id(l_appl_id, upper(p_tab_name));
  l_col_id   := get_column_id(l_appl_id, l_table_id, upper(p_col_name));

  l_key_id := get_primary_key_id(l_appl_id, l_table_id, p_key_name);

  if (l_table_id is null) then
     raise_application_error(-20000,
           'Cannot find the table_id for table: "'||p_tab_name||
           '" with application_short_name "'||p_appl_short_name||'"');
  end if;

  if (l_col_id is null) then
     raise_application_error(-20000,
           'Cannot find the column_id for column: "'||
           p_tab_name||'.'||p_col_name||'" with application_short_name "'||
           p_appl_short_name||'"');
  end if;

  if (l_key_id is null) then
     raise_application_error(-20000,
           'Cannot find the primary_key_id for the key : "'||
           p_key_name||'" on table "'||p_tab_name||
           '" with application_short_name "'|| p_appl_short_name||'"');
  end if;

  ad_zd_seed.prepare('FND_PRIMARY_KEY_COLUMNS');
  insert into fnd_primary_key_columns(
     APPLICATION_ID,
     TABLE_ID,
     PRIMARY_KEY_ID,
     PRIMARY_KEY_SEQUENCE,
     COLUMN_ID,
     LAST_UPDATE_DATE, LAST_UPDATED_BY,
     CREATION_DATE, CREATED_BY,
     LAST_UPDATE_LOGIN)
  select l_appl_id,
         l_table_id,
         l_key_id,
         p_col_sequence,
         l_col_id,
         to_date('01/01/1990', 'DD/MM/YYYY'), 1,
         to_date('01/01/1990', 'DD/MM/YYYY'), 1,
         0
   from  dual
   where not exists (
            select 'x'
            from   fnd_primary_key_columns
            where  application_id = l_appl_id
            and    table_id       = l_table_id
            and    primary_key_id = l_key_id
            and    column_id      = l_col_id);
end;


procedure delete_primary_key_column
           (p_appl_short_name in varchar2,
            p_key_name        in varchar2,
            p_tab_name        in varchar2,
            p_col_name        in varchar2 default null)
is
  l_table_id     number := null;
  l_appl_id      number := null;
  l_col_id       number := null;
  l_key_id       number;
begin
  --
  -- check to see if the application_id is valid
  --
  is_valid_appl_short_name(p_appl_short_name, l_appl_id);

  --
  -- check to see if the table exists
  --
  l_table_id := get_table_id(l_appl_id, upper(p_tab_name));

  if (p_col_name is not null) then
     l_col_id   := get_column_id(l_appl_id, l_table_id, upper(p_col_name));
  end if;

  l_key_id := get_primary_key_id(l_appl_id, l_table_id, p_key_name);

  if (l_table_id is null) then
     raise_application_error(-20000,
           'Cannot find the table_id for table: "'||p_tab_name||
           '" with application_short_name "'||p_appl_short_name||'"');
  end if;

  if (l_key_id is null) then
     raise_application_error(-20000,
           'Cannot find the key_id for key: "'||p_key_name||'" for table "'||
           p_tab_name||'" with application_short_name "'||
           p_appl_short_name||'"');
  end if;

  ad_zd_seed.prepare('FND_PRIMARY_KEY_COLUMNS');

  delete from fnd_primary_key_columns
  where application_id = l_appl_id
  and   table_id       = l_table_id
  and   primary_key_id = l_key_id
  and   column_id      = decode(p_col_name, null, column_id, l_col_id);

end;


end ad_dd;
